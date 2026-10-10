# Adaptive reasoning disclosure qualification

Card `t_e3589e12`; task `VERIFY-CHAT-DISCLOSURE-ADAPTIVE`; goal `CHAT-FIDELITY`.

## Delivered fix and focus policy

The adaptive avatar wrapper remounts `ExpansionTile` while retaining its exact-owner
reasoning row. Before this fix, the row's expanded semantics survived but its body
was hidden by a newly collapsed tile. The discriminating widget regression failed
on missing body after resize (`.dart_tool/reasoning-disclosure-adaptive/widget-red-body.log`).
The minimal production change seeds `initiallyExpanded` from the retained row's
existing `_expanded`. No durable state, protocol, Agent API or Wing Link change.

- Same layout resize: expansion and exact summary FocusNode survive.
- Compact/wide boundary: the inner tile remounts, preserving expansion; old
  actionable focus is released. Tab/Shift+Tab reaches the replacement summary;
  Enter/Space opens/collapses without changing the run.
- Completion under reduced motion: Thinking… becomes Thought with expansion and
  current focus retained. A static hourglass is used for active reasoning.
- Owner replacement reusing an ID: old body/focus disappear; the new owner starts
  collapsed. Existing eviction/reconnect policy remains unchanged.
- Body stays selectable and path-redacted; summaries expose expanded/live-region
  semantics. This does not establish screen-reader usability.

## Acceptance evidence

1. [Adaptive widget target](../../test/features/hermes_chat/screens/hermes_reasoning_disclosure_adaptive_test.dart)
   passes compact-first and wide-first roundtrips at 390/1280px, same-layout
   resize at 430/1320px, active reasoning, completion and reused-ID owner change.
   Actual Tab, Shift+Tab, Enter and Space are used. Summary bounds and framework
   exceptions are checked; channel counters show zero sends, creates, selects,
   model locks/assignments, approval replies, Stop or connect calls.
2. [Compiled browser journey](../../playwright/tests/regression/reasoning-disclosure-adaptive.spec.mjs)
   passes 390 → 1280 → 390, height 900, reduced-motion media plus existing Flutter
   reduced-motion bootstrap. All composer/send/disclosure operations use keys;
   only connect/accessibility/reduced-motion and deterministic fixture controls
   use bootstrap hooks. It waits for the actual Flutter width rebuild before
   checking the returned disclosure. Nine render receipts show Thinking/Thought,
   expansion/body agreement, viewport-contained summary/body and no document
   overflow. Focused/unfocused summary pixels differ and keyboard escape/return
   passes. The focused compact summary, wide open reasoning and completed compact
   render were visually inspected: readable status/body, static icon, grey focus
   fill and chevron, no clipping in the inspected disclosure.
3. Exact browser request counts (final `attachments/adaptive-receipt.json`):
   `GET /v1/capabilities`, `/v1/models`, `/v1/skills`, `/v1/toolsets`,
   `/api/jobs`, `/api/sessions`, `/v1/runs/run_1/events`: one each;
   `GET /api/sessions/e2e-hermes-session/messages`: two;
   `GET /v1/runs/run_1`: three; `POST /v1/runs`: one explicit generation.
   Zero incidental non-GET traffic after adaptive resizing, zero creates,
   model writes, approvals or Stop. Browser page/overflow errors: zero.

## Executed commands

Final logs and screenshots are retained in ignored
`.dart_tool/reasoning-disclosure-adaptive/`.

- `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_reasoning_disclosure_adaptive_test.dart`
  — exit 0, two tests.
- `dart format --output=none --set-exit-if-changed lib/features/hermes_chat/presentation/hermes_chat_timeline.dart test/features/hermes_chat/screens/hermes_reasoning_disclosure_adaptive_test.dart`
  — exit 0, no changes.
- `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart test/features/hermes_chat/presentation/hermes_transcript_viewport_test.dart test/features/hermes_chat/screens/hermes_reasoning_disclosure_recovery_test.dart test/features/hermes_chat/screens/hermes_reasoning_disclosure_adaptive_test.dart`
  — exit 0, 101 tests (`flutter-tests-final.log`).
- `flutter analyze` — exit 0, no issues (`analyze-final.log`).
- `flutter build web --release -t lib/main_e2e.dart` — exit 0, fresh JS build
  (`build-final.log`); existing TTS Wasm/font warnings are not Wasm qualification.
- `WING_APP_URL=http://127.0.0.1:8987/ CHROME_EXECUTABLE=/usr/bin/chromium npx playwright test --config=playwright.config.mjs playwright/tests/regression/reasoning-disclosure-adaptive.spec.mjs playwright/tests/regression/reasoning-disclosure-recovery.spec.mjs --workers=1 --output=.dart_tool/reasoning-disclosure-adaptive/browser-results`
  — exit 0, three tests (`browser-final.log`).
  `python .dart_tool/reasoning-disclosure-adaptive/run_browser.py` executes this
  with `PORT=8987 HERMES_E2E_PORT=8988`, verifies HTTP readiness, and terminates
  its child fixture in finally. Both predecessor recovery journeys pass.
- Scoped `git diff --check` and `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo>`
  are required at handoff, with exact results in the source/commit receipt.

The initial browser failure was a harness locator: compact Flutter's focused
native editor drops its hint accessible name. The test now reaches the unique
editor with Tab and verifies native focus/value; no production composer change.
Widget development failures from the interrupted predecessor run remain retained;
only the adaptive body/semantics disagreement warranted a production fix.

## Source, scope and limits

The accepted source reference and [recovery receipt](reasoning-disclosure-recovery.md)
remain the parity baseline; no broad upstream audit or Desktop execution here.
Local agent commit is parented on approved recovery commit
`8963edcba055db55f097f326e3af21b9c46b0029`. Only three production lines, the
new widget/browser tests and this receipt belong to this card. The deterministic
fixture needed no changes; unrelated `sessionMetadata` working-tree hunks are
excluded. Source hashes and branch/SHA are in `source-and-commit.json` alongside
logs. Shared HEAD/index are preserved; no push or merge.

Hermes Agent remains authoritative; this is volatile exact-owner presentation,
not cached Agent state or mutation/replay support. Full CHAT-FIDELITY is partial.
Native desktop window, live provider, physical Android, screen reader, audio,
Wasm, relaunch and durable expansion persistence: NOT_CHECKED.
No new questions; no-system/no-device/no-publication defaults remain applied.
