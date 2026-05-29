# Navivox Playwright E2E Tests

End-to-end tests for the Navivox Flutter web app, using Playwright to interact
with the Flutter web accessibility/semantics tree.

## Prerequisites

- Flutter SDK 3.38+
- Node.js 22+
- Playwright (installed via `npm install`)
- Built Flutter web e2e bundle: `flutter build web --release -t lib/main_e2e.dart`

## Quick Start

```bash
# Build the e2e test app
flutter build web --release -t lib/main_e2e.dart

# Serve and test
node serve_web.mjs &
npx playwright test --config=playwright.config.mjs
kill %1

# Or use the script
./playwright/scripts/run_tests.sh
```

## Layout

```text
playwright/
├── tests/        # Specs run by playwright.config.mjs
├── support/      # Shared Flutter semantics helpers for specs and probes
├── debug/        # One-off browser/debug scripts
├── probes/       # Exploratory route and surface probes
├── scripts/      # Runnable helpers
└── screenshots/  # Generated local screenshots, ignored by git
```

## Test Coverage (83 Playwright tests total)

Current count comes from `npm run web:e2e -- --list`.

| Area | Tests | Verifies |
|------|-------|----------|
| **Profile Contacts** | 4 | 3 seeded profiles visible, UI elements (FAB, search, menu), health previews, attention badge on needs-auth profile |
| **Chat Navigation** | 3 | Clicking each profile navigates to correct `/chats/:server/:profile` URL, chat composer present |
| **Menu Navigation** | 5 | Menu → Gateways (`/servers`), Manage profiles (`/agents`), Memory (`/memory`), Config (`/config`), Settings (`/settings`) |
| **Gateways Screen** | 1 | Server list with Local Gormes + Office Gormes + Register gateway button |
| **Agents Screen** | 2 | Profiles listed with Status/Channels/Memory/Latest details, Active profile indicator, Refresh button |
| **Memory Screen** | 1 | Degraded state with "Gormes memory API is unavailable" message |
| **Config Screen** | 1 | Profile scope, server info, profile ID, "No config available" state |
| **Settings Screen** | 1 | Voice settings, Global app settings, command word "navi", gateway/profile overview |
| **Screenshots** | 7 | All 7 screens captured as PNG |
| **Setup Screen*** | 14 | Form fields, token toggle, error states, retry guidance |
| **Additional Regression Coverage** | 4 | Office-scoped profile chat routing, accessible switch state, config fallback boundaries, gateway chip semantics |

*\* Setup screen tests (from earlier session) use the real (non-e2e) build.*

## Architecture

The e2e build (`lib/main_e2e.dart`) uses `E2EMockChannel` — a `ChangeNotifier`
implementing `NavivoxChannel` — pre-seeded with:

- **2 gateways**: Local Gormes (online), Office Gormes (online)
- **3 profiles**: Mineru Builder (online, mic), Support Triage (needs-auth, badge),
  Voice Agent (online, mic)
- **Chat echo**: `sendText()` stores messages and echoes back "Echo: {text}"

Flutter web renders via CanvasKit (no DOM widgets). Tests interact through the
**accessibility semantics tree** — parallel `flt-semantics` elements with ARIA
roles, labels, and text content.

### Click approach

Buttons use `role="button"` with text content; popup menu items use
`role="menuitem"` with `aria-label`. All clicks dispatch
`PointerEvent` + `MouseEvent` sequences directly on the semantics element.

### Limitations

- CanvasKit requires WebGL which may not work in headless Chrome.
  Tests validate DOM/accessibility state, not pixel output.
- Flutter stores input values in `TextEditingController` (internal state),
  not the native `<input>`/`<textarea>` DOM value. `page.fill()` and
  programmatic value setters don't propagate to Flutter's state.
  Tests verify navigation and element presence, not text entry.
- Popup menu items (`role="menuitem"`) use `aria-label` not text content.