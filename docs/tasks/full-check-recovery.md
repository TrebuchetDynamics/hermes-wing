# Full offline check result recovery

This is a bounded infrastructure repair contract, not a product-test repair or a
new qualification claim. The owning task is `CHECK-RESULTS-001`, now in Needs
decision for the [unresolved admission boundary](#review-finding-and-admission-blocker).
Its acceptance, scope, checks and exclusions are unchanged. Keep the complete
offline Flutter inventory and the [required checks](../../CONTRIBUTING.md#required-checks).

## Inspected evidence

Read these files **in place**, relative to `git rev-parse --git-common-dir`:

`autowork-execution/main-evidence/a6a560b6ec761b8e7fd543303ce56075335998e6/`

- `main_check.json`: state `broken`, crash `Bad state: No element`, checked revision
  `a6a560b6ec761b8e7fd543303ce56075335998e6`; previous green revision
  `66c8a28e02863bc49f0c83d284e9cce712cdc04f`.
- `main-check.log`: dependency preparation completes, Flutter reports test results,
  and line 3624 contains the recorded crash string inside a Flutter framework
  exception. Line 4761 ends `23:45 +4134 ~9 -5: Some tests failed.`
- `main-check.exit`: `1`.
- `main-check-reruns.log`: empty; `flaky_history.json`: `{}`.

The maintainer request reports two check-crash attempts. The published bundle
contains the final log, not two independently retained attempts. Its classification
and log disagree: do not describe this log as containing no test results, infer
flakiness, or create product/test-name repair tasks from the crash label. No test
was rerun by this documentation pass, and main is not declared green or red here.
Do not copy the bundle into a worktree or commit.

### Previous main bundle

The later bundle was also read in place:
`autowork-execution/main-evidence/e611aa9c750fb1231628236f723c25872bb825e0/`.
Its `main_check.json` records checked revision
`e611aa9c750fb1231628236f723c25872bb825e0`, the same previous green revision,
state `broken` and crash `Bad state: No element`. In `main-check.log`, the crash
string is at line 3628, but line 4765 reports
`30:56 +4137 ~9 -5: Some tests failed.`. `main-check.exit` is `1`,
`main-check-reruns.log` is empty and `flaky_history.json` is `{}`.
The log does not identify the SDK version. This is another classification/output
mismatch, not evidence that no tests ran or that the SDK needs replacement.
Keep this existing recovery task; do not open duplicate MAIN, named-test repair
or flaky-test tasks from the crash label. No new main verdict is asserted here.

### Latest main bundle and reader recheck

Read in place:
`autowork-execution/main-evidence/3b009e155c802fccf44ae79691534932ca483796/`.
`main_check.json` records that checked revision, the same previous green revision,
state `broken` and crash `Bad state: No element`. The log contains the string at
line 3628 and terminal `21:03 +4137 ~9 -5: Some tests failed.` at line 4765.
`main-check.exit` is `1`, `main-check-reruns.log` is empty and
`flaky_history.json` is `{}`. The request reports two crashes; this retained
bundle alone does not supply two independent attempt logs or isolated reruns.

A read-only Python probe of installed release
`075f01eda4b1b1074ededb099ed654ab1f70c005`, `pi_autowork/main_check.py`, consumed
this log without running a suite or changing runner state. For the unchanged
repository `Full check:` command it returned `failures(...) == []`,
`complete_results(...) == False` and `crash_line(...) == 'Bad state: No element'`.
Inspection of that release's `worker.py:_run_gate` (lines 527–617) still shows
`base_result` receiving the candidate command and comparison by recognized failure
IDs. The reporting and baseline-transition boundaries remain unresolved; this is
not evidence of a missing or faulty SDK, flakiness or newly qualified main.
Keep the same task in Needs decision, with all acceptance and write boundaries
unchanged. No duplicate task, named-test repair or blocker-resolution note is added.

## Result-consumption boundary

Read-only inspection of installed Autowork release
`56be5eddb532d2e001adabbac2bb22e6607cca3f`, module
`pi_autowork/main_check.py`, found:

- `FAILURE` (line 25) and `failures()` (line 363) recognize unittest, pytest and Go
  failure records, not Flutter's expanded failure records.
- `complete_results()` (lines 372–406) recognizes a direct `python -m unittest`
  command with a real unittest terminal summary, or the supported `CHECK` inventory
  sections. The current compound Flutter command does not meet either form.
- `crash_line()` (line 338) can select `Bad state` from an application-test exception
  when no supported failure ID was extracted.

These observations explain a reporting mismatch; they do not establish a faulty
Flutter SDK or a product-code cause. The current entrypoint is
[AGENTS.md](../../AGENTS.md#validation), line 220:

```sh
flutter pub get --offline --enforce-lockfile && flutter test --no-pub --concurrency=1
```

The supported setup is Flutter 3.44.2 and its matching Dart SDK, per
[CONTRIBUTING](../../CONTRIBUTING.md#setup). Do not upgrade dependencies, change the
lockfile or modify the installed runner to work around this contract.

## Bounded implementation

Restate the repository's `Full check:` line through a repository-owned Python
unittest entrypoint (`scripts/full_check_test.py`, invoked with
`python3 -m unittest scripts.full_check_test`). Its real orchestration test runs
the unchanged two-command offline sequence above, after checking the documented
SDK. It must retain child output, numeric exits and Flutter's terminal results;
preparation failure, missing results, interruption and nonzero Flutter exits must
fail rather than become success or a skip. The unittest summary counts the
orchestration test, **not** Flutter cases. Never print invented unittest summaries,
rename Flutter failures as individual Python tests, suppress exceptions or reduce
the inventory to make the classifier happy.

Add focused synthetic subprocess regressions in
`test/tooling/full_check_runner_test.py`: successful complete suite, failed suite
with terminal results, setup failure, wrong/missing SDK, and absent/interrupted
terminal results. Use deterministic fake outputs, not the retained raw bundle.
Prove that the installed reader recognizes genuine entrypoint failure/completeness
output without editing its implementation or state. Keep focused helper tests
separate from the full-suite invocation to avoid recursion.

Update only the entrypoint documentation needed in AGENTS/CONTRIBUTING and this
handoff. Record the exact source, SDK, command, child exit and terminal result of a
fresh complete full check. Existing Flutter failures remain failures for separate
evidence-backed triage; this task succeeds at making them observable, not at
making every product test pass. No private coordinator handoff is a prerequisite.
No Agent/runtime/upstream changes, live operations, publication or platform
qualification are authorized.

## Review finding and admission blocker

Both implementation attempts remain retained, not integrated into the inspected
main revision. Their reports, reread for the latest bundle, are now archived under
Git-common `autowork-execution/slot-history/CHECK-RESULTS-001/1/slot-data/`
(the former location was `autowork-execution/slot-data/CHECK-RESULTS-001/`):

- `attempt-1/report.json`: candidate
  `2e76623a925e7093e39e27a2310721c957932ddd`.
- `attempt-2/report.json`: candidate
  `8e7ca0a51d1a3b75d7f79dfb9fb7d59f87295305`.

The second report records six synthetic passes and read-only reader probes, but
explicitly leaves the new-command/baseline-import mismatch unresolved. These
reported checks are historical evidence, not tests executed by this docs pass.
Current main has neither `scripts/full_check_test.py` nor its synthetic test file;
do not close the task on the strength of an unlanded candidate.

Read the retained gate evidence in place under the runner's state directory
`full-check/` (not a repository path):

| Evidence | Observed result |
| --- | --- |
| `CHECK-RESULTS-001-merged.log` | Integration source `04c174ec11314264922f817c51c0076b3480aa4a`, clean working tree; Flutter 3.44.2/Dart 3.12.2; SDK and offline locked preparation exits 0; serial Flutter suite exit 1, terminal `+4137 ~9 -5: Some tests failed.`; genuine unittest `Ran 1 test in 1357.156s`, `FAILED (failures=1)`. |
| `base-e611aa9c750fb1231628236f723c25872bb825e0.json` and `.log` | The same new command, `python3 -m unittest scripts.full_check_test`, runs on a baseline without that module. Exit 1, `ModuleNotFoundError`, ID `unittest.loader._FailedTest.full_check_test`. It does not run Flutter. |

The review record in the runner's `review-findings/CHECK-RESULTS-001.json`
names integration `04c174ec11314264922f817c51c0076b3480aa4a` and the unresolved
finding: **the full check has new failures the base does not:**
`scripts.full_check_test.FullOfflineFlutterCheck.test_full_offline_suite`.
The merged log's failure is the real orchestration assertion on the nonzero
Flutter exit, not a fabricated test result. It is nevertheless a different ID
from the baseline import error.

Read-only inspection of installed release
`e95ed78b907a6d2f782768e4307d35b095ac7ad2` confirms that
`pi_autowork/worker.py:_run_gate` uses the candidate command for the base and
compares recognized failure IDs. Its `main_check.py` still does not recognize
direct Flutter failure IDs or completeness. Reader recognition of synthetic
unittest output therefore does not establish baseline equivalence or admission.
Staging only the helper first leaves the old direct-Flutter reporting boundary;
no verified repository-only split resolves both problems.

The missing external input is a **supported command/result-format transition that
preserves genuine baseline failure comparison**. It is not another owner product
decision or a private coordinator receipt. No such path was established by these
attempts. Keep `CHECK-RESULTS-001` in Needs decision rather than retrying the same
candidate or unchanged full suite. Do not alter installed Autowork, bypass its
guards, relabel failures, mask the nonzero exit, reduce the inventory or repair
excluded product/tests to force this task through. No blocker-resolution note or
acceptance waiver is justified. Reassess the retained candidate only after a
supported transition path is available; retain all four acceptance items and use
the runner-owned merged-tree gate, not a duplicate worker full run.

## Verification boundary

This docs pass inspects retained evidence and validates task metadata, links and
whitespace only; it runs no Flutter, synthetic harness or full-suite check. The
merged-run results above belong to the named retained integration, not current
main or a fresh docs-maintainer execution. The task remains open and blocked,
with disjoint Touches from the existing Linux qualification chain. No goal,
product, platform or live/device qualification is advanced.
