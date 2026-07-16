#!/usr/bin/env bash
set -euo pipefail

for cmd in flutter adb python3 timeout; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required for the Android Hermes voice-loop smoke." >&2
    exit 1
  fi
done

discover_android_device() {
  local devices_json
  devices_json="$(mktemp -t wing-flutter-devices.XXXXXX.json)"
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

device="${WING_ANDROID_DEVICE_ID:-}"
if [ -z "$device" ]; then
  for _ in $(seq 1 "${WING_ANDROID_DEVICE_WAIT_SECONDS:-120}"); do
    device="$(discover_android_device)"
    if [ -n "$device" ]; then
      break
    fi
    sleep 1
  done
  if [ -z "$device" ]; then
    echo "No Android device/emulator found. Set WING_ANDROID_DEVICE_ID or start an emulator/device." >&2
    flutter devices >&2 || true
    adb devices >&2 || true
    exit 2
  fi
fi

wait_for_android_ready() {
  local boot package_service settings_service consecutive=0
  for _ in $(seq 1 "${WING_ANDROID_BOOT_WAIT_SECONDS:-360}"); do
    boot="$(adb -s "$device" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
    package_service="$(adb -s "$device" shell service check package 2>/dev/null || true)"
    settings_service="$(adb -s "$device" shell service check settings 2>/dev/null || true)"
    if [ "$boot" = "1" ] && \
      printf '%s' "$package_service" | grep -q 'found' && \
      printf '%s' "$settings_service" | grep -q 'found' && \
      adb -s "$device" shell cmd package list packages >/dev/null 2>&1; then
      consecutive=$((consecutive + 1))
      if [ "$consecutive" -ge "${WING_ANDROID_READY_CONSECUTIVE_CHECKS:-3}" ]; then
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

run_flutter_test_with_install_retry() {
  local log code
  log="$(mktemp -t wing-android-hermes-voice-loop.XXXXXX.log)"
  set +e
  timeout "${WING_ANDROID_TEST_TIMEOUT_SECONDS:-900}" \
    flutter test -d "$device" integration_test/hermes_continuous_voice_android_smoke_test.dart 2>&1 | tee "$log"
  code=${PIPESTATUS[0]}
  set -e
  if [ "$code" -eq 0 ]; then
    rm -f "$log"
    return 0
  fi
  if [ "${WING_ANDROID_RETRY_ON_INSTALL_FLAKE:-1}" = "1" ] && grep -Eqi "Can't find service: package|Broken pipe|device offline|Unable to start the app on the device" "$log"; then
    echo "Android install/start flake detected; waiting for framework services and retrying once..." >&2
    wait_for_android_ready
    timeout "${WING_ANDROID_TEST_TIMEOUT_SECONDS:-900}" \
      flutter test -d "$device" integration_test/hermes_continuous_voice_android_smoke_test.dart
    rm -f "$log"
    return 0
  fi
  echo "Android Hermes voice-loop smoke failed. Full output: $log" >&2
  return "$code"
}

run_flutter_test_with_install_retry

receipt_path="${WING_ANDROID_VOICE_PATH_RECEIPT:-build/receipts/android-hermes-voice-loop-smoke.json}"
mkdir -p "$(dirname "$receipt_path")"
python3 - "$receipt_path" "$device" <<'PY'
import datetime, json, os, subprocess, sys

path = sys.argv[1]
device = sys.argv[2]
try:
    head_sha = subprocess.check_output(
        ['git', 'rev-parse', 'HEAD'], text=True, stderr=subprocess.DEVNULL
    ).strip()
except Exception:
    head_sha = ''

def adb_shell(*args):
    try:
        return subprocess.check_output(
            ['adb', '-s', device, 'shell', *args],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip().strip('\r')
    except Exception:
        return ''

def getprop(name):
    return adb_shell('getprop', name)

receipt = {
    'kind': 'android_hermes_voice_loop_smoke',
    'status': 'passed',
    'timestamp_utc': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'head_sha': head_sha,
    'device_id': device,
    'device_properties': {
        'manufacturer': getprop('ro.product.manufacturer'),
        'model': getprop('ro.product.model'),
        'sdk': getprop('ro.build.version.sdk'),
        'fingerprint': getprop('ro.build.fingerprint'),
    },
    'coverage': 'deterministic transcript capture plus fake TTS continuous re-arm',
    'voice_turns': ['android first voice', 'android second voice'],
    'tts_outputs': ['echo: android first voice', 'echo: android second voice'],
    'evidence_for': [
        'Android Flutter Hermes voice-loop UI',
        'deterministic transcript-to-Hermes text submission',
        'fake TTS playback callback',
        'continuous voice re-arm after first reply',
        'distinct second deterministic voice turn after re-arm',
    ],
    'not_evidence_for': [
        'physical Android microphone audio',
        'provider-backed Hermes reply',
        'Hermes realtime/server audio',
        'Windows/iOS/macOS native-host receipts',
        'platform workflow publication',
        'deferred Hermes Desktop parity surfaces',
        'whole-goal completion',
    ],
}
with open(path, 'w', encoding='utf-8') as fh:
    json.dump(receipt, fh, indent=2)
    fh.write('\n')
PY

printf 'Android Hermes voice-loop receipt: %s\n' "$receipt_path"

cat <<'EOF'

Android Hermes continuous voice-loop smoke passed with deterministic transcript
capture and fake TTS. This verifies the Flutter Android Hermes voice loop and
continuous re-arm without a human speaker, but it is not physical microphone
audio input, provider-backed replies, or Hermes realtime/server audio.
It is not whole-goal completion evidence by itself; run
WING_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit before any completion claim.
EOF
