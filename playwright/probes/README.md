# Playwright probes

Exploratory scripts for discovering Navivox Flutter web routes, semantics, and feature behavior before promoting stable checks into `playwright/tests/`.

## Layout

- `screens/` — broad route and screen inventory probes.
- `navigation/` — nav rail, gateway/profile detail, and navigation surface probes.
- `features/` — targeted feature and regression-discovery probes.
- `support/` — probe-local browser/runtime helpers that wrap shared Flutter semantics helpers.

These scripts share stable Flutter semantics helpers from `../support/flutter_semantics.mjs` through `support/probe_runtime.mjs`. Keep one-off browser investigations in `../debug/`; promote repeatable behavior checks to `../tests/`.
