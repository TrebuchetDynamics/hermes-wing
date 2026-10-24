# Connection primary entry acceptance

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card: `t_22ea1211`; ledger task: `CONNECTION-PRIMARY-ENTRY`; goal: `CONNECTION-PATHS`.
Source base: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784` with preserved dirty predecessor work.

## Delivered boundary

Production Chat and Add Hermes share the existing connection form. Its primary
choices are now local, ssh, remote, in that order. VPN is a nested Remote
subchoice, with an indented border and accessible container. Activating Remote
while VPN is selected preserves that selection. Connecting disables both levels.
The existing mode-selection, endpoint persistence, authentication, channel,
capability and local-setup contracts are unchanged. No managed SSH, subprocess,
bootstrap, new protocol, credential migration or shadow domain state was added.

Existing localized labels are deliberately retained: “This device”, “SSH tunnel”,
and “Remote HTTPS”; Remote also contains “Remote HTTPS” and “VPN / NetBird /
Tailscale”. Exact shortened Local/SSH/Remote wording is a wording-only remaining
delta, not a functional grouping gap. English ARB and generated localizations
remain excluded because they are owned by interactive predecessor work.
SSH retains the explicit instruction to start a trusted tunnel outside Wing and
supply its local Agent URL. Network location does not grant authorization.

## Acceptance and executed checks

All commands ran in the project checkout. Tests and builds ran sequentially.

- `dart format --output=none --set-exit-if-changed lib/features/hermes_chat/screens/state/hermes_chat_layout.dart test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart`
  passed: three files, zero formatting changes.
- `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart`
  passed: 13 tests. At 390 and 1280 logical pixels the new production-composed
  widget journeys verify exactly three primary identities, Tab/Space operation,
  VPN selection, truthful external SSH instructions, loopback form default,
  existing local setup navigation and public cancel/back. The real
  `HermesApiChannel` owner remains identical, profile `default` and session `keep`
  are preserved, no extra Agent requests or endpoint saves/clears occur. Only
  deterministic transport and host inspection are substituted. Existing typed
  authentication recovery and superseded connection checks also pass.
- `flutter analyze` passed: no issues.
- `flutter build web --release -t lib/main_e2e.dart` passed: fresh `build/web`.
  Non-fatal existing flutter_tts WebAssembly dry-run and missing Cupertino font
  warnings remain; this is a JavaScript web build, not Wasm qualification.
- Fixture server: `PORT=8977 HERMES_E2E_PORT=8978 node serve_web.mjs`.
  `curl --fail --silent --output /dev/null http://127.0.0.1:8977/` passed.
- `CHROME_EXECUTABLE=/usr/bin/chromium WING_APP_URL=http://127.0.0.1:8977/ NODE_OPTIONS=--max-old-space-size=2048 npx playwright test --config=playwright.config.mjs playwright/tests/regression/connection-primary-entry.spec.mjs --workers=1 --output=.dart_tool/connection-primary-entry/browser`
  passed: four compiled Chromium journeys. Each traverses all primary choices
  and both Remote transports, checks disclosure and connects via public controls;
  selected connect modes cover Local, SSH, VPN and Remote. Compact and wide
  layouts restore authoritative synthetic history and profile/session owner.
  Rename cancel and unsaved endpoint edits followed by browser Back preserve
  the persisted owner. Fixture counters and observed Agent traffic show zero
  mutations; no page errors. Web does not offer privileged native local setup.
- `git diff --check -- lib/features/hermes_chat/screens/state/hermes_chat_layout.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart`
  passed; the final isolated task commit additionally receives a full scoped
  diff check including new files.
- `python ~/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo>`
  passed before final supported task/evidence/render updates; repeated afterward.

Logs and per-journey synthetic JSON receipts are retained under
`.dart_tool/connection-primary-entry/`. Large task-created web build output is
removed after acceptance. A first server attempt at 8877 failed with EADDRINUSE;
its existing owner was not stopped. An initial Playwright invocation lacked its
bundled browser and failed before any test ran; using installed system Chromium
resolved that prerequisite without installing packages.

## Reference, ownership and limits

Read-only reference locations were confirmed and their AGENTS.md inspected:
Agent `hermes-agent/` at `158fd638da1629c8e62caf9ade1515d162def8ab`;
Desktop `withdrawn source citation` at `withdrawn reference revision`.
Desktop Welcome uses local/ssh/remote identities; its managed SSH and remote
OAuth are not implemented or claimed here. Wing callers were traced through
`HermesAddScreen`, shared Chat layout, `_selectConnectionMode`, connection
controller and nearest auth-recovery tests. No upstream repository was edited.

Only the connection-grouping layout hunk, two focused Dart test files, the new
Playwright spec and this receipt belong in the local card branch commit. The
pre-existing `requireExplicitSelection` model-picker layout hunk is explicitly
excluded. Other dirty files, localization, fixture repairs, Wing Link, and ledger
wholesale changes are excluded. Ledger updates use goals.py only.

Exercised: Flutter widget environment (Linux target override for local inspection)
and fresh compiled web in deterministic Chromium. Native desktop interaction,
real SSH forwarding/authentication, live Agent API, physical Android, native
installation, remote OAuth and deployment are NOT_CHECKED. No credentials,
private endpoints, inference, gateway restarts or device changes were used.

Questions: none. Reversible grouping default applied; review approval follows
native same-card handoff and is not an implementation gate.

## UI-DRIFT-REPAIR-001: current connection journey repair

Retry baseline: `c26b43ea72b9acceb87351e235e65d508ce0e9ab`. Commit `b2ba738c`
already repaired the three-choice chooser's Advanced navigation. That journey
passes alone on the untouched baseline. General connection help and both SSH
remember-consent journeys still fail alone: zero passes and one failure each.
These are expectation drift from `588718f8`, which intentionally hid optional
Agent port/profile under Advanced and omitted general help in SSH, not product
regressions. The [route contract](../product/routes.md) already describes the
compact form. Reproduction commands (each run separately):

```bash
flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart --plain-name 'Add Hermes groups VPN within three primary connection choices'
flutter test --no-pub --concurrency=1 test/features/hermes_chat/widgets/connection_information_help_dialog_test.dart --plain-name 'production chooser offers safe selectable connection help'
flutter test --no-pub --concurrency=1 test/features/hermes_chat/widgets/ssh_quick_connect_test.dart --plain-name 'first verified connection remembers only with explicit consent: false'
flutter test --no-pub --concurrency=1 test/features/hermes_chat/widgets/ssh_quick_connect_test.dart --plain-name 'first verified connection remembers only with explicit consent: true'
```

The repaired help journey retains selectable text, sanitized clipboard, keyboard
activation and automatic focus return in Local/Remote, and explicitly requires
help to be absent in SSH. Both remember cases open Advanced through its rendered
header, verify the reviewed host pin, forward the exact `demo` profile, and persist
only with consent. The hidden-profile and secret-obscuring assertions remain.
Platform restoration, widget unmount and fixture-owned controller/channel disposal
are failure-safe. No production, Agent, credential or trust behavior changed.
Independent read-only review found no actionable issues.

The final focused check passes **28 tests, zero failures**:

```bash
flutter test --no-pub --concurrency=1 test/features/hermes_chat/widgets/ssh_quick_connect_test.dart test/features/hermes_chat/widgets/connection_information_help_dialog_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart
```

Locked preparation, `dart format --output=none --set-exit-if-changed lib test`
(602 files unchanged), `flutter analyze --no-pub`, task-store validation and
whitespace checks pass. The broader command completes, but is **not green**:

```bash
autowork-run timeout 1700 flutter test --no-pub --concurrency=1 test/features/hermes_chat/
```

Result: **2,037 passes, four failures, zero skips**, exit 1. All four are the
untouched `hermes_reasoning_disclosure_accessibility_test.dart` (200% text) and
`hermes_reasoning_disclosure_adaptive_test.dart` keyboard-roundtrip cases, each
at initial widths 390.0 and 1280.0. Each also fails alone on untouched `c26b43ea`
before this repair, at its initial collapsed-summary assertion. Commit `0d15a9b4`
added live-preview preferences; these unrelated expectations are not changed here.
The retry's held-integration failures therefore also exist in its current base.

The retained main-evidence bundles were inspected in place. `ee7ba740` records
4,218 passes, nine skips and four connection failures; `c26b43ea` records 4,268
passes, nine skips and seven failures (three connection, four reasoning). Both
exit 1, with empty isolated-rerun logs and no flaky history. They contain Dart
execution, not browser qualification. The five retained bundles do not include
the older claimed `69e2a8dd` pass; it cannot establish either cluster's provenance.
No full unchanged Dart suite was run by this worker; the coordinator owns that gate.

Exercised: Flutter 3.44.2/Dart 3.12.2 widgets on Linux, including Android/Linux
target overrides. [Cluster B](chat-workspace-overlay-browser.md#ui-drift-repair-001-settings-picker-navigation)
has separate deterministic Chromium results. Native SSH, physical devices and
live Agent/provider qualification remain outside this repair.
