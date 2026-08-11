-- =====================================================================
-- Phase 0 — Migration 1: Core Schema
-- Shop Stock & Sales Management App
--
-- Creates: enums, profiles, products, sales, stock_entries,
--          stock_adjustments, activity_logs, notifications
--
-- IMPORTANT (Phase 0 scope):
--   - No rows are seeded. No fake transactions are created.
--   - sales / stock_entries / stock_adjustments tables exist so the
--     schema is ready, but NOTHING may insert into them yet — that is
--     wired up in a later phase via SECURITY DEFINER RPC functions.
--   - stock_quantity can never go negative: enforced by a CHECK
--     constraint at the database level (defense in depth, independent
--     of any application-level check that will be added later).
-- =====================================================================

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- ENUMS
-- ---------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'user_role') then
    create type user_role as enum ('owner', 'manager', 'staff');
  end if;

  if not exists (select 1 from pg_type where typname = 'activity_action') then
    create type activity_action as enum (
      'sale',
      'stock_in',
      'stock_adjustment',
      'product_created',
      'product_updated',
      'price_updated',
      'user_created',
      'user_role_changed',
      'user_deactivated'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'notification_type') then
    create type notification_type as enum (
      'sale', 'stock_in', 'stock_adjustment', 'low_stock', 'system'
    );
  end if;
end
$$;

-- ---------------------------------------------------------------------
-- profiles
--   One row per auth.users row. Created automatically by a trigger
--   (see 0003_helper_functions.sql) — never created directly by the app.
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  name        text not null,
  phone       text,
  role        user_role not null default 'staff',
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

comment on table public.profiles is
  'One profile per authenticated user. Role changes must go through a privileged path, never a self-update.';

-- ---------------------------------------------------------------------
-- products
-- ---------------------------------------------------------------------
create table if not exists public.products (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,
  photo_url        text,
  photo_thumb_url  text,
  company          text,
  category         text,
  pack_size        text,
  mrp              numeric(12, 2) check (mrp is null or mrp >= 0),
  purchase_price   numeric(12, 2) check (purchase_price is null or purchase_price >= 0),
  sale_price       numeric(12, 2) not null check (sale_price >= 0),
  current_stock    numeric(12, 3) not null default 0 check (current_stock >= 0),
  low_stock_limit  numeric(12, 3) not null default 0 check (low_stock_limit >= 0),
  is_active        boolean not null default true,
  created_by       uuid not null references public.profiles (id),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

comment on table public.products is
  'current_stock is authoritative and MUST only ever be changed by the server-side sale/stock-in/adjustment RPC functions added in a later phase — never by a direct client UPDATE.';

create index if not exists idx_products_name on public.products using gin (to_tsvector('simple', name));
create index if not exists idx_products_is_active on public.products (is_active);
create index if not exists idx_products_low_stock on public.products (current_stock, low_stock_limit);

-- ---------------------------------------------------------------------
-- sales  (schema only in Phase 0 — no INSERT permitted yet, see RLS)
-- ---------------------------------------------------------------------
create table if not exists public.sales (
  id                    uuid primary key default gen_random_uuid(),
  product_id            uuid not null references public.products (id),
  user_id               uuid not null references public.profiles (id),
  quantity              numeric(12, 3) not null check (quantity > 0),
  unit_price_at_sale    numeric(12, 2) not null check (unit_price_at_sale >= 0),
  total_amount          numeric(14, 2) not null check (total_amount >= 0),
  device_txn_id         uuid not null unique,
  created_at            timestamptz not null default now()
);

comment on table public.sales is
  'Append-only. Rows are created exclusively by the future record_sale() RPC function, never directly by clients.';

create index if not exists idx_sales_product on public.sales (product_id);
create index if not exists idx_sales_user on public.sales (user_id);
create index if not exists idx_sales_created_at on public.sales (created_at);

-- ---------------------------------------------------------------------
-- stock_entries  (schema only in Phase 0)
-- ---------------------------------------------------------------------
create table if not exists public.stock_entries (
  id              uuid primary key default gen_random_uuid(),
  product_id      uuid not null references public.products (id),
  user_id         uuid not null references public.profiles (id),
  quantity        numeric(12, 3) not null check (quantity > 0),
  device_txn_id   uuid not null unique,
  created_at      timestamptz not null default now()
);

comment on table public.stock_entries is
  'Append-only. Rows are created exclusively by the future record_stock_in() RPC function.';

create index if not exists idx_stock_entries_product on public.stock_entries (product_id);
create index if not exists idx_stock_entries_user on public.stock_entries (user_id);
create index if not exists idx_stock_entries_created_at on public.stock_entries (created_at);

-- ---------------------------------------------------------------------
-- stock_adjustments  (schema only in Phase 0)
-- ---------------------------------------------------------------------
create table if not exists public.stock_adjustments (
  id                uuid primary key default gen_random_uuid(),
  product_id        uuid not null references public.products (id),
  user_id           uuid not null references public.profiles (id),
  quantity_change   numeric(12, 3) not null check (quantity_change <> 0),
  reason            text not null check (char_length(btrim(reason)) > 0),
  device_txn_id     uuid not null unique,
  created_at        timestamptz not null default now()
);

comment on table public.stock_adjustments is
  'Append-only. Rows are created exclusively by the future record_adjustment() RPC function. Reason is mandatory.';

create index if not exists idx_stock_adjustments_product on public.stock_adjustments (product_id);
create index if not exists idx_stock_adjustments_user on public.stock_adjustments (user_id);
create index if not exists idx_stock_adjustments_created_at on public.stock_adjustments (created_at);

-- ---------------------------------------------------------------------
-- activity_logs  (immutable audit trail)
-- ---------------------------------------------------------------------
create table if not exists public.activity_logs (
  id                uuid primary key default gen_random_uuid(),
  actor_id          uuid not null references public.profiles (id),
  action            activity_action not null,
  reference_table   text,
  reference_id      uuid,
  details            jsonb not null default '{}'::jsonb,
  created_at        timestamptz not null default now()
);

comment on table public.activity_logs is
  'Immutable audit trail. INSERT-only for the whole application — no UPDATE or DELETE is permitted by RLS for any role, including owner.';

create index if not exists idx_activity_logs_actor on public.activity_logs (actor_id);
create index if not exists idx_activity_logs_action on public.activity_logs (action);
create index if not exists idx_activity_logs_created_at on public.activity_logs (created_at);

-- ---------------------------------------------------------------------
-- notifications
-- ---------------------------------------------------------------------
create table if not exists public.notifications (
  id            uuid primary key default gen_random_uuid(),
  recipient_id  uuid not null references public.profiles (id),
  type          notification_type not null,
  message       text not null,
  read          boolean not null default false,
  created_at    timestamptz not null default now()
);

create index if not exists idx_notifications_recipient on public.notifications (recipient_id, read);
