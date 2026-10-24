# README transcript framing after literal chat layout

Date: 2026-10-24. Product source: frozen parity candidate `61abd42d`.

The previous desktop crop started at absolute x=530 while the current message
rows begin at x=261. Its 750px window therefore removed the beginning of both
the prompt and the assistant summary. The old source contract required this
obsolete rectangle, so it could not detect the presentation failure.

The generator now captures the desktop at 1000×800, where the full-width message
rows fit the existing 750×310 presentation frame. It measures the exact prompt,
File activity and final-summary semantic groups, captures their padded union,
and contains that image inside the existing frame. Missing, offscreen or
oversized content fails generation instead of silently cutting it. The outer
published showcase stays 1200×760; the mobile showcase stays 390×808.

The mobile approval journey, safety prompt, synthetic-data labels and provenance
caption are unchanged. The newly generated mobile image is byte-identical to the
integration candidate's already regenerated mobile image. The desktop after-image
was visually inspected: prompt, file activity/status and final summary are fully
visible, with no clipped first characters or unrelated composer guidance.

## Executed checks

The frozen candidate's existing `main_e2e.dart` web build was copied read-only
into this task's isolated worktree. An owned loopback fixture and private scratch
state were used; the integration checkout, its running fixtures and its build
artifacts were not modified. The public package lock and dependencies are unchanged.

- Node 22: `node --test test/tooling/readme_transcript_crop_test.mjs` — **6 passed**.
  Covers full semantic containment, translated layout, fractional/edge bounds,
  rejection of the original too-wide transcript, excessive height and missing or
  invalid semantic bounds.
- `node --check scripts/generate_readme_assets.mjs` — passed.
- `flutter test --no-pub --concurrency=1 test/tooling/readme_assets_contract_test.dart`
  — **5 passed**. This existing suite now also executes the Node regression, so
  the geometry checks participate in ordinary Flutter validation.
- `npm run readme:assets` against the owned fixture through the existing
  `README_ASSET_BASE_URL` entry — passed using Chromium and the frozen web build.
  Generator error checks and mobile approval checks passed.
- Changed Dart contract formatted; `git diff --check` passed.

Only generator/support code, its regression checks and this receipt belong to
this commit. Integration regenerates the published assets after merging the fix.
These documentation captures do not establish live Agent, native/device,
cross-device synchronization or full Desktop parity qualification. They do not
change product source or invalidate unrelated frozen-product test evidence.
