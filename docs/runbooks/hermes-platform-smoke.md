# Hermes platform smoke checklist

Use this checklist while moving Navivox from the legacy Gormes UI toward the
native Hermes Agent UI. It separates build-only gates from live-device gates so
we do not claim mobile/desktop parity from widget tests alone.

## Build gates

Run from the repo root:

```bash
flutter analyze
flutter test --concurrency=1
flutter build web --release -t lib/main_e2e.dart
flutter build apk --debug
npm run linux:release-build
```

Current local receipts (refreshed through 2026-07-03):

- `flutter analyze` — pass.
- `flutter test --concurrency=1` — pass, 1016 tests.
- `flutter build web --release -t lib/main_e2e.dart` — pass.
- `flutter build apk --debug` — pass, artifact at `build/app/outputs/flutter-apk/app-debug.apk` with SHA-256 `453e746d9773b466a7393ec73713943a49276f4bee4465d18a3d083e5cb5ab0a` (artifact identity only; not live Android, mic, or reconnect evidence).
- `cd android && ./gradlew :app:testDebugUnitTest` — pass for Navivox app native Android unit tests. The broader `./gradlew testDebugUnitTest` runs third-party plugin tests too and currently fails in `image_picker_android`'s `ImagePickerDelegateTest` in this environment.
- `npm run linux:release-build` — pass, artifact at
  `build/linux/x64/release/bundle/navivox`. This container has no passwordless
  `sudo`, so `libsecret-1-dev`/`libgcrypt20-dev`/`libgpg-error-dev` (required
  by `flutter_secure_storage_linux`'s `pkg_check_modules(... libsecret-1 ...)`)
  can't be `apt-get install`ed system-wide. Root-less recipe used instead:
  1. `apt-get download libsecret-1-dev libgcrypt20-dev libgpg-error-dev`
     (download only, no root needed) and `dpkg -x <pkg>.deb <prefix>` each
     into a local prefix directory.
  2. Copy the `.pc` files from `<prefix>/usr/lib/x86_64-linux-gnu/pkgconfig/`
     into a separate directory, rewriting `prefix=/usr` to
     `prefix=<prefix>/usr` in each (the extracted `.pc` files still point at
     the system `/usr` by default).
  3. Fix the dev package's `libsecret-1.so -> libsecret-1.so.0` symlink,
     which is dangling inside the extracted prefix (the versioned `.so.0` is
     only installed system-wide by the already-present runtime package,
     `libsecret-1-0`) — repoint it at the real system file:
     `ln -sf /usr/lib/x86_64-linux-gnu/libsecret-1.so.0 <prefix>/usr/lib/x86_64-linux-gnu/libsecret-1.so`.
  4. `rm -rf build/linux` (force a clean CMake configure — a cached
     `CMakeCache.txt` from an earlier failed attempt will otherwise keep a
     stale `pkgcfg_lib_LIBSECRET_secret-1-NOTFOUND` `find_library` result
     even after the symlink is fixed) and rerun `flutter build linux` with
     `PKG_CONFIG_PATH` pointing at the rewritten `.pc` directory and `CPATH`
     pointing at `<prefix>/usr/include`. The helper script
     `scripts/run_linux_release_build.sh` automates this fallback and is exposed
     as `npm run linux:release-build`.
  The resulting binary links the real system `libsecret-1.so.0` at runtime
  (confirmed via `ldd`) — the local prefix is a build-time-only stand-in for
  the missing dev headers/symlink, not something the shipped binary depends
  on. The helper accepts a relative or absolute `NAVIVOX_LINUX_BUILD_DEPS_DIR`
  and resolves it before rewriting `.pc` files so nested CMake builds can still
  find the extracted headers/libs. This recipe is only needed in root-less
  containers; CI/normal dev machines should just `apt-get install
  libsecret-1-dev`.
- `flutter build windows --debug` — blocked here because Flutter only supports
  this command on Windows hosts (`"build windows" only supported on Windows
  hosts.`; latest local reprobe exited 1 on 2026-07-03).
- `flutter build ios` — blocked here because this Linux Flutter toolchain does
  not expose usable iOS simulator build options (`flutter build ios --simulator
  --debug` exits 64 with `Could not find an option named "--simulator".`);
  validate on macOS/Xcode.

Windows and iOS platform folders are present. The iOS `Info.plist` includes
microphone and speech-recognition usage descriptions for the Hermes
voice-to-text path. Windows and iOS builds must run on their host platforms/CI
runners; they are not validated from this Linux container.

Host-runner CI is defined in `.github/workflows/hermes-platform-smoke.yml` with
bounded job timeouts so unavailable hosts/emulators fail with actionable logs
instead of hanging:

- Ubuntu: analyze, tests, web e2e build, fake Hermes browser smoke, Android
  debug APK build, Linux release build, and uploaded Android/Linux artifacts.
- Windows: Flutter Windows debug build on `windows-latest` plus uploaded debug
  bundle artifact.
- macOS: Flutter iOS simulator debug build on `macos-latest` plus uploaded
  simulator app artifact.
- Manual `workflow_dispatch`: optional provider-backed Hermes web smoke when
  `run_provider_smoke` is enabled and `provider_url` is supplied. Store the API
  key in the `NAVIVOX_PROVIDER_HERMES_API_KEY` repository secret.
- Manual `workflow_dispatch`: optional Android emulator integration smoke when
  `run_android_emulator_smoke` is enabled. It runs the speech-readiness,
  deterministic Hermes continuous-voice loop, and durable-key integration tests
  on a GitHub-hosted Android emulator through the same hardened `scripts/run_android_*`
  wrappers used locally.

The workflow file must be visible to GitHub before this counts as a receipt.
A local YAML file is not enough: as of 2026-07-03,
`NAVIVOX_WATCH_WORKFLOW=false npm run platform:workflow-smoke` still exits 2
and prints visible workflows (`pages-build-deployment` only), so no native-host
Windows/iOS/hosted Android receipt is present yet.

Once the workflow file is published to the remote branch, dispatch and watch the
host-runner receipt path with:

```bash
npm run platform:workflow-smoke
```

If `NAVIVOX_WATCH_WORKFLOW=false` is used, the helper only proves dispatch; it
does not wait for job results. If dispatch succeeds but no run id is visible,
the helper exits 4 and still does not count as a platform receipt. Collect
successful Windows/iOS/Android/Linux job receipts from `gh run view`/artifact
logs before claiming platform readiness.

Before any completion claim, run the readiness audit in strict mode:

```bash
NAVIVOX_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit
```

While blockers remain, the helper must exit 3 and print
`Completion verdict: NOT COMPLETE`. Do not promote proxy evidence such as tests,
APK hashes, configured Hermes home, workflow YAML, or dispatch-only output to
platform readiness.

Optional knobs:

```bash
NAVIVOX_RUN_ANDROID_EMULATOR_SMOKE=true npm run platform:workflow-smoke
NAVIVOX_RUN_PROVIDER_SMOKE=true \
NAVIVOX_PROVIDER_HERMES_URL=https://hermes.example \
npm run platform:workflow-smoke
```

The provider smoke still requires the `NAVIVOX_PROVIDER_HERMES_API_KEY`
repository secret. If workflow pushes are blocked by credential scope, validate
these gates manually on equivalent host runners until the workflow can be
published.

## Browser e2e Hermes smoke

```bash
flutter build web --release -t lib/main_e2e.dart
node serve_web.mjs &
npx playwright test --config=playwright.config.mjs playwright/tests/regression/hermes-smoke.spec.mjs --reporter=list
```

The e2e server provides a local Hermes HTTP/SSE fake so the browser test uses
real `HermesApiChannel` web transport for health, capabilities, sessions, runs,
run events, approvals, tool progress, and stop/approval endpoints.

Current receipts:

- 2026-07-01: `hermes-smoke.spec.mjs` passed 2 Chromium tests, covering
  disconnected setup hints plus connected text, new-session, voice-transcript,
  approval, stop, and tool-progress UI.
- 2026-07-03: focused regression rerun of `navivox-e2e.spec.mjs` plus
  `hermes-smoke.spec.mjs` passed. The broad `npm run web:e2e` wrapper timed out
  in this environment, so the current usable receipt is the focused Playwright
  command recorded in `TODO.md`.

## Live Hermes Agent smoke

A local installed Hermes Agent API connect smoke is automated:

```bash
npm run hermes:live-smoke
```

The script starts `hermes gateway` with a generated test API key, isolated temp
`HERMES_HOME`, API server enabled, and CORS for the local Navivox web bundle. It
then builds `lib/main_e2e.dart`, serves the Flutter web bundle, and runs
`playwright/tests/regression/hermes-live-api.spec.mjs` against the live Hermes
API. It verifies `/hermes` can connect to the installed Hermes API and render the
session surface without using provider/model credentials.

Override knobs when needed:

```bash
NAVIVOX_LIVE_HERMES_PORT=8642 npm run hermes:live-smoke
NAVIVOX_LIVE_HERMES_HOME=/path/to/test-home npm run hermes:live-smoke
```

Current receipt (refreshed 2026-07-03): installed `hermes` v0.16.0 was present on PATH;
`npm run hermes:live-smoke` passed against a temp-home API server on loopback.
This proves API connect/session rendering only; it is not provider/model evidence,
not a chat/voice provider smoke, not physical microphone evidence, and not
whole-goal completion evidence by itself. The helper points operators back to
strict readiness audit before any completion claim.

Provider-backed web chat plus transcript-voice validation is gated because it
needs a Hermes endpoint already configured with real model/provider credentials:

```bash
NAVIVOX_PROVIDER_HERMES_URL=http://127.0.0.1:8642 \
NAVIVOX_PROVIDER_HERMES_API_KEY=... \
npm run hermes:provider-smoke
```

If the installed local Hermes home is already configured with provider/model
credentials, this helper starts the API server with a temporary Navivox test API
key and runs the same provider smoke:

```bash
NAVIVOX_CONFIGURED_HERMES_HOME=$HOME/.hermes npm run hermes:provider-smoke:local
```

The provider smoke builds `lib/main_e2e.dart`, serves the Flutter web bundle,
connects to the supplied Hermes endpoint, sends a typed prompt, then submits a
simulated device voice transcript through `HermesApiChannel`. It expects the
assistant to include `NAVIVOX_PROVIDER_SMOKE_OK` and
`NAVIVOX_PROVIDER_VOICE_OK` by default; override the prompt/expected text with
`NAVIVOX_PROVIDER_TEXT_PROMPT`, `NAVIVOX_PROVIDER_TEXT_EXPECTED`,
`NAVIVOX_PROVIDER_VOICE_PROMPT`, and `NAVIVOX_PROVIDER_VOICE_EXPECTED` for a
specific provider/model. It intentionally does not test a physical microphone;
that remains the Android device-gated smoke below.

Current receipt (refreshed 2026-07-03):
`npm run hermes:provider-smoke:local` passed against the installed local Hermes
server and configured provider/model credentials (Playwright reported 1 pass).
This is still transcript voice, not physical microphone or Hermes server audio,
and not whole-goal completion evidence by itself. The helper points operators
back to strict readiness audit before any completion claim.

Full live chat/voice validation still requires, for Android microphone capture,
a responsive device/emulator:

1. Start Hermes Agent API server on `127.0.0.1:8642` with test credentials.
2. Open Navivox `/hermes` on web/desktop or Android.
3. Connect using the platform-appropriate URL:
   - desktop/Linux/Windows/iOS simulator: `http://127.0.0.1:8642`
   - Android emulator: `http://10.0.2.2:8642`
   - physical device: LAN/VPN/Tailscale URL
4. Verify: session list/create, typed text turn, streamed assistant response,
   tool progress card, approval prompt + response, stop, reconnect from saved
   endpoint, push-to-talk voice transcript, and continuous voice loop.

## Android live smoke (still required)

A debug APK builds locally, but no responsive Android device/emulator was
available in this environment. The automated readiness gate is:

```bash
npm run android:voice-smoke
```

or, for a specific target:

```bash
NAVIVOX_ANDROID_DEVICE_ID=<device-id> npm run android:voice-smoke
```

The script grants `RECORD_AUDIO` when possible and runs
`integration_test/android_device_speech_smoke_test.dart`, which verifies the
native Android speech diagnostics MethodChannel reports at least one speech
recognition service and microphone permission granted. This is a readiness gate,
not a substitute for listening to real microphone input, and not whole-goal
completion evidence by itself. The helper points operators back to strict
readiness audit before any completion claim.

Current receipt (2026-07-02): the bundled `fractal_test` emulator had to be
launched headlessly with software rendering:

```bash
/usr/lib/android-sdk/emulator/emulator -avd fractal_test -no-window -no-audio -no-snapshot -gpu swiftshader_indirect -accel off
```

After boot completed, `npm run android:voice-smoke` passed. Earlier attempts
could also observe the emulator while it was still `offline`; the Android smoke
scripts now wait up to `NAVIVOX_ANDROID_DEVICE_WAIT_SECONDS` for Flutter to list
an Android target before selecting one. Install attempts also timed out while
Android framework services were still stabilizing, so the scripts require
repeated readiness checks for `sys.boot_completed=1`, `service check package`,
and `service check settings` before installing/running tests on slow
software-emulated runners. They also require `cmd package list packages` to
succeed because `service check package` can briefly report `found` while package
commands still fail. The scripts retry once when Flutter/ADB reports an Android
install/start flake such as a missing package service, broken pipe, or offline
device.

A deterministic Android Hermes voice-loop smoke, still without physical audio,
can exercise the Flutter continuous-voice loop on device:

```bash
npm run android:hermes-voice-loop-smoke
```

or, for a specific target:

```bash
NAVIVOX_ANDROID_DEVICE_ID=<device-id> npm run android:hermes-voice-loop-smoke
```

It runs `integration_test/hermes_continuous_voice_android_smoke_test.dart` with
a deterministic transcript capture service and fake Hermes channel. Passing this
means the Android Flutter UI can perform capture → submit transcript → assistant
reply/TTS → re-arm. It still does not prove physical microphone audio input.

Current receipt (refreshed 2026-07-03): after KVM-backed `fractal_test`
emulator boot stabilized, `NAVIVOX_ANDROID_DEVICE_ID=<emulator>
NAVIVOX_ANDROID_DEVICE_WAIT_SECONDS=1 npm run android:hermes-voice-loop-smoke`
passed. This refresh proves deterministic Android UI loop mechanics only; it is
not physical microphone evidence, not a provider-backed reply receipt, not
Hermes realtime/server audio, and not whole-goal completion evidence by itself.
The helper points operators back to strict readiness audit before any completion
claim.

Then perform the manual live Hermes Agent voice smoke on the same device. Use
[`android/live-mic-smoke.md`](android/live-mic-smoke.md) as the canonical
physical-audio receipt checklist. To install the debug APK, grant microphone
permission, and launch Navivox on an audio-capable Android target, run:

```bash
npm run android:live-mic-prep
```

Optional knobs:

```bash
NAVIVOX_ANDROID_DEVICE_ID=<device-id> \
NAVIVOX_ANDROID_HERMES_URL=http://10.0.2.2:8642 \
npm run android:live-mic-prep
```

Current prep receipt (2026-07-03): after KVM-backed `fractal_test` emulator
boot stabilized, `NAVIVOX_ANDROID_DEVICE_ID=<emulator>
NAVIVOX_ANDROID_DEVICE_WAIT_SECONDS=1 NAVIVOX_ANDROID_SKIP_BUILD=1
NAVIVOX_ANDROID_HERMES_URL=http://10.0.2.2:8642 npm run android:live-mic-prep`
installed/launched/granted microphone permission. This prep command is not a
pass receipt and not whole-goal completion evidence by itself. The helper points
operators back to strict readiness audit before any completion claim. The
operator must still record the manual evidence:

1. Connect to Hermes using `http://10.0.2.2:8642` for emulator or a LAN/VPN URL
   for a physical device.
2. Tap Speak and confirm a spoken phrase submits as a Hermes text turn.
3. Enable continuous voice and confirm capture → assistant reply/TTS → re-arm.
4. Confirm no API key or transcript secret appears in routes, logs, notices, or
   diagnostics export.

## Android durable-key smoke

For the legacy Gormes durable reconnect blocker, Android keypair readiness can
be checked separately from the full reconnect protocol:

```bash
npm run android:durable-key-smoke
```

or, for a specific target:

```bash
NAVIVOX_ANDROID_DEVICE_ID=<device-id> npm run android:durable-key-smoke
```

This runs `integration_test/durable_key_store_android_smoke_test.dart` on an
Android target and verifies both the native keystore MethodChannel and the Dart
`MethodChannelDurableCredentialKeyStore` adapter can create an ES256 keypair,
export only the public JWK coordinates, sign a payload, delete the key, and
reject unsafe aliases. It does not prove Gormes durable credential issuance or
reconnect end to end.

Current receipt (refreshed 2026-07-03): after KVM-backed `fractal_test`
emulator boot stabilized, `NAVIVOX_ANDROID_DEVICE_ID=<emulator>
NAVIVOX_ANDROID_DEVICE_WAIT_SECONDS=1 NAVIVOX_ANDROID_TEST_TIMEOUT_SECONDS=900
npm run android:durable-key-smoke` passed. This verifies keypair readiness only;
durable credential issuance and silent reconnect remain future work. It is not
whole-goal completion evidence by itself; the helper points operators back to
strict readiness audit before any completion claim.

Dart-side durable reconnect evidence was refreshed on 2026-07-03:

```bash
flutter test test/core/session/reconnect test/core/session/credentials \
  test/core/gateway/capabilities/durable_reconnect_readiness_contract_test.dart \
  test/core/session/readiness/reconnect_readiness_test.dart
flutter test test/core/channel/gateway/runtime/channel_test.dart \
  --plain-name 'falls back to device-bearer reconnect when stream reconnect exhausts'
flutter test test/core/channel/gateway/runtime/channel_test.dart \
  --plain-name 'provider reconnects automatically from saved durable gateway'
```

Those tests passed, covering in-memory durable credential issuance/readiness and
fake-gateway reconnect fallback/provider startup reconnect. They still do not
prove a physical Android saved credential reconnect against real Gormes after an
app/server restart.
