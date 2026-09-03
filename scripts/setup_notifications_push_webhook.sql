-- Optional reference: database webhook for push notifications (Phase 5B).
-- Replit production deploy created an equivalent trigger via API/SQL.
-- Run in Supabase SQL Editor ONLY when setting up a fresh project.
--
-- Prerequisites:
--   1. Edge Function send-push-notification deployed (--no-verify-jwt)
--   2. Supabase secret PUSH_WEBHOOK_SECRET set
--   3. Extension pg_net enabled (Database → Extensions)
--
-- Replace YOUR_PROJECT_REF and set the header secret to match PUSH_WEBHOOK_SECRET
-- in Supabase Edge Function secrets. Never commit the real secret to git.

-- Example pattern (adjust to your Supabase project's webhook helper if available):
-- INSERT on public.notifications → POST to send-push-notification with
-- header x-push-webhook-secret matching PUSH_WEBHOOK_SECRET.

SELECT 'Use Supabase Dashboard Database Webhooks or Management API after deploy.' AS note;
