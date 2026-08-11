-- =====================================================================
-- Phase 1 — Migration 4: Product Photo Storage
--
-- Creates a private Supabase Storage bucket for product photos and
-- the RLS policies governing it.
--
-- DESIGN DECISION — why the bucket is PRIVATE, not public:
--   A "public" Supabase Storage bucket serves objects to anyone with
--   the URL, with no authentication check at all, forever. That is
--   more exposure than this app needs: product photos are only meant
--   to be seen by this shop's 4-5 signed-in staff, not by anyone who
--   guesses or scrapes a URL. Marking the bucket private means every
--   read goes through Storage's own RLS on `storage.objects`, gated
--   to `authenticated` — i.e. only a logged-in shop user can ever
--   fetch a photo, matching the rest of this app's access model.
--   The tradeoff is that the client must request a short-lived signed
--   URL (or download bytes directly) rather than using one permanent
--   public URL — a small extra step handled once in
--   lib/services/product_photo_service.dart, not by every screen.
-- =====================================================================

insert into storage.buckets (id, name, public)
values ('product-photos', 'product-photos', false)
on conflict (id) do nothing;

-- Storage RLS is enabled by default on storage.objects in Supabase;
-- this line is included for explicitness/idempotency and is a no-op
-- if it's already on.
alter table storage.objects enable row level security;

-- Any authenticated shop user may read product photos (needed for the
-- photo-first product grid used by every role, including plain staff
-- for the future Sale/Stock screens).
drop policy if exists product_photos_select_authenticated on storage.objects;
create policy product_photos_select_authenticated
  on storage.objects for select
  to authenticated
  using (bucket_id = 'product-photos');

-- Only Manager/Owner may upload a product photo — mirrors who is
-- allowed to create/edit products via the RPC functions in migration
-- 0006. Plain staff cannot upload here even though they can read.
drop policy if exists product_photos_insert_manager_owner on storage.objects;
create policy product_photos_insert_manager_owner
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'product-photos' and public.is_manager_or_owner());

-- Only Manager/Owner may overwrite/replace a product photo (used when
-- editing an existing product's photo with `upsert: true`).
drop policy if exists product_photos_update_manager_owner on storage.objects;
create policy product_photos_update_manager_owner
  on storage.objects for update
  to authenticated
  using (bucket_id = 'product-photos' and public.is_manager_or_owner())
  with check (bucket_id = 'product-photos' and public.is_manager_or_owner());

-- No DELETE policy — product photos are never deleted from the client
-- in Phase 1 (consistent with never hard-deleting products; an
-- orphaned photo object left behind by, e.g., a cancelled product
-- creation is a low-cost tradeoff documented in the Phase 1 report,
-- not a security concern since it's unreachable without auth).
