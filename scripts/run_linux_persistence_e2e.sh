#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
umask 077
persistence_root=$(mktemp -d /tmp/wing-linux-persistence.XXXXXX)
cleanup_persistence() {
  [[ "$persistence_root" == /tmp/wing-linux-persistence.* ]] || return 1
  rm -r -- "$persistence_root"
}
trap cleanup_persistence EXIT
mkdir -p "$persistence_root/config" "$persistence_root/data" "$persistence_root/cache"
for phase in write verify; do
  env XDG_CONFIG_HOME="$persistence_root/config" \
    XDG_DATA_HOME="$persistence_root/data" XDG_CACHE_HOME="$persistence_root/cache" \
    WING_ISOLATED_PREFERENCES=1 WING_PERSISTENCE_PHASE="$phase" \
    xvfb-run -a flutter test -d linux integration_test/linux_persistence_e2e_test.dart --reporter expanded
done
