-- =====================================================================
-- Phase 1 — Migration 6: Product Management RPC Functions
--
-- products has NO client INSERT/UPDATE policy (see migration 0003 and
-- its Phase 0 security-review fix). These three SECURITY DEFINER
-- functions are the ONLY way a client can create, edit, or deactivate
-- a product. Each one:
--   - requires an authenticated caller (auth.uid() is never trusted
--     as a client-supplied parameter — it is always read server-side)
--   - explicitly checks public.is_manager_or_owner() before doing
--     anything else, and raises an exception otherwise
--   - validates its inputs and raises a clear exception on failure
--     (the table's own CHECK constraints remain a second line of
--     defense regardless)
--   - never accepts current_stock as a parameter at all — it is
--     therefore structurally impossible for these functions to change
--     it. New products always start at current_stock = 0.
--   - writes a row to activity_logs for every create/update/deactivate,
--     bypassing RLS the same way (SECURITY DEFINER, owned by the same
--     role that owns the tables — see the note at the end of this
--     file), so the audit trail is populated without needing any
--     client-facing INSERT policy on activity_logs.
-- =====================================================================

-- New activity_action values needed for product management. Added as
-- its own statement (not inside the enum's original creation block in
-- migration 0001) because Postgres enum values can only be added, not
-- inserted into an existing CREATE TYPE statement after the fact.
alter type activity_action add value if not exists 'product_deactivated';

-- ---------------------------------------------------------------------
-- create_product()
-- ---------------------------------------------------------------------
create or replace function public.create_product(
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
  v_product public.products;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  if not public.is_manager_or_owner() then
    raise exception 'Only a manager or owner can create products.' using errcode = '42501';
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

  insert into public.products (
    name, photo_url, photo_thumb_url, company, category, pack_size,
    mrp, purchase_price, sale_price, low_stock_limit,
    current_stock, created_by
  ) values (
    btrim(p_name), p_photo_url, p_photo_thumb_url, p_company, p_category, p_pack_size,
    p_mrp, p_purchase_price, p_sale_price, p_low_stock_limit,
    0,                    -- current_stock is always 0 at creation, always, no exceptions
    auth.uid()
  )
  returning * into v_product;

  insert into public.activity_logs (actor_id, action, reference_table, reference_id, details)
  values (
    auth.uid(),
    'product_created',
    'products',
    v_product.id,
    jsonb_build_object(
      'name', v_product.name,
      'company', v_product.company,
      'mrp', v_product.mrp,
      'purchase_price', v_product.purchase_price,
      'sale_price', v_product.sale_price,
      'low_stock_limit', v_product.low_stock_limit
    )
  );

  return v_product;
end;
$$;

revoke all on function public.create_product(
  text, text, text, text, text, text, numeric, numeric, numeric, numeric
) from public;
grant execute on function public.create_product(
  text, text, text, text, text, text, numeric, numeric, numeric, numeric
) to authenticated;

-- ---------------------------------------------------------------------
-- update_product()
--   Note there is no p_current_stock parameter anywhere in this
--   function's signature — see the file header.
-- ---------------------------------------------------------------------
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
    -- current_stock is deliberately absent from this SET list.
    -- Product Management can never change it, by construction, not by
    -- convention: there is no code path in this function that touches
    -- that column.
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
    case when v_price_changed then 'price_updated' else 'product_updated' end,
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

revoke all on function public.update_product(
  uuid, text, text, text, text, text, text, numeric, numeric, numeric, numeric
) from public;
grant execute on function public.update_product(
  uuid, text, text, text, text, text, text, numeric, numeric, numeric, numeric
) to authenticated;

-- ---------------------------------------------------------------------
-- deactivate_product()
--   Soft-delete only. Never removes the row, so historical
--   sales/stock references (added in a later phase) always stay
--   valid.
-- ---------------------------------------------------------------------
create or replace function public.deactivate_product(p_id uuid)
returns public.products
language plpgsql
security definer
set search_path = public
as $$
declare
  v_product public.products;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;

  if not public.is_manager_or_owner() then
    raise exception 'Only a manager or owner can deactivate products.' using errcode = '42501';
  end if;

  update public.products
  set is_active = false
  where id = p_id
  returning * into v_product;

  if not found then
    raise exception 'Product not found.' using errcode = 'P0002';
  end if;

  insert into public.activity_logs (actor_id, action, reference_table, reference_id, details)
  values (
    auth.uid(),
    'product_deactivated',
    'products',
    v_product.id,
    jsonb_build_object('name', v_product.name)
  );

  return v_product;
end;
$$;

revoke all on function public.deactivate_product(uuid) from public;
grant execute on function public.deactivate_product(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- Why these functions are allowed to write to products/activity_logs
-- despite neither table having a client INSERT/UPDATE policy:
--
-- A SECURITY DEFINER function runs with the privileges of the role
-- that OWNS the function (here: whichever role applies this
-- migration — normally the same role that owns the tables, e.g.
-- `postgres`/`supabase_admin` in a standard Supabase project).
-- Postgres row-level security does not apply to a table's owner by
-- default (only `FORCE ROW LEVEL SECURITY` would change that, which
-- these tables do not use). So these functions can INSERT/UPDATE
-- normally, while every other path a client might try — a raw
-- `.from('products').update(...)` call, for example — is still
-- blocked by RLS exactly as before. This is the standard, documented
-- Supabase pattern for "write only through an RPC".
-- ---------------------------------------------------------------------
