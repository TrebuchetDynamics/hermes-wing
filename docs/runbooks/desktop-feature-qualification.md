# Desktop feature qualification on Linux and Android

Status: execution procedure, not a passing platform receipt.
The [feature matrix](../product/hermes-desktop-feature-matrix.md) links Desktop
outcomes to existing Android Maestro and native Linux Flutter candidates.

## Safety and prerequisites

Before claiming port fidelity, pin the Desktop revision and name the reference
screen/component for the tested slice. Capture matching reference and Wing states
at the named viewport. Review screen structure, terminology, layout, visual hierarchy,
interaction and recovery, not only request counts. Record adaptations and unsupported
operations as differences. Tests establish only their source, target and assertions.

For welcome qualification, use fresh disposable app storage, not the owner's paired
app. Observe launch before any connection, then supported connect/failure/retry and
saved-owner relaunch. Check that selected navigation matches visible content.
Android handoff acceptance requires execution of the exact APK on the authorized
target. Earlier source-run receipts do not qualify a different artifact.

Use isolated current Wing source and a disposable QA app/target. Exclude both
upstream reference clones from builds and keep them read-only. Do not install
packages, reset a personal app, change the owner's desktop or alter Agent profiles
as an implicit test prerequisite. Live provider/cost/mutation scope needs explicit
approved-target authority separately from a fixture run.

The Android wrappers build with `WING_ISOLATED_DEVICE_TEST=1`. The
[Android host](../../android/app/build.gradle.kts) adds `.qa` to the application ID.
Flows may run `clearState: true`: confirm the installed package is the disposable
QA package before execution. A caller-selected serial alone does not prove the
package or device is safe. Preserve the paired production application.

Native Linux requires Flutter Linux tooling, libsecret/GStreamer development
metadata and `xvfb-run`. Read existing source before invoking launchers. The
[earlier preflight](../../.task-evidence/parity-flow-matrix/preflights.json) stopped
at missing development metadata. The later
[native relaunch receipt](../quality/native-relaunch-workflow.md#safe-user-space-prerequisites-and-reproduction)
records compatible development packages extracted into an owned prefix, without
sudo or system package changes. Recheck compatibility and prepare a fresh prefix
before native execution; the removed local prefix is not a permanent prerequisite
installation. This qualifies only the two-process workflow, not all feature flows.

## Terminal working-directory files: qualification prerequisites

Status: planned; no file-feature launcher or live/native receipt exists in this pass.
See the [source study](../analysis/terminal-files-feasibility.md),
[planned design](../spec.md#terminal-working-directory-files-planned-design) and
[test scenarios](../test-plan.md#terminal-working-directory-files-planned).

Use a disposable target with a compatible authenticated `hermes serve` connection.
Record the exact runtime revision, owning profile/session and terminal backend.
Chat on the messaging API does not qualify filesystem endpoint availability.
Verify the authoritative root and server-enforced canonical boundary before reads.
If either is unavailable, record the operation as unsupported rather than retarget it.
No procedure here authorizes starting a personal service, changing root configuration,
copying credentials, editing Agent or installing Wing Link.

After implementation, exercise browse, text preview and deliberate file save in
Wing on Linux and Android separately. Read back saved bytes and compare with the
selected source. Test denial, owner switches, cancellation and interrupted transfers.
Record native save-picker behavior separately from HTTP and fixture checks.
Until matching receipts exist, report those outcomes as NOT_CHECKED.

## Android Maestro fixture run

Waydroid is the selected Android QA environment. The
[Waydroid project](https://github.com/waydroid/waydroid) runs Android in a Linux
container; it is not a physical phone. The owner selected it in
[BLK-20261006-W02](../../BLOCKERS.md#blk-20261006-w02--physical-device-run-for-m2-android-recovery).
Use the separate `.qa` application and preserve the paired application.

Inspect `waydroid status` and `adb devices -l`, then select the authorized QA
serial. A running session/container does not imply an ADB connection or app
qualification. Wing owns reversible user-space connectivity/tooling preparation
for this selected environment; an empty ADB list is not another owner decision.
Do not disable authentication, silently trust another key, use sudo, restart a
shared service or replace production app data. Ask only for an actual permission
or privileged action that the safe user-space path requires.

Do not bypass the device authorization prompt. Existing question
[BLK-20261006-005](../../BLOCKERS.md#blk-20261006-005--waydroid-device-authorization-and-host-connection)
records completed enrollment and separate unresolved live SSH/API access. The
[latest fixture receipt](../quality/android-approval-attachment-fixture.md) instead
records an unreachable enrolled target and failed startup before any Android flow.
Recheck successful `get-state` with `device`; prior enrollment is not current
connectivity. The fixture needs no live Agent/provider credentials.

After authorization and package review, run from the isolated repository root:

```bash
WING_QA_DEVICE='DISPOSABLE_SERIAL' MAESTRO_BIN="$HOME/.maestro/bin/maestro" npm run android:maestro-features
WING_QA_DEVICE='DISPOSABLE_SERIAL' MAESTRO_BIN="$HOME/.maestro/bin/maestro" npm run android:maestro-profiles
```

Replace the serial with the selected QA target. Replace the binary path if the
installed Maestro differs. The wrappers check syntax, build their fixture
entrypoints, install the QA APK and run the flows. Record each wrapper's exact
command and exit separately. Both wrappers accept `WING_QA_OUTPUT_DIR` for owned
output and isolate Maestro's cache per run.

The feature wrapper also accepts explicit allowlisted flow paths. No arguments
still selects its full suite. After the same target/package review, run this subset:

```bash
WING_QA_DEVICE='DISPOSABLE_SERIAL' MAESTRO_BIN="$HOME/.maestro/bin/maestro" \
  bash scripts/run_android_maestro_features.sh \
  scripts/maestro/fixture/approvals_recovery.yaml \
  scripts/maestro/fixture/attachment_picker_race.yaml
```

Unknown paths fail before tool dispatch. Failed ADB `get-state` or a state other
than `device` stops this wrapper before syntax checks, build, install or flows.
That check does not establish disposable identity or reviewed package safety.

These commands exercise deterministic screens and services, not live inference.
Inspect [feature flows](../../scripts/run_android_maestro_features.sh) and
[profile flows](../../scripts/run_android_maestro_profiles.sh) before changing
coverage. Live/regression scripts under `.maestro/` and `scripts/maestro/` must
not be executed merely because their syntax passes.

## Native Linux counterpart run

Maestro does not provide a supported native Linux desktop driver. Use the existing
native Flutter counterpart rather than claiming Android YAML ran against GTK.
With the development dependencies available, an owned Xvfb display supports:

```bash
xvfb-run -a flutter test -d linux integration_test/linux_maestro_flows_test.dart --reporter expanded
env -u DISPLAY bash scripts/run_linux_e2e.sh
```

The first command runs mapped counterpart scenarios. The broader launcher repeats
that target and also runs native fixture/HTTP/transport, large-reader, persistence
and input suites. Do not run both commands concurrently against one build tree.
Inspect each subordinate launcher for owned display/preferences/clipboard use
before extending the qualification scope. A native fixture is still not a live
Agent, real microphone or actual provider execution receipt.

Maestro web can be considered separately for a Chromium-hosted Flutter web app.
It is beta, can download a managed browser, and does not qualify native menus,
plugins, installation or GTK windows. No web Maestro runtime is qualified here.

## Credential-free Linux shell restart

This narrower source-run check uses production shell/channel components with
synthetic in-process reads. It does not contact an Agent or provider. Before
execution, prepare compatible Linux development dependencies, Flutter caches,
Xvfb and Xauthority tools. The launcher also requires reviewed local Git object
`894439b76c889fed45f3c4d57b73086f1e18d479` for its attributed helper overlays.
Do not substitute older dirty shared helpers or copy personal credentials.

```bash
bash scripts/run_linux_desktop_no_inference_smoke.sh
```

Run from the repository root. The launcher accepts no credentials, endpoints or
live mode. It captures complete source before checks, then launches six sequential
GTK processes on one owned authenticated display with isolated preferences.
Write and baseline verify precede synthetic history-denial 401/403 restart phases
and required-capabilities bootstrap-denial 401/403 phases. Denied bootstrap allows
only health/capabilities reads, with no usable inventory/history. Focus alone must
not retry. Explicit keyboard Retry retains the saved owner during continued denial
and restores canonical history after read authority recovers. Cancelled and
wrong-owner history must not settle.
Expected signal: `NATIVE_NO_INFERENCE_PASS`, matching synthetic owner/history,
keyboard recovery and zero mutation counts. Confirm owned-process teardown before
state deletion. Retain sanitized source manifests, archive and phase logs.
A failed or incomplete receipt does not qualify restoration.

The [corrected receipt](../quality/native-no-inference-smoke.md#executed-corrected-qualification)
records this frozen-source Linux check. The earlier archive is superseded and must
not be reused. The [denied-read successor](../quality/native-no-inference-auth-recovery.md)
records the earlier four-phase source-run qualification. The
[bootstrap-denied successor](../quality/native-no-inference-bootstrap-recovery.md)
records the current six-phase qualification. The current source-run launcher
requires local predecessor Git object `358f645c52c9cb53f8368ecb3346d577c05e9f68`.
This run does not qualify packaged execution, all mapped features,
physical keyboard/IME, actual approvals/Stop or live generation.

## Per-feature receipts and failure handling

For each matrix ID, record actual scenario and driver, not merely a containing
file name. Collect pass, fail, unsupported, not-run and coverage-gap outcomes
separately. An unsupported-state pass must leave the positive feature gap open.
Store only sanitized logs and screenshots with source/build/flow fingerprints.
Screenshots must not contain endpoints, paths, credentials or private transcripts.

Use public controls and observable assertions. Fixture counters should prove
exact send/approval/delete effects and zero incidental recovery mutations. Live
qualification requires canonical Agent readback, not fixture counters.

On failure, retain the first failed step, inspect the production caller and nearest
tests, add a discriminating regression and apply the smallest in-scope repair.
Do not weaken selectors or assertions, enable an unsupported operation, or rerun
unchanged failures until they accidentally pass. Update the affected matrix row
only with executed matching-target evidence. Record UI/behavior deviations and
unverified native/live behavior even when the underlying command exits zero.
