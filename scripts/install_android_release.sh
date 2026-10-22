#!/usr/bin/env bash
set -euo pipefail

# One-command install of the private release APK on an attached Android device:
# install -> grant microphone -> launch -> print the exact remaining phone taps.
#
# Android itself still requires the user to confirm the install and, for a
# browser download, to allow installs from that source. Those are OS gates that
# no client can remove. This script removes every computer-side step.
#
# Usage:
#   ./scripts/install_android_release.sh
#   ./scripts/install_android_release.sh -d <adb-serial>
#   ./scripts/install_android_release.sh --build        # rebuild first
#   ./scripts/install_android_release.sh --apk <path>  # install an existing APK
#
# Environment:
#   WING_ANDROID_PACKAGE    app id (default: the private release test id)
#   WING_ANDROID_ACTIVITY   activity (default: .MainActivity)
#   WING_ANDROID_DEVICE_ID  explicit adb serial; otherwise the single online device

usage() {
  cat <<'USAGE'
Install the private release APK on an attached Android device and launch it.

Usage:
  ./scripts/install_android_release.sh [options]

Options:
  -d, --device <serial>  Explicit adb serial. Required when several devices are online.
  -b, --build            Build the ARM64 release APK before installing.
  -a, --apk <path>       Install an existing APK instead of the default artifact.
  -h, --help             Show this help.

Notes:
  - Grants RECORD_AUDIO so the voice path is ready without a second manual trip.
  - Launches the app immediately after install.
  - Android still requires the install confirmation on the phone itself.
USAGE
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir/.."

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 127
  fi
}

require_cmd adb
require_cmd flutter

package="${WING_ANDROID_PACKAGE:-com.trebuchetdynamics.hermes.wing.qa.release}"
activity="${WING_ANDROID_ACTIVITY:-com.trebuchetdynamics.hermes.wing/.MainActivity}"
device_id="${WING_ANDROID_DEVICE_ID:-${ANDROID_SERIAL:-}}"
default_apk="build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
apk_path="$default_apk"
build_first=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--device)
      if [[ $# -lt 2 || -z "${2:-}" ]]; then
        echo "Missing value for $1" >&2
        exit 2
      fi
      device_id="$2"
      shift 2
      ;;
    -b|--build)
      build_first=1
      shift
      ;;
    -a|--apk)
      if [[ $# -lt 2 || -z "${2:-}" ]]; then
        echo "Missing value for $1" >&2
        exit 2
      fi
      apk_path="$2"
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

if [[ "$build_first" -eq 1 ]]; then
  echo "Building ARM64 private release APK..."
  WING_PRIVATE_RELEASE_TEST=1 flutter build apk --release --split-per-abi \
    --target-platform android-arm64 -t lib/main.dart
fi

if [[ ! -s "$apk_path" ]]; then
  echo "APK not found or empty at $apk_path." >&2
  echo "Build it first with --build, or pass an explicit path with --apk." >&2
  exit 1
fi

if [[ -z "$device_id" ]]; then
  mapfile -t devices < <(adb devices | awk 'NR > 1 && $2 == "device" { print $1 }')
  case "${#devices[@]}" in
    0)
      echo "No online Android device found. Connect a phone with USB debugging enabled, or start an emulator." >&2
      echo "Then re-run this script." >&2
      adb devices >&2 || true
      exit 2
      ;;
    1)
      device_id="${devices[0]}"
      ;;
    *)
      echo "Multiple Android devices online. Pick one with -d <serial>:" >&2
      printf '  %s\n' "${devices[@]}" >&2
      exit 2
      ;;
  esac
fi

echo "Using Android target: $device_id"
if ! adb -s "$device_id" shell true >/dev/null 2>&1; then
  echo "Device $device_id is not responsive. Re-run after it is ready." >&2
  exit 3
fi

echo "Installing $apk_path"
adb -s "$device_id" install -r "$apk_path"

echo "Granting RECORD_AUDIO to $package"
adb -s "$device_id" shell pm grant "$package" android.permission.RECORD_AUDIO || \
  echo "Microphone permission grant was not confirmed; grant it in Android App info if the mic is refused."

echo "Launching $activity"
adb -s "$device_id" shell am start -n "$activity" >/dev/null

echo
echo "Installed and launched on $device_id."
echo
echo "Remaining phone-side steps (Android requires these taps):"
echo "  1. Accept the install confirmation if Android still prompts."
echo "  2. Open Hermes Wing and connect to your Hermes Agent API."
echo "  3. Open a chat, tap Speak, and say a short phrase aloud."
echo "  4. Confirm the banner reads 'Continuous voice ready' before capture."
echo
echo "This script installs, grants the microphone permission and launches."
echo "It does not prove physical microphone capture, provider replies, TTS or"
echo "continuous-loop behavior. Those remain manual evidence."
