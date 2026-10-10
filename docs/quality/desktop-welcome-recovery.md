# Desktop welcome recovery on Linux

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card `t_636ced72` implements and qualifies `PORT-DESKTOP-WELCOME-RECOVERY`.
`CONNECTION-PATHS` remains partial. This is an isolated GTK fixture result, not
live authentication, Android qualification or protected-main delivery.

## Implemented delta

`HermesAddScreen` now uses widget-order focus traversal only for welcome entry.
The first native run reproduced inaccessible keyboard Back after scrolling the
200% text form at both 390px and 1280px. Stable traversal fixes that root cause
without changing shell-route traversal, transport, credentials or authority.
The existing public welcome, route gate, owner fences and secure-save callback
remain the predecessor's work; this card does not claim their entire dirty diff.

Dedicated widget and native tests exercise Local, SSH, Remote and VPN controls,
keyboard Back without reads or saves, a sanitized 401, no automatic retry,
explicit keyboard resubmission with exactly one endpoint save, and canonical
`/hermes` navigation. Retry uses the existing Add Hermes button; no new automatic
retry or separately named Retry control was introduced.

The native launcher runs write and verify in distinct compiled GTK processes.
Real isolated Linux preferences retain selected contact/session; a credential-free
synthetic endpoint file restores the same endpoint identity into the test store.
The production directory, channel and router reconcile `synthetic-qa` and
`synthetic-history` without another save, management request or Agent mutation.
This proves process restoration logic, not physical secure-storage persistence.

## Reference and observed rendering

Read-only Desktop `withdrawn reference revision`,
`src/renderer/src/screens/Welcome/Welcome.tsx:405-437` and
`src/renderer/src/components/common/OnboardHero.tsx:129-158`, remains the source
for emblem, title, primary action and secondary SSH/Remote hierarchy.
The [predecessor](desktop-welcome.md) records branding, static hero and external
SSH tunnel deviations. Desktop itself was not run; no matching Desktop runtime
capture is claimed. Agent reference `158fd638da1629c8e62caf9ade1515d162def8ab`
was inspected read-only; neither reference checkout was modified.

Seventeen actual Xvfb/GTK captures cover normal and 200% text at logical widths
390 and 1280. Inspected welcome, SSH, denial, connected desktop and fresh-process
restoration captures show readable hierarchy and error text. Compact enlarged
welcome scrolls: secondary actions are below the initial viewport and are reached
by the tested keyboard path. Desktop Chat navigation matches the visible session.
Compact restored Chat shows readable canonical history; existing disabled transport
chips and composer hint truncate. This card does not claim whole-chat visual parity,
screen-reader qualification or pointer-free operation of every chat control.

## Exact-source evidence

Evidence directory: `.task-evidence/t_636ced72/` (ignored, retained locally).
Final native run: `attempt-zu710z7d/verification.json` with source and dependency
manifests, `executed-source.tar.gz`, logs, five journey receipts and seventeen PNGs.
The earlier passing run `attempt-lzplnjqb` has identical inspected capture hashes.

Candidate: base `b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319` plus all 808 recorded
Wing input files and attributed dirty prerequisites. Canonical sorted input-hash
fingerprint: `f351652b98745baeac7362a271440f6cd90f521f8eac68bcc05836de7c5430a7`.
The snapshot excludes Agent/Desktop/Conduit, credentials, personal runtime state
and build outputs. Dependency source, lockfile, SDK and extracted development
package identities are recorded before checks. No system install or sudo was used.

Executed from the repository:

```bash
PREFIX="$PWD/.task-evidence/t_636ced72/deps/root/usr" \
PKG_CONFIG_PATH="$PWD/.task-evidence/t_636ced72/deps/root/usr/lib/x86_64-linux-gnu/pkgconfig" \
CMAKE_PREFIX_PATH="$PWD/.task-evidence/t_636ced72/deps/root/usr" \
LIBRARY_PATH="$PWD/.task-evidence/t_636ced72/deps/root/usr/lib/x86_64-linux-gnu" \
timeout 15m bash scripts/run_linux_desktop_welcome_recovery.sh
```

Result: `NATIVE_WELCOME_RECOVERY_PASS`, exit 0, 248.401 seconds.
This launcher freezes a Wing-only candidate and executes:

- Python tooling tests: five pass; launcher shell syntax: pass.
- Changed-Dart format check: pass, no changes.
- `flutter analyze --no-pub`: pass, no issues.
- `flutter test --no-pub --concurrency=1` on direct-first-run, welcome recovery,
  primary entry, auth recovery, connection gate and router transitions: 34 pass.
- `flutter test --no-pub --concurrency=1 -d linux integration_test/linux_desktop_welcome_recovery_test.dart`:
  four write journeys pass, then one fresh-process restoration passes.
  Flutter ignores concurrency for integration tests; the launcher serializes both
  phases and caps native compilation at two workers.

Every write receipt reports one deliberate successful save and zero mutations,
management requests or forbidden reads. Verify reports zero saves and the exact
saved owner/session. Write PID 2486261 and verify PID 2494246 were independently
observed inside launcher-owned process groups. Isolated state and processes were
removed after teardown.

Because the focus policy changed browser behavior too, affected predecessor
coverage was rebuilt and rerun in the same source candidate plus hashed browser
inputs. `flutter build web --release --no-wasm-dry-run --no-pub -t lib/main_e2e.dart`
passed in 39.987 seconds. Four `desktop-welcome.spec.mjs` Chromium journeys passed
with one worker. Exact command, environment and duration are in
`browser-build-resume.json` and `browser-test-resume.json`; browser receipts and
screenshots are retained separately. JavaScript only was qualified. The first
browser build was terminated when the prior worker crashed; the resumed build
skips Wasm dry run. The existing Cupertino font warning remains.

## Failures, attribution and remaining gaps

The retained first native attempt fails keyboard Back at enlarged text. The second
passes write but fails restoration because the fixture asserted before asynchronous
restoration completed. The test now waits for the existing channel connection;
no production restoration contract was changed. Two later native runs pass.
Failed attempts and the interrupted browser log are retained, not relabeled pass.

The local agent branch contains the new tests/launcher/docs and an integration
patch for the baseline-relative `HermesAddScreen` fix and documentation/ledger
updates. Assemble the recorded pre-existing dirty prerequisites first, hash-check
`production-baseline.json`, then apply with `git apply --unidiff-zero`. The branch alone is not the
qualified standalone app. Shared HEAD and real index are preserved; no push or
merge was performed. Frozen source archives retain the actual executed candidate.

Android is `NOT_CHECKED`: `adb devices -l` returned no devices. `waydroid status`
reported a running headless session, not an authorized disposable UI target with a
qualified driver. No Android build/install or personal paired-app replacement was
performed. Required follow-up: authorized disposable target and exact APK execution.
Broader setup/auth matrix, managed SSH, live authentication, remaining platforms,
physical keychain and protected-main integration remain milestone gaps. Full-suite
and release qualification are outside this bounded check. Usage/cost is unknown.

Questions: none. Defaults applied: reuse production ownership and public controls;
keep optional management separate and managed SSH explicitly unavailable.
