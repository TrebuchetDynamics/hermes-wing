# Hermes Desktop capability parity

This ledger defines “full port” against one reproducible Hermes Desktop baseline. It tracks user capabilities rather than React components, Electron IPC methods, or screenshot similarity. The source-backed inventory of the newer sibling checkout is [Hermes Desktop complete feature study](hermes-desktop-feature-study.md); it records deltas without moving this frozen baseline.

## Frozen baseline

- Repository: `fathah/hermes-desktop`
- Version: `0.7.3`
- Commit: `d31e52e85449b6effcfd4d037b7517541c8fadf2`
- Frozen: 2026-07-13
- Source checkout: sibling `hermes-desktop/` repository

Changes after this commit enter the delta ledger below. They do not alter an in-flight slice's acceptance criteria. This is the stable planning baseline, not the final retirement target.

## Status vocabulary

| Status | Meaning |
| --- | --- |
| `unassessed` | Baseline behavior and contracts still need extraction. |
| `existing` | Hermes Wing already provides the user outcome, but parity evidence may remain. |
| `contract-blocked` | Hermes Agent lacks the authoritative interface required by ADR 0012. |
| `host-blocked` | A supported desktop host adapter is missing. |
| `implementing` | One bounded vertical slice is active. |
| `validated` | Contract, Flutter behavior, platform gating, accessibility, and relevant E2E evidence pass. |
| `platform-excluded` | The capability is unsafe or impossible on this platform and is hidden with an approved equivalent path. |

A domain is complete only when every baseline capability is `validated` on supported desktop targets and either `validated` or `platform-excluded` on mobile/web. Visual resemblance alone is not parity.

## Electron retirement gate

Hermes Desktop remains supported while Hermes Wing ships incremental Android and desktop milestones. Retirement requires every planning-baseline capability and accepted pre-cutoff delta to be validated, replaced by an equivalent outcome, explicitly deprecated, or assigned an approved platform exclusion on Linux, Windows, and macOS. Android or Linux reference-platform success alone does not open the gate; iOS and web completion do not block it. Retirement is also blocked until ADR 0039's canonical Linux, Windows, and macOS packages pass install/update/uninstall receipts, every legacy Electron package format has a documented canonical migration path, every desktop platform passes authenticated managed-runtime install/rollback receipts, keyboard-only and supported-screen-reader receipts, all twelve baseline locales have reviewed critical-flow coverage with Arabic and Hebrew RTL receipts, portable and encrypted recovery backup/restore receipts pass, every spatial capability has an accessible equivalent, every platform that stored legacy local wallets passes local-only one-wallet-at-a-time manual and encrypted-file recovery export receipts, and the explicit client-state import passes clean, detected, confirmed, cancelled, retried, and malformed-source scenarios.

## Retirement cutoff policy

A final Hermes Desktop version and commit will be named before retirement. Every user-capability change from the planning baseline through that cutoff enters the delta ledger and receives a disposition. After the cutoff, Electron receives only critical security, data-loss, migration, and compatibility fixes; no new product capabilities land there. A critical fix that changes user-visible behavior is mirrored in Hermes Wing or added to the ledger without reopening completed unrelated slices.

## Initial capability inventory

| Domain | Baseline surfaces | Initial Hermes Wing state |
| --- | --- | --- |
| Bootstrap | splash, welcome, external runtime discovery/install, verification, first-run setup | host-blocked |
| Connections | local, remote HTTP, and explicitly trusted SSH tunnel transports | canonical remote origin existing; desktop local/SSH host-blocked |
| Chat and runs | multi-run chat, streaming, reasoning, tools, approvals, clarify, queue, stop/retry/undo | core run flow, queue/retry, and bounded run token usage implemented; multi-run switching and advanced metadata remain partial |
| Sessions and projects | history, search, rename/delete, pinning, resource-handle context folders and attachments | partial existing |
| Profiles and persona | create/clone/switch/delete, metadata, avatar, soul, profile-scoped state | contract-blocked |
| Providers and models | credentials, discovery, saved models, active model, task overrides | gateway-scoped runtime model inventory available read-only; administration contract-blocked where scoped APIs are absent |
| Skills and Discover | installed/community skills, install/remove, MCP discovery | contract-blocked |
| Tools and MCP | toolsets, MCP lifecycle/configuration/testing | read-only skill/toolset inventory implemented; mutations and MCP contract-blocked |
| Memory | entries, profile, capacity, providers | contract-blocked |
| Schedules | list/create/pause/resume/run/delete and delivery targets; no existing-job edit UI | gateway-scoped read-only inventory implemented; mutations contract-blocked |
| Gateway | lifecycle, health, logs, and messaging-platform configuration | gateway-scoped read-only health implemented; lifecycle/logs/configuration contract-blocked |
| Kanban | boards, tasks, transitions, dispatch, details, Claw3D mirror | contract-blocked |
| Office | shared agent interactions; accessible 2D Android presentation; 3D desktop environment, One Chat, and representatives | unassessed |
| Account and wallets | Hermes account, agent sync, backend-managed wallets and balances; guarded export for legacy local wallets | contract-blocked |
| Settings and data | appearance, language, privacy, network, server-owned backup/restore, diagnostics | partial existing; backup contract-blocked |
| Desktop shell | menus, shortcuts, window behavior, updater, GPU recovery, context menu | host-blocked |
| Security and accessibility | secret storage, scoped authorization, one-time enrollment, transport policy, CSP-equivalent controls, keyboard and screen-reader behavior | secure storage and Android ingress existing; authorization/enrollment contract-blocked |

Each domain must be expanded into baseline scenarios, required Hermes contracts, platform availability, Flutter owner, and executable acceptance evidence before implementation.

### Office acceptance split

Office shares one interaction model for agent status, selection, CEO assignment, buildings, representatives, One Chat, and account actions. Android Office is complete when those mobile-safe outcomes pass through a TalkBack-operable 2D presentation. Desktop Office additionally requires the frozen baseline’s interactive 3D scene, spatial navigation, GPU fallback behavior, and a fully operable non-spatial semantic path on Linux, Windows, and macOS; that path cannot be read-only or omit actions available in 3D.

## Rollout order

1. **Android reference client:** implement and validate every remote/mobile-safe contract and user outcome first, using the connected Android device for integration receipts.
2. **Linux reference desktop:** add local installation, process, SSH, filesystem, updater, window, and other host capabilities, then close complete baseline parity.
3. **Windows and macOS desktops:** implement the stable host-adapter contracts and package them.
4. **iOS and web clients:** complete remote-safe parity and approved platform exclusions.

Android-first does not move Hermes domain authority into the client. Capabilities that require local host control remain contract-blocked or platform-excluded on Android rather than receiving mobile-specific replicas of Hermes state.

Android uses Chat, Discover, Office, and Tasks as primary destinations plus More for administrative destinations. The same route tree later maps to desktop navigation; routes land only with working slices, not placeholders.

## Program roadmap

Every milestone is a vertical slice: authoritative Hermes contract, capability and scope declaration, typed Flutter client behavior, adaptive UI, focused tests, Android build, and device receipt. Every new app-owned string is externalized in Flutter localization resources when introduced; English-first milestones do not hard-code temporary UI copy. Every slice includes semantic labels and states, logical focus, visible focus, 200% text scaling, AA contrast, reduced motion, non-color cues, and manual assistive-technology coverage for its critical flow. Every connected slice tests stale labeling, reconnect refresh, and rejection of offline mutation replay. Administrative domains additionally require atomic mutation, domain-revision, stale-write, secret non-reveal, apply-disposition, explicit reload/drain, active-work preservation, and post-apply verification evidence. Domains with live state additionally require profile-scoped SSE event IDs, reconnect/deduplication tests, GET reconciliation, idle-timeout behavior, and stale-event rejection. Android run slices also prove background detachment without implicit stop or replay, process-death recovery, and foreground authoritative reconciliation. A later milestone starts only after its dependencies are validated.

| Milestone | Outcome | Depends on |
| --- | --- | --- |
| 0. Remote trust foundation | Scoped operator tokens, capability requirements, one-time Android enrollment, rotation and revocation. | existing endpoint security |
| 1. Profiles and Agents | Profile list/active state, create/clone/rename/delete, persona, `/agents`, and Chat profile switching. | milestone 0 |
| 2. Providers and Models | Provider presence/set/remove, discovery, saved models, active model, and auxiliary task overrides without secret reveal. | milestone 1 |
| 3. Discover, Skills, Tools, and MCP | Community discovery, install/remove, toolset toggles, and MCP lifecycle through scoped contracts. | milestones 1–2 |
| 4. Memory | Entries, profile memory, capacity, and provider configuration. | milestones 1–2 |
| 5. Tasks | Schedules first, then Kanban boards/tasks/transitions/dispatch under `/tasks`. | milestones 1–3 |
| 6. Gateway | Lifecycle, health, logs, messaging-platform configuration, and explicit reload/drain/restart orchestration. | milestones 0 and 2 |
| 7. Chat and Sessions completion | Multi-run switching, queue, clarify, reasoning, Android detached-run reconciliation and optional redacted notifications, resource-handle uploads and context folders, projects, web preview, shortcuts, and history parity. | milestones 1–3 |
| 8. Office, Account, and Wallets | Shared Office interactions with an accessible 2D Android renderer, hardened native Hermes One device authorization, account sync, and backend-managed wallet outcomes. | milestones 1–7 |
| 9. Settings and Data | Appearance, all baseline locales and RTL, privacy, explicit minimal analytics, network, diagnostics, portable profile backup/restore, and non-revealing secret administration. | milestones 0–8 |
| 10. Linux desktop host parity | Interactive 3D Office plus authenticated version-pinned runtime discovery/install/update/rollback, local process lifecycle, explicitly trusted SSH tunnelling, picker-originated filesystem/worktree grants, signed APT/RPM distribution and verified updates, window integration, and packaging. | stable shared contracts |
| 11. Remaining platforms | Port the desktop Office and host adapters to Windows/macOS, ship signed MSIX and notarized DMG packages with verified updates, deliver and validate the final Electron guarded legacy-wallet export, satisfy the Electron retirement gate, then complete iOS/web remote parity and approved exclusions. | milestones 0–10 |

The executable plan for milestones 0–1 is `docs/superpowers/plans/2026-07-13-android-auth-profiles.md`. Later milestones receive separate implementation plans after their baseline scenarios and server contracts are expanded in this ledger.

### Milestone status

| Milestone | Status | Evidence present | Remaining before `validated` |
| --- | --- | --- | --- |
| 0. Remote trust foundation | `implementing` | Hermes Agent contracts (scope vocabulary, hashed revocable credential store, request scope-authorization, one-time origin-bound enrollment) with 256 passing auth-suite tests; Flutter scope-gated capability parsing and the Android pairing/enrollment flow (branch `feat/android-auth-profiles`, 433 tests, debug APK builds). All server work is on the unmerged branch `feat/scoped-operator-auth`. | On-device enrollment receipt (revoke-then-401); hermes-agent branch merge. |
| 1. Profiles and Agents | `implementing` | Scoped profile CRUD + soul contracts (server) and typed Flutter profile model, client-local selection, `/agents` screen, Chat switcher, l10n seam (client). | On-device profile-administration receipt and the TalkBack/200%-scale accessibility receipt for the More → Agents → select → Chat flow. |
| 2. Providers and Models | `implementing` | Scoped provider-credential (presence/set/remove/validate, write-only, never revealed) and model (catalog/refresh/assignment with `If-Match`) contracts on the unmerged `feat/scoped-operator-auth` branch, covered by unit suites plus an end-to-end contract receipt (`tests/gateway/test_milestone2_receipt.py`) proving the sentinel-key-never-escapes invariant; Flutter `/providers` screen, write-only credential sheet, model picker, and exact-route read-only `/v1/models` fallback land with matching widget tests. | On-device provider/model administration receipt (secret non-reveal verified on a real device); hermes-agent branch merge. |
| 3. Discover, Skills, Tools, and MCP | `implementing` | `/tools` shows gateway-scoped, advertised installed skills with bounded searchable description/category metadata and enabled toolsets with unsupported/empty/failure separation and a physical-device inventory receipt. | Discover, install/remove, toolset mutation, and MCP require authoritative scoped contracts. |
| 5. Tasks | `implementing` | `/tasks` shows gateway- and profile-scoped `GET /api/jobs` inventory only with exact declared and granted `tasks:read`, with refresh and no mutation controls; focused tests cover exact route-and-scope gating, refresh, gateway switching, error redaction, and 200% scale. The current physical gateway receipt proves fail-closed behavior because it does not advertise jobs. | Live inventory receipt on a compatible gateway; exact revision-safe schedule mutation and complete Kanban contracts. |
| 6. Gateway | `implementing` | `/gateway` shows gateway-selected bounded `GET /health/detailed` status only with an exact declared and granted `gateway:read` scope; startup and refresh fail closed before network I/O otherwise. It preserves unsupported/failure separation, error redaction, and no mutation controls. | Lifecycle, logs, messaging-platform configuration, revision-safe apply, drain, reload, and restart contracts. |
| 7. Chat and Sessions completion | `implementing` | Streaming, bounded reasoning events, tools, approvals, stop, retry, duplicate-safe dropped-run reconciliation, queued follow-ups, attachment-safe transcripts, session lifecycle/search/export, TTS, and bounded server-reported input/output/total token usage are implemented with focused tests and Android receipts. | Multi-run switching, clarify parity, detached-run process recovery, resource handles/context folders, runtime server-command discovery beyond the implemented client-owned slash commands, cost/cache/rate-limit/context metadata, and remaining history parity. |

Milestones 0–2 stay `implementing` — not `validated` — until the Android device
and accessibility receipts exist, per this ledger's status vocabulary.

Linux host parity requires two installation receipts: a clean machine verifies and runs an exact installer artifact from signed Hermes Agent release metadata and reaches a verified capability document, while an existing supported installation is adopted without replacing its Hermes home, profiles, configuration, credentials, or runtime layout. Existing Hermes Desktop client state is offered through a previewable, confirmed, idempotent allowlist import; credentials, private paths, wallet data, and Hermes domain state are excluded. Cancellation and import failure leave both applications' state unchanged, receipts contain no private values, and fresh scoped enrollment and Hermes One sign-in are required. Hermes Wing packages must contain neither Python nor a Hermes Agent payload. The application release matrix tests clean install, signed upgrade, wrong-channel rejection, tampered artifact and metadata rejection, interrupted-update recovery, active-work deferral, and a signed higher-version rollback fix. The managed-runtime matrix separately tests signed manifest and artifact verification, per-user install, native elevation cancellation, mutable-reference rejection, active-work drain, side-by-side activation, failed-health rollback, retained Hermes state, and explicit old-runtime cleanup. Privacy receipts prove zero analytics requests or identifiers before opt-in, rejection of non-allowlisted properties, no user-content fields, and immediate transmission stop plus identifier deletion on opt-out. Backup receipts cover portable exclusions, encrypted-recovery passphrase handling, opaque-handle expiry, malformed and oversized archives, traversal and decompression limits, compatibility rejection, preview cancellation, active-work drain, successful restore verification, injected apply failure, and rollback to the prior revisions. SSH receipts cover explicit first trust, known-key reconnect, changed-key rejection and deliberate rotation, injection attempts, loopback-only forwarding, private-path redaction, and no mutation of user-global trust files. Hermes One receipts cover allowed browser origins, complete-URI device authorization without clipboard or hostname leakage, polling/expiry/cancellation/suspension, client-global secure credentials, refresh/revocation/account switching, and independent Hermes Agent operation; web PKCE remains separately gated. Legacy-wallet exit receipts inventory every profile without exposing phrases, verify address derivation, manual timeout/focus protection, encrypted-file round trip and failure cleanup, blocked clipboard/QR/bulk/remote paths, and deletion as a separate action. Filesystem receipts cover native-picker origin, read/write separation, session expiry, remembered access, revocation, profile/principal isolation, sensitive-root rejection, symlink/reparse races, worktree containment, remote registration denial, and path redaction. Canonical package receipts cover signed AAB/APK, APT/RPM, MSIX, and notarized DMG outputs; upgrades preserve client identity and Hermes state, uninstall leaves the external runtime and home intact, package scripts make no network calls, and AppImage/Snap/portable/tar users receive a tested migration path. Equivalent domain and host receipts are required on Windows and macOS before Electron retirement.

## Delta ledger

Intake occurs before each new parity-slice plan and at the retirement-cutoff review. Allowed dispositions are `planned`, `validated`, `equivalent replacement`, `deprecated`, and `platform-excluded`; each non-validated disposition requires recorded rationale and operator migration impact.

| Desktop commit/version | Capability change | Disposition |
| --- | --- | --- |
| `8da8d212` / 0.7.3 | Remote Dashboard OAuth flow and transport selection. | pending intake |
| `8da8d212` / 0.7.3 | Custom-provider management and provider/model-list improvements. | pending intake |
| `8da8d212` / 0.7.3 | Current reachable feature inventory and source/README contradictions captured in the complete feature study. | planned |
