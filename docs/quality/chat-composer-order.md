# Wide composer control-order qualification

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card: `t_1aee2792`. Task: `PORT-CHAT-COMPOSER-ORDER`. Goal:
`CHAT-FIDELITY` remains partial. Executor qualification; native same-card review
follows the implementation handoff. No full composer parity is claimed.

## Source-backed group

Read-only Desktop HEAD: `withdrawn reference revision`.
Wing HEAD: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`, with approved and
pre-existing changes in the shared checkout.

Desktop `withdrawn source citation`,
lines 690–768, orders attachment, supported draft microphone, caller-provided
`toolbarExtras`, optional context gauge, then Stop or quick-ask/Send.
`withdrawn source citation`, lines 1075–1165,
places ModelPicker first in those extras, then reasoning/fast/folder/preview
controls. Attachment is disabled while loading. Draft microphone availability
and transcribing/recording states are independent. Stop replaces Send while
loading. This is source inspection, not an executed Desktop journey.

Wing's `_buildDesktopComposerCommandBar` already orders attachment → direct
**Dictate a draft** → model strip → hands-free switch/button → Send. The
`t_f2f5b956` dictation slice repaired the historical ordering; no layout,
localization or production change was necessary here. This card adds the missing
full-group keyboard, loading and active-run regression qualification.

Only the supported attachment/draft/model/Send subset is compared. Wing's separate
hands-free controls are an explicit addition. Active-run Stop appears before the
disabled model inside `_HermesComposerStrip`, not in Desktop's terminal Send slot.
Wing permits explicit local follow-up queuing during a run; a nonempty draft can
therefore retain an enabled Send. Empty Send is disabled. These retained behaviors
are not relabeled as complete Desktop loading-state parity. No folder, reasoning,
fast-mode, context gauge, quick-ask, preview or native IPC capability is added.
Flutter currently exposes ActionChip model/Stop as checkbox semantics in Chromium;
this receipt observes that role without claiming screen-reader qualification.

## Acceptance evidence

1. `test/features/hermes_chat/screens/hermes_chat_composer_order_test.dart`
   adds six tests. The supported wide row has increasing horizontal coordinates,
   nonempty accessible names, exact primary-focus ownership after each Tab and
   inverse Shift+Tab, and return to the unchanged editor draft. The Chromium
   journey repeats that full named sequence without focus injection or pointer
   activation after the existing connection/accessibility bootstrap.
2. Empty Send is disabled and skipped in widgets. Enter and Space activate the
   model control while its catalog read is held: one read despite repeat input,
   zero model locks, then a usable sheet that Escape dismisses without losing the
   draft. During an active run, the model is disabled and skipped between Stop
   and the hands-free switch. Both Enter and Space activate Stop exactly once in
   widgets while retaining draft text. The browser confirms empty Send/model
   disabled state during an approval-paused run and activates Stop with Space.
3. Named traversal has zero sends, session creates, model locks/assignments,
   approvals or Stop calls. Browser draft activation with Enter and Space reports
   unavailable capture, recovers through **Continue in text**, and preserves the
   draft with zero Agent mutations. Model open/cancel also has zero writes. Only
   the later explicit Send and Stop issue mutations: one `POST /v1/runs` and one
   `POST /v1/runs/run_1/stop`; fixture readbacks confirm one run, one Stop,
   no approvals and no model locks. No browser errors or RenderFlex overflow.
4. The current direct-dictation owner/gate and voice-lifecycle suites ran again,
   not merely inherited their old verdict. Session/profile/origin/channel changes,
   cancellation, unavailable capture and late draft rejection remain covered by
   the direct-dictation suite; compact and hands-free behavior by the lifecycle
   suite. This does not execute the queued adaptive-return successor.

The retained browser receipt includes actual named focus, viewport bounds, every
Agent request and exact counters. Focused/unfocused crops were decoded as RGB:
1250 changed pixels for each draft activation crop, 3536 for model, 1238 for Send,
and 2181 for Stop. Inspected the full wide screenshot and focused model/Stop crops:
readable, unclipped controls; visible focus fills. These are deterministic
Chromium 1440×900 renders, not a native desktop application or physical audio.

## Executed checks

Logs and browser attachments are retained under
`.task-evidence/t_1aee2792/` (ignored). The fresh JavaScript build was removed after
qualification; it was not present before this task. No pre-existing build is removed.

| Command | Result / receipt |
| --- | --- |
| `dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_composer_order_test.dart` | PASS; `format.log` |
| `flutter analyze` | PASS; no issues; `analyze.log` |
| `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_composer_order_test.dart test/features/hermes_chat/screens/hermes_chat_composer_focus_test.dart test/features/hermes_chat/screens/hermes_chat_direct_dictation_test.dart test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart` | PASS; 59 tests; `widgets.log` |
| `NODE_OPTIONS=--max-old-space-size=2048 flutter build web --release -t lib/main_e2e.dart` | PASS; `build.log`; existing flutter_tts Wasm dry-run and font warnings; no Wasm claim |
| `CHROME_EXECUTABLE=/usr/bin/chromium WING_APP_URL=http://127.0.0.1:18987/ NODE_OPTIONS=--max-old-space-size=2048 npx playwright test --config=playwright.config.mjs playwright/tests/regression/chat-composer-order.spec.mjs --workers=1 --output=.task-evidence/t_1aee2792/browser` | PASS; one journey; `browser-final.log` and `attachments/composer-receipt.json` |
| `git diff --check -- test/features/hermes_chat/screens/hermes_chat_composer_order_test.dart playwright/tests/regression/chat-composer-order.spec.mjs docs/quality/chat-composer-order.md` | PASS; owned files also checked in temporary-index commit diff |
| `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo>` | PASS; task done; goal remains partial |

The first widget run failed on harness assumptions: incorrect model-sheet title,
platform override restoration and expecting a nonempty queued draft's Send to be
disabled. The second exposed Android Tab insertion when the Linux override was
restored too early; the third passed. Browser iterations corrected ambiguous
textboxes, exact attachment/switch labels and ActionChip checkbox roles. No
production behavior or fake authority was weakened to obtain passing results.
Retained first/second/third logs distinguish these failures from production defects.

## Scoped source fingerprints

SHA-256 identifies the inspected/tested checkout, not an entire packaged closure.

| Path | SHA-256 |
| --- | --- |
| `withdrawn source citation` | `57b91c3e755ecd027c682568b455be15153bab1c2c1ad97edea593979a10b421` |
| `withdrawn source citation` | `f3c668c6f94bcf088117c5a8a5d9173c0db95c85771aeb7c8617e842739d01bc` |
| `lib/features/hermes_chat/screens/state/hermes_chat_layout.dart` | `2a4edc243fe86b94f037e2b18221d3e462210d0cba4ba281715c1883d591a660` |
| `lib/features/hermes_chat/screens/hermes_chat_screen.dart` | `e7c22f33789f4eccfadefcdb2daded3215088d509485e5ed5ef96f94077acc1d` |
| `lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart` | `b1c314cf972bea68743a8dae7edb382fc50ff59019693bb0639cc84f0bece390` |
| `lib/features/hermes_chat/voice/hermes_voice_input_controller.dart` | `76ebad78649590b127bd0db5ed0bd5f3a0ca462f5bca10c79f2b6c5f613b3a42` |
| `test/features/hermes_chat/screens/hermes_chat_composer_order_test.dart` | `1e6918ba78ac759bd234032ee846454632163956013641298467ec40d3797280` |
| `test/features/hermes_chat/screens/hermes_chat_composer_focus_test.dart` | `e45c66d1f71bddfc15f53c20f750422f4b286460367b126475907f76cfb2dffe` |
| `test/features/hermes_chat/screens/hermes_chat_direct_dictation_test.dart` | `207952b2a614290c9f4e54667e3a2ab9e8b7c587da1e1031f11c8d442ad528fe` |
| `test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart` | `6ccda5b47bd1ac6d19f3c72eb94e3d52c7bfd1e86560a617fdc1c4d2c045dbcb` |
| `playwright/tests/regression/chat-composer-order.spec.mjs` | `feca0d8d34c40acb41c173d4a0498028c0365ac0281b8cdb406da06cbe063147` |
| `playwright/support/inventory_keyboard.mjs` | `850370b758d2e78984d2cf7a7b0900c530b016ddaa6524758083b19b5f2f1645` |
| `serve_web.mjs` | `5c66672ab8bdb683e7921fdd1398c5dbcddebbbbed5ebbce93cb909b302ec2da` |

## Current-source Stop traversal repair

A later shared-worktree `npm run test` reproduced two keyboard failures:
Tab skipped the newly inserted Stop chip and reached the hands-free switch.
A focused rerun reproduced both failures with Enter and Space cases.

`_HermesComposerStrip` now has its own `FocusTraversalGroup`. This keeps
new Stop/Retry controls in the strip's existing toolbar position.
The original focus, draft and mutation assertions remain unchanged.

Executed after the repair:

- `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_composer_order_test.dart test/tooling/readme_assets_contract_test.dart` passed all seven tests.
- `flutter analyze` passed with no issues.
- `dart format --output=none --set-exit-if-changed lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart test/tooling/readme_assets_contract_test.dart` passed.

The source-contract test now requires both explicit and platform reduced motion.
It no longer depends on a formatter-sensitive substring.
These results are widget/source-contract evidence, not a fresh browser render.
The earlier Chromium screenshots and source fingerprints above remain historical.
The full `npm run test` rerun passed: 3,598 tests, zero failures, exit 0.
Dart/ARB and package-input fingerprints were unchanged during that run.
The [receipt](../../.task-evidence/connection-entry-labels/verification-npm-test-result.json)
and [log](../../.task-evidence/connection-entry-labels/verification-npm-test.log)
retain the result and source boundary. This does not qualify native devices or live providers.

## Delivery boundaries

Production layout and draft-controller fingerprints match the prior dictation
receipt; none of those dirty paths is staged by this card. The commit contains
only the new widget/browser qualification, this receipt and a bounded ledger
projection created through goals.py from HEAD. Shared ledger updates retain other
cards' uncommitted entries; their unrelated deltas are excluded from the commit.
The isolated projection is not another product worktree or a validated app build.

Execution qualifies the combined shared checkout with its approved predecessors.
The card's standalone branch requires the dictation and model-selection slices;
standalone build/package execution is NOT_CHECKED. No production dependency is
copied or expanded to conceal that gap. No upstream checkout, backend, protocol,
credential, audio engine, service, device or host management mutation was changed.
Native Linux, mobile devices, live Agent/provider, physical speech and assistive
technology are NOT_CHECKED. Full suite, README regeneration and npm audit were
not rerun for this test-only slice. No owner question remains.
