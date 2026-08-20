-- =====================================================================
-- Phase 5 — Migration 11: Offline Sync Idempotency
--
-- Makes record_sale(), record_stock_in(), and record_adjustment()
-- safe to replay with the same device_txn_id (offline sync queue).
--
-- For each function:
--   - Validates auth/role/business rules as before (migration 0010).
--   - Uses a transaction-scoped advisory lock on device_txn_id so two
--     concurrent replays cannot both mutate stock.
--   - If device_txn_id already exists in the ledger table, returns the
--     existing row WITHOUT changing current_stock.
--   - On unique_violation race on insert, returns the existing row.
--
-- No new tables. No new RLS policies. No client INSERT on ledger tables.
-- =====================================================================

-- ---------------------------------------------------------------------
-- record_sale() — idempotent replay
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
  v_actor_name text;
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

  perform pg_advisory_xact_lock(hashtext(p_device_txn_id::text));

  select * into v_sale from public.sales where device_txn_id = p_device_txn_id;
  if found then
    return v_sale;
  end if;

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

  begin
    insert into public.sales (product_id, user_id, quantity, unit_price_at_sale, total_amount, device_txn_id)
    values (p_product_id, auth.uid(), p_quantity, v_product.sale_price, v_product.sale_price * p_quantity, p_device_txn_id)
    returning * into v_sale;
  exception
    when unique_violation then
      select * into v_sale from public.sales where device_txn_id = p_device_txn_id;
      if found then
        return v_sale;
      end if;
      raise;
  end;

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

  select name into v_actor_name from public.profiles where id = auth.uid();

  perform public._notify_managers_owners(
    'sale',
    format('Sale: %s sold %s x %s (৳%s)', coalesce(v_actor_name, 'Staff'), p_quantity, v_product.name, v_sale.total_amount),
    auth.uid()
  );

  perform public._maybe_notify_low_stock(v_product);

  return v_sale;
end;
$$;

-- ---------------------------------------------------------------------
-- record_stock_in() — idempotent replay
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
  v_actor_name text;
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

  perform pg_advisory_xact_lock(hashtext(p_device_txn_id::text));

  select * into v_entry from public.stock_entries where device_txn_id = p_device_txn_id;
  if found then
    return v_entry;
  end if;

  update public.products
  set current_stock = current_stock + p_quantity
  where id = p_product_id
    and is_active
  returning * into v_product;

  if not found then
    raise exception 'Product not found or inactive.' using errcode = 'P0002';
  end if;

  begin
    insert into public.stock_entries (product_id, user_id, quantity, device_txn_id)
    values (p_product_id, auth.uid(), p_quantity, p_device_txn_id)
    returning * into v_entry;
  exception
    when unique_violation then
      select * into v_entry from public.stock_entries where device_txn_id = p_device_txn_id;
      if found then
        return v_entry;
      end if;
      raise;
  end;

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

  select name into v_actor_name from public.profiles where id = auth.uid();

  perform public._notify_managers_owners(
    'stock_in',
    format('Stock in: %s added %s x %s', coalesce(v_actor_name, 'Staff'), p_quantity, v_product.name),
    auth.uid()
  );

  return v_entry;
end;
$$;

-- ---------------------------------------------------------------------
-- record_adjustment() — idempotent replay
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
  v_actor_name text;
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

  perform pg_advisory_xact_lock(hashtext(p_device_txn_id::text));

  select * into v_adj from public.stock_adjustments where device_txn_id = p_device_txn_id;
  if found then
    return v_adj;
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

  begin
    insert into public.stock_adjustments (product_id, user_id, quantity_change, reason, device_txn_id)
    values (p_product_id, auth.uid(), p_quantity_change, btrim(p_reason), p_device_txn_id)
    returning * into v_adj;
  exception
    when unique_violation then
      select * into v_adj from public.stock_adjustments where device_txn_id = p_device_txn_id;
      if found then
        return v_adj;
      end if;
      raise;
  end;

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

  select name into v_actor_name from public.profiles where id = auth.uid();

  perform public._notify_managers_owners(
    'stock_adjustment',
    format('Adjustment: %s changed %s by %s (%s)', coalesce(v_actor_name, 'Manager'), v_product.name, p_quantity_change, btrim(p_reason)),
    auth.uid()
  );

  perform public._maybe_notify_low_stock(v_product);

  return v_adj;
end;
$$;
