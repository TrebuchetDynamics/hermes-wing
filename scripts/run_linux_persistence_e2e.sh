#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
umask 077
persistence_parent=$(realpath "${TMPDIR:-/tmp}")
persistence_root=$(mktemp -d "$persistence_parent/wing-linux-persistence.XXXXXX")
cleanup_persistence() {
  [[ "$(dirname "$persistence_root")" == "$persistence_parent" && "$(basename "$persistence_root")" == wing-linux-persistence.* && -f "$persistence_root/.wing-linux-test-owner" ]] || return 1
  rm -r -- "$persistence_root"
}
trap cleanup_persistence EXIT
mkdir -p "$persistence_root/config" "$persistence_root/data" "$persistence_root/cache" "$persistence_root/home"
touch "$persistence_root/.wing-linux-test-owner"
for phase in write verify; do
  env HOME="$persistence_root/home" WING_LINUX_TEST_ROOT="$persistence_root" \
    XDG_CONFIG_HOME="$persistence_root/config" \
    XDG_DATA_HOME="$persistence_root/data" XDG_CACHE_HOME="$persistence_root/cache" \
    WING_ISOLATED_PREFERENCES=1 WING_PERSISTENCE_PHASE="$phase" \
    xvfb-run -a flutter test --no-pub -d linux integration_test/linux_persistence_e2e_test.dart --reporter expanded
done
