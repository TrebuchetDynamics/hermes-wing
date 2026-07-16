# ADR 0009: Use local device STT and TTS packages for voice

Status: accepted
Date: 2026-07-07

## Context

Hermes Wing voice is local to the client install. The app depends on `speech_to_text` for speech-to-text, `flutter_tts` for platform text-to-speech, and the pinned `pocket_speech` package for optional offline model inference. Hermes receives submitted text transcripts; it does not need client-recorded audio for the active workflow.

## Decision

Use local device packages for voice:

- `speech_to_text` captures user speech as a text transcript.
- The explicit microphone control fills the composer with the transcript for
  review and editing; it does not send automatically.
- Continuous voice is a separate opt-in mode that submits the transcript,
  speaks the completed Hermes reply, and then re-arms capture.
- Recognition requests set `onDevice: true`; unsupported on-device recognition
  fails closed instead of silently using a network recognizer.
- `flutter_tts` speaks assistant replies when the platform supports it.
- `pocket_speech` runs the selected model entirely on device: Kitten nano-int8
  (about 26 MB) or Kokoro (about 365 MB including voices).
- Voice package support is platform-gated. Unsupported platforms return `null` providers and the UI pauses continuous voice with plain-language feedback.
- Do not log raw recognized speech text in diagnostics.
- Foreground lifecycle changes, switch-off, disconnects, and session changes
  cancel active capture and invalidate late results.
- Pocket Speech playback completion is observed before re-arming capture, and
  optional downloaded voice packs require HTTPS plus pinned SHA-256 digests.

## Consequences

- Server audio APIs remain out of scope until Hermes exposes stable mobile-safe endpoints.
- Tests use injectable engine interfaces and fake services rather than real microphones or speakers.
- Linux can still build the app. Platform TTS remains unavailable there, while Pocket Speech can run when a compatible voice pack is installed.

## Edge cases

- Unsupported platforms return `null` services and the UI pauses continuous voice instead of crashing.
- Blank captured transcripts fail locally before reaching Hermes.
- TTS ignores blank assistant text and retries configuration after a failed setup call.
- Speech diagnostics log metadata, not raw recognized words.

## Evidence

- `pubspec.yaml` (pinned `pocket_speech` Git dependency)
- `lib/features/hermes_chat/screens/hermes_chat_screen.dart:37-44`
- `lib/features/hermes_chat/controllers/hermes_voice_input_controller.dart`
- `lib/features/voice/services/platform/default_voice_capture_service.dart:15-33`
- `lib/features/voice/services/speech/speech_to_text_voice_capture_service.dart:17-99`
- `lib/features/voice/services/tts/text_to_speech_service.dart`
- `lib/features/voice/services/tts/pocket_speech_text_to_speech_service.dart`
- `test/features/voice/services/speech/speech_to_text_voice_capture_service_test.dart`
- `test/features/voice/services/tts/pocket_speech_text_to_speech_service_test.dart`
