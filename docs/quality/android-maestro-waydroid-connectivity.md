# Android Maestro: current Waydroid connection preflight

Task: `PARITY-MAESTRO-ANDROID-DEVICE`. Checked 2026-10-17T18:05:56Z.
Status: **Android journeys not-run; live qualification pending**. This is a
connection diagnostic receipt, not completion of the device task or a parity pass.
See the [machine-readable receipt](android-maestro-waydroid-connectivity-receipt.json),
[previous fixture receipt](android-approval-attachment-fixture.md), and
[execution runbook](../runbooks/desktop-feature-qualification.md).

## Executed boundary

The isolated worker started at clean source revision
`49487943e3bd426413eabb22277869662ebae5c3`. No Dart, fixture, flow, wrapper,
Android host, dependency or Agent source was changed. The only repository changes
are this receipt and documentation links. Temporary output uses `$TMPDIR`.
The initial default `adb devices -l` automatically started the host ADB daemon
on port 5037 before port isolation was configured, outside the assigned worker
port range. Subsequent probes used port 20100. No daemon was stopped or restarted
as a repair; the initial port use is recorded, not represented as compliant.

- `waydroid status`: session/container `RUNNING`, IP `UNKNOWN`.
- `ADB_SERVER_SOCKET=tcp:localhost:20100 waydroid adb connect`: exit 1,
  `Unknown container IP address. Is Waydroid running?`.
- `ADB_SERVER_SOCKET=tcp:localhost:20100 adb devices -l`: exit 0, no devices.
  Successful inventory enumeration is **not** successful ADB authentication.
- Read-only `waydroid prop get` calls: `sys.boot_completed=1`, `ro.adb.secure=1`;
  DHCP address/gateway and `service.adb.tcp.port` returned no value. These are not
  evidence of a currently authenticated ADB connection.
- Host bridge and one attached virtual interface are up. The DHCP lease file
  is readable but empty (0 bytes). Inspection of the installed Waydroid
  `tools/helpers/net.py` and `tools/actions/status.py` shows that both the normal
  connector and status discover the container IP from that lease file.
- `waydroid shell -- ip -brief address`: exit 1, `Action "shell" needs root access`.
  No escalation was attempted.

This localizes the normal connection failure to absent lease-based IP discovery;
it does **not** establish why Android lacks a lease or prove that the container
has no address by another mechanism. No address was guessed, subnet scanned,
alternate device adopted, key replaced, authentication disabled, property changed,
service restarted, network reconfigured, or personal application reset.

The normal connector is available; no missing user-space tool was identified.
Deeper shell/network inspection hits a privileged boundary excluded by this task.
The live follow-up needs the selected Waydroid target reachable through normal
ADB, or separately authorized privileged diagnostics/repair if needed. It does
not need a replacement phone, Agent credentials, or live inference.

## Artifact and journey status

No reachable serial was available to review. No wrapper/device test was dispatched
with an invented serial. Maestro 2.4.0 ran **syntax checks only** in this attempt;
there is no fresh `maestro test` launch or per-flow device exit to report. Earlier
failed driver launches remain attributed to the previous receipt.

The [Android host](../../android/app/build.gradle.kts) still applies `.qa` to debug
builds with `WING_ISOLATED_DEVICE_TEST=1`. The expected application ID is
`com.trebuchetdynamics.hermes.wing.qa`; this source check does not verify an installed
package. No APK was built, installed, launched, cleared or hashed. SDK/installed
artifact identity and build fingerprints remain unchecked. The read-only Android
OS fingerprint is in the JSON receipt, separate from the missing Wing APK digest.

| Required journey | Current outcome | Evidence still required |
| --- | --- | --- |
| Approval / Stop / reconnect | not-run | Actual Maestro launch; 3 sends, 2 decisions, 1 Stop; unchanged recovery counters; exact `sess_1` retention |
| Deferred attachment owner race | not-run | Pending pick, switch to `sess_2`, late completion rejected for both owners, zero sends, usable next pick |
| Earlier-history tail | not-run, separate from approval controls | Execute retained pagination tail and observe earlier history plus exhausted control |
| Fresh welcome | not-run | Fresh disposable storage on exact Android artifact, before connection |
| Keyboard Back / cancel | not-run | Android keyboard navigation with saved-owner preservation |
| Sanitized denial / explicit retry | not-run | Denial and deliberate retry on exact Android artifact; no focus-triggered replay |
| Saved-owner relaunch | not-run | Relaunch same artifact with exact endpoint/profile/session restoration and no duplicate mutation |
| Other mapped journeys | all not-run | Per-row candidate inventory and availability are recorded in the JSON; none is promoted to pass |

All counters and device exits are **null / unobserved**, not zero. No unavailable
state is treated as positive feature qualification. The JSON preserves all 46
matrix IDs, distinguishes missing mappings, retired/missing candidates and current
wrapper candidates, and fingerprints the current flow files. Candidate availability
is source evidence only, not product support or Android execution.

## Offline verification and source attribution

Executed on this documentation-only candidate:

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest test/tooling/android_maestro_features_wrapper_test.py -v`:
  exit 0, 6 tests. Tools are mocked; this verifies wrapper dispatch/fail-closed
  behavior only, not Android authentication, package identity or UI interaction.
- `maestro check-syntax` for `approvals_recovery.yaml` and
  `attachment_picker_race.yaml`: each exit 0. Owned cache under `$TMPDIR`.
- `bash -n scripts/run_android_maestro_features.sh scripts/run_android_maestro_profiles.sh`:
  exit 0.
- Documentation link/receipt consistency checks and `git diff --check`: exit 0.

The JSON records current source/build-input and flow fingerprints plus the exact
manifest algorithm. Its source revision remains the pre-documentation baseline:
none of those inputs changed in this worker. It also compares every input named
by the previous fixture receipt. Both repaired YAML files and the interaction
fixture still match. The wrapper, fixture entrypoint and two regression files
have changed since that receipt, so its widget/analyzer results are **historical**,
not current-source validation. No Flutter widget, analyzer or device pass is
borrowed from it. No Dart was changed here; Dart formatting, analysis and Flutter
regressions were not rerun for this documentation-only attempt.

## Resume and remaining acceptance

1. Restore normal reachability of the **selected** Waydroid target within applicable
   authorization. Require current successful `adb -s "$WING_QA_DEVICE" get-state`
   returning `device`; previous enrollment and readable Android properties do not
   replace it. Preserve host key trust and the paired production app.
2. Review the target and disposable `.qa` identity, then follow the runbook's
   existing wrappers. Capture source, APK, installed-package and flow fingerprints,
   actual Maestro launch and individual exits. Do not reuse these syntax results
   as runtime passes.
3. Qualify the approval/race journeys and earlier-history tail separately, then
   welcome/Back/cancel/denial/retry/saved-owner relaunch against the matching APK.
   Run remaining current candidates; classify retired or unavailable operations
   explicitly without closing their positive gaps.
4. Keep physical-device M2, TalkBack, native chooser/IME, real transport and live
   provider acceptance separate. Waydroid fixture execution would not close them.

Recheck this receipt when the selected target becomes reachable or the source,
wrapper, matrix, flows or APK changes. No production or release qualification,
protected-main integration, publication, or official Desktop fidelity is claimed.
