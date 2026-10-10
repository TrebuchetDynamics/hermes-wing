# Canonical transcript reconnect and viewport remount

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card: `t_2fe70cc9`. Task: `VERIFY-CHAT-TRANSCRIPT-RECONNECT`.
Goal: `CHAT-FIDELITY`, still partial. This receipt covers deterministic Flutter
widgets, the real API channel over injected transport, and freshly compiled
Chromium. It is not native desktop or live Agent qualification.

## Repair and authority

The retained `widget-red.log` reproduces a Wing defect: reconnect to authoritative
history removed `canonical-read` and `canonical-web`, leaving only user,
commentary and answer. `_turnsFromHistory` excluded every `role: tool` row.

The minimal repair in
`lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart` retains
one category-only activity turn per persisted tool-result row in server order.
Canonical message IDs replace transient event IDs; the projection does not merge
or append cached activity. Tool content never becomes transcript prose, preview
or result. Missing tool names use the existing generic host category. The nearest
channel test now checks empty tool text and null preview/result, including this
unnamed-row fallback. No UI, approval queue, capability, wire schema, dependency,
Wing Link or upstream file changed.

A persisted result establishes finished activity, not successful execution.
Recovered rows use the existing completed-host-activity presentation. The history
shape has no authoritative per-tool success/failure field; historical outcome
classification and recovery of unfinished invocations are not qualified here.
Reasoning history recovery and tool-call-only assistant rows without result rows
are also outside this repair. The run-history snapshot still retains its original
model-context safety classification; category projection does not authorize
unsafe continuation through the plain-history run transport.

Read-only contract trace:

- Agent `gateway/platforms/api_server.py:3046-3052` projects existing message
  `id`, `session_id`, `role`, `content`, `tool_name` and related metadata.
- Agent `gateway/platforms/api_server.py:3295-3328` returns bounded canonical
  message pages in chronological order within the latest page.
- Agent `tests/gateway/test_session_api.py:116-146` checks latest bounded history;
  `:498-562` supplies interleaved assistant/tool/answer history with `tool_name`.
  These were inspected, not executed or modified.
- Wing `HermesMessage.fromJson` already admits `tool_name`, while
  `_fetchTurns` checks current connection, profile and caller ownership before
  accepting history. `_turnsFromHistory` is shared by refresh and earlier-page
  loading; no duplicate conversion path was introduced.
- Desktop `src/renderer/src/screens/Chat/MessageList.tsx:212-253` preserves history
  rows and transcript-window ordering. This is reference source, not runtime proof.

## Executed journeys and exact receipts

The new focused widget uses `HermesApiChannel`, not replacement turns supplied by
`FakeHermesChannel`. It streams commentary, two adjacent completed tools and a
pending approval; reconnects the same channel to canonical history with different
message IDs; checks retired approval focus; unmounts/remounts the Chat screen;
returns through 390px and 1280px viewports; refreshes canonical history; and opens
the recovered tool disclosure using Tab/Enter/Space. It asserts exactly two tool
rows, File before Web, request/commentary/activity/answer vertical order, no tool
result text, and no obsolete actionable approval.

A separate explicit new-connection setup proves the current approval stays
keyboard reachable through compact/wide layout replacement and accepts exactly
one deliberate Enter decision. The log's computed receipt is:

- reconnect/remount mutation delta: 0;
- explicit setup prompts: 2;
- explicit current-owner decisions: 1, only `/v1/runs/run_2/approval`;
- Stop: 0.

Two independent Chromium journeys exercise connection replacement and page
reload while the old approval has keyboard focus. They recover canonical history,
leave Chat for Settings and return, change viewport to 390px then 1280px, assert
unique vertically ordered rows and absence of stale approval/Stop controls,
verify rendered tool-disclosure focus pixels, and use Enter/Space to open/close
File/Web activity. Activating the recovered empty composer does not replay a send.
The final screenshot was visually inspected: ordered request, commentary, one
2-step activity group and answer; no stale approval or exposed synthetic context.

Each browser journey's server receipt and independent client request capture
agree on exactly one deliberate `POST /v1/runs`, for `synthetic-reconnect` with
`Synthetic reconnect request`; decisions 0; Stop 0. Recovery, route remount and
viewport changes add zero mutations. Each journey retains three rendered-order
observations and no page/overflow errors. Fixture-control POSTs are separate from
Agent requests and are never counted as product mutation behavior.

`playwright/support/hermes_transcript_reconnect_fixture.mjs` owns the fixed
scenario. Its wrapper generates an ignored server composition without changing
co-owned `serve_web.mjs`; it reuses the current base server only for unchanged
capabilities, inventory and static-file behavior. No provider, host tool or real
approval executes.

## Exact final checks

The shared Flutter suite was still active at validation discovery (PIDs 649157
and 648884). All Flutter validation ran in the ignored Wing-only copy
`.dart_tool/transcript-reconnect/wing`, with no reference repositories or private
runtime state copied. Other processes and shared build outputs were untouched.
Final commands returned exit 0:

From the repository root:

```sh
dart format --output=none --set-exit-if-changed lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart test/core/hermes/channel/hermes_api_channel_tests/direct_chat_tests.dart test/features/hermes_chat/screens/hermes_chat_transcript_reconnect_test.dart
node --check playwright/support/hermes_transcript_reconnect_fixture.mjs
node --check playwright/support/hermes_transcript_reconnect_server.mjs
node --check playwright/tests/regression/chat-transcript-reconnect.spec.mjs
CHROME_EXECUTABLE=/usr/bin/chromium WING_APP_URL=http://127.0.0.1:8899/ NODE_OPTIONS=--max-old-space-size=2048 timeout 6m npx playwright test -c .dart_tool/transcript-reconnect/playwright.config.mjs playwright/tests/regression/chat-transcript-reconnect.spec.mjs --workers=1
```

From `.dart_tool/transcript-reconnect/wing`:

```sh
timeout 3m flutter analyze
timeout 5m flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_transcript_reconnect_test.dart test/features/hermes_chat/screens/hermes_chat_transcript_order_test.dart test/core/hermes/channel/hermes_api_channel_test.dart test/core/hermes/channel/hermes_session_caller_admission_test.dart test/core/hermes/channel/hermes_approval_settlement_owner_test.dart test/core/hermes/channel/hermes_recovery_read_admission_test.dart --reporter expanded
timeout 9m flutter build web --release -t lib/main_e2e.dart
```

Formatter: 3 files, no changes. Analyzer: no issues. Focused tests: 391 passed.
Fresh release web build passed. Chromium 152.0.7977.75: 2 passed, workers=1,
retries=0, skipped=0, flaky=0. Ports 8899/8900 were checked free and the owned
fixture was health-checked before testing. Existing flutter_tts Wasm dry-run and
Cupertino font warnings remain; no Wasm claim is made.

Retained failures are explicit, not waived: an initial widget fake-async harness
wait timed out; a subsequent RED failed on missing canonical tool IDs; current-run
terminal waiting needed a widget pump before awaiting the send future. Initial
analyzer findings were two test-style infos, corrected. The nearest historical
channel assertion initially expected tool rows to be absent; it now checks the
stronger content-redaction invariant. Browser harness corrections used inverse
Tab traversal and the observed avatar-prefixed commentary semantic name; order,
uniqueness, focus and exact-mutation assertions were not removed.

## Tested source identities and retained evidence

Wing HEAD: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`.
Agent reference HEAD: `158fd638da1629c8e62caf9ade1515d162def8ab`.
Desktop reference HEAD: `withdrawn reference revision`.
These identify local checkouts only.

Selected SHA-256 identities:

| Source | SHA-256 |
| --- | --- |
| history projection repair | `95d53e5335af3145f0856a683ff0b3f75bbdca14c77df749e0cfa0caccffff44` |
| focused reconnect widget | `7d918db55d9a5a2e8390aa44b7f835d7f2676da368a3a841128e1951f51db9d0` |
| existing timeline | `13f53c8a9833dfefe611b03e51d8dfcac3eb63f37665b72be7fe6071af04b4ee` |
| Chromium journey | `1e0f852ce8ef97d97f76545fb8342dce04a7e22ce1d29440aa69fcd2f7c5412c` |
| compiled main.dart.js | `116dafaa14d74f2bebf66a85f4dd19c2daf0e7e16bdb217589920193a3ed2e2b` |

This is composed dirty-tree qualification, not clean-HEAD or packaged proof.
`composition.json` captures the initial copied lib fingerprints; comparison
against the root found only this card's intended history-projection change.
`tested-source.json` records the final isolated lib/test identities.
`evidence.json` retains selected inputs, generated-server/build hashes, browser
stats and computed request counts.

Ignored evidence under `.dart_tool/transcript-reconnect/`: `widget-red.log`,
`widget-green.log`, `widget-debug.log`, `format.log`, `analyze.log`, `focused.log`,
`build.log`, `browser-harness-1.log`, `browser-harness-2.log`, `browser.log`,
`browser.json`, source manifests and decoded `observations/` screenshots,
semantics and exact receipts. Large owned copied source/build outputs are removed
after retaining these identities. Nothing was committed or pushed.

## Post-handoff workspace verification

After the competing suite exited, the npm test entry point was also exercised
in the actual repository workspace, not the isolated copy:

```sh
npm run test -- test/features/hermes_chat/screens/hermes_chat_transcript_reconnect_test.dart test/features/hermes_chat/screens/hermes_chat_transcript_order_test.dart test/core/hermes/channel/hermes_api_channel_test.dart test/core/hermes/channel/hermes_session_caller_admission_test.dart test/core/hermes/channel/hermes_approval_settlement_owner_test.dart test/core/hermes/channel/hermes_recovery_read_admission_test.dart --reporter expanded
```

Exit 0; 391 tests passed. Raw output: `.dart_tool/transcript-reconnect/npm-focused.log`.
All selected source hashes still matched the retained inputs before this run.
This is fresh workspace-level focused evidence, not an unrestricted full-suite
pass. No additional code repair was needed.

## Limits and handoff

Not checked: native Linux/macOS/Windows interaction, live Agent/provider/tools,
Android, screen reader, enlarged text/whole-render zoom, full-suite integration,
packaging, distribution or deployment. Browser approval/profile/channel matrices
beyond the named journeys are not newly qualified. The existing successor
`VERIFY-CHAT-TRANSCRIPT-ACCESSIBILITY` owns enlarged-text verification; this card
does not start it. `CHAT-FIDELITY` remains partial.

The scoped ledger task/evidence/render updates and native same-card review handoff
finish this worker's goal. Review approval is a later step. No owner questions or
new defaults were needed.
