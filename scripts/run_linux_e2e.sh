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
if [[ -z "${DISPLAY:-}" ]]; then
  if ! command -v xvfb-run >/dev/null 2>&1; then
    echo 'xvfb-run is required when DISPLAY is unset.' >&2
    exit 2
  fi
  runner=(xvfb-run -a)
fi

"${runner[@]}" flutter test \
  -d linux \
  integration_test/linux_fixture_e2e_test.dart \
  --concurrency=1
