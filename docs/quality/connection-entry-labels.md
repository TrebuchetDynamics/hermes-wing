# Connection entry labels

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


## Delivered boundary

Card `t_68412445` implements `CONNECTION-ENTRY-LABELS` for `CONNECTION-PATHS`.
Primary controls render exactly **Local**, **SSH**, **Remote**, in that order.
Nested **Remote HTTPS** and **VPN / NetBird / Tailscale** remain distinct controls.
Selecting primary Remote retains an already selected VPN transport.
SSH still requires a trusted tunnel started outside Wing. Wing does not create
SSH processes or manage SSH keys through this form.

Only label composition changed. Existing enum identities, URLs, authentication,
capability gates, channel ownership and setup routing remain unchanged. Agent
traffic stays direct. No Wing Link operation or upstream source was changed.
HD-ENTRY remains partial: native bootstrap, managed SSH and remote OAuth are not
qualified by this slice.

## Acceptance evidence

1. Exact primary labels and order are asserted on rendered ChoiceChip text at
   390px and 1280px. Browser semantics assert five uniquely named controls:
   Local, SSH, Remote, Remote HTTPS and VPN / NetBird / Tailscale.
   Real Tab traversal and Space activation exercise every primary control and
   both nested transports. Primary Remote retains VPN selection.
2. Widgets exercise local setup inspect/routing, cancellation and Back while
   retaining the same production channel state, default profile and exact session.
   They assert unchanged requests, zero endpoint saves and zero credential clears.
   SSH disclosure still requires an external fixed tunnel and forbids arbitrary
   SSH commands/key storage. Four browser journeys connect through public controls,
   restore canonical synthetic history, cancel rename and Back out of unsaved edits.
   Persisted ownership is identical and fixture/observed mutation counts remain zero.
3. The exact-label regression was run before production edits. It failed at both
   widths with This device / SSH tunnel / Remote HTTPS instead of Local / SSH /
   Remote. After localization regeneration, the focused widget suite and fresh
   compiled Chromium journeys pass. Logs and SHA-256 source fingerprints are in
   `.dart_tool/connection-entry-labels/`; no unrelated full-suite pass is claimed.

## Executed checks

Commands ran from the repository root. Each listed successful command exited 0.
Logs retain full output rather than a synthesized result.

- RED: `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart`
  exited 1, two expected exact-label failures; `widget-red.log`.
- `flutter gen-l10n` passed; `localization.log`. Generated localization was not
  hand-edited. Existing predecessor keys remain present.
- `dart format lib/features/hermes_chat/screens/state/hermes_chat_layout.dart lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart`
  passed; `format.log`.
- `dart format --output=none --set-exit-if-changed lib/features/hermes_chat/screens/state/hermes_chat_layout.dart lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart`
  passed, zero changes; `format-check.log`.
- `flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart`
  passed, 13 tests; `widget-green.log`.
- `flutter analyze` passed, no issues; `analyze.log`.
- `flutter build web --release -t lib/main_e2e.dart` passed; `build.log`.
  Existing flutter_tts Wasm dry-run and Cupertino font warnings remain. This is
  JavaScript release compilation, not Wasm qualification.
- `PORT=19077 HERMES_E2E_PORT=19078 NODE_OPTIONS=--max-old-space-size=2048 node serve_web.mjs`
  started the owned deterministic server after both ports were checked unused.
  `curl --fail --silent --output /dev/null http://127.0.0.1:19077/` passed.
- `CHROME_EXECUTABLE=/usr/bin/chromium WING_APP_URL=http://127.0.0.1:19077/ NODE_OPTIONS=--max-old-space-size=2048 npx playwright test --config=playwright.config.mjs playwright/tests/regression/connection-primary-entry.spec.mjs --workers=1 --output=.dart_tool/connection-entry-labels/browser-accepted`
  passed, four journeys; `browser-accepted.log` and four synthetic JSON receipts.
  Selected connection modes cover Local, SSH, VPN and HTTPS across both widths.
  Earlier test-harness runs failed: DOM focus needed frame synchronization and
  the restored wide shell includes 50 additional session controls. Traversal now
  has a rendered-control-derived bound and 180-second test deadline, with zero
  retries. No assertion or keyboard activation was removed. Earlier failure logs
  remain in `browser.log`, `browser-green.log` and `browser-final.log`.
- `git diff --check` passed.
- Supported `goals.py task/evidence/render/validate` updates record this bounded
  implementation. CONNECTION-PATHS remains partial with saved-workflow and exact
  owner-reconnect follow-ups. No second feature or board card was dispatched.

## Reference and ownership

Read-only Desktop reference is `withdrawn source citation` at
`withdrawn reference revision`. Its AGENTS.md was read.
Welcome.tsx exposes local bootstrap and SSH/Remote panels. Exact shortened
Local/SSH/Remote terminology comes from the owner's matrix and CONN-1, not a
claim that Desktop Welcome renders those exact three strings.
Wing label callers and the nearest auth-recovery assertion were traced before
editing. Local/SSH label keys are used only by this form. The existing Remote
HTTPS key remains for the nested choice; a separate primary Remote key prevents
accidental relabeling of both levels.

The worktree was already dirty. This card owns two existing ARB value edits, one
new primary Remote key, generated localization for those changes, primary label
composition and nested group semantics, exact widget assertions and the focused
browser spec updates. Predecessor grouping, composer, voice, model, disclosure,
fixture and unrelated changes are preserved. The shared layout is a collision
hotspot; its full Git diff is not this card's patch. Source fingerprints identify
the tested snapshot, not ownership of all its contents.

Exercised: Flutter widgets on Linux host (Linux target override for setup), and
fresh compiled deterministic web in installed Chromium. Native desktop UI,
physical Android, live Agent authentication/chat, real SSH, OAuth, installation,
packaging, deployment and release are NOT_CHECKED. No real provider, private
endpoint, secret, personal device or upstream/runtime mutation was used.

Applied the project's STE-inspired writing profile to changed prose. Scoped
meaning and local links were reviewed; full ASD-STE100 dictionary compliance was
not verified. Questions: none. Default applied: distinct primary Remote wording
with unchanged nested HTTPS/VPN and external-tunnel behavior. Same-card native
review is the final step of this card's goal; approval follows the handoff.
