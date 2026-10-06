# Flutter suite keyboard follow-through

Status: inspected execution records and later scoped repair, not a fresh gate.

## Earlier broad run

The completed background process `proc_40694fad1eff` ran:

```sh
timeout 900s npm run test -- --no-pub
```

`package.json` maps `npm run test` to `flutter test --concurrency=1`.
The observed exit was 1, not the timeout exit 124. The terminal summary recorded
2,846 passing tests and one failure. The profile-local scratch log is
`openapi-npm-test-full.log`, SHA-256
`88fb8f6e3c0b199cf0ea1251973c7888165c6130865322fc26375e8444b99dd4`.

The failing test was `shell keyboard semantics survive /providers at 1280.0 / 200%`
in [the inventory keyboard test](../../test/shared/widgets/inventory_keyboard_navigation_test.dart).
After Tab left the search editor, Shift+Tab did not restore its focus.
The expectation at line 254 reported `Expected: true`, `Actual: <false>`.

This run predates the forward repair below. No launch-time source-fingerprint
receipt was recovered for the broad run. Its log proves that run's outcome,
not current-source failure or causal attribution to documentation changes.
It does not include analyzer, Go, browser or native-app qualification.

## Later forward repair

The [Providers runbook](../runbooks/provider-search.md#forward-shared-shell-repair-receipt-t_c5a4d301)
owns the diagnosis, fixed traversal behavior, exact focused commands and limits.
Task `t_c5a4d301` is done; its authorized native review run 98 approved the
bounded shared-shell repair. Original cards `t_11b62717` and `t_1c1e6f37` remain
blocked. Native review is the approval lane, not native app execution.

Inspected retained evidence records:

- 120 unique focused widget cases across traversal, original inventory and
  neighboring Providers/shared-shell checks.
- Five compiled deterministic Chromium journeys, with no skipped, unexpected
  or flaky results in `browser-results.json`.
- A fresh reviewer execution of four new and eight unchanged original cases:
  12 passed, exit 0. Reviewer formatting, analyzer and scoped checks also passed.
- All five task-final source/document hashes matched before this documentation
  pass. Later runbook status wording is documentation maintenance, not a new
  implementation snapshot or a rewrite of the immutable review evidence.

The profile-local journal is `autogoal/shared-shell-keyboard-forward/`.
`verification-summary.json`, `final-hashes.json`, `browser-results.json` and
`native-review-run98.md` retain the mapped evidence. No log or test was fabricated
or rerun for this follow-through document.

## Remaining qualification

No post-repair full-suite result is established by these focused checks.
Browser 200% text, native desktop runtime, Android, physical screen reader,
live Agent/provider, full daily-use workflow and release remain unchecked here.
The [parity ledger](../product/hermes-desktop-parity.md) and
[root handoff](../../TODO.md) preserve the independent restoration and native/live
admission gates. This record does not authorize another suite, repair or card change.
