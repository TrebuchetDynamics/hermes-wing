# Available-platform test pass — 2026-09-05

Tested the current checkout on the locally available Android, Linux, and Chromium
runtimes. Application/domain traffic used deterministic fixtures. This pass does
not qualify live provider inference, physical microphone or speaker quality,
service installation, or signed release distribution.

Local artifacts and logs: `/tmp/wing-platform-check/`.
Android device comparison gallery: `/tmp/wing-platform-check/index.html`.

## Shared checks

- `flutter analyze`: no issues.
- `flutter test --concurrency=1`: 1,604 passed.
- `(cd wing_link && go test ./...)`: passed.
- `npm audit`: zero vulnerabilities.
- The QA APK was built from `integration_test/hermes_features_maestro_main.dart`
  with `WING_ISOLATED_DEVICE_TEST=1`; package identity was checked before install.
  Production app data was not cleared.

## Android

Both Android targets ran the same five Maestro flows: `visual_review.yaml`,
`settings.yaml`, `providers.yaml`, `attachments.yaml`, and `computer_setup.yaml`.
The visual tour captures 13 routes in light and dark modes and asserts zero
layout overflows. These are five selected flows, not the entire feature suite.

Waydroid x86-64 / Android 13: **5/5 passed**, 5m 42s.
Samsung SM-S928B / Android 16: **5/5 passed**, 8m 42s.

An initial attempt to run two independent Maestro processes concurrently hit a
Samsung driver TCP-forwarding error before app launch. That batch was stopped;
it is not an application-flow failure or a pass. The Samsung retry ran alone.
Unwanted failure screenshots from the aborted launch attempt were discarded.

## Linux

The initial runner lacked development packages on its default search path.
Reused the existing rootless dependency bundle at
`/tmp/hermes-wing-linux-deps-full` through `PKG_CONFIG_PATH`, `CPATH`,
`LIBRARY_PATH`, `LD_LIBRARY_PATH`, and its compiler wrapper; no system packages
were changed.

- `npm run linux:e2e` with that environment: native app boot, session creation,
  and fixture chat passed under Xvfb.
- `xvfb-run -a flutter test -d linux integration_test/linux_feature_regression_test.dart --reporter expanded`:
  **1,025 passed, one failed** in 6m 59s.
- Failure: `profile setup retries catalog, offers unconfigured provider and
  clears stale model`, at `test/features/profiles/profile_catalog_test.dart:246`.
  After Retry and typing the provider display name, the expected `alpha`
  autocomplete row is absent. It reproduces in a focused native rerun; using
  `pumpAndSettle` instead of a single pump did not fix it. That test-only
  experiment was reverted. The same file's seven widget tests pass. Native
  catalog Retry remains unverified; the full native suite is not green.
- `bash scripts/run_linux_secure_storage_regression.sh`: passed write and
  verify phases in two native app processes using an isolated D-Bus/keyring.

## Web

The first Playwright pass failed browser speech fallback with
`MissingPluginException`. The cached generated web plugin registrant omitted
`flutter_tts`, even though the current dependency inventory included it.
An ordinary rebuild retained that stale registrant. Moved only the two stale
web target cache directories into the temporary evidence folder and rebuilt;
the resulting JavaScript includes the speech plugin. No application workaround
or assertion change was made. The fresh run exercised all eight configured web
specs against this build, including all 19 speech tests.

Final Chromium result: **46 passed, one skipped** across the eight specs.
The fresh cross-origin run initially omitted the fixture-port environment
variable and received connection refusals on the default port. Repeating that
spec with `HERMES_E2E_PORT=8892` passed both tests. All final runs used
`WING_APP_URL=http://127.0.0.1:8891/` and
`npx playwright test --config=playwright.config.mjs <spec>`.
Logs retain both the runner configuration error and the successful rerun.
Web screenshot artifacts are saved in `/tmp/wing-platform-check/web-screenshots`.

The live Hermes say-hi test is intentionally skipped because no live test
endpoint/credential was supplied. Browser speech tests use synthetic playback
recorders; they do not establish audible speech quality.

## Unavailable targets

macOS and iOS require a macOS/Xcode runtime, which is absent. No native Windows
Flutter target or built Windows app is present. Wine exists, but it is not native
Windows qualification. Firefox and WebKit Playwright browser binaries are not
installed. Chromium is the available browser target.

## Closeout

`git diff --check` passed. This testing pass adds only this report; the temporary
native test experiment was reverted. Existing installer changes were preserved.
The remaining failure is the native Linux provider-catalog Retry test described
above. No source fix or all-platform success claim is made for that failure.

## Follow-up fixes — 2026-09-06

The native Retry failure was traced to a test harness error, not the provider
catalog implementation. The fake loader called Flutter Test's guarded `expect`
inside the native `pumpWidget` callback. Its guarded-function conflict was caught
as a catalog failure before the fixture incremented its attempt counter. Retry
then reached the fixture's intended first failure, leaving no suggestions. The
test now records profile IDs and verifies both requests after pumping; it retains
the provider selection, stale-model clearing, and model-selection assertions.
All eight catalog tests pass on native Linux after this change.

Reviewed the 13-route Android light/dark screenshot tours, the wide Waydroid
contact sheet, and the Chromium desktop Settings screenshot. Targeted fixes:

- Autocomplete now opens toward the available space. A new bottom-edge selection
  regression failed before the change and passes afterward, including on Linux.
- Persona uses a smaller context heading, allows its helper text to wrap, and
  omits the unrelated default-profile deletion notice. Profile lifecycle editing
  retains that notice and the existing deletion protections.
- Providers omits the repeated model-selection heading when the active-model
  card already identifies the section.
- Desktop Settings groups voice and diagnostics beside appearance, removing the
  disconnected full-width diagnostics row and aligning both links.

No Agent/Wing Link authority, capability gate, credentials, or mutation contract
changed. Follow-up evidence is under `/tmp/wing-ui-fixes/`.

Follow-up validation:

- `flutter analyze`: no issues.
- `dart format --output=none --set-exit-if-changed lib test integration_test`:
  341 files checked, zero changes.
- `flutter test --concurrency=1`: **1,606 passed**.
- The full native Linux command above, with the same rootless dependencies:
  **1,028 passed**, zero failures, in 7m 01s.
- `(cd wing_link && go test ./...)`: passed; `npm audit`: zero vulnerabilities.
- Fresh isolated QA APK on Samsung Android 16: **4/4 Maestro flows passed** in
  7m 55s (`visual_review`, `providers`, `soul_directories`, `settings`). The tour
  captures all 26 light/dark views and checks for layout overflows. Production
  app data was preserved. Waydroid screenshots were reviewed; it was not rerun
  for this follow-up.
- `flutter build web --release -t lib/main_e2e.dart`, then all eight Playwright
  specs using `npx playwright test --config=playwright.config.mjs`: **46 passed,
  one live-service test skipped**. Both fixture ports were explicitly configured.
- `README_ASSET_BASE_URL=http://127.0.0.1:8891/ npm run readme:assets`: passed
  against the fresh E2E build; generated tracked assets remained unchanged.
- `git diff --check`: passed. Temporary diagnostic instrumentation was removed.

The original native failure is resolved. Reviewed fresh Android Providers,
Persona, Settings, and Diagnostics screenshots and the desktop Settings capture.
The before/after gallery is `/tmp/wing-ui-fixes/index.html`; web captures are in
`/tmp/wing-ui-fixes/web-screenshots/`. These checks continue to use synthetic
data and do not qualify live provider inference or physical audio.
