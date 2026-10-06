# Desktop continuation — integrated browser regression and contract mismatch

Occurrence: 2026-10-03 22:55 local; gate executed 22:59–23:00 local.
Status: new regression implemented, compiled browser gate failed; complete workflow
not verified. No same-occurrence qualification retry.

## Owned change and admission

[Goal ledger](../plans/2026-10-03-desktop-port-goal.md) and primary session release
agreed prior scopes were released. Native delegation/terminal lists were empty;
filtered OS census found no competing Flutter/Dart/browser/fixture/display work.
One owner leased only the ledger, this receipt and the new
[browser regression](../../playwright/tests/regression/desktop-daily-workflow.spec.mjs),
plus generated web output and wing scratch artifacts. No subagents were spawned.

The new regression uses one `desktop-daily` seed and real saved-contact activation,
explicit off-page session selection through **Load more sessions**, model
rejection/retry, correlated approval, authoritative Stop/reconnect, route leave,
reload and third deliberate send. It asserts exact stored owner, canonical
metadata/history/model, unchanged mutation arrays across navigation/reload/model
reopen Escape, and final 3 submits/2 approvals/1 Stop/2 lock attempts. These later
steps are written assertions, not executed passing behavior in this occurrence.

Existing fixtures, server, production Flutter, ROADMAP, native harness and upstream
references stayed read-only. Existing dirty changes were preserved. No installs,
personal runtime/auth access, inference, commits, card changes or scheduler edits.

## Observed commands and failure

Scratch evidence:
`/home/xel/.hermes/profiles/wing/cache/scratch/desktop-cron-2255-integrated/`.
`run.py` records bounded synchronous execution, command arrays, timestamps and
cleanup in `results.json`. Build deadline 180s; browser 240s; readiness 15s;
remaining runner budget caps command waits at a 480s whole-run deadline.

| Command | Result |
| --- | --- |
| `node --check playwright/tests/regression/desktop-daily-workflow.spec.mjs` | Exit 0. |
| `node --test playwright/support/hermes_desktop_daily_fixture_test.mjs` | Exit 0; 3 passed, 0 failed/cancelled/skipped. |
| `flutter build web --release --no-pub -t lib/main_e2e.dart` | Exit 0; fresh `build/web` compiled in 42.3s. Existing flutter_tts Wasm dry-run warnings remain; not Wasm qualification. |
| `PORT=9284 HERMES_E2E_PORT=9285 node scripts/support/desktop_daily_workflow_fixture.mjs` | Owned loopback service; readiness app 200 / health ok. |
| `CHROME_EXECUTABLE=/usr/bin/chromium WING_APP_URL=http://127.0.0.1:9284/ HERMES_E2E_PORT=9285 PLAYWRIGHT_JSON_OUTPUT_FILE=<scratch>/integrated.json ./node_modules/.bin/playwright test playwright/tests/regression/desktop-daily-workflow.spec.mjs --workers=1 --retries=0 --reporter=list,json --output=<scratch>/integrated-artifacts` | Exit 1; both 390px and 1280px failed at line 121; 0 passed, 2 failed, 0 skipped/flaky; exactly one attempt each. |
| `git diff --check` | Exit 0. Owned untracked-file whitespace/local-link checks separately recorded at close. |

Both widths reached saved default-profile contact, loaded page two, selected
`e2e-hermes-session`, searched/selected the exact alpha pair and displayed the
model-confirmation error. The first rejected-lock receipt was expected but
`model_locks` was empty. Neither browser journey reached generation, approval,
Stop or restoration. Playwright JSON was independently parsed into
`validated-results.json`; failure logs and semantic snapshots are retained in
`integrated.log` and `integrated-artifacts/*/error-context.md`.

The runner stopped after this gate. Its planned ten nearest legacy Chat/picker/
restoration cases did **not** run; there is no new legacy/browser acceptance.
No Flutter analyzer or Dart tests ran: this scope added JS regression coverage
without modifying Dart behavior. This is a reproduced gate failure, not a
completed tests-first behavior implementation or a red/green cycle.

## Source-backed cause and ranked next proposal

1. [Shared capability fixture](../../serve_web.mjs), lines 310–317 and 361–364,
   advertises lifecycle query profile context but omits `profile_scoped` on
   `session_model_lock`.
2. [Production lock caller](../../lib/core/hermes/channel/api_channel/hermes_api_channel_providers.dart),
   lines 183–201, passes the selected profile only when that exact endpoint
   advertises `profileScoped == true`.
3. [API client](../../lib/core/hermes/client/hermes_api_client.dart), lines 455–465,
   builds the lock URI using that supplied scope.
4. [Combined lifecycle fixture](../../playwright/support/hermes_lifecycle_fixture.mjs),
   lines 60–78, rejects a missing profile before recording any model attempt.
5. [Node regression](../../playwright/support/hermes_desktop_daily_fixture_test.mjs),
   lines 62–74, manually supplies `?profile=default`; therefore its passing HTTP
   test did not prove capability-driven browser composition.

This source chain explains the empty attempt receipts and is a fixture discovery/
handler mismatch, not evidence that an actual Agent model operation is broken.
No network status capture was attached to the failed lock, so the exact browser
HTTP status is not claimed from execution. Do not fix Wing to invent authority,
remove the handler's owner requirement or weaken the failing assertion.

**Next bounded scope:** freshly check ownership, then lease the exact scoped
`session_model_lock` capability entry in `serve_web.mjs` and the nearest Node
fixture regression, plus the existing new browser spec for failure-evidence
instrumentation only if needed. Advertise profile scoping only for the combined
`desktop-daily` scenario. Add a discovery assertion with observed red-before-green,
preserve ordinary picker/no-body lifecycle behavior, then execute fresh wide/
compact integrated and nearest legacy browser gates. Exit criteria: exact profile
query follows advertised scope; two lock attempts settle rejected/accepted; all
continuous journey assertions pass; legacy contracts stay unchanged; cleanup and
parent-parsed operation receipts match. Existing shared-server dirt must be read
and preserved before any scoped edit. No production or upstream repair is proposed.

Single-owner source review checked count/owner assertions and identified this
contract discrepancy. Independent review remains open. This is the first
occurrence with this mismatch, not three consecutive same-blocker failures.

## Binding and cleanup

Before/after scoped source manifests match for **501 files** during execution.
They include the new test and production/test/platform/browser/script dependency
subset, not all unrelated dirty docs or private runtime state. New spec SHA-256:
`3ff956f069e1be65292f1b912624fa14018c5e86c5114d5c9cf0868d399c9ec3`.
Fresh JS artifact SHA-256:
`ca26b754738822a031d12acdcb2545424aa920cee7cd4132e3ce5333605ed7ee`.
A dirty HEAD is not a content snapshot.

Fixture PID `1539422` terminated/reaped with exit 143; both public ports return
connection-refused code 111. Node fixture tests separately reaped PIDs 1538398,
1538416 and 1538432 (143) and checked their ports closed. Final process census
found no remaining Flutter/browser/fixture/display commands. No owned persistent
resource or pending worker remains.

Environment recorded in `sdk.log`, `node.log`, `chromium.log`: Flutter 3.44.2,
Dart 3.12.2, Chromium 152.0.7977.75 on Linux; Node v26.7.0 differs from intended
Node 22. Native two-process qualification, separately reviewed native integration
and approved live-provider generation remain open and were not retried.

## Requested supplemental verification

After the failed-browser report, an explicit follow-up requested `npm run test`.
Fresh admission census found no competing build/test process; the ledger leased
verification-only docs/scratch scope. Command ran once, foreground bounded to
540s, from 05:04:33 to 05:09:15 UTC October 4 and exited **0**. Parsed output:
`04:39 +2397: All tests passed!` — **2,397 passed, 0 skipped**, no error markers.
`npm-test.log`, `npm-test-result.json` and `npm-test-parsed.json` retain evidence.
New browser-spec Node syntax and scratch runner Python AST syntax checks also
passed; `git diff --check` passed and no QA command remained after the test exit.

`npm run test` invokes `flutter test --concurrency=1`; it does not run Playwright.
Therefore the integrated browser gate remains failed and the new JS regression
is **not fully verified**. Correcting the exact fixture advertisement requires a
new scoped server/test lease; the no-same-occurrence browser-retry rule remains
in force. No failing assertion or authorization requirement was weakened and no
production repair was made. Supplemental verification ownership is released.

Run summary: not_available — host accounting was not exposed.
