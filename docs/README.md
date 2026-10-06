# Hermes Wing Docs

Hermes Wing is an independent cross-platform Flutter client for Hermes Agent,
adapted for mobile, web, and desktop. Hermes Agent remains authoritative for
agent state; Wing Link is its authenticated remote management plane, not a chat
proxy or second backend.

Use the [official Hermes Agent documentation](https://hermes-agent.nousresearch.com/docs/)
for current Agent installation, CLI, provider, profile, and gateway behavior.
The Wing documents below describe only this client's integration and evidence.

## Document ownership

All core document roles have existing owners. Do not create duplicate root files
or treat a source map as release evidence.

| Role | Canonical owner | Boundary |
| --- | --- | --- |
| Orientation | [Root README](../README.md) | Purpose, alpha setup and document navigation. |
| Product requirements | [PRD](product/prd.md) | Accepted intent and leading acceptance outcome. |
| Architectural decisions | [Living ADRs](adr/README.md) | Five current decisions; preserve their history. |
| Technical design | [Spec](spec.md) | Current implementation and planned integration boundaries. |
| Owned HTTP API | [Wing Link OpenAPI](api/wing-link.openapi.yaml) | Manual code-first snapshot; Go handlers remain authoritative. Wing consumes, but does not own, Agent HTTP contracts. |
| Verification | [Test plan](test-plan.md) | Risk scenarios and qualification limits, not a passing receipt. |
| Operations | [Getting started](getting-started.md), [setup](runbooks/android-hermes-setup.md), [release](runbooks/release-alpha.md) and focused runbooks below | Local/host procedures and recovery limits, not proof of production deployment. |
| Change history | [Changelog](../CHANGELOG.md) | Implemented Unreleased changes and recorded baseline, not invented publication. |

[Goal status](../goals.json) is the machine-readable outcome ledger.
[TODO goal coverage](../TODO.md#goal-coverage) maps incomplete outcomes to bounded
next tasks. The [maintenance record](quality/repo-docs-goal-bootstrap.md) records
core-role coverage and verification limits. [BLOCKERS](../BLOCKERS.md) contains only owner questions; engineering
and verification work remain in TODO and the existing tracker.

## Start here

- [Your first conversation](getting-started.md) — beginner setup, explained step by step
- [Android and remote-host setup](runbooks/android-hermes-setup.md)
- [Hermes Agent compatibility](product/hermes-compatibility.md)
- [Wing Link remote management](product/wing-link.md)
- [Security policy](../SECURITY.md) and [threat model](security/threat-model.md)

Use these first when installing, pairing, troubleshooting a connection, or
checking whether a Hermes Agent release exposes the routes Wing needs.

## Product and architecture

- [Delivery roadmap](../ROADMAP.md) — outcome milestones, current evidence and unblock choices
- [Root task handoff](../TODO.md) — bounded parity follow-ups and blockers; the goal ledger retains ownership authority
- [User-action blockers](../BLOCKERS.md) — canonical user-input, sudo and user-decision dependencies, separate from engineering work
- [Architecture decision records](adr/README.md)
- [Four-repository study](analysis/understand-anything/README.md) — curated Agent/Desktop/Conduit/Wing source evidence informing delivery; Desktop-first roadmap priority supersedes the study’s proposed ordering, not its evidence boundaries or runtime limits
- [Study follow-through plan](plans/2026-10-03-study-follow-through.md) — scoped readiness correction and restoration/Chat/mobile/native/setup/release acceptance gates
- [Product requirements](product/prd.md)
- [Technical design](spec.md) — current component/state/flow map and planned integration boundaries
- [Wing Link HTTP contract](api/wing-link.openapi.yaml) — manually maintained code-first snapshot; Go handlers remain authoritative
- [Wing Link implementation plan](plans/wing-link-remote-management.md)
- [Gateway, profile, and Project management](product/gateway-profile-management.md)
- [Routes](product/routes.md)
- [Hermes Desktop capability parity ledger](product/hermes-desktop-parity.md)
- [Desktop shell reference fidelity](runbooks/desktop-shell-reference-fidelity.md) — implemented redesign, attributed widget/browser checks and pending independent finish review
- [Chat session mutation intent](runbooks/chat-session-mutation-intent.md) — owner-bound confirmations and the limits of recorded regression evidence
- [Profiles mutation intent](runbooks/profile-mutation-intent.md) — source-bound rename/delete, confirmation and local-approval retry; deterministic regression evidence, not native approval
- [Chat queued-follow-up intent](runbooks/chat-queued-follow-up-intent.md) — owner-bound queue dialogs and displayed-row removal
- [Chat approval settlement](runbooks/chat-approval-settlement.md) — responder-lifetime fencing and deterministic reconnect regression evidence
- [Whole-transcript clipboard outcomes](runbooks/chat-transcript-copy-outcomes.md) — delayed success, contained rejection and explicit retry
- [Chat session-pin lifetime](runbooks/chat-session-pin-lifetime.md) — disposal fences for local pin actions and focused test evidence
- [Chat session-pin write order](runbooks/chat-session-pin-write-order.md) — serialized same-store commits, coalescing and persistence limits

## Operations and qualification

- [M2 CPU enforcement feasibility](quality/2026-10-06-m2-cpu-enforcement-feasibility.md) —
  source-only finding that the reviewed interfaces do not establish the exact
  inclusive budget; one conditional envelope proof remains, with no control execution.

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
- [Android release handoff](runbooks/android/release-handoff.md)
- [Test plan](test-plan.md) — risk scenarios, environments, developer gates and qualification limits
- [Evidence matrix](quality/evidence-matrix.md)
- [Current loaded-session qualification](quality/2026-10-06-global-sessions-current-check.md) — fresh source/build/browser attribution; the [independent review receipt](../.task-evidence/t_d06ef06d/review-run/review-validation.json) approves this bounded slice, not native or full-parity support
- [Offline discovery conformance](quality/2026-10-06-wing-link-api-conformance.md) — source-bound GET `/meta` and GET `/healthz` checks, not complete OpenAPI or live transport qualification
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
