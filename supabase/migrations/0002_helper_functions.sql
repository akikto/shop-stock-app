-- =====================================================================
-- Phase 0 — Migration 2: Helper Functions & Triggers
-- =====================================================================

-- ---------------------------------------------------------------------
-- updated_at auto-touch trigger (generic, reused by profiles/products)
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists trg_products_updated_at on public.products;
create trigger trg_products_updated_at
  before update on public.products
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- current_user_role(): reads the caller's role without recursive RLS
-- lookups. SECURITY DEFINER + fixed search_path so it can be safely
-- used inside RLS policies.
-- ---------------------------------------------------------------------
create or replace function public.current_user_role()
returns user_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.is_owner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select role from public.profiles where id = auth.uid()) = 'owner', false);
$$;

create or replace function public.is_manager_or_owner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select role from public.profiles where id = auth.uid()) in ('owner', 'manager'),
    false
  );
$$;

-- ---------------------------------------------------------------------
-- handle_new_user(): automatically creates a profile row whenever a
-- new auth.users row is created (e.g. when the Owner invites a staff
-- member). Default role is 'staff' — role must be elevated afterwards
-- by an Owner through a privileged update, never by the user.
-- ---------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name, role, is_active)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', 'New User'),
    'staff',
    true
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists trg_on_auth_user_created on auth.users;
create trigger trg_on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------
-- prevent_self_role_change(): blocks a user from changing their own
-- role or is_active flag, even if some future policy accidentally
-- allows a self-UPDATE on profiles. Owners change other users' roles
-- through a normal UPDATE (allowed by RLS in migration 0003) — this
-- trigger only stops someone editing their OWN row's role/is_active.
-- ---------------------------------------------------------------------
create or replace function public.prevent_self_role_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.id = auth.uid() then
    if new.role is distinct from old.role then
      raise exception 'You cannot change your own role.';
    end if;
    if new.is_active is distinct from old.is_active then
      raise exception 'You cannot change your own active status.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_prevent_self_role_change on public.profiles;
create trigger trg_prevent_self_role_change
  before update on public.profiles
  for each row execute function public.prevent_self_role_change();

-- ---------------------------------------------------------------------
-- list_profiles_public(): returns id/name/role/is_active for every
-- user — deliberately EXCLUDING phone.
--
-- Why this exists: plain staff need to see who did what (e.g. "Karim
-- sold 3x Rice") for future history/attribution screens, but have no
-- operational reason to see every colleague's phone number. Postgres
-- RLS is row-level, not column-level, so the profiles table's SELECT
-- policies (migration 0003) intentionally only let a non-privileged
-- user read their OWN full row. This SECURITY DEFINER function is the
-- narrow, explicit exception: it bypasses RLS internally but only
-- ever returns the four non-sensitive columns, for any authenticated
-- caller. Owner/Manager can still see full rows including phone via
-- the normal `profiles_select_manager_owner` policy when they need to
-- actually contact a staff member.
-- ---------------------------------------------------------------------
create or replace function public.list_profiles_public()
returns table (
  id          uuid,
  name        text,
  role        user_role,
  is_active   boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select id, name, role, is_active
  from public.profiles
  order by name;
$$;

-- Explicitly restrict who can call it: authenticated shop users only,
-- never the anonymous/public role.
revoke all on function public.list_profiles_public() from public;
grant execute on function public.list_profiles_public() to authenticated;
