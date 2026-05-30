# Playwright debug scripts

One-off scripts for investigating the Flutter web semantics tree and browser interactions.

## Layout

- `accessibility/` — app and semantics-tree inspection scripts.
- `chat-input/` — chat composer, text entry, keyboard, and blocker investigations.
- `gateway/` — gateway connection form/debug flow scripts.
- `navigation-menu/` — app menu and nav rail investigations.
- `profile-clicks/` — profile tile/click method investigations.
- `support/` — local debug harness helpers for launching the app and enabling Flutter semantics.

These scripts are intentionally not part of the Playwright test suite. Prefer promoting stable helpers to `playwright/support/` when a pattern graduates from debugging into probes/tests.
