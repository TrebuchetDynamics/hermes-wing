# Native Linux Chat workspace overlays

WING-TASK-408 remains in progress. This bounds existing production router/shell
behavior on the Linux GTK engine; it adds no production behavior and does not
complete Desktop parity or live daily-use acceptance.

## Exercised behavior

`integration_test/linux_chat_workspace_overlay_test.dart` runs twelve journeys:
Settings and Profiles at 390 and 1280 logical pixels, each dismissed by
keyboard-activated Close, Escape or Flutter's `handlePopRoute` Back seam. Every
journey uses 200% Flutter text scaling. Rendered shell controls open the modal;
Close autofocus and Tab/Shift+Tab return are asserted before dismissal.

The original Chat state and composer controller must remain mounted. The exact
return URL (query and fragment included), unsent draft, session identity and
rendered synthetic transcript must survive. The existing fake channel must record
zero connect/disconnect, Send, Stop, session creation/selection or profile selection
calls, and the fake endpoint store must record zero saves.

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
It validates all twelve typed journey receipts, observes the actual app PID under
the test driver, hashes the executable and checks process-group teardown and
isolated-state removal. Its existing local prerequisite is the native dependency
bundle described by that shared runner; this is not a portable installer.

On Flutter 3.44.2/Dart 3.12.2, the isolated Linux GTK run passed all twelve journeys.
The runner confirmed owned-process teardown and state removal. Analyzer and the
25 focused router/receipt tests passed. Locked offline package resolution passed.
The first analyzer attempt exposed an incorrect test-only state getter; it was
corrected to the existing `activeMessages` API before execution.

A native negative control changed only retained `push` to replacing `go` and
rebuilt the Linux app. The first compact Settings journey failed at the mounted
Chat assertion; subsequent journeys were not reached. Exact production source
was restored before the final native run. This detects workspace destruction,
not every possible focus or ownership bug.

## Remaining acceptance

Automatic composer focus restoration, keyboard-only shell entry, chat-local
slash/Manage entries in the native app, active stream behavior in GTK,
profile/connection replacement, late old-run completion and Android remain
unqualified. Surface size and input use Flutter integration seams, not physical
window resizing, an OS keyboard/IME, OS Back or screen-reader qualification.
No live Agent, provider inference, personal preferences, keyring or services were
used. The full Flutter suite and browser suite were not rerun for this native-only
test addition; the existing compiled browser evidence is unchanged.
