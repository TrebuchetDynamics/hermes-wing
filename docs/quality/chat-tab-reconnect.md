# Two session-owned tabs: bounded reconnect qualification

Task: `DOC-PARITY-TAB-RECONNECT-CONTRACT`. This is offline Wing behavior evidence,
not complete Desktop parity or Android/SSH qualification.

## Reference and authority

Read-only official reference: Hermes Agent
`158fd638da1629c8e62caf9ade1515d162def8ab`.

- Desktop [`reconcileBusyStatesOnReconnect`, session-states.ts:1093–1184][desktop]
  scopes recovery to the affected connection and preserves unrelated live work.
  Its [nearest regressions:130–183][desktop-tests] protect the other connection's
  session and turn clock. Wing preserves that outcome using its existing direct
  API channel; this is not a port of Desktop's JSON-RPC transport.
- Agent [`_load_owned_run`, status/events:1036–1140][agent] authenticates the exact
  run and exposes pollable status separately from the SSE subscriber. [Stop:1253–1275][stop]
  returns `stopping`, not proof of termination. [The status regression:522–551][agent-test]
  checks the explicit submitted session identity. These sources were inspected,
  not executed or changed.

[desktop]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/session-states.ts#L1093-L1184
[desktop-tests]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/session-states-reconnect.test.ts#L130-L183
[agent]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server_runs.py#L1036-L1140
[stop]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server_runs.py#L1253-L1275
[agent-test]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server_runs.py#L522-L551

## Change and trace

Previously, Chat's **Reconnect** rebuilt the channel even for a single lost run
stream on a still-connected API channel. That cancelled healthy sibling streams;
bootstrap could also select a different detached conversation. A fresh stream
showing the same running indicator was not proof of continuity.

[Chat recovery](../../lib/features/hermes_chat/screens/state/hermes_chat_connection.dart)
now reconciles an inactive selected run in place when recovery is unresolved
or another session is still streaming. Foreground EOF need not set the
selection-time recovery flag; a healthy sibling must still survive. Foreground
[resume recovery](../../lib/features/hermes_chat/screens/state/hermes_chat_lifecycle.dart)
uses that same path. Failed reads retain the existing recovery error and duplicate
submission guards; they do not fall through to a resend or another conversation.

The existing shared channel remains the authority adapter:

| Boundary | Existing source and invariant |
| --- | --- |
| Exact owner | [messaging:1723–1728](../../lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart#L1723-L1728): detached key includes endpoint, profile, session and run. SSH forwards use the reviewed stable owner, not a replacement local port. |
| Status/history | [messaging:2212–2307](../../lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart#L2212-L2307): matching terminal status plus canonical history releases the owner; failed/404/mismatched status retains it. |
| Late result | [sessions:81–166](../../lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart#L81-L166): connection/client, profile and selection generations fence status/history acceptance. Selecting an inactive session also retires only its old stream generation, so its pending EOF status cannot resurrect a resolved lease or failed transcript. Healthy sibling generations remain valid. |
| Full connection replacement | [connection:58–197](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart#L58-L197): retires the old connection, restores one selected detached owner; other retained owners recover lazily on explicit selection. It does **not** automatically reattach all background streams. |
| Presentation | [workspace](../../lib/features/hermes_chat/session/hermes_chat_session_workspace.dart) and [draft ownership](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart#L814-L880) retain only visited tab identities and volatile drafts, not shadow run state. |

No Agent code, capability gates, credentials, endpoints or mutation protocols were
changed. The [deterministic entrypoint](../../lib/main_e2e.dart) now uses the same
secure detached-owner store as the production provider, rather than omitting the
lease seam. Browser storage is not Android keystore/process-death evidence.

## Executed oracle

One new [actual-channel widget case](../../test/features/hermes_chat/screens/hermes_chat_session_workspace_test.dart)
starts B, retains its draft, starts A and loses A's SSE stream while A remains
selected. Without reselecting A, it holds both the original EOF status and an
explicit Reconnect status read. It switches back to B and waits for the explicit
reconciliation to settle after releasing that result. B keeps its original
subscription, exact owner, draft, text selection and keyboard focus; its original
stream still updates B only. Selecting A again restores canonical history.
Releasing the original stale `running` response afterward cannot resurrect A's
lease or failed transcript. The mutation ledger contains only the two deliberate
submissions. Red runs demonstrated sibling teardown with the previous admission
and canonical-history replacement without the target-only stream-generation fence.

The [compiled browser journey](../../playwright/tests/regression/chat-session-workspace.spec.mjs)
uses the [synthetic lifecycle fixture](../../playwright/support/hermes_lifecycle_fixture.mjs)
to disconnect background A while B is selected, fail A's status reads, then supply
canonical completion. At **390px and 1280px**, public Send/session/tab/Reconnect
controls exercise the delayed explicit-status race, awaiting E2E-only completion
counters after real channel reconciliation (not merely a server receipt). B's tab
control retains keyboard focus after the late result and its draft remains
visible. Receipts require exactly two owner-bound submissions, zero approvals,
zero Stop, zero unexpected writes, and exactly one B event subscription while B
remains awaiting approval. Browser request counts also reject attempted mutations,
including rejected writes. A's canonical reply appears only when deliberately
opened. The predecessor's Stop/close journeys remain intact.

The held integration failed **before disconnect**, entering B's draft: fixed
100ms semantic-click waits could leave no focused native editor. A controlled
focus-loss probe reproduced that timeout. Focus-event traces also showed a
transient focused editor losing focus before keyboard input. The final helper
uses bounded, settled **Tab traversal** to activate the public editor, refreshes
handles replaced by session transitions, and verifies draft admission. It does
not retry submissions or entire tests, extend the journey timeout, set controller
state, or weaken recovery assertions.

Validation (Flutter 3.44.2, Node 22.22.2, Linux host, Chromium):

```bash
flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_session_workspace_test.dart
flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_session_workspace_test.dart test/features/hermes_chat/screens/hermes_chat_reconnect_owner_test.dart test/features/hermes_chat/screens/hermes_chat_reconnect_read_owner_test.dart test/core/hermes/channel/hermes_recovery_read_admission_test.dart test/core/hermes/channel/hermes_api_channel_test.dart
flutter test --no-pub --concurrency=1 test/core/hermes/channel/
flutter analyze
flutter build web --release --no-pub -t lib/main_e2e.dart
```

The workspace module passes **13 tests**, the five focused modules **399**, and
the full channel directory **594** (overlapping coverage, not additive). Analysis,
changed-Dart formatting, changed-JavaScript syntax and `git diff --check` pass.
The final fixture build succeeds with existing optional Wasm/`flutter_tts` interop
and missing Cupertino-font warnings; this is a JavaScript build, not Wasm
qualification. Its `main.dart.js` SHA-256 is
`19ad56fbb27c49ce1f6162dc8c3bb455044cf5fa3f1788959e778561faeb0278`.

Browser execution uses `serve_web.mjs` on the assigned ports and a task-temporary
Playwright config with one worker, Chromium and **zero retries**. The four
`chat-session-workspace.spec.mjs` journeys plus two existing
`hermes-lifecycle.spec.mjs` journeys pass **three consecutive repetitions: 18/18**,
zero skipped or flaky results, after the final rebuild. The browser command uses
`--repeat-each=3 --max-failures=1` under `timeout 600`; repeated runs are a
qualification check, not a failure-retry policy. Local links were checked.
The full-suite integrated gate belongs to the coordinator, not this receipt.

## Remaining live qualification and update triggers

- Physical Android: two conversation runs through authenticated native SSH;
  tunnel loss and replacement, profile switching, stale old-generation events,
  canonical history and no send/approval/Stop replay; retain the sibling draft,
  selection and focus. No Android runtime was exercised here.
- Native/live Agent authentication, provider execution, OS suspension/process
  death and secure-store survival remain unqualified. No background-service or
  uninterrupted multi-profile stream claim follows from foreground switching.
- Native serve tabs remain unavailable; this change does not relax that gate.

Revisit this receipt when reconnect/resume admission, session-generation fences,
secure owner storage, tab/draft identity or the pinned official reference changes.
Related: [exact-owner reconnect](connection-owner-reconnect.md),
[canonical transcript recovery](chat-transcript-reconnect.md), and the
[reference/evidence boundary](../product/hermes-desktop-parity.md#reference-and-evidence-boundary).
