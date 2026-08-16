-- =====================================================================
-- Phase 3 — Migration 9: Expiry/Composition fields + Activate Product
--
-- Adds two product fields that were in the Phase 3 requirements but
-- never existed in the schema (expiry_date, composition), and closes
-- a one-way gap: deactivate_product() existed since migration 0006,
-- but there was no way to reactivate a product afterwards.
--
-- IMPORTANT — avoiding duplicate function overloads:
-- create_product()/update_product() are gaining two new trailing
-- parameters. Postgres identifies a function by name + parameter
-- TYPE LIST, so simply adding parameters and using
-- CREATE OR REPLACE would create a SECOND overloaded function instead
-- of replacing the original — leaving a duplicate, unused-but-still
-- callable old version behind. To prevent that, the old-signature
-- functions are explicitly DROPped first, then recreated with the
-- additional parameters. Migrations 0001-0008 are not edited — this
-- is a new migration redefining functions, the same pattern already
-- used in migration 0007.
-- =====================================================================

-- ---------------------------------------------------------------------
-- New product fields
-- ---------------------------------------------------------------------
alter table public.products add column if not exists expiry_date date;
alter table public.products add column if not exists composition text;

comment on column public.products.expiry_date is
  'Optional. Informational only — no automated expiry enforcement/alerting exists yet.';
comment on column public.products.composition is
  'Optional free-text active-ingredient/composition field (pharmacy use case).';

-- ---------------------------------------------------------------------
-- New activity_action value for reactivation
-- ---------------------------------------------------------------------
alter type activity_action add value if not exists 'product_activated';

-- ---------------------------------------------------------------------
-- Drop old-signature create_product / update_product before recreating
-- with the two new trailing parameters, to avoid leaving a duplicate
-- overload behind.
-- ---------------------------------------------------------------------
drop function if exists public.create_product(
  text, text, text, text, text, text, numeric, numeric, numeric, numeric
);
drop function if exists public.update_product(
  uuid, text, text, text, text, text, text, numeric, numeric, numeric, numeric
);

-- ---------------------------------------------------------------------
-- create_product() — same validation/authorization/audit logic as
-- migration 0006, plus p_expiry_date and p_composition (both
-- optional). current_stock is still always 0 at creation, still not a
-- parameter — unchanged guarantee from 0006.
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
  p_low_stock_limit numeric default 0,
  p_expiry_date date default null,
  p_composition text default null
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
    expiry_date, composition,
    current_stock, created_by
  ) values (
    btrim(p_name), p_photo_url, p_photo_thumb_url, p_company, p_category, p_pack_size,
    p_mrp, p_purchase_price, p_sale_price, p_low_stock_limit,
    p_expiry_date, p_composition,
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
      'low_stock_limit', v_product.low_stock_limit,
      'expiry_date', v_product.expiry_date,
      'composition', v_product.composition
    )
  );

  return v_product;
end;
$$;

revoke all on function public.create_product(
  text, text, text, text, text, text, numeric, numeric, numeric, numeric, date, text
) from public;
revoke execute on function public.create_product(
  text, text, text, text, text, text, numeric, numeric, numeric, numeric, date, text
) from anon;
grant execute on function public.create_product(
  text, text, text, text, text, text, numeric, numeric, numeric, numeric, date, text
) to authenticated;

-- ---------------------------------------------------------------------
-- update_product() — same fixed logic as migration 0007 (including
-- the activity_action cast fix), plus p_expiry_date/p_composition.
-- current_stock remains absent from the SET list — unchanged
-- guarantee.
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
  p_low_stock_limit numeric default 0,
  p_expiry_date date default null,
  p_composition text default null
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
    low_stock_limit   = p_low_stock_limit,
    expiry_date       = p_expiry_date,
    composition       = p_composition
    -- current_stock is deliberately absent from this SET list, same
    -- as migrations 0006/0007 — Product Management still can never
    -- change it.
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
        'low_stock_limit', v_old.low_stock_limit, 'photo_url', v_old.photo_url,
        'expiry_date', v_old.expiry_date, 'composition', v_old.composition
      ),
      'after', jsonb_build_object(
        'name', v_new.name, 'company', v_new.company, 'category', v_new.category,
        'pack_size', v_new.pack_size, 'mrp', v_new.mrp,
        'purchase_price', v_new.purchase_price, 'sale_price', v_new.sale_price,
        'low_stock_limit', v_new.low_stock_limit, 'photo_url', v_new.photo_url,
        'expiry_date', v_new.expiry_date, 'composition', v_new.composition
      )
    )
  );

  return v_new;
end;
$$;

revoke all on function public.update_product(
  uuid, text, text, text, text, text, text, numeric, numeric, numeric, numeric, date, text
) from public;
revoke execute on function public.update_product(
  uuid, text, text, text, text, text, text, numeric, numeric, numeric, numeric, date, text
) from anon;
grant execute on function public.update_product(
  uuid, text, text, text, text, text, text, numeric, numeric, numeric, numeric, date, text
) to authenticated;

-- ---------------------------------------------------------------------
-- activate_product() — the missing counterpart to deactivate_product()
-- from migration 0006. Manager/Owner only, same pattern.
-- ---------------------------------------------------------------------
create or replace function public.activate_product(p_id uuid)
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
    raise exception 'Only a manager or owner can activate products.' using errcode = '42501';
  end if;

  update public.products
  set is_active = true
  where id = p_id
  returning * into v_product;

  if not found then
    raise exception 'Product not found.' using errcode = 'P0002';
  end if;

  insert into public.activity_logs (actor_id, action, reference_table, reference_id, details)
  values (
    auth.uid(),
    'product_activated',
    'products',
    v_product.id,
    jsonb_build_object('name', v_product.name)
  );

  return v_product;
end;
$$;

revoke all on function public.activate_product(uuid) from public;
revoke execute on function public.activate_product(uuid) from anon;
grant execute on function public.activate_product(uuid) to authenticated;
