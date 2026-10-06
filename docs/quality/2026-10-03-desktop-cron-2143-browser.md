# Desktop continuation — fresh compiled browser workflow

Occurrence: 2026-10-03 21:43 local. Single-owner bounded verification; no production/test implementation changes.

## Ownership and source binding

The [goal ledger](../plans/2026-10-03-desktop-port-goal.md), [integrated wave receipt](2026-10-03-desktop-daily-workflow-wave.md) and primary session release agree the prior scopes are released. Delegation and terminal tools returned no active handles; filtered process census found no competing Flutter/Dart/Xvfb/fixture/Playwright execution. This run claimed only the ledger and this receipt plus generated build output and wing scratch artifacts. No children were spawned.

HEAD: `ca149a82189c8c9e5abd98b376bfeae1e43f6f3f`. The worktree was already dirty; HEAD is not a content snapshot. Before/after SHA-256 maps of 499 production/test/platform/browser/script and dependency/config source files were identical. Manifest file digest: `20f7eda21499bfc4e9b1b68842783e12918e9aaa16b0dbec0d70a518e85b345a`. The manifests bind this bounded run, not every unrelated file in the worktree. Upstream Agent/Desktop/Conduit and personal runtime were not modified or scanned.

## Executed commands and environment

Linux Chromium, compiled Flutter JS-release E2E target, deterministic Node Agent API fixture. Flutter 3.44.2 (framework `c9a6c484230f8b5e408ec57be1ef71dee1e77020`, user-branch/unknown source), Dart 3.12.2; Node v26.7.0 (not the repository's intended Node 22); Chromium 152.0.7977.75 on Ubuntu 24.04.4 LTS.

```sh
flutter build web --release --no-pub -t lib/main_e2e.dart
PORT=9278 HERMES_E2E_PORT=9279 node serve_web.mjs
CHROME_EXECUTABLE=/usr/bin/chromium \
  WING_APP_URL=http://127.0.0.1:9278/ HERMES_E2E_PORT=9279 \
  PLAYWRIGHT_JSON_OUTPUT_FILE="$TMPDIR/desktop-cron-2143-browser/playwright.json" \
  ./node_modules/.bin/playwright test \
  playwright/tests/regression/production-chat-journey.spec.mjs \
  playwright/tests/regression/session-restoration.spec.mjs \
  --workers=1 --retries=0 --reporter=list,json \
  --output="$TMPDIR/desktop-cron-2143-browser/browser-artifacts"
```

Build exit 0 (03:45:17–03:46:08 UTC October 4 / October 3 local); browser command exit 0 (03:46:08–03:47:19 UTC). Owned fixture health returned `status: ok`; app root returned HTTP 200 before tests. Compiled `build/web/main.dart.js` SHA-256: `ca26b754738822a031d12acdcb2545424aa920cee7cd4132e3ce5333605ed7ee`.

Build emitted existing flutter_tts Wasm interop and missing Cupertino font warnings. This is a JS build, not Wasm qualification. No dependency acquisition, installation, native build or unchanged full-suite rerun occurred.

## Readback-validated results

**8 passed, 0 failed, 0 skipped, 0 flaky; one result per test, retries disabled.** Parent parsed reporter results and all eight attached fixture JSON receipts, rather than trusting exit alone.

- Two production Chat journeys, at 390px and 1280px: explicit saved host/default-profile/session selection; streamed synthetic output/tool activity; exact approval request correlation; denial; Stop acknowledgment kept composer blocked until authoritative synthetic terminal status/history reconciliation; transport EOF and explicit recovery; subsequent deliberate prompt. Each final receipt has exactly 5 ordered submits, 3 approval responses, 1 Stop, zero unexpected mutations and canonical user history. These are fixture readbacks through production `HermesApiChannel`, not actual provider output.
- Six restoration journeys, at both widths: page-two UI selection from 60 sessions, exact metadata/history on reload without inventory fallback; parked read failure and explicit same-owner Retry; picker Escape cancellation and manual selection superseding a late old-owner response. Each receipt preserves 60 sessions and records **zero mutations**, hence no restoration submits, session creations or approval responses. Canonical message and saved owner assertions passed.
- The restored and production Chat flows are separate scenarios. They do not prove one integrated local connect/model/generation/stop/process-relaunch workflow. Explicit model selection, full keyboard-only traversal, 200% text, physical screen-reader behavior, native process relaunch and actual provider generation were not qualified by this run. 390px Chromium is not Android.

## Logs and cleanup

Logs/artifacts: `/home/xel/.hermes/profiles/wing/cache/scratch/desktop-cron-2143-browser/`:

- `run.py`: bounded synchronous orchestrator, build deadline 180s, browser deadline 240s; fixture cleanup in finally.
- `results.json`, `sdk.log`, `node.log`, `browser.log`, `build.log`, `server.log`, `journeys.log`, `playwright.json`.
- `sources-before.json`, `sources-after.json`, `baseline-status.log`, `validated-artifacts.json`, and `browser-artifacts/` containing eight attached journey JSON files.

Exclusive fixture PID `1457397` was terminated and reaped with exit -15 (SIGTERM). Post-run loopback connection checks on both owned ports returned 111 (connection refused); filtered process census found no remaining QA commands. No pre-existing process/listener was killed or reused. The synchronous runner exited 0. Lease is released in the goal ledger after receipt/link/diff checks.

## Remaining gate and next checkpoint

Fresh compiled Chat/reload subset passes; daily-use milestone remains open. Native execution is still gated by the previously observed missing libsecret/GStreamer development metadata and separately reviewed native integration; these were not retried with unchanged prerequisites. Live qualification still requires an approved isolated target and supported private auth for `openai-codex` / `gpt-6.1-sol`. No model substitution, auth scanning, acceptance/card, roadmap, commit, release or scheduler changes occurred.

Next dependency-ready bounded task: claim explicit session-model picker compiled-browser/readback verification and its owner-isolation assertions from daily-workflow step 4. Preserve the separate-scenario gap; do not infer integrated local workflow completion from adding independent passing checks. Do not repeat this unchanged eight-test gate just to fill a tick. Native/private-auth work requires owner resolution before execution.

Run summary: not_available — host accounting was not exposed.
