# Native denied-read restart recovery

Card `t_3e074d68`; goal task `PARITY-NATIVE-AUTH-RESTART`, M1.

## Qualification contract

Extend the reviewed [no-inference predecessor](native-no-inference-smoke.md),
commit `0d8c8166dd822079cfd8efa5c34e980e4c052cdb`, without production changes.
The launcher captures the complete attributed candidate and retained source archive
before checks, excludes nested runtime/tool trees, and rejects source links.
The older shared live helper is replaced only in the isolated candidate with the
reviewed `894439b76c889fed45f3c4d57b73086f1e18d479` helper/test overlays.

Observable checks:

1. After reading production persisted selection in a fresh GTK process, synthetic
   typed HTTP 401/403 at exact-session history restoration leaves no active history,
   retains the exact gateway/profile/session, and shows production recovery UI.
2. Tab and Space activate the public restoration Retry only after synthetic read
   authority recovers. Exact canonical history returns, without mutations or Wing
   Link. Cancelled modal reads returning another owner's history cannot settle;
   explicit denied modal read retry also rejects wrong-owner history.
3. Baseline write/verify restart, denial widget/channel regressions, public no-input
   live refusal and provider-call ceiling guards remain passing in the same frozen
   candidate. Driver/application/display ownership and teardown are observed.

`timeout 30m bash scripts/run_linux_desktop_no_inference_smoke.sh` runs sequential
write, verify, verify401 and verify403 processes with one owned authenticated Xvfb
and isolated HOME/XDG preferences. The denied history seam is in-process; no Agent
socket, real credentials, provider adapter or inference exists. Mutation transports
remain unsupported and receipt validation rejects management/non-Agent reads.
Keyboard evidence is injected Flutter key events on Linux GTK, not physical input.
Source-run dependency closure uses the predecessor helper imported from its Git
object; this requires a local checkout and prepared SDK/packages. Packaged execution
is NOT_CHECKED. No packaging edits or release claims are authorized.

## Execution

`timeout 30m bash scripts/run_linux_desktop_no_inference_smoke.sh` exited 0,
`NATIVE_NO_INFERENCE_PASS`, in 216.551 seconds. Final evidence is
`build/t_3e074d68/attempt-1zxd2lyo/`: `source.json`, `archive.json`,
`executed-source.tar.gz`, `verification.json`, `archive-audit.json`,
`check-*.log`, per-phase logs and `*-receipt.json`.

Linux x86_64 / GTK, kernel 7.0.0-31-generic, Flutter 3.44.2 / Dart 3.12.2,
framework c9a6c48423 were exercised. Exact SDK/package/plugin and extracted
development dependency identities are in `verification.json`. Ten user-space
development archives match the predecessor's hashes; no system install occurred.
CMake and Go build parallelism were bounded to two workers. Test suites used one.

All commands below ran inside the complete isolated candidate:

| Command | Exit | Seconds | Result |
| --- | --- | --- | --- |
| `bash -n scripts/run_linux_desktop_no_inference_smoke.sh` | 0 | 0.024 | syntax |
| `python3 -B -m unittest discover -s test/tooling -p desktop_no_inference_smoke_test.py` | 0 | 0.133 | 14 regressions |
| `dart format --output=none --set-exit-if-changed integration_test/linux_desktop_no_inference_smoke_test.dart integration_test/support/desktop_no_inference_fixture.dart` | 0 | 0.133 | unchanged |
| `flutter analyze --no-pub` | 0 | 18.052 | no issues |
| `flutter test --no-pub --concurrency=1 test/tooling/desktop_live_workflow_budget_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart test/features/hermes_chat/screens/hermes_chat_session_search_resume_journey_test.dart test/shared/widgets/app_shell_global_session_modal_test.dart` | 0 | 34.188 | 83 tests |
| `python3 -B -m unittest test.tooling.desktop_live_workflow_test.BoundaryTests.test_no_auth_no_network_or_workspace test.tooling.desktop_live_workflow_test.BoundaryTests.test_live_call_ceiling_refusal_survives_remaining_and_exhausted_budget test.tooling.desktop_live_workflow_test.BoundaryTests.test_fresh_process_phase_and_reset_counter_cannot_upgrade_live_admission test.tooling.desktop_live_workflow_test.BoundaryTests.test_real_launcher_no_inputs` | 0 | 0.634 | 4 admission guards |
| `bash scripts/run_linux_desktop_live_workflow.sh < /dev/null` | 2 expected | bounded 30 s | zero-I/O refusal |

The native command for each phase was
`flutter test --verbose --no-pub --concurrency=1 -d linux integration_test/linux_desktop_no_inference_smoke_test.dart`.
One write and three fresh restart processes shared the same preferences; no
restart reseeded selection. The baseline verify process also passed.

| Phase | Driver PID | GTK PID | Exit | Seconds |
| --- | --- | --- | --- | --- |
| write | 3294037 | 3296837 | 0 | 38.924 |
| verify | 3297408 | 3298863 | 0 | 37.136 |
| verify401 | 3299539 | 3300764 | 0 | 38.627 |
| verify403 | 3301219 | 3302361 | 0 | 37.310 |

Xvfb PID 3294026, authenticated display `:1`, rejected missing/wrong authority.
Application executable/start ticks and driver process groups were observed while
live. Groups were torn down before isolated SDK/build/state deletion. Independent
`python3 -B build/t_3e074d68/audit-evidence.py` verified all process identities
absent, no remaining ephemeral state, and every retained archive member.

The complete pre-check archive contains 1,067 source inputs, including 212
inherited dirty inputs and five separately attributed reviewed live overlays.
All executed source hashes matched after checks. Archive size is 9,311,815 bytes;
SHA-256 `242fce02b18ed828e0d735064f9e4e534bad940aa0e359ba9ba42b2e70802611`.
Manifest SHA-256 is
`0acb1bc4c93928fd4db392ef07967944665f1d72a52cc2b6cc132b53b0ef46cc`.
This execution report is a post-check documentation-only delta; its pre-report
bytes remain archived. No analyzed implementation input changed after checks.

All phases returned owner hash
`4735197aa74274d5c54c9c50bd987da294180a0b9da1d9836921b38201bbfae0`
and canonical history hash
`fd80e7b15d758f94e8b2513ad566a17d4c94df71879190d885f5061826f314a2`.
Denial receipts distinguish one startup history denial and one explicit mounted
history denial per status. Tab focus alone did not retry; Space deliberately
recovered the exact remembered owner. Cancelled delayed valid-owner and
foreign-owner histories remained unapplied. Wrong-owner explicit retry also stayed
in error until canonical history returned. Every mutation/provider/management
counter is zero; provider zero is structural fixture evidence, not billing proof.

Three native runs occurred: `attempt-8x2w12rs` failed on an overly narrow runner
read allowlist for the inherited wrong-owner metadata probe; `attempt-vx6z85lj`
passed before adding the valid-owner cancellation assertion; final
`attempt-1zxd2lyo` passed the strengthened candidate. Their archives/receipts remain
attributed and retained; only the final attempt qualifies the final implementation.
No production code or upstream checkout changed. Shared inherited dirty bytes
were preserved except observed concurrent changes to `goals.json` and `TODO.md`
before this worker's ledger transition; current ledger bytes were not restored.

Acceptance mapping: (1) fixture typed denial plus production directory/channel
restoration and native startup assertions; (2) native public Tab/Space Retry,
valid/foreign late-result cancellation and wrong-owner rejection, zero mutation
transport seams, plus 83 nearest regressions and 14 tooling tests; (3) pre-check
archive, executed hash comparison, independent teardown/archive audit and public
admission guards. Local attributed commit, scoped goal-ledger update and native
same-card review are the handoff steps; review approval follows them.

Source tracing: `HermesGatewayDirectory` maps typed 401/403 to authentication and
retains `restoringSessionId`; `HermesApiChannel._restoreSession/_selectSession`
use generation/owner/acceptance fences. Production restoration UI exposes the
public Retry. No API change is introduced; current upstream auth enforcement is
read-only context, not evidence that the synthetic read response is live Agent
behavior. Source-run Python imports resolve to the exact reviewed Git object,
and all Flutter local imports are captured in the retained candidate.

## Boundaries

Implemented test scope is not live qualification or milestone completion.
M1 real generation/approval/Stop, live-authoritative restoration, packaging and
protected-main delivery remain NOT_CHECKED. Cost is unknown unless measured.
Questions: none; default retained is credential-free synthetic reads only.
