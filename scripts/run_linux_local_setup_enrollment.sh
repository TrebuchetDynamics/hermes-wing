#!/usr/bin/env bash
set -euo pipefail
umask 077
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# Cooperate with the native heavyweight lane before snapshots or compilation.
LOCK_ROOT="${TMPDIR:?}/desktop-daily-workflow-harness"
mkdir -p "$LOCK_ROOT"
exec 9>"$LOCK_ROOT/flutter-owner.lock"
flock -w 180 9 || { printf 'Native build owner occupied.\n'; exit 3; }
# Reuse the established user-space development packages, without host installation.
DEPS="$ROOT/.task-evidence/t_636ced72/deps/root"
export PKG_CONFIG_PATH="$DEPS/usr/lib/x86_64-linux-gnu/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export CMAKE_PREFIX_PATH="$DEPS/usr${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
export LIBRARY_PATH="$DEPS/usr/lib/x86_64-linux-gnu${LIBRARY_PATH:+:$LIBRARY_PATH}"
export CPATH="$DEPS/usr/include${CPATH:+:$CPATH}"
exec python3 -B "$ROOT/scripts/support/local_setup_enrollment_native.py" "$@"
