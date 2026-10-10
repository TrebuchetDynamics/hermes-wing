#!/usr/bin/env bash
set -euo pipefail
umask 077
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
exec python3 -B "$ROOT/scripts/support/desktop_no_inference_smoke.py" "$@"
