-- =====================================================================
-- Migration 13: log_sync_conflict() — client-side conflict logging when
-- offline replay fails with a business rule error (e.g. insufficient stock).
-- =====================================================================

create or replace function public.log_sync_conflict(
  p_device_txn_id uuid,
  p_action text,
  p_product_id uuid default null,
  p_details jsonb default '{}'::jsonb
)
returns public.sync_conflicts
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.sync_conflicts;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '28000';
  end if;
  if p_device_txn_id is null then
    raise exception 'device_txn_id is required.';
  end if;
  if p_action is null or btrim(p_action) = '' then
    raise exception 'action is required.';
  end if;

  insert into public.sync_conflicts (
    device_txn_id, actor_id, action, product_id, details
  )
  values (
    p_device_txn_id,
    auth.uid(),
    btrim(p_action),
    p_product_id,
    coalesce(p_details, '{}'::jsonb)
  )
  on conflict (device_txn_id) do update
    set action = excluded.action,
        product_id = excluded.product_id,
        details = excluded.details,
        resolved = false
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.log_sync_conflict(uuid, text, uuid, jsonb) from public;
revoke execute on function public.log_sync_conflict(uuid, text, uuid, jsonb) from anon;
grant execute on function public.log_sync_conflict(uuid, text, uuid, jsonb) to authenticated;
