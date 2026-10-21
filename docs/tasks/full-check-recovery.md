# Full offline check result recovery

This is a bounded infrastructure repair contract, not a product-test repair or a
new qualification claim. The owning task is `CHECK-RESULTS-001`. Keep the complete
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

## Verification boundary

This docs pass inspects evidence and validates task metadata, links and whitespace
only. All implementation and runtime checks above remain planned and unrun. The
new task has disjoint Touches from the existing Linux qualification chain; it does
not replace, release or close that chain or any live/device gate.
