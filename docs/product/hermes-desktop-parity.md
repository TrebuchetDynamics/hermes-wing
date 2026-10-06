# Hermes Desktop parity

The owner-accepted priority (2026-10-03) is a **1:1 Hermes Desktop product port in
Flutter**: feature coverage, navigation, wording, interactions, state transitions
and recovery follow Desktop, not merely equivalent outcomes. Native implementation
may differ; responsive adaptations must be explicit deviations. This ledger tracks
existing Wing support and missing parity, not accepted full-port completion.
A Desktop screen or source file is not proof of Wing capability or authorization.
Desktop/wide-web is the accepted fidelity baseline; preserve mobile usability and
record its adaptive differences. Full local Desktop functionality is the target
through separately designed bounded native integration. Remote mode may expose a
smaller capability-gated subset; browser width confers no local authority. Native
integration is not implemented or approved by this ledger, and existing fixed
operation, authorization and secret-handling rules are unchanged.

## Current delivery assessment

Wing is a working Flutter client, not a visual mockup. Chat and shared client
reliability are its strongest areas. Existing session actions, profile/model
selection and supporting routes do not establish a qualified Desktop replacement.
See [route status](routes.md) for operation-specific availability.

The largest remaining gaps are the accepted end-to-end daily workflow, Desktop
profile/recents/session/tab composition, and full host-local/admin functionality.
The tables below distinguish implemented subsets from missing surfaces. Some gaps
need Flutter implementation; others need authoritative contracts or separately
reviewed bounded native integration. They are not all presentation work.

No parity percentage or completion date is established. Feature groups have
different sizes, and no weighted completion model has been adopted. Follow the
[roadmap sequence](../../ROADMAP.md#now--next--later): qualify daily use first,
then matched Desktop composition and remaining capabilities, with separate
packaging, installation, update and recovery evidence.

## Leading daily-use milestone

[Daily-workflow acceptance](../plans/2026-10-03-desktop-daily-workflow.md) now leads:
connect locally → select exact profile/model/session → real generation → correlated
approval/authoritative stop → leave/relaunch → restore that exact session with no
duplicate sends. Supporting Copy session ID, profile-picker and shell fixes follow
observed workflow gaps, not isolated polish priority. Fixture/native/browser/live
receipts remain separate; native deterministic replies are not actual inference.
Historical auth/build preflight findings require a fresh safe check, not an
automatic impossibility claim. The
[goal ledger](../plans/2026-10-03-desktop-port-goal.md) owns continuation/leases:
job `6f218a559ed2` has a recorded 10-minute cadence and local outputs. The
[latest recorded preflight](../quality/2026-10-04-desktop-cron-0322-auth-preflight.md)
paused it for missing provisioning; no automatic resume is authorized. This is
receipt-based status, not a fresh scheduler check or uptime guarantee. Historical
cards are not promoted by this ordering.

### Recorded workflow checkpoint

The [integrated browser receipt](../quality/2026-10-04-desktop-cron-0117-selector.md)
records 0 passed / 2 failed at 390px and 1280px: Stop/reconnect, route return and
reload progressed, but reopening the picker did not recover the confirmed
provider/model pair. Model-label restoration is not authoritative pair restoration;
the final resumed send and complete zero-duplicate guarantees were not reached.
The [parent review receipt](../quality/2026-10-04-desktop-cron-0309-review-validation.md)
validated source consistency only and withheld runtime acceptance. Native
process-relaunch and actual approved-target generation remain unqualified.
The [independent restoration admission review](../quality/2026-10-04-autogoal-restoration-admission-review.md)
also concluded `SOURCE_CONSISTENT_RUNTIME_WITHHELD`. It closed the clarified
proposal's source-review gate, not implementation authorization or runtime
acceptance. Exact-pair reads, passive resume semantics and private native
authentication remain qualification gates.
These are historical executed receipts, not new test results from this update.
See [root TODO](../../TODO.md) for the bounded blocked-work index; the goal ledger
remains the authority for continuation ownership. The [technical design](../spec.md)
maps current components and trust boundaries. The [test plan](../test-plan.md)
owns verification methods; neither document establishes workflow acceptance.

## Reference and evidence boundary

Read-only source pin: `2ed89070bc6c9e8231a37bb55df8a7722a3776b8` from
`https://github.com/fathah/hermes-desktop`, verified with HEAD/origin and cited
local paths on 2026-10-03. Five pre-existing `.claude` deletions remain untouched;
the pin is not a complete dirty-tree snapshot or remote-latest claim. No Desktop
runtime or tooling was exercised. The [UI audit](hermes-desktop-ui-gap.md) supplies
source links for Layout, profile/footer/recents, tabs, composer and transcript.

| Port gap | Source-backed Desktop reference | Delivery boundary |
| --- | --- | --- |
| Shell collapse/expand | [Layout](../../hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx), `toggleSidebar` and persisted `SIDEBAR_COLLAPSED_KEY` | First-wave local toggle/regression receipt preserved; not the leading daily-use milestone. Runtime/card acceptance not observed here; relaunch persistence is a separate gap. |
| Navigation, profile footer, recents | [Layout](../../hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx), [ProfileSwitcher](../../hermes-desktop/src/renderer/src/screens/Layout/ProfileSwitcher.tsx), [SidebarRecentSessions](../../hermes-desktop/src/renderer/src/screens/Layout/SidebarRecentSessions.tsx) | Workflow/Utilities grouping is implemented in the production desktop shell; see the [navigation runbook](../runbooks/desktop-navigation-groups.md) for bounded widget/browser evidence and explicit adaptations. Profiles/Persona remain utility routes, not Desktop's profile-footer editor; global profile-picker placement, grouped recents and full session-modal parity remain gaps. The [global loaded-session slice](../runbooks/global-session-access.md) now supplies exact Open/New Session from feature routes without incidental reads. Unsupported routes remain visibly unavailable or hidden, not fake working screens. Grouping does not establish full sidebar or daily-workflow acceptance. |
| Multi-conversation tabs | [ActiveSessionsBar](../../hermes-desktop/src/renderer/src/screens/Layout/ActiveSessionsBar.tsx), [chatRuns](../../hermes-desktop/src/renderer/src/screens/Layout/chatRuns.ts) | Current-session status is not parity. Exact identity, safe switching/close-stop and reconnect require independent behavior qualification. |
| Composer and transcript fidelity | [ChatInput](../../hermes-desktop/src/renderer/src/screens/Chat/ChatInput.tsx), [MessageList](../../hermes-desktop/src/renderer/src/screens/Chat/MessageList.tsx) | Compare action order, disclosure, model/context/reasoning controls and recovery; current responsive layout is a deviation, not acceptance. |
| Full remaining surfaces | [Discover](../../hermes-desktop/src/renderer/src/screens/Discover/Discover.tsx), [Memory](../../hermes-desktop/src/renderer/src/screens/Memory/Memory.tsx), [Kanban](../../hermes-desktop/src/renderer/src/screens/Kanban/Kanban.tsx), [Office](../../hermes-desktop/src/renderer/src/screens/Office/Office.tsx) | **Later:** complete feature coverage only through qualified authoritative contracts and accessible/native implementations. Existing partial surfaces remain gaps. |

Follow the [daily-workflow plan](../plans/2026-10-03-desktop-daily-workflow.md) and
[Now/Next/Later](../../ROADMAP.md#now--next--later). This documentation lane observes
source only: new implementation, browser/native/device/live Agent execution, card
acceptance and release qualification are **not observed**.


## Supporting Chat repairs

These implemented repairs support daily use without closing the integrated
workflow gate:

- [Approval settlement](../runbooks/chat-approval-settlement.md): retired responses
  cannot erase replacement mappings or release a newer response's duplicate guard.
  Already-started requests are not cancelled or replayed. Same-card review approved
  `t_6209124f` in run 130 after independently passing 398 focused tests.
- [Queued-follow-up intent](../runbooks/chat-queued-follow-up-intent.md): stale
  Manage and Cancel All dialogs cannot remove a replacement owner's queue.
  Manage removes the displayed object, not its old index.
- [Whole-transcript clipboard outcomes](../runbooks/chat-transcript-copy-outcomes.md):
  success follows clipboard completion. Rejection shows a fixed localized failure;
  retry requires a new user action. Started writes cannot be undone.
- [Session-pin lifetime](../runbooks/chat-session-pin-lifetime.md): disposed stores
  do not initiate writes from obsolete pending toggles. Already-started writes
  can still settle. Pins remain local presentation preferences.
- [Session-pin write order](../runbooks/chat-session-pin-write-order.md): one store
  serializes preference commits and coalesces waiting choices into the latest
  bounded snapshot. Successful settled writes preserve the newest local choice.
  Failed persistence remains best-effort, with no automatic retry, cross-instance
  ordering or physical durability guarantee.

The runbooks contain recorded Linux Flutter test-runner evidence, not fresh tests
from this documentation pass. Physical clipboard/preferences, compiled browser,
native application, live Agent and full Desktop parity remain unqualified here.

## Recorded quality checkpoint

The [full-suite follow-through](../quality/flutter-keyboard-follow-through.md)
records the earlier `npm run test -- --no-pub` result: exit 1, 2,846 passed and
one wide Providers keyboard-return failure at 200% text. It is not a passing
full-suite gate or a source-bound result for the later repaired tree.

The separate forward repair `t_c5a4d301` is completed and approved in native
review run 98. Its [receipt](../runbooks/provider-search.md#forward-shared-shell-repair-receipt-t_c5a4d301)
records 120 unique focused widget cases and five compiled deterministic Chromium
journeys, with a fresh 12-case reviewer rerun. No post-repair full-suite result
is established here. Native review names the approval lane, not native app
execution. This repair does not qualify live inference, native relaunch or full
Desktop parity. The governor separately archived `t_11b62717` as superseded,
not done or approved. Global loaded-session access `t_1c1e6f37` is completed and
independently approved in run 169. Its [runbook](../runbooks/global-session-access.md)
records the bounded Open/New Session surface and remaining qualification limits.
Grouped recents, the profile footer and full session-modal parity remain gaps.

## Statuses

- **implemented** — existing Wing capability with focused tests/gates; not a claim
  of 1:1 Desktop behavior, current-platform qualification or acceptance of this wave.
- **partial** — a subset/read-only capability exists; remaining Desktop behavior,
  mutation, transport or presentation differences are still parity gaps.
- **contract-blocked** — the current Hermes Agent capability document does not advertise the required operation.
- **local-native** — a desktop-local feature requiring platform implementation and runtime evidence.

| Hermes Desktop outcome                                                        | Wing status      | Current Wing outcome                                              | Required next contract or evidence                                     |
| ----------------------------------------------------------------------------- | ---------------- | ----------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Streaming chat, Markdown, tool activity, approvals, stop, retry               | implemented      | `/hermes` chat and runs                                           | Maintain Agent session/run contracts                                   |
| Session search, resume, fork, rename, delete | implemented | Chat session rail and actions. The [mutation-intent runbook](../runbooks/chat-session-mutation-intent.md) records owner-bound rename, branch and delete confirmations. | Preserve exact session endpoints and operation authorization. The runbook records widget regressions, not browser/native or full-workflow acceptance. |
| Agents/profiles and persona editing                                           | partial          | `/profiles`, embedded profile editor                              | Stable Agent profile/SOUL contracts or reviewed compatibility adapter  |
| Skills/Discover registry, install, uninstall, source links, profile targeting | contract-blocked | Installed skill inventory only through `/v1/skills`               | Bounded Agent registry/install/uninstall/profile-target contracts      |
| Memory entries, profile memory, capacity, providers                           | contract-blocked | No memory route                                                   | Advertised bounded memory read/write/provider contracts                |
| Saved models and full provider configuration                                  | partial          | Read-only/runtime and session model selection where advertised    | Agent provider/model CRUD, OAuth, pool, and secret-safe contracts      |
| Schedule create/edit/pause/resume/run/delete and delivery targets             | partial          | `/tasks` read-only job inventory                                  | Agent must advertise jobs admin endpoints and typed delivery targets   |
| Messaging gateway administration                                              | contract-blocked | Gateway health/status only                                        | Exact typed per-platform Agent or Wing Link operations                 |
| Toolset enable/disable and MCP administration                                 | partial          | `/tools` inventory only                                           | Advertised mutation and MCP contracts                                  |
| Standalone Soul/persona route                                                 | partial          | `/soul` plus the embedded Profiles persona editor                 | Stable profile-scoped SOUL read/write contract                         |
| Kanban/task planning                                                          | contract-blocked | No board state                                                    | Agent-owned Hermes Project/card contract plus opaque directory grants  |
| Backup/import, debug dump, log viewer, config health/fixes                    | partial          | Bounded diagnostics and local settings                            | Redacted structured diagnostics and atomic backup contracts            |
| Account/OAuth/credential pools, credits, wallet balances                      | contract-blocked | No account route                                                  | Exact account/provider/wallet contracts and secure OAuth handoff       |
| SSH/Docker/WSL remote backends                                                | contract-blocked | Typed gateway connections only                                    | Fixed Wing Link backend profiles and lifecycle contracts               |
| Web preview, file viewer, attachments/media                                   | partial          | Text/image attachments and bounded transcript media               | Advertised artifact/preview contracts and directory grants             |
| Office 3D/Claw3d management                                                   | partial          | Accessible 2D Office path; full Desktop interaction parity missing | Qualified native/3D implementation; accessible 2D remains required     |
| Auto-updates and desktop window/install flows                                 | partial          | Linux install/build and native menu commands                      | Signed manifest, activation, health, and rollback evidence             |
| Full Desktop slash-command catalog                                            | partial          | Curated local `/usage`, `/model`, `/persona`, `/version` commands | Agent command catalog/completion contract; no arbitrary shell dispatch |

The existing capability matrix above is not a fresh operation-by-operation runtime
audit. Read [route status](routes.md) and the roadmap's preserved source/card receipts
before promoting any row. Mobile single-pane/bottom navigation, sheets, bubbles,
Desktop Settings-route organization and 2D-only Office are explicit current
differences, not replacements for Desktop parity. Visual matching alone cannot
close interaction or recovery gaps.

## Ownership rules

Hermes Agent owns domain state. Wing Link owns authenticated host setup, lifecycle,
health, reviewed typed compatibility operations and opaque directory grants; it
is not the product organizing principle. This priority neither removes existing
dependencies nor makes Wing Link optional today. Wing never becomes a shell bridge,
proxy for Agent traffic or second backend. Reference repositories remain read-only;
parity cannot justify Agent patches, privileged file/config/database copying,
merged credentials, broad CLI or reconnect mutation replay.

A feature is promoted from `contract-blocked` or `partial` only after the exact operation is advertised by the connected Agent or implemented as a reviewed fixed Wing Link operation, then covered by unit/widget, deterministic fixture, and named-platform E2E evidence.
