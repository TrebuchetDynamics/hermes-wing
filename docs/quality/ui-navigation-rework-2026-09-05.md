# UI navigation and density rework — 5 September 2026

This pass adds Profiles to the compact navigation bar, alongside Hermes,
Settings, and More. The existing focused-chat behavior still hides that bar.
Profile rows put Chat beside the identity when the viewport and text scale allow
it, retaining the wrapped action layout for narrow screens and larger text.
Office contacts use compact avatar, identity, status, and accessible action rows.
Shared cards use smaller corners and subtle boundaries; fields and buttons use
consistent smaller corners, and the light surface is closer to white.

The deterministic Android feature harness now includes AppShell around the same
feature routes as the application. Pairing and local setup remain outside the
shell. Previously, the visual tour captured standalone pages and omitted the
navigation's effect on available space. The fixture footer remains test-only.

No Agent/Wing Link capabilities, credentials, profile identities, mutation paths,
or runtime ownership changed in this presentation pass.

## Evidence

Artifacts are local to `/tmp/hermes-wing-ui-v3/`, with a light/dark comparison in
`index.html`. Captures contain synthetic QA data only. The physical target is
Samsung SM-S928B running Android 16. Fixture screenshots validate presentation,
not live inference or Termux installation. Native desktop and iOS were not run.

Focused validation passed 96 tests with:

```bash
flutter test --concurrency=1 test/shared/widgets/app_shell_test.dart \
  test/theme/wing_theme_test.dart test/features/profiles test/features/office
```

After adding an actual bottom-tab navigation test, the shell target passed all
15 tests. `flutter analyze` passed. Both Android debug builds passed, using
`integration_test/hermes_features_maestro_main.dart` with
`WING_ISOLATED_DEVICE_TEST=1`, and the regular `lib/main.dart` entry point.
`npm run readme:assets` rebuilt the deterministic web target and regenerated
README/landing images. Existing Android toolchain warnings remain.

The physical Maestro tour passed, producing 26 screenshots and passing its
`Layout overflows: 0` assertion:

```bash
maestro --device "$ANDROID_SERIAL" test \
  --test-output-dir /tmp/hermes-wing-ui-v3/final \
  scripts/maestro/fixture/visual_review.yaml
```

All 20 selected Chromium checks passed against the regenerated web build:

```bash
npx playwright test --config=playwright.config.mjs \
  playwright/tests/regression/hermes-smoke.spec.mjs \
  playwright/tests/regression/browser-surfaces.spec.mjs \
  --output=/tmp/hermes-wing-ui-v3/browser --reporter=line
```

`dart format --output=none --set-exit-if-changed lib test integration_test`
checked 333 files with no changes. `git diff --check` passed. The regular debug
app was installed with `adb install -r` and opened on the Samsung; no application
data was cleared. Go validation was not rerun for this presentation-only change.
