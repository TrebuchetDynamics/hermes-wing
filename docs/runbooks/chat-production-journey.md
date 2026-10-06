# Production Chat deterministic work journey

This slice exercises Hermes Wing's production `HermesApiChannel` through the
compiled `lib/main_e2e.dart` release browser UI. Output is fixed synthetic Agent
API fixture output, not provider generation or a deployed Hermes Agent receipt.
The implementation and self-verification on `t_19a425b2` still require independent
same-card tester and reviewer acceptance. M1 is not complete.

## Behavior and authority

- Select the saved host/profile contact and explicitly choose the session. Chat,
  runs, approvals and history remain direct Agent data-plane operations; no Wing
  Link chat traffic or native-web lifecycle activation is added.
- Stop acknowledgment is not terminal confirmation. Wing finishes its local
  stream, keeps exact run ownership and blocks another prompt until the exact
  advertised run-status read confirms `cancelled`, `completed` or `failed`, and
  canonical history loads. A completion can win the race with interruption.
- Rejected Stop, unknown/nonterminal status, missing status capability, mismatched
  run/session identity and failed history reads retain recovery ownership.
  Reconnect is available without offering duplicate Retry. Connection, profile
  and session-selection generations fence late stop responses, including A→B→A.
- Authoritative cancellation/failure events hydrate canonical history for the
  next prompt even though they are not generation success. If the server has no
  reply for that turn, keep the local failed partial transcript. Do not silently
  switch transport merely because a denied run invalidated its context snapshot.
- Reconnect performs status/history reconciliation, not mutation replay. Existing
  uncertain-submission, approval-correlation, detached-run, windowing, session
  picker and remembered-session recovery guards remain in effect.
- Native approval events preserve Agent's `request_id` and send it back on the
  exact run approval POST. A supplied exact ID is never dropped into Agent's
  legacy FIFO resolver. Stale IDs receive conflict without answering a newer
  request; in-flight or already-answered emitted approvals cannot be submitted
  twice. Genuinely idless legacy events retain their supported explicit-run path.
- A submission response for a different session is rejected. Rollback may confirm
  that exact run's terminal status and release its cleanup lease, but it never
  reads or admits the response-derived session's transcript, pagination or model
  history. Uncertain rollback retains the exact lease without admitting history.
  The guard also survives in memory when no durable store is configured: later
  explicit selection of that owner cannot submit another run until authoritative
  terminal status and canonical history reconcile it. Local cancellation alone
  does not release ownership.

The read-only reference Agent stop/approval handlers and tests establish the
acknowledgment and `request_id` contracts:
`hermes-agent/gateway/platforms/api_server_runs.py`,
`hermes-agent/tests/gateway/test_api_server_runs.py`,
`hermes-agent/tools/approval_gateway_wait.py` and `hermes-agent/tools/approval.py`.
No reference/runtime changes are part of this slice.

## Executable journey and receipts

`playwright/tests/regression/production-chat-journey.spec.mjs` runs at 390px and
1280px using explicit UI actions, without connect/send/selection/reconnect hooks.
`playwright/support/hermes_lifecycle_fixture.mjs` exposes bounded test-only receipt
and transition controls through the existing `serve_web.mjs` deterministic server.
These controls are not product routes or invented Agent capabilities.

Each fresh journey proves:

1. Explicit host/default-profile/session selection and isolation of a second
   session's canonical history.
2. One prompt, streamed synthetic text/tool activity, correlated Approve once,
   and authoritative completion; then one denied approval/cancelled run.
3. A third prompt and Stop acknowledged as `stopping`; composer blocked and no
   fourth submit. A test-only terminal gate permits later `cancelled` status,
   explicit Reconnect and canonical stopped history.
4. A fourth prompt whose SSE closes without a terminal event, with status/history
   temporarily unavailable (503). The fixture's recovery gate restores reads;
   explicit Reconnect retrieves canonical failed-run history without resending.
5. A usable fifth prompt and correlated approval. Fresh receipt assertions show
   exactly five ordered submits, three answers (once/deny/once), one Stop, exact
   profile/session/run/request identities, native `waiting_for_approval` status,
   final states, untouched second
   session, canonical user turns and the fifth request's canonical input history.
   Browser mutation observation permits only the expected direct run operations.

The scenario attaches one JSON file per width with eight stage receipts, the
native pending-approval status/request ID and observed mutation routes. Its
semantic input driver allows one explicit refocus if the editing bridge loses
focus. Before entering each prompt it traverses away by keyboard and clicks the
actual editor again, reactivating Flutter's input handlers after approval. It
fills that focused editor through Playwright's UI input action rather than
inserting keystrokes into a replaced bridge. This does not retry a submission.
It is not single-tap Android focus/IME evidence.
The compact flow also dismisses the existing voice tip explicitly; no speech is
used in this journey.

Focused new regressions live in
`test/core/hermes/channel/hermes_api_channel_tests/stop_outcome_tests.dart` and
`test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart`.
The nonempty foreign-history regression and cleanup matrix in
`test/core/hermes/channel/hermes_api_channel_tests/run_failure_tests.dart` cover
all three terminal statuses, nonterminal/unknown/error/stale status, volatile and
durable ownership, and failed lease admission. They assert no foreign read or
published state, exact uncertain leases, no reconnect replay and a usable next
run with only the requested owner's canonical model context.
The explicit-owner cleanup matrix also tests volatile and durable guards after
nonterminal/unknown/error/stale status or missing Stop support, local cancellation,
terminal reconciliation and a subsequent run with the selected canonical context.
`native_approval_tests.dart` and `client/hermes_api_approval_test.dart` additionally
prove native once/deny exact correlation, native-ID precedence over an alias,
stale/replaced same-run conflicts without a FIFO answer, in-flight/answered reuse
rejection, zero reconnect replay and the genuinely idless legacy request shape.

## Reproduce

Use installed tools without upgrading dependencies. Observed executor tools:
Flutter 3.47.5 / Dart 3.13.4, Node v26.5.1; this is not the intended 3.44.2 SDK.

```sh
/opt/flutter/bin/flutter analyze --no-pub
/opt/flutter/bin/flutter test --no-pub --concurrency=1 \
  test/core/hermes test/features/hermes_chat --reporter expanded
/opt/flutter/bin/flutter build web --release -t lib/main_e2e.dart
node --check serve_web.mjs
node --check playwright/support/hermes_lifecycle_fixture.mjs
node --check playwright/tests/regression/production-chat-journey.spec.mjs
# Separate terminal; use free loopback ports, then stop your server afterward.
PORT=9028 HERMES_E2E_PORT=9029 node serve_web.mjs
curl --fail http://127.0.0.1:9029/health
CHROME_EXECUTABLE=/opt/data/cache/wing-playwright/chromium-1228/chrome-linux64/chrome \
  WING_APP_URL=http://127.0.0.1:9028/ HERMES_E2E_PORT=9029 \
  npx playwright test \
  playwright/tests/regression/production-chat-journey.spec.mjs \
  playwright/tests/regression/hermes-lifecycle.spec.mjs \
  playwright/tests/regression/chat-tts.spec.mjs \
  playwright/tests/regression/chat-approval-confirmations.spec.mjs \
  playwright/tests/regression/browser-cors-streams.spec.mjs \
  playwright/tests/regression/session-restoration.spec.mjs \
  playwright/tests/regression/chat-window.spec.mjs \
  playwright/tests/regression/session-model-picker.spec.mjs \
  playwright/tests/regression/hermes-smoke.spec.mjs \
  --workers=1 --retries=0 --reporter=line
git diff --check
```

Executor revision self-verification: 1,214 affected Flutter tests and 46 compiled Chromium
checks passed, including both new integrated journeys and parent restoration,
window and picker regressions. Analyze, fresh release build, changed handwritten
Dart format and Node syntax checks passed. The build retains known flutter_tts
Wasm dry-run and Cupertino font warnings; Wasm is not qualified. No Wing Link
files changed, so no Go qualification is claimed.

## Remaining qualification gates

Only Linux Flutter unit/widgets and compiled JS-release Chromium were exercised.
This does not qualify actual Agent/provider inference, deployed authentication,
physical Android/process death/secure storage/TalkBack/IME, iOS, native desktop,
voice/acoustic behavior, push, signed distribution or full Desktop parity.
The browser profile is explicitly `default`; named-profile credential/query
isolation is covered by real-client Flutter regressions, not live browser auth.
Actual generation needs a disposable backend/provider/model, authorized harmless
input/tool, network and billing limit, and private secure credential input.
Android needs a named accessible device/emulator and OS/API. These remain the
separate [roadmap gates](../../ROADMAP.md#blockers-and-the-smallest-unblock-choices).
