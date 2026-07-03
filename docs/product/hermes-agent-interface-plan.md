# Hermes Agent interface plan for Navivox

Status: planning note for steering Navivox away from Gormes-only runtime toward Hermes Agent-only operation. The current Gormes-first app state is preserved on the `gormes` branch at `b0b4390`; this plan targets future work on `main` or a new Hermes-focused delivery branch.

**Amendment (see [ADR 0007](../adr/0007-native-hermes-channel-not-navivox-channel-adapter.md)):** the early transition-seam idea that adapted Hermes to the old Gormes-shaped `NavivoxChannel` interface is superseded. Navivox builds a native `HermesChannel` abstraction sized to Hermes's actual surface. Old Gormes-only screens (profile contacts, config-admin, memory, profile seed, voice profiles, run-record) are not wired to Hermes; new chat/session/voice screens are built against the native channel. The rest of this document (Hermes surface coverage table, target product model, MVP chat/session/streaming mapping) still holds as the source of truth for *what* Hermes surface to expose and in what order — only the *how* (adapter vs. native) changed.

## Decision

Interface Navivox directly with Hermes Agent's native API server first, not through the existing Gormes `/v1/navivox/*` protocol and not through ACP.

Why:

- Hermes Agent already exposes an HTTP/SSE API server intended for external UIs: `/health`, `/v1/capabilities`, `/api/sessions`, `/api/sessions/{session_id}/chat/stream`, `/v1/runs`, `/v1/runs/{run_id}/events`, `/v1/runs/{run_id}/approval`, `/v1/runs/{run_id}/stop`.
- Navivox already has a channel abstraction and UI concepts that can be mapped onto Hermes sessions/runs while we rename product language.
- A compatibility shim that makes Hermes pretend to be a Gormes Navivox gateway would preserve old code temporarily, but it would also keep the wrong domain model alive: profile contacts, Gormes config-admin, Gormes durable credentials, and `/v1/navivox` capabilities.
- ACP is a good editor/agent-client protocol but is not the best first mobile interface: it assumes ACP sessions, editor-oriented resources, and JSON-RPC-ish agent updates. Hermes API server is simpler for a mobile chat/control app.

## Current contracts found

### Hermes Desktop study

Reference studied: `fathah/hermes-desktop` at commit `6d89b05` in `/tmp/hermes-desktop-study`.

What to copy:

- **Local/remote setup split.** Hermes Desktop first asks whether the operator wants local Hermes or a remote Hermes API server, then validates URL + key. Navivox should use the same mental model, with Android-specific URL hints.
- **Capability-gated run transport.** `src/main/run-stream.ts` enables `/v1/runs` only when `/v1/capabilities` advertises `run_submission`, `run_events_sse`, `run_stop`, `run_approval_response`, `tool_progress_events`, and exact endpoint paths. Navivox should do the same instead of assuming every Hermes build is new enough.
- **Fallback from runs to chat streaming.** Hermes Desktop starts with `/v1/runs` where possible but falls back to `/v1/chat/completions` when run start/events fail or approval would deadlock old UI. Navivox's MVP should invert this: use `/api/sessions/{id}/chat/stream` as the stable session-chat path, then add `/v1/runs` for controls when the UI can render approvals.
- **Explicit client session IDs.** Hermes Desktop generates `desk-<timestamp>-<uuid>` and sends `X-Hermes-Session-Id` to avoid server fingerprint collisions. Navivox should generate `navi-<timestamp>-<uuid>` (or equivalent) for new sessions and store the returned/effective session id.
- **SSE parsers are test seams.** Hermes Desktop has standalone SSE parsing (`src/main/sse-parser.ts`, `src/main/run-stream.ts`) and regression tests. Navivox should make Dart SSE parsing pure and fixture-tested before wiring UI.
- **End-of-stream reconciliation.** The desktop reconciles streamed text against DB/session history to preserve text around tool calls. Navivox should reload or reconcile `GET /api/sessions/{id}/messages` after a completed stream before declaring transcript final.
- **Do not block on Desktop-only surfaces.** Desktop manages install, profiles, models, memory, schedules, gateway platforms, office, backups, logs, and updater. Navivox should only bring over mobile-relevant chat/session/run setup first; the rest waits for Hermes APIs and mobile UX need.

What not to copy now:

- Electron local install orchestration and updater mechanics.
- Desktop-specific remote dashboard token header (`X-Hermes-Session-Token`) unless Hermes Agent API server documents it for this path; Navivox should use bearer auth for the API server first.
- Legacy `/v1/chat/completions` as primary app state. It is useful fallback, but `/api/sessions/*` better matches mobile session navigation.

### Navivox today

Current Dart client expects a Gormes Navivox gateway:

- `GET /healthz`
- `GET /v1/navivox/status`
- `GET /v1/navivox/capabilities`
- `GET /v1/navivox/profile-contacts`
- `GET /v1/navivox/profile-routing`
- `POST /v1/navivox/turn`
- `WS /v1/navivox/stream`
- optional config-admin, memory, voice-profile, run-record, profile-seed, and durable-reconnect endpoints.

The WebSocket sends Navivox messages such as `start_turn`, `cancel_turn`, `stop_turn`, and `subscribe_session`, then receives gateway events decoded into transcript, tool, approval, and session state.

### Hermes Agent available surface

Hermes Agent API server (`gateway/platforms/api_server.py`) exposes:

- `GET /health` and `/health/detailed` for liveness/status.
- `GET /v1/capabilities` with feature flags and endpoint paths.
- `GET /v1/models`.
- `GET /v1/skills` and `/v1/toolsets`.
- `GET /api/sessions`, `POST /api/sessions`, `GET/PATCH/DELETE /api/sessions/{session_id}`.
- `GET /api/sessions/{session_id}/messages`.
- `POST /api/sessions/{session_id}/fork`.
- `POST /api/sessions/{session_id}/chat` and `/chat/stream`.
- `POST /v1/runs`, `GET /v1/runs/{run_id}`, `GET /v1/runs/{run_id}/events`.
- `POST /v1/runs/{run_id}/approval` and `/stop`.

Auth is bearer-token based (`API_SERVER_KEY` when configured). The default API server port is `8642`.

## Target product model

Rename the main runtime concepts instead of keeping Gormes words in operator UI.

| Current Navivox/Gormes concept | Hermes-first concept | Notes |
| --- | --- | --- |
| Gormes gateway | Hermes endpoint / Hermes Agent server | One configured Hermes API server. |
| Profile contact | Conversation / session | Hermes sessions are the durable chat lane. |
| Profile contact list | Sessions list | Backed by `GET /api/sessions`; empty state can create a session. |
| Run record | Run evidence | Backed by `/v1/runs/{run_id}` and run SSE events. |
| Config admin | Out of MVP | Hermes config stays in Hermes setup/CLI until a native API exists. |
| Goncho memory console | Out of MVP | Hermes memory APIs are not exposed here yet. |
| Durable reconnect credential | Saved Hermes endpoint + API key | Store API key in secure storage, not shared prefs. |
| Pairing handoff | Hermes connection setup | Manual URL + API key first; QR/deep link later. |

## Full Hermes surface coverage

The plan must consider every Hermes Desktop/Hermes Agent surface, but not every surface belongs in the first mobile MVP. Default assumption: Navivox becomes a Hermes mobile companion/operator app first, not a full Electron Desktop replacement on day one.

| Surface | Hermes evidence | Navivox treatment | First path |
| --- | --- | --- | --- |
| Chat | Desktop primary screen; API server `/api/sessions/{id}/chat/stream`, `/v1/chat/completions`, `/v1/runs` | **MVP** | Session chat stream, pure SSE decoder, transcript reconciliation. |
| Sessions/history | Desktop Sessions screen; API server `/api/sessions`, `/messages`, `/fork` | **MVP** | List/create/resume sessions; rename/delete/fork after chat works. |
| Run controls/evidence | Desktop `run-stream.ts`; API server `/v1/runs/*` | **MVP+** | Gate on capabilities; add stop/approval/run event cards after chat stream MVP. |
| Tool progress | Desktop renders tool started/completed/failed; API server emits tool events | **MVP** | Map tool SSE/run events to current tool cards; redact unsafe payloads. |
| Approvals | API server `/v1/runs/{run_id}/approval`; Desktop currently falls back when hidden approval would deadlock | **MVP+** | Do not enable run transport for approval-heavy flows until Navivox renders active approval prompts. |
| Continuous voice mode | Navivox already has local continuous voice settings; Hermes API server has no realtime voice API, Desktop uses local/recorded transcription helpers | **MVP local-only** | Keep device STT/continuous capture in Navivox, submit transcripts as text turns; no server TTS/realtime voice promise until Hermes exposes audio/realtime APIs. |
| Push-to-talk / one-shot voice | Navivox voice run lifecycle; Hermes Desktop voice input needs local Hermes STT support | **MVP local-only** | Device transcription -> Hermes text turn; mark server STT/TTS unavailable. |
| TTS / spoken replies | Navivox local setting exists; Hermes Agent has TTS providers but no mobile API contract in current evidence | **Later** | Use platform TTS locally only if cheap; otherwise hide. |
| Config | Desktop manages config/model/provider files and health; API server capabilities say `admin_config_rw: False` | **Out of MVP** | Replace Gormes config-admin with read-only connection/config-health notes until Hermes exposes safe config APIs. |
| Models/providers | Desktop Models/Providers screens; API server `/v1/models`, Desktop config writers | **MVP read-only, edit later** | Show current model/capabilities; editing waits for Hermes config API or explicit CLI-backed design. |
| Skills/toolsets | API server `/v1/skills`, `/v1/toolsets`; Desktop has Skills/Tools screens | **MVP read-only** | Browse enabled skills/toolsets; enabling/disabling later. |
| Memory | Desktop Memory screen; Hermes memory providers exist, but current API capabilities report `memory_write_api: False` | **Later** | Hide Goncho memory; add Hermes memory only when read/list/search APIs are explicit. |
| Schedules/cron | Desktop Schedules screen; API server `/api/jobs` routes exist in current source | **MVP read-only, admin later** | Show read-only job inventory when `/api/jobs` is advertised; schedule/job mutation waits for explicit safe admin contracts, auth, and confirmation UX. |
| Messaging gateways | Desktop Gateway screen for Telegram/Discord/etc. | **Later** | Mobile can show status eventually; setup/admin is too broad for first cut. |
| Profiles/environments | Desktop profiles isolate Hermes homes/config | **Later** | Treat one Hermes endpoint first; multi-profile selection later maps to endpoint/profile config, not old Profile contacts. |
| Persona/SOUL | Desktop Persona screen edits SOUL.md | **Later** | Needs explicit Hermes API or safe file/CLI flow; do not edit remotely by guessing paths. |
| Office/Claw3d | Desktop Office screen and adapter management | **Out of mobile MVP** | Link/status only, if anything. |
| Attachments/media | Navivox has composer/media seams; Hermes chat endpoints accept multimodal in some paths | **MVP text, images later** | Start text-only + device STT; add image attachments after API fixture coverage. |
| Files/context folder | Desktop context-folder support; mobile filesystem semantics differ | **Later** | Defer until a mobile-safe workspace picker/remote path story exists. |
| Local install/update | Desktop installs/updates Hermes locally | **Out of mobile MVP** | Navivox connects to existing Hermes endpoint; Android Termux install can be a runbook later. |
| Remote/SSH mode | Desktop supports remote URL/SSH tunnel | **MVP remote URL only** | URL + API key first; SSH tunnel is not mobile-native and waits. |
| Secrets/auth | Desktop stores API keys; Hermes API server uses bearer `API_SERVER_KEY` | **MVP** | API key in secure storage only; no shared-pref leak; no screenshots/log echo. |
| Logs/debug dump | Desktop Settings surfaces logs/backup/debug | **Bounded diagnostics now, raw logs later** | Export safe status/capability/readiness counts only; raw logs, transcript contents, tool payloads, and secrets stay excluded. |
| i18n/theme/accessibility | Desktop has i18n/theme; Flutter app has platform accessibility needs | **Always** | Keep basic accessibility and clear mobile copy in every slice. |

Hard default from the grill: **ship mobile chat/session/voice-to-text first, with every other Hermes surface either read-only, hidden, or explicitly deferred.** Consequence: the app becomes useful quickly without reimplementing Hermes Desktop in Flutter; full parity remains a roadmap, not a prerequisite.

## Recommended architecture

### 1. Add a Hermes transport/client package

Create `lib/core/hermes/` with:

- `HermesApiConfig`: base URL, bearer token, normalized endpoint URIs.
- `HermesApiClient`: `health`, `capabilities`, `listSessions`, `createSession`, `sessionMessages`, `streamSessionChat`, `startRun`, `runEvents`, `respondApproval`, `stopRun`.
- `HermesSseEventDecoder`: parses server-sent events into typed Dart events. Keep it pure like Hermes Desktop's `sse-parser.ts` / `run-stream.ts`.
- `HermesTransportPolicy`: capability checks mirroring Hermes Desktop's `supportsHermesRunsTransport`, but with `/api/sessions/{id}/chat/stream` as the first MVP path.
- focused tests using fixtures copied from Hermes API server shapes and Hermes Desktop parser tests.

Do not mutate the existing Gormes client in place; use a parallel client so tests can compare the old preserved branch if needed.

### 2. Implement a native `HermesChannel`

ADR 0007 supersedes the early adapter idea: Hermes should not be squeezed into
the old Gormes-shaped `NavivoxChannel` contract. Use a parallel native
`HermesChannel` and Hermes session terminology.

Mapping:

- `connect(baseUrl, token)` -> `GET /health`, `GET /v1/capabilities`, then `GET /api/sessions`.
- `state.sessions` -> Hermes sessions loaded from the endpoint.
- `sendText(text)` -> start/continue the selected Hermes session.
- `cancelActiveTurn` / `stopActiveTurn` -> `/v1/runs/{run_id}/stop` when using run transport.
- `respondToApproval` -> `/v1/runs/{run_id}/approval`.
- Voice runs -> local device transcript submitted as a normal Hermes text turn.

Legacy Gormes screens can remain preserved during transition, but new Hermes work
uses the native channel and `/hermes` surface.

### 3. Use session chat streaming for MVP, then run streaming for full control

MVP chat path:

1. If no session exists, create a client id such as `navi-<timestamp>-<uuid>` and `POST /api/sessions`.
2. Load history with `GET /api/sessions/{session_id}/messages`.
3. Send a turn with `POST /api/sessions/{session_id}/chat/stream`, carrying `X-Hermes-Session-Id` and `X-Hermes-Session-Key` when appropriate.
4. Map SSE events:
   - `run.started` -> local pending turn state.
   - `message.started` -> assistant placeholder.
   - `assistant.delta` -> append assistant text.
   - `tool.started`, `tool.progress`, `tool.completed`, `tool.failed` -> tool cards.
   - `assistant.completed` / `run.completed` -> finalize.
   - `error` -> bounded system error.
   - `done` -> close stream.
5. Reconcile final transcript with `GET /api/sessions/{session_id}/messages` after completion, preserving streamed text when it contains pre-tool-call content not present in the final assistant field.

Full control path:

- Use `/v1/runs` + `/v1/runs/{run_id}/events` when approval prompts and stop/cancel become required.
- Map run events:
  - `message.delta` -> assistant delta.
  - `tool.started/completed/failed`, `reasoning.available` -> tool/thinking cards.
  - `approval.request` -> approval prompt with choices `once`, `session`, `always`, `deny`.
  - `approval.responded` -> approval resolved.
  - `run.completed/failed/cancelled` -> final turn state.

Open verification before choosing the final send path: confirm whether `/v1/runs` with explicit `session_id` reloads/persists transcript history the same way `/api/sessions/{id}/chat/stream` does. If not, keep `/chat/stream` for normal chat and add a small Hermes API enhancement for approval callbacks on session chat streams.

### 4. Replace setup/persistence safely

- Setup form becomes: Hermes API base URL, API key, optional session selector.
- Default hints:
  - local desktop: `http://127.0.0.1:8642`
  - Android emulator hitting host: `http://10.0.2.2:8642`
  - physical Android: LAN/VPN/Tailscale host URL.
- Save non-secret base URL in shared preferences.
- Save API key only in secure storage.
- Remove Gormes durable credential issuance from Hermes mode.
- Keep QR/deep-link setup as a later convenience format, e.g. `hermes://connect?base_url=...` where the API key is treated as secret material.

### 5. Hide or remove unsupported surfaces early

Until Hermes exposes equivalent APIs, disable or remove:

- Gormes config-admin screens.
- Goncho memory console.
- Profile seed.
- Voice profile configuration.
- Gormes gateway management copy.

Keep local device STT: voice can still transcribe on-device and submit text into a Hermes session.

## Delivery slices

1. **Docs/domain reset**
   - Add this plan.
   - Add a follow-up ADR superseding `docs/adr/0005-gormes-first-navivox-with-hermes-desktop-as-reference.md`.
   - Update `CONTEXT.md` terms from Gormes gateway/profile contact to Hermes endpoint/session.

2. **Hermes API client fixtures**
   - Add typed Dart models for `/health`, `/v1/capabilities`, sessions, messages, and SSE events.
   - Add pure Dart SSE parser tests based on Hermes Desktop `sse-parser.ts` and `run-stream.ts` behavior: multi-line `data:`, named events, malformed chunks skipped, usage extraction, tool events, reasoning events, and `[DONE]`/done close.

3. **Native Hermes channel**
   - Add a parallel `HermesChannel`/`HermesChannelState` shaped around Hermes sessions/messages, per ADR 0007.
   - Keep legacy Gormes screens preserved separately while `/hermes` becomes the native Hermes surface.
   - Gate `/v1/runs` use on `/v1/capabilities`; fall back to session chat stream when run transport is missing or not safe.
   - Tests: connect, list/create session, load messages, stream assistant deltas, stream tool events, reconcile final messages, fail boundedly.

4. **Setup flow conversion**
   - Replace Gormes pairing copy with Hermes connection setup.
   - Store API key in secure storage.
   - Test no API key leaks into shared preferences, logs, screenshot text, or route state.

5. **Surface gating pass**
   - Add one central Hermes capability/readiness projection for chat, sessions, runs, skills/toolsets, jobs, models, config, memory, voice, and diagnostics.
   - Hide unsupported Gormes-era screens rather than leaving broken navigation.
   - Tests: config and memory show Hermes-unavailable/read-only states; continuous voice remains local transcript submission; unsupported run approval controls do not appear.

6. **Chat/session UI rename**
   - Convert profile contacts to sessions/conversations.
   - Add session create, rename, delete, fork affordances using `/api/sessions` APIs.

7. **Run controls**
   - Add run event stream support for approvals and stop.
   - Wire `respondToApproval` to `/v1/runs/{run_id}/approval`.
   - Wire stop/cancel to `/v1/runs/{run_id}/stop`.

8. **Remove Gormes-only code paths**
   - Delete `/v1/navivox/*` client pieces from main once Hermes path is green.
   - Keep recoverability through the already-pushed `gormes` branch.

9. **Android live smoke**
   - Run Hermes API server locally.
   - Connect from emulator using `10.0.2.2:8642`.
   - Connect from physical Android over LAN/Tailscale.
   - Verify typed text, one-shot voice-to-text, continuous voice-to-text, streaming assistant response, tool card, approval, stop, and app restart reconnect.

## Risks and decisions to make

- **Session chat vs run API:** `/api/sessions/{id}/chat/stream` is better for persisted chat; `/v1/runs` is better for approvals/stop. Verify persistence behavior before committing to one path.
- **Hermes API key lifecycle:** Hermes does not appear to expose a Navivox-style pairing/durable credential issue endpoint. First version should require manual API key entry and secure storage.
- **Domain rename scope:** Keeping `ProfileContact` internally for too long will slow us down. Use it only as a transition seam.
- **Config/memory parity:** Do not rebuild Gormes config-admin/memory screens until Hermes has explicit APIs for them.
- **Continuous voice:** Keep it as local repeated STT-to-text turns. Do not imply Hermes realtime voice or server TTS until the API exists.
- **Prompt-cache safety:** Hermes treats prompt caching and stable conversation history as core constraints. Navivox must not mutate or resend old context unpredictably; prefer server-owned session history.

## First implementation recommendation

Build a thin Hermes client and fixture-tested SSE decoder first. Then expose it through a native `HermesChannel` and dedicated `/hermes` UI instead of adapting Hermes to the old `NavivoxChannel` interface. Keep legacy Gormes screens preserved during transition, but new work should use Hermes endpoint/session/run language directly.
