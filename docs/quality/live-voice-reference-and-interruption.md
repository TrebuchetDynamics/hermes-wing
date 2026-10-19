# Live voice references and interruption correction

## Product boundary

Continuous voice in Wing currently means device recognition → authenticated Hermes
text turn → speech playback. It is not native speech-to-speech realtime. An
authenticated capabilities read from the selected Agent reported `audio_api: false`,
`realtime_voice: false`, and no audio endpoints. This is an observed deployment
constraint, not a claim that every Agent deployment lacks audio.

Do not add a direct provider connection, independent session/tool authority or
replacement backend. A future native realtime transport needs an exact advertised
Agent contract for audio, authorization, profile/session identity, cancellation and
reconciliation. A feature flag alone is insufficient.

## Read-only project references

These are implementation examples, not evidence that ChatGPT's or Gemini's private
consumer application internals are public or reproduced in Wing.

- [Google Gemini Live console, interruption handler](https://github.com/google-gemini/live-api-web-console/blob/0a4542fe0e39d07956ea7af5de45d7c81fde8960/src/hooks/use-live-api.ts#L75-L94)
  and [audio queue stop](https://github.com/google-gemini/live-api-web-console/blob/0a4542fe0e39d07956ea7af5de45d7c81fde8960/src/lib/audio-streamer.ts#L215-L235):
  stop playback and clear queued audio on the interruption event. Apache-2.0
  source; client-side example API-key handling is not a Wing credential design.
- [OpenAI Agents realtime WebRTC](https://github.com/openai/openai-agents-js/blob/9687b544c8c873080e6ff7e7d294c0b353cd9ab6/packages/agents-realtime/src/openaiRealtimeWebRtc.ts#L795-L814)
  and [WebSocket interruption](https://github.com/openai/openai-agents-js/blob/9687b544c8c873080e6ff7e7d294c0b353cd9ab6/packages/agents-realtime/src/openaiRealtimeWebsocket.ts#L729-L785):
  distinguish cancellation, output buffer clearing and history truncation to
  actually played audio. MIT source; these are provider operations, not Hermes
  endpoints Wing may infer.
- [OpenAI realtime agents example](https://github.com/openai/openai-realtime-agents):
  VAD versus push-to-talk and server-side credential exchange. Example routes and
  preview-model names are not a current Hermes transport contract.
- [Flutter WebRTC Android capture](https://github.com/flutter-webrtc/flutter-webrtc/blob/db81cea2730ae65b53fd3ffa97f45ad71200344a/android/src/main/java/com/cloudwebrtc/webrtc/GetUserMediaImpl.java#L275-L284):
  a useful AEC/noise-suppression reference. Adding WebRTC does not establish that
  separate platform TTS is part of its acoustic reference. Physical validation is
  required; no dependency was added.
- [LiveKit false-interruption tests](https://github.com/livekit/agents/blob/640bbd92196b57ea436d53d5352fb92fd1aa9a71/tests/test_false_interruption_resume.py):
  useful state/test patterns, not permission for another Agent backend. Source and
  model licenses must be checked independently before reuse. No code was copied.

## Implemented correction

Listening may rearm before the Agent has published a streaming run. Previously the
voice controller captured the interruption target when listening began. That
could retain `null`, then reject a genuine interruption once the run started.

Resolve the exact current interruption target at final recognized interruption
intent, after the existing channel/profile/session and operation-generation
checks. Pass that captured target once to `stopTurn`; retain confirmation and
fail-closed behavior. Never silently retarget a pending Stop or replay a prompt.
This does not implement native AEC, VAD or speech-to-speech audio.

## Verification

- Regression failed before implementation: expected one Stop, observed zero.
  Fixture was subsequently completed with a fake TTS service so the independent
  playback-unavailable guard does not terminate the scenario.
- Voice controller/reply policy, voice lifecycle, STT and TTS union:
  `flutter test --no-pub --concurrency=1 test/features/hermes_chat/voice test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart test/features/voice/services/speech test/features/voice/services/tts`:
  183 passed.
- `flutter analyze --no-pub`, changed-file formatter check and `git diff --check`:
  passed using Flutter 3.44.9 / Dart 3.12.2. Repository documentation pins 3.44.2;
  offline enforced-lockfile resolution used the available 3.44.9 without changes.
- Isolated Debug QA APK built and installed on the physical Moto G06; package
  metadata reported `DEBUGGABLE` and the new update time. Existing compile-SDK
  warning remains (secure-storage plugin requests 37, build uses 36).

Build and installation are not acoustic qualification. Physical recognition,
speaker echo, Bluetooth routing, actual barge-in latency and a complete live
conversation remain unverified. Do not claim the requested full Live mode is
complete from this correction or deterministic tests.
