# Agent-only consumer regression closure

Status: implemented local candidate for `t_7fb12f77`; independent native review,
canonical integration and publication remain pending. This is a test-only slice of
CONNECTION-LINK-REMOVAL / CONNECTION-PATHS, not completion of either milestone.

## Source and scope

Admitted base: `9591083d881b5f9acaf2e60589592a33854583a2`.
The original `pass_workspace.py` invocation used manifest SHA-256
`2a582548da67b642f612a904be316d317f8a7361873c2194f4ebf3a153852681`
and returned `worker_start_admitted` before the first edit. Original tool history,
not this receipt, is the authority for admission ordering. The finish-task receipt
and native review handoff identify the exact commit/ref for this candidate.

Owned Dart source fingerprint (sorted relative filenames, NUL, then file bytes;
SHA-256): `829c5424fe49c4c92482ecca9b57e499fd2e6be8b39d4529fe311a0094a4e593`.
This excludes this evidence document. No production, service, packaging, stored
user data, canonical backlog or goal-ledger changes were made.

Decision: reuse the existing authority test and retained core suite. Move the
catalog compatibility scenario intact rather than delete security coverage or add
another test harness. `enrollment_retirement_contract_test.dart` was inspected
and exercised unchanged; its saved-endpoint, enrollment, fixture and separate
service guards already cover their named boundaries.

## Traced boundary

All 209 Dart files under `lib` were scanned, including entrypoints, generated
localization, app/router/shared code, features, Agent transport and platform
conditional exports. All 886 import/export/part directives were read by a bounded
source scan; 866 are outside the retained core. No directive outside
`lib/core/wing_link/` refers to that subtree. The complete-client guard checks 202
Dart files, excluding only the seven retained legacy core files. This is source
inspection, not a runtime, AST dependency graph or packaging qualification.

- `lib/features/profiles/screens/profiles_screen.dart` imports Agent channel and
  capability contracts and supplies that channel to the profile editor. Exact
  Agent methods, paths and scopes gate profile controls; missing authority stays
  unavailable.
- `lib/features/profiles/widgets/profile_editor_sheet.dart` uses Agent create,
  rename and delete operations. Its injected catalog loader takes explicit profile
  identity and returns `HermesModelOptions`; retry/manual entry and keyboard
  behavior remain unchanged.
- `test/features/hermes_chat/support/fake_hermes_channel.dart` implements the
  existing Agent channel contract. `HermesModelOptions` remains the bounded Agent
  inventory model; no new fake, config, export or runtime seam was needed.
- `lib/core/wing_link/wing_link_client.dart:getProfileModelOptions` remains legacy
  code: profile validation precedes metadata/transport and exact
  `profiles.model-options.read` capability precedes the profile-bound request.
  Its only production definition is inside the retained core; no outside client
  caller was found.
- `lib/core/hermes/setup/secure_hermes_endpoint_store.dart` retains inert historical
  fields under the same saved Agent ID/origin and secure-only secret placement,
  plus scoped deletion cleanup. These are data-preservation safeguards, not live
  management consumers. They were not excluded as a whole file or removed.

The current [product retirement decision](../adr/product.md#complete-removal-including-legacy)
and [retained compatibility boundary](../adr/runtime-and-delivery.md#management-and-compatibility)
remain unchanged. Retained Go/service source assertions and directory service
checks are still present; this slice does not delete or qualify the service.

## Acceptance evidence

1. Catalog security scenario relocated from Profiles to
   `test/core/wing_link/wing_link_client_test.dart`. A direct comparison with the
   admitted base confirmed the test block is byte-for-byte identical. It still
   checks the control authorization header, exact capability, explicit default
   profile route, capability denial without catalog traffic and invalid profile
   rejection. The Profiles file no longer imports or constructs Link.
2. `test/tooling/hermes_domain_authority_contract_test.dart` now scans every Dart
   client source outside the exact retained core. It rejects Link paths, named
   types/construction and client builders, including import, export and
   conditional-import cases. A sibling `core/wing_link_extra` negative control
   prevents widening the exclusion. A positive control preserves legacy storage
   key text. This conservative text guard is not a Dart semantic parser.
3. Discriminating RED: with the collector temporarily returning an empty list,
   the negative-control test failed on `app/caller.dart` (expected its path,
   actual `[]`). GREEN: the implemented collector passed the complete client and
   all negative controls, with the retained compatibility assertions unchanged.
4. Original focused Linux-host Flutter regression run: 495 tests passed in 1 minute
   42 seconds. Includes Profiles unavailable/denied/owner fencing and catalog
   retry/keyboard tests; gateway reconnect/exact-session restoration; old handoff
   rejection; endpoint security, secure storage and raw historical record
   preservation; authority/retirement contracts; retained Link client and TLS
   transport tests.
5. `flutter analyze --no-pub`: no issues after fixing one unnecessary cascade in
   the new test. `dart format` applied to changed Dart files. `git diff --check`
   passed. The commit gate reruns these acceptance checks before committing.

Exact acceptance commands (run from the task workspace):

```sh
dart format --output=none --set-exit-if-changed test/features/profiles/profile_catalog_test.dart test/core/wing_link/wing_link_client_test.dart test/tooling/hermes_domain_authority_contract_test.dart
timeout 5m flutter analyze --no-pub
timeout 10m flutter test --no-pub --concurrency=1 test/features/profiles test/features/gateway test/features/enrollment test/features/hermes_chat/gateways test/core/hermes/setup test/tooling/hermes_domain_authority_contract_test.dart test/tooling/enrollment_retirement_contract_test.dart test/core/wing_link
git diff --check
```

RED/GREEN selector:

```sh
timeout 5m flutter test --no-pub test/tooling/hermes_domain_authority_contract_test.dart --plain-name 'client guard rejects Link consumers outside the exact retained core'
```

Environment: Flutter 3.44.2 / Dart 3.12.2 on a Linux host, deterministic
unit/widget/source tests and local test transport. The first `--no-pub` attempt
could not find package configuration; `flutter pub get --offline` populated the
isolated workspace using existing dependencies without changing tracked manifests
or the lockfile. No dependency was added. An initial analyzer run found the one
cascade lint; it was corrected before the passing run. Cost and independent review
duration are unknown.

## Independent review rework

Review of `b1b390a3dc5a0b74c528745d967e05773a6fa3b5` requested a Windows-path
correction. Before rework, the task ref, admitted-base ancestry, four-file
cumulative scope and owned file bytes matched that reviewed commit. Original
admission remains unchanged; no post-edit startup-guard replay was used.

The retained-core predicate now normalizes backslashes in both the enumerated
file path and root before comparing the exact subtree. A small private predicate
lets the existing collector and deterministic path regression exercise identical
logic without a new dependency or production seam. The regression covers relative
and Windows absolute roots, backslash and mixed separators, and rejection of
`core/wing_link_extra` for each root. No consumer, fixture, config or export outside
this existing test needs to change; retained catalog assertions are unchanged.

RED: the new regression with the original predicate failed (`Expected: true`,
`Actual: false`, exit 1). GREEN: all five authority-contract tests passed after
normalization. Commands:

```sh
timeout 5m flutter test --no-pub --reporter expanded test/tooling/hermes_domain_authority_contract_test.dart --plain-name 'retained core exclusion handles Windows paths without excluding siblings'
dart format test/tooling/hermes_domain_authority_contract_test.dart
timeout 5m flutter test --no-pub --reporter expanded test/tooling/hermes_domain_authority_contract_test.dart
```

The mandatory finish gate reruns the exact acceptance commands above against this
source before committing. `.dart_tool/t_7fb12f77-rework-finish.log` and the native
review handoff bind its check outcomes to the new exact task commit. Windows-style
paths were exercised on Linux, not on a Windows runtime. No production, service,
packaging, stored-data or canonical-ledger edits were needed.

## Remaining milestone gaps

NOT_CHECKED: live Agent/provider behavior, native app/device journeys, Android,
browser E2E, installed service lifecycle, Go service qualification, installer,
artifact/image builds, signing and distribution. No real management network
operation or personal service change was performed. Local TLS transport tests do
not qualify an installed service.

Independent native review must bind the finish-task commit/ref and original
admission history. Only the coordinator may integrate/publish and reconcile the
parent after its remaining acceptance gates. Parent remains in progress and the
service retirement task does not become eligible solely from this source guard.
The next milestone slice remains the existing service/delivery retirement work,
after the coordinator verifies full consumer closure and required review.
