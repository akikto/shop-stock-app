import type { DatabaseWebhookPayload, NotificationRecord } from "./types.ts";

const NOTIFICATIONS_TABLE = "notifications";

export function verifyWebhookSecret(
  req: Request,
  expectedSecret: string | undefined,
): Response | null {
  if (!expectedSecret || expectedSecret.trim() === "") {
    return jsonError("Push webhook secret is not configured.", 500);
  }

  const provided = req.headers.get("x-push-webhook-secret")?.trim();
  if (!provided || provided !== expectedSecret) {
    return jsonError("Unauthorized webhook request.", 401);
  }

  return null;
}

export function parseNotificationInsert(
  body: unknown,
): { record: NotificationRecord } | { error: Response } {
  if (!body || typeof body !== "object") {
    return { error: jsonError("Invalid webhook payload.", 400) };
  }

  const payload = body as DatabaseWebhookPayload;

  if (payload.type !== "INSERT") {
    return { error: jsonError("Only INSERT events are supported.", 400) };
  }
  if (payload.schema !== "public" || payload.table !== NOTIFICATIONS_TABLE) {
    return { error: jsonError("Unexpected webhook table.", 400) };
  }

  const record = payload.record;
  if (!record || typeof record !== "object") {
    return { error: jsonError("Missing notification record.", 400) };
  }

  const id = stringField(record.id);
  const recipientId = stringField(record.recipient_id);
  const type = stringField(record.type);
  const message = stringField(record.message);

  if (!id) {
    return { error: jsonError("Missing notification id.", 400) };
  }
  if (!recipientId) {
    return { error: jsonError("Missing recipient_id.", 400) };
  }
  if (!type) {
    return { error: jsonError("Missing notification type.", 400) };
  }
  if (!message) {
    return { error: jsonError("Missing notification message.", 400) };
  }

  return {
    record: {
      id,
      recipient_id: recipientId,
      type,
      message,
      read: record.read === true,
      created_at: stringField(record.created_at) ?? undefined,
    },
  };
}

function stringField(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function jsonError(message: string, status: number): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
