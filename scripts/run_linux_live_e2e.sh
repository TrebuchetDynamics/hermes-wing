#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# This manifest must come from real, isolated Agent profiles.
# Credentials are runtime-only files, never dart-defines or command arguments.
: "${WING_LIVE_PROFILE_MANIFEST:?Provide an owner-only real Agent profile manifest}"
manifest="$WING_LIVE_PROFILE_MANIFEST"
[[ -f "$manifest" && ! -L "$manifest" && -O "$manifest" ]] || { echo 'Live manifest must be an owned regular file, not a symlink.' >&2; exit 2; }
mode="$(stat -c '%a' "$manifest")"
(( (8#$mode & 077) == 0 )) || { echo 'Live manifest must have owner-only permissions.' >&2; exit 2; }
runner=()
if [[ -z "${DISPLAY:-}" ]]; then runner=(xvfb-run -a); fi
"${runner[@]}" flutter test -d linux integration_test/linux_real_profiles_e2e_test.dart --reporter expanded
