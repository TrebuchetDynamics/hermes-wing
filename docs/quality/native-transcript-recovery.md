# Native transcript recovery and keyboard approval

Card: `t_912b8858`; task: `M1-NATIVE-APPROVAL-RESTORATION`; goal: `M1`.
This qualifies a deterministic Linux GTK slice, not the live daily-use milestone.

## Implemented

Added the [native target](../../integration_test/linux_transcript_recovery_test.dart),
[fixture](../../integration_test/support/transcript_recovery_native_fixture.dart),
[owned launcher](../../scripts/run_linux_transcript_recovery.sh),
[driver](../../scripts/support/transcript_recovery_native.py), and
[receipt regressions](../../test/tooling/transcript_recovery_native_test.py).
No production source, inherited launcher, upstream reference, or packaging file
was changed. No product defect was reproduced; iterations repaired the new harness.

The target runs production `HermesApiChannel`, the Chat screen, timeline, and
approval queue. Only the HTTP/SSE function seam is deterministic. There is no
fixture listener, credential, provider, real tool execution, or Wing Link request;
`127.0.0.1:8642` is a non-contacted synthetic origin, not a claimed owned socket.
The existing reconnect fixture supplies canonical synthetic history through an
import; its test entrypoint is not invoked. Keys go through Flutter's keyboard
input/focus path in an actual GTK process, not a physical keyboard.

## Acceptance evidence

1. Four cases: widths 390/1280 logical pixels, text scales 1/2. Each executes
   canonical reconnect, removes retired approval controls/focus, compares exact
   canonical message IDs, remounts Chat, and returns across compact/wide layouts.
   Tab/Enter reach and open recovered tool disclosure. File/Web categories and
   all three completed-status labels render, with synthetic hidden tool content
   absent. Current Approve once is reached and activated by keyboard.
   Reduced motion and traditional keyboard-focus highlighting are explicitly
   selected in the harness. Twenty fresh root-window captures contain before/
   focused disclosure, expanded disclosure, and before/focused current approval.
   Each paired focus capture has different pixels. Four final 200% captures were
   loaded and inspected: category/status wrapping and approval labels are readable;
   disclosure shows a visible focus fill. Approval focus uses a subtler fill change.
   The pre-existing wide sidebar wraps its Sessions heading and truncates inventory
   labels at 200%; these unrelated shell limitations were not changed.
2. Each case has exactly five deliberate synthetic setup sends and five explicit
   decision attempts: run_2/request_2 once (one successful normal decision),
   run_3/request_3 once (failure then deliberate retry), run_4/request_4 once
   (delayed failure retired by disconnect), and run_5/request_5 once (replacement).
   Failed attempts count, not only acknowledgments. Retired origins are rejected
   without posting. Delayed failure neither answers nor removes the replacement;
   only its deliberate activation adds the run_5 decision. Canonical recovery,
   viewport remount/return, and waiting after failure cause no mutation replay.
   Final counts per case: five sends, five decision attempts, zero creates/Stops,
   zero recovery mutations, 23 reads. Exact paths and request IDs are recorded.
   Native late failure is exercised; late success/dispose and in-flight reuse
   variants are covered by the focused channel regressions, not claimed as extra
   native scenarios.
3. All final source-bound checks below pass. The local agent-branch commit contains
   only these six additive files. Native review is the final worker transition;
   independent approval and protected-main delivery remain separate.

## Frozen source and execution

Final evidence directory: `build/t_912b8858/evidence/attempt-m5sboot_/`.
Manifest SHA-256:
`680cce6a26c3561a8fc9a258f879b7dce9a08b30664099573810fbafad11b9a5`.
Executed source archive SHA-256:
`9233f175f98474fcb2e182f44c3ec569cb9bd190bb0df4906976a77ca9e69d95`.

The baseline is the independently attributed predecessor `t_263cb8bd` source
archive, SHA-256
`2cc3740bcd2924e9c907bacc60ed7faac9835f292a95759c9a33163c26aaa72b`,
associated with commit `9f84b77197a83f4fc08a61ee3251c5456f380533`.
The launcher validates archive membership and every input hash, copies only the
five owned execution files on top, archives the candidate before checks, then
rechecks it afterward. It does not copy a generic shared dirty overlay or switch
branches. Documentation is not an execution input. Read-only launcher helper
bytes must match that baseline; the attributed runtime helper is loaded from its
fixed Git revision and retained. Dart packages and Go modules are copied, hashed,
used offline, and retained through compact manifests. The source-run commit is
not standalone: the integration owner must assemble its attributed prerequisites.
No packaged/image/distribution qualification is implied.

`verification.json` contains exact executable paths, per-check elapsed times and
exits, lockfile/source hashes, SDK/OS/package versions, sysroot/tool/package hashes,
binary SHA-256, linked libraries, fixture paths/counts, and GTK `/proc` evidence.
The observed executable is `wing`; use the exact
`native_pid`, driver group and start ticks in the receipt. Owned Xvfb authenticates
with a new authority and rejects missing/wrong authority. HOME/XDG, SDK, build,
module closure and display are isolated; group teardown and state deletion pass.

Final commands (all exit 0, inside the frozen candidate):

- `python3 -B -m unittest discover -s test/tooling -p transcript_recovery_native_test.py`: 4 tests, 0.082 seconds.
- `bash -n scripts/run_linux_transcript_recovery.sh`: 0.020 seconds.
- `dart format --output=none --set-exit-if-changed integration_test/linux_transcript_recovery_test.dart integration_test/support/transcript_recovery_native_fixture.dart`: 0.132 seconds.
- `flutter analyze --no-pub`: no issues, 17.192 seconds.
- `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_transcript_reconnect_test.dart test/features/hermes_chat/screens/hermes_chat_transcript_accessibility_test.dart test/core/hermes/channel/hermes_approval_settlement_owner_test.dart`: 15 tests, 20.716 seconds.
- `flutter test --no-pub --concurrency=1 -d linux integration_test/linux_transcript_recovery_test.dart`: one test executing four GTK cases, 92.832 seconds. Flutter ignores integration-test concurrency; CMake parallelism is bounded at 2.
- `timeout 25m bash scripts/run_linux_transcript_recovery.sh`: `NATIVE_TRANSCRIPT_RECOVERY_PASS`, 167.222 seconds.

Earlier attempts are retained as failures, not hidden: missing development metadata,
a brace analyzer notice, wrong status-label assertion, an incomplete read-route
receipt allowlist, next-approval visibility/pump timing, focus captures before
ink animation settled, and a receipt publication race. Atomic rename now publishes
receipts only when complete. A preliminary behavioral pass preceded the stronger
focus oracle. Cost, total model usage and review duration are unknown.

## Reproduction and limits

Keep the predecessor source archive at the `BASELINE` path declared in the driver.
Prepare an owned development prefix using the
[reviewed user-space recipe](native-relaunch-workflow.md#safe-user-space-prerequisites-and-reproduction),
substituting `build/t_912b8858/deps/downloads` for packages and
`build/t_912b8858/deps/sysroot` for root. Download/extract the listed 13 packages
without sudo, and rewrite `.pc` prefixes to that extracted `usr`. The driver uses
only this card's prefix; inherited compiler-prefix environment is discarded.
Run `timeout 25m bash scripts/run_linux_transcript_recovery.sh`. It accepts no
arguments or live credentials. Existing Flutter/package configuration and Go
module cache must be provisioned; the runner copies rather than installs them.

Observed Linux x86_64 GTK 3.24.41, GStreamer 1.24.2, libsecret 0.21.4, Flutter
3.44.2. Captures show the logical Flutter surface within an owned Xvfb window,
not OS scaling or physical-device dimensions. Actual-Agent auth/generation,
provider limits, real tool approvals/Stop, process relaunch restoration, physical
keyboard/screen reader, other platforms and protected-main delivery are
NOT_CHECKED. `PARITY-LIVE-WORKFLOW` remains partial/in_progress;
`VERIFY-CHAT-TRANSCRIPT-NATIVE` is not closed. M1 remains open.
Next seam: actual-Agent qualification when supported budget/auth prerequisites
exist; otherwise bounded native failure recovery. No follow-up card was created.

Questions: none. Defaults applied: deterministic transport, no live inference,
existing presentation, source-bound additive qualification, independent native review.
