# Dormant enrollment retirement — t_17a16299

Status: implemented offline; independent same-card review pending. No commit was
made: this card explicitly reserves the scoped commit for the coordinator after
approval. CONNECTION-LINK-REMOVAL remains in progress; no ledger changes.

## Source and admission

Base: `96d94f5c692361dff038d9cd61c0fc140f791b9a`.
Original `pass_workspace.py` guard returned `worker_start_admitted` before the
first edit, using manifest SHA-256
`c33dc64ec7af462218c883ca7ba2cdaa3feec15e077dc863820ba672f12784bc`.
The original native workspace is the task's `db9d399dd9e886f8-e5c79c28f4794d1fa267fcde238a258c`
scratch directory. No repin, canonical edit, runtime change or upstream edit.

Final scoped fingerprint (before this receipt):
`403a66057c3f7b7746eced99cb3bc010e0faab69aebc0b5e069ca9b48865320a`.
Calculation: sorted unique changed/untracked paths plus `pubspec.yaml` and
`pubspec.lock`; SHA-256 over each UTF-8 path, NUL, and file bytes (or `<deleted>`).
Lockfile SHA-256: `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`.
Flutter 3.44.2 / Dart 3.12.2 on Linux. Existing cached dependencies were resolved
with `flutter pub get --offline`; manifest and lockfile remained unchanged.

## Acceptance evidence

- Removed the unused enrollment controller, inspect/exchange provider wiring,
  payload parser, readiness/computer guide widgets and exclusively used transport
  classifiers. Production caller search found the controller only in its own
  provider and retired readiness widget; remaining callers were test fixtures.
- Kept `hermesConnectIntentSourceProvider` at its existing import location with
  the original platform source construction. WingApp's consume/discard flow,
  accessible generic rejection and public navigation remain unchanged.
- `test/tooling/enrollment_retirement_contract_test.dart` failed before deletion
  because the production provider still constructed `HermesEnrollmentController`;
  after deletion it passes. It guards enrollment source against management imports,
  parsing, inspect/exchange and endpoint-store wiring, and retains the ingress seam.
- Retained cold/warm/malformed rejection tests, no raw-input display, no clipboard,
  scanner, network/connect or writes, exact saved records, owner/profile/session,
  drafts, public Cancel and platform Back. Only overrides and counters for the
  deleted controller were removed. Direct entry, absent/denied capabilities and
  Android SSH/Remote/Termux order remain covered by existing tests.
- Native fixture imports and inventory were closed without removing direct Agent
  assertions. Existing `management_attempts` receipts now count forbidden
  `localWingLinkHostProvider` construction, rather than callbacks on a nonexistent
  enrollment controller. Local fixture `management` uses the same actual Link
  construction counter. These are not network-operation counts or fresh native
  qualification receipts.
- Replaced the obsolete native/Android fixture pairing journey with generic
  rejection/direct-options recovery. A widget test exercises that production
  screen through the Maestro fixture router. Android Maestro YAML was updated,
  but was not run on Android.
- Core Link service/client, API methods/models, secure store/raw records, scanner
  and platform packaging, profile/provider management and localization unchanged.
  Updated [current enrollment guidance](../getting-started.md#direct-agent-connection).

## Executed checks

All commands ran in the original task workspace, with bounded timeouts.

```text
timeout 3m flutter test --no-pub --reporter expanded test/tooling/enrollment_retirement_contract_test.dart
```

RED: failed on dormant controller construction. The first attempt could not run
without package configuration; cached offline resolution supplied it. GREEN: pass.

```text
timeout 10m flutter test --no-pub --concurrency=1 --reporter expanded test/features/enrollment test/router test/features/local_setup test/app/wing_app_connect_intent_test.dart test/app/hermes_connect_intent_stream_test.dart test/integration test/core/hermes/setup test/shared/security test/tooling/enrollment_retirement_contract_test.dart test/features/hermes_chat/gateways test/features/hermes_chat/screens/hermes_chat_saved_endpoint_edit_test.dart test/features/profiles test/features/gateway
```

Final run: 573 tests passed, 2m25s. Prior run: 572 passed, one new fixture test
failed because its lazy list item had not been scrolled into existence; fixed
with the existing `scrollUntilVisible` pattern. After the final formatting-only
change, the two new tests were rerun and passed at the fingerprint above:

```text
timeout 3m flutter test --no-pub --reporter expanded test/features/enrollment/legacy_fixture_rejection_test.dart test/tooling/enrollment_retirement_contract_test.dart
timeout 5m flutter analyze --no-pub
git diff --check
```

Final analysis: no issues (1.8s). Earlier analysis found obsolete integration
fixture overrides, then one newly unused import; all closed. Changed-file
`dart format --output=none --set-exit-if-changed` passed: 15 files, zero changes.
Current guidance's 15 relative local file links exist. No localization input
changed, so no `flutter gen-l10n` was needed.

## Skill application

Explicit task request; verified engineering router revision
`1be8e34187e34647bb83adc3a1323b26ae6f6abe`, under
`hermes-toolset/skills/engineering/upstream/skills/`:

- `test-driven-development/PROTOCOL.md`: discriminating production source guard
  before deletion, observed RED then GREEN; retained behavior tests passed.
- `deprecation-and-migration/PROTOCOL.md`: traced production, test and integration
  consumers, removed dormant code only, kept ingress and existing stored access;
  source closure and 573-test regression pass, no data migration.
- `security-and-hardening/PROTOCOL.md`: untrusted intent/share boundary discards
  rather than exchanges; preserved generic errors, no secret rendering/replay,
  secure-store assertions and exact owner/draft checks; rejection/setup/security
  suites passed. No new authentication or native authority.
- `frontend-ui-engineering/PROTOCOL.md`: retained production live-region rejection,
  Back/Cancel, compact 200% text, keyboard and Android ordering checks; same-screen
  fixture recovery passed. No redesign or native/platform support claim.
- `ponytail:ponytail`: kept the existing provider seam, deleted the obsolete
  implementation instead of adding an adapter; no dependencies or migration.

## Exact residual consumers and limits

Remaining product consumers to inspect in the next slice:
`lib/features/profiles/screens/profiles_screen.dart`,
`lib/features/profiles/widgets/profile_editor_sheet.dart`,
`lib/features/profiles/widgets/profile_directory_browser_sheet.dart`, and retained
`lib/features/local_setup/providers/local_hermes_setup_provider.dart` host provider.
`lib/features/gateway/screens/gateway_screen.dart` retains legacy compatibility
seams although its normal route no longer constructs management. Core
`lib/core/hermes/client/hermes_api_client.dart` still contains enrollment API
methods/models; `lib/core/hermes/setup/secure_hermes_endpoint_store.dart` retains
legacy raw records. `lib/main_local_setup_recovery_e2e.dart` is an old fixture
consumer. Wing Link service/installer/platform packaging, native scanner,
obsolete localization and stale historical visual/fixture controls remain separate
successors, not silently removed here.

Exercised only Linux-hosted Flutter test VM and deterministic Linux/Android
widget variants. Native Linux integration, Android Maestro/device execution,
physical secure storage, browser build/E2E and live authentication NOT_CHECKED.
No commit, integration, push, PR, deployment or release. Review approval and
coordinator-owned commit/integration remain pending; measured cost is unknown.
