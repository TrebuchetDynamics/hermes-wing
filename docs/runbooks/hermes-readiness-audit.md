# Hermes companion readiness audit

Last updated: 2026-07-03.

This audit maps the current Hermes Agent companion goal to concrete evidence and
remaining blockers. It is intentionally conservative: a passing test only counts
for the behavior it directly exercises. For a quick read-only local snapshot,
run `npm run hermes:readiness-audit`; that helper prints every explicit external
or deferred blocker but is not a completion receipt.

## Success criteria and evidence

| Requirement | Current evidence | Status |
| --- | --- | --- |
| Provider-backed Hermes chat smoke with real model/provider credentials | `npm run hermes:provider-smoke:local` passed on 2026-07-03 with a configured local Hermes home; Playwright reported 1 pass. The smoke connects to a configured local Hermes API, sends a typed prompt, and verifies the model reply. The helper now prints that this receipt is not whole-goal completion evidence by itself and points to strict readiness audit before completion claims. | Covered for configured local Hermes text. |
| Provider-backed Hermes voice smoke | Same provider smoke submits a deterministic device transcript via `navivoxE2EHermesSubmitVoice` and verifies a model reply. The helper caveat says this is deterministic transcript voice only, not physical microphone evidence or Hermes realtime/server audio. | Covered for transcript voice only; not physical mic or server audio. |
| Android speech/mic readiness | `npm run android:voice-smoke` passed on a KVM-backed `fractal_test` emulator on 2026-07-03, verifying speech recognizer availability and granted mic permission. `NAVIVOX_ANDROID_SKIP_BUILD=1 NAVIVOX_ANDROID_HERMES_URL=http://10.0.2.2:8642 npm run android:live-mic-prep` also installed/launched/granted mic permission on `fractal_test`. A later direct target recheck showed `adb devices` had no attached Android devices while `flutter devices` listed only Linux desktop and Chrome web. The Android readiness/prep helpers now print that their receipts/prep are not whole-goal completion evidence by themselves and point to strict readiness audit before completion claims. The canonical manual physical-audio checklist is `docs/runbooks/android/live-mic-smoke.md`. | Readiness/prep covered; real spoken audio not covered. |
| Android continuous voice loop | `NAVIVOX_ANDROID_DEVICE_ID=<emulator> NAVIVOX_ANDROID_DEVICE_WAIT_SECONDS=1 npm run android:hermes-voice-loop-smoke` passed on a KVM-backed `fractal_test` emulator on 2026-07-03. It runs `HermesChatScreen` with deterministic capture, fake Hermes channel, and fake TTS for two loop turns. The helper caveat says this is not physical microphone audio input, not provider-backed replies, and not whole-goal completion evidence by itself. | Deterministic loop covered; physical mic/provider loop not covered. |
| Android debug APK build | `flutter build apk --debug` passed on 2026-07-03 and produced `build/app/outputs/flutter-apk/app-debug.apk` with SHA-256 `453e746d9773b466a7393ec73713943a49276f4bee4465d18a3d083e5cb5ab0a`. App-scoped native units also passed with `cd android && ./gradlew :app:testDebugUnitTest`. | Covered locally for build/native units and artifact identity only; no live Android target, physical mic, or full durable reconnect receipt. |
| Android durable keypair readiness | `NAVIVOX_ANDROID_DEVICE_ID=<emulator> NAVIVOX_ANDROID_DEVICE_WAIT_SECONDS=1 NAVIVOX_ANDROID_TEST_TIMEOUT_SECONDS=900 npm run android:durable-key-smoke` passed on a KVM-backed `fractal_test` emulator on 2026-07-03. It creates an ES256 keypair, exports public JWK coordinates only, signs, deletes, and rejects unsafe aliases. The integration test also covers the Dart `MethodChannelDurableCredentialKeyStore` adapter path on Android. The helper caveat says this is not full Gormes durable reconnect issuance/authentication end to end and not whole-goal completion evidence by itself. | Key readiness covered; reconnect protocol not covered. |
| Gormes durable reconnect issuance/readiness unit path | `flutter test test/core/session/reconnect test/core/session/credentials test/core/gateway/capabilities/durable_reconnect_readiness_contract_test.dart test/core/session/readiness/reconnect_readiness_test.dart` passed on 2026-07-03 with 23 tests. | Dart issuance/readiness covered. |
| Gormes durable reconnect fallback/provider startup path | Targeted fake-gateway tests passed on 2026-07-03: `flutter test test/core/channel/gateway/runtime/channel_test.dart --plain-name 'falls back to device-bearer reconnect when stream reconnect exhausts'` and `flutter test test/core/channel/gateway/runtime/channel_test.dart --plain-name 'provider reconnects automatically from saved durable gateway'`. | Fake-gateway path covered; real Android + real Gormes restart not covered. |
| Linux release build | `npm run linux:release-build` passed on 2026-07-03 and produced executable `build/linux/x64/release/bundle/navivox`. | Covered locally. |
| Windows build | `.github/workflows/hermes-platform-smoke.yml` defines a `windows-latest` Flutter Windows build and artifact upload. | CI path exists; no native-host receipt yet. |
| iOS simulator build | `.github/workflows/hermes-platform-smoke.yml` defines a `macos-latest` iOS simulator build and artifact upload. | CI path exists; no native-host receipt yet. |
| Browser fake Hermes smoke | Focused Playwright regression rerun of `navivox-e2e.spec.mjs` plus `hermes-smoke.spec.mjs` passed on 2026-07-03 against `node serve_web.mjs` with 68 Chromium tests after a longer-timeout rerun; the focused Hermes smoke itself passed 2 Chromium tests and covers fake Hermes health/capabilities/sessions/runs/events/approvals/tool progress/stop. | Covered for fake server. |
| Installed Hermes API connect smoke | `npm run hermes:live-smoke` passed on 2026-07-03 against installed local Hermes with isolated temp home and no provider credentials; Playwright reported 1 pass. The helper caveat says this is API connect/session rendering only, not provider/model evidence, not chat/voice provider smoke, not physical microphone evidence, and not whole-goal completion evidence by itself. | Covered for live connect/session surface. |
| Deferred server realtime audio honesty | `lib/core/hermes/policy/hermes_surface_readiness.dart` marks server realtime voice/audio as `deferred` even when advertised; README states voice is local-first. | Covered by code/docs. |
| Deferred config admin honesty | Surface readiness marks config editing/admin as `deferred`; legacy Gormes config remains transitional. | Covered by code/docs. |
| Deferred memory UI honesty | Hermes surface readiness marks Memory UI as `deferred`; legacy Gormes memory can show read-only/empty state. | Covered by code/docs. |
| Jobs/schedules | `GET /api/jobs` is implemented as read-only inventory; surface readiness now separates jobs/schedules inventory (`readOnly`) from jobs/schedules admin (`deferred`). | Read-only inventory covered; admin deferred. |
| Messaging gateways, persona/SOUL, attachments, files/context folders | Surface readiness marks each as deferred with explicit copy. | Covered as deferred, not implemented. |
| Diagnostics/log export | Bounded diagnostics export exists and excludes secrets/raw logs; surface readiness separately marks raw diagnostics/log export as `deferred`. The diagnostics test now seeds transcript and raw tool-payload content and asserts the export reports only counts/statuses. | Bounded diagnostics covered; raw logs/payloads deferred. |
| Multi-endpoint/profile management | Surface readiness says current Hermes MVP targets one saved endpoint. | Deferred. |
| Secret hygiene for Hermes diagnostics | `test/features/hermes_chat/screens/hermes_chat_screen_test.dart` asserts diagnostics include `Secrets: excluded` and omit `Authorization`, fake transcript tokens, and raw tool payload markers. | Covered for diagnostics export. |
| Overall Dart/widget regression | `flutter test --concurrency=1` passed on 2026-07-03 with 1016 tests after the latest diagnostics, workflow, docs, and readiness-guard changes. | Covered locally, but does not replace device/host receipts. |
| Static analysis | `flutter analyze` passed with no issues after the readiness audit/docs/test guard changes and again after the closeout status refreshes. | Covered locally. |
| E2E web release build | `flutter build web --release -t lib/main_e2e.dart` passed after the closeout status refreshes and produced `build/web`. Flutter still reports wasm dry-run incompatibilities from `flutter_secure_storage_web`, but the JS web build succeeds. | Covered locally for web build only. |
| CI receipt path robustness | `.github/workflows/hermes-platform-smoke.yml` has quoted `"on"`, artifact uploads, optional provider/Android emulator jobs, and bounded job timeouts. `NAVIVOX_WATCH_WORKFLOW=false npm run platform:workflow-smoke` still exits 2 because `Hermes platform smoke` is not visible to `gh`; a direct `gh workflow list` recheck still shows only `pages-build-deployment`. The helper and readiness audit print visible workflows as blocker evidence, not native-host receipt evidence. | CI path improved; no run receipt yet. |

## Open blockers

1. **Real Android spoken microphone continuous loop** — requires an audio-capable
   responsive Android device/emulator. Current Android receipts use either native
   readiness diagnostics or deterministic transcript capture; a KVM-backed
   `fractal_test` refresh passed `npm run android:voice-smoke`, but that still
   proves recognizer/permission readiness only, not spoken audio, provider reply,
   TTS, or continuous re-arm. A later target recheck found no attached Android
   device in `adb devices`; Flutter listed only Linux desktop and Chrome web.
2. **Windows and iOS host receipts** — workflow/job definitions exist, but the
   repository currently has no successful native-host GitHub Actions or manual
   runner receipts. Direct Linux probes confirm this host cannot produce those
   artifacts: `flutter build windows --debug` exits 1 with `"build windows" only
   supported on Windows hosts.`, and `flutter build ios --simulator --debug`
   exits 64 with `Could not find an option named "--simulator".` on this Linux
   toolchain.
3. **Real Android + real Gormes durable reconnect** — Android keystore readiness
   and Dart fake-gateway reconnect are proven separately, but no end-to-end
   saved credential reconnect after app/server restart has been run on Android
   against real Gormes.
4. **Hermes server realtime audio** — not implemented in Navivox; voice remains
   local STT to text.
5. **Deferred product surfaces** — config editing/admin, Hermes memory UI,
   jobs/schedules admin, messaging gateways, persona/SOUL, attachments/media,
   files/context folders, raw log export, and multi-endpoint/profile management
   remain outside the implemented Hermes mobile MVP.

## Current completion audit verdict

The active Hermes companion goal is **not complete**. Current evidence maps to
the explicit objective as follows:

| Objective item | Concrete artifact/evidence inspected | Verdict |
| --- | --- | --- |
| Full live provider-backed Hermes chat/voice smoke needs configured credentials | `npm run hermes:provider-smoke:local` has a configured-local receipt for text plus deterministic transcript voice. | Partial: provider text/transcript covered; physical mic/server audio still not covered. |
| Android microphone + continuous voice needs responsive Android device/emulator | `adb devices` currently has no attached Android device; `flutter devices` lists only Linux desktop and Chrome web. Earlier `fractal_test` receipts are readiness/prep/deterministic only. | Blocked: no current Android target for manual spoken-audio closeout. |
| Windows and iOS builds need native host runners | `.github/workflows/hermes-platform-smoke.yml` exists, but `gh workflow list` exposes only `pages-build-deployment`; no successful `gh run view` jobs/artifacts exist. Direct local probes confirm this Linux host cannot produce them: `flutter build windows --debug` exits 1 with `"build windows" only supported on Windows hosts.`, and `flutter build ios --simulator --debug` exits 64 with `Could not find an option named "--simulator".` | Blocked: no native-host receipt. |
| Hermes realtime/server audio is not implemented | `hermesSurfaceReadiness()` marks server realtime voice/audio as deferred; voice remains local STT-to-text. | Deferred/unimplemented by policy. |
| Hermes config editing/admin is deferred | `hermesSurfaceReadiness()` marks config editing/admin deferred. | Deferred by policy. |
| Hermes memory UI is deferred | `hermesSurfaceReadiness()` marks Memory UI deferred. | Deferred by policy. |
| Jobs/schedules, messaging gateways, persona/SOUL, attachments, files/context folders, diagnostics/log export are deferred | Jobs inventory and bounded diagnostics are read-only; jobs admin, gateways, persona/SOUL, attachments/media, files/context folders, and raw diagnostics/log export are deferred. | Deferred/read-only by policy. |
| Multi-endpoint/profile management is deferred | Current Hermes MVP targets one saved endpoint. | Deferred by policy. |
| Legacy Gormes durable reconnect blocked on Android secure credential/keypair work | Android keypair readiness and Dart/fake-gateway paths pass, but no real Android + real Gormes restart reconnect receipt exists. | Blocked: real-device/server closeout missing. |

Do not promote this audit, green tests, APK hashes, configured Hermes home
presence, workflow YAML, or dispatch-only workflow output to completion evidence
unless the missing live/provider/device/native-host receipts above are captured.

## Current blocker detail

The read-only helper currently expands the remaining blockers into these
non-overlapping categories:

- Provider-backed smoke receipt: configured Hermes home presence is only
  informational. Strict closeout still requires a current
  `npm run hermes:provider-smoke:local` receipt with configured model/provider
  credentials, and deterministic transcript voice still is not physical
  microphone or Hermes server-audio evidence.
- Native/host receipts: workflow not visible remotely, missing Windows host
  receipt, missing iOS/macOS host receipt, and no online Android target. When
  Android is missing, the helper prints `flutter devices`, `flutter emulators`,
  and `emulator -accel-check` output as blocker context only, not Android/audio
  or live-mic receipt evidence.
- Voice/audio: real Android spoken microphone loop missing; Hermes
  realtime/server audio not implemented, so voice remains local STT-to-text.
- Deferred Hermes surfaces: config editing/admin, memory UI, jobs/schedules
  admin, messaging gateways, persona/SOUL, attachments/media, files/context
  folders, raw diagnostics/log export, and multi-endpoint/profile management.
- Legacy durable reconnect: Android key readiness and Dart/fake-gateway paths
  are not enough; real Android + real Gormes restart reconnect remains unproven.

## Do not count as completion

- Android `voice-smoke` by itself: it proves recognizer/mic permission readiness,
  not spoken audio capture.
- Android `live-mic-prep` by itself: it installs/launches/grants permission and
  prints a checklist; it is not a spoken-audio receipt.
- Deterministic Android voice-loop smoke by itself: it proves UI loop mechanics,
  not physical microphone input.
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
  platform receipt. Collect successful job status and artifacts with
  `gh run view` before claiming Windows/iOS/Android/Linux readiness.
- Durable reconnect unit/fake-gateway tests by themselves: they do not prove a
  real Android saved credential reconnect against real Gormes after restart.
