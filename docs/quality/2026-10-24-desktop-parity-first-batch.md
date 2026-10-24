# Desktop parity: first implementation batch, 2026-10-24

This is an implementation receipt, not complete Desktop parity or release acceptance.
Implementation commit: `ad666107`. Official reference:
`NousResearch/hermes-agent@14e1e43a23761b369641208e204365cd6cb9399d`.

## Delivered

- Reject legacy provider credential Set/Remove/Validate before transport; exact
  route grants cannot satisfy the credential identity/revision/idempotency and
  effect-consent requirements. No credential input is collected. Provider reads
  and model actions keep independent authorization. The positive credential
  lifecycle remains pending; disabling unsafe callers is not that implementation.
- Apply official full-width user messages, flat assistant prose and radius-scalar
  geometry to messages/composer. Replace the Wing creature picker and contact
  presentation with the official static fallback profile shapes/colors. Retain
  legacy preference records; no Agent avatar assignment or remote image loading.
- Search implemented Settings categories/topics, select through existing route
  intents, and cancel without changing category or making Agent calls.
- Reserve the overlay Close action's space in the shared page action slot. The
  first Chromium run reproduced Close covering Search at desktop width; the
  geometry regression and subsequent Chromium journeys verify the correction.
- Update native/Maestro fixtures to prove credential denial and preserve model
  conflict flows, rather than claiming synthetic legacy writes qualify the ADR.

## Executed validation

Toolchain: Flutter 3.44.2 / Dart 3.12.2; Node 22.23.4. Locked dependencies were
prepared without changing manifests or lockfiles.

| Check | Result and limits |
| --- | --- |
| Focused Flutter suite | **675 passed**, serial, `--no-pub`; command below. |
| `flutter analyze --no-pub` | No issues. Includes changed integration targets. |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | 681 files, zero changes. One pre-existing gateway test assertion was formatted to satisfy this gate. |
| `git diff --check` | Passed before commit. |
| `TMPDIR=/tmp python -m unittest discover -s test/tooling -p 'linux_feature_qualification_*test.py'` | 28 passed; synthetic driver/checker tests, not native campaign acceptance. |
| `python -m unittest discover -s test/tooling -p task_status_report_test.py` | 3 passed; read-only task reporting preserves waiver dispositions. |
| `flutter build web --no-pub --release -t lib/main_e2e.dart` | Passed. Existing Wasm compatibility and Cupertino font warnings remain; no Wasm support claim. |
| Chromium `browser-surfaces.spec.mjs` | 12 passed in the default E2E runner. |
| Chromium `settings-search.spec.mjs` | 2 passed at 390/1280px, including actual pointer selection, cancellation, route retention and zero mutations. |
| `npm audit --audit-level=low` | Zero vulnerabilities. |
| `flutter build linux --no-pub --debug` | Passed using a rootless Debian 13 GTK/LLVM dependency prefix. This is compilation, not a native runtime journey. |

Focused Flutter command:

```sh
flutter test --no-pub --concurrency=1 \
  test/core/hermes/channel/hermes_api_channel_test.dart \
  test/core/hermes/hermes_api_test.dart \
  test/core/hermes/hermes_surface_readiness_authorization_test.dart \
  test/features/providers test/features/settings \
  test/features/hermes_chat/gateways/gateway_contacts_view_test.dart \
  test/features/hermes_chat/screens/hermes_chat_desktop_geometry_test.dart \
  test/features/hermes_chat/screens/hermes_chat_composition_test.dart \
  test/features/hermes_chat/screens/hermes_chat_gateway_confirmation_owner_test.dart \
  test/shared/widgets/hermes_profile_avatar_test.dart \
  test/router/chat_workspace_overlay_geometry_test.dart \
  test/integration/maestro_feature_fixture_test.dart
```

The unchanged whole serial Flutter suite was attempted but interrupted by the
execution environment restart after 450 passing cases; it is **not passed**.
The complete `npm run web:e2e` was also interrupted during the overlay suite after
the two completed specs above; it is **not passed**. Earlier exploratory selector
failures and the reproduced Close overlap are not hidden by these bounded results.

## Remaining acceptance

- Finish the whole serial Flutter and default browser suites on the final source.
- Run the existing isolated Linux native campaign with the prepared toolchain;
  management fixture changes were analyzed, not accepted as executed GTK journeys.
- Render and compare official Desktop and Wing scenes from the same reference;
  source inspection, widget geometry and screenshots are not paired visual parity.
- Complete shell, full Settings tree/field links, connections, workspace and the
  remaining CLONE packages. Preserve the working Bot Chat implementation.
- No disposable authenticated Agent QA target is available, as confirmed by the
  owner. No actual generation, approval/Stop/recovery or provider mutation was run.
- Android/macOS/Windows runtime, physical voice, accessibility and signed artifact
  installation/update/rollback/uninstall remain pending. Only available targets
  were requested for current validation; the full product scope is unchanged.

## Publication state

Historical publication failure below was superseded by the remote `main` merge
`9a6fc49d17fd2c58a479ddb509be0b0438114687`, verified through GitHub during the
follow-up review. This establishes publication of that batch, not full parity.

The owner requested incremental publication. Native Git authenticated as
`DanielOlan28` returned 403 permission denied for this repository. The connected
`olanhiram-bot` account reports repository push permission, but the GitHub
integration rejected Git tree creation with 403, `Resource not accessible by
integration`. These are external authorization failures, not branch-protection
checks to bypass. No remote branch or commit publication is claimed.

## Follow-up: task counts and local Settings subpages

The task reporter now partitions administrative records by their recorded closure
disposition. In the 297-record snapshot at `9a6fc49d`, 75 closed records retain qualification
gaps (64 waivers, 9 deferrals and 2 retired aggregates); aggregate rows can overlap
with child tasks. Fourteen matching pass receipts, one manual delivery reference,
202 historical/other closures, three retired/superseded records and two open rows
remain separate. No percentage or new runtime acceptance is inferred.

Settings ports the supported Appearance children Theme/Typography, parent versus
caret actions, and `page`/`setting` navigation from the same official pin's
`appearance-subpages.ts`, `subpages.ts` and `settings-manifest.ts`. Search can open
Theme or Chat text size directly. Changing categories clears stale target
parameters; cancelling search or replacing its navigation owner preserves the
newer selection. Existing preference keys, values and Agent authority are unchanged.
The rest of the Settings tree and field catalog remains pending.

Executed on Linux with Flutter 3.44.2 and Node 22.22.2:

- `python3 -m unittest discover -s test/tooling -p task_status_report_test.py -v`:
  9 passed; text/JSON output, receipt identity, unknown closures, duplicate IDs,
  and read-only reporting are covered.
- Focused serial Flutter run across `test/features/settings`, `test/router`,
  `hermes_chat_rich_transcript_test.dart`, `local_hermes_home_discovery_test.dart`
  and `fixture_server_test.dart`: 221 passed. The subsequent stale-search guard
  and route checks passed in an 8-case run of `settings_subpages_test.dart` and
  `settings_routes_test.dart`.
- The original complete serial attempt finished with 4,172 passed, nine existing
  skips and 13 failures. Eleven failures required absent `TMPDIR`, one spawned an
  unconfigured `dart` shim, and one retained the retired 20px message radius.
  Discovery now uses `Directory.systemTemp`; all 11 cases pass with `TMPDIR`
  explicitly unset. The matching Flutter SDK is on PATH for child Dart processes.
  The old radius assertion now checks the pinned 3.2px user/flat assistant geometry;
  its focused suite passed. A new complete-suite pass is not established here.
- `flutter analyze --no-pub`: no issues after addressing two analyzer suggestions.
- Formatting of the eight changed Dart files: no changes. `git diff --check` passed.
- `flutter build web --no-pub --release -t lib/main_e2e.dart`: passed; existing
  Wasm/Cupertino-font warnings remain. `npm ci` used the existing lockfile and
  reported zero vulnerabilities.

`npm run web:e2e` passed all 12 browser-surface cases, then stopped on two new
Settings assertions that expected standalone text where Flutter merges the
accessible label. The corrected focused command
`npx playwright test --config=playwright.config.mjs playwright/tests/regression/settings-search.spec.mjs`
passed both 390px/1280px cases against the same E2E build. These cases check search,
cancellation, direct targets, persisted text size after reload, no Agent mutations
and no browser/overflow errors. Both resulting screenshots were reviewed. The
remaining default browser suites did not execute in this run.

No physical device, native GTK journey, actual Agent call, acoustic test, paired
Desktop visual comparison or signed distribution is qualified by this follow-up.
