#!/usr/bin/env bash
# Explicit stdin-only authorization; no credential discovery or Agent bootstrap.
set -euo pipefail
umask 077
cd "$(dirname "${BASH_SOURCE[0]}")/.."
exec python3 -B scripts/support/desktop_live_workflow.py "$@"
