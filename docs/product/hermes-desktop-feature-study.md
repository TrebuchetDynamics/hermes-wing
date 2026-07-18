# Hermes Desktop complete feature study

This is a source-backed inventory of the sibling `../hermes-desktop` application for Hermes Wing capability-parity planning. It describes user outcomes, not a line-for-line Electron port.

## Study baseline

- Repository: sibling `../hermes-desktop`
- Version: `0.7.3`
- Studied commit: `8da8d212abd40b449d55957b2cff9a220797ff71`
- Existing frozen Wing planning baseline: `d31e52e85449b6effcfd4d037b7517541c8fadf2`
- Architecture: Electron main process + context-isolated preload bridge + React renderer (`../hermes-desktop/src/main/app/start.ts:25`, `../hermes-desktop/src/preload/index.d.ts:229`, `../hermes-desktop/src/renderer/src/App.tsx:21`)

The studied checkout is newer than the frozen planning baseline. Its notable post-baseline additions are remote Dashboard OAuth, provider/model-list improvements, and custom-provider management. These are deltas; they do not silently move the frozen retirement baseline.

## How to read this inventory

| Disposition | Meaning for Hermes Wing |
| --- | --- |
| **Remote outcome** | A mobile-safe outcome Wing may provide through an advertised Hermes Agent contract. |
| **Contract-gated** | Do not expose until the selected gateway advertises the exact operation and required scope. |
| **Host-only** | Requires a supported desktop host adapter; exclude from Android/web rather than emulating it. |
| **Account-service** | Belongs to the optional Hermes One account service, independently of Hermes Agent. |
| **Presentation** | Reuse the outcome and interaction model, not necessarily Desktop's rendering technology. |

Hermes Desktop often implements domain operations by invoking the Hermes CLI or directly reading `~/.hermes`, YAML, JSON, SQLite, PID files, and SSH-host files. Hermes Wing must not copy those mechanisms. Hermes Agent remains authoritative.

## Product topology

Desktop currently presents a chat-first shell with these primary destinations:

- **Discover**, **Office**, **Kanban**, and **Schedules** in pinned navigation.
- **Providers**, **Gateway**, **Tools**, and **Memory** in footer navigation.
- **Agents** through the profile switcher's **Manage profiles** action.
- **Sessions** as sidebar history and a full-list modal, not a top-level route.
- **Skills** inside Tools and Discover, not a top-level destination.
- **Models** inside Providers, not a standalone screen.
- **Soul/persona** inside Memory and each profile modal.
- **Settings** as a global modal.

Source: `../hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx:43-93`, `../hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx:217-234`.

This topology matters: the README's screen list reflects older standalone destinations in places, while current renderer navigation is authoritative.

## Complete user-facing feature inventory

### 1. Bootstrap, installation, and first-run setup

Desktop provides:

- Splash-time installation and connection checks.
- Choice of local installation, remote HTTP server, or SSH-hosted Hermes.
- Explicit install confirmation showing whether the target is fresh, updated, or replaced.
- Progress, logs, retry, copied failure diagnostics, and community help.
- Adoption of an existing Hermes home followed by restart.
- Hermes installation verification and repair/reinstall warning.
- First-run provider, API-key, endpoint, and optional model setup.
- Local OpenAI-compatible presets and remote compatible endpoints.
- OpenClaw detection and migration from Settings.

Sources: `../hermes-desktop/src/renderer/src/App.tsx:21-240`, `../hermes-desktop/src/renderer/src/screens/Welcome/Welcome.tsx:20-381`, `../hermes-desktop/src/renderer/src/screens/Install/Install.tsx:28-292`, `../hermes-desktop/src/renderer/src/screens/Setup/Setup.tsx:15-331`.

**Wing disposition:** local discovery/install/update/adoption and SSH are **host-only**. Remote enrollment and provider setup are **remote outcomes** but remain capability- and scope-gated. Android must never run the Desktop installer or inspect a Hermes home.

### 2. Connection modes and transports

Desktop supports:

- **Local** Hermes on loopback.
- **Remote HTTP** using API-key or detected OAuth authentication.
- **SSH** connection testing and local port forwarding.
- Chat transport preference: `auto`, `dashboard`, or `legacy`.
- Dashboard WebSocket probing and fallback to legacy transport where allowed.
- Remote OAuth login/logout/session state.
- Connection test, saved endpoint, API-key masking, SSH host/user/key/ports.
- Force-IPv4 and HTTP proxy settings.
- Connection-change events that reset or refresh affected renderer state.

Sources: `../hermes-desktop/src/preload/index.d.ts:338-410`, `../hermes-desktop/src/renderer/src/components/settings/ConnectionPane.tsx:8-431`, `../hermes-desktop/src/main/ssh-tunnel.ts`.

**Wing disposition:** one canonical Hermes API origin is the Wing transport. Dashboard WebSockets are not a Wing transport. SSH is **host-only** and requires explicit host-key trust in Wing. Remote OAuth is a post-frozen-baseline delta requiring an independently accepted contract.

### 3. Desktop shell and navigation

Desktop provides:

- Collapsible sidebar with branded shell, recent sessions, profile switcher, pinned/footer navigation, updater state, and Settings.
- Multiple mounted chat runs with an active-session bar.
- New-chat, close-tab, cycle-tab, and numeric tab keyboard shortcuts.
- Application menu actions for new chat and session search.
- Native zoom, fullscreen, window, edit, and help actions.
- macOS inset titlebar behavior and platform package/window integration.
- Auto-update availability, download progress, restart-to-install, and opt-out.

Sources: `../hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx:95-1016`, `../hermes-desktop/src/main/app/menu.ts:8-82`, `../hermes-desktop/src/main/app/updater.ts:33-106`, `../hermes-desktop/src/main/app/start.ts:104-201`.

**Wing disposition:** adaptive navigation and run switching are **remote outcomes/presentation**. Menus, windows, packaging, updater, and GPU process behavior are **host-only**.

### 4. Chat and run execution

Desktop chat includes:

- Streaming assistant text, reasoning, tool-call progress, structured tool events, usage, errors, and completion.
- Approve/deny controls and inline clarify questions.
- Stop/abort plus retry/undo command paths.
- Concurrent background side questions (`/btw`) and queued follow-up messages.
- Multiple runs that continue streaming while another run is visible.
- Rich Markdown, GFM, syntax highlighting, code copy, images/media, file viewing, and generated-media save/open actions.
- Per-session model override, provider/base URL routing, reasoning effort, fast mode, and model context-window gauge.
- Prompt/completion/total tokens, cost, cache read/write, rate-limit, and context-window metadata.
- Pre-send readiness validation with targeted provider/model/gateway remediation.
- Completion chime.
- Full-chat copy as text or Markdown plus bubble-scoped selection.
- Config-health banner and diagnostics entry.
- Empty-state prompt suggestions.

Sources: `../hermes-desktop/src/renderer/src/screens/Chat/Chat.tsx:114-1150`, `../hermes-desktop/src/renderer/src/screens/Chat/MessageList.tsx`, `../hermes-desktop/src/renderer/src/screens/Chat/MessageRow.tsx`, `../hermes-desktop/src/preload/index.d.ts:412-516`.

**Wing disposition:** these are primarily **remote outcomes**. Wing now renders bounded `reasoning.available` run events in collapsed readable cards, preserves them through transcript reconciliation/export, and preserves bounded server-reported input/output/total token usage from run completion or advertised run status on the assistant reply and in transcript export. Cost, cache, rate-limit, and context-window metadata remain unavailable. Each event/action must come from advertised HTTP/SSE contracts; Wing must not use Dashboard sockets as a shortcut.

### 5. Composer, voice, attachments, and context

Desktop's composer provides:

- Multiline auto-resizing text, Enter-to-send, Shift+Enter newline, IME-safe handling, and input-history recall.
- Dynamic slash-command search with keyboard navigation and a backend-provided command catalog.
- Picker, paste, and drag/drop attachments with removable chips and explicit errors.
- Up to 10 attachments per message.
- PNG/JPEG/WebP/GIF input up to 50 MB, compressed toward a 5 MB binary target.
- UTF-8 text files up to 256 KB.
- Local path references for PDFs, Office files, and other binaries; remote mode rejects those path references.
- Voice transcription using browser speech recognition or recorded-audio transcription fallback.
- Context-folder selection, recent folders, persisted session folder, worktree/file panel, and remote folder picker.
- Embedded web preview; clicking links opens the preview and inspected HTML can be appended to the composer.
- Quick Ask and normal Send/Stop controls.

Sources: `../hermes-desktop/src/renderer/src/screens/Chat/ChatInput.tsx:58-759`, `../hermes-desktop/src/shared/attachments.ts:1-141`, `../hermes-desktop/src/renderer/src/screens/Chat/attachmentUtils.ts`, `../hermes-desktop/src/renderer/src/screens/Chat/Chat.tsx:736-1144`.

**Wing disposition:** inline images and bounded text already have mobile-safe outcomes. Arbitrary binaries and folders require opaque Hermes resource handles. Desktop path references must never cross a remote Wing boundary.

### 6. Slash commands

Desktop merges three sources:

1. Runtime commands advertised by the connected Dashboard transport.
2. Fallback Hermes commands such as `/btw`, `/approve`, `/deny`, `/status`, `/reset`, `/compact`, `/undo`, `/retry`, `/compress`, `/debug`, `/goal`, `/learn`, `/steer`, `/queue`, `/update`, `/web`, `/image`, `/browse`, `/code`, `/file`, and `/shell`.
3. Desktop-local commands including `/new`, `/clear`, `/fast`, `/usage`, `/help`, `/settings`, `/model`, and navigation commands.

The current implementation therefore has no reliable fixed command count despite the README advertising 22. Runtime discovery and conflict reconciliation are the real behavior.

Sources: `../hermes-desktop/src/renderer/src/screens/Chat/slashCommands.ts:9-174`, `../hermes-desktop/src/renderer/src/screens/Chat/slash/desktopCommands.ts:12-129`, `../hermes-desktop/src/renderer/src/screens/Chat/slash/commandCatalog.ts:40-176`.

**Wing disposition:** Wing now provides filtered, tap-operable client-owned `/new`, `/sessions`, `/clear`, `/settings`, `/usage`, `/help`, `/agents`, `/providers`, `/model`, `/tools`, `/skills`, `/schedules`, and `/gateway` suggestions, plus `/persona` only when the selected gateway advertises the exact scoped SOUL read contract and `/version` only with exact scoped detailed health, including 200% text-scale coverage. Exact local commands execute as client actions without sending slash text as an agent turn and cannot bypass an active run; unknown slash commands remain server-owned messages. Runtime model/agent command discovery is still **contract-gated** rather than reimplemented from guessed semantics.

### 7. Sessions and conversation history

Desktop provides:

- SQLite-backed history synchronization into a desktop cache.
- FTS session search with highlighted snippets and debounce.
- Recent sessions in the sidebar plus a full sessions modal.
- Today/yesterday/this-week/earlier grouping.
- Resume, rename, single delete, selection mode, select-all-visible, and bulk delete.
- Source, message count, model, title, and timestamp metadata.
- Refresh on view activation, window focus, connection changes, and a 30-second visible-view timer.
- Persisted session continuation items and local errors.
- Persisted per-session context folder and model override.
- Session de-duplication when reopening an already active run.

Sources: `../hermes-desktop/src/renderer/src/screens/Sessions/Sessions.tsx:290-1052`, `../hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx:394-555`, `../hermes-desktop/src/preload/index.d.ts:548-628`, `../hermes-desktop/src/preload/index.d.ts:780-818`.

**Wing disposition:** a **remote outcome** where exact session operations are advertised. Wing must not read Desktop's SQLite/cache files.

### 8. Agents, profiles, and persona

Desktop provides:

- Profile list with display name, stable ID, avatar, color, provider, model, skill count, gateway state, and active state.
- Create fresh or clone another profile; clone source defaults to the active profile.
- Activate a profile and poll its per-profile gateway startup state.
- Start a chat with a selected profile.
- Global profile switcher and profile-management entry.
- Editable display name separate from stable profile ID.
- Avatar upload/remove and accent-color selection.
- Persona/SOUL editor with debounced save and reset.
- Profile memory entries.
- Profile wallet and cloud-sync tabs.
- Protected default profile and confirmed deletion for named profiles.

Sources: `../hermes-desktop/src/renderer/src/screens/Agents/Agents.tsx:34-494`, `../hermes-desktop/src/renderer/src/screens/Layout/ProfileSwitcher.tsx:32-235`, `../hermes-desktop/src/renderer/src/components/profile/ProfileModal.tsx:67-558`, `../hermes-desktop/src/renderer/src/screens/Soul/Soul.tsx:9-125`.

Desktop implements profile creation/deletion/activation through CLI and local/SSH filesystem state. Its profile topology is not Wing's gateway topology.

**Wing disposition:** **contract-gated remote outcome** scoped to the selected saved gateway. Wing must preserve stable ID/display-name distinctions exposed by the server and must not mutate a CLI `active_profile` file.

### 9. Providers, credentials, models, and task overrides

Desktop provides:

- Hermes One account sign-in/out.
- Provider cards with masked/editable API keys, key removal, provider links, OAuth sign-in, and configured-state summaries.
- Named custom OpenAI-compatible providers.
- Credential pools with labels and priorities.
- Active provider/model/base-URL configuration with autosave.
- Provider model discovery and refresh.
- Saved model library and current model picker.
- Curated model registry with search, provider grouping, context length, capabilities, and modalities.
- Eleven auxiliary task-model overrides: vision, web extraction, compression, skills hub, approval, MCP, title generation, triage specifier, Kanban decomposition, profile description, and curator.
- Auxiliary reset-to-default.

Current provider options include aggregators, first-party providers, local servers, OAuth/subscription providers, and arbitrary OpenAI-compatible endpoints. The list is code-driven rather than the shorter README list.

Sources: `../hermes-desktop/src/renderer/src/screens/Providers/Providers.tsx:135-1088`, `../hermes-desktop/src/renderer/src/constants.ts:37-412`, `../hermes-desktop/src/renderer/src/components/ProviderKeysSection.tsx`, `../hermes-desktop/src/renderer/src/components/RegistryBrowserModal.tsx:28-235`, `../hermes-desktop/src/renderer/src/components/AuxiliaryTasksSection.tsx:21-341`.

**Wing disposition:** exact scoped administration remains **contract-gated**. When it is absent but the gateway advertises `GET /v1/models`, Wing shows a bounded read-only runtime model inventory without credential or assignment controls. Secrets must be write-only, profile-scoped, and never returned. Generic `.env` or YAML access is not a Wing contract.

### 10. Discover marketplace

Desktop Discover has four catalogs:

- Skills
- MCP servers
- Agent templates
- Workflows

It supports search, refresh, counts, metadata/tags, source links, Markdown/spec details, install/create actions, installed-state detection, and MCP removal. Bundled Hermes skills are merged into community skill results with deduplication.

Sources: `../hermes-desktop/src/renderer/src/screens/Discover/Discover.tsx:22-608`, `../hermes-desktop/src/preload/index.d.ts:1227-1243`.

**Wing disposition:** catalog browsing may be client/account-service owned, but installation/removal is **contract-gated** and profile-scoped.

### 11. Skills

Desktop provides:

- Installed and bundled/browse views.
- Search and category filtering.
- Skill cards with category and description.
- Full `SKILL.md` Markdown detail.
- Install and confirmed uninstall.
- Embedded installed-skills view under Tools with a Discover handoff.

Sources: `../hermes-desktop/src/renderer/src/screens/Skills/Skills.tsx:33-393`, `../hermes-desktop/src/preload/index.d.ts:746-778`.

**Wing disposition:** **contract-gated**. Wing must not inspect skill directories or invoke the skills CLI.

### 12. Toolsets and MCP servers

The current source defines 19 CLI toolsets, not the README's older count of 14:

`web`, `x_search`, `browser`, `terminal`, `file`, `code_execution`, `computer_use`, `vision`, `image_gen`, `video_gen`, `tts`, `skills`, `memory`, `session_search`, `clarify`, `delegation`, `cronjob`, `moa`, and `todo`.

Desktop supports:

- Enable/disable toolsets.
- MCP list and search.
- Add HTTP or stdio MCP server with URL/command/args/env/auth.
- Enable/disable, test, refresh, and remove MCP servers.
- MCP catalog discovery/install bridge methods, although the current renderer's main path uses Discover for catalog browsing.

Sources: `../hermes-desktop/src/main/tools.ts:10-127`, `../hermes-desktop/src/renderer/src/screens/Tools/Tools.tsx:178-753`, `../hermes-desktop/src/preload/index.d.ts:1160-1225`.

**Wing disposition:** advertised installed skills now expose bounded searchable name, description, and category metadata read-only alongside enabled toolsets. Community discovery, install/remove, toolset mutation, and MCP remain **contract-gated**. Terminal, filesystem, code-execution, and computer-use controls also require explicit risk presentation and server enforcement.

### 13. Memory and persona

Desktop Memory provides:

- Capacity/statistic cards.
- Agent-memory entry create, edit, and delete.
- User-profile memory editing with character limits.
- Memory-provider discovery, active provider, activate/deactivate controls, credential entry, and provider-site links.
- Embedded persona/SOUL editor.

Sources: `../hermes-desktop/src/renderer/src/screens/Memory/Memory.tsx:12-101`, `../hermes-desktop/src/renderer/src/screens/Memory/MemoryEntries.tsx`, `../hermes-desktop/src/renderer/src/screens/Memory/MemoryProfile.tsx`, `../hermes-desktop/src/renderer/src/screens/Memory/MemoryProviders.tsx`, `../hermes-desktop/src/preload/index.d.ts:707-732`.

**Wing disposition:** profile persona is available only where advertised; broader memory administration remains **contract-gated**.

### 14. Schedules

Desktop provides:

- List all enabled/disabled jobs and show state, next/last run, status, errors, repeat progress, skills, and script metadata.
- Create by minutes, hourly, daily, weekly, or custom cron expression.
- Name, prompt, and one delivery target at creation.
- Pause/resume, trigger-now, and confirmed delete.
- Delivery choices for local/origin plus Telegram, Discord, Slack, WhatsApp, Signal, Matrix, Mattermost, Email, Webhook, SMS, Home Assistant, DingTalk, Feishu, and WeCom.

The current screen does **not** provide job editing despite broader parity prose occasionally saying “edit”; changes require delete/recreate.

Sources: `../hermes-desktop/src/renderer/src/screens/Schedules/Schedules.tsx:14-661`, `../hermes-desktop/src/preload/index.d.ts:974-1018`.

**Wing disposition:** gateway- and profile-scoped read-only inventory is implemented at `/tasks` through advertised `GET /api/jobs`. Create, pause/resume, trigger, delete, delivery, and Kanban remain **contract-gated** and revision-safe. Failed mutations must never be replayed automatically.

### 15. Messaging gateway administration

Desktop provides:

- Gateway start, stop, restart, status polling, startup failure/log-path reporting.
- API-server key presence and generation.
- Searchable messaging-platform cards.
- Per-platform credential/config forms, password reveal, clear/save, advanced fields, documentation links, tests, configured/enabled states, and unsaved-state indication.
- Per-platform toolset toggles with explicit confirmation for high-risk terminal/file/code execution access.

The live catalog contains 20 cards, newer than the README's older “16 gateways” claim:

1. Telegram
2. Discord
3. Slack
4. Mattermost
5. Matrix
6. WhatsApp
7. Signal
8. BlueBubbles/iMessage
9. Home Assistant
10. Email
11. SMS/Twilio
12. DingTalk
13. Feishu/Lark
14. WeCom group bot
15. WeCom callback app
16. WeChat Official Account
17. QQ Bot
18. Yuanbao
19. API server
20. Webhooks

Sources: `../hermes-desktop/src/renderer/src/screens/Gateway/Gateway.tsx:30-974`, `../hermes-desktop/src/shared/messaging-platforms.ts:645-902`, `../hermes-desktop/src/preload/index.d.ts:518-546`.

**Wing disposition:** bounded, gateway-selected detailed health is implemented read-only at `/gateway`. All lifecycle, log, API-key, and messaging-platform configuration actions remain **contract-gated** and server-owned. Wing must not write gateway environment variables or restart processes itself.

### 16. Kanban

Desktop provides:

- Multiple boards, board switching, board creation, and persisted current board choice.
- Eight active lanes: triage, todo, scheduled, ready, running, blocked, review, and done; optional archived lane.
- Task creation with title, body, profile assignee, priority, scratch/worktree/selected-directory workspace, and triage option.
- Priority/age/assignee/tenant/skills metadata.
- Drag/drop through valid CLI lifecycle transitions only.
- Specify, promote, schedule, block, unblock, reclaim, complete, archive, and dispatch-once actions.
- Task detail drawer with body, summary, result, comments, recent events, status, assignee, tenant, and ID.
- Six-second visible polling plus focus refresh.
- Read-only Claw3D HQ virtual board in SSH mode.
- Explicit unsupported view for plain remote mode.

Some preload operations are not wired into the current renderer UI, including board removal, task reassignment, and adding comments.

Sources: `../hermes-desktop/src/renderer/src/screens/Kanban/Kanban.tsx:97-1382`, `../hermes-desktop/src/preload/index.d.ts:1020-1127`.

**Wing disposition:** **contract-gated**. Filesystem workspaces require resource handles. The HQ mirror is not a portable control-plane contract.

### 17. Hermes Office

Current Desktop Office is a native React Three Fiber scene, not the older externally hosted Claw3D webview described by some README text. It provides:

- 3D city, office, bank, and showroom locations.
- Enter/exit building interactions and camera/location controls.
- One avatar per profile, live gateway-derived working/idle status, profile selection, and agent detail sidebar.
- CEO assignment persisted as Desktop-local presentation state.
- Desk interaction and profile editing.
- One Chat modal with a separate `office-{profile}` session per agent.
- Bank ATM deep-link to profile wallets.
- Bank teller actions for account status, balances, and cloud-wallet creation.
- **Send money is visible but disabled/coming soon.**
- Showroom car information cards.
- GPU/software-rendering warning and recovery.
- Development-only building-position tool.

Legacy Claw3D setup/dev-server/adapter methods remain in the preload API, but the current Office renderer does not call them; they are bridge surface, not an active current UI feature.

Sources: `../hermes-desktop/src/renderer/src/screens/Office/Office.tsx:46-792`, `../hermes-desktop/src/renderer/src/screens/Office/office3d/core/locations.ts:1-113`, `../hermes-desktop/src/renderer/src/screens/Office/OneChatModal.tsx:18-499`, `../hermes-desktop/src/renderer/src/screens/Office/RepInteractionPanel.tsx:51-446`, `../hermes-desktop/src/renderer/src/screens/Office/office3d/interactions/registry.ts:31-56`.

**Wing disposition:** **presentation** over shared authoritative profile, chat, account, and wallet outcomes. Android should use an accessible 2D Office; desktop Wing may add 3D plus a fully equivalent semantic path.

### 18. Hermes One account, agent sync, and wallets

Desktop provides:

- Hermes One device/account sign-in and sign-out.
- Automatic/manual cloud-agent synchronization with per-profile linked state and outcomes.
- Local wallet listing and deletion.
- Cloud-wallet synchronization per linked agent.
- Base-network ETH/HD balance display and refresh.
- Address copy.
- Cloud-wallet provisioning from Office.
- Portfolio and account-status views.

The preload bridge also exposes local wallet create/import/rename operations, but current renderer screens do not call them. Do not count those bridge methods as active current UI parity.

Sources: `../hermes-desktop/src/renderer/src/components/profile/ProfileSyncPane.tsx:22-160`, `../hermes-desktop/src/renderer/src/components/profile/ProfileWalletPane.tsx:37-372`, `../hermes-desktop/src/main/agent-sync.ts`, `../hermes-desktop/src/preload/index.d.ts:278-287`, `../hermes-desktop/src/preload/index.d.ts:673-705`.

**Wing disposition:** **account-service**. Legacy local wallets are migration/export concerns, not a new Wing wallet store. Hermes Agent must remain usable when the optional account service is unavailable.

### 19. Settings, diagnostics, data, and preferences

Settings is a global modal with eight sections:

- **Appearance:** themes, rounded corners, interface font, GPU preference, restart-to-apply.
- **Language:** 12 locales; Arabic and Hebrew RTL.
- **Privacy:** explicit analytics toggle.
- **Connection:** local/remote/SSH, auth, transport, testing, IPv4, proxy.
- **Data:** backup export/import and OpenClaw migration.
- **About:** config health, Hermes Agent version/home/update, doctor, debug dump, Desktop version/update, auto-upgrade.
- **Community:** Discord, website, X, Telegram, and support links.
- **Logs:** gateway, agent, and error log viewer.

Config health supports rerun and selected automatic fixes. Logs show host file paths and tail content. Desktop backup/import invokes host/CLI operations.

Sources: `../hermes-desktop/src/renderer/src/components/settings/SettingsModal.tsx:22-194`, `../hermes-desktop/src/renderer/src/components/settings/AppearancePane.tsx:11-184`, `../hermes-desktop/src/shared/i18n/config.ts:6-29`, `../hermes-desktop/src/renderer/src/components/settings/DataPane.tsx:9-118`, `../hermes-desktop/src/renderer/src/components/settings/AboutPane.tsx:25-389`, `../hermes-desktop/src/renderer/src/components/settings/LogsPane.tsx:7-82`.

**Wing disposition:** app-local appearance/language/privacy are portable. Runtime diagnostics, logs, updates, and backup/restore are **host-only** or **contract-gated** depending on whether they manage the local client or Hermes Agent.

### 20. Security, platform, and packaging behavior

Desktop includes:

- Context isolation, sandbox, no renderer Node integration, web security, and no insecure content.
- URL allowlists for external navigation and local/HTTPS webviews.
- Hardened attached webview preferences and denied popups.
- Content Security Policy.
- Main/preload/renderer process separation.
- Secret providers: historical `.env` plus an optional bounded command provider.
- Windows NSIS and portable builds; macOS DMG/notarization settings; Linux AppImage, Snap, DEB, and RPM.
- Vitest unit/integration tests, renderer component tests, and live regression scripts.

Sources: `../hermes-desktop/src/main/security.ts:1-106`, `../hermes-desktop/src/main/app/start.ts:45-201`, `../hermes-desktop/electron-builder.yml:1-73`, `../hermes-desktop/package.json:8-31`.

**Wing disposition:** preserve security outcomes with native Flutter/platform mechanisms. Do not reproduce Electron-specific webview, CSP, package, or updater implementation.

## Exposed bridge features that are not current UI features

The preload interface exposes 244 methods; a source scan found 38 with no non-test renderer call in the studied commit. Important examples include:

- Legacy Claw3D setup/dev-server/adapter controls.
- Local wallet create/import/rename.
- Kanban board removal, reassignment, and comment creation.
- MCP catalog install methods superseded in the UI by Discover.
- Lower-level model-definition CRUD and platform-toggle aliases.

These methods may support tests, old screens, future work, or compatibility. They are not proof of a user-facing feature. Parity should follow reachable renderer behavior and executable scenarios, not preload surface area alone.

Source: `../hermes-desktop/src/preload/index.d.ts:229-1249` compared with non-test `window.hermesAPI.*` calls under `../hermes-desktop/src/renderer/src/`.

## Source contradictions resolved

| Claim | Live-source finding |
| --- | --- |
| “22 slash commands” | Commands are runtime-discovered and merged with larger fallback/Desktop catalogs; no stable fixed count. |
| “14 toolsets” | Current `TOOLSET_DEFS` has 19. |
| “16 messaging gateways” | Current messaging catalog has 20 cards. |
| Models and Soul are standalone screens | Current navigation folds Models into Providers and Soul into Memory/Profile. |
| Office uses an external Claw3D dev server | Current Office uses an in-renderer React Three Fiber scene; old Claw3D bridge methods remain unused by the renderer. |
| Schedule editing is available | Current Schedules UI creates, pauses/resumes, triggers, and deletes; it does not edit an existing job. |
| All preload APIs are product features | 38 declared methods have no current non-test renderer call. |

## What Wing should copy

- User outcomes and information hierarchy.
- Chat timeline semantics for streaming, tools, reasoning, approvals, clarify, usage, and failure recovery.
- Contextual composer behavior and honest attachment states.
- Session search, rename/delete, and active-run clarity.
- Gateway-scoped profile administration.
- Provider/model, Discover, Tools/MCP, Memory, Tasks, Gateway, and Office outcomes only when authoritative contracts exist.
- Adaptive presentation: Telegram-like mobile chat, compact 2D Office on mobile, richer desktop layouts where useful.

## What Wing must not copy

- Direct Hermes CLI invocation.
- Reads/writes of `~/.hermes`, YAML, JSON, SQLite, PID files, or SSH-host files.
- Mutation of the CLI's global `active_profile`.
- Per-profile gateway ports as the client profile model.
- Dashboard WebSockets as a Wing transport.
- Client paths for remote attachments, context folders, or Kanban workspaces.
- Local shadow profiles, memory, skills, schedules, Kanban, provider configuration, or gateway state.
- Electron's local wallet store as a Wing wallet subsystem.
- Electron updater/install recipes on Android or web.
- Disabled or preload-only controls presented as completed parity.

## Porting priority from this study

1. Keep chat, sessions, profiles, attachments, voice, and reconnect behavior validated.
2. Add provider/model administration only through advertised write-only/revision-safe contracts.
3. Add Discover, Skills, Tools, and MCP as one profile-explicit capability group.
4. Add Memory and Tasks through authoritative GET/mutation/event contracts.
5. Add Gateway administration with explicit restart/apply dispositions.
6. Build adaptive Office over shared profile/chat/account outcomes.
7. Add desktop-only host adapters last: runtime install/update, SSH, filesystem grants, windows/menus, and signed package update flows.

## Update triggers

Re-run this study when:

- the sibling Desktop commit changes;
- a Desktop destination or reachable renderer workflow changes;
- `src/preload/index.d.ts` gains a method that becomes renderer-reachable;
- Hermes Agent advertises a new authoritative profile, provider, memory, task, gateway, backup, or resource-handle contract;
- the frozen planning baseline or retirement cutoff changes.
