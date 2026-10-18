# Explicit Live voice conversation

## Scope and source

This is a Wing client interaction over its existing speech-recognition, Agent
voice-turn and TTS controller, not a realtime audio-model implementation. No Agent
source or contracts were changed. Official Desktop was inspected read-only at
`d923a5eb487a17c0a68801bba9ef0f56c81040a8`:

- `apps/desktop/src/app/chat/composer/hooks/use-composer-voice.ts`: separate
  dictation, conversation start/end, speech consent and interrupt/submit seams.
- `apps/desktop/src/app/chat/composer/index.tsx:1065–1086`: conversation state and
  barge-in use the existing run interruption action.
- `apps/desktop/src/lib/voice-barge-in.ts` and its tests: listening during playback
  is a distinct requirement. Wing uses recognizer partial results rather than
  porting Electron audio detection or its separate GPT-Live transport.

The explicit **Start Live voice** action is visible without opening composer
options. Saved speech consent allows one-action entry; otherwise the dialog asks
for this session only, explaining automatic sends, ongoing listening and playback.
It never writes `speakRepliesEnabled`. Unavailable capture or playback blocks entry
without a prompt submission; dictation remains separately available when supported.

The active surface exposes listening, speaking/interruption listening, microphone
mute, independent output mute, Stop reply and **End · return to text**. Microphone
mute preserves the conversation and speech output; unmute waits for cancellation
before capturing again. End cancels local input/output, rejects late recognition
and restores the retained text draft. Ending voice is not a claim that Agent work
was cancelled. An interrupted active Agent run still requires the existing exact
Stop confirmation before a replacement voice turn is submitted.

## Root-cause correction

A no-speech/timeout/echo capture window previously scheduled rearm but returned
while TTS was speaking. Long playback could therefore lose its interruption
listener until playback ended. Rearm now starts another capture independently of
pending playback, with the same teardown and owner fences. The regression failed
on the baseline (`capturing` false during blocked TTS) and passed after the fix.
Existing streaming cursor and canonical-history reconciliation tests remain intact.

## Verification

SDK: Flutter **3.44.9**, Dart 3.12.2 (available locked-dependency-compatible SDK;
repository documentation names 3.44.2). `flutter pub get --offline
--enforce-lockfile` succeeded without a lockfile delta.

Executed on Linux with deterministic Flutter services:

- Voice/controller/reconciliation, integrated Chat lifecycle, composer
  order/recovery/accessibility/focus, speech capture/TTS, voice settings and capture
  provider suite: **223 tests passed** on the final candidate.
- Integrated 390px / 200% text / reduced-motion journey: visible entry → explicit
  consent → first turn → concurrent playback/listening → partial barge-in → second
  turn exactly once → microphone mute/late-result rejection → unmute → end/text
  with retained draft and unchanged saved speech preference.
- Consent cancellation and stale consent after owner/voice-gate changes; voice
  master switch ends active listening immediately; controller session-consent
  expiry and cancellation-fenced unmute.
- Focused `flutter analyze --no-pub` on Chat screen/layout/controller and affected
  voice tests: no issues.
- `flutter build web --release --no-pub`: production web build succeeded. Existing
  flutter_tts Wasm dry-run JS interop warnings and CupertinoIcons font warning
  remain; this was a JavaScript build, not Wasm qualification.

Final command results and commit identity are reported with the local handoff.
`hermes_chat_layout_width_test.dart` has a pre-existing `testWidgets` declaration
outside `main` at line 59; it was not modified or treated as a passing full-suite
check.

No physical device, real microphone, acoustic echo cancellation, live recognition,
latency, Android audio focus, live Agent/provider or realtime model was qualified.
The APK/signing/publication handoff is separate. Deterministic barge-in tests prove
client ordering and ownership, not a guarantee of simultaneous recognition and
playback on every device.
