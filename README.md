# Shop Stock & Sales Management App

Mobile-first Flutter + Supabase app for a small shop (4–5 staff).

**Version 1.0** — all roadmap phases (0–6) from Technical Implementation Plan v1.0 are implemented.

---

## Roadmap phases (v1.0)

| Phase | Scope | Status |
|-------|--------|--------|
| 0 | Schema, RLS, auth, app shell | Done |
| 1 | Product management + photos | Done |
| 2 | Sale, stock in, adjustment (online RPCs) | Done |
| 3 | Realtime sync + in-app notifications + FCM tokens | Done |
| 4 | Dashboard, reports, audit history | Done |
| 5 | Offline queue (Drift/SQLite), idempotent replay | Done (Android) |
| 6 | Staff mgmt, notification prefs, stock movement report, low-stock list, sync conflicts, CI hardening | Done |

---

## Prerequisites

- Flutter SDK (stable channel) — Dart `>=3.3.0 <4.0.0`
- Supabase project + Supabase CLI
- Optional: Firebase project with `google-services.json` for Android push (graceful no-op if absent)

---

## Configure Supabase

1. Create a project at https://supabase.com
2. Apply migrations **in order** via `supabase db push` or the SQL editor:

   `0001` → `0002` → `0003` → `0004` → `0005` → `0006` → `0007` → `0008` → `0009` → `0010` → `0011` → `0012` → `0013` → `0014`

3. Enable Email/Password auth
4. Create the first user (Owner), then promote once in SQL:

   ```sql
   update public.profiles set role = 'owner' where id = '<auth-user-id>';
   ```

---

## Environment

Copy `config/config.example.json` to `config/config.json` with your `SUPABASE_URL` and `SUPABASE_ANON_KEY` (public anon key only — never `service_role`).

```bash
flutter pub get
flutter run --dart-define-from-file=config/config.json
```

---

## Features by role

- **Staff:** Sale, stock in, history, dashboard (self scope), offline transactions (Android)
- **Manager:** + stock adjustment, shop-wide dashboard/reports, low-stock list, sync conflicts, notification preferences
- **Owner:** + staff role/activation management, invite new staff (Edge Function)

### Staff invite (Owner)

Deploy the Edge Function once:

```bash
supabase functions deploy invite-staff
```

Then use **Settings → Staff Management → +** to create email/password accounts for new staff.

### Push notifications (Phase 5B)

In-app notifications (Phase 5A) register FCM tokens and route taps to the notifications inbox. Phase 5B adds **server-side** FCM delivery when a row is inserted into `public.notifications` (created by sale/stock RPCs — never by the Flutter client directly).

Flow:

```
RPC → notifications INSERT → Database Webhook → send-push-notification → FCM → device
```

The Flutter app must **not** call `send-push-notification`. The database remains the source of truth.

#### 1. Deploy the Edge Function

```bash
supabase functions deploy send-push-notification --no-verify-jwt
```

`--no-verify-jwt` is required because the caller is a Database Webhook, not an authenticated app user. Webhook authentication uses a shared secret header instead (see below).

#### 2. Configure Edge Function secrets

In **Supabase Dashboard → Edge Functions → Secrets** (or `supabase secrets set`), add:

| Secret | Description |
|--------|-------------|
| `FIREBASE_SERVICE_ACCOUNT` | Full Firebase service account JSON (server-side only). Used for FCM HTTP v1 OAuth. |
| `PUSH_WEBHOOK_SECRET` | Random shared secret for webhook authentication. |

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected automatically for Edge Functions.

**Never commit** Firebase service account JSON, private keys, `service_role` keys, or webhook secrets to this repository or into the Flutter app.

#### 3. Create the Database Webhook

In **Supabase Dashboard → Database → Webhooks → Create webhook**:

| Setting | Value |
|---------|--------|
| Name | `notifications-insert-push` (or similar) |
| Table | `public.notifications` |
| Events | **Insert** |
| Type | Supabase Edge Function → `send-push-notification` |

If configuring manually via HTTP instead of the Edge Function picker:

- **URL:** `https://<project-ref>.supabase.co/functions/v1/send-push-notification`
- **HTTP header:** `x-push-webhook-secret` = value of `PUSH_WEBHOOK_SECRET`

#### 4. Verify on Android

1. Sign in on a physical Android device with Firebase configured (`google-services.json`).
2. Trigger a sale or stock-in that creates a notification for your user.
3. Confirm push delivery (background/terminated) and tap routing to **Notifications**.

Foreground messages show an in-app snackbar; taps use the existing Phase 5A `FcmMessageRouter`.

#### Edge Function tests (local)

```bash
deno test supabase/functions/send-push-notification/handler_test.ts
```

Uses mocks only — no real Firebase credentials or push sends.

### Notification hardening (Phase 5C)

Production semantics:

| Concern | Behavior |
|---------|----------|
| **Inbox (source of truth)** | `notifications` rows created by server RPCs only; Realtime + PostgREST in Flutter |
| **Mark as read** | RPC-only (`mark_notification_read`, `mark_all_notifications_read`); direct client UPDATE revoked (migration `0014`) |
| **Immutable fields** | `message`, `type`, `recipient_id`, `created_at` cannot be changed by clients |
| **Push (delivery channel)** | FCM sent only after INSERT webhook; inbox row is never deleted on push failure |
| **Preferences** | Filter inbox INSERT in `_notify_managers_owners`; push layer re-checks before FCM |
| **Low-stock alerts** | Threshold-crossing only: `previous_stock > limit AND new_stock <= limit` (migration `0014`) |
| **Stale FCM tokens** | Removed only on permanent FCM errors, scoped to `(user_id, token)` |
| **Webhook idempotency** | Duplicate webhook deliveries may send duplicate pushes (no dedup table) |

Apply migration `0014` after `0013` via `supabase db push` or SQL editor.

### Offline sync (Phase 5, Android)

See `lib/sync/README.md`. Web builds skip offline sync (`kIsWeb`).

---

## CI / GitHub Pages / APK

Workflow: `.github/workflows/deploy-web-preview.yml`

- `flutter analyze` and `flutter test` must pass (no `continue-on-error`)
- Deploys web preview to GitHub Pages
- Builds release APK artifact `android-apk` (debug-signed without a release keystore)

Repository secrets: `SUPABASE_URL`, `SUPABASE_ANON_KEY`

---

## Tests

```bash
flutter analyze
flutter test
```

Includes static SQL security checks for all migrations, unit/widget tests, and offline sync tests.

---

## Project structure

```
lib/
 ├─ core/           # config, theme, routing
 ├─ features/       # home, products, sale, stock, history, settings, auth
 ├─ models/
 ├─ repositories/
 ├─ services/       # Supabase, FCM, photos
 ├─ sync/           # Drift offline queue + sync engine
 └─ shared/widgets/
supabase/migrations/  # 0001–0014
supabase/functions/   # invite-staff, send-push-notification
test/
```
