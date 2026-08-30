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

   `0001` → `0002` → `0003` → `0004` → `0005` → `0006` → `0007` → `0008` → `0009` → `0010` → `0011` → `0012`

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
- **Owner:** + staff role/activation management

---

## Offline sync (Phase 5, Android)

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
supabase/migrations/  # 0001–0012
test/
```
