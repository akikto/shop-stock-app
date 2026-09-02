#!/usr/bin/env bash
# Safe migration reconciliation when remote has versions not in local repo.
# Does NOT overwrite remote schema. Run after: supabase link --project-ref mkdzpanryypllwebuggs
#
# Usage:
#   export SUPABASE_ACCESS_TOKEN=...
#   export SUPABASE_PROJECT_REF=mkdzpanryypllwebuggs
#   bash scripts/reconcile_migrations.sh

set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v supabase >/dev/null; then
  echo "Install Supabase CLI first: npm install -g supabase" >&2
  exit 1
fi

require() { [[ -n "${!1:-}" ]] || { echo "Missing: $1" >&2; exit 1; }; }
require SUPABASE_ACCESS_TOKEN
require SUPABASE_PROJECT_REF

supabase login --token "$SUPABASE_ACCESS_TOKEN"
supabase link --project-ref "$SUPABASE_PROJECT_REF"

echo "=== Local migration files (repo) ==="
ls -1 supabase/migrations/*.sql | sed 's|supabase/migrations/||'

echo ""
echo "=== Remote migration history ==="
supabase migration list --linked || true

echo ""
echo "=== Next steps (safe order) ==="
cat <<'EOF'
1. Open Supabase Dashboard → SQL Editor
2. Run scripts/audit_migration_history.sql (read-only)
3. Check mark_notification_read exists:
   - YES → schema is at 0014; sync history only (step 4)
   - NO  → run full supabase/migrations/0014_notification_hardening.sql in SQL Editor, then step 4
4. Sync CLI history WITHOUT re-running SQL:
   For each local file in supabase/migrations/ that matches remote schema:
     supabase migration repair --status applied <version>
   (<version> is the numeric prefix, e.g. 0014 for 0014_notification_hardening.sql)
5. Do NOT use db push until migration list shows local == remote
6. Continue: bash scripts/finish_deploy.sh
EOF

echo ""
echo "=== 0014 quick check (run in SQL Editor) ==="
echo "SELECT proname FROM pg_proc WHERE proname = 'mark_notification_read';"
