# M2 independent admission and fixed-slot custody trace

Status: source-backed preparation only; no coordinator or adapter implemented.
M2 unverified. Results remain diagnostic-only, `history_admission_unavailable`
and `authoritative_counts_unavailable`; APK/device/storage/OS/live/counts NOT_CHECKED.

## Authority map

The approved [handoff contract](2026-10-06-m2-receipt-handoff-contract.md#independent-admission-distinct-from-caller-assertions)
is inherited unchanged at commit `a0a0cfc3425400a409e582715797b73119532696`
on `agent/wing/t_d6c8aa4f`, native review run 491 approved. Its synthetic controls
are inherited evidence of a proposal, not an implemented admission service.

| Immutable input or right | Independent authority required (future, not present) | Existing declaration, actual caller and nearest test | Finding |
| --- | --- | --- | --- |
| Attempt and current generation | Private QA custodian registering an attempt once and assigning a distinct process generation; authority origin must be separate from observer request | `integration_test/hermes_m2_observer_main.dart:10-19`; `integration_test/support/m2_observer.dart:36-43`; `test/tooling/m2_observer_test.dart:79-84` | Main generates both aliases afresh; test supplies constants. UUID validation is syntax, not admission. No continuation registration. |
| Prior generation and unchanged tuple | Same custodian retaining immutable prior/current/candidate/target/storage association, not decoding generation from untrusted bytes | `integration_test/support/m2_observer.dart:101-129`; `test/tooling/m2_observer_test.dart:603-640` | Decoder checks one caller-supplied generation. No prior input at startup; test refuses mismatched generation. Never rewrite old bytes to current generation. |
| Candidate, compiled target, debug package | Separately reviewed local artifact examiner binding source digest, actual compiled entrypoint, merged package/components and plugin closure | `android/app/build.gradle.kts:80-100`; `integration_test/hermes_m2_observer_main.dart:30-54`; `test/tooling/m2_observer_test.dart:555-600` | QA suffix is conditional debug configuration. Widget test proves production channel composition with mocked storage, not compiled APK identity. |
| Disposable target and storage instance | Independent target custodian measuring exact installed QA identity and same private storage instance; retain raw mappings privately | `scripts/run_android_maestro_features.sh:7-15`; `scripts/run_android_maestro_features.sh:42-46`; `integration_test/support/m2_observer.dart:53-72` | Explicit serial and QA build flag select configuration. Runner builds another target, installs a shared filename; neither sink nor runner binds installed target/storage evidence. |
| Fixed metadata read permission | Explicit private read grant bound to immutable tuple, distinct from package or writer admission | `integration_test/support/m2_observer.dart:46-72`; `integration_test/support/m2_observer.dart:463-479`; `test/tooling/m2_observer_test.dart:660-668` | Interface read has no grant; secure sink returns unchecked bytes. Actual read caller is journal flush after writes, not an admitted prior collector. Read failure invalidates diagnostics, not product load. |
| Exclusive attempt/storage writer custody | Authority that controls every QA writer and fences stale/competing generations before read and through retention/release | `integration_test/support/m2_observer.dart:385-405`; `integration_test/support/m2_observer.dart:423-479`; `test/tooling/m2_observer_test.dart:128-138` | `_worker` serializes only one journal. Test maximumActive=1 covers that fake sink's one journal, not two journals/processes or a platform lock. No shared-slot ownership check. |
| Full prior-byte retention before release | Same custodian owns bounded immutable snapshot until unchanged admission is revoked; release requires separate write permission | `integration_test/support/m2_observer.dart:444-479`; `test/tooling/m2_observer_test.dart:643-658` | Current snapshot/readback equality and nested counter freezing exist; no retained prior-generation snapshot or release acknowledgement. In-memory retention would not prove crash durability. |

No existing seam independently binds the complete tuple or supplies these rights.
A field named application_id is optional and checked only if present at
`integration_test/support/m2_observer.dart:254-267`. Allowed old_pid_absent and
new_generation booleans at `integration_test/support/m2_observer.dart:147-159`
are caller metadata, not OS witnesses. They must not become admission switches.
The observer's product coordinationKey delegation at
`integration_test/support/m2_observer.dart:483-507` does not fence the QA sink.
The separate product slot at
`lib/core/hermes/setup/secure_hermes_detached_run_store.dart:10-25` is not an
allowed collection source or a replacement QA authority.

## Actual first write and required ordering

Construction of M2Journal alone does not write. Main constructs journal and sink,
then runApp builds the provider override, creates the production channel and calls
observer.start (`integration_test/hermes_m2_observer_main.dart:10-19` and
`integration_test/hermes_m2_observer_main.dart:30-54`). Start records availability
at `integration_test/support/m2_observer.dart:497-507`; record validates/appends
and invokes `_commit()` at `integration_test/support/m2_observer.dart:423-455`.
That async function reaches sink.write before its first await completes; secure
sink validates then calls storage.write at `integration_test/support/m2_observer.dart:65-72`.
No startup read precedes this. Flush awaits writes then reads. Thus injecting an old
attempt into today's entrypoint would risk overwriting its sole prior envelope,
even though ordinary startup uses a new attempt. This card does not perform that injection.

Required future order is registration → independent package/target/storage admission
→ separate read authorization → exclusive writer custody → one fixed read → complete
bounded validation against prior generation → immutable private retention acknowledged
→ separate current writer release. Current bytes, if supplied, validate separately
against current generation. Fresh attempts require null prior bytes. Continuations
require non-null valid prior bytes. Inspection never writes. Revocation, tuple drift,
failed retention, unexpected bytes, or competing writer refuses without fallback.
Repeated unchanged inspection returns the retained diagnostic, never rereads an
already overwritten slot. Limits remain 128 events and 65536 UTF-8 bytes per envelope
(`integration_test/support/m2_observer.dart:89-129`), with independently bounded
retained and current envelopes; no extra storage slot or persistent alias map.

## Transitive delivery boundary inspected, not executed

Entrypoint imports WingApp, production HermesApiChannel, secure detached-run store,
channel provider and local observer; observer imports secure storage, uuid, channel
state and detached-run interfaces. The approved observer review records a broader
local Dart closure; that graph is not recomputed or inherited as a current full-closure
proof here. Only selected unchanged source/receipt inputs are carried forward; no APK
closure is inferred.
`pubspec.yaml:9-34` declares runtime secure storage/uuid and dev integration_test;
`pubspec.lock:323-354` locks secure storage 11.0.0 and platform interface dependencies.
No separately named Android package is inferred from that lock.

`android/settings.gradle.kts:1-26` loads Flutter's plugin build and includes app
plus headless fixture. `android/app/build.gradle.kts:102-136` mutates generated
release registration only for integration_test; it is not an admission hook.
`android/app/src/main/AndroidManifest.xml:14-57` retains exported launcher,
pairing/share filters and Flutter embedding metadata. MainActivity calls superclass
engine configuration and registers product channels at
`android/app/src/main/kotlin/com/trebuchetdynamics/hermes/wing/MainActivity.kt:40-83`;
none is an admitted QA custody transport. These declarations do not prove merged
manifest, generated plugin registration, packaged native classes, isolation,
Keystore durability or platform invocation. No packaging task was run.

## Exactly one proposed next proof slice

Propose a separately reviewed **closed QA fixed-slot custody boundary, deterministic
Dart proof only**. NOT_AUTHORIZED here. Files bounded to
`integration_test/support/m2_receipt_admission.dart` (new),
`integration_test/support/m2_observer.dart`,
`integration_test/hermes_m2_observer_main.dart`,
`test/tooling/m2_receipt_admission_test.dart` (new), and successor evidence directory.
No production, runner, manifest, Gradle, native transport, plugin or upstream changes.

The discriminating implementation is a typed, non-publicly-mintable admission/custody
handle issued only by an injected independent QA authority, not a request boolean.
It binds the full immutable tuple, separate read permission and writer ownership.
A test-only authority can issue handles; no real issuer or transport is installed.
Route the QA startup through that boundary, with missing real authority refusing
before constructing/starting a writer. Existing journal algorithm and M2Validator
rules stay intact. Encapsulate the raw secure sink so other QA callers cannot bypass
the guard; demonstrate call-site closure with source tests. Preserve any explicit
unit-test fake sink path without labelling it runtime admission. Do not automatically
start a current writer just because inspection succeeded.

Observable deterministic success: fake independently issued admission, distinct
prior/current generation, one fixed read, validate each using existing Dart
M2Validator, retain exact prior bytes, then permit only an explicitly authorized
current writer after acknowledgement. Unchanged repeat inspection performs zero
additional reads. All diagnostics remain non-qualifying.

Observable refusals: caller-constructed/absent/revoked authority, tuple/candidate/
target/storage drift, duplicate attempt registration, second writer, stale release,
changed replay and release before retention perform zero new writes; pre-admission
failures perform zero reads. Hold the fake read/retention with completers and attempt
a second writer to prove order, not only final equality. Missing/foreign/truncated/
oversized/secret-bearing prior bytes, swapped generations, occupied fresh slot,
retention failure and read failure refuse without repair/launch/fallback. Assert
full prior snapshot remains immutable and unmodified after refusals. Test two
journals sharing the same fake slot, not just one journal's queue.

Proof ceiling: this makes in-process enforcement testable and closes current QA
caller bypasses; it does NOT fence another process or provide independent platform
measurements. Cross-process use remains continuation_unavailable until a separately
admitted private authority/collection transport controls every writer and proves
installed candidate/entrypoint/target/storage identity. No mutex-only claim, new
counting authority or new native transport may fill that gap. The file allowlist
cannot deliver real package/storage custody. Packaging implication: any later
transport must trace its local imports into generated/plugin/native/APK closure
and receive separate scope approval; checkout Dart tests cannot qualify delivery.
This is one proof task, not authorization or a second proposed implementation lane.

## Offline evidence and acceptance map

Run from repository root:

    python3 .task-evidence/t_06c58314/check_trace.py snapshot
    python3 .task-evidence/t_06c58314/check_trace.py verify
    git diff --check -- docs/quality/2026-10-06-m2-coordinator-admission-trace.md .task-evidence/t_06c58314

[validation.json](../../.task-evidence/t_06c58314/validation.json) retains exact
commands/results, source fingerprints, predecessor blob comparisons, citation/link
checks and tracked/untracked whitespace checks. Checker negative controls test only
integrity refusal, not a synthetic product coordinator. Inherited controls were
not rerun. Acceptance 1 maps to authority table and actual write/read call chain;
acceptance 2 to the single typed custody proof slice and explicit delivery ceiling;
acceptance 3 to source binding and executed integrity receipts. Completion and ledger
receipts are card-local; shared ledger bookkeeping is excluded from the commit.

Only offline Python/Git checks on Linux are exercised. M2 unverified; APK, merged
package/plugin/compiled target, install, device/API/ABI, actual storage/read/protection/
durability, OS/PID/death/relaunch, live Agent/history, credentials/inference,
authoritative counts and zero live mutations remain individually NOT_CHECKED.
Questions: none. Defaults applied: no live execution, secrets, sudo or packaging edits.
