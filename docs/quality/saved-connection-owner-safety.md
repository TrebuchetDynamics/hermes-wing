# Saved-host owner-safety qualification

Card: `t_90ae659f`. This is the first independently verifiable part of
`CONNECTION-SAVED-WORKFLOWS`, not completion of `CONNECTION-PATHS`.

## Delivered behavior

Public saved-host rename and remove controls now capture connection ownership
and form intent before opening their dialogs. Confirmation from an old owner
cannot mutate saved hosts after a channel/session ownership change. A confirmed
storage operation may finish, but it cannot clear an intervening connection draft,
including select-away-and-return. Refresh reads update saved-host metadata without
connecting, disconnecting, selecting a profile or creating a session.

Remove catches secure-storage failures and leaves the form and saved hosts intact.
Rename and remove show existing localized, generic gateway error messages, never
raw platform exception details. Retrying requires another explicit user action.
Both paths check screen lifetime before refreshing or reading Riverpod after
storage settles. The delete confirmation was moved from the chip to its screen
controller so ownership is captured before consent rather than afterward.

No Agent/Wing Link API, credential boundary, authority or mutation replay changed.
The store still owns persistence; directory health is a read, not connection
selection. The confirmation removes a device-local saved endpoint, not an
Agent-owned profile or remote data.

## Acceptance mapping

| Criterion | Executed evidence | Limit |
| --- | --- | --- |
| Name/rename and cancellation | Public chip/dialog Flutter regressions and two compiled Chromium journeys | Endpoint URL/credential editing and standalone test control are not qualified by this slice. |
| Remove cancellation and exact saved ID | Flutter cancellation/current removal tests; Chromium Delete/Cancel/Remove | No remote profile deletion. |
| Storage failure and explicit retry | Public rename/remove Flutter tests with failing fake storage | No physical keychain/keystore failure was induced. |
| Late settlement cannot clear a replacement | Deferred remove, edit-away-and-return, late rename, replacement channel/session and disposal tests | Synthetic authoritative channel events; not live two-host authentication. |
| Consent cannot survive ownership change | Public rename/remove dialogs confirmed after fake channel ownership changes | Same profile route and session label on different synthetic origins. |
| Saved versus connected readiness | Fresh compiled Chromium at 390 and 1280 px: saved online host has no selected conversation; explicit host selection restores canonical history | Synthetic transport and no credential fixture. Does not establish live authentication. |
| Existing-install/setup-needed and enrollment | NOT_CHECKED in this slice | Registered in `CONNECTION-SETUP-AUTH-MATRIX`. |
| Full Remote authentication/retry and unsupported OAuth explanation | NOT_CHECKED in this slice | Existing auth-recovery tests passed, but this is not a new complete auth/OAuth journey. No new OAuth authority was added. |
| Native/live/OAuth/device behavior | NOT_CHECKED | Browser and widget evidence must not be promoted to platform/live support. |

## Executed checks

All final commands below returned exit code 0:

```sh
dart format --output=none --set-exit-if-changed lib/features/hermes_chat/screens/state/hermes_chat_connection.dart lib/features/hermes_chat/screens/widgets/hermes_chat_error.dart test/features/hermes_chat/screens/hermes_chat_saved_connection_workflows_test.dart
timeout 10m flutter analyze
timeout 10m flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_saved_connection_workflows_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_endpoint_load_intent_test.dart test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/core/hermes/setup/hermes_endpoint_store_test.dart test/core/hermes/setup/secure_hermes_endpoint_store_test.dart test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart
timeout 15m flutter build web --release -t lib/main_e2e.dart
CHROME_EXECUTABLE=/usr/bin/chromium WING_APP_URL=http://127.0.0.1:8897/ NODE_OPTIONS=--max-old-space-size=2048 timeout 8m npx playwright test --config=playwright.config.mjs playwright/tests/regression/saved-connection-workflows.spec.mjs --workers=1 --output=.dart_tool/receipts/t_90ae659f/browser
git diff --check
python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate .
```

The focused Flutter suite passed 122 tests, including 10 new saved-host tests.
Chromium passed two journeys with retries disabled. A fresh release JavaScript
build preceded those journeys. Its Wasm dry-run reported existing `flutter_tts`
interop warnings, and the build reported a Cupertino font warning; neither is
Wasm qualification. Full repository tests, Go tests and native builds were not run.

The first compiling widget run returned exit 1 with four behavior failures:
stale form clearing, unhandled delete exception, non-generic rename error and
controller access after disposal. An initial harness compile failure was corrected
before that RED run. Analyzer initially returned exit 1 for async context guards;
explicit mounted checks repaired it. Three browser harness failures returned exit
1: same-hash navigation, the dialog's actual `Profile label` name, and a merged
chip accessible label. These were repaired from rendered semantics, not by
weakening production behavior or adding private interaction hooks.

## Source-bound receipts and render inspection

Base HEAD: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784` plus the preserved dirty
working tree. Checkout evidence is not proof of a clean-HEAD build.

Retained ignored evidence: `.dart_tool/receipts/t_90ae659f/` contains
`connection-baseline.patch`, `widget-red.log`, `widget-green.log`,
`focused-tests.log`, `analyze.log`, `web-build.log`, `browser.log`, the three
browser failure logs, `source-identity.json`, and browser JSON/pixel receipts.
The receipt fingerprints changed Dart, regression sources and `build/web/main.dart.js`.
Compiled JavaScript SHA-256:
`a428e64ee1b0d2e3fbd18a9e5c8a92b60a4d5cc103a0af467351f0df9dc43794`.

The compact and wide remove confirmations were visually inspected: saved host
name, origin, secure-storage consequence and Cancel/Remove are readable without
clipping. The wide renamed-host form was inspected; saved label and affordances
are visible. The editable connection draft retains its independently entered
label; this slice does not synchronize an existing draft to a saved-host rename.
The first attempted remove screenshot preceded the dialog frame; the retained
final run waits for the dialog and consequence text before capture.

Fixture server: bounded `node serve_web.mjs`, app/API ports 8897/8898. The
process was stopped and both ports were verified free. Task-created `build/web`
is removed after qualification; screenshots, logs and fingerprints are retained.

## Ledger and ownership

`CONNECTION-SAVED-HOST-OWNER-SAFETY` is the completed bounded ledger task.
`CONNECTION-SAVED-WORKFLOWS` remains in progress; its full acceptance is not
claimed complete. `CONNECTION-SETUP-AUTH-MATRIX` records the remaining setup,
enrollment, Remote auth/storage retry, saved endpoint edit/test and OAuth
explanation matrix. No additional board card or picker was dispatched.
`CONNECTION-PATHS` remains partial. Ledger changes use `goals.py`, including
executed evidence and rendering; TODO additions are narrowly anchored.

Hotspot: `hermes_chat_connection.dart` already contained the shared-tree
`_HermesSessionsPanel` → `HermesSessionsPanel` builder change at entry. That
one-line dependency is preserved input, not this card's implemented feature.
The baseline patch distinguishes it from the rename/remove delivery. The local
agent commit excludes that inherited hunk using an isolated commit snapshot and
the helper's temporary index; the shared worktree remains unchanged. Verification
applies to the source-fingerprinted working tree, not an independently compiled
clean agent branch. Co-owned dirty `goals.json`/`TODO.md` remain updated in place;
they are not swept into the code commit with unrelated accumulated ledger work.
The committed ledger receipt preserves this slice's exact task/evidence state.
Existing
unrelated dirty code, generated localization, Android/OmniRoute fixtures and
other owners' documentation are untouched. No new owner decision was needed.

Native same-card review is the final card handoff, not evidence of approval.
