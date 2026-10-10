# Hermes Desktop: read-only Understand Anything study

> Reference correction: [official Desktop authority](../../quality/official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


## Scope and evidence

This is an outcome-oriented source study of the permanent `withdrawn source citation` reference checkout, not a Wing implementation plan or a claim that Desktop contracts are supported by every installed Hermes Agent. Desktop identifies itself as version **0.7.7** in `withdrawn source citation`; its analyzed commit is **withdrawn reference revision**. The command-derived UTC analysis timestamp is recorded in [desktop-graph.json](desktop-graph.json).

All code citations below are **relative to the Wing repository root**. Line ranges refer to this checkout. Nearest tests were inspected, **not executed**. No application, gateway, installer, provider inference, native window, microphone, SSH target, OAuth flow or packaged platform was exercised. In particular, test names containing “today”, comments about upstream support, and historical plans do not establish current runtime capability.

Only this report and the adjacent graph were written. The Desktop checkout remains read-only; its five pre-existing `.claude` deletions are unrelated and were not repaired. The surrounding Wing worktree was already substantially dirty and is not part of this study's change scope.

### Method and limitations

Applied the Understand Anything sequence: inspect repository guidance/manifests, select source and nearest-test evidence, trace behavioral/data relationships, partition responsibilities, construct a prerequisite-first tour, and mechanically review graph integrity. Methodology references: `tools/understand-anything/understand-anything-plugin/agents/{project-scanner,file-analyzer,architecture-analyzer,tour-builder,graph-reviewer,assemble-reviewer}.md`. The authoritative shape is `tools/understand-anything/understand-anything-plugin/packages/core/src/schema.ts`, especially `GraphNodeSchema`, `GraphEdgeSchema`, `LayerSchema`, `TourStepSchema` and `ProjectMetaSchema`.

This is a **curated file-level study**, not a completed automated full-repository UA pipeline. The bundled scanner cannot start because `packages/core/dist/index.js` is absent. No build or install was performed to fix that read-only tooling blocker; no scanner/import-map output is fabricated. Relationships are manually traced behavioral dependencies, transforms and test links, not a claimed deterministic import map. `lat` is not installed, so Desktop's requested `lat search`, `lat expand` and `lat check` could not run. Relevant `lat.md/` files were read directly; they remain design descriptions, not execution evidence. No functionality or upstream documentation was changed.

The graph has **44 grounded source/test nodes, 53 edges, six non-overlapping layers and nine tour stops**. Node IDs are explicitly namespaced `desktop:` as requested; layer IDs use `desktop:layer:`. That deliberate namespace overrides the generic agent prompt's type-prefix convention, while remaining valid under the actual schema's string IDs. Every node has a real Wing-root-relative path, summary, tags and complexity. Complexity is a qualitative curation label, not a measured complexity score. Edge weights describe relationship strength, not runtime confidence.

## Architecture in one view

```text
React Chat -> useDashboardChatTransport -> timed WebSocket RPC -> Agent dashboard
           -> useChatActions -> preload IPC -> main/hermes.ts
                                             -> local TUI gateway RPC
                                             -> /v1/runs + SSE
                                             -> /v1/chat/completions + SSE
                                             -> local CLI fallback
Canonical refresh -> scoped IPC -> local Agent SQLite OR remote dashboard HTTP
                  -> sessionHistory merge -> stable transcript rendering
Host setup -> preload IPC -> local CLI / Agent YAML / environment / Desktop stores
Native shell -> Electron window, menu, dialogs, webviews, OS integration
```

Desktop is a privileged host-local Electron application with remote/cloud and SSH modes. It is **not** Wing's two-plane architecture. Its main process can launch Agent processes, open Agent SQLite, modify Agent YAML/environment files and retain Desktop-owned domain overlays. Some useful outcomes rely on those privileges; adopting the outcomes does not authorize adopting the privileges.

Entry evidence: `withdrawn source citation`, `withdrawn source citation`, `withdrawn source citation`, `withdrawn source citation`. Closest isolation tests: `withdrawn source citation`, `withdrawn source citation`.

## 1. Actual chat transports

### Dashboard path: default-enabled, but connection-dependent

`withdrawn source citation` enables Dashboard unless the environment kill switch or explicit Legacy preference disables it, after connection mode has loaded. Local, direct Remote and SSH are eligible; eligibility is not proof of reachability. Auto may return control to legacy transport when Dashboard is genuinely unavailable. Once a dashboard was reachable but its chat WebSocket failed, the hook surfaces the failure rather than sending `/v1` requests into a dashboard-only tunnel (`:1877-1895`). A sticky unavailability latch for remote/SSH is cleared when connection identity or revision changes.

The RPC client in `withdrawn source citation` correlates request IDs, normalizes several notification envelopes, bounds handshake/request waits and rejects pending calls on close. The transport acquires a fresh WebSocket URL just before connecting; generation checks discard a client opened for an obsolete connection/profile. Runtime session creation/resumption precedes model selection, attachment synchronization and `prompt.submit` (`useDashboardChatTransport.ts:1917-1961`).

`withdrawn source citation` is a Desktop-specific compatibility mechanism: a random one-use loopback path with accept/connect deadlines bridges a selected upstream WebSocket. It is not a model for Wing Link routing. Neither this relay nor an SSH tunnel establishes operation authorization by itself.

Nearest evidence: `withdrawn source citation`, `withdrawn source citation`, `withdrawn source citation`, `withdrawn source citation`. The hook tests cover fresh URLs, obsolete clients, connection-edit reprobes, OAuth-required errors and frame-coalesced deltas. These use deterministic clients/mocks, not real host qualification.

### Legacy main-process path: several transports, not one API

The selection chain is in `withdrawn source citation`:

1. Local TUI gateway RPC can be preferred when eligible: not remote, no attachments, no `/approve` or `/deny` command, and no session model override. The main-process `TuiGatewayClient` manages a local dashboard WebSocket and its lifecycle (`hermes.ts:547-949`); it is distinct from the renderer Dashboard hook.
2. Otherwise use advertised Runs support for eligible requests without attachments or approval slash commands: `POST /v1/runs`, then `GET /v1/runs/{runId}/events`.
3. Use `/v1/chat/completions` for ordinary OpenAI-shaped streaming requests where Runs is ineligible/unavailable.
4. Local availability/recovery may launch or recover the gateway and ultimately fall back to a `hermes chat` subprocess. Remote mode does not use the local CLI fallback. Certain local cross-provider conversation overrides force CLI for text-only turns.

The completions builder (`hermes.ts:1441-1542`) includes text history, current attachments, optional context-folder instructions, selected model and reasoning effort. Resume identity goes in `session_id`; authenticated requests also send `X-Hermes-Session-Id`, using a UUID-based identity for new chats rather than first-message fingerprint collisions. Do not adopt the unauthenticated fallback assumption as a Wing security policy.

Runs has start/event timeouts and may stop then fall back to completions before content. Start errors/missing IDs can also cause fallback. Local recovery tracks visible output to avoid replay after partial output, and approval interaction prevents replay. **No visible output is not proof the Agent never accepted or executed the prompt.** This fallback policy is not a safe template for Wing's ambiguous submissions or detached runs. CLI builds `chat -q <message> -Q --source desktop` and optional `--resume`, then parses stdout and kills the subprocess on abort; it cannot preserve the same multimodal semantics as the supported gateway path (`hermes.ts:2650-2694`, `:2970-2974`). Never copy transcript-in-argv into Wing.

Nearest tests: `withdrawn source citation`, `withdrawn source citation`, `withdrawn source citation`, `withdrawn source citation`, `withdrawn source citation`, `withdrawn source citation`, `withdrawn source citation`. Capability predicates are in `withdrawn source citation`; tests of those predicates do not validate an arbitrary installed server's contract.

## 2. Stream reconciliation and cancellation

### Preserve continuity while reconciling authoritative history

The Dashboard reducer `withdrawn source citation` handles message, reasoning/thinking, tool and interactive lifecycle events. It reconciles final text against streamed previews rather than blindly appending final output. The hook keeps mutable stream state separate from React commits: high-frequency deltas coalesce per animation frame, while completion/tool boundaries/interactive requests flush immediately (`useDashboardChatTransport.ts:1176-1245`). Non-local assistant deltas are treated differently through `renderAssistantDeltas: connectionMode === "local"`; do not assume identical live rendering on every mode.

Legacy IPC subscriptions filter by renderer run ID, while canonical reads additionally carry immutable connection/profile and check the accepted visible session after the await (`withdrawn source citation`). Periodic refresh is opportunistic; final refresh runs on completion (`:185-239`). A delayed read for a cleared/old chat must not repopulate the new view.

`withdrawn source citation` is the strongest reusable UX lesson:

- canonical rows determine the normal order, but matching streamed bubbles retain their rendering IDs and receive canonical metadata;
- repeated equal content is matched in FIFO order, not globally collapsed;
- canonical tool rows replace synthetic live previews only in matching quantities;
- split assistant rows must not coexist with a duplicate concatenated preview;
- failed local turns retain their placement; an explicitly failed active turn bypasses normal refresh reconciliation;
- lossy reasoning deduplication is scoped within a turn;
- clarify/approval cards remain near their streamed predecessor rather than jumping to the transcript end.

Comments saying tools “never stream” are historical explanations, not universal current behavior: the current Dashboard reducer and live-tool helpers do render synthetic tool events. Copy the invariants, not that historical premise.

Nearest tests: `withdrawn source citation` directly imports the real merge helpers and covers repeated prompts, split answers, stale attachment rows, synthetic tool counts, failures, reasoning and card anchoring. `withdrawn source citation` and its renderer-local counterpart cover the reducer. `withdrawn source citation` covers stale session refresh; hook transport tests cover coalescing and completion flushing.

### Stop is transport-specific; local teardown is not server confirmation

| Transport | Current source behavior | Qualification gap / Wing lesson |
| --- | --- | --- |
| Dashboard | `session.interrupt` for the captured runtime session; expires pending interactive cards; closes client if interruption RPC rejects (`useDashboardChatTransport.ts:2103-2114`). | Sending an interrupt is not proof of terminal cancellation. Read back authoritative run/session status. |
| TUI gateway | Clears pending resolvers and uses gateway session interruption through its live client. | Preserve originating client/profile/session; do not route a stale card to the current global connection. |
| Runs | Aborts local requests and posts `/v1/runs/{runId}/stop` with original connection auth (`hermes.ts:1836-1851`, `:2145-2153`). | Stop helper ignores request errors and does not inspect a terminal response; do not claim confirmed stop from this alone. |
| Completions SSE | Aborts the HTTP request's controller (`hermes.ts:1814-1818`). | Closing a stream need not stop detached server work. |
| CLI | Signals the spawned child (`hermes.ts:2970-2974`). | Subprocess control is host-local, not remote Agent run control; no platform process-tree guarantee was established. |

Legacy abort routing is keyed by connection plus renderer run ID; no-ID legacy callers abort all handles (`withdrawn source citation`). This broad backward-compatible path must not become Wing's cancellation contract.

Wing already exposes the distinction through `HermesChannel.cancelActiveTurn`, `stopActiveTurn` and captured `HermesTurnInterruptionTarget`/`stopTurn` in `lib/core/hermes/channel/hermes_channel.dart`. Current `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart` also retains uncertain ownership and confirms terminal status rather than treating a stop POST as sufficient. Evaluate regressions against `test/core/hermes/channel/hermes_api_channel_tests/{run_transport_tests,stop_outcome_tests,approval_stop_tests}.dart`; these are live worktree tests, not results run by this study.

## 3. Approvals and clarification: the hardest boundary

### Approvals: render identity is not authorization identity

Dashboard creates a local display ID separately from upstream `request_id`. Missing upstream identity causes interruption, not a guessed approval (`useDashboardChatTransport.ts:1178-1205`, `:1247-1259`). Only the first pending approval, for the current runtime session, with an offered choice and a connected client is answerable. `approval.respond` carries upstream request ID, originating session, choice and **`all: false`**; success requires **`resolved === 1`** (`:1988-2033`). Other resolution counts invalidate approvals and request interruption. A delivery exception leaves the same request retryable, rather than marking it approved.

The TUI path similarly registers opaque renderer IDs, forwards exact gateway IDs and validates one resolution (`hermes.ts:2327-2392`). IPC binds pending approval to the renderer owner and run (`hermes.ts:1234-1297`; `ipc/register.ts:1929-1945`). This is a local Electron ownership model, not a substitute for remote device scopes or Wing Link's payload-bound local management approval.

**Important negative finding:** this Desktop checkout deliberately refuses manual Runs approval. Its source states the targeted upstream Runs approval endpoint resolves FIFO rather than safely honoring request identity; on `approval.request` it stops and fails without approval POST or prompt replay (`hermes.ts:2009-2019`). That is evidence about this client decision, not fresh proof of every upstream release. Wing must independently trace installed Agent behavior and exact approval capability/request targeting, including stale request rejection; a capability label or echoed request field alone is insufficient. Do not blanket-disable or blanket-enable Wing solely on Desktop's comment.

`withdrawn source citation` renders only offered choices, disables queued/stale/resolved cards and uses a second explicit confirmation for “always”. Strongest tests: `withdrawn source citation` checks original connection, exact upstream IDs and no replay after approval even before rejected prompt acknowledgment; `withdrawn source citation` checks missing IDs, FIFO UI, ack/retry and completion/abort expiry; `withdrawn source citation` checks command text and confirmation.

Wing's seam is `lib/core/hermes/channel/approvals/hermes_approval_responder.dart`, with `test/core/hermes/channel/approvals/hermes_approval_responder_test.dart` and `test/core/hermes/client/hermes_api_approval_test.dart`. Preserve the separate planes: Agent tool approval is direct Agent domain traffic; Wing Link approval authorizes reviewed host management, not Agent commands.

### Clarify: preserve delivery acknowledgment and successive questions

`withdrawn source citation` supports choice buttons, free text and Skip (empty answer). It does not resolve when responder delivery fails. Dashboard binds pending request to runtime session/client, blocks concurrent answers, sends `clarify.respond {request_id, answer}`, and resolves only after `status === "ok"` (`useDashboardChatTransport.ts:1721-1776`). Composer fallback uses the same responder, not a new ordinary prompt. Matching expiry, disconnect, completion and connection change make cards unavailable. A late acknowledgment for question A must not erase question B.

The older main-process TUI clarify resolver is weaker: it clears pending identity before an asynchronous `clarify.respond` acknowledgment and can consider API fallback on delivery failure (`hermes.ts:2395-2430`). Do not treat the legacy path and the stronger Dashboard path as equivalent. Adopt transport-correct card/composer routing and explicit acknowledgment, not speculative replay.

Nearest tests: `withdrawn source citation` and `withdrawn source citation` cover failed/rejected delivery, expiry, concurrent card/composer submissions, next-question preservation, socket-close races and request replay. `withdrawn source citation` describes those intents; source and tests are stronger evidence.

## 4. Session recovery and conversation model selection

### Identity and recovery

Desktop separates renderer run ID, ephemeral Dashboard runtime session ID and stored Agent session ID. Durable location is connection/profile/session, described by `withdrawn source citation` and implemented across `withdrawn source citation`, `Chat.tsx`, `ipc/register.ts` and `src/main/session-location-store.ts`. One global SSH tunnel remains a constraint: inactive SSH reads must not silently retarget it. Closest tests: `withdrawn source citation`, `withdrawn source citation`, `withdrawn source citation`.

Dashboard recovery first attempts `session.resume` for the stored ID. Only a specific missing-session error falls through to `session.create`, which may seed visible transcript messages and context-folder `cwd` (`useDashboardChatTransport.ts:255-305`). Prompt recovery may resume/re-submit once for the same missing-session condition; an approval nonce blocks it after any approval request (`:201-252`, `:1950-1961`). Failed provider/model switching can force a clean runtime for a later attempt. This is not a general idempotent reconnect protocol.

Canonical local history comes from Agent `state.db` through `withdrawn source citation` and `src/main/sessions.ts:679-721`; remote history comes from `src/main/remote-sessions.ts` dashboard `/api/...` routes. Desktop stores continuation prefixes/local errors in its own tables in the Agent database (`src/main/session-continuation-store.ts`) and uses local overlays even for non-local modes. `src/main/session-cache.ts` synchronizes summaries and writes titles to Agent SQLite. These storage mechanisms are **non-portable** under Wing's Agent ownership boundary. Source tests exist in `withdrawn source citation,session-cache-sync,sessions-history-items,remote-sessions}.test.ts`; no live persistence/reconnect result is claimed here.

Wing should restore exact authoritative session/run state after reconnect, retain drafts and presentation identity, and never fabricate a replacement domain session by seeding cached history. Existing seams: `lib/features/hermes_chat/gateways/hermes_gateway_directory.dart`, `lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart`; nearest Wing restoration tests: `test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart`, `test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart`. These are current dirty-worktree evidence, not qualification by this analysis.

### Models: learn the outcome, not the host-local mutation route

The in-chat picker is conversation-only (`withdrawn source citation`, `:926-942`). `src/renderer/src/screens/Chat/hooks/useModelConfig.ts:159-195` uses `persist: false` and increments its sequence counter so an in-flight default reload cannot overwrite the user's conversation selection. Persisted default selection writes, then reads back actual model configuration. The picker searches provider/model groups, promotes the selected model and links Providers; display branding does not discard raw routing identity.

For Dashboard, `ensureSelectedModel` reads `model.options`, resolves provider identity, sends a model slash command to the selected runtime and validates the live result; slash-worker failure has a specific reset/retry path (`useDashboardChatTransport.ts:1530-1705`). Legacy API generally carries a model string; remote cross-provider behavior is consequently narrower than the full local `{provider, model, baseUrl}` override. A checkmark is not proof that the backend switched successfully.

Desktop persists override provider/model/base URL in `desktop_session_model_overrides` within local Agent SQLite (`withdrawn source citation`). The UX distinction is useful; the table and client-owned endpoint-routing authority are not Wing implementation patterns.

Nearest tests: `withdrawn source citation`, `src/renderer/src/screens/Chat/hooks/useModelConfig.test.tsx`, `src/main/session-model-override-store.test.ts`, `tests/dashboard-chat-transport.test.ts`. Wing already has `lib/features/hermes_chat/widgets/session_model_picker_sheet.dart` and `HermesChannel.lockSessionModel`; use Agent-confirmed session selection and configured-provider catalog policy. Closest Wing tests: `test/features/hermes_chat/widgets/{session_model_picker_sheet_test,session_model_picker_search_test}.dart`, `test/core/hermes/channel/hermes_api_channel_tests/session_model_tests.dart`.

## 5. Profile/provider setup: host-local assumptions not to port

| Desktop implementation | Useful user outcome | Wing boundary |
| --- | --- | --- |
| `src/main/profiles.ts:176-268` reads profile folders/config/metadata, including incomplete folders. | Recognize an existing but unconfigured profile and guide repair rather than hiding it. | Read authoritative inventory via exact Agent operation or approved Wing Link profile adapter; no Flutter filesystem scan. |
| `profiles.ts:269-365` creates/deletes through bounded CLI; validates IDs and verifies deletion actually removed the directory; display name stored in local metadata. | Stable machine identity distinct from display name; report partial metadata failure and verify destructive effect. | Approved typed lifecycle only, explicit identity, fresh authorization/confirmation. Do not clone keys or create shadow metadata authority. |
| `profiles.ts:368-409` invokes global `profile use` and directly repairs `active_profile` even for remote-only selection. | Remember the chosen profile across relaunch. | Save client selection bound to host/profile; never modify global Agent active profile or invent the identity. |
| `screens/Setup/Setup.tsx:52-88` writes profile-bound credentials through `setEnv`, then provider/model through `setModelConfig`. | Profile-aware onboarding and clear missing-input feedback. | Sequential `.env`/YAML writes are not a safe remote transaction; use advertised secret-safe Agent API or reviewed transactional **new-profile** Wing Link setup. Existing-profile compatibility mutation remains blocked. |
| `src/main/config.ts:518-585`, `:1269` reads/replaces environment entries and rewrites Agent model YAML; public connection config is redacted. | Keep setup target consistent and reconcile saved values. | Provider secrets write-only, no generic config keys, no credential echo, revision checks where collisions are possible. Separate save from validation/inference and restart. |
| `src/main/providers-store.ts` retains `providers.json`, imports/mirrors Agent YAML and can derive environment keys, with best-effort failures. | Named custom providers appear coherently across UI and terminal. | Do not add a Wing-owned provider registry, shadow catalog or read-triggered mutations. Agent owns provider/model inventory and setup catalog visibility is not write permission. |

All Desktop source paths in this table carry prefix `withdrawn source citation`. Closest tests: `withdrawn source citation`, `tests/profile-validation.test.ts`, `src/renderer/src/screens/Setup/Setup.test.tsx`, `src/main/providers-store.test.ts`, `src/main/agent-config-providers.test.ts`, `tests/connection-config-security.test.ts`, `tests/set-model-config-base-url.test.ts`, `tests/config-model-block.test.ts`. Those tests prove intended local behavior, not safe remote transactions or secret lifecycle on Wing.

Profile modal refresh-after-mutation (`withdrawn source citation`) is a useful outcome. Persona/memory/wallet/sync panes in that modal are not proof that Wing has matching authoritative operations. OAuth host login, cloud account provisioning and SSH environment mutation are additional distinct trust paths, not API-key substitutes to expose generically. Relevant source: `withdrawn source citation,remote-oauth,ssh-env-update}.ts`; nearest tests: `withdrawn source citation,remote-oauth,ssh-env-update}.test.ts`.

For Wing policy use `docs/adr/api-and-state.md`, `docs/adr/runtime-and-delivery.md`, `docs/security/threat-model.md` and current `docs/product/routes.md`. Current profile setup's typed catalog read on Wing Link is the narrow `/v1/profiles/{id}/model-options` exception; Agent chat/session/run/tool/approval traffic remains direct. Do not upgrade the ADR's accepted existing-profile provider **design direction** into shipping support.

## 6. Native UX and security

Desktop's native outcomes worth reproducing are ordinary, operable ones: application menu accelerators for new chat/search, standard edit/zoom/window roles (`withdrawn source citation`), edit/bubble-selection and whole-chat copy context menus (`src/main/app/context-menu.ts`), adaptive native appearance/spellchecker IPC (`src/main/ipc/register.ts:2148-2197`), Escape-dismissable searchable picker, and explicit confirmations/error alerts on dangerous interactions. macOS hidden-inset chrome/vibrancy is platform-conditional source (`src/main/app/start.ts:158-194`), not proof of a qualified macOS artifact.

Isolation controls are concrete: Node integration off, context isolation and sandbox on, web security on, insecure content off; external opens go through a protocol helper; packaged top-level navigation is constrained; webview preload privileges are stripped and later navigation/redirects remain checked (`src/main/security.ts`, `src/main/app/start.ts`). The helper allows HTTPS for the designated preview and loopback HTTP with a permitted port range. This is **not** an exact host/path authorization policy: tests even describe the broader loopback range. Logs in this source can include URL/error details; do not copy those diagnostics into Wing's redacted pipeline.

Public connection shapes exclude the actual bearer while indicating presence (`src/main/config.ts:333-354`); main process owns credential-bearing requests. Redaction is not secure storage: the underlying Desktop registry contains sensitive connection data, and provider setup still writes Agent environment files. The broad preload surface includes config/env, host paths, media, terminal/editor and backup/import operations. An isolated renderer with a powerful IPC API is not a remotely safe management service.

Nearest tests are mixed evidence: `withdrawn source citation` combines static source assertions with helper behavior; `tests/preload-api-surface.test.ts` checks bridge/declaration consistency, **not authorization of every handler**; `tests/connection-config-security.test.ts` checks public redaction and credential use; `tests/askpass-security.test.ts` checks askpass boundaries. `tests/focus-outline.test.ts`, `src/renderer/src/screens/Chat/keyboard.test.ts` and picker/card component tests are useful accessibility leads, not a complete screen-reader, keyboard or reduced-motion audit. Installer/checksum tests and macOS signing source tests also do not qualify update rollback or signed distribution on a real platform.

Wing must use Flutter native/adaptive presentation, existing Riverpod providers and `HermesChannel` contracts. Preserve a full keyboard/semantic 2D path even where optional voice, previews or office visualization exist. Store Agent and Wing Link credentials separately in platform secure storage; enforce exact scopes, TLS/pinning, revocation, bounded redacted diagnostics and opaque directory grants. Do not add an Electron-like arbitrary command/config/database API to Wing Link.

## Strongest recommendations, ordered

1. **Treat identity and no-replay as product invariants.** Bind every asynchronous update and interactive response to the originating host/profile/session/run/request and current generation. Unknown submission outcome requires authoritative recovery or explicit user intent, not “try another transport”. Desktop's approval no-replay regressions are stronger than its general fallback assumptions.
2. **Audit Runs approval targeting independently.** Desktop intentionally rejects an unsafe request-targeting contract. Trace the unmodified installed Agent and nearest upstream tests, then verify Wing request identity, stale rejection and response acknowledgment. Never enable from a broad version/admin flag or a client-rendered ID.
3. **Make stop uncertainty visible.** Keep local stream teardown separate from confirmed server termination. Retain run ownership until status reconciliation; stale chat switches and late acceptance must not cancel another run or enable duplicate sends.
4. **Borrow transcript continuity, not its storage authority.** Stable rendering keys, repeated-turn FIFO matching, canonical tool replacement and inline-card anchoring are valuable. Do not write Agent SQLite, persist shadow transcript prefixes, create substitute sessions or seed cached history as silent reconnect recovery.
5. **Keep conversation model selection separate from defaults.** Adopt searchable current-first grouping and stale-load guards, but require Agent-confirmed session selection before showing success. Setup may show unconfigured providers without granting existing-profile mutation.
6. **Prefer acknowledgment-aware clarification.** Choice/free-text/skip and composer responses must share one originating responder, block duplicate sends, survive delivery failure and expire safely. Preserve question B when question A acknowledges late. Use the Dashboard test matrix, not the weaker legacy fire-and-forget resolver.
7. **Copy native user outcomes only.** Recreate editing, shortcuts, search, focus, alerts and confirmations using Flutter/platform seams. Reject global `profile use`, transcript-in-argv, `.env`/YAML edits, arbitrary host paths, provider mirror stores and generic IPC/CLI bridges.

## Graph tour and acceptance

Open [desktop-graph.json](desktop-graph.json) for exact node membership and edges. Guided reading order:

1. Window and privilege boundary.
2. Chat composition and identity.
3. Dashboard RPC and events.
4. Legacy transports and stopping.
5. Approval and clarification safety.
6. Canonical history and overlays.
7. Conversation model selection.
8. Profile and provider setup.
9. Native outcomes and evidence.

The graph's edges are a curated **reference study**, not Wing dependency relationships. Every source/test node appears in exactly one layer; tour stops refer only to existing nodes. The manually traced graph was checked against the current schema's field/type/enum constraints, file existence, uniqueness, edge references/weights, layer membership and contiguous tour orders. The actual Zod validator was not run because its dependency/build environment is absent. No graph normalization, default injection or dropped-node “repair” is relied on. Documentation whitespace and cited local path existence were checked separately. Runtime behavior remains unqualified on all Desktop platforms in this study.
