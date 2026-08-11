#!/usr/bin/env bash
set -euo pipefail

repository="TrebuchetDynamics/hermes-wing"
tag=""
expected_sha256=""
install_dir=""

usage() {
  cat <<'EOF'
Usage: ./install-wing-link-release.sh --tag TAG --sha256 HEX [--prefix DIR]

Downloads one immutable-tag Wing Link release asset, verifies it against the
expected SHA-256 supplied out-of-band, validates the binary, and atomically
installs it for the current user. It never downloads or executes a checksum.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag) tag="${2:?--tag requires a value}"; shift 2 ;;
    --sha256) expected_sha256="${2:?--sha256 requires a value}"; shift 2 ;;
    --prefix) install_dir="${2:?--prefix requires a directory}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+-alpha\.[0-9]+$ ]] || {
  echo "--tag must be an alpha release tag." >&2
  exit 2
}
expected_sha256="${expected_sha256,,}"
[[ "$expected_sha256" =~ ^[a-f0-9]{64}$ ]] || {
  echo "--sha256 must be exactly 64 hexadecimal characters." >&2
  exit 2
}
command -v curl >/dev/null 2>&1 || { echo "curl is required." >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo "sha256sum is required." >&2; exit 1; }

termux=false
if [[ -n "${TERMUX_VERSION:-}" && -n "${PREFIX:-}" ]]; then
  termux=true
  [[ -n "$install_dir" ]] || install_dir="${PREFIX}/bin"
else
  [[ -n "$install_dir" ]] || install_dir="$HOME/.local/bin"
fi
[[ "$install_dir" == /* ]] || { echo "Install prefix must be absolute." >&2; exit 2; }

machine="$(uname -m)"
case "$machine" in
  x86_64|amd64) architecture="amd64" ;;
  aarch64|arm64) architecture="arm64" ;;
  *) echo "Unsupported architecture: $machine" >&2; exit 1 ;;
esac

if [[ "$termux" == true ]]; then
  [[ "$architecture" == arm64 ]] || {
    echo "This alpha supports Termux on ARM64 only." >&2
    exit 1
  }
  asset="wing-link-android-arm64"
else
  case "$(uname -s)" in
    Linux) asset="wing-link-linux-${architecture}" ;;
    Darwin) asset="wing-link-darwin-${architecture}" ;;
    *) echo "Use the Windows release asset on Windows." >&2; exit 1 ;;
  esac
fi

work_dir="$(mktemp -d)"
destination="$install_dir/wing-link"
candidate="$install_dir/.wing-link.new.$$"
backup="$install_dir/.wing-link.backup.$$"
backup_created=false
installed_new=false

rollback() {
  status=$?
  trap - EXIT
  rm -rf "$work_dir"
  rm -f "$candidate"
  if [[ $status -ne 0 ]]; then
    if [[ "$installed_new" == true ]]; then
      rm -f "$destination"
    fi
    if [[ "$backup_created" == true && -f "$backup" ]]; then
      mv "$backup" "$destination"
    fi
  else
    rm -f "$backup"
  fi
  exit "$status"
}
trap rollback EXIT

url="https://github.com/${repository}/releases/download/${tag}/${asset}"
curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
  --output "$work_dir/$asset" "$url"
(
  cd "$work_dir"
  printf '%s  %s\n' "$expected_sha256" "$asset" | sha256sum -c -
)
chmod 0755 "$work_dir/$asset"
"$work_dir/$asset" version >/dev/null

mkdir -p "$install_dir"
[[ ! -L "$install_dir" ]] || { echo "Install prefix must not be a symlink." >&2; exit 1; }
if [[ -e "$destination" ]]; then
  [[ -f "$destination" && ! -L "$destination" ]] || {
    echo "Existing Wing Link destination is not a regular file." >&2
    exit 1
  }
  mv "$destination" "$backup"
  backup_created=true
fi
install -m 0755 "$work_dir/$asset" "$candidate"
"$candidate" version >/dev/null
mv "$candidate" "$destination"
installed_new=true
"$destination" version >/dev/null

printf 'Installed verified %s to %s\n' "$asset" "$destination"
