import type { FcmDataPayload, FcmSendResult, ServiceAccountJson } from "./types.ts";
import { tokenSuffix } from "./logging.ts";

const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const OAUTH_TOKEN_URL = "https://oauth2.googleapis.com/token";

const PERMANENT_FCM_CODES = new Set([
  "UNREGISTERED",
  "INVALID_ARGUMENT",
  "NOT_FOUND",
]);

export function parseServiceAccount(raw: string | undefined): ServiceAccountJson | null {
  if (!raw || raw.trim() === "") return null;
  try {
    const parsed = JSON.parse(raw) as ServiceAccountJson;
    if (!parsed.project_id || !parsed.client_email || !parsed.private_key) {
      return null;
    }
    return parsed;
  } catch {
    return null;
  }
}

export function notificationTitle(type: string): string {
  switch (type) {
    case "sale":
      return "বিক্রি";
    case "stock_in":
      return "স্টক যোগ";
    case "stock_adjustment":
      return "স্টক সমন্বয়";
    case "low_stock":
      return "কম স্টক";
    case "system":
      return "বিজ্ঞপ্তি";
    default:
      return "বিজ্ঞপ্তি";
  }
}

export function buildFcmData(record: {
  id: string;
  recipient_id: string;
  type: string;
}): FcmDataPayload {
  return {
    notification_id: record.id,
    notification_type: record.type,
    recipient_id: record.recipient_id,
    route: "notifications",
  };
}

export function classifyFcmError(status: number, body: unknown): {
  permanentFailure: boolean;
  retryable: boolean;
  errorCode?: string;
} {
  if (status >= 500 || status === 429) {
    return { permanentFailure: false, retryable: true };
  }

  const errorCode = extractFcmErrorCode(body);
  if (errorCode && PERMANENT_FCM_CODES.has(errorCode)) {
    return { permanentFailure: true, retryable: false, errorCode };
  }

  if (status === 404) {
    return { permanentFailure: true, retryable: false, errorCode: "NOT_FOUND" };
  }

  if (status >= 400) {
    return { permanentFailure: false, retryable: false, errorCode };
  }

  return { permanentFailure: false, retryable: false, errorCode };
}

function extractFcmErrorCode(body: unknown): string | undefined {
  if (!body || typeof body !== "object") return undefined;
  const root = body as Record<string, unknown>;
  const error = root.error;
  if (!error || typeof error !== "object") return undefined;
  const errObj = error as Record<string, unknown>;

  const status = typeof errObj.status === "string" ? errObj.status : undefined;
  const details = errObj.details;
  if (Array.isArray(details)) {
    for (const item of details) {
      if (item && typeof item === "object") {
        const detail = item as Record<string, unknown>;
        const code = detail.errorCode;
        if (typeof code === "string" && code.length > 0) {
          return code;
        }
      }
    }
  }
  return status;
}

let cachedAccessToken: { token: string; expiresAtMs: number } | null = null;

export async function getFcmAccessToken(
  serviceAccount: ServiceAccountJson,
  fetchFn: typeof fetch = fetch,
): Promise<string> {
  const now = Date.now();
  if (cachedAccessToken && cachedAccessToken.expiresAtMs > now + 60_000) {
    return cachedAccessToken.token;
  }

  const jwt = await createServiceAccountJwt(serviceAccount);
  const response = await fetchFn(OAUTH_TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!response.ok) {
    throw new Error("Failed to obtain Firebase access token.");
  }

  const json = await response.json() as { access_token?: string; expires_in?: number };
  if (!json.access_token) {
    throw new Error("Firebase access token missing from OAuth response.");
  }

  const expiresInSec = typeof json.expires_in === "number" ? json.expires_in : 3600;
  cachedAccessToken = {
    token: json.access_token,
    expiresAtMs: now + expiresInSec * 1000,
  };
  return json.access_token;
}

/** Exported for tests — clears OAuth token cache. */
export function resetFcmTokenCacheForTest(): void {
  cachedAccessToken = null;
}

async function createServiceAccountJwt(serviceAccount: ServiceAccountJson): Promise<string> {
  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: OAUTH_TOKEN_URL,
    iat: now,
    exp: now + 3600,
    scope: FCM_SCOPE,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(payload));
  const unsigned = `${encodedHeader}.${encodedPayload}`;

  const key = await importPkcs8PrivateKey(serviceAccount.private_key);
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  return `${unsigned}.${base64UrlEncodeBytes(new Uint8Array(signature))}`;
}

async function importPkcs8PrivateKey(pem: string): Promise<CryptoKey> {
  const pemBody = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");
  const binary = base64Decode(pemBody);
  return crypto.subtle.importKey(
    "pkcs8",
    binary,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

function base64UrlEncode(value: string): string {
  return base64UrlEncodeBytes(new TextEncoder().encode(value));
}

function base64UrlEncodeBytes(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  const base64 = btoa(binary);
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function base64Decode(value: string): Uint8Array {
  const base64 = value.replace(/-/g, "+").replace(/_/g, "/");
  const padded = base64 + "=".repeat((4 - (base64.length % 4)) % 4);
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

export async function sendFcmToToken(
  params: {
    projectId: string;
    accessToken: string;
    deviceToken: string;
    title: string;
    body: string;
    data: FcmDataPayload;
  },
  fetchFn: typeof fetch = fetch,
): Promise<FcmSendResult> {
  const suffix = tokenSuffix(params.deviceToken);
  const url =
    `https://fcm.googleapis.com/v1/projects/${params.projectId}/messages:send`;

  const response = await fetchFn(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${params.accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: {
        token: params.deviceToken,
        notification: {
          title: params.title,
          body: params.body,
        },
        data: {
          notification_id: params.data.notification_id,
          notification_type: params.data.notification_type,
          recipient_id: params.data.recipient_id,
          route: params.data.route,
        },
        android: {
          priority: "HIGH",
          notification: {
            channel_id: "shop_stock_notifications",
          },
        },
      },
    }),
  });

  if (response.ok) {
    return { tokenSuffix: suffix, ok: true, permanentFailure: false, retryable: false };
  }

  let body: unknown = null;
  try {
    body = await response.json();
  } catch {
    body = null;
  }

  const classification = classifyFcmError(response.status, body);
  return {
    tokenSuffix: suffix,
    ok: false,
    permanentFailure: classification.permanentFailure,
    retryable: classification.retryable,
    errorCode: classification.errorCode,
  };
}
