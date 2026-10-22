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

### Previous reader recheck (3b009e15)

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

### Current main bundle and reader recheck (de97a6d6)

Read all five bundle files in place:
`autowork-execution/main-evidence/de97a6d6b02efe0d9d1ac31d91acf28e9bdf5cf9/`.
`main_check.json` records that checked revision, the same previous green revision,
state `broken` and crash `Bad state: No element`. The log contains the string at
line 3628 inside a Flutter framework exception, then reaches
`18:36 +4137 ~9 -5: Some tests failed.` at line 4765.
`main-check.exit` is `1`, `main-check-reruns.log` is empty and
`flaky_history.json` is `{}`. The request reports two crashes; this bundle retains
one final log, not two independent attempt logs or isolated rerun evidence.
Do not infer that no tests ran, a faulty SDK or flakiness from its classification.

A read-only probe of requested release
`dd0602e8328e532f805c10a69412adef87d139f6`, `pi_autowork/main_check.py`, against
this log and the unchanged repository `Full check:` command returns
`failures(...) == []`, `complete_results(...) == False` and
`crash_line(...) == 'Bad state: No element'`. Its `worker.py:_run_gate`
(lines 527–617) still passes the candidate command to `base_result` and compares
recognized failure IDs. Both archived worker reports, the retained review finding
for integration `04c174ec` and the `base-e611aa9c` receipt were reread; they do not
supply a supported command/result-format transition. The current tree still has
neither wrapper file. Keep the existing `CHECK-RESULTS-001` in Needs decision and
all its acceptance, checks, exclusions and write boundaries unchanged. This is an
evidence refresh, not a blocker repair or task restart. No duplicate or named-test
repair task, new suite run, qualification or Blocker resolution is claimed.

### Latest bundle (b7abbd4d)

Read all five files in place under Git-common
`autowork-execution/main-evidence/b7abbd4d25c6f36f936bdc9873e85c2de91cb77c/`.
`main_check.json` names that checked revision, previous green
`66c8a28e02863bc49f0c83d284e9cce712cdc04f`, state `broken` and crash
`Bad state: No element`. The log contains that string inside a Flutter test
framework exception at line 3628, then reaches
`20:35 +4137 ~9 -5: Some tests failed.` at line 4765. Exit is `1`, reruns are
empty and flaky history is `{}`. Only one final log is retained; the request's two
attempts are not independently evidenced by this bundle. The classification does
not establish a crash before test results or a missing SDK.

A read-only probe of requested release
`390ec0844e589625b6dd4a460545ef2d5749acfe`, `pi_autowork/main_check.py`, consumes
that log with the unchanged repository Full check command and returns
`failures(...) == []`, `complete_results(...) == False` and the recorded crash
string. Its `worker.py:_run_gate` still passes the candidate command to
`base_result` and compares recognized failure IDs. Both archived worker reports,
the retained `04c174ec` review finding and `base-e611aa9c` JSON/log were reread;
neither wrapper file exists in this tree. The command/result-format transition
remains unresolved. Keep the existing task in Needs decision with every accepted
boundary intact; do not create another recovery or named-test repair task, retry
the unchanged full suite, or claim a blocker resolution or main verdict.

### Latest bundle (1c94fc1b)

Read all five files in place under Git-common
`autowork-execution/main-evidence/1c94fc1bf6bedb15d87795e61f3ff6ba885ed3bb/`.
Metadata records that checked revision, the same previous green
`66c8a28e02863bc49f0c83d284e9cce712cdc04f`, state `broken` and crash
`Bad state: No element`. The log places the exception inside the Flutter test
framework at line 3628, then reaches
`17:28 +4137 ~9 -5: Some tests failed.` at line 4765. Exit is `1`, reruns are
empty and flaky history is `{}`. This is one retained final log, not two
independently evidenced attempts; its output contradicts the no-results label.

A read-only probe of requested release `390ec0844e589625b6dd4a460545ef2d5749acfe`,
`pi_autowork/main_check.py`, against this log and the unchanged repository Full
check returns `failures(...) == []`, `complete_results(...) == False` and the
recorded crash string. Its `worker.py:_run_gate` still passes the candidate
command to `base_result` and compares recognized failure IDs. Both archived
worker reports and the retained `04c174ec` review finding were reread; neither
wrapper file exists in this checkout. The supported baseline-preserving
command/result-format transition remains unavailable. Retain `CHECK-RESULTS-001`
in Needs decision with its contract unchanged; no duplicate, named-test repair,
restart, Blocker resolution, new suite run or qualification follows from this
inspection.

### Latest bundle (da81ad13)

Read all five files in place under Git-common
`autowork-execution/main-evidence/da81ad1352068bef6f3b5d9bd4ea159523ac9b82/`.
Metadata records that checked revision, previous green
`66c8a28e02863bc49f0c83d284e9cce712cdc04f`, state `broken` and crash
`Bad state: No element`. The log places the string inside a Flutter test framework
exception at line 3628, then reaches
`16:53 +4137 ~9 -5: Some tests failed.` at line 4765. Exit is `1`, reruns are empty
and flaky history is `{}`. This bundle retains one final log, not two independent
attempt logs. Its terminal output contradicts the no-results classification;
it does not establish a missing SDK or flakiness.

A read-only probe of requested release `390ec0844e589625b6dd4a460545ef2d5749acfe`,
`pi_autowork/main_check.py`, against the entire in-place log and the unchanged
repository Full check returns `failures(...) == []`,
`complete_results(...) == False` and the recorded crash string.
`worker.py:_run_gate` (lines 528–617) still supplies the candidate command to
`base_result` and compares recognized failure IDs. Both archived worker reports,
the retained `04c174ec` review finding and the `base-e611aa9c` JSON/log were reread;
neither wrapper file exists in this checkout. The missing input remains a
supported baseline-preserving command/result-format transition outside this
task's write boundary. Preserve `CHECK-RESULTS-001` in Needs decision and all
accepted scope, acceptance, checks and exclusions. This evidence update does not
restart the task, resolve the blocker, create a duplicate or named-test repair,
run a suite, or qualify main or any goal.

### Latest bundle (f71f14d5)

Read all five files in place under Git-common
`autowork-execution/main-evidence/f71f14d55f771dc03c358e801f0e7efe956838e8/`.
Metadata names that checked revision, previous green
`66c8a28e02863bc49f0c83d284e9cce712cdc04f`, state `broken` and crash
`Bad state: No element`. The log contains that string inside a Flutter framework
exception at line 3628, then reaches
`16:30 +4137 ~9 -5: Some tests failed.` at line 4765. Exit is `1`, reruns are empty
and flaky history is `{}`. One final log is retained, not two independent attempt
logs. The bundle does not support the request's before-any-results description.

A read-only probe of requested release `390ec0844e589625b6dd4a460545ef2d5749acfe`,
`pi_autowork/main_check.py`, consumed the entire in-place log with the unchanged
repository Full check: `failures(...) == []`, `complete_results(...) == False`
and `crash_line(...) == 'Bad state: No element'`. Its `worker.py:_run_gate`
(lines 528–617) still passes the candidate command to `base_result` and compares
recognized failure IDs. Both archived worker reports, the retained `04c174ec`
review finding and baseline JSON/log were reread; neither wrapper file exists in
this checkout. The supported baseline-preserving command/result-format transition
remains unavailable outside this task's write boundary. Preserve `CHECK-RESULTS-001`
in Needs decision with all accepted boundaries unchanged; no duplicate or named-test
repair, task restart, Blocker resolution, new suite run, isolated rerun, main verdict
or goal qualification is established. This is current evidence for the existing
blocker, not another cosmetic attempt to release it.

### Latest bundle (ff302bef)

Read all five files in place under Git-common
`autowork-execution/main-evidence/ff302befe1e2f4e4b1c9d47fd66391aca52e34e1/`.
Metadata names that checked revision, previous green
`66c8a28e02863bc49f0c83d284e9cce712cdc04f`, state `broken` and crash
`Bad state: No element`. The string is inside a Flutter framework exception at
line 3628; line 4765 reaches `19:10 +4137 ~9 -5: Some tests failed.`. Exit is `1`,
reruns are empty and flaky history is `{}`. This retained final log contradicts
"before any test result"; it does not independently retain both reported attempts
or establish a missing SDK, flakiness or a new main verdict.

A read-only probe of requested release `390ec0844e589625b6dd4a460545ef2d5749acfe`
against the entire in-place log and unchanged Full check returns `failures == []`,
`complete_results == False` and the recorded crash string. Its
`worker.py:_run_gate` (lines 528–617) still compares the candidate command on the
base. Both archived worker reports, the retained `04c174ec` review finding and
baseline JSON/log were reread; neither wrapper file exists in this checkout.
The existing [admission blocker](#review-finding-and-admission-blocker) remains:
a supported baseline-preserving command/result-format transition is unavailable.
Keep `CHECK-RESULTS-001` in Needs decision with all acceptance and write boundaries
unchanged. This evidence refresh is not a repair, restart, Blocker resolution,
new task, named-test repair, suite run, isolated rerun or qualification.

### Latest bundle (8efb05f4)

Read all five files in place under Git-common
`autowork-execution/main-evidence/8efb05f473c522a6d9b03e0755e061cec7ecc443/`.
Metadata names that checked revision, previous green
`66c8a28e02863bc49f0c83d284e9cce712cdc04f`, state `broken` and crash
`Bad state: No element`. The string occurs inside a Flutter framework exception
at line 3628; line 4765 reaches `15:58 +4137 ~9 -5: Some tests failed.`. Exit is
`1`, reruns are empty and flaky history is `{}`. This final log contradicts
"before any test result"; it does not independently retain both reported attempts
or establish a missing SDK, flakiness or a new main verdict.

A read-only probe of requested release `390ec0844e589625b6dd4a460545ef2d5749acfe`
against the entire in-place log and unchanged Full check returns `failures == []`,
`complete_results == False` and the recorded crash string. Its
`worker.py:_run_gate` (lines 528–617) still supplies the candidate command to
`base_result` and compares recognized failure IDs. Both archived worker reports,
the retained `04c174ec` review finding and baseline JSON/log were reread; neither
wrapper file exists in this checkout. The existing
[admission blocker](#review-finding-and-admission-blocker) remains outside the
allowed Wing documentation changes. Keep `CHECK-RESULTS-001` in Needs decision
with all acceptance and write boundaries unchanged. No duplicate or named-test
repair, task restart, Blocker resolution, new suite run, isolated rerun or
qualification is justified by this evidence refresh.

### Latest bundle (9887fcd6)

Read all five files in place under Git-common
`autowork-execution/main-evidence/9887fcd620e6e3dcbd4b8a3ead59f555d84ae34a/`.
Metadata names that checked revision, previous green
`66c8a28e02863bc49f0c83d284e9cce712cdc04f`, state `broken` and crash
`Bad state: No element`. The complete log has 4,772 lines: the string occurs
inside a Flutter framework exception at line 3628, and line 4765 reaches
`16:00 +4137 ~9 -5: Some tests failed.`. Exit is `1`, reruns are empty and flaky
history is `{}`. This retained final log does not establish a crash before test
results, both reported attempts independently, a missing SDK or flakiness.

A read-only probe of requested release `390ec0844e589625b6dd4a460545ef2d5749acfe`
against the entire in-place log and unchanged Full check returns `failures == []`,
`complete_results == False` and the recorded crash string. Its
`worker.py:_run_gate` still supplies the candidate command to `base_result` and
compares recognized failure IDs. Both archived worker reports, the retained
`04c174ec` review finding and the baseline JSON/log were reread; the retained
merged log still records genuine unittest failure, while neither wrapper file
exists in this checkout. The missing input remains a supported command/result-format
transition preserving genuine baseline comparison, outside this task's write
boundary. Keep `CHECK-RESULTS-001` in Needs decision with its accepted contract
unchanged. No duplicate or named-test repair, restart, Blocker resolution, new
suite run, isolated rerun, main verdict or qualification is justified.

### Previous bundle (e2955ede)

Read all five files in place under Git-common
`autowork-execution/main-evidence/e2955eded3a7318c23690a9452402e534b4274c5/`.
Metadata names that checked revision, previous green
`66c8a28e02863bc49f0c83d284e9cce712cdc04f`, state `broken` and crash
`Bad state: No element`. In the 4,772-line log, line 3628 contains that string
inside a Flutter framework exception; line 4765 reaches
`19:34 +4137 ~9 -5: Some tests failed.`. Exit is `1`, reruns are empty and flaky
history is `{}`. The retained log contradicts “before any test result”; it does
not independently evidence both reported attempts, a missing SDK or flakiness.

A read-only probe of requested release `390ec0844e589625b6dd4a460545ef2d5749acfe`
against the entire in-place log and unchanged Full check returns `failures == []`,
`complete_results == False` and the recorded crash string. Its
`worker.py:_run_gate` (lines 528–617) still supplies the candidate command to
`base_result` and compares recognized failure IDs. Both archived worker reports,
the retained `04c174ec` review finding and baseline JSON were reread; neither
wrapper file exists in this checkout. The missing external input remains the
[supported baseline-preserving command/result-format transition](#review-finding-and-admission-blocker),
not an owner product decision or a receipt a Wing worker can manufacture.
Keep `CHECK-RESULTS-001` in Needs decision with all acceptance, checks and write
boundaries unchanged. The task Evidence note now points here for historical
inspections instead of repeating them in one growing line. No task restart,
Blocker resolution, duplicate or named-test repair, new suite run, isolated rerun,
main verdict or goal/platform qualification is established.

### Current bundle (2b72c232)

Read all five files in place under Git-common
`autowork-execution/main-evidence/2b72c232d6cd1bb18020bdcef1c3af9a7b9d1910/`.
Metadata names that checked revision, previous green
`66c8a28e02863bc49f0c83d284e9cce712cdc04f`, state `broken` and crash
`Bad state: No element`. The 4,772-line log contains that string inside a Flutter
framework exception at line 3628, then reaches
`27:00 +4137 ~9 -5: Some tests failed.` at line 4765. Exit is `1`, reruns are
empty and flaky history is `{}`. This retained final log contradicts the
before-any-results classification; it does not independently retain both reported
attempts, identify the SDK version or establish flakiness.

A read-only probe of requested release `020aeb087993b649afbb1993bf12a7fc281f2572`
against the entire in-place log and unchanged Full check returns `failures == []`,
`complete_results == False` and the recorded crash string. Its
`pi_autowork/main_check.py:366–409` still lacks direct Flutter failure/completeness
recognition; `worker.py:_run_gate` (lines 528–617) still supplies the candidate
command to `base_result` and compares recognized failure IDs. Both archived worker
reports, the retained `04c174ec` review finding and baseline JSON/log were reread;
neither wrapper file exists in this checkout. The missing external input remains
a supported command/result-format transition preserving genuine baseline failure
comparison, not SDK provisioning or a receipt a Wing worker can manufacture.
Keep `CHECK-RESULTS-001` in Needs decision with its accepted contract unchanged.
No duplicate or named-test repair, restart, Blocker resolution, new suite run,
isolated rerun, main verdict or goal/platform qualification is justified.

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
