# Session restoration caller admission

Card: `t_4d935efb`. One bounded correction for
`CONNECTION-OFFICIAL-DESKTOP-PORT` / `CONNECTION-PATHS`, not milestone closure.
Wing base: `d477d767df868053361ffe06b9ca2f594186adf6`.

## Defect and correction

The production `HermesApiChannel.restoreSession` cleared the active selection
before checking its caller's `canAccept` lease. A rejected restoration returned
`false` without network I/O but had already erased the current owner's selection.
The regression reproduced this through the public production channel: expected
`synthetic-active`, actual `null`. This is a channel-contract reproduction, not
an observed physical-device failure or proof of a natural UI race.

[Restoration](../../lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart)
now rejects an already-invalid caller before requiring connection state or
clearing selection, matching the existing `selectSession` / `createSession`
entry guards. Accepted restoration still clears the old send target until exact
history is ready; ownership is checked again after notification and asynchronous
reads. No capability gate, request identity, history validation, error handling,
durable recovery lease or retry policy was replaced.

Production enrollment is
[hermesChannelProvider](../../lib/features/hermes_chat/providers/hermes_channel_provider.dart):24–28,
not the qualification-only `HermesWebLifecycle`.
[HermesGatewayDirectory.activate](../../lib/features/hermes_chat/gateways/hermes_gateway_directory.dart):824–839
passes its activation-generation lease to the public channel method. Its forwarding
method and interface require no change. No new fixture, config, export, dependency,
UI control, backend or protocol field is necessary.

## Read-only official source trace

Reference: [official Agent/Desktop revision
158fd638da1629c8e62caf9ade1515d162def8ab](https://github.com/NousResearch/hermes-agent/tree/158fd638da1629c8e62caf9ade1515d162def8ab).
The reference checkout remained clean. The paths below are relative to that
revision; tests were inspected, not executed or modified.

| Outcome | Official source and nearest tests | Wing production boundary retained |
| --- | --- | --- |
| Send ownership | `apps/desktop/src/store/session-request-router.ts`:5–17,102–129 captures exact connection/profile and retains a routed turn; `app/session/hooks/use-prompt-actions/submit.ts`:396–455 guards drift and concurrent submits. `app/session/hooks/session-context-drift.test.ts`:42–77 distinguishes pin owners. Desktop paths in this table after the first row are relative to `apps/desktop/src/`. | `hermes_api_channel_messaging.dart`:69–115 captures client/profile/session, checks pending submissions and unresolved durable runs before Send. |
| Stream/disconnect | `apps/shared/src/json-rpc-gateway.ts`:130–149,475–491 owns replay generation/barriers; `apps/shared/src/json-rpc-gateway-replay.test.ts`:239–347 proves ordered replay and replacement-socket cleanup. `store/gateway-foreground-retention.test.ts`:197–232 distinguishes foreground and unrelated request leases. | `hermes_api_channel.dart`:249–262 retires local streams; `hermes_api_channel_sessions.dart`:4–13 invalidates connection/selection owners on disconnect. Existing detached-run reconciliation is retained; event recovery is not prompt replay. |
| Human input | `store/server-requests.ts`:3–37 retains the incoming socket's request and consumes its ID once; `components/assistant-ui/tool/approval.test.tsx`:131–143 checks response correlation instead of a new RPC. | `hermes_api_channel.dart`:553–595 checks origin generations/profile/run and the existing responder; no native request transport is promoted. |
| Stop | `app/session/hooks/use-prompt-actions/index.ts`:686–769 captures current runtime, clears pending prompts and handles interruption failure; nearest `index.test.tsx` includes interrupt-first and failure cleanup cases. | `hermes_api_channel_messaging.dart`:2279–2436 distinguishes local teardown, Stop request and exact terminal status/history; existing Stop/ABA tests remain in the focused suite. |
| Resume | `app/session/hooks/use-session-actions/index.ts`:1303–1337 rejects superseded resumes before post-replay view writes and :1515–1532 routes exact-owner RPCs then checks resume ownership. `use-route-resume.test.tsx`:52–136 refuses stale A while creation owns B. | Directory activation and `restoreSession` use existing generation/`canAccept` guards. This slice repairs only missing entry admission; it does not copy Desktop RPCs or auto-retry policy. |

Desktop JSON-RPC is not authority to offer it on an advertised HTTP connection.
Wing's existing `HermesApiClient.sessionMessagesPage`:239–275 still scopes the
request and validates returned session identity before channel cache admission.

## Acceptance evidence

[Caller-admission regression](../../test/core/hermes/channel/hermes_session_caller_admission_test.dart)
extends the existing open/create matrix with restore entry rejection,
notification-time invalidation, late malformed history, late read rejection and
current-owner failure. Rejected entry preserves the identical immutable state
and makes zero requests. Stale history changes neither transcript nor pagination.
A current failure still throws; later explicit restore succeeds using GET only.
There is no automatic Send, Stop, approval or session-creation replay.

The first harness attempt failed compilation because the shared future inferred
`void`; the typed restoration future repaired the test without changing production.
The next pre-fix run passed 11 tests and failed only restore entry admission.
The one-line production guard made that regression pass. The final focused suite
passed 439 tests, including production directory restoration with both loaded and
not-yet-listed remembered sessions, lifecycle races, detached recovery and Stop.

Checks executed on Linux with Flutter 3.44.2 (`c9a6c48423`), Dart 3.12.2:

```sh
flutter pub get --offline --enforce-lockfile
dart format --output=none --set-exit-if-changed lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart test/core/hermes/channel/hermes_session_caller_admission_test.dart
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 test/core/hermes/channel/hermes_session_caller_admission_test.dart test/core/hermes/channel/hermes_recovery_read_admission_test.dart test/core/hermes/channel/hermes_api_channel_test.dart test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart --reporter expanded
git diff --check
```

`pubspec.lock` was preserved: SHA256
`f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`.
The frozen `finish_task.py` gate reruns format, analysis, focused tests, diff and
lock/local-link checks before publishing only the three owned files to the local
`agent/wing/t_4d935efb` ref. Its exact commit/check receipt belongs to the native
same-card review handoff, not an assertion of review approval here.

Ponytail decision: reuse existing entry guard and regression matrix; one new
production line, no new abstraction. Excluded secure endpoint-store files and
canonical dirty work remain untouched. Browser-specific transport/presentation
and controls are unchanged; compiled browser, native app/device, live authentication,
inference, full repository/release checks and publication are NOT_CHECKED.
Independent review, canonical integration and the remaining connection milestone
are separate from this local implementation.

## Remaining official connection acceptance

Card: `t_e17c0b4a`, admitted isolated Wing base
`a5f27f62386acb6781417e79710290800b7cf2b6`. The initial frozen
`pass_workspace.py` guard returned `worker_start_admitted` before design/tests/edits,
bound to manifest SHA256
`acf14b434640cbb1c28bfec6592ca5c7b79bdbeec99d6e91ed904d3dfbe37a07`
and helper-bundle SHA256
`29755a239ad5c3d7ce0bfd7670cafaf40e6a4b649d2e746d061fcfdc155f2f08`.
The worktree began clean. Only this receipt and the
[connection comparison](../product/desktop-connection-paths.md) change; no production,
test, fixture, config, export or dependency change was necessary.

### Proposed parent acceptance mapping

This mapping is for coordinator acceptance after independent review, not a
canonical TODO/goals transition or a claim that `CONNECTION-PATHS` is met.

| Parent criterion | Evidence at the pinned candidate | Verdict and limit |
| --- | --- | --- |
| Official welcome/Local/SSH/Remote auth and transport trace | Updated comparison maps official setup overlay, Local bootstrap, OpenSSH config/trust/probe/scoped lifecycle, Remote Test/Apply and native-login/ticket paths to current Wing production callers and inspected nearest upstream tests. Official Agent `158fd638da1629c8e62caf9ade1515d162def8ab`, Desktop tree `2038178ee53e13cde6fe297daa2484a868e7d3a3`; reference clean before/after. | Source trace complete for this batch; official tests/application not run. Three-button Wing welcome is an explicit fidelity gap, not official parity. |
| One evidence-backed production correction | Delivered `restoreSession` admission guard, described above; integration `5ca00b61` is an ancestor of the admitted base. Fresh caller-admission and exact-directory-restoration tests pass in security union B below. | Already implemented before this batch; not duplicated or counted as new work. |
| Compact/wide public controls, 1x/2x text | Union A includes unchanged `hermes_connection_primary_entry_test.dart` at Linux/Android overrides × 390/1280px × 1x/2x text. Existing welcome-recovery, first-run and Local-enrollment tests exercise the public router, keyboard entry/Back, explicit rejection/retry and cancellation. | Pass in Linux Flutter widgets. Overrides are not Android/native-device qualification. |
| Local and Remote safety | Existing Local behavior tests cover metadata-only chooser cancellation/stale completion, fixed phone loopback, explicit docs and sanitized denial. Auth-recovery/remote-retry/saved-workflow tests cover explicit retry, safe persistence/removal errors and stale owner responses. Primary-entry tests preserve exact origin/profile/session and make no requests/saves on selection/Back. | Pass in unions A/B; no real chooser, certificate handshake, service preparation or live auth. |
| SSH trust, separate Agent auth and ephemeral ownership | Existing form/panel tests and union B transport/request tests cover explicit host review, denied/missing verifier, separate Agent token, cancellation, failure cleanup, replacement owner and no saved ephemeral forwarding origin. | Pass in deterministic seams; approved-host Linux/Android SSH and durable SSH relaunch remain NOT_CHECKED. |
| Imported/generated key and public-only copy | Existing key-selection/generated-key/store/UI tests cover bounds, passphrase/failure, generation consent, validated secure-storage readback/reuse, stale callbacks and public-only clipboard. Existing Help tests cover selectable safe guidance at compact/wide 200% text. | Pass in unions A/B; platform secure storage/picker and real host key login remain NOT_CHECKED. |
| Inert saved records, exact recovery, zero mutation replay | `secure_hermes_endpoint_store_test.dart`, `legacy_endpoint_preservation_test.dart`, `hermes_gateway_session_restoration_test.dart`, `hermes_session_caller_admission_test.dart` in B retain origin/identity, inert slots and read-only recovery. Existing primary-entry/first-run assertions reject any POST and incidental connection activity. | Pass for named fixture cases, not a rerun of all historical 467 integrated tests or a full live recovery journey. |
| Unsupported actions and authority | Comparison states manual Local, no lifecycle/shell/backend fallback, no production Remote OAuth/native-web negotiation, browser raw-TCP exclusion, no Agent edits and removed Link consumers/delivery. Production channel, Add/Local/SSH controller/form and enrollment callers inspected. | Inspected and documented; missing authoritative contracts stay unavailable. |
| Native/live milestone and delivery | No personal service, credentials, inference, deployment, integration or push used. | NOT_CHECKED; same-card review and coordinator integration/publication are separate. |

### Executed checks and identities

Linux host, Flutter 3.44.2 framework `c9a6c48423`, engine revision `77e2e94772`,
Dart 3.12.2. Dependency resolution used `flutter pub get --offline
--enforce-lockfile` (exit 0). No upstream tests were executed. Initial checks:

- `dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart`: exit 0, one file, zero changes.
- `flutter analyze --no-pub`: exit 0, no issues (6.4 seconds).
- Union A below: exit 0, 130 tests passed (reporter 1 minute 37 seconds).
- Union B below: exit 0, 94 tests passed (reporter 14 seconds), with render hooks enabled.
- `git diff --check`: exit 0. Lockfile hash unchanged; owned local links/anchors checked by the finish gate.

```sh
# A: retained public-control union
flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/features/enrollment test/features/hermes_chat/widgets/platform_local_connection_panel_test.dart test/features/hermes_chat/widgets/platform_local_connection_behavior_test.dart test/features/hermes_chat/widgets/managed_ssh_connection_form_test.dart test/features/hermes_chat/widgets/managed_ssh_connection_panel_test.dart test/features/hermes_chat/widgets/connection_information_help_dialog_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_remote_connection_retry_test.dart test/features/hermes_chat/screens/hermes_chat_saved_connection_workflows_test.dart --reporter expanded
# B: retained trust/storage/recovery union, with existing render hooks
flutter test --no-pub --concurrency=1 test/core/hermes/ssh/managed_ssh_test.dart test/core/hermes/ssh/ssh_connection_request_test.dart test/features/hermes_chat/ssh_keys test/features/hermes_chat/widgets/managed_ssh_generated_key_ui_test.dart test/features/hermes_chat/widgets/platform_local_connection_behavior_test.dart test/core/hermes/setup/secure_hermes_endpoint_store_test.dart test/core/hermes/setup/legacy_endpoint_preservation_test.dart test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart test/core/hermes/channel/hermes_session_caller_admission_test.dart --reporter expanded
```

Unions overlap in Local behavior; their counts are separate runs, not a unique
test total. `pubspec.lock` SHA256 remains
`f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`;
`pubspec.yaml` SHA256 is
`7986bd3eaa967657f453e08f0522a4254496393699dc9640a7aba7de4cf1a43a`.
Resolved local `.dart_tool/package_config.json` SHA256 is
`6382cec7c5d10172ea018d26fa9d05aa8a5c98067e9a91d077a93a8c13382c35`
(workspace-specific dependency receipt, not portable package identity).

Existing render hooks used `FLUTTER_ROOT=<resolved Flutter SDK>`,
`LOCAL_CAPTURE_FONT_ROOT=$FLUTTER_ROOT/bin/cache/artifacts/material_fonts`,
`LOCAL_CAPTURE_ICON_FONT=$FLUTTER_ROOT/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf`,
`LOCAL_CAPTURE_OUTPUT=$PWD/.task-evidence/connection-acceptance` and
`WING_CAPTURE_GENERATED_KEY_UI=1`. No new screenshot harness or golden baseline.
Four images were inspected: Android-override Local 390×844 and Linux-override
Local 1280×1000, plus synthetic generated-public-key form 390×844 and 960×900.
Local guide/actions and public-key/copy controls are readable; no private key or
credential is visible. The wide Local capture is scrolled, so its header/top and
bottom save controls are outside the crop; it is not proof of all controls at once.
Render capture is 1x text; 2x keyboard/layout acceptance comes from the named tests,
not these images. Widget fonts/icons are fixture rendering, not native screenshots.

Image SHA256 receipts (ignored evidence, not committed product assets):

| Relative evidence path | SHA256 |
| --- | --- |
| `.task-evidence/connection-acceptance/local-390.png` | `c0302ace63c44ca80ac701c6227038c1773c1240d377cda6422d71beb29c7658` |
| `.task-evidence/connection-acceptance/local-1280.png` | `b6c0527cb2ca180f769760684dac9c8cc33a8c229cd4f781b0a056b0d912afd3` |
| `.task-evidence/generated-ssh-key-ui/generated-390.png` | `63479857c370ad4d7f99175fbca2f0a067adbf3a1db0d678e098f2d31ac54efa` |
| `.task-evidence/generated-ssh-key-ui/generated-960.png` | `69c6d103a849901f2ef6505390ebf3d2e2390c2ee6181a96a4287a86297ea37e` |

The frozen `finish_task.py` gate reruns offline dependency resolution, format,
analysis, both unions, diff and lock/local-link checks before committing only
these two docs to `agent/wing/t_e17c0b4a`. Exact commit/check receipt is recorded
in the native handoff; this text does not assert independent approval or publication.
Ponytail decision: delete withdrawn assertions, reuse existing callers/tests/render
hooks, preserve the linked private-key section anchor, add no new production code,
dependency or test abstraction. No failed acceptance check or repair retry in the
initial batch. Cost/usage and independent review duration are unknown.

Implemented: corrected maintained comparison and this proposed acceptance mapping.
Qualified: only named Linux-hosted deterministic widget/security checks and renders.
Delivered: scoped local candidate only after the finish receipt; native review pending.
Compiled browser is NOT_CHECKED because no browser behavior changed. Native/device,
live Agent/provider/SSH/OAuth, installation, durable SSH relaunch, full repository
and release checks remain NOT_CHECKED. The coordinator owns remaining fidelity/live
gaps, review acceptance, canonical mapping/integration and authorized publication.
