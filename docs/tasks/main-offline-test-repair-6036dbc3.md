# Compact-corner offline gate repair

## Contract and evidence

`MAIN-REPAIR-004` owns the single recorded main failure; it does not own new
Desktop features or Files implementation. `FILES-TERMINAL-BROWSE` retains every
accepted outcome and waits for this shared prerequisite before another merged gate.
No existing open repair covers this test; MAIN-REPAIR-001–003 are closed.

Read the original bundle **in place**, under the Git common directory:
`autowork-execution/main-evidence/6036dbc34690d192c8275c94d20b2de16893a249/`.
Do not copy logs/runtime state into a checkout or commit them.

- `main_check.json`: TEST_FAILURE, checked revision
  `6036dbc34690d192c8275c94d20b2de16893a249`, previous green
  `056d01deec1b3111b7798802b90309ea59046fbf`, red since
  `64729223d639e99bab624d0fa05a77f95e480ec4`.
- `main-check.log:1640–1663`: only failing case is
  `test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart`:
  **message surfaces use the compact Desktop corner treatment**.
  At test line 1219, expected `BorderRadius.circular(20.0)`, actual
  `BorderRadius.circular(3.2)`.
- `main-check.log:4705–4708`: `23:21 +4184 ~9 -1: Some tests failed.`;
  `main-check.exit` is `1`.
- `main-check-reruns.log` is empty; `flaky_history.json` is `{}`.
  No isolated main-bundle reruns or three-revision flaky proof exist. This is
  neither a crashed check nor evidence to reclassify main as flaky/green.

Commits since that green, as recorded by `main_check.json`:

1. `6036dbc3` — docs(files): distinguish managed-root plan from historical cwd deferral
2. `64729223` — Merge commit '9a6fc49d17fd2c58a479ddb509be0b0438114687' into pi-autowork/20261017-134450
3. `9a6fc49d` — Merge desktop parity implementation into main
4. `f3ae3859` — docs: track Desktop parity scope, verification and remaining gates
5. `ad666107` — feat: start literal Desktop parity with safe credential admission

## Source trace and bounded repair

The [current accepted clone execution](../plans/2026-10-21-desktop-literal-clone.md#ejecución-vigente--2026-10-24)
supersedes the historical Muse/Duet 20px treatment. Its appearance section traces
the user row to `rounded-xl` with scalar `0.2` (3.2px) and assistant prose to no
bubble. This is an existing decision, not a new visual choice.

`git show ad666107 -- lib/features/hermes_chat/presentation/hermes_chat_timeline.dart`
changes `_TurnBubble` from 20px for both authors to 3.2px for users and 0 for
assistants, with a full-width user row and transparent normal assistant surface.
Current `hermes_chat_timeline.dart:1028–1052` retains that behavior.
`test/features/hermes_chat/screens/hermes_chat_desktop_geometry_test.dart:31–53`
already checks transparent square assistant prose and 3.2px user corners at
390/960/1440 widths. Before this repair, the rich-transcript case at lines
1194–1221 expected 20px for both authors, contradicting the geometry coverage.

## Worker repair and offline verification

Source: `47a2ac14ffc11e3d4da908a8f20073489b3a9633` on
`autowork/MAIN-REPAIR-004`, with only the two radius expectations changed in
`test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart:1219–1220`.
Tested file Git blob: `b49253e295ca763ed14eeeb0530c9fbf0abec4c4`.
No production code, geometry coverage or neighboring assertions changed. Explicit
user 3.2px and assistant zero-radius assertions remain independent literals;
restoring either superseded 20px treatment would fail the corresponding assertion.

Executed on the Linux host with Flutter **3.44.2**, framework
`c9a6c484230f8b5e408ec57be1ef71dee1e77020`, engine
`77e2e94772b6eb43759e34ed1ad7da4674e19cab`, Dart **3.12.2**:

| Command | Exit | Actual result |
| --- | --- | --- |
| `flutter --version --machine` | 0 | SDK revisions above. |
| `flutter pub get --enforce-lockfile` | 0 | Locked dependencies resolved; manifest and lockfile unchanged. |
| `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart --plain-name 'message surfaces use the compact Desktop corner treatment'` (before edit) | 1 | `00:03 +0 -1`; expected 20.0, actual 3.2 at line 1219, reproducing the recorded failure. |
| Same focused command (after edit) | 0 | `00:01 +1: All tests passed!` |
| `autowork-run flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart test/features/hermes_chat/screens/hermes_chat_desktop_geometry_test.dart` | 0 | `00:25 +95: All tests passed!`; all 91 rich-transcript and 4 geometry cases, no skips or failures. |
| `dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart test/features/hermes_chat/screens/hermes_chat_desktop_geometry_test.dart lib/features/hermes_chat/presentation/hermes_chat_timeline.dart` | 0 | 3 files checked, 0 changed. |
| `autowork-run flutter analyze --no-pub` | 0 | No issues found (36.9s). |
| `autowork tasks validate --worktree .` | 0 | 300 tasks, 36 goals, no drafts or pending validation errors. |
| `git diff --check` | 0 | No whitespace errors. |

The worker instruction explicitly delegates the unchanged full check
(`flutter pub get --enforce-lockfile && flutter test --no-pub --concurrency=1`)
to the coordinator on the merged tree. It was **not run by this worker**; its
source, exit, terminal totals and any remaining failures must come from that gate.
There are no remaining failures in the executed focused checks. This local repair
is not integration, green-main evidence, native/device execution, live-service
qualification or visual parity acceptance. Keep main red until a complete passing
full gate is recorded. No Files or credential behavior was implemented.

Scoped Docs Sync Maintain updates this existing repair/test-evidence owner only;
the accepted appearance plan remains unchanged. Revisit this receipt if accepted
message geometry or these test cases change. The coordinator owns task closure,
shared history and the final merged-gate receipt.

## Files review finding and retained work

Read-only evidence in the Git common directory:

- `autowork-execution/slot-data/FILES-TERMINAL-BROWSE/attempt-1/report.json`:
  candidate `9311fe4c185e85270ab5da94025c69118d40447e`.
- `autowork-execution/slot-data/FILES-TERMINAL-BROWSE/attempt-2/report.json`:
  candidate `6200cc0066bf8a8e396f3285f24b5446cefc0672`, 18 focused passes,
  analysis/browser passes reported, broader Flutter raw exit 1 from this same
  unchanged corner test. It reports reproduction before edits at `64729223`
  and one final isolated reproduction. These are worker reports, not fresh
  maintainer runs or an accepted full check.
- `autowork-execution/slots/FILES-TERMINAL-BROWSE.json`: held, not running or
  pending landing; latest integration candidate
  `076781e5bd3da4d99e50015aa7a040cf29aea534` at baseline `ae1feb765a64927bae5e0acf028deb790595b46e`.
- `autowork-execution/e01e825efd224d7e81f6b0ade8a71dd7.json` and `.log`:
  CHECK_FAILED, exit 1; rejects the integration for the same corner-treatment
  test as a new failure relative to its base. Preserve that finding; do not
  override the classifier from the worker's baseline claim.

After MAIN-REPAIR-004, reconcile the retained Files candidate rather than discard
or duplicate its implementation. Rerun its original checks and the normal merged
full gate against the repaired baseline. Keep locked-root admission, containment,
redaction, zero mutations and stale-owner protections unchanged; actual-Agent,
Linux/Android device and download qualification remain separate. Exact Files
Touches come from the attempt-2 report, including its four component/product docs.
The original documentation-only pass executed no application changes or Flutter
checks; the worker's later focused verification is recorded above.
