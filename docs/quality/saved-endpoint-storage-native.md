# Isolated Linux saved-connection secure persistence

Card: `t_d83a3347`. Goal task: `M1-SAVED-ENDPOINT-REAL-STORAGE`.
This qualifies one connection-restoration preparation slice, not M1 or delivery.

## Implemented and qualified

The new native integration target exercises the production Chat saved-row editor
and `SecureHermesEndpointStore`, using the real FlutterSecureStorage/libsecret
and native SharedPreferences plugins. No product correction was necessary.
Inherited production/store/editor bytes remain predecessor-owned and unchanged.

Two genuine compiled Linux GTK processes share one private session DBus,
GNOME Keyring Secret Service and disposable HOME/XDG state. The first process
seeds four independent same-label endpoint pairs (one pair for each 1280/390
logical-width and 100/200% Flutter text-scaling case). Public keyboard Edit/Cancel
leaves canonical state unchanged. Edit/Save repairs exactly the original ID and
origin and preserves its peer and labels. The second process loads all repaired
rows and credentials from native storage, reopens each original ID through the
public Edit action, and asserts the replacement-credential field is blank.

Each pair also exercises a real DBus policy denial of Secret Service
`org.freedesktop.Secret.Collection.CreateItem`. Save reports the exact localized
failure, leaves the editor and URL/credential draft available, does not show the
success notice, and does not change canonical storage. The owned harness restores
permission through synchronous `ReloadConfig`; only explicit keyboard Save
retries. Canonical real-plugin readback succeeds, including after process restart.
The denial is a private-service write denial, not a qualification of every locked,
missing, corrupt or hardware-backed keyring failure mode.

Ephemeral, non-authorizing credential discriminators and a test witness exist only
in memory and secure storage. The witness is test evidence, not alternate endpoint
authority; both phases read endpoints through the production store. Safe boolean
assertions avoid dumping secret-bearing objects. In-memory checks scan ordinary
preferences for every marker and credential field. No marker values or secret
hashes are retained. Before captures, the unsaved main connection credential field
is cleared; reopened replacement fields are also blank. No credential-bearing
editor is captured during failed-save/retry.

No network call is needed. A deterministic active-channel fixture establishes a
baseline owner; zero additional connection/disconnection, Agent read or mutation
attempts are asserted. No real Agent, inference, session/run creation, send,
approval, Stop, Wing Link management or automatic replay occurs. This is not a
qualification of actual Agent interaction.

## Isolation and lifecycle

The launcher reuses the existing snapshot/dependency helpers and the immutable
Git runtime/process/display helper at
`894439b76c889fed45f3c4d57b73086f1e18d479`. No predecessor helper is edited.

- Environment construction drops inherited HOME, DISPLAY, session DBus,
  credentials, proxies and Agent authorization; HOME/XDG directories are private.
- Bus configuration has a private Unix socket, EXTERNAL authentication, no system
  activation directories and no external listener. State paths are kept short
  enough for Linux Unix-socket limits.
- GNOME Keyring runs in an owned process group; its random unlock password travels
  only through stdin and is never retained. The bus-reported service PID is checked
  against that group before launching Flutter.
- Owned Xvfb requires an ephemeral owner-only Xauthority cookie. Missing and wrong
  authorities are rejected before the journey. No owner's display is attached.
- Each native app PID/start tick is observed inside its Flutter driver's group;
  write and verify use different drivers and native PIDs. The same bus/keyring
  remains alive across the boundary.
- Existing `run_owned` tears down whole groups on success, timeout, cancellation
  and exceptions before state removal. Tests inject an observer exception and
  verify group death and workspace deletion. Final receipts additionally check
  recorded service processes are gone. No personal keyring/preferences are read.

## Executed evidence

Final evidence directory:
`build/t_d83a3347/evidence/attempt-vowpwo0g/`.
`verification.json` binds exact commands, exit statuses, durations, environment,
source/dependency hashes, service/process identities, native binary identity and
linked-library listing. The final source archive SHA-256 is
`6b59e55bb01b88a0290d208b4602f3ebbbf259d780074f48eaf7ef9e50a497aa`;
its source manifest SHA-256 is
`f2a84e2e1ccd556ced3d0fe6f4ff9395db788e5c8473d13672d634be2a365d96`.

The inherited source and package closure were frozen before implementation under
`build/t_d83a3347/evidence/baseline/`. Comparing all inherited source fingerprints
against the final candidate found no drift. Source archives exclude upstream
clones, credentials, personal runtime state and build outputs. Frozen package and
offline Go-module closures are retained with manifests. Linux CMake builds the
existing bundled Wing Link executable, but this test launches no Wing Link service.

Final native PIDs: write `276981`, verify `282240`; private bus `272616`, keyring
`272637`. Final launcher duration: 247.697 seconds. Both native phases passed.
The bus log records actual rejected CreateItem calls, without payloads. Both
service groups and display were torn down; isolated state was deleted.

These commands passed on the final frozen candidate (SDK command prefixes are
recorded verbatim in `verification.json`):

```sh
python3 -B -m unittest discover -s test/tooling -p saved_endpoint_storage_native_test.py
bash -n scripts/run_linux_saved_endpoint_storage.sh
dart format --output=none --set-exit-if-changed integration_test/linux_saved_endpoint_storage_test.dart integration_test/support/saved_endpoint_storage_native_fixture.dart
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 test/core/hermes/setup/saved_endpoint_edit_store_test.dart test/features/hermes_chat/screens/hermes_chat_saved_endpoint_edit_test.dart
timeout 30m bash scripts/run_linux_saved_endpoint_storage.sh
```

Python: five tests. Focused Dart: 23 tests. Analyzer: no issues.
Native: one integration test per process, four width/scale cases each. Build
parallelism is two; no broad suite was run. `git diff --check` passed.

Eight launcher attempts produced new evidence rather than repeating an unchanged
failure: frozen-test scratch setup (32.616s), long private socket path (74.113s),
missing native development packages (78.129s and 72.753s), invalid member-only
DBus deny policy (102.749s), passing native qualification (199.604s), expanded
public-entry/dependency evidence (201.960s), and final blank-main-field capture
qualification (247.697s). Earlier failure receipts/logs and source fingerprints
remain separate. Earlier screenshots and bulky duplicate dependency archives are
not required evidence and are discarded. Owned copied SDKs, builds, state and
unpacked native prerequisites are removed; retained archives/manifests are the
cited frozen evidence. No privileged installation was used.

## Reproduction and prerequisite boundary

Run the launcher from the assembled Wing development checkout with populated
`.dart_tool`/plugin metadata, Flutter 3.44.2, Go, GTK, Xvfb, ImageMagick `import`,
DBus and GNOME Keyring. Native compilation also needs GStreamer/libsecret headers
and pkg-config metadata. On this host, missing development packages were downloaded
with `apt-get download` and unpacked with `dpkg-deb -x` under this card's ignored
`build/.../deps/sysroot`; generated `.pc` prefixes were relocated there. Export
`PKG_CONFIG_PATH`, `LIBRARY_PATH` and `CPATH` to that private sysroot before running.
Package archive/sysroot hashes and installed tool hashes are retained in the final
receipt. No sudo or system package changes were used.

The source-run Python closure imports the predecessor saved-edit, Remote-retry,
first-run and smoke helpers. The Dart target imports predecessor first-run,
Remote-retry and saved-edit fixtures and their transitive test support. The local
six-file commit is additive, not a standalone checkout: the integration owner must
assemble those prerequisites, or use the retained complete source candidate.
No packaging manifests were changed. Packaged launcher/image/distribution execution
is NOT_CHECKED; checkout native evidence is not packaged delivery.

## Visual limits and remaining work

Twelve final safe native captures are retained. The wide and compact-200% entry
and verify captures were loaded and inspected directly. Wide entry shows the
production saved-row pencil actions and an empty access-token field. The wide
reopened editor shows the repaired loopback URL, blank replacement field and
Cancel/Test/Save controls; compact 200% also shows the blank field and actions.
Compact URL text scrolls horizontally, labels ellipsize and helper/disclosure
content requires scrolling. The compact entry capture is scrolled away from the
saved-row actions, and wide entry focus highlighting is not visually established;
keyboard focus/activation are backed by native assertions, not those images.
Off-screen notice readability, physical keyboard input, screen-reader behavior,
OS text settings and every disclosure being readable simultaneously are NOT_CHECKED.
`ensureVisible` and Flutter key events are test-driver operations, not OS input.

Implemented: additive real-storage native harness and five tooling regressions.
Qualified: named Linux GTK/libsecret/GNOME Keyring backend, including write denial,
explicit retry and two-process canonical persistence at the fingerprint above.
Delivered through protected main: NOT_CHECKED. Local commit/native review handoff
are not merge, release or M1 completion.

Remaining M1 gaps: authorized live generation, correlated approvals/authoritative
Stop, model/session restoration, full connection matrix, other platforms and
protected-main delivery. Next seam: independently authorized, bounded direct-Agent
live workflow qualification or platform-specific storage failure coverage; neither
is enqueued by this card. Usage/cost and review duration are unknown.

Questions: none. Defaults applied: private user-space Secret Service, no network,
production store/plugins, existing helpers and preserved inherited ownership.
