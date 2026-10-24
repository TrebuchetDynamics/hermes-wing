# Routes

Current clone reference: `14e1e43a23761b369641208e204365cd6cb9399d`.
Settings search opens a dismissible search surface for implemented local categories
and controls. Appearance now separates Theme and Typography; its parent selects
the first implemented child, while its caret only expands/collapses navigation.
Compact Settings uses one hierarchical selector for categories and their supported
children. Both layouts show a wrapping Settings/category/page breadcrumb; its
parent opens the first supported child. The wide navigation marks only the
current leaf as selected. Automatically revealed branches fold when leaving,
while deliberately expanded branches remain open.
Search and saved links accept `page=theme|typography` and the official
`setting=theme|chat-text-scale` targets. A setting selects its owning page even
when a saved page disagrees. Category changes clear stale page/setting/field
parameters and preserve unrelated query parameters. Cancellation preserves the
current selection; an older search cannot replace newer navigation intent.
Unsupported settings are not indexed. The remaining Desktop tree and field
targets remain pending. The local creature-family picker has
been retired without deleting saved preferences; contacts use official static
fallback profile shapes/colors, without claiming full BotFace metadata/animation.
Provider inventory and model actions retain independent authorization. Legacy
credential Set/Remove/Validate are unavailable even when their route grants exist:
no eligible credential identity/revision/idempotency/effect-consent contract is
implemented. The retained sheet entry point collects no secrets.

The only Desktop product reference is [Nous Research Hermes Desktop](https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop),
locally `hermes-agent/apps/desktop/`. Prior separate-app comparisons are
[withdrawn as official parity evidence](../quality/official-desktop-reference.md).
Existing Wing test results do not establish parity with this corrected reference.

Local / SSH / Remote connect directly to Hermes Agent. Android welcome order is
SSH, Remote, then Termux. Linux Local uses metadata-only Hermes-home discovery and
a deliberate alternate-folder chooser; it does not install/start Agent or select
a Project. Legacy handoff input is discarded with generic reconnection guidance.
Saved Agent credentials and identities survive; missing credentials require direct
reauthentication. No management client/service/catalog or legacy mode is offered.
Fixtures do not establish Android, native/live authentication or installation support.

Saved-connection Chat activation in Connections, Providers, Tools and Schedules
uses typed connection-failure guidance: rejected authentication identifies the
exact endpoint/profile token (not a provider key), while address, response, network,
TLS and timeout failures keep their distinct recovery instructions. Raw transport
responses are never displayed. Failed activation does not retry or resend work.

Connection entry no longer offers QR creation or scanning. SSH opens a compact
form; optional Agent port/profile, transport and destination save/load sit under
Advanced. Hidden values retain validation, and host-key verification and secure
credential storage are unchanged. Android gateway browser sign-in remains manual.

Hermes Wing uses one adaptive route tree. Compact Chat prioritizes the transcript and composer without a persistent bottom bar; its header menu keeps all existing destinations and current connection status reachable, including saved-contact Chat. Other compact feature routes retain Chat, Profiles, Connections and More in the bottom bar. This is a mobile adaptation of official Desktop's Chat-home hierarchy (`apps/desktop/DESIGN.md`, information architecture), not full navigation parity. Desktop and wide web separate **Workflow** (Chat, Schedules) from **Utilities** (Providers, Connections, Tools, Profiles, Persona, Settings) in the sidebar. All eight working destinations remain explicit, named and route-selected when expanded or icon-only; short windows scroll the groups while keeping the collapse control available. Routes are added with working vertical slices, so approved entries may remain planned until their capability lands. See the [desktop navigation runbook](../runbooks/desktop-navigation-groups.md) for evidence and deliberate Desktop differences.

| Route          | Android placement | Purpose                                                                                                                                                                                                                                                                                            | State       |
| -------------- | ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `/hermes`      | Chat              | Connection, paginated Agent-owned session and transcript history, runs, voice, approvals, and diagnostics.                                                                                                                                                                                          | implemented |
| `/discover`    | Discover          | Skills and MCP discovery.                                                                                                                                                                                                                                                                          | planned     |
| `/tasks`       | More              | Gateway-scoped scheduled-job inventory with refresh and recovery. Agent mutation routes are not yet advertised as exact scoped operations, so create/edit/pause/run/delete controls and Kanban remain hidden.                                                                                                                                                                  | partial     |
| `/profiles`    | Profiles              | Profile inventory and lifecycle, provider/model autocomplete through exact advertised Agent operations; remote folder browsing is unavailable (`/agents` redirects for compatibility). Project creation remains unavailable until Hermes Agent advertises a suitable machine-readable operation; Project-aware Chat is separately gated. | partial     |
| `/soul`        | More              | Standalone profile persona editor, available only when the selected Agent advertises exact scoped SOUL read/write operations.                                                                                                                                                                  | partial     |
| `/enroll`      | (deep link)       | Direct Agent welcome: desktop/web Get Started, SSH and Remote; Android SSH, Remote and Termux. Legacy `?step=pair` and intent/share inputs show accessible generic reconnection guidance without parsing/exchange, Link construction or raw payload display. Warm cancellation preserves the caller and draft. Fixture checks are not physical Android or live authentication qualification. | implemented |
| `/setup/local` | enrollment        | Linux reuses Local metadata-only Hermes-home discovery, deliberate folder selection and direct Agent authentication. Android/Termux reuses the Local manual Agent guide and direct authenticated form. Neither installs/starts a service, returns to pairing or claims automatic readiness. Native installation and live authentication remain unqualified. | partial |
| `/providers`   | More              | Capability-gated provider inventory, write-only API-key management, credential validation, runtime-model inventory, and model assignment through advertised Agent operations. OAuth providers are labeled as host sign-in rather than opening an API-key form; remote OAuth and multi-credential flows remain contract-gated.                                                            | partial     |
| `/tools`       | More              | Gateway-scoped searchable installed-skill metadata and resolved toolsets with exact-scoped refresh; mutation, MCP administration, and discovery remain contract-gated.                                                                                                                             | partial     |
| `/memory`      | More              | Memory entries, profile, capacity, and providers.                                                                                                                                                                                                                                                  | planned     |
| `/gateway`     | Connections       | Saved hosts, explicit chat connect/disconnect, bounded Agent health, connection editing/removal, without Wing Link device trust/revocation; lifecycle, logs, peer administration, and messaging-platform administration remain contract-gated.                                                                      | partial     |
| `/settings`    | More              | Link to Connections, appearance, supported spellcheck, voice, and redacted diagnostics; also selected by Ctrl/Command+, and bounded Linux/Windows/macOS native Settings menu commands.                                                                                                        | implemented |

Profile switching and session history remain directly reachable from Chat. More is an action sheet, not a route.

Chat also offers **Files** in its compact overflow menu and wide toolbar; it is a
dismissible read-only surface, not a new route or a Project folder picker.
Native Linux/Android serve readers require an advertised locked managed root.
Unlocked, messaging-only and browser connections show unavailable without a
fallback browser. Bounded literal text previews and explicit retry preserve the
owning connection/profile/conversation context. Individual downloads up to 8 MiB
use authenticated raw bytes, Linux Save As or Android document creation, explicit
cancellation/retry and final saved-byte readback before success. Browser saving is
not offered. Real Linux/Android picker and live-Agent qualification remain pending;
fixtures and APK compilation are not native save receipts. See the
[managed Files contract and evidence](../quality/managed-files-browse.md#individual-download-extension--files-terminal-download).

Chat's compact More actions menu and wide header offer **Bot Chat** for the
selected profile through verified native registry, hidden-state and history/replay
operations. REST and unsettled native conversations show an explicit gap; native
multi-tab qualification is unchanged. See the [bounded Bot Chat behavior and limits](../quality/android-canonical-bot-chat.md).

Compact Chat uses the same below-600px header threshold as the compact shell.
Its composer exposes draft dictation and Live voice as distinct named controls,
without a duplicate hands-free microphone or a separate Live entry row. Phone
introductory voice tips no longer occupy transcript space; secondary settings and
all original actions remain reachable. Wide presentation and Agent ownership are
unchanged. See [compact usability evidence](../quality/mobile-chat-simplification.md)
for checks and physical-device qualification limits.

Standalone Office and its local slash action are retired, not replaced with Bots.
Obsolete `/office` URLs use the existing Page not found screen and explicit Return
to chat recovery; opening that URL does not activate a contact or mutate Agent state.
Shared gateway contacts, credentials, profiles and exact-session restoration are
unchanged. See the [offline retirement receipt](../quality/office-retirement.md).

Chat's shared connection form now groups **Local**, **SSH** and
**Remote** as three primary choices. Remote contains **Remote HTTPS** and VPN /
NetBird / Tailscale subchoices. Selecting SSH does not launch OpenSSH. The
[entry-label receipt](../quality/connection-entry-labels.md) records bounded
widget and compiled-browser checks, not native/Android qualification. Existing setup/enrollment
routes are reused. Route presence does not establish managed SSH or remote OAuth.
See the [connection comparison](desktop-connection-paths.md) and
[requirements](prd.md#connection-path-requirements).

Expanded desktop/wide-web sidebars also expose **Loaded sessions** with exact
**Open** and explicit **New Session** actions from working feature routes. This
bounded surface uses only the current owner's loaded inventory and navigates to
Chat after acknowledged success; collapse removes its controls from focus and
semantics. Compact Chat retains the full route-local picker. The later
[global session modal](../quality/global-session-modal.md) adds Sessions and
Ctrl/Command+K over feature routes. It reuses loaded search, pins, explicit
pagination and gated management without mounting Chat or adding opening reads.
Escape/Close restores focus; exact activation navigates only after acknowledgement.
Its deterministic widget/Chromium evidence does not qualify native/live use or
screen readers. The original loaded-section executor
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
The wide composer also places a keyboard-operable **Dictate a draft** button
between attachment and model controls. **Cancel draft dictation** discards pending
recognition and preserves the draft; Send and hands-free remain separate actions.
Owner or voice-gate changes reject stale callbacks and late recognition. See the
[bounded delivery evidence](../quality/chat-direct-dictation.md); browser recovery
is qualified only for unavailable capture, not physical recognition.
Chat exposes **Start Live voice** directly beside the composer. It starts the
existing recognition → Agent turn → speech-playback loop; it is not a realtime
voice-model transport. If saved spoken-reply consent is off, an explicit dialog
explains continuous listening, automatic sends and speech for this session only;
starting or ending Live voice never changes that preference. Missing capture or
playback services block entry with a text fallback. Dictation remains separate.
Live voice displays listening, reply playback, interruption listening and microphone
mute. Recognition re-arms after silence even while playback remains pending;
non-echo partial speech stops output while collecting the next turn. Speech mute
and microphone mute are independent, and **End · return to text** preserves the
draft. Foreground/session/voice-gate loss ends the local loop; resumption requires
an explicit action. See the [Live voice receipt](../quality/chat-live-voice.md)
for deterministic checks and acoustic/device exclusions. The earlier
[profile and voice UI regression report](../quality/profile-voice-ui-2026-09-08.md)
remains historical evidence.

Linux Local setup now opens the existing direct Agent form. Hermes-home discovery
checks directory metadata only; the native folder chooser does not save the path,
read Agent files, select a Project or bind the running Agent to that home.
Prepare and start Agent outside Wing, then authenticate explicitly. Back/cancel
does not modify saved connections; denial stays in the direct flow with no service
or pairing fallback. The earlier
[Linux setup regression report](../quality/linux-setup-port-conflict-2026-09-08.md)
describes the retired service consumer, not current setup behavior.

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
the selected transport's authorized exact-session read. The bounded Linux native
serve path separately restores a deliberately enabled conversation through its
secure origin/profile/stored/runtime pointer and public Retry; see the
[restoration receipt](../quality/local-serve-restoration.md). Gateway recovery uses
an exact authorized Agent session read, not a fallback selection or unbounded
page scan. Pending/failed recovery preserves the saved identity and provides
accessible **Retry** and **Choose session** actions; only an actual choice
transfers ownership. Intermediate inventory defaults cannot become writable or
overwrite the pointer. Generic 404 does not imply deletion. See the
[remembered session recovery runbook](../runbooks/chat-session-restoration.md)
for operation/grant gating, race evidence and deterministic qualification limits.

Profile inventory, lifecycle and model suggestions require exact advertised Agent
operations and authorization. Former host approval, directory grants and management
catalog reads are unavailable. No setup fallback or host write is inferred.

Settings keeps voice configuration on `/settings/voice`, reached through the
**Voice & speech** row. The overview links to Connections and contains appearance,
and links to voice and diagnostics; it does not duplicate the voice switches.
At desktop widths, voice and diagnostics share the column beside appearance.
Profile setup suggestions open toward the available space so options remain
reachable near the bottom of a window or keyboard viewport.

Profiles follows the selected Agent owner. Explicit read retry never connects Chat
or replays a mutation; owner changes invalidate cached controls.

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
Disposable actual Agent targets are authorized. Actual generation must
use `gpt-6.1-sol` / `openai-codex`; local-model inference has stopped and supported
private OAuth provisioning is still needed for the isolated target. Permission
alone is not a passing runtime result. See the
[loaded-transcript export runbook](../runbooks/chat-transcript-export.md) for
download readback evidence, size bounds and platform limits.
See the [long-conversation runbook](../runbooks/chat-long-conversation.md) for
Chromium fixture qualification and explicit platform/performance limitations.

Connections owns saved-host management. Selecting a host only changes the inspection target; **Connect chat** opens its Agent connection explicitly. **Disconnect** closes the local chat connection and clears automatic startup restoration, while preserving saved credentials. It does not stop Hermes Agent or any host service. **Remove** forgets saved access locally. Connections does not read legacy trust or offer device revocation, even when inert legacy credentials remain saved. Missing Agent lifecycle, logs and peer-management contracts remain unavailable; no replacement management service is simulated. Chat traffic continues directly to Hermes Agent. See the [bounded removal receipt](../quality/connections-agent-only-follow-through.md) for checks and exclusions.

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
