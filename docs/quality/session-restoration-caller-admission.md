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
