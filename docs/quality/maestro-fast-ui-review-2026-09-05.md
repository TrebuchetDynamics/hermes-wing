# Faster Maestro screen review — 5 September 2026

The isolated feature fixture now provides a test-only visual tour. Start visual
review visits the existing production screens using Next screen, switches from
light to dark after 13 screens, and retains the real application shell. It avoids
returning to and scrolling the fixture hub, and avoids restarting to change
themes. Other interaction flows retain their existing fixture controls.

The YAML checks the tour position and screen title before every capture, and
asserts zero layout overflows at the end. Diagnostics also asserts the explicit
missing-model fallback. No timeouts, assertions, or production animations were
disabled to obtain the speedup.

The initial 26-capture run on Samsung SM-S928B (Android 16) took 97.9 seconds,
versus 217.0 seconds for the previous tour on the same device. These figures use
the first command timestamp through the last command's completion, excluding
CLI startup. They are individual runs, not a benchmark median. The final flow
adds screen-title and missing-model assertions to the initial fast tour.

## Issues found and fixed

- Diagnostics displayed a blank Model value when the gateway supplied an empty
  string. Empty and whitespace-only values now display Not reported.
- Settings devoted two rows to accent-color chips. A labeled dropdown preserves
  all five choices and gives the following Voice section more room.
- The first dropdown capture exposed clipped selected text caused by menu-item
  padding inside a dense button. Removing that padding fixes the clipping;
  widget tests now assert that the selected label fits inside the control at
  ordinary and 200% text sizes on a 390-pixel-wide viewport.
- The dropdown inherited an oversized Android accessibility tap region. An
  explicit semantics container now bounds it to the field, and tests tap that
  container at both text sizes.
- Android merges the diagnostics and dropdown labels with their values in
  accessibility nodes. The Maestro selectors now match those complete nodes.
  The Settings flow also checks the saved color after restart and captures the
  open palette menu and persisted selection.

## Validation and scope

`flutter analyze` passed. All 36 tests passed with:

```bash
flutter test --concurrency=1 test/features/settings \
  test/integration/maestro_feature_fixture_test.dart
```

Localization was regenerated with `flutter gen-l10n`. Android debug builds passed
for the isolated feature entry point and regular `lib/main.dart`. Existing Android
toolchain warnings remain. Test artifacts and synthetic screenshots are local to
`/tmp/hermes-wing-ui-v4/`; they are not committed.

The physical flows use:

```bash
maestro --device "$ANDROID_SERIAL" test \
  --test-output-dir /tmp/hermes-wing-ui-v4/corrected \
  scripts/maestro/fixture/visual_review.yaml \
  scripts/maestro/fixture/settings.yaml
```

This run covers the 13 top-level fixture screens in both themes and Settings
persistence. It is not the entire Maestro suite or every dialog/error state.
Fixtures qualify presentation and local preferences, not live inference,
provider credentials, pairing, or Termux installation. No Agent or Wing Link
capability, transport, authority, or security behavior changed.

The corrected visual tour passed in 1m 37s with all 26 captures, title/position
assertions, and the zero-overflow check. Before/after images were inspected in
both themes. `npm run readme:assets` rebuilt the web fixture and regenerated the
previews. Changed-file formatting and `git diff --check` passed.

The final Settings flow passed separately using the same command with
`--test-output-dir /tmp/hermes-wing-ui-v4/settings-verified` and only
`scripts/maestro/fixture/settings.yaml`. It verified palette/menu interaction,
theme and palette persistence, speech preference persistence, the command word
after restart, and redacted diagnostics export. Its two extra screenshots bring
the successful capture set to 28. The final tap-region tests and analysis passed.
The regular debug app was installed with `adb install -r` and opened on the
Samsung, preserving saved application data.
