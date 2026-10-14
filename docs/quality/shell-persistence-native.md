# Linux shell preference process-relaunch evidence

Scope: DOC-SHELL-PERSISTENCE-EVIDENCE / SHELL-PERSISTENCE, native card
`t_c5aaada0`. This qualifies the existing Wing shell preference on an isolated
Linux GTK fixture, not official Desktop parity, Agent recovery or device support.
Independent native review and coordinator delivery remain separate gates.

## Journey and isolation

Run from the repository with cached Flutter dependencies prepared:

```sh
flutter pub get --offline --enforce-lockfile
python3 -B integration_test/run_linux_shell_persistence.py
```

The runner reuses the existing snapshot, package relocation, owned-process
teardown and HOME/XDG isolation helpers. It copies the cached Flutter SDK,
packages and user-space native prerequisites; it does not install system
packages. The native prerequisite cache is the same repository-local
`t_636ced72/deps/root` used by the existing Linux serve runners. Missing cached
prerequisites fail the run; there is no download or installation fallback.

1. Start a real Linux GTK app with empty isolated preferences. The production
   `AppShell` and `WingShellPreferencesController` render a 250px sidebar.
2. Traverse to the public sidebar toggle with Tab and activate it with Enter.
   Assert focus and 64px width, then reload the platform preference and assert
   `wing.shell.sidebar_expanded == false`.
3. Observe the receipt while the GTK process is alive, binding its PID and Linux
   start ticks to the owned driver process group. Wait for the driver exit and
   verify that the entire group is gone before launching the second phase.
4. Start a different GTK process against the same isolated HOME/XDG storage.
   Assert initial and final 64px width without activating the toggle. Read back
   the real Linux SharedPreferences JSON under XDG data home; its relative path
   and SHA256 must match the first phase exactly.
5. In each process, inject an unavailable preference loader into a separate shell
   scope and activate its keyboard toggle. The in-memory sidebar remains usable;
   this is an injected denial, not a claim that persistence succeeded.

The route content and disconnected channel are deterministic test fixtures.
Existing channel call recordings are checked for zero reads, sends and mutations;
no real Agent transport, authentication, credential storage or inference is used.
Native preference persistence is not mocked in the collapse/relaunch phases.
Keyboard events use Flutter's test key-event dispatch through the public focus
and control path; physical keyboard/OS event injection is not qualified.

`integration_test/linux_shell_persistence_test.dart` rejects execution without the
runner's isolated HOME/configuration and valid phase, including an inherited
DBus session. Xvfb uses private authentication and disables TCP listening.
Successful teardown removes the isolated app, SDK, packages and preference state;
source archives, receipts and logs remain in ignored task evidence.

## Checks and retained evidence

The mandatory scoped finish gate runs all of these commands before committing:

```sh
flutter pub get --offline --enforce-lockfile
dart format --output=none --set-exit-if-changed integration_test/linux_shell_persistence_test.dart integration_test/support/shell_persistence_fixture.dart test/integration/linux_shell_persistence_runner_test.dart
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 test/features/settings/providers/shell_preferences_provider_test.dart test/shared/widgets/app_shell_sidebar_persistence_test.dart test/integration/linux_shell_persistence_runner_test.dart
python3 -B integration_test/run_linux_shell_persistence.py --self-check
python3 -B integration_test/run_linux_shell_persistence.py
git diff --check
```

The self-check rejects incorrect phases, process identities, widths, keyboard
and persistence verdicts, unavailable-storage verdicts and nonzero/mistyped
channel counts. Its Dart consumer makes it part of the focused test command.
The existing provider tests also cover early interaction during loading,
serialized writes, unreadable storage, write failure recovery and disposal.

Each native attempt retains `.task-evidence/t_c5aaada0/native-*/`:

- `verification.json`: final status, both command exits, process observations,
  preference hashes, environment and duration.
- `source.json`, `archive.json`, `executed-source.tar.gz`: exact executable
  candidate inputs and hashes captured before execution, including the runner's
  reused helper closure. Executed source is rechecked after both phases.
- `dependencies.json`: copied package/native prerequisite content hashes, also
  rechecked after execution. Verification binds the manifest, lockfile, engine
  stamp, Flutter/Dart versions, platform and pkg-config versions.
- `collapse.log`, `restore.log` and phase receipts: real GTK execution and measured
  sidebar/call outcomes. Any failed exit aborts rather than upgrading a receipt
  to success; `verification.json` is retained on failure too.

During development the first native attempt failed because semantics handles
were disposed after Flutter's end-of-test invariant. The fixture now disposes
its handles before returning. The next attempt passed GTK collapse but failed
the disk oracle, which incorrectly searched XDG config rather than XDG data.
The installed Linux SharedPreferences/path-provider implementation was traced
read-only; the oracle now uses its actual XDG data location. These were fixture
corrections, not production defects; both failed attempts remain retained.

## Remaining boundaries

Development acceptance on Linux x86_64 with Flutter 3.44.2 / Dart 3.12.2:
`native-aows65ze/verification.json` records PASS in 65.279 seconds. Both GTK
drivers exited 0, application PIDs differed, the restored width was 64px and
both receipts recorded reads/sends/mutations = 0/0/0. The saved preference digest
was identical across phases:
`9c2861479b330e9c8e5b9cead251a6dd89e600a00309b793da96f2531c4acb93`.
The source manifest was
`bfdcdf7b91c4665f5597b958937c3fb48b49d9ed909cc2fdd8fb43e8d40157bf`.
The finish gate reruns the complete command list against the final owned inputs;
its source-bound result, rather than this earlier development receipt, controls
the exact commit handoff. Initial analysis passed and all nine focused tests
passed; the retained failed native attempts are not counted as passes.

No production provider or shell change, new dependency, localization change,
Agent API call or canonical ledger update is needed for this slice.
The task's exact commit, accepted attempt and finish receipt are recorded in its
native review handoff; pending review is not independent acceptance.

Actual OS keyring, installed personal app state, live Agent/provider journeys,
Android process relaunch and physical-device acceptance remain NOT_CHECKED.
The separate production serve-recovery card and its original accounting are
unchanged. This fixture cannot close those milestones or establish official
Desktop fidelity. See the [existing shell slice](graphify-shell-persistence.md)
and [reference correction](official-desktop-reference.md).
