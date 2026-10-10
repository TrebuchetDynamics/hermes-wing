# Native integrated daily-workflow restart qualification

## Scope and result

Card `t_e168b601`, ledger task `M1-NATIVE-INTEGRATED-RESTART`, qualifies one
credential-free synthetic workflow on Linux GTK. It does not complete M1 or
`PARITY-LIVE-WORKFLOW`. Native same-card review is the final worker step;
independent approval and protected-main delivery remain separate.

The final execution returned `NATIVE_INTEGRATED_RESTART_PASS` in 253.924 seconds:

```sh
timeout 30m bash scripts/run_linux_integrated_daily_restart.sh
```

Evidence is retained under
`build/t_e168b601/evidence/attempt-a6jtfh8g/`. The launcher creates a new attempt
folder on each execution. All nine attempt folders and the original validator
RED log are retained; earlier failures are not qualification passes.

## Implementation boundary

The six additive task files are:

- `integration_test/linux_integrated_daily_restart_test.dart`
- `integration_test/support/integrated_daily_restart_fixture.dart`
- `scripts/run_linux_integrated_daily_restart.sh`
- `scripts/support/integrated_daily_restart_native.py`
- `test/tooling/integrated_daily_restart_native_test.py`
- this document

No production code is changed by this card. The test uses the production router,
`HermesApiChannel`, gateway directory and contact cache. HTTP/SSE travels directly
to a loopback synthetic authority. Only endpoint discovery and unavailable voice
services are overridden. Profile/session/run state is not substituted in the
client. Real Linux SharedPreferences persists selection across process exit;
there is no mock preferences initialization. The fixture persists synthetic
backend history separately between the two application processes.

No personal credentials, provider calls, Wing Link operations or upstream
modifications are admitted. The launcher rejects command-line arguments. This is
a source-run test tool, not a packaged or shipped runtime feature.

## Observed sequence

For each width, the first application process connects to the synthetic direct
Agent contact, opens the global session picker with injected Ctrl+K, loads another
page and selects `synthetic-off-page` in `synthetic-qa`. It explicitly selects
`synthetic/model`, sends an approval prompt, answers `approval_run_1` once, sends
a second prompt and Stops exactly `run_2`.

The fixture delays the Stop response, leaving its outcome uncertain. Sending is
rejected while the run remains unreconciled. After the synthetic authority admits
a terminal cancelled outcome, explicit Reconnect reads exact run/history state.
The delayed Stop response then completes without changing canonical message IDs
or active identity. Reusing the retired interruption target returns false.

Denied canonical-history reads are NOT_CHECKED in this sequence. The fixture's
`failHistory` flag remains false throughout the archived execution. The exercised
failure boundary is uncertain Stop, not a denied history read.

The test leaves Chat for Settings and returns through the production router,
asserting no mutations. The launcher observes process exit before starting a
second application process with the same isolated preferences. That process
restores the exact off-page session and canonical history without mutation.
Provider/model identity is not authoritatively reported after restart: the model
picker displays that limitation and requires explicit selection before one
intentional resumed send. The displayed runtime model string is not proof of
restored provider/model identity.

Recorded GTK application PIDs (with driver ownership and start ticks in receipts):

| Width | First process | Restarted process | Restore mutations | Leave mutations |
| --- | --- | --- | --- | --- |
| 390 | 1065299 | 1072338 | 0 | 0 |
| 1280 | 1075710 | 1083659 | 0 | 0 |

Both widths use 200% text scale and disabled animations. Controls are reached
with Flutter-injected Tab and activated with injected Enter. Text entry uses the
Flutter test input service; scrolling uses `ensureVisible`. Settings navigation
uses `router.go`, not keyboard input. These observations do not qualify physical
keyboard hardware, an entirely keyboard-only journey or screen-reader operation.

## Source attribution and reproducibility

The execution snapshot has base revision
`b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319` plus inherited dirty Wing inputs.
It is not evidence that main contains those inputs. `source.json` marks only the
five executable/test files as task-owned and every other input as
`preexisting-worktree`, including per-file dirty status. This document was added
after execution and does not change executable inputs.

The recorded predecessors are
`b832870d6205acede576c1427424fff3abc26be0` and
`894439b76c889fed45f3c4d57b73086f1e18d479`. The latter supplies the immutable
native lifecycle helper; `executed-runtime-helper.py` retains those bytes.
Other read-only helper imports are bound by the complete source manifest.
A six-file local task commit is an additive handoff, not a standalone combined
qualified application: the integration owner must assemble the inherited inputs
and task delta before broader gates.

- `executed-source.tar.gz`: 1,296 candidate files, captured before checks.
- Archive SHA-256:
  `a8f0c87df4764f0c09bc4067783f378f014966a4c87787638b0120988c9a7292`.
- Source manifest SHA-256:
  `644c23573c34d898bde7fb7af1d5332f1ac62a39af71c725f4dcb2d62c23b206`.
- Native binary SHA-256:
  `724cac892d581dbfd7fa3efbda083ca210950282cc6a1a5bfc050270c7b681e6`.

`verification.json` records every executed input hash, SDK binary hashes, Flutter
3.44.2/Dart 3.12.2 identity, dependency/plugin and Go dependency receipts, extracted
Linux prerequisite hashes, linked libraries, display isolation, process identities,
exact commands, exit codes and durations. Owned SDK/build/HOME/XDG directories are
removed after teardown; inherited processes and build outputs are untouched.

For a rerun, provide Flutter 3.44.2, Node, Go, GTK, Xvfb, ImageMagick `import`,
GStreamer and libsecret development metadata. This runner uses its task-specific
user-space sysroot at `build/t_e168b601/deps/sysroot`; populate it with extracted
packages and rewritten pkg-config prefixes using the user-space recipe in
[native relaunch qualification](native-relaunch-workflow.md). No system install
or shared SDK mutation is required. The exact downloaded package digests are in
the final receipt. Task-created prerequisites may be removed after qualification;
they must be prepared again before rerunning.

## Executed checks

On the frozen candidate, all commands exited zero:

- `python3 -B -m unittest discover -s test/tooling -p integrated_daily_restart_native_test.py`
  — five tests. Original RED: five tests with 14 failing subcases; final GREEN:
  all pass. Corrupted traces cover replay, wrong owners and invalid recovery.
- `bash -n scripts/run_linux_integrated_daily_restart.sh`.
- `dart format --output=none --set-exit-if-changed integration_test/linux_integrated_daily_restart_test.dart integration_test/support/integrated_daily_restart_fixture.dart`.
- `flutter analyze --no-pub`.
- `npm run test -- --no-pub --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart test/features/hermes_chat/messaging/approvals/hermes_approval_profile_owner_test.dart`
  — 376 targeted tests, not a full-suite run.
- Four separate `flutter test --no-pub --concurrency=1 -d linux integration_test/linux_integrated_daily_restart_test.dart`
  invocations, with width/phase and isolated environment set by the launcher.

`check-*.log` and `verification.json` retain actual SDK-qualified command paths
and durations. Receipt validation requires the exact ordered deliberate mutation
trace, exact session/profile, canonical IDs and off-page recovery reads. No
session creation, duplicate approval, duplicate Stop or replay is allowed.

## Render inspection and limits

Fourteen fresh X display captures are hashed in the receipt. Inspection used the
local visual verification skill on compact failure, compact focused Stop and
compact/wide restored-history captures from the final attempt.

The compact failure text wraps legibly, Reconnect is visible, and the composer
shows its disabled recovery state. Stop and restored canonical history are
readable without overlapping message content. Focused/unfocused image hashes
differ, and focus ownership is asserted; the Stop focus cue is visually subtle.
At enlarged text the wide Sessions heading wraps awkwardly within a word,
several sidebar/session labels truncate, and the compact horizontal composer
controls have truncated secondary labels. These are inherited presentation
limits, not repaired here. This receipt makes no universal readable-layout or
accessibility claim. Unknown model-pair handling is asserted in the test and
captured separately; it is not a persistence claim.

Remaining milestone gaps are actual approved Agent/provider authentication and
physical-attempt call-ceiling admission, real generation, authoritative model-pair
read capability and protected-main delivery. The next slice is the outstanding
live admission seam, not another presentation audit. Other platforms, physical
input, secure keychain, packaged distribution and broader gates are NOT_CHECKED.
No new owner question is needed; existing no-credential/no-inference defaults
remain in effect.
