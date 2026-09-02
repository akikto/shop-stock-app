#!/usr/bin/env bash
# Production deploy helper for Replit (or any machine with Supabase CLI + Flutter).
# Set env vars first — never commit secrets.
#
# Required:
#   SUPABASE_PROJECT_REF
#   SUPABASE_ACCESS_TOKEN
#   SUPABASE_ANON_KEY
#   FIREBASE_SERVICE_ACCOUNT_JSON   (path to Firebase service account JSON file)
#   PUSH_WEBHOOK_SECRET             (openssl rand -hex 32)
#
# Optional:
#   OWNER_AUTH_USER_ID              (promote first user to owner after signup)

set -euo pipefail
cd "$(dirname "$0")/.."

require() {
  if [[ -z "${!1:-}" ]]; then
    echo "Missing env: $1" >&2
    exit 1
  fi
}

require SUPABASE_PROJECT_REF
require SUPABASE_ACCESS_TOKEN
require SUPABASE_ANON_KEY
require FIREBASE_SERVICE_ACCOUNT_JSON
require PUSH_WEBHOOK_SECRET

if [[ ! -f "$FIREBASE_SERVICE_ACCOUNT_JSON" ]]; then
  echo "Firebase JSON not found: $FIREBASE_SERVICE_ACCOUNT_JSON" >&2
  exit 1
fi

echo "==> Supabase login + link"
supabase login --token "$SUPABASE_ACCESS_TOKEN"
supabase link --project-ref "$SUPABASE_PROJECT_REF"

echo "==> Apply migrations 0001-0014 (or reconcile if remote drift)"
if ! supabase db push; then
  echo ""
  echo "db push failed (remote migration history mismatch is common)."
  echo "Run: bash scripts/reconcile_migrations.sh"
  echo "Then apply 0014 in SQL Editor if needed, repair history, and:"
  echo "  bash scripts/finish_deploy.sh"
  exit 1
fi

if [[ -n "${OWNER_AUTH_USER_ID:-}" ]]; then
  echo "==> Promote owner"
  supabase db execute --sql "UPDATE public.profiles SET role = 'owner' WHERE id = '$OWNER_AUTH_USER_ID';"
fi

echo "==> Edge Function secrets"
supabase secrets set \
  FIREBASE_SERVICE_ACCOUNT="$(cat "$FIREBASE_SERVICE_ACCOUNT_JSON")" \
  PUSH_WEBHOOK_SECRET="$PUSH_WEBHOOK_SECRET"

echo "==> Deploy Edge Functions"
supabase functions deploy invite-staff
supabase functions deploy send-push-notification --no-verify-jwt

echo "==> App config (anon key only)"
mkdir -p config
cat > config/config.json <<EOF
{
  "SUPABASE_URL": "https://${SUPABASE_PROJECT_REF}.supabase.co",
  "SUPABASE_ANON_KEY": "${SUPABASE_ANON_KEY}"
}
EOF

echo "==> Flutter verify + APK"
flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define-from-file=config/config.json

echo "==> Deno Edge Function tests"
deno test supabase/functions/send-push-notification/handler_test.ts
deno test supabase/functions/send-push-notification/preferences_test.ts

echo ""
echo "DONE. Manual steps remaining in Supabase Dashboard:"
echo "  1. Authentication → enable Email provider"
echo "  2. Database → Webhooks → notifications INSERT → send-push-notification"
echo "     Header: x-push-webhook-secret = \$PUSH_WEBHOOK_SECRET"
echo "  3. Run scripts/verify_production.sql in SQL Editor"
echo "  4. Place google-services.json in android/app/ (package: com.akikto.shop_stock_app)"
echo "  5. Test push on a physical Android device"
