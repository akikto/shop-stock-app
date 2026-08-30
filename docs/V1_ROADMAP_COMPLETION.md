# v1.0 Roadmap Completion Matrix

Source of truth: Technical Implementation Plan v1.0 (Phases 0–6).

| Phase | Requirement | Status | Evidence |
|-------|-------------|--------|----------|
| 0 | Schema, enums, constraints | Done | `0001_initial_schema.sql` |
| 0 | Helper functions, triggers | Done | `0002_helper_functions.sql` |
| 0 | RLS on all core tables | Done | `0003_row_level_security.sql` |
| 0 | Auth + guarded router | Done | `auth_repository.dart`, `app_router.dart` |
| 0 | App shell navigation | Done | `app_shell.dart` |
| 1 | Product CRUD via RPC | Done | `0006`, `0009`, `product_repository.dart` |
| 1 | Product photos (private bucket) | Done | `0004`, `product_photo_service.dart` |
| 1 | Product search (pg_trgm) | Done | `0005` |
| 2 | Sale RPC | Done | `0008`, `transaction_repository.dart` |
| 2 | Stock in RPC | Done | `0008` |
| 2 | Stock adjustment RPC (manager+) | Done | `0008` |
| 2 | Activity log on every write | Done | RPCs in `0008`+ |
| 3 | Supabase Realtime | Done | `0012`, `notification_providers.dart` |
| 3 | In-app notifications | Done | `0010`, `notifications_screen.dart` |
| 3 | FCM token registration | Done | `0012`, `fcm_service.dart` |
| 3 | Notification preferences | Done | `notification_preferences_screen.dart` |
| 4 | Role-aware dashboard | Done | `home_screen.dart` |
| 4 | Staff/product sales reports | Done | `reports_screen.dart` |
| 4 | Stock movement report | Done | `0012`, reports tab 3 |
| 4 | Low-stock alerts list | Done | `low_stock_screen.dart` |
| 4 | History / audit trail | Done | `history_screen.dart` |
| 5 | Drift offline queue | Done | `lib/sync/` |
| 5 | Idempotent RPC replay | Done | `0011_offline_sync_idempotency.sql` |
| 5 | Pending transactions UI | Done | `pending_transactions_screen.dart` |
| 5 | Sync conflict auto-logging | Done | `0013`, `sync_engine.dart` |
| 6 | Staff management (Owner) | Done | `staff_management_screen.dart` |
| 6 | Staff invite (Owner) | Done | `invite-staff` function, `invite_staff_screen.dart` |
| 6 | Sync conflict review | Done | `sync_conflicts_screen.dart` |
| 6 | CI analyze/test gates | Done | `deploy-web-preview.yml` |
| 6 | Version 1.0.x | Done | `pubspec.yaml` |

## Known limitations

- Android `android/` folder generated in CI when not committed.
- FCM push **delivery** requires Firebase + `google-services.json` (token registration works).
- Staff invite requires deploying `supabase/functions/invite-staff`.
- Offline integration tests require manual Android execution.
