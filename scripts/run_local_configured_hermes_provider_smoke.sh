#!/usr/bin/env bash
set -euo pipefail

if ! command -v hermes >/dev/null 2>&1; then
  echo "hermes is not on PATH. Install it first: curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash" >&2
  exit 1
fi

for cmd in curl python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required for the local configured Hermes provider smoke." >&2
    exit 1
  fi
done

configured_hermes_home="${NAVIVOX_CONFIGURED_HERMES_HOME:-${HERMES_HOME:-$HOME/.hermes}}"
if [ ! -f "$configured_hermes_home/config.yaml" ]; then
  echo "No Hermes config.yaml found at ${configured_hermes_home}. Set NAVIVOX_CONFIGURED_HERMES_HOME to a configured Hermes home." >&2
  exit 2
fi

hermes_home="$configured_hermes_home"
cloned_hermes_home=""
if [ "${NAVIVOX_CONFIGURED_HERMES_CLONE_HOME:-true}" = "true" ]; then
  cloned_hermes_home="$(mktemp -d -t navivox-configured-hermes-home.XXXXXX)"
  chmod 700 "$cloned_hermes_home"
  hermes_home="$cloned_hermes_home"
  for file in config.yaml .env auth.json SOUL.md; do
    if [ -f "$configured_hermes_home/$file" ]; then
      cp -p "$configured_hermes_home/$file" "$hermes_home/$file"
    fi
  done
fi

port="${NAVIVOX_CONFIGURED_HERMES_PORT:-28642}"
host="${NAVIVOX_CONFIGURED_HERMES_HOST:-127.0.0.1}"
api_key="${NAVIVOX_CONFIGURED_HERMES_API_KEY:-$(python3 - <<'PY'
import secrets
print('navivox-provider-' + secrets.token_urlsafe(24))
PY
)}"
base_url="http://${host}:${port}"
hermes_log="${NAVIVOX_CONFIGURED_HERMES_LOG:-/tmp/navivox-configured-hermes.log}"
hermes_pid=""
cleanup() {
  if [ -n "$hermes_pid" ]; then kill "$hermes_pid" 2>/dev/null || true; fi
  if [ -n "$cloned_hermes_home" ]; then rm -rf "$cloned_hermes_home"; fi
}
trap cleanup EXIT INT TERM

gateway_args=(gateway run)
if [ -n "$cloned_hermes_home" ]; then gateway_args+=(--force); fi

API_SERVER_ENABLED=true \
API_SERVER_KEY="$api_key" \
API_SERVER_HOST="$host" \
API_SERVER_PORT="$port" \
API_SERVER_CORS_ORIGINS="http://127.0.0.1:8767,http://localhost:8767" \
HERMES_HOME="$hermes_home" \
  hermes "${gateway_args[@]}" >"$hermes_log" 2>&1 &
hermes_pid=$!

ready=0
for _ in $(seq 1 60); do
  if curl -fsS -H "Authorization: Bearer ${api_key}" "${base_url}/health" >/dev/null 2>&1; then
    ready=1
    break
  fi
  if ! kill -0 "$hermes_pid" 2>/dev/null; then break; fi
  sleep 1
done

if [ "$ready" != 1 ]; then
  echo "Configured Hermes API server did not become ready on ${base_url}. Log: ${hermes_log}" >&2
  tail -120 "$hermes_log" >&2 || true
  exit 1
fi

NAVIVOX_PROVIDER_HERMES_URL="$base_url" \
NAVIVOX_PROVIDER_HERMES_API_KEY="$api_key" \
  "$(dirname "$0")/run_provider_hermes_smoke.sh"
