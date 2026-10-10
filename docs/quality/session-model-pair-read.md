# Exact session model pair: bounded safe-picker delivery

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card: `t_3ad70dd4`, task `PARITY-PAIR-READ`, goal M1. This delivers the card's
contract-absence fallback, not exact-pair restoration parity. Native review is
requested for the bounded change; M1 remains partial.

## Contract trace

Read-only reference Agent revision: `158fd638da1629c8e62caf9ade1515d162def8ab`.
Desktop reference: `withdrawn reference revision`.

- Agent `gateway/platforms/api_server.py:3011-3043` projects session metadata:
  model text and `has_model_config`, but no provider, runtime or model snapshot.
  Exact GET at lines 3213-3219 uses that projection.
- Its capability table advertises POST `/api/sessions/{session_id}/model`, not
  a GET for the confirmed pair. GET `/api/model/options` at lines 2518-2531
  loads the profile picker context, without exact session identity. A catalog
  default is not an authoritative session pair.
- Nearest upstream tests: `tests/gateway/test_session_api.py:83-112` verifies
  exact GET does not expose model_config; lines 776-848 verify explicit lock
  and chat response runtime. Those mutation/turn receipts are not restoration
  reads. Upstream tests were inspected, not executed or modified.
- Desktop `src/renderer/src/screens/Chat/Chat.tsx:370-409` restores its own
  persisted session override. Copying that local authority into Wing would
  violate the no-shadow-state requirement; it is not an advertised Agent read.
- Wing `HermesApiClient.getSession` validates exact row identity;
  `hermes_api_channel_sessions.dart:15-54` admits the exact off-page row and
  fetches canonical history. `HermesSession` parses metadata, not a lock.
  Confirmed locks only enter channel state through an acknowledged explicit
  POST in `hermes_api_channel_providers.dart:172-222`; reconnect/profile
  switching clears that state. No new restoration read can recover fields
  absent from the advertised response.

## Delivered behavior

Chat supplies `requireExplicitSelection: true` to the existing picker. A known
acknowledged pair still seeds the picker (including unavailable identities).
An unknown pair leaves no row selected and disables Use for session until the
user chooses a catalog row. Copy explains that Agent does not report the pair;
cancelling leaves the session unchanged. No new API, lock cache, inferred
provider, reconnect write, or duplicated model-lock mutation was introduced.

The deterministic GET fixture no longer exposes its internal lock runtime.
The fixture regression retains lock identity and mutation assertions while
checking model metadata/config presence separately. The original continuous
browser workflow and its substantive assertions are unchanged.

Production-path widget regression uses the real API channel, gateway restoration
and Chat caller at 390/1280px; it checks unknown identity, explicit choice,
route remount, repeated picker cancel, exact owner/history and zero mutations.
The earlier RED receipt failed on a falsely preselected Beta/shared-model at
both widths. A resumed-run test failure was corrected by scoping row assertions
to picker descendants rather than unrelated selected shell ListTiles.

## Executed evidence

All commands below ran in the task-owned source copy
`<home>/.hermes/cache/scratch/t_3ad70dd4/repo`. Scoped source equality was
verified against the shared worktree before handoff. Retained compact receipts
are under `<home>/.hermes/cache/scratch/t_3ad70dd4/`; the copied repository
and large build output are removed after checks.

- PASS: `dart format --output=none --set-exit-if-changed lib/features/hermes_chat/screens/state/hermes_chat_layout.dart lib/features/hermes_chat/widgets/session_model_picker_sheet.dart test/features/hermes_chat/screens/hermes_chat_model_authority_test.dart`
- PASS: `flutter gen-l10n`
- PASS: `flutter analyze --no-pub` (no issues).
- PASS: `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_model_authority_test.dart test/features/hermes_chat/widgets/session_model_picker_sheet_test.dart test/features/hermes_chat/widgets/session_model_picker_search_test.dart test/features/hermes_chat/screens/hermes_chat_model_picker_open_order_test.dart test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart test/core/hermes/channel/hermes_api_channel_test.dart` (358 tests; `verified-focused-final.log`).
- PASS: `node --test playwright/support/hermes_desktop_daily_fixture_test.mjs` (3 tests, process/port cleanup verified).
- PASS: `NODE_OPTIONS=--max-old-space-size=2048 flutter build web --release --no-pub --no-wasm-dry-run -t lib/main_e2e.dart` (`verified-build.log`). Compiler warns about a missing Cupertino font family; this does not qualify native font rendering.
- FAIL: `PORT=18977 HERMES_E2E_PORT=18978 WING_APP_URL=http://127.0.0.1:18977/ CHROME_EXECUTABLE=/usr/bin/chromium NODE_OPTIONS=--max-old-space-size=2048 npx playwright test --config=playwright.config.mjs playwright/tests/regression/desktop-daily-workflow.spec.mjs --workers=1 --retries=0 --output=<home>/.hermes/cache/scratch/t_3ad70dd4/verified-browser-artifacts` (`verified-browser.log`). Incorrect plain-server launch omitted the daily pagination projection; both failed before restoration. Corrected by using the existing owned daily launcher, not by editing the workflow.
- FAIL: `PORT=18987 HERMES_E2E_PORT=18988 WING_APP_URL=http://127.0.0.1:18987/ CHROME_EXECUTABLE=/usr/bin/chromium NODE_OPTIONS=--max-old-space-size=2048 npx playwright test --config=playwright.config.mjs playwright/tests/regression/desktop-daily-workflow.spec.mjs --workers=1 --retries=0 --output=<home>/.hermes/cache/scratch/t_3ad70dd4/verified-daily-artifacts`, served by `PORT=18987 HERMES_E2E_PORT=18988 node scripts/support/desktop_daily_workflow_fixture.mjs` (`verified-daily.log`). Both widths reach line 192 and fail the retained exact alpha/model-99 selection assertion. Prior route/reload owner/history and no-replay assertions execute; final resume and mutation-count assertions after this failure are NOT_CHECKED.

Goals helper records the executed checks, marks the bounded task done and
renders/validates the ledger. This is not a broad M1-met claim. Shared dirty
TODO/goals changes are intentionally not included wholesale in the scoped code
commit: they contain unrelated sessions' documentation and evidence.

## Acceptance and Remaining

1. Contract trace and smallest safe fallback: delivered and regression-tested.
   Exact provider/model restoration: unsupported by inspected advertised reads.
2. Focused tests, formatter, analyzer and fresh compilation: pass. Original
   two-width integrated selection: fails, without weakened assertions. Final
   integrated mutation counts: NOT_CHECKED. No native/live Agent/inference or
   full-suite qualification is claimed.
3. Named task/goal evidence and local scoped commit: recorded for review;
   same-card native review handoff is the final step, not approval.

Defaults retained: no upstream modifications, API extension, shadow lock cache,
credentials, system installation, production mutation or release. A future
unmodified Agent capability must supply an exact owner-bound confirmed pair
before Wing can claim restoration parity. No owner decision is needed for this
bounded safe delivery.
