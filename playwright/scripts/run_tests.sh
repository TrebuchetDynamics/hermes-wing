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
if lsof -ti:8767 >/dev/null 2>&1; then
  echo "ERROR: Port 8767 is already in use; stop its owner before running E2E tests." >&2
  exit 1
fi

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
if ! curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8767/ | grep -q 200; then
  echo "ERROR: Test server failed to start"
  exit 1
fi
echo "Test server running on http://127.0.0.1:8767"
echo ""

# Run the Playwright tests
echo "Running Playwright tests..."
npx playwright test --config=playwright.config.mjs 2>&1