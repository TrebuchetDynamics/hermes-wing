# Long-conversation reading in Chat

Chat projects loaded canonical turns before allocating transcript row widgets.
The initial view includes the newest 100 eligible loaded turns; empty completed
text turns without attachments remain skipped. A short contiguous tool group
crossing the boundary can include up to 100 additional turns. Longer groups
remain bounded and are labeled continued.

Show up to 100 earlier loaded turns reveals local history deliberately, with a
remaining count. It is not an Agent request. Load earlier messages remains a
separate Agent pagination action, including its existing loading and error
behavior. No Agent history limit or persisted transcript store is introduced.

While browsing, the presentation keeps a bounded newest boundary rather than
continually adding incoming output. Semantic reading anchors use unique canonical
turn IDs; ambiguous or deleted anchors fall back to Latest safely. Latest activity
restores the newest bounded projection and follow mode. Origin, profile and
session changes invalidate queued restoration. Approval and error rows are not
windowed; Latest activity brings their existing actions back into reach.

Copy transcript and per-message actions continue using the full loaded canonical
history. Copy is not an export of unloaded Agent pages. No transcript content is
added to diagnostics.

## Reproduce the deterministic browser qualification

Use the resolved package map without dependency or lockfile updates:

```bash
/opt/flutter/bin/flutter --no-version-check build web --release --no-pub -t lib/main_e2e.dart
PORT=18767 HERMES_E2E_PORT=18768 node serve_web.mjs
PLAYWRIGHT_BROWSERS_PATH=/opt/data/cache/wing-playwright \
WING_APP_URL=http://127.0.0.1:18767/ HERMES_E2E_PORT=18768 \
./node_modules/.bin/playwright test \
  playwright/tests/regression/hermes-smoke.spec.mjs \
  playwright/tests/regression/browser-surfaces.spec.mjs \
  playwright/tests/regression/chat-approval-confirmations.spec.mjs \
  playwright/tests/regression/chat-window.spec.mjs --retries=0
```

Choose unused loopback ports first and stop only the owned fixture process after
testing. The direct installed Playwright command avoids the web:e2e wrapper's
implicit build without --no-pub and performs no package installation.

The fixed synthetic fixture accepts only 250 or 1000 turns. The 1000-turn journey
loads existing 500-message Agent pages before testing local presentation reveal.
The E2E-only projection inspection counts allocated row widgets in the ListView
child delegate, not merely mounted semantics nodes. Receipts contain numeric
counts and synthetic geometry only. The test exercises keyboard reveal, appended
fixture history/canonical refresh, Latest, full loaded copy and pending approval
recovery at 390px and 1280px widths.

This evidence qualifies the Chromium deterministic Flutter UI only. It is not
real provider generation, Android/device testing, native Linux application
qualification, Wasm support, full upstream parity or a measured latency/speed
improvement. The executor used Flutter 3.47.5 / Dart 3.13.4 and Node 26.5.1;
the repository's intended Flutter 3.44.2 / Node 22 toolchain was not available.
