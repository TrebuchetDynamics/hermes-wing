# Profile footer and session-modal composition

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Status: source-backed comparison and implementation brief for `t_6a1e03fc`
(`DOC-PARITY-COMPOSITION`, goal `PARITY-COMPOSITION`). No product code changed.
The proposed first slice below is not implemented by this card.

## Evidence boundary

Wing HEAD: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`.
Desktop reference HEAD: `withdrawn reference revision`.
The local [Desktop instructions](official-desktop-reference.md#withdrawn-evidence) were read before
inspection. Desktop was not run or changed. Its pre-existing deleted `.claude`
files are outside the inspected renderer/menu scope. `lat` is not installed;
source reads replaced semantic lookup, without installing tools or reading keys.

Wing is a dirty shared checkout. HEAD is not a complete snapshot of its live UI.
The shell, loaded-session access and three shell test targets matched HEAD.
Chat screen/layout files already contained unrelated changes and were read only.
Card-local `source-fingerprints.json` records SHA-256 hashes of inspected files.
All receipts are under ignored `.task-evidence/t_6a1e03fc/`.

The [client ADR](../adr/client.md#decision) requires Desktop fidelity without
copying privileged IPC. The [API ADR](../adr/api-and-state.md#decision) keeps
Agent domain state authoritative and profile identities explicit. The
[route inventory](../product/routes.md#routes) and
[parity ledger](../product/hermes-desktop-parity.md#reference-and-evidence-boundary)
distinguish delivered loaded-session access from full composition.

## Reference actions and current Wing deviations

| Surface/action | Desktop source behavior | Current Wing caller and deviation |
| --- | --- | --- |
| Expanded profile footer | [ProfileSwitcher](official-desktop-reference.md#withdrawn-evidence), `editCurrent`: avatar/name opens the current profile edit modal. A separate Users button opens the switch picker. | [AppShell](../../lib/shared/widgets/app_shell.dart), `_DesktopShell` and `_AppShellStatus`: profile/model are passive full-width status-bar values. Profiles remains a utility destination, not a split footer control. There is no shell profile edit chip. |
| Collapsed footer | `ProfileSwitcher` with `compact`: the single avatar opens the picker. [Layout](official-desktop-reference.md#withdrawn-evidence) mounts it below footer utility icons. | Wing retains icon-only utility destinations and the bottom status bar. Collapse removes `ShellSessionAccess`; it does not add a compact profile picker. |
| Profile picker | `ProfileSwitcher`: Ctrl/Cmd+P toggles it globally. Opening resets query/highlight, refreshes profiles and focuses search. Name/id/model substring matching, running-before-stopped groups, active-first within each group, ArrowUp/Down clamping, Enter choice, Escape/backdrop dismissal and Manage Profiles are explicit. | [ChatProfilePicker](../../lib/features/hermes_chat/widgets/chat_profile_picker.dart) already has loaded name/id/model search, selected-first rows, keyboard highlight, Escape and Manage. Its owner is Chat's `_showProfileSwitcher`, not the shell. Running/stopped grouping and the global footer/shortcut are not supplied by AppShell. Do not fabricate gateway-running status from connection status. |
| Profile selection | Desktop `handleSelect` closes the picker, calls `setActiveProfile`, and still invokes `onSwitch` after failure. Layout's `handleSelectProfile` selects a profile-specific scratch run and retains other runs. | [Chat screen](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart), `_showProfileSwitcher`/`_switchProfile`, uses current channel/directory/profile identity, latched invalidation and client-local selection. [Profiles screen](../../lib/features/profiles/screens/profiles_screen.dart), `_selectProfile`, delegates to channel or directory. Do not copy optimistic failure, global profile activation, scratch-run creation or gateway start. These are not interchangeable with Wing selection. |
| Open full sessions from anywhere | Desktop [menu](official-desktop-reference.md#withdrawn-evidence) sends `menu-search-sessions` for CmdOrCtrl+K. Layout's subscription opens `Sessions` over the current view. Escape/backdrop close it; resume/New close it before dispatch. | Chat's `_showSessionsPanel` in [connection state](../../lib/features/hermes_chat/screens/state/hermes_chat_connection.dart) opens a route-local bottom sheet. Ctrl/Command+K works in Chat in deterministic tests. Shell loaded Open/New is a separate surface, not a global full-list modal. |
| Session inventory/search | [Sessions](official-desktop-reference.md#withdrawn-evidence), `loadSessions`/`refreshSessions`: connection/profile-scoped cache sync, initial 50-row slice, cached fallback, visible-only refresh timer/window focus. Debounced `searchSessions` produces results distinct from the list; date groups and source/type filters compose the display. | [Chat session widgets](../../lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart), `_HermesSessionsPanel`, filters loaded inventory locally and offers Agent-backed Load more. It includes New and management callbacks. Do not describe that as full-content server search, Desktop date grouping or equivalent cache/refresh recovery. |
| Exact resume | Desktop Layout's `handleResumeSession` locates an existing run by connection/profile/session, otherwise fetches messages and opens a run; duplicate resumes are guarded. | [ShellSessionAccess](../../lib/features/hermes_chat/widgets/shell_session_access.dart), `_activate`, calls the existing channel for an exact loaded ID, waits for acknowledged selection, then routes to Chat. This delivered Open/New behavior must not be implemented again. Multiple mounted conversations and close/Stop semantics remain separate work. |

Source behaviors above are inspected contracts, not executed Desktop outcomes.
Desktop's profile picker requests search focus explicitly. Its session overlay
code does not establish focus containment or focus return. Do not promote either
source description into a screen-reader or keyboard-runtime qualification.

## Identity, capability and recovery oracles

These are constraints for later composition work, not new backend contracts.

- Read status from the current `hermesChannelProvider` instance. Keep canonical
  Agent origin, selected profile ID, directory lifetime/instance and active
  contact identity distinct. Display fallback from `effectiveSelectedProfileId`
  is not authority to mutate a guessed default profile.
- `ShellSessionAccess._identity` also tracks connection status, profile selection,
  directory activation/restoration, unreconciled run and session create/history
  availability. `_changed` invalidates synchronously, including row removal.
  A change away and back must never revive a captured callback or late result.
- Loaded Open requires a connected, settled owner and the exact ID still in its
  loaded inventory. New additionally requires `canCreateSessions`. One pending
  action is admitted. Success must acknowledge the selected ID or a newly created
  ID before navigation. Failure retains the feature route and allows explicit
  retry. Owner loss discards late errors and navigation, not server state.
- [HermesChannelState](../../lib/core/hermes/channel/hermes_channel_state.dart)
  gates advertised `session_messages` on GET
  `/api/sessions/{session_id}/messages` and `session_create` on POST
  `/api/sessions`. The policy checks supported schema, exact method/path,
  all required scopes and supported profile query context when required.
  Both getters retain a null-capability compatibility branch. This is existing
  behavior, not evidence of exact advertised authorization in that branch.
- Read availability does not grant rename, delete, fork, profile edit, lifecycle
  or secret writes. Future modal management must retain each current gate and
  caller's intent/owner guards. Never route Agent sessions through Wing Link.
- A future global modal must have one admitted route, initial search focus,
  bidirectional traversal contained within it, visible highlighted rows, a named
  selected state, Escape/backdrop cancellation and deterministic focus return.
  Held Enter during dismissal must not reopen it. Loss of origin/profile/channel,
  contact, directory, capabilities or row identity must latch invalidation.
  Reconnect may reconcile reads; it must not replay selection or New automatically.
- Modal failure must remain visible and redacted, distinguish empty inventory
  from failed load, and allow explicit retry only for its current owner. Native
  closure, keyboard containment and recovery require new tests plus target-runtime
  qualification. Existing shell tests do not prove these future modal oracles.

## Smallest safe implementation slice

Recommended next slice: add a read-only current-profile footer with an explicit
Manage Profiles navigation action. This advances footer placement and keyboard
access without extracting Chat ownership or adding a second profile switcher.
It is deliberately partial, not a replacement for the reference edit/switch UI.

1. Compose it inside `_DesktopShell`, below the scrollable navigation region.
   Reuse `_AppShellStatus.profile` and the current channel's display projection.
   Keep the existing full-width status bar until a separately scoped removal.
   Do not move or duplicate global loaded Open/New actions.
2. Expanded: show a labeled, non-editable current-profile value and a named
   Manage Profiles button. Compact: show one named Manage Profiles icon with the
   current-profile context in its accessible label/tooltip. Never label either
   action Switch or Edit while those actions are not provided by the footer.
3. Navigate with the existing `AppRoutes.profiles` route. This action passes no
   host path, guessed profile argument or credentials. Navigation needs no new
   Agent grant. The destination retains its own exact read/write gates. Reading
   the footer must not construct a gateway directory, refresh inventory, select
   a profile/session, create a session, stop a run or assign a model.
4. Disconnected/unloaded state must use the existing unavailable display, not a
   stale profile name. A profile/endpoint replacement updates the display from
   the current owner. Missing display names may fall back to the current ID, not
   to a persisted shadow profile. Use existing preview redaction for names.
5. Preserve WidgetOrderTraversalPolicy across the shell/route boundary and route
   ReadingOrderTraversalPolicy. Keep a visible focus outline and a 48px target.
   At 2x text scale and short height, navigation must still scroll; the footer
   must remain reachable without overflow. Returning from Profiles must preserve
   the originating route's existing draft behavior, not promise new persistence.

Expected code scope for that later slice: `app_shell.dart`, nearest shell tests,
English localization input plus generated output if new copy is required, and
its support-status receipt. No new dependency, provider, transport or mutation.
This card does not edit those files or authorize broader profile administration.

Acceptance tests to add for the slice:

| Oracle | Required observable outcome |
| --- | --- |
| Passive footer ownership | Channel A/B and disconnect updates show only current context; display performs zero incidental domain calls. Test absent/default/name fallback separately. |
| Navigation-only action | Pointer, Enter and Space navigate exactly once to `/profiles`; no select/create/Stop/model/approval call occurs. Revoked read/write grants do not become synthetic permissions. |
| Focus and layout | Expanded and compact footer is named, keyboard reachable and visibly focused. Tab/Shift+Tab still reverse into the route editor after scroll/resize; 2x text and 360px height do not overflow. |
| Cancellation and return | Navigation itself does not open a profile picker, mutate a run or replay intent. Existing route drafts remain governed by their current owner. |

After that slice, the reference split edit/switch footer, global profile shortcut,
running/stopped data, global full-list session-modal extraction and modal focus
qualification remain open. Grouped recents, multi-conversation tabs and close/Stop,
composer and transcript fidelity are outside this brief's implementation slice.
Do not enqueue duplicate repairs or infer a privileged host-operation contract.

## Executed checks and qualification limits

On Linux, Flutter 3.44.2 / Dart 3.12.2:

- `flutter test --concurrency=1 test/shared/widgets/app_shell_global_session_access_test.dart test/shared/widgets/app_shell_reference_fidelity_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart` — PASS, 51 tests. Loaded Open/New acknowledgement, owner loss/change-back, capability denial, pending/error/retry, semantics, collapse/resize, focus rendering and shell/route reversal were exercised with fakes.
- `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart --name 'active header shows agent and gateway and opens sessions|sessions panel exposes Agent-backed load more|desktop shortcuts open sessions and create an authorized session|macOS command shortcut opens sessions'` — PASS, 4 tests. These prove the existing route-local panel/shortcut calls under deterministic platform overrides, not native macOS or Linux execution.
- `python .task-evidence/t_6a1e03fc/check_receipt.py` — validates this receipt's local links/anchors and pinned inspected-source hashes. See card-local `receipt-check.log` for the executed result.
- `git diff --check` and `python ~/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo>` — results are recorded in card-local `ledger-checks.log` after the targeted task/evidence/render updates.

Native Flutter desktop, compiled browser, live Agent/provider, physical Android,
macOS runtime and screen-reader qualification: NOT_CHECKED. Full-suite analysis,
builds and localization generation were not required for this documentation-only
slice. Passing checks do not mark `PARITY-COMPOSITION` fully met.

The scoped prose follows the STE-inspired writing profile. Local links and
technical meaning are checked separately. Full ASD-STE100 dictionary compliance
was not verified. No owner question is needed for this reversible brief.
