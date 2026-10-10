# Explicit Remote authentication and save retry

Card: t_96242625. Bounded subtask: CONNECTION-REMOTE-AUTH-STORAGE-RETRY,
goal CONNECTION-PATHS. Parent workflow and setup/auth matrix remain incomplete.

## Delivered behavior

Cleartext consent is fenced by form intent, conversation owner generation, channel
and directory identity. Editing away and returning does not renew old consent.
Successful connect and confirmed persistence are distinct: an uncertain save keeps
the connected channel and editable draft, announces generic localized feedback,
and requires an explicit Add Hermes retry. Pending saves disable the current
intent's Add Hermes action. Late success/error cannot close, refresh or disconnect
a replacement owner. No Agent/Wing Link protocol or transport policy changed.

The E2E-only entrypoint adds bounded fail-next/deferred storage controls with
counters only. Production main does not import this entrypoint. Successful browser
retries call the existing secure endpoint implementation; injected faults are not
physical keychain qualification. Runtime imports remain ordinary Flutter modules,
covered by the fresh JS web compilation; no CLI packaging changes are involved.

## Acceptance mapping

1. Public widget tests: 18 passing cases in
   test/features/hermes_chat/screens/hermes_chat_remote_connection_retry_test.dart.
   Authentication rejection is sanitized, persistence failure retains the connected
   draft, and one explicit retry admits one connect/save. Cancellation, edit-return,
   origin-return, session-return, channel replacement and disposal reject old
   consent; delayed success/error cannot mutate replacement ownership.
2. Four fresh-build Chromium journeys pass at 390 and 1280 pixels. They cover auth
   rejection, injected save rejection, explicit retry, persisted synthetic hosts
   with identical default (unscoped/null) profile and session labels, and deferred
   save with authoritative replacement connection. Counters assert no Agent
   mutations/page errors. The replacement event uses the existing E2E channel seam;
   draft edits, initial connects and retries use public controls. Reload between
   adding hosts resets E2E save counters; receipts preserve first-page counters.
3. Focused suites, format, analyzer, localization regeneration and diff checks pass.
   Shared dirty-worktree behavior was tested; local card commit is scoped separately
   from predecessor rename/remove, primary entry, transcript, shell and voice edits.

## Executed checks

All passing checks below returned exit 0:

- timeout 4m flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_remote_connection_retry_test.dart (18 tests).
- timeout 4m flutter test --concurrency=1 test/core/hermes/setup/hermes_endpoint_store_test.dart test/core/hermes/setup/secure_hermes_endpoint_store_test.dart test/features/hermes_chat/controllers/hermes_connection_form_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_saved_connection_workflows_test.dart test/features/hermes_chat/screens/hermes_chat_remote_connection_retry_test.dart (88 tests).
- timeout 4m flutter test --concurrency=1 test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart test/features/hermes_chat/gateways/hermes_directory_lifetime_test.dart (58 tests).
- dart format --output=none --set-exit-if-changed lib/features/hermes_chat/screens/hermes_chat_screen.dart lib/features/hermes_chat/screens/state/hermes_chat_connection.dart lib/features/hermes_chat/screens/state/hermes_chat_layout.dart lib/main_e2e.dart test/features/hermes_chat/screens/hermes_chat_remote_connection_retry_test.dart (zero changes).
- timeout 4m flutter analyze (no issues).
- flutter gen-l10n.
- timeout 8m flutter build web --release -t lib/main_e2e.dart (JS build succeeds; existing flutter_tts Wasm dry-run/font warnings remain).
- CHROME_EXECUTABLE=/usr/bin/chromium WING_APP_URL=http://127.0.0.1:19877/ timeout 8m npx playwright test --config=playwright.config.mjs playwright/tests/regression/remote-connection-retry.spec.mjs --workers=1 --output=build/t_96242625-browser (4 passed).
- git diff --check.

Earlier browser attempts failed honestly: occupied port 8877, missing default
Playwright executable, incorrect capabilities fault path, exact-text selectors
against merged Flutter semantics, same-document navigation instead of fresh
entry, directory presentation after saving a second host, assumed default profile
ID instead of authoritative null, and expired bounded server lifetime. Harness
fixes use /v1/capabilities, accessible group names, fresh page entry, All chats,
and equality with the first host's authoritative profile identity.

## Visual and qualification limits

Inspected actual rendered failed-save screenshots at both widths. Feedback wraps
readably without truncation; wide layout shows Add Hermes immediately below it.
Compact layout requires scrolling to Add Hermes, which the passing journey does.
Screenshots contain synthetic loopback endpoints only and are retained in
`~/.hermes/cache/scratch/t_96242625/`, not committed. Redacted receipts and
source fingerprints are retained beside this report in remote-connection-retry/.

Linux-hosted Chromium is the exercised target. Native desktop secure storage,
real credentials/live Agent, Android, OAuth and physical keychain behavior are
NOT_CHECKED. Remote continues to offer an Access token, not OAuth; no new OAuth
support is implied or implemented. Full repository test gate is NOT_CHECKED.
No new owner decision is required. Defaults: existing contracts and UI conventions.

## Round-one review correction

The unconditional storage banner previously claimed that the token was stored and
could never be shown after connecting. Replaced that completed-save assurance with
policy wording: saving uses secure device storage; connecting alone does not
confirm that the token was saved. No recovery/ownership implementation changed.
The failed-save public widget now enters a non-empty synthetic credential and
proves that it remains in the draft without announcing successful storage, then
explicitly retries. The focused test failed before the copy fix (exit 1), and all
88 focused tests pass after regeneration. The 58 directory tests also pass.

Fresh `timeout 8m flutter build web --release -t lib/main_e2e.dart` passed, followed
by `CHROME_EXECUTABLE=/usr/bin/chromium WING_APP_URL=http://127.0.0.1:19877/ timeout 8m npx playwright test --config=playwright.config.mjs playwright/tests/regression/remote-connection-retry.spec.mjs --workers=1 --output=build/t_96242625-rework-browser`
(4 passed). Browser assertions now require the policy banner and reject the old
assurance at both widths. An initial assertion failed because Flutter merges this
text into a group name; the corrected locator uses the observed semantics.
The compact capture now scrolls the actual Flutter surface with a wheel event:
both the full recovery notice and retry button are visible alongside the policy.
Inspected compact and wide captures; policy/recovery wording wraps without clipping.
The URL helper's existing compact ellipsis is unchanged and outside this fix.

`flutter gen-l10n`, `timeout 4m flutter analyze`,
`dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_remote_connection_retry_test.dart`,
`git diff --check` and ledger validation pass. Rework receipts and fingerprints
are retained beside this report; synthetic screenshots remain in card scratch.
Tests/build still exercise the shared dirty worktree, not the isolated card branch.
Scoped localization updates copy only the regenerated policy change and exclude
other cards' localization additions. Native storage, live Agent/authentication,
OAuth, Android and the full repository gate remain NOT_CHECKED.
