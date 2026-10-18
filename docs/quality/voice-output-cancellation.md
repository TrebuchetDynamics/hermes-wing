# Speech-output cancellation during pending configuration

Task: `DOC-VOICE-OUTPUT-CANCEL-EVIDENCE`. **Offline preparation only;
physical/acoustic qualification NOT_CHECKED.** Source inspected at
`2ddbb51b69044c71411e32168750a9a92db4c731` (`git rev-parse HEAD`). No engine was
invoked, device selected, playback/capture performed or live receipt created.
This page neither repairs TTS nor closes VOICE or official Desktop parity.

Start with the [capture preparation's remaining output gap](voice-capture-qualification.md#remaining-named-target-qualification)
and the [microphone ownership runbook](../runbooks/android/live-mic-smoke.md#conversation-ownership-qualification-2026-09-04).
This is the distinct output-only successor: cancellation before the first device
utterance, not capture → reviewed draft → Send, provider reply or re-arm.
Scope follows [VOICE journeys](../product/prd.md#core-journeys) and the
[accepted port roadmap](../../ROADMAP.md#flutter-port-execution-roadmap).

## Planned target and engine — not selected or observed

- **Target class:** physical Android, built-in speaker only. Model, Android
  version/API and installed artifact remain unselected; no device discovery is
  authorized by this preparation. No wired/Bluetooth or other platform claim.
- **Planned client engine path:** `PlatformTextToSpeechService` →
  [`flutter_tts 4.2.5`](../../pubspec.lock#L392) → Android's effective system TTS
  engine. The actual engine package/version, voice, locale and any network-backed
  processing are **unknown** until separately approved target inspection. Do not
  substitute the plugin version or assume a particular vendor engine/offline use.
- **Selection gate:** [`hermes_chat_screen.dart:131–154`](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart#L131)
  prefers Agent synthesis when the channel implements `HermesAudioChannel` and
  policy permits synthesis. Android otherwise selects platform TTS. Confirm this
  actual path without withdrawing capabilities or changing Agent configuration to
  force it. If Agent synthesis is selected, this platform-configuration scenario
  is NOT_CHECKED, not an Agent-path pass.

## Current-source trace and existing oracles

Line references below are bound to the inspected revision. Tests were read, not
executed here; their assertions are existing deterministic oracles, not acoustic
observations or fresh passing results.

| Boundary | Source / existing assertion | Limit for this scenario |
| --- | --- | --- |
| Pending platform configuration | [`platform_text_to_speech_service.dart:18–33`](../../lib/features/voice/services/tts/platform_text_to_speech_service.dart#L18) lazily creates an engine, awaits `awaitSpeakCompletion(true)`, marks configured, then calls `_tts.speak`. | No generation/disposed check between the configuration await and the speak call. |
| Stop and disposal | Same service [`36–45`](../../lib/features/voice/services/tts/platform_text_to_speech_service.dart#L36): `stop` calls the existing engine; `dispose` awaits stop and clears `_engine`. | Neither invalidates the pending `speak` continuation. Neither cancels the configuration future. |
| Platform tests | [`platform_text_to_speech_service_test.dart:13–40`](../../test/features/voice/services/tts/platform_text_to_speech_service_test.dart#L13) checks rejection (`0`) and one configuration followed by two successful chunks through a mocked method channel. | No held configuration future, explicit stop/disposal ordering or no-late-speak assertion. |
| Controller cancellation | [`readAloud:237–294`](../../lib/features/hermes_chat/voice/hermes_voice_input_controller.dart#L237) captures the service and checks speech generation around awaited chunks. [`stopSpeaking` / `_interruptActiveSpeech:840–867`](../../lib/features/hermes_chat/voice/hermes_voice_input_controller.dart#L840) invalidates generation and awaits captured-service stop. [`pause:957–999`](../../lib/features/hermes_chat/voice/hermes_voice_input_controller.dart#L957) and [`dispose:1002–1032`](../../lib/features/hermes_chat/voice/hermes_voice_input_controller.dart#L1002) also invalidate ownership and request cleanup. | These fences reject subsequent controller work; they cannot prevent a late platform call *inside* the already awaited `tts.speak`. Controller disposal requests service stop, not service disposal. |
| Controller oracles | [`hermes_voice_input_controller_test.dart:354–378`](../../test/features/hermes_chat/voice/hermes_voice_input_controller_test.dart#L354) checks read-aloud stop and source-message clearing; [`171–200`](../../test/features/hermes_chat/voice/hermes_voice_input_controller_test.dart#L171) checks independent output mute. [`632–724`](../../test/features/hermes_chat/voice/hermes_voice_input_controller_test.dart#L632) checks slow/hung/failed TTS teardown; [`1799–1829`](../../test/features/hermes_chat/voice/hermes_voice_input_controller_test.dart#L1799) checks cleanup despite synchronous throws. | Fake TTS services do not exercise platform initialization or prove silence. Output mute intentionally leaves active capture alone; it is not a microphone pause. |
| Provider lifecycle oracles | [`hermes_tts_provider_test.dart:22–137`](../../test/features/hermes_chat/providers/hermes_tts_provider_test.dart#L22) checks Agent/fallback selection, scopes and profile context; [`170–236`](../../test/features/hermes_chat/providers/hermes_tts_provider_test.dart#L170) checks disposal on withdrawal and reporting teardown errors. The provider registers disposal for either engine path. | Disposal assertions use a recording Agent fake, not platform configuration held across disposal. |
| Separate Agent engine | [`hermes_agent_text_to_speech_service.dart:50–100`](../../lib/features/voice/services/tts/hermes_agent_text_to_speech_service.dart#L50) checks generation after synthesis and after playback teardown; stop increments it and dispose calls stop. [`hermes_agent_text_to_speech_service_test.dart:28–75`](../../test/features/voice/services/tts/hermes_agent_text_to_speech_service_test.dart#L28) checks interrupted callers and a delayed predecessor completion not finishing its replacement. | That late-player oracle is not pending platform configuration, nor a test of stop/dispose while Agent synthesis itself is pending. Do not transfer it across engines. |

**Source-exposed risk, not a reproduced failure:** if configuration resolves only
*after stop has returned*, the platform continuation can still call `speak` on the
same engine. If it resolves only *after dispose has returned*, `_engine` is null
and `_tts` can create a new engine and call `speak`; `_configured` is then true.
No runtime trace or audible leak was collected. A successful stop return, cleared
UI or controller-generation fence alone is not a no-late-audio oracle.

## One prepared scenario: cancel first utterance before configuration completes

All steps below are **planned, not executed**. Stop and disposal are termination
variants of the same pending-configuration ordering, not evidence for other voice
journeys.

### Missing deterministic proof — separately scoped work

At the platform service's public `speak` / `stop` / `dispose` seam, hold the mocked
`awaitSpeakCompletion` result for the first non-empty utterance. Wait until that
call is pending, then terminate via `stop`; in the disposal variant use a fresh
service and `dispose`. Allow termination to finish **before** resolving the held
configuration. Then release configuration and drain the original caller.

Expected oracle: no subsequent `speak` method call for the cancelled utterance,
no engine recreation after disposal, no stranded caller once configuration
settles, and no stale completion affecting a later explicitly requested utterance.
Any recovery check uses a fresh owner after disposal, not the disposed service.
These assertions are **missing**, not new tests added or passing checks. No
implementation or deterministic test is changed by this preparation. Scope any
future repair/proof independently; this page does not assert current code meets
the expectation.

### Future named-target observation — separately authorized

1. Obtain explicit approval for the physical QA target/artifact and audible
   playback, including bystander/content consent and any engine network
   processing. Keep hands-free/capture and completion sounds off; use an idle,
   reconciled QA conversation with harmless existing assistant text, no active
   run or queued send. Confirm Agent/profile/session locally without exporting
   their identities. Text/keyboard operation must remain available.
2. Record the actual device model, Android version/API, engine package/version,
   effective voice/locale, built-in speaker route, installed APK SHA-256,
   source/build/version and QA-harness versus production identity. Unknown engine
   selection/version leaves engine qualification open. Never equate checkout HEAD
   with installed APK identity or replace a paired app to obtain evidence.
3. With a fresh service, explicitly request **Read aloud**, then **Stop speaking**
   while first configuration is demonstrably pending. The UI wiring is at
   [`layout:1564–1576`](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart#L1564)
   and [`3050–3057`](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart#L3050).
   A speaking indicator alone does not establish the native configuration window.
   If that ordering cannot be established safely on the unchanged artifact, mark
   pending-configuration cancellation NOT_CHECKED; do not add a delay/hook or
   relabel cancellation after audible onset as this scenario. A disposal variant
   needs separate approved lifecycle execution and evidence of actual service
   disposal; do not assume backgrounding disposes the provider.
4. After the pending operation actually settles, expect **no late audible onset,
   resumed chunk or replay** from the cancelled utterance; no automatic capture,
   re-arm or Send; readable reply and retained draft; and no stale callback
   altering a later explicit read-aloud request. Record the observation window
   and whether settlement was established. A bounded quiet wait without known
   settlement is NOT_CHECKED, not proof that audio can never arrive. Local output
   cancellation is not authoritative Agent Stop or provider-run cancellation.
5. If late audio, teardown failure or privacy exposure occurs, stop the scenario
   and record a categorical failure, not a retry/pass. Review only bounded local
   diagnostics for content leakage; export no audio, text, screenshots or raw logs.

## Sanitized worksheet and receipt boundary

Blank planning fields below are **not observations**, a new machine schema or
release-aggregator input. Use PASS / FAIL / NOT_CHECKED / UNSUPPORTED separately;
unsupported is not pass.

| Future record | Allowed bounded metadata |
| --- | --- |
| Authorization and identity | Non-sensitive consent reference; artifact digest/source/build/version and harness versus production; target class/model and Android API; no serials, fingerprints, host paths or private endpoints |
| Actual output path | Platform versus Agent; effective engine package/version, voice/locale, built-in speaker route; unknowns explicit |
| Ordering | UTC time; stop versus disposal; configuration pending established, termination finished, late configuration settled and observation window; each true/false/NOT_CHECKED |
| Outcome | Late audio absent, stale callback rejected, reply/draft preserved, zero capture/re-arm/sends, explicit recovery, diagnostic privacy; per-item status and sanitized limitation category |

The sanitized [recorder source:8–20,53–78](../../scripts/record_release_qualification.mjs#L8)
and [receipt fixture assertions:32–63](../../test/tooling/record_release_qualification_test.mjs#L32)
were inspected, not run. They bind installed bytes/version/build and omit private
inputs; they do **not** contain pending-configuration cancellation, actual engine
identity or no-late-audio observations. The fixture is not a real receipt. No
existing sanitized live cancellation receipt was identified in the tracked paths.

This output-only scenario cannot satisfy `physical-voice` (physical mic, provider
reply, TTS, distinct re-armed turn and privacy gates) or `server-audio` (Agent
transport/provider/playback/round-trip gates; local-TTS-only forbidden). Do not set
those flags from silence or this preparation. Preserve the runbook's installed
artifact/manifest binding for future release qualification, independently of this
worksheet. Do not run `android:live-mic-prep`, either recorder, engine discovery,
playback or capture for this task; the prep helper installs, grants permission
and launches, and the legacy recorder accepts content/private metadata.

## Remaining qualification and update triggers

Pending: deterministic stop/dispose-during-configuration oracle; separately
approved actual-engine/installed-artifact and physical no-late-audio observation.
No target, engine, OS or route is qualified here. Wired/Bluetooth, route loss,
screen lock, background/foreground, sustained use, ownership roundtrips, failed
Agent Stop, hands-free/re-arm, AEC, double-talk, speaker self-triggering and
interruption latency remain separate runbook cells. Compilation and mocked
completion do not close them.

Revisit when platform configuration/stop/disposal, controller generation/teardown,
provider selection/disposal, plugin version, UI cancellation or receipt gates
change. Documentation validation is local links/source references and
`git diff --check`; no Dart behavior or fixture changed and no tests were added.
