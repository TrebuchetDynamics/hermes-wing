# Exact-owner reconnect: offline recovery increment

Task: CONNECTION-OWNER-RECONNECT. Goal: CONNECTION-PATHS.
Baseline: `7aada505772162d26be93a8eb44a2dd4e4629f5a`.
This is an isolated local candidate, not coordinator integration, publication,
native/device qualification or live Agent authentication.

Follow-through: [two session-owned tabs](chat-tab-reconnect.md) distinguishes
in-place lost-run recovery from full connection replacement and records bounded
widget/compiled-browser isolation evidence.

## Change and source authority

The existing saved-contact activation and exact-session restoration paths remain
in use. Reconnect reads Agent state; it does not create a replacement session or
replay Send, approval or Stop. No protocol, credential store, transport authority,
SSH behavior, OAuth, installer or upstream runtime was changed.

The [directory](../../lib/features/hermes_chat/gateways/hermes_gateway_directory.dart#L658)
now captures activation generation and gateway identity **before** waiting for a
queued profile selection. A choice from an abandoned connection cannot run on its
replacement, including a leave-and-return to identical host/profile/session
strings. Its cleanup clears the busy flag only if it still owns the activation
generation, so stale completion cannot reopen Retry during newer restoration.
Legitimate same-host profile choices remain serialized.

The two [directory regressions](../../test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart#L232)
failed for their respective ownership defects before production changes. They use
the production channel with delayed reads and retain saved gateway `alpha`,
profile `coder`, session `older-A`, canonical message `canonical-A` and the same
persisted selection. Queued old intent is rejected after alpha/beta/alpha, and
Retry admits **zero additional requests** while current history is pending.
The extended [Reconnect widget](../../test/features/hermes_chat/screens/hermes_chat_reconnect_owner_test.dart)
also parks history, attempts public disabled Retry, and verifies one exact
metadata read and zero mutations.

Official Desktop was inspected read-only at
`158fd638da1629c8e62caf9ade1515d162def8ab`:
`apps/desktop/src/store/connections.ts:345–550` and
`apps/desktop/src/store/connections.test.ts:313–342`. It rejects superseded queued
activation and lowers only the owning switch's barrier. Wing preserves that
ownership outcome using its existing directory generations, not Electron
internals. This is a source trace, not executed Desktop parity.

## Browser evidence and integration follow-through

The existing [production Chat journey](../../playwright/tests/regression/production-chat-journey.spec.mjs)
now asserts saved ownership and unchanged **attempted browser mutation counts**
as well as accepted Agent receipts at both Stop and transport-loss recovery.
Attempt counts include rejected duplicate approvals, which accepted receipts alone
would miss. Across each full journey there are exactly five intentional Sends,
three approval answers and one Stop; recovery adds zero writes.

Both 390/1280px receipts restore gateway ID
`aHR0cDovLzEyNy4wLjAuMToyMDExMg` (the synthetic loopback fixture), profile
`default`, session `e2e-hermes-session`, with canonical stopped/recovered history.
The six [session-restoration journeys](../../playwright/tests/regression/session-restoration.spec.mjs)
record zero mutations. They retain `synthetic-restoration-050` through reload and
Retry, or retain explicit replacement `synthetic-restoration-001` after a delayed
old-owner result. Failed-read plus Retry has two exact metadata reads total;
duplicate pending semantic Retry adds none.

The previous integration hold named an intermittent disabled Send during the
[overlay profile-switch setup](../../playwright/tests/regression/chat-workspace-overlay.spec.mjs#L91).
It did not recur in six baseline attempts here. Flutter's semantic DOM focus
precedes text-input activation (`SemanticsTextEditingStrategy.activate` in the
SDK); immediate DOM `fill` is not a draft-admission barrier. That setup now uses
the existing two-frame settled keyboard-entry pattern, checks actual focus and
draft value, and requires enabled Send before the unchanged run/owner assertions.
Its locator accommodates compact Chat dropping the placeholder name after typing.
All 42 default overlay cases pass without retries. This is a harness correction,
not a production input or new platform-support claim.

The broader Flutter gate also requires correcting two stale listener-count
fixtures: channel state and the existing SSH controller both outlive route
unmount. Their assertions now require those two persistent observers while
retaining task/dialog cleanup checks. No managed SSH implementation was changed.

## Executed checks

Linux-hosted Flutter 3.44.2 / Dart 3.12.2, Node 22.22.2, Chromium
152.0.7977.75. Final command receipts and logs are under the supplied task
`$TMPDIR`; screenshots and generated output are not committed.

- Changed Dart files: `dart format --output=none --set-exit-if-changed` — zero
  changes. `node --check` on all three changed browser modules — pass.
- `AUTOWORK_PORT_BASE=20120 flutter test --no-pub --concurrency=1 test/core/hermes/ test/features/hermes_chat/ --reporter expanded`
  — **2723 passed, 8 pre-existing opt-in real SSH cases skipped**, zero failures.
  Explicit local-serve fixture ports stayed inside the allocated range and avoided
  unrelated listeners. Existing transport unit tests also use OS-assigned
  ephemeral loopback sockets.
- `flutter analyze --no-pub` — no issues.
- `flutter build web --release -t lib/main_e2e.dart` — pass, before browser
  execution. JavaScript SHA-256:
  `121b1550214d3cb146e603885053b09e5168b0a8a58a0c63141126be9515efc2`.
  Existing dependency Wasm dry-run warnings do not qualify WebAssembly.
- `npm run web:e2e` — **89 passed, 1 opt-in live-Agent case skipped**, zero
  unexpected or flaky results across all nine default suites. The unchanged
  runner rebuilt the E2E target. A task-local `npx` wrapper redirected artifacts
  and JSON/list reporting only; no filtering or retry-policy changes.
- `npx playwright test --config=playwright.config.mjs playwright/tests/regression/session-restoration.spec.mjs playwright/tests/regression/production-chat-journey.spec.mjs --workers=1 --retries=0 --max-failures=1 --reporter=list,json --output="$TMPDIR/recovery-browser-artifacts"`
  — **8 passed**, no skipped, unexpected or flaky results, after the rebuild.
  Recovery layouts are 390/1280px wide and 1100px high; short-height connection
  form scrolling is not qualified by these journeys.

Browser fixtures used owned ports 20110/20111 and 20112/20113 and were stopped.
The long temporary-directory path used an open-directory `/proc` alias for
Chromium's Unix socket; physical temporary files stayed in the task directory.
`validated-inputs.json` binds the 554 final source/test/harness inputs.
`git diff --check`, changed-receipt local-link checks and source-fingerprint
verification pass.

## Qualification boundary

Only Linux-hosted Dart/Flutter tests and deterministic compiled Chromium journeys
are in scope. Browser layouts are not native platform tests. No personal runtime,
real credential, live provider, physical device, native secure storage, SSH tunnel,
OAuth flow or deployment was operated. Native/live reconnect and authenticated
provider behavior require separate evidence. Revalidate this receipt when the
directory generations, restoration/channel contracts, composer semantic bridge,
fixtures or dependency inputs change.
