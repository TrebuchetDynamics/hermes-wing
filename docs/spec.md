# Hermes Wing technical design

The only Desktop product reference is [Nous Research Hermes Desktop](https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop),
locally `hermes-agent/apps/desktop/`. Prior separate-app comparisons are
[withdrawn as official parity evidence](quality/official-desktop-reference.md).
Existing Wing test results do not establish parity with this corrected reference.

Status: current implementation map with explicit qualification limits.
This document owns the cross-component design overview, not Agent API schemas
or new architecture decisions. [Product requirements](product/prd.md) own intent;
[living ADRs](adr/README.md) own architectural constraints.

## Away-and-return status design

Status: planned Android qualification and bounded repairs, not shipped support.
The [user-demand acceptance](product/prd.md#user-demand-emphasis) prioritizes
reliable return and visible Agent-owned job outcomes before notifications.
Reuse `hermes_chat_lifecycle.dart` resume/recovery and unread-completion paths,
the production channel, and existing transcript/restart fixtures. Do not add a
second job store, background mutation queue or a client-owned execution service.
Canonical Agent reads settle identity/history/outcomes after return; stale-owner
reads cannot update a replacement owner. Connectivity loss leaves outcome unknown
until authoritative reconciliation. Suspension is not an instruction to cancel.
The [Android matrix](test-plan.md#away-and-return-status-verification) owns the
next qualification slice. Notification enrollment/delivery remains governed by
the [existing proposal](product/notification-contract-proposal.md), not this design.

## Approval withdrawal in the internal lifecycle adapter

`HermesWebLifecycle` handles `request.cancel` before the running-turn gate.
An ordered event for the owned runtime session removes the matching server-request
ID even when no local turn is running. It notifies observers without answering
or replaying the request. Profile, session and sequence admission still apply.
This internal qualification adapter is not the production `HermesApiChannel`.
The implementation at `8866604b` does not establish production wiring, live
acceptance, native qualification or delivery on main. Existing fixture receipts
qualify only their recorded inputs, not this later change.

## Profiles removal candidate

[The Agent-only Profiles candidate](quality/profiles-agent-only-follow-through.md)
removes Link inventory/catalog/configuration callbacks from one isolated branch.
The canonical Profiles source still retains its fallback. Exact advertised Agent
operations remain gated; unavailable profile configuration is not simulated.
The reviewed correction removes the post-editor directory refresh that recovered
pending legacy credentials after Cancel/save. Agent mutation reconciliation remains
owner-fenced. The bounded slice passed independent review on its isolated source.
Full analysis still fails on excluded fixture/import inputs. Widget evidence and
review approval do not qualify the canonical tree, native/live use or main delivery.

## Android qualification environment

Waydroid is the selected Android QA environment. It runs Android in a Linux
container, not in the native Linux Flutter host. The Android APK, plugins and
Maestro driver remain Android components. Container availability, ADB access,
app launch and successful journeys are separate evidence levels. See the
[qualification procedure](runbooks/desktop-feature-qualification.md#android-maestro-fixture-run).
No transport, Agent capability or physical-device guarantee follows from this
target selection.

## Android private release packaging

[`android/app/build.gradle.kts`](../android/app/build.gradle.kts) selects the
`.qa.release` application ID suffix when `WING_PRIVATE_RELEASE_TEST=1`.
Configuration fails unless all release signing values create the release signing
configuration. Without that opt-in, local release smoke builds retain the existing
debug-signing fallback; those artifacts must not be distributed.

The private identity is separate from the paired app and opt-in `.qa` debug app.
It changes packaging, not Agent ownership, credentials or runtime capabilities.
The [private APK handoff](runbooks/android/release-handoff.md#private-release-apk-handoff)
owns build and artifact checks. Device execution and integrated recovery remain
separate qualification requirements.

## Components and state

The [secondary mobile study](quality/hermes-mobile-reference-study.md) identifies
possible improvements to existing lifecycle, rich-text and tool-grouping seams.
It adds no transport, persistent transcript store, plugin contract or runtime patch.
Notification and active artifact candidates remain proposals, not implementation
claims. The study records source provenance and incompatible reference patterns.

Wing Link is deprecated by the [product decision](adr/product.md#wing-link-deprecation).
The component map below describes retained code, not a requirement to keep two
backends. Remove management-dependent product paths before retiring service and
installer packaging. Missing Agent capabilities must be explained, not emulated.
Linux Hermes-home discovery and Android same-phone setup are the planned Local
replacement. Discovery is not authenticated runtime readiness. Preserve profile,
session and credential ownership during migration.

The [port-wide fidelity requirements](product/prd.md#port-wide-fidelity-acceptance)
govern presentation and behavior across these components. Desktop supplies the
welcome flow, screen structure, terminology, layout, visual hierarchy and interaction
reference. Reuse Flutter providers and channels rather than copying Electron internals.
Agent authority and optional management remain independent of presentation fidelity.

The current development worktree gates fresh `/hermes` entry through
[`ConnectionEntryGate`](../lib/router/widgets/connection_entry_gate.dart) before
exposing the connected shell. Empty secure storage shows
[`HermesWelcome`](../lib/features/enrollment/widgets/hermes_welcome.dart): the
settled emblem, title, Get Started and SSH/Remote actions. Get Started opens
Local direct connection; SSH uses Wing-managed authentication. Its attempt-scoped private-key
selection path has passing production-control regressions, not native qualification. Unreadable
storage offers explicit Retry instead of treating the owner as absent. Saved
ownership bypasses welcome; auxiliary routes remain available independently.
The [welcome receipt](quality/desktop-welcome.md) records widget and compiled
Chromium qualification. The [welcome recovery receipt](quality/desktop-welcome-recovery.md)
adds isolated Linux GTK keyboard Back, sanitized denial, explicit retry and
fresh-process restoration. Welcome-entry forms use widget-order focus traversal
so enlarged, scrolled fields do not make keyboard Back inaccessible. The synthetic
endpoint store does not qualify physical keychain persistence. Android, live
authentication and protected-main delivery remain open. Static branding,
local-running-Agent guidance and optional setup remain recorded Desktop differences.

- The Flutter client composes product screens under `lib/features/`.
  [`routerProvider`](../lib/router/providers/app_router.dart) uses GoRouter and
  `AppShell`. The [route ledger](product/routes.md) records availability and
  unsupported actions; route existence alone does not prove capability support.
- Wide-shell presentation uses scoped roles in
  [`app_shell_desktop_style.dart`](../lib/shared/widgets/app_shell_desktop_style.dart).
  The committed reference redesign preserves compact navigation and session authority.
  See the [shell receipt](runbooks/desktop-shell-reference-fidelity.md) for explicit
  accessibility differences, exact-tree checks and remaining composition gaps.
- [`wingSidebarExpandedProvider`](../lib/features/settings/providers/shell_preferences_provider.dart)
  owns the shell's local persisted expansion choice. `AppShell` consumes it without
  copying Agent state. Loading cannot overwrite a newer click, and saves are
  serialized. The [graph-guided receipt](quality/graphify-shell-persistence.md)
  qualifies widgets and fresh provider scopes, not native process relaunch.
- [`hermesChannelProvider`](../lib/features/hermes_chat/providers/hermes_channel_provider.dart)
  constructs `HermesApiChannel`. A reactive provider projects its immutable
  `HermesChannelState`. Connection status, selected profile/session, capabilities,
  optional-resource errors, history and model locks belong to that projection.
- [`HermesApiChannel`](../lib/core/hermes/channel/hermes_api_channel.dart)
  coordinates connection, inventory, sessions, profile/model selection,
  messaging and approval handling through its `api_channel/` parts.
  `HermesApiClient` and platform transports implement Agent requests.
  [`HermesSseEventDecoder`](../lib/core/hermes/sse/hermes_sse_event_decoder.dart)
  decodes streamed events. This is the direct Agent data plane.
- [`WingLinkClient`](../lib/core/wing_link/wing_link_client.dart) is the separate
  host-management client. The Go service under `wing_link/` owns management
  protocol handling, local approval, operation journals, directory grants and
  release activation. It does not own Agent sessions, runs or chat history.
  The [Wing Link design](product/wing-link.md) owns its detailed behavior.
  The [OpenAPI snapshot](api/wing-link.openapi.yaml) documents management and
  separately identified ephemeral pairing-broker routes. It is manually
  maintained from Go handlers, not generated or schema-first authority.
  Its declared parser and security limits require source review when routes change.
  Wing no longer bundles or manages OmniRoute: installer, discovery, release
  component and special profile-setup paths are removed, with no user-data
  migration. Generic Agent-owned catalog entries remain unfiltered.

Hermes Agent remains authoritative for domain state. Profile and session IDs
are resource identities, not display names or inventory positions. A Hermes
Project is Agent-owned; directory grants do not create a Wing-owned workspace.
See [API and state](adr/api-and-state.md) for exact operation/grant gating,
concurrency rules and the bounded setup-catalog exception.

## Existing-profile credential contract gap

Current direct `HermesApiClient` Set/Remove/Validate methods and
`ProviderCredentialSheet` dispatch already exist. Their request shapes use
provider/profile and environment-variable identity, not the opaque credential IDs,
expected revisions and idempotency required by the
[mutation acceptance contract](adr/api-and-state.md#required-agent-owned-mutation-contract).
Source presence and exact capability gates do not qualify those stronger guarantees.
`DOC-M3-PROVIDER-CONTRACT` owns the current caller/test comparison and bounded
fail-closed correction assessment. This documentation pass changes no controls,
reads no credentials and does not establish a runtime vulnerability or safe mutation.

## Terminal working-directory files (planned design)

The [feasibility study](analysis/terminal-files-feasibility.md) traces existing
Agent routes and official Desktop consumers at a pinned revision. This section
describes a proposed client integration, not shipped Wing support.

- Use the owning authenticated `hermes serve` connection for `/api/fs/list`,
  `/api/fs/read-text`, `/api/fs/download` and `/api/fs/default-cwd`. The messaging
  API transport and a successful chat connection do not establish these contracts.
  Do not route file traffic through Wing Link or add an Agent patch or plugin.
- Keep connection, profile, session and filesystem-backend identity explicit.
  Prefer authoritative session cwd. List/read-text have no session parameter.
  A local default-cwd read with `profile=` alone does not establish secondary-profile
  root selection. Do not substitute the Wing device or server host directory for
  an unqualified remote execution environment.
- Enable an operation only after its authentication, root and backend are qualified.
  The existing filesystem adapter selects configured SSH workspaces; it does not
  establish Docker, Daytona, Modal or other terminal-backend access. SSH tunnelling
  to Agent and Agent's own SSH terminal backend are distinct cases.
- Canonical path resolution and download session ownership are not cwd confinement.
  Qualify an existing server-enforced boundary aligned with the selected root.
  Hiding parent navigation or checking a lexical prefix is not symlink protection.
  Where the strict boundary cannot be established, explain the unsupported operation.
- Keep transport/domain behavior in existing core client/channel seams and feature
  presentation under `lib/features/`. Reject late results after an owner switch.
  Bound requests, listings and previews without creating shadow Agent state.
- Preview supported text as selectable, inert content. Download original bytes,
  not preview text. Stream with authenticated headers; never put credentials in
  a download URL. Linux Save As and Android document-save integration need explicit
  destination consent, cancellation, safe partial-save handling and byte readback.

The [test plan](test-plan.md#terminal-working-directory-files-planned) owns
qualification. Starting a service or changing a managed-root configuration requires
separate operational authorization; this planned integration performs neither.

## Connection and daily-use flow

Required direction: Local connects directly to Agent. Native SSH uses a
Wing-managed forward. Remote uses direct supported Agent authentication.
No path requires Wing Link installation, pairing or credentials. Direct Agent
transport already exists. Primary direct first-run access is implemented in the
current development worktree with bounded Linux widget/Chromium and GTK fixture
qualification. Main delivery, Android and live authentication remain separate gaps.
Native managed SSH is implemented in the development worktree using Dart TCP
forwarding and an app-scoped controller. The form exposes explicit key/password
selection and encrypted-key input. Selected content is limited to 64 KiB. Late
picker results cannot restore a cancelled or replaced selection. Imported keys
remain attempt-scoped. The owner-requested generated Ed25519 identity is stored
separately in platform secure storage, with validated readback, application-isolate
serialization and reuse without replacement. Consent precedes creation; public-only
copy and deliberate saved-key selection feed the existing credential path. Storage
errors fail closed without plaintext fallback. Generated identity persistence is
not saved SSH connection restoration. Production-control regressions pass, but
native storage and full-app qualification remain open. The
[generation/Local/Help receipt](quality/connection-key-generation-help.md) records
132 focused-union tests and clean analysis. See the
[key-UX comparison](product/desktop-connection-paths.md#private-key-ux-desktop-reference-and-wing-adaptations)
and [pinned source comparison](quality/graphify-wing-recomparison.md) for the
attempt-scoped Linux file picker and Android document-picker acceptance.
Neither terminal OpenSSH nor widget tests qualify those native application paths.

1. Select an explicit endpoint and authenticate to Hermes Agent. Pairing and
   optional host management use a separate Wing Link connection and credential.
   Failure or absence of that management connection must not gate Agent access.
2. Discover capabilities and load supported resources. Unsupported, empty and
   failed optional reads are distinct states in `HermesChannelState`.
3. Select the profile, session and supported provider/model operation. Resource
   requests and late-result checks must retain the current owner identity.
4. Submit through the selected Agent transport. Display streamed text, tool and
   approval activity through the channel state and event contracts.
5. Respond to an approval for its exact request/run owner. Stop must target the
   actual run; a local stream closure is not proof of Agent cancellation.
6. On return or reconnect, reconcile authoritative history and run state before
   another deliberate send. Cached reads and drafts are not replay authority.

These steps describe design and required outcomes, not a passing integrated
workflow. The [Desktop daily-use plan](plans/2026-10-03-desktop-daily-workflow.md)
owns its exact acceptance matrix. The [parity ledger](product/hermes-desktop-parity.md)
records unresolved exact-pair restoration and live qualification. The
[native relaunch receipt](quality/native-relaunch-workflow.md) records two real
Linux GTK processes under Xvfb, isolated preferences and exact off-page history
restoration without replay. The [combined native receipt](quality/native-model-relaunch-workflow.md) now
exercises model acknowledgment, approval and Stop together before restart.
Restoration retains model text but not confirmed provider identity: the picker
requires deliberate choice and never substitutes a catalog default. Exact-pair
readback is unsupported. The later [resumed-send receipt](quality/native-resumed-send.md)
qualifies explicit reselection and one send to the restored exact session across
two Linux GTK processes. Restart and route reopening add no mutations. This is
synthetic qualification, not live generation, full-shell startup or main delivery.

The later [integrated restart receipt](quality/native-integrated-daily-restart.md)
qualifies the production router, shell and HTTP/SSE channel together against a
loopback synthetic authority. At compact and wide widths with 200% text, two
processes per width exercise off-page selection, correlated approval, uncertain
Stop, canonical recovery and one deliberate resumed send. Restart and route
return add no mutations. Unknown provider/model identity still requires explicit
reselection. This frozen Linux GTK candidate does not qualify live authentication,
inference, physical input, screen readers or protected-main delivery.

The separate [live-workflow entry](quality/live-desktop-daily-workflow.md) implements
stdin-only authorization and a bounded read-only capability preflight. Its optional
native readiness target uses the production client and denies every mutation seam;
that target has been analyzed, not executed against an actual Agent. A two-phase
production Chat driver is prepared for explicit model selection, correlated approval,
Stop and exact-session relaunch. `requireQualifiedLiveBudget` refuses that driver
before network access, including direct native invocation. Mutation-attempt counters
cannot bound provider calls from tool/approval continuations. The later
[provider-call boundary assessment](quality/live-provider-call-ceiling.md) finds no
supported enforceable three-physical-attempt limit in the inspected unmodified
Agent interfaces. Retries, grace calls and auxiliary work invalidate a submission
or iteration ceiling. Its isolated branch qualifies executable refusal, not an
inference quota. The live driver stays disabled. Actual two-process GTK/live
qualification remains open within M1; QA authentication alone cannot enable it.

The separate [credential-free shell smoke](quality/native-no-inference-smoke.md)
uses production shell/channel components with synthetic in-process reads and all
mutation transports unsupported. It is not the disabled actual-Agent journey.
The same-card correction supersedes its initial receipt, which omitted an
analyzed input and captured excluded local tool state. The corrected launcher
captures complete source before execution and rejects linked inputs. A fresh
retained run records two distinct GTK processes, persisted synthetic owner/history
restoration and keyboard recovery with zero mutations. All 1,065 archived input
hashes match the manifest and executed hashes. The shared helper/tests still
differ from the reviewed overlays. This qualifies that frozen synthetic Linux
candidate, not current-tree parity, live inference or protected-main delivery.

The later [denied-read restart receipt](quality/native-no-inference-auth-recovery.md)
extends that frozen candidate to four GTK phases, including synthetic 401/403
history denial after restart. Production restoration retains the exact saved
owner; public keyboard Retry restores canonical history only after read authority
recovers. Cancelled and wrong-owner history cannot settle. All 1,067 archived
inputs match the executed hashes, with zero mutation or management requests.
Shared live helper/tests differ from the reviewed overlays. This is credential-free
Linux fixture qualification, not live authentication, inference or main delivery.

The [bootstrap-denied successor](quality/native-no-inference-bootstrap-recovery.md)
adds two fresh GTK processes with required-capabilities 401/403 before usable
inventory or history. Startup, mount and deliberate repeated denial issue only
health/capabilities reads. Saved ownership survives; public keyboard Retry restores
canonical exact-session history after synthetic authority returns. Six native phases
pass with zero mutation/provider/management counts. The retained archive matches
all 1,068 executed inputs. This is frozen-source synthetic Linux qualification,
not live authentication, generation, packaged execution or main delivery.

The later cleanup correction also owns preparation child groups and bounds Git
reads, archive creation and SDK copy. Cancellation covers preparation through
state cleanup; repeated signals cannot interrupt teardown. Its synthetic launcher
checks qualify cleanup, not native readiness or actual-Agent execution.

The [internal two-process runner](quality/live-two-process-orchestration.md) has
synthetic Linux lifecycle evidence for shared state, distinct driver/app processes
and teardown before deletion. Unconfirmed teardown preserves state and refuses.
The later [display authentication branch](quality/live-display-isolation.md)
adds an ephemeral owner-only Xauthority file and bounded X protocol admission:
correct authorization succeeds; absent or wrong authorization fails before phases.
It disables TCP and retains the owned display through both phases. This evidence
belongs to that isolated branch, not the shared helper, which still matches the
runner's predecessor. Display authorization does not isolate hostile same-UID
processes or root, qualify GTK/live Chat, or enable inference.

Chat requires an explicit catalog choice when no acknowledged session pair is
available. It does not preselect the profile catalog default as session identity.
A known acknowledged pair still seeds the picker; Cancel does not change it.
The inspected Agent session GET exposes model text and `has_model_config`, not
provider identity or the confirmed pair. No restoration read or shadow lock cache
was added. See the [bounded picker delivery](quality/session-model-pair-read.md).
Exact-pair restoration remains unsupported by those advertised reads.

## Shell composition

The [native status repair](quality/native-status-accessibility.md) makes desktop
status fields keyboard-focusable. Enter or Space toggles complete labeled values
in an inline wrapping layout. Compact More uses the same status widget, initially
expanded, and updates from the current channel while the sheet is open. Rendered
and semantic values remain redacted; recovering/error states do not present cached
profile/model values as current. Status inspection adds no domain operation.
Retained Linux GTK fixture evidence covers compact/wide layouts and enlarged text,
not live authentication, physical input, screen readers or main delivery.

The [passive footer implementation](quality/profile-footer-implementation.md)
delivers the bounded slice from the
[composition brief](quality/profile-footer-composition.md) and
[next-port contract](quality/desktop-next-port-slice.md). The desktop shell keeps
the footer below scrollable navigation in expanded and compact modes. It derives
a redacted, bounded profile label from the current channel display projection.
Manage profiles navigates to Profiles without reading inventory or changing
profile/session state. It is not Edit or Switch; the destination retains its
own operation gates. Retained widget and compiled-browser evidence is scoped
to this slice, not native or full composition parity.

The [source-grouped recents delivery](quality/grouped-recents-implementation.md)
projects loaded rows by exact source in first-encounter order. Rows retain their
in-group order and existing exact-owner Open/New gates. Semantic headings use
bounded redacted labels. Presentation adds no reads, sorting, persistence or
group disclosure. This is an intermediate adaptation, not Desktop Project/folder
grouping. The [recovery receipt](quality/grouped-recents-recovery.md) adds keyboard
hide/return and pending-owner rejection through existing sidebar lifetime controls.
Source headings remain noncollapsible. The later
[native recents receipt](quality/grouped-recents-native.md) exercises the production
shell and HTTP channel in an isolated Linux GTK app under Xvfb. It qualifies
injected keyboard traversal, adaptive viewport return and obsolete-owner rejection,
not OS minimization, physical input, full feature screens or live/screen-reader behavior.

The [global session modal](quality/global-session-modal.md) reuses
`HermesSessionsPanel` over feature routes through Sessions or Ctrl/Command+K.
Opening and local search use already-loaded inventory, with no Agent reads.
Explicit pagination and mutations retain exact operation gates. Activation closes
the panel and routes to Chat only after exact-session acknowledgement.
Owner/resource/route loss invalidates pending callbacks, including change-away-and-back.
Escape/Close restores the surviving opener's focus; traversal stays inside the dialog.
If New acknowledges a session but its history read fails, Retry selects that same
session and repeats only the read. A failed unacknowledged creation has no generic
retry because no verified creation-replay contract exists. Owner replacement
invalidates the retry before navigation or I/O. See the
[review correction](quality/global-session-modal.md#independent-review-correction-new-recovery).

The [adaptive panel receipt](quality/global-session-modal-adaptive.md) records
compact/wide keyboard access with 200% Flutter text and separate Chromium zoom
under reduced motion. The shared panel stacks its title/New header and uses one
scroll surface for controls and lazy rows. Current-panel focus is revealed after
layout, including resize; Close stays outside the scroll surface. These changes
also apply to the route-local Chat sheet and add no domain operations.

Split edit/switch controls, the global profile shortcut and Project grouping remain
gaps. The later [native panel receipt](quality/global-session-modal-native.md)
qualifies injected keyboard traversal, enlarged text, adaptive viewport return,
explicit read retry and stale-owner rejection in Linux GTK under Xvfb. Feature
route bodies are synthetic placeholders. Live profiles, physical input and screen
readers remain unqualified. Existing loaded Open/New must not be ported again.
No new Agent or Wing Link contract is introduced.

## Draft dictation design

The [enlarged-text composer qualification](quality/chat-composer-accessibility.md)
adds local widget-order traversal so text scaling cannot reorder supported commands.
Compact Send/microphone switching has zero transition duration under reduced motion.
The E2E wrapper preserves the platform reduced-motion setting. No capability or
Agent/Wing Link operation changes. Bounded widget text-scale and Chromium zoom
receipts do not establish native, physical-audio or screen-reader support.

The wide composer orders attachment, **Dictate a draft**, then model controls.
`_draftCaptureGuard` binds the rendered channel, origin/profile/session and
composer/voice-gate generations. `captureDraft(isCurrent: ...)` checks that intent
before capture and after asynchronous work. Late results cannot change a
replacement draft or steal its focus. Same-owner completion appends once and
restores the end caret and desktop/wide-web editor focus.

The direct action becomes **Cancel draft dictation** during capture. Cancellation
discards recognition through controller teardown, not Agent Stop. Hands-free,
compact-menu dictation and explicit Send remain separate. No session/model/run,
approval or Wing Link mutation is added. This differs from Desktop stop, which
can finalize transcription. See the [delivery receipt](quality/chat-direct-dictation.md)
for deterministic and compiled-browser evidence, predecessor requirements and
unqualified physical/native/standalone-branch behavior.

The [wide composer qualification](quality/chat-composer-order.md) records named
Tab/Shift+Tab traversal through attachment, draft dictation, model and Send.
The existing order needed no production change. Model loading rejects repeated
activation. During a run, Stop precedes the disabled model inside the strip,
not Desktop's terminal Send slot. A nonempty draft can still queue an explicit
follow-up; empty Send is disabled. Hands-free remains an explicit Wing addition.
The [adaptive recovery receipt](quality/chat-composer-order-recovery.md) qualifies
wide → compact → wide keyboard return and pending model/capture owner replacement.
Obsolete results neither open a sheet nor transfer focus or replace the current draft.
Enter/Space capture cancellation stays distinct from exact-current-owner Agent Stop.
Compact composition remains editor → attachment → Send, with model in its strip
and dictation in Chat menu. Supported-control enlarged-text qualification is
recorded above; full composer and native/live qualification remain open.

## Reasoning disclosure design

The [timeline](../lib/features/hermes_chat/presentation/hermes_chat_timeline.dart)
shows **Thinking…** for trailing reasoning while the last authoritative turn
streams. Answer/tool content or completion changes the summary to **Thought**.
Empty assistant placeholders do not count as visible content. Expansion uses
process-local `ExpansionTile` state and existing exact-owner viewport identities.
Completion does not steal focus from a mounted reasoning disclosure. Reduced
motion uses a static hourglass instead of a spinner; bounded selectable Markdown
and sensitive-text redaction remain unchanged. No Agent event or capability is added.

See the [implementation receipt](quality/reasoning-disclosure-implementation.md)
for reported widget/Chromium checks. The later
[recovery receipt](quality/reasoning-disclosure-recovery.md) records 100 widget
passes and two compiled Chromium journeys. Mounted exact-owner updates retain
focus and expansion. Eviction/remount and owner replacement reset expansion.
HTTP reconnect replaces transient reasoning with authoritative text history;
it does not reconstruct the reasoning row. Recovery causes no incidental mutations.
The [adaptive receipt](quality/reasoning-disclosure-adaptive.md) records compact/wide
keyboard return under reduced motion. The retained row seeds `initiallyExpanded`
when its inner tile remounts. Expansion survives the width boundary; old actionable
focus is released, and Tab/Shift+Tab reaches the replacement summary. Same-layout
resize and completion retain mounted focus. Screen-reader and native/live
qualification remain separate.
The [enlarged-text receipt](quality/reasoning-disclosure-accessibility.md) separately
covers 200% widget text scaling and Chromium whole-render zoom under reduced motion.
Current-owner expansion survives compact/wide return; remounted focus must be reached
again. Completion retains mounted focus. Reused-ID owner replacement starts collapsed
and removes old body/focus. These bounded checks do not establish screen-reader support.
Expansion is not persisted, and no relaunch-retention promise is made.

The [streamed-order receipt](quality/chat-transcript-order.md) qualifies request,
reasoning, commentary, adjacent tools and answer ordering through completion and
compact/wide keyboard return. The timeline itself required no change.
`HermesApprovalQueue` now filters explicit profile identity both when displaying
pending requests and before answering them. A reused profile-local session ID
cannot expose or activate another profile's request. Nullable-profile compatibility
is unchanged. Session/profile/channel replacement and late approval events have
bounded widget coverage; Chromium separately covers session replacement.
The [reconnect receipt](quality/chat-transcript-reconnect.md) records canonical
tool-result rows in server order after reconnect and viewport remount.
`_turnsFromHistory` projects category-only completed activity with canonical IDs,
empty text and no preview/result. It does not append transient activity or infer
success from a persisted result. Retired approvals are not restored as actions.
Focused widget/Chromium receipts establish zero recovery mutations, not native/live
qualification. The [whole-transcript accessibility receipt](quality/chat-transcript-accessibility.md)
records wrapping single/grouped tool titles, keyboard disclosure and current-owner
approval access at 200% scaling/zoom through reconnect, remount and compact/wide return.
Its eight selected source fingerprints match this snapshot. Recovery adds no mutations.
Reasoning recovery, unfinished tools and historical outcome classification remain gaps.
The [native transcript receipt](quality/native-transcript-recovery.md) adds four
Linux GTK fixture cases at 390/1280px and 100/200% text. Production Chat/channel
reconnect restores canonical IDs and category-only tool activity. Keyboard
disclosure and explicit approval retry remain bound to the current owner.
A delayed failure cannot answer or remove the replacement request. Recovery
adds no mutations; deliberate synthetic sends and decision attempts are counted
separately. This is transport-seam qualification, not process restart, live Agent
approvals, physical input, screen readers or full native transcript parity.

The [native Stop receipt](quality/native-stop-recovery.md) qualifies four Linux
GTK fixture cases at 390/1280 logical widths and 100/200% text with reduced motion.
Keyboard Stop retains unresolved ownership through acknowledgment, unknown status,
wrong-run readback and failed status/history reads. Public directory/Add Hermes
recovery admits canonical history before a deliberate resumed send. Failed Stop
and delayed retired settlement cannot release or overwrite the replacement run.
Recovery adds no mutations. This is synthetic transport-seam qualification, not
live Agent Stop, process relaunch, physical input or protected-main delivery.

## Connection-path design

The [owner correction](adr/product.md#decision) makes direct Agent use independent
of Wing Link. First-run enrollment must reach the existing Agent channel and
secure endpoint storage without visiting pairing. SSH forwards to Agent, not a
management proxy. Missing Agent operations remain explicitly unavailable.
Retained optional pairing still verifies its own management identity and grants;
do not remove those checks or reuse management credentials for Agent requests.

Current Chat and Add Hermes composition groups Local, SSH and Remote as three
primary paths, with VPN inside Remote. Local and Remote share the existing
endpoint form. SSH now uses its own managed connection panel, with host,
username, ports, password and separate Agent token. Selection alone never starts
an SSH connection; deliberate Connect reviews trust and creates a Dart forward.
Selecting Remote preserves a selected VPN mode; connecting disables both selection
levels. See the
[source comparison](product/desktop-connection-paths.md) and
[bounded delivery receipt](quality/connection-primary-entry.md).

The current development worktree routes Chat contact Add and connect-another
actions directly to `AppRoutes.addHermes`. `HermesEnrollmentScreen._chooserActions`
also offers **Add Hermes** before **Optional setup and pairing**. The endpoint form
links back to optional enrollment. These changes reuse the existing channel,
storage and pairing contracts. The [first-run receipt](quality/direct-first-run.md)
records passing public-entry, auth-denial/explicit-retry and optional-management
recovery checks. Six browser traces contain no management requests or mutations.
The [native first-run receipt](quality/direct-first-run-native.md) adds four passing
Linux GTK production-router/Chat fixture journeys at 390/1280px and 1x/2x text.
Synthetic read denial, explicit keyboard retry and owner replacement add no Agent
mutations or management requests. Endpoint persistence uses an injected store, not
physical secure storage. The launcher depends on attributed inherited helpers and
a retained Git object, so its own-files commit is not a standalone launcher checkout.
This pass inspects retained results, not a new product run. Live authentication,
Android and main delivery remain open; the [test plan](test-plan.md#connection-path-verification)
keeps those checks separate.

The grouping reuses existing Riverpod/channel contracts and enrollment. Optional
local management setup uses `LocalWingLinkHost` inspect/setup where supported.
Installation, pairing, secure persistence and live Agent readiness remain separate
results. The [saved-host owner-safety receipt](quality/saved-connection-owner-safety.md)
qualifies Chat's rename/remove controls, not the full connection workflow.
Both dialogs capture channel/directory ownership and form intent before consent.
Stale consent cannot write; an already-confirmed storage operation may finish,
but its late result cannot clear an intervening draft. Storage failures use generic
localized errors and require explicit retry. Refresh reads do not select a host,
profile or session. Removal forgets a device-local endpoint, not remote Agent data.
The [Remote retry receipt](quality/remote-connection-retry.md) qualifies explicit
authentication rejection and injected persistence failure through public controls.
An uncertain save retains the connected channel and editable draft with generic
feedback. Retry requires explicit Add Hermes activation. Pending saves disable
that action. Form intent and current channel/directory/store identity fence the
attempt. Post-connect owner generation fences storage settlement. Late results cannot close
or disconnect a replacement owner. Widget/Chromium evidence now has a separate
[native retry receipt](quality/remote-connection-retry-native.md). Four Linux GTK
journeys exercise public auth rejection, uncertain-save draft retention, explicit
retry and delayed-settlement fencing at 390/1280px and 1x/2x text. The injected
endpoint store does not qualify physical secure storage or live authentication.
Logical keyboard events and assisted scrolling do not qualify physical input.
The final rerun includes isolated Go dependencies for the bundled Wing Link build.
Its frozen source and dependency archives bind that executed candidate, not later
Chat/storage changes or main delivery. Actual Local installation, OAuth and managed
SSH qualification remain separate gaps.

Remote HTTPS and VPN now show selectable authentication guidance before submission
and after denial. `_HermesChatScreenLayout` uses `chatLayoutRemoteAuthExplanation` to
distinguish the Agent token from management and provider credentials. The guidance
explains unsupported browser OAuth without treating 401/403 as sign-in detection.
It adds no probe, browser launch or automatic retry. A keyboard focus stop exposes
the text. Widget-order traversal preserves Back after enlarged fields scroll.
The [authentication explanation receipt](quality/remote-auth-explanation.md) records
38 focused Flutter passes and four Linux GTK fixture journeys. All 855 recorded
source inputs match the inspected snapshot. This is retained candidate evidence,
not a new whole-tree check, live authentication or physical keychain qualification.

Optional Local setup now rejects inspection, setup and cancellation after controller
disposal. Teardown cancellation failures cannot escape into a replacement route.
The [setup recovery receipt](quality/local-setup-recovery.md) records consent-bound
Install/Adopt, Stop, inspection-only Check again and explicit Continue through the
production screen with synthetic typed host operations. Verified completion requires
a post-setup health inspection and keeps pairing separate. Its minimal router does
not qualify production enrollment, actual installation or authenticated Agent use.
Production web still does not expose privileged Linux setup.
The separate [native enrollment receipt](quality/local-setup-enrollment-native.md)
qualifies the real WingApp, router and enrollment composition in Linux GTK with
synthetic typed host operations. Public keyboard controls reach consent, Stop,
inspection-only retry and explicit Continue at compact/wide sizes and 100/200% text.
Continue returns to separate pairing controls. Back restores the welcome context.
Disposing Local setup then selecting a direct Agent contact performs no management
request or Agent mutation. This closes the bounded routing/fixture gap, not actual
installation/adoption, live authentication, Android or protected-main delivery.

The current development worktree also implements **Edit saved Agent connection**
in Add Hermes. The [editor receipt](quality/saved-endpoint-edit.md) records bounded
widget/Chromium qualification. Its independent draft never prefills credentials.
An unchanged canonical Agent URL may retain its saved credential. A changed URL
never reuses that credential and drops the Wing Link association; supply its
credential separately if authentication requires one.
Explicit Save updates the original saved ID, rejects another saved URL and reports
local persistence separately from authentication. Storage failure retains the draft
for explicit retry. Owner/form generations fence late UI and directory settlement.
Test creates a separate direct client for one profile-prefixed
`GET /v1/capabilities`, with a 20-second loading timeout and no automatic retry.
Cancel invalidates feedback, not an already dispatched request. Editing, testing
and cancelling do not connect Chat or mutate sessions/runs. The
[native editor receipt](quality/saved-endpoint-edit-native.md) records four passing
Linux GTK fixture journeys at compact/wide widths and 100/200% text. Explicit
Test denial, retry and cancellation preserve the active owner. Endpoint storage
is fake in that earlier journey. The later
[real-storage receipt](quality/saved-endpoint-storage-native.md) qualifies exact-ID
repair, denied-save explicit retry and two-process persistence through production
FlutterSecureStorage/libsecret and native SharedPreferences on isolated Linux GTK.
Four width/text-scale cases preserve same-label peers and blank reopened credential
fields, with no additional Agent reads, connections or mutations. This qualifies
the frozen candidate, not the later editor changes. Other keyring failure modes,
Android and live authentication remain unqualified. The later
[feedback accessibility receipt](quality/saved-endpoint-feedback-accessibility.md)
qualifies complete guidance and sanitized Test/Save outcomes in widgets and Linux
GTK fixtures at compact/wide widths and 100/200% text. These text blocks have
keyboard focus outlines. New outcomes receive focus and reveal their beginning;
Page Down reaches remaining text. Live-region semantics remain present. This
presentation correction does not change owner fencing, storage or retry contracts.
It does not requalify the real-storage backend after the editor change.

The [two-host recovery receipt](quality/two-host-recovery-native.md) qualifies
saved-host selection when profile/session IDs collide. Public keyboard selection,
cancellation and deliberate retry preserve the current host's history and draft.
Delayed success or failure cannot replace a newer selection, including a return
to the same host. Network pagination failure exposes Reconnect; a denied bootstrap
read requires explicit Retry. Recovery reads canonical history without replaying
mutations. Four Linux GTK fixture cases pass at compact/wide widths and 100/200%
text. Synthetic authority and endpoint storage do not qualify live authentication,
physical keychain behavior, managed SSH or protected-main delivery.

Managed SSH is implemented in the development worktree through
`ManagedSshForward` and `ManagedSshConnectionController`. The native Dart adapter
forwards to an already-configured Agent and uses no subprocess or remote shell.
It requires explicit host-key verification and attempt-scoped authentication.
Agent authentication remains separate from SSH success. Browser raw TCP is
unsupported. Native full-app key selection, live authentication, saved SSH relaunch
and protected-main delivery remain unqualified. Do not introduce a remote command
field or use Desktop's remote shell/configuration bridge.

Bind tunnel startup, cleanup and late results to the connection that initiated
them. Define durable host identity separately from an ephemeral forwarded port.
Reconnect and port replacement must preserve profile/session ownership without
resending prompts or approvals. Tunnel teardown and Agent run cancellation are
separate operations. Remote services must not be reported stopped merely because
the local forward closed.

Agent requests remain direct authenticated data-plane traffic over the chosen
transport. Wing Link remains independent host management, with its own credential,
TLS/pinning requirements and grants. Forwarding grants no remote configuration,
installation or lifecycle authority. Browser clients retain direct endpoint or
externally managed tunnel access, not a pretend local SSH implementation.

No new HTTP route, protocol field, credential store or runtime fallback is defined
by this connection increment. Existing [native integration rules](adr/client.md#decision) and
[runtime boundaries](adr/runtime-and-delivery.md#management-and-compatibility)
apply. The [connection test matrix](test-plan.md#connection-path-verification)
separates deterministic checks from native and live qualification.

## Failure, cancellation and lifetime

The channel tracks connection, selection and stream generations to prevent
stale asynchronous work from changing replacement-owner state. Its dispose path
invalidates generations and clears run tracking. `HermesChannelState` distinguishes
connection failures from optional-resource read errors.

Server state wins after reconnect. Unknown submission or Stop outcomes require
reconciliation; reconnect must not silently resubmit a prompt or approval.
Session restoration must not replace a remembered session with a convenient
inventory default. See the [restoration admission review](quality/2026-10-04-autogoal-restoration-admission-review.md)
for the source-review verdict and withheld runtime admission.

The [recovery-read characterization](quality/2026-10-06-m2-recovery-read-admission.md)
identified three exceptions in its recorded snapshot. An ambiguous status 404
removed durable ownership. The [bounded 404 repair](quality/2026-10-06-m2-ambiguous-404.md)
now retains that ownership on failed status reads. Its retained deterministic
execution receipts cover retry, recreation and later exact completion without
replay. The [artifact-review receipt](../.task-evidence/t_3a5135a8/review-398-validation.json)
independently repeats those checks. Final native approval remains unverified.
The shared history-page boundary now validates the envelope and every row before
publication, cache writes or recovered-lease settlement. Exact-session pages need
no additional reads. Compaction history requires fresh, authorized Agent metadata
and bounded probes proving the same canonical tip. Unrelated or malformed history
fails closed; failure retains durable ownership and the duplicate-Send guard.
See the [history-identity implementation receipt](quality/2026-10-06-m2-history-identity.md).
The [independent review execution receipt](../.task-evidence/t_cd72a5d5/review-404-validation.json)
records passing focused, nearest and caller checks against the current report
and selected sources. The [review verdict](../.task-evidence/t_cd72a5d5/review-404.md)
approves only this scoped implementation. Shared baseline hydration and pagination
now reject declared history operations without the exact contract and required
grants. Supported legacy documents may omit the baseline advertisement; null or
unsupported documents do not authorize reads. Denial retains durable ownership
and the duplicate-Send guard. See the
[history-admission implementation receipt](quality/2026-10-06-m2-history-admission.md).
The [independent review verdict](../.task-evidence/t_4e4a4f7d/review-414.json)
approves only this bounded repair. Its matching log records 539 focused, nearest
and caller passes. Neither the repair nor its review qualifies Android process
death, live mutation counts or the integrated M2 outcome.

UI mutations also need owner and lifetime fences. The
[session-mutation](runbooks/chat-session-mutation-intent.md),
[queued-follow-up](runbooks/chat-queued-follow-up-intent.md),
[clipboard](runbooks/chat-transcript-copy-outcomes.md) and
[pin-write-order](runbooks/chat-session-pin-write-order.md) runbooks document
bounded repairs and their failure limits. Local preferences are presentation
state, not a substitute for Agent authority or guaranteed durable storage.

## Security, compatibility and delivery

Credentials use platform secure storage and remain separate between planes.
Pairing handoffs carry a short-lived single-use code, not a bearer credential.
Directory access uses approved roots and opaque handles with containment checks.
Follow [security and privacy](adr/security-and-privacy.md) and the
[threat model](security/threat-model.md); this overview does not expand exceptions.

Prefer advertised Agent operations. Reviewed compatibility adapters use fixed,
bounded operations and must not patch Agent or expose arbitrary CLI execution.
Wing Link supports its current and immediately previous protocol generation.
See [runtime and delivery](adr/runtime-and-delivery.md) for activation, local
health checks, verification and rollback requirements. A documented update path
is not release or rollback qualification.

Wing-managed OmniRoute installation and discovery were removed in the committed
retirement change. The embedded npm manifests, installer, release component and
special profile setup no longer exist. Existing external installations and
Agent configuration are not migrated or deleted. Generic Agent catalog entries
remain visible without enabling the removed setup operation.
The [installer dependency review](quality/omniroute-install-review.md) records
historical failures, not a current embedded dependency closure. The remaining
[security follow-up](../TODO.md#now--next) must check retirement and retained dependencies
on the exact candidate, rather than recreate or audit deleted installer inputs.

## Verification and evolution

The [M2 observer composition](quality/2026-10-06-m2-observer-composition.md),
[QA delivery brief](quality/2026-10-06-m2-qa-delivery-admission.md) and
[receipt-handoff proposal](quality/2026-10-06-m2-receipt-handoff-contract.md)
record predecessor designs and bounded evidence. Their former injectable observer,
journal and secure sink are not the current runtime API. The
[admission trace](quality/2026-10-06-m2-coordinator-admission-trace.md),
[custody requirements](quality/2026-10-06-m2-custody-proof-review.md),
[isolated ordering oracle](quality/2026-10-06-m2-custody-ordering-oracle.md) and
[caller-closure report](quality/2026-10-06-m2-runtime-caller-closure.md)
retain their historical proof limits. None admits an installed coordinator,
private transport or cross-process custody.

The current [QA entrypoint](../integration_test/hermes_m2_observer_main.dart)
awaits the input-free `m2Bootstrap()` and returns. It does not initialize Flutter,
launch an app or construct storage, journals, observers or production channels.
The [public support boundary](../integration_test/support/m2_observer.dart)
exports metadata and a sanitized result: `not_admitted`,
`continuation_unavailable` and `qualifies=false`. Raw sink and injection APIs
have been removed. Fake diagnostic composition is library-private under
`test/tooling/support/`; metadata does not confer authority. Normal product
entrypoints, providers and stores are unchanged by this QA migration.

The [default-refusal receipt](quality/2026-10-06-m2-default-refusal.md)
records 44 tooling passes, 60 rejected external consumers, four positive
metadata/bootstrap controls and three discriminating mutations in disposable mirrors.
All 13 authored fingerprints match the inspected receipt. This pass inspects
retained execution; it does not rerun Dart or Flutter checks. Independent final
approval remains unverified. Source refusal does not prove an installed issuer,
secure-storage durability, packaging, Android process death or authoritative counts.
The [updated preflight](quality/2026-10-06-m2-refusal-continuation-preflight.md)
identified the installed QA issuer admission evidence contract as a source-only
prerequisite. The [delivered dossier](quality/2026-10-06-m2-issuer-evidence-contract.md)
is PROPOSED and records ten missing installed facts and fifteen refusal controls.
It does not supply installed authority. The delivered
[package provenance brief](quality/2026-10-06-m2-package-provenance.md) maps
configured identity, compiled-target attribution and delivered closure evidence.
F01/F02 remain UNAVAILABLE; source identity does not establish APK, installed
or OS identity. The delivered
[manifest assessment contract](quality/2026-10-06-m2-manifest-assessment-contract.md)
is PROPOSED. It defines immutable public inputs, pinned tool closure, enforced
isolation, bounded parsing and sanitized refusal results. Even successful manifest
measurement would establish only partial F01 observations, not candidate admission.
The delivered [inspector isolation preflight](quality/2026-10-06-m2-inspector-isolation-preflight.md)
reads public tool/OS metadata, not an APK or an executed inspector. Approved SDK
closure, immutable input and isolation enforcement remain UNAVAILABLE. Visible
tools and controllers do not prove enforcement. The delivered
[synthetic isolation contract](quality/2026-10-06-m2-synthetic-isolation-contract.md)
is PROPOSED, not an adapter implementation or isolation qualification. It defines
exact cumulative CPU accounting and descendant cleanup requirements. The exact
CPU enforcement mechanism remains UNAVAILABLE. Root TODO records
the [delivered CPU feasibility assessment](quality/2026-10-06-m2-cpu-enforcement-feasibility.md).
The reviewed interfaces do not establish the exact inclusive budget. Its result
is UNAVAILABLE / cpu_budget_unavailable, not proof that every construction is impossible.
The delivered [CPU-envelope assessment](quality/2026-10-06-m2-cpu-envelope-proof.md)
identifies `B_setup` as the first unestablished term in the conditional proof.
DOC-M2-CPU-ENVELOPE-PROOF is done for source-only delivery, not CPU enforcement.
The additional inode-policy review remains separate. No control or
adapter execution follows from either assessment. Missing independent admission
evidence must yield NOT_ADMITTED.
The contract grants no issuer, coordinator, transport or storage activation.
Runtime QA remains unavailable. M2 stays unverified; no positive runtime path,
counting authority, transport, migration or release is authorized here.

The [test plan](test-plan.md) separates deterministic regressions, browser flows,
platform interaction and approved live-target checks. The
[evidence matrix](quality/evidence-matrix.md) preserves qualification records;
[runbooks](README.md#operations-and-qualification) own operating procedures.

Full local Desktop parity remains a target. The
[local integration design](plans/2026-10-03-desktop-local-integration-design.md)
is a separately reviewed design lane, not permission to add native operations.
No migration, rollout or release is authorized by this implementation map.
