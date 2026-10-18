# Desktop Settings composition port

## Reference and scope

Read-only official reference: Hermes Agent `d923a5eb48`,
`apps/desktop/src/app/settings/index.tsx`, `primitives.tsx`,
`appearance-settings.tsx`, and
`apps/desktop/src/app/overlays/overlay-split-layout.tsx`.
Wing base: `fc54c07a`. No Agent changes.

Desktop organizes Settings with a category rail and a single detail pane. The
rail becomes a category dropdown in a narrow panel; settings use consistent
label/control rows, not unrelated cards. This change implements that composition
for Wing's existing controls, without exposing unimplemented Desktop settings.

## Mapping and deliberate differences

| Category | Existing Wing outcomes retained |
| --- | --- |
| Appearance | System/Light/Dark and the same five accent palettes; existing local preference providers and storage keys |
| Chat | Platform spellcheck when supported; Voice & speech opens the unchanged detail route |
| Connections | Existing Connections destination; live bounded connection status and unchanged diagnostics detail route |

Appearance is the initial category because Wing does not implement Desktop's
Model settings pane here. Category selection is ephemeral presentation state,
not an Agent configuration or a new persisted preference. The route shell,
shortcut handling and detail screens remain unchanged. Desktop's complete
category catalog, settings search, breadcrumb/deep-link parameters, and privileged
configuration/import/export operations are not ported or simulated.

The 208px rail uses the available panel width. At narrow widths or large text it
becomes a labeled native dropdown. Controls stack using their actual pane width;
theme segments become vertical when needed. Compact category selection owns the
heading rather than repeating it in the body. Native focusable controls and
traversal groups preserve keyboard access. SafeArea reserves system-navigation
space, and the detail pane scrolls independently.

## Executed verification

Toolchain: Flutter 3.47.5 / Dart 3.13.4. `flutter pub get --offline
--enforce-lockfile` passed; no lockfile change.

- `dart format --output=none --set-exit-if-changed lib/features/settings/screens/settings_screen.dart test/features/settings/settings_screen_test.dart`: passed.
- `flutter test --no-pub --concurrency=1 test/features/settings test/theme/wing_theme_test.dart`: **59 passed**, final source, no capture harness included.
- `flutter analyze --no-pub lib/features/settings/screens/settings_screen.dart test/features/settings/settings_screen_test.dart`: passed, no issues.
- `flutter analyze --no-pub`: one existing warning in
  `lib/core/hermes/local_discovery/local_hermes_home_discovery.dart:21`
  (`unawaited_return_in_try_block`); unchanged from the base source.
- `git diff --check`: passed.

Regression coverage exercises category navigation, absence of overview cards,
all existing controls, preference persistence, 320×700 and 1200×800 at 200% text,
scroll reachability, bottom safe-area geometry, and Tab/Enter activation of
categories and all three destination links. Removing bottom SafeArea protection
in an isolated reversible negative control failed on viewport bottom
700 versus required 676; the restored source passes.

A private temporary widget harness rendered all three categories at desktop
1200×800/100% and phone 320×700/200%. Appearance desktop and Chat phone were
visually inspected with readable SDK Roboto substituted only for capture text
styles (including ListTile styles). Production theme was not changed. Material
icon fonts were not loaded in that harness, so square fallback glyphs are a
capture limitation, not icon qualification. Captures/harness are not committed.
No native device, browser or live Agent/provider qualification is claimed.

## Integration follow-up

`test/router/settings_routes_test.dart` still assumes every overview link is
present immediately. Its existing test fails before navigation at line 54 because
Voice now belongs to Chat. The integration owner must select Chat before its
Voice assertions and Connections before its diagnostics assertions, preserving
the current return/persistence coverage. This file was outside this worker's
exclusive scope. The new Settings test already verifies actual push/pop and
keyboard destination activation against the new organization.

An earlier parallel test invocation had one test-process load failure
(`Connection closed before test suite loaded`); the final serial 59-test run above
passed. Initial broad tests exposed stale category assumptions and missing picker
semantics; picker identity and compact heading ownership were corrected, and the
existing appearance tests now pass unchanged.
