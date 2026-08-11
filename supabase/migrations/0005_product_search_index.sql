-- =====================================================================
-- Phase 1 — Migration 5: Product Search Index
--
-- Partial-name search (e.g. typing "para" must find "Paracetamol
-- 500 mg") is implemented client-side as an ILIKE '%term%' query
-- against products.name. A plain ILIKE with a leading wildcard cannot
-- use a normal B-tree index, so as the product catalog grows this
-- would slow down — pg_trgm's trigram GIN index is the standard
-- Postgres way to keep substring search fast at scale without
-- introducing a separate search service.
-- =====================================================================

create extension if not exists pg_trgm;

create index if not exists idx_products_name_trgm
  on public.products
  using gin (name gin_trgm_ops);
