#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# These manifests must come from real, isolated Agent and Wing Link services.
# Credentials are runtime-only files, never dart-defines or command arguments.
: "${WING_LIVE_PROFILE_MANIFEST:?Provide an owner-only real Agent profile manifest}"
: "${WING_LIVE_LINK_MANIFEST:?Provide an owner-only real Wing Link pairing manifest}"
: "${WING_LIVE_LINK_BINARY:?Provide the matching local Wing Link binary for host approval}"
: "${WING_LINK_STATE:?Provide the isolated Wing Link state used by that binary}"
for manifest in "$WING_LIVE_PROFILE_MANIFEST" "$WING_LIVE_LINK_MANIFEST"; do
  [[ -f "$manifest" && -O "$manifest" ]] || { echo 'Live manifest must be an owned regular file.' >&2; exit 2; }
  mode="$(stat -c '%a' "$manifest")"
  (( (8#$mode & 077) == 0 )) || { echo 'Live manifest must have owner-only permissions.' >&2; exit 2; }
done
runner=()
if [[ -z "${DISPLAY:-}" ]]; then runner=(xvfb-run -a); fi
for target in integration_test/linux_real_profiles_e2e_test.dart integration_test/linux_live_wing_link_test.dart; do
  "${runner[@]}" flutter test -d linux "$target" --reporter expanded
done
