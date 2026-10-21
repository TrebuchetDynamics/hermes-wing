# Dormant managed-profile directory retirement — t_7147d64c

Status: implemented and checked offline; independent same-card review pending.
The final local task ref/SHA and repeated acceptance results are recorded by
`finish_task.py` in the native card handoff. No canonical integration or publication.
[CONNECTION-LINK-REMOVAL](../tasks/work-queue.md#current-work-queue) remains in progress;
CONNECTION-LINK-RETIREMENT is not closed.

## Source and admission

Base: `2ac9db4c49bb5b1f9edbc54e4d38bd5dcc083e83`.
The original pre-edit `pass_workspace.py` command returned
`worker_start_admitted`, using manifest
`pass-3b234d1ef9cdce3c-8bdd34adb3354b55968f759e0bfd37ac.json`, SHA-256
`7a2eb836349c665d887a7a7b95a79cb52819fb309bcfd2e16b45c32d40465ff2`,
and the isolated workspace `3b234d1ef9cdce3c-8bdd34adb3354b55968f759e0bfd37ac`.
No manifest repin, admission replay, canonical write, or upstream/runtime edit.

Scoped fingerprint before this receipt:
`88cff716e0d43429b9464f091ed08fed284ee287195d7399b7a1766618acae99`.
Computed over sorted changed Dart paths plus `pubspec.yaml` and `pubspec.lock`,
using SHA-256 of each UTF-8 path, NUL, and file bytes.
Lockfile SHA-256 remains
`f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`.
Toolchain: Flutter 3.44.2 / Dart 3.12.2 on the Linux-hosted Flutter test VM.

## Acceptance evidence and caller closure

- Traced both symbols across `lib`, `test`, and `integration_test` before editing.
  `reconcileManagedProfileRename` had no production caller; its one call was in
  the directory test's online/offline loop. `enrolledGatewayIdForManagedProfile`
  had only that dormant method as a production caller, plus two test call sites.
  Removed both definitions together from
  `lib/features/hermes_chat/gateways/hermes_gateway_directory.dart`.
- Retired only the method-specific online/offline rename tests and enrollment
  lookup cases. The remaining public saved-host tests cover identity and
  credential retention, reads without save/saveAll/delete/clear, active Agent
  ownership, pending-record startup, foreground refresh and reconnect.
- Strengthened the existing public `renameGateway` test: only the display label
  changes; saved ID, Agent URL/profile identity and credential survive, as do all
  five legacy management fields. One save occurs, with no bulk save, deletion or
  clear. Generic rename/edit/refresh/reconnect implementation is unchanged.
- Extended the existing negative guard across all Wing Dart product/tests/fixtures
  (excluding the guard itself) with both retired symbols. RED failed on the
  still-present rename definition. After deletion, all seven guard tests pass.
- Required focused union passes unchanged direct Agent origin/auth/revision,
  secure-store retention/isolation, cached-control and late-completion owner
  fencing, explicit session restoration/retry and no-replay regressions.
  No endpoint store/config/model, grouping, API, export, constructor, fixture
  dependency or configuration changes were needed. No new imports/dependencies.
- No installed records or credentials were read, deleted or migrated. No services,
  providers, devices, upstream repositories or personal runtime were operated.

Decision: delete the two unused methods together rather than introduce another
identity adapter. Evidence: complete caller trace and the preceding
[gateway retirement receipt](gateway-dormant-link-retirement.md).
Reason: smallest complete removal without changing saved data or public controls.
Check: negative source guard and retained public-control/security regression union.
Ponytail full was explicitly requested; no supporting skill protocol was necessary
beyond the contract, repository checks and bundled engineering-cycle guidance.

## Executed checks

All commands ran in the admitted workspace. The finish gate repeats required
acceptance checks before committing only the four owned files.

```text
timeout 3m flutter pub get --offline
git diff --exit-code -- pubspec.yaml pubspec.lock
dart format lib/features/hermes_chat/gateways/hermes_gateway_directory.dart test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart test/tooling/enrollment_retirement_contract_test.dart
timeout 3m flutter test --no-pub --concurrency=1 --reporter expanded test/tooling/enrollment_retirement_contract_test.dart
timeout 5m flutter analyze --no-pub
timeout 10m flutter test --no-pub --concurrency=1 --reporter expanded test/features/hermes_chat/gateways test/features/profiles test/features/gateway test/core/hermes/setup test/tooling/enrollment_retirement_contract_test.dart
git diff --check
```

Offline resolution passed with manifest/lock unchanged. Guard RED was expected,
then seven tests passed GREEN. Formatting: three files, zero changes. Analysis:
no issues in 6.2s. Required union: 422 passed in 56s. Diff check passed.
No implementation test or analysis failure/retry. Independent review duration
and inference cost are unknown. Final formatting, dependency preservation and
local documentation links are checked again by the finish gate.

## Residual consumers and qualification limits

Legacy directory host grouping/projection and generic rename metadata preservation
remain. Saved legacy fields, secure endpoint storage, `lib/core/wing_link/`,
`wing_link/`, installers, platform packaging, scanner and obsolete localization
remain separate retirement work. The next slice is a scoped caller trace for
remaining grouping/storage consumers; this receipt does not authorize that work.
The two parent removal/retirement milestones remain open.

Exercised: deterministic Linux-hosted Flutter VM unit/widget/source-contract tests,
including fake secure storage and owner replacement cases. Native Linux UI,
Android/device, physical keychain, live Agent/provider authentication, browser
build/E2E and packaged runtime qualification NOT_CHECKED. Android connection
choices and qualification are unchanged. No main integration, push, PR, deployment,
service changes or release. Implemented and fixture-checked is not independently
approved, platform-qualified or delivered.
