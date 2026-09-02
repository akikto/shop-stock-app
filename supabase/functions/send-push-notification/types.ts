/** Supabase Database Webhook payload for INSERT on public.notifications. */
export interface DatabaseWebhookPayload {
  type?: string;
  table?: string;
  schema?: string;
  record?: NotificationRecord | null;
  old_record?: NotificationRecord | null;
}

export interface NotificationRecord {
  id: string;
  recipient_id: string;
  type: string;
  message: string;
  read?: boolean;
  created_at?: string;
}

export interface FcmDataPayload {
  notification_id: string;
  notification_type: string;
  recipient_id: string;
  route: string;
}

export interface FcmSendResult {
  tokenSuffix: string;
  ok: boolean;
  permanentFailure: boolean;
  retryable: boolean;
  errorCode?: string;
}

export interface ProcessResult {
  notificationId: string;
  recipientSuffix: string;
  tokenCount: number;
  successCount: number;
  failureCount: number;
  removedTokenCount: number;
  skipped: boolean;
  reason?: string;
}

export interface ServiceAccountJson {
  project_id: string;
  client_email: string;
  private_key: string;
}
