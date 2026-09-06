#!/usr/bin/env bash
# Standalone entrypoint: keep these reviewed pins aligned with the source-mode
# assets/config/termux_bootstrap.json. No checkout or JSON parser is needed.
set -euo pipefail
umask 077

hermes_commit='afc3d9d34c9c3b01fa2e1332d2c66a5b5fabae3f'
hermes_installer_sha256='5854b15670b51a8daae8f59ddfa917062de9f74be261eb73b4b8d719710f8968'
hermes_installer_size=170273
wing_commit='21b87ca8c35fb20f95eb1cd3d3bd7db9317ada8b'
wing_archive_sha256='54b516e987a28e6670fac701266baf66683e1d0398ddf8e76295a501a5f0d4d6'
wing_archive_size=4420863
wing_installer_sha256='19f11b165445ba59b6b5bf9a9925a8f622786805a9c95cbfb1ee33ebc84fce5d'

usage() {
  cat <<'HELP'
Usage: bash install-termux.sh [--update-hermes] [--verify-only]

Install Hermes Agent and Wing Link in ARM64 Termux, then start local setup.
Packages, pinned downloads, integrity checks, and temporary cleanup are handled
here. Keep Termux in the foreground and follow the pairing link when ready.

  --update-hermes Install the reviewed pinned Hermes revision even if installed.
  --verify-only  Download and verify the pinned artifacts without installing
                 packages, executing installers, or starting services.
  --help         Show this help without changing anything.
HELP
}

verify_only=false
update_hermes=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --verify-only) verify_only=true ;;
    --update-hermes) update_hermes=true ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done

if [[ "$verify_only" == false ]]; then
  [[ -n "${TERMUX_VERSION:-}" && "${PREFIX:-}" == /data/data/com.termux/files/usr ]] || {
    echo 'Open Termux on your Android phone and run this script there.' >&2
    exit 2
  }
  [[ "$(uname -m)" == aarch64 ]] || {
    echo 'This installer currently requires ARM64 Termux.' >&2
    exit 2
  }
  printf '\n[1/4] Installing required Termux packages...\n'
  pkg install -y curl coreutils tar golang clang
fi

for tool in curl mktemp sha256sum wc tr tar timeout; do
  command -v "$tool" >/dev/null || {
    echo "Required command is missing: $tool" >&2
    exit 2
  }
done

work_dir=$(mktemp -d)
trap 'rm -rf -- "$work_dir"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

verify_digest() {
  printf '%s  %s\n' "$2" "$1" | sha256sum --check --status - || {
    echo 'Integrity verification failed. No installer was executed.' >&2
    exit 1
  }
}

download_verified() {
  local url="$1" destination="$2" size="$3" digest="$4"
  curl --proto '=https' --proto-redir '=https' --tlsv1.2 \
    --fail --location --connect-timeout 15 --max-time 300 \
    --max-filesize "$size" --output "$destination" "$url"
  [[ "$(wc -c < "$destination" | tr -d '[:space:]')" == "$size" ]] || {
    echo 'Download size did not match the reviewed artifact. No installer was executed.' >&2
    exit 1
  }
  verify_digest "$destination" "$digest"
}

printf '\n[2/4] Downloading and verifying Hermes Agent and Wing Link...\n'
hermes_installer="$work_dir/hermes-install.sh"
archive="$work_dir/source.tar.gz"
download_verified \
  "https://raw.githubusercontent.com/NousResearch/hermes-agent/$hermes_commit/scripts/install.sh" \
  "$hermes_installer" "$hermes_installer_size" "$hermes_installer_sha256"
download_verified \
  "https://codeload.github.com/TrebuchetDynamics/hermes-wing/tar.gz/$wing_commit" \
  "$archive" "$wing_archive_size" "$wing_archive_sha256"
tar --extract --gzip --file "$archive" --directory "$work_dir" \
  --no-same-owner --no-same-permissions
source_dir="$work_dir/hermes-wing-$wing_commit"
verify_digest "$source_dir/install-wing-link.sh" "$wing_installer_sha256"

if [[ "$verify_only" == true ]]; then
  echo 'Verified both downloads and the Wing Link installer. Nothing was installed.'
  exit 0
fi

printf '\n[3/4] Installing or adopting Hermes Agent...\n'
installed_hermes=false
existing_hermes=$(type -P hermes || true)
if [[ -n "$existing_hermes" && "$update_hermes" == false ]]; then
  if ! timeout --kill-after=2s 15s "$existing_hermes" --version >/dev/null 2>&1; then
    echo 'Hermes is installed but its version check failed. Diagnose it with hermes doctor before retrying; this script will not overwrite it.' >&2
    exit 1
  fi
  echo 'Reusing the existing Hermes installation.'
else
  installed_hermes=true
  "$PREFIX/bin/bash" "$hermes_installer" --commit "$hermes_commit" \
    --skip-setup --non-interactive --hermes-home "$HOME/.hermes"
fi
# Match the Go host helper's direct execution semantics. A shell-only probe can
# succeed where Android rejects or misroutes the generated script launcher.
cat > "$work_dir/check-hermes.go" <<'GO'
package main
import ("context"; "os"; "os/exec"; "time")
func main() {
  ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
  defer cancel()
  launcher := os.Getenv("WING_INSTALL_CHECK_EXECUTABLE")
  if exec.CommandContext(ctx, launcher, "--version").Run() != nil { os.Exit(1) }
}
GO
if ! WING_INSTALL_CHECK_EXECUTABLE=hermes go run "$work_dir/check-hermes.go" && [[ "$installed_hermes" == true ]]; then
  # Android can misroute script argv under Go's direct exec. Replace only the
  # launcher this run just installed, after a native candidate passes the probe.
  cat > "$work_dir/hermes-launcher.c" <<'C'
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
int main(int argc, char **argv) {
  const char *home = getenv("HOME");
  char python[PATH_MAX], entry[PATH_MAX];
  if (!home) return 1;
  int p = snprintf(python, sizeof(python), "%s/.hermes/hermes-agent/venv/bin/python", home);
  int e = snprintf(entry, sizeof(entry), "%s/.hermes/hermes-agent/hermes", home);
  if (p < 0 || p >= sizeof(python) || e < 0 || e >= sizeof(entry)) return 1;
  char **args = calloc((size_t)argc + 2, sizeof(char *));
  if (!args) return 1;
  args[0] = python;
  args[1] = entry;
  for (int i = 1; i < argc; i++) args[i + 1] = argv[i];
  unsetenv("PYTHONPATH");
  unsetenv("PYTHONHOME");
  execv(python, args);
  return 1;
}
C
  clang -fPIE -pie -o "$work_dir/hermes-native" "$work_dir/hermes-launcher.c"
  WING_INSTALL_CHECK_EXECUTABLE="$work_dir/hermes-native" go run "$work_dir/check-hermes.go"
  # Stage on the destination filesystem so activation is one rename.
  launcher_stage=$(mktemp "$PREFIX/bin/.hermes-wing-XXXXXX")
  if ! cp "$work_dir/hermes-native" "$launcher_stage" ||
     ! chmod 700 "$launcher_stage" ||
     ! mv -fT "$launcher_stage" "$PREFIX/bin/hermes"; then
    rm -f -- "$launcher_stage"
    exit 1
  fi
  echo 'Installed a verified native Hermes launcher for Android.'
fi
if ! WING_INSTALL_CHECK_EXECUTABLE=hermes go run "$work_dir/check-hermes.go"; then
  echo 'Hermes could not be launched by the host helper. Setup stopped before Wing Link could attempt another installation. Run hermes doctor locally.' >&2
  exit 1
fi
printf '\n[4/4] Building Wing Link and starting local setup...\n'
# The pinned host helper otherwise probes Android interfaces before --listen,
# which can fail under Android's netlink restrictions. Keep this phone local.
WING_LINK_LISTEN=127.0.0.1:8654 \
  "$PREFIX/bin/bash" "$source_dir/install-wing-link.sh" --build --setup
