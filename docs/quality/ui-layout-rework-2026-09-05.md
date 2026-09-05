# UI layout rework — 5 September 2026

This second pass changes information hierarchy and density across Hermes Wing.
The shared gateway selector becomes a compact connection strip, with its scope
explanation available through semantics and a tooltip. Profile, Office, and
schedule status is plain non-interactive metadata rather than chip controls.

Chat starts with a left-aligned heading and four full-width suggestion rows.
Providers puts model selection before provider access. Gateway health appears
before trust details. Settings, voice, and diagnostics use section headings
outside their grouped rows, with consistent title/subtitle sizing. Tool headers,
schedule notices, voice guidance, and phone-setup instructions are shorter.

All existing capability checks, profile identities, credential handling, and
Agent/Wing Link authority remain in their existing paths. No new domain state,
network operation, dependency, or trust permission was introduced.

## Runtime evidence

The physical target was Samsung SM-S928B, Android 16. The deterministic QA tour
captures 13 screens in both light and dark themes. Local comparison artifacts
are under `/tmp/hermes-wing-ui-v2/`; screenshots are not tracked in Git.
The regular debug application was also built from `lib/main.dart` and installed
using `adb install -r`, preserving its saved data. The QA package remains separate.

The fixture tour qualifies presentation, not live inference, real pairing,
acoustic behavior, or an actual Termux installation. Tools includes its honest
unsupported-inventory state. Linux, iOS, and native desktop were not exercised.

## Validation

The focused Flutter run passed 429 tests:

```bash
flutter test test/theme test/shared/widgets test/features/settings \
  test/features/providers test/features/gateway test/features/tools \
  test/features/schedules test/features/office test/features/soul \
  test/features/local_setup test/features/enrollment test/features/profiles \
  test/features/hermes_chat/screens/hermes_chat_tips_test.dart \
  test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart \
  test/integration/maestro_feature_fixture_test.dart \
  --concurrency=1 --reporter expanded
```

`flutter analyze` passed. Android builds passed for the isolated feature harness
and `lib/main.dart`. `npm run readme:assets` rebuilt the web fixture and refreshed
the README/landing visuals. Existing Android compile SDK/plugin and Kotlin
migration warnings remain.

Initial failures were a missing presentation-widget import, tests assuming old
scroll positions, and assertions using superseded copy or chip accessibility
roles. The import was fixed; tests now reach controls through scrolling and
check status as text, preserving authorization and persistence assertions.

Browser validation used the rebuilt deterministic web target:

```bash
npx playwright test --config=playwright.config.mjs \
  playwright/tests/regression/hermes-smoke.spec.mjs \
  playwright/tests/regression/browser-surfaces.spec.mjs
```

18 tests passed on the initial run; Schedules and Diagnostics failed on old
accessibility-role expectations. After correcting those selectors, both passed
with `--grep 'Schedules renders|Diagnostics reports'`. Status is now exposed as
text rather than a checkbox. Chat suggestions, keyboard voice switches, provider
capability gating, and redacted diagnostics export retain passing browser evidence.

Changed Dart files passed the formatting check. `git diff --check` passed.

Final physical checks used:

```bash
maestro --device "$ANDROID_SERIAL" test \
  --test-output-dir /tmp/hermes-wing-ui-v2/final \
  scripts/maestro/fixture/visual_review.yaml \
  scripts/maestro/fixture/providers.yaml \
  scripts/maestro/fixture/gateway_trust.yaml
```

The final visual tour passed in 3m 32s and produced 26 captures, with the fixture's
end-of-tour overflow assertion passing. The provider flow scrolls upward to
model selection in its new position. The other existing chat Maestro flows now
recognize the revised empty-chat heading.

All three final physical flows passed: visual review (3m 32s), provider/model
setup (2m 17s), and gateway trust (38s). The regular Hermes Wing app was opened
on the phone after QA completed.
