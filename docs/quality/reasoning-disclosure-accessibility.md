# Enlarged-text reasoning disclosure qualification

Card `t_5a14d085`; task `VERIFY-CHAT-DISCLOSURE-ACCESSIBILITY`; goal `CHAT-FIDELITY`.

## Delivered and acceptance mapping

No production defect was exposed, so no production code changed. The approved
adaptive `initiallyExpanded` behavior and exact-owner row identity remain intact.
This card adds two focused regression targets and this source-bound receipt.

1. [Widget target](../../test/features/hermes_chat/screens/hermes_reasoning_disclosure_accessibility_test.dart):
   compact-first and wide-first 390/1280px journeys explicitly set
   `TextScaler.linear(2)` and `disableAnimations: true`. They assert summary
   expanded/live-region semantics, actual inherited text scale, visible body
   bounds, selectability, path redaction and absence of framework exceptions.
   Actual Tab/Shift+Tab, Enter/Space reach, expand and collapse the summary.
2. Same-layout resize retains exact focus; crossing the adaptive boundary releases
   the remounted tile's old focus, while current-owner expansion/body survive.
   Completion retains focus. A replacement session reusing the reasoning ID
   removes old focus/body and starts collapsed; keyboard can open only its new
   body. Fake-channel counters assert zero sends, creates, selections, model
   locks/assignments, approvals, Stop or connect calls throughout.
3. [Compiled Chromium journey](../../playwright/tests/regression/reasoning-disclosure-accessibility.spec.mjs):
   native browser zoom is 200%, independently asserted through DPR=2 and CSS
   viewport metrics. This is browser zoom, not Flutter text-only scaling; the
   widget tests separately cover text-only scaling. Browser windows of
   780/2560px yield 390/1280px logical viewports, height 900px. Reduced-motion
   media and the existing Flutter reduced-motion bootstrap are both applied.
   Keyboard-only composer/send/disclosure/session actions cover compact → wide
   → compact, completion and explicit replacement-owner selection. Summary/body
   bounds, expansion agreement, absence of old-owner summary/body, no document
   overflow and no browser/Flutter overflow errors pass.

Ten render receipts and thirteen attachments are retained under ignored
`.dart_tool/reasoning-disclosure-accessibility/attachments/`. Visually inspected
`compact-open.png`, `wide-return-open.png` and `compact-completed-open.png`:
Thinking/Thought and the redacted body are readable and unclipped, static
hourglass/psychology icon and expansion chevron are visible. Compact focused
summaries show grey focus fill; the wide return screenshot precedes reacquiring
focus. Screenshot inspection does not establish screen-reader usability.

Browser traffic counts (`accessibility-receipt.json`): one each of
`GET /v1/capabilities`, `/v1/models`, `/v1/skills`, `/v1/toolsets`, `/api/jobs`,
`/api/sessions`, `/v1/runs/run_1/events` and
`/api/sessions/synthetic-reasoning-other/messages`; two
`GET /api/sessions/e2e-hermes-session/messages`; four `GET /v1/runs/run_1`;
one explicit `POST /v1/runs`. Zero incidental non-GET requests during disclosure,
resize, completion or deliberate local session selection. No creation, model
writes, approval or Stop requests. Session selection's explicit history read is
not an incidental selection. Browser/framework error list is empty.

## Executed commands

Logs are retained in `.dart_tool/reasoning-disclosure-accessibility/`.

- `dart format test/features/hermes_chat/screens/hermes_reasoning_disclosure_accessibility_test.dart`
  — exit 0, new file formatted.
- `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_reasoning_disclosure_accessibility_test.dart`
  — exit 0, two tests (`widgets.log`).
- `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_reasoning_disclosure_accessibility_test.dart test/features/hermes_chat/screens/hermes_reasoning_disclosure_adaptive_test.dart test/features/hermes_chat/screens/hermes_reasoning_disclosure_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart`
  — exit 0, 98 tests (`nearest-tests.log`).
- `flutter analyze` — exit 0, no issues (`analyze.log`).
- `flutter build web --release -t lib/main_e2e.dart` — exit 0 (`build.log`).
  Existing flutter_tts Wasm dry-run and icon-font warnings remain; JS build only.
- `WING_APP_URL=http://127.0.0.1:8997/ CHROME_EXECUTABLE=/usr/bin/chromium npx playwright test --config=playwright.config.mjs playwright/tests/regression/reasoning-disclosure-accessibility.spec.mjs --workers=1 --output=.dart_tool/reasoning-disclosure-accessibility/browser-results`
  — exit 0, one journey (`browser.log`).
  `python .dart_tool/reasoning-disclosure-accessibility/run_browser.py` runs this
  command with owned fixture ports 8997/8998, verifies HTTP readiness, and
  terminates its child fixture in `finally`.
- Final format, scoped diff and goal-ledger validation results, source hashes,
  exact commands and local commit identity are in `source-and-commit.json`.

## Source and scope

Sources: [client decision](../adr/client.md#decision),
[approved adaptive receipt](reasoning-disclosure-adaptive.md),
[test plan](../test-plan.md), and TODO's task scope. Existing predecessor tests
were inspected and rerun, not upgraded from historical receipts. No upstream
inspection/change was needed for this qualification-only slice.

The task-only local agent branch contains only the two new tests and this receipt.
It does not contain the shared checkout's dirty predecessor implementation or
fixture changes. Passing execution applies to the fingerprinted shared checkout,
not to a standalone build of that agent branch. HEAD and shared index are
preserved; no push, merge, publication, service or device changes.

Hermes Agent remains authoritative; no shadow domain state, backend contract,
new transcript capability or mutation replay was introduced. Full CHAT-FIDELITY
remains partial. Native desktop, live Agent/provider, screen reader, Android,
physical input/audio, Wasm and packaged distribution: NOT_CHECKED.
No owner questions; no-system/no-device/no-publication defaults remain applied.
