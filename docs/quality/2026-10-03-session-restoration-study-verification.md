# Exact-session restoration: independent focused verification

Date: 2026-10-03, local execution window 18:26–18:29 UTC−06:00.

## Verdict and scope

**PASS for the independently executed focused deterministic matrix only.**
The six-file restoration/switch matrix passed **116 tests**, and three precisely
selected existing client/channel regressions passed: **119 passing tests** across
the two successful commands. This is not full-repository acceptance, native board
acceptance, a tester/reviewer same-card receipt, or runtime/platform qualification.
No roadmap/card transition or external board operation was performed.

Source review found the remembered tuple takes the exact read/admission path,
not an inventory-default fallback. Existing tests exercise production directory,
channel, API client, SharedPreferences cache, and screen/draft wiring at different
seams. No implementation or existing test was changed by this verifier. The only
owned repository output is this report. The dirty `main` worktree (ahead one
commit) was preserved; concurrent workers mean this receipt is evidence of the
checkout exercised during the window, not an immutable clean revision.

## Toolchain and execution receipts

Commands ran from `/home/xel/git/gormes/hermes-wing`, using installed dependencies
and `--no-pub`; no installs, inference, upstream tests, or live Agent actions.

- `flutter --version`: exit 0; Flutter **3.44.2**, channel `[user-branch]`, framework
  revision `c9a6c48423`, engine revision `77e2e94772`; Dart **3.12.2**, DevTools
  **2.57.0**.
- `command -v flutter` and `readlink -f "$(command -v flutter)"`: exit 0;
  executable resolves through `/home/xel/.local/bin/flutter` to
  `/home/xel/flutter/bin/flutter`. The runbook's `/opt/flutter/bin/flutter` is not
  the command used for this receipt.

### Restoration matrix

Executed twice, verbatim:

```sh
flutter --no-version-check test --no-pub --concurrency=1 --reporter=expanded test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart test/features/hermes_chat/gateways/gateway_selection_write_race_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart test/features/hermes_chat/screens/hermes_chat_restoration_draft_race_test.dart test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart
```

First attempt: **exit 1, zero tests passed, six suite-loading failures**. The
compiler could not read Flutter or pub package imports. Narrow inspection of
`.dart_tool/package_config.json` found 142 of 143 package entries pointed at
missing absolute roots, including a prior scratch Flutter SDK and a prior pub
cache. Missing imports caused cascading undefined Flutter/test symbols; this was
not a restoration assertion failure. This worker did not edit package metadata,
run pub get, install dependencies, or patch implementation. Package roots became
available between attempts in the shared workspace; this verifier did not observe
or attribute the intervening repair. Final read-only inspection found zero missing
absolute roots.

Second attempt: **exit 0, `00:24 +116: All tests passed!`**. No failed or skipped
tests were reported in the successful matrix output.

### Precise existing client/channel regressions

Executed with Python `subprocess.run` using this exact argument sequence:

```sh
flutter --no-version-check test --no-pub --concurrency=1 --reporter=expanded test/core/hermes/hermes_api_test.dart test/core/hermes/channel/hermes_api_channel_test.dart --name 'session inventory preserves Agent pagination metadata|session inventory bounds the number of returned sessions|history metadata does not cross profile boundaries'
```

**Exit 0, `00:00 +3: All tests passed!`**. These cover Agent inventory pagination,
its 200-row client bound, and prevention of history-usage metadata inheritance
across profiles. This was a name-filtered selection, not execution of the entire
API/channel suites.

`git diff --check`: exit 0 before and after report creation.
`git diff --no-index --check /dev/null docs/quality/2026-10-03-session-restoration-study-verification.md`:
exit 0. A Python Markdown-link existence check found 26 local links and no
missing targets (exit 0). Broader build, analyze, CI, and release gates are not
claimed here.

## Requirement-to-source-and-test evidence

Paths below refer to the live Wing checkout, not historical synthesis or upstream
runtime evidence. Line ranges are navigation hints for the inspected version.

| Requirement | Production source | Executed evidence and limits |
| --- | --- | --- |
| Restore off-page A, not inventory B | [directory](../../lib/features/hermes_chat/gateways/hermes_gateway_directory.dart), lines 1031–1114; [sessions](../../lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart), lines 15–55 | [startup tests](../../test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart), lines 150–180: off-page and already-loaded A, coder query scope, canonical message ID, remembered A, no B persistence, no POST. Harness uses real directory/channel/client with injected HTTP and synthetic credentials, not a deployed Agent. |
| Exact operation/grants and metadata identity | [sessions](../../lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart), lines 28–46; [client](../../lib/core/hermes/client/hermes_api_client.dart), lines 152–163 | [adversarial tests](../../test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart), lines 29–182: unsupported schema, missing operations, wrong metadata method/path, ungranted metadata/history scopes, no invented grant for empty scope declarations, wrong object/ID/type/shape. Unsupported admission issues no metadata lookup. |
| Denied/not-found/transient failure keeps target | [failure mapping](../../lib/features/hermes_chat/gateways/hermes_gateway_directory.dart), lines 18–42, 1098–1114 | Adversarial tests, lines 76–164, 203–227: metadata/history 401/403/404/503 and injected timeout; target retained, no active default, no saved replacement, Retry returns to exact A. Generic 404 is not deletion proof. Timeout/status exceptions are injected, not elapsed network-deadline or real HTTP-server qualification. |
| A→B→A and stale ownership fences | [sessions](../../lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart), lines 19–54, 67–108; [channel cache identity](../../lib/core/hermes/channel/hermes_api_channel.dart), lines 129–140 | Adversarial tests, lines 229–340: parked metadata/history across directory, Remove, disposal, manual B, another profile, another host, and host A→B→A reuse with identical session ID. Final identity/canonical transcript/pointer belong to the latest owner; stale-A turns and approval events are absent. This is deterministic host/client-incarnation reuse, not OS process restart. |
| Fence hidden caches before transcript publication | [history fetch](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart), lines 329–391; [session selection](../../lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart), lines 90–118 | Source checks connection/profile/caller acceptance before changing pagination, run-history snapshot or recent-turn cache; selection additionally checks transcript-list identity. Race tests observe visible state/canonical IDs and pointer, not direct enumeration of the private caches. No new cache-introspection test was added. |
| Pointer fences at storage boundary | [cache](../../lib/features/hermes_chat/gateways/gateway_contact_cache.dart), lines 82–101; [directory persistence](../../lib/features/hermes_chat/gateways/hermes_gateway_directory.dart), lines 1182–1237 | [write-race tests](../../test/features/hermes_chat/gateways/gateway_selection_write_race_test.dart), lines 20–160: real cache/SharedPreferences API over parked in-memory platform implementation; acquire-time validity prevents writes, issued-write serialization prevents an old write undoing later directory/Remove/manual choice; final stored pointer readback asserted. Not a real disk/keystore crash test. |
| Draft ownership, stale Send/new-session rejection | [screen](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart), lines 589–606, 734–787; [draft store](../../lib/features/hermes_chat/composer/hermes_composer_draft_store.dart), lines 7–11, 83–111; [message flow](../../lib/features/hermes_chat/composer/hermes_chat_message_flow.dart), lines 25–27; [session actions](../../lib/features/hermes_chat/session/hermes_chat_session_actions.dart), lines 4–35 | [restoration screen tests](../../test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart), lines 168–347: no writable B while unsettled, Ctrl+N and stale Send rejected, picker cancel keeps A, actual choice clears old ownership before B, scoped A/B/A text drafts. [real draft-race tests](../../test/features/hermes_chat/screens/hermes_chat_restoration_draft_race_test.dart), lines 18–127: actual directory/channel/client plus screen with parked metadata/history cannot replace the latest chosen B draft or pointer, no POST. |
| Accessible pending/failure and foreground recovery | [screen admission](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart), lines 845 onward; [restoration layout](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart), lines 478 onward | Restoration screen cases cover 390px, 200% text, reduced motion, live-region/header semantics, keyboard Retry/Choose, Escape/focus return. [gateway-switch tests](../../test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart), lines 1731–1939: real directory plus fake channel under actual widget lifecycle resume; default-profile picker blocked before intended profile loads, no interim pointer writes, Retry/Choose recovery. This is Flutter widget semantics, not physical screen-reader/browser qualification. |
| Remembered Telegram is not a create action | [directory](../../lib/features/hermes_chat/gateways/hermes_gateway_directory.dart), lines 1098–1145 | Adversarial remembered-Telegram case restores canonical history with zero POST; ordinary explicit-open Telegram isolation remains outside remembered restoration. Gateway-switch matrix also exercises normal authorized create flows, so zero creates/sends is a restoration-journey claim, not a claim about every test in the six-file command. |

## Gaps and non-evidence boundary

- No restoration failure reproduced after package-root availability recovered;
  no source fix is justified by these results. The initial failure was test
  environment/package-resolution failure, not evidence of broken restoration.
- Exact metadata reads have no separate `getSession` unit-test match in the
  inspected `test/core/hermes` search; validation is exercised through the real
  client inside the restoration harness. Its injected transport does not prove
  server registration, request deadlines, redirects, or credential rejection by
  an installed Agent.
- The real restoration harness advertises query-profile scope. It does not
  independently exercise enrolled `/p/<id>` restoration or a populated detached
  run lease. Production reuses `_selectSession` and detached-run reconciliation,
  but the focused run does not newly qualify detached-run uncertainty/replay,
  attachment/approval isolation, endpoint storage, long-history windowing, or
  session-model-picker behavior across their complete regression suites.
- The initial inventory fixture has B (and optionally A) plus pagination metadata;
  this is an off-page-admission test, not a genuine 50-row/10-row browser paging
  journey. [The runbook](../runbooks/chat-session-restoration.md) names a separate
  [Playwright restoration test](../../playwright/tests/regression/session-restoration.spec.mjs).
  Neither browser build nor Playwright execution was run here; parent owns that
  proportional-gate decision. Existing runbook qualification claims were not
  adopted as this worker's execution receipts.
- Private-cache admission and transcript identity fences were source-reviewed;
  race tests check final public state. They do not separately expose every private
  cache write or simulate every synchronous listener/streamed update interleaving.
- No immutable before/after source snapshot was taken while concurrent work ran.
  Re-run affected checks if restoration production/tests change after this window.
- No full Flutter analyze/test gate, Go/upstream tests, browser build, CI, signed
  distribution or release acceptance. No live host/provider, inference, mobile
  process death/secure storage, Android, iOS, native GTK app, voice/acoustic,
  push or full Desktop parity qualification. Linux-hosted Flutter unit/widget
  execution is the only exercised target.

This receipt supplies independent focused test execution and source inspection.
It does not accept or transition `t_f098a32e`, replace native tester/reviewer
same-card acceptance, or upgrade unsupported runtime operations into support.
