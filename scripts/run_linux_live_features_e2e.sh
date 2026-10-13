#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
umask 077
# Agent session organization and inventory/navigation only.
# Unlike run_linux_live_e2e.sh, this target does not request provider inference.
: "${WING_LIVE_PROFILE_MANIFEST:?Provide an owner-only isolated Agent manifest}"
manifest="$WING_LIVE_PROFILE_MANIFEST"
[[ -f "$manifest" && ! -L "$manifest" && -O "$manifest" ]] || exit 2
mode="$(stat -c '%a' "$manifest")"
(( (8#$mode & 077) == 0 )) || { echo 'Live manifests must be owner-only.' >&2; exit 2; }

temp_root=$(realpath "${TMPDIR:-/opt/data/cache/scratch}")
coverage_root=$(mktemp -d "$temp_root/wing-linux-coverage.XXXXXX")
cleanup_coverage() {
  [[ "$(dirname "$coverage_root")" == "$temp_root" &&
     "$(basename "$coverage_root")" == wing-linux-coverage.* ]] || return 1
  rm -r -- "$coverage_root"
}
trap cleanup_coverage EXIT
mkdir -p "$coverage_root/config"
touch "$coverage_root/.wing-linux-test-owner"

env TMPDIR="$temp_root" WING_LINUX_TEST_ROOT="$coverage_root" \
  XDG_CONFIG_HOME="$coverage_root/config" \
  xvfb-run -a flutter test -d linux integration_test/linux_live_feature_journeys_test.dart --reporter expanded
