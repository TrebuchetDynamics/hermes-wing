# Physical capture → reviewed draft → explicit Send

Task: `DOC-VOICE-QUALIFICATION`. **Offline preparation only; physical qualification
NOT_CHECKED.** Source reviewed at
`c147db8878e14cd7e57b3bcee50dea9c656e7efc`. No device was selected or operated,
no audio recorded, no recognized words collected, and no observation receipt
created. This page does not close VOICE acceptance or establish Desktop parity.

Start with the [microphone runbook](../runbooks/android/live-mic-smoke.md), but
use the draft entry below for this bounded scenario. The
[ownership plan](../superpowers/plans/2026-09-04-voice-ownership.md) is historical;
[current dictation evidence](chat-direct-dictation.md) covers deterministic UI
behavior, not physical speech.

## Current-source ownership map

Paths and line ranges below refer to the reviewed source revision, not a built APK.

| Boundary | Live source and expected behavior |
| --- | --- |
| Device capture selection | [`hermes_chat_screen.dart:91–111`](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart#L91) creates the default service using the selected language and disposes it on provider replacement. [`default_voice_capture_service.dart:17–46`](../../lib/features/voice/services/platform/default_voice_capture_service.dart#L17) selects platform speech on Android/iOS/macOS, not Linux/Windows/web. This scenario selects physical Android only. |
| Recognizer readiness | [`device_speech_recognition_availability.dart:87–129`](../../lib/features/voice/services/platform/device_speech_recognition_availability.dart#L87) requires a recognition service and on-device availability on Android. The factory lets initialization request microphone permission; readiness alone is not capture consent or spoken-audio proof. |
| Draft versus hands-free | [`hermes_chat_layout.dart:2674–2733`](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart#L2674) exposes **Dictate a draft** in the composer menu. The wide direct button and cancel guard are at [`3027–3061`](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart#L3027). The primary mic tap enables hands-free; its long press dictates (`2940–3000`). Do not use a primary mic tap for this scenario. |
| No submission on recognition | [`HermesVoiceInputController.captureDraft:215–216`](../../lib/features/hermes_chat/voice/hermes_voice_input_controller.dart#L215) selects `autoSend: false`; the completion branch at [`558–565`](../../lib/features/hermes_chat/voice/hermes_voice_input_controller.dart#L558) calls `onDraft`, not voice submission. [`_appendVoiceDraft:792–803`](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart#L792) appends to existing composer text. |
| Cancellation and stale ownership | The controller checks channel/origin/profile/session plus the caller guard at [`175–216`](../../lib/features/hermes_chat/voice/hermes_voice_input_controller.dart#L175). [`pause:911–954`](../../lib/features/hermes_chat/voice/hermes_voice_input_controller.dart#L911) invalidates generations before teardown and clears partials/levels. Draft failure waits on cancellation before a fresh retry (`459–469`). Backgrounding calls pause; resume reconnects but does not start capture ([`screen:769–785`](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart#L769)). |
| Explicit Send | The Send button calls `_sendComposerText` ([`layout:3064–3075`](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart#L3064)). [`hermes_chat_message_flow.dart:25–85`](../../lib/features/hermes_chat/composer/hermes_chat_message_flow.dart#L25) handles submission; [`402–463`](../../lib/features/hermes_chat/composer/hermes_chat_message_flow.dart#L402) calls the current channel's `sendText`. Use an idle session: active-run steering/queued follow-ups are different branches and are excluded here. |
| Speech provenance and diagnostics | [`speech_to_text_voice_capture_service.dart:215–223`](../../lib/features/voice/services/speech/speech_to_text_voice_capture_service.dart#L215) identifies platform speech via `speech_to_text 7.4.0`, requests on-device recognition and claims no app-owned model. Result diagnostics log length/confidence/finality (`612–626`); returned audio is empty (`690–695`), so this default draft path does not supply PCM for Agent transcription. This does **not** prove the OS recognizer's network/privacy behavior. |

Existing deterministic cases locate the offline oracles; they are not new physical
observations:

- [`hermes_voice_input_controller_test.dart:189–216`](../../test/features/hermes_chat/voice/hermes_voice_input_controller_test.dart#L189): draft completion without messages or voice runs;
  [`411–439`](../../test/features/hermes_chat/voice/hermes_voice_input_controller_test.dart#L411): cancel drops late recognition;
  [`113–138`](../../test/features/hermes_chat/voice/hermes_voice_input_controller_test.dart#L113): profile A → B → A discards capture.
- [`speech_to_text_voice_capture_service_test.dart:10–51`](../../test/features/voice/services/speech/speech_to_text_voice_capture_service_test.dart#L10): silence and final-result ordering;
  [`129–146`](../../test/features/voice/services/speech/speech_to_text_voice_capture_service_test.dart#L129): recognized words absent from normal result diagnostics.

## Execution gates — all still pending

Before **any** install, permission change, capture or live Send, obtain the
separately approved physical Android target, capture consent, isolated QA Agent
session/authentication and provider budget. Existing owner deferrals and access
limits remain in force. Confirm that consent covers OS recognizer processing,
permission denial/revoke testing and sending reviewed text to Agent/provider;
otherwise leave the corresponding step NOT_CHECKED.

Name the actual device manufacturer/model, Android version/API, recognizer
package/version and effective recognition locale (including the resolved locale
when using system default). List available recognizer services separately from
the one actually selected; if selection/version cannot be established, record
unknown and leave recognizer qualification open. Record the built-in microphone
route, exact installed APK SHA-256, source commit, build/version and whether it is
a QA harness or production artifact. Never substitute this source revision for
an installed-artifact identity. Keep serials and private connection identities
out of the shared record. Review exact Agent/profile/session ownership locally.

Do **not** run `npm run android:live-mic-prep` as an offline check: it builds,
installs, grants microphone permission and launches the app. Do not execute either
receipt recorder now. Approval to prepare this page authorizes none of those acts.

## One bounded scenario with cancellation and failure branches

All expected outcomes below are **unobserved**. Use the same named target,
recognizer, locale, installed artifact and built-in mic for each approved branch.
Disable hands-free, spoken replies and completion sounds for this input-only
scenario. Start in a connected, idle, reconciled QA session, with no attachment,
queued follow-up or active run. Keep a harmless typed draft to check preservation.

1. **Capture and review.** Choose **Dictate a draft** in the composer menu (or the
   wide direct action), not the primary hands-free mic. Speak a harmless,
   non-command phrase chosen locally after consent. Do not type, inject, generate
   or play host audio as a substitute for speech into the physical mic. Observe
   actual recognition, one append after completion and hands-free still off.
   Review/edit the draft on-device; verify zero chat submission before Send.
   Record only whether capture, append and review occurred, never the words.
2. **Explicit Send.** Reconfirm the same Agent/profile/session locally, then tap
   Send once. Observe exactly one user turn and its authoritative outcome in the
   intended QA conversation, with no second capture or replay. Record provider
   reply as a separate observation, not something inferred from recognition or a
   locally staged bubble. If transport fails or ownership changes, stop and
   record that outcome; do not silently retry, reconnect-and-send or switch owners.
3. **Cancel before completion.** With no active run, start fresh draft dictation,
   then cancel while recognition is pending. On wide UI use **Cancel draft
   dictation**; compact UI uses the active mic's pause action. Expect the previous
   draft unchanged, no late append, no Send, and no automatic capture. Only after
   teardown, explicitly retry and cancel again to observe recovery. Do not call
   local capture cancellation an Agent Stop or proof of server interruption.
4. **Failure without Send.** Under separately approved permission testing, deny
   or revoke microphone access on the isolated QA app, then explicitly attempt
   dictation. Expect an unavailable/permission notice, preserved typed draft and
   usable text input, no submission and no automatic retry. Also attempt a silent
   capture if approved: no speech should finish as no-transcript/timeout feedback,
   not an empty sent turn. Record actual category, including an unexpected one;
   restore permissions only if separately authorized. Fresh capture recovery
   requires another explicit user action and successful teardown.
5. **Privacy review.** Inspect the bounded relevant app diagnostics locally for
   recognized words after capture, cancellation and failure. Do not attach raw
   logs, screenshots, audio, phrases, transcript hashes or provider excerpts.
   Normal-result tests do not prove all error paths safe: the
   [coordinator's error diagnostics](../../lib/features/voice/services/speech/speech_to_text_capture_coordinator.dart#L76)
   stringify errors, and permission/locale probes also log errors
   ([`service:740–767`](../../lib/features/voice/services/speech/speech_to_text_voice_capture_service.dart#L740)).
   Treat absence of recognized words as an observation to verify, not a blanket
   source guarantee. If content appears, stop evidence export, mark privacy FAIL
   without copying it, and route remediation through a separately scoped task.

## Sanitized observation worksheet — blank, not a receipt

After approved execution, retain only bounded metadata and categorical outcomes.
Use PASS, FAIL, NOT_CHECKED or UNSUPPORTED per branch; UNSUPPORTED is not PASS.
No field below has an observed value yet.

| Field | Required future value |
| --- | --- |
| Authorization | Non-sensitive approval reference and consent scope; no personal identifiers |
| Artifact | Installed APK digest, source/build/version, QA harness versus production |
| Target | Device model/class, Android version/API; no serial, fingerprint or host path |
| Recognition | Actual recognizer package/version, effective locale, built-in mic route; unknowns explicit |
| Observation | UTC time and scenario branch; capture/review/explicit-send booleans or NOT_CHECKED |
| Cancel | Actual cancel, draft preserved, late append absent, zero sends, explicit recovery outcomes |
| Failure | Actual permission/no-speech/timeout/unavailable category, text operability, zero sends |
| Privacy | Recognized words absent from checked diagnostics: true/false/NOT_CHECKED; no log attachment |
| Result and limits | Per-branch status, provider observation separately, sanitized limitation categories |

This worksheet is **not** a new machine receipt schema or release-aggregator
input. A capture-only run cannot satisfy the existing sanitized recorder's
`physical-voice` gates: [`record_release_qualification.mjs:8–14,53–73`](../../scripts/record_release_qualification.mjs#L8)
requires provider reply, TTS, re-arm and a distinct re-armed turn as well as physical
mic/privacy observations. Do not set those flags from this scenario. The runbook's
legacy receipt command accepts spoken/provider excerpts; do not use it for this
content-free task. Exact-artifact release qualification needs its existing manifest
binding and all separately authorized observations, not this worksheet.

## Remaining named-target qualification

Physical capture/cancel/failure, actual recognizer/language and diagnostic privacy
remain NOT_CHECKED until the gates above are met. Output engine cancellation,
TTS/provider reply, hands-free/re-arm and acoustic checks remain separate: name
their actual target, engine and route before execution. The
[output-cancellation preparation](voice-output-cancellation.md) traces one pending
platform-configuration scenario and its missing deterministic oracle; it is not
physical or acoustic qualification. Wired/Bluetooth, route
loss, screen lock, sustained use, speaker self-triggering, echo cancellation,
double-talk and interruption latency are not inferred from built-in input,
synthetic tests or web compilation. The runbook's broader ownership matrix
(profile roundtrip, cross-gateway identity, late callbacks, failed Agent Stop)
also remains unqualified on hardware. No support claim extends to another device,
locale, route, platform or artifact.

Revisit this page when draft entry/cancel/Send wiring, conversation ownership,
recognizer selection/language, diagnostic formatting or receipt gates change.
Documentation-only validation checks local links/source ranges and whitespace;
no preparation fixtures or runtime behavior were changed, so no new tests are
required by this task's conditional fixture check.
