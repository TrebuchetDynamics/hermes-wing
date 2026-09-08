#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
umask 077
# Agent inventory/navigation and a locally approved, temporary directory grant.
# Unlike run_linux_live_e2e.sh, this target does not request provider inference.
: "${WING_LIVE_PROFILE_MANIFEST:?Provide an owner-only isolated Agent manifest}"
: "${WING_LIVE_LINK_MANIFEST:?Provide an owner-only isolated Wing Link manifest}"
: "${WING_LIVE_LINK_BINARY:?Provide the matching Wing Link binary}"
: "${WING_LINK_STATE:?Provide the isolated Wing Link state}"
for manifest in "$WING_LIVE_PROFILE_MANIFEST" "$WING_LIVE_LINK_MANIFEST"; do
  [[ -f "$manifest" && ! -L "$manifest" && -O "$manifest" ]] || exit 2
  mode="$(stat -c '%a' "$manifest")"
  (( (8#$mode & 077) == 0 )) || { echo 'Live manifests must be owner-only.' >&2; exit 2; }
done
coverage_root=$(mktemp -d /tmp/wing-linux-coverage.XXXXXX)
cleanup_coverage() {
  [[ "$coverage_root" == /tmp/wing-linux-coverage.* ]] || return 1
  rm -r -- "$coverage_root"
}
trap cleanup_coverage EXIT
mkdir -p "$coverage_root/grant-root/child-folder"
cp test/fixtures/linux-picker-sample.txt "$coverage_root/grant-root/private-file.txt"
env WING_LIVE_DIRECTORY_ROOT="$coverage_root/grant-root" \
  xvfb-run -a flutter test -d linux integration_test/linux_live_feature_journeys_test.dart --reporter expanded
