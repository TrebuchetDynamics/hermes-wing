# Native global session panel qualification

Card `t_5ca5f71b`, task `VERIFY-GLOBAL-SESSION-MODAL-NATIVE`, goal
`PARITY-COMPOSITION`. This receipt concerns the integrated dirty checkout, not a
standalone card branch or a live Agent.

## Delivered scope

- [Dedicated Linux journey](../../integration_test/linux_global_session_modal_test.dart)
  exercises production `AppShell`, `GlobalSessionScope`, `ShellSessionAccess`,
  `HermesSessionsPanel` and `HermesApiChannel` in the actual GTK Flutter engine.
  Only the feature-route bodies are minimal deterministic editor placeholders.
- [Dedicated response gate](../../integration_test/support/global_session_fixture.dart)
  records bounded method/path/query metadata and forwards the existing synthetic
  HTTP fixture. It delays actual history and creation responses; it can replace
  one history response with an explicit synthetic HTTP 503. It does not invent
  successful responses or replace production admission/state handling.
- [Isolated runner](../../scripts/support/global_session_modal_native.py)
  reuses the input-only source/SDK isolation helper. HOME, XDG preferences, display,
  source/build/SDK copies, and Go build cache are task-owned. Real native plugins
  and the bundled Wing Link build remain enabled. Compiler and Go concurrency
  are bounded to two. No plugin stubs, credentials, personal preferences, upstream
  edits, privileged installation, production changes or shared harness edits.

## Acceptance mapping

1. The native journey uses Ctrl+K, Tab, Shift+Tab, Enter, Space and Escape,
   and Flutter editing injection for search. At `TextScaler.linear(2)` and reduced
   motion, the open panel moves through 390×700, 390×480 and 1280×900 viewports.
   Search retains focus across each resize. Search, New, the exact result row and
   Close are traversed; every observed focused control has positive dimensions
   and full viewport bounds recorded. Forward and inverse traversal remain inside
   the dialog. Searching by exact synthetic session ID removes the unrelated
   row. Escape and Close/Space restore a surviving route-editor opener.
   This is Flutter viewport/input injection on a real Linux engine, not physical
   keyboard/IME or OS window resizing qualification.
2. Both Open and New delay their production HTTP response and invalidate ownership
   through feature-route away/back, dismissal, connection generation, channel
   replacement, and another explicit session selection. The delayed operation
   is awaited to completion; none can activate or navigate the replacement.
   Repeated activation while pending adds no request. A fresh explicit Space
   action succeeds once, closes the panel and opens `/hermes` with the acknowledged
   exact ID. Open adds only that ID's history GET; New adds one POST followed by
   the same acknowledged ID's history GET. Passive opening/search/resize/dismissal
   adds no requests. Replacement/setup reads are separately asserted and retained.
   A failed HTTP history read leaves the panel over the feature route; explicit
   Retry performs one current-owner read and no write. Entire request logs reject
   sends, approvals, Stop, replay and all non-creation mutations. Independent
   fixture counters remain unchanged, with zero runs.
3. The runner retains exact command/exits, copied-source hashes, compiled native
   binary hashes, control bounds, public action calls, HTTP requests, platform
   identity, source-drift check and owned-process teardown. Focused modal, action,
   adaptive, access, shell and focus regressions run serially. Shared predecessor
   sources remain inputs, never staged into the card's branch.

A New request deliberately clears the old target before submission. Dismissing
its pending response is not a server-write rollback: it must not activate the
created ID, synthesize a replacement row or replay the POST. Session replacement
can preserve the authoritative acknowledged inventory row without selecting it.
Profile away/back fencing is rerun widget coverage, not a native live-profile
switch claim.

Feature-route replacement can dispose the previously focused row. Cleanup and
fresh recovery first traverse the surviving Close control before Escape. This
qualifies keyboard reachability, not an assertion that route replacement preserves
that disposed focus or that an unfocused Escape is universally handled.

## Reproduction and evidence

Prepare compatible development metadata in an owned user-space extraction, using
[the native prerequisite recipe](native-relaunch-workflow.md#safe-user-space-prerequisites-and-reproduction).
The package versions must match installed runtime ABI; no loader override or
system package installation is used. Then from the Wing root:

```sh
TMPDIR=<home>/.hermes/profiles/wing/cache/scratch PKG_CONFIG_PATH="$PWD/build/t_5ca5f71b/prereqs/root/usr/lib/x86_64-linux-gnu/pkgconfig" LIBRARY_PATH="$PWD/build/t_5ca5f71b/prereqs/root/usr/lib/x86_64-linux-gnu" timeout --signal=TERM --kill-after=20s 1500s python scripts/support/global_session_modal_native.py
```

The runner internally executes scoped Dart format verification, `flutter analyze
--no-pub`, the six named serial widget targets, and `xvfb-run -a -s '-screen 0
1600x1200x24 -nolisten tcp' <isolated-sdk>/bin/flutter test --verbose --no-pub -d
linux integration_test/linux_global_session_modal_test.dart --reporter expanded`.
Exact relocated command arrays are retained in `checks.json`.

Final runner exit: 0. Scoped formatter: unchanged, exit 0. Isolated analyzer:
no issues, exit 0. Six focused widget targets: 89 tests passed, exit 0. Actual
Linux integration: one test containing twelve asserted phases passed, exit 0.
The canonical targeted npm wrapper was also executed, not inferred:

```sh
timeout 10m npm run test -- test/shared/widgets/app_shell_global_session_modal_adaptive_test.dart test/shared/widgets/app_shell_global_session_modal_test.dart test/shared/widgets/app_shell_global_session_access_test.dart test/shared/widgets/app_shell_global_session_modal_actions_test.dart test/shared/widgets/app_shell_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart
python -m py_compile scripts/support/global_session_modal_native.py
git diff --check
python <home>/.hermes/shared-skills/repo-docs/scripts/goals.py validate <repo>
```

All exited 0; the npm wrapper reran 89 widgets, not the full suite. Four local
documentation links were checked and exist. The native process was PID 2429139
on Linux `7.0.0-31-generic`, x86_64/glibc 2.39, GTK under owned Xvfb X11/software
rendering. There are 67 positive, fully contained focused-control observations.
The receipt records 173 app-plane requests: 163 GETs and ten explicit New POSTs.
Ten fresh actions admitted exactly once each; zero obsolete admissions, zero
unexpected mutations and zero runs. Initial bootstrap contains nine GETs.
Replacement/reconnect reads are explicitly distinguished from passive UI work.

`build/t_5ca5f71b/evidence/` retains `checks.json`, `format.log`, `analyze.log`,
`focused-tests.log`, `npm-focused.log`, `native.log`, `native-receipt.json`,
`source-manifest.json`, `source-drift.json`, `build-fingerprint.json`,
`platform.json`, `prerequisites.json` and `teardown-receipt.json`. The review
archive preserves these small receipts after owned builds are deleted. All 644
copied input fingerprints were unchanged at final runner settlement. Shared HEAD
was `b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319` at settlement; independent interactive
Git work advanced it during this card. The shared HEAD/index were not modified
by this worker. Qualification authority is the manifest, not that clean revision.

Final SHA-256 binding:

- Integration target: `716d75d8133c98fd69ae3f2cd1745f9387922289400a0899657d50c6f471d586`.
- Dedicated gate: `edd3a94c1674e0387518837a58aebee077aa8c92f149a09ccdc3448f8c96ca89`.
- Runner: `7749cd1bf1c282732c2b8996a21ee40ae1bd658691e2928f7b25bc99b91182af`.
- Executed native binary: `a6ef83927763f7bc1598ee2f10cbdb98025987dfe5a238c27ef3a077c30c3ef5`.
- Executed Dart kernel payload: `615ef448cbd65731bfd583a6aa73d9e229ae762c19aab66a4c0248b386f968f6`.

Teardown records all owned child groups reaped, no surviving groups, and isolated
source/SDK/build/HOME removed. Fixture exit -15 is intentional shutdown, not a
test failure. Downloaded/extracted prerequisite packages were task-owned and
removed after recording hashes; existing shared caches/build output are untouched.

Earlier attempts are not passing evidence: missing libsecret/GStreamer metadata,
route-disposed focus during harness dismissal, the harness's unobserved deliberate
HTTP 503, and a fixture keep-alive connection closing during a long keyboard
phase. The final gate uses non-persistent upstream fixture sockets (production
HTTP is unchanged), explicitly observes the expected 503, and traverses the
surviving Close control. All native assertions then passed in a fresh build.

## Boundaries

Native profile switching, live Agent/provider inference, physical keyboard/IME,
secure storage enrollment, screen-reader output, audio, packaged/signed
installation, standalone branch build and full-suite checks: `NOT_CHECKED`.
No connection/auth/storage or domain contract changes are delivered. The dedicated
native integration artifact is a qualification target, not a new shipping entry.
The clean base lacks predecessor global panel/shell/channel inputs; merge those
approved snapshots before attempting standalone branch qualification.

Questions: none. Existing authority and isolation defaults applied.
