# Reasoning disclosure implementation

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card `t_8c01bd65`, task `PORT-CHAT-TRANSCRIPT-DISCLOSURE`, goal `CHAT-FIDELITY`.
Implementation and executed deterministic qualification; native review approval is separate.

## Source and delivered behavior

The bounded reference is [the comparison receipt](chat-transcript-disclosure.md),
Desktop revision `withdrawn reference revision`,
`HistoryRow.tsx:18–90` and `MessageList.tsx:375–387`. Those read-only sources were
re-inspected; the Desktop checkout still reports that revision. No latest-upstream
or executed Desktop claim is made.

[The timeline](../../lib/features/hermes_chat/presentation/hermes_chat_timeline.dart)
now reports localized “Thinking…” only for trailing reasoning content while the
last authoritative turn is streaming. Empty assistant placeholders do not count
as visible content. An answer/tool arriving or completion changes the summary to
“Thought”. Existing `HermesApiChannel._applyReasoningEvent` inserts bounded,
completed reasoning before the streaming assistant placeholder, so testing the
reasoning row's own status would incorrectly show Thought throughout. No channel,
Agent event, protocol, capability or API was added. The inspected Agent
`gateway/platforms/api_server_runs.py` includes the existing reasoning payload
contract; the current checkout also has distinct native-session event projection.
This fixture qualifies Wing's existing run-event consumer, not every Agent route.

Expansion remains process-local Flutter `ExpansionTile` state under the existing
viewport's exact-owner row identity. The title exposes live status and expanded
semantics. Active chrome has a spinner, or static hourglass under reduced motion.
Existing bounded selectable Markdown and sensitive-text redaction remain intact.
A minimal [lifecycle guard](../../lib/features/hermes_chat/screens/state/hermes_chat_lifecycle.dart)
prevents completion's scheduled composer-focus request from stealing focus from
a mounted reasoning disclosure. Other completion and owner-generation behavior
is unchanged. No second Chat, persisted expansion or shadow domain state exists.

## Acceptance evidence

1. The [widget regression](../../test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart)
   traverses with Tab, opens with Enter, completes the same reasoning identity,
   retains the exact FocusNode, collapses with Space, checks status/expansion
   semantics, redaction/selectability, static reduced-motion chrome, and zero
   incidental send/create/select/model/approval/connect calls. Restoring only the
   pre-fix fixed `reasoningTitle` reproduced its failure: Thinking… was absent.
   The status implementation was restored and the entire nearest suite passes.
2. A reused reasoning ID under a replaced session disposes the old tile, hides old
   content, starts the fresh tile collapsed and reveals only fresh content. The
   answer-starts-before-completion case independently verifies trailing-content
   status. Existing bounded viewport/identity and tool tests remain green.
3. [The fresh compiled Chromium journey](../../playwright/tests/regression/reasoning-disclosure.spec.mjs)
   uses the project keyboardActor and actual Tab/Shift+Tab/Enter/Space/Escape.
   It observes named focus in viewport and compares focused/unfocused rendered
   pixels. Completion preserves summary focus; owner selection removes stale
   text/action and fresh reasoning starts collapsed. It asserts exactly two
   intentional `POST /v1/runs`, one exact session-messages read on selection,
   and no other mutations. Existing periodic active-run GET polling is allowed
   only for the exact run identity during disclosure, not counted as a new
   disclosure request. Raw request/focus traces are attached to Playwright results.

## Executed checks

All commands ran from the Wing root on Linux; all final checks below exit 0.

- `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart --plain-name 'reasoning keyboard disclosure retains focus through completion'`
  with just the old fixed label restored: expected exit 1, missing Thinking….
- `flutter gen-l10n`: exit 0; additive reasoning keys only, prior localization
  work preserved.
- `dart format test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart`:
  exit 0. Final scoped format check recorded in card handoff.
- `flutter analyze`: exit 0, no issues.
- `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart`:
  exit 0, 91 tests pass, including all three new journeys.
- `flutter build web --release -t lib/main_e2e.dart`: exit 0, fresh JavaScript web
  build. Existing flutter_tts Wasm dry-run and Cupertino font warnings remain;
  this is not a Wasm qualification.
- `WING_APP_URL=http://127.0.0.1:8987/ CHROME_EXECUTABLE=/usr/bin/chromium npx playwright test --config=playwright.config.mjs playwright/tests/regression/reasoning-disclosure.spec.mjs --workers=1`:
  exit 0, one test passes. A Python subprocess wrapper started
  `PORT=8987 HERMES_E2E_PORT=8988 node serve_web.mjs`, observed HTTP 200, ran that
  exact test command, and terminated/waited for the server in finally.
- Scoped `git diff --check` and `goals.py validate` recorded in final handoff.

Intermediate harness failures were real and repaired: standalone background
server did not survive this runner; composer name includes an ellipsis; selectable
reasoning is a semantic group rather than a text locator; run traffic uses `/v1/`
not `/api/`; reconciliation polling continues independently of UI toggling.
No failure was substituted with fabricated result output.

## Visual evidence and limits

Playwright results include `reasoning-summary-focused.png`,
`reasoning-summary-unfocused.png`, `reasoning-completed.png`,
`reasoning-receipt.json` and `reasoning-semantics.txt`. Extracted pixels were
inspected locally: completed Thought is readable, collapsed, within the 1280×900
viewport, with the tile's focus treatment and no disclosure overflow. The fixture
uses synthetic content only. The body remains Wing's redacted Markdown, not
Desktop's plain pre; Flutter's activity indicator and focus treatment are native
presentation equivalents, not identical Desktop chrome.

Native desktop window, physical Android, live provider, speech, screen-reader,
reconnect/window-eviction/relaunch persistence: NOT_CHECKED. No persistence promise.
Full transcript/CHAT-FIDELITY parity remains partial. No new owner question; existing
no-system-install/no-device/no-publication defaults remain applied.

## Dirty-work isolation

Timeline, transcript tests and the small lifecycle guard belong to this card.
The fixture has predecessor session-model metadata edits, and all three
localization files have predecessor dictation/model/shell edits. The local agent
commit uses a separate staging work directory with only this card's fixture and
reasoning localization hunks over HEAD; shared HEAD/index/worktree and predecessor
edits are preserved. Ledger changes are maintained through goals.py, not blindly
committed with unrelated shared documentation. No build output is committed.
