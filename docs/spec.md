# Hermes Wing technical design

Status: current implementation map with explicit qualification limits.
This document owns the cross-component design overview, not Agent API schemas
or new architecture decisions. [Product requirements](product/prd.md) own intent;
[living ADRs](adr/README.md) own architectural constraints.

## Components and state

- The Flutter client composes product screens under `lib/features/`.
  [`routerProvider`](../lib/router/providers/app_router.dart) uses GoRouter and
  `AppShell`. The [route ledger](product/routes.md) records availability and
  unsupported actions; route existence alone does not prove capability support.
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

## Connection and daily-use flow

1. Select an explicit endpoint and authenticate to Hermes Agent. Pairing and
   host management use a separate Wing Link connection and credential.
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
records the unresolved exact-pair restoration and native/live qualification gates.

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
DOC-M2-CPU-ENVELOPE-PROOF assesses the one conditional source-only worst-case
envelope. The additional inode-policy review remains separate. No control or
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
