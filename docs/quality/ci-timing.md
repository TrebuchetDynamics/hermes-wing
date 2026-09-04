# CI completeness and timing

`Platform readiness` and `Release readiness` are stable aggregate statuses.
`scripts/ci_gate.mjs` requires every configured job to report success. Dependency
review is required on pull requests; provider and emulator jobs are required when
explicitly enabled. Other optional jobs may report skipped, but a started failing
or cancelled optional job cannot make the aggregate green. Branch protection has
not been changed by this implementation.

Both workflows run `scripts/ci_test_receipt.mjs`, which discovers standalone
`test/**/*_test.dart` files, excludes `part of` fragments, and checks the Flutter
machine reporter's suite inventory, started/completed tests, terminal success,
and process exit. Exit zero without complete results fails. The runner retains
coverage and concurrency one, with a 30-minute test timeout and bounded shutdown.
Its receipt contains repository-relative test paths, counts, elapsed milliseconds,
and one of `success`, `assertion-failure`, `infrastructure-failure`, `timeout`, or
`result-finalization-failure`. It omits test names, error contents, absolute paths,
device identifiers, and transcript data. Startup invalidates any old receipt.
Full test stdout/stderr is retained in ignored `build/flutter-ci-test.log` for
debugging, with console progress every 30 seconds and immediate error events.
That log is not a public qualification receipt and is not uploaded by the timing
artifact step.

The workflow uploads `platform-flutter-test-timing` or
`release-flutter-test-timing`, including on failure when a receipt exists. Failure
before the runner can produce a receipt remains a failed job, never an inferred
test pass. Per-suite time includes suite loading and test execution and may
overlap in the runner; use the receipt's overall elapsed time for the phase gate.

## Measurement gate

No representative hosted timing receipts were collected in this local execution.
The sample count is **0 of 10**, and median/p95 are **not measured**. Collect ten
successful representative runs and compare test-phase duration against setup and
build duration before considering sharding. The proposed threshold is median
greater than 10 minutes or p95 greater than 15 minutes, with tests dominating.
These thresholds are not observed results. Retain the present lane count until
that gate is met. No shard planner or artifact reuse across incompatible targets
was added.

Node behavioral tests cover missing, duplicated, unknown and empty inventories,
new standalone files, part fragments, failed/cancelled/skipped jobs, incomplete
terminal results, assertion failures, and timeouts. Local synthetic results do not
qualify hosted runners or any physical platform.
