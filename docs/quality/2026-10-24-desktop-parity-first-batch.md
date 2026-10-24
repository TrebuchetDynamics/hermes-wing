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

The owner requested incremental publication. Native Git authenticated as
`DanielOlan28` returned 403 permission denied for this repository. The connected
`olanhiram-bot` account reports repository push permission, but the GitHub
integration rejected Git tree creation with 403, `Resource not accessible by
integration`. These are external authorization failures, not branch-protection
checks to bypass. No remote branch or commit publication is claimed.
