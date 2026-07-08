#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
exec scripts/build_send_apk.sh "$@"
