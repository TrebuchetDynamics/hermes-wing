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

## Verified gate (refreshed 2026-07-05)

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
  emulator, and a debug APK artifact at
  `build/app/outputs/flutter-apk/app-debug.apk`. The current APK SHA-256 is
  printed by `npm run hermes:readiness-audit` when the artifact exists; the hash
  is artifact identity only, and physical microphone audio remains unverified.
  The canonical manual closeout is `docs/runbooks/android/live-mic-smoke.md`.
- Linux release build is locally repeatable through `npm run linux:release-build`.
- App-scoped Android native units pass with `cd android && ./gradlew :app:testDebugUnitTest`.
- Windows/iOS/macOS host receipts are covered by the published `Hermes platform
  smoke` workflow. The source of truth is the refreshed current-head
  `build/receipts/hermes-platform-workflow.json`, which records the watched
  GitHub run id plus successful Windows desktop, iOS simulator, and macOS
  desktop jobs/artifacts.

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
   iOS, macOS, and Windows platform folders (no overwrite of existing Android/web/
   Linux code) plus iOS microphone/speech-recognition usage descriptions for
   continuous voice, covered by `test/platform/platform_scaffold_test.dart`.
   Added `docs/runbooks/hermes-platform-smoke.md`. Current build gates: web
   e2e build passes; Android debug APK builds; Linux desktop build is blocked
   in this container by missing `libsecret-1>=0.18.4` for
   `flutter_secure_storage_linux`; Windows/iOS/macOS require host-platform runners.
16. **Host platform smoke runbook** — documented the host gates:
   Ubuntu analyze/tests/web e2e build/Hermes browser smoke/Android debug APK/
   Linux release build with `libsecret-1-dev`, plus Windows desktop, iOS
   simulator, and macOS desktop builds on their own host runners. The published
   `Hermes platform smoke` GitHub Actions workflow now supplies the hosted
   Windows/iOS/macOS receipt path; local YAML or dispatch-only output remains
   insufficient without watched successful job/artifact evidence.
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
   Android live mic runbooks. In-app Hermes surface readiness now keeps deferred
   blockers honest, including separate rows for jobs/schedules inventory vs.
   admin and bounded diagnostics vs. raw diagnostics/log export. Validation:
   `flutter analyze`, focused Hermes regression (71 pass), full tooling/docs
   contract suite (27 pass), full `flutter test --concurrency=1` (1016 pass),
   `npm run hermes:provider-smoke:local` (1 Playwright pass), and
   `git diff --check`. Strict readiness now treats the automated Android
   voice-loop receipt as deterministic no-human loop coverage only; the
   human-spoken physical mic ship gate remains open until real spoken-audio,
   provider reply, TTS, and re-arm evidence is captured. Hermes realtime/server
   audio remains unwired, and the remaining Desktop-parity admin/mutation
   surfaces stay deferred by policy.
   Provider-backed Hermes text plus deterministic transcript voice is covered by
   a current no-retry provider receipt, and Windows/iOS/macOS host receipts plus
   workflow publication are covered by the watched `Hermes platform smoke`
   workflow receipt. Configured Hermes home presence remains informational only,
   not a provider-smoke receipt. A KVM-backed `fractal_test` launch became
   responsive long enough for `npm run android:voice-smoke`,
   `npm run android:hermes-voice-loop-smoke`, and
   `npm run android:live-mic-prep` to pass, refreshing recognizer/permission
   readiness, deterministic Android loop mechanics, and install/launch/mic-grant
   prep, then the emulator was stopped. That remains readiness and deterministic
   transcript/TTS loop evidence only; no real spoken-audio/provider reply has
   been captured. Latest local closeout rechecks after these receipts: full
   static analysis still passes with no issues, the E2E web release build still
   produces `build/web`, the Android debug APK still builds, app-scoped Android
   native units still pass, the Linux release helper still produces executable
   `build/linux/x64/release/bundle/navivox`, helper shell/JS syntax checks still
   pass, the full Flutter suite still passes (1016 tests), focused Hermes tests
   still pass (71 tests), installed-Hermes live API smoke and configured
   provider smoke still pass with their non-mic/server-audio and
   not-whole-goal-completion caveats, focused browser regression passes (68
   Chromium tests), and strict readiness audit now prints `Completion verdict:
   NOT COMPLETE; Android physical-mic, Hermes server-audio, deferred-surface
   blocker(s) remain.` when receipts are current, and adds `receipt` to the
   verdict only when provider/automated/platform receipts are stale or missing.
   It still prints an explicit warning not to promote proxy evidence (tests, APK
   hashes, configured Hermes home, workflow YAML, or dispatch-only output) to
   completion. `gh workflow list` shows `Hermes platform smoke`, and
   `build/receipts/hermes-platform-workflow.json` records a current watched
   successful run with Windows desktop, iOS simulator, and macOS desktop jobs and
   artifacts. A direct Android-target recheck still shows `adb devices` has no
   attached Android devices while `flutter devices` lists only Linux desktop and
   Chrome web. The Android live-mic runbook, plus the Android voice-readiness,
   deterministic voice-loop, and live-mic-prep helpers, require or point to
   strict readiness audit after future Android receipts and explicitly warn not
   to promote a single Android helper receipt or proxy evidence to whole-goal
   completion while unrelated blockers remain.
29. **Hermes chat hardening** — improved multiple polish/hardening edges in the
   native Hermes path: in-flight SSE streams are canceled on disposal,
   disconnect or active-session switches, active-session deletion, and late deltas are ignored,
   including stale callbacks that arrive after cancellation or after a pending
   run submission resolves or fails, so a disconnected, switched, or deleted session cannot
   be repopulated by stale events, failed reconnects clear stale endpoint session
   data, unknown session selections and mutable session calls are rejected before
   fetching history, calling mutation endpoints, or changing the active session,
   and failed session-history loads leave the previous active session intact;
   stale connect attempts cannot overwrite a newer
   Hermes endpoint connection; pending session mutations cannot repopulate state
   after disconnect/reconnect/stop, stale run submissions cannot attach old run ids,
   late run-event streams, or late submission failures to a newer/stopped endpoint
   connection, disconnect/connect/dispose clear stale pending-delete guards so
   in-progress deletes cannot leak across endpoints, connect stays sessionless instead of attempting
   unsupported session creation when Hermes has no sessions and no create endpoint, the
   sessionless no-create UI explains the endpoint limitation instead of telling
   users to create an unavailable session, and failed create/fork history loads
   leave the previous session list and active session intact; invalid Hermes base URLs are rejected before any HTTP client/request is built;
   broader network
   failures (client/handshake/connection reset/ECONNRESET/ECONNREFUSED/broken pipe/no route to host/DNS resolution failures/connection aborts/network
   unreachable/timeout) now resolve to offline recovery copy; expired/invalid API
   key and token errors resolve to auth recovery copy without echoing secrets, and
   channel-stored connect/send/stream/approval/voice errors redact bearer tokens,
   URL userinfo, Basic authorization, cookie/X-API-Key/X-Auth-Token headers, auth/credential fields, password/passwd/pwd fields,
   API keys, token values, and secret-looking values before reaching state; stream drops, `[DONE]` SSE sentinels, run
   terminal success/failure/cancellation events (including `assistant.completed`
   success and assistant-level failed/cancelled events), and run-submission/auth failures now complete the local waiter even
   when the SSE stream stays open, mark
   terminal failures/cancellations failed, mark run-event stream open failures
   failed instead of leaving a streaming turn behind, direct chat streams and
   run-event streams that close before a terminal event now reconcile from server
   history when Hermes has already persisted a non-empty assistant reply, otherwise
   fail the local assistant turn instead of being promoted to completion, surface bounded stream
   recovery copy for those failures, recover dropped direct/run streams from server
   history when Hermes has already persisted the current assistant reply, with
   stale-history, duplicate-user-turn, later-turn assistant-reply, and recovery regression coverage for both
   direct and run transports, including closed run streams, dropped direct streams, and dropped run streams, ignore
   late deltas and stream errors after the terminal
   run event, reconcile terminal success, keep the streamed assistant reply when
   immediate server history is stale/incomplete, and avoid reconciling over local
   failures; direct concurrent sends are rejected while a turn is streaming or
   while run submission is still pending, stale stopped-run cleanup cannot clear a
   newer active run/stop handle, terminal Hermes run events surface
   bounded recovery copy, expose a
   reconnect path for expired keys and stream/network drops, add a mobile-friendly
   redacted error details sheet with copy-to-clipboard support for connect and
   in-chat failures, and expose a retry action for the last failed
   user turn while hiding retry during another active streaming turn; composer follow-ups now queue
   multiple messages in order during an active streaming turn, offer a manual
   `Send now` retry, and re-queue the pending message if automatic send fails
   instead of overwriting the previous pending follow-up; the mobile session sheet
   is scroll-controlled and groups active, forked, and other sessions while
   preserving clearable search across title/id/preview/fork-parent/last-active
   fields plus active/forked/other group labels, showing filtered/total session counts,
   sorting inactive groups by recent activity, showing fork origin and last
   active metadata with redaction/bounds on last-active text, and hiding row action menus when Hermes does not advertise
   any mutable session endpoints, showing bounded feedback when session
   selection fails, bounding session mutation error details before SnackBar display,
   keeping copy actions for bounded/redacted session and job details while hiding mutation
   actions when Hermes does not advertise them,
   hiding create-session actions when Hermes does not advertise
   session creation, locally rejecting mutable session calls when Hermes does not
   advertise create/update/delete/fork endpoints, surfacing bounded feedback
   when session creation fails, requiring extra bounded/redacted confirmation before
   session-scoped and high-impact `Always allow` approval decisions, and redacting bearer tokens, API keys, token
   values, and secret-looking values from bounded active-session titles,
   bounded capability strip model/list/health details, queued-follow-up banner,
   copyable queue details, and cancel-all confirmation dialog, bounded session sheet titles/previews/parent ids, bounded delete
   confirmation copy, unsafe or overlong rename-dialog defaults, private filesystem
   paths in mobile error/details surfaces, and bounded/redacted no-result query echo; session search also uses redacted metadata with
   placeholders stripped so raw secret-looking values and `[redacted]` placeholder
   queries do not match hidden rows;
   stale setup connect completions cannot overwrite the newly saved endpoint;
   saved Hermes endpoint profile deletion, app-bar disconnect/profile-removal, and
   in-chat auth/stream reconnect cleanup paths now require mobile confirmation dialogs
   with bounded/redacted endpoint copy before removing secure API-key storage;
   session create/select/rename/fork/delete failure SnackBars redact bearer tokens,
   API keys, token values, and secret-looking values; the Hermes composer exposes
   attachments/media status as a safe deferred sheet when capabilities mention
   attachments or multimodal chat, explicitly stating that no files, photos,
   transcripts, or local paths are uploaded; Android live-mic receipts
   strip Hermes URL userinfo, query strings, and fragments before writing JSON,
   record current git `HEAD`, record Android device manufacturer/model/SDK/
   fingerprint properties plus installed Navivox package/version/RECORD_AUDIO
   grant details, require an explicit physical Android device observation,
   reject emulator targets for the final live-mic receipt, and reject
   secret-looking or overlong spoken phrases/provider reply excerpts;
   composer, mic, continuous voice, and direct channel sends share the same
   chat-transport policy, direct channel sends reject blank messages before HTTP,
   and are disabled/rejected with bounded recovery copy
   when Hermes advertises no supported chat transport; session-chat and run-event
   SSE streams now send explicit `Accept: text/event-stream` and `Cache-Control:
   no-cache` headers so intermediaries and Hermes hosts do not downgrade or reuse
   stale stream responses, live SSE decoding flushes a final data frame when the
   stream closes without a trailing blank-line separator instead of silently
   dropping the last delta/terminal/error payload, no-data `event: done` frames
   are accepted as terminal events, `message.completed`/`message.failed` terminal
   aliases are handled alongside run/assistant terminal events,
   `assistant.delta`/`message.delta` frames can consume `delta`, `content`, or
   `text` payload keys from Hermes-compatible hosts, default `message` SSE frames
   can resolve embedded `event`/`type`/`name` payload fields so terminal/delta events are not missed,
   nested SSE error payloads are surfaced without leaking secrets,
   `approval.required`/`approval.requested` aliases surface the same pending
   approval UX as `approval.request`, `tool.progress` SSE frames update the
   current tool card in place instead of disappearing or duplicating tool rows,
   and explicit SSE error events (including `message.error`
   and non-JSON error frames) fail the active assistant turn with bounded/redacted
   recovery copy instead of waiting for stream close;
   run SSE chat transport no longer requires optional
   approval/tool-progress/stop capabilities,
   `respondToApproval` rejects locally when Hermes does not advertise approval
   response, `stopActiveTurn` stays local when Hermes does not advertise run
   stop, and bounded diagnostics now report optional run stop/approval/tool-progress
   support plus a redacted, bounded Hermes endpoint route inventory separately,
   while redacting private filesystem paths from dynamic health/capability text;
   the readiness audit and `npm run hermes:server-audio-receipt`
   now define a strict future Hermes server-audio receipt schema that rejects
   local device STT/TTS fallback evidence without treating it as implementation
   evidence; the surface-readiness dialog can copy a bounded
   summary of available/read-only/deferred/blocked Hermes surfaces; retry actions hide when chat transport is unavailable; queued follow-up
   banners are bounded for many long messages, redact secret-looking preview text
   without altering the queued send payload, remain bound to their original
   session across session changes and failed-send requeues, clear when that
   original session is deleted, and stay queued with Send now disabled if chat
   transport disappears before auto-send, explain whether a queued follow-up is waiting for its original session or a supported chat transport, offer an `Open session` action when the original session still exists, and keep the queue with bounded/redacted feedback if that session cannot be opened; approval requests now queue in order,
   replayed duplicate approval requests are deduplicated, approval responses
   completing after disconnect or after the active run is gone are ignored safely,
   approval-response failures
   keep the request queued for retry and surface specific bounded
   approval-recovery copy instead of disappearing, approval prompts/risk/tool-call
   context redact bearer tokens, API keys, token values, and secret-looking values
   before display in the banner or review sheet, long approval banner prompt/risk
   text is bounded while the review sheet remains scrollable, stale approval requests clear
   when the user switches sessions or when a streaming turn is stopped or otherwise ends, and late approval-response
   completion cannot remove a same-id approval that arrived in a new active session, approval decisions are
   disabled with explanatory copy when Hermes does not advertise approval
   responses, malformed approval requests without ids fail locally with bounded
   recovery copy instead of presenting unanswerable decision buttons, direct blank
   approval responses are rejected before POST, approval ids are trimmed before POST,
   in-flight
   approval responses show progress with disabled decision buttons, approval requests
   without ids disable decision buttons before send and can be dismissed so queued
   valid approvals are not blocked, replayed approvals
   dedupe on trimmed ids/tool-call ids before display and response ids are trimmed
   before send, and approvals
   have a scroll-controlled/scrollable review sheet that
   shows prompt, risk, pending-count context for queued approvals, tool-call
   context, all decision scopes, a copy action for bounded/redacted approval
   details, and a close action that leaves the approval queued without answering; disconnect clears transient approvals, queued follow-ups,
   voice errors, stops in-flight TTS, clears the continuous-voice toggle, and
   immediately marks locally stopped streaming replies failed/Stopped so the
   spinner cannot hang after a stop; stale work cannot leak into a later connection; missing TTS plus capture and TTS failures now
   pause continuous voice before
   re-arm and show bounded recovery copy, with voice capture failure text bounded
   and redacted before display, instead of silently continuing capture;
   captured mic transcripts are discarded instead of submitted if the Hermes
   session changes mid-capture, the live Android mic runbook now has a fail-closed
   receipt recorder/audit path for observed physical mic → Hermes reply → TTS/re-arm
   evidence and requires a distinct second spoken turn after re-arm, starting a new capture cancels any superseded
   pending voice run before recording again, capture reports a bounded voice error if chat
   transport disappears before submit, submitted voice turns fail locally without
   adding transcript turns when the transcript is blank, no Hermes session is active, or Hermes has no
   supported chat transport, submitted voice
   turns fail instead of reporting
   completed if Hermes produces no assistant reply, their session changes mid-turn,
   or their assistant turn is stopped/failed,
   cancelled voice runs ignore late transcript staging/resubmission and are not
   overwritten by late send completion/failure, terminal voice runs ignore late
   cancel/fail calls,
   and continuous voice pauses instead of re-arming
   if the session changes while TTS is speaking; stopping an active turn now also stops in-flight TTS. Active Hermes surface
   readiness marks advertised-but-unwired server realtime voice/audio as blocked while keeping unadvertised server audio deferred, and diagnostics no longer include the superseded legacy durable
   reconnect row, keeping the current Hermes blockers scoped to Hermes surfaces.
   Validation: `flutter test test/features/hermes_chat test/core/hermes/channel/hermes_api_channel_test.dart test/core/hermes/hermes_api_test.dart test/platform test/tooling`
   (245 pass), `flutter analyze`, `npm run hermes:provider-smoke:local` (passed
   for typed text plus deterministic transcript voice; not physical mic evidence),
   and `npm run hermes:readiness-audit` (now parses the provider-smoke receipt as
   JSON and validates `status: passed`, typed-text/transcript-voice coverage,
   `playwright_retries: 0`, timestamp, and explicit non-evidence caveats, while
   future provider-smoke receipts now redact URL userinfo/query/fragment fields, and
   reports when active `gh` scopes still lack `workflow`); `npm run
   platform:workflow-smoke` now dispatches/watches the published `Hermes platform
   smoke` workflow and writes `build/receipts/hermes-platform-workflow.json` for
   audit validation of Windows/iOS/macOS artifact and job names/metadata. It
   still fails closed if the workflow is not visible, the watched run or any
   required native job did not reach `completed`/`success`, any required native
   artifact is missing/expired/empty/lacks a download URL, or the receipt
   `head_sha` does not match the current git `HEAD`.
   Android live-mic receipt audit now requires a
   sanitized Hermes URL with no userinfo/query/fragment, matching receipt
   `head_sha` to current git `HEAD`, non-empty Android device properties,
   installed expected Navivox package/version metadata with RECORD_AUDIO granted,
   provider reply excerpts that differ from both spoken phrases, and rejects
   secret-looking or over-240-character manual evidence fields. Readiness remains
   `Completion verdict: NOT COMPLETE` with 10 blockers while the Android
   physical-mic receipt, Hermes server audio, and deferred parity/admin surfaces
   remain incomplete).

## Remaining work

- Real spoken Android microphone smoke: connect to Hermes on an audio-capable
  Android device/emulator, tap Speak, verify the spoken phrase becomes a Hermes
  text turn, enable continuous voice, and verify capture → reply/TTS → re-arm.
  Existing Android evidence is readiness plus deterministic transcript capture,
  not physical audio.
- Windows, iOS, and macOS host-platform runner evidence is now captured by
  `build/receipts/hermes-platform-workflow.json`: Windows desktop, iOS simulator,
  and macOS desktop jobs completed successfully and uploaded non-expired,
  non-empty native artifacts.
- The platform workflow is published and visible remotely as `Hermes platform
  smoke`; the latest watched run completed successfully on `main`.
  Latest blocker recheck: attempting `flutter emulators --launch fractal_test`
  exited `-6` during startup, but direct SDK emulator launch with
  `-no-snapshot -no-boot-anim -gpu swiftshader_indirect -no-window` brought
  `emulator-5554` online long enough for `npm run android:live-mic-prep` to
  build/install/launch/grant microphone permission; the emulator still logged
  `pulseaudio: Failed to initialize PA context`, no spoken-audio/provider/TTS
  receipt was captured, and after shutdown `adb devices` again listed no
  attached Android devices while `flutter devices` listed only Linux desktop and
  Chrome web. `gh workflow list` now shows `Hermes platform smoke`; the current
  platform workflow receipt records a watched successful run for the current
  checkout plus successful Windows desktop, iOS simulator, and macOS desktop jobs
  with valid native artifacts. After adding Hermes endpoint profile management,
  `npm run hermes:readiness-audit` reports 10 remaining blockers.
- Hermes realtime/server audio, config editing/admin, Hermes memory UI,
  jobs/schedules admin, messaging gateways, persona/SOUL, attachments/media,
  files/context folders, and raw log export remain deferred or read-only by
  policy. Multi-endpoint/profile management is now available locally through
  saved Hermes endpoint profile labels/chips with safe select/rename/remove
  controls, endpoint presets clear stale selected profile secrets/labels before
  reuse, and per-profile API keys kept in secure storage. The composer now has
  safe deferred status sheets for admin surfaces, attachments/media, and
  files/context folders, with no config/memory/schedule/gateway/persona
  mutation controls, upload controls, or local path disclosure. The Hermes jobs chip also
  now opens a read-only schedule detail sheet
  with enabled/state/schedule/next/last/error fields redacted and bounded plus a
  copy action for bounded/redacted job details. Queued
  follow-ups are capped while a turn is streaming so the composer keeps overflow
  text instead of silently growing an unbounded queue. Approval review sheets now
  use bounded/redacted prompt and risk previews with explicit truncation copy for
  mobile review plus a copy action for bounded/redacted approval details. Server-audio honesty now treats either advertised `audio_api` or
  `realtime_voice` as blocked until Navivox wires real server audio. Bounded
  diagnostics now explicitly labels secrets, raw logs, tool payloads,
  transcripts, and local paths as excluded, and redacts dynamic metadata fields
  such as active session title, health strings, capability
  model/features/endpoints, and model names. Tool progress cards redact and bound tool names/results before rendering, and run
  transport now uses Hermes tool-call ids when present so parallel same-name tool
  calls do not collapse into one card. Hermes endpoint setup now strips URL
  userinfo, query strings, fragments, and route paths before connecting,
  loading, or persisting profile metadata, keeping API keys out of shared
  preferences. Android live-mic receipts now also record only the sanitized
  Hermes origin and the readiness audit rejects copied route/path state. Run
  approval events accept `approval_id`, `approvalId`, or `id` plus
  `tool_call_id`/`toolCallId` aliases so mobile approval prompts do not fail
  when Hermes event casing differs. The Hermes jobs sheet now labels itself as
  read-only even when `jobs_admin` is advertised, avoiding implied mobile
  create/edit/delete scheduling support. Queued follow-up auto-send failures now
  keep the message queued while showing bounded/redacted recovery copy. UI,
  diagnostics, and Android live-mic receipt gates redact/reject additional
  token shapes, whitespace-only observed excerpts, and invalid/non-origin
  Hermes URLs such as GitHub tokens, Slack tokens, JWT-like strings,
  diagnostic cookie headers, bare Basic credentials, and URL userinfo. Hermes
  channel stored error messages now share the broader redaction set and are
  bounded before entering channel state. Mobile approval review redaction now
  also handles equals-style Authorization/Cookie headers. Android live-mic
  receipt validators now
  also require an explicit `NAVIVOX_ANDROID_PHYSICAL_MIC_OBSERVED=true` gate,
  document that copied route/path state is stripped from recorded Hermes URLs,
  and reject Basic credentials, credential headers, and URL userinfo in spoken
  phrase/provider reply excerpts. Provider-smoke receipts are now audited for a
  current `head_sha`, sanitized origin-only `base_url`, and explicit
  non-evidence caveats for platform workflow/deferred parity. Provider-smoke
  receipts now also carry explicit evidence items for provider-backed typed text
  and deterministic transcript voice only. README platform/provider smoke copy is
  refreshed to describe the published workflow receipt and current provider
  receipt audit fields instead of the old workflow-scope push blocker.

## Honest caveat

Provider-backed Hermes web text and transcript-voice smoke now passes against a
configured local Hermes home, and installed-Hermes live connect smoke passes
against a temp-home API server. That still does not prove physical microphone
capture or Hermes realtime/server audio: Navivox voice remains local device STT
(or deterministic transcript capture in tests) submitted as normal Hermes text.
The Android emulator receipts were collected on a headless/software emulator,
including one launched with `-no-audio`, so they are not real spoken-audio
receipts. `SecureHermesEndpointStore` now keeps multi-endpoint profile metadata
in shared preferences while per-profile API keys remain in platform secure
storage, and profile label/rename UI redacts secret-looking labels while
preserving those keys without echoing them into shared storage or dialog copy;
preset chips clear selected profile secret/label fields before switching origins.

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
