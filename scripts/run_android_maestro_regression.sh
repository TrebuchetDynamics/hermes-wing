#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MAESTRO_BIN="${MAESTRO_BIN:-maestro}"
GATEWAY_LABEL="${WING_QA_GATEWAY_LABEL:-$(hostname)}"
PROFILE_LABEL="${WING_QA_PROFILE_LABEL:-default}"
DEVICE="${WING_QA_DEVICE:-}"

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
  scripts/maestro/providers_models_unsupported_qa.yaml
  scripts/maestro/schedules_unsupported_qa.yaml
  scripts/maestro/office_workspace_qa.yaml
  scripts/maestro/chat_concurrent_sessions_qa.yaml
  scripts/maestro/chat_process_recovery_qa.yaml
  scripts/maestro/chat_ux_qa.yaml
)

"$MAESTRO_BIN" "${device_args[@]}" test \
  -e WING_QA_GATEWAY_LABEL="$GATEWAY_LABEL" \
  -e WING_QA_PROFILE_LABEL="$PROFILE_LABEL" \
  "${flows[@]}"
