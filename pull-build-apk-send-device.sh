#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Pull latest git changes, build a Flutter Android APK, and install it on a connected Android device.

Usage:
  ./pull-build-apk-send-device.sh [--debug|--profile|--release] [-d DEVICE_ID] [--no-clean] [--no-pull] [--extra-flutter-arg ARG]...

Examples:
  ./pull-build-apk-send-device.sh
  ./pull-build-apk-send-device.sh --release
  ./pull-build-apk-send-device.sh -d emulator-5554

Notes:
  - Defaults to --debug.
  - DEVICE_ID is an adb serial from `adb devices`.
  - Extra Flutter args are forwarded to scripts/build_send_apk.sh.
USAGE
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

pull_first=1
build_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-pull)
      pull_first=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      build_args+=("$1")
      shift
      ;;
  esac
done

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 127
  fi
}

require_cmd git
require_cmd flutter
require_cmd adb

if [[ ! -f pubspec.yaml || ! -x scripts/build_send_apk.sh ]]; then
  echo "Run this script from the project root, or keep it in the project root." >&2
  exit 1
fi

if [[ "$pull_first" -eq 1 ]]; then
  if ! git diff --quiet -- pubspec.lock; then
    echo "Discarding local pubspec.lock changes before pull (this deploy PC should not keep generated lockfile drift)."
    git restore -- pubspec.lock
  fi

  echo "Pulling latest changes..."
  git pull --ff-only
fi

exec scripts/build_send_apk.sh "${build_args[@]}"
