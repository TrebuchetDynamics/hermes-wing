# Hermes Wing Docs

The only Desktop product reference is [Nous Research Hermes Desktop](https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop),
locally `hermes-agent/apps/desktop/`. Prior separate-app comparisons are
[withdrawn as official parity evidence](quality/official-desktop-reference.md).
Existing Wing test results do not establish parity with this corrected reference.

Hermes Wing is an independent cross-platform Flutter client for Hermes Agent,
adapted for mobile, web, and desktop. Hermes Agent remains authoritative for
agent state. Wing Link is deprecated and remains in legacy code until removal.
It is not a prerequisite for Agent use, a chat proxy or a second backend.
Wing Link setup, pairing and service runbooks describe retained legacy operations,
not the new-user direction. See the [deprecation decision](adr/product.md#wing-link-deprecation).

Use the [official Hermes Agent documentation](https://hermes-agent.nousresearch.com/docs/)
for current Agent installation, CLI, provider, profile, and gateway behavior.
The Wing documents below describe only this client's integration and evidence.

Current integration handoff: [Profiles Agent-only removal](quality/profiles-agent-only-follow-through.md).
The Profiles-only correction passed independent review on its isolated widget
candidate. It is not canonical-source or main delivery; the existing owner carries
combined-source dependency repair and remaining retirement work.

## Document ownership

All core document roles have existing owners. Do not create duplicate root files
or treat a source map as release evidence.

| Role | Canonical owner | Boundary |
| --- | --- | --- |
| Orientation | [Root README](../README.md) | Purpose, alpha setup and document navigation. |
| Product requirements | [PRD](product/prd.md) | Accepted intent and leading acceptance outcome. |
| Architectural decisions | [Living ADRs](adr/README.md) | Five current decisions; preserve their history. |
| Technical design | [Spec](spec.md) | Current implementation and planned integration boundaries. |
| Owned HTTP API | `docs/api/wing-link.openapi.yaml` | Retained legacy, manual code-first snapshot for retirement checks; Go handlers remain authoritative. Not current-user setup. Wing consumes, but does not own, Agent HTTP contracts. |
| Verification | [Test plan](test-plan.md) | Risk scenarios and qualification limits, not a passing receipt. |
| Operations | [Getting started](getting-started.md), [qualification](runbooks/desktop-feature-qualification.md), [release](runbooks/release-alpha.md) and focused runbooks below | Direct Agent use and bounded qualification; retained packaging is not proof of production deployment. |
| Change history | [Changelog](../CHANGELOG.md) | Implemented Unreleased changes and recorded baseline, not invented publication. |

[Goal status](../goals.json) is the machine-readable outcome ledger.
[TODO goal coverage](../TODO.md#goal-coverage) maps incomplete outcomes to bounded
next tasks. The [maintenance record](quality/repo-docs-goal-bootstrap.md) records
core-role coverage and verification limits. [BLOCKERS](../BLOCKERS.md) contains only owner questions; engineering
and verification work remain in TODO and the existing tracker.

## Evidence availability

Links into `.task-evidence/` refer to optional, Git-ignored local receipts.
They are not shipped documentation dependencies and may be absent in a fresh
checkout. Tracked quality reports describe their results and qualification limits.
A missing local receipt does not establish a passing check on another checkout.
The source-study graphs, census and tool checkout are also local artifacts, not
release evidence. `.repo-docs-drift-ignore` lists the exact monitor findings for
these intentional references; it does not exempt unrelated broken links.

## Start here

- [Direct Agent connection](getting-started.md#direct-agent-connection) — fresh-launch welcome and saved-owner Add Hermes without Wing Link in the development worktree
- [Desktop-guided welcome](quality/desktop-welcome.md) — widget/Chromium qualification and explicit differences
- [Welcome recovery on Linux](quality/desktop-welcome-recovery.md) — keyboard cancellation, explicit retry and process restoration; Android, physical keychain, live authentication and main delivery remain separate
- [Your first conversation](getting-started.md) — direct connection, client build and explicit recovery
- [Android and Linux qualification](runbooks/desktop-feature-qualification.md) — isolated QA procedures, not installation or live-authentication proof
- [Hermes Agent compatibility](product/hermes-compatibility.md)
- [Security policy](../SECURITY.md) and [threat model](security/threat-model.md)

Use these first when installing, pairing, troubleshooting a connection, or
checking whether a Hermes Agent release exposes the routes Wing needs.

## Product and architecture

- [Delivery roadmap](../ROADMAP.md) — outcome milestones, current evidence and unblock choices
- [Root task handoff](../TODO.md) — bounded parity follow-ups and blockers; the goal ledger retains ownership authority
- [User-action blockers](../BLOCKERS.md) — canonical user-input, sudo and user-decision dependencies, separate from engineering work
- [Architecture decision records](adr/README.md)
- [Four-repository study](analysis/understand-anything/README.md) — curated Agent/Desktop/Conduit/Wing source evidence informing delivery; Desktop-first roadmap priority supersedes the study’s proposed ordering, not its evidence boundaries or runtime limits
- [Hermes Mobile study](quality/hermes-mobile-reference-study.md) — secondary mobile lifecycle and UX evidence; source-only proposals, not a new parity target or notification approval
- [Study follow-through plan](plans/2026-10-03-study-follow-through.md) — scoped readiness correction and restoration/Chat/mobile/native/setup/release acceptance gates
- [Product requirements](product/prd.md)
- [Technical design](spec.md) — current component/state/flow map and planned integration boundaries
- [Terminal file feasibility](analysis/terminal-files-feasibility.md) — existing official `serve` routes, backend/auth/root limits and planned Linux/Android qualification; no shipped Files feature
- [Routes](product/routes.md)
- [Hermes Desktop capability parity ledger](product/hermes-desktop-parity.md)
- [Desktop feature matrix](product/hermes-desktop-feature-matrix.md) — Android Maestro candidates, native Linux counterparts and explicit per-target gaps
- [Desktop feature qualification](runbooks/desktop-feature-qualification.md) — isolated QA commands, target prerequisites and receipt rules
- [Android approval/attachment fixture](quality/android-approval-attachment-fixture.md) — repaired control/counter regressions and bounded wrapper selection; widget passes, not Android execution
- [Connection primary entry](quality/connection-primary-entry.md) — implemented Local/SSH/Remote grouping with nested VPN; bounded widget/browser evidence, not managed SSH or live authentication
- [Saved-host owner safety](quality/saved-connection-owner-safety.md) — public rename/remove consent, storage retry and delayed-owner fencing; retained widget/Chromium evidence, not the full setup/authentication matrix
- [Remote authentication/save retry](quality/remote-connection-retry.md) — explicit auth rejection, uncertain save and replacement-owner fencing; widget/Chromium plus [Linux GTK fixture evidence](quality/remote-connection-retry-native.md), not physical secure storage or live authentication
- [Remote authentication explanation](quality/remote-auth-explanation.md) — keyboard-reachable Agent-token and unsupported-OAuth guidance, denial/cancel/explicit retry; retained widget and Linux GTK fixtures, not live authentication or Android qualification
- [Native grouped recents](quality/grouped-recents-native.md) — isolated Linux GTK keyboard/adaptive return and obsolete-owner rejection; synthetic route content, not full feature screens or physical input
- [Direct first-run Agent entry](quality/direct-first-run.md) — public Local/SSH/Remote keyboard access and explicit auth retry without management requests; passing Linux widgets/Chromium and [native GTK fixtures](quality/direct-first-run-native.md), not live authentication or main delivery
- [Saved Agent connection editing](quality/saved-endpoint-edit.md) — exact-ID Save, masked credential repair and direct read-only Test; passing widget/Chromium and [native GTK fixture journeys](quality/saved-endpoint-edit-native.md)
- [Saved connection secure persistence](quality/saved-endpoint-storage-native.md) — isolated Linux libsecret/GNOME Keyring repair, denied-save retry and two-process persistence; frozen-candidate evidence, not later editor changes or live authentication
- [Saved connection readable feedback](quality/saved-endpoint-feedback-accessibility.md) — complete guidance and Test/Save outcomes with keyboard focus and paging; widget/Linux GTK fixture evidence at 100/200% text, not screen readers or later real-storage qualification
- [Optional Local setup recovery](quality/local-setup-recovery.md) — disposed-operation fencing, consent, Stop and inspection-only retry in compiled fixtures; this isolated-screen result does not qualify production enrollment or actual installation
- [Native production Local enrollment](quality/local-setup-enrollment-native.md) — four Linux GTK keyboard journeys through the real app/router, separate pairing and direct Agent selection without management requests; synthetic host operations, not actual installation, live authentication, Android or main delivery
- [Two-host selection and recovery](quality/two-host-recovery-native.md) — Linux GTK fixture keyboard selection, colliding identities and explicit read-only retry; frozen-source evidence, not live authentication or main delivery
- [Production connection browser matrix](quality/connection-production-browser-matrix.md) — real welcome/router, legacy Local setup, Remote retry and saved-owner recovery in one compiled candidate; retained Flutter/Chromium passes, not current-tree, replacement Local, native/live or main-delivery qualification
- [Desktop connection paths](product/desktop-connection-paths.md) — Local / SSH / Remote source comparison, current external-tunnel support and planned bounded native delivery
- [Whole-transcript accessibility](quality/chat-transcript-accessibility.md) — enlarged-text widget/Chromium recovery and keyboard evidence; see the separate native subset below
- [Native keyboard Stop recovery](quality/native-stop-recovery.md) — four Linux GTK fixture cases for uncertain/failed Stop, canonical recovery and replacement-owner fencing; no recovery replay, not live Stop or process-relaunch qualification
- [Integrated native restart](quality/native-integrated-daily-restart.md) — compact/wide Linux GTK fixture sequence for approval, uncertain Stop, canonical recovery and exact-session process restart; explicit reselection before one resumed send, not live generation or main delivery
- [Native status accessibility](quality/native-status-accessibility.md) — keyboard inspection of complete redacted status, current-owner compact More and enlarged-text wrapping; four Linux GTK fixture journeys, not live authentication, screen readers or main delivery
- [Native transcript approval recovery](quality/native-transcript-recovery.md) — four Linux GTK fixture cases for keyboard disclosure, explicit retry and obsolete approval rejection; not process restart, live Agent or screen-reader qualification
- [Desktop shell reference fidelity](runbooks/desktop-shell-reference-fidelity.md) — committed redesign and attributed checks; the later [inventory keyboard qualification](quality/shell-inventory-keyboard-qualification.md) closes FINISH-DESKTOP-SHELL, not full parity
- [Profile-footer composition](quality/profile-footer-composition.md) — source comparison and bounded contract
- [Compact Profiles adaptation](quality/compact-desktop-outcome.md) — direct mobile management navigation versus the Desktop picker; bounded widget evidence, not Android or persistence qualification
- [Passive profile footer](quality/profile-footer-implementation.md) — current-channel display and Manage profiles navigation; retained widget/browser evidence, not edit/switch or full composition parity
- [Next Desktop port slice](quality/desktop-next-port-slice.md) — 46 mapped feature groups and the passive-footer contract; passive footer and source-grouped recents are delivered, while full composition remains queued
- [Native global session panel](quality/global-session-modal-native.md) — Linux GTK injected keyboard/adaptive recovery, exact Open/New and read-only Retry; retained synthetic evidence, not physical input, live profiles or full feature screens
- [Adaptive global session panel](quality/global-session-modal-adaptive.md) — compact/short-window keyboard access at separate 200% Flutter text and Chromium zoom; retained widget/browser evidence, not native/live or screen-reader qualification
- [Global session modal](quality/global-session-modal.md) — Sessions and Ctrl/Command+K over feature routes; loaded search, gated management and owner-bound focus/activation. New recovery retries only acknowledged-session history, not creation; qualification remains deterministic, not native/live.
- [Source-grouped recents](quality/grouped-recents-implementation.md) — stable loaded-row projection with exact-owner keyboard Open/New; retained widget/Chromium evidence, not Project grouping or native/live parity; the [recovery receipt](quality/grouped-recents-recovery.md) adds keyboard hide/return and pending-owner rejection through existing sidebar controls
- [Chat composer reference](quality/chat-fidelity-reference.md) — historical source comparison and six port oracles; the [delivered wide draft action](quality/chat-direct-dictation.md) has bounded keyboard/owner/recovery evidence, not physical audio or full composer parity
- [Wide composer qualification](quality/chat-composer-order.md) — named keyboard traversal, loading and exact Send/Stop requests; the [adaptive recovery receipt](quality/chat-composer-order-recovery.md) qualifies compact/wide return and pending-owner rejection; the [enlarged-text receipt](quality/chat-composer-accessibility.md) qualifies the supported controls at 200% text/zoom with reduced motion; full composer/native parity remains a gap
- [Reasoning disclosure comparison](quality/chat-transcript-disclosure.md) — historical source comparison and one pointer-reveal regression
- [Reasoning disclosure implementation](quality/reasoning-disclosure-implementation.md) — delivered Thinking…/Thought summaries and keyboard focus; executor-reported widget/Chromium qualification, not eviction/reconnect or native parity
- [Reasoning disclosure recovery](quality/reasoning-disclosure-recovery.md) — final widget/Chromium evidence for mounted updates, collapsed remount and owner replacement; HTTP reconnect drops transient reasoning, not native qualification; the [adaptive receipt](quality/reasoning-disclosure-adaptive.md) separately qualifies compact/wide keyboard return under reduced motion; the [enlarged-text receipt](quality/reasoning-disclosure-accessibility.md) adds separate 200% widget text and Chromium zoom checks, not screen-reader qualification
- [Local sidebar persistence](quality/graphify-shell-persistence.md) — saved collapse/expand choice, late-load fencing and serialized writes pass widget checks; native process relaunch remains unqualified
- [Native two-process relaunch](quality/native-relaunch-workflow.md) — real Linux GTK/Xvfb processes and off-page history restoration without replay; separate model scenario, not model persistence, full-shell startup or live inference
- [Live workflow preparation](quality/live-desktop-daily-workflow.md) — tested read-only authorization/preflight and mutation guards; the prepared production Chat driver remains disabled until provider-call limits are qualified, not live generation or native journey evidence
- [Isolated two-process orchestration](quality/live-two-process-orchestration.md) — synthetic Linux lifecycle and fail-closed state preservation, not GTK/live qualification
- [Owned display authentication](quality/live-display-isolation.md) — branch-only real X protocol admission and denial checks; not yet in the shared helper, not same-UID isolation or live generation
- [Provider-call boundary](quality/live-provider-call-ceiling.md) — inspected Agent contracts do not enforce three physical attempts across retries and continuations; branch refusal tests pass, live inference stays disabled
- [Credential-free native shell smoke](quality/native-no-inference-smoke.md) — corrected frozen-source Linux GTK restart and keyboard recovery with zero fixture mutations; supersedes incomplete initial archive, not live generation or current-tree qualification
- [Native denied-read restart](quality/native-no-inference-auth-recovery.md) — four frozen-source GTK phases retain the saved owner through synthetic 401/403 and explicit keyboard Retry; cancelled/wrong-owner reads cannot settle, not live authentication or inference
- [Native bootstrap-denied restart](quality/native-no-inference-bootstrap-recovery.md) — six frozen-source GTK phases retain the exact owner through required-capabilities 401/403 before inventory/history; deliberate keyboard Retry restores canonical history without mutations, not live authentication or inference
- [Native resumed send](quality/native-resumed-send.md) — two Linux GTK processes restore the exact session, explicitly reselect a model and send once; no restart/reopen replay, not authoritative pair persistence or live generation
- [Canonical transcript reconnect](quality/chat-transcript-reconnect.md) — category-only persisted tool activity and retired-approval focus through reconnect/remount; retained widget/Chromium checks, not historical tool outcome or native/live parity
- [Streamed transcript order](quality/chat-transcript-order.md) — canonical activity order through completion/adaptive keyboard return and explicit-profile approval fencing; retained widget/Chromium evidence, not history reconnect or native/live qualification
- [Current security boundaries](quality/security-current-boundary.md) — named denial, containment, redaction, approval/replay and reconnect checks; not certification or native qualification
- [Chat session mutation intent](runbooks/chat-session-mutation-intent.md) — owner-bound confirmations and the limits of recorded regression evidence
- [Session rename journey](quality/session-rename-journey.md) — deterministic production-screen/channel/client rename, authoritative reopen, Cancel and same-ID owner replacement; not complete session parity
- [Session delete journey](quality/session-delete-journey.md) — one owner-scoped DELETE, authoritative reconnect, Cancel and same-ID owner replacement; not live persistence or full session parity
- [Session branch journey](quality/session-fork-journey.md) — one owner-scoped fork, authoritative child-history reopen and zero stale-owner mutations; not automatic restoration or full session parity
- [Session search/resume journey](quality/session-search-resume-journey.md) — loaded-row search, exact-owner history and read-only reconnect/reopen; not full-text search, automatic restoration or live/native parity
- [Chat queued-follow-up intent](runbooks/chat-queued-follow-up-intent.md) — owner-bound queue dialogs and displayed-row removal
- [Chat approval settlement](runbooks/chat-approval-settlement.md) — responder-lifetime fencing and deterministic reconnect regression evidence
- [Whole-transcript clipboard outcomes](runbooks/chat-transcript-copy-outcomes.md) — delayed success, contained rejection and explicit retry
- [Chat session-pin lifetime](runbooks/chat-session-pin-lifetime.md) — disposal fences for local pin actions and focused test evidence
- [Chat session-pin write order](runbooks/chat-session-pin-write-order.md) — serialized same-store commits, coalescing and persistence limits

## Operations and qualification

- [M2 CPU enforcement feasibility](quality/2026-10-06-m2-cpu-enforcement-feasibility.md) —
  source-only finding that the reviewed interfaces do not establish the exact
  inclusive budget. The delivered [conditional envelope assessment](quality/2026-10-06-m2-cpu-envelope-proof.md)
  identifies `B_setup` as the first unestablished term, with no control execution.

- [M2 recovery-read characterization](quality/2026-10-06-m2-recovery-read-admission.md) — approved characterization of three defects in its snapshot; the later [ambiguous-404 repair](quality/2026-10-06-m2-ambiguous-404.md) retains ownership, while the [history-identity implementation](quality/2026-10-06-m2-history-identity.md) has scoped independent approval and a done ledger task. The
  [history-admission implementation](quality/2026-10-06-m2-history-admission.md) has
  [scoped independent approval](../.task-evidence/t_4e4a4f7d/review-414.json).
  The [post-repair caller receipt](quality/2026-10-06-m2-post-repair-callers.md)
  records 85 focused passes and a fresh compiled Chromium Open/New pass; its ledger
  task is done for bounded execution, with independent final approval unverified.
  The [credential-denial oracle](quality/2026-10-06-m2-credential-denial-oracle.md)
  records exact-owner HTTP 401 denial and read-only Retry recovery; its ledger task
  is done for bounded execution, not final approval or live credential revocation.
  The later [HTTP 403 oracle](quality/2026-10-06-m2-forbidden-recovery-oracle.md)
  records three app-level cases and 60 nearest passes. The later
  [bootstrap HTTP 401 control](quality/2026-10-06-m2-bootstrap-denial-oracle.md)
  records four app-level cases and 60 nearest passes, with matching source inputs.
  The [bootstrap HTTP 403 control](quality/2026-10-06-m2-bootstrap-forbidden-oracle.md)
  records five app-level controls and 65 total passes with the nearest targets.
  The [observer composition](quality/2026-10-06-m2-observer-composition.md) maps
  production persistence seams and the complete static local dependency closure.
  That report remains historical source-only composition evidence. The
  [QA observer receipt](../.task-evidence/t_53f0d91e/report.md),
  [delivery brief](quality/2026-10-06-m2-qa-delivery-admission.md),
  [receipt-handoff proposal](quality/2026-10-06-m2-receipt-handoff-contract.md),
  [admission trace](quality/2026-10-06-m2-coordinator-admission-trace.md),
  [custody requirements](quality/2026-10-06-m2-custody-proof-review.md),
  [ordering oracle](quality/2026-10-06-m2-custody-ordering-oracle.md) and
  [caller-closure report](quality/2026-10-06-m2-runtime-caller-closure.md)
  retain their predecessor evidence and do not admit installed custody.
  The delivered [default-refusal boundary](quality/2026-10-06-m2-default-refusal.md)
  removes runtime injection and raw sink APIs. The input-free bootstrap returns
  refusal before Flutter, app or storage construction. Retained checks record
  44 tooling passes, 60 rejected consumers and four positive metadata/bootstrap
  controls. Fake diagnostic composition remains private and does not activate runtime.
  The [updated preflight](quality/2026-10-06-m2-refusal-continuation-preflight.md)
  maps the remaining named-device prerequisites against this boundary. Root TODO
  indexes the delivered [proposed admission dossier](quality/2026-10-06-m2-issuer-evidence-contract.md)
  and its delivered [F01/F02 provenance brief](quality/2026-10-06-m2-package-provenance.md).
  The delivered [partial-F01 manifest contract](quality/2026-10-06-m2-manifest-assessment-contract.md)
  remains PROPOSED, not an inspector implementation or artifact assessment.
  The delivered [isolation preflight](quality/2026-10-06-m2-inspector-isolation-preflight.md)
  records public tool/OS metadata, not enforcement or artifact facts. Root TODO
  indexes the delivered [synthetic proof contract](quality/2026-10-06-m2-synthetic-isolation-contract.md),
  still PROPOSED with enforcement NOT_ESTABLISHED. Exact cumulative CPU enforcement
  remains UNAVAILABLE; the next bounded task assesses that prerequisite without
  adapter execution or relaxed limits.
  All installed facts remain UNAVAILABLE; runtime remains refused.
  Installed authority, storage durability, packaging, Android death, authoritative
  counts, live qualification and independent final approval remain unverified.

- [Alpha release runbook](runbooks/release-alpha.md)
- [Read-only candidate comparison](runbooks/offline-release-candidate-comparison.md) — independent public expectations and offline consistency checks, not signature or runtime qualification
- [Android release handoff](runbooks/android/release-handoff.md) — includes isolated private ARM64 release testing with required signing; device qualification remains separate
- [Test plan](test-plan.md) — risk scenarios, environments, developer gates and qualification limits
- [Session model identity and safe picker](quality/session-model-pair-read.md) — unknown pairs require explicit selection; retained focused passes do not close the failing integrated exact-pair workflow
- [Chat new-session selector repair](quality/chat-new-session-selector-repair.md) — 28 retained smoke/speech browser passes, not embedded audit closure or physical speech qualification
- [Evidence matrix](quality/evidence-matrix.md)
- [Current loaded-session qualification](quality/2026-10-06-global-sessions-current-check.md) — fresh source/build/browser attribution; the [independent review receipt](../.task-evidence/t_d06ef06d/review-run/review-validation.json) approves this bounded slice, not native or full-parity support
- [Hermes readiness audit](runbooks/hermes-readiness-audit.md)
- [Hermes platform smoke](runbooks/hermes-platform-smoke.md)
- [Hermes Agent release compatibility audit](runbooks/hermes-agent-release-compatibility.md)
- [Android live microphone smoke](runbooks/android/live-mic-smoke.md)

## Historical plans and comparison studies

These documents preserve decision history. They are not current setup guides or
authority for Hermes Agent behavior; current ADRs and implementation win when a
historical plan differs.

- [Hermes Desktop complete feature study](product/hermes-desktop-feature-study.md)
- [Hermes Desktop UI gap audit](product/hermes-desktop-ui-gap.md)
- [Implementation plans and superseded designs](superpowers/)

## Research recommendations

- [Hermes WebUI feature and architecture study](product/hermes-webui-feature-study.md) — long-run chat, recovery, session, onboarding, and operations lessons with authority-safe Wing dispositions
- [Buzz UX and archived Nostr research](research/buzz-nostr-lessons.md) — Nostr control transport deferred
- [Matrix messaging lessons for Wing and Wing Link](research/matrix-messaging-lessons.md)
- [Archived offline bilingual mobile voice research](research/offline-bilingual-voice-architecture.md) — not adopted; Wing does not ship or load app-owned voice models
