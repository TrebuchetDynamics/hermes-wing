# Wide composer draft dictation

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card: `t_f2f5b956`. Task: `PORT-CHAT-DIRECT-DICTATION`. Executor evidence,
pending native same-card review; this does not close `CHAT-FIDELITY`.

## Delivered behavior

The wide composer orders attachment → **Dictate a draft** → model strip.
The separately named hands-free switch/button and explicit Send remain separate;
compact menu disclosure and long-press dictation remain available. During draft
capture the direct action becomes **Cancel draft dictation**. Cancellation discards
recognition, rather than reproducing Desktop's finalize-on-stop behavior.

Every draft entry point captures its rendered channel, origin/profile/session,
composer ownership generation and voice-setting generation. The controller checks
that guard before capture, after teardown and asynchronous recognition/upload,
and on channel notifications. Selection/recovery, disconnect, owner changes and
voice-master loss invalidate the intent, including same-frame roundtrips. A cached
cancel also requires its captured operation generation, so it cannot cancel a
newer capture. Draft failure teardown fences explicit retry; hands-free timeout
and rearm behavior remain unchanged.

Same-owner completion appends once, sets the caret at the end and returns editor
focus for desktop/wide-web review. Existing IME/Send handling is not redesigned.
No session/model/run/approval/Stop/host-management mutation is introduced.

## Acceptance evidence

All widget tests use deterministic services on Linux with a Linux target override.
The compiled browser is local Chromium, 1440×900 and 390×900. No physical audio,
live Agent/provider or native Linux application was exercised.

1. The two keyboard tests in
   `test/features/hermes_chat/screens/hermes_chat_direct_dictation_test.dart`
   check attachment/draft/model horizontal order, named semantics, actual focus
   traversal in both directions and Enter/Space single-capture activation.
   `NODE_OPTIONS=--max-old-space-size=2048 node .dart_tool/direct-dictation/visual.mjs`
   passed actual Tab/Shift+Tab, Enter/Space unavailable-service recovery and compact
   keyboard menu disclosure. Inspected `wide-unfocused.png`, `wide-focused.png`,
   `wide-unavailable.png` and `compact-menu.png` under that ignored evidence directory:
   no clipping; the draft mic gains a visible circular focus fill. A decoded RGB
   comparison found 1250 changed pixels in its (590,815)-(634,863) focus crop.
2. Six owner/gate tests reject cached callbacks before a frame and reject late
   results after session, profile, origin, disconnect, profile-selection and
   unreconciled-run transitions. The voice-master test checks disabled rendering,
   cached callbacks and active-capture invalidation. Channel replacement and route
   disposal have separate tests. Returning to the old owner/gate does not revive
   intent. The existing restoration gate is reused, not replaced.
3. Repeated cached activation while capturing starts one capture. Named cancel
   preserves the draft, discards late results and permits explicit fresh retry.
   The teardown-barrier test proves retry cannot overlap the cancelled microphone.
   Cancellation uses controller `pause`, not Agent Stop.
4. Both keyboard completion tests check one append, end caret, editor focus and
   hands-free still off. Owner/channel/disposal tests preserve replacement text
   and do not steal focus on late completion.
5. Null service, microphone denial, timeout and transcription failure retain
   text and render localized voice feedback. Recognizer failures cancel through
   the teardown fence before explicit retry. The browser exercises null-service
   feedback twice and **Continue in text**; reconnect tests never auto-capture.
6. Every fake-channel scenario checks zero session creation, model lock/assignment,
   sends/voice submissions, approvals and Agent Stop. The production
   `HermesApiChannel` widget test completes audio-bearing draft capture with an
   unadvertised audio route and cancels another capture: its HTTP mutation recorder
   remains empty, including audio transcription. The existing exact audio policy
   rejects before network I/O and device text remains the fallback. Browser receipts
   record zero mutations, remote audio requests, Wing Link management requests
   and page errors at both widths.

## Commands and results

| Executed command | Result |
| --- | --- |
| `flutter gen-l10n` | PASS |
| `dart format --output=none --set-exit-if-changed lib/features/hermes_chat/screens/hermes_chat_screen.dart lib/features/hermes_chat/screens/state/hermes_chat_layout.dart lib/features/hermes_chat/voice/hermes_voice_input_controller.dart test/features/hermes_chat/screens/hermes_chat_direct_dictation_test.dart` | PASS; four files unchanged |
| `flutter analyze` | PASS; no issues |
| `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_composer_focus_test.dart` | PASS; 5 tests |
| `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart` | PASS; 30 tests |
| `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_direct_dictation_test.dart` | PASS; 18 tests |
| `flutter test --concurrency=1 test/features/hermes_chat/voice/hermes_voice_input_controller_test.dart` | PASS; 56 tests |
| `flutter build web --release -t lib/main_e2e.dart` | PASS; JavaScript release, existing flutter_tts Wasm dry-run warnings |
| `NODE_OPTIONS=--max-old-space-size=2048 node .dart_tool/direct-dictation/visual.mjs` | PASS; wide/compact receipts and inspected screenshots |
| `README_ASSET_BASE_URL=http://127.0.0.1:8895/ NODE_OPTIONS='--max-old-space-size=2048 --import=./.dart_tool/direct-dictation/local-chromium.mjs' npm run readme:assets` | PASS; regenerated showcase inspected |
| `python .dart_tool/direct-dictation/verify_scope.py` | PASS; nine scoped fingerprints, whitespace, predecessor localization and two zero-request browser receipts |
| `git diff --check` | PASS |
| `python ~/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo>` | PASS; task done, CHAT-FIDELITY remains partial |

Regression-first execution of the direct-dictation target failed nine tests before
implementation: no direct wide action existed. Initial keyboard harness assertions
used an ancestor focus scope instead of the actual focused button; corrected to
primary-focus ownership. Analyzer findings were fixed. A broader failed-capture
teardown initially broke four continuous-voice tests; narrowing it to draft-only,
non-continuous failure restored all 56 controller tests. No upstream/test-fake
behavior was weakened to obtain that pass.

The first README command with `CHROME_EXECUTABLE=/usr/bin/chromium` failed because
the unchanged generator ignores that variable and its pinned headless shell was
absent. The ignored preload binds Playwright to installed Chromium, without
changing tooling, downloading a browser or changing system configuration.
Browser harness corrections fixed the exact attachment label, frame settling,
Agent `/v1` inventory classification and compact menuitem semantic lookup.

## Source and inherited-diff attribution

Desktop reference: read-only
`withdrawn source citation`, lines 690–734,
HEAD `withdrawn reference revision`.
The [six-oracle contract](chat-fidelity-reference.md#bounded-next-port-slice)
defines this bounded slice; broader transcript/composition parity remains open.

Pre-edit snapshots remain under `.dart_tool/direct-dictation/baseline`.
Layout inherited the approved `t_22ea1211` connection-entry diff and
`t_3ad70dd4` explicit model-selection line. All three localization snapshots
were byte-identical to approved `agent/wing/t_3ad70dd4` before this card. Their
inherited model copy is not attributed to dictation. This card adds only the
cancel label/localization, guarded dictation/layout/controller changes, focused
tests, this receipt and regenerated showcase.

The shared checkout's model picker is byte-identical to approved predecessor
`t_3ad70dd4` (`3467eb4ae432efef2bac4300a7542a1d9245a3ec`), but main HEAD lacks
its `requireExplicitSelection` property. The required scoped agent commit excludes
that read-only picker file. Consequently validation qualifies the shared checkout
with approved predecessors applied, not a standalone checkout of this card branch.
Apply that predecessor before this card when assembling a clean review build;
standalone branch build/package execution is NOT_CHECKED. No excluded dependency
file is copied into this card to hide that dependency.

Scoped SHA-256 at final validation:

| Artifact | SHA-256 |
| --- | --- |
| `hermes_chat_screen.dart` | `e7c22f33789f4eccfadefcdb2daded3215088d509485e5ed5ef96f94077acc1d` |
| `hermes_chat_layout.dart` | `2a4edc243fe86b94f037e2b18221d3e462210d0cba4ba281715c1883d591a660` |
| `hermes_voice_input_controller.dart` | `76ebad78649590b127bd0db5ed0bd5f3a0ca462f5bca10c79f2b6c5f613b3a42` |
| `hermes_chat_direct_dictation_test.dart` | `207952b2a614290c9f4e54667e3a2ab9e8b7c587da1e1031f11c8d442ad528fe` |
| `assets/readme/showcase.png` | `9c5b55e44ae544031bb4e5116d44b5f6e4138a725234e6776a2b705824d8ca17` |

## Limits and questions

The existing web voice platform factory returns no capture service. Browser
verification therefore covers real rendering, keyboard activation and unavailable
recovery, not recognition; deterministic widget services cover capture. Wide-web
focus restoration is implemented but acoustic/browser speech is not qualified.
Physical microphone, live backend/provider, native Linux runtime, packaged branch
execution, and full transcript/IME parity are NOT_CHECKED. No platform support
claim, new API, dependency, grant or host operation follows from these results.

Questions: none. Existing no-system-change, device-trust and publication defaults
remain applied. Native review entry is the final implementation step; approval
follows independently.
