# Official Desktop parity refresh — 2026-10-18

## Scope and priority

Status: Accepted

The owner requested a parity-features update against official `hermes-agent/apps/desktop`
and selected **Keep current priorities; add new gaps behind them**. This accepts
source comparison, documentation reconciliation and bounded contract-research
follow-ups, not product implementation, live operations or qualification.
Preserve Android SSH → profiles/multi-session → canonical Bot Chat → touch polish,
existing task IDs/owners/statuses/order, deliberately deferred Files/slash work,
paused jobs and the six deferred external qualification checks.

## Source identity and evidence boundary

- Official Agent snapshot: `a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70`; Desktop tree `cee4414aae0817b7ff45c76fbfd010dcd753ecf5`.
- Prior matrix snapshot: `158fd638da1629c8e62caf9ade1515d162def8ab`; Wing inspected at `d13b748a4d5b8d5a580f2e0735fbb08387cb2238`.
- [Pinned official Desktop](https://github.com/NousResearch/hermes-agent/tree/a2ad0d5b639160fbb41b2bee8d1ca1e65e544c70/apps/desktop).
- Snapshot acquired from the official repository into a separate read-only research
  checkout. The permanent Agent checkout, installed runtime and personal services
  were not changed. Main may advance after the captured probe; this is not a release pin.
- Rechecked all 45 inherited groups; 24 old primary file fingerprints differ.
  Added five explicit subgroups, for 50 inventory rows. File changes alone do not
  imply changed behavior; subgroup splits are inventory corrections, not claims
  that Radio/Vault/packages/Screen/Pets were newly introduced since October 3.
- Parent verification checked 274 citation instances across 116 files, with matching
  paths, line bounds and SHA-256. Two read-only source reviews covered disjoint
  23/22-group assignments; no upstream or Wing application/tests were executed.
- All 90 inherited Linux/Android runtime cells are preserved as JSON values; ten
  new subgroup cells remain `not_run`. Existing harness/acceptance paths are leads,
  not compatibility proof for the changed upstream. No source subset is promoted
  to full-group parity. No existing Wing graph was available; direct source
  tracing was used, not a newly generated or source-current graph.

## Main findings

1. **Canonical gateway ownership changed.** Desktop now attaches via canonical
   gateway resolution/private tickets, not a per-profile `hermes serve` child.
   Wing's native-serve transport and metadata-only discovery are not that lifecycle.
   A remote failure must never start a local owner; do not copy Electron authority.
2. **Prompt admission is durable and identity-bound.** Stable submission identity,
   queued/started/terminal/unknown receipts and durable user-row correlation differ
   from Wing's legacy acknowledgment/status allowlist. Unknown is not permission
   to resend or fall through to another transport.
3. **Queue and clarification are server-owned input contracts.** Canonical pending
   rows and atomic controls are not Wing's local follow-up queue. Request/question
   identities, staging, sequential batch locks and skip are not ordinary chat replies.
4. **Existing unmapped outcomes need distinct ownership.** All-message JSON export
   differs from loaded text; foreign Claude/Codex session import differs from backup
   recovery. Remote dashboard OAuth differs from provider acquisition/revocation.
5. **Inventory granularity concealed outcomes.** Radio, Vault, package lifecycle,
   Bot Screen leases and Pets are explicit subgroups now. Optional/default-disabled
   status is retained; none grants playback, spending, package execution, vault or
   computer-control authority. Bot Chat remains a separate existing priority.
6. **Moved/deleted evidence was corrected.** Guide now points to first-run kickoff
   and already-submitted session handoff; the deleted Guide source is not repinned.
   Hello Runtime is not treated as a shipped bundled plugin just because a demo exists.

## Follow-up decisions

Planner's call: consolidate the uncovered contract work into four source-only
follow-ups (one per existing owning goal), rather than manufacture a dozen new
UI implementations or reopen completed contract snapshots. These tasks are appended
after the existing Next work. A contract task may conclude unavailable with precise
missing guarantees; that closes its analysis only, never the corresponding product gap.
Actual feature successors require resolved contracts and bounded acceptance.

## gateway-attachment

`PARITYUPDATE-001-aa` · Goal `CONNECTION-PATHS` · HD-LOCAL, HD-HOSTS, HD-RESUME.

Trace canonical gateway discovery, private per-dial tickets, multiplexed profile ownership, stale-owner recovery and viewer disconnect versus owner shutdown. Compare exact unmodified Agent handlers/nearest tests and current Wing native-serve caller. Document a permissible attach-only path or precise unavailable boundary; no gateway ensure/start/restart, control-ticket mint, runtime installation or UI implementation.

Acceptance: Record the exact transport operations, advertisement/grants, connection/profile/home/session identities, native-ticket secret-safe delivery and expiry, stale owner versus denied access, disconnect lifetime and topology distinctions. Reject per-profile serve fallback and local startup after remote failure. Separate any necessary future bounded native design from currently advertised remote operations.

Output: `docs/quality/canonical-gateway-attachment-contract.md`. No implementation or live effects.

## pending-input

`PARITYUPDATE-002-5c` · Goal `CHAT-FIDELITY` · HD-CHAT, HD-DRAFT, HD-QUEUE, HD-CLARIFY.

Trace one coherent pending-input boundary: submission_id/payload binding and durable user-row receipts; authoritative pending FIFO and cancel/resolve_unknown/steer_queued/replace_queued; request/question-bound staged clarification and sequential Confirm/Skip locks. Inspect exact Agent handlers/tests plus Wing callers; source analysis/documentation only, no submit, queue mutation, answer or product change.

Acceptance: Provide separate operation/status matrices for queued/started/terminal/unknown, explicit exact retry versus a changed send, race-to-start and atomic queue replacement, and stale/request-mismatched/partially locked clarification batches. Preserve no automatic replay, authoritative Stop uncertainty and per-session/profile ownership. State which unmodified advertised contracts are usable versus absent; source presence or Desktop private IPC alone is insufficient.

Output: `docs/quality/canonical-pending-input-contract.md`. No implementation or live effects.

## remote-oauth

`PARITYUPDATE-003-b1` · Goal `ACCOUNT` · HD-OAUTH.

Trace remote dashboard OAuth browser return/cookie partition, connection-specific draft identity, fresh per-dial ticket and logout/cancel target fencing through exact Agent handlers/tests and Wing token-only connection path. Keep provider-account OAuth and Cloud topology distinct. No login, account change, browser authorization, cookie/credential acquisition or implementation.

Acceptance: Name exact auth operations, origins/redirect restrictions, grants and target identities; credential persistence and ephemeral handoff; cancellation, stale target and sign-out/revocation outcomes. Record platform feasibility/unavailable outcomes under current secure storage and direct-Agent boundaries. Do not acquire secrets or turn source availability into credential/runtime qualification.

Output: `docs/quality/remote-dashboard-oauth-contract.md`. No implementation or live effects.

## unowned-outcomes

`PARITYUPDATE-004-48` · Goal `PARITY` · HD-EXPORT, HD-IMPORT, HD-RADIO, HD-VAULT, HD-PLUGIN-PACKAGES, HD-SCREEN, HD-PETS.

Produce one bounded seven-row contract disposition for authoritative all-message JSON export; foreign session list/preview/continue; optional Radio; credential Vault; Agent/Desktop plugin package halves; Bot Screen observe/control leases; Pets generation/adoption. Follow each pinned Desktop caller to the exact unmodified Agent handler/nearest test or identify client-local authority. Reuse existing owners; no feature implementation, network playback, export/import, secret access, package loading, computer control or generation.

Acceptance: Each of the seven rows names exact operations/advertisement/grants, connection/profile/resource identities, positive versus unavailable outcome, side effects/secret boundary, cancellation/stale-owner/reconnect behavior, accessible equivalent and existing task overlap. Export completeness is distinct from loaded text, foreign import from backup recovery, Screen from Bot Chat, Vault from endpoint secure storage, and packages from MCP configuration. Missing guarantees stay explicit. Propose only fully specified bounded implementation successors where supported; do not reopen archived work or alter current Files/slash/live gates.

Output: `docs/quality/unowned-desktop-outcomes-contract.md`. No implementation or live effects.

## Existing coverage and non-goals

Per-row `existing_task_ids` and `refresh_followup_task_ids` in the
[JSON matrix](../product/hermes-desktop-feature-matrix.json) distinguish historical,
adjacent, live-only and new contract work. They do not reopen done tasks or claim
that a generic qualification umbrella implements a missing feature. Existing
Project, provider, skills/MCP/memory, messaging, schedules, artifacts, native/update
and accessibility owners retain their acceptance and recorded unsupported contracts.

No Agent patches/forks, host lifecycle commands, CLI bridge, arbitrary directory
access, copied Electron plugin ABI, secret readback, automatic mutation replay,
provider calls, APK builds or service/scheduler changes are part of this refresh.
No runtime/platform cells, goal evidence, live grants or task completion advance.
