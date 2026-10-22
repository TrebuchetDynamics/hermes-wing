# Linux shell compact-return evidence

Scope: DOC-SHELL-COMPACT-RETURN-EVIDENCE / SHELL-PERSISTENCE, native card
`t_0246c28c`. This bounded fixture qualifies adaptive return in a real Linux GTK
process. It does not qualify physical window resizing, official Desktop parity,
installed personal app state or a live Agent journey. Independent native review
and coordinator integration are separate gates.

## Journey and seam

The production `AppShell` and shell preference controller are unchanged.
`runShellCompactReturnJourney` reuses the existing shell-persistence keyboard
collapse journey, disconnected channel and navigation fixture's draft field.
No new dependency, platform configuration, export or production caller is needed.

1. Render wide at 1280 by 900 with empty isolated Linux preferences; observe the
   initial 250px sidebar. Tab to the public toggle and activate with Enter;
   observe focused toggle, 64px sidebar and persisted `sidebar_expanded == false`.
2. Enter a deterministic local draft and capture its `TextField` State identity
   and the existing provider container. Reload the native SharedPreferences.
3. Change the test surface to 390 by 900. Assert the desktop sidebar is absent,
   the identical field State and draft text remain, the provider container is
   identical and both in-memory and reloaded preferences remain false.
4. Return the surface to 1280 by 900. Assert the sidebar returns at 64px with
   the same State, text, provider container and persisted choice.
5. Assert zero recorded Agent reads, sends and mutations after the entire journey;
   read the real Linux preference JSON as a second storage oracle.

The resize seam is explicitly
`IntegrationTestWidgetsFlutterBinding.setSurfaceSize`, not a physical OS window
resize. Key events and text entry use Flutter's test dispatch, not OS keyboard
injection. The draft is deterministic route content, not production chat storage
or a claim that drafts survive a process relaunch.

## Isolation and proof

The current runner reuses `run_linux_shell_persistence.py`'s module loader and
preference oracle, the current owned-process helper, and the shared
[qualification input/environment seam](linux-qualification-driver.md). Set
`WING_LINUX_DEPENDENCY_PREFIX` to a reviewed disposable **usr directory**, put
Flutter 3.44.2 on PATH and provide `PUB_CACHE` for non-SDK package roots. There is
no historical private-prefix or Git-object fallback. Current source, SDK and
packages are copied into owned isolation; no system install or network fallback
is offered. This portability change is offline-tested, not a rerun of the native
result recorded below.

Xvfb uses private authentication with TCP listening disabled. The native test
rejects non-Linux execution, nonisolated HOME/XDG paths and inherited session
DBus. No personal preference storage, keyring, Agent transport or provider is
used. The runner bounds native execution at 600 seconds and binds the receipt's
PID and Linux start ticks to its still-live owned process group. Success requires
exit 0, the receipt still matching its observed hash and the entire owned group
gone. The owned-workspace helper removes temporary app/SDK/packages/state even
on failure; logs and source evidence remain.

The receipt validator requires every journey verdict, exact widths and resize
seam, a positive integer PID and correctly typed zero call counts. Its self-check
rejects missing fields, incorrect values, nulls and boolean integer impostors.
The Dart runner regression executes that self-check. Source inputs and copied
package/native dependencies are hashed before execution and rechecked afterward.

## Commands and retained evidence

Run from the repository with the cached toolchain prepared:

```sh
flutter pub get --offline --enforce-lockfile
dart format --output=none --set-exit-if-changed integration_test/linux_shell_compact_return_test.dart integration_test/support/shell_compact_return_fixture.dart test/integration/linux_shell_compact_return_runner_test.dart
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 test/features/settings/providers/shell_preferences_provider_test.dart test/shared/widgets/app_shell_sidebar_persistence_test.dart test/integration/linux_shell_compact_return_runner_test.dart
python3 -B integration_test/run_linux_shell_compact_return.py --self-check
python3 -B integration_test/run_linux_shell_compact_return.py
git diff --check
```

The historical handoff used a pinned `finish_task.py` gate; its exact candidate
and receipt remain the bounds of those results. Current checks and any new native
run require fresh evidence; pending review is not approval.

Current standalone evidence is under `$TMPDIR/compact-return-*`; campaign runs
retain artifacts under their private output directory. Historical
`.task-evidence/t_0246c28c/native-*/` attempts retained:

- `verification.json`: exact native argv/exit, journey receipt, observed process,
  cleanup verdict, source/dependency pins, toolchain/platform identities and time.
- `source.json`, `archive.json`, `executed-source.tar.gz`: pre-execution source
  manifest and retained candidate, including the reused helper closure.
- `dependencies.json`: copied package/native prerequisite content hashes.
- `native.log`, `compact-return-receipt.json`: GTK execution log and measured
  journey results. Failure retains its verification receipt without a PASS claim.

Development execution `native-qn51p2i1` passed in 41.166 seconds on Linux x86_64,
Flutter 3.44.2 / Dart 3.12.2. Native exit was 0; draft State/text and container
were retained, restored width was 64px and reads/sends/mutations were 0/0/0.
The source manifest SHA256 was
`e84216d499c0a7d2d83b730393aa7074001f8dcbd174e8ad6e7442ceaebb571a`;
archive SHA256 was
`9ba657a32ae3694231ab78aba83202ab674a912c0c43e542dbd5a82a068fba88`.
The stored preference file SHA256 was
`9c2861479b330e9c8e5b9cead251a6dd89e600a00309b793da96f2531c4acb93`.
Analysis passed. The first focused run passed the eight existing tests but caught
a self-check mistake that treated another positive PID as invalid. The invalid
PID sample is now zero; self-check and actual native execution passed afterward.
No production defect was observed. Final finish-gate checks supersede these
intermediate development results for the exact commit handoff.

## Boundaries and minimal-change decision

Applied `ponytail:ponytail` full criteria: extend the existing fixture, reuse the
existing isolation/process/source helpers and add only this journey, runner,
runner regression and evidence document. Omitted OS-resize tooling, new
abstractions, dependencies and production changes because this slice does not
need them. No original cards, canonical ledger, Agent/runtime/reference sources
or shared services were changed.

Android, installed app, actual keyring, physical keyboard/window resizing and
live Agent/provider behavior remain NOT_CHECKED. Full SHELL-PERSISTENCE and
Desktop daily-use acceptance stay open. The coordinator alone reconciles the
canonical task/goal evidence after independent review and authorized integration.
See [process-relaunch evidence](shell-persistence-native.md),
[existing shell slice](graphify-shell-persistence.md) and
[reference correction](official-desktop-reference.md).
