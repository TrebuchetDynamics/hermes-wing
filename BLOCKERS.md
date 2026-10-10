# BLOCKERS

This file contains only hard blockers that require user action.

## Active

### BLK-20261007-W04 — Separate disposable QA authentication for live Desktop

- Status: ACTIVE
- Category: USER_INPUT
- Owner: user
- Task/Card: PARITY-LIVE-WORKFLOW / t_a8a79cf5
- Blocked scope: only authenticated actual-Agent/provider qualification.
- Why blocked: W01 resolves target strategy, not test authentication. No approved
  QA bearer/provider access was supplied in this run; personal stores were not searched.
- Evidence: docs/quality/live-desktop-daily-workflow.md; the real launcher refuses
  no-input execution with zero network/mutations/inference; focused checks pass.
- User action required: make separate disposable QA Agent bearer access and
  openai-codex test authentication available through a supported secret-safe flow,
  identifying only the non-secret target/profile/session. Never send secrets in chat.
- Default if no answer: no inference, no personal credential discovery or copying;
  keep the existing three-generation/no-spending authorization unchanged.
- Proceeding with: tested read-only preflight, isolated production-client readiness
  target, attributed local commit and native review handoff. Provider-call-budget
  enforcement and the full UI journey remain engineering work, not owner questions.
- Asked: CLI task handoff, 2026-10-07; A) retain safe no-auth default; B) provide
  separately approved disposable QA authentication through the secret-safe flow.
- Resume condition: approved isolated test authentication is available. Authentication
  alone does not enable inference until its continuation budget is qualified.
- Created: 2026-10-07T18:27:30-06:00
- Owner answer: Telegram questionnaire, 2026-10-09T10:23:10-06:00: keep live qualification
  unverified for now; continue implementation and fixture QA. This is not
  authentication, permission to discover personal credentials, or a waiver of
  eventual live acceptance. No metered spending or service changes are authorized.
- Last checked: 2026-10-09T10:23:10-06:00


### BLK-20261006-005 — Waydroid device authorization and host connection

- Device question resolved on 2026-10-07: owner explicitly enrolled this host's
  public ADB key; independent `adb devices -l` and `get-state` confirm `device`.
  Visible Android consent was subsequently approved only after fingerprint
  comparison to that key, including persistent Always allow for the enrolled
  host. ADB authentication remains enabled.
- Delivered: matching isolated profile fixture APK installed; all three profile
  Maestro flows passed on Waydroid after repairing stale/ambiguous selectors.
  This proves deterministic profile flow behavior, not a live Agent connection
  or the broader all-feature Android matrix. Production app data was preserved.
- Receipt: `.task-evidence/waydroid-host-maestro-20261007/qualification.txt`.
- Status: ACTIVE
- Category: USER_INPUT
- Owner: user
- Task/Card: N/A — Waydroid app test and host Hermes connection request
- Blocked scope: authenticated live Hermes connection over SSH only.
- Why blocked: strict SSH to the owner-selected xel@localhost:2121 rejects
  available keys. The active Hermes gateway main process has no matching TCP
  listener in the inspected socket listing; an Agent API target remains unknown.
- Evidence: latest strict batch SSH probe exits 255 with authentication denied;
  `systemctl --user show hermes-gateway.service --property=MainPID` and `ss -tlnp`;
  final Maestro command exits 0 with 3/3 flows passed; npm test exits 0.
- User action required: enable key-based login to the selected SSH target or
  identify another target, and provide the running Agent API port/profile.
  Never send passwords, tokens or private keys in chat.
- Default if no answer: retain passing fixture evidence; preserve SSH trust,
  credentials and Agent settings; do not restart a shared gateway or substitute
  direct forwarding for the user's repeated SSH request.
- Proceeding with: three-flow Android qualification and regression repairs
  completed, plus passing helper tests and full Flutter suite.
- Asked: CLI questionnaire for remaining SSH/API identifiers, 2026-10-07.
- Owner answer: keep xel@localhost:2121; owner will enable key-based login for
  this test. The API port/profile question was skipped. A subsequent strict
  read-only SSH retry still returned authentication denied.
- Resume condition: authenticated SSH and an identified, authorized Agent API
  endpoint/profile for an isolated live test.
- Created: 2026-10-06T18:52:16-06:00
- Current evidence: strict BatchMode SSH with StrictHostKeyChecking=yes on
  2026-10-09T10:36:57.896543-06:00 failed with `Host key verification failed.` before
  authentication. The prior authentication-denied probe is historical evidence.
  `adb devices -l` currently returns no attached device. Neither trust nor
  authentication was changed.
- Interview answer: leave live SSH unverified for now; continue implementation
  and isolated QA. Preserve the selected target and all prior security limits.
- Last checked: 2026-10-09T10:36:57.896543-06:00

### BLK-20261006-W02 — Physical-device run for M2 Android recovery

- Status: ACTIVE
- Category: USER_INPUT
- Owner: user
- Task/Card: M2-DEVICE-QUALIFICATION (goal M2)
- Blocked scope: only M2's final qualification; 29 of 31 M2 tasks are done
- Why blocked: proof needs a named physical Android device running the death-to-completion run; agents cannot supply hardware
- Evidence: goals.json M2 (unverified, 29/31 tasks done); TODO.md M2 entries
- User action required: run (or allow an agent to run via adb on a connected device) the named-device qualification
- Default if no answer: physical-device acceptance remains outstanding;
  continue Desktop work and independent Android qualification.
- Proceeding with: Desktop-first implementation and isolated Waydroid Android
  qualification. Physical-device proof remains a separate acceptance gap.
- Asked: Claude Code session, 2026-10-06
- Resume condition: a device run receipt exists
- Created: 2026-10-06
- Owner answer: Telegram interview: use Waydroid for Android qualification now;
  keep physical-device proof separate. This selects a QA target, not evidence
  that any flow passed or permission to replace paired application data.
- Current evidence: `waydroid status` reports running session and container;
  `adb devices -l` reports no attached device. ADB connection is an engineering
  prerequisite, not another owner decision.
- Last checked: 2026-10-09T10:51:39.086193-06:00

## Resolved

### BLK-20261010-W05 — Main-only delivery conflicts with GitHub PR requirement

- Status: RESOLVED
- Category: USER_DECISION
- Owner: user
- Task/Card: N/A — repository-wide commit, push and merge request
- Blocked scope: only remote delivery of qualified commits to main.
- Why blocked: AGENTS.md requires canonical main-only development and forbids
  new branches or PRs. GitHub main ruleset 21968507 requires a pull request.
- Evidence: AGENTS.md:255–262; `gh api repos/TrebuchetDynamics/hermes-wing/rules/branches/main`
  returns a pull_request rule; PR #56 reads CLOSED and mergedAt null.
- User action required: choose whether to retain main-only delivery and have the
  repository owner change the PR requirement, or authorize a delivery-only PR exception.
- Owner answer: Telegram questionnaire: keep main-only; owner removes the PR
  requirement. No agent-side ruleset change or PR exception is authorized.
- Default if no answer: retain main-only policy and existing protection; no bypass,
  new PR, branch, or remote policy change.
- Proceeding with: preserved integration candidate in a verified private bundle
  under `.task-evidence/ship-request/`; validation repairs remain engineering work.
- Asked: Telegram questionnaire, 2026-10-10 UTC.
- Resume condition: a policy-compatible remote delivery route is available and
  the exact candidate passes required checks. This decision does not waive checks.
- Created: 2026-10-10T00:59:41Z
- Last checked: 2026-10-10T00:59:41Z

- Resolved: 2026-10-10T01:04:36.184750+00:00
- Resolution: owner explicitly directed removal of the PR requirement; removed
  only the pull_request rule from ruleset 21968507. Read back the ruleset and
  effective main rules: active deletion and non_fast_forward protections remain.
  Candidate verification remains required; no code push or merge is implied.


### BLK-20261007-006 — Remaining npm audit highs with no published fix

- Goal judge on t_a466ece0 (2026-10-07) ruled FIX-NPM-AUDIT unachievable in scope: the
  remaining embedded high-severity findings have no compatible published patched closure,
  and forced downgrades, vendored patches and weakened audit integrity are excluded.
- Question: A) accept the remaining highs as known risk until upstream publishes fixes,
  re-checking weekly (default applied); B) authorize npm `overrides` for the affected
  transitive packages even where not semver-compatible.
- Default applied: A. FIX-NPM-AUDIT moved to Needs decision; other SECURITY work continues.
- Status: RESOLVED
- Category: USER_DECISION
- Task/Card: FIX-NPM-AUDIT / t_a466ece0
- Created: 2026-10-07

- Resolved: 2026-10-09T10:35:49.161212-06:00
- Owner answer: Telegram questionnaire: accept temporary known risk; retain
  release security checks and investigate compatible fixes. No additional
  incompatible overrides, install, service change or release is authorized.
- Current evidence: `npm audit --json --ignore-scripts --prefix
  wing_link/internal/app/omniroute_assets` reports five high, zero critical,
  twelve total findings. The current pin is 3.8.51. The suggested 3.8.49
  semver-major downgrade is not verified as a repair.
- Resolution: the owner policy question is answered. Vulnerability remediation
  remains engineering work under FIX-NPM-AUDIT; findings are not resolved.


### BLK-20261006-004 — Delivery through a pull request

- Status: RESOLVED
- Category: USER_DECISION
- Resolved: 2026-10-07T17:27:29-06:00
- Resolution: owner authorized a delivery branch and PR for the two existing
  commits, explicitly without merging. Pushed `delivery/private-release-apk-bdb3284a`
  and opened [PR #53](https://github.com/TrebuchetDynamics/hermes-wing/pull/53).
- Evidence: remote branch and PR head both read back as
  `bdb3284a0a669140bcd6f49b4ffe03078cbdd592`. PR contains that private-release
  packaging commit and queued shell commit
  `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`; base is `main`, state OPEN,
  mergedAt null and auto-merge disabled. Curated-index gate and per-path local
  exclusions retained in `.task-evidence/private-release-delivery/`.
- Boundary: no merge, force-push, store publication or production operation.
  CI was pending at readback, not reported passing. Other dirty fleet changes
  and this ledger's follow-up resolution remain local.
- Created: 2026-10-06T17:17:46-06:00

### BLK-20261007-W03 — Private ARM64 release-test signing identity

- Status: RESOLVED
- Category: USER_DECISION
- Resolved: 2026-10-07T12:43:58-06:00
- Resolution: owner confirmed private releases may use a test key. Created and
  retained a dedicated private-testing key outside the repository. Built the
  optimized ARM64 release APK with separate `.qa.release` identity; no paired
  application or production signing identity was changed.
- Evidence: `.task-evidence/arm64-release-handoff/private-release-receipt.json`;
  signature matches the retained key's public certificate, ZIP integrity and AOT
  code checks pass, source inputs stayed unchanged during compilation. Artifact
  is 22.95 MB and not debuggable. All 115 tooling tests, analyzer and formatting
  pass; Gradle rejects private-release configuration without signing values.
- Limits: no store publication, phone installation or emulator execution in this
  handoff. Future private builds reuse the same key; production signing remains
  separate.

### BLK-20261005-003 — Install Linux desktop build packages (sudo)

- Status: RESOLVED
- Category: SUDO
- Resolved: 2026-10-07T17:32:32Z
- Resolution: a compatible user-space development prefix enabled the bounded
  two-process Linux GTK workflow without sudo, system package mutation or plugin
  removal. System installation is not required for that demonstrated path.
- Evidence: [native receipt](docs/quality/native-relaunch-workflow.md#safe-user-space-prerequisites-and-reproduction),
  retained native phase/teardown logs and all 628 final input fingerprints checked
  against the current snapshot. Both phases exit 0 with distinct native PIDs.
- Task/Card: PARITY-NATIVE-RELAUNCH (delivered t_eb5c693d); PARITY-NATIVE-LINUX
  still requires its own executed feature-flow checks.
- Former evidence: host pkg-config lacked six libsecret/GStreamer modules.
  This pass does not claim those system modules were installed or now resolve.
- Owner answer / Default if no answer: keep system packages unchanged. No sudo
  or host installation is authorized. Recheck compatibility and prepare an owned
  prefix for future native checks; the worker removed its temporary prefix.
- Limits: no model-persistence, live inference, all-feature or release qualification
  is inferred from this resolution. No further owner answer is needed for the
  demonstrated non-root path.
- Created: 2026-10-05T14:58Z
- Last checked: 2026-10-07T17:32:32Z

### BLK-20261006-W01 — Agent target for the live Desktop workflow qualification

- Status: RESOLVED
- Category: USER_DECISION
- Resolved: 2026-10-07
- Resolution: owner selected a disposable local QA Agent/profile, separate from
  personal runtime and app state. Wing owns implementation and QA, including
  reversible setup details. At most three short QA generations may use separately
  authorized subscription/test access. No metered spending without another approval.
- Evidence: Telegram grill-me answers and
  [owner update](docs/plans/2026-10-03-desktop-daily-workflow.md#owner-update--wing-implementation-and-qa).
- Task/Card: PARITY-LIVE-WORKFLOW (goal M1).
- Boundary: only the target-strategy and usage decision is resolved. No target
  provisioning, authentication, native/live execution or provider permission is
  inferred. Use supported secret-safe QA authorization, never copy personal keys.
  If actual authentication needs the owner, request only that step and continue
  independent implementation/testing. System packages remain unchanged.
- Default if no answer: retain the selected isolation and usage limits. Apply
  harmless QA-workspace-only test actions as the reversible default, not permission
  for host-wide or external side effects.
- Created: 2026-10-06

### BLK-20261005-001 — Admit the passive global-session lifecycle seam

- Status: RESOLVED
- Category: USER_DECISION
- Resolved: 2026-10-05T13:06:07Z
- Resolution: Premature user escalation withdrawn; an autonomous in-scope investigation remains. The original card explicitly admits minimal shared projection/admission extraction where needed. tools/global_session_access/README.md states guarded selection is a viable narrow extension and the failed weak-listener candidate does not prove every passive design impossible. Route the original Wing card to assess authoritative observation/invalidation of an already-created directory without changing startup semantics, triggering reads or inventing shadow ownership. Expensive startup/lifecycle redesign remains excluded. No implementation or acceptance is claimed; do not manufacture a replacement user gate.
- Evidence: Original t_1c1e6f37 current contract and tools/global_session_access/README.md:16-21,33-49; eager provider startup at lib/features/hermes_chat/providers/hermes_channel_provider.dart:47-56 and directory start:334-367. Current card preserved at <home>/.hermes/fleet-governor/blockers-reconciliation-20261005T124629Z/t_1c1e6f37-rechecked.json. Read-only audit trace <home>/.hermes/cache/delegation/live/deleg_879427cc/task-1.log. Juan's reconciliation request requires agents to exhaust already-authorized paths before escalation.
- Task/Card: t_1c1e6f37
- Former blocked scope: Persistent shell access to loaded sessions
- Former reason: Original card stops before an expensive directory/startup lifecycle redesign. Reading the provider initializes inventory refresh and saved-owner restoration; the tested alternative also initializes it. The broader seam is explicitly excluded.
- Former evidence: Native original blocked run and tools/global_session_access/README.md; latest picker receipt <home>/.hermes/profiles/wing/autogoal/picker-audits/20261005-115156-noop.json.
- Former user action requested: Authorize a bounded startup/passive-observation seam on t_1c1e6f37, or keep this slice parked.
- Former resume condition: Exact same-card scope admission is recorded; a project-owned native50 continuation can then be prepared without weakening ownership or zero-extra-read criteria.
- Created: 2026-10-05T12:12:31.155457+00:00
- Last checked: 2026-10-05T13:06:07Z

### BLK-20261005-002 — Resolve the original narrowed dismissal stop branch

- Status: RESOLVED
- Category: USER_DECISION
- Resolved: 2026-10-05T13:06:07Z
- Resolution: Premature user escalation withdrawn; supported-flow investigation is not exhausted. Native run139 only verified the narrowed modal-blocked reset case, not exhaustive supported-flow unreachability or a production repair. The original contract already permits tracing profile-switch reset, channel rebinding, clearPending and exact-turn invalidation with deterministic widget harnesses. Route those paths to Wing, serially with its existing work; do not ask Juan to prescribe ordinary test coverage. Do not bypass the modal barrier, invoke hidden callbacks, speculate a repair, force done or weaken final review. The disposition disagreement remains in Kanban; no closure or product acceptance is claimed.
- Evidence: Current t_6233c1c5 verification/stop contract, native run139 rejection and <home>/.hermes/profiles/wing/autogoal/approval-dismissal/native-review.md:3-14; hermes_chat_screen.dart:1034-1063, hermes_chat_connection.dart:4-24 and hermes_approval_queue.dart dismissStoppedTurn:134-157 identify further admitted source paths. Current card preserved at <home>/.hermes/fleet-governor/blockers-reconciliation-20261005T124629Z/t_6233c1c5-rechecked.json. Read-only audit trace <home>/.hermes/cache/delegation/live/deleg_879427cc/task-1.log.
- Task/Card: t_6233c1c5
- Former blocked scope: Disposition of the narrowed no-reproduction receipt
- Former reason: The governor already used supported same-card review entry. Native reviewer run139 verified the narrowed stop receipt but the goal judge rejected closure for lacking exhaustive unreachability and RED/repair. Repeating unchanged tests cannot resolve this contract/stop-branch disagreement.
- Former evidence: Original card comments and run139; <home>/.hermes/profiles/wing/autogoal/approval-dismissal/native-review.md and native-review-commands.json. Exact rejection: exercised modal-blocked reset flow does not establish all supported invalidation flows unreachable; required widget RED and repair not delivered.
- Former user action requested: Decide on t_6233c1c5 whether to accept the original narrowed no-reproduction stop disposition through supported lifecycle authority, or specify the additional supported-flow coverage required within its scope.
- Former resume condition: The same-card disposition or concrete additional coverage is explicit; no forced done, review waiver, speculative repair or replacement.
- Created: 2026-10-05T12:12:31.155457+00:00
- Last checked: 2026-10-05T13:06:07Z
