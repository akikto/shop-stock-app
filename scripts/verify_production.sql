-- Post-deploy verification for shop-stock-app (run in Supabase SQL Editor)
-- Expect all rows to return expected results; empty = missing migration.

-- Migration 0014: mark-as-read RPCs
SELECT proname, prosecdef AS security_definer
FROM pg_proc
WHERE proname IN ('mark_notification_read', 'mark_all_notifications_read');

-- Migration 0014: threshold-crossing low-stock helper (2-arg version)
SELECT proname, pg_get_function_identity_arguments(oid) AS args
FROM pg_proc
WHERE proname = '_maybe_notify_low_stock';

-- Authenticated can execute mark-as-read RPCs
SELECT has_function_privilege('authenticated', 'public.mark_notification_read(uuid)', 'EXECUTE')
  AS can_mark_one;
SELECT has_function_privilege('authenticated', 'public.mark_all_notifications_read()', 'EXECUTE')
  AS can_mark_all;

-- Direct client UPDATE on notifications should be revoked (0014)
SELECT has_table_privilege('authenticated', 'public.notifications', 'UPDATE') AS client_can_update;

-- Core tables exist
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('profiles', 'products', 'sales', 'notifications', 'fcm_tokens', 'notification_preferences')
ORDER BY tablename;

-- Owner profile (replace UUID after first signup)
-- SELECT id, role, is_active FROM public.profiles WHERE role = 'owner';
