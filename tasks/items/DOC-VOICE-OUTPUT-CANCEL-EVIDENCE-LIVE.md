+++
schema = 1
id = "DOC-VOICE-OUTPUT-CANCEL-EVIDENCE-LIVE"
title = "Live checks for DOC-VOICE-OUTPUT-CANCEL-EVIDENCE"
short = "Live checks for DOC-VOICE-OUTPUT-CANCEL-EVIDENCE"
status = "done"
goal = "VOICE"
section = "Needs decision"
rank = 61000
depends_on = ["DOC-VOICE-OUTPUT-CANCEL-EVIDENCE"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Run the live checks the offline work for DOC-VOICE-OUTPUT-CANCEL-EVIDENCE left pending."
acceptance = ["Each check passes on the real target: - Separately authorize and identify a physical Android QA target, exact installed APK/source/build, built-in speaker route, effective system TTS package/version and voice/locale, including playback/bystander/content and network-processing consent. No target or actual engine was selected here. - On that approved artifact, establish the pending-configuration ordering and actual settlement for stop/disposal, then observe no late audio, replay or stale callback; verify retained text/draft, zero automatic capture/re-arm/sends and bounded diagnostic privacy. If ordering cannot be established on the unchanged artifact, leave that branch NOT_CHECKED. No physical or acoustic acceptance is claimed."]
checks = ["Live qualification by an authorized person; offline evidence does not count."]
exclusions = []
closure = "manual"
closure_actor = "xel"
closure_timestamp = "2026-10-22T12:20:06.210786+00:00"
closure_reason = "2026-10-22 owner decision: waived this auto-generated live follow-up to clear the owner queue. The parent task's offline acceptance remains; live evidence was not produced and is not claimed. Reopen if an authorized live window becomes available."
+++

- Sources: [existing goal authority](docs/product/prd.md#core-journeys), [retained parent and qualifications](todo.archive.md).
- Touches: none before conversion; ** stands for the whole repository

## Completed offline cancellation correction

- Reproduced both pending-configuration races with a delayed platform-channel
  response: `speak` was called after `stop` and after `dispose`. Both regressions
  failed on the original implementation.
- Added a cancellation generation and terminal disposal fence. A cancelled
  configuration cannot submit speech or recreate a disposed engine; an explicit
  new utterance after Stop still works. No Agent contract/state changed.
- Flutter 3.44.9: `flutter test --no-pub --concurrency=1 test/features/voice/services/tts test/features/hermes_chat/voice test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart`
  passed all 136 tests; `flutter analyze --no-pub` passed. Platform responses were
  deterministic mocks, not physical audio.
- Do not repeat the offline implementation. The original physical/acoustic
  acceptance remains open and requires matching target/engine evidence.
