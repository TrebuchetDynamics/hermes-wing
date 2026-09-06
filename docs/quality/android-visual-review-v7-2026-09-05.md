# Android visual review — 2026-09-05, pass 7

Exercised a physical Samsung SM-S928B running Android 16 with the isolated
synthetic QA application. Captured and inspected the initial viewport of all 13
visual-tour routes in light and dark themes: Profiles, Tools, Office, Providers,
Persona, Gateway, Settings, Voice & speech, Diagnostics, Schedules, Chat,
Pairing, and local setup. This is visual-tour coverage, not every dialog or the
entire Maestro feature suite. No live provider inference was exercised.

## Changes and findings

- Disabled automatic repeat taps and extra settling for the deterministic Next
  screen control. Destination assertions and all 26 captures remain. The prior
  tour took 95 seconds; this pass took 92 seconds before the UI change and 93
  seconds afterward. This is a small observed gain, not a benchmark guarantee.
- Diagnostics previously put its export action partially below the navigation
  boundary. Status labels and values now share compact rows at normal phone
  widths. Both physical screenshots show the full export action without scrolling.
  Narrow layouts and enlarged text retain stacked rows.
- Reviewed the other 12 routes in both themes; this pass found no additional
  initial-viewport clipping that justified a layout change. Settings intentionally
  scrolls. Empty fixture inventories do not establish populated-list behavior.

## Validation

- `flutter test --concurrency=1 test/features/settings`: 36 passed, including
  light/dark export reachability at normal and 200% text scaling.
- `flutter analyze`: no issues.
- `dart format --output=none --set-exit-if-changed lib/features/settings/screens/settings_screen.dart test/features/settings/settings_diagnostics_screen_test.dart`: passed.
- `WING_ISOLATED_DEVICE_TEST=1 flutter build apk --debug -t integration_test/hermes_features_maestro_main.dart`: passed.
- Physical Maestro `visual_review.yaml`: passed, 26 screenshots and zero captured
  layout overflows.
- Physical Maestro `settings.yaml`: passed in 2m 1s; both flows passed in 3m 34s.
- `flutter build apk --debug -t lib/main.dart`: passed.
- `npm run readme:assets`: passed, including deterministic release web build.
- `git diff --check`: passed.

Temporary local evidence: `/tmp/hermes-wing-ui-v7/index.html` contains the
before/after gallery; build, test and Maestro logs are in the same directory.
Screenshots and APKs remain outside version control. This change affects
presentation and test navigation only; Agent authority, Wing Link capability
gates, credentials, and remote mutations are unchanged.
