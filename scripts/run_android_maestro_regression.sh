#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MAESTRO_BIN="${MAESTRO_BIN:-maestro}"
GATEWAY_LABEL="${WING_QA_GATEWAY_LABEL:-$(hostname)}"
PROFILE_LABEL="${WING_QA_PROFILE_LABEL:-default}"
PROFILE_FIXTURE="${WING_QA_PROFILE_FIXTURE:-maestroqa$(date +%H%M%S)}"
DEVICE="${WING_QA_DEVICE:-}"

if [[ ! "$PROFILE_FIXTURE" =~ ^maestroqa[0-9]+$ ]]; then
  echo "WING_QA_PROFILE_FIXTURE must match maestroqa<digits>." >&2
  exit 2
fi

fixture_deleted="${PROFILE_FIXTURE}2"
device_args=()
if [[ -n "$DEVICE" ]]; then
  device_args=(--device "$DEVICE")
fi

flows=(
  .maestro/real-gateway-regression.yaml
  scripts/maestro/session_branch_qa.yaml
  scripts/maestro/session_bulk_selection_qa.yaml
  scripts/maestro/session_metadata_qa.yaml
  scripts/maestro/tools_inventory_qa.yaml
  scripts/maestro/gateway_status_qa.yaml
  scripts/maestro/gateway_connection_settings_qa.yaml
  scripts/maestro/gateway_profiles_qa.yaml
  scripts/maestro/providers_models_unsupported_qa.yaml
  scripts/maestro/schedules_unsupported_qa.yaml
  scripts/maestro/office_workspace_qa.yaml
)

"$MAESTRO_BIN" "${device_args[@]}" test \
  -e WING_QA_GATEWAY_LABEL="$GATEWAY_LABEL" \
  -e WING_QA_PROFILE_LABEL="$PROFILE_LABEL" \
  -e WING_QA_PROFILE_FIXTURE="$PROFILE_FIXTURE" \
  "${flows[@]}"
suite_status=$?
cleanup_status=0

pending_id="$({ wing-link approvals list 2>/dev/null || true; } | awk -F '\t' -v target="Delete profile $fixture_deleted" '$3 == "pending" && $6 == target { id = $1 } END { print id }')"
if [[ -n "$pending_id" ]]; then
  wing-link approvals reject "$pending_id" >/dev/null 2>&1 || cleanup_status=1
elif [[ $suite_status -eq 0 ]]; then
  echo "Expected a pending approval for the temporary profile deletion." >&2
  cleanup_status=1
fi

profile_list="$(hermes profile list 2>/dev/null)" || cleanup_status=1
while IFS= read -r fixture; do
  [[ -z "$fixture" ]] && continue
  hermes profile delete -y "$fixture" >/dev/null 2>&1 || cleanup_status=1
done < <(printf '%s\n' "$profile_list" | awk -v prefix="$PROFILE_FIXTURE" 'index($1, prefix) == 1 { print $1 }')

if [[ $suite_status -ne 0 ]]; then
  exit "$suite_status"
fi
if [[ $cleanup_status -ne 0 ]]; then
  echo "The E2E suite passed, but temporary profile cleanup failed." >&2
  exit "$cleanup_status"
fi
