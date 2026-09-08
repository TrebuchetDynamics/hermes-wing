#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
umask 077
# Consumes/revokes the disposable device credential and pairs a replacement.
# Explicit opt-in is mandatory; never run with a personal runtime's manifests.
: "${WING_LIVE_REVOKE_AND_REPAIR:?Set to 1 only for an isolated disposable runtime}"
[[ "$WING_LIVE_REVOKE_AND_REPAIR" == 1 ]] || exit 2
: "${WING_LIVE_PROFILE_MANIFEST:?Provide the isolated Agent manifest}"
: "${WING_LIVE_LINK_MANIFEST:?Provide the isolated Wing Link manifest}"
: "${WING_LIVE_LINK_BINARY:?Provide the matching Wing Link binary}"
: "${WING_LINK_STATE:?Provide isolated Wing Link state}"
: "${WING_HERMES_HOME:?Provide the isolated Agent home}"
for manifest in "$WING_LIVE_PROFILE_MANIFEST" "$WING_LIVE_LINK_MANIFEST"; do
  [[ -f "$manifest" && ! -L "$manifest" && -O "$manifest" ]] || exit 2
  mode="$(stat -c '%a' "$manifest")"
  (( (8#$mode & 077) == 0 )) || exit 2
done
xvfb-run -a flutter test -d linux integration_test/linux_live_security_recovery_test.dart --reporter expanded
