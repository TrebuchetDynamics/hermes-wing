# Full Flutter verification — 2026-10-03

## Result and scope

**PASS for the three requested local Flutter checks only.** All commands exited
0. The test runner reported **2,394 passed, 0 failed, 0 skipped**. No failing tests
were observed, so no failure-specific investigation or rerun was required.

Source: actual command execution in this Wing checkout, on Linux, at commit
`ca149a82189c8c9e5abd98b376bfeae1e43f6f3f`, with the pre-existing dirty worktree.
Commands ran sequentially from the repository root. Toolchain: Flutter 3.44.2,
framework revision `c9a6c48423`, Dart 3.12.2, DevTools 2.57.0.
The run occurred on October 3 in the session's UTC−06 timezone; UTC timestamps
below therefore fall on October 4.

This report does **not** establish runtime/card acceptance, production transport
qualification, browser or native-device acceptance, live Agent compatibility,
physical speech/acoustic behavior, release readiness, or signed distribution.
The default `flutter test` run covers discovered tests under `test/`; it does not
execute the device flows under `integration_test/`. Formatting covers all three
specified directories; analysis uses the checkout's configured analyzer scope.
Go, web build, Playwright, npm audit, CI and platform integration checks are not
part of this delegated report.

## Observed checks

| Exact command | Exit | Started UTC | Ended UTC | Observed output and evidence |
| --- | --- | --- | --- | --- |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | 0 | 2026-10-04T00:49:40.899326Z | 2026-10-04T00:49:43.502528Z | `Formatted 398 files (0 changed) in 2.56 seconds.` — `format.log:1` |
| `flutter analyze` | 0 | 2026-10-04T00:49:43.502730Z | 2026-10-04T00:49:48.569176Z | `No issues found! (ran in 4.4s)` — `analyze.log:2` |
| `flutter test --concurrency=1` | 0 | 2026-10-04T00:49:48.570816Z | 2026-10-04T00:56:27.414233Z | `06:34 +2394: All tests passed!` — `test.log:2581` |

Counts were parsed programmatically from the runner's terminal summary, rather
than counting progress messages: pass counter 2394, no failure or skip counter,
exit 0 and `All tests passed!`. The log contains no `[E]` or
`EXCEPTION CAUGHT` failure markers. Parsed evidence is in `parsed-counts.json`.

## Local evidence paths

Canonical local evidence directory (scratch files are not committed and may be
pruned):

```text
/home/xel/.hermes/profiles/wing/cache/scratch/full-flutter-verification-2026-10-03/
  format.log
  analyze.log
  test.log
  results.json
  parsed-counts.json
  toolchain.log
  baseline-status.log
  final-status.log
  mid-run-scope-hashes.json
  scope-changes-since-mid-run.json
```

`results.json` records the verbatim commands, individual exit codes and full UTC
timestamps. Its `log` fields retain the original capture locations under
`/home/xel/.cache/tmp/full-flutter-verification-2026-10-03/`; identical logs were
copied into the canonical scratch directory above after execution.

## Worktree preservation and freshness

No production, test, localization, dependency, package/environment configuration
or upstream source was edited by this verification task. The formatter used
`--output=none` and reported zero changed files. The only owned repository write
is this report. Normal Flutter validation may update ignored build/tool caches;
these are not implementation edits.

A hash snapshot of all files under `lib/`, `test/` and `integration_test/` taken
mid-run matched the post-run snapshot exactly (`scope-changes-since-mid-run.json`
is an empty array). There was no pre-run content hash snapshot, so this does not
assert byte-level immutability during the early portion of the run. Baseline and
post-run Git status retained all pre-existing entries; the only additional
entries before this report was written were two other workers' quality reports.
Concurrent work and subsequent edits can make this evidence stale; this is not a
clean-tree or future-state claim.

## Failures and remaining qualification

None of the three requested checks failed. No source/test fix was attempted.
Runtime/card acceptance remains unverified by this report and must use separate,
target-specific execution evidence. Any code edits after this run require the
appropriate checks to be rerun before reusing this result.
