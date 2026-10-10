# Shell inventory keyboard qualification

Card: `t_65ce1e31`; ledger task: `FINISH-DESKTOP-SHELL`.
Baseline: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`.

## Delivered delta and attribution

The previously untracked `test/shared/widgets/inventory_keyboard_navigation_test.dart`
is now qualified for inclusion. Its original bytes passed on the first execution:
SHA-256 `a7487532f19f6d7dbff86dc2e9c1d6ccff04102f85a54393d027e4a88c042dd0`,
matching the selector's original snapshot. No harness assertions, production widgets,
route presentation, Agent contracts, capabilities or transport were changed.
No failure was reproduced and no production repair is claimed.

## Acceptance map

1. Inventory regression: eight cases passed with no skips: Tools, Schedules,
   Providers and Profiles, each at 390/1280px and 200% text. The actual router and
   deterministic channel exercise Chat focus semantics, forward Tab reachability,
   editor escape and Shift+Tab return. Existing assertions retain zero incidental
   keyboard reads, reject mutations, check provider read scope and verify Profiles
   identity/route stability. Profiles uses height 1400px; other cases use 900px.
2. Focused shell regression: 73 cases passed across the six suites listed below,
   including route-local reading order, short-window scrolling, collapse/resize,
   loaded-session owner fencing and reference-fidelity focus rendering. Analyzer
   and formatter passed. This is Linux-hosted widget evidence, not native app use.
3. Fresh JS-release E2E compilation followed by both unchanged Chromium journeys
   passed (2 expected, 0 unexpected, 0 skipped, 0 flaky; one worker, zero retries).
   Navigation covers expanded/collapsed route selection and compact More recovery.
   Global sessions covers exact Open, one explicit New Session, scoped request
   receipts and unchanged owner/no incidental reads during layout navigation.
   Browser widths are 1280/390px; browser checks do not assert 200% text scaling.
4. Goal helper marks this bounded task done and records executed results; native
   same-card review is the final handoff. Full PARITY-COMPOSITION is not claimed met.

## Executed commands

All commands ran in `<repo>`.

- `flutter test --no-pub --concurrency=1 test/shared/widgets/inventory_keyboard_navigation_test.dart`: pass, 8.
- `dart format --output=none --set-exit-if-changed test/shared/widgets/inventory_keyboard_navigation_test.dart`: pass, zero changed files.
- `flutter test --no-pub --concurrency=1 test/shared/widgets/app_shell_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart test/shared/widgets/app_shell_global_session_access_test.dart test/shared/widgets/app_shell_reference_fidelity_test.dart test/shared/widgets/app_shell_navigation_groups_test.dart test/shared/widgets/app_shell_desktop_parity_test.dart`: pass, 73.
- `flutter analyze`: pass, no issues.
- `flutter build web --release -t lib/main_e2e.dart`: pass. Existing flutter_tts Wasm dry-run and font warnings remain; this was a JS-release build, not Wasm qualification.
- Owned server: `PORT=18967 HERMES_E2E_PORT=18968 node serve_web.mjs`; HTTP readiness checked before testing, only this child terminated afterward.
- `PORT=18967 HERMES_E2E_PORT=18968 WING_APP_URL=http://127.0.0.1:18967/ CHROME_EXECUTABLE=/usr/bin/chromium NODE_OPTIONS=--max-old-space-size=2048 npx playwright test --config=playwright.config.mjs playwright/tests/regression/desktop-navigation-groups.spec.mjs playwright/tests/regression/global-session-access.spec.mjs --workers=1 --retries=0 --output=<home>/.hermes/cache/scratch/t_65ce1e31/browser-output`: pass, 2, Chromium 152.0.7977.75.
- `git diff --check`: pass.
- `python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate .`: pass before and after ledger update.

The first browser invocation without CHROME_EXECUTABLE failed before either journey
launched: Playwright's bundled headless executable was absent. Retrying readiness
on the just-used 18867 port encountered address-in-use; no listener was killed.
The successful invocation used fresh explicit ports and existing system Chromium
in headless mode with isolated Playwright state; no personal DISPLAY, browser
profile, live service or Agent credentials were used.

## Source and retained evidence

The 201-file manifest covering all `lib/**/*.dart`, this harness, pubspec files,
fixture server, Playwright configuration and both browser specs had zero drift
between widget tests, fresh compilation and successful browser verification.
Sorted JSON manifest SHA-256:
`0e91e55406ebbd2020f49d5c6f562a2c3ff92163107421bf735d29858199bcd7`.
Fresh `build/web/main.dart.js` SHA-256:
`fc523a6a52c53bc62d18bc3b8908b4cc3bf035e86b839df75e621422857380fd`.
Compact logs, source manifest, browser request/semantics receipts and results are
retained locally in `.task-evidence/t_65ce1e31/`; these ignored execution artifacts
are not product source or third-party delivery. The task-created web build is
removed after verification. The local agent branch contains only this receipt and
the qualified harness; foreign documentation, dependency, browser, Go and gateway
changes are preserved. Shared goals/TODO updates remain with the existing docs wave,
not included wholesale in the scoped commit.

## Limits and defaults

Native desktop launch, installed runtime, live Agent/provider, physical device,
screen-reader, full Flutter/Go/browser suites and signed packaging: NOT_CHECKED.
No system installation, live credentials, upstream edits or publication attempted.
This closes only the remaining inventory keyboard qualification, not full product
parity. No new owner questions; existing no-install/no-credentials defaults retained.
