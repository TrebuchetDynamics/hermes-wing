# Hermes companion readiness audit

Last updated: 2026-07-05.

This audit maps the current pure-Hermes Navivox companion goal to concrete
evidence and remaining blockers. It is intentionally conservative: a passing
test only counts for the behavior it directly exercises. For a quick read-only
local snapshot, run `npm run hermes:readiness-audit`; that helper prints every
explicit external or deferred blocker but is not a completion receipt.

## Success criteria and evidence

| Requirement | Current evidence | Status |
| --- | --- | --- |
| Provider-backed Hermes chat smoke with real model/provider credentials | `npm run hermes:provider-smoke:local` writes `build/receipts/hermes-provider-smoke.json` after a no-retry Playwright pass against a configured local Hermes home. The receipt is bound to the current `head_sha`, records a sanitized origin-only `base_url`, includes `evidence_for` entries for `provider-backed Hermes typed text turn` and `deterministic transcript voice turn`, and includes `not_evidence_for` caveats for physical Android mic, Hermes realtime/server audio, native-host receipts, platform workflow publication, deferred parity, and whole-goal completion. | Covered for configured local Hermes text. |
| Provider-backed Hermes voice smoke | Same provider smoke submits a deterministic device transcript via `navivoxE2EHermesSubmitVoice` and verifies a model reply. The helper caveat says this is deterministic transcript voice only, not physical microphone evidence or Hermes realtime/server audio, and the readiness audit rejects stale/malformed provider receipts. | Covered for transcript voice only; not physical mic or server audio. |
| Android speech/mic readiness | `npm run android:voice-smoke` passed on a KVM-backed `fractal_test` emulator on 2026-07-03, verifying speech recognizer availability and granted mic permission. `NAVIVOX_ANDROID_SKIP_BUILD=1 NAVIVOX_ANDROID_HERMES_URL=http://10.0.2.2:8642 npm run android:live-mic-prep` also installed/launched/granted mic permission on `fractal_test`. A later direct target recheck showed `adb devices` had no attached Android devices while `flutter devices` listed only Linux desktop and Chrome web. The canonical manual physical-audio checklist is `docs/runbooks/android/live-mic-smoke.md`. | Readiness/prep covered; real spoken audio not covered. |
| Android automated voice loop | `npm run android:hermes-voice-loop-smoke` writes `build/receipts/android-hermes-voice-loop-smoke.json` after an Android integration test runs `HermesChatScreen` with deterministic transcript capture, fake Hermes channel/provider replies, fake TTS, and a distinct second turn after continuous-voice re-arm. The receipt is bound to current `HEAD` and records Android device properties. | Covered for no-human Android Flutter voice-loop mechanics; explicitly not physical mic/provider/server-audio evidence. |
| Android debug APK build | `flutter build apk --debug` produces `build/app/outputs/flutter-apk/app-debug.apk`; `npm run hermes:readiness-audit` prints the current APK SHA-256 when present. App-scoped native units also passed with `cd android && ./gradlew :app:testDebugUnitTest`. | Covered locally for build/native units and artifact identity only; not physical mic evidence. |
| Linux release build | `npm run linux:release-build` passed on 2026-07-03 and produced executable `build/linux/x64/release/bundle/navivox`. | Covered locally. |
| Windows build | `build/receipts/hermes-platform-workflow.json` records the watched current-head GitHub run id with a successful `Windows desktop build` job and non-expired `navivox-windows-debug-bundle` artifact. | Covered by hosted native-runner receipt. |
| iOS simulator build | `build/receipts/hermes-platform-workflow.json` records a successful `iOS simulator build` job and non-expired `navivox-ios-simulator-app` artifact. | Covered by hosted native-runner receipt. |
| macOS desktop build | `build/receipts/hermes-platform-workflow.json` records a successful `macOS desktop build` job and non-expired `navivox-macos-debug-app` artifact. | Covered by hosted native-runner receipt. |
| Browser fake Hermes smoke | Focused Playwright regression rerun of `navivox-e2e.spec.mjs` plus `hermes-smoke.spec.mjs` passed on 2026-07-03 against `node serve_web.mjs` with 68 Chromium tests after a longer-timeout rerun; the focused Hermes smoke itself passed 2 Chromium tests and covers fake Hermes health/capabilities/sessions/runs/events/approvals/tool progress/stop. | Covered for fake server. |
| Installed Hermes API connect smoke | `npm run hermes:live-smoke` passed on 2026-07-03 against installed local Hermes with isolated temp home and no provider credentials; Playwright reported 1 pass. The helper caveat says this is API connect/session rendering only, not provider/model evidence, not chat/voice provider smoke, not physical microphone evidence, and not whole-goal completion evidence by itself. | Covered for live connect/session surface. |
| Deferred server realtime audio honesty | `lib/core/hermes/policy/hermes_surface_readiness.dart` marks advertised-but-unwired server realtime voice/audio as blocked and unadvertised server audio as deferred; README states voice is local-first. | Covered by code/docs. |
| Deferred config admin honesty | Surface readiness marks config editing/admin as `deferred`; the surface-readiness dialog repeats that no mobile config mutation controls are enabled. | Covered by code/docs. |
| Deferred memory UI honesty | Hermes surface readiness marks Memory UI as `deferred`; the surface-readiness dialog repeats that no mobile memory mutation controls are enabled. | Covered by code/docs. |
| Jobs/schedules | `GET /api/jobs` is implemented as read-only inventory; surface readiness separates jobs/schedules inventory (`readOnly`) from jobs/schedules admin (`deferred`), and the surface-readiness dialog keeps schedule mutation controls disabled. | Read-only inventory covered; admin deferred. |
| Messaging gateways, persona/SOUL, attachments, files/context folders | Surface readiness marks each as deferred with explicit copy; the surface-readiness dialog covers gateways/persona without mutation controls, and the chat composer exposes safe status sheets for attachments/media and files/context folders without upload controls. | Covered as deferred, not implemented. |
| Diagnostics/log export | Bounded diagnostics export exists and explicitly labels secrets, raw logs, tool payloads, transcripts, and local paths as excluded; surface readiness separately marks raw diagnostics/log export as `deferred`. The diagnostics test seeds transcript and raw tool-payload content and asserts the export reports only counts/statuses plus the explicit `device STT -> Hermes text; server audio not wired` voice boundary. | Bounded diagnostics covered; raw logs/payloads deferred. |
| Multi-endpoint/profile management | `HermesEndpointStore`/`SecureHermesEndpointStore` now support saved endpoint profiles; the connect form saves an optional redacted profile label, renders selectable/renamable/deletable profile chips, clears stale profile secrets/labels when using presets, and keeps per-profile API keys in secure storage. | Covered locally. |
| Secret hygiene for Hermes diagnostics | `test/features/hermes_chat/screens/hermes_chat_screen_test.dart` asserts diagnostics include `Secrets: excluded`, omit `Authorization`, fake transcript tokens, and raw tool payload markers, and redact dynamic metadata fields such as active session title, health strings, capability model/features/endpoints, and model names. | Covered for diagnostics export. |
| Overall Dart/widget regression | `flutter test --concurrency=1` passed on 2026-07-03 with 1016 tests after the latest diagnostics, workflow, docs, and readiness-guard changes. | Covered locally, but does not replace device/host receipts. |
| Static analysis | `flutter analyze` passed with no issues after the readiness audit/docs/test guard changes and again after the closeout status refreshes. | Covered locally. |
| E2E web release build | `flutter build web --release -t lib/main_e2e.dart` passed after the closeout status refreshes and produced `build/web`. | Covered locally for web build only. |
| CI receipt path robustness | `.github/workflows/hermes-platform-smoke.yml` is published and visible as `Hermes platform smoke`. `npm run platform:workflow-smoke` dispatches, watches, and writes `build/receipts/hermes-platform-workflow.json`; the receipt validates current `HEAD`, successful run conclusion, required native jobs, and non-empty non-expired native artifacts. | Covered for platform/native-host receipt. |

## Open blockers

1. **Hermes server realtime audio** — not implemented in Navivox; voice remains
   device STT -> Hermes text. Automated Android voice-loop evidence does not
   claim server audio.
2. **Deferred product surfaces** — config editing/admin, Hermes memory UI,
   jobs/schedules admin, messaging gateways, persona/SOUL, attachments/media,
   files/context folders, and raw log export remain outside the implemented
   Hermes mobile MVP. Multi-endpoint/profile management is now implemented
   locally.
3. **Polish/hardening** — SSE reconnect/drop edge cases, offline/auth-expired UX,
   session search/grouping, queued follow-ups, and mobile approval/error/session
   sheet polish remain improvement work after the core receipt blockers.
4. **Real spoken Android microphone receipt** — the active closeout still
   requires physical-audio/provider/TTS/re-arm evidence from an audio-capable
   Android target. The deterministic Android voice-loop receipt and provider
   transcript smoke are useful automated gates, but both explicitly say they are
   not physical-mic evidence.

## Current completion audit verdict

The active Hermes companion goal is **not complete**. Current evidence maps to
the explicit objective as follows:

| Objective item | Concrete artifact/evidence inspected | Verdict |
| --- | --- | --- |
| Android physical spoken mic receipt | `build/receipts/android-live-mic-smoke.json` must validate physical mic observation, provider reply, TTS, and a distinct second spoken turn after re-arm. | Not covered until the real spoken Android receipt is current; deterministic transcript receipts do not satisfy this. |
| Android automated voice-loop receipt | `build/receipts/android-hermes-voice-loop-smoke.json` validates the Android `HermesChatScreen` deterministic transcript capture, fake Hermes replies, fake TTS callback, and continuous re-arm for a distinct second turn. | Covered for no-human Android voice-loop mechanics; not physical-mic/provider/server-audio evidence. |
| Windows/iOS/macOS host receipts | `build/receipts/hermes-platform-workflow.json` validates successful watched native-host jobs and artifacts for the current checkout. | Covered. |
| Publish platform workflow | `gh workflow list` exposes `Hermes platform smoke`, and `npm run platform:workflow-smoke` produced a successful watched receipt. | Covered. |
| Hermes realtime/server audio | `build/receipts/hermes-server-audio-smoke.json` must validate a current-head Hermes realtime/audio API round trip. Until that exists, `hermesSurfaceReadiness()` marks advertised `realtime_voice` or `audio_api` as blocked and unadvertised server audio as deferred; voice remains device STT -> Hermes text. | Not covered; missing server-audio receipt keeps this blocked. |
| Deferred Hermes Desktop parity | Multi-endpoint/profile management is available locally with safe select/rename/remove/disconnect/reconnect-cleanup confirmation; jobs inventory and bounded diagnostics are read-only; bounded diagnostics explicitly excludes raw logs/tool payloads/transcripts/local paths; surface-readiness status copy covers config/admin, memory UI, jobs admin, gateways, and persona/SOUL with no mutation controls; attachments/media and files/context folders have safe deferred status sheets; attachments/media upload, files/context-folder controls, and raw diagnostics/log export are deferred. | Partially covered; remaining surfaces deferred/read-only by policy. |
| Polish/hardening | Existing tests cover SSE reconnect/drop recovery, explicit `Accept: text/event-stream`/`Cache-Control: no-cache` stream headers, final live SSE frame flush on stream close, no-data terminal `event: done` frames, message-level terminal events, approval request aliases, delta/content/text SSE delta payloads, embedded event names in default SSE `message` frames, explicit JSON/nested/non-JSON SSE error events, including message-level errors, with bounded/redacted recovery copy, in-place tool progress events, bounded diagnostics endpoint route inventory, private path redaction in diagnostics/error details, offline/auth-expired copy, session search/grouping, queued follow-ups with bounded/redacted copy details and cancel confirmation, deferred surface-readiness, attachments/media, and files/context folders status copy, session-scoped/high-impact approval confirmation, and mobile approval/error/session sheet behaviors for the implemented Hermes surfaces. Future regressions or newly wired surfaces still need focused coverage. | Covered for current implemented surfaces; not evidence for Android physical mic or server audio. |

Do not promote this audit, green tests, APK hashes, configured Hermes home
presence, workflow YAML, or dispatch-only workflow output to completion evidence
unless the missing Android physical-mic receipt, Hermes server-audio work, and
remaining deferred-surface decisions above are closed. Do not describe automated
Android voice-loop receipts as physical microphone evidence.

## Current blocker detail

The read-only helper currently expands the remaining blockers into these
non-overlapping categories:

- Provider-backed smoke receipt: configured Hermes home presence is only
  informational. Strict closeout requires a current
  `npm run hermes:provider-smoke:local` receipt with configured model/provider
  credentials. The readiness audit now requires the provider receipt to match
  current `HEAD`, carry a sanitized origin-only `base_url`, report zero
  Playwright retries, include explicit `evidence_for` labels for typed text and
  deterministic transcript voice, and include `not_evidence_for` caveats for
  Android physical mic, Hermes server audio, native hosts, platform workflow,
  deferred parity, and whole-goal completion. Deterministic transcript voice
  still is not physical microphone or Hermes server-audio evidence.
- Android automated voice-loop receipt: strict closeout requires
  `build/receipts/android-hermes-voice-loop-smoke.json` from
  `npm run android:hermes-voice-loop-smoke`. The receipt must match current
  `HEAD`, record Android device properties, prove the two deterministic voice
  turns and fake TTS outputs, and include `not_evidence_for` caveats for
  physical microphone audio, provider-backed replies, server audio,
  native-host receipts, platform workflow publication, deferred parity, and
  whole-goal completion.
- Native/host receipts: platform workflow publication and Windows/iOS/macOS
  hosted receipts are covered by `build/receipts/hermes-platform-workflow.json`.
  When Android is missing, the helper prints `flutter devices`, `flutter
  emulators`, and `emulator -accel-check` output as context only, not Android
  voice-loop or physical live-mic receipt evidence.
- Voice/audio: automated Android voice-loop mechanics are covered only as a
  no-human regression gate; real spoken Android physical-mic evidence remains a
  blocker until recorded. Hermes realtime/server audio is not implemented, so
  voice remains device STT -> Hermes text. The future server-audio closeout
  receipt is written by `npm run hermes:server-audio-receipt` to
  `build/receipts/hermes-server-audio-smoke.json`; it must match current `HEAD`,
  prove `hermes_realtime_or_audio_api`, `client_audio_to_hermes_server_audio`,
  `hermes_server_audio_to_client_playback`, provider reply, playback, round trip,
  `device_stt_used=false`, `local_tts_only=false`, safe short prompt/reply
  excerpts, no secret leaks, and explicit `not_evidence_for` caveats before it
  can clear only the server-audio blocker.
  Do not run that receipt helper until Hermes server audio is actually wired and
  observed; it is a manual evidence recorder, not an implementation.
- Deferred Hermes surfaces: config editing/admin, memory UI, jobs/schedules
  admin, messaging gateways, persona/SOUL, attachments/media, files/context
  folders, and raw diagnostics/log export. Multi-endpoint/profile management is
  implemented locally with secure per-profile API-key storage.
- Polish/hardening: current implemented Hermes surfaces have focused coverage
  for SSE reconnect/drop edge cases, offline/auth-expired UX, session
  search/grouping, queued follow-ups, and mobile approval/error/session sheet
  polish. Keep adding focused tests when new surfaces are wired or regressions
  are found.

## Do not count as completion

- Android `voice-smoke` by itself: it proves recognizer/mic permission readiness,
  not spoken audio capture.
- Android `live-mic-prep` by itself: it installs/launches/grants permission and
  prints a checklist; it is not a spoken-audio receipt.
- Deterministic Android voice-loop smoke by itself: it proves Android UI loop
  mechanics, deterministic transcript submission, fake TTS callback, and re-arm;
  it does not prove physical microphone input, provider-backed replies, or Hermes
  realtime/server audio.
- Installed-Hermes live connect smoke by itself: it proves API connect/session
  rendering against an isolated or configured API server, not provider/model
  behavior, chat/voice provider smoke, or physical microphone evidence.
- Provider transcript voice by itself: it proves device-transcript-to-Hermes text
  flow with a model reply, not microphone or Hermes realtime audio.
- Configured Hermes home presence by itself: it suggests a local provider smoke
  may be runnable, but only an actual `npm run hermes:provider-smoke:local`
  receipt proves provider-backed chat/transcript voice.
- Workflow YAML by itself: it proves a planned CI path, not a native-host build
  receipt, even when the YAML parses and has timeouts/artifact uploads.
- Workflow dispatch by itself: `NAVIVOX_WATCH_WORKFLOW=false` proves only that
  dispatch was requested; a missing visible run id or unwatched run is not a
  platform receipt. Only a watched successful run with required artifacts and the
  validated `build/receipts/hermes-platform-workflow.json` receipt can satisfy
  the workflow/native-host portion. Collect successful job status and artifacts
  with `gh run view` before claiming Windows/iOS/macOS/Android/Linux readiness.
