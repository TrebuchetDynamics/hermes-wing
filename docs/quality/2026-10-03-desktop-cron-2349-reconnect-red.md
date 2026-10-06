# Desktop continuation — minimized Reconnect regression preparation

## Result and boundary

**Latest status after the follow-up verification request: fixed and Dart-verified.**
Real Reconnect now restores the directory's exact profile/session instead of
selecting a page-zero default. Final requested `npm run test`: **exit 0, 2,398
passed**. Formatter/analyzer and 53 focused tests also pass. Fresh compiled-browser
and native/live qualification remain open. The sections below retain earlier
failed attempts; the final repair section supersedes their unverified status.

Added [a real Chat Reconnect regression](../../test/features/hermes_chat/screens/hermes_chat_reconnect_owner_test.dart), using the existing production `HermesApiChannel` and `HermesGatewayDirectory` [HTTP restoration harness](../../test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart). **Intended RED is not yet observed.** The only test execution failed in setup before the Reconnect button was exercised. No production fix was made and no passing workflow is claimed.

The [previous attribution](2026-10-03-desktop-cron-2333-stop-attribution.md) remains a source/artifact hypothesis, not newly reproduced runtime proof. This occurrence deliberately narrows to off-page session and profile identity; confirmed model, uncertain Stop and full compiled-browser recovery remain subsequent gates.

## Admission and ownership

Read the [goal ledger](../plans/2026-10-03-desktop-port-goal.md), [daily plan](../plans/2026-10-03-desktop-daily-workflow.md), CONTEXT, CONTRIBUTING, ROADMAP and current client/API ADRs before edits. Prior primary conversation records its suite completion; occurrence process/delegation lists are empty and OS census finds no competing Flutter/Dart/browser/fixture/display command. Empty occurrence-local lists alone were not treated as exclusivity.

One direct owner, ordered prerequisite before production repair. Exact lease: new regression, this receipt, goal ledger and wing scratch evidence. Existing dirty production/tests/fixtures/server/ROADMAP and Agent/Desktop/Conduit references remain read-only. No workers, network/inference, installs, personal runtime mutation, cards, commits, scheduler edits or native build. OMH-specific routing/accounting tools are unavailable; native todo tracking was used and no delegation was dispatched.

## Regression contract and observed failure

The new test restores `older-A` outside page-zero inventory with profile `coder`, provokes a real unsupported-transport channel error without any HTTP submit, and is wired to tap `hermes-chat-error-reconnect`. It asserts active and persisted exact owner, canonical A history, profile-scoped exact metadata read and no mutations. A synthetic-only diagnostic records both active/persisted identity and read paths before post-Reconnect assertions.

Observed first execution:

```text
flutter test --no-pub --concurrency=1 --reporter=expanded test/features/hermes_chat/screens/hermes_chat_reconnect_owner_test.dart
exit 1; 0 passed / 1 failed
Expected: <Instance of 'GatewayContactSelection'>
  Actual: <Instance of 'GatewayContactSelection'>
...hermes_chat_reconnect_owner_test.dart:28:7
```

The setup incorrectly compared object instances. [GatewayContactSelection](../../lib/features/hermes_chat/gateways/gateway_contact_cache.dart) has no value equality; directory persistence creates another instance. Replaced both setup and post-action comparisons with exact `contactId` and `sessionId` field assertions; this corrects the test oracle, not expected owner identity. The test was **not rerun**, respecting the occurrence's no-same-tick-gate-retry policy. Actual post-Reconnect identity, saved-pointer changes and request counts are therefore unobserved here.

## Commands and evidence

Scratch: `/home/xel/.hermes/profiles/wing/cache/scratch/desktop-cron-2349-reconnect-red/`.

- Initial `dart format <new test>`: exit 0, one file formatted.
- Focused Flutter test: exit 1, setup failure above; 2026-10-04T05:51:08Z–05:51:10Z. `red.log`, exact commands/timestamps in `commands.json`. This is **not** an intended behavior RED.
- After field-oracle correction, `dart format --output=none --set-exit-if-changed <new test>`: exit 0, zero changes.
- `flutter analyze --no-pub`: exit 1, exactly one warning, unused directory import in the new test. Removed that import; analyzer was not rerun, so final analyzer success is **not verified**. `analyze.log`, `static-commands.json`.
- Closing source-hash/document/diff checks and tool versions recorded in `checks.json` / `versions.log`; no behavior qualification implied.

No real browser/native surface or provider executed. Linux Flutter widget runner loaded the production restoration harness and passed active profile/session setup, then failed the object-comparison assertion before mounting Chat. No services/displays were created; synchronous commands exited. No QA resource is retained.

## Explicitly requested supplemental verification

After fresh exclusive process admission, `npm run test` ran at
2026-10-04T05:54:08Z–05:59:02Z: **exit 1, 2,397 passed / 1 failed**.
The sole failure was the new test's setup: unsupported `sendText` throws a
StateError without publishing a channel error. No Reconnect action occurred.
Logs: `npm-test.log`, `npm-test-result.json`, `npm-test-parsed.json` in the
scratch directory above.

Setup repairs were attempted only in the leased new test. Capturing the expected
throw still yielded null `errorMessage`. Replaced the trigger with a failed
session-pagination read; focused runs `read-error-focused.log` and
`read-error-final.log` also fail the setup's non-null error assertion before
mounting Chat. Broadening the synthetic read interceptor from offset 50 to the
sessions path did not change that result. The working restoration harness does
not establish that this pagination operation is eligible at this point; do not
infer request execution from its method call. No intended owner-loss RED yet.
Stopped these setup attempts rather than trying another untraced error trigger.
The new regression remains failing/unverified; no assertions were skipped,
weakened or deleted, and no production repair was authorized by this setup failure.

Final static gates: `dart format <new test>` **exit 0, zero changes**;
`flutter analyze --no-pub` **exit 0, no issues**.
`supplemental-static-results.json` records commands/exits. The full suite remains
failed, not superseded by the clean analyzer. No browser/native/provider execution.
Supplemental verification ownership is released; next scope must inspect the
harness's current pagination admission and choose a traced read/error trigger
before another RED attempt. This replaces the earlier proposed immediate retry.

## Follow-up repair and final verification

Traced the null-error setup to the [session-page decoder](../../lib/core/hermes/models/hermes_session.dart): it reads `has_more` and offset/limit at the top level, whereas the reused harness puts them in `pagination`. Consequently `loadMoreSessions` was ineligible. The new test now supplies the actual top-level page shape and asserts `hasMoreSessions` before injecting the failing read; existing harness/test files remain unchanged. This is test composition correction, not relaxed production admission.

First admitted attempt reached real Reconnect but timed out during settlement. A bounded diagnostic pump showed only `/health` requested and no restored identity; inspection found the test's empty endpoint-store override omitted the synthetic bearer required by its reused HTTP harness. Supplied that same-origin synthetic fixture config. `credential-owner-red.log` then produced the **intended RED, exit 1**:

```text
active=newer-B profile=default saved=newer-B savedProfile=coder
reads=[/health, /v1/capabilities, /api/sessions?profile=default,
       /api/sessions/newer-B/messages?profile=default]
mutations=0
Expected: older-A
Actual: newer-B
```

After recording a precise production lease, added only nine lines to
[Chat's Reconnect handler](../../lib/features/hermes_chat/screens/state/hermes_chat_connection.dart).
When a directory contact and active session exist, it calls existing
`directory.activate(contactId, preferredSessionId: sessionId)` and returns.
This seam defers default session selection, selects the exact profile, restores
metadata/canonical history, fences stale activations and exposes restoration
failures instead of falling back. No new transport/credential/state authority.
Direct connections without a directory owner retain the previous equivalent-URL
credential selection and duplicate-tap guard. The prior dirty session-panel
restoration guard is preserved, not attributed to this repair.

First post-fix run passed the owner/history/read assertions but failed teardown:
Riverpod and the reused harness both disposed the directory. The new test now
transfers disposal ownership through the harness's existing `disposed` flag when
its provider is built. Assertions remain intact; no skip/delete/xfail.

Final observed gates:

- Formatter: `dart format lib/features/hermes_chat/screens/state/hermes_chat_connection.dart test/features/hermes_chat/screens/hermes_chat_reconnect_owner_test.dart` — **exit 0, two files / zero changes**.
- `flutter analyze --no-pub` — **exit 0, no issues**.
- `flutter test --no-pub --concurrency=1 --reporter=expanded` on the new Reconnect test, auth recovery, exact-session directory restoration and adversarial restoration targets — **exit 0, 53 passed**. `fix-focused.log` / `fix-focused-static-results.json`.
- Requested `npm run test` — **exit 0, 2,398 passed**, 2026-10-04T06:06:38Z–06:11:27Z. `npm-test-fixed.log`, `npm-test-fixed-result.json`; parent-parsed counts, zero error markers/skips and source hashes in `fixed-verification.json`.
- GREEN diagnostic: active **older-A/coder**, saved **older-A/coder**, exact A metadata/history reads carry `profile=coder`, **zero mutations**. Canonical A history and no B persistence assertions pass.
- Four consumed read-only source hashes remain unchanged. Scoped diff review confirms only this occurrence's Reconnect insertion plus the pre-existing session-panel change in the production diff; all other dirty changes preserved.

Actual surface exercised: real Flutter Chat Reconnect control in the Linux widget
runner with production channel/directory and deterministic HTTP responses. This is
not compiled Chromium, native GTK, uncertain Stop/run recovery, confirmed-model
restoration, actual provider output or independent review. No upstream changes,
personal auth access, service launch or retained QA resource. SDK: Flutter 3.44.2 /
Dart 3.12.2 from the recorded version command. Ownership released after the gate.

## Next checkpoint

Fresh exclusive ownership, fresh compiled web build and the integrated daily
workflow plus nearest legacy Chat/picker/restoration browser gate at both widths.
Preserve original assertions and capture exact owner/model/canonical stopped
history plus zero restoration mutation receipts. The minimized widget error is a
failed read, not an uncertain Stop; that complete-flow claim must come from the
browser/native gates. Independent review and native/live qualification remain open.
