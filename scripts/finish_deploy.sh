#!/usr/bin/env bash
# Finish production deploy AFTER migrations are reconciled (skip db push).
# Requires: supabase link already done, 0014 applied if app uses mark-as-read RPCs.
#
# Required env:
#   SUPABASE_PROJECT_REF=mkdzpanryypllwebuggs
#   SUPABASE_ACCESS_TOKEN
#   SUPABASE_ANON_KEY
#   PUSH_WEBHOOK_SECRET
# Optional:
#   FIREBASE_SERVICE_ACCOUNT_JSON  (skip push secrets if unset)
#   OWNER_AUTH_USER_ID

set -euo pipefail
cd "$(dirname "$0")/.."

require() { [[ -n "${!1:-}" ]] || { echo "Missing: $1" >&2; exit 1; }; }
require SUPABASE_PROJECT_REF
require SUPABASE_ACCESS_TOKEN
require SUPABASE_ANON_KEY
require PUSH_WEBHOOK_SECRET

command -v supabase >/dev/null || { echo "npm install -g supabase" >&2; exit 1; }

supabase login --token "$SUPABASE_ACCESS_TOKEN"
supabase link --project-ref "$SUPABASE_PROJECT_REF"

if [[ -n "${FIREBASE_SERVICE_ACCOUNT_JSON:-}" && -f "$FIREBASE_SERVICE_ACCOUNT_JSON" ]]; then
  supabase secrets set \
    FIREBASE_SERVICE_ACCOUNT="$(cat "$FIREBASE_SERVICE_ACCOUNT_JSON")" \
    PUSH_WEBHOOK_SECRET="$PUSH_WEBHOOK_SECRET"
else
  echo "Skipping FIREBASE_SERVICE_ACCOUNT (set FIREBASE_SERVICE_ACCOUNT_JSON to enable push)"
  supabase secrets set PUSH_WEBHOOK_SECRET="$PUSH_WEBHOOK_SECRET"
fi

supabase functions deploy invite-staff
supabase functions deploy send-push-notification --no-verify-jwt

if [[ -n "${OWNER_AUTH_USER_ID:-}" ]]; then
  supabase db execute --sql \
    "UPDATE public.profiles SET role = 'owner' WHERE id = '$OWNER_AUTH_USER_ID';"
fi

mkdir -p config
cat > config/config.json <<EOF
{
  "SUPABASE_URL": "https://${SUPABASE_PROJECT_REF}.supabase.co",
  "SUPABASE_ANON_KEY": "${SUPABASE_ANON_KEY}"
}
EOF

echo ""
echo "=== Manual (Dashboard) ==="
echo "1. Authentication → Email ON"
echo "2. Database → Webhooks → notifications INSERT → send-push-notification"
echo "   Header: x-push-webhook-secret = \$PUSH_WEBHOOK_SECRET"
echo "3. SQL Editor → scripts/verify_production.sql"
echo "4. android/app/google-services.json (package com.akikto.shop_stock_app)"
echo ""
echo "Deploy functions: DONE"
