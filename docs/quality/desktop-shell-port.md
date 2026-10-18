# Official Desktop shell: structural adaptation

Reference inspected read-only: Hermes Agent `d923a5eb487a`,
[`apps/desktop`](https://github.com/NousResearch/hermes-agent/tree/d923a5eb487a/apps/desktop).
This is a bounded shell adaptation, not complete Desktop feature parity.

## Composition and equivalence

| Official source | Wing implementation / outcome |
| --- | --- |
| `DESIGN.md`, information architecture; `src/app/chat/sidebar/index.tsx:1562–1723` | Chat remains the home surface. Existing destination rows form one contiguous top navigation block instead of splitting navigation around sessions and a large flexible gap. All eight destinations and their existing route/overlay callbacks remain available. |
| `src/app/chat/sidebar/index.tsx:251–260`, `1726–1730` | A single scrollable stack prevents short-window sections from overlapping. Collapse control and profile footer remain outside that viewport. Navigation uses 10px gutters and 1px row gaps; header drops its unused 16px. |
| `src/app/chat/sidebar/chrome.tsx`; `sessions-section.tsx:65–104` | Session actions precede a muted section caption and indented source groups. Selected session has visible fill as well as selected semantics; rows align left. Exact loaded source identities, order, redaction and acknowledged activation remain unchanged. The inventory-scope explanation remains available as a tooltip. |
| `src/app/chat/sidebar/index.tsx:2062–2068`, `profile-switcher.tsx` | Fixed profile footer becomes one compact action containing current profile and Manage profiles, rather than a detached value plus a second row. Its semantic action includes the complete redacted profile value in expanded and collapsed states. It uses the existing Profiles overlay; it does not pretend to implement Desktop's profile rail switching. |
| `DESIGN.md`, context preservation | Collapse retains the real Chat editor/draft. Owner/generation fences, creation, selection, pagination, modal search, recovery, navigation and existing status inspection are unchanged. No new inventory, API, route, dependency or Agent mutation is introduced. |

## Explicit differences

Wing retains its eight currently implemented destination names, 48px minimum
interactive targets, 250/64px expanded/collapsed widths, and existing four-field
status strip. Desktop has a denser pointer-oriented navigation, profile rail,
Projects, contributed pages and native titlebar controls. Those contracts are not
simulated. At 390px, Chat keeps its existing header navigation menu and full
route-local session access, without a permanent bottom bar. At 768px the expanded
sidebar remains available rather than silently overriding the user's saved choice.
Other route/theme/chat/overlay files are outside this change's scope.

## Executed validation

Environment: Flutter 3.47.5 / Dart 3.13.4, using the existing lockfile. This differs
from older contributor prose naming Flutter 3.44.2; no SDK dependency upgrade.

- `flutter pub get --offline --enforce-lockfile`: passed, lockfile unchanged.
- `flutter test --no-pub --concurrency=1 test/shared/widgets/app_shell*_test.dart`:
  145 passed. Includes keyboard traversal/reversal, exact-session ownership,
  stale callbacks, delayed recovery, modal management, persisted collapse,
  redaction, status accessibility, and the production AppShell + HermesChatScreen
  at 390/768/1440px with 100% and 200% text.
- The real-Chat structural cases verify contiguous navigation before sessions,
  composer hit testing, mobile header menu, fixed footer reachability, no duplicate
  chat rail, no unsolicited session action, and retained editor state/draft through
  collapse/expand.
- `flutter analyze --no-pub`: no errors; one pre-existing warning at
  `lib/core/hermes/local_discovery/local_hermes_home_discovery.dart:21`
  (`unawaited_return_in_try_block`), outside scope, remains unchanged.
- Changed Dart files formatted; `git diff --check`: passed.

The footer paint regression previously expected literal gray `0x55` despite the
shared token palette having changed. The identical failure was reproduced on
base `fc54c07a`; the assertion now compares painted pixels to the actual opaque
composite of the current secondary/rail tokens, retaining the continuous-edge
pixel count and keyboard/focus assertions.

Optional widget captures can be reproduced with `FLUTTER_ROOT` set to the active
SDK and `WING_SHELL_CAPTURE_DIR` set to a private output directory while running
`test/shared/widgets/app_shell_desktop_structure_test.dart`. Captures use SDK
Roboto substituted for test font families, plus the SDK Material icon font;
ordinary checks use the unmodified production theme. Six captures were generated.
Image inspection confirmed panel containment, profile/footer separation and
visible composer at the requested sizes, but the test renderer still produced
block-shaped text glyphs. These images are not typography or pixel-parity proof.
The Flutter debug ribbon is test chrome, not a shipped shell element.

Qualification is Linux Flutter widget rendering/interaction, not a live Agent,
compiled browser, native desktop device, Android IME, or screen-reader pass.
Full Desktop parity and those runtime qualifications remain unverified.
