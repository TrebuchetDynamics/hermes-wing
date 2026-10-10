# Grouped recents keyboard and pending-owner recovery

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card `t_1e01f86b`, task `VERIFY-GROUPED-RECENTS-RECOVERY`, goal
`PARITY-COMPOSITION`. Bounded acceptance is executor-verified; native same-card
review follows the handoff. Approval and broad composition parity are not claimed.

## Delivered and unchanged boundaries

New targets:
- [Recovery widgets](../../test/shared/widgets/app_shell_grouped_recents_recovery_test.dart)
- [Compiled browser journey](../../playwright/tests/regression/grouped-recents-recovery.spec.mjs)
- This receipt, plus narrow goals.py task/evidence/render updates.

The interrupted first attempt left both targets and the isolated QA copy intact.
The resumed run read them, verified every copied source against the live worktree,
and executed the final checks below. No production, fixture, predecessor test,
localization, shared product document, upstream or runtime file was edited.
The existing dirty checkout is input, not this card's implementation diff.

Use the [accepted reference](grouped-recents-reference.md#observable-acceptance-oracles-for-implementation)
and [predecessor receipt](grouped-recents-implementation.md#acceptance-mapping-and-retained-evidence).
The [client ADR](../adr/client.md#decision) remains binding. Source headings are
noncollapsible: hide/restore means existing sidebar collapse/expand or compact
sidebar removal and wide return. No group disclosure, Project/path inference,
new state, metadata, persistence, API or dependency is introduced. Agent remains
the session authority; Wing Link is untouched.

Live source traced: `ShellSessionAccess._activate` at
`lib/features/hermes_chat/widgets/shell_session_access.dart:367-439`, including
captured channel identity, generation/current admission and acknowledged navigation.
The unchanged `DelayedChannel.selectSession` at
`test/shared/widgets/app_shell_global_session_access_test.dart:53-58` waits for its
gate then rechecks `canAccept`. The new widgets reuse that fake and its shell/router.

## Acceptance evidence

1. Two recovery widgets use actual Tab/Shift+Tab and Enter/Space at 1280x600,
   2x text. Collapse/expand itself uses keyboard activation. Compact is 390x844.
   Hidden inventory/rows are absent through forward/reverse traversal. Restored
   equal-title active `a1` and nonactive `b1` controls regain visible, viewport-bound
   focus; each explicit Open selects only its exact ID once. No Flutter exception
   or overflow was observed.
2. Six pending widgets combine profile A-B-A or identical-ID channel replacement
   with visible, collapsed and compact return. An explicit pending `b1` Open is
   recorded once; late success leaves both owners on `a1`, messages empty and route
   `/tools`, without stale error. Disconnect/reconnect adds no selection. Fresh
   keyboard Space is accepted once afterward. Assertions cover no incidental
   New, submissions/attachments, model/approval/Stop/profile/connect/paging work,
   and no directory construction. Explicit Open counters are separate from zeros.
3. One freshly compiled Chromium test uses real keyboard controls, same-row
   focused/unfocused captures and bounded focus/viewport assertions. Actual
   fixture history responses are fetched then held with Playwright route control;
   no synthetic success payload replaces a failed backend. Pending collapse,
   compact return and identical-origin/profile/session connection-generation
   replacement reject late navigation and history admission. Browser A-B-A is not
   claimed; that discriminating case is exercised in production-shell widgets.

Browser receipt: 33 app requests, all GET. Three explicitly initiated fixture
connections account for nine bootstrap reads each. Six exact session-history reads
account for two keyboard Opens, three pending Opens, and one final fresh Space
Open. Each targets `/api/sessions/synthetic-recents-recovery/messages` with
`profile=default`, `limit=500`, `offset=0`, `order=latest`. Traversal, collapse,
expand, adaptive return and late-response settlement add zero requests. There are
no mutation requests or page errors. Fixture reset/seed calls use the test request
client and are setup, not incidental app requests. Final tuple is connected,
profile `default`, session `synthetic-recents-recovery`, no error.

Rendered evidence inspected locally: restored identical-owner row retains its
readable label; focus adds a light gray fill compared with the unfocused outlined
white row. Compact Tools has no recents/sidebar and no observed overflow. Wide
return shows the source heading and exact selected row, readable and contained in
the sidebar. Keyboard reach assertions complement pixels; no screen-reader or
contrast-standard qualification is inferred from screenshots.

## Exact final executed checks

QA cwd: `<repo>/build/t_1e01f86b/qa`.
It contains Wing-only copied source/test/assets/web and unchanged fixture, and
reuses installed Node dependencies. Upstream clones are not validation inputs.

```sh
dart format --output=none --set-exit-if-changed test/shared/widgets/app_shell_grouped_recents_recovery_test.dart
flutter analyze
flutter test --no-pub --concurrency=1 test/shared/widgets/app_shell_grouped_recents_recovery_test.dart test/shared/widgets/app_shell_grouped_recents_test.dart test/shared/widgets/app_shell_global_session_access_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart --reporter expanded
flutter build web --release -t lib/main_e2e.dart
PORT=8893 HERMES_E2E_PORT=8894 node serve_web.mjs
curl --fail --silent --output /dev/null http://127.0.0.1:8893/
WING_APP_URL=http://127.0.0.1:8893/ CHROME_EXECUTABLE=/usr/bin/chromium NODE_OPTIONS=--max-old-space-size=2048 npx playwright test --config=playwright.config.mjs playwright/tests/regression/grouped-recents-recovery.spec.mjs --workers=1 --output=test-results/grouped-recents-recovery
```

Final formatter: one file, zero changes; analyzer: no issues; focused suite:
71 passing tests, including eight new recovery cases; release web build: passed;
Chromium: one passed, zero skipped/unexpected/flaky, no retry. Existing flutter_tts
Wasm dry-run and missing Cupertino font warnings remain; this is JavaScript web
qualification, not Wasm support. The server was task-local and stopped after use.

Earlier attempt logs are retained as historical evidence, not substituted for
these final executed checks. A resumed source comparison initially failed because
its relative root was evaluated in the QA cwd; corrected absolute-root comparison
passed before the build. This was a verification-command error, not a product
failure. The previous run also corrected its own unintended Space activation in
the hidden-layout harness; final targets are the passing versions.

## Source identity and retained evidence

Wing HEAD `1afe1307e37ee1ddfa1f7d67ad047509e99c8784` is dirty, not a complete
source identity. Read-only Desktop checkout:
`withdrawn reference revision`; Agent checkout:
`158fd638da1629c8e62caf9ade1515d162def8ab`. Reference instructions were read;
no upstream execution/modification or remote-latest claim is made.

Small local evidence remains under ignored `build/t_1e01f86b/evidence/`:
`source-sha256.json`, `final-source-sha256.json`, `source-verification.log`,
`focused-tests-resumed.log`, `analyze-resumed.log`, `web-build-resumed.log`,
`browser.log`, `playwright-results.json`, `grouped-recents-recovery-receipt.json`,
`grouped-recents-recovery-semantics.txt`, focused/unfocused PNGs and compact/wide
captures. Final fingerprints bind tested copy and live source, including excluded
shared production and unchanged harness files. The task-created QA copy and large
build outputs are removed after evidence capture; other owners' build outputs stay.

Ledger/check commands run in the main repo are recorded in `ledger-checks.log`:
`goals.py task ... VERIFY-GROUPED-RECENTS-RECOVERY done`, exact executed check
references via `evidence ... PARITY-COMPOSITION --kind executed`, `render`,
`validate`, and `git diff --check`. Only the bounded recovery task is closed;
full composition remains partial and native review approval follows separately.

## Gaps and defaults

Native Flutter desktop, Android/device, live Agent/provider, screen-reader,
physical input/acoustics, Wasm, packaging/deployment and full-suite qualification:
NOT_CHECKED. Single-source browser fixture and fake channel do not establish live
contracts or Desktop Project grouping. No shared production defect was exposed.
No commits, staging, system/device changes, notifications or publication occurred.

Questions: none. Defaults applied: source grouping only, existing sidebar lifetime,
no group disclosure or incidental replay, preserve shared dirty work and owner gates.
