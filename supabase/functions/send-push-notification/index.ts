// Phase 5B — server-side FCM delivery for notifications INSERT webhook.
//
// Deploy:
//   supabase functions deploy send-push-notification --no-verify-jwt
//
// Required secrets (Supabase Dashboard → Edge Functions → Secrets):
//   FIREBASE_SERVICE_ACCOUNT  — Firebase service account JSON (server-side only)
//   PUSH_WEBHOOK_SECRET       — shared secret; send as header x-push-webhook-secret
//
// Database webhook (Supabase Dashboard → Database → Webhooks):
//   Table: public.notifications
//   Events: INSERT
//   URL: https://<project-ref>.supabase.co/functions/v1/send-push-notification
//   HTTP header: x-push-webhook-secret = <PUSH_WEBHOOK_SECRET>
//
// The Flutter app must NOT call this function. Notifications are created by RPCs;
// the webhook invokes push delivery after INSERT.

import { handlePushWebhookRequest } from "./handler.ts";

Deno.serve((req) =>
  handlePushWebhookRequest(req, {
    env: {
      SUPABASE_URL: Deno.env.get("SUPABASE_URL"),
      SUPABASE_SERVICE_ROLE_KEY: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"),
      FIREBASE_SERVICE_ACCOUNT: Deno.env.get("FIREBASE_SERVICE_ACCOUNT"),
      PUSH_WEBHOOK_SECRET: Deno.env.get("PUSH_WEBHOOK_SECRET"),
    },
  })
);
