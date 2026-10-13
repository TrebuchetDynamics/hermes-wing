#!/usr/bin/env bash
set -euo pipefail
umask 077
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
: "${WING_QA_DEVICE:?Set WING_QA_DEVICE to the approved disposable Android serial}"
: "${TMPDIR:?Set TMPDIR to private scratch}"
if (( $# != 0 )) || [[ "${WING_QA_DISPOSABLE:-}" != 1 || -n "${WING_LIVE_AUTH:-}" ]]; then
  printf 'Requires approved disposable ownership (WING_QA_DISPOSABLE=1), no live auth or extra arguments.\n' >&2
  exit 2
fi
# Cooperate with the established heavyweight lane and serialize this target.
LOCK_ROOT="$TMPDIR/desktop-daily-workflow-harness"
mkdir -p "$LOCK_ROOT"
exec 9>"$LOCK_ROOT/flutter-owner.lock"
flock -w 180 9 || exit 3
device_digest="$(printf '%s' "$WING_QA_DEVICE" | sha256sum)"
exec 8>"$LOCK_ROOT/android-${device_digest%% *}.lock"
flock -n 8 || { printf 'Selected target already has a writer.\n' >&2; exit 3; }
[[ "$(adb -s "$WING_QA_DEVICE" get-state)" == device ]] || {
  printf 'Selected target is not authenticated and reachable.\n' >&2
  exit 1
}
# The existing debug Gradle suffix produces com.trebuchetdynamics.hermes.wing.qa.
WING_ISOLATED_DEVICE_TEST=1 timeout 15m flutter test --no-pub \
  --device-id "$WING_QA_DEVICE" \
  --dart-define=WING_ANDROID_DIRECT_SETUP_QA=true \
  integration_test/android_direct_setup_enrollment_test.dart
