# Desktop continuation — Stop/Reconnect owner attribution

## Scope and admission

Read-only investigation of the next checkpoint in the [goal ledger](../plans/2026-10-03-desktop-port-goal.md), following the [daily workflow](../plans/2026-10-03-desktop-daily-workflow.md) and [previous failing gate](2026-10-03-autogoal-model-scope.md). Only this receipt and the goal ledger were edited. Production, tests, fixtures, ROADMAP and all upstreams remain unchanged by this occurrence.

At 2026-10-04T05:33:28Z, OS parent/cwd inspection identified `flutter test --concurrency=1` PID 1579580 under `npm run test` PID 1579567 in this worktree. The primary conversation's latest dispatch also records `npm run test`. Occurrence-local process/delegation lists were empty; they do not prove global exclusivity. No Flutter/build/browser command, service, display or worker was launched here. No completion/result is attributed to the competing primary test process.

Dependency topology: one direct owner, investigation before regression implementation. No parallel handoff, inference, installs, personal runtime access, scheduler changes or acceptance-card changes. `omh_run_summary` is not exposed by this host.

## Evidence and source index

Prior execution artifacts, not new browser execution:

- Scratch `autogoal-model-scope/integrated.json` parses to **0 passing / 2 failed / 0 skipped / 0 flaky**, one attempt each, at 390 and 1280px. Both fail spec line 155 after Reconnect, following a successful terminal-control HTTP assertion.
- The 1280px error-context snapshot explicitly says **Active Hermes session Synthetic untouched session**, shows its isolated history, and shows **Hermes model**, not the selected `alpha/model-99`.
- The 390px snapshot also shows only isolated history and **Hermes model**, with an enabled normal composer. It does not expose a session ID; exact identity at this width is not established from that snapshot alone.
- These snapshots contradict a selector-only account: the rendered wide surface has changed conversation/model. The test stores staged receipts only at final success (spec lines 218–220), so this failed run does not supply post-reconnect saved-pointer/status-read/mutation receipts. Do not invent those observations.

| Source | Indexed evidence |
| --- | --- |
| [Browser regression](../../playwright/tests/regression/desktop-daily-workflow.spec.mjs) | Lines 101–113 deliberately select the session from page two and assert its saved pointer; 115–127 confirm the exact model; 152–155 terminalize run_2 then invoke real Reconnect. |
| [Chat connection](../../lib/features/hermes_chat/screens/state/hermes_chat_connection.dart) | Lines 168–206 deduplicate Reconnect, resolve endpoint/credential and call `_connectToEndpoint`; 221–241 invoke `channel.connect` without deferred selection or captured profile/session restoration. |
| [Channel connection](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart) | Lines 76–93 load page zero and select `detachedActiveId ?? sessions.firstOrNull?.id` unless selection is explicitly deferred. Lines 103–145 fetch and publish that chosen conversation. |
| [Run recovery](../../lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart) | Lines 2057–2089 restrict connect-time detached candidates to IDs present in the supplied inventory page. The exact off-page owner therefore cannot qualify through this path, even if its detached lease exists. |
| [Daily wrapper](../../scripts/support/desktop_daily_workflow_fixture.mjs) | Lines 103–107 fetch authoritative inventory; 141–150 order non-target first and cap each page at one. The target remains off page zero by design. |
| [Lifecycle fixture](../../playwright/support/hermes_lifecycle_fixture.mjs) | Lines 43–54 append stopped canonical history to the run's own session and set cancelled; history reads are recorded at 89–94. No terminal reset or session switch is present here. |
| [Directory](../../lib/features/hermes_chat/gateways/hermes_gateway_directory.dart) | Lines 1031–1114 provide an existing exact preferred-session activation path with deferred connect/profile selection and `restoreSession`; 1182–1237 automatically remember a connected active selection. A direct default-selection reconnect can consequently persist the replacement pointer; that persistence is a source prediction, not an observed failed-run receipt. |
| [Provider wiring](../../lib/features/hermes_chat/providers/hermes_channel_provider.dart) | Lines 47–54 give the directory the same channel used by Chat. The reconnect path does not independently restore the directory owner. |
| [Working legacy journey](../../playwright/tests/regression/production-chat-journey.spec.mjs) | Lines 144–150 use the same terminal/real-Reconnect assertion without the daily off-page projection. Previous receipt reports legacy success; this occurrence did not rerun it. |
| [Nearest recovery tests](../../test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart) | Lines 2011–2037 assert uncertain-stop recovery affordances and send blocking, not owner preservation after clicking Reconnect. |
| [Auth recovery tests](../../test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart) | Lines 276–367 deliberately bypass saved-directory routing and assert equivalent credential selection/duplicate-tap exclusion. They do not exercise an off-page saved owner. |

Recent scoped Git diff inspection found deferred-selection support in channel connect and a session-panel restoration guard, but no owner restoration added to the Reconnect handler. HEAD was `ca149a82189c8c9e5abd98b376bfeae1e43f6f3f`; dirty HEAD is not an execution-source snapshot.

## Attribution and ranked next work

**Leading source-backed attribution:** Chat's direct Reconnect re-enters initial page-zero selection rather than restoring its explicit owner. The off-page fixture intentionally removes that owner from initial inventory. Connect-time run recovery also filters it out. This explains the wide artifact's replacement conversation/model. No evidence here supports changing Stop authorization, relaxing fixture pagination, weakening the semantic assertion, or patching Agent.

Remaining hypotheses and discriminating evidence:

1. **Reconnect owner loss (strongest).** Reproduce with the production channel/directory and real Chat Reconnect button, page-zero B and remembered off-page A. Assert active/saved profile/session/model immediately before and after the click; count exact metadata/history/run-status requests. Expected current failure: B selected instead of A.
2. **Fixture terminal/history composition (less likely).** Inspect terminal response and exact A history/status readbacks at failure. Source appends canonical content to A; it does not explain the wide snapshot choosing B. Preserve fixture authorization/discovery assertions.
3. **Semantic-only mismatch (contradicted by wide snapshot).** Only consider after active/saved owner and canonical A history remain correct. Changing the turn locator now would hide the observed ownership regression.

Next bounded implementation proposal, conditional on fresh exclusive admission and a ledger lease:

- New focused regression file `test/features/hermes_chat/screens/hermes_chat_reconnect_owner_test.dart`; production write scope only `lib/features/hermes_chat/screens/state/hermes_chat_connection.dart`. Treat existing directory/channel/contracts and browser spec as read-only initially; expand scope only if a reproduced shared invariant requires it.
- PIN/RED: real saved directory plus production channel, off-page exact session, non-default profile, confirmed model and an uncertain stopped run; click the real Reconnect control. Capture nonzero intended identity failure before editing production. No mocked `connect` success as the sole proof.
- GREEN: smallest owner-aware restoration using existing seams. Preserve equivalent-endpoint credential rules, duplicate-tap guard, stale owner/generation fencing, unavailable/revoked restoration failure and send blocking. No fallback session on failed exact lookup, mutation replay, automatic resend or session creation.
- SURFACE: fresh `flutter build web --release --no-pub -t lib/main_e2e.dart`, then daily continuous regression at both widths with zero retries; include legacy Chat/picker/restoration journeys. Capture failure-stage receipts even if a later assertion fails, without relaxing acceptance.
- Exit criteria: original session/profile/model and canonical stopped history survive Reconnect, route leave/return and reload; three deliberate submits, two correlated approvals, one authoritative Stop, unchanged two deliberate model-lock attempts, zero restoration mutations/unexpected writes. Missing/revoked authority must retain recovery ownership, not select B.
- Relevant commands: `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_reconnect_owner_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart`; changed-file formatter and `flutter analyze`; fresh web build; `./node_modules/.bin/playwright test playwright/tests/regression/desktop-daily-workflow.spec.mjs playwright/tests/regression/production-chat-journey.spec.mjs playwright/tests/regression/session-model-picker.spec.mjs playwright/tests/regression/session-restoration.spec.mjs --workers=1 --retries=0` against an exclusively owned fixture. Do not run while primary Flutter work is active.

## This occurrence's verification and cleanup

Scratch evidence: `/home/xel/.hermes/profiles/wing/cache/scratch/desktop-cron-2333-stop-attribution/`.

- Prior Playwright JSON parsing: exit 0; `prior-failure-summary.json` includes cases, retry/status/error details and both error-context SHA-256 hashes.
- Scoped source manifest: `sources-before.json`, with ten inspected implementation/test/fixture source files. Closing gate compares identical hashes and writes `checks.json`.
- Read-only scoped `git diff` and `git log -1`: exit 0. No staged/committed changes.
- Closing gate checks scoped `git diff --check`, receipt/ledger whitespace and receipt local links; exact results recorded in `checks.json`.
- No QA resources were created, so none require teardown. Primary process was neither stopped nor claimed. No new native/browser/provider/runtime/card acceptance. Native/private-auth gates remain open, not retried.

This is attribution from existing failing browser artifacts plus inspected live source; a new minimized RED and verified fix remain the next checkpoint, not completed work.
