-- =====================================================================
-- Phase 6 / v1.0 — Migration 12: FCM tokens, notification prefs,
-- stock movement report, staff management RPCs, realtime publication,
-- sync conflict log for Owner/Manager review.
-- =====================================================================

-- ---------------------------------------------------------------------
-- FCM device tokens
-- ---------------------------------------------------------------------
create table if not exists public.fcm_tokens (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  token       text not null,
  platform    text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (user_id, token)
);

create index if not exists idx_fcm_tokens_user on public.fcm_tokens (user_id);

alter table public.fcm_tokens enable row level security;

drop policy if exists fcm_tokens_select_own on public.fcm_tokens;
create policy fcm_tokens_select_own
  on public.fcm_tokens for select to authenticated
  using (user_id = auth.uid());

drop policy if exists fcm_tokens_insert_own on public.fcm_tokens;
create policy fcm_tokens_insert_own
  on public.fcm_tokens for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists fcm_tokens_update_own on public.fcm_tokens;
create policy fcm_tokens_update_own
  on public.fcm_tokens for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists fcm_tokens_delete_own on public.fcm_tokens;
create policy fcm_tokens_delete_own
  on public.fcm_tokens for delete to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- Notification preferences
-- ---------------------------------------------------------------------
create table if not exists public.notification_preferences (
  user_id                   uuid primary key references public.profiles (id) on delete cascade,
  notify_sale               boolean not null default true,
  notify_stock_in           boolean not null default true,
  notify_stock_adjustment   boolean not null default true,
  notify_low_stock          boolean not null default true,
  updated_at                timestamptz not null default now()
);

alter table public.notification_preferences enable row level security;

drop policy if exists notification_preferences_select on public.notification_preferences;
create policy notification_preferences_select
  on public.notification_preferences for select to authenticated
  using (user_id = auth.uid() or public.is_owner());

drop policy if exists notification_preferences_upsert on public.notification_preferences;
create policy notification_preferences_upsert
  on public.notification_preferences for all to authenticated
  using (user_id = auth.uid() or public.is_owner())
  with check (user_id = auth.uid() or public.is_owner());

-- ---------------------------------------------------------------------
-- Sync conflicts (offline replay failures)
-- ---------------------------------------------------------------------
create table if not exists public.sync_conflicts (
  id              uuid primary key default gen_random_uuid(),
  device_txn_id   uuid not null unique,
  actor_id        uuid not null references public.profiles (id),
  action          text not null,
  product_id      uuid references public.products (id),
  details         jsonb not null default '{}'::jsonb,
  resolved        boolean not null default false,
  created_at      timestamptz not null default now()
);

create index if not exists idx_sync_conflicts_open on public.sync_conflicts (resolved, created_at desc);

alter table public.sync_conflicts enable row level security;

drop policy if exists sync_conflicts_select_manager_owner on public.sync_conflicts;
create policy sync_conflicts_select_manager_owner
  on public.sync_conflicts for select to authenticated
  using (public.is_manager_or_owner());

drop policy if exists sync_conflicts_update_manager_owner on public.sync_conflicts;
create policy sync_conflicts_update_manager_owner
  on public.sync_conflicts for update to authenticated
  using (public.is_manager_or_owner())
  with check (public.is_manager_or_owner());

-- ---------------------------------------------------------------------
-- Realtime publication
-- ---------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'products'
  ) then
    alter publication supabase_realtime add table public.products;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'activity_logs'
  ) then
    alter publication supabase_realtime add table public.activity_logs;
  end if;
end
$$;

-- ---------------------------------------------------------------------
-- Notification helper — respect preferences
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
  left join public.notification_preferences np on np.user_id = p.id
  where p.is_active
    and p.role in ('owner', 'manager')
    and (p_exclude_actor is null or p.id <> p_exclude_actor)
    and (
      (p_type = 'sale' and coalesce(np.notify_sale, true))
      or (p_type = 'stock_in' and coalesce(np.notify_stock_in, true))
      or (p_type = 'stock_adjustment' and coalesce(np.notify_stock_adjustment, true))
      or (p_type = 'low_stock' and coalesce(np.notify_low_stock, true))
      or (p_type = 'system')
    );
end;
$$;

-- ---------------------------------------------------------------------
-- register_fcm_token()
-- ---------------------------------------------------------------------
create or replace function public.register_fcm_token(p_token text, p_platform text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;
  if p_token is null or btrim(p_token) = '' then
    raise exception 'Token is required.';
  end if;

  insert into public.fcm_tokens (user_id, token, platform)
  values (auth.uid(), btrim(p_token), p_platform)
  on conflict (user_id, token) do update
    set platform = excluded.platform, updated_at = now();
end;
$$;

revoke all on function public.register_fcm_token(text, text) from public;
revoke execute on function public.register_fcm_token(text, text) from anon;
grant execute on function public.register_fcm_token(text, text) to authenticated;

-- ---------------------------------------------------------------------
-- upsert_notification_preferences()
-- ---------------------------------------------------------------------
create or replace function public.upsert_notification_preferences(
  p_notify_sale boolean,
  p_notify_stock_in boolean,
  p_notify_stock_adjustment boolean,
  p_notify_low_stock boolean,
  p_target_user_id uuid default null
)
returns public.notification_preferences
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_row public.notification_preferences;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  v_user_id := coalesce(p_target_user_id, auth.uid());
  if v_user_id <> auth.uid() and not public.is_owner() then
    raise exception 'Only the owner can change another user''s preferences.' using errcode = '42501';
  end if;

  insert into public.notification_preferences (
    user_id, notify_sale, notify_stock_in, notify_stock_adjustment, notify_low_stock
  )
  values (v_user_id, p_notify_sale, p_notify_stock_in, p_notify_stock_adjustment, p_notify_low_stock)
  on conflict (user_id) do update
    set notify_sale = excluded.notify_sale,
        notify_stock_in = excluded.notify_stock_in,
        notify_stock_adjustment = excluded.notify_stock_adjustment,
        notify_low_stock = excluded.notify_low_stock,
        updated_at = now()
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.upsert_notification_preferences(boolean, boolean, boolean, boolean, uuid) from public;
revoke execute on function public.upsert_notification_preferences(boolean, boolean, boolean, boolean, uuid) from anon;
grant execute on function public.upsert_notification_preferences(boolean, boolean, boolean, boolean, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- get_notification_preferences()
-- ---------------------------------------------------------------------
create or replace function public.get_notification_preferences(p_target_user_id uuid default null)
returns public.notification_preferences
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_row public.notification_preferences;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  v_user_id := coalesce(p_target_user_id, auth.uid());
  if v_user_id <> auth.uid() and not public.is_owner() then
    raise exception 'Not allowed.' using errcode = '42501';
  end if;

  select * into v_row from public.notification_preferences where user_id = v_user_id;
  if not found then
    insert into public.notification_preferences (user_id)
    values (v_user_id)
    on conflict (user_id) do nothing
    returning * into v_row;
    if v_row is null then
      select * into v_row from public.notification_preferences where user_id = v_user_id;
    end if;
  end if;
  return v_row;
end;
$$;

revoke all on function public.get_notification_preferences(uuid) from public;
revoke execute on function public.get_notification_preferences(uuid) from anon;
grant execute on function public.get_notification_preferences(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- get_stock_movement_report()
-- ---------------------------------------------------------------------
create or replace function public.get_stock_movement_report(
  p_from timestamptz,
  p_to timestamptz,
  p_product_id uuid default null
)
returns table (
  movement_type text,
  reference_id uuid,
  product_id uuid,
  product_name text,
  user_id uuid,
  user_name text,
  quantity numeric,
  quantity_change numeric,
  reason text,
  amount numeric,
  created_at timestamptz
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
  select * from (
    select 'sale'::text, s.id, s.product_id, pr.name, s.user_id, pf.name,
           s.quantity, -s.quantity, null::text, s.total_amount, s.created_at
    from public.sales s
    join public.products pr on pr.id = s.product_id
    join public.profiles pf on pf.id = s.user_id
    where s.created_at >= p_from and s.created_at < p_to
      and (p_product_id is null or s.product_id = p_product_id)
    union all
    select 'stock_in'::text, e.id, e.product_id, pr.name, e.user_id, pf.name,
           e.quantity, e.quantity, null::text, null::numeric, e.created_at
    from public.stock_entries e
    join public.products pr on pr.id = e.product_id
    join public.profiles pf on pf.id = e.user_id
    where e.created_at >= p_from and e.created_at < p_to
      and (p_product_id is null or e.product_id = p_product_id)
    union all
    select 'stock_adjustment'::text, a.id, a.product_id, pr.name, a.user_id, pf.name,
           abs(a.quantity_change), a.quantity_change, a.reason, null::numeric, a.created_at
    from public.stock_adjustments a
    join public.products pr on pr.id = a.product_id
    join public.profiles pf on pf.id = a.user_id
    where a.created_at >= p_from and a.created_at < p_to
      and (p_product_id is null or a.product_id = p_product_id)
  ) m
  order by created_at desc;
end;
$$;

revoke all on function public.get_stock_movement_report(timestamptz, timestamptz, uuid) from public;
revoke execute on function public.get_stock_movement_report(timestamptz, timestamptz, uuid) from anon;
grant execute on function public.get_stock_movement_report(timestamptz, timestamptz, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- Staff management (Owner only)
-- ---------------------------------------------------------------------
create or replace function public.list_staff_profiles()
returns table (id uuid, name text, role user_role, is_active boolean, created_at timestamptz, updated_at timestamptz)
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_owner() then
    raise exception 'Only the owner can list staff.' using errcode = '42501';
  end if;
  return query
  select p.id, p.name, p.role, p.is_active, p.created_at, p.updated_at
  from public.profiles p order by p.name;
end;
$$;

create or replace function public.update_staff_role(p_user_id uuid, p_role user_role)
returns public.profiles
language plpgsql security definer set search_path = public
as $$
declare v_profile public.profiles;
begin
  if not public.is_owner() then raise exception 'Only the owner can change roles.' using errcode = '42501'; end if;
  if p_user_id = auth.uid() then raise exception 'You cannot change your own role.' using errcode = '42501'; end if;
  update public.profiles set role = p_role where id = p_user_id returning * into v_profile;
  if not found then raise exception 'User not found.' using errcode = 'P0002'; end if;
  insert into public.activity_logs (actor_id, action, reference_table, reference_id, details)
  values (auth.uid(), 'user_role_changed', 'profiles', p_user_id, jsonb_build_object('new_role', p_role::text));
  return v_profile;
end;
$$;

create or replace function public.set_staff_active(p_user_id uuid, p_is_active boolean)
returns public.profiles
language plpgsql security definer set search_path = public
as $$
declare v_profile public.profiles;
begin
  if not public.is_owner() then raise exception 'Only the owner can activate/deactivate staff.' using errcode = '42501'; end if;
  if p_user_id = auth.uid() then raise exception 'You cannot deactivate yourself.' using errcode = '42501'; end if;
  update public.profiles set is_active = p_is_active where id = p_user_id returning * into v_profile;
  if not found then raise exception 'User not found.' using errcode = 'P0002'; end if;
  insert into public.activity_logs (actor_id, action, reference_table, reference_id, details)
  values (auth.uid(), case when p_is_active then 'user_created' else 'user_deactivated' end,
          'profiles', p_user_id, jsonb_build_object('is_active', p_is_active));
  return v_profile;
end;
$$;

revoke all on function public.list_staff_profiles() from public;
revoke execute on function public.list_staff_profiles() from anon;
grant execute on function public.list_staff_profiles() to authenticated;

revoke all on function public.update_staff_role(uuid, user_role) from public;
revoke execute on function public.update_staff_role(uuid, user_role) from anon;
grant execute on function public.update_staff_role(uuid, user_role) to authenticated;

revoke all on function public.set_staff_active(uuid, boolean) from public;
revoke execute on function public.set_staff_active(uuid, boolean) from anon;
grant execute on function public.set_staff_active(uuid, boolean) to authenticated;

-- ---------------------------------------------------------------------
-- list_low_stock_products() — manager/owner
-- ---------------------------------------------------------------------
create or replace function public.list_low_stock_products()
returns setof public.products
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_manager_or_owner() then
    raise exception 'Only a manager or owner can view low-stock alerts.' using errcode = '42501';
  end if;
  return query
  select * from public.products
  where is_active and low_stock_limit > 0 and current_stock <= low_stock_limit
  order by current_stock asc, name;
end;
$$;

revoke all on function public.list_low_stock_products() from public;
revoke execute on function public.list_low_stock_products() from anon;
grant execute on function public.list_low_stock_products() to authenticated;

-- ---------------------------------------------------------------------
-- list_sync_conflicts() / resolve_sync_conflict()
-- ---------------------------------------------------------------------
create or replace function public.list_sync_conflicts(p_include_resolved boolean default false)
returns setof public.sync_conflicts
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_manager_or_owner() then
    raise exception 'Only a manager or owner can view sync conflicts.' using errcode = '42501';
  end if;
  return query
  select * from public.sync_conflicts
  where p_include_resolved or not resolved
  order by created_at desc;
end;
$$;

create or replace function public.resolve_sync_conflict(p_conflict_id uuid)
returns public.sync_conflicts
language plpgsql security definer set search_path = public
as $$
declare v_row public.sync_conflicts;
begin
  if not public.is_manager_or_owner() then
    raise exception 'Only a manager or owner can resolve conflicts.' using errcode = '42501';
  end if;
  update public.sync_conflicts set resolved = true where id = p_conflict_id returning * into v_row;
  if not found then raise exception 'Conflict not found.' using errcode = 'P0002'; end if;
  return v_row;
end;
$$;

revoke all on function public.list_sync_conflicts(boolean) from public;
revoke execute on function public.list_sync_conflicts(boolean) from anon;
grant execute on function public.list_sync_conflicts(boolean) to authenticated;

revoke all on function public.resolve_sync_conflict(uuid) from public;
revoke execute on function public.resolve_sync_conflict(uuid) from anon;
grant execute on function public.resolve_sync_conflict(uuid) to authenticated;
