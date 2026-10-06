# M2 QA delivery and private receipt-retrieval admission

Card: `t_ccec142b`. Task: `DOC-M2-QA-DELIVERY-ADMISSION`.
Result: source-bound admission brief only. **M2 remains unverified.**

## Interpreted acceptance

1. Bind the exact observer entrypoint, imports and conditional debug package to
   inspected inputs, without claiming a merged APK, installed identity or plugin run.
2. Separate in-process sink equality from cross-process attempt/generation continuity
   and permitted retrieval; identify the missing seam and keep qualification refused.
3. Execute offline source-integrity, document-link and isolated refusal controls;
   retain exact commands, exits and fingerprints. No platform/runtime execution.

## Delivery chain: inspected configuration, not packaged execution

| Boundary | Source evidence | Admission consequence |
| --- | --- | --- |
| Explicit Dart target | `integration_test/hermes_m2_observer_main.dart:1-19` imports WingApp, HermesApiChannel, SecureHermesDetachedRunStore and `support/m2_observer.dart`; initializes the Flutter binding | Required future target is exactly `integration_test/hermes_m2_observer_main.dart`, not `lib/main.dart`, `lib/main_e2e.dart` or either Maestro target. A filename/import is not proof of the packaged entrypoint. |
| Production composition | `integration_test/hermes_m2_observer_main.dart:30-54` overrides only hermesChannelProvider; delegates the real store and uses default channel transport with WingApp | No fake channel/endpoint/directory is installed here. Preserve the predecessor's full local-import closure receipt; do not infer native dependency delivery from Dart tests. |
| Package selection | `android/app/build.gradle.kts:23-45` sets namespace/base application ID `com.trebuchetdynamics.hermes.wing`; `android/app/build.gradle.kts:80-94` gives debug `.qa` only when `WING_ISOLATED_DEVICE_TEST=1` | Required candidate configuration is debug plus that exact environment value, yielding `com.trebuchetdynamics.hermes.wing.qa`. Release has no QA suffix, even with the flag; debug without the flag is production ID. Neither is admitted. Namespace remains base namespace; it is not installed package identity. |
| Flutter Gradle/plugin input | `android/settings.gradle.kts:1-26` loads Flutter tooling/plugin loader; `android/app/build.gradle.kts:3-8` applies the Flutter plugin; `android/app/build.gradle.kts:98-100` points to repo source | Target selection comes from the build invocation, not a dedicated flavor or Gradle observer binding. No observer-specific package/target enforcement exists in these inspected inputs. |
| Native entry/registration | `android/app/src/main/AndroidManifest.xml:8-53` launches MainActivity and declares embedding v2; `android/app/src/main/kotlin/com/trebuchetdynamics/hermes/wing/MainActivity.kt:29-83` calls super.configureFlutterEngine and registers existing pairing/speech/durable-key channels | No metadata retrieval channel is present in this configuration block. Source manifest still inherits ordinary launcher/pairing/share filters. A QA suffix does not prove merged component/export isolation. |
| Secure plugin | `integration_test/support/m2_observer.dart:1-7` imports flutter_secure_storage and uuid; `pubspec.yaml:9-27` declares secure storage; `pubspec.lock:323-330` locks flutter_secure_storage 11.0.0 | Dependency declaration/lock is not proof of generated registration, packaged Android classes, platform invocation, Keystore durability or protection. Do not assume a separately named Android package: the lock has no flutter_secure_storage_android entry. |
| Dev-plugin handling | `android/app/build.gradle.kts:102-136` strips only integration_test's generated registration for release | Does not validate secure-storage registration, observer entrypoint or debug plugin delivery. Do not execute the mutating task as a source check. |
| Existing runners | `scripts/run_android_maestro_features.sh:7-15`, `scripts/run_android_maestro_features.sh:42-46`; `scripts/run_android_maestro_profiles.sh:7-15`, `scripts/run_android_maestro_profiles.sh:31-35` | Explicit serial and isolated Maestro cache exist, but build different fixture targets and install shared app-debug.apk without merged-package/entrypoint/installed identity readback. They are not M2 delivery/retrieval runners. Do not run or silently retarget them. |

Before any separately authorized install: exclusive disposable target/build ownership,
source-to-APK fingerprint, selected target/configuration receipt, merged package and
component identity, ABI/API and debug mode, generated plugin registration and packaged
native dependency closure must agree. Then a bounded real secure-plugin write/read
control on that same QA installation must succeed. Failure or absent evidence refuses
admission. Native/APK/device/plugin checks are all NOT_CHECKED here.

The approved predecessor [review round 2](../../.task-evidence/t_53f0d91e/reviewer-round-2.md)
records 24 deterministic tests, scoped analyzer/formatter and full local closure checks
at `c141d8d727ed8a44168fc80674f05dce2cbf63aa` on `agent/wing/t_53f0d91e`.
This card compares all three authored source blobs to that exact commit; it does not
rerun its Flutter suites or 186-file closure. Its source evidence is inherited only,
not proof of packaging. Selected current input SHA-256 values are in
[source-snapshot.json](../../.task-evidence/t_ccec142b/source-snapshot.json).

## Continuity and sink boundary

`integration_test/hermes_m2_observer_main.dart:10-19` generates both attempt and
process-generation aliases afresh at every startup. `integration_test/support/m2_observer.dart:36-43`
requires UUID-v4 aliases. `integration_test/support/m2_observer.dart:53-72` writes only
`wing.qa.m2.metadata.v1.$attempt` using FlutterSecureStorage, validates before write,
and reads only the same instance key. No caller-selected storage key/path, readAll,
export or deletion operation is offered by M2SecureSink.

`integration_test/support/m2_observer.dart:101-129` validates an envelope against one
attempt AND one generation. `integration_test/support/m2_observer.dart:463-479`
flushes and compares complete in-process readback, rejecting concurrent changes,
missing/corrupt bytes and errors. This is not a post-death collector. A new startup
selects a new attempt/key and cannot discover the old one through the entrypoint.
Reusing the old attempt with a fresh generation would still reject the old envelope
if validated against the new generation. Do not merge generations into a single
existing validator or label fresh aliases as continuity. There is no admitted private
coordinator carrying the same attempt with distinct per-process records, mapping
old/new generations, witnessing PID absence or retrieving old-generation receipts.
Private storage surviving is not proof that these links exist.

The sink namespace alone does not enforce runtime package identity: it accepts aliases,
not an Android package readback. `integration_test/support/m2_observer.dart:254-260`
rejects a foreign application_id IF a record supplies that field; it is not mandatory
or a platform package measurement. Similarly old_pid_absent/new_generation are allowed
booleans, not independent OS witnesses. No secure data or device was inspected.

## Bounds and fail-closed ceiling

The [preflight allowlist](2026-10-06-m2-android-preflight.md#allowlisted-output-and-fail-closed-rules)
is narrowed by current implementation, not expanded into arbitrary extraction:

- `integration_test/support/m2_observer.dart:89-129`: at most 128 events and 65536
  UTF-8 bytes including envelope; exact schema/attempt/generation binding.
- `integration_test/support/m2_observer.dart:131-267`: allowlisted alias/int/digest/
  enum/boolean fields, fixed QA application ID and bounded ABI choices; authoritative
  counts, ledger epoch and complete_coverage=true are refused, not silently zeroed.
- `integration_test/support/m2_observer.dart:238-244`: contiguous sequence and
  non-regressing elapsed time; `integration_test/support/m2_observer.dart:330-379`
  refuses failed/unavailable history/canonical admission before state advancement.
- `integration_test/support/m2_observer.dart:395-478`: irreversible invalidation,
  one in-flight and one pending bounded snapshot (at most 128 KiB encoded envelopes),
  complete readback rather than dropped/sampled events; qualifies is always false.
- `integration_test/support/m2_observer.dart:497-507` emits
  `authoritative_counts_unavailable` and `history_admission_unavailable`.
  `integration_test/support/m2_observer.dart:640-650` repeats history unavailability
  after observed removal. Neither visible state nor a removal ack is canonical admission.

Receipt collection must fail closed for missing admission, package/target drift,
unknown attempt/generation, stale/mixed/duplicate/missing/oversized records, retrieval
failure, secret/extra fields or loss of coverage. No raw serial/PID, credential,
origin, profile/session/run ID, alias mapping, host path, storage ciphertext/database,
prompt/transcript, provider value, arbitrary error text or private-value digest enters
public output. Aliases and matches only; authority remains with Hermes Agent, not
Wing Link or client counters. The existing sink read is not authority to dump storage,
use adb/run-as, logcat, clipboard, shares, generic paths or a new remote endpoint.

## Exactly one proposed next slice: QA-only continuity/retrieval adapter

NOT_IMPLEMENTED and NOT_AUTHORIZED by this card. Proposal for separate review:
write allowlist only `integration_test/support/m2_observer.dart`,
`integration_test/hermes_m2_observer_main.dart`,
`integration_test/support/m2_receipt_admission.dart` (new),
`test/tooling/m2_receipt_admission_test.dart` (new), and that card's evidence directory.
No production, Android manifests/Gradle, native channel, runner or upstream edits.
If a permitted private transport needs those, stop that operation and record a new
scope requirement rather than widening this allowlist.

Implement a typed in-process QA admission boundary accepting only a reviewed
attempt UUID and current generation UUID, with separately bound prior-generation
UUID where appropriate. It must require independently supplied QA package/entrypoint
admission (not turn caller assertions into measurements), and retrieve only that
attempt's fixed metadata key through M2Sink. Validate prior bytes against THEIR
recorded generation, current bytes against the current generation; never mutate or
relax M2Validator's one-generation rule. Enforce one bounded request/envelope, no
enumeration or arbitrary keys, and metadata-only sanitized return. Keep product owner
mappings private/ephemeral, no product tuple hashing or shadow state. Existence of
this adapter would still not authorize a transport/coordinator or prove PID continuity.
Private provisioning/collection transport must be explicitly admitted separately.

Discriminating future deterministic check: an explicit same-attempt/new-generation
handoff reads a valid prior-generation envelope and validates it independently;
wrong package/target, absent retrieval permission, swapped generation, foreign attempt,
missing/truncated data, over-limit/secret fields and changed handoff must reject
without storage enumeration, writes, launch, fallback or qualification. A fake sink
is static tooling only. Future actual death/relaunch requires independently witnessed
old PID absence and QA identity plus same-storage readback; that is outside this slice.
History/counting remain unavailable and qualifies remains false after successful retrieval.
This is a prerequisite, not another broad runner roadmap or platform qualification.

## Executed offline checks and acceptance evidence

From repository root:

```text
python3 .task-evidence/t_ccec142b/check_admission.py snapshot
python3 .task-evidence/t_ccec142b/check_admission.py verify
git diff --check -- docs/quality/2026-10-06-m2-qa-delivery-admission.md .task-evidence/t_ccec142b
```

The checker checks selected hashes, exact import/composition/package contracts,
source-line citations, local links including anchors, predecessor branch/blob binding,
fixed sink limits/refusal symbols and isolated negative controls for wrong package,
wrong target, omitted isolation and absent continuity/retrieval admission. These are
source/text integrity checks and a synthetic admission-policy model, not Dart runtime
validation or an implemented retrieval service. Logs/exits and checks are in
[validation.json](../../.task-evidence/t_ccec142b/validation.json).
The no-index whitespace check includes untracked authored files; exit 1 with empty
output means an added-file difference, not a whitespace failure.

Observed: snapshot and verify exited 0; 13 selected source hashes, 30 source-line
citations and four local links passed. Eleven isolated negative controls refused
for their expected reasons; the positive synthetic policy model passed. All three
predecessor source blobs matched the approved branch revision. These checks do not
execute M2Validator or a secure-storage plugin. Exact captured stdout/stderr and
the scoped diff result are retained in commands.json and offline-check.log.

Acceptance 1: delivery table, source snapshot and contract checks.
Acceptance 2: continuity/sink bounds, explicit absences, refusal controls and one
bounded next-slice proposal. Acceptance 3: checker receipts and scoped diff check.
Source fingerprints rather than dirty checkout HEAD alone bind these claims.

NOT_CHECKED individually: APK build/digest/entrypoint, merged manifest/package/plugin
closure, install/storage isolation, secure-plugin execution, Keystore protection/
durability, actual receipt retrieval, named device/API/ABI, old PID absence/new process,
notifications, live Agent/run/history, auth expiry/revocation, credentials/inference,
credential-wide authoritative counts and zero live mutations. No M2 promotion.
Only offline Python/Git checks were exercised on this Linux host.

Shared goals/TODO reservation remains with repo-docs job `ba15b4ed8db6`; no release
was observed. Exact task/evidence/render helper handoff is retained in this card's
completion receipt rather than racing that reservation. This source-only pass must
not promote M2. Questions: none; no-live/no-secret/no-sudo defaults retained.
