# Routes

Hermes Wing uses one adaptive route tree. Android currently keeps Chat, Profiles, and Connections in the compact bottom bar and places the other working slices in More. Desktop and wide web separate **Workflow** (Chat, Office, Schedules) from **Utilities** (Providers, Connections, Tools, Profiles, Persona, Settings) in the sidebar. All nine working destinations remain explicit, named and route-selected when expanded or icon-only; short windows scroll the groups while keeping the collapse control available. Routes are added with working vertical slices, so approved entries may remain planned until their capability lands. See the [desktop navigation runbook](../runbooks/desktop-navigation-groups.md) for evidence and deliberate Desktop differences.

| Route          | Android placement | Purpose                                                                                                                                                                                                                                                                                            | State       |
| -------------- | ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `/hermes`      | Chat              | Connection, paginated Agent-owned session and transcript history, runs, voice, approvals, and diagnostics.                                                                                                                                                                                          | implemented |
| `/discover`    | Discover          | Skills and MCP discovery.                                                                                                                                                                                                                                                                          | planned     |
| `/office`      | More              | Accessible 2D workspace over authoritative gateway contacts with search, refresh, status/session counts, and exact contact activation into Chat; representative, account/wallet, and desktop 3D interactions remain gated.                                                                         | partial     |
| `/tasks`       | More              | Gateway-scoped scheduled-job inventory with refresh and recovery. Agent mutation routes are not yet advertised as exact scoped operations, so create/edit/pause/run/delete controls and Kanban remain hidden.                                                                                                                                                                  | partial     |
| `/profiles`    | Profiles              | Profile inventory and lifecycle, Agent-backed provider/model autocomplete through Wing Link during setup, plus approved child-folder browsing through device-bound opaque handles (`/agents` redirects for compatibility). Project creation remains unavailable until Hermes Agent advertises a suitable machine-readable operation; Project-aware Chat is separately gated. | partial     |
| `/soul`        | More              | Standalone profile persona editor, available only when the selected Agent advertises exact scoped SOUL read/write operations.                                                                                                                                                                  | partial     |
| `/enroll`      | (deep link)       | Guided phone/computer setup, QR/link pairing, transaction recovery, and endpoint-bound readiness checks outside the shell; advanced manual connection remains available within pairing.                                                                                                                                                                                                                                               | implemented |
| `/setup/local` | enrollment        | Platform-specific guided local setup: qualified Linux service flow or unqualified Android/Termux Tier 2 explicit bootstrap; no command bridge.                                                                                                                                                     | partial     |
| `/providers`   | More              | Capability-gated provider inventory, write-only API-key management, credential validation, runtime-model inventory, and model assignment through advertised Agent operations. OAuth providers are labeled as host sign-in rather than opening an API-key form; remote OAuth and multi-credential flows remain contract-gated.                                                            | partial     |
| `/tools`       | More              | Gateway-scoped searchable installed-skill metadata and resolved toolsets with exact-scoped refresh; mutation, MCP administration, and discovery remain contract-gated.                                                                                                                             | partial     |
| `/memory`      | More              | Memory entries, profile, capacity, and providers.                                                                                                                                                                                                                                                  | planned     |
| `/gateway`     | Connections       | Saved hosts, explicit chat connect/disconnect, bounded Agent health, connection editing/removal, and independent Wing Link device trust/revocation; lifecycle, logs, peer administration, and messaging-platform administration remain contract-gated.                                                                      | partial     |
| `/settings`    | More              | Link to Connections, appearance, supported spellcheck, voice, and redacted diagnostics; also selected by Ctrl/Command+, and bounded Linux/Windows/macOS native Settings menu commands.                                                                                                        | implemented |

Profile switching and session history remain directly reachable from Chat. More is an action sheet, not a route.

Expanded desktop/wide-web sidebars also expose **Loaded sessions** with exact
**Open** and explicit **New Session** actions from working feature routes. This
bounded surface uses only the current owner's loaded inventory and navigates to
Chat after acknowledged success; collapse removes its controls from focus and
semantics. Compact Chat retains the full route-local picker. Search, pins,
pagination and management remain in Chat, not this global section. Executor
verification and independent same-card review on `t_1c1e6f37` are complete (review run 169).
This does not qualify native desktop execution or the full daily workflow. See the
[global session access runbook](../runbooks/global-session-access.md) for ownership,
zero-incidental-read evidence, route-local draft limits and platform exclusions.

Tools and Schedules have keyboard-only compiled Chromium journeys at 390/1280px
on `t_2b24fc6c`, executor-verified pending same-card tester/reviewer acceptance.
Tab/Shift+Tab reach and escape editors, clears, filters, disclosures and shell
navigation; Enter/Space perform explicit read-only actions with rendered focus
evidence and exact scoped API receipts. A minimal desktop shell semantic boundary
keeps the drawn navigation rail exposed beside the nested route. Tools independent
queries survive refresh; Schedules retains its filter/query through sanitized
failure and keyboard Retry. Resolved-tool chips remain display-only. See the
[Tools](../runbooks/tools-search.md#keyboard-only-compiled-browser-workflows) and
[Schedules](../runbooks/schedule-search.md#keyboard-only-compiled-browser-workflows)
evidence for current roles and limits. Browser viewports are not native desktop,
Android, live Agent/provider or screen-reader qualification; full live requirement
`t_38174cb7` remains unmet.

Persona drafts, authoritative reads and explicit revision-aware saves use the
shared profile editor and remain bound to the current Agent channel, host,
profile and exact read/write authority. Owner changes discard the volatile draft;
late completions cannot enter the replacement editor or close its route. An
already-submitted write may still finish at its original Agent. The Profiles
modal also invalidates on management-source changes. Bounded Linux widget and
compiled Chromium evidence is recorded in the
[persona ownership runbook](../runbooks/persona-ownership.md); `t_294eb674` was
independently accepted through executor78 → tester79 → reviewer80. Literal persona
document whitespace is now preserved by the shared decoder, with malformed
content failing closed rather than becoming an empty document. Padded read/save,
conflict recovery and editor reload are executor-verified on `t_5881bb6b`, pending
its same-card independent acceptance. No live Agent/provider or native-device
qualification is implied; full qualification requires source-bound revalidation.

Standalone Persona **Cancel** discards the volatile draft and returns to Profiles.
Successful **Save**, including an unchanged document with zero writes, also
returns there; failures and conflicts remain in the editor. Profiles modal
completion still dismisses only that modal. Late saves cannot replace a newer
owner or a route already chosen during the shell's exit transition. The bounded
`t_d393d318` extension is executor-verified pending a fresh independent default
review: actual-router widgets at 390/1280px, 200% text/reduced motion, and strict
keyboard-only compiled Chromium at those widths and height 1400px cover entry,
cancel, save, recovery and authoritative reopen. Exact receipts, decoded RGB
focus evidence and limits are in the
[Persona lifecycle runbook](../runbooks/persona-ownership.md#standalone-completion-and-keyboard-only-editing).

Tools inventory search is local to the selected Agent client/host/profile and
resets on owner or exact read-authority loss. Same-owner refresh retains it.
Each nonempty skills/toolsets search has its own labeled clear action, with no
extra Agent read or mutation. Search, no-match feedback and resolved-tool
disclosure keep independent semantic boundaries. Linux widget and compiled
Chromium checks pass at 390/1280px, independently accepted on `t_3348dc5c`
(executor62 → tester63 → reviewer64). See the [Tools search runbook](../runbooks/tools-search.md).
Explicit Tools refresh now captures its rendered owner, synchronously rejects
cached controls after selecting/owner/authority loss, and hides inventory controls
while selecting; partial skills/toolsets refresh remains available when settled.
Direct jobs/tools refresh rejects unsettled selection and non-connected state
before optional reads or state/request ownership changes. `t_389042e6` is
executor-verified pending same-card acceptance; its client/widget race evidence
does not qualify a deployed Agent or native device.

Providers searches only already-loaded provider slugs and displayed labels,
without requests or changes to model assignment or Chat ownership. Configured and
available groups retain their relative order. Search and its labeled clear action
are volatile and reset on channel/host/profile or exact read-authority loss,
including same-frame roundtrips; same-owner inventory updates retain the query.
Linux widgets at 390/1280px with 200% text and compiled Chromium journeys pass;
same-card acceptance on `t_f7239dbd` is executor70 → tester71 → reviewer72. See the
[Providers search runbook](../runbooks/provider-search.md) for limits.

Providers now also has strictly keyboard-only compiled Chromium journeys at
390/1280px on `t_8cda73dd`, executor-verified pending same-card independent review.
Actual focus and rendered crops prove editor/clear/shell escape and backward
return; local search leaves main/auxiliary assignments and the exact Chat tuple
unchanged with zero extra reads or mutations. This test/evidence-only extension
adds no provider write support or native/live/screen-reader qualification; see
the [keyboard evidence](../runbooks/provider-search.md#keyboard-only-compiled-browser-workflows).

Chat's existing session-model picker now searches model IDs and provider labels
or slugs case-insensitively, with an independent provider filter and an All
selectable providers option. The confirmed active-session identity is selected
when reopening and appears first, independently of catalog defaults; filtering does
not change the explicit draft selection. **Use for session** waits for Agent
confirmation; rejected writes retain search, filter and selection for explicit
retry. Unconfigured catalog providers remain excluded. The model control is also
reachable in the idle compact composer when supported. This is session-only
selection, not provider setup, profile configuration or inference qualification.
See the [session picker runbook](../runbooks/chat-session-model-picker.md).

Schedules supports pull-to-refresh on its inventory, including short and empty
lists, alongside the labeled refresh button. Refresh remains an exact-scoped
Agent read; repeated input cannot start overlapping reads. Local literal search
matches bounded displayed name, job ID and schedule metadata case-insensitively.
All/Enabled/Disabled filters use the Agent's enabled flag without relabeling job
status. **Clear filters** restores the inventory; no matches is distinct from
an empty inventory or unavailable read. Filters and refresh UI belong to the exact
Agent channel/host/profile and current read authority, resetting even on same-frame
loss/restoration; ordinary inventory/equivalent capability updates retain them.
Cached old-owner refresh/pull/Retry actions and late completions cannot affect the
replacement owner. Search/filtering was independently accepted on `t_8547edd8`
(executor59 → tester60 → reviewer61); the ownership repair `t_1c295a52` was
independently accepted through executor84 → tester85 → reviewer86. Connection and
explicit profile-selection bootstrap now reuse the same exact jobs-read policy
as refresh: supported schema, exact operation/method/path, declared `tasks:read`,
every required grant and supported query context for profile-scoped operations.
Denied optional jobs reads leave the connection usable and Schedules unavailable,
without issuing a jobs request or inventing a read failure. This bootstrap repair
on `t_40a71fac` was independently accepted through executor87 → tester88 → reviewer89;
it adds no job
mutation or selection side effect. Linux widgets and compiled Chromium
fixtures are not deployed Agent/native-device qualification. See the
[schedule search runbook](../runbooks/schedule-search.md) and the
[Hermes Mobile comparison](../research/hermes-mobile-lessons.md).

Profiles distinguishes the active Agent chat from the selected management host.
Its local literal search matches loaded profile ID, display name, description
and model without requests or changes to Chat ownership. The labeled clear action
restores inventory order; no matches remains distinct from empty/unavailable.
Queries reset on management host/client/source or read-authority loss, not on
same-owner updates. Creation and row actions retain full inventory and exact
identities. Linux widget/compiled Chromium checks at 390/1280px were independently
accepted on `t_ca0bbb3d` (executor67 → tester68 → reviewer69); see the
[Profiles search runbook](../runbooks/profile-search.md) for limits.
Profiles additionally has strict keyboard-only compiled Chromium journeys at
390/1280px on `t_2e679eff`, executor-verified pending same-card tester/reviewer
acceptance. Actual focus and rendered RGB crops prove editor/clear/shell escape
and backward return; hiding the active row leaves the exact Chat tuple unchanged
with zero local reads/mutations. The one bootstrap inventory read is host-scoped,
not a profile-query-scoped collection. This test/evidence-only extension adds no
management capability or native/live/screen-reader qualification; see the
[keyboard evidence](../runbooks/profile-search.md#keyboard-only-compiled-browser-workflows).
New-profile setup explains inherited configuration and shows naming rules before
submission. Chat labels the host and names the selected profile in the composer.
The composer menu exposes **Dictate a draft** without requiring a long press.
Hands-free voice shows simultaneous listening and playback with separate labeled
controls. After interruption, **Resume hands-free** requires an explicit tap and
waits for teardown; **Continue in text** dismisses the notice. See the
[profile and voice UI regression report](../quality/profile-voice-ui-2026-09-08.md).

Linux setup shows the reported stage and offers **Stop setup** while running.
An unverified occupied gateway port stops setup before credential/endpoint
configuration or gateway restart. **Check again** performs inspection only; it
does not retry installation automatically. See the
[Linux setup regression report](../quality/linux-setup-port-conflict-2026-09-08.md).

Oversized single-line plain paragraphs use a lazily rendered, grapheme-safe
reader. Selection operates on mounted chunks; use its **Copy as text** action
for an exact full-source copy without chunk boundaries. Markdown-rich messages
retain complete parsing and use measured variable-height block indexing for large
message viewports, avoiding transient mounting of skipped blocks at distant jumps.
Extent measurements reset for width, text scale, theme and source changes, and
visible expansion/collapse remeasures natural layout without forcing guessed
heights. This does not qualify arbitrary large Markdown
or 60-fps streaming; see the
[Linux large-text validation report](../quality/linux-e2e-2026-09-06.md#plain-line-performance-fix).

While a profile switch is pending, Send and New Chat are disabled and the current
draft is retained. Conversation operations reject writes during that transition;
late responses from a previous profile selection cannot overwrite the new one.

New Chat stops targeting the previous session as soon as creation starts. Sending
is unavailable until the new session's initial history request finishes. Delayed
creation or session-selection responses must respect a later selection; a created
session remains discoverable in history without taking over the current chat.

Session history refreshes preserve turns that arrive while a read is pending.
Superseded selection responses are rejected before updating transcript, pagination,
or run-history caches, so an invisible stale read cannot change the next prompt's
loaded context.

Remembered conversations outside the first session inventory page recover through
an exact authorized Agent session read, not a fallback selection or unbounded
page scan. Pending/failed recovery preserves the saved identity and provides
accessible **Retry** and **Choose session** actions; only an actual choice
transfers ownership. Intermediate inventory defaults cannot become writable or
overwrite the pointer. Generic 404 does not imply deletion. See the
[remembered session recovery runbook](../runbooks/chat-session-restoration.md)
for operation/grant gating, race evidence and deterministic qualification limits.

Computer enrollment now completes host installation and pairing before provider
configuration. A confirmed Wing Link pairing offers **Set up a profile**, opening
`/profiles?setup=new` and the transactional new-profile editor after the selected
host's authenticated profile inventory loads. The editor collects provider,
model, and a write-only credential; any required approval remains on the host.
Opening or cancelling it does not create a profile. Existing-profile compatibility
configuration remains unavailable; advertised Agent configuration APIs retain
priority. Wing Link profile management is independent of the Agent chat
connection, while chat still requires a separately enrolled Agent endpoint.

Settings keeps voice configuration on `/settings/voice`, reached through the
**Voice & speech** row. The overview links to Connections and contains appearance,
and links to voice and diagnostics; it does not duplicate the voice switches.
At desktop widths, voice and diagnostics share the column beside appearance.
Profile setup suggestions open toward the available space so options remain
reachable near the bottom of a window or keyboard viewport.

Profiles follows the selected host as saved connections finish loading. Guided
setup opens once after its authoritative inventory becomes available. Failed
Wing Link inventory reads expose Retry without connecting chat or replaying a
mutation. Enrollment changes invalidate displayed management controls, and a
failed enrolled-profile connection leaves Profiles open with an error.

Chat reconciles streamed assistant segments against the current user turn's
canonical reply. Equivalent pre-tool text is replaced by its authoritative
message, while distinct commentary, tool activity, and intentionally repeated
answers in earlier turns remain visible. When canonical history contains both
commentary and a final reply, streamed final text reconciles with the final
assistant segment.

Chat Stop acknowledgment does not unlock the next prompt. An exact advertised
run-status read must confirm a terminal outcome and canonical history must load;
unknown/error outcomes retain ownership and offer **Reconnect**, not duplicate
Retry. Terminal denial/failure also refreshes canonical context for the next
explicit prompt. The [production journey runbook](../runbooks/chat-production-journey.md)
records self-tested compiled Chromium approval/denial/stop/transport-recovery
evidence at 390/1280px pending independent same-card acceptance, not real Agent
generation or Android qualification.
Native approval correlation preserves and returns Agent's exact `request_id`;
stale requests cannot answer a newer FIFO entry, and emitted approval responses
reject in-flight or already-answered reuse. This is deterministic client evidence,
not live scoped-auth qualification.
Cleanup of a rejected cross-session run response confirms only its exact control
resource; it does not admit that session's transcript or history caches.
Uncertain cleanup retains its exact owner even without durable storage; explicitly
selecting that owner still blocks another run until terminal/history reconciliation.

Long conversations initially project the newest 100 eligible loaded turns before
allocating rows. Short tool groups may extend that boundary by at most 100 turns;
longer groups are marked continued. **Show up to 100 earlier loaded turns** reveals
local history separately from **Load earlier messages** fetching Agent pages.
Browsing retains its reading point without expanding for new output; **Latest
activity** recovers the newest bounded view and approval/error actions. Transcript
copy still includes the full loaded history, not just the presentation window.
In the browser, that same transcript action also offers **Save as text** and
**Save as Markdown**, requesting a local UTF-8 download only after an explicit
choice. It snapshots all loaded turns at confirmation, excludes unfetched older
history, uses generic filenames and the copy redaction policy, and rejects large
output without truncating it. No Agent export or artifact read is involved.
Linux also offers those Save choices through the native GTK dialog, rechecking
ownership before writing; other native save/share targets remain unavailable.
Executor native file readback/cancel/owner-change checks and the original Linux
input suite on the named real IBus X11/GTK target pass. Bare simple GTK composition,
complete live-service qualification and same-card independent acceptance remain open.
Disposable actual Agent/Wing Link targets are authorized. Actual generation must
use `gpt-6.1-sol` / `openai-codex`; local-model inference has stopped and supported
private OAuth provisioning is still needed for the isolated target. Permission
alone is not a passing runtime result. See the
[loaded-transcript export runbook](../runbooks/chat-transcript-export.md) for
download readback evidence, size bounds and platform limits.
See the [long-conversation runbook](../runbooks/chat-long-conversation.md) for
Chromium fixture qualification and explicit platform/performance limitations.

Connections owns saved-host management. Selecting a host only changes the management target; **Connect chat** opens its Agent connection explicitly. **Disconnect** closes the local chat connection and clears automatic startup restoration, while preserving saved credentials. It does not stop Hermes Agent or Wing Link. **Remove** forgets saved access locally; **Revoke this device** revokes Wing Link access through the host. Wing Link trust and profile inventory remain available while Agent chat is disconnected. Chat traffic continues directly to Hermes Agent.

Connections health refresh and explicit retry belong to the current Agent channel,
host/profile, selected management host and exact authorized read. Ownership loss
clears pending/failure UI, including same-frame restoration; late completions
cannot disable or fail the new owner. Ordinary same-owner health updates retain
pending state, and repeated pending actions make one read. Shared-loader errors
are not rendered without current bootstrap/action ownership; a screen-lifetime
successful display read prevents stale failures from restoring failure/Retry UI.
Basic-health fallback
and unavailable states remain distinct; no host lifecycle or Chat mutation is
added. Linux widget and compiled Chromium fixture evidence is recorded in the
[Connections health runbook](../runbooks/connections-health.md), independently
accepted on `t_a260473a` (executor75 → tester76 → reviewer77). Full live qualification still requires
source-bound post-slice revalidation on `t_38174cb7`.
The bounded Connections keyboard extension on `t_88121eee` is executor-verified,
pending same-card tester/reviewer acceptance: Refresh/Retry, pending single-read
recovery and named shell escape/return use keys alone after fixture bootstrap.
A regression-first semantic merge preserves Refresh focus and its disabled
button identity without changing Chat or read authority. Linux widget and compiled
Chromium 390/1280px, height 1400px, evidence and qualification limits are in the
[keyboard runbook](../runbooks/connections-health.md#keyboard-only-compiled-browser-workflows);
no native/live/screen-reader or full-goal support is added.
