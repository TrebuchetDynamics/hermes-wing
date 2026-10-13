# Plan reference policy

## Flutter port target

All Wing plans use **Nous Research Hermes Desktop**, located at
`hermes-agent/apps/desktop/`, as the application to port to Flutter.
The official repository is
[NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop).
Read its `README.md`, `AGENTS.md`, `src/AGENTS.md` and `DESIGN.md` before deriving a slice.
The [reference record](../quality/official-desktop-reference.md) owns provenance
and withdrawal of earlier separate-app parity conclusions.

The inspected local Agent revision is
`158fd638da1629c8e62caf9ade1515d162def8ab`.
This identifies a checkout, not live upstream freshness or a released application.
Keep the upstream checkout read-only. A Flutter port reproduces official app
behavior without copying Electron internals or modifying Hermes Agent.

## Using retained plans

The reference notice at the top of each plan governs its current use.
Historical bodies preserve their original proposals, implementation sequences
and executed Wing checks. They are not current product authority.
Old app versions, feature lists, source names, graphs and screenshots must not
be reassigned to the official app without a fresh source comparison.

Use [the current product decision](../adr/product.md),
[PRD](../product/prd.md), [roadmap](../../ROADMAP.md) and
[root backlog](../../TODO.md) for accepted scope and ordering.
Wing Link is deprecated and is not a port prerequisite.
Conduit and Hermes Mobile can inform techniques, not replace the product reference.
Deferred proposals and superseded Agent contracts remain deferred or superseded.

## Re-baseline acceptance

Existing tasks `CONNECTION-OFFICIAL-DESKTOP-PORT` and `PARITY-OFFICIAL-MATRIX`
own connection tracing and rebuilding the withdrawn feature matrix.
Preserve their dependencies and active ownership. Do not create duplicate tasks.

For each new port slice:

1. Record the official app revision and real source components.
2. Trace transport, authentication, profile and process ownership into nearest tests.
3. Identify the Wing caller and exact supported contract. Similar labels are not compatibility proof.
4. Implement the smallest Flutter slice with recovery and accessibility tests.
5. Record named-platform execution separately from source comparison and fixture checks.

Retain passing Wing checks only for the Wing behavior and source they exercised.
Re-baselining plans does not qualify existing UI, JSON-RPC/HTTP compatibility,
native execution, complete parity or delivery to main.

## Applying the official knowledge study

The [maintained knowledge findings](../analysis/official-desktop-graphify.md#bounded-knowledge-study-and-planning-consequences)
come from the pinned official Desktop source, not the retired separate application.
Graph queries and inspected test assertions are source evidence only.

- `CONNECTION-OFFICIAL-DESKTOP-PORT`: use shared gateway ownership, timeout/abort,
  headless launch and request-lease findings to trace one production connection slice.
- `PARITY-OFFICIAL-MATRIX`: map boot, pane composition, replay, Stop and expired-input
  outcomes into real source/test references and separate Linux/Android acceptance.
- `DOC-PARITY-TAB-CONTRACT`: trace official pane/session ownership and keyboard/close
  behavior before implementing supported multi-conversation presentation.
- The [daily-use plan](2026-10-03-desktop-daily-workflow.md#official-lifecycle-source-trace)
  applies warm/cold replay and input/Stop scenarios to existing recovery acceptance.

Preserve milestone focus, dependencies and live worker ownership. The study does
not authorize a transport migration, dynamic plugin system, new host-management
service, Agent edits, personal-runtime changes or release. Wing Link stays deprecated.
Deep semantic gaps are readings within the corresponding implementation tasks,
not additional preflight cards that replace working vertical slices.

## Plan locations

- [Current and retained plans](.) contain roadmap, daily workflow and integration records.
- [Detailed implementation plans](../superpowers/plans/) retain task-by-task sequences.

The notices apply to both collections. The task ledger remains the executable
backlog; unchecked boxes in historical plans do not dispatch work.

## Plan-to-task coverage

Every plan in both collections has an explicit disposition and canonical task
connection below. Current accepted work uses `goals.json` and the full bodies in
[root TODO](../../TODO.md#now--next). The plan is context, not another queue.
Historical and superseded rows identify current successor owners only. They do
not certify completion of the original plan or reopen old unchecked steps.
Proposal rows identify assessment owners, not approved implementation. The
explicitly deferred Nostr plan has no executable task until its decision is reopened.

The two restart outcomes have dedicated tasks: `CONNECTION-CRON-ADMISSION`
precedes `CONNECTION-CRON-CANARY`. A link from an authentication-matrix task alone
does not cover dispatcher repair or canary qualification. Creation of these tasks
neither starts a worker nor resumes cron. Existing product owners and focus stay intact.

Keep this mapping and each plan's Backlog connection current when adding a plan.
The regression `flutter test --no-pub test/tooling/plan_backlog_traceability_test.dart`
checks inventory, dispositions and canonical task IDs. Links and ledger checks
remain separate; this test does not prove requirement coverage or implementation.

<!-- plan-task-map:start -->
| Plan | Disposition | Canonical task owners | Meaning and plan link |
| --- | --- | --- | --- |
| `docs/plans/2026-08-09_183623-hermes-desktop-study-roadmap-evidence-matrix.md` | Historical | `PARITY-OFFICIAL-MATRIX`, `CONNECTION-OFFICIAL-DESKTOP-PORT` | Withdrawn comparison; successors rebuild official evidence, not the old work packages. [Open](2026-08-09_183623-hermes-desktop-study-roadmap-evidence-matrix.md) |
| `docs/plans/2026-08-10_193813-wing-next-do-test-roadmap.md` | Historical | `CONNECTION-LINK-REMOVAL`, `CONNECTION-SETUP-AUTH-MATRIX`, `PARITY-MAESTRO-ANDROID-DEVICE` | Old priorities are superseded; current connection and device owners retain bounded outcomes. [Open](2026-08-10_193813-wing-next-do-test-roadmap.md) |
| `docs/plans/2026-08-10_210519-nostr-gateway-channel-roadmap.md` | Deferred | None — explicitly deferred | No executable Nostr tasks. Reopening the decision is required before booking implementation. [Open](2026-08-10_210519-nostr-gateway-channel-roadmap.md) |
| `docs/plans/2026-09-01_111952-project-setup-contract.md` | Superseded | `DOC-M3-PROJECT-CONTRACT`, `DOC-M3-PROJECT-ASSIGNMENT-CONTRACT` | Project contract-assessment successors only; no legacy adapter expansion. [Open](2026-09-01_111952-project-setup-contract.md) |
| `docs/plans/2026-09-02_162056-hermes-wing-rehabilitation-audit.md` | Historical | `PARITY-OFFICIAL-MATRIX`, `VERIFY-CHAT-TRANSCRIPT-NATIVE`, `MT-RERUN-TRAIN` | Dated findings require fresh reproduction; successors are not historical completion proof. [Open](2026-09-02_162056-hermes-wing-rehabilitation-audit.md) |
| `docs/plans/2026-10-03-desktop-daily-workflow.md` | Current | `CONNECTION-OFFICIAL-DESKTOP-PORT`, `PARITY-LIVE-WORKFLOW`, `VERIFY-LIVE-WORKFLOW-RECOVERY`, `WING-TASK-405`, `WING-TASK-406`, `WING-TASK-407`, `WING-TASK-408` | Accepted daily-use outcome remains incomplete; native/live acceptance stays separate. [Open](2026-10-03-desktop-daily-workflow.md) |
| `docs/plans/2026-10-03-desktop-local-integration-design.md` | Proposal | `DOC-NATIVE-DESIGN-REVIEW`, `DOC-NATIVE-FAILURE-BOUNDARY` | Design review only; the proposed coordinator and old Link mechanism are not implementation authority. [Open](2026-10-03-desktop-local-integration-design.md) |
| `docs/plans/2026-10-03-desktop-port-first-wave.md` | Historical | `CONNECTION-OFFICIAL-DESKTOP-PORT`, `PARITY-OFFICIAL-MATRIX`, `DOC-PARITY-TAB-CONTRACT`, `DOC-PARITY-TAB-RECONNECT-CONTRACT` | Current continuation owns re-baselining; original lanes are not redispatched. [Open](2026-10-03-desktop-port-first-wave.md) |
| `docs/plans/2026-10-03-desktop-port-goal.md` | Current | `CONNECTION-CRON-ADMISSION`, `CONNECTION-CRON-CANARY`, `CONNECTION-LINK-REMOVAL`, `CONNECTION-OFFICIAL-DESKTOP-PORT`, `CONNECTION-SAVED-WORKFLOWS`, `CONNECTION-SETUP-AUTH-MATRIX`, `CONNECTION-LINK-RETIREMENT` | Accepted port and gated restart plan; native admission and product completion remain unverified. [Open](2026-10-03-desktop-port-goal.md) |
| `docs/plans/2026-10-03-study-follow-through.md` | Current | `CONNECTION-OWNER-RECONNECT`, `PARITY-LIVE-WORKFLOW`, `M2-DEVICE-QUALIFICATION`, `DOC-M5-ANDROID-FIXTURE`, `DOC-M3-CONTRACT-CHECKPOINT`, `DOC-M6-INTEGRATED-RECEIPT-GAP`, `DOC-NATIVE-DESIGN-REVIEW` | Retained follow-through uses current owners; M2 device work remains Needs decision. [Open](2026-10-03-study-follow-through.md) |
| `docs/plans/2026-10-12-wing-landing-onboarding.md` | Current | `LANDING-PRODUCT-PROOF`, `LANDING-PAGES-QUALITY`, `CONNECTION-SETUP-AUTH-MATRIX`, `PARITY-LIVE-WORKFLOW` | First-reply onboarding is complete and archived; visual proof, delivery quality and live acceptance remain distinct. [Open](2026-10-12-wing-landing-onboarding.md) |
| `docs/plans/README.md` | Policy | `CONNECTION-OFFICIAL-DESKTOP-PORT`, `PARITY-OFFICIAL-MATRIX` | Reference and traceability policy, not a separate implementation plan. [Open](README.md) |
| `docs/plans/wing-link-remote-management.md` | Superseded | `CONNECTION-LINK-REMOVAL`, `CONNECTION-LINK-RETIREMENT`, `DOC-M3-PROVIDER-CONTRACT`, `DOC-M3-PROJECT-CONTRACT` | Retirement and Agent-contract successors only; no Link expansion. [Open](wing-link-remote-management.md) |
| `docs/superpowers/plans/2026-07-13-android-auth-profiles.md` | Superseded | `DOC-M3-CONTRACT-CHECKPOINT`, `DOC-M3-ROLLBACK-EVIDENCE` | Persona evidence is complete and archived; remaining owners assess supported enrollment/rollback only, not proposed Agent routes. [Open](../superpowers/plans/2026-07-13-android-auth-profiles.md) |
| `docs/superpowers/plans/2026-07-14-milestone2-providers-models.md` | Superseded | `DOC-M3-PROVIDER-CONTRACT`, `DOC-M3-PROVIDER-REMOVAL-CONTRACT`, `DOC-ACCOUNT-CONTRACT` | Supported provider/OAuth assessment only; no upstream additions. [Open](../superpowers/plans/2026-07-14-milestone2-providers-models.md) |
| `docs/superpowers/plans/2026-07-16-multi-gateway-unified-chats.md` | Historical | `CONNECTION-SAVED-WORKFLOWS`, `CONNECTION-OWNER-RECONNECT`, `CONNECTION-LINK-REMOVAL` | Foundation receipts remain historical; successors own current saved-host recovery. [Open](../superpowers/plans/2026-07-16-multi-gateway-unified-chats.md) |
| `docs/superpowers/plans/2026-07-17-settings-information-architecture.md` | Historical | `WING-TASK-408`, `DOC-VOICE-QUALIFICATION` | Original extraction is not reopened; its diagnostics-read contract is complete and archived, while current Settings composition and voice retain separate owners. [Open](../superpowers/plans/2026-07-17-settings-information-architecture.md) |
| `docs/superpowers/plans/2026-08-05-wing-link-local-runtime.md` | Superseded | `CONNECTION-LINK-REMOVAL`, `CONNECTION-LINK-RETIREMENT`, `VERIFY-OMNIROUTE-NODE22-CLOSURE`, `SECURITY-RETAINED-RELEASE-AUDIT` | Retirement and retained security closure, not installer reconstruction. [Open](../superpowers/plans/2026-08-05-wing-link-local-runtime.md) |
| `docs/superpowers/plans/2026-08-17-audit-remediation.md` | Historical | `MT-RERUN-TRAIN`, `MT-VERIFY-BROWSER-GATES`, `SECURITY-RETAINED-RELEASE-AUDIT` | Current gates and audit owners only; speculative refactors are not accepted debt. [Open](../superpowers/plans/2026-08-17-audit-remediation.md) |
| `docs/superpowers/plans/2026-08-22-android-pairing-ux.md` | Superseded | `CONNECTION-LINK-REMOVAL`, `CONNECTION-LINK-RETIREMENT`, `CONNECTION-SETUP-AUTH-MATRIX` | Direct Agent entry supersedes mandatory pairing; deferred App Links/QR work is not booked. [Open](../superpowers/plans/2026-08-22-android-pairing-ux.md) |
| `docs/superpowers/plans/2026-08-24-wing-link-hardening.md` | Historical | `DOC-API-DEVICE-SELF-CONFORMANCE`, `DOC-API-PROTOCOL-ERROR-EVIDENCE`, `DOC-M4-HOST-LIFECYCLE-EVIDENCE`, `CONNECTION-LINK-RETIREMENT` | Retained conformance and retirement checks; old updater qualification is not restarted. [Open](../superpowers/plans/2026-08-24-wing-link-hardening.md) |
| `docs/superpowers/plans/2026-08-30-android-termux-local-agent.md` | Superseded | `CONNECTION-LINK-REMOVAL`, `CONNECTION-LINK-RETIREMENT`, `CONNECTION-SETUP-AUTH-MATRIX` | Link-free replacement only; obsolete publication and physical Termux receipts are not implied. [Open](../superpowers/plans/2026-08-30-android-termux-local-agent.md) |
| `docs/superpowers/plans/2026-08-30-directory-selection-project-readiness.md` | Superseded | `DOC-M3-PROJECT-CONTRACT`, `DOC-M3-PROJECT-ASSIGNMENT-CONTRACT`, `CONNECTION-LINK-RETIREMENT` | Retained Project assessment and browser retirement; no new Link Project adapter. [Open](../superpowers/plans/2026-08-30-directory-selection-project-readiness.md) |
| `docs/superpowers/plans/2026-08-30-hermes-desktop-parity.md` | Historical | `PARITY-OFFICIAL-MATRIX`, `PARITY-NATIVE-LINUX`, `PARITY-MAESTRO-ANDROID-DEVICE` | Rebuild withdrawn reference mapping first; operation-specific ledger tasks own bounded successors. [Open](../superpowers/plans/2026-08-30-hermes-desktop-parity.md) |
| `docs/superpowers/plans/2026-09-04-chat-continuity.md` | Historical | `CONNECTION-OWNER-RECONNECT`, `M1-MOBILE-AWAY-STATUS`, `WING-TASK-407`, `VERIFY-CHAT-TRANSCRIPT-NATIVE-RESTART` | Retained exact-owner recovery; durable drafts and provisional migration are not accepted implementation. [Open](../superpowers/plans/2026-09-04-chat-continuity.md) |
| `docs/superpowers/plans/2026-09-04-conduit-adaptation-roadmap.md` | Historical | `CONNECTION-OFFICIAL-DESKTOP-PORT`, `PARITY-OFFICIAL-MATRIX`, `MT-RERUN-TRAIN`, `MT-VERIFY-BROWSER-GATES` | Secondary technique umbrella, not a separate program to restart or close. [Open](../superpowers/plans/2026-09-04-conduit-adaptation-roadmap.md) |
| `docs/superpowers/plans/2026-09-04-provenance-and-notifications.md` | Historical | `M1-MOBILE-AWAY-STATUS`, `M1-NOTIFICATION-CONTRACT`, `VERIFY-PROFILE-FOOTER-NATIVE`, `DOC-M5-LARGE-TEXT-EVIDENCE` | Notification assessment is accepted; architecture/infrastructure remains proposed. [Open](../superpowers/plans/2026-09-04-provenance-and-notifications.md) |
| `docs/superpowers/plans/2026-09-04-release-evidence.md` | Historical | `DOC-M6-CHECKER-NODE22`, `DOC-M6-INTEGRATED-RECEIPT-GAP`, `DOC-DESKTOP-UNINSTALL-EVIDENCE`, `MT-RERUN-TRAIN` | Desktop delivery evidence is complete and archived; remaining artifact/uninstall/integration owners do not establish signed distribution. [Open](../superpowers/plans/2026-09-04-release-evidence.md) |
| `docs/superpowers/plans/2026-09-04-resource-consistency.md` | Historical | `CONNECTION-SAVED-WORKFLOWS`, `CONNECTION-SETUP-AUTH-MATRIX`, `VERIFY-LIVE-WORKFLOW-RECOVERY`, `WING-TASK-406`, `WING-TASK-407` | Owner isolation and terminal certainty retained; old race/performance matrices are not fully qualified. [Open](../superpowers/plans/2026-09-04-resource-consistency.md) |
| `docs/superpowers/plans/2026-09-04-voice-ownership.md` | Historical | `DOC-VOICE-QUALIFICATION`, `DOC-VOICE-OUTPUT-CANCEL-EVIDENCE`, `PARITY-OFFICIAL-MATRIX` | Physical voice and output cancellation remain bounded qualification, not old controller-test parity. [Open](../superpowers/plans/2026-09-04-voice-ownership.md) |
<!-- plan-task-map:end -->
