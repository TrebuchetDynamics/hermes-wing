# Hermes WebUI feature and architecture study

Status: source-backed planning input

Reviewed: 2026-08-12

## Study baseline

- Reference repository: `nesquena/hermes-webui`[1]
- Studied branch: `master`
- Studied commit: `483772b44b585b3185c2420a80f05ce268f47d2d`
- Commit date: 2026-08-12 (`2026-08-12T06:58:06Z`)
- Tag on the studied commit: `exp-v0.52.203` (prerelease)
- Latest stable release observed during the study: `v0.52.106` (2026-07-29)
- Target: Hermes Wing current working tree
- Reference access: read-only

This is a frozen reference baseline. Later WebUI changes enter a separate delta
review; they do not silently alter Hermes Desktop retirement criteria, Wing's
authority model, or an in-flight Wing slice.

This study inventories reachable user outcomes and durable product contracts. It
does not treat route declarations, test names, README claims, or unused backend
helpers as shipped features by themselves.

## Executive conclusion

Hermes WebUI is a mature browser companion with especially strong long-running
chat, recovery, session-management, onboarding, and operational-diagnostics
patterns.[2][3] Hermes Wing should adapt those outcomes where Hermes Agent
advertises an authoritative HTTPS/SSE contract. It should not copy WebUI's local
Python integration, direct Agent imports, filesystem/database access, config
writes, or process-global runtime mechanisms.

That distinction is not merely a Wing preference. WebUI's own source-boundary
audit says its durable target is to remove the direct Agent source mount and
move Agent-owned state and runtime operations behind HTTP endpoints plus a small
versioned client/schema package.[9] Wing already starts on the target side of
that boundary: Hermes Agent owns sessions, runs, profiles, providers, skills,
memory, schedules, gateway state, and credentials; Wing is an adaptive client.

## Reachable product topology

The current WebUI presents:

- a conversation-first shell with session history and search;
- a composer with model, reasoning, busy-input, attachment, and voice controls;
- progressively disclosed reasoning, tools, approvals, clarification, and live
  activity;
- session projects, pin/archive/tag, branch, import/export, and batch actions;
- a demand-driven workspace/files panel with previews, editing, upload, Git
  status, and terminal;
- control-center surfaces for profiles, providers/models, skills, memory, cron,
  MCP, extensions, appearance, authentication, health, and diagnostics;
- mobile navigation and an installable PWA shell;
- first-run provider/workspace/authentication setup and detailed troubleshooting.

The repository also contains numerous compatibility, recovery, and future-facing
routes. They are planning evidence only unless a current non-test UI action,
transport hook, and backend transition form a complete path.

## Highest-value lessons for Hermes Wing

### 1. One owned assistant-reply lifecycle

WebUI's accepted Live-to-Final contract models a long run as one owned assistant
reply: live process prose, supporting tool/reasoning activity, recovery/replay,
terminal evidence, and a final answer or honest non-success outcome.[7] It rejects
"stream ended" as sufficient proof of successful completion and requires stale
events to leave the current visible reply untouched.

**Wing disposition: adapt early.** Wing already owns streams by session/run and
keeps background sessions running. The next completion slice should make the
canonical-final rule explicit:

- reconcile only the assistant segment owned by the exact session/run;
- preserve reasoning and tool boundaries rather than flattening them into prose;
- accept authoritative replacement only when the streamed text is a plausible
  ordered lossy copy;
- show distinct cancelled, interrupted, no-response, tool-limit, compression-
  exhausted, connection-lost, and error outcomes when Hermes advertises them;
- preserve the same lifecycle after reconnect, process restoration, and session
  switching.

This is more important than adding a second ornamental activity surface.

### 2. Progressive disclosure over one activity model

WebUI projects the same assistant-turn activity into Compact Worklog,
Transparent Stream, or Final-answer-only views rather than creating competing
owners.[7] Tool arguments, raw output, and debugging detail remain behind deeper
disclosure while process prose and the final answer stay readable.

**Wing disposition: adapt presentation, not storage.** Keep Hermes events as the
single source. Strengthen the existing reasoning/tool cards into a coherent
activity summary with:

- compact live progress;
- collapsed settled activity;
- readable tool/result summaries;
- preserved chronological boundaries;
- no hidden or truncated final answer;
- reduced-motion and 200%-text behavior.

Transparent Stream is a later preference, not a prerequisite for chat quality.

### 3. Explicit busy-input semantics

WebUI's pending-intent RFC distinguishes three meanings that must not be
collapsed:[8]

- **Queue:** a future normal user turn owned by the session;
- **Steer:** mid-run guidance owned by the active run;
- **Stop-and-send:** explicit cancellation followed by a queued next turn.

It also records the failure modes: queued input lost on refresh, transient steer
with no replay provenance, and cancel/send races that display a user message the
Agent never durably accepted.[8]

**Wing disposition: contract-gated, high priority.** Keep current queue behavior,
but do not infer Steer or Stop-and-send from ordinary send/stop calls. Require
Hermes-advertised typed controls and durable IDs. Once available:

- show queued input as an editable/deletable compact composer card;
- render accepted Steer as user-authored causal timeline content;
- keep it through settle/replay;
- prevent stale run IDs from receiving guidance;
- never replay a failed offline intent automatically.

### 4. Recovery is a product state

WebUI treats reload, SSE loss, stale worker bookkeeping, process restart,
compression exhaustion, and recovered partial output as distinct user-facing
states, with durable run-journal and session-reload paths behind them.[5][7]

**Wing disposition: adapt semantics through Hermes contracts.** Wing must not
create a client run journal or inspect Agent files. It should consume typed
server recovery/status events, retain bounded local accepted-run handles, and
fall back to authoritative session GET reconciliation. Add explicit restoring,
degraded, connection-lost, and focused-continuation guidance instead of showing
a generic failure or silently declaring completion.

### 5. Session organization beyond a flat history

WebUI offers pinning, archiving, projects, tags, branching, import/export, bulk
operations, lineage grouping, and cross-device recency updates.[3]

**Wing disposition: split by authority.** Search, branching, export, and selected
mutations already exist. Add pin/archive/project/tag/import only when Hermes
advertises exact profile-scoped, revision-safe contracts. Client-local filters
may control presentation, but must not become a shadow session taxonomy.

### 6. Renderer quality as core behavior

WebUI treats Markdown tables, syntax highlighting, code copy, media, Mermaid,
KaTeX, narrow-screen containment, and mobile scroll stability as permanent
regression surfaces.[3]

**Wing disposition: adapt incrementally.** The current Wing delivery improves
Markdown hierarchy, fenced code, copy, attachment cards, and overflow safety.
Future renderer slices should prioritize:

1. tables and links with narrow-screen containment;
2. selectable/copyable code and diff fidelity;
3. server-provenanced media/artifact links;
4. KaTeX math when a maintained Flutter renderer and accessibility fallback are
   available;
5. Mermaid only with a sandboxed, non-executable rendering path and a readable
   text/source fallback.

Never execute transcript HTML or scripts to obtain parity.

### 7. First-run and troubleshooting information architecture

WebUI separates local bootstrap, Docker variants, WSL, remote access, provider
setup, workspace setup, authentication, and safe isolated trial state.[4] Its
troubleshooting entries consistently use **Symptom → Why → Diagnostic → Fix →
When to file a bug**, and explicitly warn users not to paste keys, cookies,
tokens, private paths, or full environment files.[5]

**Wing disposition: adapt now.** Wing Link documentation should use the same
problem-solving structure while preserving Wing's narrower role. Add focused
runbook entries for:

- clean install versus healthy-install adoption;
- signed-manifest/artifact verification failures;
- Hermes setup/provider readiness failures;
- loopback/private listener and phone reachability;
- one-time pairing expiry/revocation;
- service start/restart/health disagreement;
- scoped enrollment unavailable versus explicit full-access compatibility;
- safe diagnostics and support-bundle redaction.

Do not add Docker or source-mount instructions merely because WebUI uses them.

### 8. Authentication and remote access outcomes

WebUI supports optional password cookies, passkeys, OIDC, localhost defaults,
Tailscale-oriented remote access, CSRF protections, and secure-cookie behavior.[2]

**Wing disposition: preserve outcomes through different mechanisms.** Wing uses
native secure storage and Hermes scoped bearer enrollment, not WebUI cookies.
Hermes One/OIDC may be added only as an advertised account-service contract.
Passkeys are relevant to future browser-hosted enrollment but are not a reason
to add a Wing-owned identity database. Keep loopback/private-network defaults,
HTTPS warnings, origin review, credential rotation, and revocation central.

### 9. Notifications and background attention

WebUI provides completion/error/approval attention states and browser/PWA
notifications.[3]

**Wing disposition: contract-gated.** Continue the existing plan for
server-advertised, endpoint-opt-in, content-redacted run notifications. Push
metadata must contain no transcript, prompt, tool arguments, approval payload,
or private route identifier. Notifications are optional UX and never the source
of detached-run correctness.

### 10. Operational contract routing

WebUI maintains a contributor-facing contract index routing changes to
streaming, recovery, pending-intent, session-SSE, UI, security, onboarding, and
operations documents.[6]

**Wing disposition: adapt documentation discipline.** Add this study to the docs
index and require each future parity slice to name:

- authoritative owner and endpoint;
- required capability, scope, profile, revision, and event identity;
- offline/reconnect behavior;
- redaction and platform exclusions;
- focused regression and intended evidence tier.

## Capabilities Wing must not copy

| WebUI mechanism/outcome | Wing disposition | Reason |
| --- | --- | --- |
| Direct imports from the Agent checkout | Never copy | Breaks client/server authority and mobile distribution. WebUI itself plans to remove this dependency.[9] |
| Reads/writes of Agent SessionDB, config, profiles, skills, memory, cron, credential pools, or runtime provider internals | Never copy | Creates a second privileged backend and bypasses scoped contracts. |
| Workspace filesystem browser/editor and embedded terminal over arbitrary server paths | Never copy directly | Remote clients require picker-originated opaque resource handles and explicit server policy. |
| WebUI-owned session JSON as canonical Hermes history | Never copy | Hermes sessions are authoritative; Wing may persist only bounded client state and accepted handles. |
| Password/passkey/OIDC user database in Wing | Never copy | Authentication belongs to Hermes enrollment or an optional account service. |
| Python bootstrap/source mounts/Docker topology | Never copy | Wing Link installs/adopts and supervises a pinned Hermes runtime; Flutter packages contain no Agent runtime. |
| WebUI extension JavaScript/sidecars with full session authority | Defer/likely exclude | Incompatible with mobile sandboxing and Wing's small trusted client surface; Hermes plugins remain server-owned. |
| Public share snapshots generated from local WebUI state | Contract-gated | Requires server-owned redaction, revocation, expiry, attachment policy, and profile authorization. |
| Local config/provider/profile mutation used as API fallback | Never copy | Unsupported operations must remain explicitly unavailable. |

## Roadmap changes from this study

These are additions or refinements to the existing program roadmap, not a new
parallel product plan.

### P0 — trustworthy chat lifecycle

1. Canonical-final assistant reconciliation with exact session/run ownership.
2. Typed terminal outcomes and visible restoring/degraded states.
3. Chronological tool/reasoning/activity projection over one turn owner.
4. Regression matrix for dropped stream chunks, stale finals, pre/post-tool
   prose, session switching, reconnect, and process restoration.

### P1 — busy controls and durable recovery

1. Make Wing's existing session-owned Queue visible, editable, and durable as
   unsent client-local intent without representing it as Hermes state.
2. Add a Hermes Agent contract for Steer and Stop-and-send with accepted intent
   IDs and exact run/session ownership; keep those controls unavailable before
   the contract exists.
3. Preserve an accepted Steer as a persistent causal timeline boundary.
4. Typed compression-exhausted/focused-continuation recovery.
5. Optional redacted completion/approval notifications.

### P1 — session organization and artifacts

1. Revision-safe pin/archive/project/tag/import contracts.
2. Opaque resource/artifact handles, picker grants, previews, and downloads.
3. Produced-artifact handoff that survives settle/replay without exposing host
   paths.

### P2 — renderer and adaptive polish

1. Tables/link containment and stronger message-selection actions.
2. Accessible math rendering with source fallback.
3. Sandboxed Mermaid rendering with readable fallback.
4. Optional activity display preference after the single-owner lifecycle is
   complete.

### P2 — setup and operations documentation

1. Wing Link troubleshooting organized by symptom and evidence.
2. Provider-readiness and first-chat checklist after install/adoption.
3. Safe diagnostic bundle guidance with explicit redaction list.
4. Platform-specific service and reachability diagnostics as adapters ship.

### Deferred

- General client extension/sidecar ecosystem.
- Public share URLs.
- Arbitrary remote terminal or filesystem editing.
- Browser-cookie authentication as a native-client identity system.
- WebUI-specific Docker/Python/source-checkout lifecycle.

## Verification requirements for adopted slices

Every adopted behavior must include:

- an exact Agent contract and fail-closed unsupported state;
- profile/session/run ownership and stale-event rejection;
- no offline mutation replay;
- secret/content redaction tests;
- narrow-screen and 200%-text coverage;
- focused RED→GREEN regression;
- full Flutter suite and static analysis;
- Android and web release builds where affected;
- current device/integration evidence before claiming qualification.

WebUI screenshots, source tests, or production maturity do not qualify a Wing
implementation. They are reference evidence only.

## Duplicates already present in Wing

Do not re-add these as new roadmap features: HTTPS/SSE chat, concurrent
session-owned runs, detached-run duplicate protection, reasoning/tool cards,
approval review, rich Markdown and code copy, Telegram-style bubbles and
structured attachment cards, stable profile colors, session search/export/
branching/bulk deletion, read-only skills/tools/models/schedules/health, the 2D
Office directory, Wing Link installation/adoption/pairing/lifecycle, and the
strict separation between deterministic voice fixtures and physical acoustic
qualification. Future work on these is refinement or current-source
qualification, not feature discovery from WebUI.

## Sources

[1] https://github.com/nesquena/hermes-webui

[2] https://raw.githubusercontent.com/nesquena/hermes-webui/483772b44b585b3185c2420a80f05ce268f47d2d/README.md

[3] https://raw.githubusercontent.com/nesquena/hermes-webui/483772b44b585b3185c2420a80f05ce268f47d2d/ROADMAP.md

[4] https://raw.githubusercontent.com/nesquena/hermes-webui/483772b44b585b3185c2420a80f05ce268f47d2d/docs/onboarding.md

[5] https://raw.githubusercontent.com/nesquena/hermes-webui/483772b44b585b3185c2420a80f05ce268f47d2d/docs/troubleshooting.md

[6] https://raw.githubusercontent.com/nesquena/hermes-webui/483772b44b585b3185c2420a80f05ce268f47d2d/docs/CONTRACTS.md

[7] https://raw.githubusercontent.com/nesquena/hermes-webui/483772b44b585b3185c2420a80f05ce268f47d2d/docs/rfcs/live-to-final-assistant-replies.md

[8] https://raw.githubusercontent.com/nesquena/hermes-webui/483772b44b585b3185c2420a80f05ce268f47d2d/docs/rfcs/webui-pending-intent-controls.md

[9] https://raw.githubusercontent.com/nesquena/hermes-webui/483772b44b585b3185c2420a80f05ce268f47d2d/docs/architecture/agent-api-contract.md
