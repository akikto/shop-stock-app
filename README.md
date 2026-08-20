# Shop Stock & Sales Management App

Mobile-first Flutter + Supabase app for a small shop (4–5 staff).
This README covers **Phase 0** only: schema, authentication, and app shell.

---

## What Phase 0 + Phase 1 contain

**Phase 0:** schema, RLS, authentication, app shell.

**Phase 1 (Product Management):**
- Add/Edit Product form (Bengali-first labels) — name, company,
  category, pack size, MRP, purchase price, sale price, low-stock
  limit. No current_stock field on this form; new products always
  start at 0.
- Product photo capture (camera or gallery), client-side compression
  into two variants (full + thumb), upload to a private Supabase
  Storage bucket.
- `create_product()`, `update_product()`, `deactivate_product()` — the
  only way products can be written from the client. See
  supabase/migrations/0006_product_management_rpc.sql.
- Product list: photo-first grid, partial-name search (pg_trgm-backed),
  lazy pagination, low-stock badge.
- Product detail screen (read-only fields, no stock editing control).
- Role-gated Edit/Deactivate (Owner/Manager only) and Add button.
- Every create/update/deactivate writes an `activity_logs` row.

## What Phase 1 intentionally does NOT contain

- Sale, Stock In, or Stock Adjustment (current_stock is still only
  ever set to 0 at creation and never changed anywhere in this phase).
- Notifications (push or in-app).
- Reports / dashboards.
- Offline transaction sync (photo upload/product creation still
  require connectivity in Phase 1).
- Photo cropping UI (capture + compress + preview only — cropping was
  marked "if practical" in the spec; adding it means an extra native
  package with per-platform setup that couldn't be verified in this
  sandbox, so it was deferred rather than shipped unverified).

---

## Prerequisites

- Flutter SDK (stable channel) — this repo was authored against Dart
  SDK constraint `>=3.3.0 <4.0.0`. Install Flutter and run
  `flutter doctor` to confirm your local setup before continuing.
- A Supabase project (free tier is enough for Phase 0).
- Supabase CLI (`npm install -g supabase` or see supabase.com/docs) —
  used to apply the SQL migrations.

---

## 1. Configure Supabase

1. Create a project at https://supabase.com.
2. In the Supabase SQL editor (or via CLI — see below), run the three
   migration files **in order**:
   - `supabase/migrations/0001_initial_schema.sql`
   - `supabase/migrations/0002_helper_functions.sql`
   - `supabase/migrations/0003_row_level_security.sql`

   Using the Supabase CLI instead:
   ```bash
   supabase link --project-ref YOUR_PROJECT_REF
   supabase db push
   ```

3. In your Supabase project dashboard, go to **Authentication → Providers**
   and confirm Email/Password sign-in is enabled.
4. Create your first user (the Owner) via **Authentication → Users → Add User**
   in the dashboard. A `profiles` row is created automatically for
   them by the `handle_new_user` trigger, with `role = 'staff'` by
   default.
5. **Promote that first user to Owner manually**, once only, directly
   in the SQL editor (there is no "first owner" bootstrap flow yet —
   this is a deliberate one-time manual step so that "owner" can never
   be self-assigned through the app):
   ```sql
   update public.profiles set role = 'owner' where id = '<their-auth-user-id>';
   ```
   After that, the Owner can use their Owner-only UPDATE policy to
   promote/demote other accounts once user-management UI exists
   (a later phase) — or via the SQL editor in the meantime.

---

## 2. Required environment variables

The Flutter app takes exactly two values, both **public/client-safe**:

| Key | Where to find it |
|---|---|
| `SUPABASE_URL` | Supabase dashboard → Project Settings → API |
| `SUPABASE_ANON_KEY` | Supabase dashboard → Project Settings → API → `anon` `public` key |

**Never** put the `service_role` key, or any Firebase server key, into
this app. Copy the example config and fill in your values:

```bash
cp config/config.example.json config/config.json
# edit config/config.json with your project's URL and anon key
```

`config/config.json` is gitignored — it will never be committed.

---

## 3. Running the app

```bash
flutter pub get
flutter run --dart-define-from-file=config/config.json
```

If you forget the `--dart-define-from-file` flag, the app fails fast
at startup with a clear error (see `lib/core/config/app_config.dart`)
rather than silently trying to reach an empty URL.

---

## 3b. Browser preview (Flutter Web)

**Flutter Web is enabled for preview/testing only.** The app remains,
and is meant to ship as, a native Android app — the web build exists
so you can look at screens without needing an Android device or
emulator handy. It uses the exact same `lib/` source and the exact
same Supabase project/RLS as the Android app; nothing about
authentication or security is different or weaker on web.

### Commands

```bash
flutter config --enable-web   # one-time, if `flutter devices` doesn't list Chrome/web-server
flutter pub get
flutter analyze
flutter test
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 --dart-define-from-file=config/config.json
flutter build web --dart-define-from-file=config/config.json
```

`flutter run -d web-server --web-hostname 0.0.0.0` starts a local dev
server reachable from other devices on the same network (not just
`localhost`) — useful for opening the preview on your phone's browser
while it's running on a computer on the same Wi-Fi. After it starts,
open `http://<that-computer's-LAN-IP>:8080` on your phone.

### The easiest way to get a preview URL: GitHub Pages (no local Flutter needed)

A GitHub Actions workflow is already set up at
`.github/workflows/deploy-web-preview.yml`. It builds the web preview
**on GitHub's servers** and publishes it to GitHub Pages — you never
need Flutter installed anywhere yourself. One-time setup:

1. Push this repository to GitHub (if you haven't already).
2. Repo **Settings → Pages → Source → "GitHub Actions"**.
3. Repo **Settings → Secrets and variables → Actions → New repository
   secret**, add:
   - `SUPABASE_URL` — your project's URL (same value as in
     `config/config.json`)
   - `SUPABASE_ANON_KEY` — your project's public anon key (same value
     as in `config/config.json`). **Never** put the `service_role` key
     here or anywhere in this repo.
4. Push to `main` (or run the workflow manually from the Actions tab).
5. After it finishes (a few minutes), your preview is live at:
   `https://<your-github-username>.github.io/<repo-name>/`

If your repository is not named `shop-stock-app`, edit the `BASE_HREF`
value near the top of `.github/workflows/deploy-web-preview.yml` to
match — it must be `/<your-repo-name>/`, matching how GitHub Pages
serves a "project site". A mismatched base href is the most common
cause of a blank white page on Pages.

### Android / Termux

Flutter's SDK is not officially supported for running the `flutter`
CLI directly inside Termux — this is a genuine limitation, not
something this project can configure around. The reliable path for a
phone-only workflow is the GitHub Pages route above: push from Termux
using `git` (which does work fine in Termux), let GitHub Actions do
the actual Flutter build, then just open the resulting Pages URL in
your phone's browser. That is the recommended way to preview this app
from an Android/Termux-only setup.

If you do want to experiment with Flutter directly in Termux, community
projects exist for this, but they're unofficial and can break between
Flutter releases — treat that path as experimental, not as this
project's supported workflow.

### Deploying `build/web` elsewhere

`flutter build web` output in `build/web/` is a plain static site — it
can be deployed to any static host (Netlify, Vercel, Firebase Hosting,
a plain S3 bucket, etc.), not just GitHub Pages. For any host other
than a GitHub Pages *project* site, build with `--base-href /` (the
default) instead of a repo-specific path.

### Browser preview troubleshooting

- **Blank white page, nothing in the browser console errors:** usually
  a `--base-href` mismatch — the deployed URL's path must exactly
  match what was passed to `flutter build web --base-href ...`.
- **Blank white page with a 404 for `flutter_bootstrap.js` or
  `main.dart.js` in the browser console:** this repo's
  `web/index.html` was hand-authored (not generated by a local
  `flutter create`, since that wasn't available while building this
  project) using the loader pattern current stable Flutter expects. If
  your installed Flutter SDK is old enough to expect the previous
  loader (`flutter.js` + `_flutter.loader.loadEntrypoint`), run
  `flutter create --platforms web .` once from the project root — it
  will safely regenerate just the `web/` platform boilerplate to match
  your exact installed SDK, without touching `lib/`, `test/`, or
  `supabase/`.
- **Camera/gallery photo picking behaves differently than on Android:**
  expected — a browser can only offer its own file-picker UI for
  "camera", and some browsers restrict camera access to secure
  (HTTPS) origins. GitHub Pages serves over HTTPS, so this should work
  there; a plain `flutter run -d web-server` over `http://` on a LAN
  IP may prompt differently or block camera access depending on the
  browser. This is a browser/OS constraint, not a bug in this project.

---

## 4. How authentication works

- Login is email + password via Supabase Auth (`AuthRepository`,
  `lib/repositories/auth_repository.dart`). Phone/OTP can replace this
  later without changing the rest of the app, since all screens go
  through `AuthRepository`, never the Supabase client directly.
- `GoRouter`'s `redirect` callback (`lib/core/routing/app_router.dart`)
  is the single enforcement point: any route is redirected to `/login`
  unless a session exists, and `/login` itself redirects away once
  signed in.
- A valid session is **not sufficient** on its own — the app also
  loads the user's `profiles` row (`currentProfileProvider`) and
  blocks access with a clear message if `is_active = false`. This
  covers the case of a disabled account whose auth token hasn't
  expired yet.
- Role (`owner` / `manager` / `staff`) is read from `profiles.role`
  and exposed via `UserRole` (`lib/models/user_role.dart`). No screen
  in Phase 0 yet branches on role — that begins in the phase that adds
  real Sale/Stock/Reports logic.
- A user can never change their own `role` or `is_active` — blocked by
  both an RLS policy shape and a dedicated Postgres trigger
  (`prevent_self_role_change`), so the restriction holds even if one
  layer is misconfigured later.
- **`products` is fully read-only from the client in Phase 0** — no
  INSERT or UPDATE policy exists, only SELECT. This was corrected
  during a Phase 0 security review: an earlier version of this
  migration let Manager/Owner INSERT/UPDATE products directly, which
  would also have allowed editing `current_stock` from the client,
  contradicting this project's core rule that stock must only ever
  change via a future server-side RPC. Product creation/editing (name,
  price, photo, etc.) is deferred to the phase that introduces that
  RPC pattern, rather than adding a partial client-write exception now.
- **`profiles` phone numbers are not exposed to every authenticated
  user.** A user can always read their own full profile row (including
  phone), and Owner/Manager can read every profile's full row (needed
  to actually contact staff). A plain staff member cannot directly
  `select * from profiles` for other users. Instead, cross-user "who
  did this" name lookups (for future History/attribution screens) go
  through `public.list_profiles_public()` — a `SECURITY DEFINER`
  Postgres function that returns only `id, name, role, is_active`,
  never `phone`. This keeps one source of truth (the `profiles` table)
  while narrowing what a non-privileged client can read from it,
  without needing a second synced table or a client-side workaround.

---

## 5. Database migrations

Migrations are plain, numbered SQL files in `supabase/migrations/`,
designed to be run once, in order, via `supabase db push` or pasted
into the SQL editor. They are idempotent where practical (`create
table if not exists`, `create or replace function`, `drop policy if
exists` before `create policy`) so re-running them is safe.

1. `0001_initial_schema.sql` — enums, tables, constraints
2. `0002_helper_functions.sql` — role-check functions, triggers,
   `list_profiles_public()`
3. `0003_row_level_security.sql` — RLS policies
4. `0004_product_photos_storage.sql` — private Storage bucket + policies
5. `0005_product_search_index.sql` — pg_trgm index for partial-name search
6. `0006_product_management_rpc.sql` — `create_product`/`update_product`/
   `deactivate_product`

---

## 6. Project structure

```
lib/
 ├─ core/            # config, theme, routing, responsive (app-wide, not feature-specific)
 ├─ models/           # plain Dart models mirroring DB rows
 ├─ repositories/     # sole boundary between app and Supabase
 ├─ services/         # Supabase client bootstrap, image/photo services
 ├─ features/         # one folder per screen/domain area
 ├─ shared/widgets/   # reusable UI (loading, error, app shell, product photo)
 └─ sync/             # Phase 5: Drift offline queue, product cache, sync engine
supabase/migrations/  # numbered SQL, source of truth for the schema
web/                  # Flutter Web preview platform files (index.html, manifest.json, icons)
.github/workflows/    # CI: builds the web preview and deploys it to GitHub Pages
test/                 # unit + widget tests (see below)
```

---

## 7. Running tests

```bash
flutter analyze
flutter test
```

Test coverage in Phase 0:

- `test/models/profile_test.dart` — `UserRole`/`Profile` parsing and
  role-permission flags.
- `test/auth/auth_state_test.dart` — auth/profile providers, using a
  `FakeAuthRepository` test double (no real network calls).
- `test/routing/protected_route_test.dart` — confirms an
  unauthenticated user is redirected to Login and never renders the
  protected shell; confirms a deactivated account is blocked with a
  clear message instead of reaching the shell.
- `test/database/security_assumptions_test.dart` — statically checks
  the migration SQL itself for the safety guarantees this app depends
  on (non-negative stock constraint, no client-writable
  sales/stock/audit tables, RLS enabled everywhere, idempotency key
  present). This guards against someone accidentally weakening a
  policy in a future edit; it is not a substitute for testing against
  a real Supabase project.

**Not covered by automated tests in Phase 0:** live Row Level Security
behavior against an actual Postgres instance (e.g., "can a `staff`
row actually not `UPDATE` another user's role") — that requires a
running Supabase project and is listed as a manual verification step
in the Phase 0 completion report.

---

## Phase 5 — Offline sync (Android-first)

Phase 5 adds **offline Sale, Stock In, and Stock Adjustment** on native
Android. Web preview builds skip offline sync (`kIsWeb`).

### Supported offline operations

- Record Sale (`record_sale` RPC)
- Record Stock In (`record_stock_in` RPC)
- Record Stock Adjustment (`record_adjustment` RPC, Manager/Owner only)
- Read active products from a **local cache** for Sale/Stock pickers

### Out of scope (still require connectivity)

- Product create/edit/deactivate
- Photo upload
- Firebase push notifications
- History, Dashboard, Reports
- Login / authentication
- Web offline sync

### Queue behavior

- Each offline write generates a **stable `device_txn_id` (UUID)** once
  and stores a row in local SQLite (`pending_transactions`).
- Optimistic cache updates adjust `cached_products.current_stock` for UI.
- UI receives `TransactionWriteResult.queuedLocally` and shows a Bengali
  “saved locally” snackbar.

### Sync behavior

- `SyncCoordinator` triggers sync on reconnect, app resume, and manual retry.
- `SyncEngine` replays the queue **FIFO** using the same `device_txn_id` on
  every retry.
- Network errors keep rows **pending**; business errors (e.g. insufficient
  stock) mark rows **failed** (no automatic retry).
- Successful sync refreshes the product cache and invalidates Riverpod providers.
- Server migration `0011_offline_sync_idempotency.sql` makes RPC replay
  idempotent — duplicate `device_txn_id` returns the existing ledger row
  without double stock mutation.

### Stale cache

- Offline pickers show cached stock with a Bengali stale-data warning.
- Cache is refreshed after successful sync when online.

### Conflict resolution

- Client queue is authoritative for replay order (FIFO).
- Server enforces stock/role rules at sync time; conflicts become **failed**
  pending rows (user can retry or delete from Settings).

### Known limitations

- Android-first: no offline sync on web.
- Cache may be stale while offline; insufficient stock may only surface at sync.
- Integration scenarios A–D in `integration_test/offline_sync_test.dart`
  require **manual execution** on Android with network toggling.

See also `lib/sync/README.md`.

---

## 8. What comes after Phase 0

Per the approved phased plan: Product Management + photo capture,
Quick Sale / Quick Stock In / Stock Adjustment (via secure RPC),
Realtime + push notifications, History/Reports, then Offline Sync,
then polish. Each is a separate, approved phase — this app does not
proceed to the next phase automatically.
