# Voice Ownership Implementation Plan

> **For agentic workers:** Use executing-plans task-by-task. Checkboxes track future implementation; no commit, external mutation, or delegation authorization is implied.

**Goal:** Make capture, send, assistant reply, playback, and interruption belong to one explicit conversation operation.

**Architecture:** Extend the existing HermesVoiceInputController and capture/reply policies. Operation and speech generations already exist; establish one conversation ownership epoch above adapter-local cancellation without removing teardown protections.

**Tech Stack:** Flutter 3.44.2, Dart, existing VoiceCaptureService/TextToSpeechService seams and HermesChannel. No new voice engine or wake-word dependency.

## Global Constraints

- Follow the [program](2026-09-04-conduit-adaptation-roadmap.md) and exact Agent audio capability gates.
- Microphone pause and output mute are independent intents. Text input, text replies, and explicit Stop remain operable.
- No speech content in diagnostics, receipts, ordinary preferences, or new fixtures; use synthetic test phrases.
- Deterministic lifecycle tests do not qualify microphone, echo cancellation, Bluetooth, barge-in, battery, or thermals.

## Task 1: Fence the whole conversation operation

**Files:** modify `lib/features/hermes_chat/voice/hermes_voice_input_controller.dart`, `hermes_voice_capture_flow.dart`, and `hermes_continuous_voice_reply_policy.dart` in the same directory as needed; inspect `lib/features/hermes_chat/screens/state/hermes_chat_lifecycle.dart`; modify `lib/core/hermes/channel/hermes_channel.dart` and `api_channel/hermes_api_channel_voice.dart` if the tests prove the staged voice-run contract must change. Tests: `test/features/hermes_chat/voice/hermes_voice_input_controller_test.dart`, `hermes_voice_capture_flow_test.dart`, `hermes_continuous_voice_reply_policy_test.dart` in the same test directory, `test/core/hermes/channel/hermes_api_channel_tests/voice_tests.dart`, and `test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart`.

**Interfaces:** Capture channel identity, explicit gateway/profile/session, conversation epoch, and authoritative run/turn identity when available. Reuse current arguments and fields before adding a feature-local value type. Without a run ID use captured submission/turn identity and reject ambiguous unsolicited replies; never invent an Agent run ID.

- [ ] Trace `_operationGeneration`, `_speechGeneration`, reply selection, capture completion, partial transcripts, sound-level subscription, playback completion, and delayed rearm. Record which owner each callback checks.
- [ ] Extend controlled capture/TTS fakes to complete after pause, dispose, backgrounding, session switch, profile A → B → A, and same-ID session on another gateway. Assert zero draft writes, sends, speech, or rearm from stale work.
- [ ] Test a second run completing before the expected first reply and old playback finishing during a newer run. Current newest-assistant selection is not run-owned; only the exact response produced by the captured voice submission may trigger speech. If Agent events cannot identify it reliably, fail closed rather than speaking an unrelated same-session turn.
- [ ] In the channel voice suite, start voice staging under session/profile A, then switch session, profile, connection generation, and A → B → A before submit. Assert a terminal local failure and zero HTTP. If current `startVoiceRun / stageVoiceRunTranscript / submitVoiceRun` cannot express this, return a feature-local `HermesVoiceRunHandle` from start and require it at stage/submit; retain connection generation privately and update production, `test/features/hermes_chat/support/fake_hermes_channel.dart`, and `integration_test/support/hermes_voice_smoke_harness.dart`.
- [ ] Increment conversation epoch synchronously on ownership changes, before awaiting teardown. Propagate through capture/send/reply/playback/rearm. Preserve bounded teardown and adapter cancellation generations.
- [ ] Verify failure, denied permission, absent synthesis capability, and interrupted shutdown leave usable text input and bounded safe errors. Do not automatically resume the microphone after backgrounding.
- [ ] Close capture-provider ownership: make `SpeechToTextVoiceCaptureService` implement idempotent `VoiceCaptureLifecycleService.dispose()`, invalidate completion identity before awaiting teardown, detach callbacks, and close owned streams. Register `ref.onDispose` where `hermes_chat_screen.dart:76-85` creates the service. Test disposal while readiness/capture/language replacement is pending and reject every late callback.
- [ ] Run `flutter test test/features/hermes_chat/voice test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart`.

## Task 2: Separate mute, pause, and confirmed interruption

**Files:** inspect/modify the controller above, `lib/features/settings/providers/voice_settings_provider.dart`, `lib/features/settings/screens/settings_voice_screen.dart`, `lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart`, and `lib/l10n/app_en.arb`. Tests: controller/lifecycle tests above and `test/features/settings/settings_voice_screen_test.dart`.

**Interfaces:** Reuse existing settings where they represent input pause/output mute. Confirmed barge-in invalidates playback and stops local output, then requests the existing exact-scoped Agent interruption for the captured run. Never interrupt whichever session happens to be selected later.

- [ ] Add cases for mute during speech, microphone pause during capture, explicit Stop during teardown, and repeated interruption. Muting must not start capture; input pause must not redefine output preference.
- [ ] Prove local playback stops even when Agent interruption times out or lacks permission. Expose that Agent work may still run and retain detached-run reconciliation; never falsely report cancellation.
- [ ] Replace parameterless, fire-and-forget voice barge targeting with an awaitable expected identity carrying originating profile, session, backend run ID when known, and local stream generation. Stop local playback first; request interruption only for that captured active turn; await stop success/failure before submitting a replacement voice run. Update all three channel implementations and test mismatch, duplicate stop, terminal-before-stop, timeout, and stop-before-resubmit ordering.
- [ ] Treat sound level or a timer as insufficient proof of barge-in. Wire automatic interruption only if the existing adapter supplies reviewed evidence; otherwise retain accessible Stop and mark automatic barge-in unqualified.
- [ ] Reuse current timeout bounds; document utterance/silence limits only when the adapter supports them. Add no pretend controls for unsupported limits.
- [ ] Localize independent controls. Test keyboard, semantics, 200% text, and reduced motion without sound/color-only state.
- [ ] Run `flutter gen-l10n`, `flutter analyze`, and `flutter test test/features/hermes_chat/voice test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart test/features/settings/settings_voice_screen_test.dart`.

## Task 3: Qualify the exact artifact on physical hardware

**Files:** update `docs/runbooks/android/live-mic-smoke.md`, `docs/quality/evidence-matrix.md`, and, through the [release plan](2026-09-04-release-evidence.md), `scripts/record_android_live_mic_receipt.sh`.

**Interfaces:** Receipts reference artifact SHA-256, source/build identity, OS/device class, actual audio route, scenario outcomes, and limitations. Keep serials, endpoints, spoken phrases, and transcript content out of published receipts.

- [ ] Execute the runbook on physical Android for built-in mic/speaker, wired and Bluetooth routes where supported, permission revoke, background/foreground, screen lock, route loss, and sustained use. Record unsupported routes separately from failures.
- [ ] Observe playback during user speech, interruption latency, accidental self-triggering, and recovery. Never infer AEC or double-talk success from synthetic tests. Missing physical targets remain unverified.
- [ ] Attach exact-artifact receipts after Release Tasks 1–2. A harness build and production APK are different artifacts; qualify only what was exercised.
- [ ] Run `dart run scripts/check_evidence_matrix.dart` and `git diff --check` after updating the ledger. Broader claims require additional named-platform receipts.

## Completion

Controller regressions can close deterministic work independently of physical
qualification. Keep the statuses separate in the [program](2026-09-04-conduit-adaptation-roadmap.md).
No physical or automated voice tests were run while writing this plan.

## Execution receipt — 2026-09-04

Task 1 deterministic slice implemented: controller-owned channel listener and
conversation epoch fence profile/session/origin changes (including A → B → A),
capture completion, partials, levels, playback, and delayed rearm. Pause/dispose
invalidate synchronously. API staging retains opaque voice IDs with bounded
private ownership records and rechecks after deferred send admission. A profile
replacement retires local voice entries; a session-only replacement retains a
failed entry. Both paths dispatch zero HTTP for stale staging.

Voice submission captures its actual local assistant turn; speech selects only
that submission's identity. The production lookup also rejects same-ID reuse
with a different creation timestamp. Canonical replacement without a reliable
mapping fails closed and may suppress automatic speech; explicit read aloud is
still available. No Agent run/message ID is invented. Direct text
`speakNextReply()` remains separate and is not a fully run-owned API.

SpeechToTextVoiceCaptureService now implements idempotent lifecycle disposal,
invalidates recognition callbacks before teardown, rejects capture after disposal,
and closes owned streams. Plugin sound callbacks cannot add after closure.
Tests cover disposal while readiness and capture are pending, late result/status/
error/level callbacks, profile roundtrip, replacement channel with the same
session, and an unrelated newer assistant reply.

Task 2 deterministic slice: immutable interruption targets bind channel,
connection generation, profile, session, stream generation, and backend run when
known. `stopTurn` validates the captured target and awaits the existing stop
operation. Replacement voice submission waits for confirmation with a bounded
timeout; failure preserves the possibility that Agent work still runs. Independent
`muteOutput`, `unmuteOutput`, and `pauseMicrophone` APIs do not rewrite persisted
preferences; root integration owns their localized UI. Partial recognition still
heuristically stops local output: reviewed automatic acoustic interruption and
the full duplicate/terminal/timeout interruption matrix remain open.

Validation:

- `flutter test test/features/hermes_chat/voice test/features/voice/services/speech/speech_to_text_voice_capture_service_test.dart --reporter expanded`: 114 passed.
- `flutter test test/core/hermes/channel/hermes_api_channel_test.dart --plain-name voice --reporter expanded`: 11 passed.
- Changed Dart files formatted; targeted analyzer clean for controller, speech
  service, and provider sheets. Full analyzer/lifecycle integration is recorded
  by the program owner.
- `dart run scripts/check_evidence_matrix.dart`: PASS, 20 rows.
- `git diff --check`: passed.

Task 3 remains unverified: no physical Android, wired/Bluetooth route, microphone,
AEC, barge-in, battery, thermal, or exact-artifact voice receipt was exercised.
The live-mic runbook now names the changed ownership scenarios. Existing ledger
classifications were not promoted. No commits or external actions performed.
