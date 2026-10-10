#!/usr/bin/env bash
set -euo pipefail
umask 077
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/build/t_e168b601"
exec 9>"$ROOT/build/t_e168b601/owner.lock"
flock -n 9 || { printf 'Integrated restart owner occupied.\n'; exit 3; }
exec python3 -B "$ROOT/scripts/support/integrated_daily_restart_native.py" "$@"
