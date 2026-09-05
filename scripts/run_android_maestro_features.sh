#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Require an explicit target: never replace or clear a paired production app.
: "${WING_QA_DEVICE:?Set WING_QA_DEVICE to the disposable Android target serial}"
MAESTRO_BIN="${MAESTRO_BIN:-maestro}"
OUTPUT_DIR="${WING_QA_OUTPUT_DIR:-$ROOT_DIR/test-results/maestro-features}"
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"
# Maestro prunes its shared log cache on startup. Isolate this run so another
# syntax check or device job cannot delete the active run's logs.
MAESTRO_CACHE_DIR="$(mktemp -d "$OUTPUT_DIR/maestro-cache.XXXXXX")"
flows=(
  scripts/maestro/fixture/attachments.yaml
  scripts/maestro/fixture/attachment_picker_race.yaml
  scripts/maestro/fixture/draft_isolation.yaml
  scripts/maestro/fixture/chat_groups.yaml
  scripts/maestro/fixture/composer_commands.yaml
  scripts/maestro/fixture/transcript_export.yaml
  scripts/maestro/fixture/voice_language.yaml
  scripts/maestro/fixture/providers.yaml
  scripts/maestro/fixture/soul_directories.yaml
  scripts/maestro/fixture/schedules.yaml
  scripts/maestro/fixture/approvals_recovery.yaml
  scripts/maestro/fixture/microphone_denied.yaml
  scripts/maestro/fixture/sessions.yaml
  scripts/maestro/fixture/settings.yaml
  scripts/maestro/fixture/spellcheck.yaml
  scripts/maestro/fixture/gateway_connection.yaml
  scripts/maestro/fixture/gateway_trust.yaml
  scripts/maestro/fixture/trust_errors.yaml
  scripts/maestro/fixture/pairing.yaml
  scripts/maestro/fixture/local_setup_accessibility.yaml
)

for flow in "${flows[@]}"; do
  XDG_CACHE_HOME="$MAESTRO_CACHE_DIR" "$MAESTRO_BIN" check-syntax "$flow"
done
WING_ISOLATED_DEVICE_TEST=1 flutter build apk --debug \
  -t integration_test/hermes_features_maestro_main.dart
adb -s "$WING_QA_DEVICE" install -r build/app/outputs/flutter-apk/app-debug.apk
XDG_CACHE_HOME="$MAESTRO_CACHE_DIR" "$MAESTRO_BIN" --device "$WING_QA_DEVICE" test \
  --test-output-dir "$OUTPUT_DIR" "${flows[@]}"
