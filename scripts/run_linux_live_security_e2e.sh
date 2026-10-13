#!/usr/bin/env bash
set -euo pipefail
# Preserve historical invocations without reviving removed product controls.
printf '%s\n' 'Retired Linux product revoke/re-pair journey. For offline retained service checks, run: bash scripts/run_linux_live_retained_security_service_e2e.sh' >&2
exit 2
