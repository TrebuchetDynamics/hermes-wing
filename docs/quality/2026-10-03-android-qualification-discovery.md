# Android qualification discovery — 2026-10-03

## Outcome and evidence boundary

**HOLD for Android process-death continuity and M5 native qualification.** A fresh,
owned Android 14/API 34 x86_64 emulator booted and executed 17 existing deterministic
feature tests successfully. Two existing Maestro fixture flows failed before their
intended output/accessibility exits. No live Agent, personal app, connected physical
device, real credentials or upstream runtime was used. This is executor evidence,
not independent card acceptance, physical-device support or release qualification.

Only this receipt is a source/document edit. Existing dirty changes were preserved.
Android build output and disposable AVD/Maestro state were generated locally; no
source fixes, dependency upgrades, staging or commits were performed.

## Discovery and target

Initial commands from the Wing root, in order:

```sh
adb devices -l
flutter devices
 git status --short --branch
flutter emulators
flutter doctor -v
/usr/lib/android-sdk/emulator/emulator -accel-check
sdkmanager --list_installed
```

All returned exit 0. `adb` initially had no devices and started its host daemon.
Flutter initially listed Linux only. Four pre-existing AVDs were listed:
`arenaton-maestro-test`, `cadencia-maestro-test`, `luma-core-feel`, `visorbox-avd`.
Their names do not establish disposal permission; none was launched or altered.

Tools observed: Flutter 3.44.2 / Dart 3.12.2; Android SDK build tools 36.0.0;
emulator 36.3.10; Java 21.0.12.1; installed Google APIs API 34 x86_64 image;
KVM usable. Flutter doctor warned about the user-branch/unknown Flutter origin and
missing Chrome; Android toolchain passed. SDK tools emitted XML-version/package
metadata warnings, but listed the installed system image. Maestro was absent from
PATH, but the existing `/home/xel/.maestro/bin/maestro` installation was available.

A new `wing-qualification-disposable` AVD was created using the installed image:

```sh
# S is an owned directory under this profile's TMPDIR, not a personal AVD root.
S=/home/xel/.hermes/profiles/wing/cache/scratch/wing-android-qualification-20261003
ANDROID_AVD_HOME="$S/avd" /usr/lib/android-sdk/cmdline-tools/13.0/bin/avdmanager \
  create avd --name wing-qualification-disposable \
  --package 'system-images;android-34;google_apis;x86_64' --path "$S/target.avd"
# Answered only the hardware-profile prompt with "no"; exit 0.
ANDROID_AVD_HOME=/home/xel/.hermes/profiles/wing/cache/scratch/wing-android-qualification-20261003/avd \
  /usr/lib/android-sdk/emulator/emulator -avd wing-qualification-disposable \
  -port 5580 -no-window -no-audio -no-snapshot -gpu swiftshader_indirect -no-boot-anim
```

The first launch using `ANDROID_AVD_HOME="$TMPDIR/.../avd"` exited 1 with
`Unknown AVD name`; its boot probe timed out. Retrying the same newly created AVD
with the absolute owned AVD-home path succeeded. An explicit bounded boot probe
read `sys.boot_completed=1`. Readback from **emulator-5580** established Android
14, API 34, `sdk_gphone64_x86_64`. The isolated QA package was subsequently read
back as `com.trebuchetdynamics.hermes.wing.qa`, not the personal product package.
TalkBack packages existed, but `enabled_accessibility_services` was `null`.
TalkBack operation was not exercised.

## Executed checks against the current dirty Wing tree

Runs occurred locally on 2026-10-03, starting around 18:49 UTC−06:00. Sibling workers
were active; this is not an immutable clean-commit receipt or a full-suite gate.
No source changes were made by this worker. The following results are distinct.

### Android native-engine deterministic tests: PASS, 17 tests

```sh
WING_ISOLATED_DEVICE_TEST=1 flutter test integration_test/android_feature_regression_test.dart \
  -d emulator-5580 --no-pub \
  --name 'hermes_chat_message_actions_a11y_test|hermes_transcript_viewport_test|hermes_chat_screen_auth_recovery_test' \
  --reporter expanded
```

Exit 0, `All tests passed!`: five transcript anchor/owner restoration tests, one
per-message long-press semantics test and eleven typed auth/reconnect/error recovery
tests. Existing Android adapter imports the shared feature inventory with host
checks disabled. It uses deterministic channel/storage/service seams: native
Flutter execution is real, but secure storage, actual revocation, server runs,
TalkBack, native keyboard/IME and process death are not proven by these tests.

Flutter built and installed the QA APK. Build warned that `flutter_secure_storage`
requires compile SDK 37 while Wing uses 36, and about future built-in Kotlin
migration. Compilation nevertheless succeeded. Flutter cleanup tried to uninstall
the **non-QA** package and printed `DELETE_FAILED_INTERNAL_ERROR`; the suite still
exited 0. No personal app existed on this freshly created emulator. Preserve the
QA isolation environment and review the runner's package cleanup before reusing
this command on anything other than an owned disposable target.

### Existing Maestro fixture output/accessibility: FAIL, 2 flows

```sh
WING_ISOLATED_DEVICE_TEST=1 flutter build apk --debug --no-pub \
  -t integration_test/hermes_features_maestro_main.dart
adb -s emulator-5580 install -r build/app/outputs/flutter-apk/app-debug.apk
# Each invocation used this isolated cache, not Maestro's shared log cache:
# XDG_CACHE_HOME=/home/xel/.hermes/profiles/wing/cache/scratch/wing-android-qualification-20261003/maestro-cache
/home/xel/.maestro/bin/maestro check-syntax scripts/maestro/fixture/transcript_export.yaml
/home/xel/.maestro/bin/maestro check-syntax scripts/maestro/fixture/local_setup_accessibility.yaml
/home/xel/.maestro/bin/maestro --device emulator-5580 test \
  --test-output-dir /home/xel/.hermes/profiles/wing/cache/scratch/wing-android-qualification-20261003/maestro-output \
  scripts/maestro/fixture/transcript_export.yaml \
  scripts/maestro/fixture/local_setup_accessibility.yaml
```

Build/install and both syntax checks passed. Combined Maestro execution exited 1:

- `transcript_export` failed after 28 seconds: `Element not found: Text matching
  regex: (?s).*Message Hermes.*`. Its screenshot shows the production Chat fixture
  with a host-specific `Message Fixt...` placeholder. The static old selector no
  longer matches. Neither text nor Markdown clipboard receipt was reached.
- `local_setup_accessibility` failed after 56 seconds: `Element not found: Text
  matching regex: Fixture controls`. Its screenshot shows Android's **Sharing
  text** sheet covering the setup fixture. The preceding `Copy setup command`
  action now leaves a native share sheet; the existing flow does not dismiss it
  before returning to fixture controls. This is not evidence of TalkBack success,
  keyboard success, completed large-text coverage or a runtime crash.

Failure screenshots and command JSON are confined to the owned scratch directory
`maestro-output/2026-10-03_185633/`; they contain only synthetic fixture UI. No
screenshots were added to the repository. No selectors or app code were repaired.

### Linux-hosted detached-run regressions: PASS, 22 tests

```sh
flutter test --no-pub test/core/hermes/channel/hermes_api_channel_test.dart \
  --name 'process recreation|detached|terminal status releases|reattach' \
  --concurrency=1 --reporter expanded
```

Exit 0, 22 tests passed. Covers deterministic channel recreation, non-default
session reopening, duplicate guards, exact tuple terminal release, reattachment
status/history recovery, keepalive/silence, durable-save ordering, malformed/load
failure and conservative transient recovery. This is not Android OS process-death
or live running→completed evidence.

### Linux-hosted store/output regressions: PASS, 36 tests

```sh
flutter test --no-pub test/core/hermes/setup/secure_hermes_detached_run_store_test.dart \
  test/core/hermes/channel/hermes_detached_run_store_test.dart \
  test/features/hermes_chat/export \
  test/features/hermes_chat/screens/hermes_chat_transcript_export_test.dart \
  --concurrency=1 --reporter expanded
```

Exit 0, 36 tests passed: opaque lease validation/bounds, fail-closed malformed
storage; immutable Unicode UTF-8 export, byte limits, Linux save seam cancellation,
owner changes and errors; all loaded turns/redaction, late-owner suppression,
overlap/cancel/disposal/failure cases, unsupported native gating and 390px/200%
semantic keyboard operation. Mocks/seams on Linux do not qualify Android save,
share, keystore, clipboard or accessibility services.

## Routes inspected and exact missing prerequisites

Read AGENTS, CONTEXT, CONTRIBUTING, the ADR index and living client/runtime/security
ADRs; the study follow-through plan; restoration, export and platform-smoke
runbooks; nearest shared Android adapter/tests and Maestro scripts.

1. **Process-death route exists, but is not safe in this task:**
   `scripts/maestro/chat_process_recovery_qa.yaml` targets the production package,
   opens a new server session and sends a 2,000-word generation prompt before
   stopping/relaunching Wing. It needs an explicitly authorized, already paired
   disposable unmodified Agent/provider target and exact profile/gateway selection.
   None was authorized here; running it would mutate Agent state and spend inference.
   The broad `scripts/run_android_maestro_regression.sh` additionally mutates and
   deletes Agent profiles; do not use it as a harmless discovery check.
   The existing process-recovery flow asserts only still-active/Reconnect/no-Retry
   after relaunch; it does **not** prove the plan's completed canonical history,
   exact run readback/zero resend, expired/revoked/wrong-owner or denied-notification
   matrix. No existing credential-free Android death-to-completion harness was
   found in the inspected integration inventory/scripts.
2. **Safe deterministic fixture route exists:**
   `scripts/run_android_maestro_features.sh` requires `WING_QA_DEVICE`, builds the
   `.qa` package and uses synthetic production-screen overrides. Its two relevant
   flows were attempted individually above; their concrete selector/share-sheet
   failures currently block those exits. Full 20-flow runner was not run.
3. **Android save/share is not enabled by current product implementation:**
   `lib/features/hermes_chat/export/hermes_transcript_export_io.dart` chooses a
   saver only for Linux. Other native targets use the unsupported saver, matching
   the export runbook. Android loaded-transcript Copy is the existing candidate;
   save/share acceptance cannot be claimed from plugin presence or Linux tests.
4. **TalkBack/CJK IME/200% native acceptance remains missing:** the fresh target
   has TalkBack installed but disabled; no existing inspected flow drives actual
   TalkBack focus/actions or CJK composition. The large-text flow did not complete.

## Concrete next actions and cleanup

- In a separately authorized source-fix slice, update the fixture transcript
  selector to the current production host-specific composer identity, and make
  the setup flow dismiss/handle the native sharing sheet before fixture controls.
  Rerun exactly these two fixture flows on an owned `.qa` disposable target.
- For M2, first obtain the plan's authorized disposable Agent/provider runtime
  and supported M1 receipt. Then separately scope an exact-run death/relaunch
  harness that reads terminal canonical status/history and proves zero resend,
  expired/revoked/wrong-owner and denied-notification cases. The current Maestro
  flow is only a starting route, not the complete acceptance matrix; do not run
  the broad profile-mutating wrapper without separate permission.
- For M5, qualify existing Copy with actual Android clipboard readback and
  TalkBack/CJK input on a named disposable target. Keep Android save/share
  explicitly unsupported unless an independently authorized implementation slice
  changes the product gate. No implementation change is included here.

The owned emulator received `adb -s emulator-5580 emu kill` (exit 0). A subsequent
process/device readback confirms shutdown. No pre-existing AVD or real device was
started, cleared, uninstalled or modified. Scratch AVD/output remain local and
untracked for diagnosis; no destructive cleanup was applied to the shared tree.
