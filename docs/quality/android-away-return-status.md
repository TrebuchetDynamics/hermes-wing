# Android away/return status: source comparison and qualification handoff

Task: `M1-MOBILE-AWAY-STATUS`. Inspected 2026-10-17 UTC at Wing baseline
`8e6c2801d7c5aad79cdbd2020ce4a69770313190` in its isolated task worktree.

**Android matrix: NOT_CHECKED.** This is the task's offline receipt/source
comparison, not completed Android acceptance. No production defect was reproduced
and no runtime, test, dependency, upstream or packaging source was changed.
The [planned matrix](../test-plan.md#away-and-return-status-verification)
remains pending named-target execution. No notification infrastructure is added.

## Checklist and evidence boundary

- [x] Compare existing transcript/restart/approval receipts with current source.
- [x] Inspect production resume/recovery and nearest regression assertions.
- [x] Check selected Waydroid readiness without installing or replacing an app.
- [x] Record the missing matrix and source-bound handoff; check document integrity.
- [ ] Execute the matrix on the authenticated isolated Waydroid QA artifact.
- [ ] Repair any Wing defect actually reproduced there, with a focused regression.

The following discovery commands exited 0:

```sh
waydroid status
adb devices -l
```

Waydroid reported session/container `RUNNING`, vendor type `MAINLINE`, display
`waydroid-headless`, but IP `UNKNOWN`. ADB started its host daemon and listed no
devices. This does **not** establish current authentication, Android release,
API/ABI, package ownership, app launch or a passing journey. No alternate device,
authentication bypass, privileged network/service repair, install, app reset,
inference or production-app operation was attempted. Do not infer zero Agent
requests from this preflight: no instrumented Android scenario ran.

| Required artifact/observation | This attempt |
| --- | --- |
| Wing source | Baseline above; documentation-only candidate |
| Android target / release / API / ABI | Selected environment is Waydroid; authenticated serial and device readback NOT_CHECKED |
| Existing isolated QA APK / SHA-256 / source / entrypoint | NOT_CHECKED; no APK built, selected, installed or launched |
| Installed QA package and storage separation | NOT_CHECKED; required identity is `com.trebuchetdynamics.hermes.wing.qa` |
| Restored host/profile/session/run and canonical history | NOT_CHECKED on Android |
| Send / session-create / approval / Stop counts | NOT_CHECKED, not zero |
| Compact / enlarged-text controls and error messaging | NOT_CHECKED on Android |

## Existing receipts versus current bytes

Read the [transcript reconnect receipt](chat-transcript-reconnect.md),
[native transcript receipt](native-transcript-recovery.md),
[Android approval receipt](android-approval-attachment-fixture.md) and its
[recorded fingerprints](android-approval-attachment-fixture-receipt.json),
[Android discovery](2026-10-03-android-qualification-discovery.md), and
[M2 preflight](2026-10-06-m2-android-preflight.md).
Historical runs retain their stated outcomes and platform limits; none is promoted
to current Android qualification. In particular, native transcript recovery is GTK,
not Android, and provider-container recreation is not OS process death.

The table compares SHA-256 bytes with the explicit fingerprints in those receipts.
`same` means only that one file matches, not that its dependency closure or prior
execution is revalidated. These unchanged proofs were not rerun.

| File | Comparison | Current SHA-256 |
| --- | --- | --- |
| `lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart` | changed from reconnect receipt's `95d53e53…` | `ced75b416a43c70a265185932c2e1b6131274cf77b203ffa2f1c2aa4116d13c1` |
| `test/features/hermes_chat/screens/hermes_chat_transcript_reconnect_test.dart` | same | `7d918db55d9a5a2e8390aa44b7f835d7f2676da368a3a841128e1951f51db9d0` |
| `playwright/tests/regression/chat-transcript-reconnect.spec.mjs` | same | `1e0f852ce8ef97d97f76545fb8342dce04a7e22ce1d29440aa69fcd2f7c5412c` |
| `scripts/run_android_maestro_features.sh` | changed from Android receipt's `38966f19…` | `547b790f45e05413bf0b28ee46f9ea99f62dbcb060d2a0d49cf385c03dd2ee5b` |
| `scripts/maestro/fixture/approvals_recovery.yaml` | same | `452970b3d97dd98ba5eab9bdd9a149ad98b7f0b98f412afafdf76cd45528524f` |
| `integration_test/hermes_features_maestro_main.dart` | changed from Android receipt's `ccd6bc14…` | `cb0664219794d8cfe36116b3f948b960fb7f9fa1d9f06b2a8bd5e8b0e296f4f1` |
| `integration_test/support/maestro/interaction_fixture.dart` | same | `084f032d271e32aa7d27cd739eded7d5772e72e3eff5d3b51a406ccd36a25984` |

Thus even unchanged widget/YAML bytes do not justify transferring their historical
passes to today's connection or fixture implementation. No historical APK identity
or complete native source-archive closure was verified in this attempt.

## Current seams, not executed behavior claims

- [`didChangeAppLifecycleState`](../../lib/features/hermes_chat/screens/hermes_chat_screen.dart)
  (lines 768–786) invokes resume recovery; other transitions capture viewport and
  pause voice, not Stop. The [lifecycle extension](../../lib/features/hermes_chat/screens/state/hermes_chat_lifecycle.dart)
  (lines 4–56) reconciles the active session after recovery, checks composer owner
  generation, and restores the viewport only without unresolved run ownership.
  It also tracks unread completed sessions (lines 139–160).
- [`reconcileActiveSession`](../../lib/core/hermes/channel/hermes_api_channel.dart)
  (lines 445–455) skips streaming sessions and the separately gated serve-reader
  path. Resume is not a new transport or permission to resend.
- [`_recoverDetachedRun`](../../lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart)
  (lines 2161–2251) matches endpoint/profile/session and run response identity,
  fences connection/profile generations, and retains uncertainty on status/read
  failures. Terminal status alone cannot release ownership before canonical
  history succeeds. This is source inspection, not Android durability proof.
- [`HermesApprovalResponder.respond`](../../lib/core/hermes/channel/approvals/hermes_approval_responder.dart)
  (lines 71–134) checks the current approval-response transport policy and fences
  settlement after teardown. The Android matrix must still exercise exact grants
  and retired origins through production controls; labels are not authorization.

| Missing Android observation | Existing regression/fixture to reuse, with limits |
| --- | --- |
| Running → completed while absent; exact remembered owner, canonical IDs/order and no replay | [Absent-client oracle](../../test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart), cases beginning at line 323: real channel/Chat with deterministic transport and serialized fixture storage. It fixes its viewport at 1280×900; neither compact Android nor OS death is exercised. |
| Running → failed while absent; unknown during disconnect; deliberate Retry | [Resume cases](../../test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart), lines 1846–2125, include healthy/live-stream preservation and recovery failure/Retry. They use a fake channel; the enlarged-text Retry variants explicitly target Linux. These are not the absent-client failed-outcome matrix. |
| Granted current approval only; late old-owner results rejected | [Approval settlement cases](../../test/core/hermes/channel/hermes_approval_settlement_owner_test.dart) and [read-admission cases](../../test/core/hermes/channel/hermes_recovery_read_admission_test.dart), lines 455–610, distinguish missing grants, replacement identity and late reads. Host-side transport assertions do not establish touch usability. |
| Current compact/enlarged-text status and approval controls | [Native transcript target](../../integration_test/linux_transcript_recovery_test.dart) uses 390/1280 widths and 1×/2× text with a real channel transport seam, but is Linux-specific (environment gate, screenshot process and file receipts). Do not run it unchanged as an Android target. |
| Unread outcome access without incidental actions | [Gateway-switch tests](../../test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart), lines 1058–1246, cover background completion/failure/approval presentation. Background here means a different selected session, not Android suspension. |

The [Android feature adapter](../../integration_test/android_feature_regression_test.dart)
imports the [shared inventory](../../integration_test/linux_feature_regression_test.dart).
That inventory includes gateway-switch and auth-recovery tests, but does not import
the absent-client oracle or transcript-reconnect test. The existing
[approval YAML](../../scripts/maestro/fixture/approvals_recovery.yaml) deliberately
sends three turns, decides twice and Stops once before fixture reconnect. Its
fake-channel counters and reconnect are not an absent-client Agent outcome proof.
Running either broad entrypoint unchanged would not close this task's matrix.

## Resume this task's Android qualification

First recheck authenticated target readiness and the existing isolated artifact
under the [qualification procedure](../runbooks/desktop-feature-qualification.md#android-maestro-fixture-run).
Do not substitute a paired app, unrelated target or historical APK. Record source
closure, APK digest/entrypoint, installed package equality, Android API/ABI and
an ephemeral target alias before operating the app.

For each planned matrix row, keep the same exact owner tuple and separate fixture
control requests from Agent transport attempts. Establish running before actual
Android background, change the deterministic backend outcome while absent, and
return through production controls. Include completed, failed, disconnected/unknown
then explicit Retry, current/missing approval grants, and delayed reads after owner
replacement. At compact width and enlarged text, verify usable status, Retry and
approval controls, not just render success. Report per-phase send/create/approval/
Stop attempt deltas including rejected attempts: recovery permits zero; a deliberate
action permits only its intended request. Unobserved counts remain NOT_CHECKED.

Repair only defects reproduced by those observations. For changed code/fixture
inputs run the task checks, plus the smallest affected test:

```sh
flutter test --no-pub --concurrency=1 test/core/hermes/ test/features/hermes_chat/
flutter analyze --no-pub
git diff --check
```

Those Flutter commands were **not run** for this documentation-only change: no
code/test inputs changed and no current runtime pass is claimed. This attempt
checks local links, cited line ranges, recorded fingerprints and whitespace only.
Independent read-only review verified the seven fingerprint comparisons and local
links; its sole finding was a corrected oracle line citation. That review assesses
this document, not Android acceptance.
The complete Waydroid matrix remains pending live target access, not an offline
implementation blocker. Physical M2 process death, actual providers, screen-reader
operation and notification delivery remain separate and unqualified. Revisit this
handoff when the named source bytes, artifact or target readiness changes.
