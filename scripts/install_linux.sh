#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
install_dir="${WING_LINUX_INSTALL_DIR:-$HOME/.local/opt/hermes-wing}"
bundle="$repo_root/build/linux/x64/release/bundle"

if [[ "$(uname -s)" != Linux ]]; then
  echo "Linux installation must run on Linux." >&2
  exit 2
fi
if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter is required for the Linux installation." >&2
  exit 1
fi

cd "$repo_root"
printf '[1/3] Fetching Flutter dependencies...\n'
flutter pub get

printf '[2/3] Building the Linux release bundle...\n'
./scripts/run_linux_release_build.sh

[[ -x "$bundle/wing" ]] || {
  echo "Linux release bundle was not produced." >&2
  exit 1
}

printf '[3/3] Installing the complete bundle...\n'
mkdir -p "$install_dir"
cp -a "$bundle/." "$install_dir/"

printf '\nInstalled: %s\n' "$install_dir/wing"
printf 'Run:       %s\n' "$install_dir/wing"
printf 'Override:  WING_LINUX_INSTALL_DIR=/path/to/install %s\n' "$0"
