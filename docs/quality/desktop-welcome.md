# Desktop-guided welcome

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card t_9f4e6557 implements PORT-DESKTOP-WELCOME; CONNECTION-PATHS remains open.

## Behavior

Fresh `/hermes` launch resolves secure saved ownership before exposing the shell.
Empty storage shows the settled Hermes emblem, eyebrow, title, subtitle, Get Started,
SSH and Remote choices. Get Started selects the existing Local connection form;
SSH uses an already established external trusted tunnel; Remote uses the existing
explicit Agent endpoint form. Optional installation and pairing remain secondary.
Cancellation returns to welcome without saves or Agent mutations. Successful secure
connection admission returns to `/hermes`. Saved-owner launch bypasses welcome.
Unreadable secure storage stays explicit and retryable rather than pretending empty.

## Reference and deviations

Read-only Desktop revision `withdrawn reference revision`:
`src/renderer/src/screens/Welcome/Welcome.tsx:405-437` and
`src/renderer/src/components/common/OnboardHero.tsx:129-158` define the hierarchy
and emblem. The settled emblem is rasterized from those verified SVG paths.
Desktop itself was NOT_RUN; reference evidence is verified source/assets, not
an invented Desktop screenshot. Wing renders were inspected at 390/1280px,
normal and 200% text. Emblem/title/primary/secondary hierarchy is visible; compact
200% text scrolls, wraps secondary buttons and keeps keyboard actions reachable.

Intentional deviations: Hermes Wing branding instead of HERMES ONE; static settled
hero and adaptive theme instead of flying introduction/aurora/starfield; truthful
running-Agent hint instead of an automatic installer promise; external tunnel
instructions instead of managed SSH/key handling; optional setup disclosure.
The welcome connection page deliberately avoids SelectionArea: compiled Chromium
showed its root selection focus swallowed keyboard Back activation. Other shell
routes retain their existing selectable presentation. Explicit cancellation is
bound to the welcome entry only. No transport, upstream, credential, management,
or profile-authority contract changed.

## Executed evidence

All commands ran in the Wing-only isolated candidate under
`.task-evidence/t_9f4e6557/app`. The original baseline manifest includes dirty
prerequisites, dependency/lockfile hashes; final manifest identifies actual inputs.
Toolchain: Flutter 3.44.2 / Dart 3.12.2, Node 26.7.0, Linux x86_64;
Chromium executable `chromium-1234/chrome-linux64/chrome` (existing user cache).
Exact commands, exit codes, durations and failed iterations are retained in
`.task-evidence/t_9f4e6557/checks.jsonl` and named logs.

- `timeout 120s flutter gen-l10n`: pass; generated outputs copied unchanged.
- Changed-Dart `dart format`: pass; exact paths in checks.jsonl.
- `timeout 3m flutter analyze`: pass, no issues (final-analyze-2).
- `timeout 5m flutter test --concurrency=1 test/router test/features/enrollment/hermes_direct_first_run_test.dart test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/shared/widgets/app_shell_test.dart -r expanded`: pass, 41 tests (final-widgets).
- `timeout 10m flutter build web --release -t lib/main_e2e.dart`: pass (final-build).
- `CHROME_EXECUTABLE=<home>/.cache/ms-playwright/chromium-1234/chrome-linux64/chrome NODE_OPTIONS=--max-old-space-size=2048 timeout 10m npx playwright test playwright/tests/regression/desktop-welcome.spec.mjs --workers=1`: pass, four journeys (browser-qualified).

Compiled journeys exercise all entry-mode keyboard choices and cancellation,
401 visibility/redaction, no automatic retry, explicit retry, connected canonical
session content, and saved-owner reload. Request receipts assert zero Agent
mutations and zero Wing Link management requests. No inference or spending occurs.
The normal read sequence is direct Agent capabilities/session/history. Widget
checks also prove no Wing Link credentials saved and exact current-owner fences.
Screenshots and four request receipts remain in the compact evidence directory.
Build emits existing flutter_tts Wasm dry-run and Cupertino font warnings;
qualification is JavaScript Chromium, not Wasm or native desktop.

## Attribution and remaining work

Existing shared dirty edits were hash-matched before applying only this card's
baseline-relative delta. Shared main/index and prior owners' edits are preserved.
The local review branch carries clean/new files directly and an integration patch
for pre-existing dirty prerequisite files; that patch, not their whole dirty
contents, is attributed to this worker. Apply it only after assembling the recorded
prerequisites with `git apply --unidiff-zero`; hash-check those prerequisites first.
The qualified candidate fingerprint, not the branch alone, describes
runtime evidence. No protected-main delivery is claimed.

Remaining: PORT-DESKTOP-WELCOME-RECOVERY, broader local setup/live authentication,
managed SSH, actual native/platform qualification, independent review and
protected-main integration. No owner questions; reference-backed defaults applied.
