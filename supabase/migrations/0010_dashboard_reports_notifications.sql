-- =====================================================================
-- Phase 4 — Migration 10: Dashboard, Reports, In-App Notifications
--
-- Adds:
--   - Server-side notification creation on sale / stock-in / adjustment
--   - Low-stock alerts when stock crosses below the limit
--   - Role-aware dashboard stats RPC
--   - Staff-wise and product-wise sales report RPCs (manager/owner)
-- =====================================================================

-- ---------------------------------------------------------------------
-- Internal: notify all active managers and owners (except optional actor)
-- ---------------------------------------------------------------------
create or replace function public._notify_managers_owners(
  p_type notification_type,
  p_message text,
  p_exclude_actor uuid default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (recipient_id, type, message)
  select p.id, p_type, p_message
  from public.profiles p
  where p.is_active
    and p.role in ('owner', 'manager')
    and (p_exclude_actor is null or p.id <> p_exclude_actor);
end;
$$;

revoke all on function public._notify_managers_owners(notification_type, text, uuid) from public;

-- ---------------------------------------------------------------------
-- Internal: low-stock alert when stock is at or below the limit
-- ---------------------------------------------------------------------
create or replace function public._maybe_notify_low_stock(p_product public.products)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_product.low_stock_limit > 0
     and p_product.current_stock <= p_product.low_stock_limit
     and p_product.is_active then
    perform public._notify_managers_owners(
      'low_stock',
      format('Low stock: %s (%s remaining)', p_product.name, p_product.current_stock)
    );
  end if;
end;
$$;

revoke all on function public._maybe_notify_low_stock(public.products) from public;

-- ---------------------------------------------------------------------
-- record_sale() — add notifications + low-stock check
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
-- record_stock_in() — add notifications
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
-- record_adjustment() — add notifications + low-stock check
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

-- ---------------------------------------------------------------------
-- get_dashboard_stats()
--   Staff: own sales in the date range.
--   Manager/Owner: shop-wide totals + low-stock product count.
-- ---------------------------------------------------------------------
create or replace function public.get_dashboard_stats(
  p_from timestamptz,
  p_to timestamptz
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  if not exists (select 1 from public.profiles where id = auth.uid() and is_active) then
    raise exception 'Your account is not active.' using errcode = '42501';
  end if;

  if p_from is null or p_to is null or p_from >= p_to then
    raise exception 'Invalid date range.';
  end if;

  if public.is_manager_or_owner() then
    select jsonb_build_object(
      'role_scope', 'shop',
      'sale_count', coalesce((select count(*)::int from public.sales where created_at >= p_from and created_at < p_to), 0),
      'total_sales_amount', coalesce((select sum(total_amount) from public.sales where created_at >= p_from and created_at < p_to), 0),
      'stock_in_count', coalesce((select count(*)::int from public.stock_entries where created_at >= p_from and created_at < p_to), 0),
      'adjustment_count', coalesce((select count(*)::int from public.stock_adjustments where created_at >= p_from and created_at < p_to), 0),
      'low_stock_count', coalesce((
        select count(*)::int from public.products
        where is_active and low_stock_limit > 0 and current_stock <= low_stock_limit
      ), 0)
    ) into v_result;
  else
    select jsonb_build_object(
      'role_scope', 'self',
      'sale_count', coalesce((select count(*)::int from public.sales where user_id = auth.uid() and created_at >= p_from and created_at < p_to), 0),
      'total_sales_amount', coalesce((select sum(total_amount) from public.sales where user_id = auth.uid() and created_at >= p_from and created_at < p_to), 0),
      'stock_in_count', coalesce((select count(*)::int from public.stock_entries where user_id = auth.uid() and created_at >= p_from and created_at < p_to), 0),
      'adjustment_count', 0,
      'low_stock_count', 0
    ) into v_result;
  end if;

  return v_result;
end;
$$;

revoke all on function public.get_dashboard_stats(timestamptz, timestamptz) from public;
revoke execute on function public.get_dashboard_stats(timestamptz, timestamptz) from anon;
grant execute on function public.get_dashboard_stats(timestamptz, timestamptz) to authenticated;

-- ---------------------------------------------------------------------
-- get_staff_sales_report() — manager/owner only
-- ---------------------------------------------------------------------
create or replace function public.get_staff_sales_report(
  p_from timestamptz,
  p_to timestamptz
)
returns table (
  user_id uuid,
  user_name text,
  sale_count bigint,
  total_amount numeric
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  if not public.is_manager_or_owner() then
    raise exception 'Only a manager or owner can view reports.' using errcode = '42501';
  end if;

  if p_from is null or p_to is null or p_from >= p_to then
    raise exception 'Invalid date range.';
  end if;

  return query
  select
    s.user_id,
    p.name as user_name,
    count(*)::bigint as sale_count,
    coalesce(sum(s.total_amount), 0) as total_amount
  from public.sales s
  join public.profiles p on p.id = s.user_id
  where s.created_at >= p_from
    and s.created_at < p_to
  group by s.user_id, p.name
  order by total_amount desc, user_name;
end;
$$;

revoke all on function public.get_staff_sales_report(timestamptz, timestamptz) from public;
revoke execute on function public.get_staff_sales_report(timestamptz, timestamptz) from anon;
grant execute on function public.get_staff_sales_report(timestamptz, timestamptz) to authenticated;

-- ---------------------------------------------------------------------
-- get_product_sales_report() — manager/owner only
-- ---------------------------------------------------------------------
create or replace function public.get_product_sales_report(
  p_from timestamptz,
  p_to timestamptz
)
returns table (
  product_id uuid,
  product_name text,
  sale_count bigint,
  total_quantity numeric,
  total_amount numeric
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  if not public.is_manager_or_owner() then
    raise exception 'Only a manager or owner can view reports.' using errcode = '42501';
  end if;

  if p_from is null or p_to is null or p_from >= p_to then
    raise exception 'Invalid date range.';
  end if;

  return query
  select
    s.product_id,
    pr.name as product_name,
    count(*)::bigint as sale_count,
    coalesce(sum(s.quantity), 0) as total_quantity,
    coalesce(sum(s.total_amount), 0) as total_amount
  from public.sales s
  join public.products pr on pr.id = s.product_id
  where s.created_at >= p_from
    and s.created_at < p_to
  group by s.product_id, pr.name
  order by total_amount desc, product_name;
end;
$$;

revoke all on function public.get_product_sales_report(timestamptz, timestamptz) from public;
revoke execute on function public.get_product_sales_report(timestamptz, timestamptz) from anon;
grant execute on function public.get_product_sales_report(timestamptz, timestamptz) to authenticated;
