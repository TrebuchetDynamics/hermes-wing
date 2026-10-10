# Isolated two-process orchestration

Card: `t_2e1f363d`; scoped ledger task: `PARITY-LIVE-TWO-PROCESS` / M1.

Implemented: internal preparation and sequential write/verify process orchestration
beneath the prepared production Chat driver. Qualified: deterministic synthetic
Linux subprocess control flow only. Delivered: **NOT_CHECKED** (no protected PR,
merge or main-ancestry verification). M1 and `PARITY-LIVE-WORKFLOW` remain partial.
Actual Agent authentication, GTK/native production execution and inference remain
**NOT_CHECKED**. No actual Agent/provider was contacted by this card.

## Changed boundary

Only `scripts/support/desktop_live_workflow.py`,
`test/tooling/desktop_live_workflow_test.py` and this receipt have card increments.
The shell launcher and both predecessor Dart files are byte-for-byte unchanged.
No product `lib/`, packaging, Agent, Desktop, Conduit, runtime or schedule changes.

`prepared_two_process` is an internal Python entry, not a new public command. It
freezes the predecessor baseline plus explicitly owned overlays, prepares one
owned SDK/workspace, creates owner-only HOME/XDG/state directories and supervises
one display for both phases. The default fixed Flutter command runs the existing
integration target, sequentially with `WING_LIVE_PHASE=write` then `verify`.
No credential is discovered, inferred or supplied by this entry. Its production
Dart target still refuses before creating clients or performing any network work.
Authentication/provider-budget hookup is deliberately not enabled in this card.

`two_phase_runner` waits for the first driver to finish, terminates its entire
owned process group (TERM, then KILL when necessary), reaps the driver and verifies
no live group members remain before launching the successor. The same state and
display survive both phases; all groups, including the display, are gone before
workspace deletion. Parent-only SIGINT/SIGTERM in either phase prevents success;
repeated cancellation cannot interrupt cleanup. Existing archive/SDK preparation
cancellation checks remain covered. Display readiness is bounded to ten seconds;
each phase has a 300-second deadline. The synthetic display is not Xvfb proof.
If teardown cannot be confirmed, a fixed refusal preserves owned state rather
than deleting it underneath a potentially live child; this error path has a
separate deterministic regression. Successful/cancelled test groups are leak-free.
Default Xvfb transport disables TCP; production display/authentication/privacy
qualification is still required before supplying actual QA credentials.

Phase admission accepts only the prepared Dart driver's exact allowlisted keys,
phase, expected owner digest, bounded run identifier, SHA-256 history identity,
integer app PID/message count/provider-call observation, exact mutation counts and
canonical terminal status. Files are at most 4096 bytes, regular and not symlinks;
duplicate JSON keys, booleans masquerading as counters, FIFO files, stale receipts,
missing receipts, changed handoffs and unexpected fields fail closed. The first
handoff is revalidated before the second launch and after completion. Raw run
identity stays in owned ephemeral state, never in the returned summary.

The observer verifies the reported app is a live member of its driver's kernel
process group and is not the driver itself. Both app and driver identities must
be distinct across phases. If that identity cannot be observed while alive, the
runner refuses rather than upgrading a reported PID into native qualification.
Final summaries contain phase/PID identities, receipt digests and verified group
teardown, not transcripts, endpoints, authorization or raw run identifiers.
Provider-call observations are not an enforced billing ceiling.

The `_prepare`, `_display` and `_command` Python seams are for deterministic test
injection only; none is reachable through public argv or stdin fields. Tests use
a fake SDK executable at the default fixed Flutter path, a synthetic display and
separate real driver/app subprocesses. No synthetic success authorizes live mode.

## Source attribution

Predecessor: `agent/wing/t_a8a79cf5`,
`8bdae36cd40bccbf5b7fd6056d395606f01f58db`; original production base:
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`.

The verification candidate was a clean archive of the exact predecessor commit,
with only this card's two Python overlays. Its 1136 file hashes and 212 excluded
working-tree file hashes are recorded in `build/t_2e1f363d/source-manifest.json`.
No other dirty/staged/untracked owner bytes, predecessor synthetic-workflow
*overlays*, upstream reference clones or personal runtime state entered the
candidate. Committed baseline files are retained unchanged, not treated as live
qualification. Runtime snapshots now pin this predecessor rather than whatever
happens to be checked out on the shared main branch, and record both tracked and
untracked input exclusions. The shell and Dart predecessor hashes were compared
before every verification freeze. All frozen input hashes were unchanged after
the final checks.

Final Python SHA-256:

- Helper: `b83affe05220c2b63a95bc73f3a5d5689f6390c44ba7ae4f1b498d3d543015f9`.
- Regressions: `8400e63615158b2b743d35af4eb7356dd4747a33ebcd786f0275e16527b2fe4c`.

Local commit is created only with the authorized `agent_commit.sh` helper on
`agent/wing/t_2e1f363d`, parented on the predecessor. The exact SHA and parent
readback are in the native review handoff and compact commit receipt. No shared
index staging, checked-out branch commit, push, merge or protection bypass.

This remains a source-run script: the shell resolves this sibling helper and the
helper imports only Python standard-library modules. There is no new packaged
runtime dependency. Native build closure still includes the existing Linux Wing
Link bundle and relocated cached Flutter packages; neither native build nor
packaged execution was run. Packaging/service/release qualification is NOT_CHECKED.

## Executed evidence

Final checks ran in `build/t_2e1f363d/candidate`, not the shared dirty tree. Each
command below was executed under `timeout 120s bash -c '<command>'`.

| Command | Result | Wall duration |
| --- | --- | --- |
| `python3 -B -m unittest discover -s test/tooling -p desktop_live_workflow_test.py` | 23 passed; exit 0 | 34.242 s |
| `bash -n scripts/run_linux_desktop_live_workflow.sh` | exit 0 | 0.002 s |
| `bash scripts/run_linux_desktop_live_workflow.sh < /dev/null` | expected exit 2; zero read attempts/mutations/inference | 0.043 s |
| `git diff --check` | exit 0 against predecessor baseline | 0.005 s |

Acceptance mapping:

1. `test_two_process_sequence_distinct_app_and_driver_shared_state_display`
   demonstrates two real driver/app pairs, one owned state and one display.
   The verify app checks restoration of its synthetic selection and no live first
   group before proceeding. `test_successful_leader_exit_reaps_resistant_phase_descendants`
   exercises KILL escalation after normal leader exit. The cancellation test
   waits until descendants have installed TERM-ignore handlers before signaling
   only the orchestration parent in each phase. A test-only deletion hook checks
   group teardown immediately before removing state. Failure, invalid/missing
   handoff, stale receipt, driver-as-app and handoff-tampering tests refuse.
2. `test_successful_internal_phase_receipt_cannot_enable_public_live_gate`
   first passes synthetic orchestration, then proves public live/read-only/live
   argument and synthetic argument attempts cannot reach network or the runner.
   The unchanged Dart source contract is checked for unconditional
   `requireQualifiedLiveBudget` before authorization/client access. This is
   inspected/source-contract evidence, not a fresh Dart runtime run. The
   predecessor's six Dart mutation-budget tests are not relabeled as executed
   here. Live mode continues to refuse `LIVE_INFERENCE_BOUND_NOT_QUALIFIED`.
3. Source hashes, scoped local commit, this receipt, goal-ledger update and native
   review transition provide the implementation handoff; they do not prove
   milestone completion, review approval or merged-main delivery.

Environment observed: Linux x86_64, kernel `7.0.0-31-generic`, glibc 2.39,
Python 3.12.14. Installed SDK metadata: Flutter 3.44.2 / Dart 3.12.2, revision
`c9a6c484230f8b5e408ec57be1ef71dee1e77020`, engine
`77e2e94772b6eb43759e34ed1ad7da4674e19cab`.
Lockfile SHA-256:
`9ec3db9492cbace9de690033eead7b4fe162f2f485544813a3166b58e9ac9e85`.
SDK metadata is environment identification, not a Flutter execution claim.
Dart was unchanged: no SDK copy, analyzer, Flutter test, GTK journey, broad suite
or shared build lease was used. No installs or dependency downloads.

Four scoped Python runs passed (21, 22, 22, then final 23 tests) as admission
and cleanup coverage was tightened; final evidence supersedes the earlier source.
An initial command used a not-yet-created candidate directory and exited 126
before running anything; preparation was then run from the repository. No Python
regression run failed. Final command receipts are in `checks.json`; environment
identities are in `environment.json`. The large owned candidate is removed after
commit/evidence capture; compact evidence is retained. Actual inference count: 0.
Usage/billing cost and independent review duration: unknown.

## Remaining milestone gaps and questions

Next qualification slice: establish an authoritative supported provider-call
ceiling across tool/approval continuations, then separately approved actual-Agent
QA authentication and production two-process GTK generation/approval/Stop/history
restoration, with display privacy and exact canonical readbacks. Protected PR,
required CI and merge/main verification remain the integration owner's work.
No follow-up task was created by this bounded worker.

Questions (no reply = defaults apply): existing `BLK-20261007-W04` in
[BLOCKERS.md](../../BLOCKERS.md) still applies. Default: no inference and no
personal credential access. No new owner decision is required for this synthetic
engineering slice. Native review is this card's final goal step, not a prerequisite
for handing off and not evidence that M1 is met.
