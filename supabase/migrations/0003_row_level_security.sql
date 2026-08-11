-- =====================================================================
-- Phase 0 — Migration 3: Row Level Security
--
-- Default-deny: RLS is enabled on every table and NOTHING is
-- accessible until an explicit policy allows it.
--
-- Phase 0 deliberately does NOT allow client INSERT/UPDATE on
-- products, or client INSERT on sales / stock_entries /
-- stock_adjustments — those will only ever be writable via
-- SECURITY DEFINER RPC functions added in a later phase, called with
-- the caller's own auth context so `user_id`/`created_by` can be
-- trusted server-side. This is intentional and matches the safety
-- rules for this phase. (products was corrected to this state after
-- an initial Phase 0 review — see the products section below for why.)
-- =====================================================================

alter table public.profiles           enable row level security;
alter table public.products           enable row level security;
alter table public.sales              enable row level security;
alter table public.stock_entries      enable row level security;
alter table public.stock_adjustments  enable row level security;
alter table public.activity_logs      enable row level security;
alter table public.notifications      enable row level security;

-- ---------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------

-- Users may see their own full profile row, including phone.
drop policy if exists profiles_select_authenticated on public.profiles;
drop policy if exists profiles_select_self on public.profiles;
create policy profiles_select_self
  on public.profiles for select
  to authenticated
  using (id = auth.uid());

-- Owner/Manager may see every profile's full row (including phone) —
-- needed for staff management and contacting staff directly.
drop policy if exists profiles_select_manager_owner on public.profiles;
create policy profiles_select_manager_owner
  on public.profiles for select
  to authenticated
  using (public.is_manager_or_owner());

-- Plain staff do NOT get a blanket SELECT-all-rows policy here, because
-- that would expose every other user's phone number to every staff
-- member for no operational reason. Staff-wise "who did this" name
-- lookups instead go through public.list_profiles_public() (see
-- migration 0002), a SECURITY DEFINER function that returns only
-- id/name/role/is_active — never phone — for all users. This keeps a
-- single source of truth (the profiles table) while narrowing what a
-- non-privileged client can actually read from it.

-- A user may update their own row, EXCEPT role/is_active — enforced by
-- the prevent_self_role_change trigger from migration 0002, not by
-- this policy alone (defense in depth).
drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Only Owner may update ANY profile (used to change other users'
-- role/is_active, e.g. promoting staff to manager or disabling an
-- account). This policy plus profiles_update_self together cover both
-- "edit my own name" and "owner manages the team".
drop policy if exists profiles_update_owner on public.profiles;
create policy profiles_update_owner
  on public.profiles for update
  to authenticated
  using (public.is_owner())
  with check (public.is_owner());

-- Only Owner may directly insert a profile row (normal signups are
-- handled by the handle_new_user trigger; this exists only as an
-- explicit, auditable escape hatch for the Owner, e.g. fixing a
-- missing profile row).
drop policy if exists profiles_insert_owner on public.profiles;
create policy profiles_insert_owner
  on public.profiles for insert
  to authenticated
  with check (public.is_owner());

-- No one may delete a profile from the client — accounts are disabled
-- via is_active, never deleted, to preserve historical attribution.
-- (No delete policy is created, so delete is denied by default.)

-- ---------------------------------------------------------------------
-- products
-- ---------------------------------------------------------------------

drop policy if exists products_select_authenticated on public.products;
create policy products_select_authenticated
  on public.products for select
  to authenticated
  using (true);

-- Phase 0 SECURITY FIX: products is read-only from the client.
--
-- Previously this migration granted Manager/Owner a client-side INSERT
-- and UPDATE policy on products. That was inconsistent with the
-- project's core safety rule: current_stock must never be directly
-- writable by a client, and must only ever change via a future
-- server-side RPC (record_sale / record_stock_in / record_adjustment).
-- Since `current_stock` lives on this same table, any UPDATE policy
-- that lets Manager/Owner edit "just the price" from the client would
-- also, technically, let them edit current_stock directly — defeating
-- that guarantee.
--
-- For Phase 0, product creation and editing (name, price, photo, etc.)
-- are therefore deferred to a later phase, where they will go through
-- a dedicated RPC function too (mirroring the sale/stock pattern),
-- rather than a raw client UPDATE — even though price/name are not
-- stock-critical, this keeps a single consistent write path for the
-- whole table instead of a partial, easy-to-misuse exception.
--
-- No INSERT policy and no UPDATE policy exist for products in Phase 0
-- (intentionally omitted — do not re-add without an RPC in front of
-- current_stock).

-- No delete policy — products are soft-deleted via is_active only,
-- and even that will go through the future RPC/Product Management
-- phase, not a direct client UPDATE.

-- ---------------------------------------------------------------------
-- sales / stock_entries / stock_adjustments
--   Phase 0: read-only schema. No INSERT/UPDATE/DELETE policies exist
--   for any role, including Owner — these tables are intentionally
--   inert until the record_sale / record_stock_in / record_adjustment
--   RPC functions are introduced (later phase). SELECT is allowed now
--   so history/report screens can be built and tested against an
--   empty (correctly-shaped) table.
-- ---------------------------------------------------------------------

drop policy if exists sales_select_manager_owner on public.sales;
create policy sales_select_manager_owner
  on public.sales for select
  to authenticated
  using (public.is_manager_or_owner() or user_id = auth.uid());

drop policy if exists stock_entries_select_manager_owner on public.stock_entries;
create policy stock_entries_select_manager_owner
  on public.stock_entries for select
  to authenticated
  using (public.is_manager_or_owner() or user_id = auth.uid());

drop policy if exists stock_adjustments_select_manager_owner on public.stock_adjustments;
create policy stock_adjustments_select_manager_owner
  on public.stock_adjustments for select
  to authenticated
  using (public.is_manager_or_owner());

-- ---------------------------------------------------------------------
-- activity_logs
--   Immutable: SELECT only. No INSERT/UPDATE/DELETE policy for any
--   role via the client — rows will only ever be written by
--   SECURITY DEFINER RPC functions running with elevated privilege,
--   never by a direct client insert. This guarantees staff (and even
--   Manager/Owner, from the client) cannot silently alter history.
-- ---------------------------------------------------------------------

drop policy if exists activity_logs_select_manager_owner on public.activity_logs;
create policy activity_logs_select_manager_owner
  on public.activity_logs for select
  to authenticated
  using (public.is_manager_or_owner() or actor_id = auth.uid());

-- ---------------------------------------------------------------------
-- notifications
-- ---------------------------------------------------------------------

drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own
  on public.notifications for select
  to authenticated
  using (recipient_id = auth.uid());

-- A user may mark their own notification as read, nothing else.
drop policy if exists notifications_update_own on public.notifications;
create policy notifications_update_own
  on public.notifications for update
  to authenticated
  using (recipient_id = auth.uid())
  with check (recipient_id = auth.uid());

-- No client INSERT policy — notifications are created server-side
-- (future phase) when a sale/stock-in/adjustment/low-stock event fires.
