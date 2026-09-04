#!/bin/bash
# Run Hermes Wing Playwright E2E tests
set -euo pipefail

echo "=== Hermes Wing Playwright E2E Tests ==="
echo ""

if ! node -e "const { existsSync } = require('node:fs'); const { chromium } = require('@playwright/test'); const browser = process.env.CHROME_EXECUTABLE; process.exit((browser && existsSync(browser)) || existsSync(chromium.executablePath()) ? 0 : 1)"; then
  echo "ERROR: No Chromium executable found. Set CHROME_EXECUTABLE or run 'npx playwright install chromium'."
  exit 1
fi

# Never kill an existing listener; it may belong to another local workflow.
export PORT="${PORT:-8767}"
export HERMES_E2E_PORT="${HERMES_E2E_PORT:-$((PORT + 1))}"
export WING_APP_URL="${WING_APP_URL:-http://127.0.0.1:$PORT/}"
for required_port in "$PORT" "$HERMES_E2E_PORT"; do
  if lsof -ti:"$required_port" >/dev/null 2>&1; then
    echo "ERROR: Port $required_port is already in use; stop its owner before running E2E tests." >&2
    exit 1
  fi
done

# The regular and e2e Flutter builds share build/web; always rebuild the e2e entrypoint.
echo "Building Flutter web e2e app..."
flutter build web --release -t lib/main_e2e.dart 2>&1 | tail -3
echo ""

cleanup() {
  echo ""
  echo "Stopping test server..."
  kill "$SERVER_PID" 2>/dev/null || true
  wait "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT

echo "Starting test server..."
node serve_web.mjs &
SERVER_PID=$!
sleep 2

# Check server health
if ! curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$PORT/" | grep -q 200; then
  echo "ERROR: Test server failed to start"
  exit 1
fi
echo "Test server running on http://127.0.0.1:$PORT"
echo ""

# Run each default suite in a fresh Playwright process. Flutter web and system
# Chromium accumulate enough resources across the full discovery set to make
# later timing-sensitive approval and speech flows flaky under CI load.
echo "Running Playwright tests..."
DEFAULT_SPECS=(
  playwright/tests/regression/browser-surfaces.spec.mjs
  playwright/tests/regression/browser-cors-streams.spec.mjs
  playwright/tests/regression/chat-approval-confirmations.spec.mjs
  playwright/tests/regression/chat-tts.spec.mjs
  playwright/tests/regression/hermes-lifecycle.spec.mjs
  playwright/tests/regression/hermes-live-say-hi.spec.mjs
  playwright/tests/regression/hermes-smoke.spec.mjs
  playwright/tests/screenshots/e2e-screenshots.spec.mjs
)
for spec in "${DEFAULT_SPECS[@]}"; do
  echo ""
  echo "Running $spec..."
  npx playwright test --config=playwright.config.mjs "$spec" 2>&1
done