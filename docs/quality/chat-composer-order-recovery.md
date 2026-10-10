# Composer adaptive-return and exact-owner recovery

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card: `t_9e45aaf2`. Task: `VERIFY-CHAT-COMPOSER-ORDER-RECOVERY`.
Goal: `CHAT-FIDELITY` remains partial. Native same-card review follows this
implementation handoff; approval is not implementation evidence.

## Delivered acceptance

1. Seven new widgets in
   `test/features/hermes_chat/screens/hermes_chat_composer_order_recovery_test.dart`
   qualify actual Tab/Shift+Tab traversal at 1440 → 600 → 1440 × 900.
   The supported wide group retains its named forward and inverse order and the
   current-owner draft. Compact composition deliberately remains editor →
   attachment → Send, with model in its separate strip and dictation in Chat menu.
   No production ordering or capability gate was changed.
2. Controlled pending model reads reject session, profile and channel replacement
   across adaptive return: one initiating read, no replacement read, no obsolete
   sheet or focus transfer, and the replacement draft retained. A pending capture
   rejects channel replacement and late text/focus. Capture cancellation via both
   Enter and Space records one capture and one cancel, zero Agent Stop calls.
   After active-run owner replacement and adaptive return, both keys activate only
   the replacement channel's Stop, once; the original records zero Stop calls.
   Disabled model is skipped between Stop and hands-free. Every case asserts zero
   sends, session creates, locks, assignments and approval responses.
3. `playwright/tests/regression/chat-composer-order-recovery.spec.mjs` exercises a
   fresh compiled Chromium application with actual keys, no focus injection or
   hidden action callbacks after the existing connection/accessibility bootstrap.
   It repeats wide traversal before and after compact return, checks compact
   attachment/Send access, and activates draft fallback with Enter and Space.
   A held real fixture catalog response settles after keyboard selection of
   `synthetic-composer-other` in compact Sessions and wide return. No old sheet
   appears or steals attachment focus. Keyboard return to the editor confirms its
   replacement draft; a fresh model intent can open/dismiss the real sheet.
   An explicit Enter Send creates `run_1` for that exact replacement session and
   message. After another compact/wide return, Space stops `run_1`, once.

No production correction was exposed. These narrowly named tests supplement,
not replace, the predecessor's static-wide qualification.

## Exact browser receipts

Ignored evidence: `.task-evidence/t_9e45aaf2/`; final attachments include
`composer-recovery-receipt.json`, `composer-semantics.txt`, `wide-return.png`,
`returned-composer.png` and paired focused/unfocused crops.
The fixture setup creates one synthetic session before browser request tracking;
it is not a user mutation and is explicitly excluded from application counts.
The held response is the existing fixture's catalog, not a fabricated API result.

Application request counts:

| Request | Count |
| --- | ---: |
| GET /v1/capabilities, /v1/models, /v1/skills, /v1/toolsets | 1 each |
| GET /api/jobs, /api/sessions | 1 each |
| GET /api/sessions/e2e-hermes-session/messages | 1 |
| GET /api/model/options | 1 |
| GET /api/sessions/synthetic-composer-other/messages | 2 |
| POST /v1/runs | 1 |
| GET /v1/runs/run_1/events | 1 |
| GET /v1/runs/run_1 | 2 |
| POST /v1/runs/run_1/stop | 1 |

Fixture readbacks: one run, one Stop, zero approval decisions, zero model locks;
canonical `run_1` is cancelled and belongs to `synthetic-composer-other`.
The sole run payload has `session_id: synthetic-composer-other` and both
`input`/`message: Replacement owner draft`. There are zero application creates,
model writes, approval writes, replay sends or audio requests. Browser errors and
RenderFlex/overflow reports are empty.

Inspected actual wide-return pixels and model/compact attachment focus crops:
readable, unclipped composer and visible focus fills. RGB decoded differences
are 1331 pixels for compact attachment, 3536 model, 1250 each draft activator,
1238 Send and 2181 Stop. Flutter ActionChip model/Stop retains checkbox semantics;
this does not claim screen-reader qualification.

## Executed checks

All commands ran in `<repo>`.

| Command | Result |
| --- | --- |
| `dart format test/features/hermes_chat/screens/hermes_chat_composer_order_recovery_test.dart` | PASS; formatted new test |
| `dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_composer_order_recovery_test.dart` | PASS; format.log |
| `flutter analyze` | PASS; no issues; analyze.log |
| `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_composer_order_recovery_test.dart` | First FAIL, then PASS; seven widgets; widgets-first.log / widgets-second.log |
| `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_composer_order_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_composer_order_test.dart test/features/hermes_chat/screens/hermes_chat_composer_focus_test.dart test/features/hermes_chat/screens/hermes_chat_direct_dictation_test.dart test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart test/features/hermes_chat/screens/hermes_chat_model_authority_test.dart` | PASS; 68 tests; widgets.log |
| `NODE_OPTIONS=--max-old-space-size=2048 flutter build web --release -t lib/main_e2e.dart` | PASS; build.log; existing flutter_tts Wasm dry-run/font warnings; JavaScript only |
| `CHROME_EXECUTABLE=/usr/bin/chromium WING_APP_URL=http://127.0.0.1:18991/ NODE_OPTIONS=--max-old-space-size=2048 npx playwright test --config=playwright.config.mjs playwright/tests/regression/chat-composer-order-recovery.spec.mjs --workers=1 --output=.task-evidence/t_9e45aaf2/browser` | PASS; one journey; browser-final.log |
| `git diff --check -- test/features/hermes_chat/screens/hermes_chat_composer_order_recovery_test.dart playwright/tests/regression/chat-composer-order-recovery.spec.mjs docs/quality/chat-composer-order-recovery.md` | PASS |
| `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo>` | PASS |

The first widget failure was a harness wait: compact run progress never settles;
bounded frame pumps fix that without weakening focus/counter assertions. Browser
iterations exposed asynchronous viewport rendering, a 32-key full-tree search
limit, the fixture's actual session accessible name, and Flutter's unfocused
native textarea proxy (blank despite a retained enabled draft). Tests now await
the actual adaptive surface, traverse through real nearby controls, use the full
observed row name and reacquire editor focus with keys before inspecting text.
First through sixth logs retain those failures; seventh and final logs pass.
No production behavior or authority was changed to obtain the passing checks.

## Source identity and delivery boundary

Wing HEAD: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784` plus shared approved
predecessors. Desktop HEAD: `withdrawn reference revision`.
The [predecessor receipt](chat-composer-order.md#source-backed-group) supplies
unchanged source-inspected Desktop comparison; no new upstream inspection or
Desktop execution is claimed. Existing approved dirty files were not edited.

| Tested file | SHA-256 |
| --- | --- |
| lib/features/hermes_chat/screens/state/hermes_chat_layout.dart | 2a4edc243fe86b94f037e2b18221d3e462210d0cba4ba281715c1883d591a660 |
| lib/features/hermes_chat/screens/hermes_chat_screen.dart | e7c22f33789f4eccfadefcdb2daded3215088d509485e5ed5ef96f94077acc1d |
| lib/features/hermes_chat/screens/state/hermes_chat_lifecycle.dart | 19976075f4b59b4fd642280fb8d232f52a5935187e11a9d8649565345144b553 |
| lib/features/hermes_chat/voice/hermes_voice_input_controller.dart | 76ebad78649590b127bd0db5ed0bd5f3a0ca462f5bca10c79f2b6c5f613b3a42 |
| serve_web.mjs | 5c66672ab8bdb683e7921fdd1398c5dbcddebbbbed5ebbce93cb909b302ec2da |
| test/features/hermes_chat/screens/hermes_chat_composer_order_recovery_test.dart | 07af3df1451e2df351def1b51c96db02779b41cfed92878f43aab9cfd781e0b8 |
| playwright/tests/regression/chat-composer-order-recovery.spec.mjs | ea633eb35d9e72dd9a96edea5e7fbef65cdde5b81b88a7dd3c2e844994e09abf |

The isolated local card commit contains only the two new test files and this
receipt. Shared goal changes are made by goals.py, not committed wholesale with
unrelated dirty ledger entries. Execution qualifies the combined shared checkout;
standalone card-branch build/dependency closure is NOT_CHECKED and requires the
approved predecessor slices. The fresh build/web output was absent initially and
is removed at finish. Retained evidence is ignored, not product source.

Native desktop, Android/iOS, live Agent/provider, physical capture/acoustics,
assistive technology, large-text qualification, full repository suite, Go,
npm audit and distribution/install/update are NOT_CHECKED. Stop and follow-up
placement retain the explicit Desktop differences in the predecessor receipt.
No backend contract, host service, device, credential or upstream was modified.

Questions (defaults applied): none.
