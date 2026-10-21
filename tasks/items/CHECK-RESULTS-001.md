+++
schema = 1
id = "CHECK-RESULTS-001"
title = "Restore runner-readable terminal results for the complete offline Flutter check"
short = "Recover full-check result reporting"
status = "open"
goal = "INTEGRATION"
section = "Now"
rank = 1000
depends_on = []
touches = ["AGENTS.md", "CONTRIBUTING.md", "scripts/full_check_test.py", "test/tooling/full_check_runner_test.py", "docs/tasks/full-check-recovery.md"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Restate Full check through a repository-owned direct Python unittest orchestration entrypoint that runs the unchanged offline locked pub-get and entire serial Flutter suite using the documented Flutter 3.44.2 SDK. Add synthetic harness regressions and update entrypoint guidance. Resolve the recorded result-format mismatch without modifying Autowork, repairing named Flutter tests, changing product code or reducing checks. Preserve failed child outcomes and distinguish one orchestration test from Flutter case counts."
acceptance = ["The documented Full check invokes the entire existing offline sequence on the supported SDK, with no test filtering, dependency upgrade, lockfile change, live opt-in or upstream edit.", "A genuine unittest orchestration test retains Flutter output, numeric child exits and terminal counts, fails on setup failure, missing or interrupted results and nonzero suite exit, and emits no fabricated summaries or skips.", "Focused synthetic tests cover complete success, complete failure, preparation failure, wrong or missing SDK and incomplete results without recursively launching the full suite.", "Read-only validation against the installed result reader demonstrates recognized genuine failure IDs and completeness output, and a fresh full offline run records its actual source, SDK, exits and terminal results even when Flutter tests fail. This is infrastructure recovery, not a green-main or platform qualification claim."]
checks = ["python3 -m unittest discover -s test/tooling -p full_check_runner_test.py -v", "flutter --version --machine", "python3 -m unittest scripts.full_check_test", "git diff --check"]
exclusions = ["No product or named Flutter-test repairs", "No installed Autowork or Agent/runtime/reference changes", "No weakened inventory, fabricated results or masked failures", "No lockfile changes, live operations, credentials, publication or device qualification"]
+++

- Sources: docs/tasks/full-check-recovery.md#bounded-implementation; AGENTS.md#validation; CONTRIBUTING.md#setup; CONTRIBUTING.md#required-checks
- Evidence: Crash line: Bad state: No element. Checked revision a6a560b6ec761b8e7fd543303ce56075335998e6; previous green 66c8a28e02863bc49f0c83d284e9cce712cdc04f. Read in place: Git-common autowork-execution/main-evidence/a6a560b6ec761b8e7fd543303ce56075335998e6/{main_check.json,main-check.log,main-check.exit,main-check-reruns.log,flaky_history.json}. Metadata says broken but log has terminal +4134 ~9 -5: Some tests failed., exit 1; reruns empty and flaky history {}. Installed release 56be5eddb532d2e001adabbac2bb22e6607cca3f main_check.py lacks Flutter failure parsing and direct Flutter completeness recognition. See docs/tasks/full-check-recovery.md for the reporting boundary; no isolated reruns or new pass are claimed.
- Touches: The typed touches array is the write boundary; it is disjoint from the existing Linux qualification chain.
- Acceptance: All four typed acceptance items remain mandatory. Observable terminal failures satisfy reporting recovery, not a passing product suite.
- Checks: Run each typed check separately and retain its exit. The orchestration entrypoint runs the complete unchanged Flutter sequence once; do not append a successful command that masks a failure.
- Exclusions: The typed exclusions preserve all product, runtime, live and qualification boundaries.
- Next action: Implement and exercise synthetic entrypoint regressions first, then run the full check once through the new entrypoint. It must execute flutter pub get --offline --enforce-lockfile && flutter test --no-pub --concurrency=1 without selecting fewer tests. Preserve nonzero terminal results as evidence rather than rerunning the unchanged suite or demanding a product repair in this task.
