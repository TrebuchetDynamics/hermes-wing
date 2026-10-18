# Desktop capabilities: bounded Flutter port

## Reference and shipped scope

Read-only official reference: `apps/desktop/src/app/capabilities/index.tsx`,
`skills/skills-tab.tsx` and `toolsets/toolsets-tab.tsx` in Nous Research's
[Hermes Agent repository](https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop/src/app/capabilities).
The shell has Skills, Toolsets, Connectors and Plugins modes; skills and toolsets
use searchable lists with inspection details and explicit connection/profile scope.

Wing's existing `/tools` route now presents **Skills** and **Toolsets** tabs instead
of two stacked cards. Each tab has a flat searchable inventory. Skill descriptions
and categories remain readable in the list; toolsets show their authoritative
status and disclose resolved tools inline. Inline disclosure is the responsive
Flutter adaptation, not Desktop's separate resizable detail pane.

The inventories still come exclusively from the existing exact-authorized Agent
skills/toolsets reads. Empty, name-only, unavailable, failed and no-match states
remain distinct. Refresh uses the existing owner-bound read, with sanitized errors.
No new API, dependency, mutation, provider setup or Agent modification is involved.
Connectors, Plugins, Hub installation, editing, toggles, usage sorting and other
Desktop administration are deliberately absent: this does **not** establish full
Desktop capability parity. See [route status](../product/routes.md).

## Volatile presentation ownership

Searches remain independent per tab, as established by Wing's existing search
contract. Unlike Desktop's shared query, switching tabs does not replace either
query. Both queries and toolset disclosure survive same-owner refresh, filtering
and tab visits; the inactive tab is removed from accessible interaction.

The owning channel, host, profile, connection/selection state and each inventory's
exact read authority invalidate presentation state synchronously. Even a loss and
restoration before the next frame discards the old owner's queries/disclosures.
Losing just one inventory grant resets only that inventory; equivalent capability
documents and same-owner inventory updates retain state. No search or disclosure
is persisted, and navigation/filtering makes no additional Agent read or write.

## Executed offline checks

Environment: Linux Flutter widget renderer, Flutter 3.47.5 / Dart 3.13.4,
existing lockfile unchanged.

- `dart format lib/features/tools/screens/tools_screen.dart test/features/tools`
- `flutter test --no-pub test/features/tools --concurrency=1`: 41 passing tests.
  Covers tabs, independent query/clear behavior, refresh and stale completions,
  actual channel delayed reads, denied inventory grants, owner changes including
  same-frame roundtrips, disclosure retention through filtering/tab visits, and
  keyboard Tab/Enter operation at 390/1280 logical pixels with 200% text.
- `flutter analyze --no-pub`: one existing warning outside this scope at
  `lib/core/hermes/local_discovery/local_hermes_home_discovery.dart:21`
  (`unawaited_return_in_try_block`); no Tools diagnostic. The unchanged baseline
  source returns that Future inside the try block as well.
- Optional reproducible widget captures:
  `TOOLS_CAPTURE_DIR=<existing-private-directory> flutter test --no-pub test/features/tools/tools_screen_test.dart --plain-name 'keyboard tabs preserve disclosure'`.
  Captures load SDK Roboto and MaterialIcons, render the real screen and write
  only to the explicitly supplied private directory. Ordinary tests retain the
  standard test font/theme. Captures at 390/1280 × 900, 200% text were inspected:
  tabs, status wrapping, disclosure and tool chip remain contained. At 390 the
  long search label uses Material's ellipsis; its full accessible label remains
  covered by the semantic tests. No screenshots are committed.
- `git diff --check`.

These are deterministic widget/layout checks, not compiled browser, native-device,
screen-reader, live Agent inventory or end-to-end qualification. No shared service
was started or changed. Canonical integration and remote delivery are separate.
