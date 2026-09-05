# Provider/model setup catalog validation — 2026-09-05

The profile setup form obtains suggestions through Wing Link's typed
`GET /v1/profiles/{id}/model-options` endpoint. The host reads the installed
Hermes Agent's advertised catalog with a separate, existing profile credential.
No provider/model list is maintained by Wing, and catalog reads do not mutate
configuration or authorize additional provider writes.

## Verified behavior

- An authenticated Wing Link request passes through profile validation and an
  Agent capability check to a controlled HTTP Agent fixture. Only provider
  slugs/names and model IDs return to the client.
- Pending credentials, missing profile grants, unknown profiles, arbitrary query
  parameters, wrong methods, redirects, and unsafe credential paths are rejected.
- Catalog errors do not expose upstream diagnostics; malformed or oversized
  results fail rather than presenting a partial catalog.
- Setup retains unconfigured providers and providers with an empty model list.
  A 400-model client fixture verifies suggestions beyond the previous 256-row cap.
- Search matches provider display names or IDs. Models are filtered by provider;
  switching providers clears the prior model. Retry recovers from catalog failure.
- Keyboard navigation and text-input submission select a suggestion. Freezing a
  pending setup payload dismisses the suggestion overlay.
- Audit events use an allowlisted operation name and outcome, without catalog
  content, request bodies, or credentials.

## Validation commands

```bash
(cd wing_link && go test ./...)
(cd wing_link && go test ./internal/app ./internal/audit)
(cd wing_link && go test ./internal/app -run ModelOptions -count=1)
flutter analyze
flutter test --no-pub test/features/profiles/profile_catalog_test.dart
flutter test --no-pub --concurrency=1
flutter build web --release -t lib/main_e2e.dart
PORT=8877 HERMES_E2E_PORT=8878 npm run web:e2e
```

The Go suite and final affected Go tests passed. Final analysis passed. All five
catalog-focused Dart/widget tests passed. All 46 browser regression tests passed. The full Flutter run reported 1,564
passes and nine failures while multiple sessions edited the shared worktree.
After those edits settled, all 149 tests in the failing suites passed on rerun,
including the catalog test. This is a full-suite run plus targeted recovery, not
an isolated immutable-checkout qualification.

## Limits

Validation ran on Linux with deterministic widget/HTTP fixtures. No Agent API
was listening on the default local port for a live catalog check. No physical
Android or real-provider inference qualification was performed for this change.
Remote catalog reads require normally trusted Agent HTTPS with TLS 1.3, or a
loopback HTTP Agent origin; this endpoint does not inherit the native client's
separate explicit private-VPN plaintext exception. Missing Agent or Wing Link
catalog capabilities leave manual entry available with a visible retry error.

## OmniRoute discovery follow-up

Added fixed host-loopback discovery and profile-editor selection/recheck UI.
No local service was listening at the default endpoint during verification;
serving and authentication-required behavior are tested with deterministic HTTP
transports, not claimed as live OmniRoute or physical-device qualification.
Authenticated OmniRoute provisioning, installation/start from Wing, and custom
remote endpoints remain unsupported in this UI.

Validation for the discovery follow-up:

- `flutter analyze`: passed.
- `flutter test --no-pub test/features/profiles/profile_catalog_test.dart test/features/profiles/profiles_screen_test.dart`: 39 passed. The reload-failure fixture now counts profile-list requests independently of discovery capability requests.
- `(cd wing_link && go test ./...)`: passed.
- `git diff --check`: passed.

These checks ran on Linux. They do not qualify physical Android or an installed
OmniRoute service. The shared worktree also contains other ongoing UI changes.
