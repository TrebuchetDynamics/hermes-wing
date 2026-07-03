#!/usr/bin/env bash
set -euo pipefail

for cmd in flutter adb python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required for the Android live microphone smoke prep." >&2
    exit 1
  fi
done

package="${NAVIVOX_ANDROID_PACKAGE:-com.trebuchetdynamics.navivox}"
activity="${NAVIVOX_ANDROID_ACTIVITY:-com.trebuchetdynamics.navivox/.MainActivity}"

android_endpoint_hint() {
  if [ -n "${NAVIVOX_ANDROID_HERMES_URL:-}" ]; then
    printf '%s' "$NAVIVOX_ANDROID_HERMES_URL"
  else
    printf 'http://10.0.2.2:8642 for emulator, or LAN/VPN/Tailscale URL for physical device'
  fi
}

discover_android_device() {
  local devices_json
  devices_json="$(mktemp -t navivox-flutter-devices.XXXXXX.json)"
  flutter devices --machine >"$devices_json" 2>/dev/null || true
  python3 - "$devices_json" <<'PY'
import json, sys
try:
    with open(sys.argv[1], encoding='utf-8') as fh:
        data = json.load(fh)
except Exception:
    data = []
for d in data:
    platform = str(d.get('targetPlatform', ''))
    if platform.startswith('android'):
        print(d.get('id', ''))
        break
PY
  rm -f "$devices_json"
}

device="${NAVIVOX_ANDROID_DEVICE_ID:-}"
if [ -z "$device" ]; then
  for _ in $(seq 1 "${NAVIVOX_ANDROID_DEVICE_WAIT_SECONDS:-120}"); do
    device="$(discover_android_device)"
    if [ -n "$device" ]; then
      break
    fi
    sleep 1
  done
  if [ -z "$device" ]; then
    echo "No Android device/emulator found. Set NAVIVOX_ANDROID_DEVICE_ID or start an audio-capable device/emulator." >&2
    flutter devices >&2 || true
    adb devices >&2 || true
    exit 2
  fi
fi

wait_for_android_ready() {
  local boot package_service settings_service consecutive=0
  for _ in $(seq 1 "${NAVIVOX_ANDROID_BOOT_WAIT_SECONDS:-360}"); do
    boot="$(adb -s "$device" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
    package_service="$(adb -s "$device" shell service check package 2>/dev/null || true)"
    settings_service="$(adb -s "$device" shell service check settings 2>/dev/null || true)"
    if [ "$boot" = "1" ] && \
      printf '%s' "$package_service" | grep -q 'found' && \
      printf '%s' "$settings_service" | grep -q 'found' && \
      adb -s "$device" shell cmd package list packages >/dev/null 2>&1; then
      consecutive=$((consecutive + 1))
      if [ "$consecutive" -ge "${NAVIVOX_ANDROID_READY_CONSECUTIVE_CHECKS:-3}" ]; then
        return 0
      fi
    else
      consecutive=0
    fi
    sleep 1
  done
  echo "Android target $device did not report stable package/settings readiness." >&2
  return 1
}

echo "Using Android target: $device"
wait_for_android_ready

if [ "${NAVIVOX_ANDROID_SKIP_BUILD:-0}" != "1" ]; then
  flutter build apk --debug
fi

flutter install -d "$device" || true
adb -s "$device" shell pm grant "$package" android.permission.RECORD_AUDIO >/dev/null 2>&1 || true
adb -s "$device" shell am start -n "$activity" >/dev/null

cat <<EOF

Android live microphone smoke is prepared on $device.

Manual evidence still required; do not count this prep as a pass:
  1. Start a configured Hermes Agent API server with provider/model credentials.
  2. In Navivox /hermes, connect to: $(android_endpoint_hint)
  3. Tap Speak and say a unique phrase aloud.
  4. Verify the spoken phrase appears as a Hermes text turn and receives a provider-backed reply.
  5. Enable continuous voice.
  6. Verify capture → Hermes reply → TTS → re-arm for another spoken turn.
  7. Verify no API key/transcript secret appears in routes, logs, notices, or diagnostics export.

This script only installs/launches/grants microphone permission. It does not
prove physical microphone capture, provider replies, or continuous-loop behavior.
It is not whole-goal completion evidence by itself; run
NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit before any completion claim.
EOF
