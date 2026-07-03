#!/usr/bin/env bash
set -euo pipefail

status=0
blockers=0

ok() { printf 'OK: %s\n' "$*"; }
info() { printf 'INFO: %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*"; status=1; }
block() { printf 'BLOCKED: %s\n' "$*"; blockers=$((blockers + 1)); }

file_exists() {
  local path="$1" label="$2"
  if [ -e "$path" ]; then ok "$label ($path)"; else warn "$label missing ($path)"; fi
}

printf 'Navivox Hermes readiness audit (read-only)\n\n'

file_exists docs/runbooks/hermes-readiness-audit.md 'readiness audit doc'
file_exists docs/runbooks/hermes-platform-smoke.md 'platform smoke runbook'
file_exists docs/runbooks/android/live-mic-smoke.md 'Android live microphone runbook'
file_exists docs/runbooks/android/durable-keystore-smoke.md 'Android durable reconnect runbook'
file_exists docs/runbooks/android/release-handoff.md 'Android release handoff runbook'
file_exists .github/workflows/hermes-platform-smoke.yml 'Hermes platform workflow file'
file_exists scripts/run_provider_hermes_smoke.sh 'provider smoke helper'
file_exists scripts/run_android_voice_smoke.sh 'Android speech readiness helper'
file_exists scripts/run_android_hermes_voice_loop_smoke.sh 'Android deterministic voice-loop helper'
file_exists scripts/run_android_durable_key_smoke.sh 'Android durable-key helper'
file_exists scripts/prepare_android_live_mic_smoke.sh 'Android live mic prep helper'
file_exists scripts/run_hermes_platform_workflow.sh 'platform workflow dispatch helper'

printf '\nLocal build artifacts (informational):\n'
[ -f build/web/main.dart.js ] && ok 'web e2e bundle present' || warn 'web e2e bundle not present; run flutter build web --release -t lib/main_e2e.dart'
if [ -f build/app/outputs/flutter-apk/app-debug.apk ]; then
  ok 'Android debug APK present'
  if command -v sha256sum >/dev/null 2>&1; then
    info "Android debug APK sha256: $(sha256sum build/app/outputs/flutter-apk/app-debug.apk | awk '{print $1}') (artifact identity only; not live Android, mic, or reconnect evidence)"
  fi
else
  warn 'Android debug APK not present; run flutter build apk --debug'
fi
[ -x build/linux/x64/release/bundle/navivox ] && ok 'Linux release binary present' || warn 'Linux release binary not present; run npm run linux:release-build'

printf '\nObjective checklist (read-only; not completion evidence):\n'
info 'provider-backed Hermes chat/voice: requires configured model/provider credentials plus a current npm run hermes:provider-smoke:local receipt; transcript voice is not physical mic/server audio'
info 'Android microphone + continuous voice: requires responsive audio-capable Android target and manual docs/runbooks/android/live-mic-smoke.md receipt'
info 'Windows and iOS builds: require successful native-host runner jobs/artifacts or native host receipts'
info 'Hermes realtime/server audio: unimplemented; current voice path is local STT-to-text'
info 'Deferred Hermes surfaces: config admin, memory UI, jobs/schedules admin, messaging gateways, persona/SOUL, attachments/media, files/context folders, raw diagnostics/log export, and multi-endpoint/profile management'
info 'Legacy Gormes durable reconnect: requires real Android secure key/credential path plus real Gormes restart reconnect receipt'

printf '\nExternal receipt blockers:\n'
if command -v gh >/dev/null 2>&1; then
  workflow_list="$(gh workflow list 2>&1 || true)"
  if printf '%s\n' "$workflow_list" | grep -Fq 'Hermes platform smoke'; then
    ok 'Hermes platform workflow visible to gh'
  else
    block 'Hermes platform workflow is not visible to gh; publish the workflow then run npm run platform:workflow-smoke before claiming Windows/iOS/hosted Android receipts'
    printf 'INFO: Visible workflows (not native-host receipt evidence):\n'
    printf '%s\n' "$workflow_list" | sed 's/^/INFO:   /'
  fi
else
  block 'gh not installed; cannot inspect/dispatch native-host workflow receipts; install gh before running npm run platform:workflow-smoke'
fi
info 'workflow dispatch without successful gh run view job/artifact evidence is not a platform receipt; NAVIVOX_WATCH_WORKFLOW=false only proves dispatch was requested'

block 'Windows desktop native-host build receipt missing; run on a Windows host or published platform workflow before claiming Windows readiness'
block 'iOS simulator native-host build receipt missing; run on a macOS/Xcode host or published platform workflow before claiming iOS readiness'

if command -v adb >/dev/null 2>&1; then
  android_devices="$(adb devices | awk 'NR>1 && $2=="device" {print $1}' | paste -sd, -)"
  if [ -n "$android_devices" ]; then
    ok "Android target(s) online: $android_devices"
    block 'real spoken Android mic loop still requires manual audio/provider evidence; online device alone is not a pass'
  else
    block 'no online Android device/emulator for real spoken mic or Android reconnect receipts; start an audio-capable target, follow docs/runbooks/android/live-mic-smoke.md, then run npm run android:live-mic-prep'
    if command -v flutter >/dev/null 2>&1; then
      printf 'INFO: Flutter connected devices (not Android/audio receipt evidence):\n'
      flutter devices 2>/dev/null | sed 's/^/INFO:   /' || true
      printf 'INFO: Flutter emulator inventory (availability is not an online/audio receipt):\n'
      flutter emulators 2>/dev/null | sed 's/^/INFO:   /' || true
    fi
    emulator_bin="$(command -v emulator 2>/dev/null || true)"
    if [ -z "$emulator_bin" ] && [ -x /usr/lib/android-sdk/emulator/emulator ]; then
      emulator_bin=/usr/lib/android-sdk/emulator/emulator
    fi
    if [ -n "$emulator_bin" ]; then
      printf 'INFO: Android emulator acceleration check (not audio/live-mic evidence):\n'
      "$emulator_bin" -accel-check 2>&1 | sed 's/^/INFO:   /' || true
    fi
  fi
else
  block 'adb not installed; cannot inspect Android device readiness'
fi

if [ -f "${NAVIVOX_CONFIGURED_HERMES_HOME:-${HERMES_HOME:-$HOME/.hermes}}/config.yaml" ]; then
  info 'configured local Hermes home appears present; this is not a provider-smoke receipt, run npm run hermes:provider-smoke:local for proof'
else
  block 'no configured Hermes config.yaml found for local provider-backed smoke'
fi
block 'full live provider-backed Hermes chat/voice smoke receipt missing from this audit; run npm run hermes:provider-smoke:local with configured model/provider credentials; deterministic transcript voice is not physical microphone/server audio evidence'

block 'Hermes realtime/server audio remains unimplemented; local STT-to-text only'
block 'Hermes config editing/admin remains deferred by policy'
block 'Hermes memory UI remains deferred by policy'
block 'Hermes jobs/schedules admin remains deferred; current jobs support is read-only inventory only'
block 'Hermes messaging gateways remain deferred by policy'
block 'Hermes persona/SOUL editing remains deferred by policy'
block 'Hermes attachments/media remain deferred by policy'
block 'Hermes files/context folders remain deferred by policy'
block 'Hermes raw diagnostics/log export remains deferred; bounded diagnostics only'
block 'Hermes multi-endpoint/profile management remains deferred; one saved endpoint MVP only'
block 'full real Android + real Gormes durable reconnect after restart is not proven by key/unit/fake-gateway tests; follow docs/runbooks/android/durable-keystore-smoke.md closeout'

printf '\nSummary: %s blocker(s), %s warning state.\n' "$blockers" "$status"
if [ "$blockers" -gt 0 ]; then
  printf 'Completion verdict: NOT COMPLETE; live provider/device/native-host/reconnect or deferred-surface blockers remain.\n'
fi
printf 'This audit is informational and must not be used as a completion receipt by itself.\n'
printf 'Do not promote proxy evidence (tests, APK hashes, configured Hermes home, workflow YAML, or dispatch-only output) to completion.\n'

if [ "${NAVIVOX_FAIL_ON_BLOCKERS:-0}" = "1" ] && [ "$blockers" -gt 0 ]; then
  exit 3
fi
exit 0
