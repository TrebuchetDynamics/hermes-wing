# Hermes Desktop Architecture Map

A practical source map of the local `hermes-desktop/` reference checkout for studying Hermes Wing bugs. It describes the checkout at commit `3aaadb01076a749d7f9389dca4ffce081cf8ebaa` (the `0.7.4` reference used by the existing feature study), not a promise that every declared API is currently reachable in the UI.

> **Important:** Hermes Desktop is reference material. Hermes Agent owns agent/domain state. Wing Link owns host management. Do not port Desktop's filesystem, CLI, SQLite, SSH, or Electron mechanisms into Wing.

Related Wing documents: [Desktop feature study](../docs/product/hermes-desktop-feature-study.md), [client ADR](../docs/adr/client.md), [API and state ADR](../docs/adr/api-and-state.md).

## 1. One-page system map

```text
┌──────────────────────────────── Hermes Desktop ────────────────────────────────┐
│                                                                                │
│  React renderer                                                                │
│  src/renderer/src/main.tsx                                                    │
│        │                                                                       │
│        ▼                                                                       │
│  App.tsx → Layout.tsx → screen/components/hooks                                │
│        │  calls window.hermesAPI                                               │
│        ▼                                                                       │
│  Context-isolated preload                                                     │
│  src/preload/index.ts + index.d.ts                                             │
│        │  contextBridge; ipcRenderer.invoke/on                                 │
│        ▼                                                                       │
│  Electron main process                                                         │
│  src/main/app/start.ts → ipc/register.ts                                      │
│        │                                                                       │
│        ├── local host adapters: CLI/processes, ~/.hermes, YAML, JSON, SQLite  │
│        ├── local API: gateway /v1, /health, SSE                               │
│        ├── Dashboard: /api/* and /api/ws JSON-RPC/WebSocket                  │
│        ├── remote HTTP: direct Dashboard API                                  │
│        ├── SSH: exec + one local port-forwarded tunnel                       │
│        ├── account/registry/wallet integrations                               │
│        └── Electron OS services: windows, menus, updater, webviews, dialogs   │
│                                                                                │
└───────────────┬───────────────────────────────┬────────────────────────────────┘
                │                               │
                ▼                               ▼
        Hermes Agent host                 Optional Hermes One services
        gateway / dashboard               account, registry, credits, sync
        profiles, runs, state.db
```

### The most important split

Desktop has two different Hermes transports:

| Transport              | Main endpoint                                             | Typical use                                       | Do not confuse it with |
| ---------------------- | --------------------------------------------------------- | ------------------------------------------------- | ---------------------- |
| **Gateway/API server** | `/health`, `/v1/*`, `/v1/chat/completions`                | legacy chat, run APIs, local gateway health       | Dashboard `/api/*`     |
| **Dashboard**          | `/api/status`, `/api/sessions`, `/api/model/*`, `/api/ws` | current chat JSON-RPC stream and management reads | Gateway `/v1/*`        |

The Dashboard is not a `/v1` superset. A tunnel pointed at the wrong process can look healthy while chat fails with a 404/405 or an authentication error.

## 2. Process and trust boundaries

| Layer    | Source                               | Responsibility                                                                                            | Bug-triage question                                                                    |
| -------- | ------------------------------------ | --------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| Renderer | `src/renderer/src/`                  | React state, navigation, transcript rendering, input, accessible presentation                             | Did UI state or event filtering lose the operation?                                    |
| Preload  | `src/preload/index.ts`, `index.d.ts` | Small context-isolated typed bridge; no direct renderer Node access                                       | Is the method/event declared and wired with the same argument order?                   |
| Main     | `src/main/`                          | Privileged filesystem/process/network access, IPC handlers, transport routing, lifecycle                  | Did the correct profile, mode, endpoint, credential, and source of truth get selected? |
| Shared   | `src/shared/`                        | Cross-layer types and pure protocol helpers                                                               | Is the wire shape normalized consistently?                                             |
| Agent    | external Hermes installation         | Authoritative profiles, projects, providers, models, sessions, runs, tools, schedules, gateway, and state | Is the assumed contract actually advertised by this Agent version?                     |

`src/main/app/start.ts:createWindow` enables `nodeIntegration: false`, `contextIsolation: true`, `sandbox: true`, and `webSecurity: true`. `src/main/security.ts` gates navigation, popups, and webview URLs. Renderer code must reach privileged behavior through the preload bridge, not by importing Node APIs.

At this snapshot, `src/main/ipc/register.ts` contains 138 `ipcMain.handle` channels. The preload exposes 244 public methods/events, so the two counts are intentionally not one-to-one: some methods are renderer-only helpers, notifications, or bridge aliases. The authoritative bridge contract is `src/preload/index.d.ts` plus the corresponding handler.

## 3. Boot and screen lifecycle

```text
src/main/index.ts
  ├─ loadDotEnvForDev()
  ├─ applyGpuPreferences(), installGpuCrashGuard()
  └─ startMainProcess()
       ├─ registerIpcHandlers()
       ├─ setupUpdater()
       ├─ app.whenReady()
       │    ├─ security hooks / CSP / webview hardening
       │    ├─ createWindow()
       │    └─ buildMenu()
       └─ before-quit cleanup
            ├─ stop health polling and active runs
            ├─ stop dashboards and SSH tunnel
            ├─ remove temporary media
            └─ close SQLite connection
```

Renderer bootstrap:

```text
src/renderer/src/main.tsx
  └─ I18nProvider → App
       └─ ThemeProvider → FontProvider → ChatPreferencesProvider
            → ProfileModalProvider → SettingsModalProvider
                 → ErrorBoundary → selected screen
```

`App.tsx` starts on `splash`, checks the saved connection, and chooses `welcome`, `installing`, `setup`, or `main`. Local mode checks `~/.hermes` installation/configuration; remote mode skips local installation checks; SSH mode starts a tunnel attempt and enters the main shell. Deep install verification runs after the UI is shown so a slow Python probe does not block startup.

The main shell in `screens/Layout/Layout.tsx` keeps visited panes mounted and toggles their display. Chat runs are also kept mounted: each `ChatRun` has a stable `runId`, profile, optional Agent session ID, title, loading state, and transcript. Only the active run is visible, but background runs continue to receive events.

## 4. Renderer navigation map

Current navigation is defined in `src/renderer/src/screens/Layout/Layout.tsx`; the README's older standalone-screen list is not the source of truth.

| Visible area    | Renderer entry                             | Main responsibility                                                 | Current placement                  |
| --------------- | ------------------------------------------ | ------------------------------------------------------------------- | ---------------------------------- |
| Chat            | `screens/Chat/Chat.tsx`                    | compose, send, stream, tool/reasoning/approval timeline, media      | default pane                       |
| Recent sessions | `screens/Layout/SidebarRecentSessions.tsx` | cached list, resume, delete, context-folder indicators              | sidebar                            |
| Sessions        | `screens/Sessions/Sessions.tsx`            | search, filter, resume, rename, bulk delete                         | modal from sidebar/menu            |
| Discover        | `screens/Discover/Discover.tsx`            | skill/MCP/agent/workflow catalogs                                   | pinned navigation                  |
| Agents          | `screens/Agents/Agents.tsx`                | profile management and profile modal entry                          | Profile Switcher → Manage profiles |
| Providers       | `screens/Providers/Providers.tsx`          | provider keys, OAuth status, model picker/library, auxiliary models | footer navigation                  |
| Skills          | `screens/Skills/Skills.tsx`                | installed/bundled skills                                            | embedded/handoff path, not pinned  |
| Memory          | `screens/Memory/Memory.tsx`                | memory entries/providers and persona entry                          | footer navigation                  |
| Tools           | `screens/Tools/Tools.tsx`                  | toolset and MCP controls                                            | footer navigation                  |
| Gateway         | `screens/Gateway/Gateway.tsx`              | gateway lifecycle, messaging platform cards, platform toolsets      | footer navigation                  |
| Schedules       | `screens/Schedules/Schedules.tsx`          | cron list/create/pause/resume/trigger/delete                        | pinned navigation                  |
| Kanban          | `screens/Kanban/Kanban.tsx`                | boards/tasks/lifecycle                                              | pinned navigation                  |
| Office          | `screens/Office/Office.tsx`                | React Three Fiber office, agent status, wallets, Office chat        | pinned navigation                  |
| Settings        | `components/settings/SettingsModal.tsx`    | appearance, language, privacy, connection, data, diagnostics, logs  | global modal                       |

### Chat component map

```text
Chat.tsx
  ├─ useModelConfig / useFastMode / useReasoningEffort
  ├─ useChatIPC                 ← legacy IPC event channels + DB refresh
  ├─ useDashboardChatTransport  ← Dashboard WebSocket JSON-RPC + events
  ├─ useChatActions              ← slash routing, send/abort/approve/deny
  ├─ ChatInput                   ← text, slash menu, files, voice, folder
  ├─ MessageList / MessageRow    ← bubbles, reasoning, tools, approvals
  ├─ ContextGauge / ContextFolderChip / WorktreePanel
  └─ WebPreviewPanel / media/file attachment UI
```

`Layout.tsx` owns run switching. `Chat.tsx` owns per-run session/transcript state. `useChatIPC.ts` and `useDashboardChatTransport.ts` both listen to global event surfaces, so every listener must filter to its own `runId` or runtime session. This is a major source of multi-chat bugs.

## 5. IPC bridge map

The normal call path is:

```text
renderer component/hook
  → window.hermesAPI.method(...)
  → preload ipcRenderer.invoke("channel", ...)
  → ipcMain.handle("channel", ...)
  → main adapter
  → local Agent / remote Agent / SSH host / account service
  → typed result or pushed event
```

Progress and streaming reverse direction:

```text
Agent SSE/WebSocket or child process
  → main callback
  → event.sender.send("chat-*" / "install-*" / "oauth-*", payload)
  → preload listener with cleanup function
  → renderer state reducer/hook
```

### IPC groups

| Group                  | Representative bridge channels                                                                                           | Main implementation                                           |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------- |
| Install/lifecycle      | `check-install`, `start-install`, `verify-install`, `run-hermes-update`, `run-hermes-doctor`                             | `installer.ts`, `ipc/register.ts`                             |
| Connection             | `get-connection-config`, `set-connection-config`, `connect-remote-gateway`, `set-ssh-config`                             | `config.ts`, `remote-oauth.ts`, `ssh-tunnel.ts`               |
| Chat                   | `send-message`, `abort-chat`, `transcribe-audio`, `clarify-respond`                                                      | `hermes.ts`, `run-stream.ts`, `tui-gateway-stream.ts`         |
| Chat events            | `chat-session-started`, `chat-chunk`, `chat-reasoning-chunk`, `chat-tool-event`, `chat-usage`, `chat-done`, `chat-error` | `ipc/register.ts` callbacks                                   |
| Dashboard              | `start-dashboard`, `dashboard-status`, `fresh-dashboard-ws-url`                                                          | `dashboard.ts`, `remote-api.ts`, `remote-sessions.ts`         |
| Sessions               | `list-sessions`, `get-session-messages`, `search-sessions`, `delete-session(s)`                                          | `sessions.ts`, `remote-sessions.ts`, `ssh-remote.ts`          |
| Session-local overlays | `record-session-continuation`, `record-session-local-error`, context/model override channels                             | `session-continuation-store.ts`, related stores               |
| Profiles               | `list-profiles`, `create-profile`, `delete-profile`, `set-active-profile`                                                | `profiles.ts`                                                 |
| Provider/model         | `get/set-env`, `get/set-config`, `get/set-model-config`, model library and credential-pool channels                      | `config.ts`, `models.ts`, `providers-store.ts`, `secrets/`    |
| Skills/tools/MCP       | skill, toolset, MCP, registry channels                                                                                   | `skills.ts`, `tools.ts`, `mcp-servers.ts`, `registry.ts`      |
| Memory/persona         | `read-memory`, memory mutations, `read/write/reset-soul`                                                                 | `memory.ts`, `soul.ts`                                        |
| Gateway/platforms      | `start/stop/restart-gateway`, platform read/update/test                                                                  | `hermes.ts`, `messaging-platforms.ts`                         |
| Schedules/Kanban       | `list/create/pause/resume/trigger-cron-job`, `kanban-*`                                                                  | `cronjobs.ts`, `kanban.ts`                                    |
| Media/files            | attachment staging, media read/save, directory/file viewer, terminal launch                                              | `media.ts`, `attachment-staging.ts`, `terminal-launcher.ts`   |
| Office/account         | Claw3D, wallet, Hermes One account and agent sync                                                                        | `claw3d.ts`, `wallet-*`, `hermes-account.ts`, `agent-sync.ts` |
| Native shell           | external URLs, menus, updater, GPU, spell checker                                                                        | `app/`, `updater.ts`, `gpu-fallback.ts`                       |

When debugging a bridge issue, compare all three locations: the renderer call, the preload declaration/implementation, and the main handler. A typed declaration alone does not prove a handler or a reachable UI path exists.

## 6. Connection and transport decision tree

```text
getConnectionConfig() from ~/.hermes/desktop.json
  │
  ├─ local
  │    ├─ start local gateway when needed
  │    ├─ gateway API: http://127.0.0.1:<profile port>/v1/*
  │    ├─ Dashboard: spawn `hermes dashboard` on a free loopback port
  │    └─ legacy fallback: main-process HTTP/SSE or CLI path
  │
  ├─ remote
  │    ├─ direct Dashboard HTTP/WebSocket when configured/available
  │    ├─ token auth: X-Hermes-Session-Token / bearer as appropriate
  │    ├─ OAuth auth: persistent Electron cookie partition + WS ticket
  │    └─ `auto` may fall back to legacy remote API; forced Dashboard fails
  │
  └─ ssh
       ├─ ssh-remote.ts executes fixed remote helper commands
       ├─ ssh-tunnel.ts owns one global local port-forwarded tunnel
       ├─ preferred target: remote `hermes dashboard` → /api/* + /api/ws
       └─ fallback target: remote gateway api_server → /v1/*
```

`src/main/hermes.ts:sendMessage` uses this local/remote split:

1. Remote/SSH uses API-oriented transport; it does not spawn a local gateway.
2. Local mode checks API-server health and may start/recover the gateway.
3. Local text-only or compatible cases can use the API fast path.
4. A CLI fallback remains for local cases when the API server is unavailable.
5. Session model overrides can force a local CLI limitation; attachments are not equivalent on that path.

`src/renderer/src/screens/Chat/hooks/useDashboardChatTransport.ts` is the current renderer Dashboard path. It starts/probes the Dashboard, connects `DashboardGatewayClient`, creates/resumes a runtime session, optionally switches model via `slash.exec`, then sends prompts and reduces events. In `auto`, an absent Dashboard can latch a fallback-to-legacy decision; a transient WebSocket drop is retried instead of being mistaken for a missing Dashboard.

### Profile scoping

- Local gateways use per-profile homes and allocated ports (`gateway-ports.ts`).
- Named-profile Dashboard requests use `?profile=<id>` where the server is a unified machine Dashboard.
- SSH Dashboard uses one tunnel and one remote Dashboard for all profiles; `profile` query scoping is therefore mandatory.
- `activeSshProfile()` falls back to the persisted active profile when a caller omitted the profile.
- `Layout.tsx` keeps a visible `activeProfile` aligned with each run's profile; existing background runs remain attached to their original profile.

## 7. Chat/run lifecycle map

### Dashboard path

```text
submit in ChatInput
  → useChatActions
  → useDashboardChatTransport.sendMessage()
  → ensureClient()
       → startDashboard()
       → freshDashboardWsUrl()
       → DashboardGatewayClient.connect()
  → ensureRuntimeSession()
       → session.resume(stored id)
       → or session.create(seed transcript, profile, cwd)
  → ensureSelectedModel()
       → model.options / slash.exec / validation
  → image.attach_bytes and/or file.attach
  → prompt.submit
  → Dashboard events
       message.start / reasoning.delta / tool.* / message.delta /
       clarify.request / message.complete / background.complete
  → dashboardEventAdapter
  → messagesRef + React messages
  → completion reconciliation and optional local overlay persistence
```

### Legacy IPC path

```text
Chat action
  → window.hermesAPI.sendMessage(..., runId, profile, session id, history, attachments)
  → ipc/register.ts send-message handler
  → hermes.ts sendMessage()
  → local/remote HTTP SSE or local CLI stream
  → callbacks tagged with runId
  → preload event channels
  → useChatIPC.ts
       ├─ append deltas/reasoning/tool events
       ├─ poll getSessionMessages() every 750 ms during a live session
       └─ on done, reconcile from Agent state.db
```

The event payloads are deliberately redundant. Live events make the UI responsive; persisted session reads repair missing reasoning/tool rows and normalize the transcript after completion.

### Run identity versus Agent session identity

| Identity                     | Owner                                             | Purpose                                                         |
| ---------------------------- | ------------------------------------------------- | --------------------------------------------------------------- |
| `runId`                      | Desktop renderer, minted per mounted conversation | routes global IPC events to the correct visible/background chat |
| runtime Dashboard session ID | Dashboard runtime                                 | identifies the live JSON-RPC session used by `prompt.submit`    |
| stored Agent session ID      | Agent state / Desktop handoff                     | identifies the durable history to resume/reconcile              |

Do not collapse these IDs. Recovery may create a new runtime session while retaining the stored session ID and recording a continuation overlay.

## 8. State and persistence map

| Data                         | Location/owner                                                                      | Read/write path                                     | Bug risk                                                      |
| ---------------------------- | ----------------------------------------------------------------------------------- | --------------------------------------------------- | ------------------------------------------------------------- |
| Desktop connection config    | `~/.hermes/desktop.json` (Desktop-owned)                                            | `config.ts` and connection IPC                      | stale mode, URL, auth, or transport preference                |
| Hermes home                  | `HERMES_HOME`; usually `~/.hermes`                                                  | `installer.ts` resolution                           | Windows/custom-home mismatch; module-load-time constant       |
| Profile config               | `<profile home>/config.yaml` (Agent-owned)                                          | `config.ts`, CLI, SSH helpers                       | YAML nesting, stale `model.api_mode`/base URL, wrong profile  |
| Provider secrets             | `<profile home>/.env`, `auth.json`, optional command provider                       | `config.ts`, `secrets/`, spawn env                  | cache, precedence, accidental exposure                        |
| Agent history                | `<profile home>/state.db` (Agent-owned)                                             | read-only `better-sqlite3` in `db.ts`/`sessions.ts` | schema drift, active-profile connection, incomplete live rows |
| Desktop session cache        | `<profile home>/desktop/sessions.json`                                              | `session-cache.ts`                                  | stale title/count, wrong profile, cache not authoritative     |
| Desktop continuations/errors | extra SQLite tables `desktop_session_continuations`, `desktop_session_local_errors` | `session-continuation-store.ts`                     | local overlays can be mistaken for Agent history              |
| Session folder mapping       | Desktop SQLite store                                                                | `session-context-folder-store.ts`                   | path semantics and remote/local mismatch                      |
| Session model override       | Desktop SQLite store                                                                | `session-model-override-store.ts`                   | global model config accidentally changed                      |
| Model library                | `~/.hermes/models.json`, `model-definitions.json`                                   | `models.ts`                                         | local presentation/routing metadata is not Agent authority    |
| Profile metadata             | `<profile home>/profile-meta.json`                                                  | `profile-meta.ts`/`profiles.ts`                     | display name differs from stable profile ID                   |
| Gateway PID/logs             | profile home `gateway.pid`, `gateway-stderr.log`                                    | `hermes.ts`, Gateway UI                             | stale PID reuse and process identity                          |
| Dashboard process state      | in-memory `dashboards` map in `dashboard.ts`                                        | start/status/stop IPC                               | process can exit outside map; token is ephemeral              |
| SSH tunnel state             | process-global variables in `ssh-tunnel.ts`                                         | start/ensure/stop IPC                               | one tunnel retarget can affect every feature                  |
| Attachment staging           | temporary files under Desktop temp area                                             | `attachment-staging.ts`, session cleanup            | cleanup and path-ref behavior differ by transport             |

### Agent history reconstruction

`sessions.ts` reads Agent SQLite rows and expands them into a renderer timeline:

```text
messages row
  ├─ user/assistant content → visible bubble
  ├─ assistant reasoning* → reasoning row
  ├─ assistant tool_calls → tool-call row
  └─ tool row → tool-result row
       ↓
  decode multimodal sentinel content
       ↓
  merge stored prompt-image attachments
       ↓
  merge Desktop continuation prefix/local errors
       ↓
  renderer HistoryItem[]
```

The `CONTENT_JSON_PREFIX` decoder, reasoning-column priority, tool-call parser, and `expandRowsToHistory()` are the key compatibility points when Agent schema or payloads change.

## 9. Feature-to-source index

| Outcome                           | Renderer                                 | Main/shared implementation                                                           | Nearest tests                                                                                                   |
| --------------------------------- | ---------------------------------------- | ------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------- |
| Streaming chat and event timeline | `screens/Chat/`                          | `hermes.ts`, `run-stream.ts`, `tui-gateway-stream.ts`, `dashboard.ts`                | `tests/chat-runs.test.ts`, `tests/run-stream.test.ts`, `tests/sse-parser.test.ts`, dashboard client/event tests |
| Session history/search            | `screens/Sessions/`, sidebar             | `sessions.ts`, `remote-sessions.ts`, `session-cache.ts`                              | `tests/remote-sessions.test.ts`, `tests/session-cache-sync.test.ts`, `tests/sessions-*`                         |
| Profile lifecycle                 | `screens/Agents/`, `ProfileSwitcher.tsx` | `profiles.ts`, `profile-meta.ts`                                                     | `tests/profiles.test.ts`, `tests/profile-validation.test.ts`                                                    |
| Provider/model setup              | `screens/Providers/`, model picker       | `config.ts`, `models.ts`, `provider-registry.ts`, `providers-store.ts`, `secrets/`   | `tests/providers.test.ts`, `tests/model-discovery.test.ts`, `tests/provider-picker.test.ts`                     |
| Dashboard/remote modes            | connection settings, Chat hooks          | `dashboard.ts`, `remote-api.ts`, `remote-oauth.ts`, `ssh-remote.ts`, `ssh-tunnel.ts` | `tests/dashboard-*`, `tests/remote-*`, `tests/ssh-*`                                                            |
| Gateway/platform config           | `screens/Gateway/`                       | `hermes.ts`, `messaging-platforms.ts`, `tools.ts`                                    | `tests/gateway-*`, `tests/messaging-platform-runtime-state.test.ts`                                             |
| Skills/MCP/Discover               | `screens/Discover/`, `Skills/`, `Tools/` | `skills.ts`, `mcp-servers.ts`, `registry.ts`                                         | `tests/skills-*`, `tests/mcp-servers.test.ts`                                                                   |
| Memory/persona                    | `screens/Memory/`, `screens/Soul/`       | `memory.ts`, `soul.ts`, `memory-limits.ts`                                           | `tests/memory-limits.test.ts`                                                                                   |
| Schedules/Kanban                  | `screens/Schedules/`, `Kanban/`          | `cronjobs.ts`, `kanban.ts`                                                           | `tests/cronjobs.test.ts`, `tests/kanban-unsupported.test.ts`                                                    |
| Attachments/media                 | `Chat/` components                       | `media.ts`, `attachment-staging.ts`, `session-attachment-store.ts`                   | `tests/media.test.ts`, attachment tests                                                                         |
| Security boundary                 | webviews and startup                     | `security.ts`, `app/start.ts`, preload                                               | `tests/electron-security.test.ts`, `tests/preload-api-surface.test.ts`                                          |
| Install/update/OS                 | Welcome/Install/Settings                 | `installer.ts`, `updater.ts`, `gpu-fallback.ts`, `app/`                              | `tests/installer-*`, `tests/release-artifacts.test.ts`                                                          |

The reference test commands are:

```bash
(cd hermes-desktop && npm test)
(cd hermes-desktop && npm run typecheck)
```

Run them only against the read-only reference checkout when needed; do not format it or include it in Wing validation.

## 10. Bug-triage recipe for Wing

1. **Name the user outcome.** Chat send, resume, model selection, profile switch, folder selection, gateway health, and so on.
2. **Record mode and identity.** Local, direct remote, or SSH; selected profile; `runId`; stored session ID; runtime session ID if Dashboard is involved.
3. **Locate the renderer owner.** Start at the screen/hook in the feature-to-source table. Check whether the view is still mounted but hidden.
4. **Trace the bridge.** Verify renderer call → preload method/channel → `ipcMain.handle` argument order and result shape.
5. **Trace the selected transport.** Confirm `/api/*` versus `/v1/*`, Dashboard versus legacy, and whether `auto` fallback is expected.
6. **Check authority.** Determine whether the value came from Agent state, a remote Agent response, Desktop cache, or a Desktop-only overlay. Server state wins after reconnect.
7. **Check profile propagation.** An omitted profile can silently read the default profile, especially on the unified SSH Dashboard.
8. **Check event ownership.** Global events must be filtered by `runId` and/or session ID; stale listeners must be removed on unmount.
9. **Check reconciliation.** A successful live stream can still need a final Agent history read. Compare `dashboardEventAdapter.ts`, `useChatIPC.ts`, and `sessions.ts`.
10. **Read the nearest regression test before changing behavior.** The reference repository has many issue-specific tests; they often encode the intended edge case better than the UI.
11. **Port the outcome, not the mechanism.** Implement in Wing's existing `HermesChannel`/Riverpod/Agent contract seams. Do not copy Desktop file reads, CLI commands, Dashboard sockets, or local shadow state.

## 11. High-risk seams and symptoms

| Symptom in Wing study                            | Desktop seam to inspect                                                                | Likely class of failure                                             |
| ------------------------------------------------ | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| New chat receives another chat's response        | `runId` filtering in `useChatIPC.ts`, `Layout.tsx` run mounting                        | global event cross-talk or reused session identity                  |
| Named profile shows default sessions/model       | `activeSshProfile()`, `dashboardApiUrl()`, `ensureDashboardRuntimeSession()`           | missing explicit profile propagation                                |
| Chat works once, then continuation fails         | `getApiServerKey()` and `buildGatewayEnv()` in `config.ts`/`hermes.ts`                 | API key source/precedence or Agent session-header auth mismatch     |
| Dashboard chat returns 405/404                   | `dashboard.ts`, `prepareSshTunnel()`, Dashboard/Gateway split                          | tunnel targets gateway while client speaks Dashboard, or vice versa |
| Stream text duplicates or loses pre-tool text    | `dashboardEventAdapter.ts`, `mergeStreamedWithFinal()`                                 | delta/final-response reconciliation error                           |
| Reasoning or tool rows appear only after reload  | `useChatIPC.ts` polling and `sessions.ts:expandRowsToHistory()`                        | event shape omitted; DB reconciliation is the repair path           |
| Old session content appears in a new chat        | explicit session ID generation in `hermes.ts`                                          | fingerprint-derived session collision or wrong stored ID            |
| Model switch routes to wrong provider            | `resolveDashboardProviderForModel()`, `resolveLibraryModelEntry()`, `setModelConfig()` | provider/base URL/api-mode identity drift                           |
| Session list title/count is stale                | `session-cache.ts` versus `sessions.ts`                                                | cache is optimized read state, not authority                        |
| Remote attachment/folder works locally only      | `Chat.tsx`, `remote-sessions.ts`, `ssh-remote.ts`                                      | absolute path cannot cross a remote boundary safely                 |
| Gateway restart affects another profile          | profile-keyed maps in `hermes.ts`, `gateway-ports.ts`                                  | wrong profile key or process/PID lookup                             |
| SSH reconnect flaps between ports                | global `ssh-tunnel.ts` plus `prepareSshTunnel()`                                       | competing tunnel target or stale generation callback                |
| Config edit appears saved but runtime ignores it | YAML helpers and gateway restart path in `config.ts`/`hermes.ts`                       | nested YAML path, cache invalidation, or reload requirement         |
| Secret appears in UI/logs/argv                   | `secrets/`, preload types, spawn helpers                                               | trust-boundary violation; fix before any parity work                |
| A declared feature cannot be found in the UI     | `preload/index.d.ts` compared with renderer call sites                                 | bridge surface is not proof of reachable product behavior           |

## 12. What Wing may learn, and what it must reject

### Good reference patterns

- Chat-first information hierarchy and clear run/session status.
- Separate live stream rendering from final persisted-history reconciliation.
- Stable identity for each mounted conversation and explicit event filtering.
- Profile-aware transport selection and visible fallback/error states.
- Typed bridge methods with cleanup functions for event listeners.
- Small pure adapters for wire-shape normalization and transcript reconstruction.
- Tests for protocol variants, malformed payloads, retries, and stale state.

### Desktop mechanisms Wing must not copy

- Direct reads/writes of `~/.hermes`, `config.yaml`, `.env`, `auth.json`, PID files, or Agent `state.db`.
- `hermes profile use` or any other global active-profile side effect.
- Per-profile local gateway ports as Wing's profile model.
- Dashboard WebSockets as a substitute for advertised Agent data-plane contracts.
- Absolute host paths, SSH shell commands, arbitrary file browsing, or path-based remote attachments.
- Desktop-owned shadow copies of Agent profiles, projects, providers, models, memories, skills, schedules, tools, or gateway state.
- Electron updater, installer, webview, GPU, menu, or Office implementation on mobile/web.
- Treating preload-only, disabled, legacy, or coming-soon controls as shipped capability.

For Wing, use the exact advertised Hermes Agent operation, profile/project identity, authorization, and revision/resource identity. Use Wing Link only for reviewed host-management or fixed compatibility operations. Keep Agent traffic direct; Wing Link is not a proxy.

## 13. Snapshot and maintenance

Refresh this map when the reference checkout changes materially, especially when any of these move:

- `src/main/ipc/register.ts` or `src/preload/index.d.ts` bridge surface;
- `src/main/hermes.ts`, `dashboard.ts`, `remote-*`, or `ssh-*` transport behavior;
- `src/renderer/src/screens/Layout/`, `Chat/`, or session/profile screens;
- Agent session, Dashboard, model, profile, or capability contracts;
- the pinned Desktop commit in `docs/product/hermes-desktop-feature-study.md`.

Use the existing feature study for user-outcome and Wing-disposition history. Use this map for code navigation and bug tracing.
