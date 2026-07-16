#!/usr/bin/env bash
set -euo pipefail

if [ -z "${WING_PROVIDER_HERMES_URL:-}" ]; then
  cat >&2 <<'EOF'
WING_PROVIDER_HERMES_URL is required.
Point it at a running Hermes Agent API server that is configured with a real provider/model.
Optional:
  WING_PROVIDER_HERMES_API_KEY
  WING_PROVIDER_TEXT_PROMPT / WING_PROVIDER_TEXT_EXPECTED
  WING_PROVIDER_VOICE_PROMPT / WING_PROVIDER_VOICE_EXPECTED
EOF
  exit 2
fi

for cmd in flutter node npx curl python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required for the provider-backed Hermes smoke." >&2
    exit 1
  fi
done

base_url="${WING_PROVIDER_HERMES_URL%/}"
safe_receipt_base_url="$(python3 - "$base_url" <<'PY'
from urllib.parse import urlsplit, urlunsplit
import sys
parts = urlsplit(sys.argv[1])
host = parts.hostname or ''
if ':' in host and not host.startswith('['):
    host = f'[{host}]'
if parts.port:
    host = f'{host}:{parts.port}'
print(urlunsplit((parts.scheme, host, '', '', '')))
PY
)"
web_log="${WING_PROVIDER_WEB_LOG:-/tmp/wing-provider-web.log}"
headers=()
if [ -n "${WING_PROVIDER_HERMES_API_KEY:-}" ]; then
  headers=(-H "Authorization: Bearer ${WING_PROVIDER_HERMES_API_KEY}")
fi

curl -fsS "${headers[@]}" "${base_url}/health" >/dev/null
curl -fsS "${headers[@]}" "${base_url}/v1/capabilities" >/dev/null

flutter build web --release -t lib/main_e2e.dart

web_pid=""
cleanup() {
  if [ -n "$web_pid" ]; then kill "$web_pid" 2>/dev/null || true; fi
}
trap cleanup EXIT

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

npx playwright test --config=playwright.config.mjs playwright/tests/regression/hermes-provider-chat.spec.mjs --reporter=list --retries=0

receipt_path="${WING_PROVIDER_SMOKE_RECEIPT:-build/receipts/hermes-provider-smoke.json}"
head_sha="$(git rev-parse HEAD 2>/dev/null || true)"
mkdir -p "$(dirname "$receipt_path")"
cat >"$receipt_path" <<EOF
{
  "kind": "hermes_provider_smoke",
  "status": "passed",
  "timestamp_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "head_sha": "${head_sha}",
  "base_url": "${safe_receipt_base_url}",
  "coverage": "typed text plus deterministic transcript voice",
  "playwright_retries": 0,
  "evidence_for": [
    "provider-backed Hermes typed text turn",
    "deterministic transcript voice turn"
  ],
  "not_evidence_for": [
    "physical Android microphone audio",
    "Hermes realtime/server audio",
    "native-host Windows/iOS/macOS receipts",
    "platform workflow publication",
    "deferred Hermes Desktop parity surfaces",
    "whole-goal completion"
  ]
}
EOF
printf 'Provider smoke receipt: %s\n' "$receipt_path"

cat <<'EOF'
Provider-backed Hermes smoke passed for typed text plus deterministic transcript voice only.
This is not physical microphone evidence and does not prove Hermes realtime/server audio.
It is not whole-goal completion evidence by itself; run
WING_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit before any completion claim.
EOF
