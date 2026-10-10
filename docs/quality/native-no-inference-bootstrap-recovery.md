# Native bootstrap-denied restart recovery

Card `t_e662982c`; goal task `PARITY-NATIVE-BOOTSTRAP-RESTART`, M1.

## Contract

Additive qualification of reviewed predecessor
`358f645c52c9cb53f8368ecb3346d577c05e9f68`, not attribution of its implementation.
Required `/v1/capabilities` is the representative bootstrap entry point for both
401 and 403. Denial precedes usable profile/session inventory and history. The
summary loader and active channel each encounter denial on startup; a deliberate
keyboard Retry repeats it once before synthetic authority is restored. A
mount-time directory inventory refresh is separately recorded: it also fails at
capabilities, without session activation or downstream inventory/history reads.

The native driver reads persisted production `GatewayContactCache` selection in
fresh GTK processes, never reseeding restart preferences. It asserts exact
remembered gateway/profile/session retention, truthful recovery UI, no stale
transcript/composer and no fallback session. Tab focus alone issues no requests;
Space activates the public restoration Retry. Startup, mount and repeat-denial receipts
allow only health and capabilities reads. Canonical exact-session history must
return after recovery. Inherited cancellation tests reject foreign history and a
valid-owner late response with distinguishable `cancelled-message` identity.
Every mutation/provider/management counter remains zero.

The launcher runs six sequential phases: write, verify, verify401, verify403,
bootstrap401 and bootstrap403. It retains a complete pre-check source archive,
input hashes, dependency and SDK identities, phase receipts and teardown evidence
using the predecessor's isolated HOME/XDG and authenticated owned Xvfb mechanism.
Reviewed helper overlays remain `894439b76c889fed45f3c4d57b73086f1e18d479`.
Inherited dirty inputs are separately attributed. No production fix is assumed.

Source tracing: `HermesApiGatewaySummaryLoader.load` reads health then required
capabilities before inventory. `HermesGatewayDirectory.start/activate` retains
cached exact selection on bootstrap failure, classifies the channel's typed
authentication failure and exposes `retrySessionRestoration`.
`HermesApiChannel._connect` fails typed 401/403 before selecting a session.
Nearest existing bootstrap regressions are in
`hermes_chat_death_completion_recovery_test.dart`; synthetic widget coverage is
not native evidence. No API/backend contract changes are introduced.

## Boundaries

This is synthetic Linux GTK qualification with injected Flutter keyboard events,
not physical input or live Agent authentication. There are no sockets, real
credentials, inference or Agent launch in the fixture. Agent/Desktop clones and
personal runtime state are unchanged. Source-run helper imports require local Git
objects and prepared SDK/packages; packaged execution is NOT_CHECKED.

M1 real generation/approval/Stop, live-authoritative restart, packaging and
protected-main delivery remain NOT_CHECKED. M1 stays partial. Cost is unknown.
Default retained: credential-free synthetic reads only; no new owner question.

## Execution

`timeout 30m bash scripts/run_linux_desktop_no_inference_smoke.sh` returned
`NATIVE_NO_INFERENCE_PASS`, exit 0, in 297.361 seconds. Retained evidence:
`build/t_e662982c/attempt-nrx5dzoe/` (`source.json`, `archive.json`,
`executed-source.tar.gz`, `verification.json`, `archive-audit.json`, scoped check
logs and six phase logs/receipts). Ephemeral VM/DDS authentication URLs in logs
were redacted after execution; source and receipt bytes were not changed.

All checks below ran inside the isolated complete candidate; `verification.json`
records the exact absolute SDK command paths and environment identities.

| Command | Exit | Seconds | Result |
| --- | --- | --- | --- |
| `bash -n scripts/run_linux_desktop_no_inference_smoke.sh` | 0 | 0.025 | syntax |
| `python3 -B -m unittest discover -s test/tooling -p desktop_no_inference_smoke_test.py` | 0 | 0.134 | 15 tests |
| `dart format --output=none --set-exit-if-changed integration_test/linux_desktop_no_inference_smoke_test.dart integration_test/support/desktop_no_inference_fixture.dart` | 0 | 0.135 | unchanged |
| `flutter analyze --no-pub` | 0 | 18.803 | no issues |
| focused `flutter test --no-pub --concurrency=1` below | 0 | 37.944 | 88 tests |
| four public admission/budget Python guards below | 0 | 0.586 | 4 tests |
| `bash scripts/run_linux_desktop_live_workflow.sh < /dev/null` | 2 expected | bounded 30 s | zero-I/O refusal |
| `python3 -B build/t_e662982c/audit-evidence.py` | 0 | not measured | independent archive/teardown audit |
| `git diff --check` | 0 | not measured | shared and scoped whitespace check |

Focused Flutter targets (one sequential command):

```sh
flutter test --no-pub --concurrency=1 test/tooling/desktop_live_workflow_budget_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_session_search_resume_journey_test.dart test/shared/widgets/app_shell_global_session_modal_test.dart
python3 -B -m unittest test.tooling.desktop_live_workflow_test.BoundaryTests.test_no_auth_no_network_or_workspace test.tooling.desktop_live_workflow_test.BoundaryTests.test_live_call_ceiling_refusal_survives_remaining_and_exhausted_budget test.tooling.desktop_live_workflow_test.BoundaryTests.test_fresh_process_phase_and_reset_counter_cannot_upgrade_live_admission test.tooling.desktop_live_workflow_test.BoundaryTests.test_real_launcher_no_inputs
```

Native phase command:
`flutter test --verbose --no-pub --concurrency=1 -d linux integration_test/linux_desktop_no_inference_smoke_test.dart`.

| Phase | Driver PID | GTK PID | Exit | Seconds |
| --- | --- | --- | --- | --- |
| write | 3416925 | 3420401 | 0 | 38.470 |
| verify | 3421316 | 3423120 | 0 | 37.027 |
| verify401 | 3423829 | 3424768 | 0 | 35.825 |
| verify403 | 3425267 | 3428023 | 0 | 37.966 |
| bootstrap401 | 3429718 | 3431240 | 0 | 37.673 |
| bootstrap403 | 3432694 | 3445666 | 0 | 39.697 |

Linux x86_64 / GTK, kernel 7.0.0-31-generic, Flutter 3.44.2 / Dart 3.12.2,
framework c9a6c48423 were exercised. Ten downloaded development archives matched
the predecessor's hashes and were extracted in user space only, with a local
compiler/linker wrapper. No sudo or system install. Compilation used two workers;
test phases were sequential. Xvfb PID 3416915 owned authenticated display `:1`;
missing/wrong Xauthority was rejected. Audit verified driver/GTK/display process
identities absent and all isolated SDK/build/state trees removed after teardown.

The archive has 1,068 candidate inputs, including 213 inherited dirty inputs and
five separately attributed reviewed helper overlays. All executed hashes matched
the pre-check manifest. Archive SHA-256:
`994997136f548a388ff9423a4d762baf64b1c28076bf49ac718256ae992a9001`;
manifest SHA-256:
`a9f7d3dde354fdf7fa25135dc6e2d97369297578557372f9ff780b98115a9d1c`.
The report is a post-check documentation-only delta; analyzed/tested source inputs
remain exactly archived. Scoped local commit is parented on the reviewed
predecessor using an isolated commit candidate, not checked-out main. Shared dirty
bytes and index are preserved; inherited implementation is not claimed.

Three native attempts ran: `attempt-44rfy6k2` failed on an inherited harness
assertion that assumed disconnected pre-discovery capability getters were action
availability; `attempt-wed4w_vr` passed native assertions but receipt admission
omitted the mount-time inventory refresh denial. Final `attempt-nrx5dzoe` passed
after correcting these harness expectations. No production defect was reproduced
and no production fix was made. Failed attempt archives remain retained.

Acceptance mapping:

1. Both fresh bootstrap-denied GTK processes read persisted selection and retain
   the exact gateway/profile/session; startup and mounted checkpoints show empty
   live inventory/history and only health/capabilities I/O. Recovery UI is visible
   without stale transcript/composer or default/first-session selection.
2. Native public Tab/Space assertions prove focus does not retry, deliberate retry
   under continued denial retains ownership, and authority recovery restores
   canonical exact-session history. Each phase also rejects cancelled foreign and
   distinguishable valid-owner late history. Every mutation/provider/management
   counter is zero. Provider zero is structural fixture evidence, not billing.
3. Pre-check archive and post-check hashes, 15 tooling/88 Flutter/4 admission
   regressions, six native phases, independent process/archive audit and scoped
   diff check pass. Local commit, goal ledger and native same-card review handoff
   finish this card, not M1 or protected-main delivery.

Implemented: additive fixture, native assertions and receipt validation.
Qualified: synthetic Linux GTK restart/bootstrap denial and keyboard recovery at
the retained fingerprint. Delivered: NOT_CHECKED (no merge/push).
Next seam: authorized isolated live prerequisites for M1, or a newly evidenced
restoration defect; not another unchanged audit. No new owner questions.
