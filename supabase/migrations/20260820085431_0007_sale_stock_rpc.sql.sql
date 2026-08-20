-- =====================================================================
-- Phase 2 — Migration 7: Sale & Stock Operations RPC Functions
--
-- sales / stock_entries / stock_adjustments tables exist since Phase 0
-- (migration 0001) but have NO client INSERT policy (migration 0003).
-- These three SECURITY DEFINER functions are the ONLY way a client can
-- record a sale, stock-in, or stock adjustment. Each one:
--   - requires an authenticated caller (auth.uid() read server-side,
--     never passed as a parameter)
--   - validates inputs and raises a clear exception on failure
--   - performs the stock change atomically (UPDATE ... WHERE current_stock
--     >= p_quantity) so negative stock is impossible at the DB level
--   - writes the transaction row and an activity_logs row in the same
--     function, bypassing RLS the same way migration 0006 does
--   - record_adjustment additionally checks is_manager_or_owner()
--
-- current_stock on products is NEVER accepted as a parameter — only
-- incremented/decremented inside these functions.
-- =====================================================================

-- ---------------------------------------------------------------------
-- record_sale()
--   Atomic: decrements current_stock and inserts a sales row in one
--   transaction. If current_stock < p_quantity, the UPDATE affects zero
--   rows and the function raises an insufficient-stock exception.
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
  v_sale     public.sales;
  v_updated  int;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  if p_quantity is null or p_quantity <= 0 then
    raise exception 'Quantity must be greater than zero.';
  end if;

  select * into v_product from public.products where id = p_product_id and is_active;
  if not found then
    raise exception 'Product not found.' using errcode = 'P0002';
  end if;

  -- Atomic decrement: only succeeds if enough stock exists.
  update public.products
    set current_stock = current_stock - p_quantity
    where id = p_product_id and current_stock >= p_quantity
    returning * into v_product;

  get diagnostics v_updated = row_count;
  if v_updated = 0 then
    raise exception 'Insufficient stock. Available: %, Requested: %',
      (select current_stock from public.products where id = p_product_id),
      p_quantity;
  end if;

  insert into public.sales (product_id, user_id, quantity, unit_price_at_sale, total_amount, device_txn_id)
  values (
    p_product_id,
    auth.uid(),
    p_quantity,
    v_product.sale_price,
    v_product.sale_price * p_quantity,
    p_device_txn_id
  )
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
      'total_amount', v_sale.total_amount
    )
  );

  return v_sale;
end;
$$;

revoke all on function public.record_sale(uuid, numeric, uuid) from public;
grant execute on function public.record_sale(uuid, numeric, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- record_stock_in()
--   Atomic: increments current_stock and inserts a stock_entries row.
--   Any authenticated user may stock in (staff receive deliveries too).
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
  v_entry   public.stock_entries;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  if p_quantity is null or p_quantity <= 0 then
    raise exception 'Quantity must be greater than zero.';
  end if;

  select * into v_product from public.products where id = p_product_id and is_active;
  if not found then
    raise exception 'Product not found.' using errcode = 'P0002';
  end if;

  update public.products
    set current_stock = current_stock + p_quantity
    where id = p_product_id
    returning * into v_product;

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
      'quantity', p_quantity
    )
  );

  return v_entry;
end;
$$;

revoke all on function public.record_stock_in(uuid, numeric, uuid) from public;
grant execute on function public.record_stock_in(uuid, numeric, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- record_adjustment()
--   Manager/Owner only. Atomic stock correction with mandatory reason.
--   quantity_change may be positive (add) or negative (remove), but the
--   resulting current_stock can never go negative (CHECK constraint on
--   products + the WHERE clause here).
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
  v_adj     public.stock_adjustments;
  v_updated int;
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

  select * into v_product from public.products where id = p_product_id and is_active;
  if not found then
    raise exception 'Product not found.' using errcode = 'P0002';
  end if;

  -- Atomic: only applies if the result stays >= 0.
  update public.products
    set current_stock = current_stock + p_quantity_change
    where id = p_product_id and current_stock + p_quantity_change >= 0
    returning * into v_product;

  get diagnostics v_updated = row_count;
  if v_updated = 0 then
    raise exception 'Adjustment would make stock negative. Current: %, Change: %',
      (select current_stock from public.products where id = p_product_id),
      p_quantity_change;
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
      'reason', btrim(p_reason)
    )
  );

  return v_adj;
end;
$$;

revoke all on function public.record_adjustment(uuid, numeric, text, uuid) from public;
grant execute on function public.record_adjustment(uuid, numeric, text, uuid) to authenticated;