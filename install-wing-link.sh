#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_dir="$script_dir/wing_link"
install_dir="${WING_LINK_INSTALL_DIR:-$HOME/.local/bin}"
use_sudo=false
termux=false
if [[ -n "${TERMUX_VERSION:-}" && -n "${PREFIX:-}" ]]; then
  install_dir="${PREFIX}/bin"
  termux=true
fi

usage() {
  cat <<'EOF'
Usage: ./install-wing-link.sh [--system | --prefix DIR]

Builds and installs wing-link (the Go wing_link package) for the current user
in ~/.local/bin by default.
  --system      Install machine-wide in /usr/local/bin (uses sudo when needed)
  --prefix DIR  Install in a custom directory
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --system) install_dir="/usr/local/bin"; use_sudo=true; shift ;;
    --prefix) install_dir="${2:?--prefix requires a directory}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -d "$source_dir" && -f "$source_dir/go.mod" ]] || {
  echo "The wing_link Go package was not found beside this installer." >&2
  exit 1
}

tmp_bin="$(mktemp)"
trap 'rm -f "$tmp_bin"' EXIT
[[ "$termux" == false || "$use_sudo" == false ]] || {
  echo "--system is not supported in Termux; Wing Link installs to ${PREFIX}/bin." >&2
  exit 2
}

build_args=(-trimpath -o "$tmp_bin")
if [[ "$termux" == true ]]; then
  build_args+=(-buildmode=pie)
fi
(cd "$source_dir" && go build "${build_args[@]}" .)

if [[ "$use_sudo" == true && $EUID -ne 0 ]]; then
  command -v sudo >/dev/null 2>&1 || {
    echo "sudo is required for --system." >&2
    exit 1
  }
  sudo install -D -m 0755 "$tmp_bin" "$install_dir/wing-link"
else
  install -D -m 0755 "$tmp_bin" "$install_dir/wing-link"
fi

"$install_dir/wing-link" version >/dev/null
printf 'Installed wing-link to %s\n' "$install_dir/wing-link"
if [[ ":$PATH:" != *":$install_dir:"* ]]; then
  printf 'Add %s to PATH to run wing-link from any directory.\n' "$install_dir"
fi
