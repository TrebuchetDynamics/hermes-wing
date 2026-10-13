# Native fixture consumer retirement closure

Task: `t_7a812cf7`; milestone `CONNECTION-PATHS`, parent
`CONNECTION-LINK-REMOVAL`. This is a bounded offline consumer guard, not service
retirement or native/device qualification. The parent remains in progress and
`CONNECTION-LINK-RETIREMENT` stays gated by the
[accepted removal decision](../adr/product.md#complete-removal-including-legacy).

## Candidate and admission

Base: `fce44664e92f0740570f8ceb2072ad8976ba25d0`.
The original pre-edit `pass_workspace.py` invocation used manifest
`pass-0cf0e82ed49fb29e-986f4cca6ce044fa9621d4fd7397c9fb.json`, pinned SHA-256
`39b6949e15099a3def3830aacb3ba6550b865a3f0fbdecc8cbcee932cd6929e8`, and the
matching isolated workspace. It returned `worker_start_admitted` before the first
edit. The original native task tool history, not this document, proves ordering.
The finish gate returned `validation_failed`; no task ref or finish commit was
created. This candidate is retained uncommitted, not ready for review admission.
The tested contract SHA-256 is
`219be2e2b092cc35718cb37114c02cab263cfbadc1f190f3c7a6c0b92d6ae795`.

Owned files are this receipt and
[`enrollment_retirement_contract_test.dart`](../../test/tooling/enrollment_retirement_contract_test.dart).
No production, service, storage, packaging, localization, dependency, upstream or
canonical ledger inputs changed.

## Boundary and dependency trace

Decision: reuse the existing conservative management source guard for every
`integration_test/**/*.dart` source. Its only integration exclusion is the exact
root-relative `linux_live_directory_service_test.dart`. Keep that standalone
service safety test until the service itself is retired. The existing production
`lib/core/wing_link/` exclusion does not apply within integration fixtures.

The helper and all callers are local to the existing contract test. Sentinel
checks reject management imports, exports, client construction and builder
references in lookalike filenames, nested service filenames, a copied
`core/wing_link/` subtree, and both Android/Linux raw-storage fixtures. Inert
`wingLinkToken` records remain accepted; no raw-storage file is exempt. Path
checks cover POSIX, Windows and mixed root/file separator forms. Existing tests
continue to cover conditional directives and production storage consumers.

A read-only local directive trace inspected 65 integration Dart roots and 335
transitive local Dart sources, including imports into `test/` and `lib/`, with no
missing local targets. Only the standalone service fixture directly imports the
retained management client; it has no incoming local directive edges. Its
closure includes the retained client, HTTP/transport implementations and device/
directory models. Product fixtures reach Agent APIs and shared fixture/test
support instead. This bounded source trace is not packaged runtime evidence.

The [standalone service test](https://github.com/TrebuchetDynamics/hermes-wing/blob/918e7c318bab1d91f348570e2309598d729ecb9c/integration_test/linux_live_directory_service_test.dart)
still checks grant/list, folder-only results, revocation and HTTP 410 for old
handles. It was inspected, not executed. The
[Android](../../integration_test/android_secure_storage_regression_test.dart) and
[Linux](../../integration_test/linux_secure_storage_integration_test.dart)
raw-storage fixtures keep historical fields and credential-isolation checks.
Nothing reads, migrates or deletes real user records in this change.

## Executed checks and frozen finish gate

Environment: Linux x64; Flutter 3.44.2 (framework `c9a6c48423`), Dart 3.12.2,
Node v26.7.0, Go 1.26.1. Node 22 was not exercised; no Node/Go build is claimed.
`flutter pub get --offline --enforce-lockfile` passed without lockfile changes.

RED: `timeout 5m flutter test --no-pub test/tooling/enrollment_retirement_contract_test.dart --plain-name native --reporter expanded`
failed as intended: the old guard rejected the retained standalone service test
in the real tree and isolated sentinel tree. GREEN after the shared helper fix:
`timeout 15m flutter test --no-pub --concurrency=1 test/tooling/enrollment_retirement_contract_test.dart test/core/hermes/setup --reporter expanded`
passed 73 tests. `timeout 5m flutter analyze --no-pub` passed with no issues
(6.3 seconds reported by analyzer). Scoped format and `git diff --check` passed.

The mandatory `finish_task.py` gate froze the two owned files and ran these
explicit acceptance argv; failure prevented `agent/wing/t_7a812cf7` creation:

- `dart format --output=none --set-exit-if-changed test/tooling/enrollment_retirement_contract_test.dart`
- `timeout 5m flutter analyze --no-pub`
- `timeout 15m flutter test --no-pub --concurrency=1 test/tooling/enrollment_retirement_contract_test.dart test/core/hermes/setup`
- `timeout 35m flutter test --no-pub --concurrency=1`
- The gate stopped at the full-suite failure. `git diff --check`, unchanged
  manifest/lock checks and local receipt link checks passed separately.

Cumulative result: `12:28 +3811 ~8 -2`, exit 1 (3811 passed, eight skipped,
two failed). The complete tracked finish invocation took 759.01 seconds,
including format, analysis (1.8 seconds) and the 73 focused tests. The initial
foreground invocation was interrupted by the terminal tool's 420-second ceiling;
its process was gone before the sole tracked retry began. No complete result was
inferred from that interrupted attempt. Final log and duration receipt remain in
the isolated workspace's `.dart_tool/t_7a812cf7-finish-final.log` and
`.dart_tool/t_7a812cf7-duration.json`.

Both failing tests and their source dependencies are unchanged from the admitted
base, outside the two owned files:

1. `test/tooling/playwright_profile_language_contract_test.dart:14` expects
   `playwright/tests/regression/browser-surfaces.spec.mjs` to contain
   `Add gateway or profile`. The current direct connection fixture instead uses
   `Connect to Remote Hermes` at line 27. This is the first failing assertion.
2. `test/tooling/readme_assets_contract_test.dart:68` expects `README.md` to contain
   `Try the web alpha`; current `README.md:17` uses `Preview the connection screen`.

Required repair: separately admit reconciliation of those stale source-contract
expectations with current direct-Agent/browser and README behavior, preserving
the still-relevant semantics, security and asset assertions. Inspect subsequent
expectations as well; fixing only the first string is not proof that either whole
test passes. Do not restore retired wording, delete tests, or expand this card's
write scope. Then rerun the cumulative frozen gate, obtain a scoped finish commit
and request independent native review. No gate bypass or acceptance waiver was
used. This final receipt-only update does not change the tested contract or justify
replaying the known failing suite without the separately admitted repairs.

## Qualification and remaining work

Implemented: fixture-wide anti-restoration scanning with the exact retained
service exception and falsification checks. Qualified here: deterministic
Flutter focused unit/widget/source-contract checks only; cumulative acceptance
failed as recorded above. Delivered: no finish commit, canonical integration or
remote publication by this worker. Independent same-card native review remains
required after the blocked finish gate passes.

Do not replay Chromium: the approved predecessor's compiled browser evidence
covers unchanged production/build/dependency inputs; this run adds no browser
execution claim. Android/Linux integration fixtures, physical secure storage,
Windows runtime, live provider, services, packaging, image builds and deployment
are NOT_CHECKED. Conservative text scanning is not an analyzer and does not prove
arbitrary obfuscated dependencies absent.

Next slice: the coordinator reconciles cumulative regression evidence and
outstanding native/device qualification before service/package deletion. Keep
standalone service safety and inert user records intact until their separately
admitted retirement work; do not close the parent milestone from this receipt.

Retirement link maintenance: removed-source links now point at the last tracked
pre-retirement baseline `918e7c318bab1d91f348570e2309598d729ecb9c`. These are
source lookup pointers, not replacements for the original dirty-source manifests
or fresh qualification of the historical results above.
