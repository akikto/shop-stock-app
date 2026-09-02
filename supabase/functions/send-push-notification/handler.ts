import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import {
  buildFcmData,
  getFcmAccessToken,
  notificationTitle,
  parseServiceAccount,
  sendFcmToToken,
} from "./fcm.ts";
import { redactId, tokenSuffix } from "./logging.ts";
import { isPushEnabledForType, type NotificationPreferencesRow } from "./preferences.ts";
import type { FcmSendResult, NotificationRecord, ProcessResult, ServiceAccountJson } from "./types.ts";
import { parseNotificationInsert, verifyWebhookSecret } from "./webhook.ts";

export interface HandlerDeps {
  env: Record<string, string | undefined>;
  fetchFn?: typeof fetch;
  createAdminClient?: (url: string, key: string) => SupabaseClient;
  /** Test hook — bypass OAuth JWT signing. */
  getAccessToken?: (serviceAccount: ServiceAccountJson) => Promise<string>;
  /** Test hook — bypass live FCM HTTP calls. */
  sendFcm?: typeof sendFcmToToken;
}

export async function handlePushWebhookRequest(
  req: Request,
  deps: HandlerDeps,
): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed." }, 405);
  }

  const authFailure = verifyWebhookSecret(req, deps.env.PUSH_WEBHOOK_SECRET);
  if (authFailure) return authFailure;

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body." }, 400);
  }

  const parsed = parseNotificationInsert(body);
  if ("error" in parsed) return parsed.error;

  try {
    const result = await deliverNotificationPush(parsed.record, deps);
    return json({ ok: true, result }, 200);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unexpected error.";
    if (message.includes("Firebase credentials")) {
      return json({ error: "Firebase push is not configured." }, 500);
    }
    if (message.includes("access token")) {
      return json({ error: "Temporary Firebase auth failure." }, 503);
    }
    if (message.includes("Temporary FCM delivery failure")) {
      return json({ error: "Temporary FCM delivery failure." }, 503);
    }
    if (message.includes("Notification not found")) {
      return json({ error: "Notification not found." }, 404);
    }
    return json({ error: "Push delivery failed." }, 500);
  }
}

export async function deliverNotificationPush(
  record: NotificationRecord,
  deps: HandlerDeps,
): Promise<ProcessResult> {
  const fetchFn = deps.fetchFn ?? fetch;
  const supabaseUrl = deps.env.SUPABASE_URL ?? "";
  const serviceRoleKey = deps.env.SUPABASE_SERVICE_ROLE_KEY ?? "";
  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error("Supabase admin credentials are not configured.");
  }

  const serviceAccount = parseServiceAccount(deps.env.FIREBASE_SERVICE_ACCOUNT);
  if (!serviceAccount) {
    throw new Error("Firebase credentials are not configured.");
  }

  const createClientFn = deps.createAdminClient ?? createClient;
  const admin = createClientFn(supabaseUrl, serviceRoleKey);

  const notificationExists = await verifyNotificationExists(admin, record.id);
  if (!notificationExists) {
    throw new Error("Notification not found.");
  }

  const preferences = await loadNotificationPreferences(admin, record.recipient_id);
  if (!isPushEnabledForType(record.type, preferences)) {
    console.log(
      `push_delivery_preferences_disabled notification_id=${redactId(record.id)} recipient=${redactId(record.recipient_id)} type=${record.type}`,
    );
    return {
      notificationId: record.id,
      recipientSuffix: redactId(record.recipient_id),
      tokenCount: 0,
      successCount: 0,
      failureCount: 0,
      removedTokenCount: 0,
      skipped: true,
      reason: "preferences_disabled",
    };
  }

  const { data: tokens, error: tokenError } = await admin
    .from("fcm_tokens")
    .select("token")
    .eq("user_id", record.recipient_id);

  if (tokenError) {
    throw new Error("Failed to load device tokens.");
  }

  const deviceTokens = (tokens ?? [])
    .map((row) => (row as { token?: string }).token)
    .filter((token): token is string => typeof token === "string" && token.trim() !== "");

  const baseResult: ProcessResult = {
    notificationId: record.id,
    recipientSuffix: redactId(record.recipient_id),
    tokenCount: deviceTokens.length,
    successCount: 0,
    failureCount: 0,
    removedTokenCount: 0,
    skipped: false,
  };

  if (deviceTokens.length === 0) {
    console.log(
      `push_delivery_no_tokens notification_id=${redactId(record.id)} recipient=${redactId(record.recipient_id)}`,
    );
    return { ...baseResult, skipped: true, reason: "no_tokens" };
  }

  const accessToken = deps.getAccessToken
    ? await deps.getAccessToken(serviceAccount)
    : await getFcmAccessToken(serviceAccount, fetchFn);
  const title = notificationTitle(record.type);
  const data = buildFcmData(record);
  const sendFcmFn = deps.sendFcm ?? sendFcmToToken;

  const sendResults: FcmSendResult[] = [];
  for (const deviceToken of deviceTokens) {
    const result = await sendFcmFn(
      {
        projectId: serviceAccount.project_id,
        accessToken,
        deviceToken,
        title,
        body: record.message,
        data,
      },
      fetchFn,
    );
    sendResults.push(result);

    if (result.permanentFailure) {
      await removeStaleToken(admin, record.recipient_id, deviceToken);
      baseResult.removedTokenCount += 1;
    }
  }

  baseResult.successCount = sendResults.filter((r) => r.ok).length;
  baseResult.failureCount = sendResults.filter((r) => !r.ok).length;

  const retryableFailures = sendResults.some((r) => !r.ok && r.retryable);
  if (retryableFailures && baseResult.successCount === 0) {
    throw new Error("Temporary FCM delivery failure.");
  }

  console.log(
    `push_delivery_complete notification_id=${redactId(record.id)} recipient=${redactId(record.recipient_id)} token_count=${baseResult.tokenCount} success_count=${baseResult.successCount} failure_count=${baseResult.failureCount} removed_count=${baseResult.removedTokenCount}`,
  );

  return baseResult;
}

async function verifyNotificationExists(
  admin: SupabaseClient,
  notificationId: string,
): Promise<boolean> {
  const { data, error } = await admin
    .from("notifications")
    .select("id")
    .eq("id", notificationId)
    .maybeSingle();

  if (error) {
    throw new Error("Failed to verify notification record.");
  }

  return data != null;
}

async function loadNotificationPreferences(
  admin: SupabaseClient,
  recipientId: string,
): Promise<NotificationPreferencesRow | null> {
  const { data, error } = await admin
    .from("notification_preferences")
    .select("notify_sale, notify_stock_in, notify_stock_adjustment, notify_low_stock")
    .eq("user_id", recipientId)
    .maybeSingle();

  if (error) {
    throw new Error("Failed to load notification preferences.");
  }

  return data as NotificationPreferencesRow | null;
}

async function removeStaleToken(
  admin: SupabaseClient,
  recipientId: string,
  token: string,
): Promise<void> {
  const { error } = await admin
    .from("fcm_tokens")
    .delete()
    .eq("user_id", recipientId)
    .eq("token", token);

  if (error) {
    console.log(
      `push_token_cleanup_failed recipient=${redactId(recipientId)} token_suffix=${tokenSuffix(token)}`,
    );
    return;
  }

  console.log(
    `push_token_removed recipient=${redactId(recipientId)} token_suffix=${tokenSuffix(token)}`,
  );
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-push-webhook-secret",
};

function json(payload: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
