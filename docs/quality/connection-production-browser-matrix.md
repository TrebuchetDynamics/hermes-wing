# Production connection browser matrix

Task: CONNECTION-PRODUCTION-BROWSER-MATRIX. Goal: CONNECTION-PATHS.
Card: t_b47919e4. This narrows browser composition qualification; it does not close
CONNECTION-SETUP-AUTH-MATRIX or CONNECTION-SAVED-WORKFLOWS, or claim main delivery.

## Implemented increment

`lib/main_connection_production_matrix_e2e.dart` composes the actual `WingApp`,
production router, enrollment/welcome, Add Hermes form, contacts and saved editor.
Only external boundaries are overridden: a typed synthetic LocalWingLinkHost,
Agent fixture and endpoint-store failure/delay controls. It is not a replacement
chooser/router. Existing Remote and saved-editor specs are executed again against
this same compiled entrypoint, not counted from older receipts.

A shared `localLinuxSetupAvailableProvider` seam is used by enrollment and the
local route guard. Its production default remains native Linux only; web builds
cannot install/adopt Hermes. The qualification entrypoint deliberately enables it
for the typed fake host. The setup controller's existing generation fences remain
unchanged. No actual installer, service, gateway or provider was operated.

The browser exposed a product accessibility defect: an unfocused SelectableText
exported the authentication explanation as an empty disabled textbox. The nearest
regression failed before the fix (`auth-red.json`, exit 1), then passed. A labeled,
child-excluding Semantics wrapper now exports the complete explanation as static
text while retaining selection and the existing keyboard Focus wrapper. No OAuth
implementation, detection claim, transport contract or credential change was added.

## Acceptance mapping

1. Four production-welcome cases: 390/1280 widths, 200% Flutter text, missing and
   existing installation. Public optional setup controls open the real setup screen;
   consent Cancel starts nothing; Stop fences late success; failed setup requires
   explicit Check again; Back disposes pending setup and late success cannot select
   pairing. Public Get Started reaches direct Local; public Remote mode reaches
   direct Agent use. Each journey ends with exactly 3 inspections, 3 setup attempts,
   2 cancellations and one completed direct save. No inspection triggers setup replay.
2. Four reused Remote cases: denied discovery/auth, sanitized feedback, uncertain
   save, retained form and explicit Add retry; fresh-page saved host restoration;
   two origins sharing profile/session IDs; late save settlement cannot disconnect
   replacement. Four reused saved-editor cases: keyboard edit/Test, denied/successful
   read, Cancel test with late settlement, cancelled edit, failed save and explicit
   retry, persisted draft and write-only replacement credential. Widths 390/1280,
   browser zoom 1/2 for saved-editor cases.
3. Two additional two-saved-host cases: both hosts persisted through public Add;
   colliding profile/session IDs; parked old-host discovery; authoritative replacement
   connection through the existing channel seam; old discovery released and settled;
   exact origin/profile/session/status remains replacement-owned, both saved hosts
   remain visible. Replacement itself is a channel-event seam, not a public second
   host click while discovery is pending.
4. Management is absent from saved direct endpoints. On normal matrix pages,
   management routes are additionally configured to return synthetic 403 if attempted.
   They are never requested. Actual network observations and independent persistent
   saved-editor context receipts assert zero Agent mutations, including send,
   approval and Stop, and zero management traffic. Agent-only paths call the typed
   host zero times; optional host calls are attributed separately above. No stale
   owner mutation is observed. Unsupported OAuth wording is asserted through the
   public Remote form's accessibility text, not an injected replacement widget.

## Executed checks

All checks used a frozen candidate under `.dart_tool/connection-production-matrix/candidate`.
The full source/dependency manifest was checked after execution with zero hash mismatches.
No dependency upgrade occurred. The installed Node was 26.7.0 (not the documented
Node 22 default); Flutter 3.44.2 / Dart 3.12.2 and Chromium 152.0.7977.75 were used.

- Scoped `dart format --output=none --set-exit-if-changed`: exit 0, 7 files, 0 changed.
- `flutter analyze --no-pub`: exit 0, 3.18 seconds.
- `flutter test --no-pub --concurrency=1`: exit 0, 64 tests, 67.95 seconds. Targets:
  `test/integration/connection_production_matrix_fixture_test.dart`,
  enrollment/local setup, Remote retry, saved edit, router transitions and Remote
  explanation. Exact target command is retained in `regressions-final.json`.
- `flutter build web --release --no-pub -t lib/main_connection_production_matrix_e2e.dart`:
  exit 0, 50.71 seconds. JavaScript build only. Existing flutter_tts Wasm dry-run
  incompatibilities and missing Cupertino font-family warnings remain; no Wasm claim.
- `npx playwright test --config playwright/connection_production_matrix.config.mjs --workers=1 --retries=0`:
  exit 0, 14 passed, 0 skipped/flaky/unexpected, 150.94 seconds.
- Scoped `git diff --check` and integration patch reverse-apply check: exit 0.

Each heavy command was timeout-bounded; exact wrappers, durations, exits and failed
iterations are retained alongside the final results. One terminal invocation timed
out at the tool boundary without a receipt; it is not counted as a passing check.
Harness corrections included accessible-name/static-text role mismatches and
keyboard field focus instead of pointer clicks on overlapping web semantics at
200% text. Direct-form keyboard Back at 200% was not qualified by this matrix.

Frozen source fingerprint:
`f189dc8b5cb670d172cafea74348a15dc4d7cef29d02a8c8a7255d7cbd7d2381`.
Compiled JavaScript SHA-256:
`0fae3a55c458a25f7c6f186de375b9fe29e1a39029373b915159edd0af70162d`.
Lockfile hashes, versions and complete source hashes are in retained `source.json`.

## Attribution, artifacts and visual inspection

Evidence is retained in `.dart_tool/connection-production-matrix/evidence/`:
`receipt.json`, `source.json`, baseline hashes, per-command logs/receipts, Playwright
JSON, per-case boundary counters, owner/store/request receipts and actual PNGs.
Build and copied-source outputs are removed after preserving this compact evidence.
No screenshot, browser profile or build output is committed.

The scoped agent commit contains only new matrix files, this report, and
[the integration patch](connection-production-browser-matrix-integration.patch).
All five shared-file pre-card bytes were reconstructed and verified against the
recorded SHA-256 baseline before producing that patch. Foreign welcome, managed
SSH, saved-editor and recovery implementation remains outside this card's commit.
Apply the patch only after assembling its exact predecessor baseline; it is already
applied in the shared working tree. Clean main alone lacks those predecessor
uncommitted dependencies, so the commit is an attributed integration increment,
not a standalone clean-main build. The integration owner owns that assembly/gate.

Inspected actual captures: compact 200% scrolled Remote explanation (OAuth text
readable, no overlap), wide 200% setup consent (readable Cancel/Run setup), compact
2x browser-zoom saved-editor failure/retry (obscured synthetic replacement and
reachable actions), and wide two-host directory (distinct labels retained).
Long content scrolls vertically; the viewport is not a full-page screenshot.
Directory still displays Profiles while Chat is selected; that pre-existing shell
wording mismatch is not fixed or upgraded to parity by this behavior qualification.

## Remaining scope

Native Linux/Android execution, physical secure storage, live authentication,
OAuth implementation, SSH qualification, real setup and protected-main delivery:
NOT_CHECKED by this card. Previous native receipts remain limited to their own exact
sources and journeys. No live provider calls or spending. Usage/cost: UNKNOWN.

Next seam: integration owner assembles predecessor increments and this patch,
then qualifies the combined candidate and protected-main delivery. Parent connection
milestone remains partial; its live/native/integration gaps are not closed here.
Questions: none. No new architectural or irreversible default was required.
