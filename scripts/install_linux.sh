#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
install_dir="${WING_LINUX_INSTALL_DIR:-$HOME/.local/opt/hermes-wing}"
bin_dir="${WING_LINUX_BIN_DIR:-$HOME/.local/bin}"
bundle="$repo_root/build/linux/x64/release/bundle"

usage() {
  cat <<'EOF'
Usage: scripts/install_linux.sh

Build and install the Hermes Wing Linux bundle and launcher.
Set WING_LINUX_INSTALL_DIR to override the install directory.
EOF
}

if [[ $# -gt 0 ]]; then
  if [[ $# -eq 1 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then
    usage
    exit 0
  fi
  echo "Unknown argument: $*" >&2
  usage >&2
  exit 2
fi

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

printf '[3/3] Installing the complete bundle and launcher...\n'
install_parent="$(dirname -- "$install_dir")"
mkdir -p "$install_parent" "$bin_dir"
[[ ! -L "$install_dir" ]] || {
  echo "Install directory must not be a symlink: $install_dir" >&2
  exit 1
}

staging="$(mktemp -d "${install_dir}.new.XXXXXX")"
backup="${install_dir}.old.$$"
trap 'rm -rf "$staging"' EXIT
cp -a "$bundle/." "$staging/"
if [[ -e "$install_dir" ]]; then
  [[ ! -e "$backup" && ! -L "$backup" ]] || {
    echo "Could not prepare the previous Linux installation." >&2
    exit 1
  }
  mv "$install_dir" "$backup"
fi
if ! mv "$staging" "$install_dir"; then
  if [[ -e "$backup" ]]; then mv "$backup" "$install_dir"; fi
  echo "Could not activate the Linux installation." >&2
  exit 1
fi
trap - EXIT
rm -rf "$backup"

launcher="$bin_dir/hermes-wing"
[[ ! -L "$launcher" ]] || {
  echo "Launcher must not be a symlink: $launcher" >&2
  exit 1
}
printf -v quoted_binary '%q' "$install_dir/wing"
printf '#!/usr/bin/env bash\nexec %s "$@"\n' "$quoted_binary" > "$launcher"
chmod 0755 "$launcher"

printf '\nInstalled: %s\n' "$install_dir/wing"
printf 'Command:   %s\n' "$launcher"
printf 'Run:       hermes-wing\n'
printf 'Override:  WING_LINUX_INSTALL_DIR=/path/to/install %s\n' "$0"
if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
  printf 'PATH:      Add %s to run hermes-wing from any directory.\n' "$bin_dir"
fi
