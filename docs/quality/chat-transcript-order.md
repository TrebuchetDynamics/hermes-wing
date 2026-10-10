# Streamed transcript order and adaptive approval recovery

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card: `t_b9368977`. Task: `VERIFY-CHAT-TRANSCRIPT-ORDER`.
Goal: `CHAT-FIDELITY`, still partial. This receipt qualifies deterministic Flutter
widgets and compiled Chromium, not live Agent or native Desktop execution.

## Delivered behavior

New widget coverage proves canonical request → reasoning → commentary → adjacent
tools → answer order without duplicate activity. Tab/Enter/Space operate the
reasoning disclosure through 390px compact and 1280px wide return; grouped tools
remain readable in their original order. This card does not change the timeline:
its predecessor reasoning/disclosure implementation already passes these checks.

A real defect was reproduced: switching profiles while reusing a profile-local
session ID left the old profile's actionable approval visible. The approval queue
now filters explicit profile identity at display and again at decision activation.
The nullable-profile compatibility behavior is unchanged. A focused queue test
rejects the stale decision and then accepts exactly the current profile's decision.
New widget journeys cover session, profile and channel replacement while approval
focus is active, stale keyboard activation and late old-owner approval emission.

Two new compiled Chromium journeys send one synthetic request through the actual
API channel. They assert visible vertical order while approval is pending and after
completion, exact row uniqueness, compact/wide reasoning readability, keyboard
escape/return and rendered focus-pixel changes. The completion journey answers
exactly once and checks File activity before Web activity. The replacement journey
selects the other session using the visible keyboard control, removes the obsolete
approval/reasoning/Stop controls, and activates the replacement composer without
replaying anything. Both assert exact mutations: one run submission; zero Stop;
zero decisions for replacement or exactly one `once` decision for completion.
The old run stays owned by `e2e-hermes-session`, not the replacement session.

## Authority and source boundary

Agent remains authoritative. No API, event, capability, dependency, Wing Link or
upstream change was made. The fixed fixture emits existing `reasoning.available`,
`message.delta`, `tool.started`, `tool.completed`, approval and completion events;
no provider or host tool executes.

Inspected source contracts:

- Agent `gateway/platforms/api_server_runs.py:92-97`: existing reasoning/tool fields.
- Agent `tests/gateway/test_api_server_runs.py`: interim-commentary forwarding,
  completed-tool result preview, terminal stream and exact pending approval tests.
- Wing `hermes_api_channel_messaging.dart:1850-1945`: owned-run admission,
  reasoning insertion, commentary segmentation at tools, approval correlation and
  terminal completion. This shared path was not patched around an upstream API.
- Desktop `MessageList.tsx:212-270`: preserves history rows and protects pending
  requests while projecting the transcript. This is read-only source research,
  not a Desktop runtime result or a claim of identical approval placement.

Wing HEAD: `1afe1307e37ee1ddfa1f7d67ad047509e99c8784`.
Agent reference HEAD: `158fd638da1629c8e62caf9ade1515d162def8ab`.
Desktop reference HEAD: `withdrawn reference revision`.
These identify local checkouts, not current upstream releases.

The tested Wing tree includes predecessor dirty work. Selected SHA-256 identities:

| Source | SHA-256 |
| --- | --- |
| approval queue | `a0d90d4555e7c353716fe4a9fa789dacf69d0fb5b0b203a705da63e42facf496` |
| existing timeline | `13f53c8a9833dfefe611b03e51d8dfcac3eb63f37665b72be7fe6071af04b4ee` |
| new widget journey | `d53da5a5276c8f7f7888bdd151787a89e269a7d747367167572e676873273d93` |
| new queue regression | `f5cad4b6ab7ff572076a92df454959236189078558e1affae2f6bf5a065328b5` |
| new Chromium journey | `edbf491dcde0eb25c6a1fa4c1cc1fac99b0468aa613be4a868fcc50974f6bfa6` |
| scoped fixture server | `e0abc8c6d4c243d56a88e875d04a094a7dde9d794db5d6d63b5e4ea02f6c145d` |
| exercised compiled `main.dart.js` | `79a4a99489d1d2444a420b783700bae008f9df597f08e1ceaae2c33c3a7a856e` |

The scoped server snapshot contains HEAD plus only this card's six fixture hooks;
final Chromium checks also passed against this snapshot. The helper commit uses
that snapshot via `GIT_WORK_TREE`, not the co-owned full `serve_web.mjs` diff.
Timeline, screen/layout/lifecycle, localization, main_e2e and shared ledger
predecessor changes remain outside this commit. The receipt is composed-tree
qualification; the isolated branch alone is not claimed to contain predecessor
reasoning-disclosure work. Full dependency-closure/packaged execution is NOT_CHECKED.

## Executed acceptance checks

Commands ran from the Wing repository on Linux. Each final command returned 0.

```sh
dart format --output=none --set-exit-if-changed lib/features/hermes_chat/messaging/approvals/hermes_approval_queue.dart test/features/hermes_chat/messaging/approvals/hermes_approval_profile_owner_test.dart test/features/hermes_chat/screens/hermes_chat_transcript_order_test.dart
timeout 3m flutter analyze
timeout 4m flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_transcript_order_test.dart test/features/hermes_chat/messaging/approvals/hermes_approval_profile_owner_test.dart test/features/hermes_chat/messaging/approvals/hermes_approval_queue_test.dart test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart test/features/hermes_chat/screens/hermes_reasoning_disclosure_accessibility_test.dart test/features/hermes_chat/screens/hermes_reasoning_disclosure_adaptive_test.dart test/features/hermes_chat/screens/hermes_reasoning_disclosure_recovery_test.dart --reporter expanded
timeout 12m flutter build web --release -t lib/main_e2e.dart --output=.dart_tool/transcript-order/web
CHROME_EXECUTABLE=/usr/bin/chromium WING_APP_URL=http://127.0.0.1:8897/ NODE_OPTIONS=--max-old-space-size=2048 timeout 6m npx playwright test -c .dart_tool/transcript-order/playwright.config.mjs playwright/tests/regression/chat-transcript-order.spec.mjs --workers=1
node --check playwright/support/hermes_transcript_order_fixture.mjs
node --check playwright/tests/regression/chat-transcript-order.spec.mjs
node --check .dart_tool/transcript-order/commit-source/serve_web.mjs
git diff --check -- lib/features/hermes_chat/messaging/approvals/hermes_approval_queue.dart serve_web.mjs
```

Formatter: 3 files, no changes. Analyzer: no issues. Focused tests: 129 passed.
Fresh release web build: passed; existing flutter_tts Wasm dry-run incompatibilities
and Cupertino font warnings remain. Wasm support is not claimed. Browser: 2 passed,
no retries, skips or flakes; system Chromium 152.0.7977.75. Ports 8897/8898 were
checked free, owned by this run and health-checked before use. The JSON reporter
resolves under `.dart_tool/transcript-order/.dart_tool/transcript-order/browser.json`.
The ignored config imports the standard config, sets workers=1 and retries=0,
and isolates output under `.dart_tool/transcript-order/browser-results`.

Retained ignored evidence: `.dart_tool/transcript-order/` contains `widget-red.log`,
`widget-green.log`, `widgets.log`, `format.log`, `analyze.log`, `build.log`,
`browser.log`, compiled-browser observations and `evidence.json`. RED contains
both the actual stale-profile failure and an initial test-label mistake; the latter
was a harness correction, not a timeline defect. Earlier browser failures were
missing Playwright browser binary, incorrect semantic names and editor-focus
observation; using installed Chromium and source-observed names resolved them.
Final assertions were not removed. Large owned web output is deleted after receipt
capture; its hash identifies the exercised artifact but does not distribute it.

## Acceptance mapping and remaining limits

1. Ordering, unique activity, keyboard disclosure and adaptive return: new widget
   and compiled-browser journeys pass against the unchanged predecessor timeline.
2. Owner replacement and no replay: new widget session/profile/channel journeys,
   stale queue decision test and Chromium session replacement pass. Profile-local
   approval visibility/activation was repaired; browser profile/channel replacement
   is not separately qualified. Existing production channel owner fencing remains.
3. Format/analyze/focused-widget/fresh-web/focused-Chromium/diff: executed as above;
   ledger task/evidence/render/validate and scoped helper commit accompany review.

NOT_CHECKED: native Linux/macOS/Windows app interaction, Android/device, screen
reader, live Agent/provider/tool, reconnect/history recovery, full suite, Wasm,
packaging/release/deployment. `VERIFY-CHAT-TRANSCRIPT-RECONNECT` remains open;
`CHAT-FIDELITY` is not complete parity. No owner questions or new defaults were
needed. Native review is the final implementation handoff, not prior approval.
