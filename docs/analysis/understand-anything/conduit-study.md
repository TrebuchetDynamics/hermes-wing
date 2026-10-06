# Hermes Conduit: read-only Understand Anything study

## Scope and evidence

- **Reference:** `kaishi00/hermes-conduit`, checkout `67a2e8de6b39d2086f59149e0f5fd8b1d44c1fe6`; analyzed at `2026-10-04T00:08:26Z` (UTC, obtained from `date -u`). This identifies the inspected checkout, not the latest release or a qualified deployment.
- **Method:** read the Understand Anything file-analyzer, architecture-analyzer and tour-builder instructions and `packages/core/src/schema.ts` in `tools/understand-anything/understand-anything-plugin/`. Run the bundled structural extractor, inspect source and nearest tests, curate semantic dependencies, compute graph topology, then build a prerequisite-ordered tour. The extractor analyzed 44 of 45 selected files with no unreadable files; `Conduit/Info.plist` had no parser result and was read manually. Input/output lived in anonymous memory descriptors, not upstream files. Swift structure was extracted successfully; framework imports are not evidence of per-file dependencies in Swift's shared module.
- **Artifact:** [conduit-graph.json](conduit-graph.json), a curated architecture map, not an exhaustive symbol graph: **48 nodes** (45 files plus three significant functions), **77 edges**, **six layers**, **nine tour steps**. IDs use `conduit:` and file paths are relative to the Wing root. Dependencies are explicit source-level usage, not invented Swift file imports. `tested_by` means inspected test coverage, never a passing run.
- **Read-only boundary:** no upstream edits, installs, hooks, simulator builds, test execution, plugin installation, login, service startup or live endpoints were used. No upstream `AGENTS.md` was found. Wing's `CONTEXT.md`, `CONTRIBUTING.md`, living API/state, runtime/delivery and security/privacy ADRs, `SECURITY.md` and threat model govern the comparison.
- **Evidence labels:** **Claim** = README/document assertion; **Implemented** = source plus available fixtures; **Unverified** = not exercised here, including Apple hardware, live Agent compatibility, provider billing, APNs delivery, relay/plugin enforcement and release signing.

## Executive findings

1. **Conduit is a native iOS dashboard client, not an Agent backend or host manager.** Its core path is authenticated Hermes dashboard REST plus JSON-RPC over `/api/ws`, not a direct connection to the underlying gateway socket. The dashboard is the app-facing server boundary. The app contains no implementation of that server or the external notifier/relay.
2. **The best reusable work is identity-safe mobile reconciliation.** Durable stored conversation IDs are separated from transient runtime aliases; contradictory resume claims are rejected before adopting transcript, composer, viewport or selected-session state. Partial catalogs do not authorize navigation to another conversation.
3. **The local state boundary is mixed, not uniformly server-authoritative.** Offline transcripts are deliberately display-only, but persisted per-session YOLO choices override conflicting server snapshots and are automatically reasserted with `config.set` after resume. The latter must not be copied into Wing.
4. **“No relay / no extra processes” is a baseline-chat claim, not the complete feature topology.** Push adds a notifier plugin, APNs and a relay; live voice adds provider/plugin transports. Gemini directly opens a plugin-issued WSS destination; GPT exchanges WebRTC SDP through the host; Grok uses a dashboard plugin relay socket.
5. **Conduit's security mechanisms are useful examples, not Wing contracts.** Dashboard-scoped cookie stores, staged authentication commits, PKCE and stale-result fencing are worth studying. Private-network HTTP heuristics, page-script secret injection, relay decision writes, raw filesystem paths and automatic approval-mode replay do not satisfy Wing Link's boundaries.

## What Conduit actually does

[README](../../../hermes-conduit/README.md) advertises streaming Markdown chat, attachments, tool/reasoning/delegation visibility, steering/interruption, session management, bot mode, multiple dashboards, profile/model controls, capabilities, scheduled jobs, voice, CarPlay, OAuth, notifications and Face ID. These are product claims, not a compatibility guarantee for Wing's installed Agent.

**Implemented baseline:** [ConduitApp.swift](../../../hermes-conduit/Conduit/ConduitApp.swift):62–83 uses SwiftUI and a shared runtime `AppState`; [ChatView.swift](../../../hermes-conduit/Conduit/Views/ChatView.swift):12–29 composes the chat with a separate viewport engine. [HermesClient.swift](../../../hermes-conduit/Conduit/Services/HermesClient.swift):1284–1365 handles correlated JSON-RPC, cancellation, deadlines and default profile scope; its typed methods include `prompt.submit`, `session.resume`, `session.steer`, `session.redirect`, cancellation, approval/clarification responses, attachments, commands and context accounting. [StreamEventParser.swift](../../../hermes-conduit/Conduit/Services/StreamEventParser.swift) translates stream events with per-event required-field checks.

**Administration is still server-owned, but broad:** `HermesClient.swift`:1386–1549 calls profile/bot and Project RPCs; `AppState.swift`:19618–19797 reads skills/toolsets and scheduled-job routes and issues corresponding operations. `AppState.swift`:19967–19994 performs model selection followed by a full configuration read/modify/PUT. These show client calls, not server-side authorization, revisions, atomicity or compatibility with any particular Agent release. A UI and method existing here cannot establish advertised support in Wing.

**Bots and workspace chats are distinct surfaces over server conversations.** [SessionReference.swift](../../../hermes-conduit/Conduit/Services/SessionReference.swift):15–98 persists conversation kind and profile scope, plus unverified provenance for legacy selections. Bot metadata and avatar operations live in `Conduit/Services/BotManagement.swift` and the client RPC methods. This is not a second bot worker implementation.

## Authority and state ownership

| Owner | Implemented responsibility | Boundary / limitation |
| --- | --- | --- |
| External Hermes dashboard / Agent | Runtime sessions, durable transcript, profiles, Projects, commands, tools, approvals and configuration through server routes | Client source cannot prove server persistence, authorization or lifecycle semantics. “Same database” in README refers to the external service, not device database access. |
| `AppState` | Connection/profile/session selection, stream reconciliation, local pending UI, voice orchestration and cache coordination | MainActor isolation alone does not prevent stale async results; explicit client/profile/generation fences do. This is a large orchestration object, not a desirable Wing architecture template. |
| Local presentation stores | Saved connection identities, drafts/viewport/preferences and bounded read-only transcript copies | Presentation state must not become domain or permission authority. The YOLO store is a concrete exception. |
| Optional external plugins/relay/providers | Kanban lifecycle, push routing/decisions, live voice token/SDP/relay endpoints | Their server source is outside this checkout. Comments about credentials staying host-side are contracts the client expects, not proof of server enforcement. |

### Reconciliation is the strongest pattern

- [ConversationIdentity.swift](../../../hermes-conduit/Conduit/Services/ConversationIdentity.swift):3–43 distinguishes durable selection from runtime routing and positively confirmed aliases. `ConversationIdentityGate.admit`:83–153 rejects durable contradictions and IDs owned by another catalog row while accommodating request-scoped legacy runtime rebinds.
- `AppState.swift`:8759–8795 launches compact resume and persisted history hydration concurrently; :8883–8940 validates the response identity before adopting conversation-owned state. Discovery catalog replacement is independent from adopting a selected conversation.
- [ChatResumePolicy.swift](../../../hermes-conduit/Conduit/Services/ChatResumePolicy.swift):24–110 preserves the user's saved selection when a cold catalog is incomplete and excludes known bot-owned conversations. [PersistedTranscriptWindow.swift](../../../hermes-conduit/Conduit/Services/PersistedTranscriptWindow.swift):7–80 uses tail-anchored pages of 120 rows and requires the server's `order=latest` echo before treating pagination as the tail contract. Actual rows, not just a declared count, drive offset bookkeeping.
- [OfflineChatCache.swift](../../../hermes-conduit/Conduit/Services/OfflineChatCache.swift):5–43 states and implements a read-only copy excluding approval, clarification and partial rows. Its protected atomic file write and backup exclusion are at :192–202 and :332. Cached copies never populate the authoritative `AppState.messages`/`sessions` arrays by contract. Device file protection is not end-to-end encryption or a live privacy audit.

**Evidence:** `ConduitTests/ConversationIdentityTests.swift` includes `testGateRejectsExplicitDurableContradiction` and `testGateRejectsRuntimeIDPositivelyOwnedByAnotherCatalogConversation`; `AppStateForegroundLifecycleTests.swift` includes `testFastSecondSendKeepsStoredConversationWhenRefreshedCatalogDropsRuntimeAlias`. `OfflineChatCacheTests.swift::testRecordKeepsNewestPageOfDisplayRowsOnly` checks actionable-row exclusion. `AppStateDecisionFenceTests.swift` checks replacement-client, newer-generation and same-message-ID/different-request races. These were inspected, not run.

### Important counterexample: automatic approval-mode replay

[SessionYoloStore.swift](../../../hermes-conduit/Conduit/Services/SessionYoloStore.swift):15–30 stores explicit per-session overrides in `UserDefaults`, keyed by profile/session; :136–143 clears them on server change rather than using origin in the key. `AppState.swift::applyEffectiveYolo`:10416–10443 treats an override as authoritative unless profile-wide approvals are already disabled. `reassertSessionYolo`:16211–16260 automatically resends a stored override when the server's reported session value disagrees, and keeps the local indicator after replay failure. `HermesClient.swift`:2130–2137 writes `config.set` with `key=yolo`.

There are real race defenses and tests (`ConduitTests/SessionYoloPersistenceTests.swift`, `SessionYoloStoreTests.swift`, `YoloProfileSwitchBookkeepingTests.swift`), but this is **client-retained security/domain intent and reconnect mutation replay**. Wing's server-wins rule prohibits silently replaying it. Preserve the draft or explain the disagreement; request fresh intent through an exactly authorized Agent operation.

## Transport and authentication

### Baseline connection sequence

1. Validate/normalize the user-entered dashboard base URL, preserving a reverse-proxy path prefix.
2. Discover `/api/auth/providers`. `NativeAuthClient.swift`:98–165 separates recognizable provider JSON, interactive sign-in redirection and unrecognized content; capability/provider evidence chooses the login flow rather than treating all empty responses alike.
3. Password flow: `/auth/password-login` returns transaction-local cookies, then POST `/api/auth/ws-ticket` mints a ticket (`NativeAuthClient.swift`:300–384). Automatic cookie sending is disabled. `NativeAuthConnection.commitCookies(dashboardID:)`:81–84 publishes the accepted transaction and clears stale OAuth credentials only when activated.
4. Native OAuth flow: [NativeOAuth.swift](../../../hermes-conduit/Conduit/Services/NativeOAuth.swift) implements browser authorization, PKCE, state/callback validation, a bounded loopback HTTP callback, Keychain tokens and refresh. Bearer REST also mints `/api/auth/ws-ticket` (:270–310).
5. Open the dashboard WebSocket: `HermesClient.connect`:791–858 builds `/api/ws?ticket=…`, applies configured proxy headers and waits for the actual handshake before accepting RPC traffic. Superseded sockets/tasks are retired and stale frames are dropped.
6. The [DashboardTicketBridge](../../../hermes-conduit/Conduit/Services/DashboardTicketBridge.swift) provides authenticated REST and reconnect ticket minting. Cookie mode uses a dashboard-owned `WKWebView` and credentialed fetch; native OAuth uses native bearer REST. `requestJSON`:610–760 uses response limits and independent Swift deadlines, not only JavaScript abort timers. Response messages require the expected origin and main frame (:993–1008).

The “gateway” terminology in comments is inconsistent: the concrete app transport is the dashboard endpoint, which fronts the runtime. This dashboard forwarding topology is **not** a precedent for routing Wing's Agent data plane through Wing Link.

### Secure storage and isolation

- `DashboardTicketBridge.swift`:19–25 defines per-dashboard WebKit stores and native cookie jars; `ConduitTests/DashboardSessionIsolationTests.swift` tests sibling hosts with parent-domain cookies, distinct jars and stale restore failures.
- [SavedDashboardRegistry.swift](../../../hermes-conduit/Conduit/Services/SavedDashboardRegistry.swift) keeps registry and credential records in Keychain, keyed by dashboard UUID; switching servers does not intentionally reuse their authentication sessions.
- `AppState.swift` contains `KeychainHelper` near the end of the file. Different record classes use `WhenUnlockedThisDeviceOnly` or `AfterFirstUnlockThisDeviceOnly` accessibility. [BiometricAuth.swift](../../../hermes-conduit/Conduit/Services/BiometricAuth.swift):17–29 allows device-passcode recovery. Do not claim every secret requires an active Face ID challenge or is inaccessible while the phone is locked.
- `NativeAuthClient.swift::SecureRedirectDelegate`:647–700 refuses cross-origin redirects; password redirect cookies remain scoped to that transaction. Native OAuth and auth tests use deterministic URLProtocol fixtures; they do not validate a deployed reverse proxy or identity provider.

### Trust-boundary cautions

[ConnectionURLPolicy.swift](../../../hermes-conduit/Conduit/Services/ConnectionURLPolicy.swift):17–26 and :172–214 permit HTTPS or HTTP on loopback, RFC1918 addresses, `.ts.net` names and the Tailscale CGNAT range. Tests reject malformed CGNAT-like names and out-of-range octets. **A hostname suffix/private address does not prove an active encrypted tunnel, trusted LAN, authenticated service or pinned identity.** `Info.plist` declares ATS exceptions, including a CIDR-shaped key; its presence and a plist assertion do not qualify Apple's actual handling of that exception on a physical device.

[CloudflareAccess.swift](../../../hermes-conduit/Conduit/Services/CloudflareAccess.swift):41–54 omits service-token headers on cleartext and :73–139 injects them into same-origin WebKit fetch/XHR. [CustomHeaders.swift](../../../hermes-conduit/Conduit/Services/CustomHeaders.swift):52–107 validates names/values, rejects reserved framing headers and binds values to secure origins; :174–201 preserves already-set auth and generates similar page injection. Origin scoping is valuable, but these secrets are deliberately embedded in page JavaScript. Wing should not import that mechanism or arbitrary proxy-header configuration into Wing Link. This study does not establish an exploitable leak; it identifies a larger page/server trust surface than a native typed client.

README correctly notes that system-browser OAuth authorization cannot receive native service-token headers; a service-token-only challenge on that route requires deployment changes, not an insecure embedded OAuth fallback. Keep that distinction between authentication mode, reachability and credential rejection.

## Integrations and external deployment boundaries

| Integration | Client implementation | Actual transport / external dependency | Qualification status |
| --- | --- | --- | --- |
| Kanban | `Conduit/Services/KanbanService.swift`, `KanbanEventStream.swift`, Kanban views/models | `/api/plugins/kanban` REST and ticketed `/api/plugins/kanban/events`; boards/tasks/orchestration are plugin-owned | Typed client implemented; server plugin behavior not verified here. |
| Classic voice | `Conduit/Voice/HermesVoiceGateway.swift`, `VoiceConversationController.swift`, Apple audio/speech adapters | `/api/audio/transcribe`, `/api/audio/speak`, ticketed `/api/audio/speak-stream`, or on-device recognition/playback | Client code/fixtures exist; exact installed Agent audio routes, AEC and physical speech are unverified. |
| GPT Live | `Conduit/Voice/GPTLive/GPTLiveClient.swift`, `GPTLivePeer.swift` | `/api/plugins/conduit_push/gpt-live/status` and `/session` exchange SDP; WebRTC media/data channel leaves the baseline REST/WS topology | Client insists on `auth=subscription` and WebRTC SDP; host token custody and billing remain outside this checkout. |
| Gemini Live | `GeminiLiveTokenClient.swift`, `GeminiLiveSession.swift`, `GeminiLiveToolBridge.swift` under `Conduit/Voice/GeminiLive/` | Plugin mints ephemeral token; phone opens returned WSS URL with `access_token`; plugin search/memory/personality/job bridges add routes | Client accepts WSS scheme but the token parser does not pin a provider hostname (:335–352). Expected Google destination is a plugin contract, not independently enforced host allowlisting here. |
| Grok Live | `Conduit/Voice/GrokLive/GrokLiveClient.swift`, `GrokLiveSession.swift` | Ticketed `/api/plugins/conduit_push/grok-live/socket` relays provider events through the Hermes host | Host keeps xAI credentials according to client comments; plugin source/behavior not audited. |
| Voice jobs | `Conduit/Voice/VoiceBackgroundJobs.swift` | Ordinary Hermes sessions started/tracked/cancelled by the client; explicit whole-utterance/leading-phrase command matching | Does not make Conduit a worker runtime; fixture behavior is not detached-run qualification. |
| Push notifications | `Conduit/Services/PushNotificationService.swift`, `ConduitApp.swift` | APNs plus external notifier and configurable relay; shared relay default in source | Registration, pairing, routing and decision writes implemented; delivery, expiry enforcement and server authorization unverified. |
| CarPlay / shortcuts / wake | `Conduit/CarPlay/CarPlayVoiceCoordinator.swift`, `Conduit/Intents/StartVoiceConversationIntent.swift`, `Conduit/Voice/Wake/` | Apple platform APIs and the same shared `AppState`/voice owner | Source and deterministic tests, not vehicle, entitlement, microphone or background endurance evidence. |

### Event recovery worth studying

`KanbanEventStream.swift` uses a board snapshot watermark, fresh ticket per connection, monotonically advancing cursor, generation retirement, heartbeat deadlines, reconnect backoff and batched invalidation. `ConduitTests/KanbanV3DTests.swift` includes `testReconnectMintsAFreshTicketAndNeverReuses`, `testMalformedOrMissingWatermarkMeansNoSocket`, `testCursorNeverMovesBackwards` and `testBoardSwitchSubscribesFromItsOwnWatermark`. Copy the identity/cursor discipline only when the authoritative Agent contract actually advertises those semantics; do not invent a cursor-based Wing task database.

### Push is also a decision path

`PushNotificationService.swift`:864–899 binds pairing requests to dashboard identity; routing tests fail closed for unknown/malformed dashboards and ambiguous unscoped pushes. The relay is not merely a wake signal: :650–652 and :699–724 POST clarification answers to `/v1/decisions/{requestId}/respond`, expecting the gateway/plugin to poll the relay. 404, 409 and 410 distinguish absent, locked and released decisions. Do not silently add this as Wing's approval/input data path. Agent decisions remain direct authenticated Agent traffic, not management or third-party relay mutations.

### Claims versus full implementation

- README's “no relay service, no extra processes” and “all communication directly to your Hermes instance” need feature scope. They describe ordinary dashboard chat but do not describe push/plugin/provider voice traffic. Live voice can transmit microphone audio, history, briefing and tool context beyond the Agent host; plugin-mediated credentials do not mean local-only content.
- README advertises “same capabilities as the desktop client.” This study finds substantial corresponding client surfaces, not complete release/platform/capability parity or a server support matrix.
- “No analytics / telemetry / ads” is an advertised statement. This targeted source study is not a dependency-wide privacy audit or network capture and does not certify it.
- API paths and provider/model strings in this checkout are evidence of this client's contracts only. They must not be copied as assumed Agent 0.20 or Wing capabilities, and cannot justify modifying Agent.

## Build, release and test evidence

[project.yml](../../../hermes-conduit/project.yml) declares Swift 5.9, iOS 17 minimum, native app/unit/UI targets, manual signing metadata and the exact `stasel/WebRTC` 153.0.0 binary dependency. XcodeGen generates the Xcode project. No Android/web/desktop host implementation is supplied by this package definition, and it is not a host service installer.

The current [CI workflow](../../../hermes-conduit/.github/workflows/ci.yml), `scripts/hosted-suite.json` and `.github/workflows/nightly.yml` describe Linux planning/static checks, macOS build/unit shards and UI smoke, with nightly timing/performance repeats and full UI selection. The legacy smoke manifest comments and some release prose describe earlier gate shapes; use current workflow/planner code rather than treating all docs as simultaneously current. [RELEASE_WORKFLOW.md](../../../hermes-conduit/docs/RELEASE_WORKFLOW.md):45–70 separately requires a release-mode exhaustive Mac gate for the exact candidate SHA. Declared gate policy is not a retrieved passing CI result or signed-store artifact.

| Risk / behavior | Inspected test evidence | What it establishes, not a run result |
| --- | --- | --- |
| Socket lifecycle | `ConduitTests/HermesClientTests.swift`: `testRPCGuardRejectsBeforeHandshake`, `testSupersededReceiveLoopDoesNotClobberNewConnection`, `testSupersededLoopDropsStaleFrame` | Fake sockets explicitly model late completions and replaced transport. |
| Password auth | `ConduitTests/NativeAuthClientTests.swift`: `testPasswordLoginCarriesReturnedSessionCookieIntoTicketRequest`, `testTicketRequestDoesNotFallBackToUnrelatedSharedCookie` | Transaction-local cookie routing and no shared-cookie fallback. |
| OAuth | `ConduitTests/NativeOAuthTests.swift`: `testPKCEChallengeMatchesRFC7636Vector`, `testCallbackRequiresExactPathMatchingStateAndCode` | Deterministic cryptographic vector and callback checks; not live OAuth interoperability. |
| Origin/header policy | `ConduitTests/SecurityBoundaryTests.swift`, `CloudflareAccessTests.swift`, `CustomHeadersTests.swift` | Allowed transport/host shapes, secure-only proxy values and header validation. No proof a VPN is active. |
| Dashboard isolation | `ConduitTests/DashboardSessionIsolationTests.swift`, `CrossProfilePresentationCacheTests.swift` | Distinct dashboard cookie stores and scoped presentation fixtures. |
| Identity / foreground | `ConduitTests/ConversationIdentityTests.swift`, `SessionIdentityContractTests.swift`, `AppStateForegroundLifecycleTests.swift` | Durable/runtime distinctions and partial-catalog recovery. |
| Decision races | `ConduitTests/AppStateDecisionFenceTests.swift` | Older requests/generations cannot settle replacement cards; authoritative refresh retires stale restored cards. |
| Kanban | `ConduitTests/KanbanV3DTests.swift`; REST/model tests in `KanbanTests.swift`, `KanbanV2Tests.swift`, other V3 families | Scripted plugin REST/event contracts; not the external worker lifecycle in production. |
| Live voice | `ConduitTests/GPTLiveVoiceTests.swift`, `GeminiLiveVoiceTests.swift`, `GrokLiveVoiceTests.swift` | Protocol/status/SDP/tool/audio fixtures and fake peers/sockets, not provider billing or acoustics. |
| Voice suspension / CarPlay | `ConduitTests/VoiceBackgroundSuspensionTests.swift`, `CarPlayTransportRecoveryTests.swift`, `CarPlayVoiceTests.swift` | Release local runtime, preserve identity, fence late work and reconnect when CarPlay is the active surface. No physical vehicle qualification. |
| Notifications | `ConduitTests/NotificationDashboardOwnershipTests.swift` | Dashboard routing ownership and ambiguous legacy-payload denial; not APNs or relay security. |
| Setup UI | `ConduitUITests/ConnectionSetupUITests.swift`, `ConnectionSetupTestConnectionUITests.swift`, `ConnectionRepairUITests.swift` | XCTest UI fixtures exist; no simulator execution in this study. |

No Conduit test suite was run: this environment has no `xcodebuild`, and the reference is read-only. No historical timing prose, fixture, schema pass or compilation substitutes for live runtime evidence.

## Recommendations for Wing

Wing's binding references are [CONTEXT.md](../../../CONTEXT.md), [API and state](../../adr/api-and-state.md), [runtime and delivery](../../adr/runtime-and-delivery.md) and [security/privacy](../../adr/security-and-privacy.md). These recommendations are patterns to evaluate, not permission to add endpoints or advertise new product support.

### Useful patterns, with explicit adaptation

1. **Capture full identity before every await.** Use canonical Agent origin, explicit profile/resource identity, durable conversation/run identity and transport generation. Reject contradictory resume claims before publishing into composer/transcript/viewport state; preserve current user intent when a catalog is incomplete. Adapt into existing `HermesChannel`/Riverpod seams, not a parallel AppState.
2. **Treat discovery and adoption separately.** A refreshed inventory may remain useful even when the selected-resource response is rejected. A request completing does not authorize changing today's selected conversation.
3. **Use pure boundary parsers and deterministic race fixtures.** Test malformed payloads, foreign identities, superseded client/generation, missing fields and late responses before asserting UI success. Keep exact-capability and authorization gates in addition to parser success.
4. **Separate compact live state from bounded durable history.** Tail hydration, real-row pagination accounting and stable viewport identity are valuable for long conversations, but only use Agent-advertised contracts. Legacy read fallback must not become mutation retries.
5. **Keep offline copies presentation-only.** Exclude actionable decision cards and streaming partials; scope caches by canonical origin/profile/resource. Never rehydrate domain state or queue mutations from a read-only cache. Apply Wing's existing privacy/retention controls.
6. **Stage setup probes without committing side effects.** `ConnectionSetupTest` and `NativeAuthConnection` show a typed partial outcome and explicit promotion/commit. Test reachability, recognized server and authentication independently; preserving an old good connection is better than overwriting it during a failed repair.
7. **One runtime owner, many adaptive surfaces.** CarPlay's presentation/lifecycle bridge does not create a second voice/domain owner. Wing should keep shared domain behavior and accessible alternatives across platform-native views, not copy Apple's scenes or entitlements.
8. **Qualify exactly what ran.** Exact-SHA release gates, test inventory validation, bounded deadlines and infrastructure-failure classification are useful CI ideas. Adopt only scoped tooling; no need to reproduce the upstream's entire host/simulator orchestration.

### Approaches NOT to copy

| Conduit approach | Why it conflicts / required Wing alternative |
| --- | --- |
| Dashboard fronts RPC and REST as one app-facing connection | Wing's Agent data traffic remains direct authenticated Agent traffic. Wing Link is separate authenticated host management, not a dashboard proxy, shell bridge or second backend. Keep independent credentials. |
| Locally persisted YOLO override becomes authoritative and replays on resume | Violates server-wins and no silent mutation replay, especially for approval bypass. Require fresh authorized intent; never let a stale preference claim the server accepted it. |
| `workspaceDirectoryEntries` calls `/api/fs/list?path=…`, returns file names/paths; `writeProjectIdea` posts path/content to `/api/fs/write-text` (`AppState.swift`:19515–19555) | Wing Link must expose only bounded child-folder listings under locally approved, revocable opaque handles with canonical containment and symlink checks. No arbitrary absolute host paths, file metadata/content or generic file writes. Projects remain Agent-owned. |
| Generic configuration RPC values and full config read/modify/PUT | A client helper or server route is not authorization or authoritative concurrency. Wing needs exact advertised operations/grants/resource identity and revisions; no caller-selected command/config-key compatibility API. Saving and reload/inference/restart remain separate outcomes. |
| Custom proxy headers / page JavaScript secret injection | Adds a page/server trust surface and broad caller-selected configuration. Do not turn Wing Link into arbitrary proxy configuration, bearer forwarding or WebView authentication plumbing. Credentials stay secure and plane-specific. |
| Private-address or `.ts.net` HTTP admission as sufficient transport policy | Network location is not authorization. Wing Link remains TLS 1.3 plus native reviewed SPKI pin off loopback; the separate Agent HTTP exception needs explicit user confirmation and the Wing policy, not Conduit's heuristics. |
| Relay-mediated clarification answers | Do not route Agent approvals/input through Wing Link or a new relay decision authority. Use exact Agent-owned direct decision operations and reconcile authoritative state. |
| Plugin token/SDP endpoints as implicit voice support | Independently inspect unmodified Agent capability, authorization and provider privacy boundaries. Keep absent routes unavailable; never patch/install injected Agent internals to obtain parity. A provider-issued URL/token does not authorize a caller-selected upstream proxy. |
| Single very large AppState and string/protocol compatibility assumptions | Reuse existing typed clients, models, channel state and providers. Extract the small identity/policy invariant, not the object layout, fallback catalog or synthetic capability claims. |
| Orb, sound or speech as the only control affordance | Wing requires fully operable accessible equivalents independent of 3D/canvas, sound, color, motion, speech and pointer precision. Hardware/platform success must be separately evidenced. |

No arbitrary shell implementation is inferred from Conduit's `slash.exec`/`command.dispatch` calls: they are server command RPCs. The warning is that their breadth is **not** permission to expose a generic Wing Link executor.

## Guided tour and graph reading

The JSON tour contains the authoritative node memberships; read in this order:

1. **Product and package:** README, XcodeGen, manifest and entry point; identify claims versus built targets.
2. **Authentication before data:** password transactions, PKCE, cookie/bearer bridge and isolation tests.
3. **Transport and origin boundaries:** JSON-RPC, parser, URL policy and secure proxy header scope.
4. **Conversation identity and safe adoption:** broad AppState through the small identity gate and typed restoration policies.
5. **Large histories and offline presentation:** compact runtime versus tail pages and non-authoritative cache.
6. **Decisions and the replay exception:** race tests, then explicitly study the YOLO conflict rather than assuming all cache state is safe.
7. **Plugin state and event recovery:** typed Kanban REST, watermarks and board-scoped stream tests.
8. **Voice is more than one transport:** classic, WebRTC, provider WSS, host relay, ordinary-session jobs and shared CarPlay surface.
9. **Push, deployment and evidence limits:** notification relay writes, routing ownership, current CI and unverified runtime.

Programmatic topology informed this ordering: AppState has the largest curated fan-out (22); URL policy and the ticket bridge have the largest fan-in (8 and 7). These are counts in this curated map, not full-repository metrics. Every represented node belongs to exactly one layer. External services are discussed explicitly but not turned into fabricated source nodes.

## Validation and remaining uncertainty

- Bundled `extract-structure.mjs`: exit 0, `scriptCompleted=true`, 44 selected files analyzed, one parser skip manually read, no unreadable files.
- Actual bundled `KnowledgeGraphSchema.safeParse`: success with no issues; no alias/default repair or dangling-edge dropping was needed.
- Final artifact checks cover unique IDs, valid paths/line ranges, endpoint and tour references, exact layer coverage, graph counts, local Markdown links and whitespace.
- Reference status was clean before analysis; final readback verifies no upstream modifications. The dirty Wing worktree is unrelated and was preserved; only this study and graph were written.
- **Unverified:** iOS build/test passes, live dashboard/Agent version compatibility, reverse proxy/Cloudflare/OIDC deployment, provider routing/billing, physical audio/CarPlay, APNs/relay operation, external plugin authorization, signed distribution and exhaustive privacy/security properties. Obtain isolated target-specific evidence before elevating any of these into Wing support claims.
