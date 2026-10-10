# Bounded desktop-local integration design

> Current Flutter port target: `hermes-agent/apps/desktop/`, the official Nous Research app. Follow [the plan reference policy](README.md). The old transport comparison below is withdrawn, not a finding about the official app.

> Reference correction: [official Desktop authority](../quality/official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Date: 2026-10-03. Status: decision-ready proposal, **not implementation authorization or platform acceptance**.

## Recommendation

Use a small **in-process, desktop-only host coordinator** around the existing secure endpoint store, `HermesChannel`, and fixed bundled Wing Link inspection/setup seam. Keep Agent traffic direct. Do not introduce another HTTP management service merely to make local mode work. Reuse Wing Link's existing remote management contracts where already needed; do not expand them into a Desktop backend.

Deliver one workflow first: **connect to an already configured local Agent → select explicit profile and session model → generate → answer one approval or Stop → leave → restore the same durable session with no duplicate send**. Most of this is existing direct Agent domain work, not privileged native work. The initial new native contract needs installation inspection and safe selection of an already enrolled local connection, not provider/config/file administration or a second chat implementation.

A native dashboard/`serve` transport is a separately gated candidate, not a prerequisite for this first milestone. The inspected local dashboard authentication path has a concrete conflict with Wing's no-credentials-in-URLs rule. Do not copy Desktop's token URL, patch Agent, or relax the rule to activate it. Full local parity is the product goal; operations without a safe unmodified Agent contract remain explicitly unavailable until individually qualified.

## Authority and evidence

The [goal ledger](2026-10-03-desktop-port-goal.md), owner decisions 1–3, accepts Desktop-first fidelity, full local functionality via bounded native integration, a smaller remote subset, and the daily workflow above. It explicitly does **not** authorize arbitrary shell/filesystem/config access or Agent modification. This lane writes only this report. Concurrent harness and documentation lanes retain their recorded scopes; continuation must not implement this proposal while those scopes are leased.

Binding decisions: [product](../adr/product.md), [client](../adr/client.md), [API/state](../adr/api-and-state.md), [runtime/delivery](../adr/runtime-and-delivery.md), [security/privacy](../adr/security-and-privacy.md), [threat model](../security/threat-model.md), and [security policy](../../SECURITY.md). A local integration contract that expands compatibility authority requires a separately approved scope and corresponding living-ADR review **before** code. Locality never grants remote permissions or ownership of Agent state.

### Source pins

Observed reference revisions:

| Repository | HEAD | Worktree qualification |
| --- | --- | --- |
| Wing | `ca149a82189c8c9e5abd98b376bfeae1e43f6f3f` | Extensively dirty, including current production/channel changes and untracked qualification clients. HEAD alone is not their content snapshot. |
| Agent | `158fd638da1629c8e62caf9ade1515d162def8ab` | `git status --short` returned empty. Source evidence for this reference only, not the installed runtime. |
| Desktop | `withdrawn reference revision` | Existing `.claude` settings/skill deletions observed; preserved. Inspected main/preload sources are reference evidence, not runtime proof. |

SHA-256 content pins at inspection (concurrent changes require re-tracing before implementation):

```text
62bb6636dd0526ed7615cf99685dd42ac5df6c1fbdb34c4674ca951bdfd38a5b  withdrawn source citation
d9a81f3206ecf3b0b7be1f022f5ab3a035393f24abd9ced89af87ed7c68daf4e  withdrawn source citation
3b93c80366ea8fa05811d5fd1bc24a0a909bfd738dbe3372583f4e8ac77aa93b  withdrawn source citation
29a0b007e2a78eefed635d785a49c8c18b40c60329185d647157071bf4219290  lib/core/hermes/channel/hermes_channel.dart
e53915c6cc53ef9414e910b6574fb1b08275666fc4b5d5a05ee562f042a8e770  lib/core/hermes/client/hermes_web_read_client.dart
f40ab9494c64d42eb6e97406c3572c70e5cee00d3f6f9ce4ffd3ffb29f3958f2  lib/core/hermes/client/hermes_web_lifecycle.dart
e9f59be57ed26c400cc52fe731e6106b27547299e4546439cb7c5a52cf583b6b  lib/core/wing_link/local_wing_link_host.dart
777b70523383854b88ca336771ec8409f5f5bad6fcaa933e06db74b6fa5adaa9  docs/plans/2026-10-03-desktop-port-goal.md
```

Read both reference `AGENTS.md` files and relevant Agent CLI/web/TUI/gateway guides. Desktop's `lat` command was not available on PATH; no installation or semantic-key provisioning was attempted. Source files were inspected directly. No source test below was executed: parser declarations and inspected tests establish source contracts only.

### Source index

Paths are repository-relative; line ranges refer to inspected content, not immutable anchors. Symbols are the durable lookup keys.

| ID | Source and exact seam |
| --- | --- |
| D1 | [Desktop preload](../quality/official-desktop-reference.md#withdrawn-evidence), `hermesAPI`, `DashboardConnection` (71–81), install/adopt APIs (131–155): typed renderer calls via `ipcRenderer.invoke`, including paths and token-bearing dashboard descriptors. |
| D2 | [Desktop IPC registration](../quality/official-desktop-reference.md#withdrawn-evidence), `registerIpcHandlers` (728 onward), `send-message` (1679 onward), `approval-respond` (1930), dashboard handlers (2198–2212), `select-folder` (3279): privileged main-process dispatch and local/remote/SSH branches. Sender destruction aborts its owned legacy run (1733–1773); completion notifications can include a transcript preview (1811–1825). |
| D3 | [Desktop local backend](../quality/official-desktop-reference.md#withdrawn-evidence), `startDashboard` (617–739), `stopDashboard` (742–752); [argument builder](../quality/official-desktop-reference.md#withdrawn-evidence), `buildLocalDashboardCliArgs`: per-profile child process, loopback port, token minted in main, environment handoff, readiness probe, token-bearing WebSocket URL. |
| D4 | [Desktop compatibility](../quality/official-desktop-reference.md#withdrawn-evidence), `ensureLocalDashboardCompatibility` (485–517), called by D3 (647): reads and may rewrite Agent `hermes_cli/web_server.py`. This mechanism is forbidden in Wing. |
| D5 | [Desktop gateway/chat](../quality/official-desktop-reference.md#withdrawn-evidence), `resolveProfile`, `getApiUrl`, `getApiAuthHeaders` (101–212): explicit profile can fall back to global file-backed selection; local gateway uses per-profile ports and keys. |
| D6 | [Desktop profiles](../quality/official-desktop-reference.md#withdrawn-evidence), `createProfile` (269–325), `deleteProfile` (328–366), `setActiveProfile` (368–409): fixed CLI creation/deletion but extra profile metadata write, global `profile use`, and `active_profile` fallback write. |
| D7 | [Desktop config](../quality/official-desktop-reference.md#withdrawn-evidence), `readEnv`, `setEnvValue`, `getConfigValue`, `setConfigValue`, `setModelConfig`; [sessions](../quality/official-desktop-reference.md#withdrawn-evidence), `deleteSession` / transaction (771–801); [memory](../quality/official-desktop-reference.md#withdrawn-evidence), `writeMemoryRaw`, entry mutations; [SOUL](../quality/official-desktop-reference.md#withdrawn-evidence), `writeSoul`: privileged local Agent-file/database access, not a Wing contract. |
| D8 | [Desktop cron](../quality/official-desktop-reference.md#withdrawn-evidence), `listCronJobs`, CLI runner (324 onward); [toolsets](../quality/official-desktop-reference.md#withdrawn-evidence), `setToolsetEnabled`; [MCP](../quality/official-desktop-reference.md#withdrawn-evidence), `readConfig`, `writeConfig`, `addMcpServer`: mixed local file reads/edits and CLI operations; not wholesale compatibility authorization. |
| A1 | [Agent API server](../../hermes-agent/gateway/platforms/api_server.py), `_CAPABILITY_ENDPOINTS` (78–102), `_http_route_table` (1751–1793): exact advertised direct endpoints, distinct from dashboard REST/WS. |
| A2 | [Agent server parsers](../../hermes-agent/hermes_cli/subcommands/dashboard.py), `_add_server_runtime_args`, `_configure_serve_parser`, `build_dashboard_parser` (15–101); [parser tests](../../hermes-agent/tests/hermes_cli/test_fast_serve_launch.py), `test_lean_serve_parser_matches_full_subcommand_parser`. |
| A3 | [Agent dashboard auth](../../hermes-agent/hermes_cli/web_server.py), `_resolve_session_token` (364–371), `_has_valid_session_token` (452 onward), `_desktop_loopback_auth_exempt` (541–560); [WS auth](../../hermes-agent/hermes_cli/web_server_chat.py), `_ws_auth_reason` (250–374); [WS route](../../hermes-agent/hermes_cli/web_routers/chat_ws.py), `gateway_ws` (595–613). |
| A4 | [Native auth routes](../../hermes-agent/hermes_cli/dashboard_auth/routes.py), `api_auth_ws_ticket` (485–493), native authorize/token/refresh; [ticket store](../../hermes-agent/hermes_cli/dashboard_auth/ws_tickets.py), `mint_ticket`, `consume_ticket` (36–61). |
| A5 | [TUI contracts](../../hermes-agent/tui_gateway/contracts/sessions.py), `SessionCreateParams` (118–139), `SessionResumeParams` (182–194), `session.history` (493), `session.interrupt` (598–614), `SessionEventsSinceResult` (717–731); [prompt/approval](../../hermes-agent/tui_gateway/contracts/prompt_voice.py), `prompt.submit` (26–77), `approval.received` / `approval.respond` (304–330); [negotiation](../../hermes-agent/tui_gateway/contracts/liveness.py), `ClientCapabilitiesParams` (29–48). |
| A6 | [Native model contract](../../hermes-agent/tui_gateway/contracts/config_free_tier_control.py), `ConfigSetParams`, `ModelOptionsParams`; [setter](../../hermes-agent/tui_gateway/methods_config_set.py), `_set_model` (107–163); [model switch](../../hermes-agent/tui_gateway/model_switch.py), `_switch_request` (178–197), `_apply_model_switch` (295 onward). Model strings are parsed as flags; generic string forwarding can change persistence scope. |
| A7 | [Profile parser](../../hermes-agent/hermes_cli/subcommands/profile.py), list/create/delete/rename declarations; [auth parser](../../hermes-agent/hermes_cli/subcommands/auth.py), `auth add` (12–38). `--api-key` exists but is forbidden for Wing secrets; there is no basis here to invent an `--stdin` flag. |
| W1 | [Wing channel](../../lib/core/hermes/channel/hermes_channel.dart), `connect`, `restoreSession`, `selectProfile`, model/inventory APIs, interruption target; [production API channel](../../lib/core/hermes/channel/hermes_api_channel.dart), [URI config](../../lib/core/hermes/client/hermes_api_config.dart), [readiness](../../lib/core/hermes/policy/hermes_surface_readiness.dart). Client URI constants are not proof Agent advertises them. |
| W2 | [Internal native reads](../../lib/core/hermes/client/hermes_web_read_client.dart), `productAuthorization`, `connectLifecycleForQualification`, `_connect` (128–176); [native lifecycle](../../lib/core/hermes/client/hermes_web_lifecycle.dart), create/resume, canonical/replay, submit, interrupt, approval; [RPC seam](../../lib/core/hermes/client/hermes_web_read_rpc.dart), `_read`. Explicit internal qualification only, not production enrollment/channel. |
| W3 | [Local host](../../lib/core/wing_link/local_wing_link_host.dart), `inspect`, `setup`, bundled executable resolution; [process implementation](../../lib/core/wing_link/local_wing_link_platform_io.dart), Linux-only `Process.start`, `runInShell: false`, output/time limits; [Go inspection](../../wing_link/internal/app/inspect.go), `inspectLocalInstallation`. Inspection's `hermes_healthy` means successful version parsing, **not** inference or API readiness. |
| W4 | [Secure endpoint store](../../lib/core/hermes/setup/secure_hermes_endpoint_store.dart), `saveAll` (58–143), independent Agent/Link token fields; [Linux runner](../../linux/runner/my_application.cc), `create_host_command_channel`, Settings menu dispatch (125 onward). The menu channel is not an Agent privileged-operation broker. |
| W5 | [Wing Link pairing](../../wing_link/internal/app/pair.go), `issuedHermesConnection`, `ensureHermesProfileMultiplex` (747 onward); [bootstrap](../../wing_link/internal/app/bootstrap.go), fixed `config env-path`, API setup and restart shapes; [profile adapter](../../wing_link/internal/app/serve.go), `profileBackend` / setup; [host execution](../../wing_link/internal/hostexec/process.go), fixed process runner. These management seams retain their existing approval and trust boundaries. |

## Source-backed authority map

| Desktop user outcome | Authority and reusable Wing path | Bounded native responsibility | Initial / later status |
| --- | --- | --- | --- |
| Connect, inspect installation | Agent answers its API health/capability requests (A1); endpoint credentials in W4, channel W1. Desktop D1–D5 combines several authorities. | W3 read-only installation inspection; resolve only a previously enrolled connection by opaque Wing ID. No scan of `.env`, auth pools or arbitrary directories. | Initial. No automatic setup, restart or new enrollment on an inspection/read. |
| Select profile | Agent resource identity; W1 client-local selection. API multiplex prefix is `/p/<profile>/…` (A1). | None for switching. Reuse existing reviewed profile inventory adapter only if direct profile inventory is absent and independently authorized. | Initial selection, not create/rename/delete. Never D6 global active-profile state. |
| Pick model, generate, approval, Stop | A1 direct session model lock/chat/run endpoints; existing W1 channel and approval responder. Native A5/A6 are a different potential transport. | None for the data plane. Secure credential retrieval stays inside trusted transport wiring. | Initial where exact endpoint and required grants are present. No provider credential/default-config mutation. |
| Leave and exact restore | Agent durable session/history/run state; W1 `restoreSession`, `reconcileActiveSession`, generation-bound interruption identity. A5 distinguishes stored vs runtime IDs. Session model text is not confirmed provider/model readback. | Wing may remember only connection/profile/durable-session selection and client drafts/preferences, not reconstruct sessions, persist a shadow pair or replay actions. | Initial identity/history recovery where qualified; exact restored pair is blocked pending a supported authorized read. Leaving a route is not quitting/killing Agent, and reconnect is not automatic prompt resubmission. |
| Start/stop backend, install/update | External Agent runtime; Wing Link host lifecycle W3/W5. D3 is child ownership, not persistent service ownership. | Fixed owned-process/service operations, local confirmation, verification and rollback. No process scanning/kill-by-name from UI. | Existing setup remains separately consented; new `serve` launch and lifecycle expansion deferred. |
| Profile lifecycle/new-profile setup | Advertised Agent API if exact; otherwise current W5 reviewed typed adapter. | Reuse its transaction/authorization; no extra files, active-profile writes or secret export (D6). | Later than daily workflow; current approved adapter is not full Desktop admin permission. |
| Provider/OAuth/config/model defaults | Agent owns credential pools and configuration. Direct exact secret-safe APIs preferred; existing-provider compatibility ADR is design-only. | Future local host sign-in orchestration or fixed stdin-only writes only after supported semantics/concurrency review. | Deferred. D7 raw env/config access and generic A6 `config.set` must not become public Wing interfaces. |
| Memory, Persona, sessions administration | Agent owns content and DB. Existing exact scoped Persona APIs stay available when advertised. | No local file/database editor. Typed native Agent operation may be evaluated individually. | Deferred beyond existing gates. D7 direct writes/deletes forbidden. |
| Schedules, tools, skills, MCP, Projects | Agent owns state. A1 has skills/toolsets reads and job routes in source; route registration alone is not scoped advertisement. W1 readiness must gate actual actions. | Later approved directory handles may translate only inside a fixed Agent Project operation. MCP executable definitions require separate security scope. | Remote/current mutations remain contract-gated; never read/edit `jobs.json`, tool YAML, skill trees or invent profile workdir stores. |
| Attachments/export, clipboard, speech, notifications, shell UI | OS owns device operations; Agent owns session attachment ingestion. | User-selected bounded file handles/bytes, explicit clipboard action, redacted notification; accessibility/native UI adapters. | Separate native qualification. No unrestricted host file tree or transcript-preview notification by default; no physical audio claim. |
| SSH/cloud/account/wallet/3D | External authorities and optional presentation (D2 branches). | No blanket SSH exec, sudo/password broker or cloud credential copying. | Not needed for first workflow; individually inventoried/authorized later. Accessible equivalents mandatory. |

## Exact contracts that can and cannot be reused

### Preferred direct API path

A1 advertises in source: `GET /v1/capabilities`, `GET /api/model/options`, `GET/POST /api/sessions`, `GET /api/sessions/{session_id}`, `GET /api/sessions/{session_id}/messages`, `POST /api/sessions/{session_id}/model`, `POST /api/sessions/{session_id}/chat/stream`, `POST /v1/runs`, `GET /v1/runs/{run_id}`, `GET /v1/runs/{run_id}/events`, `POST /v1/runs/{run_id}/approval`, and `POST /v1/runs/{run_id}/stop`.

This list is **reference source evidence**, not the live host capability document. Reuse the existing Wing caller/policy/tests and require the connected host's exact operation and all required grants, supported schema and current identity. Keep explicit profile context according to the chosen surface; a multiplex origin and dashboard `profile` query are not interchangeable. Do not add invented profile/config/audio/enrollment endpoints simply because W1 has corresponding abstract methods or URI constants.

A1's authenticated exact-session GET projects model text, not provider/runtime/lock; model POST's accepted pair is a write acknowledgment, not a later read contract. Keep metadata display, volatile acknowledged selection, pending native switch and effective runtime distinct. Missing/revoked/mismatched fields leave selection unconfirmed: no provider inference from catalog/defaults, synthetic lock, shadow pair store or repeated POST to reconstruct it. See the [runtime-pair assessment](../quality/2026-10-04-desktop-cron-0147-runtime-pair.md) and [native resume review](../quality/2026-10-04-desktop-cron-0225-native-model-review.md). Exact-pair restoration remains an unmet milestone criterion, not a reason to weaken the existing browser oracle.

Source also registers job mutations (A1 lines 1780–1787), while [route status](../product/routes.md) says exact scoped mutation advertisement is missing. This is not a reason to enable those controls. Registration, advertisement, authorization and qualification are distinct checks.

### Native dashboard candidate: blocked authentication handoff

A2 supports the fixed candidate shape `hermes --profile <validated-profile> serve --isolated --host 127.0.0.1 --port <host-selected-port>`. `serve` is headless and does not require rebuilding the browser frontend. The older separate Desktop reference D3 actually launches `dashboard --isolated --no-open --host 127.0.0.1 --port <port>` with optional `--skip-build`; do not confuse it with Agent's newer in-repository desktop architecture. These are supported parser shapes, **not** approved commands to run now. No caller-selected executable, bind host, cwd, extra flags, environment overlay or port override.

D3 mints `HERMES_DASHBOARD_SESSION_TOKEN`, sets `HERMES_DESKTOP=1`, and returns a token-bearing WS URL. A3 ungated loopback WS (369–374) accepts `?token=`; it does not establish an Authorization-header alternative for that branch. A3's Desktop loopback exemption requires that environment combination and can bypass the normal public-URL login gate for the private backend. Neither pattern should be silently adopted.

A4's `POST /api/auth/ws-ticket` requires an authenticated dashboard **Session** (`_require_session`), then mints a 30-second one-use ticket. Gated A3 accepts `hermes-gateway-v1` plus `hermes-gateway-ticket.<ticket>` subprotocols and echoes only the stable protocol. This is what W2's ticket client targets. A minted process `_SESSION_TOKEN`, gateway API key and provider-verified dashboard user session are not interchangeable. Do not assume a process token can mint an A4 ticket. Native authorize/token/refresh routes exist in A4, but their product enrollment, identity/scopes, private callback and secure-storage lifecycle have not been qualified here.

**Decision:** prefer existing direct API for the milestone. Native transport may proceed only through a qualified no-secret-URL acquisition path supplied by an unmodified Agent release, or supported gated native login plus ticket path demonstrated in an isolated target. If unavailable, native WS stays disabled. No token URL, reverse relay, Agent patch, exported provider key or invented CLI flag as a fallback.

### Native RPC narrowing if later admitted

Only typed daily-workflow operations should be projected into `HermesChannel`, not `rpc(method, params)`:

- Per-connection negotiation: `client.capabilities {server_requests: true}` (A5/liveness); handle only supported request classes and explicitly reject others. Its declared Params has no `profile` field. W2 currently passes one when opting into lifecycle; trace this against the installed contract before any production promotion. Source similarity is not compatibility proof.
- New session: `session.create` with explicit profile and only reviewed daily fields; A5 supports provider/model and idempotency key, but forbids treating those as a config transaction. No seeded messages, arbitrary cwd or tool/security flags. Stored ID and runtime ID remain separate.
- Restore candidate: `session.resume` with durable ID and profile is **not a passive read**. The [inspected branch review](../quality/2026-10-04-desktop-cron-0225-native-model-review.md) separates warm reattach, cold lazy/watch, deferred hydration, default cold and eager build. Warm reattach may expose pending display identity; cold `lazy: true` uses child/watch history and profile-model fallback, not stored pair recovery. Default cold/eager restore overrides but may schedule Agent-owned crash continuation; deferred's response-path lack of that call does not qualify hydration/build/next-turn behavior or select it for production. No branch is admitted here. After separately reviewed admission, canonical history/status and `session.events.since` must preserve origin/profile/stored ID/runtime ID and distinguish pending/effective/acknowledged identity. Epoch/truncation/open requests are recovery information, not durable event-storage guarantees. Project only bounded reviewed reply fields; never expose host paths.
- Submit: fixed `prompt.submit` with runtime session/profile/text. Its source contract can queue/steer busy sessions; initial Wing UX must refuse a second owned send rather than silently adopting busy semantics. A lost submit receipt remains uncertain; never fail over to HTTP and send again.
- Approval: exact current request identity; acknowledge display when required, correlate server request responses or the qualified `approval.respond` path. Restrict choices to offered `once`/`deny` for the first slice. No FIFO fallback, `all`, session-wide or permanent permissions. A receipt is not proof generation completed.
- Stop: `session.interrupt`; its interruption receipt is not canonical terminal outcome or process shutdown. Reconcile after transport loss.
- Models: `model.options` is a possible bounded catalog read, not session-pair readback; config provider reads and rendered `session.status` text cannot fill that authority gap. A6 `config.set key=model` parses flag-bearing strings and can affect persistence. Prefer A1 session-model API for explicit writes now, without claiming restored-pair support. Any later native setter must encode only validated catalog selections and verified session-only semantics; public `key`, scope or raw flag strings are forbidden.

These are **source-backed candidates**, not proposed new Agent capabilities. W2 remains an internal qualification seam with `unsupportedAuthorization`; converting it into production requires separate auth/transport/channel scope and regression evidence.

## Minimal local interface proposal

Names below are new **Wing-local typed methods**, not HTTP routes, Agent APIs or released Wing Link CLI subcommands. Host implementation can be Dart IO for fixed process work and platform plugins for secure storage/dialogs. Avoid Go FFI or a service unless measured isolation/lifecycle needs justify it.

```text
inspectLocalInstallation() -> LocalInstallationSummary
selectEnrolledLocalConnection(connectionId, expectedSelectionGeneration)
  -> LocalConnectionSelection
cancelLocalSelection(selectionGeneration) -> CancelledOrSettled
```

`LocalInstallationSummary`: schema version, platform, installation/version-probe enum, bounded version label, enrollment-required boolean and exact local operation availability/reasons. No paths, env, logs, endpoint tokens or provider inventory. Delegate to W3 `wing-link inspect --json` where supported; its fixed subprocess is already present, not a new service. Keep version-probe success separate from authenticated API and inference readiness.

`LocalConnectionSelection`: opaque existing connection ID, explicit Agent profile identity, transport enum (`agentApi` only initially), new selection generation, bounded readiness state. Trusted composition looks up W4's secure connection material and calls W1; feature widgets receive state, not credentials. Local mode validates that the stored canonical origin is loopback before retrieving a credential. Remote connections remain a separate explicit mode; do not downgrade or rewrite their transport automatically. UI rendering may display reviewed endpoint metadata, but private endpoints never enter diagnostics.

`cancelLocalSelection`: invalidates acceptance of late reads/connection completions; does not interrupt a run or kill Agent. A current run keeps its separately captured owner/session/run/generation fences.

Proposed bounds: IDs 128 characters under the existing identity grammar; labels/version strings 128 characters; one local selection at a time; inspection at most 30 seconds and existing 256 KiB subprocess output ceiling (W3), projected summary at most 8 KiB; authenticated connect deadline at most 30 seconds with no automatic mutation retry. Exact limits should be regression-tested, not represented as upstream guarantees. Connection IDs are Wing identities, not renamed Agent profile IDs.

Enrollment remains the existing explicit reviewed flow, not an initial `readLocalSecrets` method. If no usable stored connection exists, return `enrollment_required` and route to enrollment; no background API-key creation, gateway enabling/multiplexing or restart. Existing setup/pairing W5 may change runtime state and therefore requires its own explicit consent and approved target. “Connect” must not silently invoke setup to bypass an authentication blocker.

### Consistent results and errors

Use a typed success result or `LocalIntegrationFailure(code, operation, retryDisposition)`, localized bounded user copy, no raw exception/stdout/stderr or upstream body. No HTTP status codes for an in-process interface.

| Failure | Code | Retry behavior |
| --- | --- | --- |
| Invalid ID, non-loopback local selection, wrong mode | `invalid_selection` | Correct explicit selection; no request with credential sent. |
| Missing installation/helper or unsupported OS | `local_unavailable` | No fallback executable/path search from UI input. |
| Secure store locked/unavailable, missing connection auth | `enrollment_required` / `secure_store_unavailable` | Explicit unlock/enrollment; never plaintext persistence. |
| Missing exact operation/grant/schema | `unsupported_operation` | Explain; do not try another admin surface automatically. |
| Selection/resource identity changed | `stale_selection` | Discard result, require current selection. |
| Deadline/oversized/malformed response | `inspection_failed` / `connection_failed` | Explicit retry for reads only; sanitized error. |
| Lost write/submission acknowledgment | Channel's authoritative uncertain state | Reconcile first; no native or transport replay. |

Consumers: connection/enrollment composition and existing Riverpod channel wiring; Chat/profile/model UI continues consuming W1 rather than new host methods. Platform hosts only supply necessary OS functions. Existing W3 and remote Wing Link protocol remain unchanged. No new datastore/domain schema or migration is proposed. Introduce the coordinator additively behind a desktop opt-in; rollback disables that wiring and retains existing manual connection. Do not remove existing Link dependencies as part of this proposal. Native interface v1 is internal to the matched app build; if a helper protocol is added later it needs explicit version negotiation and its own sunset/removal trigger.

## Wing Link reuse versus in-process integration

| Option | Benefits | Risks/costs | Recommendation |
| --- | --- | --- | --- |
| Existing local bundled Wing Link fixed CLI invocation | Reuses shipped inspection/setup and bounded runner; no new listener. | Linux-only Dart implementation; setup has broader effects and cannot masquerade as connect. Helper integrity and process-tree cleanup still require evidence. | Reuse inspection now. Existing setup only through its separate approved UI. |
| In-process local coordinator | Smallest wiring; secure storage and direct Agent client remain local; no pairing/TLS/HTTP service solely for same-device reads. | Not a security sandbox against compromised Wing code or same-user malware; no durable helper lifetime. OS packaging and secure storage vary. | Preferred initial design. A typed API reduces accidental authority, not OS-user privileges. |
| Reuse running Wing Link HTTP management | Existing independent credentials, grants, approvals, journals, directories and lifecycle for a paired host. | Pairing/service dependency and loopback attack surface; remote grants do not imply local admin; data plane must remain separate. | Retain for existing management needs, not mandatory for daily chat. |
| New native helper/daemon or expanded Link service | Can isolate privilege/process lifetime if a concrete later requirement needs it. | New protocol, authentication, packaging, lifecycle and review; easy to become a second backend/data proxy. | Defer until a justified host slice cannot safely fit current seams. No assumption that more HTTP is necessary. |

For later approved local-only operations, share validation/operation design with Link but do not automatically expose them remotely. A local trust decision may have no remote equivalent. Directory grant bookkeeping is host integration state; Agent Project/profile/path assignments must remain Agent-owned. An in-process interface cannot manufacture missing upstream concurrency, rollback or authentication semantics.

## Allowed, separately gated, forbidden

**Allowed initial proposal:** read-only bounded local installation inspection; selecting an already securely enrolled loopback connection; direct Agent daily-workflow calls through existing exact gates; client-local selection/drafts; reconciliation reads. This report authorizes none of their implementation or execution on personal runtime state.

**Separately gated later:** local enrollment/setup, profile lifecycle/new-profile transactions already within reviewed Link boundaries, supported Agent native authentication/transport, provider OAuth, directory/Project mapping, attachments/export, notifications, voice and admin controls. Each needs explicit operation authority, installed-source trace, nearest upstream tests, Wing caller/regression, local consent for sensitive writes, authoritative conflict semantics, timeout/redaction and platform receipts. A CLI parser's existence is not adequate authorization.

**Forbidden:** shell strings or caller-selected executables/argv/config keys/URLs/host paths; general RPC bridge; `profile use`/`project use`; copying Desktop's `.env`/YAML/SQLite/memory/SOUL writes; maintaining a replacement provider/model/profile/session/job store; provider secrets in argv/environment/ordinary preferences, bearer tokens in URLs/QR/clipboard/logs; D4 compatibility rewriting, injected Python internals or Wing Agent builds; generic SSH exec, privileged sudo credential broker; weakening grant/containment/TLS/rollback checks; automatic prompt/approval/config replay or transport fallback after uncertain writes; private transcript notification previews without reviewed consent.

The observed D3 environment-based **dashboard process token** is not a provider key, but still needs separate security review for child environment visibility/inheritance and its URL requirement. It is not silently permitted by the transactional stdin-only provider exception. `auth add` accepts `--api-key` in A7; Wing's approved adapter instead sends secret bytes through stdin (W5). Do not invent `--stdin` or treat add as credential replacement. Existing-provider atomic replacement/revision requirements remain those in the API/state ADR.

## Threat model for this proposal

All new controls below are **planned**, existing source controls **unverified at runtime in this lane**. This is not a scan, penetration test or security attestation.

| Asset | Data class | Primary loss |
| --- | --- | --- |
| Agent/Link credentials and provider keys | Secret | Disclosure |
| Sessions/transcripts and approved directory details | Private content | Disclosure |
| Profile/config/model/approval authority | Operational | Corruption |
| Installed helper/runtime and process lifetime | Availability-critical | Unavailability |
| Operation outcome/audit identity | Operational | Corruption |

Boundary B1: feature UI → local coordinator → fixed OS/helper operations. Crossing: connection ID/generation and inspect intent. Caller is internal app composition, not implicitly trusted input; validate shape, exact method, selected connection and local origin. No app-level token makes this an OS sandbox. Boundary B2: trusted Wing transport → Agent. Crossing: credential, explicit resource identity, prompts/events. Agent authenticates; exact capability/grant gates and response identity checks remain independent. Boundary B3: coordinator → OS secure store/process/dialog and existing Link management. Crossing: private credential retrieval and narrow operation identity; OS user/secure-store policy plus independent Link credential/approval authenticate their respective legs. No credential exchange between planes.

STRIDE coverage by boundary (S spoofing, T tampering, R repudiation, I disclosure, D denial, E elevation):

| Scenario / boundary | Entry, precondition, path and impact | Decision / owner / control and failing observable |
| --- | --- | --- |
| S/T/E B1: substituted connection or executable | Stale/hostile UI arguments reach host selection/process dispatch; caller input selects another origin/executable; credential or host authority crosses scope. | Mitigate — native integration owner. Fixed bundled helper and typed IDs, verify current generation and loopback origin. Test wrong-mode/origin/ID and substituted-helper cases: zero credentialed requests/process launches. |
| R/I B1: raw output/transcript diagnostics | Failed inspect or UI error carries sensitive helper output or chat preview into logs/notifications; private content disclosed and outcomes misleading. | Mitigate — client/security owners. Enum-only bounded projection, no request bodies or previews. Canary error tests inspect every output sink; leaked sentinel or unbounded payload fails. |
| D B1: repeated inspection/selection | UI races start excessive child processes or connection reads, exhaust resources and leave stale owners. | Mitigate — native integration owner. One active selection, bounded input/output/deadlines, cancellation fences. Test burst/oversize/hung child: bounded concurrency and no late state admission. |
| S/T/E B2: endpoint impersonation or wrong resource | Another loopback app occupies a port, wrong auth mode is assumed, or profile/session changes mid-request; write crosses identity boundary. | Mitigate — transport owner. Use reviewed canonical enrollment and exact auth, reject redirect/proxy substitution, explicit identities/generation checks. Test occupied port/wrong credential/other profile and delayed response: no resource adoption or secret forwarding. |
| R B2: lost prompt/approval acknowledgment | Network drops after server acceptance; automatic retry creates a second action and conceals original uncertainty. | Mitigate — channel owner. Reconcile authoritative state, exact request correlation, never implicit replay. Test accepted-but-lost receipt: one server action, uncertainty until readback. |
| I/D B2: oversized or malicious Agent payload | Authenticated server emits large/nonconforming content or unsafe renderer links; disclosure or resource exhaustion. | Mitigate — transport/presentation owners. Existing bounded decoders/rich-text policy, sanitized errors, backpressure/limits. Test size/schema/link cases: rejection without external fetch or UI freeze. |
| S/T/E B3: local path/process/secret-store confusion | Same-user process or untrusted file selection substitutes runtime/helper/secret material; overly broad native access enables unrelated Agent writes. | Mitigate — host/security owners. Fixed reviewed install identity, owner/containment checks, no raw file/config interface, narrow secure-store purpose. Test symlink/substitution/forbidden method: denied before access. Same-user malware remains residual risk, not solved by method typing. |
| R/I B3: secret handoff/audit leakage | Helper failure or OS prompt exposes credential bytes/path in argv/log/journal; user cannot distinguish save from restart. | Mitigate — host/security owners. Secret-safe approved channel only, allowlisted outcome audit and separate persistence/lifecycle receipts. Canary tests across argv/env/stdout/stderr/audit/preferences: zero secret bytes. Provider/env writes are eliminated from initial scope. |
| D B3: termination affects unrelated Agent | Cancellation or app quit kills an externally managed gateway or duplicate launcher; unrelated work unavailable. | Mitigate — host owner. No initial lifecycle operations; later exact owned child handle/service identity, bounded termination and reconciliation. Test unrelated running process survives cancel/quit, and owned orphan handling matches explicit policy. |

No STRIDE category is assumed unreachable just because calls are local. Initial arbitrary config/filesystem/shell entry points are **eliminated**, owned by the architecture reviewer; negative interface tests prove absence. Residual risks: broad Agent credential authority may exceed Wing's UI allowlist; compromised app/same-user malware is not contained; runtime auth, secure-storage availability and platform process ownership remain unverified. Independent security review and platform testing are required; no accepted residual-risk waiver is recorded here.

## Phased tests and release gates

| Phase | Scope and required evidence | Exit / forbidden inference |
| --- | --- | --- |
| 0: freeze contracts | Re-read goal/ADRs and installed unmodified Agent source/revision; inspect nearest tests/callers. Capture exact live capability/grants through an approved isolated target without provisioning here. Trace private connection acquisition before any new launch. | Operation allowlist approved, write lease granted. Source/parser evidence does not mean live support. |
| 1: coordinator unit/boundary | Linux first. DI fake W3 runner/store; fixed argv and no shell; unknown/nonlocal/stale IDs, secure-store failure, max output/deadline, cancel-before-start and late completion. Assert reads never call setup/config/restart or retrieve unrelated keys. | Focused Dart tests and analyze; existing Link inspection tests if changed. No services/install/provider changes. |
| 2: existing daily channel regression | Exercise current production W1 with deterministic Agent fixture: explicit profile/model, streamed turn/tool activity, exact approval/Stop, route leave/reopen, server-canonical terminal state, missing remembered session, delayed profile switch, lost receipt and no duplicate prompt. Pin model-only metadata as display without synthesizing a confirmed pair; keep the integrated restored-picker oracle intact. | Native deterministic workflow harness receipts. Fixture success is not live generation, restored-pair authority, native auth or full admin parity. Released harness ownership must be freshly checked before edits. |
| 3: isolated live Linux qualification | Approved disposable Agent installation/data homes and private auth acquisition; preserve owner's chosen provider/model, no copied personal credentials. Exercise actual Flutter desktop connect/generation/approval/Stop and exact stored-session restore, including a supported authorized provider/model read. Observe exact identities, client mutations, server turns and canonical history in redacted receipts. Test wrong auth, killed connection, occupied port, restart during uncertainty, secure-store lock. | Matching live/native receipts and independent review; model text alone cannot pass pair restoration. Exit/relaunch and leave-route recovery tested separately; no detached-run guarantee from socket behavior alone. Missing exact read keeps that criterion open. |
| 4: optional native transport | Only if required outcome cannot use A1 and safe A4 authorization exists. Test supported `serve` parser/install window, private auth acquisition, ticket expiry/single-use/wrong-audience, no secrets in URLs, negotiation shape, foreign/stale request denial, replay epoch/truncation and runtime/durable identity. Independently exercise warm reattach, cold lazy/watch, deferred hydration/build/next-turn, default cold and eager resume with absent/fresh/stale crash markers and still-live owner cases. Count server turns/canonical history as well as client submits; distinguish Agent continuation from Wing replay. | Separate production adapter/auth approval and explicit resolution of automatic continuation before resume is admitted as reconciliation. No personal/global config or marker edits, guessed opt-out field, stop-after-start workaround or upstream patch. W2 fixtures and zero client sends alone prove neither passive recovery nor zero generation; `unsupportedAuthorization` remains. |
| 5: full local admin slices | One operation family per scope: profile lifecycle, existing-provider semantics, Persona/memory, schedules/tools/MCP, Project handles, OS integrations. Trace unmodified upstream operation plus concurrent external edits, expected revisions, partial failures, separate save/reload, revocation and approval replay. Remove adapter when equivalent authoritative API exists. | Per-operation release window/removal trigger and adversarial/live evidence. Missing atomicity/safe secret contract blocks only that operation. |
| 6: platform/remote qualification | macOS/Windows owned-process identity, secure storage, packaging and menus independently; physical speech/microphone evidence separately. Remote operation subset has explicit negative tests proving local-only methods are unreachable. | Named-platform acceptance only; Linux/Xvfb or cross-build evidence does not qualify other OSes. |

Implementation handoff stack: Flutter/Dart existing `HermesChannel`/Riverpod and W3 runner, platform-native plugins only when needed; Go existing `internal/app`/`hostexec` when a separately approved Link operation changes. Read nearest sibling implementation/tests first. No Agent migrations or new domain database. Future signed packages/service activation require the current runtime ADR's digest/signature/health/rollback evidence, not this document.

## Decision points and missing evidence

The recommended initial scope does not require another owner interview: it follows the accepted daily-workflow direction and reuses existing direct API. Two choices become material only when implementation reaches them:

1. **First-use private enrollment target:** an already enrolled isolated local Agent is sufficient to qualify daily use. If none exists, an owner-approved disposable target and supported private credential provisioning are needed. No personal-runtime extraction or “easier” provider substitution.
2. **Native transport necessity:** decide whether a concrete Desktop outcome actually requires native RPC after direct API qualification. If yes, resolve A3/A4 authentication incompatibility and the installed contract window before approving launch/adapter work. Do not choose a helper/service topology to conceal this missing auth evidence.

Other known unknowns are engineering gates, not owner policy gaps: installed release compatibility, model persistence semantics on native RPC, durable recovery across process death, secure-storage availability, service/process ownership and signed distribution on each OS. Full admin authorization is intentionally later and operation-specific.

## Verification receipt

Performed read-only Git revision/status checks, source/parser and nearest-test inspection, and SHA-256 source pinning. Verified local source-link targets and scoped whitespace after writing this report. No code, upstream, tooling, runtime, credentials, services, acceptance cards or other documentation was modified by this lane. No install, authentication provisioning, live endpoint call or test execution was performed; every phase above remains future qualification work.
