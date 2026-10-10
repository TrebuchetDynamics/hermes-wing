# Native saved Agent connection repair

Card `t_f18c95fe`; goal task `M1-SAVED-ENDPOINT-EDIT-NATIVE`. M1 remains partial.

## Implemented

The [GTK target](../../integration_test/linux_saved_endpoint_edit_test.dart) adds
native qualification of the existing public saved-row editor. It does not
reimplement the editor or invoke its internal callbacks. Tab/Space enters the
original saved row, edits the draft, activates Test/Cancel/Save and reopens it.
The production `HermesChatScreen`, `HermesApiChannel`, endpoint-store interface
and connection directory are used with deterministic overrides.

The [fixture](../../integration_test/support/saved_endpoint_edit_native_fixture.dart)
binds a disposable IPv4 loopback HTTP server on an ephemeral port. Only explicit
Test uses its discovery GET. All mutation and stream callbacks reject and count;
unexpected destinations, routes, query parameters and authentication headers
reject. There are no real credentials, authentication or inference. The active
conversation uses the inherited GET-only synthetic authority through the
production API channel. Its request list, connect/disconnect counters and exact
host/profile/session remain unchanged throughout repair. Directory loading is
inert. No Wing Link credentials or transport are supplied; source inspection of
the existing Test path confirms it calls direct Agent capabilities only.

The saved editor remains attributed to predecessor
`589e0a703ef6bcfc2ac85398c59fc533ecb44b9b`, not this card. All production files,
upstream Agent/Desktop references, prerequisite launchers and other profiles are
unchanged. The endpoint store is a fake interface implementation, not a claim of
physical secure-storage persistence. Native SharedPreferences is real but its
HOME/XDG is disposable and unrelated to the user's application state.

## Acceptance evidence

1. The compiled GTK target passes four journeys: 390/1280 logical widths crossed
   with 100/200% text. Public saved-row entry and all actions use widget-driven
   logical keyboard events. `ensureVisible` assists scrolling and `enterText`
   inserts a synthetic URL. These are not external OS-key automation, physical
   keyboard/IME, OS text-setting or OS-window-resizing qualification.
2. Cancel discards a changed draft without reads or saves. Discovery denial is a
   deterministic 403 with generic feedback and no raw response. Idle does not
   retry. Explicit Test retries successfully. A held 500 read is cancelled through
   the public Cancel test control; its late settlement cannot emit failure or
   readiness feedback. Each journey admits exactly three discovery GETs, with
   statuses 403/200/500 and empty query parameters. Before Save there are zero
   saves, connects/disconnects, active-channel reads or mutation/stream attempts.
   Save writes exactly the original ID and preserves the same-label peer. It
   shows persistence feedback, not readiness, and leaves the conversation owner
   unchanged. Reopening shows a blank replacement credential field. The target
   does not qualify replacing a real stored credential.
3. The [launcher](../../scripts/run_linux_saved_endpoint_edit.sh) freezes the
   exact source closure and inherited dirty-input hashes before checks. Its
   [adapter](../../scripts/support/saved_endpoint_edit_native.py) reuses read-only
   first-run/Remote process, display, snapshot and dependency helpers. Immutable
   source/Dart/Go archives, dependency manifests, baseline-to-task patch and exact
   per-attempt command/exit/duration logs are retained. Final source hashes match
   after execution and still match the working source at handoff. An authenticated
   private Xvfb display rejects missing/wrong Xauthority. Copied SDK, packages,
   Go modules, app/build outputs, HOME/XDG and owned processes are removed after
   execution. Build parallelism is two; only one native driver is launched.
   Flutter reports integration-test `--concurrency` is ignored.

## Executed checks

Final evidence directory: `build/t_f18c95fe/evidence/attempt-875k_v1d/`.
`verification.json` retains actual isolated executable argv; `sanitized-receipt.json`
uses `flutter`/`dart` aliases. All final checks returned exit 0:

| Command | Duration |
| --- | ---: |
| `python3 -B -m unittest discover -s test/tooling -p saved_endpoint_edit_native_test.py` | 0.132s |
| `bash -n scripts/run_linux_saved_endpoint_edit.sh` | 0.022s |
| `dart format --output=none --set-exit-if-changed integration_test/linux_saved_endpoint_edit_test.dart integration_test/support/saved_endpoint_edit_native_fixture.dart` | 0.134s |
| `flutter analyze --no-pub` | 18.456s |
| `flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_saved_endpoint_edit_test.dart test/core/hermes/setup/saved_endpoint_edit_store_test.dart test/features/hermes_chat/screens/hermes_chat_saved_connection_workflows_test.dart test/features/hermes_chat/screens/hermes_chat_remote_connection_retry_test.dart` | 31.836s |
| `flutter test --no-pub --concurrency=1 -d linux integration_test/linux_saved_endpoint_edit_test.dart` | 99.913s |

Four Python boundary tests, 51 focused Dart tests and four compiled native
journeys passed. Launcher duration: 194.009s. Flutter 3.44.2 / Dart 3.12.2,
GTK 3.24.41, GStreamer 1.24.2, libsecret 0.21.4 and Go 1.26.1 were exercised
on Linux x86_64. This is not a full-repository gate.

Reproduction uses the existing
[user-space prerequisite recipe](native-relaunch-workflow.md#safe-user-space-prerequisites-and-reproduction)
with an isolated `build/t_f18c95fe/deps/` prefix. No sudo or system install was
used. Downloaded package filenames and hashes are retained in `verification.json`.
Prepare that prefix before running:

```sh
PKG_CONFIG_PATH="$PWD/build/t_f18c95fe/deps/root/usr/lib/x86_64-linux-gnu/pkgconfig" LIBRARY_PATH="$PWD/build/t_f18c95fe/deps/root/usr/lib/x86_64-linux-gnu" timeout 30m bash scripts/run_linux_saved_endpoint_edit.sh
```

## Source and inspection boundary

Frozen base: `b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`. The archive contains
767 source inputs, including 124 inherited dirty inputs; these are not owned
changes. Source archive SHA-256:
`f3829391aefa6ba783ce65d980c03a2a22aa4af925bf8ceeb8d216e9af2ae61c`.
The source manifest and dependency hashes bind the exact candidate, not just HEAD.

The source-run Python closure imports inherited `remote_connection_retry_native.py`,
`direct_first_run_native.py` and `desktop_no_inference_smoke.py`; it loads the
runtime helper from Git object `894439b76c889fed45f3c4d57b73086f1e18d479`.
Exact loaded bytes are retained in `executed-runtime-helper.py`. The Dart target
also imports inherited Remote/first-run fixtures and the fake endpoint store.
The owned commit alone is not a standalone checkout: integration must assemble
these prerequisites or use the retained source candidate. Linux CMake compiles
Wing Link from frozen offline Go dependencies but no service is launched.
Packaged launcher/image/distribution execution remains NOT_CHECKED.

Twelve fresh GTK/X11 captures were retained. Six were loaded directly and
inspected; `visual-inspection.json` binds findings to their hashes. Wide discovery
and denial guidance and compact 100% discovery guidance wrap legibly. Keyboard
Test/Save/Cancel focus and blank reopened replacement field are visible. Compact
200% actions remain visible and focused; the content is vertically scrollable,
URL/credential helper text ellipsizes, and discovery/denial notices are off-screen
in the captured action-focused view. Their native widget assertions passed, but
visual readability of those off-screen notices is NOT_CHECKED. This is a bounded
interaction qualification, not a claim that every large-text disclosure is
simultaneously readable without scrolling. No production UI repair is attributed
here. Screen reader, physical input and platform text-settings remain NOT_CHECKED.

All three attempts are retained separately. `attempt-8tiak_fm` (164.856s) and
`attempt-3e3m_gwd` (165.506s) passed scoped checks but failed the native expectation
for an obsolete snackbar string copied from predecessor tests. The first
correction observed transient feedback before settling; source inspection then
identified the actual localized wording, “The active conversation is unchanged.”
The third attempt asserts that live wording and passes. No production defect was
reproduced. Earlier failed dependency archives are disposable; source manifests,
patches, check logs and failure receipts remain retained.

## Delivery and remaining milestone gaps

Implemented: native saved-edit fixture, public-control journey, isolated launcher,
four tooling boundary tests and source-bound evidence.
Qualified: deterministic Linux GTK repair/Test/Save/Cancel with fake endpoint
storage at the frozen candidate above, with the visual limits explicitly noted.
Delivered through protected main: NOT_CHECKED. Local attributed commit and native
review handoff are not merge, release or M1 milestone completion.

Physical secure storage is NOT_CHECKED: no private Secret Service was provisioned,
and the launcher deliberately excludes shared session DBus. Real authentication,
generation, approval/Stop, authoritative model restoration, full connection matrix,
Android and other native targets, protected PR and merged-main delivery remain
milestone gaps. The next seam is isolated real platform storage or an eligible
in-scope connection-matrix slice, not a rerun of this fixture. No follow-up card
was enqueued. Usage/cost and review duration are unknown.

Questions: none. Defaults applied: disposable credential-free discovery authority,
fake store, existing production contracts and preserved inherited ownership.
