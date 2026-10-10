# Hermes Desktop UI Gap Audit

> Reference correction: [official Desktop authority](../quality/official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Source reference: `withdrawn source`, inspected read-only
from the local `withdrawn source citation` checkout. The verified pin and limits are below.

Historical Hermes Wing screenshot leads (not refreshed or exercised here):

- `playwright/screenshots/hermes-connected-desktop-scaffold.png`
- `playwright/screenshots/hermes-connected-mobile-scaffold.png`
- `playwright/screenshots/hermes-connect.png`
- `playwright/screenshots/settings.png`
- `playwright/screenshots/hermes-active-session-bar.png`

## Design target and current priority (2026-10-03)

The accepted goal is a **1:1 Hermes Desktop product port in Flutter**, not an
inspired-by redesign or merely equivalent outcomes. Desktop feature coverage,
navigation, terminology, interactions, state transitions and recovery define
parity. Native implementation may differ; responsive adaptation is an explicit
product deviation, not a substitute for Desktop fidelity. Existing phone layouts
and Telegram-style bubbles are current differences to review, not a competing goal.

The source pin is `withdrawn reference revision`, verified read-only
from Desktop HEAD and its origin URL on 2026-10-03. The checkout retains five
pre-existing `.claude` deletions; this pin is not an immutable snapshot of every
working-tree file or a remote-latest claim. No upstream tooling was run or changed.
The paths below exist locally; source inspection is not an exercised Desktop UI.
Screenshots listed above and historical slices below are leads, not current-source
parity, runtime or acceptance receipts.

## Current source-backed gaps

Desktop references below are relative to `withdrawn source citation`.
Wing route support remains in [Routes](routes.md); operation gaps are in the
[parity ledger](hermes-desktop-parity.md).

| Area | Desktop source reference | Wing difference / remaining gap |
| --- | --- | --- |
| Welcome and first launch | [Welcome](../quality/official-desktop-reference.md#withdrawn-evidence), [OnboardHero](../quality/official-desktop-reference.md#withdrawn-evidence) | Desktop starts with a branded hero, Get Started and separate SSH/Remote actions. The owner-supplied APK instead shows a Profiles empty state, gateway-first copy and bottom navigation, with Chat selected under a Profiles title. The current worktree adds the settled emblem, title, Get Started and SSH/Remote actions before the shell. The [welcome receipt](../quality/desktop-welcome.md) records widget/Chromium fresh launch, cancellation, retry and saved-owner reload at 390/1280px and 100/200% text. Static branding/motion and supported connection differences remain explicit. The [recovery receipt](../quality/desktop-welcome-recovery.md) adds isolated Linux GTK keyboard cancellation, explicit retry and process restoration with synthetic endpoint storage. Android, physical keychain, live authentication and protected-main delivery remain open; this candidate does not repair the supplied APK. |
| Shell hierarchy | [Layout](../quality/official-desktop-reference.md#withdrawn-evidence), `PINNED_NAV_ITEMS`, `FOOTER_NAV_ITEMS` | Desktop pins Discover/Office/Kanban/Schedules, puts Providers/Gateway/Tools/Memory in the footer and reaches profile management through the profile switcher. Wing's [presentation](../../lib/shared/widgets/app_shell_presentation.dart) now separates desktop Workflow (Chat/Office/Schedules) and Utilities (Providers/Connections/Tools/Profiles/Persona/Settings); see the [navigation runbook](../runbooks/desktop-navigation-groups.md) for bounded evidence. Profiles/Persona remain explicit utility routes rather than the Desktop footer editor. Discover/Memory/Kanban remain gaps; grouping is not full hierarchy parity. |
| Collapse / expand | [Layout](../quality/official-desktop-reference.md#withdrawn-evidence), `SIDEBAR_COLLAPSED_KEY`, `toggleSidebar` | Accessible local collapse/expand is implemented with bounded evidence in the [first-wave receipt](../quality/2026-10-03-desktop-port-first-wave.md), retaining current route and Chat ownership. Desktop persists the preference; Wing's relaunch persistence remains a separate gap. Local tests/source review do not establish native runtime or card acceptance. |
| Profile footer and session access | [ProfileSwitcher](../quality/official-desktop-reference.md#withdrawn-evidence), [SidebarRecentSessions](../quality/official-desktop-reference.md#withdrawn-evidence), [Layout](../quality/official-desktop-reference.md#withdrawn-evidence) | Wing's [global loaded-session section](../runbooks/global-session-access.md) provides exact Open/New Session from other feature routes in the expanded sidebar. It is completed and independently approved. The later [passive profile footer](../quality/profile-footer-implementation.md) adds current-profile display and Manage profiles navigation, not Desktop's split edit/switch controls. The later [source-grouped recents](../quality/grouped-recents-implementation.md) preserve loaded order and exact Open/New without incidental reads. Project/folder grouping and group disclosure remain gaps. The [global session modal](../quality/global-session-modal.md) now reuses the full session panel over feature routes with bounded keyboard/owner recovery. The [adaptive receipt](../quality/global-session-modal-adaptive.md) adds compact/short-window keyboard reachability at separate 200% text/zoom; native/live and screen-reader qualification remain unverified. Chat retains full session management. No direct DB/filesystem access or raw path grouping is implied. |
| Active conversation tabs | [ActiveSessionsBar](../quality/official-desktop-reference.md#withdrawn-evidence), [chatRuns](../quality/official-desktop-reference.md#withdrawn-evidence) | Wing's current-session status bar is not switch/new/close multi-conversation parity. Qualify exact tuple ownership, concurrency, terminal Stop and reconnect before adding live-tab claims. Mobile omission is a recorded deviation, not silently accepted parity. |
| Composer | [ChatInput](../quality/official-desktop-reference.md#withdrawn-evidence), [ModelPicker](../quality/official-desktop-reference.md#withdrawn-evidence), [ReasoningEffortPicker](../quality/official-desktop-reference.md#withdrawn-evidence) | Wing has its own responsive command bar and conversation-only model picker. The historical [dictation comparison](../quality/chat-fidelity-reference.md) identified hidden wide draft capture. The [delivered draft action](../quality/chat-direct-dictation.md) now places a keyboard-operable microphone beside attachment and before the model strip; hands-free stays separate. Cancellation discards recognition rather than finalizing it as Desktop does. Controlled recognition and compiled-browser unavailable-service recovery do not qualify physical audio, a standalone branch build or full composer parity. The [wide composer receipt](../quality/chat-composer-order.md) qualifies named traversal, model loading and exact Send/Stop requests for the supported subset. Stop placement and explicit follow-up queuing differ from Desktop. The [adaptive recovery receipt](../quality/chat-composer-order-recovery.md) qualifies compact/wide return, pending-owner rejection and capture cancel versus exact run Stop. The [enlarged-text receipt](../quality/chat-composer-accessibility.md) qualifies supported controls at 200% widget text/browser zoom with reduced motion. Context/folder, web/tool, reasoning and full composition remain gaps; unavailable Agent operations stay explicitly gated. |
| Transcript and recovery | [MessageList](../quality/official-desktop-reference.md#withdrawn-evidence), [ApprovalCard](../quality/official-desktop-reference.md#withdrawn-evidence), [HistoryRow](../quality/official-desktop-reference.md#withdrawn-evidence) | The [reasoning implementation](../quality/reasoning-disclosure-implementation.md) delivers active/completed summaries and keyboard focus through completion, with executor-reported widget/Chromium checks. The later [recovery receipt](../quality/reasoning-disclosure-recovery.md) records collapsed remount, owner replacement and read-only reconnect; HTTP history drops transient reasoning. The [adaptive receipt](../quality/reasoning-disclosure-adaptive.md) qualifies compact/wide keyboard return under reduced motion; the [enlarged-text receipt](../quality/reasoning-disclosure-accessibility.md) separately covers 200% widget text scaling and Chromium zoom, completion and reused-ID owner replacement; the [streamed-order receipt](../quality/chat-transcript-order.md) qualifies canonical activity order through completion and adaptive keyboard return, and repairs explicit-profile approval display/activation for reused session IDs. The [reconnect receipt](../quality/chat-transcript-reconnect.md) retains canonical tool-result categories after history recovery, route/viewport remount and page reload without mutation replay. It does not recover tool content, transient reasoning, unfinished invocations or authoritative tool success/failure. The [whole-transcript receipt](../quality/chat-transcript-accessibility.md) adds bounded enlarged-text keyboard/recovery checks with wrapped tool titles. The [native transcript receipt](../quality/native-transcript-recovery.md) adds four Linux GTK fixture cases for keyboard disclosure, explicit approval retry and delayed-owner rejection at 100/200% text, with zero recovery replay. Process restart, live Agent behavior, physical input, screen readers and broader native transcript qualification remain open. Existing grouped tools/approvals/failures and bubble alignment are not full parity. Preserve redaction, canonical reconciliation and exact request correlation; do not invent reasoning events. |
| Settings and status | [StatusBar](../quality/official-desktop-reference.md#withdrawn-evidence), [Gateway](../quality/official-desktop-reference.md#withdrawn-evidence), [Providers](../quality/official-desktop-reference.md#withdrawn-evidence) | Wing's Settings route and Connections dashboard differ from Desktop's settings-modal/footer/status organization. Simplicity on phones does not waive parity; host trust and provider mutation remain separately gated. |
| Remaining product screens | [Discover](../quality/official-desktop-reference.md#withdrawn-evidence), [Memory](../quality/official-desktop-reference.md#withdrawn-evidence), [Kanban](../quality/official-desktop-reference.md#withdrawn-evidence), [Office](../quality/official-desktop-reference.md#withdrawn-evidence) | Planned/unavailable Discovery, Memory and Kanban plus accessible 2D Office remain explicit gaps against Desktop feature coverage. 2D accessibility is required but does not prove 3D/representative/account parity. |

## Current shell redesign evidence

The [shell redesign receipt](../runbooks/desktop-shell-reference-fidelity.md)
records a reference-matched 250/64 logical-pixel sidebar, scoped light/dark colors,
a top collapse control and a 26px-minimum status strip. The branded header is
removed. Workflow/Utilities groups remain semantic groups, without painted headings.
Profiles/Persona remain labeled utility routes. The later
[passive footer](../quality/profile-footer-implementation.md) adds fixed display
and navigation; it is not the Desktop profile editor/switcher.

The receipt records 57 focused widget passes and two compiled Chromium journeys.
The bounded independent review resolved the toggle-outline and typography findings;
`DESIGN.md` records the delivered slice. Commit `1afe1307` carries that correction.
Its [exact-tree receipt](../runbooks/desktop-shell-reference-fidelity.md#committed-tree-validation)
records 3,469 Flutter passes and two compiled Chromium journeys. This documentation
pass checked receipt integrity, not a new product run. Native/live, screen-reader,
relaunch persistence and complete sidebar/session composition remain unqualified.
The historical branded-shell notes below do not describe the current shell.

## Historical initial slice and verification boundary

The [first-wave plan](../plans/2026-10-03-desktop-port-first-wave.md) scoped shell
collapse/expand only, plus a failing-then-passing regression and parent review.
The [first-wave receipt](../quality/2026-10-03-desktop-port-first-wave.md) records
its bounded implementation/review, not runtime acceptance. Current ordering is
the [daily workflow](../plans/2026-10-03-desktop-daily-workflow.md); the
[parity ledger](hermes-desktop-parity.md) records the later navigation grouping
and blocked integrated checkpoint.
No new route, Agent API, Wing Link operation, credential, domain state or runtime
mutation belongs to this slice. Persisted preference, footer navigation, recents,
profile switcher, keyboard session switching and true tabs are separate next gaps.

Desktop source/reference paths have been inspected; browser, native desktop,
Android, screen-reader and live Agent execution for this new slice are **not
observed in this documentation lane**. Card acceptance, integrated parity and
release qualification are also not observed. Screenshots or a passing local shell
regression alone cannot close those gaps.

## Historical scaffold evidence (retained, not re-qualified)

The following original slice notes describe earlier implementation observations.
Their symbols/screenshots may predate current refactors. They preserve history,
not a current implementation audit or acceptance claim. References to Telegram-like
mobile styling describe existing deviations; they no longer define the target.

## Completed implementation slice: Hermes Dark + branded desktop shell polish

Evidence:

- `lib/theme/wing_theme.dart` now defines `wingHermesDarkTheme` with near-black Hermes surfaces, blue accents, dark cards/chips, and rounded dark inputs.
- `lib/shared/widgets/app_shell.dart` applies Hermes Dark to desktop/tablet shell widths and adds a `HERMES WING` branded rail header.
- `playwright/screenshots/hermes-dark-desktop-scaffold.png` shows dark shell, dark session rail, dark chat pane, dark empty state chips, and dark composer.
- `playwright/screenshots/hermes-dark-mobile-scaffold.png` shows mobile staying Telegram-like: single pane, bottom nav, bottom composer, and large touch targets.

## Completed implementation slice: Desktop composer command bar

Evidence:

- `lib/features/hermes_chat/screens/hermes_chat_screen.dart` now switches composer layout by available width.
- Desktop/tablet chat panes use a single rounded `hermes-desktop-command-bar` containing the message field, voice toggle, model/voice/ready/retry/diagnostics chips, attachments, mic, and send.
- Mobile keeps the previous Telegram-like two-row bottom composer.
- `playwright/screenshots/hermes-commandbar-desktop-scaffold.png` shows the Desktop-like command bar in the dark Hermes shell.
- `playwright/screenshots/hermes-commandbar-mobile-scaffold.png` shows mobile still using the Telegram-style bottom composer.

## Completed implementation slice: Tool activity grouping + desktop session search

Evidence:

- `lib/features/hermes_chat/screens/hermes_chat_screen.dart` now renders transcripts through `_HermesTranscriptList`.
- Consecutive Hermes `toolCall` turns collapse into `_ToolActivityGroup`, a left-aligned expandable card similar to Hermes Desktop's `ToolActivityGroup` pattern.
- Individual tool rows remain available inside the expanded group with running/completed/failed icons and redacted previews/results.
- Desktop/tablet `_HermesSessionRail` now has `Search sessions`, clear action, and visible result counts, matching Desktop's first-class session-history direction.
- User and assistant text remains in simple Telegram-style right/left bubbles.

## Completed implementation slice: Inline approval timeline

Evidence:

- Pending approvals are now rendered by `_HermesTranscriptList` as inline left-aligned approval cards after transcript rows instead of a full-width top-of-chat banner.
- The approval card keeps review/deny/allow/approve actions, pending count, risk copy, and malformed/unavailable states.
- This better matches Hermes Desktop's chat-flow cards while preserving mobile-safe approval buttons.

## Completed implementation slice: Inline failure/status timeline polish

Evidence:

- Chat errors now render through `_HermesTranscriptList` as compact left-aligned failure cards rather than full-width chrome above the composer.
- Failure cards keep contextual recovery text plus Details/Reconnect/Retry actions.
- The card shape matches the bounded assistant-side approval/tool cards, while mobile still keeps simple bottom composer ergonomics.

## Completed implementation slice: Desktop assistant turn/avatar polish

Evidence:

- `_AssistantTimelineItem` adds a lightweight Hermes avatar column around assistant-side text, tool, approval, and failure rows on desktop/tablet widths.
- Widths below the desktop command-bar breakpoint keep the previous Telegram-like mobile bubble rhythm without assistant avatar chrome.
- This makes tool/approval/final-answer sequences read closer to Hermes Desktop's one-assistant-turn timeline while preserving right-aligned user bubbles.

## Completed implementation slice: Hermes settings/status dashboard

Evidence:

- `lib/features/settings/screens/settings_screen.dart` now renders a Hermes Agent dashboard instead of basic list tiles.
- Card sections cover Hermes Agent status, Connection, Appearance, Diagnostics, and Local voice preferences.
- The dashboard shows endpoint, auth-present/not-shown state, health/version, model, run transport, session/inventory counts, and an Open Hermes action.
- Cards stay stacked and mobile-simple; no Desktop-only nav sprawl was added.

## Completed implementation slice: Desktop active-session bar

Evidence:

- `lib/features/hermes_chat/screens/hermes_chat_screen.dart` now adds `_HermesActiveSessionBar` on desktop/tablet chat panes.
- The bar mirrors Hermes Desktop's top active-session/tabs region without becoming a full multi-run tab system: current session pill, ready/streaming/transport status, model, and message count.
- Mobile stays single-pane and Telegram-like; the active-session bar is hidden below the desktop command-bar breakpoint.

## Completed implementation slice: VPN/mobile reconnect clarity

Evidence:

- `HermesChannelState` now carries the connected API origin and whether a bearer key was used, so connected/status surfaces can describe the real VPN endpoint instead of falling back to localhost placeholders.
- Chat error recovery now uses a true reconnect path against the current/saved endpoint instead of routing through destructive Disconnect, preserving saved VPN profiles and secure API-key storage.
- When the app resumes from background, recoverable connected/error states reconnect against the saved/current VPN endpoint instead of waiting for manual setup.
- The connect form hydrates from the saved endpoint profile when available, which keeps reopen/reconnect behavior aligned with the mobile-over-VPN use case.
- Settings now prefers the live connected endpoint/auth state and still hides the API key value.

## Explicit deviations and non-copy boundaries

- Current phone single-pane layout, bottom navigation, sheets, bubble alignment
  and composer density differ from Desktop. Review reachable actions, ordering,
  recovery and keyboard/accessibility behavior against the reference; do not use
  “mobile-simple” or “Telegram-like” as an exemption from the port target.
- Flutter/OS window chrome replaces Electron chrome. Native APIs are implementation
  choices, not evidence of qualified desktop install/update behavior.
- Accessible 2D Office must remain operable without 3D. It is an accessible path,
  not completion of Desktop's full Office surface.
- Desktop host-local CLI, file/database/config access, SSH/worktree controls and
  account integrations cannot be copied as authority. Use exact advertised Agent
  operations or only already-reviewed fixed Wing Link compatibility boundaries.
- Wing Link is current host management, not the product organizing principle;
  dependencies have not been removed or made optional. Agent traffic remains
  direct, credentials separate, directory grants folder-only, server state
  authoritative and reconnect mutation replay forbidden.

Next work follows the [roadmap](../../ROADMAP.md#now--next--later), with exact
source/test/target receipts for each gap. Missing contracts defer only affected
operations, not supported presentation. No implementation/runtime/card status is
promoted by this audit refresh.
