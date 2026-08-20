# sync/ — Phase 5 offline transaction queue

Offline Sale, Stock In, and Stock Adjustment for **Android native** builds.

## Architecture

- `database/sync_database_io.dart` — Drift SQLite schema (conditional export; web uses stub)
- `repositories/` — product cache + pending transaction queue
- `services/connectivity_service.dart` — online/offline detection
- `services/sync_engine.dart` — FIFO replay via RPC with stable `device_txn_id`
- `services/sync_coordinator.dart` — reconnect / resume triggers (debounced)
- `repositories/offline_aware_transaction_repository.dart` — online RPC vs local queue
- `providers/sync_providers.dart` — Riverpod wiring
- `sync_bootstrap.dart` — opens DB after Supabase init (skipped on web)

## Server idempotency

Migration `0011_offline_sync_idempotency.sql` makes `record_sale`, `record_stock_in`,
and `record_adjustment` return existing ledger rows for duplicate `device_txn_id`
without double stock mutation.

## Offline-supported operations

- Sale, Stock In, Stock Adjustment (queued locally)
- Active product picker from cache (stale OK)

## Out of scope

- Product CRUD offline, photo upload, push, History/Dashboard/Reports, login, web offline sync

## Queue / sync behavior

- UUID `device_txn_id` generated once per offline write
- FIFO replay; network errors stay pending; business errors (e.g. insufficient stock) fail
- Successful sync refreshes product cache and invalidates providers

Web preview builds skip offline sync (`kIsWeb`).
