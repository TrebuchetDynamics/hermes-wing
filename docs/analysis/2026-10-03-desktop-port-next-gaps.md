# Desktop port: next bounded gaps and dependency boundaries

> Reference correction: [official Desktop authority](../quality/official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Source audit for the accepted Desktop 1:1 product-port priority. This report proposes work; it does not implement it, qualify a platform, accept a card, or expand management permissions.

## Evidence and scope

- Wing HEAD: `ca149a82189c8c9e5abd98b376bfeae1e43f6f3f`; the inspected worktree is extensively dirty, so HEAD is **not** a snapshot of the inspected Wing content.
- Desktop reference HEAD: `withdrawn reference revision`. Its pre-existing deleted `.claude` configuration/skill entries were preserved. No fetch, checkout, installation, hook configuration or upstream edits were performed.
- Agent reference HEAD: `158fd638da1629c8e62caf9ade1515d162def8ab`; clean at initial inspection. This pins the available clone, not the installed/connected runtime or upstream latest release.
- Read `CONTEXT.md`, `CONTRIBUTING.md`, all five living ADRs, security policy/threat model, route status and the first-wave plan. Its lane ownership explicitly reserves only this report for this audit [S1]. The shell collapse/expand implementation belongs to another lane and is deliberately not claimed or re-audited here.
- Desktop's guide and `lat.md/sidebar-navigation.md` were read as reference intent. `lat` is not installed on PATH; no tooling/key setup was attempted. Live source, rather than graph prose, backs the findings below.
- Evidence is inspected source and inspected test intent only. No product tests, browser/native journeys, network requests, runtime mutation or acceptance workflow were executed.

## Observed navigation and interaction differences

Desktop's shell orders **New Chat → Discover → Office → Kanban → Schedules**, places recent sessions in a separately scrolling sidebar section, and puts Providers/Gateway/Tools/Memory plus Settings and the profile switcher in the footer [S2, S3]. Profiles is reached through **Manage profiles**, not its pinned primary navigation [S2, S4].

Wing's destination presentation instead lists Chat, Office, Profiles, Persona, Providers, Tools, Schedules, Connections and Settings together [S5]. Its session rail is composed inside Chat only, when that pane has at least 900 logical pixels; New Session belongs to that rail/header rather than the global shell [S6, S7]. Thus implementing shell collapse alone does not establish navigation or recent-session parity.

Do not conceal this difference by inventing Discover, Memory or Kanban data. Their route status is planned/partial and their domain actions remain operation-gated [S8]. The existing working destinations can be regrouped separately from enabling missing features.

## Ranked implementation slices

Ranking favors source certainty, reuse of current seams and no management expansion. Larger navigation convergence remains important but follows independently testable local improvements.

| Rank | Bounded slice | Observed gap and source | Dependency / exit criterion |
| --- | --- | --- | --- |
| 1 | Exact **Copy session ID** row action | Desktop passes the selected row's stable ID to a dedicated menu callback [S9], with a focused test [S10]. Wing's row menu instead copies a labeled, redacted details summary; its ID field is preview-limited to 120 characters [S11]. Copy details is not the same outcome. | Local explicit clipboard write using the already-loaded row identity. No new Agent request or Wing Link API. Preserve Copy details separately; assert exact selected ID bytes and no title, source, transcript, URL or credential in the clipboard. Await clipboard success and handle failure without a false success notice. |
| 2 | Searchable, keyboard-first Chat profile picker | Desktop filters name/ID/model, groups running/stopped, floats active first, supports arrow/Enter/Escape navigation and a Manage profiles row [S12, S4]. Wing's Chat switcher is an unfiltered bottom-sheet list of loaded profiles [S13]. Profiles-screen search does not fill this Chat-picker gap. | Filter loaded `state.profiles`; reuse existing `_switchProfile`, never global profile activation. First slice: query/clear/no matches, active-first ordering, keyboard selection/escape and Manage profiles navigation. Add running/stopped grouping only where current metadata actually supports it. Filtering and dismissal issue zero requests; selection retains existing exact owner/confirmation fences. Global Ctrl/Command+P and footer placement are a later shell slice, not required to ship search. |
| 3 | Collapsible Pinned / Chats session sections | Desktop exposes semantic disclosure buttons, excludes hidden rows from tab order and separates Pinned from ordinary Chats [S14]. Wing already has pins and recency grouping, but wide and compact lists draw group headings as `Text` and unconditionally draw every row [S15]. | Local presentation state only. First add Pinned/Chats disclosure without Project or filesystem grouping. Collapse must remove hidden rows from keyboard/semantic traversal, preserve pins/selection, perform no Agent read/write, and reset appropriately on owner change. Decide explicitly whether date subgroups remain a documented temporary deviation; they are not Desktop's Chats grouping. |
| 4 | Recent-session shell composition and working-destination regrouping | Desktop's session area survives feature-view changes in Layout [S3]. Wing attaches it to Chat [S6], while its global destinations are flat [S5]. | After the first-wave shell lane releases ownership, compose the existing session presentation/actions in the desktop shell, not a new session store or second client. Start with currently supported destinations, current owner's loaded sessions, and New Chat using the existing action. Verify navigate-away/back, profile/host change, collapsed tab order, exact-session resume, large text and narrow-window recovery. Missing destinations remain explicitly unavailable; no new backend surface is required for the existing loaded-session portion. |

### Proposed immediately next slice

Implement rank 1, **Copy session ID**, as a small RED→GREEN regression before implementation. Candidate scope: the shared `_HermesSessionTile` menu in `lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart`, English ARB plus generated localization through the normal generator, and focused widget tests near `hermes_chat_gateway_switch_test.dart`. Both wide and compact lists already reuse that tile [S15], avoiding two handlers.

Acceptance should cover a non-active row while another session is active, exact opaque ID preservation, keyboard menu operation, clipboard failure and stale-owner menu invalidation. Explicit copy is consent to copy this identifier, not permission to copy credential-bearing connection details. Do not silently normalize or truncate an authoritative ID; malformed identity handling should follow the existing model contract. Preserve existing Copy details coverage [S16]. Follow with the rank-2 picker rather than provider-management expansion.

## Direct Agent versus Wing Link: what is actually required

The product ADR explicitly says Wing Link is not the organizing principle or prerequisite goal of the port; making existing dependencies optional is still separately scoped work [S17]. The code already has a direct connection path: `HermesApiChannel` constructs its Agent client, reads health/capabilities, lists sessions and loads history without a Wing Link client [S18]. That observation does **not** prove any particular deployed Agent supports the negotiated surface.

| Requirement | Classification | Source-backed conclusion |
| --- | --- | --- |
| Chat, session history, runs, approvals and advertised Agent administration | Agent authority; Wing Link is not inherently required | Direct plane remains direct. Each action requires the exact supported operation/grant/current identity, not a broad admin/version flag [S19]. None of ranks 1–3 needs management expansion. |
| Profile inventory and lifecycle through Wing Link | Current fallback/compatibility choice, not universal profile authority | Profiles chooses Wing Link when direct profile-read authority is unavailable; its source also gates native profile creation separately [S20]. Therefore “all Profiles needs Wing Link” overstates the implementation. For an Agent lacking those operations, current bounded compatibility remains necessary to offer them remotely; removing it must not simulate a native capability. |
| Setup provider/model catalog through Wing Link | Explicit current setup exception, not intrinsic model-catalog host authority | Wing Link resolves an existing profile credential, verifies the Agent catalog operation/scopes and returns bounded display fields [S21]. The ADR requires this current path [S22]. A future direct setup read may be simpler only with a qualified direct credential/profile/capability acquisition path and a separately reviewed change; merely copying Desktop catalog calls is not evidence. Chat's model-picker policy is separate. |
| Installation/adoption, service lifecycle and updates | Unavoidable host-side authority for these outcomes; Wing Link is the chosen implementation | A remote UI cannot safely perform host service/process work with local presentation code. A host authority is needed; it need not philosophically be named Wing Link, but Wing's current reviewed authority is Wing Link. Do not add a generic shell/SSH bridge or route Agent traffic through it [S23]. Ordinary direct chat need not perform setup or lifecycle work. |
| Directory grants and remote approved-folder browsing | Unavoidable host filesystem authorization for remote browsing; current Wing Link boundary is deliberate | A client must not assert host-path containment or locally approve a remote root. Current rules require opaque handles, host canonical revalidation, revocation and folders-only results [S24]. This is not a reason to block unrelated local UI slices. Desktop's path-based project grouping and move-menu calls must not be copied as authorization [S14, S9]. |
| Pairing, device grants, TLS pin review, revocation and host approvals | Current management trust plane, not an Agent credential substitute | These protect Wing Link's host powers. Keep credentials/grants independent; an already-authenticated direct Agent endpoint does not imply management authorization, and management pairing does not qualify every Agent operation [S25]. |
| Existing-profile provider/config writes, Project creation, schedule/MCP mutations | Missing/qualified domain contracts, not automatically host-management work | The current compatibility exception is narrow; existing-profile configuration and Project operations are blocked outside verified contracts [S23]. Provider expansion is a design checkpoint, not shipped permission [S26]. Moving these actions to Wing Link does not resolve missing transaction/concurrency/secret semantics. |

## Deferred parity and non-gaps

- Full Project grouping, Move to project and folder choice require Agent-owned Project identity/contracts plus approved host directory translation. Do not synthesize a `contextFolder` mapping from Desktop's private client store. Keep them out of the local disclosure slice [S14, S23, S24].
- Discover/Memory/Kanban enablement, installation/update parity, privileged configuration and SSH/file explorer behavior are not bounded presentation-only changes. Missing actions defer individually rather than blocking all navigation work [S8, S23].
- Wing already has session pinning, date grouping, search/source filters, model-picker search, local slash keyboard navigation and transcript export-related source. Do not re-propose them as wholly absent. This audit narrows to differences inspected above; it is not an exhaustive feature census or executed parity verdict.
- Do not reproduce Desktop's optimistic global `setActiveProfile` behavior from the picker. Borrow selection/search outcomes, preserving Wing's explicit identity and authoritative failure handling [S12, S19].

## Reference index

Paths are repository-relative; line ranges refer to inspected worktree content, not a guarantee against concurrent edits. Desktop calls describe client behavior, never an advertised connected-Agent contract.

- **S1** `docs/plans/2026-10-03-desktop-port-first-wave.md:13-35` — lane ownership and evidence limits.
- **S2** `withdrawn source citation` — view vocabulary, primary/footer destinations.
- **S3** `withdrawn source citation` — New Chat and global session area.
- **S4** `withdrawn source citation` — Manage profiles action.
- **S5** `lib/shared/widgets/app_shell_presentation.dart:11-20` — current destination list.
- **S6** `lib/features/hermes_chat/screens/state/hermes_chat_layout.dart:580-628` — Chat-local rail and existing action wiring.
- **S7** `lib/features/hermes_chat/screens/hermes_chat_screen.dart:1477-1512` — profile/session/new-session header controls.
- **S8** `docs/product/routes.md:5-21` — current route availability, not runtime acceptance.
- **S9** `withdrawn source citation` — ID copy versus Project menu.
- **S10** `withdrawn source citation` — inspected callback regression.
- **S11** `lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart:1594-1660` and `lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart:1717-1733` — details copy, menu and preview-limited ID.
- **S12** `withdrawn source citation` — shortcut, filter, ordering, keyboard behavior and global activation caveat.
- **S13** `lib/features/hermes_chat/screens/hermes_chat_screen.dart:867-964` — current Chat picker.
- **S14** `withdrawn source citation` — Pinned/Projects/Chats disclosure, row actions and path-based Project selection.
- **S15** `lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart:438-505`, `lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart:1124-1185` and `lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart:1229-1258` — static headers, shared tile and date groups.
- **S16** `test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart:1401-1436` — existing details-copy test intent.
- **S17** `docs/adr/product.md:7-28` — port priority and management-plane role.
- **S18** `lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart:26-109` — direct connection, negotiation and session/history reads.
- **S19** `docs/adr/api-and-state.md:7-48` — exact authorization, state/reconnect and identity rules.
- **S20** `lib/features/profiles/screens/profiles_screen.dart:265-356` — direct/fallback source selection and independently gated native create.
- **S21** `wing_link/internal/app/model_options.go:75-145` and `wing_link/internal/app/model_options.go:148-189` — credential resolution, advertised catalog validation and management authorization.
- **S22** `docs/adr/api-and-state.md:50-69` — current catalog exception and separate Chat policy.
- **S23** `docs/adr/runtime-and-delivery.md:53-89` — host authority and narrow compatibility boundary.
- **S24** `docs/security/threat-model.md:66-75` — host directory controls and missing Project operation.
- **S25** `docs/adr/security-and-privacy.md:20-47` — separate credentials, transport and local trust decisions.
- **S26** `docs/adr/api-and-state.md:71-119` — provider direction and preconditions, not enabled operations.

## Verification and remaining unknowns

The report's indexed source paths and inclusive ranges are checked against local files, and only this report receives a whitespace check. No Dart/Flutter/Go/browser tests are claimed by this source-only lane. Upstream status/revision commands are read-only. Existing dirty files and other lanes' work remain untouched.

Unknown: actual connected Agent capabilities/grants, production direct native-dashboard authorization, runtime persistence/recovery outcomes, clipboard behavior on each platform, screen-reader/keyboard behavior of rendered controls, shell-lane completion, same-card acceptance and release/device qualification. Source-backed proposals should receive focused RED→GREEN tests and then proportional platform verification before any parity claim.
