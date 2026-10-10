# Native two-process relaunch qualification

Card: `t_eb5c693d`. Goal task: `PARITY-NATIVE-RELAUNCH` / M1.
Result: PASS for the bounded deterministic Linux workflow. Native review is the
final card handoff; approval is subsequent and is not implied by this receipt.

## Delivered change

The [launcher](../../scripts/run_linux_desktop_daily_workflow_e2e.sh) now uses
independent source, build and Flutter SDK copies created by the
[workspace helper](../../scripts/support/desktop_daily_workspace.py). It no longer
mistakes unrelated Flutter testers for owners of these new resources. The SDK
copy has independent inodes, including its lock; no shared SDK locks are removed.
The receipt lock is acquired before opening/truncating logs. Existing native
plugins and the bundled Wing Link build remain enabled. Go and native compiler
parallelism are bounded to two.

The copied dependency closure includes package configuration and graph, Linux
host sources, Wing Link sources/assets, and the fixture's transitive local JS
imports. Upstream Agent/Desktop references and shared build output are excluded.
The original pub and Go module caches remain explicit tool inputs; compilation,
preferences, HOME/XDG directories, display and Go build cache are owned temporary
resources. This is development isolation, not an OS security sandbox.

The [integration target](../../integration_test/linux_desktop_daily_workflow_test.dart)
now emits actual native process IDs and counters derived from fixture readback,
and checks the channel's confirmed session/provider/model identity. The runner
retains separate model and lifecycle receipts, verifies distinct native PIDs and
checks that all owned child groups have disappeared before deleting isolated
state. Incomplete teardown retains state and fails instead of reporting success.

[Workspace regressions](../../test/tooling/desktop_daily_workspace_test.py) exercise
independent SDK lock/source writes, package-root relocation, dependency closure,
exclusion of shared ephemeral output, refusal of existing destinations, and a
competing launcher that must not truncate the owner's log.

## Executed acceptance evidence

Executed on Ubuntu 24.04.4 amd64, Linux, Flutter's GTK desktop runner under a
fresh Xvfb X11 display with software rendering. Base checkout:
`1afe1307e37ee1ddfa1f7d67ad047509e99c8784` plus preserved uncommitted work.
Evidence is bound to copied input SHA-256 manifests, not a claim that the clean
base commit or the card-only branch has the same runtime behavior. No predecessor
production changes, tests or receipts were rewritten.

1. Two real native phases: PASS. Final invocation:
   `timeout 700s bash scripts/run_linux_desktop_daily_workflow_e2e.sh`, exit 0,
   with the package environment below. Each phase invokes the isolated SDK's
   `flutter test --verbose --no-pub -d linux integration_test/linux_desktop_daily_workflow_test.dart --reporter expanded`.
   Write native PID 1058090 and verify native PID 1060230 both exit successfully.
   Both read back gateway `daily-fixture`, profile `default`, session
   `e2e-hermes-session`, 2 submissions, 1 approval, 1 Stop and 0 unexpected
   mutations. Restoration compares before/after mutation and session state,
   proves the pointer is absent from the first inventory page, and requires exact
   metadata and canonical history fetched by production restoration itself.
   Final fixture counters: 10 inventory reads, 2 exact metadata reads and 5
   history reads. Verify displays the canonical stopped outcome and completed
   reply after reopening the Chat route. No replacement session or replay occurs.
2. Restoration/isolation regressions: PASS. The isolated checkout executed
   `flutter analyze --no-pub` (exit 0, no issues), and
   `flutter test --no-pub --concurrency=1 test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart test/features/hermes_chat/gateways/gateway_contact_cache_test.dart test/tooling/linux_live_directory_isolation_test.dart`
   (exit 0, 56 tests). Exact SDK paths and commands are in `focused-checks.json`.
   The isolation suite
   `python3 -m unittest discover -s test/tooling -p desktop_daily_workspace_test.py`
   passed 2 tests, exit 0. The nearest existing fixture suite
   `timeout 60s node --test playwright/support/hermes_desktop_daily_fixture_test.mjs`
   passed 3 tests, exit 0. This existing suite is not a new native model-restoration
   or live-provider claim.
3. Source-bound receipts and owned cleanup: PASS. `teardown-receipt.json` records
   both phase launcher exits 0, fixture exit 143 (intentional SIGTERM),
   `all_reaped: true`, no surviving owned groups and
   `all_owned_groups_gone: true`. The outer launcher reports guarded state removal.
   A subsequent directory probe found no `wing-linux-daily.*` or
   `native-relaunch-checks.*` roots. Task-owned SDK/source/build copies were removed;
   downloaded/extracted prerequisites were removed after retaining their manifest.

Additional checks, all exit 0:

- `bash -n scripts/run_linux_desktop_daily_workflow_e2e.sh`
- `dart format integration_test/linux_desktop_daily_workflow_test.dart`
- `dart format --output=none --set-exit-if-changed integration_test/linux_desktop_daily_workflow_test.dart`
- `git diff --check`

## Separate model and lifecycle scenarios

The model test first rejects then accepts the explicit `alpha` /
`alpha/model-99` pair for its exact session. It confirms production channel state,
2 lock attempts and zero runs. The lifecycle scenario is then reset separately
using its legacy no-body seed. Its model mutations remain forbidden; its two
native phases qualify selection/history persistence, not model persistence.

The live fixture now also supports an optional `desktop-daily` model scenario;
therefore the card's blanket description that the lifecycle fixture cannot
support any model writes was stale. That was recorded on the card. This change
intentionally retains separate scenarios, as requested, rather than expanding
into combined-fixture or live-inference qualification.

Model restoration across process restart, a combined model/generation journey,
live Agent/provider inference, full app-shell startup, credential enrollment,
physical input/IME, audio, physical Android, screen-reader behavior and signed
release/package distribution: NOT_CHECKED. The integration app uses the production
HTTP/SSE channel, Chat widget and real Linux SharedPreferences, but an injected
synthetic endpoint store. The bundled Wing Link compiles; no service is launched
or lifecycle authority added.

## Safe user-space prerequisites and reproduction

The initial runner invocation exited 2 because libsecret and GStreamer development
metadata were missing. Installed runtime versions were confirmed before resolving
compatible Ubuntu Noble packages. No sudo, host package install/update, plugin
removal, fake library or system package database mutation was used.

These commands ran from the Wing root, each package download/extraction batch
under a 120-second timeout. Public package downloads were verified by apt;
`prerequisites.json` retains all 13 filenames, versions and SHA-256 hashes.
The developer explicitly prepares this local prefix; the runner does not install
or download packages automatically.

```bash
mkdir -p build/native-relaunch-prereqs/packages build/native-relaunch-prereqs/root
cd build/native-relaunch-prereqs/packages
apt-get download libsecret-1-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev liborc-0.4-dev
apt-get download libgcrypt20-dev libgpg-error-dev libunwind-dev libdw-dev libelf-dev libsecret-1-0 libgstreamer1.0-0 libgstreamer-plugins-base1.0-0 liborc-0.4-0t64
for f in *.deb; do dpkg-deb -x "$f" ../root; done
cd ../../..
python3 -c "import pathlib; r=pathlib.Path('build/native-relaunch-prereqs/root').resolve(); [(p.write_text(p.read_text().replace('prefix=/usr', 'prefix='+str(r / 'usr')))) for p in r.rglob('*.pc')]"
export PKG_CONFIG_PATH="$PWD/build/native-relaunch-prereqs/root/usr/lib/x86_64-linux-gnu/pkgconfig"
export LIBRARY_PATH="$PWD/build/native-relaunch-prereqs/root/usr/lib/x86_64-linux-gnu"
timeout 700s bash scripts/run_linux_desktop_daily_workflow_e2e.sh
```

Use a fresh extraction prefix and recheck candidate/runtime compatibility on
another host. Observed host runtime versions: libsecret 0.21.4-1build3,
GStreamer core 1.24.2-1ubuntu0.1, GStreamer base 1.24.2-1ubuntu0.5 and
ORC 1:0.4.38-1ubuntu0.1. No loader override was needed: installed runtime ABI
matched the extracted development libraries. `LIBRARY_PATH` is necessary because
the real audioplayers plugin links GStreamer library names without propagating
the pkg-config library directory; this is a build environment fix, not a plugin
patch. Plugin loading succeeded; audio functionality itself was not exercised.

Intermediate native attempts returned exit 1 and produced new diagnostic evidence:
missing copied JS fixture imports, missing copied package graph, missing bundled
Wing Link sources, and finally the audioplayers linker search path. Each was
repaired before rerunning. Verbose logs were enabled to expose the linker failure.
The final runner then passed twice as receipt checks were strengthened; final
retained receipts below refer to the last run only, not the failed attempts.

## Retained evidence and source identity

Review attachments preserve `launcher.log`, `write.log`, `verify.log`,
`fixture.log`, `final-receipt.json`, `phase-receipts.json`, `model-receipt.json`,
`teardown-receipt.json`, `source-manifest.json`, `focused-source-manifest.json`,
`focused-checks.json`, `analyze.log`, `focused-tests.log`, and `prerequisites.json`.
They were produced under the profile scratch directory's
`desktop-daily-workflow-harness` receipt directory; review attachment copies are
the durable evidence, not the disposable build directories.

SHA-256 values from the final native manifest:

- Launcher: `89961a3d0b54bfa3f724bd183c92bed7cc9eb1bb01567c9d227dda4541816b82`
- Workspace helper: `a6bb8f27ebdd9aeea7a2c481ea004cbdb0850c36182ffcc1cfd842f9309ed67a`
- Integration target: `8ff1078c96bf29f38139aaf0876c0b50fa54888f8c53f04d0a6fa4a9a66fe5c2`
- Unmodified daily fixture wrapper: `0881effdd01686830ecec30da5e10e471181aa614fe47aa180df7a079bae1773`
- Preserved shared fixture: `4b70918cad51b44afed0d82ece43fd65c01a8031d29393a5007e8cc4afeb0100`

Questions: none. Default applied: retain separate synthetic scenarios, preserve
all unrelated work, and do not claim unexecuted live/platform qualification.
