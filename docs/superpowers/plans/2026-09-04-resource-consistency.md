# Resource Consistency Implementation Plan

### Additional connection checkpoint (2026-09-04)

A deferred secure-store save reproduced a stale connection-attempt completion
disconnecting a newer attempt. `_connectToEndpoint` now rechecks form generation,
mounted state, and channel instance after connect, save, and disconnect awaits.
The new regression in `hermes_chat_screen_auth_recovery_test.dart` failed before
the guard and passes afterward. The integrated auth/tips/viewport/rich suites
pass 88 tests; separate endpoint/transport/redaction suites pass 55 tests.
This fixes stale post-save UI/connection cleanup, **not transactional storage**:
an already-started obsolete secure-store write may still finish. Serialize or
transactionally commit credential writes in the remaining connection work;
do not mark replacement activation or credential publication complete.

> **For agentic workers:** Use executing-plans task-by-task. Checkboxes describe future work; do not commit, publish, or delegate without authorization.

**Goal:** Prevent stale asynchronous work from changing the selected resource and keep authoritative chat reconciliation and large responses dependable.

**Architecture:** Fix the state writer in existing channel parts and feature owners. Reuse connection/profile generations; add per-resource request generations where overlap is possible. Presentation guards do not substitute for channel/cache guards.

**Tech Stack:** Repository-pinned Flutter 3.44.2, Dart, Riverpod, HermesChannel, deterministic fake transports. No new dependency assumed.

## Global Constraints

- Follow the [program constraints and source baseline](2026-09-04-conduit-adaptation-roadmap.md).
- Explicit Agent resource identity and exact capability/scope checks apply to every operation.
- No queued mutation replay after reconnect, inferred ordering from text, or persistent shadow history.
- Consult local Agent source and nearest tests before changing any wire contract; read its AGENTS.md first. Upstream clones stay read-only.
- Each behavioral change starts with a reproducing test. An already-passing invariant needs no production rewrite.

## Task 1: Inventory and fence resource loads

**Files:** inspect/modify `lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart`, `hermes_api_channel_profiles.dart`, and `hermes_api_channel_providers.dart` in that same directory; inspect `lib/core/hermes/channel/hermes_api_channel.dart`. Test `test/core/hermes/channel/hermes_api_channel_tests/lifecycle_race_tests.dart` through its parent `test/core/hermes/channel/hermes_api_channel_test.dart`.

**Current evidence:** profile/model loads already capture connection plus profile-selection generations; tool inventory captures profile plus client; detailed health is correctly connection-owned. `_reloadJobs` is a proven gap: it passes the current profile into `listJobs` but checks only connection identity after await, so profile A can overwrite profile B on the same connection. These are different protections, not proof that every path is broken.

**Interfaces:** Keep public `loadJobs()`, `loadToolInventory()`, `loadProviders()`, and `loadModels()` unchanged. A result may commit only when client identity, connection epoch, selected resource, selection epoch, and latest request for that resource still match. Apply the same rule to failure and loading state.

- [ ] Trace profiles, capabilities, models/options, provider state, skills, toolsets, jobs, detailed health, and Projects from request to state writer/cache. Record each writer, identity, epoch, and test in this document. For unavailable Project inventory, record `blocked by contract`; add no speculative request.
- [ ] In the existing fake HTTP harness defer two responses for the same resource. Start old A, switch B, return A, start new A, complete new A, then old A. Assert current data, error, and loading state describe new A. Repeat with an old failure and reconnect to the same origin/profile using a new client.
- [ ] Cover two refreshes without a profile change. The later request wins even if the first finishes last. For simultaneous skills/jobs errors, verify one completion does not overwrite the other's optional-resource error entry.
- [ ] Add missing epochs at the state writer, before starting requests. Invalidate on owner changes, disposal, and replacement; merge only the affected error entry into current state at commit time.
- [ ] Fix `_reloadJobs` first: capture `final profileId = _state.selectedProfileId`, send that exact value, and gate both success and error through `_isConnectedProfile(client, profileId)`. Add A → B and A → B → A deferred-response tests at `test/core/hermes/channel/hermes_api_channel_test.dart:1778-1838`. Add a per-job request generation only if same-identity overlap is proven reachable.
- [ ] Run `flutter test test/core/hermes/channel/hermes_api_channel_test.dart`. Expected: current results survive reversed completions; stale responses neither clear current errors nor release another request's loading indicator.

## Task 2: Fence deferred UI work and connection replacement

**Files:** inspect/modify `lib/features/providers/screens/providers_screen.dart`, `lib/features/providers/widgets/model_picker_sheet.dart`, `lib/features/tools/screens/tools_screen.dart`, `lib/features/schedules/screens/schedules_screen.dart`, `lib/features/gateway/screens/gateway_screen.dart`, `lib/features/profiles/screens/profiles_screen.dart`, `lib/features/hermes_chat/gateways/hermes_gateway_directory.dart`, `lib/features/hermes_chat/gateways/gateway_contact_cache.dart`, `lib/features/hermes_chat/messaging/approvals/hermes_approval_queue.dart`. Tests: corresponding feature suites plus `test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart` and `test/features/hermes_chat/messaging/approvals/hermes_approval_queue_test.dart`.

**Interfaces:** Preserve existing providers and activation methods. A UI callback captures owner identity plus request epoch, and updates only its owner's presentation. Approval actions additionally bind the original approval/run identity; selection changes never retarget an approval.

- [ ] Audit scheduled post-frame loads, picker completions, busy-state cleanup, cache writes, retry callbacks, approval responses, and stream flush timers. Chat picker and viewport implementation belong to the [chat plan](2026-09-04-chat-continuity.md); avoid duplicate fixes.
- [ ] Defer refresh in Tools/Schedules, change gateway, then finish the old request with an error. Assert no error banner on the replacement gateway and a newer refresh stays busy. Extend to same-name resources on different gateways and A → B → A.
- [ ] Write the profile-switch approval regression first. `HermesApprovalRequest` already stores its originating profile/generation, but `HermesChannel.respondToApproval` currently accepts only approval/run/decision and production posts with the newly selected profile. Carry the originating profile through the response command, require exact run/approval/profile/generation plus advertised endpoint/scope before POST, and never default to current selection. Test cache completion after removal/revocation so removed entries cannot reappear.
- [ ] Exercise successful and failed replacement activation while predecessor A streams. B becomes active only after it is usable; failure preserves A, its session, and stream. Superseded B must close only B's candidate resources, never subsequently selected C.
- [ ] Preserve the existing gateway-directory transaction if it passes. If profile switching bypasses it, implement the smallest candidate-then-activate sequence with explicit rollback, independent credentials, and bounded candidate lifetime. Do not create a second long-lived channel coordinator.
- [ ] Run `flutter test test/features/providers test/features/tools test/features/schedules test/features/gateway test/features/profiles test/features/hermes_chat/gateways test/features/hermes_chat/messaging/approvals`.

## Task 3: Establish authoritative reconciliation certainty

**Files:** inspect/modify `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart`, `lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart`, `lib/core/hermes/channel/hermes_channel_state.dart`, `lib/features/hermes_chat/controllers/hermes_channel_observation.dart`, `lib/features/hermes_chat/presentation/hermes_chat_timeline.dart`. Tests: `test/core/hermes/channel/hermes_api_channel_tests/run_transport_tests.dart`, `run_failure_tests.dart`, and `session_mutation_tests.dart` in the same directory; `test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart`.

**Interfaces:** Preserve `hasUnreconciledRun` as the public send gate unless a behavioral test proves it cannot express the needed state. Only authoritative run/message identity and ordering evidence resolve uncertainty. A future reveal animation consumes text; it never determines run completion or clears reconciliation debt.

- [ ] Trace current detached-run reconciliation and upstream message ordering/IDs. Record which evidence resolves locally submitted turns, which responses are paginated/incomplete, and which terminal failures are known versus uncertain.
- [ ] Add deferred-history tests: missing final chunk; terminal event before history; duplicate/reordered events; send accepted with response lost; partial pagination; session deletion; reconnect during approval; stale flush after profile switch.
- [ ] Fix detached terminal hydration at `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart:1893-2008`: when status is terminal but canonical `_fetchTurns` fails transiently, retain the exact `HermesDetachedRunLease` and a retryable reconciliation state. Commit canonical history before releasing the lease; only authoritative terminal hydration or existing typed deletion policy may release it. Test channel recreation after failed hydration to prove the durable retry survives without replay.
- [ ] Fix SSE liveness at `lib/core/hermes/sse/hermes_sse_event_decoder.dart:208-235` and messaging timer code at `hermes_api_channel_messaging.dart:1818-1828`: syntactically valid comment-only frames re-arm transport liveness but emit no domain event or comment text. Repeated keepalives followed by completion must not timeout; a connection with no bytes still must.
- [ ] Assert uncertain submission blocks another send until authoritative resolution, without replay. A failed refresh retains the gate and exposes recovery; confirmed deletion exposes session selection rather than an endless spinner.
- [ ] Strengthen existing transitions before adding a second certainty store. Never equate matching prompt text, time proximity, list position, or terminal animation with authoritative order.
- [ ] Do not reconstruct reasoning/tool chronology from local shadow events after reconnect. Current Agent history mapping drops `role=tool` and exposes no durable reasoning/tool kind; measure current Agent payloads and require an authoritative bounded history contract before planning recovery.
- [ ] Hold presentation animation/layout work while emitting a terminal event. Logical terminal state must advance immediately; send availability still depends on canonical certainty. If Wing has no reveal layer, record that and add no animation.
- [ ] Run `flutter test test/core/hermes/channel/hermes_api_channel_test.dart test/features/hermes_chat/controllers/hermes_channel_observation_test.dart test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart`.

## Task 4: Audit connection transactions and reconcile security wording

**Files:** inspect `lib/features/hermes_chat/screens/state/hermes_chat_connection.dart`, `lib/core/hermes/setup/`, `lib/core/hermes/client/platform/hermes_api_transport_io.dart`, `lib/core/wing_link/wing_link_transport_io.dart`, and `lib/shared/security/wing_redaction.dart`. Documentation: `SECURITY.md`, `docs/adr/security-and-privacy.md`, `docs/security/threat-model.md`. Tests: `test/core/hermes/setup/secure_hermes_endpoint_store_test.dart`, `test/core/hermes/client/platform/hermes_api_transport_io_test.dart`, `test/core/wing_link/wing_link_transport_io_test.dart`, `test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart`.

**Interfaces:** A candidate connection owns credentials until validation succeeds and its generation remains current. Origin comparison includes scheme, canonical host, and effective port. No Dashboard cookies/tickets or WebView login are introduced.

- [ ] Document the supplied loopback-only rule versus the working ADR/SECURITY direct-Agent exception. Keep the supplied stricter constraint for this program; prepare matching documentation and focused transport tests before any transport change. Do not alter the user's in-flight exception implementation as an incidental polish edit.
- [ ] Trace validation, secure-store write, active-connection publish, cancellation, and disconnect. Prove a failed or stale candidate cannot publish credentials or clear the winning connection's credentials.
- [ ] Cover embedded URL credentials, query/fragment input, effective-port changes, redirect origin changes, stale validation success/failure, missing/changed Wing Link SPKI, and Agent/Wing Link credential separation with deterministic redacted inputs.
- [ ] Apply origin and transaction fixes only where tests demonstrate a gap. Do not add biometrics, cookies, cloud access injection, or a trust exception to match Conduit.
- [ ] Run the four named tests plus `flutter test test/shared/security/wing_redaction_test.dart`. Report unresolved policy discrepancies before claiming security closeout.

## Task 5: Measure and bound large transcript rendering

**Files:** inspect/modify `lib/features/hermes_chat/presentation/hermes_rich_text.dart` and `hermes_chat_timeline.dart` in the same directory. Create `integration_test/hermes_transcript_performance_test.dart` and `docs/quality/transcript-performance.md`. Extend `test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart`.

**Interfaces:** `HermesRichText.data` remains complete authoritative text. Preview/chunking is a disposable presentation projection; copy/export preserves full text. Preserve safe links, inline-image budgets, selection, semantics, and viewport ownership.

- [ ] Generate synthetic 100,000-byte and 1,000,000-byte cases: paragraphs, fenced code, one giant line, wide/deep tables, malformed/unclosed fences, and streaming tails. Never use real transcripts or fetch remote images.
- [ ] Record release/profile target, source/artifact identity, device class, cold/warm parse/layout time, p50/p95 frame time, worst interaction stall, and peak memory. Use ten measured repetitions after two warmups; stream 1 KiB updates at 20 Hz and exercise scrolling/stop concurrently.
- [ ] Adopt initial investigation thresholds, not measured claims: p95 frame work above 32 ms on the named 60 Hz target, interaction stalls above 100 ms, or memory growth that fails to settle after five open/close cycles. Record actual device memory limits before selecting an absolute memory cap.
- [ ] If thresholds fail, first reduce unnecessary whole-message rebuilding; then evaluate immutable completed blocks plus a bounded live tail. Preserve constructs spanning boundaries. If a 1 MB block remains expensive, offer an accessible bounded preview with explicit full-text access; never silently truncate canonical data.
- [ ] Compare before/after on the same configuration and target. Add correctness cases for split fences/tables, copy, reduced motion, and 200% text. Skip optimization if measurements pass.
- [ ] Run `flutter test test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart`, `flutter analyze`, and the new integration target on the explicitly selected device. Record its actual device-specific command and receipt in the performance report; widget timing is not device performance evidence.

## Completion

### Execution receipt — 2026-09-04

Implementation is partial; unchecked matrix items remain outstanding. Preserved
the existing dirty worktree and made no commits or upstream changes.

Implemented and reproduced before the fix:

- Jobs: connection/client, profile-selection epoch, explicit profile, and newest
  jobs request now fence success and failure. Tools use the same fences and merge
  only their own optional-error entries into current state.
- Seventeen jobs/tools regressions cover reversed overlapping refreshes,
  A → B, A → B → A, replacement clients, old failures, and simultaneous optional
  resource errors (eleven failed before the fixes).
- Model assignment and its 412 recovery now capture the profile-selection epoch;
  success and conflict roundtrip regressions failed before this fix.
- Providers, models, model options and detailed health now also reject superseded
  reads of the same resource. All four reversed-completion tests failed before
  their newest-request fences were added.
- `reconcileActiveSession()` refreshes the selected idle session through the
  existing canonical history path and preserves live streams. Session selection
  now checks the profile epoch; the foreground roundtrip regression failed before
  that fence. History cache writes also reject changed connection/profile owners.
- Detached terminal stream hydration retains its durable lease on transient
  history failure. Recovery status must load canonical history before releasing
  the lease. The regression recreates the channel with history still unavailable
  and confirms the lease survives until a successful refresh.
- Valid comment-only SSE frames invoke a content-free liveness callback; no
  domain event or comment text is emitted. Keepalive and no-byte timer tests
  distinguish a live connection from a silent one.
- Tools and Schedules invalidate refresh ownership on resource changes and
  gateway activation. Old failures cannot show replacement-resource feedback or
  clear newer busy state; both roundtrip tests failed before these changes.
- Approval commands carry the original immutable request and validate connection,
  profile-selection epoch, profile, session/run and command identity before POST.
  An emitted approval cannot be retargeted after a profile roundtrip. Old queue
  completions after reset no longer affect replacement queue errors/busy state;
  the queue regression failed before its epoch fence.

#### Resource writer matrix

| Writer | Current ownership evidence | Remaining work |
| --- | --- | --- |
| Initial health/capabilities/catalog/sessions | Connection generation + client; single connect transaction | Preserve existing connection tests |
| `_selectProfile` inventory batch | Selection generation + connection/client; explicit request profile | Candidate selection failure already preserves the prior profile until final commit |
| `_reloadJobs` | Client/connection/profile/selection/newest request | Implemented, 8 delayed success/failure cases |
| `_reloadToolInventory` skills/toolsets | Same owner tuple + newest tool request; error merge at commit | Implemented, 8 delayed cases + independent-error regression |
| `_reloadDetailedHealth` | Connection/client, connection-owned, newest request | Reversed refresh regression passes |
| `_loadProviders`, `_loadModels`, `_loadModelOptions` | Connection/client/profile-selection epoch and selected profile when scoped; newest request | Three reversed refresh regressions pass |
| `_assignModel`, 412 `_refreshModelInventory` | Connection/client/profile-selection epoch and explicit profile | Profile roundtrip fixed; overlapping inventory/mutation ordering not fully audited |
| Profile list mutation refresh | Connection/client | Latest-request ordering across simultaneous mutations not yet proven |
| Session history/cache | Connection/client/profile epoch; selection generation at presentation writer | Broader overlapping pagination/history matrix outstanding |
| Provider screen reads | Existing load generation/context key, per-operation capability checks | Post-frame ownership dispatch and complete same-origin reconnect matrix outstanding |
| Tools/Schedules refresh UI | Refresh generation, resource-change observation | Roundtrip/newer busy/error regression passes |
| Gateway health UI | Existing local busy/error state | Equivalent refresh-generation regression/fix outstanding |
| Profile Wing Link inventory | Existing `_wingLinkLoadGeneration`, gateway and mounted checks | Existing feature suite preserved; full deferred matrix not newly added |
| Gateway summaries/cache | Existing global/per-gateway refresh generations; removed-config checks | Existing removal-in-flight/stale-refresh tests pass; arbitrary delayed cache-write ordering not fully audited |
| Projects inventory/mutations | No authoritative reachable inventory contract | Blocked by contract; no speculative requests added |

#### Important uncompleted boundary

`HermesGatewayDirectory.activate()` disconnects its existing active channel
before it connects the replacement, and publishes `_activeContactId` before
connection validation. This does **not** satisfy the proposed candidate-before-
retirement requirement. The directory owns one final channel reference; a proper
handoff needs an explicit channel ownership design, not a second hidden
coordinator or a claim that the current transaction already meets the plan.
No coordinator rewrite was made in this slice.

The requested exhaustive detached ordering/pagination/submission-loss matrix is
not fully added. Existing run failure/transport tests remain in place. The local
Agent `_handle_session_messages` returns bounded latest pages (500 maximum),
with canonical IDs and order; its nearest `test_session_messages_default_to_latest_bounded_page`
confirms the boundary. `_handle_run_events` sends 30-second comment keepalives.
Run approval resolves within the requested run's approval session. These are
Agent source contracts; no Dashboard endpoints were adopted. Durable tool or
reasoning chronology is still unavailable through Wing's mapped history and was
not reconstructed from local shadow events. Wing has no reveal-animation layer
to gate run completion on.

Two existing live-send paths still need a separate certainty fix:
`_currentAssistantReplyIndex` uses normalized prompt text and pre-send list
position to recognize a reply, and initial live-run completion releases a lease
before best-effort history hydration. Neither is equivalent to authoritative
message/run identity. This slice fixes detached reattachment hydration; it does
not certify all live-send reconciliation as meeting Task 3's stronger ordering
contract.

#### Validation

`flutter test test/core/hermes/channel/hermes_api_channel_test.dart
test/features/providers test/features/tools test/features/schedules
test/features/gateway test/features/profiles test/features/hermes_chat/gateways
test/features/hermes_chat/messaging/approvals
test/features/hermes_chat/controllers/hermes_channel_observation_test.dart
test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart
--reporter expanded`: **593 passed** at this slice's checkpoint. Earlier core/SSE/
approval check: **280 passed**. Final integrated suite is owned by the program
closeout and must be rerun after all concurrent changes.

After the final overlapping-read fences, the focused core/SSE/Tools/Schedules/
approval suite passed **314 tests**. `git diff --check` passed. Formatting covered
the changed Dart paths. The final analyzer follow-up is part of integrated
closeout; no native device was exercised by these deterministic tests.

The [performance receipt](../../quality/transcript-performance.md) documents the
new native benchmark harness and the attempted Linux profile run, blocked by a
missing `gstreamer-1.0` development dependency. There are no performance results
and no rendering optimization or physical-device support claim.

Record the resource race matrix and benchmark receipt, then update the
[program](2026-09-04-conduit-adaptation-roadmap.md). Run the complete repository
gate after integrating shared channel changes. No tests or performance
measurements were executed by writing this plan.
