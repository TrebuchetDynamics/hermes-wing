# Android M2 preflight delta after QA default refusal

Card: `t_c799c475`. Backlog: `DOC-M2-REFUSAL-CONTINUATION`. Goal: M2.
Disposition: source-only updated preflight; Android and full M2 remain **unverified**.
Runtime remains `not_admitted`, `continuation_unavailable`, `qualifies=false`.

## Evidence ceiling and historical correction

This receipt supersedes only the actionable source assumptions in the
[original preflight](2026-10-06-m2-android-preflight.md), not its historical evidence.
The [single named-device scenario](2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01)
remains the intended outcome: running, confirmed client death, completed while
absent, same-storage relaunch, exact canonical history, no recovery mutation.
No target, credentials, cost consent, artifact or positive runtime is admitted here.

[Default refusal](2026-10-06-m2-default-refusal.md#scope-and-predecessor-limits)
removed the formerly proposed injectable observation/storage APIs. Its predecessor
44-test/60-negative-consumer results are historical offline enforcement, not rerun
by this card and not platform acceptance. The old delivery/handoff receipts cite
pre-migration constructors and cannot establish today's public delivery boundary.
Do not copy those constructors into a device runner or recreate them as public
factories to make an earlier plan executable. Historical receipts remain untouched.

Bindings are current worktree SHA-256 values in
[source-snapshot.json](../../.task-evidence/t_c799c475/source-snapshot.json), not
HEAD alone. The selection comparison records scoped equality/drift against the
picker's snapshot; neither selection nor an earlier review grants installed authority.
Only Python/Git document/source checks run here. No Dart/Flutter suites, builds,
installs, process/device actions, plugin I/O, private storage, network or live calls.
Agent/Desktop/Conduit references require no deep inspection for this Wing-local
export correction and are not changed or searched.

## Current prerequisite map

INSPECTED means source, not execution. Removed means absent from the bounded
current QA delivery graph, not absence of analogous product functionality.

| Area | Current inspected source | Updated consequence |
| --- | --- | --- |
| QA entrypoint/public exports | `integration_test/hermes_m2_observer_main.dart:1-8`; `integration_test/support/m2_observer.dart:1-33` | Main only awaits no-input `m2Bootstrap`. Public result has a private constructor; private runtime is unconditionally unavailable. There is no public app/observer/provider/sink/journal/authority input. No Flutter binding, providers, channel or store construction is delivered by this entrypoint. |
| Transitive delivery | Main imports observer; observer exports metadata; `integration_test/support/m2_metadata.dart:1-6`; `pubspec.yaml:9-18` | Complete local directive closure is exactly main, observer and metadata. External directives are `dart:convert` and `package:uuid/uuid.dart`; UUID is declared and locked. No product imports, secure plugin, fake harness, launcher or issuer in that Dart graph. This is source dependency closure, not APK/native registration proof. |
| Conditional package isolation | `android/app/build.gradle.kts:37-45`; `android/app/build.gradle.kts:80-94`; `scripts/run_android_maestro_features.sh:7-15`; `scripts/run_android_maestro_features.sh:42-46` | Debug plus `WING_ISOLATED_DEVICE_TEST=1` still selects `.qa` statically. The wrapper builds the different feature fixture and installs shared output; it does not enforce this M2 entrypoint, inspect the merged artifact, or prove device/storage ownership. No packaged entrypoint, installed package, APK digest, native dependency or target readback exists as evidence here. |
| Product storage retained, QA raw sink removed | `lib/features/hermes_chat/providers/hermes_channel_provider.dart:17-28`; `lib/core/hermes/setup/secure_hermes_detached_run_store.dart:10-54`; `lib/core/hermes/channel/hermes_detached_run_store.dart:74-84` | Production still composes secure endpoint/run stores and exposes load/save with process-local coordination identity. Awaited secure write is not measured durability. The removed QA raw sink/key writer cannot be called; a production constructor is not permission to use personal storage or substitute it for QA receipt custody. |
| Durable run admission retained | `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart:209-269` | Run-mode admission still awaits delegated lease save. It neither emits an independently witnessed QA write acknowledgement nor proves Android survival. No product persistence migration is proposed. |
| Receipt custody now fake-only | `test/tooling/support/m2_fake_harness.dart:1-13`; `test/tooling/support/m2_diagnostic_writer.dart:8-34`; `test/tooling/support/m2_receipt_admission_cases.dart:75-112`; `test/tooling/support/m2_receipt_admission_cases.dart:179-200` | Library-private sink/journal/observer, fake authority and custody remain diagnostic test composition. The tooling consumers register tests only. They supply no installed issuer, cross-process retainer, permitted retrieval transport or public raw writer. Fake retention/release is not real post-death custody. |
| Metadata retained without authority | `integration_test/support/m2_metadata.dart:45-58`; `integration_test/support/m2_metadata.dart:68-96`; `integration_test/support/m2_metadata.dart:297-346` | Validator/envelope/aliases/enums remain public. One envelope is limited to 128 events/65536 UTF-8 bytes and one attempt/generation. Synthetic history expectations can validate records, not grant observation rights or expose a runtime witness. No public pre-removal history-admission seam is created. |
| Actual history admission retained separately | `lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart:334-420`; `lib/core/hermes/client/hermes_api_client.dart:239-275`; `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart:2100-2175` | Production checks declared read authorization, bounded page response identity/lineage and current ownership. Matching terminal status fetches history before removing/persisting the lease; status/history failure retains uncertainty, including ambiguous 404. This is inspected production reconciliation, not a public QA admission callback or an independently measured canonical UI result. Completed is the scenario's only accepting terminal outcome; failed/cancelled settlement is not completed qualification. |
| Authoritative counting still unavailable | `integration_test/support/m2_metadata.dart:104-113`; `integration_test/support/m2_metadata.dart:229-259`; `test/tooling/support/m2_diagnostic_writer.dart:125-135` | Validator refuses authoritative accepted/rejected counters, ledger epoch and complete coverage. Client/fixture diagnostic counts do not become server counts. No counting route/source has been qualified; `authoritative_counts_unavailable` remains the ceiling. Never infer zero recovery mutations from silence, UI or successful fake custody. |

Current history admission is stronger than the original preflight's historical
registry-absence interpretation: failed status reads retain ownership. The
[history repair receipt](2026-10-06-m2-history-admission.md) is context, not a
fresh executed pass here. Production read policy and response identity checks do
not resolve the separate observation/custody/counting admission gaps.

## Exactly one missing prerequisite

Selected prerequisite: a separately reviewable, source-bound **installed QA
issuer admission evidence contract** for this refusal-only delivery boundary.
This is a contract/provenance prerequisite, NOT an issuer, ticket API, public
runtime observer, coordinator or collection transport. Existing
[handoff requirements](2026-10-06-m2-receipt-handoff-contract.md#independent-admission-distinct-from-caller-assertions)
remain design constraints; their old `M2Sink.read()` assumption is not callable
in the current export graph. Caller-provided booleans, random aliases, class
privacy and valid metadata do not independently establish trusted admission.

Observable next proof, under a separately scoped source-only contract: one
bounded candidate admission dossier maps each required fact to a named independent
measurement owner and an exact inspected source/artifact provenance or explicitly
UNAVAILABLE evidence. It must discriminate the current refusal-only candidate
from an admitted installed issuer; missing evidence yields NOT_ADMITTED. A review
can check that mapping without executing the candidate. This is the next proof
artifact, not a new measurement performed or positive admission granted here.

The dossier must bind QA package/debug/compiled entrypoint and dependency closure,
target/storage incarnation, immutable attempt/current/prior generation identity,
freshness/revocation, separate read/write permissions and exclusive receipt custody
(retain prior bytes before any later writer release). It must distinguish source
identity from merged APK, installed identity and OS observations. It may reference
only reviewed, independently sourced evidence; self-asserted package fields and
private fake authority objects cannot supply it. Each absent measurement remains
UNAVAILABLE, not a invented implementation or default authorization.

Implementation limit: propose that evidence contract and fail-closed acceptance
matrix only; do not add an issuer, issue authority, reopen bootstrap inputs,
construct stores, write/read receipts, launch Flutter, select transport, activate a
coordinator or edit product/tooling/tests/runners/manifests. If the contract needs
excluded paths, record the specific scope requirement rather than modifying them.
Review limit: native review may approve the source-only dossier's boundedness and
provenance, not authorize installation, credential acquisition, inference, device
control, storage I/O or runtime activation. Any later implementation and any live
qualification require separate scope and evidence. No new card is created here.

This single prerequisite does not silently absorb the remaining qualification
conditions into one implementation. Packaging, real secure-plugin survival/lock,
OS-death/absent completion, independently admitted history, notification denial,
auth expiry/revocation/wrong-owner controls and credential-wide authoritative
accepted/rejected mutation counts remain separately NOT_CHECKED. Even a future
valid admission contract cannot satisfy the authoritative counting gap, assert
zero sends/creates/Stop/approvals, or make M2 met. No counting endpoint, private
storage export, Wing Link data-plane proxy or Agent change is proposed.

## Checks and acceptance mapping

Run from the repository root:

    python3 .task-evidence/t_c799c475/check_preflight.py snapshot
    python3 .task-evidence/t_c799c475/check_preflight.py verify

The task-local checker compares bounded source fingerprints, resolves literal
import/export/part closure, checks refusal/export/privacy/counting source markers,
verifies local links/anchors and citation ranges, and runs scoped whitespace
checks including untracked authored files. These are lexical/source integrity
checks, not a Dart compiler test, validator execution or security proof.
Exact argv/cwd/stdout/stderr/exits are retained in task-local command receipts;
[validation.json](../../.task-evidence/t_c799c475/validation.json) records computed
check totals, source graph and authored hashes. For added files,
`git diff --no-index --check` exit 1 with empty output is an added-file difference,
not a whitespace failure. No predecessor suite is replayed.

Acceptance 1: the prerequisite map, current source snapshot and closure checks
separate removed APIs, retained private diagnostics/metadata and product seams.
Acceptance 2: the single admission-evidence-contract prerequisite and observable
source-only dossier, with implementation/review limits and unchanged refusal and
counting ceilings. Acceptance 3: recorded link/citation/hash/whitespace checks,
helper-managed task/evidence/render readback and local authored-only overlay commit.

Ledger completion means this documentation task is done, not Android qualification.
The helper can auto-promote M2 after its last task and any executed document pass;
use its public load/dump/render APIs to preserve **unverified**, retaining the
resulting no-open-task validation diagnostic if present. Do not invent a passing
platform check or create new backlog scope. Shared ledger changes are recorded
as a task-local delta; unrelated existing ledger contents are not claimed as authored.
Native same-card review handoff is this card's final worker step; review approval
is not claimed. Local overlay branch/SHA and ledger outcomes are in the handoff.

Executed outcomes: snapshot and verify exited 0; 36 source fingerprints, seven
local links and 25 citation ranges passed. The source closure is the three QA
Dart files listed above. Task/evidence/render helper calls succeeded. The helper
auto-promoted M2 to met; its public API restored unverified before final render.
`goals.py validate` then exited 1 with `M2: unverified goal has no open task`.
This ledger-model gap is retained in `.task-evidence/t_c799c475/ledger.json`, not
fixed by inventing another task, promoting M2 or executing excluded device work.
Unrelated goal/task objects and existing evidence entries were preserved.

Questions: none. Defaults retained: refusal-only runtime, source-only continuation,
no live requests, secrets, sudo, upstream changes, product migration or activation.
