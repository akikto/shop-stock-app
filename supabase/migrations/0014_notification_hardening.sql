-- =====================================================================
-- Phase 5C — Migration 14: Notification UPDATE restriction + low-stock
-- threshold-crossing deduplication
--
-- 1. RPC-only mark-as-read (no client UPDATE on notifications)
-- 2. Low-stock alerts only when stock crosses INTO low state
--    (previous_stock > limit AND new_stock <= limit)
--
-- Forward-only. No data migration. No new tables.
-- Rollback: restore 0011 record_sale/record_adjustment bodies,
--           re-create notifications_update_own policy, drop RPCs.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Migration #1: secure mark-as-read RPCs
-- ---------------------------------------------------------------------
create or replace function public.mark_notification_read(p_notification_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  if p_notification_id is null then
    raise exception 'Notification id is required.';
  end if;

  update public.notifications
  set read = true
  where id = p_notification_id
    and recipient_id = v_uid;

  if not found then
    raise exception 'Notification not found.' using errcode = 'P0002';
  end if;
end;
$$;

create or replace function public.mark_all_notifications_read()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  update public.notifications
  set read = true
  where recipient_id = v_uid
    and read = false;
end;
$$;

revoke all on function public.mark_notification_read(uuid) from public;
revoke execute on function public.mark_notification_read(uuid) from anon;
grant execute on function public.mark_notification_read(uuid) to authenticated;

revoke all on function public.mark_all_notifications_read() from public;
revoke execute on function public.mark_all_notifications_read() from anon;
grant execute on function public.mark_all_notifications_read() to authenticated;

-- Remove direct client UPDATE on notifications (RPC is the only mutation path).
drop policy if exists notifications_update_own on public.notifications;
revoke update on table public.notifications from authenticated;
revoke update on table public.notifications from anon;

-- ---------------------------------------------------------------------
-- Migration #2: threshold-crossing low-stock notifications
-- ---------------------------------------------------------------------
drop function if exists public._maybe_notify_low_stock(public.products);

create or replace function public._maybe_notify_low_stock(
  p_product public.products,
  p_previous_stock numeric
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_product.low_stock_limit > 0
     and p_product.is_active
     and p_previous_stock > p_product.low_stock_limit
     and p_product.current_stock <= p_product.low_stock_limit then
    perform public._notify_managers_owners(
      'low_stock',
      format(
        'Low stock: %s (%s remaining)',
        p_product.name,
        p_product.current_stock
      )
    );
  end if;
end;
$$;

revoke all on function public._maybe_notify_low_stock(public.products, numeric) from public;

-- ---------------------------------------------------------------------
-- record_sale() — row lock for previous stock + threshold crossing
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
  v_previous_stock numeric;
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

  select current_stock into v_previous_stock
  from public.products
  where id = p_product_id
    and is_active
    and current_stock >= p_quantity
  for update;

  if not found then
    if exists (select 1 from public.products where id = p_product_id and is_active) then
      raise exception 'Insufficient stock.' using errcode = 'P0001';
    else
      raise exception 'Product not found or inactive.' using errcode = 'P0002';
    end if;
  end if;

  update public.products
  set current_stock = v_previous_stock - p_quantity
  where id = p_product_id
  returning * into v_product;

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

  perform public._maybe_notify_low_stock(v_product, v_previous_stock);

  return v_sale;
end;
$$;

-- ---------------------------------------------------------------------
-- record_adjustment() — row lock for previous stock + threshold crossing
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
  v_previous_stock numeric;
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

  select current_stock into v_previous_stock
  from public.products
  where id = p_product_id
    and is_active
    and current_stock + p_quantity_change >= 0
  for update;

  if not found then
    if exists (select 1 from public.products where id = p_product_id and is_active) then
      raise exception 'Adjustment would result in negative stock.' using errcode = 'P0001';
    else
      raise exception 'Product not found or inactive.' using errcode = 'P0002';
    end if;
  end if;

  update public.products
  set current_stock = v_previous_stock + p_quantity_change
  where id = p_product_id
  returning * into v_product;

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

  perform public._maybe_notify_low_stock(v_product, v_previous_stock);

  return v_adj;
end;
$$;
