# Android approval and attachment fixture slice

Card: `t_be855c75`. Goal: PARITY, partial. Android outcome: **NOT_CHECKED**.
The [source-bound receipt](android-approval-attachment-fixture-receipt.json)
separates executed Flutter widget checks from failed Android driver startup.

## Delivered

- The feature wrapper accepts explicit allowlisted flow paths; no arguments still
  selects its existing full suite. Unknown paths fail before tools run. An explicit
  target must return successful ADB `get-state` with `device` before syntax checks,
  build, install or flow execution. This preflight is not proof of disposable
  identity: the existing runbook's target and `.qa` APK review remain required.
- Approval YAML matches the current profile-addressed composer hint. A production-
  screen mobile-sized widget regression exposed another stale assumption: the
  fixture's disconnect/reconnect controls retain its selected contact, rather than
  navigating to Profiles. The flow now checks recovered transcript/session instead
  of imposing unrelated contact navigation. No production reconnect logic changed.
- Fixture receipts expose exact Stop calls and active session. The attachment race
  additionally requires a pending pick, an actual switch to `sess_2`, completion of
  that pick, no staged attachment in either owner, and a successful subsequent pick.
- `FeatureFixture.buildApp()` lets tests exercise the same fixture presentation,
  controls, production screens and provider overrides used by the Android target.
  The seam and counters are integration-only, not compiled into `lib/main.dart`.

Bounded invocation after target/package review:

```bash
WING_QA_DEVICE='DISPOSABLE_SERIAL' MAESTRO_BIN="$HOME/.maestro/bin/maestro" \
  bash scripts/run_android_maestro_features.sh \
  scripts/maestro/fixture/approvals_recovery.yaml \
  scripts/maestro/fixture/attachment_picker_race.yaml
```

## Executed evidence

Linux-hosted Flutter widget tests, viewport 390 × 844 (not an Android device):

- Deny through Review, Stop through the production composer control, then Approve
  once: exactly 3 submitted turns, 2 approval decisions, 1 Stop. Disconnect/reconnect
  leaves those counters unchanged, retains `sess_1`, and shows the completed reply.
- Deferred picker through production attachment control: pending true, switch to
  `sess_2`, one completion, pending false, no attachment for either `sess_2` or
  `sess_1`, zero submitted turns. A subsequent text pick stages `fixture-note.txt`;
  picker calls total 2. This does not qualify the native Android chooser.

Commands/results:

- `flutter test --concurrency=1 test/integration/maestro_approval_attachment_controls_test.dart test/integration/maestro_feature_fixture_test.dart`: exit 0, 7 tests.
- `python -m unittest test/tooling/android_maestro_features_wrapper_test.py -v`:
  exit 0, 4 tests; tools are mocked, not Android execution. The negative test first
  demonstrated that an ADB command returning `device` but failing could pass the
  preflight; separate assignment now preserves that command's exit status.
- `dart format --output=none --set-exit-if-changed integration_test/hermes_features_maestro_main.dart integration_test/support/maestro/interaction_fixture.dart test/integration/maestro_approval_attachment_controls_test.dart`: exit 0.
- `flutter analyze`: exit 0, no issues.
- `bash -n scripts/run_android_maestro_features.sh`: exit 0.
- `maestro check-syntax scripts/maestro/fixture/approvals_recovery.yaml` and
  `maestro check-syntax scripts/maestro/fixture/attachment_picker_race.yaml`: each exit 0.
- `git diff --check`: exit 0.

The receipt records HEAD plus content hashes of this card's sources and an aggregate
fingerprint of current Flutter sources, fixture dependencies and manifests. Tests
ran in the preserved dirty working tree, not an isolated checkout of the eventual
agent branch. The ignored full manifest/logs are under `.task-evidence/t_be855c75/`.
Pre-repair driver attempts have their own flow hashes; they are not passes of the
repaired flows. This card created no APK or large build copies to retain/clean.

## Android attempts and coverage limits

Only the previously enrolled disposable Waydroid target was selected. Current
`waydroid status` still reports that target and running container/session, but
`adb connect` returns `No route to host`, `ip neigh` reports FAILED, and
`adb devices -l` is empty. Unprivileged Waydroid inspection required root and was
not escalated. No alternate target, auth bypass, enrollment, service restart,
provider invocation, install or app reset occurred; the release lane's Gradle file
and paired production app were untouched.

Maestro 2.4.0 was actually invoked separately for both named flows with explicit
`--device`, `--no-reinstall-driver`, owned cache/output and `timeout 45s`. Each
exited 1 before launch: the requested device was not connected. The repaired
wrapper also exited 1 at ADB preflight. Current ADB authentication, SDK/build
fingerprint, APK identity/digest, installation and every Android assertion/counter
are therefore NOT_CHECKED, not zero and not a fixture-derived pass.

| Matrix ID | Delivered executable fixture subset | Android status |
| --- | --- | --- |
| HD-APPROVAL | Review/Deny and Approve once dispatch; exact two decisions | NOT_CHECKED |
| HD-STOP | Exact one owned Stop, approval removed, next send usable | NOT_CHECKED |
| HD-RESUME | Fixture offline/online transcript/session retention and unchanged send/decision counters | NOT_CHECKED |
| HD-ATTACH | Deferred picker owner-race rejection and next text pick | NOT_CHECKED |

The YAML's earlier-history control/tap/assertions remain intact, but the new widget
regression does not exercise that tail: history pagination remains NOT_CHECKED.
No live transport, authoritative Agent Stop/recovery, relaunch, physical hardware,
provider generation, native file dialog, or whole-matrix parity is claimed. Upstream
approval identity and cancellation contracts were inspected read-only in Agent
`api_server.py`/nearest approval tests and Desktop `chat-approval.ts`; they are not
runtime receipts. No backend contracts or authority boundaries changed.

## Remaining

`PARITY-MAESTRO-ANDROID-DEVICE` retains both real-device flow requirements and the
other mapped Android feature journeys. PARITY remains partial. Target recovery can
be retried through normal authenticated ADB; privileged service/network repair was
not performed. No new owner decision is required by this fixture repair, and no
new trust or system action is assumed by default.
