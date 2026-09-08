#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter is required for the Linux E2E test." >&2
  exit 1
fi

required_packages=(
  gtk+-3.0
  libsecret-1
  gstreamer-1.0
  gstreamer-app-1.0
  gstreamer-audio-1.0
)
missing_packages=()
for package in "${required_packages[@]}"; do
  pkg-config --exists "$package" || missing_packages+=("$package")
done
if ((${#missing_packages[@]})); then
  printf 'Missing Linux desktop packages: %s\n' "${missing_packages[*]}" >&2
  echo 'Install the Flutter Linux development dependencies before running this test.' >&2
  exit 2
fi

runner=()
# Clipboard/paste targets always get an owned display, even when other native
# tests can use an existing DISPLAY.
if ! command -v xvfb-run >/dev/null 2>&1; then
  echo 'xvfb-run is required for isolated native clipboard tests.' >&2
  exit 2
fi
if [[ -z "${DISPLAY:-}" ]]; then
  runner=(xvfb-run -a)
fi

# Separate launches avoid native debugger attachment races between targets.
for target in linux_fixture_e2e_test.dart linux_http_e2e_test.dart linux_transport_boundary_test.dart; do
  "${runner[@]}" flutter test -d linux "integration_test/$target" --reporter expanded
done
xvfb-run -a flutter test -d linux integration_test/linux_maestro_flows_test.dart --reporter expanded
xvfb-run -a flutter test -d linux integration_test/linux_large_reader_e2e_test.dart --reporter expanded
bash scripts/run_linux_persistence_e2e.sh
bash scripts/run_linux_native_input_e2e.sh
