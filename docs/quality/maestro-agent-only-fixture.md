# All-feature Maestro fixture consumer retirement

Task: `t_d316ba18`; parent `CONNECTION-LINK-REMOVAL` remains in progress.
Admitted base: `968755f80ecae1c87f8f4f932828259ffa496267`.
This receipt covers offline implementation, not milestone closure or device support.

## Change and caller closure

`integration_test/hermes_features_maestro_main.dart` no longer imports or constructs
Wing Link, holds a management fingerprint/revocation state, generates pairing
payloads, or offers retired trust/pairing controls. Its legacy-input destination
still uses the production rejection screen and recovers to direct Agent options.
The empty intent source keeps fixture startup independent of native channels.
Agent channel overrides, saved Agent endpoints, visual destinations, approval,
Stop, reconnect and attachment-owner fencing remain unchanged.

The actual Android runner consumes `scripts/maestro/fixture/`, not `.maestro/`.
The independent `.maestro/android-pairing-same-device.yaml` harness is outside
this slice. The runner now dispatches `legacy_input_rejection.yaml` and
`gateway_read_only.yaml`. Obsolete computer setup, Link trust errors and device
revocation flows are removed rather than relabeled as supported Agent operations.
The Linux counterpart and nearest unit/widget tests use the same current behavior.
Retained directory-service and transport-security fixtures, client/service code,
installers, packaging and user stores are untouched.

## Execution evidence

The original manifest-pinned `pass_workspace.py` command passed before edits.
Manifest SHA-256: `b828c00d456293fd16a6a7340f645fd462e43b2cfd2f5d556cf49fd47959adfc`.
The pre-edit enrollment retirement suite passed 19 tests despite the dormant
`WingLinkClient` consumer. The new focused source contract then failed on
`core/wing_link/` (exit 1) before removal, proving the missing coverage.

Executed on Linux with Flutter 3.44.2, framework `c9a6c48423`, Dart 3.12.2.
`pubspec.lock` remained unchanged with SHA-256
`f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`.

Passing checks, repeated by `finish_task.py` before its scoped local commit:

- `dart format --output=none --set-exit-if-changed integration_test/hermes_features_maestro_main.dart integration_test/linux_maestro_flows_test.dart test/tooling/enrollment_retirement_contract_test.dart test/integration/maestro_feature_fixture_test.dart test/integration/maestro_approval_attachment_controls_test.dart test/features/enrollment/legacy_fixture_rejection_test.dart`
- `timeout 5m flutter analyze --no-pub`
- `timeout 5m flutter test --no-pub test/tooling/enrollment_retirement_contract_test.dart test/tooling/hermes_domain_authority_contract_test.dart test/features/enrollment test/integration/maestro_feature_fixture_test.dart test/integration/maestro_approval_attachment_controls_test.dart --reporter expanded` — 57 tests, including legacy rejection/direct recovery, read-only gateway, approval deny/once, Stop, reconnect without replay and deferred picker ownership.
- `python3 -m unittest test/tooling/android_maestro_features_wrapper_test.py` — six tests; stub dispatch evidence only, not Android execution.
- `timeout 20m env WING_ISOLATED_DEVICE_TEST=1 flutter build apk --debug --no-pub -t integration_test/hermes_features_maestro_main.dart` — actual all-feature APK target compiled. No installation or device access.
- `git diff --check`

The initial read-only widget assertion needed scroll animation settlement before
hit testing; after adding `ensureVisible` and `pumpAndSettle`, all focused tests
passed. No production workaround was introduced. Analysis took 6.2 seconds and
the initial APK build took 49.9 seconds; final-gate timings remain in tool output.
Usage cost and independent-review duration are unknown at implementation handoff.

## Limits and remaining milestone gaps

Implemented: fixture consumer/control retirement and direct caller closure.
Qualified: Linux-hosted deterministic unit/widget regressions and offline Android
APK compilation only. Android device behavior, native Linux counterpart runtime,
native SSH, live authentication/providers and physical secure storage are
NOT_CHECKED. Maestro CLI is absent; its check-syntax/device execution is
NOT_CHECKED. Optional Python YAML parser probes failed because PyYAML is absent;
these are not claimed as syntax passes. No dependencies were installed.

The Android build passed with existing compile SDK 36 versus plugin SDK 37 and
Kotlin migration warnings. Packaging configuration is outside this slice and was
not weakened or changed. Compilation does not qualify runtime compatibility.

Delivered: local task-ref commit only, as identified by the native review handoff
and `finish_task.py` receipt. Independent review, canonical integration and remote
publication remain pending. No parent goal/task closure, main merge or push.
Remaining milestone work includes the last retained client/service consumers and
service/installer/packaging retirement with source-bound checks, plus separate
native/device/live qualification. No new follow-up card is created by this slice.
