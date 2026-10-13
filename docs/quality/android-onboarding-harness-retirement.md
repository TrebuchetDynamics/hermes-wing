# Android onboarding harness retirement

Task: `t_bd978f36`; parent `CONNECTION-LINK-REMOVAL` remains in progress,
with `CONNECTION-LINK-RETIREMENT` still dependent on complete consumer removal.
Admitted base: `e3d0e4f6b9a797d9f5b29ae1401a861ff0d5628f`.
This is offline implementation evidence, not device qualification.

## Change and caller closure

The obsolete `.maestro/android-pairing-same-device.yaml` is deleted, not renamed
or presented as supported direct enrollment. Its broker exchange, nine-profile
pairing success and re-pair recovery cannot run against current production.
The retirement source contract rejects restoration of that active file.

The [production fixture flow](../../scripts/maestro/android_fixture_regression.yaml)
now enters from Welcome to Hermes Wing through Connect to Remote Hermes,
checks Android Back returns to welcome, and selects the existing private-network
transport for the non-secret USB-reversed loopback fixture URL. Android Local
uses a fixed on-phone endpoint and cannot select this fixture's port. No
production behavior, credential policy or transport validation changes.
The ordered source contract rejects obsolete controls and preserves URL/name
entry, explicit Add Hermes, opening the saved contact, generation, approval,
force-stop/relaunch transcript recovery, orientation, Stop and approved recovery.

Tracked caller search (`git grep -n -E 'android-pairing-same-device|android_fixture_regression'`)
found no runner or test dispatching either standalone flow. The all-feature runner
continues using `scripts/maestro/fixture/`, unchanged. The only external references
are the previous retirement receipt and the historical Android pairing plan and
physical regression receipt. They remain historical, not current support claims.
The old pairing harness is available at
[its historical revision](https://github.com/TrebuchetDynamics/hermes-wing/blob/e3d0e4f6b9a797d9f5b29ae1401a861ff0d5628f/.maestro/android-pairing-same-device.yaml).
The [previous fixture receipt](maestro-agent-only-fixture.md) correctly records
that it was outside that earlier slice; this receipt supersedes that scope gap.
The [2026-09-04 device receipt](android-physical-regression-2026-09-04.md) is not
proof the edited flow runs today. Unrelated live-device harnesses are outside scope.

## Executed checks

Original manifest-pinned admission passed before the first edit:
`pass_workspace.py` with manifest
`pass-dbb8085d9c7a2748-4e2148fe948f474582e6dc67f1707a00.json`, SHA-256
`0125478dc8790e09439890754991e64ec301a867ee19419d50e47f54c3d9c865`.
The tool history records the exact workspace/command and `worker_start_admitted`.

The new focused Android contracts failed before harness edits: obsolete file
present and removed first-run label still required (two discriminating failures).
The first test invocation lacked workspace package configuration; existing locked
dependencies were resolved using `timeout 5m flutter pub get --offline`.
`pubspec.lock` is unchanged. No dependency was added.

Passing acceptance commands, also required by the scoped `finish_task.py` gate:

- `dart format --output=none --set-exit-if-changed test/tooling/enrollment_retirement_contract_test.dart`
- `timeout 5m flutter analyze --no-pub`
- `timeout 5m flutter test --no-pub test/tooling/enrollment_retirement_contract_test.dart test/tooling/android_pairing_contract_test.dart test/features/enrollment test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/features/hermes_chat/screens/hermes_chat_screen_android_endpoint_test.dart test/integration/maestro_approval_attachment_controls_test.dart test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart --reporter expanded` — 61 tests passed on the initial check.
- `python3 -m unittest test/tooling/android_maestro_features_wrapper_test.py` — six wrapper tests; stub dispatch only.
- `timeout 20m env WING_ISOLATED_DEVICE_TEST=1 flutter build apk --debug --no-pub -t lib/main.dart` — actual production target compiled; no installation or device access.
- `git diff --check`

Linux host, Flutter 3.44.2 (`c9a6c48423`), Dart 3.12.2. Initial focused suite:
18 seconds; analysis: 6.3 seconds; Gradle compilation: 42.1 seconds. Final-gate
results/timings and exact task-ref commit are recorded in the native handoff.
Review duration and usage cost are unknown at implementation handoff.

## Limits and remaining work

Implemented: scoped active harness retirement and current direct enrollment entry.
Qualified: Linux-hosted source/unit/widget tests and offline Android compilation.
Maestro is unavailable: Maestro YAML syntax validation and device execution are
NOT_CHECKED. Source assertions do not validate Maestro parsing or native semantics.
Physical Android/Termux, native SSH, live authentication/provider behavior and
secure storage on hardware are NOT_CHECKED and were not accessed.

The APK build retains existing SDK 36 versus plugin SDK 37 and Kotlin migration
warnings. Packaging changes are excluded; a passing debug build does not qualify
runtime compatibility. Production, localization, retained service/client tests,
installers, packaging and user stores are unchanged. Build outputs are discarded.

Delivered: local task-ref commit only, identified by `finish_task.py` and the native
review handoff. Independent review, canonical integration and publication remain
pending. No parent/goal closure, merge or push. Remaining milestone work includes
retained client/service and installer/packaging retirement plus separately
authorized native/device/live qualification; this card creates no follow-up task.
