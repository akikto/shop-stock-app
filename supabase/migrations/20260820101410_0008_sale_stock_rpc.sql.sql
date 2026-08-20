-- =====================================================================
-- Phase 2 — Migration 8: Sale / Stock In / Stock Adjustment RPCs
--
-- sales, stock_entries, and stock_adjustments have NO client
-- INSERT policy (see migration 0003), and products has NO client
-- UPDATE policy (see the Phase 0 security fix). These three
-- SECURITY DEFINER functions are the ONLY way a client can record a
-- sale, add stock, or adjust stock. Each one:
--   - requires an authenticated, active caller
--   - record_adjustment() additionally requires manager/owner (staff
--     may sell and add stock, but may not arbitrarily adjust it)
--   - changes current_stock with a single atomic UPDATE whose WHERE
--     clause re-checks the stock condition at write time — not from
--     an earlier SELECT — so two concurrent requests against the same
--     limited stock can never both succeed (no lost-update race)
--   - never allows current_stock to go negative (both the UPDATE's
--     WHERE clause and the table's own CHECK constraint enforce this
--     independently — defense in depth)
--   - writes the corresponding ledger row (sales / stock_entries /
--     stock_adjustments) and an activity_logs row, bypassing RLS the
--     same way migration 0006 explained (SECURITY DEFINER, owned by
--     the table-owning role)
-- =====================================================================

-- ---------------------------------------------------------------------
-- record_sale()
-- ---------------------------------------------------------------------
create or replace function public.record_sale(
  p_product_id uuid,
  p_quantity numeric,
  p_device_txn_id uuid
)
returns public.sales
language plpgsql
security definer
set search_path = public
as $$
declare
  v_product public.products;
  v_sale public.sales;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  if not exists (select 1 from public.profiles where id = auth.uid() and is_active) then
    raise exception 'Your account is not active.' using errcode = '42501';
  end if;

  if p_quantity is null or p_quantity <= 0 then
    raise exception 'Quantity must be greater than zero.';
  end if;

  if p_device_txn_id is null then
    raise exception 'Missing transaction id.';
  end if;

  -- Atomic, race-safe stock decrement: the WHERE clause re-checks
  -- sufficient stock and active status at the moment of the update.
  update public.products
  set current_stock = current_stock - p_quantity
  where id = p_product_id
    and is_active
    and current_stock >= p_quantity
  returning * into v_product;

  if not found then
    if exists (select 1 from public.products where id = p_product_id and is_active) then
      raise exception 'Insufficient stock.' using errcode = 'P0001';
    else
      raise exception 'Product not found or inactive.' using errcode = 'P0002';
    end if;
  end if;

  insert into public.sales (product_id, user_id, quantity, unit_price_at_sale, total_amount, device_txn_id)
  values (p_product_id, auth.uid(), p_quantity, v_product.sale_price, v_product.sale_price * p_quantity, p_device_txn_id)
  returning * into v_sale;

  insert into public.activity_logs (actor_id, action, reference_table, reference_id, details)
  values (
    auth.uid(),
    'sale',
    'sales',
    v_sale.id,
    jsonb_build_object(
      'product_id', p_product_id,
      'product_name', v_product.name,
      'quantity', p_quantity,
      'unit_price', v_product.sale_price,
      'total_amount', v_sale.total_amount,
      'remaining_stock', v_product.current_stock
    )
  );

  return v_sale;
end;
$$;

revoke all on function public.record_sale(uuid, numeric, uuid) from public;
revoke execute on function public.record_sale(uuid, numeric, uuid) from anon;
grant execute on function public.record_sale(uuid, numeric, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- record_stock_in()
-- ---------------------------------------------------------------------
create or replace function public.record_stock_in(
  p_product_id uuid,
  p_quantity numeric,
  p_device_txn_id uuid
)
returns public.stock_entries
language plpgsql
security definer
set search_path = public
as $$
declare
  v_product public.products;
  v_entry public.stock_entries;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  if not exists (select 1 from public.profiles where id = auth.uid() and is_active) then
    raise exception 'Your account is not active.' using errcode = '42501';
  end if;

  if p_quantity is null or p_quantity <= 0 then
    raise exception 'Quantity must be greater than zero.';
  end if;

  if p_device_txn_id is null then
    raise exception 'Missing transaction id.';
  end if;

  update public.products
  set current_stock = current_stock + p_quantity
  where id = p_product_id
    and is_active
  returning * into v_product;

  if not found then
    raise exception 'Product not found or inactive.' using errcode = 'P0002';
  end if;

  insert into public.stock_entries (product_id, user_id, quantity, device_txn_id)
  values (p_product_id, auth.uid(), p_quantity, p_device_txn_id)
  returning * into v_entry;

  insert into public.activity_logs (actor_id, action, reference_table, reference_id, details)
  values (
    auth.uid(),
    'stock_in',
    'stock_entries',
    v_entry.id,
    jsonb_build_object(
      'product_id', p_product_id,
      'product_name', v_product.name,
      'quantity', p_quantity,
      'new_stock', v_product.current_stock
    )
  );

  return v_entry;
end;
$$;

revoke all on function public.record_stock_in(uuid, numeric, uuid) from public;
revoke execute on function public.record_stock_in(uuid, numeric, uuid) from anon;
grant execute on function public.record_stock_in(uuid, numeric, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- record_adjustment()
--   Manager/Owner only — staff may sell and add stock, but may not
--   arbitrarily adjust it. quantity_change may be positive or
--   negative; a mandatory reason is always recorded.
-- ---------------------------------------------------------------------
create or replace function public.record_adjustment(
  p_product_id uuid,
  p_quantity_change numeric,
  p_reason text,
  p_device_txn_id uuid
)
returns public.stock_adjustments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_product public.products;
  v_adj public.stock_adjustments;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  if not public.is_manager_or_owner() then
    raise exception 'Only a manager or owner can adjust stock.' using errcode = '42501';
  end if;

  if p_quantity_change is null or p_quantity_change = 0 then
    raise exception 'Adjustment quantity cannot be zero.';
  end if;

  if p_reason is null or btrim(p_reason) = '' then
    raise exception 'A reason is required for stock adjustments.';
  end if;

  if p_device_txn_id is null then
    raise exception 'Missing transaction id.';
  end if;

  update public.products
  set current_stock = current_stock + p_quantity_change
  where id = p_product_id
    and is_active
    and current_stock + p_quantity_change >= 0
  returning * into v_product;

  if not found then
    if exists (select 1 from public.products where id = p_product_id and is_active) then
      raise exception 'Adjustment would result in negative stock.' using errcode = 'P0001';
    else
      raise exception 'Product not found or inactive.' using errcode = 'P0002';
    end if;
  end if;

  insert into public.stock_adjustments (product_id, user_id, quantity_change, reason, device_txn_id)
  values (p_product_id, auth.uid(), p_quantity_change, btrim(p_reason), p_device_txn_id)
  returning * into v_adj;

  insert into public.activity_logs (actor_id, action, reference_table, reference_id, details)
  values (
    auth.uid(),
    'stock_adjustment',
    'stock_adjustments',
    v_adj.id,
    jsonb_build_object(
      'product_id', p_product_id,
      'product_name', v_product.name,
      'quantity_change', p_quantity_change,
      'reason', v_adj.reason,
      'new_stock', v_product.current_stock
    )
  );

  return v_adj;
end;
$$;

revoke all on function public.record_adjustment(uuid, numeric, text, uuid) from public;
revoke execute on function public.record_adjustment(uuid, numeric, text, uuid) from anon;
grant execute on function public.record_adjustment(uuid, numeric, text, uuid) to authenticated;
