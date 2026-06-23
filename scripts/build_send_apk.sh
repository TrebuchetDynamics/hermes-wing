#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Build a Flutter Android APK and install it on an attached Android device.

Usage:
  scripts/build_send_apk.sh [--debug|--profile|--release] [-d DEVICE_ID] [--no-clean] [--extra-flutter-arg ARG]...

Examples:
  scripts/build_send_apk.sh
  scripts/build_send_apk.sh -d emulator-5554
  scripts/build_send_apk.sh --release -d R58M123ABC

Notes:
  - Defaults to --debug.
  - DEVICE_ID is an adb serial from `adb devices`.
  - Extra Flutter args are appended to `flutter build apk`.
USAGE
}

mode="debug"
device_id="${ANDROID_SERIAL:-}"
clean_first=1
extra_flutter_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug|--profile|--release)
      mode="${1#--}"
      shift
      ;;
    -d|--device)
      if [[ $# -lt 2 || -z "${2:-}" ]]; then
        echo "Missing value for $1" >&2
        exit 2
      fi
      device_id="$2"
      shift 2
      ;;
    --no-clean)
      clean_first=0
      shift
      ;;
    --extra-flutter-arg)
      if [[ $# -lt 2 || -z "${2:-}" ]]; then
        echo "Missing value for --extra-flutter-arg" >&2
        exit 2
      fi
      extra_flutter_args+=("$2")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 127
  fi
}

require_cmd flutter
require_cmd adb

if [[ ! -f pubspec.yaml ]]; then
  echo "Run this script from the Flutter project root." >&2
  exit 1
fi

apk_path="build/app/outputs/flutter-apk/app-${mode}.apk"

if [[ "$clean_first" -eq 1 ]]; then
  flutter clean
fi

flutter pub get
flutter build apk --"$mode" "${extra_flutter_args[@]}"

if [[ ! -f "$apk_path" ]]; then
  echo "APK not found at expected path: $apk_path" >&2
  exit 1
fi

if [[ -z "$device_id" ]]; then
  mapfile -t devices < <(adb devices | awk 'NR > 1 && $2 == "device" { print $1 }')
  case "${#devices[@]}" in
    0)
      echo "Built $apk_path. No online Android devices found. Connect one or start an emulator, then run: adb devices" >&2
      exit 1
      ;;
    1)
      device_id="${devices[0]}"
      ;;
    *)
      echo "Built $apk_path. Multiple Android devices found. Pick one with -d DEVICE_ID:" >&2
      printf '  %s\n' "${devices[@]}" >&2
      exit 1
      ;;
  esac
fi

echo "Installing $apk_path on $device_id"
adb -s "$device_id" install -r "$apk_path"

echo "Done. Installed $apk_path on $device_id"
