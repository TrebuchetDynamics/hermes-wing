# Setup/authentication matrix: offline prerequisite audit

Task: `CONNECTION-SETUP-AUTH-MATRIX`; goal: `CONNECTION-PATHS`.
Audited Wing baseline: `af1df8dbe47289c6db85aefcf661c7eae6833855`.
**Parent acceptance remains incomplete.** This documentation-only increment checks
current prerequisite, discovery-error and guide behavior. It does not qualify a
live connection, native storage, installation, Desktop parity or a first reply.

Start with the [public first-chat guide](../getting-started.md). Existing fixture
receipts below remain attributed to their own executed sources and targets; they
are not new passing results for this baseline. No production/test/harness input
was changed, and no completed browser or native matrix was replayed.

## Current-source prerequisite and outcome checks

The [official API Server guide](https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server)
was inspected as public documentation. Its Quick Start describes enabling an
API listener, `API_SERVER_KEY`, gateway startup and optional explicit CORS origins.
Its OpenAI-client `/v1` example is **not** Wing's endpoint/capability acceptance.
Do not copy token-bearing curl examples into argv or infer Wing readiness from
CLI success. This worktree has no `hermes-agent/` reference checkout; no upstream
source, dashboard navigation, CLI output or installed runtime was requalified.

| Boundary | Current Wing source and audited result | What remains unproved |
| --- | --- | --- |
| Address and profile | [`hermes_api_config.dart:41–85,136–153`](../../lib/core/hermes/client/hermes_api_config.dart) builds `/health`, `/v1/capabilities`, `/api/sessions`, exact-session history and chat/run URLs; the supplied `/p/<profile>` prefix is preserved by [`hermes_api_uri.dart:6–24`](../../lib/core/hermes/shared/hermes_api_uri.dart). Query profile identity is explicit when applicable. Use the administrator-supplied base endpoint, not an OpenAI-client `/v1` URL. | A reachable listener or similarly named Desktop endpoint does not prove this contract. |
| Guide and credential | [`connection_setup_guide.dart:22–118`](../../lib/features/hermes_chat/widgets/connection_setup_guide.dart) links to the official guide and sequences preparation, address, token, browser origin where applicable, then verification. Token generation is disabled. [`app_en.arb:19–29`](../../lib/l10n/app_en.arb) distinguishes the Agent key from provider keys, same-profile configuration, exact CORS origin and administrator-owned activation/restart. | Widget copy checks do not verify the documented dashboard/status procedure on an actual Agent release. Wing must not read secrets, rotate a shared key or restart a gateway to complete it. |
| Discovery only | [`connection_check_panel.dart:91–139`](../../lib/features/hermes_chat/widgets/connection_check_panel.dart) makes an explicit capabilities read, checks supported schema/object/platform and derives chat-transport availability. It does not save, connect Chat or generate. Editing/cancellation/owner loss invalidates feedback; an in-flight read stays single-flight. | A verified discovery result is not authenticated session access, persistence or inference success. |
| Chat operation | [`hermes_transport_policy.dart:8–24,73–89`](../../lib/core/hermes/policy/hermes_transport_policy.dart) requires session-chat streaming **or** run submission plus run events, with exact advertised method/path, supported schema, every declared grant and supported context for profile-scoped endpoints. [`hermes_capabilities.dart:58,118–122,151–152`](../../lib/core/hermes/models/hermes_capabilities.dart) defines the supported schema/profile/grant interpretation. | A broad version/admin flag, `/v1/models`, health or OpenAI compatibility alone is insufficient. Additional history/run-state gates still apply when sending. |
| Connect versus save | [`hermes_api_channel_connection.dart:84–178`](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart) reads health, capabilities and session inventory, with history when selecting a session, before connected state. [`hermes_chat_connection.dart:394–492`](../../lib/features/hermes_chat/screens/state/hermes_chat_connection.dart) separately connects and attempts secure save; uncertain save does not claim rollback or disconnect a replacement owner. | Connection does not prove confirmed storage. Save does not prove later keychain access or generation. Exact request counts depend on the selected owner and advertised optional reads. |
| First reply | [`hermes_api_channel_messaging.dart:124–148`](../../lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart) rejects unsupported chat transport and run-only history it cannot preserve. The [public first-message step](../getting-started.md#start-the-conversation) requires one deliberate no-tools prompt in the selected conversation. | Only an actual owned assistant reply qualifies generation. Discovery, save and connection must be recorded separately. |

### Error/recovery review

The following are source-reviewed branches, not newly executed live failures:
[`connection_check_panel.dart:140–162`](../../lib/features/hermes_chat/widgets/connection_check_panel.dart)
maps typed 401/403 to authentication denial; invalid endpoints and incompatible
discovery have distinct messages; timeout and TLS have distinct recovery; browser
network/CORS/mixed-content/certificate failures remain inconclusive about token
validity. Feedback uses localized messages rather than raw exception bodies.
No branch infers OAuth from denial or performs sign-in. Browser OAuth remains
unsupported; reuse the [Remote explanation receipt](remote-auth-explanation.md),
not another OAuth-copy implementation.

The eight existing public-widget cases executed below cover single-flight
read-only discovery, changed-draft and owner-loss fencing, selection-only field
changes, browser-network versus HTTP denial, and native/browser guide traversal
including disabled token generation. They do **not** separately execute every
error branch above, browser networking, OS permissions or real authentication.

## Reuse, do not redispatch

| Existing evidence | Reused bounded conclusion | Still separate |
| --- | --- | --- |
| [Local enrollment native](local-setup-enrollment-native.md) | Linux GTK metadata-only missing/default/selected home, cancellation, denial and explicit saved-owner recovery over external fakes. | Actual chooser/window sizing, keychain and authenticated Agent. |
| [Android direct setup](android-direct-setup-enrollment.md) | Manual preparation, guide retry and retained-owner/auth/save recovery under Android-targeted fixtures. | Approved Android execution, actual Termux preparation, keystore and authentication. |
| [Saved workflows](connection-saved-workflows.md) | Current direct-only browser composition, public saved-host collision selection, explicit retry and owner fencing in that receipt's candidate. | Complete live two-host/profile/session collision matrix. |
| [Production browser matrix](connection-production-browser-matrix.md) | Its frozen production-router composition and request counters only. Its legacy installer/setup cells are historical, not replacement Local support. | No transfer of legacy setup, OAuth or physical-platform claims. |
| [Remote retry](remote-connection-retry.md), [two-host native](two-host-recovery-native.md) | Synthetic denied auth/uncertain save and native keyboard selection/retry with zero forbidden mutations in their declared fixtures. | Real Remote authentication, physical storage and full live collisions. |
| [Saved editor native](saved-endpoint-edit-native.md), [storage native](saved-endpoint-storage-native.md) | Their specifically recorded edit/Test and storage subsets. | No duplicate M1 saved-editor dispatch; no blanket backend/storage qualification. |

[Optional Local setup recovery](local-setup-recovery.md) is preserved historical
controller/isolated-screen evidence. Do not run its retired service/pairing
procedure as current setup; current Local enrollment is metadata/manual preparation
plus direct Agent authentication. None of these receipts closes the parent.

## Remaining cells and admission (all NOT_CHECKED here)

These are remaining cells of this task, not new tasks, live launch commands or
permission to acquire credentials. Keep authentication, target and spending gates.

| Cell | Required supplied admission | Required observation |
| --- | --- | --- |
| Native Linux Local existing/preparation-needed | Approved disposable unmodified Agent and authenticated endpoint; isolated Wing state; approved chooser/keychain target. | Follow public prerequisites, discover exact capabilities, cancel without altering saved identity, deliberately connect, distinguish persistence and obtain one owned reply only under an approved provider budget. Separately observe real chooser/keychain/window behavior. |
| Android manual preparation / saved recovery | Approved disposable device/package and Termux target, private QA authentication and separately qualified provider budget. | Execute the existing native entry without replacing a personal app; actual preparation/authentication and retained saved-owner recovery remain distinct from fixtures. Observe physical keystore and assistive-technology output separately. |
| Native Remote / saved connections | Approved HTTPS Agent and disposable token delivered privately, named platform/storage backend and isolated saved state. | Rejection, cancellation, explicit correction/retry, confirmed save and fresh-process restore keep exact endpoint/profile/session; no management fallback. Token authentication is not OAuth qualification. |
| Hosted browser Remote | Approved compatible HTTPS Agent, valid certificate, exact hosted Wing CORS origin, disposable authentication and provider budget. | Separate topology from native/loopback: explicit discovery, sanitized/inconclusive failures as applicable, deliberate connect and one reply in the owned conversation. Never bypass trust, allow wildcard CORS or publicly bind a port. |
| Two-host full collision | Two approved disposable authenticated Agents with intentionally colliding profile/session IDs; isolated stores and a bounded delayed-response mechanism. | Public A→B→A selection/cancel/retry preserves origin-bound credentials, exact owner/history and inert legacy bytes; stale completions cause zero stale-owner mutations. Bind each read to its actual origin/profile/session. |

SSH remains limited to its separately verified native forward/trust contract;
this audit grants no remote install, exec, lifecycle or OAuth authority. No
personal credential search, service change, provider call or device operation
was performed. Missing live inputs belong in `pending_live`, not an offline test
failure. First reply does not qualify subsequent tool/approval/Stop/restoration
acceptance under `PARITY-LIVE-WORKFLOW`.

### Required non-secret receipt for each future live cell

Record Wing commit/artifact, platform/version and route topology, unmodified Agent
release identity, the exact discovery operation/schema/grant/context outcome,
public actions and sanitized recovery, separate persistence/connect/generation
outcomes, and an opaque owner alias bound to the actual endpoint/profile/session.
Record exact allowlisted method/path/query counts using aliases for private
identities, plus zero management attempts and zero stale-owner mutations.
Confirm legacy preservation without exporting raw records. Record budget admission
and consumed calls without secrets, transcripts, private URLs or host paths.
An independently observed reply in that owned conversation is required per named
target; do not infer another target from it.

## Executed offline checks

Linux-hosted Flutter 3.44.2 / Dart 3.12.2, using the existing shared cached SDK and
package cache. No dependency manifest or lockfile changed.

- `flutter pub get --offline`: passed, cached dependency preparation only.
- `flutter test --no-pub --concurrency=1 test/features/hermes_chat/widgets/connection_check_panel_test.dart test/features/hermes_chat/widgets/connection_setup_guide_test.dart`: **8 passed**.
- `flutter analyze --no-pub`: **no issues**.
- Local Markdown target/source-range validation and `git diff --check`: passed.

No Flutter UI, protocol or runner changed, so no new test was added and no browser
build/native journey was needed for this documentation increment. Prior compiled
checks retain only their original receipt scope. No new network request ledger or
screen-reader/native/device/provider qualification is claimed. Offline logs and
audited source fingerprints are retained in this attempt's supplied temporary
directory; coordinator integration, publication and parent completion are separate.

Revisit this audit if the public guide, connection guide/check panel, capability
policy, URL/profile handling, connection/save ownership or linked fixtures change.
Rebuild `lib/main_e2e.dart` before any later changed-input compiled browser check.
