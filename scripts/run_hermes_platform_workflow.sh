#!/usr/bin/env bash
set -euo pipefail

workflow_name="${NAVIVOX_HERMES_PLATFORM_WORKFLOW:-Hermes platform smoke}"
ref="${NAVIVOX_WORKFLOW_REF:-$(git branch --show-current 2>/dev/null || true)}"
run_provider="${NAVIVOX_RUN_PROVIDER_SMOKE:-false}"
provider_url="${NAVIVOX_PROVIDER_HERMES_URL:-}"
run_android="${NAVIVOX_RUN_ANDROID_EMULATOR_SMOKE:-false}"
watch="${NAVIVOX_WATCH_WORKFLOW:-true}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh is required to dispatch the Hermes platform workflow." >&2
  exit 1
fi

if [ -z "$ref" ]; then
  echo "Could not determine git ref. Set NAVIVOX_WORKFLOW_REF." >&2
  exit 1
fi

workflow_list="$(gh workflow list 2>&1 || true)"
if ! printf '%s\n' "$workflow_list" | grep -Fq "$workflow_name"; then
  cat >&2 <<EOF
Workflow '$workflow_name' is not visible to gh.
Publish .github/workflows/hermes-platform-smoke.yml to the remote branch first,
or ensure the current token/repository can read workflows.

Visible workflows:
$workflow_list
EOF
  exit 2
fi

if [ "$run_provider" = "true" ] && [ -z "$provider_url" ]; then
  echo "NAVIVOX_PROVIDER_HERMES_URL is required when NAVIVOX_RUN_PROVIDER_SMOKE=true." >&2
  exit 1
fi

args=(
  workflow run "$workflow_name"
  --ref "$ref"
  -f "run_provider_smoke=$run_provider"
  -f "provider_url=$provider_url"
  -f "run_android_emulator_smoke=$run_android"
)

printf 'Dispatching %s on %s\n' "$workflow_name" "$ref"
gh "${args[@]}"

# Give GitHub a moment to create the run, then show the newest matching run.
sleep "${NAVIVOX_WORKFLOW_RUN_DISCOVERY_DELAY_SECONDS:-5}"
run_id="$(gh run list --workflow "$workflow_name" --branch "$ref" --limit 1 --json databaseId --jq '.[0].databaseId // empty')"
if [ -z "$run_id" ]; then
  cat >&2 <<'EOF'
Workflow dispatched, but no run id was visible yet. This is not a platform receipt.
Check gh run list/gh run view and collect successful job evidence before claiming readiness.
EOF
  exit 4
fi

echo "Run: $(gh run view "$run_id" --json url --jq '.url')"

if [ "$watch" = "true" ]; then
  gh run watch "$run_id" --exit-status
else
  cat <<'EOF'
Workflow dispatch succeeded, but NAVIVOX_WATCH_WORKFLOW=false did not wait for job results.
Collect successful Windows/iOS/Android/Linux job receipts before claiming platform readiness.
EOF
fi
