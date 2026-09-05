# Physical Android UI review — follow-up

Target: Samsung SM-S928B, Android 16, portrait. Screenshots use the isolated
`com.trebuchetdynamics.hermes.wing.qa` package and deterministic synthetic data.
No live credentials or transcripts were captured.

## Speed and coverage

The existing 13-screen tour covers Profiles, Tools, Office, Providers, Persona,
Gateway, Settings, Voice & speech, Diagnostics, Schedules, Chat, pairing, and
local setup in light and dark themes (26 screenshots).

A 500 ms settle-time experiment passed but took 97.11 seconds, offering no
measurable improvement over the previous 97-second run; it was removed.
Visual-review mode now uses transition-free pages and removes duplicate position
assertions while retaining every screen-title assertion, screenshots, theme
boundary/end positions, missing-model checks, and the zero-overflow check.
Production navigation and ordinary interactive fixture navigation retain their
page transitions. The final tour took 93.65 seconds (3.6% faster in this measured
pair; single-run evidence, not a benchmark distribution).

## Changes from screenshot inspection

- Gateway health appears before the explanatory read-only note. The routine note
  uses compact padding and body-small text; fallback notices retain normal text
  and their retry action. Trust and capability behavior is unchanged.
- Diagnostics inventory uses localized singular/plural forms for models, skills,
  toolsets, and jobs. The captured fixture now says “1 job”.

Both final contact sheets and the detailed Gateway screenshot were reviewed.
The tour reported zero Flutter layout overflows. Existing scrollable content
remains scrollable; this is not coverage of every modal or every scroll position.

## Validation

Passed:

```bash
WING_ISOLATED_DEVICE_TEST=1 flutter build apk --debug -t integration_test/hermes_features_maestro_main.dart
maestro --device "$ANDROID_SERIAL" test --test-output-dir /tmp/hermes-wing-ui-v5/final scripts/maestro/fixture/visual_review.yaml scripts/maestro/fixture/gateway_trust.yaml
flutter test --concurrency=1 test/features/gateway test/features/settings test/integration/maestro_feature_fixture_test.dart
flutter analyze
flutter build apk --debug -t lib/main.dart
npm run readme:assets
git diff --check
```

- Maestro: 2/2 flows passed, visual review 94 seconds rounded and Gateway trust
  39 seconds; 2 minutes 13 seconds combined.
- Flutter: 52 focused tests passed, including count pluralization and existing
  Gateway trust/fallback/accessibility tests. Changed Dart files pass formatting.
- Initial analysis reported no issues, then a Flutter shutdown exception
  (`Cannot add new events after calling close`); a clean rerun passed without
  that exception.
- README/landing generation rebuilt the deterministic web target successfully;
  this is not a full browser E2E suite run.
- Both APK package IDs were verified before installation. The regular app was
  updated with `adb install -r`, preserving its stored data.

Local evidence is under `/tmp/hermes-wing-ui-v5/`: `index.html` switches before/
after and light/dark, `final/screenshots/` contains all 26 final captures, and
logs record builds, tests, analysis, assets, and Maestro. Screenshots are not
checked into the repository.

This pass exercised physical Android fixture presentation and a deterministic
trust flow, not live provider inference, all Maestro suites, or other platforms.
Agent/Wing Link ownership, authorization, transport, and domain contracts were
not changed.
