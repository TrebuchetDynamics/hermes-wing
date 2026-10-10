# Owned live-workflow display authentication

Card: `t_a8c770c8`; ledger: `PARITY-LIVE-DISPLAY-ISOLATION` / M1.
Implemented and qualified for Linux X protocol access only. Not integrated into
main, not GTK/live Agent qualification, and not permission to enable inference.

## Attributed source

Candidate: `build/t_a8c770c8/candidate`, detached from reviewed predecessor
`1749a739873d01acc965f61d2f2318a6d466a8d4`. Only this document,
`scripts/support/desktop_live_workflow.py`, and
`test/tooling/desktop_live_workflow_test.py` are this card's overlays. All other
predecessor files are baseline; no shared dirty/staged/untracked source was copied.
The local agent branch is `agent/wing/t_a8c770c8`; native review metadata records
its exact commit. The candidate can be reconstructed from that commit.

Final executed source SHA-256:

| Input | SHA-256 |
| --- | --- |
| Python implementation | `295299f3d23505ff115ceb03fbfac3d552889c2c3dd3eb775c4de8108d39dec6` |
| Python tests | `67282642e2d85ecb3f3d3de2f6bacdf60c81e2a1e50b72bb759fb5e906e637ff` |
| Public shell launcher (unchanged) | `ec6f4941b9e01264d9710d8a898f4c6ddf928d45658cfbb7fd94934c1e750794` |
| Dart integration driver (unchanged) | `e60cf55d6d7ff13ec08948f6553e2ccc00257da4596d9f7f38203aeb8bcdbc35` |
| Dart budget test (unchanged) | `b0ceb32a4b35df95ff08581e9ab41fb640865a5ccfe013f96e2f8f3dc8cf0a53` |
| pubspec.lock (unchanged) | `9ec3db9492cbace9de690033eead7b4fe162f2f485544813a3166b58e9ac9e85` |

Hashes were identical before/after final checks. Source-run Python uses only the
standard library; no new Dart/Go/package dependency or packaging change. The
public launcher resolves this local support module; its entry remains read-only.
The internal prepared runner is not exposed as a public live mode.

## Behavior and boundary

`prepared_two_process` creates one owner-only ephemeral workspace. It writes an
exclusive mode-0600 binary Xauthority record containing a random 128-bit
MIT-MAGIC-COOKIE-1 credential. FamilyWild permits the server-selected display
number without racing a public display reservation. No xauth subprocess receives
cookie arguments; `/usr/bin/xauth` is available but is not needed.

Owned `/usr/bin/Xvfb` uses `-displayfd 1`, `-nolisten tcp`, and `-auth` with only
the ephemeral file path. A bounded display-number read precedes three fixed
`/usr/bin/xdpyinfo` probes (three-second deadline each): correct auth must succeed,
empty auth and independently generated wrong auth must fail. All probe stdout
and stderr are discarded. Any failed admission prevents both phases.

Both driver/app phases inherit only the owned `DISPLAY` and `XAUTHORITY`, never
personal display/auth environment. Both phase groups finish teardown before the
server group is terminated; workspace/auth deletion follows confirmed group
cleanup. Existing refusal preserves state if teardown cannot be confirmed.
No global xhost operation, shared display, provider access, or Agent mutation.

This protects against X clients lacking the credential, not hostile same-UID
processes or root. Same-UID processes can read owner-only files and access process
memory; authorized X clients can inspect/control the display. FamilyWild material
is therefore secret and must remain confined to this temporary workspace. This
is not an OS sandbox, per-client least privilege, or encrypted X transport.

## Executed acceptance evidence

Environment: Linux 7.0.0-31-generic, x86_64, glibc 2.39, Python 3.12.14.
Live executable discovery resolved Xvfb, xauth and xdpyinfo under `/usr/bin`.
Installed packages: xvfb `2:21.1.12-1ubuntu1.6`, xauth `1:1.1.2-1build1`,
x11-utils `7.7+6build2`. No installation/system/service changes were needed.

Commands ran in the isolated candidate, bounded by a 120-second subprocess
limit (suite also invoked under timeout during iteration):

| Exact command | Exit | Wall seconds | Result |
| --- | --- | --- | --- |
| `python3 -B -m unittest discover -s test/tooling -p desktop_live_workflow_test.py` | 0 | 40.961 | 29 tests, OK; unittest reports 40.882 seconds |
| `bash -n scripts/run_linux_desktop_live_workflow.sh` | 0 | 0.001 | shell syntax pass |
| `bash scripts/run_linux_desktop_live_workflow.sh < /dev/null` | 2 | 0.047 | expected AUTHORIZATION_REQUIRED_NO_NETWORK; zero reads, mutations, inference |
| `git diff --check` | 0 | 0.036 | attributed whitespace pass |
| `dpkg-query -W xvfb xauth x11-utils` | 0 | 0.031 | dependency versions above |

Compact machine receipt: `build/t_a8c770c8/verification.json` in the integration
checkout. This document also preserves its relevant commands/results/hashes.

Acceptance 1: `test_real_xvfb_admission_both_phases_and_cleanup` and
`test_real_xvfb_cancellation_cleanup` actually launch Xvfb and execute all three
protocol probes, not synthetic display tests. Correct authorization passes;
missing/wrong authorization is rejected. A loopback TCP connection attempt to
6000 + owned display number is rejected. Synthetic driver/app processes each
successfully connect using xdpyinfo and share the same owned auth file/display.
Their owner-only auth checks and process-group-before-deletion assertions pass.

Acceptance 2: all 23 predecessor lifecycle tests plus six focused tests pass.
Coverage includes setup/admission refusal before phases, unsafe permissions,
exclusive creation, malformed display reporting, probe timeout/cancellation,
real X server cleanup on success and cancellation, and TERM-resistant phase
children. Adversarial inherited DISPLAY/XAUTHORITY never reach app phases.
Unchanged Dart gate is inspected by the existing source-contract regression:
`requireQualifiedLiveBudget()` precedes reading WING_LIVE_AUTH and throws
LIVE_INFERENCE_BOUND_NOT_QUALIFIED. Public live authorization still refuses
before network. No-input public launcher explicitly reports zero operations.

Acceptance 3: local attributed commit, scoped goals.py ledger update and native
same-card review handoff are administrative evidence in the board metadata.
Review approval follows handoff; it is not this worker's completion criterion.

## Iteration and limits

Initial candidate suite: exit 1, 27 tests, 35.867 seconds; one incorrect record
length assertion (45 versus actual 44 bytes) also prevented real admission.
Corrected the record-size validation; candidate suite then passed 27 tests in
40.594 seconds. Added malformed-report, timeout/cancellation and inherited-env
checks; final 29-test result above. An accidental intermediate check in the shared
checkout passed 23 baseline tests in 33.752 seconds; it is NOT candidate evidence.
These observations are retained here; no initial source fingerprint was captured,
so initial results must not be reused as source-bound qualification. Cost unknown.

Real GTK UI, live Agent generation/approval/Stop/history and relaunch restoration,
provider continuation-aware call ceiling, separately approved QA authentication,
exact supported model reselection, packaging/image execution and protected-PR
main delivery: NOT_CHECKED by this card. M1 remains partial and
PARITY-LIVE-WORKFLOW remains in_progress. Next slice: supported provider-call
ceiling qualification without enabling inference from fixture observations.

Questions: none. Default retained: no inference or personal credential access.
