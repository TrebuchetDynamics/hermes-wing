# Android direct setup and saved-owner recovery

Task: `t_d229db7f`, CONNECTION-SETUP-AUTH-MATRIX / CONNECTION-PATHS.
Admitted source: `cd6897f51e5dd9f61884b8fa3613afed55af2d5f`.
This is an Android production-control fixture, not actual Termux installation,
live Agent authentication, physical keystore or screen-reader qualification.
The exact checked task commit and executed results belong to the native card's
finish receipt and independent review handoff; parent closure stays separate.

## Smallest complete harness

The existing `local_setup_enrollment_native_fixture.dart` shares WingApp/router,
SecureHermesEndpointStore, HermesApiChannel, keyboard activation and retained-owner
assertions between Linux and Android. Its Android branch does not create Linux
HOME/XDG folders, invoke a directory chooser or capture with `/usr/bin/import`.
The existing Linux consumers keep their metadata-only assertions.

`android_direct_setup_enrollment_fixture.dart` supplies synthetic authenticated
loopback reads only. It rejects other origins and missing/wrong synthetic bearer
credentials, then delegates the existing deterministic Agent read responses.
There is no real Agent, provider request, Termux process, shell bridge, management
fallback or network socket. Secure storage is mocked even in the native entry;
SharedPreferences uses the isolated QA package on Android. No dependencies or
production controls were added.

The widget and native entries exercise public controls at 320/1024 logical widths
and 100/200% Flutter text:

- Saved endpoint with missing Agent credential enters welcome and manual Termux
  preparation; existing-Agent choice reaches configuration and masked token entry.
- Guide Back returns to preparation. Documentation launch throw/false renders a
  sanitized failure; a deliberate retry succeeds without connection or storage writes.
- AppBar Back and system Back cancel replacement, preserving the exact saved
  endpoint/profile/session and inert raw/secure legacy entries.
- Direct authentication denial is a live-region error; no automatic retry occurs.
- Secure-storage write failure is reported separately from connection failure;
  retained bytes and ownership survive, and the next deliberate Add Hermes succeeds.
- Contact selection restores the exact remembered owner/session. Observed legacy
  reads/deletes, management sockets, forbidden reads and Agent mutations (including
  send/approval/Stop) remain zero. Raw legacy fields and secure slot values survive.

## Offline checks

Use cached dependencies (`flutter pub get --offline`) first in a fresh worktree.

```sh
flutter test --no-pub --concurrency=1 test/integration/android_direct_setup_enrollment_test.dart test/features/enrollment/hermes_local_setup_enrollment_test.dart test/features/local_setup/termux_hermes_setup_test.dart
flutter analyze --no-pub
python3 -B test/tooling/android_direct_setup_enrollment_test.py
bash -n scripts/run_android_direct_setup_enrollment.sh
```

Runner tests use fake executables, not an Android device: they check explicit
serial, disposable ownership acknowledgement, no live-auth mode/extra arguments,
unreachable-target refusal, cooperative device locking, QA build environment and
failure propagation. They do not prove Gradle packaging or a native journey.

## Native execution: NOT_CHECKED

The picker and this worker observed `emulator-5586` online. That is availability,
not approved disposable ownership. No install/reset or native journey was run.
Establish approved target ownership and absence of any competing device writer
before using the launcher. Its locks serialize cooperating launchers, not arbitrary
ADB jobs. An acknowledgement is not independent authorization evidence.

```sh
WING_QA_DEVICE=APPROVED_DISPOSABLE_SERIAL WING_QA_DISPOSABLE=1 \
  bash scripts/run_android_direct_setup_enrollment.sh
```

The runner requires a private TMPDIR, authenticated explicit serial, no live-auth
mode, the existing `WING_ISOLATED_DEVICE_TEST=1` Gradle debug suffix, a device lock
and the shared heavyweight lock. It runs only the new integration entry with a
15-minute bound and Dart admission define. The resulting application ID is
`com.trebuchetdynamics.hermes.wing.qa`; never run with a personal paired package.
The native entry checks Android/admission before clearing QA preferences and
exports bounded journey data through `IntegrationTestWidgetsFlutterBinding`.
No actual Termux installation/start or live Agent request is part of this run.

Remaining milestone gaps: approved-target native execution, actual installation,
real authentication, physical secure storage and assistive-technology output.
Independent review, canonical integration and remote delivery are not implied by
an offline pass or local task commit.
