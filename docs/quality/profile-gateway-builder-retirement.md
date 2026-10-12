# Profiles and Connections builder retirement

Task: `t_746f3e04`; bounded slice of CONNECTION-LINK-REMOVAL / CONNECTION-PATHS.
Base: `96630a7651df6ae1ecf0d962d4395ac8100e193c`.
Status: implemented and locally checked; independent native review pending.
The parent removal task remains in progress. This is not full Wing Link removal.

## Decision and changed artifacts

Delete the dormant builders rather than replace them. Profiles already used the
Agent channel; its Link provider was never read. Connections retained a constructor
argument only for test probes that could not observe production behavior.

Owned files:

- `lib/features/profiles/screens/profiles_screen.dart`: remove Link import,
  `WingLinkClientBuilder`, `wingLinkClientBuilderProvider`, and stale refresh comment.
- `lib/features/gateway/screens/gateway_screen.dart`: remove Link import,
  `GatewayWingLinkClientBuilder`, constructor parameter/field, and now-unused endpoint
  config import. Health ownership and authorization logic are unchanged.
- `test/features/profiles/profiles_screen_test.dart`: remove unused builder
  overrides/counters; preserve direct Agent HTTP request, denial, cancel, exact
  profile/model/session identity, revision and legacy-data retention assertions.
- `test/features/profiles/profiles_search_ownership_test.dart`: use existing Agent
  and directory providers without a Link builder; retain all owner/grant-loss tests.
- `test/features/gateway/gateway_screen_test.dart`: remove unused Link fake and
  probes; retain public refresh, cancellation, reconnect and raw-store retention
  outcomes. Saved-config replacement now asserts renamed label, retained metadata,
  no reconnect/disconnect and absent trust UI.
- `test/tooling/enrollment_retirement_contract_test.dart`: static negative guard
  on both screen files for Link imports, client types and builder identifiers.
- `integration_test/hermes_features_maestro_main.dart`: compiler-closure expansion
  only, route uses `const GatewayScreen()` instead of the removed constructor
  parameter. Existing directory/trust fixture assets are outside this slice.
- This receipt.

All builder callers were traced in `lib`, `test`, and `integration_test`.
Final `git grep -n -E 'WingLinkClientBuilder|wingLinkClientBuilder' -- lib test
integration_test playwright scripts` finds only the source-contract forbidden string.
No replacement provider, compatibility adapter, dependency or migration was added.

## Admission and red/green evidence

Before the first edit, executed successfully:

```text
python3 /home/xel/git/gormes/hermes-toolset/skills/autowork/scripts/pass_workspace.py --manifest /home/xel/.hermes/profiles/wing/autowork/pass-320a9d964e396f49-d89f9628618e498eb6b3f148a011bc30.json --manifest-sha256 0dce0f204f2216d6ec701b7838cbc2e0c9ee0581c97e00ce2780561ab6297a15 --workspace /home/xel/.hermes/profiles/wing/cache/scratch/autowork-passes/320a9d964e396f49-d89f9628618e498eb6b3f148a011bc30
```

Result: `worker_start_admitted`, exit 0. Original run tool history is the admission
record; this receipt is not a substitute for its ordering evidence.

RED: `flutter test --no-pub test/tooling/enrollment_retirement_contract_test.dart
--plain-name 'Profiles and Connections screens have no legacy builder dependency'`
exited 1 on the existing Profiles `core/wing_link/` import.
GREEN: `flutter test --no-pub test/tooling/enrollment_retirement_contract_test.dart`
passed all four tests after screen deletion.

## Acceptance evidence

Linux-host deterministic checks, not live Agent or native/device qualification:

- `flutter pub get --offline`: pass. Before/after SHA-256 unchanged:
  `pubspec.yaml` = `f0989f9a42f11321a0737dccfa073d506a7f4f79e543f5a0cddde08a53ce35d2`;
  `pubspec.lock` = `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`.
- `dart format` on the seven changed Dart files: pass.
- `flutter analyze --no-pub`: pass, no issues, 2.1 seconds on corrected source.
  Initial analysis exposed the Maestro constructor caller and unused import;
  both were corrected within scope.
- Literal requested test command including `test/features/persona`: exit 1,
  262 tests passed; the only failure was the nonexistent directory. Card comment
  records correction: Persona route tests live under `test/features/soul`;
  profile Persona ownership/fidelity tests remain under `test/features/profiles`.
- Corrected command, pass, 297 tests, runner duration 55 seconds:

```text
flutter test --no-pub --concurrency=1 test/features/gateway test/features/profiles test/features/soul test/shared/widgets/app_shell_profile_footer_test.dart test/tooling/enrollment_retirement_contract_test.dart
```

- `git diff --check`: pass before receipt; repeated by finish gate.

Criterion mapping: source-contract guard proves absence of direct screen Link
imports/builders; analysis proves caller compilation closure. Gateway health
ownership/loader tests and Profiles mutation/search/Persona ownership suites
retain exact-owner and same-frame grant-loss fencing. Screen HTTP tests retain
Agent-only requests, denial with no fallback, no automatic mutation replay,
explicit model retry and exact profile/session selection. Gateway cancellation
and retention tests preserve saved Agent access and legacy fields without deletion.
No relevant behavioral test or security/ownership assertion was removed; only
uninvoked builder counters were replaced by source and public-outcome checks.

The immutable task commit and branch are recorded in the native review handoff
from `finish_task.py`; its repeated checks bind these artifacts to that revision.
Implementation is local only: no integration, push, publication or deployment.
Review time and inference cost are unknown, not estimated.

## Exclusions and remaining gaps

[Product removal decision](../adr/product.md#complete-removal-including-legacy)
and [threat model](../security/threat-model.md) remain the boundary.
No profile editor approval logic, directory browser, core transport, saved-contact
models/stores, localization, upstream code, ledgers or service/packaging were edited.
Raw user data was neither accessed nor deleted. Android connection ordering is unchanged.

Profile editor approval types, directory adapters, saved management metadata,
credential APIs, service and packaging closure remain future removal slices.
Transitive editor/directory Link types still exist; this receipt claims only direct
screen builder retirement, not a Link-free application or artifact.
Maestro fixture runtime, packaged execution, web E2E, Linux GTK, Android,
live authentication/provider inference, installed services and rollback are
NOT_CHECKED. No live operations or hardware tests were authorized or performed.
