-- Safe migration audit for shop-stock-app (run in Supabase SQL Editor)
-- Use BEFORE db push / repair. Read-only checks only.

-- 1) What Supabase CLI thinks is applied remotely
SELECT version, name, inserted_at
FROM supabase_migrations.schema_migrations
ORDER BY version;

-- 2) Core tables exist (0001)
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'profiles', 'products', 'sales', 'stock_entries',
    'stock_adjustments', 'activity_logs', 'notifications'
  )
ORDER BY tablename;

-- 3) Migration 0012 markers (FCM, staff, reports)
SELECT proname
FROM pg_proc
WHERE proname IN (
  'register_fcm_token',
  'get_notification_preferences',
  'list_staff_profiles',
  'get_stock_movement_report'
)
ORDER BY proname;

-- 4) Migration 0013 (sync conflicts)
SELECT proname FROM pg_proc WHERE proname = 'log_sync_conflict';
SELECT tablename FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'sync_conflicts';

-- 5) Migration 0014 (notification hardening) — CRITICAL for current app
SELECT proname
FROM pg_proc
WHERE proname IN ('mark_notification_read', 'mark_all_notifications_read');

SELECT pg_get_function_identity_arguments(oid) AS args
FROM pg_proc
WHERE proname = '_maybe_notify_low_stock';

-- 0014: client UPDATE on notifications should be revoked
SELECT has_table_privilege('authenticated', 'public.notifications', 'UPDATE') AS client_can_update_notifications;

-- 6) RLS enabled on core tables
SELECT relname, relrowsecurity
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND relname IN ('profiles', 'products', 'sales', 'notifications')
ORDER BY relname;
