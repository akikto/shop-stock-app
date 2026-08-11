# sync/ — reserved for a later phase

This folder is intentionally empty in Phase 0.

Per the approved architecture, offline transaction support will live
here: a local SQLite (Drift) queue of pending Sale / Stock In /
Adjustment actions, plus a sync engine that replays them against the
server-side RPC functions once connectivity returns, using
`device_txn_id` for idempotent retries.

Not implemented yet — see the phased implementation plan.
