# WING-TASK-407: production serve conversation restoration

Status: local implementation and two-process Linux fixture passed;
exact-source independent native review pending.
This is bounded Linux deterministic qualification, not closure of
CONNECTION-PATHS, the daily-use milestone or live Agent support.

## Behavior and ownership

Deliberately enabling chat on a Linux loopback serve session remembers only its
exact authenticated origin, profile, stored/runtime session identities, replay
metadata and uncertainty fence. The credential and pointer are written together
in the existing platform secure-storage dependency under a new Wing-owned slot.
No transcript, draft, prompt, approval answer or Stop command is persisted.
Read-only connection alone does not save this pointer or grant chat authority.
Existing gateway records and inert legacy secure slots are untouched.

Startup uses the existing directory/provider lifetime to restore this pointer
before considering gateway defaults. The native read client validates the exact
profile and stored session, including a session absent from the first inventory
page. It then acquires a fresh authenticated single-use ticket and performs the
existing fixed chat negotiation. REST readiness is never mutation authority.
A denied read preserves the saved pointer and offers the public Chat **Retry**
control. Neither failure nor Retry chooses a page-zero replacement session.
Explicit disconnect or a new endpoint connection clears the owned restoration
slot; disposing the app/channel does not. Profile/session changes still retire
old subscriptions and approvals; chat on a newly selected conversation requires
explicit enablement. Until then the last deliberately enabled conversation is
what startup remembers.

The adapter brackets canonical history with two exact-runtime replay reads.
Advancing replay or live events beyond the final barrier leave input blocked;
Retry must obtain a settled snapshot. Replay text is never appended to canonical
history. Wrong-owner, duplicate and stale events cannot edit the conversation.
Saved runtime IDs/epochs/cursors are observations, not authority on a new socket;
resume establishes fresh ownership and a fresh barrier even if IDs are unchanged.

Send writes an uncertainty fence before issuing its single RPC and disables
concurrent local submissions while that storage operation is pending. Stop reserves
the captured lifecycle synchronously, exposes the pending state to both public
callers, and writes the fence before its RPC. After storage it revalidates the
captured owner and running turn; completion or owner replacement suppresses the
interrupt, and overlapping Stops cannot issue another interrupt.
Unknown outcomes remain blocked until an
explicitly idle authoritative resume and settled canonical history are available.
Missing idle evidence, a running turn, failed history or advancing events do not
clear uncertainty. Recovery issues no prompt, approval response or interrupt.
A later deliberate Send is a new, single action, not a retry of the old command.

A native socket is not a durable detached-run guarantee. App foreground resume
still does not automatically reconnect this transport. Cold application startup
restores a previously enabled conversation; socket loss uses explicit Retry.

## Source trace

Read-only official Agent/Desktop reference:
`158fd638da1629c8e62caf9ade1515d162def8ab`. Reference and runtime were not modified.

- `tui_gateway/methods_session.py:2584-2598`: replay has per-runtime sequence,
  process epoch, truncation and open-request metadata; history is a separate read.
- `tui_gateway/server.py:3136-3168`: live resume captures authoritative running
  state and exact runtime/session identity. Snapshot receipt is not durability.
- `tests/tui_gateway/test_tui_gateway_event_replay.py:31-65,96-115`: monotonic
  per-session sequences and client-dispatchable event objects.
- `tests/tui_gateway/test_protocol.py:999-1034`: a running resume reports running,
  rather than treating a resume acknowledgment as a terminal turn.
- Official Desktop `apps/desktop/AGENTS.md:49-70,148-158`: durable versus runtime
  identity, scoped persistence and fresh-ticket authentication.
- Official Desktop
  `apps/desktop/src/app/session/hooks/warm-resume-replay-barrier.test.tsx:152-167`:
  reconnect replay barrier tied to the exact runtime/cursor. Wing uses its
  canonical-history barrier rather than copying Desktop cached stream state.

## Checks and evidence

Initial immutable base: `d8823ab6e7ce6909997f3816f7099d27a061f81e`.
The manifest-pinned initial `pass_workspace.py` returned `worker_start_admitted`
before the first edit. Manifest SHA256:
`56e723ec14f62a7dc72c9dd39ee7d5ec1511c4f6c7edc7057ee8d44add59e5e3`.
Helper bundle manifest SHA256:
`c4684c9b28d30201ddc9bb5d407dda3b2d9136effe19e3610274eebeb5361922`.

Execution commands are repeated by the mandatory `finish_task.py` receipt before
commit/review entry:

- `flutter pub get --offline --enforce-lockfile`.
- Changed Dart `dart format --output=none --set-exit-if-changed`.
- `flutter analyze --no-pub`.
- Focused lifecycle, serve chat and public-control targets named by the card.
- Recovery/storage/channel regression union including gateway/session restoration.
- `python3 -B integration_test/run_linux_local_serve_chat.py --self-check`.
- `python3 -B integration_test/run_linux_local_serve_restoration.py`.
- `git diff --check` and changed local documentation-link verification.

Two regression-first checks failed on the prior adapter: history could unlock
input while events advanced, and a live event newer than the returned final
barrier could be silently lost. Both now require reconciliation before input.
The new channel tests use separate channel instances, denied history, pending
history, exact non-default ownership, unknown Stop and late-restoration fencing.
Secure-store tests cover exact roundtrip, bounded malformed-owner/origin rejection
without deletion, and preservation of unrelated/inert slots.

Round-one independent review reproduced duplicate interrupts from overlapping
Stops and an interrupt after completion during a delayed secure-store save.
Rework adds three delayed-save regressions in the existing restoration target:
overlapping `stopTurn`/`stopActiveTurn`, terminal-during-save, and changed-owner-
during-save. Before the fix the first two failed; after the shared-path reservation
and captured-target revalidation all seven restoration tests passed. The rework
finish receipt reruns the full scoped gate and binds the new review candidate.

The isolated runner freezes Wing sources, SDK and locked packages, copies only
existing user-space native development dependencies, and launches two different
Linux GTK application processes against one authenticated loopback wire fixture.
The first performs one deliberate Send, one current approval and one Stop whose
reply is lost. The second initially receives denied history, then uses public
Retry and restores the exact non-default conversation before one later deliberate
Send. Expected cumulative mutation counts are `(1,1,1)` then `(2,1,1)`;
restoration itself adds no mutation. The runner verifies different native PIDs,
exact profile/stored/runtime ownership and every lazy-resume request. Its source
manifest, commands, process receipts and verification live under
`.task-evidence/t_d9e374e1/native-*/` and its owned HOME/XDG/DBus/state is removed.

This runner injects a test-only file implementation at the platform secure-storage
boundary, holding synthetic credentials only. It executes the production secure
pointer codec and channel/UI startup/Retry path, not the OS keyring. The earlier
read/chat journey remains deliberately nonpersistent and overrides its channel
without a recovery store; its updated exact RPC total is 23 (additional canonical
barrier reads), with its original mutation and ticket totals unchanged.

Initial native rehearsals exposed an incomplete readiness-file publication and
an unpumped composer update before clicking Send. The fixture now atomically
publishes readiness and pumps the real composer state before the action. These
failed rehearsals are not acceptance receipts. Final PASS, exact revision and
source fingerprints belong to the mandatory finish receipt and native review.

The successful pre-finish rehearsal took 80.049 seconds, with different native
PIDs, cumulative RPC counts 9 then 21 and freshly minted ticket counts 1 then 3.
Its manifest SHA256 was
`bca7a0a4fff34481514758b2ad8dadda63be71809a8ce4dee06b64cc9001f093`.
The final gate repeats execution with the added strict RPC/ticket/resume-count
assertions; that receipt, rather than this rehearsal, binds final acceptance.

## Method and limits

Ponytail: reuse the lifecycle/read adapter, HermesApiChannel, directory/provider
startup, Chat Send/approval/Stop/Retry controls, Flutter secure storage and existing
native snapshot/isolation helpers. Add a single bounded restoration slot, not a
transport registry, mutation queue, transcript store, background service or Agent
backend. No new dependency, upstream modification, secret discovery, system
package installation, inference or platform-authority expansion.

Implemented, fixture-qualified, reviewed, integrated and published are separate
states. This worker requests one independent same-card native exact-source review
and performs no integration, push, service change or deployment. Canonical ledger
closure and coordinator frozen-candidate broad gates remain separate.

NOT_CHECKED: real Agent authentication/generation, private credential acquisition,
OS keyring/hardware backing, detached-run durability, physical input/IME, screen
readers, SSH/Remote/Android/physical devices, release and distribution. A fixture
PASS never upgrades any of these to support claims.
