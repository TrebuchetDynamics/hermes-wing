#!/usr/bin/env bash
# Plan is side-effect-free; --run is reserved for the integrated source owner.
# Python must provide asyncssh; use an isolated QA venv, never system installs.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "${WING_SSH_KEY_PYTHON:-python3}" \
  "$ROOT/scripts/support/managed_ssh_key_native.py" "$@"
