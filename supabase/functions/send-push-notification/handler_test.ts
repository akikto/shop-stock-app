import {
  assert,
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { classifyFcmError, buildFcmData, parseServiceAccount } from "./fcm.ts";
import { deliverNotificationPush, handlePushWebhookRequest } from "./handler.ts";
import type { FcmSendResult, NotificationRecord } from "./types.ts";
import { parseNotificationInsert, verifyWebhookSecret } from "./webhook.ts";

const sampleRecord: NotificationRecord = {
  id: "11111111-1111-1111-1111-111111111111",
  recipient_id: "22222222-2222-2222-2222-222222222222",
  type: "sale",
  message: "বিক্রি সম্পন্ন",
};

const validServiceAccount = JSON.stringify({
  project_id: "shop-stock-test",
  client_email: "firebase-adminsdk@test.iam.gserviceaccount.com",
  private_key: "-----BEGIN PRIVATE KEY-----\nTEST\n-----END PRIVATE KEY-----\n",
});

function baseEnv(overrides: Record<string, string | undefined> = {}) {
  return {
    SUPABASE_URL: "https://example.supabase.co",
    SUPABASE_SERVICE_ROLE_KEY: "service-role-key",
    FIREBASE_SERVICE_ACCOUNT: validServiceAccount,
    PUSH_WEBHOOK_SECRET: "test-webhook-secret",
    ...overrides,
  };
}

function webhookRequest(body: unknown, secret = "test-webhook-secret"): Request {
  return new Request("https://example.test/push", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-push-webhook-secret": secret,
    },
    body: JSON.stringify(body),
  });
}

function mockAdmin(tokens: string[]) {
  const deleted: { user_id: string; token: string }[] = [];
  return {
    deleted,
    client: {
      from(_table: string) {
        return {
          select(_cols: string) {
            return {
              eq(_column: string, _value: string) {
                return Promise.resolve({
                  data: tokens.map((token) => ({ token })),
                  error: null,
                });
              },
            };
          },
          delete() {
            return {
              eq(_column: string, userId: string) {
                return {
                  eq(_column2: string, token: string) {
                    deleted.push({ user_id: userId, token });
                    return Promise.resolve({ error: null });
                  },
                };
              },
            };
          },
        };
      },
    },
  };
}

Deno.test("valid webhook payload is accepted", async () => {
  const parsed = parseNotificationInsert({
    type: "INSERT",
    table: "notifications",
    schema: "public",
    record: sampleRecord,
  });
  assert(!("error" in parsed));
  assertEquals(parsed.record.id, sampleRecord.id);
});

Deno.test("unauthorized webhook is rejected", () => {
  const req = new Request("https://example.test", {
    headers: { "x-push-webhook-secret": "wrong" },
  });
  const response = verifyWebhookSecret(req, "expected-secret");
  assert(response);
  assertEquals(response?.status, 401);
});

Deno.test("missing notification id is rejected", () => {
  const parsed = parseNotificationInsert({
    type: "INSERT",
    table: "notifications",
    schema: "public",
    record: { ...sampleRecord, id: "" },
  });
  assert("error" in parsed);
  assertEquals(parsed.error.status, 400);
});

Deno.test("missing recipient is rejected", () => {
  const parsed = parseNotificationInsert({
    type: "INSERT",
    table: "notifications",
    schema: "public",
    record: { ...sampleRecord, recipient_id: "" },
  });
  assert("error" in parsed);
  assertEquals(parsed.error.status, 400);
});

Deno.test("no tokens is a safe no-op", async () => {
  const admin = mockAdmin([]);
  const result = await deliverNotificationPush(sampleRecord, {
    env: baseEnv(),
    createAdminClient: () => admin.client as never,
    getAccessToken: async () => "access-token",
  });
  assertEquals(result.skipped, true);
  assertEquals(result.tokenCount, 0);
});

Deno.test("one valid token succeeds", async () => {
  const admin = mockAdmin(["device-token-1"]);
  const result = await deliverNotificationPush(sampleRecord, {
    env: baseEnv(),
    createAdminClient: () => admin.client as never,
    getAccessToken: async () => "access-token",
    sendFcm: async () => ({
      tokenSuffix: "token-1",
      ok: true,
      permanentFailure: false,
      retryable: false,
    }),
  });
  assertEquals(result.successCount, 1);
  assertEquals(result.failureCount, 0);
});

Deno.test("multiple tokens are processed independently", async () => {
  const admin = mockAdmin(["token-a", "token-b"]);
  let calls = 0;
  const result = await deliverNotificationPush(sampleRecord, {
    env: baseEnv(),
    createAdminClient: () => admin.client as never,
    getAccessToken: async () => "access-token",
    sendFcm: async () => {
      calls += 1;
      return {
        tokenSuffix: `t${calls}`,
        ok: calls === 1,
        permanentFailure: calls === 2,
        retryable: false,
        errorCode: calls === 2 ? "UNREGISTERED" : undefined,
      };
    },
  });
  assertEquals(calls, 2);
  assertEquals(result.successCount, 1);
  assertEquals(result.failureCount, 1);
  assertEquals(result.removedTokenCount, 1);
  assertEquals(admin.deleted.length, 1);
});

Deno.test("invalid token triggers cleanup for that token only", async () => {
  const admin = mockAdmin(["bad-token"]);
  await deliverNotificationPush(sampleRecord, {
    env: baseEnv(),
    createAdminClient: () => admin.client as never,
    getAccessToken: async () => "access-token",
    sendFcm: async () => ({
      tokenSuffix: "bad-token",
      ok: false,
      permanentFailure: true,
      retryable: false,
      errorCode: "UNREGISTERED",
    }),
  });
  assertEquals(admin.deleted, [{
    user_id: sampleRecord.recipient_id,
    token: "bad-token",
  }]);
});

Deno.test("temporary FCM failure is retryable", async () => {
  const admin = mockAdmin(["device-token"]);
  await assertRejects(
    () =>
      deliverNotificationPush(sampleRecord, {
        env: baseEnv(),
        createAdminClient: () => admin.client as never,
        getAccessToken: async () => "access-token",
        sendFcm: async () => ({
          tokenSuffix: "suffix",
          ok: false,
          permanentFailure: false,
          retryable: true,
        }),
      }),
    Error,
    "Temporary FCM delivery failure.",
  );
});

Deno.test("missing Firebase credentials returns configuration error", async () => {
  const response = await handlePushWebhookRequest(
    webhookRequest({
      type: "INSERT",
      table: "notifications",
      schema: "public",
      record: sampleRecord,
    }),
    {
      env: baseEnv({ FIREBASE_SERVICE_ACCOUNT: undefined }),
    },
  );
  assertEquals(response.status, 500);
});

Deno.test("FCM UNREGISTERED is treated as permanent", () => {
  const result = classifyFcmError(404, {
    error: {
      status: "NOT_FOUND",
      details: [{ errorCode: "UNREGISTERED" }],
    },
  });
  assertEquals(result.permanentFailure, true);
  assertEquals(result.retryable, false);
});

Deno.test("data payload matches Flutter router conventions", () => {
  const data = buildFcmData(sampleRecord);
  assertEquals(data.notification_id, sampleRecord.id);
  assertEquals(data.notification_type, "sale");
  assertEquals(data.recipient_id, sampleRecord.recipient_id);
  assertEquals(data.route, "notifications");
});

Deno.test("service account JSON must include required fields", () => {
  assertEquals(parseServiceAccount(validServiceAccount)?.project_id, "shop-stock-test");
  assertEquals(parseServiceAccount("{}"), null);
});

Deno.test("handler rejects unauthorized request end-to-end", async () => {
  const response = await handlePushWebhookRequest(
    webhookRequest({ type: "INSERT" }, "wrong-secret"),
    { env: baseEnv() },
  );
  assertEquals(response.status, 401);
});

Deno.test("handler accepts authorized valid payload", async () => {
  const admin = mockAdmin([]);
  const response = await handlePushWebhookRequest(
    webhookRequest({
      type: "INSERT",
      table: "notifications",
      schema: "public",
      record: sampleRecord,
    }),
    {
      env: baseEnv(),
      createAdminClient: () => admin.client as never,
      getAccessToken: async () => "access-token",
    },
  );
  assertEquals(response.status, 200);
  const json = await response.json() as { ok: boolean };
  assertEquals(json.ok, true);
});
