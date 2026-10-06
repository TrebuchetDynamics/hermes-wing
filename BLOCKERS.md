# BLOCKERS

This file contains only hard blockers that require user action.

## Active

### BLK-20261006-W01 — Agent target for the live Desktop workflow qualification

- Status: ACTIVE
- Category: USER_DECISION
- Owner: user
- Task/Card: PARITY-LIVE-WORKFLOW (goal M1)
- Blocked scope: only the end-to-end live qualification (real generation, approval, Stop, restoration) against a running Agent
- Why blocked: it needs a named isolated Hermes Agent target with provider credentials; credentials are a red line for agents
- Evidence: TODO.md PARITY-LIVE-WORKFLOW; docs/quality/2026-10-04-desktop-cron-0322-auth-preflight.md
- User action required: name the Agent target (e.g. a dedicated local `wing-qa` profile) and confirm it may use its own provider key
- Default if no answer: no live qualification; M1's other slices (dismissal, pair read, native relaunch) proceed
- Proceeding with: all other M1 and Desktop parity work
- Asked: Claude Code session, 2026-10-06
- Resume condition: owner names the target
- Created: 2026-10-06
- Last checked: 2026-10-06

### BLK-20261006-W02 — Physical-device run for M2 Android recovery

- Status: ACTIVE
- Category: USER_INPUT
- Owner: user
- Task/Card: M2-DEVICE-QUALIFICATION (goal M2)
- Blocked scope: only M2's final qualification; 29 of 31 M2 tasks are done
- Why blocked: proof needs a named physical Android device running the death-to-completion run; agents cannot supply hardware
- Evidence: goals.json M2 (unverified, 29/31 tasks done); TODO.md M2 entries
- User action required: run (or allow an agent to run via adb on a connected device) the named-device qualification
- Default if no answer: M2 stays parked at priority 90; agents prepare nothing further for it
- Proceeding with: Desktop-first goals
- Asked: Claude Code session, 2026-10-06
- Resume condition: a device run receipt exists
- Created: 2026-10-06
- Last checked: 2026-10-06

### BLK-20261005-003 — Install Linux desktop build packages (sudo)

- Status: ACTIVE
- Category: SUDO
- Impact: SCOPE_BLOCKING
- Owner: user
- Task/Card: PARITY-NATIVE-RELAUNCH in [TODO.md](TODO.md); no tracker card is assigned by this entry.
- Blocked scope: Native Linux compilation and checks that depend on that build. Browser, other-platform, source inspection and Dart/Flutter checks do not depend on these Linux packages.
- Why blocked: The Linux desktop build links libsecret and GStreamer; their development packages are system packages that need root to install. No user-space alternative is configured.
- Evidence: `pkg-config --exists` reports MISSING for libsecret-1, gstreamer-1.0, gstreamer-app-1.0, gstreamer-audio-1.0, gstreamer-video-1.0 and gstreamer-plugins-base-1.0 (checked 2026-10-05T14:58Z). Earlier picker reports repeated "native/browser/live parity remains unverified".
- User action required: Install the three development packages only if native Linux qualification is selected: `sudo apt install libsecret-1-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev`.
- Default if no answer: Do not install system packages. Continue documentation, contract inspection and checks that do not require native Linux compilation.
- Proceeding with: Default applied; only the native Linux build and its dependent runtime checks are skipped. Other platforms and source/deterministic work do not depend on this package question.
- Resume condition: The six pkg-config modules above resolve; agents then run the native Linux build and parity checks.
- Created: 2026-10-05T14:58Z
- Last checked: 2026-10-06T02:30:03Z; a fresh read-only pkg-config check still reports all six modules missing. No installation or runtime qualification was attempted.

## Resolved

### BLK-20261005-001 — Admit the passive global-session lifecycle seam

- Status: RESOLVED
- Category: USER_DECISION
- Resolved: 2026-10-05T13:06:07Z
- Resolution: Premature user escalation withdrawn; an autonomous in-scope investigation remains. The original card explicitly admits minimal shared projection/admission extraction where needed. tools/global_session_access/README.md states guarded selection is a viable narrow extension and the failed weak-listener candidate does not prove every passive design impossible. Route the original Wing card to assess authoritative observation/invalidation of an already-created directory without changing startup semantics, triggering reads or inventing shadow ownership. Expensive startup/lifecycle redesign remains excluded. No implementation or acceptance is claimed; do not manufacture a replacement user gate.
- Evidence: Original t_1c1e6f37 current contract and tools/global_session_access/README.md:16-21,33-49; eager provider startup at lib/features/hermes_chat/providers/hermes_channel_provider.dart:47-56 and directory start:334-367. Current card preserved at /home/xel/.hermes/fleet-governor/blockers-reconciliation-20261005T124629Z/t_1c1e6f37-rechecked.json. Read-only audit trace /home/xel/.hermes/cache/delegation/live/deleg_879427cc/task-1.log. Juan's reconciliation request requires agents to exhaust already-authorized paths before escalation.
- Task/Card: t_1c1e6f37
- Former blocked scope: Persistent shell access to loaded sessions
- Former reason: Original card stops before an expensive directory/startup lifecycle redesign. Reading the provider initializes inventory refresh and saved-owner restoration; the tested alternative also initializes it. The broader seam is explicitly excluded.
- Former evidence: Native original blocked run and tools/global_session_access/README.md; latest picker receipt /home/xel/.hermes/profiles/wing/autogoal/picker-audits/20261005-115156-noop.json.
- Former user action requested: Authorize a bounded startup/passive-observation seam on t_1c1e6f37, or keep this slice parked.
- Former resume condition: Exact same-card scope admission is recorded; a project-owned native50 continuation can then be prepared without weakening ownership or zero-extra-read criteria.
- Created: 2026-10-05T12:12:31.155457+00:00
- Last checked: 2026-10-05T13:06:07Z

### BLK-20261005-002 — Resolve the original narrowed dismissal stop branch

- Status: RESOLVED
- Category: USER_DECISION
- Resolved: 2026-10-05T13:06:07Z
- Resolution: Premature user escalation withdrawn; supported-flow investigation is not exhausted. Native run139 only verified the narrowed modal-blocked reset case, not exhaustive supported-flow unreachability or a production repair. The original contract already permits tracing profile-switch reset, channel rebinding, clearPending and exact-turn invalidation with deterministic widget harnesses. Route those paths to Wing, serially with its existing work; do not ask Juan to prescribe ordinary test coverage. Do not bypass the modal barrier, invoke hidden callbacks, speculate a repair, force done or weaken final review. The disposition disagreement remains in Kanban; no closure or product acceptance is claimed.
- Evidence: Current t_6233c1c5 verification/stop contract, native run139 rejection and /home/xel/.hermes/profiles/wing/autogoal/approval-dismissal/native-review.md:3-14; hermes_chat_screen.dart:1034-1063, hermes_chat_connection.dart:4-24 and hermes_approval_queue.dart dismissStoppedTurn:134-157 identify further admitted source paths. Current card preserved at /home/xel/.hermes/fleet-governor/blockers-reconciliation-20261005T124629Z/t_6233c1c5-rechecked.json. Read-only audit trace /home/xel/.hermes/cache/delegation/live/deleg_879427cc/task-1.log.
- Task/Card: t_6233c1c5
- Former blocked scope: Disposition of the narrowed no-reproduction receipt
- Former reason: The governor already used supported same-card review entry. Native reviewer run139 verified the narrowed stop receipt but the goal judge rejected closure for lacking exhaustive unreachability and RED/repair. Repeating unchanged tests cannot resolve this contract/stop-branch disagreement.
- Former evidence: Original card comments and run139; /home/xel/.hermes/profiles/wing/autogoal/approval-dismissal/native-review.md and native-review-commands.json. Exact rejection: exercised modal-blocked reset flow does not establish all supported invalidation flows unreachable; required widget RED and repair not delivered.
- Former user action requested: Decide on t_6233c1c5 whether to accept the original narrowed no-reproduction stop disposition through supported lifecycle authority, or specify the additional supported-flow coverage required within its scope.
- Former resume condition: The same-card disposition or concrete additional coverage is explicit; no forced done, review waiver, speculative repair or replacement.
- Created: 2026-10-05T12:12:31.155457+00:00
- Last checked: 2026-10-05T13:06:07Z
