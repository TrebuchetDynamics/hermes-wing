# GOAL STATE — 2026-07-01

## Status

Active goal: **become a Hermes Agent mobile app with continuous voice
support** (see `docs/product/hermes-agent-interface-plan.md`,
`docs/adr/0006-hermes-agent-first-runtime.md`, and
`docs/adr/0007-native-hermes-channel-not-navivox-channel-adapter.md`).

The prior **durable-reconnect-credentials** goal (Gormes-era) reached its
non-device-gated ceiling on 2026-06-17 and is preserved below for history; it
is no longer the active goal now that the product direction is Hermes-first.

## Course correction (2026-07-01)

The Hermes interface plan originally proposed a `HermesNavivoxChannel
implements NavivoxChannel` transition seam so old Gormes-era screens (profile
contacts, config-admin, memory, profile seed, voice profiles, run-record)
could keep compiling. The owner rejected that: Navivox should adapt to
Hermes's actual surface, not force Hermes into a 35-member Gormes-shaped
interface, and should lean on `fathah/hermes-desktop`'s own architecture
(SSE parsing, capability-gated transport, session store shape, chat voice
input) as the reference. See ADR 0007.

## Verified gate (refreshed 2026-07-03)

- Navivox: `flutter analyze` — no issues; `flutter test --concurrency=1` —
  **1016 tests pass**.
- `flutter build web --release -t lib/main_e2e.dart` passes and produces
  `build/web`.
- Focused Playwright browser regression (`navivox-e2e.spec.mjs` plus
  `hermes-smoke.spec.mjs`) passes after updating stale memory/mobile-tab
  assertions.
- Installed-Hermes live connect smoke (`npm run hermes:live-smoke`) passes.
- Configured provider-backed Hermes text plus transcript-voice smoke
  (`NAVIVOX_CONFIGURED_HERMES_HOME=$HOME/.hermes npm run hermes:provider-smoke:local`)
  passes when a configured local Hermes home is available; latest refresh used
  `npm run hermes:provider-smoke:local` and Playwright reported 1 pass.
- Android receipts now cover speech-recognition readiness, deterministic
  Hermes continuous-voice loop mechanics, durable-key create/sign/delete on an
  emulator, and a debug APK artifact (`build/app/outputs/flutter-apk/app-debug.apk`,
  SHA-256 `453e746d9773b466a7393ec73713943a49276f4bee4465d18a3d083e5cb5ab0a`).
  The APK hash is artifact identity only; physical microphone audio remains
  unverified. The canonical manual closeout is
  `docs/runbooks/android/live-mic-smoke.md`.
- Linux release build is locally repeatable through `npm run linux:release-build`.
- App-scoped Android native units pass with `cd android && ./gradlew :app:testDebugUnitTest`.
- Windows/iOS remain native-host gated; the CI workflow path exists but no
  successful host-runner receipt is present in this checkout.

See `docs/runbooks/hermes-readiness-audit.md` for the current prompt-to-artifact
readiness checklist and non-completion caveats.

## Delivered slices (Hermes-first transition)

1. **Docs/domain reset** — ADR 0006, `hermes-agent-interface-plan.md`.
2. **Hermes API client fixtures** — `lib/core/hermes/` client/config/models/
   `HermesTransportPolicy`/SSE decoder, fixture-tested.
3. **ADR 0007 course correction** — no `NavivoxChannel` adapter; native
   `HermesChannel` instead.
4. **Streaming client + native Hermes channel** — `HermesApiClient.
   streamSessionChat` (new streaming POST transport, io/web/stub, plus
   `HermesSseEventDecoder.decodeStream`/`decodeJsonEventStream`); the native
   `lib/core/hermes/channel/` module (`HermesChannel`, `HermesChannelState`,
   `HermesApiChannel`) covering connect (health + capabilities + session
   list/create with a `navi-<timestamp>-<uuid>` client id), session select/
   create, `sendText` with streamed assistant-delta accumulation and
   post-stream reconciliation against `GET /api/sessions/{id}/messages`, and
   the continuous-voice run lifecycle (start/stage/submit/cancel/fail)
   reusing the already-generic `NavivoxVoiceRun` model end to end into a
   Hermes text turn.
5. **Hermes chat/session UI + continuous voice** — `lib/features/hermes_chat/`:
   `HermesVoiceRunController` and `hermesContinuousVoiceReplyToSpeak` (ports
   of the Gormes `VoiceRunController`/`continuousVoiceReplyToSpeak`, retyped
   to `HermesChannel`/`HermesChatTurn`), `hermesChannelProvider`, and
   `HermesChatScreen` (manual connect form, session picker, streamed
   transcript, composer, push-to-talk mic, and a continuous-voice toggle that
   loops capture → send → speak-via-TTS → re-arm hands-free). Wired as an
   additive `/hermes` route in the existing `ShellRoute` — reachable by URL,
   not yet in the bottom nav, and does not touch the Gormes-first
   `redirect`/`initialLocation` default. Caught and fixed a real bug that
   `flutter analyze` missed: `headers.forEach(request.setRequestHeader)` in
   `hermes_api_transport_web.dart` is an illegal JS-interop tear-off under
   the actual web compiler (both the pre-existing `_request` helper and the
   new streaming transport had it) — only surfaced by running a real
   `flutter run -d web-server` build.
6. **Setup-flow secure storage** — `lib/core/hermes/setup/`:
   `HermesEndpointStore` interface + `EmptyHermesEndpointStore` default
   (mirrors the existing `DurableCredentialStore` convention) and
   `SecureHermesEndpointStore` (base URL in `SharedPreferences`, API key only
   in `FlutterSecureStorage`). `hermesChannelProvider` auto-connects from any
   saved endpoint on creation; `HermesChatScreen` saves after a successful
   connect and clears on a new disconnect action.
7. **`/v1/runs` run transport** — `HermesApiClient.startRun`/`runEvents`
   (new GET-streaming transport)/`respondApproval`/`stopRun`.
   `HermesApiChannel.sendText` switches to run transport automatically when
   `HermesTransportPolicy.supportsRunsTransport` is true, decoding
   `message.delta` into the same assistant-turn accumulation, tool events as
   lightweight system turns (not a rich tool-card model yet), and
   `approval.request` through a new `approvalRequests` stream. Added real
   `stopActiveTurn()` (server `/v1/runs/{run_id}/stop`) and
   `respondToApproval()` (`once`/`deny` only — `session`/`always` not wired).
   `HermesChatScreen` gained the approval banner and stop control the
   interface plan requires before this transport can ship.
8. **Full approval-decision set** — `HermesApprovalDecision`
   (`once`/`session`/`always`/`deny`, `.name` maps directly to the wire
   `decision` field). `respondToApproval` on both `HermesChannel` and
   `HermesApiChannel` takes the enum instead of a boolean `approved` flag;
   `HermesChatScreen`'s approval banner now offers all four choices.
9. **Rich tool-progress cards** — `HermesToolCall` (name/status/preview/
   result) + a `HermesTurnKind` (`text`/`toolCall`) on `HermesChatTurn`.
   `HermesApiChannel` tracks each tool invocation by a `${runId}:${toolName}`
   call id (matching hermes-desktop's `chatToolEventFromRunEvent`
   synthesis — Hermes run events have no guaranteed-stable per-call id) so
   `tool.started`/`completed`/`failed` update one turn in place instead of
   duplicating it. `HermesChatScreen` renders these as a status card instead
   of plain text.
10. **Hermes nav-bar entry** — per owner decision, `/hermes` is now a
   first-class `AppShellDestination` in the desktop rail and mobile bottom
   nav (Memory moved to mobile overflow to keep the primary row compact).
   Explicit `/hermes` navigation is not redirected away just because no Gormes
   server is configured.
11. **Cross-platform endpoint hints** — the Hermes connect form now surfaces
   platform-specific base URL examples inline: local desktop/Linux/Windows/iOS
   simulator (`127.0.0.1`), Android emulator (`10.0.2.2`), and physical
   device LAN/VPN/Tailscale URL.
12. **Capability status strip** — connected Hermes chats now show a bounded
   capability summary sourced from `/v1/capabilities`: model, whether full
   run/tool-progress transport is enabled (or session-chat fallback), and the
   local-device voice boundary when Hermes realtime voice is not advertised.
13. **Real browser Hermes route smoke** — added Playwright smoke coverage for
   the Flutter web e2e bundle that opens `/#/hermes` in Chromium and verifies
   both the disconnected connect form/cross-platform endpoint hints and a
   connected Hermes session against the local e2e HTTP/SSE Hermes fake served
   by `serve_web.mjs`, covering the real web `HermesApiChannel` transport,
   capability strip, text exchange, approval prompt/response UI, stop control
   hitting `/v1/runs/{run_id}/stop`, streamed tool progress card,
   new-session creation, and the device-voice-transcript lifecycle rendering
   as a Hermes text turn in a real browser accessibility tree.
14. **Gormes screen deprecation notices** — a reusable `GormesLegacyNotice`
   banner ("This is a legacy Gormes screen. Navivox is moving to Hermes
   Agent." + an "Open Hermes" action) is wired into the Gormes-era top-level
   surfaces: `ProfileContactsScreen` (Chats), `ServersScreen`, `AgentsScreen`,
   `MemoryDashboardScreen`, and `ConfigScreen`. Purely additive — no Gormes
   functionality removed.
15. **Platform scaffolds + smoke runbook/build receipts** — added generated
   iOS and Windows platform folders (no overwrite of existing Android/web/
   Linux code) plus iOS microphone/speech-recognition usage descriptions for
   continuous voice, covered by `test/platform/platform_scaffold_test.dart`.
   Added `docs/runbooks/hermes-platform-smoke.md`. Current build gates: web
   e2e build passes; Android debug APK builds; Linux desktop build is blocked
   in this container by missing `libsecret-1>=0.18.4` for
   `flutter_secure_storage_linux`; Windows/iOS require host-platform runners.
16. **Host platform smoke runbook** — documented the unavailable-host gates:
   Ubuntu analyze/tests/web e2e build/Hermes browser smoke/Android debug APK/
   Linux release build with `libsecret-1-dev`, plus Windows desktop and iOS
   simulator builds on their own host runners. A GitHub Actions workflow draft
   was prepared but not shipped because the current push credential lacks
   GitHub `workflow` scope; host CI remains an owner follow-up.
17. **Hermes-first startup and README refresh** — fresh no-Gormes-server
   startup now lands at `AppRoutes.hermes` instead of the legacy Gormes
   setup path, using `AppRoutes.isHermesLocation()` so query/deep links do not
   fall through to legacy setup. Seeded legacy Gormes sessions still start at
   Chats for transition tests/users, and legacy setup remains available
   explicitly at `/setup`. `README.md`, `pubspec.yaml`, and `package.json` now
   describe the Hermes Agent companion app instead of saying Hermes Desktop is
   not the runtime target.
18. **`flutter build linux` unblocked without root** — this container has no
   passwordless `sudo`, so the missing `libsecret-1-dev`/`libgcrypt20-dev`/
   `libgpg-error-dev` (required by `flutter_secure_storage_linux`) couldn't be
   `apt-get install`ed system-wide. Worked around with `apt-get download`
   (no root needed) + `dpkg -x` into a local prefix, a rewritten `.pc` search
   path, and fixing the dev package's dangling `libsecret-1.so` symlink to
   point at the already-installed runtime `.so.0`. `ldd` confirms the built
   binary and plugin `.so` link the real system library at runtime — the
   local prefix is build-time-only. Full recipe in
   `docs/runbooks/hermes-platform-smoke.md`.
19. **Read-only Hermes catalog strip** — added the first small read-only
   Hermes Desktop-style operator catalog surface from API-server endpoints
   already advertised by `/v1/capabilities`: `HermesApiClient.listModels()`
   parses `/v1/models`, `listSkills()` parses `/v1/skills`, and
   `listEnabledToolsets()` parses `/v1/toolsets`. `HermesApiChannel.connect()`
   loads them only when advertised and treats catalog failures as non-blocking
   so chat/session connect still works. `HermesChannelState` carries the names,
   and the connected capability strip shows model names plus skills/toolset
   counts. The web e2e Hermes fake now advertises/serves the three catalog
   endpoints, the Playwright smoke asserts the catalog chips through Flutter
   semantics, and `README.md` lists the catalog surface. Validation: focused Hermes API/channel/screen tests (35 pass),
   `flutter analyze`, full `flutter test --concurrency=1` (987 pass),
   `node --check serve_web.mjs`, `node --check playwright/tests/regression/hermes-smoke.spec.mjs`,
   `flutter build web --release -t lib/main_e2e.dart`, Playwright Hermes smoke
   (2 pass), `git diff --check`. Onklaud status was operational; the advisory
   loop passed but surfaced only a pass/fail summary, and final gate passed
   10/10 with only a generic edge-case note, so implementation details came
   from source-backed Pi validation.
20. **Session rename parity** — added capability-gated `PATCH /api/sessions/{session_id}`
   support for renaming the active Hermes session. `HermesApiClient.updateSessionTitle()`
   uses a new PATCH transport seam (io/web/stub), `HermesChannel.renameSession()`
   trims/rejects blank titles and replaces the session row only after the server
   returns the updated `hermes.session`, and `HermesChatScreen` shows a Rename
   action only when the active session exists and capabilities advertise
   `session_update`. Failed renames show a SnackBar and leave local state alone.
   The web e2e Hermes fake supports CORS/PATCH and Playwright renames a session
   through the real web bundle. Validation: focused Hermes API/channel/screen
   tests (39 pass), `flutter analyze`, full `flutter test --concurrency=1`
   (991 pass), `node --check serve_web.mjs`, `node --check playwright/tests/regression/hermes-smoke.spec.mjs`,
   `flutter build web --release -t lib/main_e2e.dart`, Playwright Hermes smoke
   (2 pass), `git diff --check`. Onklaud planning failed on under-specified
   plan details; useful issues were addressed in the Pi implementation. Final
   Onklaud gate passed 10/10 with only a generic edge-case note.
21. **Session delete parity** — added capability-gated `DELETE /api/sessions/{session_id}`
   support. `HermesApiClient.deleteSession()` uses a new DELETE transport seam
   (io/web/stub), verifies the server's deletion envelope id plus `deleted: true`,
   and rejects unconfirmed deletes. `HermesApiChannel.deleteSession()` is
   pessimistic, guards duplicate in-flight deletes, removes the deleted row and
   messages only after server confirmation, selects the next remaining session
   when the active session is deleted, and supports an empty connected session
   list without a stale active session. `HermesChatScreen` confirms destructive
   deletion, gates the action on `session_delete`, disables composer/mic/send
   when no active session remains, and shows an empty-state prompt to create a
   new session. The web e2e fake supports CORS/DELETE and Playwright deletes a
   session through the real web bundle. Validation: focused Hermes API/channel/
   screen tests (44 pass), `flutter analyze`, full `flutter test --concurrency=1`
   (996 pass), `node --check serve_web.mjs`, `node --check playwright/tests/regression/hermes-smoke.spec.mjs`,
   `flutter build web --release -t lib/main_e2e.dart`, Playwright Hermes smoke
   (2 pass), `git diff --check`. Onklaud planning failed on under-specified
   delete semantics; useful issues were addressed in Pi implementation. Final
   Onklaud gate passed 10/10 with only a generic edge-case note.
22. **Session fork parity** — added capability-gated `POST /api/sessions/{session_id}/fork`
   support. `HermesApiConfig.sessionForkUri()` and `HermesApiClient.forkSession()`
   post a generated `navi-*` id/title and parse the returned `hermes.session`;
   `HermesApiChannel.forkSession()` adds/selects the returned child session and
   loads forked messages only after the server response, leaving local state
   unchanged on failure. `HermesChatScreen` shows Fork only when capabilities
   advertise `session_fork` and surfaces failures with a SnackBar. The web e2e
   fake advertises/serves session fork by copying source messages, and
   Playwright forks a renamed session through the real web bundle. Validation:
   focused Hermes API/channel/screen tests (48 pass), `flutter analyze`, full
   `flutter test --concurrency=1` (1000 pass), `node --check serve_web.mjs`,
   `node --check playwright/tests/regression/hermes-smoke.spec.mjs`,
   `flutter build web --release -t lib/main_e2e.dart`, Playwright Hermes smoke
   (2 pass), `git diff --check`. Onklaud planning timed out during arbitration;
   first gate failed only on generic edge coverage, then final gate passed 10/10
   after adding the fork-failure no-local-mutation test.
23. **Dedicated Sessions panel** — moved Hermes session management out of
   separate chat app-bar actions into a bottom-sheet Sessions panel. The app bar
   now keeps Sessions, New session, and Disconnect; the panel lists sessions with
   active marker, title/id, message count, preview, row-tap selection, a New
   button, and capability-gated row actions for Rename/Fork/Delete. The old
   inline dropdown picker was removed. Panel actions close the sheet before
   invoking row-targeted channel operations, preserving existing confirmation
   and error SnackBar behavior. Validation: focused Hermes API/channel/screen
   tests (49 pass), `flutter analyze`, full `flutter test --concurrency=1`
   (1001 pass), `node --check playwright/tests/regression/hermes-smoke.spec.mjs`,
   `flutter build web --release -t lib/main_e2e.dart`, Playwright Hermes smoke
   (2 pass), `git diff --check`. Onklaud planning failed on under-specified
   panel details; useful issues were addressed in Pi implementation. Final
   Onklaud gate passed 10/10 with only a generic edge-case note.
24. **Local installed Hermes Agent smoke** — confirmed `hermes` is installed on
   this PC (Hermes Agent v0.16.0 under `/home/xel/.hermes/hermes-agent`) and
   added `scripts/run_live_hermes_smoke.sh` / `npm run hermes:live-smoke`. The
   script starts installed `hermes gateway` with an isolated temp `HERMES_HOME`,
   generated test API key, loopback API server, and local CORS; builds the
   Navivox e2e web bundle; serves it; and runs a gated Playwright live-connect
   spec against the real Hermes API. `lib/main_e2e.dart` accepts an optional
   Hermes base URL/API key for e2e tests while preserving the fake default.
   Validation: manual temp-home Hermes API probe (`/health`, `/v1/capabilities`),
   package JSON parse, Node syntax checks for the fake/live Hermes Playwright
   specs and `serve_web.mjs`, `bash -n scripts/run_live_hermes_smoke.sh`,
   `flutter analyze`, `flutter build web --release -t lib/main_e2e.dart`, fake
   Hermes Playwright smoke (2 pass), `scripts/run_live_hermes_smoke.sh`
   (Playwright live Hermes spec 1 pass), full `flutter test --concurrency=1`
   (1001 pass), and `git diff --check`. Onklaud planning timed out during
   arbitration and was recorded unusable; final Onklaud gate passed 10/10 with
   only a generic edge-case note.
25. **Catalog detail dialogs** — made the read-only Hermes model/skill/toolset
   catalog chips actionable. The capability strip stays compact, but Models,
   Skills, and Toolsets chips now open simple dialogs listing loaded catalog
   names. No new API calls or dependencies. Validation: focused Hermes chat
   screen tests (18 pass), `flutter analyze`, full `flutter test --concurrency=1`
   (1001 pass), `flutter build web --release -t lib/main_e2e.dart`, fake Hermes
   Playwright smoke (2 pass), and Onklaud gate 10/10 with only a generic
   edge-case note.
26. **Health detail strip** — added optional `/health/detailed` support.
   `HermesApiClient.healthDetailed()` uses the existing config URI;
   `HermesApiChannel.connect()` loads it only when capabilities advertise
   `health_detailed` and treats failure as non-blocking. `HermesChannelState`
   carries safe detailed health fields, and the Hermes capability strip shows
   version, gateway state, and active agent count without raw platform errors,
   logs, PIDs, or secrets. The fake web Hermes API advertises/serves
   `/health/detailed`, and the browser smoke asserts the new health chips.
   Validation: focused Hermes API/channel/screen tests (50 pass),
   `flutter analyze`, `node --check serve_web.mjs`, `node --check
   playwright/tests/regression/hermes-smoke.spec.mjs`, full
   `flutter test --concurrency=1` (1002 pass), `flutter build web --release -t
   lib/main_e2e.dart`, fake Hermes Playwright smoke (2 pass),
   `scripts/run_live_hermes_smoke.sh` (live Hermes spec 1 pass), and
   `git diff --check`. Onklaud planning timed out during arbitration and was
   recorded unusable; final Onklaud gate passed 10/10.
27. **Hermes setup presets** — added Hermes Desktop-style setup presets to the
   connect form. `Local Hermes` fills the loopback default, `Android emulator`
   fills the host-emulator URL, and `Remote/LAN` clears the field so the user
   enters a trusted LAN/VPN/Tailscale/TLS endpoint. This keeps the existing
   URL/API-key form and secure storage behavior; no installer, background
   service, or secret handling was added. Validation: focused Hermes chat screen
   tests (19 pass), `flutter analyze`, `node --check
   playwright/tests/regression/hermes-smoke.spec.mjs`, full
   `flutter test --concurrency=1` (1003 pass), fake Hermes Playwright smoke
   (2 pass), `scripts/run_live_hermes_smoke.sh` (live Hermes spec 1 pass), and
   `git diff --check`. Onklaud planning timed out; follow-up gates failed only
   on generic `prefer HTTPS` advice even though these presets are documented
   loopback/emulator local-development URLs, so Pi recorded the advice and used
   local validation.
28. **Hermes readiness guardrails and closeout runbooks** — added a read-only
   readiness audit helper (`scripts/audit_hermes_readiness.sh`, exposed as
   `npm run hermes:readiness-audit`) that fails closed in strict mode while
   external/deferred blockers remain. Added the canonical Android physical-audio
   closeout runbook (`docs/runbooks/android/live-mic-smoke.md`) and linked it
   from README, docs index, and the platform smoke runbook. Added tooling
   contracts for package helper scripts, the host-runner workflow shape, the
   readiness audit helper, testing-plan smoke matrix, runbook topology, and
   Android live mic/durable reconnect runbooks. In-app Hermes surface readiness now keeps deferred
   blockers honest, including separate rows for jobs/schedules inventory vs.
   admin and bounded diagnostics vs. raw diagnostics/log export. Validation:
   `flutter analyze`, focused Hermes regression (71 pass), full tooling/docs
   contract suite (27 pass), full `flutter test --concurrency=1` (1016 pass),
   `npm run hermes:provider-smoke:local` (1 Playwright pass), and
   `git diff --check`. Strict readiness audit now reports 16 blockers because
   full live provider-backed chat/voice smoke is an explicit closeout blocker,
   Windows and iOS/macOS host receipts are split explicitly, and configured
   Hermes home presence is informational only, not a provider-smoke receipt. External
   recheck still shows the platform workflow is not visible to `gh`. A later
   KVM-backed `fractal_test` launch became responsive long enough for
   `npm run android:voice-smoke`, `npm run android:hermes-voice-loop-smoke`,
   `npm run android:durable-key-smoke`, and `npm run android:live-mic-prep` to
   pass, refreshing recognizer/permission readiness, deterministic Android loop
   mechanics, keypair readiness, and install/launch/mic-grant prep, then the
   emulator was stopped. That remains readiness,
   deterministic transcript/TTS loop, and key-storage evidence only; no real
   spoken-audio/provider reply or real Android durable reconnect closeout has
   been captured. Latest local closeout rechecks after these receipts: full
   static analysis still passes with no issues, the E2E web release build still
   produces `build/web`, the Android debug APK still builds with SHA-256
   `453e746d9773b466a7393ec73713943a49276f4bee4465d18a3d083e5cb5ab0a`,
   app-scoped Android native units still pass, the Linux release helper still
   produces an executable `build/linux/x64/release/bundle/navivox`, durable
   reconnect unit/readiness contracts and the two targeted fake-gateway
   reconnect paths still pass, helper shell/JS syntax checks still pass, the
   full Flutter suite still passes (1016 tests), focused Hermes tests still pass
   (71 tests), installed-Hermes live API smoke and configured provider smoke
   still pass with their non-mic/server-audio and not-whole-goal-completion
   caveats, focused browser
   regression passes (68 Chromium tests), strict readiness audit still reports
   16 blockers including the explicit full live provider-backed chat/voice smoke
   closeout blocker and now prints `Completion verdict: NOT COMPLETE` plus an
   explicit warning not to promote proxy evidence (tests, APK hashes, configured
   Hermes home, workflow YAML, or dispatch-only output) to completion,
   `gh workflow list` still exposes only
   `pages-build-deployment`, so no hosted Windows/iOS/native-host receipt is
   available, direct native-host reprobes on this Linux host still fail
   (`flutter build windows --debug` exits 1 because Windows builds require a
   Windows host; `flutter build ios --simulator --debug` exits 64 because this
   toolchain has no `--simulator` option), and a direct Android-target recheck
   shows `adb devices` has no attached Android devices while `flutter devices`
   lists only Linux desktop and Chrome web. The Android live-mic and durable
   reconnect runbooks, plus the Android voice-readiness, deterministic
   voice-loop, durable-key, and live-mic-prep helpers, now require or point to
   strict readiness audit after future Android receipts and explicitly warn not
   to promote a single Android/reconnect/helper receipt or proxy evidence to
   whole-goal completion while unrelated blockers remain.

## Remaining work

- Real spoken Android microphone smoke: connect to Hermes on an audio-capable
  Android device/emulator, tap Speak, verify the spoken phrase becomes a Hermes
  text turn, enable continuous voice, and verify capture → reply/TTS → re-arm.
  Existing Android evidence is readiness plus deterministic transcript capture,
  not physical audio.
- Windows and iOS/macOS host-platform builds/smokes still need successful native
  host-runner receipts. The workflow definition exists in
  `.github/workflows/hermes-platform-smoke.yml`, but this checkout has no
  successful Windows/iOS run receipt.
- Real Android + real Gormes durable reconnect still needs end-to-end validation
  after app/server restart. Android keystore readiness and Dart fake-gateway
  reconnect are proven separately, but not the full real-device protocol.
- Hermes realtime/server audio, config editing/admin, Hermes memory UI,
  jobs/schedules admin, messaging gateways, persona/SOUL, attachments/media,
  files/context folders, raw log export, and multi-endpoint/profile management
  remain deferred or read-only by policy.

## Honest caveat

Provider-backed Hermes web text and transcript-voice smoke now passes against a
configured local Hermes home, and installed-Hermes live connect smoke passes
against a temp-home API server. That still does not prove physical microphone
capture or Hermes realtime/server audio: Navivox voice remains local device STT
(or deterministic transcript capture in tests) submitted as normal Hermes text.
The Android emulator receipts were collected on a headless/software emulator,
including one launched with `-no-audio`, so they are not real spoken-audio
receipts. The concrete `SecureHermesEndpointStore` has no dedicated direct test,
matching the existing convention for `SecureStorageDurableCredentialStore`; both
are thin platform-plugin glue exercised through higher-level tests instead.

## Loose ends

None outstanding for these slices: ADR 0007, the streaming client, the
native channel, the Hermes chat/session UI, setup-flow secure storage,
`/v1/runs` transport, the full approval-decision set, rich tool-progress
cards, the Hermes nav-bar entry, cross-platform endpoint hints, the capability
status strip, the real-browser Hermes e2e smoke, Gormes deprecation notices,
the iOS/Windows scaffolds plus platform smoke runbook/build receipts, the
host-platform smoke runbook, Hermes-first startup, README/package metadata
refresh, read-only Hermes catalog strip, session rename/delete/fork parity, and
Dedicated Sessions panel, local installed Hermes API connect smoke, compact
catalog detail dialogs, health detail strip, and setup presets are implemented
and green locally where the platform is available.
The next goal should get a live Hermes Agent/API browser or Android smoke in
front of `HermesChatScreen`, or continue deeper conversion/hiding of remaining
Gormes-era internals.

---

## Prior goal (superseded): durable-reconnect-credentials — 2026-06-17

The durable-reconnect-credentials goal was driven to its
**non-device-gated ceiling**. Every slice that can be built and validated
without a responsive Android target is implemented, validated, and on `main`
(Navivox) or pushed (Gormes). The remaining work is **device-gated** and waits
on a responsive Android target — the same standing blocker as the Android
live-smoke item above.

Delivered slices (durable reconnect):

1. **Gormes endpoints + capability advertisement** — `gormes-agent` commit
   `5e6ef089f`, merged to `development` (`41009dcbe`).
2. **Client parse + readiness** — `reconnect_readiness_test.dart`.
3. **Readiness surfaced in gateway-status UI** — `navivox-app` `main`
   (`dd1af32`).
4. **Client issuance method** — `navivox-app` `main` (`f1d386b`).
5. **Issuance + store seam + connect wiring** — `navivox-app` `main`
   (`d3cb4f8`).

Remaining work (device-gated, BLOCKED): real Android secure-storage
`DurableCredentialStore`, ECDSA P-256 keystore challenge, `device_bearer`
silent reconnect, live end-to-end validation. This is Gormes-era work,
preserved on the `gormes` branch; it is not part of the active Hermes-first
goal.
