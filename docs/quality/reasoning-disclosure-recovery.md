# Reasoning disclosure recovery qualification

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card `t_0b5660ab`; task `VERIFY-CHAT-DISCLOSURE-RECOVERY`; goal `CHAT-FIDELITY`.
This is deterministic Flutter widget and compiled Chromium evidence, not a live
Agent, native desktop, physical Android, screen-reader, speech or Wasm claim.

## Delivered behavior and policy

No production fix was required: the existing exact-owner viewport and disclosure
passed the discriminating recovery tests. No durable expansion state, API fields,
backend changes or new mutation paths were introduced.

- Same-owner, unique-ID mounted update: expanded state and the exact summary
  FocusNode are retained; canonical replacement text replaces the old body.
  The body remains selectable and host paths are redacted.
- Deliberate eviction: adding 100 later turns unmounts the reasoning tile and
  releases its old actionable focus. Reveal remounts it collapsed. Tab/Enter/Space
  reach and operate the returned readable Thought summary; old expansion is not
  persisted. Retained keys stay stable, evicted keys reset, canonical input remains
  intact and duplicate Agent IDs cannot gain unique-ID restoration authority.
- Owner replacement with a reused reasoning ID: the replacement starts collapsed,
  the old body and old FocusNode disappear, and keyboard reveal shows only the new
  owner's redacted body. A pending resume-refresh restoration settles after owner
  replacement without restoring the obsolete disclosure.
- Read-only resume refresh with a mounted reasoning row: exact focus and expansion
  remain. This widget test deliberately supplies a reasoning row through the
  existing fake channel; it does not claim HTTP history encodes reasoning.
- Actual HTTP reconnect after an interrupted synthetic run: canonical history wins.
  The existing HTTP history projection creates ordinary text turns and does not
  reconstruct the transient SSE reasoning row. Therefore the summary and old body
  disappear, rather than being promised reconnect persistence. The composer remains
  keyboard reachable; subsequent exact-session selection cannot reveal stale text.

The [widget tests](../../test/features/hermes_chat/screens/hermes_reasoning_disclosure_recovery_test.dart)
exercise actual Tab/Enter/Space and Flutter lifecycle notifications (inactive to
resumed). The [identity test](../../test/features/hermes_chat/presentation/hermes_disclosure_recovery_identity_test.dart)
qualifies key retention, bounds, duplicate identity and owner generation.
The [compiled browser tests](../../playwright/tests/regression/reasoning-disclosure-recovery.spec.mjs)
exercise actual controls via the existing keyboardActor. Only initial connect,
accessibility and reduced-motion hooks bootstrap the app; no hidden reconcile or
reveal callback stands in for user operation.

## Browser fixture and mutation evidence

`serve_web.mjs` adds one fixed recovery scenario, a bounded 100-call event burst,
and a fixed transport-interruption control. All use existing tool/run/reasoning
contracts. Tool call IDs are distinct; completed calls are coalesced into one
presentation group. The scenario flag resets between tests. No real provider/tool
is invoked. The burst exists only to evict an earlier reasoning disclosure without
creating 100 independent sends or changing the production protocol.

The eviction journey observes 104 canonical-loaded client turns, two projected
rendered rows (100 tool calls plus answer), and no Thought/body after eviction.
Explicit reveal includes the three preceding turns and returns five rendered
rows with the reasoning summary collapsed. It verifies visible rendered focus
by comparing focused/unfocused summary pixels and reopens/collapses with keys.
The canonical-history read that may follow completion is separate from window
projection; no claim is made that transient tool/reasoning rows survive it.

Both journeys assert exactly one intentional `POST /v1/runs` and zero other
Agent mutations: no sends from recovery, creates, model writes, approvals or
stops. Request traces record each method and exact path, including active-run
GET polling. Reconnect explicitly requires a canonical exact-session messages
GET and exclusively GET traffic after activation; subsequent owner selection
reads `/api/sessions/synthetic-reasoning-other/messages`. Widget channel counters
independently assert zero incidental mutations and exactly two resume reads in
the same-owner then pending-owner-switch case.

## Executed checks

All final commands below passed on Linux. Evidence is retained under ignored
`.dart_tool/reasoning-disclosure-recovery/` (source hashes, commands and logs).

1. `dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_reasoning_disclosure_recovery_test.dart test/features/hermes_chat/presentation/hermes_disclosure_recovery_identity_test.dart`
   — exit 0, no formatting changes.
2. `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart test/features/hermes_chat/presentation/hermes_transcript_viewport_test.dart test/features/hermes_chat/screens/hermes_reasoning_disclosure_recovery_test.dart test/features/hermes_chat/presentation/hermes_disclosure_recovery_identity_test.dart`
   — exit 0, 100 tests passed (`flutter-tests-pass.log`).
3. `flutter analyze` — exit 0, no issues (`analyze-final.log`).
4. `flutter build web --release -t lib/main_e2e.dart` — exit 0, fresh JavaScript
   compilation (`build.log`). Existing flutter_tts Wasm dry-run/font warnings do
   not establish Wasm support.
5. `WING_APP_URL=http://127.0.0.1:8987/ CHROME_EXECUTABLE=/usr/bin/chromium npx playwright test --config=playwright.config.mjs playwright/tests/regression/reasoning-disclosure-recovery.spec.mjs --workers=1`
   — exit 0, two tests passed (`browser-final.log`).
   `python .dart_tool/reasoning-disclosure-recovery/run_browser.py` executes this
   exact command with a child fixture server (`PORT=8987 HERMES_E2E_PORT=8988`),
   checks HTTP 200 readiness, and terminates/waits for the server in finally.
6. Scoped `git diff --check` and `goals.py validate` — recorded in card handoff.

Intermediate failures were harness defects, not production findings: semantics
handles initially disposed too late; lazy reveal needed scrolling to mount the
old row; lifecycle transitions needed inactive/resumed rather than paused/resumed;
the standalone viewport test needed an initialized binding. The first browser
attempt reused the fallback tool-name identity instead of distinct call IDs and
incorrectly expected empty-draft Send to be enabled after reconnect. Those were
fixed; final suites and both compiled journeys pass. No result was fabricated.

## Visual, source and parity boundaries

Focused Thought pixels were inspected locally: readable title and icon, grey
focus treatment, collapsed chevron, no clipping. Full reconnect/owner-replacement
render has the selected synthetic owner, an empty authoritative transcript and
usable composer, with no stale reasoning or overflow. Browser attachments include
focused/unfocused crops, canonical refresh and final render, semantics and JSON
request/focus/projection traces. Final copies are retained with the evidence.

The predecessor reference receipt pins Desktop at
`withdrawn reference revision` and documents mount-local `useState(false)`.
The accepted [implementation receipt](reasoning-disclosure-implementation.md)
is the basis for the existing label/focus fix. This card does not repeat a broad
upstream audit or claim Desktop execution. Wing source contracts inspected:
viewport `project`/`retainRows`/`setOwner`/`restore`, lifecycle resume owner fence,
and HTTP `_turnsFromHistory` authoritative text projection.

Only the two new Dart files, new browser spec, this receipt and the additive
fixture hunks belong to this card. Shared production/localization/shell files and
predecessor session-model fixture metadata are preserved. The local agent commit
is based on approved predecessor `33bc5502333b2570cf642b2780cc095288e6fcc3` and
isolates recovery fixture hunks, excluding the unrelated `sessionMetadata` edit.
The shared HEAD/index/working files remain untouched by commit construction.

Native window/live provider, physical Android, speech, screen reader, Wasm,
process relaunch and durable expansion persistence: NOT_CHECKED. Browser recovery
owner-switch-after-settlement and widget owner-switch-during-settlement are
separate evidence; no browser in-flight-owner race claim. Full CHAT-FIDELITY
remains partial. No new owner question; existing no-system/no-device/no-publication
defaults remain applied.
