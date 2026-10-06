# Desktop continuation — fresh integrated browser gate, 2026-10-04 00:26

## Result

**Reconnect ownership repair advances both continuous journeys past the previous
Stop/Reconnect failure. The complete journey still fails after leaving Chat and
returning: the composer shows `Hermes model` instead of the confirmed session
model.** No production/test/fixture changes in this occurrence and no gate retry.

390px and 1280px each pass canonical stopped-history visibility, cancelled run
readback, route-return history visibility and exact saved-pointer equality before
failing `expectModel` at
[desktop-daily-workflow.spec.mjs:168](../../playwright/tests/regression/desktop-daily-workflow.spec.mjs).
Reload, model-picker reopen and the final explicit resumed send were not reached.
Full zero-replay and integrated completion are not established by these failures.

## Ownership and scope

The [goal ledger](../plans/2026-10-03-desktop-port-goal.md) and prior occurrence's
release agree all previous producer scopes are released. Native delegation and
terminal lists were empty; OS process census found no competing Flutter/Dart/
fixture/Playwright/Xvfb command. `hermes cron list` showed this occurrence running
(job `6f218a559ed2`) and hourly autogoal completed, not another active writer.

One owner leased only the goal ledger, this new receipt, generated `build/web`
and wing-profile scratch runner/log/artifacts. ROADMAP, production, tests, shared
fixture/server and Agent/Desktop/Conduit stayed read-only. No subagents, installs,
full Dart suite, upstream tools, auth discovery, personal runtime mutation,
inference, cards, commits, release or scheduler changes.

Durable process `proc_24ec75011900`, PID 1745920, confirmed
`persist_on_release: true`. The cron host rejected async notification support;
one bounded `process_manage wait` returned the completed runner, exit **1**.
Requested wait 550s was clamped by the host to 180s; it completed in that call.
Runner deadline was 540s with per-command limits and owned cleanup. No polling.

## Observed commands and evidence

Scratch root:
`/home/xel/.hermes/profiles/wing/cache/scratch/desktop-cron-0026-browser/`.
`run.py` records exact command arrays, timestamps, exits and cleanup in
`results.json`. Parent parsed result counts/attempts in `parsed-results.json`.

| Command | Observed result |
| --- | --- |
| `node --test playwright/support/hermes_desktop_daily_fixture_test.mjs` | Exit 0; 3 passed, 0 failed/cancelled/skipped. Discovery/owner rejection/legacy behavior assertions executed. |
| `flutter build web --release --no-pub -t lib/main_e2e.dart` | Exit 0, fresh compiled artifact; 06:27:05–06:27:52 UTC. |
| `./node_modules/.bin/playwright test playwright/tests/regression/desktop-daily-workflow.spec.mjs --workers=1 --retries=0 --reporter=list,json --output=<scratch>/integrated-artifacts` | Exit 1; 0 passed, 2 failed, 0 skipped/flaky, exactly one attempt each. 06:27:52–06:28:30 UTC. |
| `./node_modules/.bin/playwright test playwright/tests/regression/production-chat-journey.spec.mjs playwright/tests/regression/session-model-picker.spec.mjs playwright/tests/regression/session-restoration.spec.mjs --workers=1 --retries=0 --reporter=list,json --output=<scratch>/legacy-artifacts` | Exit 0; 10 passed, 0 failed/skipped/flaky, exactly one attempt each. 06:28:30–06:29:50 UTC. |

Integrated fixture: `node scripts/support/desktop_daily_workflow_fixture.mjs`,
reserved ephemeral loopback ports 59649/55087. Legacy fixture separately used
`node serve_web.mjs`, ports 40417/56797. Each environment had
`PORT`, `HERMES_E2E_PORT`, `WING_APP_URL`,
`CHROME_EXECUTABLE=/usr/bin/chromium`, and a distinct
`PLAYWRIGHT_JSON_OUTPUT_FILE`; exact values/paths in results/runner.

Flutter 3.44.2 / Dart 3.12.2; Chromium 152.0.7977.75 on Linux/Ubuntu 24.04.4.
Node v26.7.0 differs from intended Node 22; no provisioning attempted.
Build retained existing flutter_tts Wasm dry-run and Cupertino font warnings;
compiled JavaScript browser evidence is not Wasm qualification.

HEAD `ca149a82189c8c9e5abd98b376bfeae1e43f6f3f` is dirty, not a content snapshot.
`build/web/main.dart.js` SHA-256:
`1fd06e46da0ee35790449a2d1893c1561c58c4145fe04f6c296f2f75ae7f90ff`.
499 bounded execution-source hashes matched before/after (`sources-*.json`),
excluding private fixture directories and nested upstream/tool/build trees.
This is a verification manifest, not a parser census or semantic graph.

## Indexed source attribution and bounded proposals

1. **Observed surface gap, not Stop ownership failure:** both Playwright failures
   call model expectation at spec:168, after assertions at :155–167 succeed.
   Wide error context shows the exact E2E session, canonical stopped transcript,
   active-session/status model `alpha/model-99`, but composer checkbox
   `Hermes model`. Compact error context has the same failed expectation.
   Error contexts/logs remain under `integrated-artifacts/` and `integrated.log`.
2. **Divergent presentation sources:**
   [layout:667–670](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart)
   uses `activeSession.model` for the active-session bar; layout:1280–1288 uses
   volatile `sessionModelLocks` or profile assignment for the composer, not that
   session metadata. Picker current selection uses the lock map at :1209–1224.
3. **Volatile versus authoritative read:**
   [disconnect:4–12](../../lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart)
   clears channel state; restore/select at :15–119 reloads exact metadata/history.
   [HermesSession:31–55](../../lib/core/hermes/models/hermes_session.dart) decodes
   the session model but not a provider/accepted runtime lock pair.
   [lock handling:172–221](../../lib/core/hermes/channel/api_channel/hermes_api_channel_providers.dart)
   populates lock state only after an acknowledged deliberate model write.
   These inspected sources explain the presentation mismatch; they do not prove
   that the server changed the session model or lost its accepted lock.
4. **Fixture contract distinction:**
   [daily model handler:61–87](../../playwright/support/hermes_lifecycle_fixture.mjs)
   sets authoritative synthetic session model/runtime on acceptance. That does
   not authorize the client to fabricate an accepted provider/model lock from a
   model-name-only metadata field. Actual advertised Agent runtime authority and
   nearest upstream tests must be traced before adding any runtime-pair decoder.
   Upstream runtime/tests were not executed in this occurrence.

Ranked next work, ordered rather than concurrent:

- **P1 — exact-session composer recovery regression.** Claim a new
  `test/features/hermes_chat/screens/hermes_chat_model_restoration_test.dart`
  (reuse the production-channel restoration harness read-only), and conditional
  smallest presentation-only edit to
  `lib/features/hermes_chat/screens/state/hermes_chat_layout.dart` after genuine
  RED. Assert recovered authoritative session model display on route return,
  wrong-owner fencing, and zero model-lock/session/send mutations. No persistent
  lock cache or fabricated provider identity. Exit: observed focused RED/GREEN,
  formatter/analyzer, nearest picker/restoration tests and fresh compiled gate.
- **P2 — reopened picker provider/model authority prerequisite.** Before a
  channel/model/client change, trace unmodified Agent discovery, metadata/runtime
  schema, nearest upstream tests and Wing decoders. A model display fallback alone
  cannot prove an accepted provider/model pair. Record precise supported read
  contract or a blocker; never restore this by repeating the model mutation.

This verification-only occurrence did not expand its lease into either edit.
No assertion was changed or weakened, and no same-tick browser rerun occurred.
This is the first occurrence of the new route-return model-display failure, not
three consecutive failures of the earlier Stop/Reconnect blocker.

## Cleanup and remaining gates

Runner reaped integrated fixture PID 1747172 (143) and legacy PID 1748422 (-15).
All four public ports refused connections (111). Node fixture tests also emitted
reaped/closed-port receipts for all three owned children. Parent final OS census
was empty (`close-census.json`); no owned QA processes or pending child remain.

Nearest legacy gates pass independently; they do not complete the continuous
journey. Native two-process execution, separately reviewed local integration,
approved private live auth/inference and independent acceptance remain open.
Native prerequisites were not retried; no new native support claim. Lease released
with the next checkpoint above. Scoped document/link/status checks are recorded
in `close-checks.json`.
