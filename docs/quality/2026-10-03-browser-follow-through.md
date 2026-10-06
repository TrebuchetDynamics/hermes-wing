# Browser follow-through verification

## Scope

Parent-run compiled JavaScript-release Chromium verification of the current dirty
Wing worktree on Linux. This is deterministic Agent API fixture evidence using
production `HermesApiChannel`, not actual Agent/provider inference, Android,
signed distribution, or tracked same-card acceptance. Existing unrelated changes
are preserved and the upstream repositories are not implementation targets.

## Executed build and focused journeys

```sh
flutter build web --release -t lib/main_e2e.dart
PORT=9168 HERMES_E2E_PORT=9169 node serve_web.mjs
curl --fail --silent http://127.0.0.1:9169/health
CHROME_EXECUTABLE=/usr/bin/chromium \
  WING_APP_URL=http://127.0.0.1:9168/ HERMES_E2E_PORT=9169 \
  npx playwright test \
  playwright/tests/regression/session-restoration.spec.mjs \
  playwright/tests/regression/production-chat-journey.spec.mjs \
  --workers=1 --retries=0 --reporter=list
```

Build exit 0: `Built build/web`. Build emitted existing `flutter_tts` Wasm
compatibility warnings and a missing Cupertino icon font warning; this receipt
does not qualify Wasm. Fixture readiness returned `status: ok`.

Focused journey exit 0: **8 passed**, at 390px and 1280px. This includes two
production Chat approval/Stop/transport-recovery flows and six exact-session
restoration flows (page-two selection/reload, failed exact read/Retry, and
manual-choice supersession/picker cancellation).

## Broader browser gate

A separate notified bounded process runs each deterministic spec in a fresh
Playwright process with one worker and zero retries. Per-spec logs and copied
JSON reporters are saved under `tools/verification/2026-10-03-browser/` with an
incremental `summary.json`. It excludes live API/provider tests and separate
landing/packaged-artifact targets; those require their own prerequisites and do
not count as executed by this run. Results are pending and will be recorded
only after the process completion is delivered.

The loopback fixture server belongs to this verification and must be stopped
when the broader run finishes. No existing listener was killed or reused.
