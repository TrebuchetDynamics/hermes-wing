#!/usr/bin/env bash
set -euo pipefail

repository="TrebuchetDynamics/hermes-wing"
tag=""
expected_sha256=""
expected_size=""
install_dir=""
build=false
release=false
quick_setup=false
use_sudo=false
custom_prefix=false

usage() {
  cat <<'EOF'
Usage:
  ./install-wing-link.sh [--prefix DIR]
  ./install-wing-link.sh --build [--setup] [--system | --prefix DIR]
  ./install-wing-link.sh --release [--setup] [--prefix DIR]
  ./install-wing-link.sh --tag TAG --sha256 HEX --size BYTES [--setup] [--prefix DIR]

By default, builds and installs the local Go wing_link package, then installs or
adopts Hermes Agent and starts its gateway. Release mode downloads an alpha Wing
Link binary and verifies it against its published checksum. Supplying immutable
release metadata verifies both the expected SHA-256 and exact byte size
out-of-band. The binary is always validated and atomically installed.

  --build       Build and install the local Go wing_link package
  --release     Download and install the most recent alpha release
  --setup       Install/adopt Hermes Agent, prepare API access, and start its gateway
  --system      With --build, install in /usr/local/bin (uses sudo when needed)
  --prefix DIR  Install in a custom directory
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build) build=true; shift ;;
    --release) release=true; shift ;;
    --setup) quick_setup=true; shift ;;
    --tag) tag="${2:?--tag requires a value}"; shift 2 ;;
    --sha256) expected_sha256="${2:?--sha256 requires a value}"; shift 2 ;;
    --size) expected_size="${2:?--size requires a value}"; shift 2 ;;
    --system) install_dir="/usr/local/bin"; use_sudo=true; shift ;;
    --prefix) install_dir="${2:?--prefix requires a directory}"; custom_prefix=true; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$build" == false && "$release" == false && -z "$tag" && -z "$expected_sha256" && -z "$expected_size" ]]; then
  build=true
  quick_setup=true
fi
[[ "$use_sudo" == false || "$custom_prefix" == false ]] || {
  echo "--system and --prefix cannot be combined." >&2
  exit 2
}
if [[ "$build" == true && ( "$release" == true || -n "$tag" || -n "$expected_sha256" || -n "$expected_size" ) ]]; then
  echo "Release options cannot be combined with --build." >&2
  exit 2
fi
if [[ "$release" == true && ( -n "$tag" || -n "$expected_sha256" || -n "$expected_size" ) ]]; then
  echo "--release cannot be combined with immutable release metadata." >&2
  exit 2
fi

termux=false
if [[ -n "${TERMUX_VERSION:-}" || "${PREFIX:-}" == /data/data/com.termux/* ]]; then
  [[ -n "${TERMUX_VERSION:-}" && -n "${PREFIX:-}" ]] || {
    echo "Termux setup requires TERMUX_VERSION and PREFIX." >&2
    exit 2
  }
  termux=true
  [[ -n "$install_dir" ]] || install_dir="${PREFIX}/bin"
else
  [[ -n "$install_dir" ]] || install_dir="${WING_LINK_INSTALL_DIR:-$HOME/.local/bin}"
fi

if [[ "$termux" == true ]]; then
  [[ "${PREFIX}" == "/data/data/com.termux/files/usr" ]] || {
    echo "--setup requires the canonical Termux prefix." >&2
    exit 2
  }
  [[ "$install_dir" == "${PREFIX}/bin" ]] || {
    echo "Wing Link installs only to the Termux prefix." >&2
    exit 2
  }
elif [[ "$quick_setup" == true && "$(uname -s)" != Linux ]]; then
  echo "--setup currently requires Linux or Android/Termux." >&2
  exit 2
fi

run_quick_setup() {
  local binary="$1"
  [[ "$quick_setup" == true ]] || return 0
  printf '\n[4/4] Installing or adopting Hermes Agent and starting its gateway...\n'
  if ! "$binary" setup; then
    echo "Host setup failed. Wing Link remains installed so you can inspect and retry." >&2
    echo "Retry: $binary setup" >&2
    return 1
  fi
  if [[ "$termux" == true ]]; then
    local runtime_dir="${HOME}/.local/state/hermes-wing-link"
    local log_file="${runtime_dir}/wing-link.log"
    [[ ! -L "$runtime_dir" ]] || { echo "Wing Link runtime directory must not be a symlink." >&2; return 1; }
    mkdir -p "$runtime_dir"
    [[ -d "$runtime_dir" && ! -L "$runtime_dir" ]] || { echo "Wing Link runtime directory is unsafe." >&2; return 1; }
    chmod 0700 "$runtime_dir"
    [[ ! -L "$log_file" ]] || { echo "Wing Link log file must not be a symlink." >&2; return 1; }
    touch "$log_file"
    [[ -f "$log_file" && ! -L "$log_file" ]] || { echo "Wing Link log file is unsafe." >&2; return 1; }
    chmod 0600 "$log_file"
    if ! curl --fail --silent --show-error --connect-timeout 2 --max-time 3 \
      http://127.0.0.1:8654/healthz >/dev/null 2>&1; then
      command -v nohup >/dev/null 2>&1 || { echo "nohup is required." >&2; return 1; }
      nohup "$binary" serve --listen 127.0.0.1:8654 >>"$log_file" 2>&1 &
      local health_attempt=0
      while (( health_attempt < 120 )); do
        if curl --fail --silent --show-error --connect-timeout 2 --max-time 3 \
          http://127.0.0.1:8654/healthz >/dev/null 2>&1; then
          break
        fi
        health_attempt=$((health_attempt + 1))
        sleep 0.25
      done
    fi
    curl --fail --silent --show-error --connect-timeout 2 --max-time 3 \
      http://127.0.0.1:8654/healthz >/dev/null 2>&1 || {
      echo "Wing Link did not become healthy on loopback." >&2
      return 1
    }
    printf '\nHermes and Wing Link are ready on this phone.\n'
    WING_LINK_SERVICE=external "$binary" pair --local --same-device
    return
  fi
  printf '\nHermes runtime is ready for provider setup.\n'
  printf 'Next: run hermes setup to choose a provider and model.\n'
  printf 'Same host: wing-link pair --local\n'
  printf 'Android with Tailscale: wing-link pair\n'
  printf 'Other VPNs: bind the Hermes API to its trusted address and set WING_HERMES_URL.\n'
  printf 'Guide: docs/runbooks/android-hermes-setup.md\n'
}

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
  ) >/dev/null 2>&1 &
  local watchdog_pid=$!
  wait "$probe_pid" || status=$?
  kill "$watchdog_pid" 2>/dev/null || true
  wait "$watchdog_pid" 2>/dev/null || true
  return "$status"
}

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

  printf '[2/3] Validating and installing binary...\n'
  run_version_probe "$tmp_bin"
  installed_version="$build_version"
  privileged=()
  if [[ "$use_sudo" == true && $EUID -ne 0 ]]; then
    command -v sudo >/dev/null 2>&1 || {
      rm -f "$tmp_bin"
      echo "sudo is required for --system." >&2
      exit 1
    }
    privileged=(sudo)
  fi
  "${privileged[@]}" mkdir -p "$install_dir"
  [[ ! -L "$install_dir" ]] || {
    rm -f "$tmp_bin"
    echo "Install prefix must not be a symlink." >&2
    exit 1
  }
  candidate="$install_dir/.wing-link.new.$$"
  backup="$install_dir/.wing-link.backup.$$"
  adoption_prepared=false
  source_build_rollback() {
    status=$?
    trap - EXIT INT TERM
    set +e
    rm -f "$tmp_bin"
    if [[ $status -ne 0 && "$adoption_prepared" == true ]]; then
      if [[ -e "$backup" ]]; then
        "${privileged[@]}" rm -f "$destination"
        "${privileged[@]}" mv "$backup" "$destination"
      elif [[ ! -e "$candidate" && -e "$destination" ]]; then
        "${privileged[@]}" rm -f "$destination"
      fi
    else
      "${privileged[@]}" rm -f "$backup"
    fi
    "${privileged[@]}" rm -f "$candidate"
    exit "$status"
  }
  trap source_build_rollback EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM

  if [[ -e "$destination" ]]; then
    [[ -f "$destination" && ! -L "$destination" ]] || {
      echo "Existing Wing Link destination is not a regular file." >&2
      exit 1
    }
  fi
  "${privileged[@]}" install -m 0755 "$tmp_bin" "$candidate"
  run_version_probe "$candidate"
  adoption_prepared=true
  if [[ -e "$destination" ]]; then
    "${privileged[@]}" mv "$destination" "$backup"
  fi
  "${privileged[@]}" mv "$candidate" "$destination"

  printf '[3/3] Verifying executable...\n'
  run_version_probe "$destination"
  trap - EXIT INT TERM
  rm -f "$tmp_bin"
  "${privileged[@]}" rm -f "$backup"
  printf '\nInstalled: %s\n' "$destination"
  printf 'Version:   %s\n' "$installed_version"
  if [[ "$quick_setup" == true ]]; then
    run_quick_setup "$destination"
  elif [[ ":$PATH:" == *":$install_dir:"* ]]; then
    printf 'Next:      wing-link inspect\n'
  else
    printf 'Next:      %s inspect\n' "$destination"
  fi
  if [[ ":$PATH:" != *":$install_dir:"* ]]; then
    printf 'PATH:      Add %s to run wing-link from any directory.\n' "$install_dir"
  fi
  printf 'Help:      %s help\n' "$destination"
  exit 0
fi

[[ "$use_sudo" == false ]] || {
  echo "--system requires --build." >&2
  exit 2
}
auto_release=$release
if [[ "$auto_release" == false && ( -z "$tag" || -z "$expected_sha256" || -z "$expected_size" ) ]]; then
  echo "--tag, --sha256, and --size must be supplied together." >&2
  exit 2
fi
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
  (( expected_size <= 52428800 )) || {
    echo "--size exceeds the 50 MiB Wing Link asset limit." >&2
    exit 2
  }
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
adoption_prepared=false

rollback() {
  status=$?
  trap - EXIT INT TERM
  set +e
  rm -rf "$work_dir"
  if [[ $status -ne 0 && "$adoption_prepared" == true ]]; then
    if [[ -e "$backup" ]]; then
      rm -f "$destination"
      mv "$backup" "$destination"
    elif [[ ! -e "$candidate" && -e "$destination" ]]; then
      rm -f "$destination"
    fi
  else
    rm -f "$backup"
  fi
  rm -f "$candidate"
  exit "$status"
}
trap rollback EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

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
fi
install -m 0755 "$work_dir/$asset" "$candidate"
run_version_probe "$candidate"
adoption_prepared=true
if [[ -e "$destination" ]]; then
  mv "$destination" "$backup"
fi
mv "$candidate" "$destination"
run_version_probe "$destination"

printf 'Installed verified %s to %s\n' "$asset" "$destination"
trap - EXIT INT TERM
rm -f "$backup"
rm -rf "$work_dir"
run_quick_setup "$destination"
