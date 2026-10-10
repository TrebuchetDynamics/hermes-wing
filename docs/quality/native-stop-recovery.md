# Native keyboard Stop recovery: Linux GTK fixture qualified

Card `t_a7ab04dd`; goal `M1`; task `M1-NATIVE-STOP-RECOVERY`.
This is synthetic native qualification, not live-Agent or milestone completion.

## Final implementation and qualification

The six additive files below exercise production HermesApiChannel HTTP/SSE seams,
Chat Stop, the production router, Add Hermes and directory activation. The fake
endpoint store and summary loader prevent access to real credentials or endpoints.
No production or upstream changes were required. Reusing the full router fixed
the standalone harness's missing navigation context. Keyed focus ancestry fixes
its ambiguous Add Hermes label and custom contact-control lookup.

Acceptance 1: PASS on Linux GTK for all four combinations of 390/1280 logical
width and 100%/200% text, reduced motion. Tab/Enter activates Stop. Acknowledgment,
unknown status, wrong run, status-read failure and history-read failure retain
unresolved ownership and reject attempted sends. History failure returns to the
public directory; keyboard Add Hermes, its direct connection form and explicit
contact activation recover without a domain mutation. Exact canonical message ID
`canonical-stop` is admitted before a deliberate resumed send. A failed Stop
retains ownership until terminal status/history recovery. A delayed old Stop
success and rejected retired interruption target cannot overwrite or release the
replacement run_4 streaming owner. Native wrong-run readback is covered; other
profile/session permutations remain focused channel-test evidence.

Acceptance 2: PASS. Each receipt contains 68 bounded reads and exactly the ordered
mutation trace: submit run_1, Stop run_1, deliberate resumed submit run_2,
failed Stop run_2, setup submit run_3, delayed Stop run_3, setup submit run_4.
There are four explicit submissions, three deliberate Stops, zero session creates,
zero approval decisions and zero recovery-caused mutations/extra Stops. Only
one send is labeled the deliberate resumed-send journey; runs 3/4 are explicit
race setup. Counters include failed attempts. Exact ordered mutation assertions
and receipt-validator negatives reject replay or wrong owners.

Acceptance 3: PASS for this fixture slice. Four correlated receipts and twenty
fresh Xvfb screenshots were retained. Compact/wide 200% Stop-focus, compact 200%
failed/reconnect and Add Hermes recovery captures were loaded and inspected.
Stop, Reconnect and Add Hermes remain readable; compact error copy wraps without
clipping. The Stop focus outline/fill is subtle, and each focused/unfocused image
pair has different bytes. Unrelated wide Sessions-heading wrapping, abbreviated
sidebar labels and compact status-strip clipping at 200% remain visible; no broad
shell polish or screen-reader/physical-keyboard qualification is claimed.

Final evidence: `build/t_a7ab04dd/evidence/attempt-zt9xnmpu/`.
Executed source archive SHA-256:
`1689e127c4860ae92d0a3982be4968a6e8212967c70036fd776238ec1bc61a64`.
Source manifest SHA-256:
`17a0259e6c41d67874e7f5ff19187f3840023d28a80668fb3c6a95545a759d6e`.
Native binary SHA-256:
`375a762e7171605d3e88c33ceb1011bfd29f164525be84132e134535fa81e71f`.
All 788 executed input hashes were checked before preparation and after execution.
Manifest attribution distinguishes owned changes from inherited dirty bytes; SDK,
package closure, Go modules, sysroot and tool hashes are recorded. Observed native
PID 642111, driver 637518, executable `wing`, start ticks 224268981. Owned HOME/XDG,
authenticated Xvfb, SDK/source/build and process-group teardown passed.

Final checks, all exit 0 (exact executable paths in verification.json):

- `python3 -B -m unittest discover -s test/tooling -p stop_recovery_native_test.py`: five tests, 0.084 seconds.
- `bash -n scripts/run_linux_stop_recovery.sh`: 0.021 seconds.
- `dart format --output=none --set-exit-if-changed integration_test/linux_stop_recovery_test.dart integration_test/support/stop_recovery_native_fixture.dart`: 0.135 seconds.
- `flutter analyze --no-pub`: no issues, 15.992 seconds.
- `flutter test --no-pub --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart test/features/hermes_chat/screens/hermes_chat_transcript_reconnect_test.dart`: 335 tests, 19.519 seconds.
- `flutter test --no-pub --concurrency=1 -d linux integration_test/linux_stop_recovery_test.dart`: one target, four complete cases, 115.582 seconds.
- `timeout 25m bash scripts/run_linux_stop_recovery.sh`: `NATIVE_STOP_RECOVERY_PASS`, 186.826 seconds.

Observed Flutter 3.44.2/Dart 3.12.2, Linux x86_64, GTK 3.24.41, GStreamer 1.24.2,
libsecret 0.21.4. Ten launcher attempts (seven reached GTK) took 986.192 measured
seconds in total. Earlier failures are retained, including harness timing/router,
missing/wrong/unused imports, ambiguous labels and contact focus ancestry. No
passing expectations were weakened. The board clarified that three attempts is
the dispatcher retry budget, not a limit on in-worker fixes with new evidence;
the historical partial report below predates that clarification and final pass.

Implemented: native harness and regression validator. Qualified: Linux GTK with
synthetic HTTP/SSE and injected keys. Delivered: NOT_CHECKED; local owned-file
agent commits only, no push/merge/release. Task evidence is updated and same-card
native review is the final worker handoff. Review approval remains separate.
M1 and PARITY-LIVE-WORKFLOW remain partial: live Agent/provider auth/generation,
real Stop/tools, process-relaunch recovery and protected-main delivery are open.
Next slice is actual-Agent qualification when its admission prerequisites exist;
otherwise a bounded native daily-workflow integration. No follow-up card created.
Model cost/token usage and review duration are unknown. Questions: none.
Defaults applied: credential-free fixture, existing production behavior and
independent review. Reproduce with the user-space prefix recipe below and the
same launcher; no older source archive is required.

## Historical partial report (superseded by final passing evidence above)

Card `t_a7ab04dd`; goal `M1`; task `M1-NATIVE-STOP-RECOVERY` remains unfinished.

## Implemented

Added the [GTK target](../../integration_test/linux_stop_recovery_test.dart),
[synthetic fixture](../../integration_test/support/stop_recovery_native_fixture.dart),
[launcher](../../scripts/run_linux_stop_recovery.sh),
[driver](../../scripts/support/stop_recovery_native.py), and
[receipt tests](../../test/tooling/stop_recovery_native_test.py).
No production, upstream, inherited helper or packaging sources were modified.
The fixture overrides HTTP/SSE function seams of production HermesApiChannel;
it does not listen on a socket or contact the synthetic loopback origin.
There are no credentials, provider calls, tools or Wing Link requests.
Keyboard input is injected through Flutter in a real Linux GTK process, not
physical-keyboard qualification.

The target specifies four width/text combinations (390/1280, 100%/200%, reduced
motion), acknowledgment/unknown/wrong-run/status-error/history-error ownership
retention, deliberate canonical recovery, failed Stop, and delayed retired Stop
settlement after replacement. These are intended assertions, not passed coverage.
The receipt validator rejects extra or wrong-owner mutations, incomplete phases,
missing status reads and false ownership evidence; its five tests pass.

## Executed evidence and failures

Three native attempts were executed, respecting the card's three-attempt limit:

| Attempt | Outer exit | Elapsed seconds | Native exit | Observed failure |
| --- | --- | --- | --- | --- |
| `attempt-js1q9uy7` | 1 | 99.832 | 1 | Recovery lookup before pumping the blocked-send state update |
| `attempt-co5uzd4l` | 1 | 104.748 | 1 | Reconnect lookup after history failure had changed the displayed surface |
| `attempt-4f2hc85p` | 1 | 105.945 | 1 | Public Add Hermes entry needs GoRouter; standalone MaterialApp supplies none |

Evidence root: `build/t_a7ab04dd/evidence/`. Each attempt retains source.json,
executed-source.tar.gz, archive.json, dependencies.json, Go dependency manifests,
executed-runtime-helper.py, additive patch, check logs and verification.json.
These are local ignored evidence, not shipped artifacts or protected-main delivery.

Latest executed archive SHA-256:
`b8c6a076888c3b52b8c060930e994c83c118396198ed3de7cf8d768652c1aeb6`.
Latest source manifest SHA-256:
`5821ae6cbf51b2f6424f6ab721f4395c6a24e1b876178a0c3b7f51e22b49cbdb`.
The archive binds 788 current Wing inputs, attributes owned files separately from
preexisting dirty worktree bytes, and excludes upstream clones, tool state,
credentials and build outputs. No generic predecessor production overlay is used.
The isolated runtime launcher helper is sourced from its fixed reviewed Git
revision and retained separately. SDK/package/Go closures, system tool hashes,
user-space prerequisite hashes and versions are recorded in verification.json.
The executed candidate is complete for these checks, not a standalone owned-file
commit: an integration owner must assemble inherited source prerequisites.

Latest source-bound commands and results (full executable paths in the receipt):

- `python3 -B -m unittest discover -s test/tooling -p stop_recovery_native_test.py`: exit 0, five tests, 0.080 seconds.
- `bash -n scripts/run_linux_stop_recovery.sh`: exit 0, 0.020 seconds.
- `dart format --output=none --set-exit-if-changed integration_test/linux_stop_recovery_test.dart integration_test/support/stop_recovery_native_fixture.dart`: exit 0, 0.130 seconds.
- `flutter analyze --no-pub`: exit 0, no issues, 15.494 seconds.
- `flutter test --no-pub --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart test/features/hermes_chat/screens/hermes_chat_transcript_reconnect_test.dart`: exit 0, 17.159 seconds.
- `flutter test --no-pub --concurrency=1 -d linux integration_test/linux_stop_recovery_test.dart`: built GTK, exit 1, 36.369 seconds.
- `timeout 25m bash scripts/run_linux_stop_recovery.sh`: exit 1, 105.945 seconds.

All earlier frozen attempts also passed the non-native checks above. They are not
substitutes for the failing integrated native target. Flutter ignores integration
concurrency, while CMake/Go parallelism is bounded at two. HOME/XDG/SDK/build and
Xvfb are owned and isolated. No system installation or shared service was used.
Owned process groups and disposable source/SDK/build directories were cleaned.

## Acceptance mapping and remaining work

1. PARTIAL, not qualified: latest GTK execution reaches keyboard Stop and asserts
   unresolved ownership and blocked submission after acknowledgment, unknown,
   wrong-run, status-read failure and history-read failure at the first size.
   It fails before canonical recovery. Other size/scale cases, Stop-error and late
   replacement native coverage are NOT_CHECKED. Existing channel tests cover
   terminal/history and owner fences but do not qualify this native journey.
2. NOT_CHECKED: final correlated fixture receipts are not published because the
   target fails. Zero-replay and deliberate-resumed-send expectations exist in
   code, but complete native request accounting has not passed.
3. PARTIAL: fresh GTK build/test logs, executed source/dependency/environment
   identities and failures are retained. No final screenshots survived: the
   driver copies renders only after success, and failure teardown removed the
   temporary captures. Visual inspection/readability is therefore NOT_CHECKED,
   not inferred from keyboard reachability. The local-visual-verification skill
   was loaded. Owned-file local branch/commit is recorded in the card handoff;
   independent review and delivery are not claimed.

Next repair is harness-only: mount the production router/enrollment recovery
composition (and deterministic credential-free endpoint store) so public Add
Hermes can recover after history read failure; preserve failed-run ownership and
all no-replay assertions. Retain partial screenshots on failure in the driver.
Then qualify the full native matrix in a separately authorized continuation.
No production defect was proved and no existing assertions were weakened.

Reproduction: provision the user-space development prefix using the
[existing recipe](native-relaunch-workflow.md#safe-user-space-prerequisites-and-reproduction),
with `build/t_a7ab04dd/deps/downloads` and `build/t_a7ab04dd/deps/sysroot`.
Run `timeout 25m bash scripts/run_linux_stop_recovery.sh`. It accepts no arguments
or credentials, snapshots current source and uses offline isolated dependencies.
The current target is expected to fail at missing GoRouter, not return a pass.

Implemented: additive partial harness. Qualified: focused analysis/unit checks,
not full GTK workflow. Delivered: NOT_CHECKED; no merge/push/release.
M1 and PARITY-LIVE-WORKFLOW remain open. Actual Agent inference/auth/Stop,
physical keyboard, screen reader, other platforms and packaged distribution are
NOT_CHECKED. Model cost, review duration and overall token usage are unknown.

Questions: none. Defaults applied: synthetic transport only, existing production
behavior, preserve inherited dirty work, stop after three native attempts and
retain honest partial evidence. No follow-up card was created.
