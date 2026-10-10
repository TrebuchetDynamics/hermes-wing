# Optional Local setup recovery

Card: `t_6117d698`; goal slice: `CONNECTION-LOCAL-SETUP-RECOVERY`.
Implemented and qualified against the isolated candidate below; protected-main
delivery, native installation and authenticated Agent connection are NOT_CHECKED.
The broad CONNECTION-PATHS milestone remains partial.

## Change and authority

The controller now rejects inspection, setup and cancellation after disposal.
Its asynchronous disposal cancellation also contains failures instead of leaking
an unhandled exception into a replacement route. Both defects were reproduced
with failing regression tests before the provider was changed.

Existing production consent, Stop, inspection-only Check again, sanitized error
copy, generation fences and explicit Continue behavior were retained, not replaced.
No screen, typed host contract, router, enrollment, localization, dependency,
upstream Agent/Desktop or privileged operation was changed.

The isolated entrypoint renders the production Local setup screen and provider.
Only the typed host runner/starter are synthetic. The harness has a separate
fixture panel and a minimal router: its landing page represents an unrelated
Direct Agent entry, not working Chat or live authentication. Actual production
web entry still does not expose privileged Linux setup. This harness does not
expand platform capability or change the management/data-plane boundary.

Read-only parity reference: Desktop `src/renderer/src/screens/Install/Install.tsx`
lines 55–128 and its adjacent test keep installation consent-bound, single-run,
and late completion mount-fenced. Wing intentionally does not copy privileged
Desktop IPC or raw installation logs. Wing's fixed `inspect --json` and typed
setup-operation/cancellation contract remain in
`lib/core/wing_link/local_wing_link_host.dart`.

## Acceptance evidence

1. Fresh missing/existing inspection exposes Install/Adopt respectively. Escape
   and Cancel leave setup calls at zero. Every Run setup increments the synthetic
   typed starter exactly once. Verified completion requires the post-setup health
   inspection, explicitly says pairing is separate, and does not navigate until
   Continue is activated. Pushed Local setup returns to its original landing page;
   it does not force that unrelated entry into pairing.
2. Stop fences late success, while unit tests cover late success and failure.
   Disposing the route fences both delayed outcomes in Chromium and calls
   cancellation. Failed/stopped states do not replay setup. Check again increments
   only inspection. Unknown process output is absent from rendered semantics;
   existing port-conflict and inspection-failure regressions also pass.
3. Four compiled Chromium keyboard journeys pass: missing/existing × 390/1280px,
   all with 2× Flutter text scaling and reduced animations. Each observes 6
   inspections, 5 deliberate setup starts and 3 cancellations, with zero network
   mutations and zero page errors. This is synthetic host qualification only.

## Frozen candidate and prerequisites

Base HEAD: `b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`.
The source snapshot includes foreign worktree prerequisites, not only that HEAD.
Snapshot location: `.dart_tool/local-setup-recovery/`; file-level SHA-256 inventory
is retained in `.dart_tool/local-setup-recovery-evidence/source-manifest.json`.
Combined sorted source inventory SHA-256:
`1e78686a7c53e1a777e86f80eb1a5b46aa7a4379a3e59e110ec6d9560030372e`.
Compiled `main.dart.js` SHA-256:
`bcbbddbb63f89f0470e2decb994bc23fc67c879b559b4e71217eb8a8645cb0e5`.

Frozen dependency hashes:

- pubspec.yaml: `d321ab03cb44f69eabf75b5c11324bdc726c734df87530db87f00b9a95a70bab`
- pubspec.lock: `de9f16e0d199a369a2ac0fc6ea91735c04a4fb8b189254d2ac272753256b8685`
- package.json: `c5acb3d1eae19f0f20c119745fd3ee5b0677457e01e9b14fcd3d8f1266b4e833`
- package-lock.json: `f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63`

Flutter 3.44.2, framework c9a6c48423, Dart 3.12.2; Node v26.7.0;
Chromium 152.0.7977.75 on Linux. Node differs from the documented Node 22 default;
these are the executed tool identities, not a Node 22 qualification. An earlier
promoted background command observed Node v24.19.0 and stopped at an owned
harness lint; final snapshot/checks were executed in the foreground environment.

## Executed checks and reproduction

From repository root:

```sh
dart format --output=none --set-exit-if-changed lib/features/local_setup/providers/local_hermes_setup_provider.dart lib/main_local_setup_recovery_e2e.dart test/features/local_setup/local_hermes_setup_recovery_test.dart
python scripts/support/local_setup_recovery_snapshot.py
```

From `.dart_tool/local-setup-recovery`:

```sh
timeout 5m flutter pub get --offline
timeout 5m flutter analyze
timeout 5m flutter test --concurrency=1 test/features/local_setup
timeout 8m flutter build web --release -t lib/main_local_setup_recovery_e2e.dart
```

From repository root:

```sh
timeout 10m env CHROME_EXECUTABLE=/usr/bin/chromium NODE_OPTIONS=--max-old-space-size=2048 npx playwright test playwright/tests/regression/local-setup-recovery.spec.mjs --config playwright/local_setup_recovery.config.mjs --workers=1
git diff --check
```

Results: no analyzer issues; 22 local-setup tests passed; JS web release built
in 51.9s; final four browser journeys passed in 32.9s; format and diff checks
passed. Web compilation emitted existing flutter_tts Wasm dry-run warnings and a
Cupertino font warning; no Wasm claim is made. Only focused checks were run;
MT-RERUN-TRAIN retains combined gates.

Iteration evidence: disposed-controller test first observed additional inspect
and setup calls; disposal-failure test first observed an unhandled synthetic
failure. Both pass after the provider repair. First browser run failed because
Flutter merges state text into named semantic groups; the next focused run found
progress text is a named progressbar. Selectors were repaired against actual
semantics without changing production assertions or UI. Subsequent full runs
passed; final run includes viewport-only, keyboard-focused captures and an
ignored output location. Review duration and monetary cost are unknown.

## Visual inspection and retained evidence

Evidence directory: `.dart_tool/local-setup-recovery-evidence/` contains the
Playwright JSON report, four request-count receipts and consent/stopped/failure/
verified PNGs. Screenshots were opened and inspected: compact consent is readable
with both buttons visible; compact failure wraps Check again/Connection options
without overlap; wide failure and verified completion remain readable, with
pairing explicitly separate. Compact app-bar title ellipsizes at 2× text, while
its full semantic heading remains available. The fixture panel is not shipped UI.
The browser assertions confirm keyboard focus before recovery/completion captures.

The ephemeral server was shut down; port 18997 was checked free. Build outputs
created inside the snapshot are removed after recording compiled identity;
reproduction builds them again. Foreign shared HEAD/index/worktree changes are
not included in the local owned-files commit.

## Remaining milestone gaps

Native installs/adoption, service restart, live authentication/provider inference,
OAuth, managed SSH, Android, full production enrollment routing, complete
setup/auth matrix and protected-main delivery remain NOT_CHECKED. Next milestone
seam is the remaining full enrollment/auth matrix, not replaying the already
qualified Remote/saved-host subsets. Questions: none; existing conventions applied.
