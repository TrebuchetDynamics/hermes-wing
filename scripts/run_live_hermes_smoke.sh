#!/usr/bin/env bash
set -euo pipefail

if ! command -v hermes >/dev/null 2>&1; then
  echo "hermes is not on PATH. Install it first: curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash" >&2
  exit 1
fi

for cmd in flutter node npx curl python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required for the live Hermes smoke." >&2
    exit 1
  fi
done

port="${WING_LIVE_HERMES_PORT:-18642}"
host="${WING_LIVE_HERMES_HOST:-127.0.0.1}"
api_key="${WING_LIVE_HERMES_API_KEY:-$(python3 - <<'PY'
import secrets
print('wing-live-' + secrets.token_urlsafe(24))
PY
)}"
base_url="http://${host}:${port}"
hermes_home="${WING_LIVE_HERMES_HOME:-$(mktemp -d -t wing-hermes-home.XXXXXX)}"
web_log="${WING_LIVE_WEB_LOG:-/tmp/wing-live-web.log}"
hermes_log="${WING_LIVE_HERMES_LOG:-/tmp/wing-live-hermes.log}"

hermes_pid=""
web_pid=""
cleanup() {
  if [ -n "$web_pid" ]; then kill "$web_pid" 2>/dev/null || true; fi
  if [ -n "$hermes_pid" ]; then kill "$hermes_pid" 2>/dev/null || true; fi
  if [ -z "${WING_LIVE_HERMES_HOME:-}" ]; then rm -rf "$hermes_home"; fi
}
trap cleanup EXIT

mkdir -p "$hermes_home"

API_SERVER_ENABLED=true \
API_SERVER_KEY="$api_key" \
API_SERVER_HOST="$host" \
API_SERVER_PORT="$port" \
API_SERVER_CORS_ORIGINS="http://127.0.0.1:8767,http://localhost:8767" \
HERMES_HOME="$hermes_home" \
  hermes gateway run --force >"$hermes_log" 2>&1 &
hermes_pid=$!

ready=0
for _ in $(seq 1 45); do
  if curl -fsS -H "Authorization: Bearer ${api_key}" "${base_url}/health" >/dev/null 2>&1; then
    ready=1
    break
  fi
  if ! kill -0 "$hermes_pid" 2>/dev/null; then break; fi
  sleep 1
done

if [ "$ready" != 1 ]; then
  echo "Hermes API server did not become ready on ${base_url}. Log: ${hermes_log}" >&2
  tail -120 "$hermes_log" >&2 || true
  exit 1
fi

curl -fsS -H "Authorization: Bearer ${api_key}" "${base_url}/v1/capabilities" >/dev/null

flutter build web --release -t lib/main_e2e.dart
node serve_web.mjs >"$web_log" 2>&1 &
web_pid=$!

web_ready=0
for _ in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:8767/ >/dev/null 2>&1; then
    web_ready=1
    break
  fi
  if ! kill -0 "$web_pid" 2>/dev/null; then break; fi
  sleep 1
done

if [ "$web_ready" != 1 ]; then
  echo "Hermes Wing web server did not become ready. Log: ${web_log}" >&2
  tail -120 "$web_log" >&2 || true
  exit 1
fi

WING_LIVE_HERMES_URL="$base_url" \
WING_LIVE_HERMES_API_KEY="$api_key" \
  npx playwright test --config=playwright.config.mjs playwright/tests/regression/hermes-live-api.spec.mjs --reporter=list

cat <<'EOF'
Installed-Hermes live smoke passed for API connect/session rendering only.
This uses an isolated temp home by default; it is not provider/model evidence,
not a chat/voice provider smoke, and not physical microphone evidence.
It is not whole-goal completion evidence by itself; run
WING_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit before any completion claim.
EOF
