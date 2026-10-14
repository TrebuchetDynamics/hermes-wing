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

## Boundaries

Input is `WidgetTester.sendKeyEvent` in the native Flutter engine; resizing is the
framework surface/physicalSize seam, not physical keyboard or OS-window resizing.
Reconnect is deterministic channel-state replacement/notifications, not an Agent
transport reconnect. Live Agent/provider, Android, screen reader, keyring,
physical-input, install/update, signing and release qualification are NOT_CHECKED.
Full repository/browser suites are not required or claimed for this fixture-only
slice. No upstream runtime, personal service/configuration, ledger, canonical main
or remote publication is modified. Pending review leaves canonical closure and
parent parity open. See [prior implementation](profile-footer-implementation.md)
and [native session-modal boundaries](global-session-modal-native.md#boundaries).
