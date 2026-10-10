# Hermes Wing product requirements

The only Desktop product reference is [Nous Research Hermes Desktop](https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop),
locally `hermes-agent/apps/desktop/`. Prior separate-app comparisons are
[withdrawn as official parity evidence](../quality/official-desktop-reference.md).
Existing Wing test results do not establish parity with this corrected reference.

Status: current product direction

Pending decisions: [continuity retention](continuity-retention-proposal.md) and
[notification contracts](notification-contract-proposal.md) are proposals, not
approved storage or delivery features. See the
[capability claim audit](capability-claim-audit.md) before expanding support claims.

## Product

Hermes Wing is a Flutter client for Hermes Agent on desktop, web, and mobile.
The accepted direction is a 1:1 Hermes Desktop product/behavior port, with Flutter
desktop and wide web as the fidelity baseline while preserving mobile usability.
Match welcome and connection flow, navigation, screen structure, terminology,
layout, visual hierarchy, interactions, Chat, sessions, profiles, settings and recovery;
platform-native implementation may differ, but product deviations must be explicit.
See [product boundaries](../adr/product.md) and the
[parity ledger](hermes-desktop-parity.md).

### User-demand emphasis

Status: Accepted

Acceptance covers outcome priority and bounded return/status qualification.
Notification architecture remains Proposed and requires separate review.

The owner supplied excerpts from the community discussion
[What do you want in a Hermes mobile app?](https://www.reddit.com/r/hermesagent/comments/1x1zdix/what_do_you_want_in_a_hermes_mobile_app/).
This is qualitative feedback supplied in chat, not an independently retrieved
complete thread or a representative survey. Do not infer vote-based rankings.

The owner selected this outcome order after the current connection slice:
**reliable away-and-return chat, job status, then notifications**. Preserve current
work ownership and small individually usable deliveries. Desktop fidelity remains
the interaction reference, not a reason to defer mobile reliability behind
nonessential visual or feature work.

Desired acceptance, not current support claims:

- Connect and chat through simple, clear controls. Explain failure and give an
  explicit recovery action instead of a false-ready state.
- Leave Wing while an Agent-owned run continues. Return to the exact host,
  profile, session and run, with authoritative history and outcome. Wing suspension
  must not imply Agent cancellation. Unsupported detached operation stays explicit.
- Show understandable running, approval-needed, completed, failed and unknown
  states where authoritative Agent evidence supports them. A lost connection must
  not manufacture completion. Recover without duplicate sends, creates, approvals
  or Stop requests. Reuse the existing status and recovery paths.
- Follow with opt-in completion/attention notifications only through reviewed
  supported contracts. Permission denial must leave foreground status usable.
  Generic lock-screen content, deduplication and exact-owner tap navigation are
  required. A notification is not permission to retry or approve work.

Existing M1 recovery tasks and M2 Android qualification own related work.
M1-MOBILE-AWAY-STATUS is the bounded Android return/status successor;
M1-NOTIFICATION-CONTRACT is its notification assessment successor. Their full
scope, acceptance and dependencies are in [TODO.md](../../TODO.md).
Reuse completed fixture evidence only for matching inputs and do not repeat receipt-only
proofs. Live and physical-device qualification remain separate. The
[notification contract](notification-contract-proposal.md) remains proposed:
priority selection does not approve a relay, provider, enrollment API, secret
access, platform credentials or implementation architecture.

The supplied comments also request fast voice conversation, local/LAN inference,
mobile Kanban, foldable layouts and Desktop-equivalent controls. These are signals
for subsequent bounded design, not approval to add every requested feature now.
Existing VOICE and M4-KANBAN goals retain their scope. End-to-end encryption needs
an explicit endpoint/threat model; transport TLS alone is not E2EE. SMS/phone
control, CarPlay and Watch support are not authorized by this feedback.

### Port-wide fidelity acceptance

Hermes Desktop is the product reference, not inspiration for a separate client.
For each slice, name the inspected reference revision and screen/component.
Match its visible hierarchy and interaction states as well as supported behavior.
Flutter adaptations must preserve the experience, keyboard access and mobile
usability. Record necessary differences and unsupported operations explicitly.
Do not count a difference as matched parity because an API outcome is equivalent.

First launch without a saved connection must show a Desktop-guided welcome and
connection flow, not a Profiles empty state or mandatory management onboarding.
Use the reference welcome hero, Get Started and SSH/Remote entry as the guide.
Explain unsupported native actions without pretending they work or requiring Wing Link.
After connection, the selected navigation destination must agree with the visible screen.

Passing behavioral tests prove only the exercised behavior. Product parity needs
reference comparison and named-target interaction evidence for the same source.
Build and signing checks do not prove welcome fidelity in a delivered APK.

Full local Desktop functionality is the target through separately designed,
reviewed bounded native integration. Remote mode may expose a smaller exact-
capability-gated subset; browser width grants no host-local authority. These are
accepted requirements, not claims of shipped parity or approved native contracts.

Hermes Agent remains authoritative for profiles, projects, providers, models,
sessions, tools, schedules, memory, and gateway state.

## Architecture

### Secondary mobile reference

The [Hermes Mobile study](../quality/hermes-mobile-reference-study.md) supplies
mobile recovery and interaction scenarios. It does not replace Desktop fidelity
or approve new runtime, storage, notification or active-content features.
Renderer controls and additional voice controls remain proposals. Existing
requirements and task ownership determine implementation scope.

Hermes Wing requires a direct authenticated Hermes Agent connection. Wing Link
is not required for Local, SSH or Remote use. The current integration separates:

- the **Hermes Agent data plane** for chat, sessions, runs, tools, approvals, and
  every supported Agent API; and
- retained **Wing Link management code**, pending removal. It is deprecated,
  not an optional supported setup path or a requirement for Agent use.

Retained management credentials and security checks remain separate from Agent
credentials until consumer retirement. Their presence does not authorize new
management dependencies or imply that replacement native operations are qualified.

## Leading acceptance outcome

The owner also requires a source-backed Desktop feature matrix with Android
Maestro journeys and matching Linux qualification. The
[feature matrix](hermes-desktop-feature-matrix.md) separates current subsets,
missing features, adaptations and per-target execution. Android Maestro and
native Linux Flutter integration are different drivers. The owner selected
Waydroid for current Android qualification. Waydroid runs Android in a Linux
container; it is not a physical device. Use an isolated QA app and retain
physical-device acceptance as a separate gap. Target availability is not a
passing Android receipt or live Agent proof. Linux-hosted browser
automation is not native desktop evidence. No 1:1 port claim is accepted until
the mapped supported operations and recovery behavior pass on their named targets.

The next milestone is local connection → explicit profile/model/session selection
→ actual Chat generation → correlated approval and authoritative Stop → leave and
relaunch → restore exactly the same session without duplicate sends.

Acceptance requires authoritative identity, model, history and terminal-outcome
readback; one submission per deliberate send; and no sends, session creation or
approval replay caused by restoration. Keyboard operation and compact/mobile
usability must remain available. The
[daily-workflow plan](../plans/2026-10-03-desktop-daily-workflow.md) owns the detailed
verification matrix and evidence requirements. Fixture output and source/unit
checks do not establish live generation, native execution or milestone acceptance.
This integrated outcome remains unqualified; supporting shell polish does not
substitute for it.

## Core journeys

These journeys describe intended scope, not uniform current support. Their
priority follows the leading outcome above; availability remains operation- and
platform-specific.

1. Connect directly to a trusted Hermes Agent using Local, SSH or Remote.
   Deprecated management pairing must not gate Agent use. Retained handoffs must
   never place bearer credentials in a QR code.
2. Choose a profile and session, send text or voice transcripts, follow events,
   answer approvals, and stop or resume work.
3. Inspect health and perform explicit lifecycle or recovery actions.
4. Create, clone, rename, describe, and delete profiles through Agent-owned or
   advertised Agent contracts. Retained Wing Link compatibility is deprecated;
   missing direct operations remain unavailable until supported.
5. Browse approved host folders—without listing files—and create a per-profile
   Hermes Project for a repository or subfolder.
6. Configure providers and models remotely through typed write-only contracts;
   provider secrets are never returned.

## Terminal working-directory files

Status: accepted requirement; not implemented or platform-qualified.

[Source research](../analysis/terminal-files-feasibility.md) establishes existing
browse/read/download routes in the official Desktop's `hermes serve` backend.
This does not establish file support on Wing's current messaging API connection.
Initial implementation targets qualified authenticated `serve` connections.
Session/profile root selection, strict canonical containment and terminal-backend
support must be qualified before enabling the affected operation. Missing contracts
remain unavailable; this does not relax FILES-4 or promise support on every host.

**FILES-1 — Browse:** Linux and Android users can navigate folders and see files
within the connected Agent's effective `terminal.cwd`. Resolve the root for the
selected connection/profile/session from Agent authority; never substitute the
Wing device's current directory, Hermes home, or a guessed Project folder.
Show the owning context and loading, empty, unavailable, permission and connection
errors. A context switch must discard stale listings and read results.

**FILES-2 — Read:** selecting a supported text file opens a read-only, selectable
preview in Wing. Bound listings and previews; explain oversized, binary or
unsupported content rather than execute it or render active HTML. Browsing and
reading must not submit a prompt, change the terminal directory, or modify files.

**FILES-3 — Download:** an explicit Download action retrieves the selected file
and saves its bytes on the device running Wing. Linux uses a deliberate Save As
destination; Android uses the platform document-save picker. Support cancellation,
progress and actionable failure, and distinguish retrieval from confirmed local
save success. Never silently overwrite an existing destination.

**FILES-4 — Boundary and evidence:** no mandatory Wing Link or Agent modifications.
Use a qualified authenticated Agent file contract or separately reviewed bounded
native operation, with exact owner identity and canonical root containment.
Prevent traversal and symlink escape; keep credentials and file content out of
logs and diagnostics. Permission to chat is not blanket file access. Unsupported
file operations remain clearly unavailable. The existing Wing Link folder-only
contract is unchanged. Qualify browse/read/download and downloaded-byte readback
separately on Linux and Android; fixture tests alone do not establish native saves.

Default scope: read-only browsing, text previews and individual-file downloads;
no upload, editing, deletion, execution or recursive folder download.

## Connection-path requirements

The latest owner decision deprecates Wing Link entirely, superseding the earlier
optional-management target. Existing code and pairing state remain until removal.
New setup/connection must use Agent directly or bounded native operations. The
[deprecation decision](../adr/product.md#wing-link-deprecation) owns this boundary.

The owner requested Desktop's three main connection paths: **Local**, **SSH**
and **Remote**. This is required product scope, not current managed-SSH support.
The [source comparison](desktop-connection-paths.md) distinguishes Desktop behavior
from Wing's implemented three-primary-path grouping over four transport modes.

Owner correction, 2026-10-07: Wing Link installation, pairing and credentials
must not be prerequisites for any of these paths. The committed enrollment chooser
places manual Agent connection inside pairing. The current development worktree
adds primary **Add Hermes** access and separates optional setup/pairing. The
[first-run receipt](../quality/direct-first-run.md) records bounded widget/Chromium
qualification on Linux. The [native first-run receipt](../quality/direct-first-run-native.md)
also records four passing Linux GTK fixture journeys. Neither receipt establishes
main delivery, Android or live authentication.
The acceptance requirements below remain unchanged.

- **CONN-1 — Entry:** expose three clear primary paths. Retain VPN / NetBird /
  Tailscale connectivity within Remote. Preserve keyboard operation and compact
  layouts. Apply this to first-run enrollment, not only the Chat form. Direct
  connection must be a primary action, not an advanced step inside pairing.
  A visible SSH choice must distinguish managed support from an external
  tunnel fallback.
- **CONN-2 — Local:** detect or reuse an existing supported installation, or enter
  explicit local setup with confirmation, progress, cancellation and actionable
  failure. Continue into direct authenticated Agent connection without Wing Link.
  Linux defaults to inspecting `~/.hermes` and offers deliberate selection of an
  alternate Hermes home, not an Agent Project or conversation working directory.
  Android offers guided on-phone installation/setup and direct local connection,
  using the mobile reference as an interaction guide. Neither path requires Wing
  Link, wing-cli, pairing or an externally managed tunnel. Distinguish installation,
  saved credentials, connectivity and model readiness. Runtime remains unmodified.
- **CONN-3 — Remote:** connect to a supplied trusted Agent endpoint through
  supported authentication without Wing Link. Keep saved connection and live readiness separate.
  Match token/OAuth outcomes only where a qualified Agent contract exists.
  Unsupported OAuth must be explained, not simulated or replaced silently.
- **CONN-4 — SSH:** provide a managed native connection with explicit host trust,
  supported authentication, bounded forwarding, cancellation and recovery.
  Forward directly to Agent without Wing Link installation or pairing.
  Preserve external-tunnel access where managed SSH is unsupported. The proposed
  first slice targets an already-configured Agent. Remote install/bootstrap remains
  separate host management, not an implicit Connect side effect.
- **CONN-5 — Saved connections:** provide naming, selection, editing, testing and
  removal. Keep credentials outside public records and diagnostics. Preserve
  host/profile/session ownership across switches, delayed results and reconnect.
- **CONN-6 — Evidence:** qualify each path separately. A health probe does not
  prove authenticated chat, and fixture checks do not prove native SSH or live
  authentication. Disconnect does not imply authoritative Agent Stop.

Existing native-integration and security review requirements remain binding.
These requirements do not authorize arbitrary SSH commands, Agent patches,
credential copying or expanded Wing Link compatibility operations. The
[connection verification matrix](../test-plan.md#connection-path-verification)
defines acceptance checks. CONNECTION-PATHS and REMOTE-BACKENDS in
[root TODO](../../TODO.md#now--next) separate entry/workflow delivery from the
managed native backend.

## Product rules

- Gate direct-client features on the exact connected Agent operation. A missing
  Agent API leaves the feature unavailable with an explanation, not a Wing Link
  requirement. Retained legacy management actions remain gated during Wing Link retirement.
- Keep remote mutations explicit; never queue or replay them after reconnect.
- Use stable resource IDs and opaque directory handles, not client-supplied host
  paths. Wing Link returns child folders only, never file entries.
- Keep secrets in platform secure storage. Prefer trusted HTTPS or an encrypted
  VPN remotely; future provider-secret operations must reject plaintext.
- Require confirmation for destructive, secret, filesystem-grant, and lifecycle
  actions.
- Preserve an accessible non-spatial path for every outcome.
- Make platform and release claims only from runtime evidence.

## Current status

Wing Link-dependent functions listed below describe retained legacy code, not
future product requirements. Do not add compatibility expansion to compensate for
missing Agent APIs. Removal and direct/native replacement require their own checks.

The alpha supports direct Agent chat/runs/sessions, approvals, health, pairing,
Linux Wing Link lifecycle, bounded profile lifecycle, capability-gated provider,
model, and SOUL management, and read-only navigation of locally approved host
folders. Hermes Project creation and assignment, project-scoped Chat, public signed
distribution, and non-Linux Wing Link services remain planned or unqualified.
Isolated private Android release packaging is implemented; artifact checks do not
establish named-device install, upgrade or recovery. See the
[private APK handoff](../runbooks/android/release-handoff.md#private-release-apk-handoff).

See [Routes](routes.md), the [Agent compatibility contract](hermes-compatibility.md),
and the [roadmap](../../ROADMAP.md). Retained legacy contracts are retirement
inputs, not current-user setup guidance.
