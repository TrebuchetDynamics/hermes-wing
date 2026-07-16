#!/bin/bash
# Run Hermes Wing Playwright E2E tests
set -e

echo "=== Hermes Wing Playwright E2E Tests ==="
echo ""

# Kill any existing server on port 8767
kill $(lsof -ti:8767) 2>/dev/null || true
sleep 1

# Build the Flutter web app if not already built or if --rebuild flag is passed
if [ ! -f "build/web/main.dart.js" ] || [ "$1" == "--rebuild" ]; then
  echo "Building Flutter web e2e app..."
  flutter build web --release -t lib/main_e2e.dart 2>&1 | tail -3
  echo ""
fi

echo "Starting test server..."
node serve_web.mjs &
SERVER_PID=$!
sleep 2

# Check server health
if ! curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8767/ | grep -q 200; then
  echo "ERROR: Test server failed to start"
  kill $SERVER_PID 2>/dev/null
  exit 1
fi
echo "Test server running on http://127.0.0.1:8767"
echo ""

# Run the Playwright tests
echo "Running Playwright tests..."
npx playwright test --config=playwright.config.mjs 2>&1
EXIT_CODE=$?

# Cleanup
echo ""
echo "Stopping test server..."
kill $SERVER_PID 2>/dev/null

exit $EXIT_CODE