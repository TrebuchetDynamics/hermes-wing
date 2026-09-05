# Compact Linux UI review

This pass uses the native Linux screenshots from
[the real-service rerun](linux-live-e2e-rerun-2026-09-05.md), then exercises the
updated application with the same isolated Agent and Wing Link setup.
The design direction is compact navigation, restrained surfaces, readable text,
and visible primary actions. Existing capability and credential boundaries stay
unchanged.

## Screenshot findings

| Area | Finding | Response |
| --- | --- | --- |
| Shared desktop shell | The 256-pixel app rail and 320-pixel session rail consume almost half a 1280-pixel window. | Reduced them to 208 and 280 pixels. Chat gains 88 pixels of width. Navigation scrolls in short windows. |
| Brand and navigation | Large all-caps branding competes with page titles. | Smaller mark, sentence-case brand, tighter spacing, rectangular selection indicator. Destination labels remain visible. |
| Status strip | Four two-line metadata blocks dominate the bottom edge. | A single line with icons and full labeled tooltips. The captured strip drops from 47 to 29 pixels without removing status values. |
| Profiles | The app bar and body repeat the same heading. | Removed the repeated body heading, keeping the purpose text and New Profile action. |
| Profile setup | Create and Cancel scroll away below the credential fields; the title also disappears during scrolling. | Fixed header and action row around independently scrolling form fields. Validation, write-only credentials, catalog requests, and approval handling retain their existing behavior. |
| Provider/model autocomplete | Provider lists and OmniRoute discovery already provide useful choices; form chrome makes the workflow feel longer. | The form layout keeps the current operation visible while navigating the actual catalog. No providers or models are fabricated. |
| Gateway | The desktop page repeats its title above the health content. | Removed the duplicate heading. Existing parallel changes simplify trust details through progressive disclosure. |
| Settings and diagnostics | Nested spacing and card borders distract from a small number of controls. | Preserved the parallel compact layout and flat card treatment. Diagnostics is visible in the initial 1280×695 Settings capture. |
| Typography and surfaces | Light mode has inconsistent-looking fallback typography; nested outlines create visual noise. | Explicit system sans-serif fallback and restrained modal corners complement the parallel neutral palette, smaller app bars, and flat surfaces. |
| Tools, Providers, Schedules, Office, Persona | Sparse or unsupported states can appear more substantial than the available actions. | Shared styling reduces decoration; parallel targeted changes tighten inventory panels. Capability explanations remain visible. |
| Pairing and local setup | Explanatory text is long, but communicates meaningful trust and setup decisions. | Retained instruction content and primary action sizes; shared visual changes apply. |

The accompanying Android work is documented separately in
[the minimalist UI review](maestro-minimalist-ui-review-2026-09-05.md).
Those edits were already being made in the shared workspace and were preserved.
This pass does not claim authorship or independent physical-device verification
of that work.

## Remaining product issues visible in the screenshots

- Agent session IDs can appear as conversation titles. A useful display title
  should be derived from authoritative session metadata without rewriting IDs.
- Profile selection, model aliases, and inventory counts describe different
  resources but can appear contradictory. Cosmetic edits must not invent a
  selected profile or replace an advertised model with guessed host settings.
- Session counters can remain zero while a transcript is visible. This needs a
  separate reconciliation investigation rather than a hardcoded display fix.
- Voice-language menus remain wider than their short choices need. Native audio
  capture and playback are outside this visual review.
- Unsupported administration still needs clearer next-step guidance where a real,
  capability-authorized alternative exists.

## Verification

Passed:

- `flutter analyze` — no issues.
- `flutter test --concurrency=1 test/shared/widgets test/features/profiles test/theme test/features/gateway test/features/settings test/features/hermes_chat/screens` — 384 tests.
- `flutter test test/features/profiles/profile_catalog_test.dart test/shared/widgets/app_shell_test.dart` — 23 tests after adding the short-window regression.
- `bash scripts/run_linux_live_visual.sh` with the isolated live manifests and rootless Linux dependencies — native tour passed in 3 minutes 6 seconds; runner exit 0. Real chat, profile lifecycle, catalog autocomplete, OmniRoute discovery, reconnect, and settings controls were exercised.
- Changed Dart files pass `dart format --output=none --set-exit-if-changed`; `git diff --check` passes.
- Chromium decoded all 78 PNGs and exercised the before/after selector without page errors.

The focused native command
`xvfb-run -a flutter test -d linux integration_test/linux_feature_regression_test.dart --name 'profile editor keeps actions visible|desktop navigation reaches Settings|profile setup retries catalog' --reporter expanded`
passed the two new layout regressions and failed the existing catalog-Retry
case: the expected `alpha` option was absent. This remains the previously
reported native-only failure. It was not skipped or weakened. The broader native
suite was not rerun in this design pass.

Local evidence:

- [Before/after viewer](../../test-results/linux-compact-ui-2026-09-05/before-after.html) — 77 matching states.
- [Current gallery](../../test-results/linux-compact-ui-2026-09-05/index.html) — 78 screenshots across 14 routes and feature states.
- [Screenshot archive](../../test-results/linux-compact-ui-2026-09-05/linux-ui-review.zip).

The previous gallery had 80 captures. The updated layout needs fewer additional
scroll captures; this is not a claim that every possible UI state is covered.
Screenshots remain ignored local artifacts. Linux ran under Xvfb with real
services and an isolated secure keyring; physical display, microphone, and
acoustic behavior were not tested in this pass.
