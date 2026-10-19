# Linux profile footer management-return recovery

Task: `t_66ec0dbc` / `VERIFY-PROFILE-FOOTER-NATIVE-RECOVERY`,
parent `PARITY-COMPOSITION` remains partial. Base:
`97d53656c43c5534d3621d691009bb44b986089d`.
Implementation and native fixture qualification are separate from independent
review, canonical integration and publication.

## Delivered oracle

The existing [Linux target](../../integration_test/linux_profile_footer_native_test.dart),
[fixture](../../integration_test/support/profile_footer_native_fixture.dart) and
[runner](../../integration_test/run_linux_profile_footer_native.py) now exercise:

- Keyboard Space/Enter opens the real ProfilesScreen from the collapsed/expanded
  passive footer. The existing ChatWorkspaceOverlay supplies keyboard Close.
- Close returns to the synthetic Chat route at 390px and 1280px, at normal and
  200% text. Its focus and hit-test reachability are asserted before Enter.
- The current channel disconnects and reconnects by authoritative fixture-state
  notifications. Wide disconnected display is Not loaded; reconnected display is
  the current redacted Profile B label, never a retired owner's value.
- Retired-channel notifications occur during management return, while disconnected
  and after reconnect. Exact selected profile `b` and `synthetic-session-b` remain
  owned by the replacement channel. Reconnect never reopens Profiles.
- Compact layout has no desktop footer. Returning wide restores the same sidebar
  mode and a keyboard-reachable redacted footer. Four recovery rows and fourteen
  painted-focus/inverse-traversal rows are required by the strict receipt validator.

The [shared test helper](../../test/shared/widgets/app_shell_profile_footer_test.dart)
adds only a synthetic Chat editor route and the existing production overlay widget.
There is no production change, new provider, transport, API or dependency. The
fixture keeps Profiles in its simplified ShellRoute; it is not the full production
router, retained Chat composer or live connection workflow. The first management
entry is from Tools. Ordinary go/Close fallback routing recreates the editor empty;
this slice does not add draft persistence or qualify retained-overlay drafts.
The production router's push/pop Chat retention remains a separate contract.

## Requests, identity and evidence

Passive phases override directory construction with a throwing factory. Explicit
Profiles phases allow the existing directory with no configured gateways and denied
read/write grants. Its loader calls are measured separately as
`profiles_route_reads=0`; this is not a claim of granted inventory-read coverage.
Channel call assertions cover connection calls, profile/session/model mutations,
Send/voice, approval, Stop and inventory/reconciliation reads. Both owners must
finish with zero calls. State identity is checked before and after return/reconnect.
Names are redacted for display without changing profile/session identity.

The runner uses the existing isolated source/SDK/packages/HOME/XDG/Xvfb harness.
Each run retains `.task-evidence/t_66ec0dbc/native-*/verification.json`, native log,
profile-footer receipt, source manifest/archive and dependency hashes. These bind
source, executed binary, environment, driver/native PID and native start ticks.
Acceptance requires `status=PASS`, exact receipt validation, unchanged copied
inputs/dependencies, the owned process group gone and isolated state removed.
The same-card finish receipt binds acceptance argv and the resulting task commit.
A document or validator self-check alone is not native execution evidence.

Required commands on the final source:

```sh
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed integration_test/linux_profile_footer_native_test.dart integration_test/support/profile_footer_native_fixture.dart test/shared/widgets/app_shell_profile_footer_test.dart test/integration/linux_profile_footer_native_runner_test.dart
flutter test --no-pub --concurrency=1 test/shared/widgets/app_shell_profile_footer_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart test/integration/linux_profile_footer_native_runner_test.dart
python3 -B integration_test/run_linux_profile_footer_native.py --self-check
python3 -B integration_test/run_linux_profile_footer_native.py
git diff --check
```

Changed local Markdown links are checked for existing targets. Exact command exits,
source/build hashes and native receipt path accompany the review handoff. Independent
review must inspect the original pre-edit manifest-pinned admission tool history,
not reconstruct admission by rerunning it after edits.

## Repairs and method

The first local test command lacked package resolution in the isolated checkout;
`flutter pub get --offline` restored cached dependencies without lockfile changes.
Early attempts incorrectly treated an imperative Chat push as a go-route URI and
omitted the production overlay's Close control. The bare denied Profiles screen
then had no route-local focus target after compact return. Trial production focus
and empty-state changes were removed: reusing ChatWorkspaceOverlay corrected the
fixture instead of expanding product behavior. Those failures are not acceptance.

Ponytail: bundled fallback `autowork/references/ponytail.md` in the card's pinned
runtime; reuse the existing journey, overlay, test helper and owned-process runner;
omit new harnesses, inventory grants, recovery APIs, draft stores and speculative
production fixes. Focused widget checks and strict malformed-receipt self-checks
cover the changed oracle; the native run is the Linux GTK evidence.

## Retained-source oracle repair (PARITYUPDATE-006-f4)

Baseline `536eba29165b77e0ab15fe4548714724983a861c` reproduces the widget-harness
failure at fixture line 102: zero outline pixels versus the unchanged minimum of
24. Diagnostic capture at 100% expanded layout found the expected bounds
`[8, 638, 242, 686]` and 420 border pixels at RGB `(87, 90, 95)`, not the oracle's
hard-coded opaque `#555555`. The retained theme change `ad6db4ef` supplies a
translucent secondary color; compositing it over the rail explains those pixels.
The nearest footer widget test already accounts for this composition. This is
an attributable stale-color oracle, not evidence of product failure or flakiness.

The shared journey now samples the same top-edge strip against the composited
shell focus color, with the footer widget oracle's one-channel-level rounding
tolerance. It still requires at least 24 actual painted pixels, not focus state
or Material configuration. A focused positive control followed by moving focus
to Settings proves the same pixel assertion rejects a missing footer indicator.
The strict receipt self-check also rejects zero-pixel rows as well as 23-pixel
rows. Capture dimensions, timing, coordinates, all 100/200% and adaptive-return
phases, inverse traversal, hit-test/48px bounds, redaction, retired-owner and
zero-effect assertions are unchanged. No production UI or Agent code changed.

The existing isolation harness canonicalizes its attempt path before producing
absolute package URIs. This permits its ignored evidence directory to point into
`$TMPDIR` without a Flutter canonical-project-root/package-root mismatch; it adds
no harness, dependency or native capability. In this worker, the existing
`.task-evidence/t_66ec0dbc` evidence location points to
`$TMPDIR/profile-footer-native-evidence`.

Final native evidence after the baseline test repair:
`native-vtm5zb33/verification.json`, status `PASS`, 141.278 seconds. All 14 focus
rows report 48–420 pixels; four activation and four recovery rows pass strict
validation. The receipt binds the observed native
child PID/start ticks, binary and source, confirms unchanged copied source and
dependencies, owned process group gone and isolated state removed.

| Native artifact | SHA-256 |
| --- | --- |
| Source manifest | `8b5d4a2e8e7f5d5a5faeb410bfa915356d08de61150b11152a9d52650b2479b1` |
| Pre-check source archive | `5e502f8c12d844d3e7332f5cd66a89ba5193d575e0ef2ff780427f85eb1fa660` |
| Native binary | `e5ee60c7966ea8dbc6b6da4fccac42c97ad5a0c8c4f8bc74b1f919fc4bbb167a` |
| Footer receipt | `db863619f2f1916b7295a1eacf3c22a06fc8ea9343ff6045870e8cc8917bf0b8` |

The baseline's top-level `testWidgets` registration in
`test/features/hermes_chat/screens/hermes_chat_layout_width_test.dart` prevented
analysis. Separate prerequisite commit `78114a47d7d2647efb6edf5606163e26c3957e73`
moves it inside `main`, preserving both assertions. Running the newly registered
case exposed its missing unit device-pixel ratio: 1440 physical pixels did not
provide the intended wide logical viewport. It now sets and restores the ratio
like its neighboring cases and disposes its fake channel. All six Chat layout
cases pass. No production behavior changed. The native journey was rebuilt and
rerun against these changed manifest inputs; the old receipt was not repinned.

Final offline checks pass:

```sh
flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_chat_layout_width_test.dart
flutter test --no-pub --concurrency=1 test/integration/linux_profile_footer_native_runner_test.dart test/shared/widgets/app_shell_profile_footer_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart
python3 -B integration_test/run_linux_profile_footer_native.py --self-check
python3 -B integration_test/run_linux_shell_compact_return.py --self-check
python3 -B integration_test/run_linux_profile_footer_native.py
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed integration_test/support/profile_footer_native_fixture.dart test/integration/linux_profile_footer_native_runner_test.dart test/features/hermes_chat/screens/hermes_chat_layout_width_test.dart
git diff --check
```

The footer command passes 16 tests including the negative control; analysis
reports no issues. This source-bound repair is a local worker candidate for
coordinator integration, not a reopening of the original completed footer tasks.
Full `flutter test --concurrency=1` and canonical assembly gates remain
`MT-RERUN-TRAIN`'s responsibility. The platform/live limits below remain unchanged.

## Boundaries

Input is `WidgetTester.sendKeyEvent` in the native Flutter engine; resizing is the
framework surface/physicalSize seam, not physical keyboard or OS-window resizing.
Reconnect is deterministic channel-state replacement/notifications, not an Agent
transport reconnect. Live Agent/provider, Android, screen reader, keyring,
physical-input, install/update, signing and release qualification are NOT_CHECKED.
Full repository/browser suites are not required or claimed for this fixture-only
slice. No upstream runtime, personal service/configuration, ledger, canonical main
or remote publication was modified by the worker. Independent native review run
424 approved exact commit `7bc246f60a3fe1cdf93e36425724e60de9a6ebc3` after
repeating analysis, formatting, 15 focused tests, strict self-check and the isolated
GTK/Xvfb journey. Coordinator verified all 786 native source input hashes and
owned-process teardown, fast-forward integrated that exact candidate and read back
origin/main at the same SHA. The bounded recovery task is complete;
`WING-TASK-408` and parent parity remain open. See [prior implementation](profile-footer-implementation.md)
and [native session-modal boundaries](global-session-modal-native.md#boundaries).
