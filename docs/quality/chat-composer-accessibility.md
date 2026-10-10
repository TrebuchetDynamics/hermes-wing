# Composer enlarged-text and reduced-motion qualification

Card: `t_70b3c065`. Task: `VERIFY-CHAT-COMPOSER-ACCESSIBILITY`.
Goal: `CHAT-FIDELITY` remains partial. Implementation qualification is complete;
native same-card review is the final handoff, not independent approval evidence.

## Delivered behavior

The first enlarged-text widget run exposed geometric focus traversal skipping the
supported hands-free switch position (`widgets-1.log`). The composer now has a
local `WidgetOrderTraversalPolicy`; text scaling no longer changes command order.
Compact Send/microphone switching uses zero transition duration when
`MediaQuery.disableAnimations` is true. No controls, capabilities, ownership
contracts or Agent/Wing Link operations were added. The E2E wrapper now preserves
the platform reduced-motion flag rather than overriding it with its false fixture
notifier. Existing approved predecessor changes in these dirty files are retained.

Two new widgets exercise actual Tab/Shift+Tab and Enter/Space at
`TextScaler.linear(2)`, with `disableAnimations: true`. They check wide → compact
→ wide composition at 1440 → 600 → 1440 × 900, a live 200% → 150% → 200%
text-scale change without remount, named controls inside the viewport, no Flutter
overflow/errors, retained draft and unchanged session/profile/origin. The compact
switcher duration is explicitly zero. Each key activates draft capture and local
cancellation: one capture, one cancel, zero Agent Stop calls, cancelled late text
not appended. Model open/Escape cancellation produces no mutation. Explicit
active-run Stop records exactly one call on the initiating channel with the
retained session/profile/origin; all sends, creates, locks, assignments and
approval responses remain zero in widgets. Five existing composer-focus tests
also pass; unchanged predecessor order/recovery suites were not rerun.

## Compiled Chromium journey

Chromium `152.0.7977.75`, headless on Linux, runs a fresh release JavaScript build
of `lib/main_e2e.dart` against the existing deterministic fixture. Only connection
and semantics enablement use the existing bootstrap hooks. All subsequent
interaction uses real keys; state/focus observations are read-only.

An isolated disposable browser profile sets Chromium's native
`partition.default_zoom_level.x` to `log(2)/log(1.2)`. This is native 200% browser
zoom, not CSS transform, pinch magnification, device-scale emulation, or viewport
shrink masquerading as enlarged text. Assertions observe a 2880 × 1800 physical
viewport becoming 1440 × 900 CSS pixels with `devicePixelRatio == 2`. The compact
physical viewport is 1200 × 1800, observed as 600 CSS pixels wide while retaining
200% zoom. `prefers-reduced-motion: reduce` is observed true; the wrapper preserves
Flutter's inherited accessibility setting. Native browser zoom enlarges the whole
render, including text and controls; it is not Flutter text-only scaling. The
widgets separately qualify real text-only scaling. The isolated preference schema
is Chromium-specific and metrics fail closed if it changes.

Wide forward/inverse traversal reaches attachment → draft → model → hands-free
switch → voice → Send and returns to the editor. Compact composition remains
editor → attachment → Send, with model in the separate strip and dictation in
Chat menu. Wide return awaits actual adaptive controls before traversing. Draft
activation with both Enter and Space uses the unavailable-device-capture fallback
and keyboard **Continue in text**, preserving the draft. Model Space/Escape is
read-only. Before explicit Send there are zero application mutations. The retained
owner is `e2e-hermes-session`; profile identity is unchanged (fixture summary is
null, not a newly qualified non-default profile). Enter sends once and Space stops
that exact run once. Stop is not confused with local capture cancellation.

Application request counts, from `attachments/composer-accessibility-receipt.json`:

| Request | Count |
| --- | ---: |
| GET /v1/capabilities, /v1/models, /v1/skills, /v1/toolsets | 1 each |
| GET /api/jobs, /api/sessions, /api/model/options | 1 each |
| GET /api/sessions/e2e-hermes-session/messages | 2 |
| POST /v1/runs | 1 |
| GET /v1/runs/run_1/events | 1 |
| GET /v1/runs/run_1 | 3 |
| POST /v1/runs/run_1/stop | 1 |

Fixture readbacks independently confirm one run, one Stop, zero approvals and
zero model locks. Canonical `run_1` is cancelled and belongs to the retained
session. No session creates, model writes, approval writes, audio requests or
replayed sends occur. Browser errors/RenderFlex overflow reports are empty.

Inspected wide and compact rendered screenshots plus focused draft/Stop crops:
composer text, icons and labels are readable and unclipped. Compact draft wraps
without losing text. Focused/unfocused RGB differences are 4838 pixels for each
draft key crop, 4883 compact Send, 4875 wide Send and 8472 Stop. Zoom-aware crops
use physical screenshot coordinates rather than unscaled CSS semantics bounds.
Flutter ActionChip model/Stop retains checkbox semantics; this is not a
screen-reader qualification.

## Executed checks and iterations

Evidence is ignored under `.task-evidence/t_70b3c065/`. All commands ran in the
project checkout, preserving unrelated changes. No commit, stage, push or release.

| Exact command | Result / evidence |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib/features/hermes_chat/screens/state/hermes_chat_layout.dart lib/main_e2e.dart test/features/hermes_chat/screens/hermes_chat_composer_accessibility_test.dart` | PASS; format-pass.log |
| `flutter analyze` | PASS; no issues; analyze-pass.log |
| `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_composer_accessibility_test.dart test/features/hermes_chat/screens/hermes_chat_composer_focus_test.dart` | PASS; seven tests; widgets-pass.log |
| `NODE_OPTIONS=--max-old-space-size=2048 flutter build web --release -t lib/main_e2e.dart` | PASS; build-resume.log; existing flutter_tts Wasm dry-run/font warnings; no Wasm support claim |
| `CHROME_EXECUTABLE=/usr/bin/chromium WING_APP_URL=http://127.0.0.1:18993/ NODE_OPTIONS=--max-old-space-size=2048 npx playwright test --config=playwright.config.mjs playwright/tests/regression/chat-composer-accessibility.spec.mjs --workers=1 --output=.task-evidence/t_70b3c065/browser-fifth` | PASS; one journey; browser-fifth.log; attachments/ |
| `git diff --check -- lib/features/hermes_chat/screens/state/hermes_chat_layout.dart lib/main_e2e.dart test/features/hermes_chat/screens/hermes_chat_composer_accessibility_test.dart playwright/tests/regression/chat-composer-accessibility.spec.mjs docs/quality/chat-composer-accessibility.md` | PASS |
| `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo>` | PASS |

The prior worker's build was interrupted, not a passing build. Browser attempts
one/two rejected incorrect zoom preference shapes; third verified zoom and
exposed unscaled screenshot cropping; fourth exposed an asynchronous adaptive
render wait. Fifth passes. Test cleanup briefly removed a needed model type
import and restored the platform override too late; retained analyze-final.log,
widgets-final.log and widgets-verified.log record those failures. Final import
and explicit end-of-test restoration pass without weakening assertions.

## Scoped source identity and limits

Wing HEAD: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`, with approved shared
predecessors. Read-only Desktop source comparison remains the
[predecessor's supported group](chat-composer-order.md#source-backed-group);
its AGENTS.md was read. No new upstream behavior/execution is claimed. Retained
Stop placement and local follow-up differences are unchanged.

| Tested path | SHA-256 |
| --- | --- |
| lib/features/hermes_chat/screens/state/hermes_chat_layout.dart | fd3646fee14e8daaed6dcaba20cfcdd868a2246768ecd00e09925d3c105fcdd4 |
| lib/main_e2e.dart | 2dbe7e5f481cef73e43262e2f8b9070cf4bc611f74f4e6496a0284d1a255d687 |
| lib/features/hermes_chat/screens/hermes_chat_screen.dart | e7c22f33789f4eccfadefcdb2daded3215088d509485e5ed5ef96f94077acc1d |
| lib/features/hermes_chat/voice/hermes_voice_input_controller.dart | 76ebad78649590b127bd0db5ed0bd5f3a0ca462f5bca10c79f2b6c5f613b3a42 |
| test/features/hermes_chat/screens/hermes_chat_composer_accessibility_test.dart | cd16b337a319c96285c1e67d3f1fefa4c6e04988b900e3f7be1d7c59bcecb53a |
| playwright/tests/regression/chat-composer-accessibility.spec.mjs | a0656b4f5fb7017bcca2b038f800ef1fbef78c62b5b4f0814c35a744efa80544 |
| playwright/support/inventory_keyboard.mjs | 850370b758d2e78984d2cf7a7b0900c530b016ddaa6524758083b19b5f2f1645 |
| serve_web.mjs | 5c66672ab8bdb683e7921fdd1398c5dbcddebbbbed5ebbce93cb909b302ec2da |

The newly generated build/web and focused-test build outputs are removed after
qualification; retained logs/attachments are the evidence, not a distribution.
No backend, upstream, credentials, shared settings or services changed. Native
Linux desktop, Android/iOS, physical audio, live Agent/provider, assistive
technology, arbitrary scales/viewports, full suite, Go, npm audit and packaged
standalone dependency closure are NOT_CHECKED. No full accessibility or parity
claim. Questions (defaults applied): none.
