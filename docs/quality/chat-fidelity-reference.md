# Chat composer reference: direct dictation

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card: `t_98e84581`. Ledger task: `DOC-CHAT-FIDELITY-REFERENCE`.
Goal: `CHAT-FIDELITY`, still partial. This receipt compares source and records
executed Wing widget checks. It does not implement or accept composer parity.

## Scope and source identity

The selected interaction is microphone activation followed by draft review.
The comparison covers control order, discoverability, ownership and recovery.
It excludes model/transcript repairs, new audio protocols and privileged IPC.

Desktop reference HEAD is `withdrawn reference revision`.
Wing HEAD is `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`.
Wing's inspected working tree includes pre-existing changes, so HEAD alone does
not identify the tested source. No existing product or test file was edited.
Desktop's five pre-existing `.claude` deletions were left untouched.
Neither checkout is claimed to be the latest remote release.

SHA-256 fingerprints of the inspected comparison and executed test seams:

| File | SHA-256 |
| --- | --- |
| `withdrawn source citation` | `57b91c3e755ecd027c682568b455be15153bab1c2c1ad97edea593979a10b421` |
| `withdrawn source citation` | `d9fc9157729fb40f4f3585dcf4eae53cebb16b237a1b798e5a438f43246b34c3` |
| `lib/features/hermes_chat/screens/state/hermes_chat_layout.dart` | `82546919cc39b0fc7a59a0d3dd9dacd71ea137581f7d88bdfe77016ce454eaa5` |
| `lib/features/hermes_chat/screens/hermes_chat_screen.dart` | `a1a0cb7a6853379e2cce644e16b01c17d30cd44c569fc30fb36df188f901d4fa` |
| `lib/features/hermes_chat/voice/hermes_voice_input_controller.dart` | `271d80b6e5f8990faad9e6add3cda487f0450d7beac52a1b21b80613ceb6ddcb` |
| `test/features/hermes_chat/screens/hermes_chat_composer_focus_test.dart` | `e45c66d1f71bddfc15f53c20f750422f4b286460367b126475907f76cfb2dffe` |
| `test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart` | `6ccda5b47bd1ac6d19f3c72eb94e3d52c7bfd1e86560a617fdc1c4d2c045dbcb` |

The layout and focus-test fingerprints match the selection snapshot. These
fingerprints identify selected files, not the full dependency closure or a
packaged binary. Existing build caches were retained; this card did not create
a web/native build or a copied repository.

## Source-bound comparison

[Desktop ChatInput](official-desktop-reference.md#withdrawn-evidence)
provides the reference interaction:

- `ChatInput`, lines 690–768: bottom toolbar source order is attachment,
  supported microphone, `toolbarExtras` (caller-provided model/folder controls),
  spacer, optional context gauge, then Stop or quick-ask/Send.
- The microphone's `onClick`, lines 706–724, snapshots `input` before starting
  `voice.toggle()`. The button is disabled while transcribing and exposes a
  recording state through `aria-pressed`. It is not a hands-free-send control.
- `handleVoiceResult`, lines 120–132, combines the existing draft with recognition
  results. A final result refocuses the textarea. Sending remains a separate
  `handleSend` action. `handleKeyDown` ignores IME composition and treats
  Enter as Send, with Shift+Enter left for multiline text.
- Voice errors appear separately above the input, lines 657–661.
  [useVoiceInput](official-desktop-reference.md#withdrawn-evidence)
  defines `supported` from SpeechRecognition or MediaRecorder/getUserMedia,
  passes `profile` to transcription, and stops recording through `toggle`.
  Final transcription failure and microphone denial produce error state.
  Stopping recording can finalize a transcript; it is not a discard operation.

This is source inspection, not a Desktop runtime result. Ordinary HTML button
keyboard activation is an expected browser affordance, not an executed keyboard
journey here. This component does not prove endpoint/session race safety.

[Wing composer layout](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart)
shows one actual deviation: direct microphone activation selects hands-free
capture/send instead of draft dictation. Control placement also obscures the
draft-only action on the wide baseline.

- `_buildDesktopComposerCommandBar`, lines 2216–2286: textarea is followed by
  hands-free switch, expanded model/Stop strip, then attachment, microphone,
  Send via `_composerIconButtons`. Draft dictation has no direct wide button
  or wide composer menu.
- `_buildMicButton`, lines 2544–2592: ordinary activation calls
  `_setContinuousVoice(true)` and is named Hands-free voice. `GestureDetector`
  long press calls `captureDraft`. While capturing, ordinary activation pauses.
- `_buildMobileComposer`, lines 2044–2088: compact mode has a menu, emoji,
  textarea, attachment, then Send when there is payload or microphone otherwise.
  `_buildComposerMenuButton`, lines 2293–2342, discloses Sessions, Hands-free voice,
  then Dictate a draft. The latter calls `captureDraft`, not automatic submission.
- The compact menu therefore supplies a visible draft-only disclosure path.
  That path is absent from the wide command bar. A long press is not a keyboard
  equivalent, and the primary mic's semantics name the different hands-free action.

The discrepancy is behavioral, not a claim about pixel spacing. Responsive
composition is already an explicit deviation in the
[parity ledger](../product/hermes-desktop-parity.md#reference-and-evidence-boundary).
The [route inventory](../product/routes.md) describes compact dictation disclosure;
it does not establish wide direct-dictation parity.

## Authority and exact gates

Agent remains authoritative for sessions and runs. Dictation adds volatile text
to the current Wing draft. It must not change model assignment, create a session,
submit a run, or use Wing Link. Desktop's main-process transcription is reference
behavior only; copying its provider/IPC authority is not permitted.

Current Wing ownership is explicit in
[HermesVoiceInputController](../../lib/features/hermes_chat/voice/hermes_voice_input_controller.dart):
`_bindConversation` / `_ownsConversation` bind channel object identity plus
`(connectedBaseUrl, selectedProfileId, activeSessionId)` and a conversation
generation. Operation generation rejects cancelled capture results.
Disconnect or replacement owner pauses capture. Late transcription is checked
again before draft admission. `_capture(autoSend: false)` invokes `_onDraft`,
not `startVoiceRun` / `submitVoiceRun`.
[Screen `_appendVoiceDraft`](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart)
appends to the current draft, places the caret at its end, and restores desktop
composer focus. It does not send text.

Current UI dictation enablement is `canSendTurns && continuousVoiceEnabled` and
not capturing. The long-press path uses the same idle mic gates.
[Message flow `_canSendTurns`](../../lib/features/hermes_chat/composer/hermes_chat_message_flow.dart)
requires settled remembered-session recovery, no profile selection, a non-null
active session, no unreconciled run, and `_hasChatTransport`.
With a capability document, that transport is exactly
[HermesTransportPolicy](../../lib/core/hermes/policy/hermes_transport_policy.dart):

- `session_chat_streaming` plus `session_chat_stream`,
  `POST /api/sessions/{session_id}/chat/stream`; or
- `run_submission` plus `run_events_sse`, `runs`, `POST /v1/runs`,
  and `run_events`, `GET /v1/runs/{run_id}/events`.

Each endpoint requires a supported schema, every declared caller scope, and
supported query context when `profile_scoped`. The null-document branch remains
an existing compatibility path, not new authorization or proof of remote support.

Local capture uses `hermesVoiceCaptureServiceProvider` and the existing platform
service. Absence/denial is reported by the capture flow, not simulated as support.
Remote audio is separate: [API channel `transcribePcm16`](../../lib/core/hermes/channel/hermes_api_channel.dart)
requires `audio_api`, exact `audio_transcribe`, `POST /api/audio/transcribe`,
supported schema, every declared scope and supported scoped profile context.
The request carries the selected profile. Controller fallback retains device
transcription when the exact remote audio route is unavailable or fails.
No new route, synthetic capability, credential access or provider call is proposed.

## Bounded next port slice

Register `PORT-CHAT-DIRECT-DICTATION` under `CHAT-FIDELITY`. This is a future
implementation contract, not product work performed by this card.

Deliver one wide-composer draft-only microphone action, visibly adjacent to the
attachment control and before the model strip, with a distinct localized name.
Use the existing `captureDraft` path. Preserve the separately named hands-free
switch and existing compact menu; do not silently convert hands-free behavior.
Attachment/model/Stop/Send support and accepted model repairs remain unchanged.
The slice does not port folder, context gauge, quick-ask, attachment protocol,
transcript disclosures or Desktop's recorder/provider implementation.

The smallest implementation seams are `_buildDesktopComposerCommandBar` and a
small draft-action builder in the layout, plus English localization and generated
output if needed. Extend the nearest composer/voice tests with existing service
fakes. No new transport, state-management layer or dependency is needed.

Required regression oracles for that slice:

1. At wide width, inspect visual and traversal order: attachment → draft mic →
   model strip, with separately named hands-free and Stop/Send still operable.
   Tab/Shift+Tab reach and leave the draft action. Enter/Space starts one draft
   capture without a long press, automatic submission or hands-free activation.
   Test semantic name and visible focus, not widget presence alone.
2. Apply the current UI gates at activation as well as rendering. Capture the
   rendered channel/origin/profile/session identity. Cached actions after owner
   change, unsettled selection, gate loss or disconnection start zero captures.
   This synchronous activation requirement is a next-slice oracle; the inspected
   popup callback alone does not prove it. Do not broaden local or remote grants.
3. While capturing, repeat activation must not overlap capture. Provide a clearly
   named cancellation action using existing `pause`/teardown semantics. Cancel
   discards pending recognition results, preserves the existing draft and sends
   nothing. Do not claim Wing cancel equals Desktop's finalize-on-stop behavior.
4. Same-owner completion appends once to the existing draft, preserves caret and
   restores desktop editor focus for review. Keep IME handling and explicit Send.
   A profile/session/origin/channel change or route disposal rejects late results
   without altering the replacement draft or stealing focus.
5. Null service, microphone denial, timeout and transcription failure retain the
   draft and show localized safe feedback. After teardown, explicit retry starts
   a fresh capture only for the still-current authorized owner. Reconnect never
   starts capture or resends a prompt. Keyboard users can dismiss feedback and
   continue in text. Preserve the existing no-overlap teardown path.
6. Deterministic assertions show zero session creation, model writes, run submits,
   approvals, Agent Stop and Wing Link operations for opening/starting/completing/
   cancelling dictation. Unsupported remote audio makes zero remote audio requests.
   UI focus checks do not substitute for channel-boundary ownership assertions.

## Executed checks and coverage limits

All commands ran from the Wing repository on Linux. The platform overrides and
controlled capture services are widget-test inputs, not native microphone proof.

| Exact command | Result | What it proves |
| --- | --- | --- |
| `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_composer_focus_test.dart` | PASS, 5 tests | Model/Stop presence; no idle badges; initial desktop focus; current-session completion refocus; no background focus theft; no mobile completion keyboard opening. |
| `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart --plain-name 'dictation stays a draft; use menu true'` | PASS, 1 test | At 360px, menu activation starts one controlled capture; result stays a draft with no voice run. Pointer activation, not keyboard disclosure. |
| `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart --plain-name 'desktop dictation restores composer focus for review'` | PASS, 1 test | Long-press dictation appends to existing draft and restores Linux-overridden editor focus without a voice run. Does not prove wide direct-button parity. |

`python .dart_tool/chat-fidelity-reference/check_receipt.py` passed: 10 local
links and their anchors resolve, and the receipt has no trailing whitespace.
The card-owned ignored helper also ran
`git diff --no-index --check /dev/null docs/quality/chat-fidelity-reference.md`.
It returned no diagnostics. Git's exit 1 denotes the new-file diff, not a
whitespace failure. The first chained command stopped on that exit before any
ledger writes; the helper explicitly validates exit 0/1 with empty diagnostics.
The helper resolves every Markdown target relative to this receipt, verifies
heading anchors, and rejects whitespace diagnostics; it uses no network.

The supported ledger helper marked `DOC-CHAT-FIDELITY-REFERENCE` done, recorded
the executed checks, registered `PORT-CHAT-DIRECT-DICTATION` in Now, and rendered
coverage. `DOC-CHAT-TRANSCRIPT-DISCLOSURE` remains separate and open.
`python ~/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo>`
returned `ok`. `CHAT-FIDELITY` remains partial. Shared ledger files are excluded
from this card's isolated receipt commit. No follow-up card was dispatched.

NOT_CHECKED: Desktop runtime; strict keyboard-only dictation journey; native
Linux/Windows/macOS capture or permissions; Android device; compiled web;
screen-reader operation; live Agent/provider/audio; acoustic behavior; full
cancel/error/owner/gate-loss matrix; packaging/release; full product parity.
No broader suite, analyzer or formatter was required for this new receipt-only
change. Source inspection defines the remaining oracles, not passing runtime
results for them. Applied STE-inspired wording and meaning review to this receipt;
full ASD-STE100 dictionary compliance was not verified.
