# Hermes Wing readiness audit

Last updated: 2026-07-18.

2026-07-13 status refresh: the latest main-branch `Hermes platform smoke` run
(29129974871, head `b7b99d8`, 2026-07-10) failed three jobs. Browser smoke
failed because `hermes-smoke.spec.mjs` still asserted the pre-`fc40db6`
diagnostics chip copy `Voice: device STT -> Hermes text`; the spec now asserts
the current `Voice: device STT → Hermes` copy and the focused smoke passed
locally on 2026-07-13. iOS/macOS builds failed because `flutter_onnxruntime`
(Pocket Speech) requires minimum iOS 16.0/macOS 14.0 while the projects
targeted 13.0/10.15; deployment targets were raised in `6ca4afb`, and the
push-triggered main run 29256462998 (head `9c44607`, 2026-07-13) succeeded on
all native jobs with a validated receipt written to
`build/receipts/hermes-platform-workflow.json`. The
`Dependency and license review` job fails on every PR with
"Dependency review is not supported on this repository"; enabling the
Dependency graph in repository settings is an owner action.

This audit maps the current Hermes-only Hermes Wing client goal to concrete
evidence and remaining blockers. It is intentionally conservative: a passing
test only counts for the behavior it directly exercises. For a quick read-only
local snapshot, run `npm run hermes:readiness-audit`; that helper prints every
explicit external or deferred blocker but is not a completion receipt.

Receipt inventory for this checkout: `build/receipts/` is absent. Receipt-backed
rows below are therefore labeled historical or unverified for the current
checkout even when a dated run previously passed. The explicit Android physical,
two-gateway, server-audio, and deferred-surface blockers remain unchanged.

## Success criteria and evidence

| Requirement | Current evidence | Status |
| --- | --- | --- |
| Provider-backed Hermes chat smoke with real model/provider credentials | `npm run hermes:provider-smoke:local` writes `build/receipts/hermes-provider-smoke.json` after a no-retry Playwright pass against a configured local Hermes home. The receipt is bound to the current `head_sha`, records a sanitized origin-only `base_url`, includes `evidence_for` entries for `provider-backed Hermes typed text turn` and `deterministic transcript voice turn`, and includes `not_evidence_for` caveats for physical Android mic, Hermes realtime/server audio, native-host receipts, platform workflow publication, deferred parity, and whole-goal completion. | Historical configured-local claim only; the current-checkout receipt is absent and provider-backed chat is unverified here. |
| Provider-backed Hermes voice smoke | Same provider smoke submits a deterministic device transcript via `wingE2EHermesSubmitVoice` and verifies a model reply. The helper caveat says this is deterministic transcript voice only, not physical microphone evidence or Hermes realtime/server audio, and the readiness audit rejects stale/malformed provider receipts. | Historical transcript-voice claim only; the current-checkout receipt is absent, and physical mic/server audio remain unverified. |
| Android speech/mic readiness | `npm run android:voice-smoke` passed on a KVM-backed `fractal_test` emulator on 2026-07-03, verifying speech recognizer availability and granted mic permission. `WING_ANDROID_SKIP_BUILD=1 WING_ANDROID_HERMES_URL=http://10.0.2.2:8642 npm run android:live-mic-prep` also installed/launched/granted mic permission on `fractal_test`. A later direct target recheck showed `adb devices` had no attached Android devices while `flutter devices` listed only Linux desktop and Chrome web. The canonical manual physical-audio checklist is `docs/runbooks/android/live-mic-smoke.md`; the live receipt helper and readiness audit reject whitespace-only observed excerpts and invalid/non-origin Hermes URLs. | Readiness/prep covered; real spoken audio not covered. |
| Android automated voice loop | `npm run android:hermes-voice-loop-smoke` writes `build/receipts/android-hermes-voice-loop-smoke.json` after an Android integration test runs `HermesChatScreen` with deterministic transcript capture, fake Hermes channel/provider replies, fake TTS, and a distinct second turn after continuous-voice re-arm. The receipt is bound to current `HEAD` and records Android device properties. | Historical no-human mechanics claim only; the current-checkout receipt is absent, and this remains no evidence for physical mic/provider/server audio. |
| Android debug APK build | `flutter build apk --debug` produced `build/app/outputs/flutter-apk/app-debug.apk` and `adb install -r` returned `Success` on an attached physical Android device on 2026-07-16; `npm run hermes:readiness-audit` prints the current APK SHA-256 when present. | Historical installation only; the present APK is artifact identity, not current-checkout installation, multi-gateway behavior, or physical-mic evidence. |
| Linux release build | `npm run linux:release-build` passed on 2026-07-03 and produced executable `build/linux/x64/release/bundle/wing`. | Historical only; the referenced executable is absent from the current checkout. |
| Windows build | A dated `build/receipts/hermes-platform-workflow.json` previously recorded a watched GitHub run with a successful `Windows desktop build` job and non-expired `wing-windows-debug-bundle` artifact. | Historical only; the current-checkout receipt is absent and Windows is unverified here. |
| iOS simulator build | A dated `build/receipts/hermes-platform-workflow.json` (run 29256462998, head `9c44607`, 2026-07-13) recorded a successful `iOS simulator build` job and non-expired `wing-ios-simulator-app` artifact after the deployment target was raised to 16.0 for `flutter_onnxruntime`. | Historical only; the current-checkout receipt is absent and iOS is unverified here. |
| macOS desktop build | A dated `build/receipts/hermes-platform-workflow.json` (run 29256462998, head `9c44607`, 2026-07-13) recorded a successful `macOS desktop build` job and non-expired `wing-macos-debug-app` artifact after the deployment target was raised to 14.0 for `flutter_onnxruntime`. | Historical only; the current-checkout receipt is absent and macOS is unverified here. |
| Browser fake Hermes smoke | Focused Playwright regression rerun of `wing-e2e.spec.mjs` plus `hermes-smoke.spec.mjs` passed on 2026-07-03 against `node serve_web.mjs` with 68 Chromium tests after a longer-timeout rerun; the focused Hermes smoke itself passed 2 Chromium tests and covers fake Hermes health/capabilities/sessions/runs/events/approvals/tool progress/stop. | Covered for fake server. |
| Installed Hermes API connect smoke | `npm run hermes:live-smoke` passed on 2026-07-03 against installed local Hermes with isolated temp home and no provider credentials; Playwright reported 1 pass. The helper caveat says this is API connect/session rendering only, not provider/model evidence, not chat/voice provider smoke, not physical microphone evidence, and not whole-goal completion evidence by itself. | Covered for live connect/session surface. |
| Deferred server realtime audio honesty | `lib/core/hermes/policy/hermes_surface_readiness.dart` marks advertised-but-unwired server realtime voice/audio as blocked and unadvertised server audio as deferred; README states voice is local-first. | Covered by code/docs. |
| Deferred config admin honesty | Surface readiness marks config editing/admin as `deferred`; the surface-readiness dialog repeats that no mobile config mutation controls are enabled. | Covered by code/docs. |
| Deferred memory UI honesty | Hermes surface readiness marks Memory UI as `deferred`; the surface-readiness dialog repeats that no mobile memory mutation controls are enabled. | Covered by code/docs. |
| Jobs/schedules | `/tasks` exposes a gateway- and profile-scoped, read-only `GET /api/jobs` inventory only when the endpoint declares `tasks:read` and the token is granted that scope. Startup, profile reload, and manual refresh fail closed before network I/O otherwise. It preserves explicit unsupported/empty/failure states, bounded schedule metadata, and no raw server error details. Focused tests cover exact route-and-scope fail-closed behavior, gateway switching, refresh, and 200% text scale. `scripts/maestro/schedules_unsupported_qa.yaml` validates fail-closed behavior on the current saved physical-device gateway, which does not advertise `GET /api/jobs`; live inventory and refresh still require a compatible gateway. Surface readiness separately keeps schedule administration `deferred`. | Read-only inventory covered; create/pause/resume/trigger/delete and Kanban remain contract-blocked. |
| Providers and models | `/providers` uses exact scoped `/api/providers` and `/api/models` contracts for administration. When those are absent but exact `GET /v1/models` is advertised, it shows bounded runtime model IDs read-only and hides credential/assignment controls. Focused widget tests prove no administrative loads or controls are issued in this fallback. The updated `providers_models_unsupported_qa.yaml` awaits a device-unlock rerun. | Read-only runtime model inventory covered locally; compatible-gateway provider/model mutation and secret non-reveal receipt remains blocked. |
| Skills and toolsets | `/tools` exposes gateway-selected, read-only installed skills with bounded searchable name/description/category metadata and enabled toolsets only when `/v1/skills` and `/v1/toolsets` are advertised. Optional inventory failures, including authorization failures on scoped servers, remain isolated from chat. Widget tests cover metadata search/no-match, distinguish unsupported, empty, and failed inventories, and cover gateway switching plus 200% text scale. `scripts/maestro/tools_inventory_qa.yaml` is the physical-device flow for both inventories and the search no-match path without enabling mutation or MCP controls; the earlier inventory receipt passed, while the metadata-search extension awaits a device-unlock rerun. | Read-only gateway inventory covered; install/remove, toolset mutation, and MCP administration remain contract-blocked. |
| Persona/SOUL and attachments | Persona editing is available only when exact profile SOUL read/write routes and `profiles:read`/`profiles:write` scopes are present. Chat additionally advertises `/persona` only for an exact scoped SOUL read and shows a bounded, selectable view for the client-selected profile; unsupported gateways receive no local persona control or request. The composer supports advertised inline PNG/JPEG/GIF/WebP images and bounded UTF-8 text attachments; arbitrary media still requires opaque server resource handles. | Capability-gated profile persona plus bounded inline attachments covered locally; compatible-gateway persona read/write and arbitrary-media receipts remain blocked. |
| Gateway health | `/gateway` exposes only gateway-selected, bounded `GET /health/detailed` status when the endpoint declares `gateway:read` and the token is granted that scope. Startup and manual refresh both fail closed before network I/O otherwise. Focused tests cover scope gating, gateway switching, stale-data suppression, raw-error exclusion, and 200% text scale. `scripts/maestro/gateway_status_qa.yaml` validates live status and refresh on the saved physical-device gateway. | Exact scoped read-only health covered; lifecycle, logs, messaging-platform configuration, drain/reload/restart remain contract-blocked. |
| Messaging gateways and files/context folders | Surface readiness keeps messaging-platform administration and files/context folders deferred; neither receives local shadow state or client-path emulation. | Deferred pending authoritative contracts. |
| Diagnostics/log export | Bounded diagnostics export exists and explicitly labels secrets, raw logs, tool payloads, transcripts, and local paths as excluded; surface readiness separately marks raw diagnostics/log export as `deferred`. The diagnostics test seeds transcript and raw tool-payload content and asserts the export reports only counts/statuses plus the explicit `device STT -> Hermes text; server audio not wired` voice boundary. | Bounded diagnostics covered; raw logs/payloads deferred. |
| Multi-endpoint/profile management | `HermesGatewayDirectory` projects saved Hermes Agent endpoints and Hermes profiles into unified activity-ordered contacts, refreshes at most three gateways concurrently with one active streaming channel, retains non-secret cached rows offline, and keeps per-endpoint credentials in secure storage. Settings provides gateway-scoped rename, reconnect, and confirmed removal. The canonical static invocations `maestro check-syntax scripts/maestro/chat_ux_qa.yaml`, `maestro check-syntax scripts/maestro/multi_gateway_chat.yaml`, `maestro check-syntax scripts/maestro/gateway_profiles_unsupported_qa.yaml`, `maestro check-syntax scripts/maestro/providers_models_unsupported_qa.yaml`, `maestro check-syntax scripts/maestro/tools_inventory_qa.yaml`, `maestro check-syntax scripts/maestro/schedules_unsupported_qa.yaml`, and `maestro check-syntax scripts/maestro/gateway_status_qa.yaml` pass, and the package-script contract rejects environment-specific sensitive data; these static checks are not device-behavior evidence. | Covered locally by focused directory, screen, enrollment, settings, and static Maestro contract checks. |
| Secret hygiene for Hermes diagnostics | `test/features/hermes_chat/screens/hermes_chat_screen_test.dart` asserts diagnostics include `Secrets: excluded`, omit `Authorization`, fake transcript tokens, and raw tool payload markers, and redact dynamic metadata fields such as active session title, health strings, capability model/features/endpoints, and model names. | Covered for diagnostics export. |
| Overall Dart/widget regression | `flutter test --coverage --concurrency=1` is the canonical local receipt; exact test and coverage totals come from that run and `coverage/lcov.info`, not this durable runbook. | A current passing command covers the local regression layer but does not replace device/host receipts. |
| Static analysis | `flutter analyze` passed with no issues on 2026-07-17 against the current multi-gateway worktree. | Covered locally. |
| E2E web release build | `flutter build web --release -t lib/main_e2e.dart` passed after the closeout status refreshes and produced `build/web`. | Covered locally for web build only. |
| CI receipt path robustness | `.github/workflows/hermes-platform-smoke.yml` was published and visible as `Hermes platform smoke`. `npm run platform:workflow-smoke` dispatches, watches, and writes `build/receipts/hermes-platform-workflow.json`; the validator requires current `HEAD`, successful run conclusion, required native jobs, and non-empty non-expired native artifacts. | Validator path is covered statically; the current-checkout hosted receipt is absent. |

## Multi-gateway plan acceptance reconciliation

Here, **gateway** means one saved Hermes Agent endpoint, not a Hermes
messaging-platform gateway. This matrix maps the plan's global constraints and
task-level outcomes to a focused test or an explicit readiness deferral. Source
presence or a broad green suite is not substituted for a missing focused
behavior receipt.

| Plan acceptance criterion | Focused evidence | Readiness verdict |
| --- | --- | --- |
| Stable contact identity | `gateway_contact_test.dart`: `identity includes gateway and profile`; directory activation also selects by the full `GatewayContactId`. | Covered by focused tests. |
| Profile-less fallback contact | `hermes_gateway_directory_test.dart`: `profile-less gateway produces one default contact` and `fallback contact skips profile selection`. | Covered by focused tests. |
| Activity ordering and deterministic tie-breaking | `gateway_contact_test.dart`: `contacts sort by latest activity then stable identity`, `contacts without activity sort after active contacts`, and `equal activity sorts by gateway then profile`. | Covered for descending activity, missing activity last, and deterministic gateway/profile tie-breaking. |
| Bounded refresh triggers | Directory tests cover the three-worker limit and `foreground timer stops refreshing while paused`; the provider covers startup without opening the full channel; the contact-list widget test covers `pull to refresh invokes the refresh callback`. | Covered for launch, resume, pull-to-refresh, one foreground periodic timer, paused non-firing, and three-worker concurrency. |
| Single active streaming channel | `hermes_channel_provider_test.dart`: directory refresh does not open a channel; directory tests cover activation and disconnect-before-second-activation. | Covered locally for one full `HermesChannel`. Static tests do not claim a real SSE socket-count receipt. |
| Offline cache and gateway failure isolation | Cache round-trip/removal plus directory `offline refresh retains cached contacts and healthy results` and authentication-failure tests. | Covered by focused tests. |
| Empty contacts stay sessionless | Channel test `connect never creates a session merely by viewing an empty gateway`. | Covered by a focused transport test. |
| Gateway secret hygiene | Contact JSON test omits credentials/transcript previews; directory tests reject leaked error/key sentinels; Settings omits credential text; the package contract checks Maestro fixtures. | Covered for models, cache, errors, Settings, and static fixtures. **Explicit readiness deferral:** the manual device diagnostics/screenshot and analytics-absence inspection remains unrecorded. |
| Safe contact switching | `hermes_chat_gateway_switch_test.dart`: active run, pending approval, and in-flight submission each require confirmation; choosing Stay preserves the active contact. | Covered by focused switch-guard tests for all three active-work states. |
| Enrollment append or update | Enrollment controller tests `successful enrollment appends and reloads without deletion` and `updating a gateway preserves every unrelated gateway`. | Covered by focused append and update tests. |
| Directory generation and gateway-scoped mutation | Directory tests cover stale refresh rejection, reconnect during refresh, remove during in-flight refresh, rename/reconnect isolation, and one-gateway removal. | Covered by focused tests. |
| Contact-list presentation details | View tests cover five ordered rows, opening a contact, pull-to-refresh callback wiring, the empty state with its optional connect action, list/contact refreshing affordances, trimmed multi-code-point avatar graphemes with `?` fallback, one-line ellipsized previews, normalized UTC `HH:mm` timestamps, retained offline rows, and offline semantics. | Covered by focused contact-list presentation tests. |
| Gateway-aware header and history | Gateway-switch tests cover agent/gateway header, sessions-panel opening, selecting an older session without leaving the active gateway contact, compact-phone overflow, explicit back, and system Back returning to all chats without deletion while preserving the active-work guard. | Header, history selection, and both back paths are covered by focused tests. |
| Gateway management and lifecycle integration | Enrollment, directory, gateway-switch, first-connect endpoint, and Settings tests cover append/reload, active-only resume, completed-turn summary refresh, rename, reconnect, confirmed removal, endpoint-chip deletion with directory reload, and preservation of another gateway. | Covered by focused lifecycle and gateway-scoped management tests. |
| Documentation and local validation | README/changelog/runbook changes exist; serialized coverage, formatting, static analysis, package contracts, and Maestro syntax checks use the commands and current receipts above. | Covered when those current local receipts pass; this is not Android behavior evidence. |
| Android and two-gateway receipts | The debug APK was built/installed previously; static Maestro flows exist and parse. | **Explicit readiness deferral:** current-worktree Android installation and the manual two-gateway 3+2-profile, offline-isolation, older-session, single-stream, and no-secret-leak receipt require explicit device/fixture authorization. |

The plan's commit steps are delivery mechanics, not behavior acceptance. They are
explicitly deferred by the owner instruction for this worktree; no commit, push,
or external publication is counted as evidence.

## Open blockers

1. **Hermes server realtime audio** — not implemented in Hermes Wing; voice remains
   device STT -> Hermes text. Automated Android voice-loop evidence does not
   claim server audio.
2. **Deferred product surfaces** — config editing/admin, Hermes memory UI,
   jobs/schedules admin, messaging gateways, richer profile-builder fields,
   arbitrary media/resource uploads, files/context folders, and raw log export remain outside
   the implemented Hermes mobile MVP. Capability-gated profile create, clone,
   rename, persona/SOUL edit, and delete are implemented for each saved gateway;
   unsupported gateways remain read-only/unavailable rather than gaining local
   shadow profiles. See
   [Gateway profile management and limitations](../product/gateway-profile-management.md).
3. **Polish/hardening** — SSE reconnect/drop edge cases, offline/auth-expired UX,
   session search/grouping, queued follow-ups, and mobile approval/error/session
   sheet polish remain improvement work after the core receipt blockers.
4. **Real spoken Android microphone receipt** — the active closeout still
   requires physical-audio/provider/TTS/re-arm evidence from an audio-capable
   Android target. The deterministic Android voice-loop receipt and provider
   transcript smoke are useful automated gates, but both explicitly say they are
   not physical-mic evidence.

## Current completion audit verdict

The active Hermes Wing goal is **not complete**. Current evidence maps to
the explicit objective as follows:

| Objective item | Concrete artifact/evidence inspected | Verdict |
| --- | --- | --- |
| Android physical spoken mic receipt | `build/receipts/android-live-mic-smoke.json` must validate physical mic observation, provider reply, TTS, and a distinct second spoken turn after re-arm. | Not covered until the real spoken Android receipt is current; deterministic transcript receipts do not satisfy this. |
| Android automated voice-loop receipt | A dated `build/receipts/android-hermes-voice-loop-smoke.json` previously validated deterministic transcript capture, fake Hermes replies, fake TTS callback, and continuous re-arm for a distinct second turn. | Historical only; the current-checkout receipt is absent, and this is not physical-mic/provider/server-audio evidence. |
| Windows/iOS/macOS host receipts | A dated `build/receipts/hermes-platform-workflow.json` previously validated watched native-host jobs and artifacts. | Historical only; the current-checkout receipt is absent. |
| Publish platform workflow | A prior `gh workflow list` inspection exposed `Hermes platform smoke`, and a prior `npm run platform:workflow-smoke` produced a successful watched receipt. | Historical only; publication and receipt status were not re-queried for this checkout. |
| Hermes realtime/server audio | `build/receipts/hermes-server-audio-smoke.json` must validate a current-head Hermes realtime/audio API round trip. Until that exists, `hermesSurfaceReadiness()` marks advertised `realtime_voice` or `audio_api` as blocked and unadvertised server audio as deferred; voice remains device STT -> Hermes text. | Not covered; missing server-audio receipt keeps this blocked. |
| Deferred Hermes Desktop parity | Unified contacts across saved Hermes endpoints and profiles are available locally with activity ordering, offline cache, one active streaming channel, and safe rename/remove/disconnect/reconnect confirmation; focused tests cover the single-channel invariant but not a real SSE socket count. Capability-gated profile create, clone, rename, persona/SOUL edit, and delete are implemented per gateway. Jobs inventory and bounded diagnostics are read-only; bounded diagnostics explicitly excludes raw logs/tool payloads/transcripts/local paths and can copy raw-log deferred status; surface-readiness status copy covers config/admin, memory UI, jobs admin, messaging gateways, and richer profile-builder fields with no controls. Inline supported images and bounded UTF-8 text attachments are implemented; arbitrary media/resource uploads, files/context-folder controls, and raw diagnostics/log export are deferred. | Partially covered; remaining surfaces deferred/read-only by policy. |
| Polish/hardening | Existing tests cover SSE reconnect/drop recovery, explicit `Accept: text/event-stream`/`Cache-Control: no-cache` stream headers, final live SSE frame flush on stream close, no-data terminal `event: done` frames, message/response-level terminal events, approval request aliases, delta/content/text SSE delta payloads including response text deltas, embedded event names in default SSE `message` frames, explicit JSON/nested/non-JSON SSE error events, including message/response-level errors, with bounded/redacted recovery copy, in-place tool progress events, bounded diagnostics endpoint route inventory, private path redaction in diagnostics/error details, offline/auth-expired copy, session search/grouping, queued follow-ups with bounded/redacted copy details and cancel confirmation, deferred surface-readiness, attachments/media, and files/context folders status copy, session-scoped/high-impact approval confirmation, and mobile approval/error/session sheet behaviors for the implemented Hermes surfaces. Future regressions or newly wired surfaces still need focused coverage. | Covered for current implemented surfaces; not evidence for Android physical mic or server audio. |

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
- Native/host receipts: a dated platform workflow previously covered
  Windows/iOS/macOS, but the current-checkout receipt is absent and those hosts
  are unverified here.
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
  `device_stt_used=false`, `local_tts_only=false`, safe short non-empty
  prompt/reply excerpts with the provider reply distinct from the prompt, no
  secret leaks, and explicit `not_evidence_for` caveats before it can clear only
  the server-audio blocker.
  Do not run that receipt helper until Hermes server audio is actually wired and
  observed; it is a manual evidence recorder, not an implementation.
- Deferred Hermes surfaces: config editing/admin, broader memory UI,
  jobs/schedules admin, messaging gateways, arbitrary attachment/media
  resources, files/context folders, and raw diagnostics/log export. Exact
  scoped profile persona read/edit is implemented separately. Multi-endpoint/profile management is
  implemented locally with secure per-endpoint credential storage.
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
- Workflow dispatch by itself: `WING_WATCH_WORKFLOW=false` proves only that
  dispatch was requested; a missing visible run id or unwatched run is not a
  platform receipt. Only a watched successful run with required artifacts and the
  validated `build/receipts/hermes-platform-workflow.json` receipt can satisfy
  the workflow/native-host portion. Collect successful job status and artifacts
  with `gh run view` before claiming Windows/iOS/macOS/Android/Linux readiness.
