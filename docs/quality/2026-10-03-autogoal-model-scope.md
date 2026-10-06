# Autogoal — daily model-lock profile discovery

## Selected bounded task

Source: `docs/quality/2026-10-03-desktop-cron-2255-integrated.md`, ranked next
proposal and failed 390/1280px continuous journey. Correct the daily synthetic
fixture's exact `session_model_lock` profile-scope advertisement, add discovery
regression coverage, and exercise integrated plus nearest legacy browser gates.
No production Dart, upstream, credentials, packages or tracker state changed.

## Changes

- `serve_web.mjs`: advertise `profile_scoped: true` for session model locking
  only when the lifecycle scenario is `desktop-daily`. Ordinary model-picker and
  legacy no-body lifecycle behavior retain their existing capability shape.
- `playwright/support/hermes_desktop_daily_fixture_test.mjs`: assert daily exact
  endpoint scope/context discovery, legacy lifecycle endpoint absence and ordinary
  model-picker endpoint shape. Existing owner-denial assertions remain unchanged.
- Goal ledger updated with a single-owner task lease and observed completion/gap.

Existing dirty server/test edits were preserved with targeted patches. This is a
fixture discovery correction, not a new actual Agent capability or permission.

## Observed verification

Logs/artifacts:
`/home/xel/.hermes/profiles/wing/cache/scratch/autogoal-model-scope/`.

| Exact check | Exit / observed result |
| --- | --- |
| `node --test playwright/support/hermes_desktop_daily_fixture_test.mjs` before server change | 1; expected RED, 2 passed / 1 failed because `profile_scoped: true` was missing. `red.log`, `red-result.json`. |
| Same command after scoped fix | 0; 3 passed / 0 failed / 0 skipped. `green.log`, `green-result.json`; repeated by browser runner as `fixture-regressions.log`. |
| `flutter build web --release --no-pub -t lib/main_e2e.dart` | 0; fresh artifact, `build.log`, execution 2026-10-04T05:20:24.838261Z–05:21:06.621723Z. |
| `./node_modules/.bin/playwright test playwright/tests/regression/desktop-daily-workflow.spec.mjs --workers=1 --retries=0 --reporter=list,json --output=<scratch>/integrated-artifacts` | 1; 0 passed / 2 failed / 0 skipped / 0 flaky, one attempt each. Both widths advanced beyond model confirmation to the Stop/reconnect assertion at spec line 155. |
| `./node_modules/.bin/playwright test playwright/tests/regression/production-chat-journey.spec.mjs playwright/tests/regression/session-model-picker.spec.mjs playwright/tests/regression/session-restoration.spec.mjs --workers=1 --retries=0 --reporter=list,json --output=<scratch>/legacy-artifacts` | 0; 10 passed / 0 failed / 0 skipped / 0 flaky, retries disabled. `legacy.log`, `legacy.json`, `legacy-result.json`. |

Integrated run environment: `CHROME_EXECUTABLE=/usr/bin/chromium`,
`WING_APP_URL=http://127.0.0.1:9284/`, `HERMES_E2E_PORT=9285`,
`PLAYWRIGHT_JSON_OUTPUT_FILE=<scratch>/integrated.json`. Owned fixture:
`PORT=9284 HERMES_E2E_PORT=9285 node scripts/support/desktop_daily_workflow_fixture.mjs`.
Legacy fixture used separately reserved ephemeral loopback ports, recorded by its
runner. An initial legacy admission attempt could not bind the prior fixed port
(errno 98); no tests/services started in that attempt. Fresh QA census was empty,
then the runner reserved ephemeral ports and the legacy gate passed.

Exact command arrays/exits/timestamps and cleanup are in `results.json`; legacy
command/cleanup in `legacy-result.json`. Playwright JSON supplies parsed counts.
Artifact SHA-256:
`ca26b754738822a031d12acdcb2545424aa920cee7cd4132e3ce5333605ed7ee`.
Execution-source manifest was unchanged during the integrated run. No tests or
assertions were weakened to force green. No full Dart suite was rerun during the
initial bounded slice; the explicitly requested supplemental run below followed.

## Requested supplemental verification

`npm run test` (which invokes `flutter test --concurrency=1`) ran after a fresh
exclusive Flutter-owner check. Exit **0**, 2026-10-04T05:26:35.061548Z–
05:31:20.435290Z; runner summary `04:42 +2397: All tests passed!`.
Logs: `npm-test.log` and exact command/exit/timestamps `npm-test-result.json` in the
same scratch directory. No repairs were needed. This Dart suite does not execute
the failing Playwright journey; the separate browser gap below remains open.

## Remaining blocker and disposition

**Fixture advertisement regression fixed; full continuous workflow gate remains
failed.** Both 390px and 1280px now reach model rejection/confirmation, Chat,
approval and Stop, but the browser cannot find the expected semantic group for
`Synthetic canonical stopped outcome.` after Reconnect:
`playwright/tests/regression/desktop-daily-workflow.spec.mjs:155`.

Error contexts are preserved under `integrated-artifacts/*/error-context.md`.
This run does not yet establish whether the next failure is production recovery,
fixture composition or selector/semantic projection. That is a separate bounded
investigation; no speculative production fix or second task was started.

Integrated fixture PID 1563581 reaped (143); public ports closed (111/111).
Legacy fixture PID 1567078 reaped (-15); public ports closed (111/111).
No native build/packages, actual provider generation, runtime/card acceptance,
commits, release or full Desktop parity claim. Native/live owner prerequisites
remain unchanged. The task lease is released with the next exact failed assertion
recorded in the goal ledger.
