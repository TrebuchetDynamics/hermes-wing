# Saved connection feedback accessibility

Scoped task: `t_263cb8bd`, goal `M1`, task
`M1-SAVED-ENDPOINT-FEEDBACK-ACCESSIBILITY`. Implementation and isolated Linux
qualification are complete; protected-main delivery and independent review
approval are not claimed here.

## Reproduction and correction

The inherited editor is byte-identical to editor prerequisite
`589e0a703ef6bcfc2ac85398c59fc533ecb44b9b`, SHA-256
`4d8facaec4dadfacfa1064111f412bc9d056fcc7e355f047a6abff42ec90ef69`.
The storage predecessor `49d435a52746499a759f2510828be9e1d008de11`
is a separate additive harness commit, not the editor's source parent.

Before correction, the new widget regression reproduced `didExceedMaxLines`
for credential guidance at 390 logical pixels at both text scales. Removing
that limit exposed a second failure: outcome text remained outside the content
viewport. Baseline source, dirty-file hashes, and failing logs are retained in
`build/t_263cb8bd/evidence/baseline/`.

[The editor](../../lib/features/hermes_chat/screens/widgets/hermes_saved_endpoint_editor.dart)
now renders complete guidance as a keyboard-focusable text block. New sanitized
outcomes retain live-region semantics, receive focus after layout, and reveal
their beginning inside the existing scrollable dialog. Both blocks have a
visible focus outline. Tab returns to explicit Test, Save and Cancel actions;
Page Down reads the remainder when text exceeds the viewport. No domain/store,
API, localization, credential, ownership or retry contract changed.

## Acceptance evidence

1. [New widget regression](../../test/features/hermes_chat/screens/hermes_saved_endpoint_feedback_accessibility_test.dart):
   12 cases across 1280/390 logical pixels, 100/200% Flutter text and reduced
   motion. Complete localized help and success/denied/failed/save-failed notices
   render without truncation; beginning and end are reachable with keyboard
   pages. Live-region semantics are asserted. Pending cancellation and deliberately
   replaced owner reject late success; stale/cancel notices remain readable and
   Cancel works. These are Flutter key events, not physical keyboard evidence.
2. [Native GTK journey](../../integration_test/linux_saved_endpoint_feedback_test.dart)
   and [support](../../integration_test/support/saved_endpoint_feedback_native_fixture.dart):
   four public saved-row Edit journeys use Tab/Space without test-driver
   `ensureVisible`, pointer activation or dragging. They read help and each
   outcome, deliberately retry Test and Save, cancel a pending Test, then
   cancel after another storage denial. The credential fields are absent/blank
   throughout. The draft survives failure; canonical owner/peer rows remain
   unchanged until the one explicit successful save. Exactly four explicit
   discovery GETs (403, 200, 500, cancelled delayed 500), three explicit save
   attempts (denied, retry committed, denied then Cancel), and one commit occur
   per journey. No automatic connect/disconnect, active conversation read,
   send/create/approval/Stop or Wing Link operation occurs. Directory reads are
   inert; the socket fixture rejects all other routes and methods.
3. [Launcher](../../scripts/run_linux_saved_endpoint_feedback.sh),
   [driver](../../scripts/support/saved_endpoint_feedback_native.py), and
   [four tooling regressions](../../test/tooling/saved_endpoint_feedback_native_test.py)
   qualify admission, environment isolation, attribution and exact receipt
   contracts. Authenticated owned Xvfb rejects missing/wrong authority. Each
   observed GTK process belongs to the driver; source and dependency inputs are
   frozen and rechecked. Owned process groups and disposable HOME/XDG are removed.

## Executed checks and source identity

Final evidence: `build/t_263cb8bd/evidence/attempt-vqmcptlp/`.
Source manifest SHA-256:
`062c0b4724303cb4b6005bd799954f51cf1ce8331769dec7757568b6a190410b`.
The retained `executed-source.tar.gz` SHA-256 is
`2cc3740bcd2924e9c907bacc60ed7faac9835f292a95759c9a33163c26aaa72b`.
`source.json` attributes inherited inputs separately; `baseline-to-task.patch`
contains only this card's new files and editor presentation delta.
`verification.json` records full executed commands, per-check durations,
environment, dependency hashes and exact GTK receipts.

All final checks exited 0 inside the isolated candidate:

- `dart format --output=none --set-exit-if-changed integration_test/linux_saved_endpoint_feedback_test.dart integration_test/support/saved_endpoint_feedback_native_fixture.dart lib/features/hermes_chat/screens/widgets/hermes_saved_endpoint_editor.dart test/features/hermes_chat/screens/hermes_saved_endpoint_feedback_accessibility_test.dart`
- `flutter analyze --no-pub` (16.193 seconds, no issues)
- `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_saved_endpoint_feedback_accessibility_test.dart test/features/hermes_chat/screens/hermes_chat_saved_endpoint_edit_test.dart` (33 tests, 23.670 seconds)
- `python3 -B -m unittest discover -s test/tooling -p saved_endpoint_feedback_native_test.py` (4 tests)
- `bash -n scripts/run_linux_saved_endpoint_feedback.sh`
- `flutter test --no-pub --concurrency=1 -d linux integration_test/linux_saved_endpoint_feedback_test.dart` (4 GTK journeys, 112.648 seconds including build; integration-test concurrency flag is ignored by Flutter, CMake parallelism remains 2)
- `timeout 30m bash scripts/run_linux_saved_endpoint_feedback.sh` (187.001 seconds, `NATIVE_SAVED_ENDPOINT_FEEDBACK_PASS`)
- `git diff --check`

Attempts are preserved, not replaced: first launcher failed before checks for
missing user-space headers (37.870 seconds); second found a deprecated semantics
assertion (52.031 seconds); third passed (191.133 seconds); fourth qualified the
final added storage-failure Cancel path (187.001 seconds). A pre-fourth format
check caught an unformatted multiline call before launching; formatting corrected
it. Baseline/iteration widget tests also exposed helper truncation, hidden notice,
and a success notice taller than the compact viewport (handled by bounded
keyboard paging, not smaller text). Early widget attempt durations were not
measured. Usage/cost and review duration are unknown.

Linux x86_64, Flutter 3.44.2 / Dart 3.12.2, GTK 3.24.41, GStreamer 1.24.2,
libsecret 0.21.4, Go 1.26.1. No shared gateway, display, credentials or keyring
were used. Development headers were downloaded/extracted without sudo under
`build/t_263cb8bd/deps/` following
[the existing recipe](native-relaunch-workflow.md#safe-user-space-prerequisites-and-reproduction).
Prepare that disposable prefix again to reproduce; package hashes are in the
receipt. Also retain/copy the immutable prerequisite editor into
`build/t_263cb8bd/evidence/baseline/editor.dart` before invoking the driver.
Set `PKG_CONFIG_PATH` to the prefix's `usr/lib/x86_64-linux-gnu/pkgconfig` and
`LIBRARY_PATH` to its `usr/lib/x86_64-linux-gnu` when running the launcher.

## Rendered inspection and limits

32 final secret-free captures are retained; six were loaded and directly inspected.
`visual-inspection.json` binds findings to source and capture hashes. Compact
200% denial, storage failure, pre-Cancel failure and guidance show complete copy
and explicit actions. Wide 200% success shows its complete inference disclaimer.
Compact 100% failure wraps completely. Focus outlines are visible. The compact
replacement-field label still ellipsizes and URL editing scrolls horizontally;
this card corrects guidance/outcome text, not every field label. Larger text may
require keyboard paging; complete copy need not fit simultaneously.

Native screenshot pixels reflect the Flutter logical test surface inside Xvfb,
not physical device size or OS scaling. Widget semantics and key assertions do
not prove screen-reader announcements or physical input. Real Agent/provider,
real storage backend, physical keyboard, screen reader, OS scaling, Android,
other desktop platforms and packaged distribution remain NOT_CHECKED.

The source-run launcher depends transitively on predecessor first-run, smoke,
Remote-retry and saved-edit helpers/fixtures and their test support. The scoped
commit is additive on the editor prerequisite, not a standalone built product.
The integration owner must assemble those prerequisites and run frozen combined
gates. No packaging manifest changed; checkout qualification is not packaged
execution or protected-main delivery. Large owned SDK/build/dependency copies and
archives were removed; small receipts, hashes, final source archive and captures
remain. Earlier archives are represented only by retained hashes.

Remaining M1 gaps: authorized actual generation, correlated approvals,
authoritative Stop, restoration, other platform qualification and protected-main
delivery. Next product slice remains separately authorized bounded live workflow
qualification; this card does not enqueue it. Questions: none. Defaults applied:
existing dialog/navigation, no inference, synthetic storage denial, no credentials.
