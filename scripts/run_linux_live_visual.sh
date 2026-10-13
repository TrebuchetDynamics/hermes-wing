#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${WING_LIVE_PROFILE_MANIFEST:?Provide the real isolated Agent manifest}"
manifest="$WING_LIVE_PROFILE_MANIFEST"
[[ -f "$manifest" && ! -L "$manifest" && -O "$manifest" ]] || { echo 'Live manifest must be an owned regular file, not a symlink.' >&2; exit 2; }
mode="$(stat -c '%a' "$manifest")"
(( (8#$mode & 077) == 0 )) || { echo 'Live manifest must have owner-only permissions.' >&2; exit 2; }
umask 077
export WING_VISUAL_OUTPUT="${WING_VISUAL_OUTPUT:-$PWD/test-results/linux-live-visual}"
mkdir -p "$WING_VISUAL_OUTPUT"
WING_VISUAL_OUTPUT="$(realpath "$WING_VISUAL_OUTPUT")"
visual_keyring_root=$(mktemp -d "${TMPDIR:-/tmp}/wing-visual-keyring.XXXXXX")
cleanup() {
  for mount in "$visual_keyring_root/run/doc" "$visual_keyring_root/run/gvfs"; do
    if findmnt -rn --mountpoint "$mount" > /dev/null; then
      # D-Bus teardown may remove the portal mount between these commands.
      if ! fusermount3 -uz -- "$mount" 2>/dev/null && findmnt -rn --mountpoint "$mount" > /dev/null; then
        return 1
      fi
    fi
  done
  rm -r -- "$visual_keyring_root"
}
trap cleanup EXIT
export XDG_CONFIG_HOME="$visual_keyring_root/config"
export XDG_DATA_HOME="$visual_keyring_root/data"
export XDG_CACHE_HOME="$visual_keyring_root/cache"
export XDG_RUNTIME_DIR="$visual_keyring_root/run"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_RUNTIME_DIR"
dbus-run-session -- xvfb-run -a -s '-screen 0 1600x1000x24' bash -c '
  set -euo pipefail
  python3 -c "import secrets; print(secrets.token_hex(32))" | gnome-keyring-daemon --unlock --components=secrets > /dev/null
  flutter test -d linux integration_test/linux_live_visual_test.dart --reporter expanded
'
