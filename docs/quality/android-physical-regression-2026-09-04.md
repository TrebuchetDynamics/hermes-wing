# Physical Android regression — 2026-09-04

Target: a USB-connected Samsung SM-S928B, Android 16 / API 36, ARM64.
The WayDroid device was excluded. Tests used the opt-in debug package
`com.trebuchetdynamics.hermes.wing.qa`; the existing Wing installation and its
paired credentials were preserved. This is debug-device evidence, not signed
release qualification. The tested QA APK was matched by digest before removal;
the original app remained installed. Temporary servers, the owned USB reverse
and the device hierarchy dump were removed.

## Results

| Check | Result |
| --- | --- |
| Complete Android feature/app/router/shared inventory | 979 passed, zero failures, 7m 51s |
| Full Dart unit/widget suite on Linux | 1,538 passed, zero failures, 3m 31s |
| Production Android UI through native input and HTTP/SSE | Complete Maestro flow passed |
| Android secure storage across three app processes | Write, rotate and verify/delete phases passed |
| Native speech readiness | On-device recognizer available; permission denial, grant and revocation reported correctly |
| Native TTS discovery | Installed voices/languages enumerated in all three phases |
| Browser functional regression | 35 passed across five suites, retries disabled |
| Go suite, static analysis and dependency audit | Passed; npm audit found zero vulnerabilities |

The [Android inventory](../../integration_test/android_feature_regression_test.dart)
reuses 85 suites covering enrollment, connection/trust states, chat, sessions,
branching, drafts, attachments, transcripts, approvals, voice-state logic,
profiles, directories, providers/models, schedules, tools, settings,
accessibility and navigation. Services, credentials and widget input are
synthetic in that inventory. Desktop presentation variants running in the
Android engine do not qualify desktop hardware. Two repository-file checks and
one embedded Bash syntax assertion run on the host instead of inside the APK.
The nine host cases passed. Unit and device counts overlap and must not be added
as unique coverage.

The separate [native UI flow](../../scripts/maestro/android_fixture_regression.yaml)
uses `lib/main.dart`, actual Android text input, actual screen dimensions and a
USB reverse connection to the deterministic HTTP/SSE fixture. It verifies:

- enrollment → manual connection → Android Back → enrollment;
- entering a connection and opening its contact;
- two typed turns with approval and streamed responses;
- force-stop/relaunch with authoritative transcript recovery;
- landscape and portrait rotation;
- stopping an approval-blocked run and completing a new approved turn.

The fresh passing flow produced four fixture runs, three `once` decisions and
one stop request. The fixture is not a live Hermes Agent/provider, and its
loopback transport does not qualify remote TLS, pairing or a physical network.

The [native storage test](../../integration_test/android_secure_storage_regression_test.dart)
uses real platform secure storage, not mocks. Independent random credentials
survive process restarts; rotating the Agent credential leaves Wing Link's
credential unchanged. Only digests cross processes in ordinary preferences.
Plaintext absence from ordinary preferences and final deletion are checked.
The test refuses to mutate storage outside the isolated QA application process.

Artifact digests and sanitized counts are recorded in the
[machine-readable receipt](android-physical-regression-2026-09-04.json).

## Defects found on the phone

1. **Manual-connection navigation crash.** A shell → enrollment → manual-setup
   push created a duplicate shell page key. Manual setup now owns a root
   navigation page while retaining shell presentation. The regression reproduced
   the assertion before the fix, and verifies Back navigation on Android and
   Linux variants. The native flow also exercises actual Android Back.
2. **Stopped approvals blocking the next run.** The channel invalidated stopped
   run approvals, but the UI queue retained their prompts. Stop now dismisses
   only prompts matching the channel, connection generation, profile, session
   and run. It does not answer an approval or claim server cancellation has
   finished. Tests preserve other owners and reject stale in-flight failures;
   the native stop/recovery flow reproduced and then verified the fix.

The shared harness also required normalizing physical insets and touch slop
alongside its synthetic screen size and pixel ratio. Otherwise a physical
phone's metrics caused false overflow and scrolling failures. An intermediate
965-pass / nine-failure run identified those gesture failures; the corrected
pre-fix inventory passed all 974 cases. Native UI checks retain actual device
metrics. Automation selectors were adjusted for merged Android accessibility
labels and the prefilled connection field. One automation launch failure was
followed by a successful direct Android launch and fresh complete flow.

## Reproduction and limits

Set `DEVICE` to an explicitly selected physical USB device; never select the
first Android target when a virtual device is also connected.

```bash
WING_ISOLATED_DEVICE_TEST=1 flutter test -d "$DEVICE" \
  integration_test/android_feature_regression_test.dart --no-uninstall
```

Run native storage with `WING_DEVICE_STORAGE_PHASE=write`, `rotate`, then
`verify`, each through a separate `flutter test --dart-define=...` process and
`--no-uninstall`. Revoke QA `RECORD_AUDIO` before write and verify; grant it
before rotate. The tests inspect readiness but never begin recording.

For native UI, build/install `lib/main.dart` with
`WING_ISOLATED_DEVICE_TEST=1`, start a dedicated `serve_web.mjs` fixture and
reverse its Agent port over ADB. Pass its device-loopback origin through
`WING_QA_FIXTURE_ORIGIN` to the Maestro flow. That flow clears only the QA
package. Store logs and screenshots privately; do not publish device IDs,
operator data or phone screenshots as receipts.

Physical microphone capture, an observed spoken phrase, audible speaker
playback, Bluetooth audio, live-provider behavior, installation/update/rollback
and signed release distribution remain unqualified by this run. Readiness and
TTS discovery are not acoustic proof. The build also reported the existing
secure-storage compile-SDK expectation and Kotlin migration warnings; successful
debug execution does not qualify future toolchain or release compatibility.

Concurrent untracked files under `integration_test/support/maestro/` appeared
after validation began. They are preserved outside this change and its receipts.
