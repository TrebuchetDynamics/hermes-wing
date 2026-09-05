#!/usr/bin/env bash
# Qualify the actual Linux secret-service plugin across two app processes.
# Requires Flutter Linux build dependencies, Xvfb, D-Bus, and GNOME Keyring.
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077
keyring_test_root=$(mktemp -d /tmp/wing-keyring.XXXXXX)
cleanup_keyring_test() {
  local keyring_cleanup_status=$?
  # Desktop portals can leave FUSE mounts after the isolated bus exits.
  # Detach only mounts in this helper's newly created runtime directory.
  for keyring_mount in "$keyring_test_root/run/doc" "$keyring_test_root/run/gvfs"; do
    if findmnt -rn --mountpoint "$keyring_mount" > /dev/null; then
      # The portal can finish unmounting between the lookup and detachment.
      if ! fusermount3 -uz -- "$keyring_mount" 2>/dev/null &&
        findmnt -rn --mountpoint "$keyring_mount" > /dev/null; then
        keyring_cleanup_status=1
      fi
    fi
  done
  if ! rm -r -- "$keyring_test_root"; then
    keyring_cleanup_status=1
  fi
  return "$keyring_cleanup_status"
}
trap cleanup_keyring_test EXIT
export XDG_CONFIG_HOME="$keyring_test_root/config"
export XDG_DATA_HOME="$keyring_test_root/data"
export XDG_CACHE_HOME="$keyring_test_root/cache"
export XDG_RUNTIME_DIR="$keyring_test_root/run"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_RUNTIME_DIR"
export WING_ISOLATED_KEYRING=1
export WING_KEYRING_RECEIPT="$keyring_test_root/receipt.json"
dbus-run-session -- xvfb-run -a bash -c '
  set -euo pipefail
  python3 -c "import secrets; print(secrets.token_hex(32))" | gnome-keyring-daemon --unlock --components=secrets > /dev/null
  WING_KEYRING_PHASE=write timeout 300s flutter test -d linux integration_test/linux_secure_storage_integration_test.dart --reporter expanded
  WING_KEYRING_PHASE=verify timeout 300s flutter test -d linux integration_test/linux_secure_storage_integration_test.dart --reporter expanded
'
