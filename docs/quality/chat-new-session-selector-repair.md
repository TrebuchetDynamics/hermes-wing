# Chat new-session browser selector repair

Card: `t_4df15a47`. Implementation evidence; independent native same-card review
is requested after the local commit. This is only the browser harness slice of
`FIX-NPM-AUDIT`; that task remains open and `SECURITY` remains partial.

## Delivered

Both smoke and speech regressions now select Chat's exact, case-sensitive
`New session` button rather than also matching the shell's `New Session`.
The speech test runs at 1280px and 390px and retains the compact `More actions`
→ exact `New session` menu item fallback. No positional selector, hidden callback
for session creation, assertion removal, production change, or dependency edit
was introduced.

The rendered RED diagnostics expose both button identities. Current callers are
`lib/features/hermes_chat/screens/hermes_chat_screen.dart:1654-1664` (Chat button),
`:1666-1701` (compact menu), and
`lib/features/hermes_chat/widgets/shell_session_access.dart:221-227` (shell button).
Chat invokes `_createSession`; the shell uses its separate `_activate` owner and
navigation checks. Neither production path changed.

## Executed acceptance evidence

Commands ran from the repository root. One fresh deterministic target was used
for RED, focused GREEN, and the complete affected suites.

1. `flutter build web --release -t lib/main_e2e.dart` — exit 0.
   Existing flutter_tts Wasm dry-run and missing Cupertino font warnings remain;
   this qualified the default JavaScript target, not Wasm.
2. Fixture server: `PORT=18977 HERMES_E2E_PORT=18978 node serve_web.mjs`.
   `curl --fail -s -o /dev/null http://127.0.0.1:18977/` — exit 0.
   The initially attempted 8877/8878 pair belonged to other Python listeners;
   no existing listener was terminated or changed.
3. `NODE_OPTIONS=--max-old-space-size=2048 CHROME_EXECUTABLE=/usr/bin/chromium WING_APP_URL=http://127.0.0.1:18977/ npx playwright test playwright/tests/regression/hermes-smoke.spec.mjs playwright/tests/regression/chat-tts.spec.mjs --workers=1 --retries=0 --grep 'Hermes route renders connected|Agent speech stops when starting'`
   — RED exit 1, both original flows failed with the same two-button strict
   collision. After selection repair: exit 0, all three cases passed (including
   the additional compact speech case). Focused GREEN preceded indentation-only
   cleanup; the complete suite below exercised the final source bytes.
4. `NODE_OPTIONS=--max-old-space-size=2048 CHROME_EXECUTABLE=/usr/bin/chromium WING_APP_URL=http://127.0.0.1:18977/ npx playwright test playwright/tests/regression/hermes-smoke.spec.mjs playwright/tests/regression/chat-tts.spec.mjs --workers=1 --retries=0`
   — exit 0, 28 passed, no skips or retries. Existing fixture resets remain.
   Smoke verifies a new session heading, empty conversation, subsequent reply
   and approval flows. Both speech widths verify a new session heading,
   increased pause count, removed Stop speaking control, the stopped-speech
   notice, and a second playback with the expected new-session spoken reply.
5. `node --check playwright/tests/regression/hermes-smoke.spec.mjs` and
   `node --check playwright/tests/regression/chat-tts.spec.mjs` — exit 0.
   No repository JavaScript formatter is declared; edited code follows adjacent
   formatting. No Dart source changed; Dart formatting/analyzer/tests were not
   required for this harness-only change.
6. `git diff --check` — exit 0.

Logs are retained under `.pi/t_4df15a47/`: `build.log`, `red.log`,
`green-focused.log`, `green-suites.log`. The task-owned fixture server is stopped
and the newly generated `build/web` target is removed after verification.

Source base: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`, with unrelated shared-tree
changes preserved and excluded from this card's local commit.
SHA-256 fingerprints of the exercised artifact and final tests:

- `build/web/main.dart.js`: `fc523a6a52c53bc62d18bc3b8908b4cc3bf035e86b839df75e621422857380fd`
- `playwright/tests/regression/hermes-smoke.spec.mjs`: `370a24457f3a01fd9daa6800905a80904d0cd78e28c7f92e01aad0fd035c2f4e`
- `playwright/tests/regression/chat-tts.spec.mjs`: `2d1c842a2a69acc52767d399103fed157081caff29783c4c496640cf3b935f68`

## Limits

Only deterministic compiled Chromium on Linux was exercised. Live Agent,
physical/native speech, Android devices, native desktop relaunch, image builds,
installation, release and deployment are NOT_CHECKED. Browser speech recorders
are not physical audio evidence. Other browser suites were deliberately not run.

Audits were not rerun in this harness card. Prior independent review617 reports
four high, zero critical embedded Braces-chain findings; fixing these remains
separate residual work, not a claim of a clean security acceptance here.
Goal evidence is recorded through `goals.py`; shared `goals.json` and `TODO.md`
are deliberately excluded from the authored-files commit because they already
contain other owners' edits. No owner questions or new defaults are needed.
