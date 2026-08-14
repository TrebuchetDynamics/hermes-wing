#!/usr/bin/env bash
set -euo pipefail

repository="TrebuchetDynamics/hermes-wing"
tag=""
expected_sha256=""
expected_size=""
install_dir=""
build=false
use_sudo=false
custom_prefix=false

usage() {
  cat <<'EOF'
Usage:
  ./install-wing-link.sh [--prefix DIR]
  ./install-wing-link.sh --tag TAG --sha256 HEX --size BYTES [--prefix DIR]
  ./install-wing-link.sh --build [--system | --prefix DIR]

By default, downloads the most recent alpha Wing Link release and verifies it
against its published checksum. Supplying immutable release metadata verifies
both the expected SHA-256 and exact byte size out-of-band. The binary is always
validated and atomically installed for the current user.

  --build       Build and install the local Go wing_link package instead
  --system      With --build, install in /usr/local/bin (uses sudo when needed)
  --prefix DIR  Install in a custom directory
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build) build=true; shift ;;
    --tag) tag="${2:?--tag requires a value}"; shift 2 ;;
    --sha256) expected_sha256="${2:?--sha256 requires a value}"; shift 2 ;;
    --size) expected_size="${2:?--size requires a value}"; shift 2 ;;
    --system) install_dir="/usr/local/bin"; use_sudo=true; shift ;;
    --prefix) install_dir="${2:?--prefix requires a directory}"; custom_prefix=true; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ "$use_sudo" == false || "$custom_prefix" == false ]] || {
  echo "--system and --prefix cannot be combined." >&2
  exit 2
}
if [[ "$build" == true && ( -n "$tag" || -n "$expected_sha256" || -n "$expected_size" ) ]]; then
  echo "Release verification options cannot be combined with --build." >&2
  exit 2
fi

termux=false
if [[ -n "${TERMUX_VERSION:-}" && -n "${PREFIX:-}" ]]; then
  termux=true
  [[ -n "$install_dir" ]] || install_dir="${PREFIX}/bin"
else
  [[ -n "$install_dir" ]] || install_dir="${WING_LINK_INSTALL_DIR:-$HOME/.local/bin}"
fi

if [[ "$build" == true ]]; then
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  source_dir="$script_dir/wing_link"
  [[ -d "$source_dir" && -f "$source_dir/go.mod" ]] || {
    echo "The wing_link Go package was not found beside this installer." >&2
    exit 1
  }
  [[ "$termux" == false || "$use_sudo" == false ]] || {
    echo "--system is not supported in Termux; Wing Link installs to ${PREFIX}/bin." >&2
    exit 2
  }

  destination="$install_dir/wing-link"
  app_version="$(awk '/^version:/{print $2; exit}' "$script_dir/pubspec.yaml")"
  app_version="${app_version%%+*}"
  [[ "$app_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
    echo "Could not determine the Wing Link version from pubspec.yaml." >&2
    exit 1
  }
  revision="unknown"
  dirty_suffix=""
  if command -v git >/dev/null 2>&1 && revision="$(git -C "$script_dir" rev-parse --short=8 HEAD 2>/dev/null)"; then
    if [[ -n "$(git -C "$script_dir" status --porcelain 2>/dev/null)" ]]; then
      dirty_suffix=".dirty"
    fi
  fi
  build_version="${app_version}-dev+${revision}${dirty_suffix}"

  printf 'Wing Link source build\n'
  printf '  Source:      %s\n' "$source_dir"
  printf '  Destination: %s\n' "$destination"
  printf '  Version:     %s\n\n' "$build_version"

  tmp_bin="$(mktemp)"
  trap 'rm -f "$tmp_bin"' EXIT
  build_args=(-trimpath -ldflags "-X main.version=$build_version" -o "$tmp_bin")
  if [[ "$termux" == true ]]; then
    build_args+=(-buildmode=pie)
  fi
  printf '[1/3] Building Go package...\n'
  (cd "$source_dir" && go build "${build_args[@]}" .)

  printf '[2/3] Installing binary...\n'
  if [[ "$use_sudo" == true && $EUID -ne 0 ]]; then
    command -v sudo >/dev/null 2>&1 || {
      echo "sudo is required for --system." >&2
      exit 1
    }
    sudo install -D -m 0755 "$tmp_bin" "$destination"
  else
    install -D -m 0755 "$tmp_bin" "$destination"
  fi

  printf '[3/3] Verifying executable...\n'
  installed_version="$("$destination" version)"
  printf '\nInstalled: %s\n' "$destination"
  printf 'Version:   %s\n' "$installed_version"
  if [[ ":$PATH:" == *":$install_dir:"* ]]; then
    printf 'Next:      wing-link inspect\n'
  else
    printf 'Next:      %s inspect\n' "$destination"
    printf 'PATH:      Add %s to run wing-link from any directory.\n' "$install_dir"
  fi
  printf 'Help:      %s help\n' "$destination"
  exit 0
fi

[[ "$use_sudo" == false ]] || {
  echo "--system requires --build." >&2
  exit 2
}
auto_release=false
if [[ -z "$tag" && -z "$expected_sha256" && -z "$expected_size" ]]; then
  auto_release=true
elif [[ -z "$tag" || -z "$expected_sha256" || -z "$expected_size" ]]; then
  echo "--tag, --sha256, and --size must be supplied together." >&2
  exit 2
fi
command -v curl >/dev/null 2>&1 || { echo "curl is required." >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo "sha256sum is required." >&2; exit 1; }
[[ "$install_dir" == /* ]] || { echo "Install prefix must be absolute." >&2; exit 2; }

if [[ "$auto_release" == true ]]; then
  releases="$(curl --proto '=https' --tlsv1.2 --fail --silent --show-error \
    --connect-timeout 15 --max-time 30 \
    "https://api.github.com/repos/${repository}/releases?per_page=100")"
  tag="$(printf '%s' "$releases" | grep -oE '"tag_name"[[:space:]]*:[[:space:]]*"v[0-9]+\.[0-9]+\.[0-9]+-alpha\.[0-9]+"' | awk -F'"' 'NR == 1 { print $4 }' || true)"
  [[ -n "$tag" ]] || {
    echo "No alpha Wing Link release was found." >&2
    exit 1
  }
  printf 'Using latest alpha release %s.\n' "$tag"
fi

[[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+-alpha\.[0-9]+$ ]] || {
  echo "--tag must be an alpha release tag." >&2
  exit 2
}
if [[ "$auto_release" == false ]]; then
  expected_sha256="${expected_sha256,,}"
  [[ "$expected_sha256" =~ ^[a-f0-9]{64}$ ]] || {
    echo "--sha256 must be exactly 64 hexadecimal characters." >&2
    exit 2
  }
  [[ "$expected_size" =~ ^[1-9][0-9]*$ ]] || {
    echo "--size must be the exact positive asset byte count." >&2
    exit 2
  }
fi

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

if [[ "$auto_release" == true ]]; then
  checksum_manifest="$work_dir/wing-link-checksums.sha256"
  curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
    --connect-timeout 15 --max-time 30 --max-filesize 65536 \
    --output "$checksum_manifest" \
    "https://github.com/${repository}/releases/download/${tag}/wing-link-checksums.sha256"
  expected_sha256="$(awk -v expected="$asset" '
    $2 == expected { count++; digest = $1 }
    END { if (count != 1) exit 1; print digest }
  ' "$checksum_manifest")" || {
    echo "Release checksum manifest did not contain exactly one entry for ${asset}." >&2
    exit 1
  }
  expected_sha256="${expected_sha256,,}"
  [[ "$expected_sha256" =~ ^[a-f0-9]{64}$ ]] || {
    echo "Release checksum for ${asset} was invalid." >&2
    exit 1
  }
fi

run_version_probe() {
  local binary="$1"
  local status=0
  "$binary" version >/dev/null 2>&1 &
  local probe_pid=$!
  (
    sleep 15
    kill -TERM "$probe_pid" 2>/dev/null || exit 0
    sleep 2
    kill -KILL "$probe_pid" 2>/dev/null || true
  ) &
  local watchdog_pid=$!
  wait "$probe_pid" || status=$?
  kill "$watchdog_pid" 2>/dev/null || true
  wait "$watchdog_pid" 2>/dev/null || true
  return "$status"
}

url="https://github.com/${repository}/releases/download/${tag}/${asset}"
download_limit="${expected_size:-52428800}"
curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
  --connect-timeout 15 --max-time 300 --max-filesize "$download_limit" \
  --output "$work_dir/$asset" "$url"
if [[ -n "$expected_size" ]]; then
  actual_size="$(wc -c < "$work_dir/$asset" | tr -d '[:space:]')"
  [[ "$actual_size" == "$expected_size" ]] || {
    echo "Downloaded asset size did not match the expected byte count." >&2
    exit 1
  }
fi
(
  cd "$work_dir"
  printf '%s  %s\n' "$expected_sha256" "$asset" | sha256sum -c -
)
chmod 0755 "$work_dir/$asset"
run_version_probe "$work_dir/$asset"

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
run_version_probe "$candidate"
mv "$candidate" "$destination"
installed_new=true
run_version_probe "$destination"

printf 'Installed verified %s to %s\n' "$asset" "$destination"
