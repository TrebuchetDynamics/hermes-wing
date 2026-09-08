#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
umask 077
if [[ "${1:-}" == --inside-display ]]; then
  [[ "${WING_ISOLATED_NATIVE_INPUT:-}" == 1 && "${XDG_CONFIG_HOME:-}" == /tmp/wing-linux-native.*/config ]] || exit 2
  mkdir -p "$XDG_CONFIG_HOME/fluxbox"
  cp test/fixtures/linux-fluxbox-init "$XDG_CONFIG_HOME/fluxbox/init"
  fluxbox -rc "$XDG_CONFIG_HOME/fluxbox/init" -no-slit -no-toolbar > "$XDG_CONFIG_HOME/fluxbox/log" 2>&1 &
  native_wm_pid=$!
  trap 'kill -TERM "$native_wm_pid" 2>/dev/null || true; wait "$native_wm_pid" 2>/dev/null || true' EXIT
  for ((attempt=0; attempt<50; attempt++)); do
    if [[ "$(xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null)" == *"window id"* ]]; then
      flutter test -d linux integration_test/linux_native_input_e2e_test.dart --reporter expanded
      exit
    fi
    sleep 0.1
  done
  echo 'The isolated window manager did not become ready.' >&2
  exit 2
fi
command -v fluxbox >/dev/null || { echo 'fluxbox is required for native lifecycle tests.' >&2; exit 2; }
command -v xprop >/dev/null || exit 2
native_input_root=$(mktemp -d /tmp/wing-linux-native.XXXXXX)
cleanup_native_input() {
  [[ "$native_input_root" == /tmp/wing-linux-native.* ]] || return 1
  rm -r -- "$native_input_root"
}
trap cleanup_native_input EXIT
mkdir -p "$native_input_root/config" "$native_input_root/data" "$native_input_root/cache"
# Copy only the repository's synthetic fixture, never a user-selected file.
cp test/fixtures/linux-picker-sample.txt "$native_input_root/sample.txt"
env XDG_CONFIG_HOME="$native_input_root/config" XDG_DATA_HOME="$native_input_root/data" \
  XDG_CACHE_HOME="$native_input_root/cache" WING_ISOLATED_NATIVE_INPUT=1 \
  WING_NATIVE_PICK_FILE="$native_input_root/sample.txt" \
  xvfb-run -a bash scripts/run_linux_native_input_e2e.sh --inside-display
