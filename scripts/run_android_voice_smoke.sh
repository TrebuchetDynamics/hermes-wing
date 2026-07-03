#!/usr/bin/env bash
set -euo pipefail

for cmd in flutter adb python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required for the Android voice smoke." >&2
    exit 1
  fi
done

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
    echo "No Android device/emulator found. Set NAVIVOX_ANDROID_DEVICE_ID or start an emulator/device." >&2
    flutter devices >&2 || true
    adb devices >&2 || true
    exit 2
  fi
fi

package="${NAVIVOX_ANDROID_PACKAGE:-com.trebuchetdynamics.navivox}"

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
  echo "Android target $device did not report stable boot_completed=1 with package/settings services ready." >&2
  adb -s "$device" shell getprop sys.boot_completed >&2 || true
  adb -s "$device" shell service check package >&2 || true
  adb -s "$device" shell service check settings >&2 || true
  adb -s "$device" shell cmd package list packages >/dev/null 2>&1 || true
  return 1
}

echo "Using Android target: $device"
wait_for_android_ready
flutter install -d "$device" || true
adb -s "$device" shell pm grant "$package" android.permission.RECORD_AUDIO >/dev/null 2>&1 || true

run_flutter_test_with_install_retry() {
  local log code
  log="$(mktemp -t navivox-android-voice.XXXXXX.log)"
  set +e
  flutter test -d "$device" integration_test/android_device_speech_smoke_test.dart 2>&1 | tee "$log"
  code=${PIPESTATUS[0]}
  set -e
  if [ "$code" -eq 0 ]; then
    rm -f "$log"
    return 0
  fi
  if [ "${NAVIVOX_ANDROID_RETRY_ON_INSTALL_FLAKE:-1}" = "1" ] && grep -Eqi "Can't find service: package|Broken pipe|device offline|Unable to start the app on the device" "$log"; then
    echo "Android install/start flake detected; waiting for framework services and retrying once..." >&2
    wait_for_android_ready
    flutter test -d "$device" integration_test/android_device_speech_smoke_test.dart
    rm -f "$log"
    return 0
  fi
  echo "Android device-speech smoke failed. Full output: $log" >&2
  return "$code"
}

run_flutter_test_with_install_retry

cat <<'EOF'

Automated Android device-speech readiness passed.
Manual continuous-voice closeout still required on this same device/emulator:
  1. Start a configured Hermes Agent API server.
  2. Open Navivox /hermes and connect using http://10.0.2.2:8642 for emulator or LAN/VPN URL for device.
  3. Tap Speak and confirm a spoken phrase submits as a Hermes text turn.
  4. Enable continuous voice and confirm capture → reply/TTS → re-arm works.

This readiness smoke is not whole-goal completion evidence by itself; run
NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit before any completion claim.
EOF
