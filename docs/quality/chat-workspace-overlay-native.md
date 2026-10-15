# Native Linux Chat workspace overlays

WING-TASK-408 remains in progress. This bounds production router/shell behavior
on the Linux GTK engine. The focus follow-through fixes chat-local return focus;
it does not complete Desktop parity or live daily-use acceptance.

## Exercised behavior

`integration_test/linux_chat_workspace_overlay_test.dart` now runs 36 journeys:
Settings and Profiles via shell and slash suggestions, Settings via Tab completion,
and Profiles via the profile picker's Manage action, at 390 and 1280 logical pixels.
Each is dismissed by
keyboard-activated Close, Escape or Flutter's `handlePopRoute` Back seam. Every
journey uses 200% Flutter text scaling. Rendered shell controls open the modal;
Close autofocus and Tab/Shift+Tab return are asserted before dismissal.

The original Chat state and composer controller must remain mounted. The exact
return URL (query and fragment included), unsent draft, session identity and
rendered synthetic transcript must survive. The existing fake channel must record
zero connect/disconnect, Send, Stop, session creation/selection or profile selection
calls, and the fake endpoint store must record zero saves. All 24 chat-local
journeys assert automatic composer focus return, without tapping Chat. Slash
commands intentionally consume their command text; shell and Manage preserve the
unsent draft. Shell return focus is not asserted (`composer_focus_restored: false`
means not checked for those twelve journeys, not a failed focus assertion).

This uses the existing in-memory test channel and endpoint store, with mocked
preferences. It does **not** exercise HTTP/SSE or credentials. The separate
[browser receipt](chat-workspace-overlay-browser.md) covers synthetic HTTP/SSE
stream completion and same-endpoint/session replacement in compiled Chromium.
Neither receipt substitutes for actual Agent or provider qualification.

## Runner and checks

```bash
flutter pub get --offline --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 \
  test/router/chat_workspace_overlay_test.dart \
  test/integration/linux_chat_workspace_overlay_runner_test.dart
python3 -B integration_test/run_linux_chat_workspace_overlay.py
```

The runner reuses `run_linux_shell_compact_return.py`: frozen source and package
manifests, a private Flutter SDK/package layout, isolated HOME/XDG directories,
no inherited D-Bus, private copied native dependencies and Xvfb with TCP disabled.
It validates all 36 typed journey receipts, observes the actual app PID under
the test driver, hashes the executable and checks process-group teardown and
isolated-state removal. Its existing local prerequisite is the native dependency
bundle described by that shared runner; this is not a portable installer.

The initial Flutter 3.44.2/Dart 3.12.2 isolated GTK run passed twelve shell journeys.
The runner confirmed owned-process teardown and state removal. Analyzer and the
25 focused router/receipt tests passed. Locked offline package resolution passed.
The first analyzer attempt exposed an incorrect test-only state getter; it was
corrected to the existing `activeMessages` API before execution.

A native negative control changed only retained `push` to replacing `go` and
rebuilt the Linux app. The first compact Settings journey failed at the mounted
Chat assertion; subsequent journeys were not reached. Exact production source
was restored before the final native run. This detects workspace destruction,
not every possible focus or ownership bug.

## Chat-local focus follow-through

The expanded GTK run passed all 36 typed journeys on Flutter 3.44.2/Dart 3.12.2,
with owned-process teardown and isolated-state removal. The initial expanded run
failed at the first compact slash Settings return-focus assertion; the focused
widget regression reproduced the same defect before the fix. Chat-local callers
now provide the existing composer focus node to the shared overlay opener, which
awaits return and only requests focus while its originating Chat route is current
and mounted. No new provider, domain state or transport is involved.

The expanded harness initially exposed a receipt publication race: the observer
read a newly created empty file before JSON was written. The Dart test now writes
a sibling pending file and renames it atomically. That interrupted run remains
failed; only the subsequent complete run qualifies the matrix.

## Keyboard shell-entry follow-through

The twelve shell journeys now reach Settings and Profiles with Tab and activate
with Enter. Compact Settings first traverses More and then its Settings action.
The existing bounded shell traversal helper asserts semantic focus; the native
test also requires the target to intersect the viewport before activation. No
pointer click, programmatic focus or `ensureVisible` is used for shell entry.
Bootstrap and draft entry still use fixture setup and `enterText`; these are not
fully keyboard-only journeys.

On the isolated candidate based on `2494e135`, all 36 GTK journeys passed with
Flutter 3.44.2/Dart 3.12.2: twelve keyboard-shell and 24 retained chat-local cases.
The runner verified the app PID, typed receipts, unchanged frozen source and
dependency manifests, owned-process teardown and isolated-state removal.
Analyzer, locked offline dependency resolution and 28 focused router/receipt/shell
navigation tests passed. Independent read-only native-source review approved the
two changed test/runner files. Production code and dependencies are unchanged.

A rebuilt native negative control omitted Enter in the shell activation helper.
The first compact Settings journey failed because More never opened and its
Settings action was absent. The exact approved source was restored byte-for-byte;
the passing frozen-source receipt above remains bound to those restored bytes.
This detects missing activation, not every possible traversal or focus regression.

## Remaining acceptance

Shell return focus, active stream behavior in GTK, profile/connection replacement,
late old-run completion and Android remain unqualified. The chat-local entry/focus
matrix is separate from shell focus.
Surface size and input use Flutter integration seams, not physical window resizing,
an OS keyboard/IME, OS Back or screen-reader qualification.
No live Agent, provider inference, personal preferences, keyring or services were
used. The full Flutter and full browser suites were not rerun; focused router,
Chat-screen/shell and compiled overlay suites cover this change. See the separate
[browser receipt](chat-workspace-overlay-browser.md) for its distinct HTTP/SSE scope.
