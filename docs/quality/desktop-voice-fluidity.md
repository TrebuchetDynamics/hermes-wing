# Desktop voice interaction — bounded fluidity slice

Task: `t_f7117e0e`. User priority: voice interaction, fluidity, cleanliness and
clarity before broader visual-port work. This is partial implementation, not full
Desktop voice parity or physical-audio qualification.

## Reference and behavior

Official read-only Desktop checkout inspected at `d923a5eb487a17c0a68801bba9ef0f56c81040a8`:
`apps/desktop/src/app/chat/composer/voice-menu.tsx` separates dictation,
conversation and spoken-reply controls; `hooks/use-voice-conversation.ts:703-804`
drains queued fallback sentences immediately after playback. No upstream code,
configuration, gateway or provider was modified.

Wing previously awaited the microphone rearm delay after every spoken chunk,
including one-shot reply playback. A fake-clock regression with a two-second
rearm delay demonstrated that the next ready sentence was not spoken. Playback
now advances without that artificial delay; microphone retry delay, teardown
barriers, session ownership and authoritative run interruption remain intact.
Continuous playback also drains already available text after each chunk without
requiring another channel notification.

The active voice panel uses existing neutral surface/text tokens instead of a
large accent-filled panel. Mute/unmute stays visible during playback, independently
of stopping the current spoken output, ending microphone listening or leaving
voice mode. Text remains available after ending voice; mute does not cancel the
microphone or submit another turn. No new speech engine, wake-word listener,
provider selector or background voice service is introduced.

## Observed checks

- Regression first: `flutter test --no-pub --concurrency=1 test/features/hermes_chat/voice/hermes_voice_input_controller_test.dart --plain-name 'spoken streaming chunks do not wait'` failed before the fix, then the entire controller target passed (57 tests).
- Combined voice controller/policy, capture adapters, widget lifecycle and settings command passed 170 tests before the final neutral-surface styling and extra enlarged-text regression.
- Final enlarged-text regression passed at 390 logical pixels and 200% text, including live playback mute, preserved capture and return to the text composer.
- `flutter analyze --no-pub` passed after neutral-surface styling.
- Deterministic E2E web build succeeded; existing flutter_tts Wasm dry-run and font-family warnings remain.
- Compiled Chromium `chat-tts.spec.mjs` passed 20 tests with retries disabled before the final neutral-surface styling. It covers synthetic audio playback, explicit stop, queued replies, new-session/disconnect fencing and narrow controls, not physical microphone capture.

Toolchain: Flutter 3.44.9 / Dart 3.12.2, not repository pin 3.44.2; dependencies
resolved offline with `--enforce-lockfile`, lockfile preserved. Node 22.23.3.

## Final verification checkpoint

After the last style/test edits, the combined voice/capture/settings command passed
**171 tests**, with the JSON runner reporting `success: true`. Formatter check,
`flutter analyze --no-pub` and `git diff --check` passed. The deterministic web
entrypoint was rebuilt after neutral styling, then Chromium queue-drain,
stop-discards-queue and mobile-control cases passed **3/3**, retries disabled.
The broader earlier Chromium run remains **20/20**, with its earlier-style boundary
retained above. Independent Hermes review `deleg_04606c30` reported no bugs
attributable to the diff and independently passed 88 controller/lifecycle tests
using Flutter 3.47.5, distinct from the builder's 3.44.9. It identified a remaining
coverage gap: explicitly prove continuous-mode queue draining without another
channel notification; the new delay regression exercises one-shot playback.
No Android device or physical audio was used.

## Remaining qualification

Final affected-suite/build checks and independent review belong to this slice's
closing evidence. Android device execution, actual recognition, acoustic echo,
barge-in quality, TTS latency and live Agent/provider generation remain unverified.
No new APK or canonical integration is implied. Full Desktop voice port still
includes clearer unified voice entry, dictation finalization and separately
qualified engine/streaming capabilities; this slice does not mark them complete.
