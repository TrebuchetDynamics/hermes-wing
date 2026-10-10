# Native status accessibility

Card `t_4a9f2ee8`; task `M1-STATUS-ACCESSIBILITY`; goal `M1` remains partial.
This repair is implemented and qualified with a synthetic Linux GTK fixture,
not delivered to protected main or qualified against a live Agent.

## Behavior and bounded scope

The desktop status fields are keyboard-focusable buttons. Tab to a field and
press Enter or Space to expand the strip into complete labeled, wrapping values;
activate a field again to collapse. The normal strip retains compact styling.
Expanded columns adapt to available width and text scaling. Semantic labels
include each complete redacted value and the expansion state.

At 390 logical pixels the shell uses its existing More sheet rather than the
desktop strip. Characterization found single-line truncation there too. The
smallest compact correction renders the same status widget, initially expanded,
inside that sheet. Its channel listener updates an open sheet when the owner or
connection changes. No old owner is captured in a modal status snapshot.
The optional `InfoActionSheet.infoBuilder` leaves other sheets unchanged.
This additive scope correction is recorded in the card thread.

Production changes are limited to the status class, the shell status-sheet
builder, and the optional presenter slot. Footer, recents, persistence, routes,
backend, capability gating, and Agent/Wing Link authority are unchanged.
Recovering/error states retain existing truthful `Disconnected`/`Not loaded`
wording rather than suggesting that cached profile/model state is current.
Redaction applies before both rendered text and semantic labels.

## Acceptance evidence

1. Focused RED: `flutter test --no-pub --concurrency=1
   test/shared/widgets/app_shell_status_accessibility_test.dart` returned 1:
   both wide cases lacked keyboard full-value inspection. Compact cases initially
   characterized the existing More entry; the final regression additionally
   requires an untruncated model. An earlier test-authoring compile error was
   corrected before RED. Probe durations were not recorded.
   GREEN: five status tests and the existing shell/focus tests pass, 25 total.
   Labeled semantics, non-truncated text, current owner replacement,
   disconnected/recovering state and zero mutations are asserted.
2. Real Linux GTK: [native target](../../integration_test/linux_status_accessibility_test.dart)
   runs the production AppShell with an
   [in-memory authority](../../integration_test/support/status_accessibility_native_fixture.dart),
   production GoRouter navigation, reduced motion, injected Tab/Enter/Escape,
   resize and route return. Four journeys cover 390/1280 logical width and
   100%/200% text. Each includes connected, recovering, failed, replacement and
   returned phases. Receipts require zero sends, creates, approval decisions,
   model writes, Stops, profile writes and selections, including attempted calls.
   The validator rejects mutation counts, obsolete owners and incomplete phases.
   No Agent, provider, Wing Link, personal storage or inference is contacted.
3. The exact frozen candidate passes format, analysis, focused unit tests,
   native execution, validator and shell syntax. The source archive includes
   794 input files with inherited-byte attribution; dependencies, Go closure,
   sysroot, tools, executable and process identities are retained. A local
   owned-delta agent commit and same-card native review are recorded on the card;
   approval is a separate subsequent step.

## Executed checks

Final evidence: `build/t_4a9f2ee8/evidence/attempt-yvyh4r9l/`.
The receipt retains exact copied-SDK command paths, exit codes and timings.
All final checks below returned 0:

- `python3 -B -m unittest discover -s test/tooling -p status_accessibility_native_test.py`: five tests, 0.089 seconds.
- `bash -n scripts/run_linux_status_accessibility.sh`: 0.026 seconds.
- `dart format --output=none --set-exit-if-changed integration_test/linux_status_accessibility_test.dart integration_test/support/status_accessibility_native_fixture.dart test/shared/widgets/app_shell_status_accessibility_test.dart lib/shared/widgets/app_shell.dart lib/shared/widgets/sheet_presenter.dart`: 0.183 seconds.
- `flutter analyze --no-pub`: no issues, 18.851 seconds.
- `flutter test --no-pub --concurrency=1 test/shared/widgets/app_shell_status_accessibility_test.dart test/shared/widgets/app_shell_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart`: 25 tests, 25.628 seconds.
- `flutter test --no-pub --concurrency=1 -d linux integration_test/linux_status_accessibility_test.dart`: four journeys, 56.417 seconds.
- `timeout 25m bash scripts/run_linux_status_accessibility.sh`: `NATIVE_STATUS_ACCESSIBILITY_PASS`, 139.397 seconds.

The first launcher attempt lasted 55.951 seconds and stopped at four harness
lint findings. They were fixed before the final passing attempt. Both attempts
retain receipts; unchanged expectations were not weakened.

Source archive SHA-256:
`218ca9a18a8717a68567f0b23161d43e350d082ae586be219c566013ddd3351b`.
Source manifest SHA-256:
`9db087db0bef125cbe608449d44ea77bbd9fe766c620ec4f438a77e4a2bcd858`.
Native executable SHA-256:
`16a4866d5fcec9c5539f4c62c06a596c3c4e064ec79a33cf12c075e01981550d`.
The selection fingerprints matched before editing. Baseline shell SHA-256:
`b815bed0802b953e48d0e3ed3f6f4fe40e15d66bd44e3620dad22d9590312847`.
Inherited shell bytes outside the declared delta are preserved.

## Render inspection and limits

Twenty fresh native screenshots are retained. All four connected captures were
loaded and inspected, plus compact 200% failed and wide 200% returned captures.
Status labels and complete profile/model values wrap without clipping. Enlarged
compact status remains visible after scrolling the existing More sheet; the
wide focused gateway has a visible fill. Normal 11-point compact status remains
small, matching the existing strip. Unrelated sidebar/footer truncation and
scrolling remain visible and are not restyled by this card.

HOME/XDG, source/build, SDK, package closure and authenticated unique Xvfb were
isolated. Missing/wrong X authority is rejected, build jobs are bounded at two,
and owned process groups and disposable workspaces were removed after execution.
The user-space prefix follows the
[existing prerequisite recipe](native-relaunch-workflow.md#safe-user-space-prerequisites-and-reproduction),
using `build/t_4a9f2ee8/deps/downloads` and `build/t_4a9f2ee8/deps/sysroot`.
Reproduce with `timeout 25m bash scripts/run_linux_status_accessibility.sh` after
preparing that prefix; no arguments or credentials are accepted.

NOT_CHECKED: live Agent/provider authentication, inference/call ceiling,
real Stop/tools/approvals, combined daily-workflow restart, physical keyboard,
screen reader, other platforms, release packaging and protected-main delivery.
The qualified source includes inherited dirty prerequisites; the local scoped
commit is not a claim that main contains those prerequisites. The integration
owner must assemble the attributed commits and run its broader frozen gate.
Next seam: credential-free integrated approval, Stop and restart in one native
sequence, not repeated standalone qualification. Cost and review time are unknown.

Questions: none. Defaults applied: inline inspection, existing compact More
entry, credential-free authority, preserve all inherited work, independent review.
