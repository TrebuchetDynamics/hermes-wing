# Saved Agent endpoint edit and read-only test

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card: `t_c7e40011`. Goal task: `M1-SAVED-ENDPOINT-EDIT` (bounded M1 connection recovery slice). Executor qualification only; native review follows this handoff. No main delivery or full M1 completion is claimed.

## Implemented behavior

The public saved endpoint row in Add Hermes exposes **Edit saved Agent connection**. Its independent modal draft edits the Agent URL and an obscured replacement credential, explicitly removes a credential, tests discovery, saves, or cancels. Opening, editing, testing and cancelling never connect a channel or change the active conversation.

Saved credentials are never prefilled. Blank replacement preserves the original credential only for an unchanged canonical Agent URL; changing the URL requires a separately supplied credential. Changed Agent identity drops the saved Wing Link association instead of forwarding management trust. The secure store updates the exact original saved ID and rejects another saved endpoint's URL, preserving same-label/profile peers. Explicit Save failure keeps the draft for explicit retry. Saving reports local persistence, not remote authentication or reconnection.

Test creates a separate direct Agent API client and makes exactly one `GET /v1/capabilities`, retaining a `/p/<profile>` prefix. It validates the supported discovery document and distinguishes denied credentials from unavailable/invalid/error outcomes. The existing cleartext credential warning is reused. It never creates sessions, sends prompts, approves, stops, connects Chat, saves the draft, or uses Wing Link. A 20-second timeout bounds loading. Cancel test invalidates the result, not an already dispatched network request; late results cannot announce success. There is no automatic retry. URL components that would be silently discarded or contain secrets are rejected.

The owner/form generation and channel/directory/store identities fence callbacks, including away/back transitions. Save begun while owned can finish its authorized storage write after ownership loss, but cannot refresh a replacement directory, pop a replacement editor, reconnect or announce success. Disposal similarly rejects late UI settlement.

## Reference and authority trace

Read-only Desktop reference: `withdrawn source citation` uses separate saved connection selection, remote URL/API key draft, save and test controls. Wing implements the bounded equivalent with native Flutter widgets, not Desktop's SSH, OAuth or transport-selection authority.

Read-only Agent reference: `hermes-agent/gateway/platforms/api_server.py:2536` protects `_handle_capabilities` with `_require_auth` and returns `hermes.api_server.capabilities` / `hermes-agent`. Wing's existing `HermesApiClient.capabilities`, `HermesApiConfig.capabilitiesUri`, capability parser, HTTP timeout/response bounds and secure store remain the contract. No upstream modifications.

Reference revisions: Agent `158fd638da1629c8e62caf9ade1515d162def8ab`; Desktop `withdrawn reference revision`.

## Attribution and frozen inputs

HEAD at entry was `b9eb5b3d`; inherited dirty changes are other-owner prerequisites, not this card's implementation. The previous interrupted run left an immutable baseline under ignored `build/t_c7e40011/baseline/`. This retry recovered that baseline, reviewed only baseline-to-current changes, and ran fresh checks. The task-only patch applies cleanly to HEAD in a separate assembly; the authorized helper commits only that delta with a temporary index. Shared HEAD, real index and unrelated dirty files are not staged/reset/checked out.

Retained evidence is under ignored `build/t_c7e40011/evidence/`: baseline hashes, frozen source hashes, task-only patch, check history, final logs, browser receipts and renders. Frozen source manifest SHA-256: `28de67816d6c13367d04ebbbe5a519f7a622073e2dbecbefd2489d166c987038`. It includes actual check inputs and dependency lock identities. Build/test inputs were isolated in `build/t_c7e40011/source/`; large copies and compiled output are removed after evidence retention. The committed delta is not a claim that the currently delivered main includes inherited prerequisites.

Tool identities observed: Flutter 3.44.2 (framework `c9a6c48423`), Dart 3.12.2, Node 26.7.0 (differs from repository's Node 22 default), system Chromium 152.0.7977.75 on Linux. This is compiled Chromium fixture qualification, not native GTK or actual Agent authentication.

## Acceptance evidence

1. Public edit/save/cancel and exact ID preservation: `test/features/hermes_chat/screens/hermes_chat_saved_endpoint_edit_test.dart` covers wide/compact at actual 200% widget text scale, cancellation, obscured replacement, same-label peers, delayed storage failure/retry, stale owner away/back rejection and pending save disposal/owner settlement. `test/core/hermes/setup/saved_endpoint_edit_store_test.dart` executes secure-store fakes for exact-ID collision rejection and management trust preservation/invalidation. Real platform secure storage is NOT_CHECKED.
2. Read-only Test: widget regressions discriminate success, 401, 403, 500, timeout, incompatible document, draft edits, cancellation, owner change and disposal during a delayed read. Invalid secret-bearing/unsupported URL drafts cannot issue reads or saves. The injected client asserts the exact capabilities URI; mutation hooks fail. Chromium checks owner equality and store counters across denial/success/cancel/retry, empty credential upon reopen, zero non-GET Agent requests and zero management/run requests.
3. Compiled keyboard journeys: `playwright/tests/regression/saved-endpoint-edit.spec.mjs` passes four runs: 390/1280 logical pixels at 100/200% browser zoom with reduced motion. Saved-edit controls and text entry use keys only. Fixture hooks are limited to initial owner/bootstrap and failure setup; hash route changes prepare the public entry. Keyboard focus escape/return produces different rendered focus pixels. Widget tests separately exercise actual 200% text scaling; browser zoom is not a substitute for that test.

Actual rendered screenshots inspected: compact 390 at 100% saved reopen and 200% retry; wide 1280 at 100% saved reopen and 200% cancelled read. Copy, feedback, masked replacement and Cancel/Test/Save remain readable and within the dialog. Compact actions stack; wide actions remain inline. Reopened saved credential is blank. No clipped editor/action content observed on these named layouts. This is not a screen-reader or all-height accessibility qualification.

## Executed checks

Commands below ran in the isolated source snapshot unless marked shared-tree. Exact exits/durations and all retry attempts are retained in `evidence/checks.json`.

- Shared-tree `dart format --output=none --set-exit-if-changed` on the ten changed Dart files: exit 0, no changes.
- `timeout 2m flutter gen-l10n`: exit 0, 0.410 seconds; generated outputs match the task-owned shared files.
- `timeout 5m flutter analyze`: final exit 0, 2.982 seconds, no issues.
- `timeout 5m flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_saved_endpoint_edit_test.dart test/features/hermes_chat/screens/hermes_chat_saved_connection_workflows_test.dart test/features/hermes_chat/screens/hermes_chat_remote_connection_retry_test.dart test/features/hermes_chat/screens/hermes_chat_endpoint_load_intent_test.dart test/core/hermes/setup/hermes_endpoint_store_test.dart test/core/hermes/setup/secure_hermes_endpoint_store_test.dart test/core/hermes/setup/saved_endpoint_edit_store_test.dart`: exit 0, 25.710 seconds, 93 passing tests.
- `timeout 5m flutter test --no-pub --concurrency=1 test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart test/core/hermes/client`: exit 0, 12.724 seconds, 166 passing tests.
- `timeout 10m flutter build web --release -t lib/main_e2e.dart`: final exit 0, 50.227 seconds. Existing flutter_tts Wasm dry-run casts and Cupertino font warning remain; this is the JavaScript build, not Wasm qualification.
- `CHROME_EXECUTABLE=/usr/bin/chromium WING_APP_URL=http://127.0.0.1:18871/ timeout 10m npx playwright test --config=playwright.config.mjs playwright/tests/regression/saved-endpoint-edit.spec.mjs --workers=1 --retries=0`: final exit 0, 60.590 seconds, four passing journeys after fresh compilation. Owned fixture ports 18871/18872; isolated deterministic loopback backend and synthetic intercepted draft discovery only.
- Task patch/commit whitespace check is recorded with the local commit handoff.

Failures were not hidden: initial browser launch lacked Playwright's expected executable; used the installed system Chromium. Keyboard harness initially matched an exact editor label that Flutter changes when focused, bounded traversal too narrowly for inherited recents, and matched duplicate live-announcement text. Corrected task-local selectors/traversal and scoped visible spans; repeated fresh qualification passed. An additional nearest-test command accidentally included a nonexistent capability-test path; removed that guessed path and reran the discovered client/directory targets successfully. Prior-run analyze failures and regression-red output are retained separately from this retry's final qualification.

## Remaining milestone gaps

NOT_CHECKED: native Linux saved-edit/test, Android, physical secure storage/keychain, deployed/live Agent credentials, actual inference/approval/Stop/relaunch, the full connection/auth matrix, full repository gate, packaged release, protected PR and main delivery. The actual-Agent workflow and bounded provider-call budget remain M1 gaps. The next qualification seam is the same public saved-edit/test workflow against a disposable native Linux no-inference target and real platform secure storage. This card neither closes the parent matrix nor authorizes new SSH/OAuth/management trust.

Questions: none. Defaults applied: independent modal draft, exact-ID save, direct capabilities-only read, explicit retry and conservative management-association invalidation.
