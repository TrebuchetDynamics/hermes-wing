# Linux passive profile footer qualification

Status: implementation verified for `t_247cda0e` /
`VERIFY-PROFILE-FOOTER-NATIVE`, goal `PARITY-COMPOSITION`; independent native
review is pending. This does not close the canonical ledger or establish full
Desktop parity. Coordinator integration and publication are separate.

## Delivered boundary

The [native entry](../../integration_test/linux_profile_footer_native_test.dart)
runs the existing production [AppShell](../../lib/shared/widgets/app_shell.dart)
and real ProfilesScreen with deterministic denied-grant channel/directory
fixtures. No production code, Agent contract, dependency, localization, profile
configuration or canonical ledger changes were necessary.

The [journey](../../integration_test/support/profile_footer_native_fixture.dart)
reuses the existing footer, focus and navigation widget helpers. The
[runner](../../integration_test/run_linux_profile_footer_native.py) reuses the
[compact-return isolation harness](../../integration_test/run_linux_shell_compact_return.py)
with explicit task, target, receipt and validator arguments. Its original
no-argument target, task and retained receipt name remain unchanged. Both native
journeys ran successfully. The shared harness additionally retains the built
Linux binary digest before deleting its owned build/state workspace.

Ponytail full decision: reuse composition, fixtures and source/process isolation;
no duplicate native harness, new API, management fallback, new feature or
production abstraction. The new validator's malformed-receipt self-check and
[nearest regression](../../test/integration/linux_profile_footer_native_runner_test.dart)
exercise this reuse. Synthetic validator unit data is not execution evidence.

## Acceptance evidence

One real GTK/Flutter Linux test journey runs at both 100% and 200% text with
reduced motion, a 1280×720 wide viewport and 390×720 compact viewport:

- Tab reaches Manage profiles when expanded, collapsed and returned from compact.
  Shift+Tab reverses footer→Settings; Tab/Shift+Tab reverses footer→route editor.
  Ten focus receipts contain safe semantics, on-viewport rectangles, real rendered
  outline pixels and inverse-traversal assertions. Targets are at least 48×48.
- Keyboard Enter collapses the sidebar. Compact has no desktop footer/sidebar;
  returning wide restores the 64px collapsed sidebar without replacing the
  ProviderScope. The footer remains keyboard-reachable.
- Replacing owner A/session A with B/session B updates the redacted tooltip and
  semantics, and the expanded value. A subsequent obsolete-channel notification
  cannot restore A. Sensitive-looking path/token markers are synthetic; the
  expected displayed value is `Profile B [redacted-path] token=[redacted]`.
- After adaptive return, Space in collapsed mode and Enter in expanded mode each
  navigate exactly once to the real ProfilesScreen, at both text scales. The
  replacement's exact selected profile `b`, active session `synthetic-session-b`
  and complete state object remain unchanged. Denied grants expose no New Profile
  or profiles-search affordance. No domain selection or inventory permission is
  inferred from navigation.
- Passive directory construction throws. Both old and current channels' existing
  fake call counters/lists are asserted empty/zero across the whole journey:
  connection, session/profile mutations, submissions, Stop, approvals, provider/
  model writes, history/reconciliation and supported inventory reads. The
  receipt reports zero reads/sends/mutations at those deterministic seams.
  This is not a captured HTTP transcript or proof of live Agent transport.
- The test unmounts its tree without framework exceptions. The harness observes
  the receipt-producing native PID as a live child of its driver, binds its Linux
  start ticks and receipt digest, confirms the owned process group is gone,
  checks unchanged source/dependency hashes and removes isolated state.

Input is `WidgetTester.sendKeyEvent` in the native Flutter engine, not a physical
keyboard or OS-input test. Adaptive sizes use
`IntegrationTestWidgetsFlutterBinding.setSurfaceSize` plus
`TestFlutterView.physicalSize`, not an OS-window resize. Aligning both metrics is
necessary for root-layer capture coordinates; initial 900px surface-only captures
were clipped/transformed by the native view and are retained as failed attempts,
not passing focus evidence. Native production code did not need a fix.

## Commands and source binding

Base committed candidate: `ba832dc552279279f76bff0691b4c536ac922aea`.
The generated manifest-pinned initial guard returned `worker_start_admitted`
before edits. Owned task-branch commit and repeated acceptance commands are bound
by the pinned `finish_task.py` receipt in the native review handoff; HEAD remains
on the original admitted candidate. No worker merge or push is authorized.

Executed checks (exit 0 on the final source):

```sh
flutter pub get --offline
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 test/shared/widgets/app_shell_profile_footer_test.dart test/shared/widgets/app_shell_focus_traversal_test.dart test/integration/linux_profile_footer_native_runner_test.dart test/integration/linux_shell_compact_return_runner_test.dart
dart format --output=none --set-exit-if-changed integration_test/linux_profile_footer_native_test.dart integration_test/support/profile_footer_native_fixture.dart test/integration/linux_profile_footer_native_runner_test.dart
python3 -B integration_test/run_linux_profile_footer_native.py --self-check
python3 -B integration_test/run_linux_profile_footer_native.py
python3 -B integration_test/run_linux_shell_compact_return.py
git diff --check
```

The focused suite passes 16 tests. Analyzer reports no issues. Formatting has no
changes. A local Markdown-link existence check also passes. Initial analyzer
findings were two missing block braces in new test code; both were repaired.
Three initial native focus-capture failures were diagnosed and retained, then
both native runners passed. No infrastructure or upstream boundary was bypassed.

Evidence is retained privately under `.task-evidence/t_247cda0e/`: source manifest,
pre-check `executed-source.tar.gz`, dependency manifest, build/test log,
`profile-footer.json`, `verification.json`, analyzer/test logs and the final
finish-helper log. The compact regression uses its unchanged original
`.task-evidence/t_0246c28c/` receipt location. These ignored artifacts are not
product source or a published distribution.

One final pre-commit native receipt is `native-ddte3ylb/verification.json` (106.45s):

| Input/artifact | SHA-256 |
| --- | --- |
| Source manifest | `304ff9dd41076f335b369624efdd6bf4bc4a2479828aaebefb0b7c818095a011` |
| Retained source archive | `a662f9605e4f915d2f3ca2d7c6f0ee9299eff222dcb71115c9e26330ca77b67c` |
| Native binary | `d752c0cfe34474037f46d1dcaef743c1d6809bd7e7c0a9af906aa55bba4b4bb2` |
| Native focus/owner receipt | `98faa68c53e59918159cd4edfb227a930e77e19c102c510076e6da92154975b4` |
| Unchanged production AppShell | `4bed03a2823cfb5d7e92d7ebe731f179081e2e473dbecbc3dcb3eaf3e9a2d2c5` |
| New native journey fixture | `2ba33345071ed394ad19eeb149e5552130b22e043d475e2b98637bf102c51a63` |
| Footer runner | `5fb794d721e015669cdcf6c76d452462126c316f9c0f97e8f57d5ac7fb78d2cf` |
| Reused compact-return runner | `42bacd7551ae58abff58fc40a05a0b0ce2322b4cfcc12d2f872b2181fe4ae72c` |

The runner uses Flutter 3.44.2/Dart 3.12.2, owned Xvfb and cached user-space Linux
build prerequisites, with isolated HOME/XDG and no inherited session DBus. No
system installs, personal state, live Agent, credentials or inference are used.

## Limits and next slice

Independent review, canonical integration, publication and
`VERIFY-PROFILE-FOOTER-NATIVE-RECOVERY` remain separate. Full
`PARITY-COMPOSITION` is partial; no ledger closure is proposed before review.
Physical keyboard/OS resize, screen reader, Android, keyring, live Agent/provider,
packaging/install/update and full repository/release/browser gates are
NOT_CHECKED. This bounded fixture does not qualify those outcomes or the split
edit/switch footer and other remaining Desktop composition features. See the
[earlier implementation boundary](profile-footer-implementation.md) and
[client ADR](../adr/client.md).
