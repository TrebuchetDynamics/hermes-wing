# Production Local enrollment on native Linux

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Card: `t_4c7cb087`. Bounded qualification of `CONNECTION-LOCAL-ENROLLMENT-NATIVE`
within `CONNECTION-PATHS`; not completion of the parent setup/auth matrix.

## Delivered change and authority

Added a shared deterministic journey, widget regression, native Linux driver,
source-preserving launcher, and Python harness tests. The driver mounts the real
`WingApp`, production router, enrollment and Local setup screen. It does not use
`main_local_setup_recovery_e2e.dart` or a substitute landing page/router.
Only external typed host execution, endpoint storage, Agent HTTP callbacks,
contact preferences, management enrollment callbacks and speech are fixtures.
The production Local controller, host JSON decoder, navigation and gateway
composition remain intact. No Local production fix was necessary. The existing
Local provider's dirty cancellation guards are inherited prerequisites, not
this card's implementation or commit.

All setup results are synthetic. No installer, adoption, service restart,
management exchange, provider call, personal preference or runtime access is
performed. Agent GET callbacks use credential-free `example.invalid` fixtures;
Agent mutations and unexpected reads fail and are counted. Management callbacks
fail and are counted independently. Direct connection saves a synthetic Agent
endpoint without Wing Link fields, then publicly selects the discovered contact.
Saving an endpoint alone does not imply an active channel.

Reference inspected read-only: `withdrawn source citation` and
`withdrawn source citation`, particularly the
confirmation phase, mounted-result fences and separate existing-install action.
Wing intentionally retains its reviewed typed host contract and explicit pairing
return, not Desktop's privileged home adoption or restart implementation.

## Acceptance evidence

Every scenario runs through keyboard Tab/Space activation, public Back and the
production enrollment `hermes-enrollment-local-setup` control. The native target
executes at logical 390×1000 and 1280×1000, each with 100% and 200% text.

1. Missing-install and existing-adopt states open consent. Escape and Cancel
   each perform zero setups. Confirmation starts one typed operation. Success
   performs a fresh inspection and leaves Continue visible without navigation.
   Only explicit Continue returns to the separate pairing controls; management
   attempts remain zero. Public Back restores the actual welcome context.
2. Stop fences both delayed success and failure. Check again performs one read
   without replay. A sanitized setup failure exposes recovery without rendering
   raw output. Disposing a running Local route, then opening the public direct
   connection form, fences both late outcomes and never opens pairing. Direct
   Agent connection and contact selection succeed without management credentials.
3. The four native journeys each record exactly 12 inspections, 6 setup starts,
   4 cancellations, and zero management attempts, Agent mutations or forbidden
   reads. Fixed inspect argument shapes are asserted outside the async callback.
   Native PID ownership is observed from `/proc`, not inferred from compilation.
   The driver really builds and runs GTK; no Chromium substitute was used.

The failure UI retains its live-region Semantics and progress its labeled
LinearProgressIndicator. Keyboard operation is executed; assistive-technology
speech output is NOT_CHECKED. The native contact sheet and full-size compact
200% consent/failure and wide 200% completion captures were opened. Body text,
Cancel/Run setup, Check again and Continue remain readable without overflow.
The compact app-bar title is ellipsized; full task context remains in the body.

## Source-bound execution

Final receipt directory (ignored, local):
`.task-evidence/t_4c7cb087/attempt-k8l4p_go/`.
It contains `verification.json`, `source.json`, `dependencies.json`, six check
logs, four native counter receipts, 20 PNG captures and `contact-sheet.jpg`.
The immutable `executed-source.tar.gz` has SHA-256
`2c4dcc5ad0bfaac01b9eb9db1d8bb1b47eb1b5be968ccead9318dc4959d31d95`.
Its source manifest has SHA-256
`4fe0b1ca1a709948684d2a379e5ae730b3f8049a9ebd4f09d6e0aa5d5fe4d842`.
Base checkout: `b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`, plus individually
hashed/attributed dirty prerequisites. The executed candidate is NOT simply the
agent commit applied to clean main. Integration must preserve the manifest's
inherited prerequisites, notably production welcome, routing, direct-entry and
Local recovery work. This document is a post-run receipt, not a build input.

The launcher reuses the existing snapshot helper and the reviewed process/display
helper at `894439b76c889fed45f3c4d57b73086f1e18d479`; transitive source is in the
archive. Its runtime helper SHA-256 is
`295299f3d23505ff115ceb03fbfac3d552889c2c3dd3eb775c4de8108d39dec6`.
It copies the SDK and external local packages, rebinds native plugin paths, hashes
the dependency source, then verifies all source-input hashes after execution.
No pub resolution or upstream-clone inclusion occurs.

Heavyweight ownership uses the existing profile scratch
`desktop-daily-workflow-harness/flutter-owner.lock`, bounded wait 180 seconds,
before copying/building. Compilation parallelism is 2. The existing user-space
GTK/GStreamer/libsecret extraction under `.task-evidence/t_636ced72/deps/` is a
required local development prerequisite, not installed system-wide or committed.
Archive identities and pkg-config versions are recorded in `verification.json`.
The launcher is a source-run QA tool with inherited local helper/package
prerequisites, not a packaged end-user installer or portable release artifact.

HOME/XDG/TMPDIR are fresh owner-only directories. Personal DISPLAY, Xauthority,
DBus, proxies and credentials are not inherited. Xvfb has a private cookie and
no TCP listener; correct authority succeeds and wrong/missing authority fails.
Owned driver/app/display groups are terminated before isolated state deletion.
Large copied SDK/packages/build outputs were removed by owned-workspace teardown;
only the evidence listed above remains.

Environment: Linux 7.0.0-31-generic x86_64, Flutter 3.44.2 framework c9a6c48423,
Dart 3.12.2, GTK 3.24.41, GStreamer 1.24.2, libsecret 0.21.4.

## Exact checks

The frozen SDK paths and durations are retained verbatim in `verification.json`;
below `flutter`/`dart` denote those copied executables, not a different run.

| Command | Result | Seconds |
| --- | --- | ---: |
| `python3 -B -m unittest discover -s test/tooling -p local_setup_enrollment_native_test.py` | 2 pass | 0.082 |
| `bash -n scripts/run_linux_local_setup_enrollment.sh` | pass | 0.022 |
| `dart format --output=none --set-exit-if-changed integration_test/linux_local_setup_enrollment_test.dart test/features/enrollment/hermes_local_setup_enrollment_test.dart integration_test/support/local_setup_enrollment_native_fixture.dart` | unchanged, pass | 0.133 |
| `flutter analyze --no-pub` | no issues | 21.653 |
| `flutter test --no-pub --concurrency=1 test/features/enrollment/hermes_local_setup_enrollment_test.dart test/features/local_setup` | 26 pass | 40.248 |
| `flutter test --no-pub --concurrency=1 -d linux integration_test/linux_local_setup_enrollment_test.dart` | built GTK app; 4 pass | 163.669 |
| `timeout 15m bash scripts/run_linux_local_setup_enrollment.sh` | NATIVE_LOCAL_ENROLLMENT_PASS | 246.008 |
| `git diff --check` | pass | not measured |

Flutter reports that concurrency is ignored for integration tests; the native
journeys still execute serially in one owned GTK process. No full-suite,
Playwright, live-provider, Android or packaged release gate is claimed.

RED: the package-freezing regression first failed because `freeze_packages` was
absent, then passed after implementation; the receipt test initially exposed the
absent harness. New UI tests characterize existing production behavior; no
production bug fix is claimed. Iteration receipts remain: two pre-native runs
caught formatting/analyzer and direct-contact test-composition problems; three
native runs caught an expectation inside the injected async runner before the
final native pass. Moving argument validation to the synchronous journey kept
all argument assertions and allowed the synthetic runner to be exercised.
Parallel SSH localization generation was temporarily inconsistent in one root
widget run; foreign files were not repaired or committed. Six launcher attempts
are retained, including failures; monetary cost and review time are unknown.

## Delivery boundary and remaining work

Only the seven newly owned files are saved on `agent/wing/t_4c7cb087`. Native
review is the final worker-card step. No push, main commit, merge or protected-PR
delivery occurred. Goal-ledger changes remain attributed local ledger updates,
not a commit of foreign accumulated TODO/goals content.

Live install/adopt/auth, OAuth/public-auth contracts, SSH Linux/Android,
combined frozen-candidate gates and protected-main delivery remain unqualified.
Next milestone seam: unsupported OAuth/public-auth matrix, not another run of
this Local fixture subset. Parent `CONNECTION-SETUP-AUTH-MATRIX` and
`CONNECTION-PATHS` are not marked complete.

Questions (defaults applied): none; synthetic-only, separate optional pairing,
no host mutations and no publication defaults were retained.
