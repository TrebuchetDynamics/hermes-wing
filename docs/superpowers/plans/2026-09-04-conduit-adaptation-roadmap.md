# Conduit-Informed Reliability Roadmap Implementation Plan

> **For agentic workers:** Use the available executing-plans skill task-by-task. Checkboxes track implementation, not planning completion. No commits, external tracker writes, or delegation are authorized by this document.

**Goal:** Adapt the strongest reliability lessons from Hermes Conduit without adopting its Dashboard transport, security policy, shadow state, or monolithic coordinator.

**Architecture:** Deliver five independent, reviewable workstreams. Keep Hermes Agent authoritative, keep Wing Link limited to typed host management, and place small policies beside the Wing feature that owns them. Every workstream begins by proving a current gap; recommendations that are already satisfied become documented invariants rather than rewrites.

**Tech Stack:** Flutter 3.44.2, Dart, Riverpod, GoRouter, HermesChannel, direct advertised Hermes Agent HTTP/SSE contracts, platform voice adapters, GitHub Actions, flutter_test. No new runtime dependency is assumed.

## Global Constraints

- Reference evidence: [Hermes Conduit](https://github.com/kaishi00/hermes-conduit) at commit `df550e9358eb9bd59657e0d767813fcda1916987`; it is a product and reliability reference, not a protocol authority.
- Hermes Agent owns profiles, Projects, providers, models, sessions, runs, tools, schedules, memory, and gateway state.
- Agent chat and run traffic remains direct; Wing Link never becomes a Dashboard proxy, WebView bridge, shell bridge, notification relay, or second backend.
- Require exact endpoint, method, scope, resource identity, revision, and capability before exposing a mutation.
- Never put credentials, transcripts, recognized speech, provider values, private hostnames, host paths, or tool arguments in URLs, logs, notifications, diagnostics, fixtures, or ordinary preferences.
- HTTP remains loopback-only. Non-loopback Wing Link requires TLS 1.3, device authentication, and reviewed SHA-256 SPKI pinning.
- Default profile, gateway, Project, session, and run identities remain explicit; no implicit global profile or Project side effects.
- Preserve Riverpod/feature boundaries; do not create a global AppState-style coordinator.
- Deterministic tests do not establish microphone, acoustic, APNs/FCM delivery, signed distribution, service, thermal, or production evidence.
- Do not stage or commit during execution unless the human explicitly asks. Each task ends at a validation/review checkpoint.

---

## Evidence classification

Status: implementation partially executed; see the execution receipt below.
The evidence anchors that follow describe the pre-implementation inspection,
not the current state of the changed files.
Source baseline: inspected dirty Wing worktree on 2026-09-04, not a qualified
release. The user-supplied Conduit audit is the source for detailed Conduit
findings; it was not independently repeated. The
[pinned repository README](https://github.com/kaishi00/hermes-conduit/tree/df550e9358eb9bd59657e0d767813fcda1916987)
was checked for its Dashboard transport and optional relay description.

Local evidence anchors (line numbers describe this inspection):

- `lib/features/hermes_chat/composer/hermes_chat_message_flow.dart:6-63,147+`: picker/read awaits do not capture full composer ownership; send eagerly clears text and the global attachment before the long-lived send future resolves. A start/terminal failure cannot conditionally restore the submitted generation without overwriting newer input.
- `lib/features/hermes_chat/screens/hermes_chat_screen.dart:172-179,294-319`: text drafts are gateway/profile/session scoped and bounded, but attachment/error/busy state is global and there is no draft generation.
- `lib/features/hermes_chat/screens/state/hermes_chat_lifecycle.dart:40-55`: near-bottom scrolling uses a raw 160-pixel threshold; there is no semantic restore marker, per-session viewport owner, or healthy-resume transcript reconcile.
- `lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart:279-301`: `_reloadJobs` is a demonstrated profile race because it commits on connection identity alone; providers/models already use stronger connection/profile generations and tool inventory captures profile.
- `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart:1893-2008`: terminal detached-run recovery can release its durable lease before canonical history hydration, then lose retry identity on a transient fetch failure.
- `lib/core/hermes/sse/hermes_sse_event_decoder.dart:208-235`: comment-only keepalives are discarded before the run idle timer can observe liveness.
- `lib/core/hermes/channel/hermes_approval_request.dart` and `hermes_api_channel.dart:426-453`: the request remembers originating profile but the response API posts with current selection.
- `lib/features/hermes_chat/voice/hermes_voice_input_controller.dart:132-153,300-447`: operation and speech generations exist, but target checks are session-only; staged voice submit, reply selection, and barge-in do not carry one immutable channel/gateway/profile/session/run identity.
- `.github/workflows/hermes-platform-smoke.yml:249-295` uploads `hermes-wing-*` platform artifacts while both receipt validators require `wing-*`, so a successful hosted run cannot currently yield a passing receipt.
- `.github/workflows/release-alpha.yml` already verifies source/checksums/signatures, but the final evidence is emitted before separate smoke receipts and those receipts do not bind the exercised artifact digest.

### Contradictions and decisions to preserve

The supplied instructions require loopback-only HTTP. The working
[security ADR](../../adr/security-and-privacy.md),
[threat model](../../security/threat-model.md), and [SECURITY.md](../../../SECURITY.md)
describe a confirmed direct-Agent HTTP exception for certain networks. This is
an unresolved policy discrepancy, not permission to expand cleartext support.
Resource consistency Task 4 reconciles the policy and tests before transport
work. Wing Link non-loopback TLS 1.3 and native SPKI requirements remain explicit.

The initial continuity milestone is process-local: it covers foregrounding while
the process survives. Process-death restoration is a separate retention-gated
deliverable; do not advertise it after completing only the in-memory work.

### Already present; strengthen with regression tests instead of rewriting

- Foreground reconnect, active stream preservation, detached-run recovery, and conservative `hasUnreconciledRun` send gating.
- Gateway/profile/session-scoped in-memory text drafts with bounded entry and character counts.
- Attachment-picker duplicate-action guard.
- Voice shutdown on lifecycle and contact/session transitions, expected reply-session checks, capture cancellation, and generation-aware platform TTS/STT seams.
- Generation fencing in gateway directory refresh/activation and Wing Link profile inventory loading.
- Direct Agent capability/scope checks and independent Wing Link credentials.
- Exact source revision, checksums, signature checks, artifact download, and artifact smoke stages in the alpha release workflow.

### Observed gaps and hypotheses to validate first

1. A late attachment-picker result can outlive its original gateway/profile/session unless it captures and revalidates composer ownership.
2. Composer text and staged attachment do not share one generation-owned draft bucket.
3. Chat has automatic latest scrolling but no explicit follow/browse/restore ownership model or semantic post-refresh anchor.
4. Manual jobs refresh, detached terminal hydration, SSE keepalive liveness, and profile-bound approval response are proven consistency gaps; the wider A → B → A matrix determines whether more owners need changes.
5. Missing/duplicate Agent message IDs collapse presentation keys and completion observation; a fallback must remain presentation-only and non-content-derived.
6. Large Markdown/code/table behavior needs a measured 100 KB–1 MB work budget.
7. Hosted artifact names must agree before release work can bind dependency locks, artifacts, and device receipts in one final manifest.

### Contract- or evidence-gated work

- Provisional-session draft migration ships only if Wing has a real create-and-send flow whose provisional identity can become an Agent session identity.
- Schedule, skill, toolset, MCP, model, provider, Project, and Kanban mutations remain unavailable until advertised Agent contracts exist.
- Durable drafts or viewport state require an explicit private-data retention and secure-storage decision; the first implementation stays process-local.
- Push notifications require a separate account/plugin/relay contract and privacy review. Wing Link is not the relay.
- Physical voice qualification and release qualification attach to the exact artifact; tests and compilation are insufficient.

## Ordered delivery

| Priority | Workstream | Deliverable | Detailed plan |
| --- | --- | --- | --- |
| P0 | Composer ownership | Late picker results cannot cross resource identity; text and attachments clear only for their captured generation | [Chat continuity](2026-09-04-chat-continuity.md) |
| P0 | Async state audit | A → B → A tests for every profile-scoped resource; only current identity and generation can commit | [Resource consistency](2026-09-04-resource-consistency.md) |
| P0 | Release identity | One exact-artifact evidence manifest covering source, locks, artifacts, and receipts | [Release evidence](2026-09-04-release-evidence.md) |
| P1 | Viewport continuity | Follow/browse/restore state and semantic turn anchor after authoritative refresh | [Chat continuity](2026-09-04-chat-continuity.md) |
| P1 | Voice ownership | One explicit conversation operation identity across capture, send, reply, and playback | [Voice ownership](2026-09-04-voice-ownership.md) |
| P1 | Provenance | Gateway/profile/session/source/run state stays visible and accessible in Chat | [Provenance and notifications](2026-09-04-provenance-and-notifications.md) |
| P1 | Reconciliation certainty | Preserve or strengthen fail-closed send gating when canonical ordering cannot be proven | [Resource consistency](2026-09-04-resource-consistency.md) |
| P2 | Rendering budgets | Benchmark giant Markdown, code lines, tables, and streaming tails before selecting an optimization | [Resource consistency](2026-09-04-resource-consistency.md) |
| P2 | CI scaling | Measure first; add timing-aware test sharding only after the threshold in the release plan is exceeded | [Release evidence](2026-09-04-release-evidence.md) |
| P3 | Notifications | Produce a privacy and contract proposal; implement nothing until every gate is met | [Provenance and notifications](2026-09-04-provenance-and-notifications.md) |

## Program acceptance gates

- [ ] Each behavior change starts with a focused failing behavioral test.
- [ ] Delayed callbacks capture gateway, profile, session, operation generation, and resource identity as applicable.
- [ ] Explicit notification/deep-link navigation wins over automatic restoration.
- [ ] Server state wins after reconnect; Wing never silently replays queued mutations.
- [ ] Logical run completion is independent from optional reveal animation.
- [ ] No content-derived transcript marker is persisted.
- [ ] Large-render optimization is selected from benchmark evidence, not copied from SwiftUI.
- [ ] Notifications contain only an opaque one-time routing handle plus a non-sensitive category.
- [ ] Release receipts name the exact artifact digest they exercised.
- [ ] `dart format --output=none --set-exit-if-changed lib test integration_test`, `flutter analyze`, `flutter test --concurrency=1`, `(cd wing_link && go test ./...)`, the relevant artifact builds, and `git diff --check` pass before program closeout.

## Explicit non-goals

- Dashboard-first REST or `/api/ws` transport.
- Cookies, tickets, or credentials in query strings.
- Credentials injected into WebView JavaScript.
- Private-LAN HTTP allowlists or network-location authorization.
- Client-owned copies of Agent domain state.
- Third-party clarification decisions or Wing Link push relay behavior.
- Wake-word claims without an implemented reviewed adapter and physical evidence.
- A shared coordinator merely to imitate Conduit’s `AppState.swift`.
- Timing-aware CI sharding before measured suite duration justifies its maintenance cost.

## Dependencies and completion evidence

Execute Chat Task 1 first, then its draft store. Resource consistency's read
audit and release manifest design can proceed independently; serialize edits to
shared chat files. Finish reconciliation certainty before wiring authoritative
viewport restore. Voice consumes the same resource-identity rules, not the draft
store. Provenance can ship independently of notifications. CI sharding and
durable storage are decision gates, not unconditional implementation tasks.

For each task record: status (`not started`, `in progress`, `verified`,
`not applicable`, or `blocked by contract`), source revision plus dirty-state
description, exact test command/result, exercised target, artifact digest when
applicable, and remaining limits. A passing existing regression closes an audit
item without requiring a rewrite. Never mark a task verified from this plan alone.

## Audit coverage map

| Supplied finding | Owning task |
| --- | --- |
| Generation-safe sends, text/attachments, late picker/image normalization | Chat Tasks 1–2 |
| Provisional migration and private durable drafts | Chat Tasks 3 and 6 |
| Missing/duplicate presentation IDs without invented canonical identity | Chat Task 3A |
| Follow/browse/restore, canonical IDs, explicit navigation, layout changes | Chat Tasks 4–5 |
| Every inventory, deferred callback, cache write, approval, A → B → A | Resource Tasks 1–2 |
| Transaction-scoped login and replacement connection rollback | Resource Tasks 2 and 4 |
| Durable history/live projection/reveal, ordering certainty | Resource Task 3 |
| Bounded Markdown parsing and giant tables/code | Resource Task 5 |
| Voice ownership, barge-in, mute/pause, cancellation, physical checks | Voice Tasks 1–3 |
| Profile/gateway/source/run provenance and accessible polish | Provenance Task 1 |
| Exact scopes, no shadow administration or broad parity claims | Provenance Task 2 |
| Optional private notifications; no relay decisions | Provenance Task 3 |
| Exact tested SHA/artifact, locks, receipts, aggregate CI, sharding | Release Tasks 1–3 |
| Hosted artifact-name agreement between producer and receipt consumers | Release Task 0 |
| No tickets in URLs, WebView secrets, broad navigation, insecure relay | Resource Task 4 and Provenance Task 3 |
| MCP and wake-word marketing beyond reachable implementation | Provenance Task 2; no inferred support |

## Program closeout

After each P0 plan completes, update `ROADMAP.md`, `docs/quality/evidence-matrix.md`, and the affected route/runbook only with evidence earned by that exact change. Re-read this roadmap before starting P1; remove tasks made obsolete by upstream Hermes Agent contracts or already-proven Wing behavior.

Run the complete gate in `CONTRIBUTING.md`, including the deterministic web build,
`npm run web:e2e`, and `npm audit`. Record failures independently of whether they
predate the slice. Physical Android voice and Linux service/rollback receipts
remain separate from fixture and compilation results. Implementation evidence
does not establish new platform support.

## Execution receipt (2026-09-04)

Source: `5cd4400e582590e6d1d6337a2bbfc32291b36f0e` plus uncommitted changes in
an already heavily modified worktree. No commit, push, upstream change, hosted
release, device installation, or live service operation was performed.

Implemented slices:

- Chat: bounded process-local generation-owned drafts, picker/read/normalization
  fencing, exception-safe draft restoration, unique authoritative viewport
  anchors, presentation-only fallback keys, explicit Latest activity, and a
  foreground canonical-refresh seam. Unknown session source no longer becomes
  an invented `api_server` attribution.
- Resources: current-owner/newest-request guards, origin-bound approval decisions,
  detached terminal hydration retry retention, and SSE comment liveness. See the
  [resource receipt](2026-09-04-resource-consistency.md) for the audited matrix.
- Voice: conversation/run ownership, cancellation and disposal, separate output
  mute/input pause, and modal owner fencing. See the
  [voice receipt](2026-09-04-voice-ownership.md) for remaining interruption limits.
- Delivery: exact input/artifact manifests, digest-bound receipts, sanitized manual
  recorders, complete test discovery, aggregate gates, and timing measurement.
  See the [release receipt](2026-09-04-release-evidence.md).
- Product: [retention](../../product/continuity-retention-proposal.md),
  [notifications](../../product/notification-contract-proposal.md), and
  [claim audit](../../product/capability-claim-audit.md) documents. No notification
  transport or durable draft store was introduced.

The program is **not complete**. Remaining implementation includes typed terminal
send outcomes (normal completion can still represent a failed run), candidate
connection activation/rollback, initial live-run lease/order certainty, and the
full lifecycle, voice interruption, and accessibility matrices. The broader
HTTP policy discrepancy requires a decision before transport edits. Provisional
draft migration remains inapplicable while composing requires an Agent session.
Durable recovery and notifications remain contract/retention gated. CI sharding
requires timing history; rendering optimization requires successful measurements.
Physical voice, signed distribution, and Linux service rollback remain unqualified.

Validation receipts are recorded below after the integrated checks finish.
