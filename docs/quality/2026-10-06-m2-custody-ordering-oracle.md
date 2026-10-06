# M2 isolated custody-ordering oracle follow-through

Status: inspected execution receipts, not a new product test run.
Card: `t_40dcd771`. Backlog: `QA-M2-CUSTODY-ORDERING-ORACLE`.
Branch: `agent/wing/t_40dcd771` at `c0ff6edb`.
M2 remains unverified.

## Delivered behavior and evidence

The [test-only oracle](../../test/tooling/m2_receipt_admission_test.dart) uses
private fake authority, storage, retention and writer types. It calls the existing
`M2Validator` and `M2Journal`; it does not install a runtime coordinator.

The [acceptance receipt](../../.task-evidence/t_40dcd771/acceptance.json) maps
seven required observations to isolated tests: OBS-PAIR, OBS-REPLAY, OBS-REGISTER,
OBS-RELEASE, OBS-READRACE, OBS-RETAINRACE and OBS-TWOWRITERS. Completers hold reads,
retention and writes. Separate counters distinguish inspection from journal readback.
The oracle checks exact prior-byte retention before explicit writer release,
competing facade refusal and revoked late completion. Three mutated fake models
show that the checks detect missing retention, facade-keyed registration and an
omitted post-await epoch check.

The retained release command was:

```bash
flutter test --no-pub test/tooling/m2_receipt_admission_test.dart
```

The [release receipt](../../.task-evidence/t_40dcd771/test-release.json) records
exit 0 and 18 passes. Its retained log matches the embedded release log in
[logs.json](../../.task-evidence/t_40dcd771/logs.json).
Earlier `test-final.log` records 17 passes; it is not the 18-pass release receipt.
The acceptance receipt also records successful formatting, scoped analysis and
`flutter analyze --no-pub`. These checks were not rerun by this documentation pass.

The documentation check compared seven selected source hashes in
[final.json](../../.task-evidence/t_40dcd771/final.json) and the authored test hash.
All eight match the current files. The test also matches its committed branch blob.
The worker's full tree binding was not recomputed here. Independent final review
approval is not established by these executor receipts or the branch name.

## Qualification limits and next proof

All custody types are private to the test library. Public runtime constructors,
observer startup and secure sink composition remain unchanged. This oracle does
not enforce runtime caller closure, independent installed authority, cross-process
exclusion, secure plugin I/O, persistence or process-death survival.
`continuation_unavailable`, `history_admission_unavailable` and
`authoritative_counts_unavailable` remain explicit limits. Synthetic counters do
not prove zero live mutations.

The [custody requirements](2026-10-06-m2-custody-proof-review.md) require a complete
runtime caller/import/export/constructor closure before enforcement can be proposed.
[DOC-M2-RUNTIME-CALLER-CLOSURE](../../TODO.md#now--next) prepares that bounded proof
and identifies the smallest missing executable check. It does not activate an
issuer, migrate constructors or authorize real storage, packaging or transport.

The completed oracle stays done in `goals.json`; M2 stays unverified. The worker's
ledger validation failed because no open M2 task remained. The new follow-up covers
that gap without reopening a completed gate or treating a fixture as Android proof.
No product, platform, API or release support claim changes.
