-- =====================================================================
-- Phase 1 — Migration 7: Fix update_product() activity_action cast bug
--
-- BUG: update_product()'s activity_logs insert used
--   case when v_price_changed then 'price_updated' else 'product_updated' end
-- as the `action` value. Postgres resolves a CASE expression's own
-- result type (here: text) BEFORE attempting to coerce it into the
-- INSERT target column's type (activity_action), unlike a plain
-- literal, which Postgres coerces directly against the target column
-- type. This caused every product edit to fail with:
--   "column "action" is of type activity_action but expression is of
--    type text"
--
-- FIX: cast the CASE expression's result to activity_action
-- explicitly. Both branch values ('price_updated', 'product_updated')
-- are pre-existing, verified members of the activity_action enum
-- (defined in migration 0001) — this is not a new/invented value.
--
-- This migration only redefines update_product(). create_product()
-- and deactivate_product() already insert plain literals directly
-- (no CASE expression), which Postgres coerces correctly on its own,
-- and are therefore untouched here. No table, column, or RLS change.
-- =====================================================================

create or replace function public.update_product(
  p_id uuid,
  p_name text,
  p_photo_url text default null,
  p_photo_thumb_url text default null,
  p_company text default null,
  p_category text default null,
  p_pack_size text default null,
  p_mrp numeric default null,
  p_purchase_price numeric default null,
  p_sale_price numeric default 0,
  p_low_stock_limit numeric default 0
)
returns public.products
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old public.products;
  v_new public.products;
  v_price_changed boolean;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  if not public.is_manager_or_owner() then
    raise exception 'Only a manager or owner can update products.' using errcode = '42501';
  end if;

  select * into v_old from public.products where id = p_id;
  if not found then
    raise exception 'Product not found.' using errcode = 'P0002';
  end if;

  if p_name is null or btrim(p_name) = '' then
    raise exception 'Product name is required.';
  end if;
  if p_sale_price is null or p_sale_price < 0 then
    raise exception 'Sale price must be zero or greater.';
  end if;
  if p_mrp is not null and p_mrp < 0 then
    raise exception 'MRP cannot be negative.';
  end if;
  if p_purchase_price is not null and p_purchase_price < 0 then
    raise exception 'Purchase price cannot be negative.';
  end if;
  if p_low_stock_limit is null or p_low_stock_limit < 0 then
    raise exception 'Low-stock limit cannot be negative.';
  end if;

  update public.products set
    name              = btrim(p_name),
    photo_url         = p_photo_url,
    photo_thumb_url   = p_photo_thumb_url,
    company           = p_company,
    category          = p_category,
    pack_size         = p_pack_size,
    mrp               = p_mrp,
    purchase_price    = p_purchase_price,
    sale_price        = p_sale_price,
    low_stock_limit   = p_low_stock_limit
    -- current_stock is deliberately absent from this SET list, same
    -- as before — unchanged by this migration.
  where id = p_id
  returning * into v_new;

  v_price_changed := (
    v_old.mrp is distinct from v_new.mrp
    or v_old.purchase_price is distinct from v_new.purchase_price
    or v_old.sale_price is distinct from v_new.sale_price
  );

  insert into public.activity_logs (actor_id, action, reference_table, reference_id, details)
  values (
    auth.uid(),
    (case when v_price_changed then 'price_updated' else 'product_updated' end)::activity_action,
    'products',
    v_new.id,
    jsonb_build_object(
      'before', jsonb_build_object(
        'name', v_old.name, 'company', v_old.company, 'category', v_old.category,
        'pack_size', v_old.pack_size, 'mrp', v_old.mrp,
        'purchase_price', v_old.purchase_price, 'sale_price', v_old.sale_price,
        'low_stock_limit', v_old.low_stock_limit, 'photo_url', v_old.photo_url
      ),
      'after', jsonb_build_object(
        'name', v_new.name, 'company', v_new.company, 'category', v_new.category,
        'pack_size', v_new.pack_size, 'mrp', v_new.mrp,
        'purchase_price', v_new.purchase_price, 'sale_price', v_new.sale_price,
        'low_stock_limit', v_new.low_stock_limit, 'photo_url', v_new.photo_url
      )
    )
  );

  return v_new;
end;
$$;

-- Grants are unchanged from migration 0006 (CREATE OR REPLACE keeps
-- existing grants intact), but re-asserted explicitly here for
-- clarity and to guarantee they still match intent after this edit.
revoke all on function public.update_product(
  uuid, text, text, text, text, text, text, numeric, numeric, numeric, numeric
) from public;
revoke execute on function public.update_product(
  uuid, text, text, text, text, text, text, numeric, numeric, numeric, numeric
) from anon;
grant execute on function public.update_product(
  uuid, text, text, text, text, text, text, numeric, numeric, numeric, numeric
) to authenticated;
