#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Require an explicit target: never replace or clear a paired production app.
: "${WING_QA_DEVICE:?Set WING_QA_DEVICE to the disposable Android target serial}"
MAESTRO_BIN="${MAESTRO_BIN:-maestro}"
OUTPUT_DIR="${WING_QA_OUTPUT_DIR:-$ROOT_DIR/test-results/maestro-profiles}"
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"
# Maestro prunes its shared log cache on startup. Isolate this run so another
# syntax check or device job cannot delete the active run's logs.
MAESTRO_CACHE_DIR="$(mktemp -d "$OUTPUT_DIR/maestro-cache.XXXXXX")"
flows=(
  scripts/maestro/profiles/switch_chat.yaml
  scripts/maestro/profiles/create_setup_delete.yaml
  scripts/maestro/profiles/provider_model_chat.yaml
)

case "${1:-all}" in
  all) ;;
  provider-model-chat) flows=(scripts/maestro/profiles/provider_model_chat.yaml) ;;
  *) echo "Usage: $0 [all|provider-model-chat]" >&2; exit 2 ;;
esac

for flow in "${flows[@]}"; do
  XDG_CACHE_HOME="$MAESTRO_CACHE_DIR" "$MAESTRO_BIN" check-syntax "$flow"
done
WING_ISOLATED_DEVICE_TEST=1 flutter build apk --debug \
  -t integration_test/hermes_profile_lifecycle_maestro_main.dart
adb -s "$WING_QA_DEVICE" install -r build/app/outputs/flutter-apk/app-debug.apk
XDG_CACHE_HOME="$MAESTRO_CACHE_DIR" "$MAESTRO_BIN" --device "$WING_QA_DEVICE" test \
  --test-output-dir "$OUTPUT_DIR" "${flows[@]}"
