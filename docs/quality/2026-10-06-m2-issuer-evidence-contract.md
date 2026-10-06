# M2 installed QA issuer admission evidence contract

Card: `t_620a6d33`. Backlog: `DOC-M2-ISSUER-EVIDENCE-CONTRACT`. Goal: M2.
Status: PROPOSED, source-only; current candidate **NOT_ADMITTED**.
Android and full M2 remain **unverified**. Runtime remains `not_admitted`,
`continuation_unavailable`, `qualifies=false`, `authoritative_counts_unavailable`.

## Scope and authority ceiling

This is the single dossier prerequisite selected by the
[updated preflight](2026-10-06-m2-refusal-continuation-preflight.md#exactly-one-missing-prerequisite).
It is not an issuer implementation, ticket protocol, coordinator, collection
transport, counting endpoint or instruction to activate a runner. Its review can
approve document boundedness and source provenance only, never runtime rights.
No APK, install, plugin, OS-death, live request, history measurement, private
storage I/O, cross-process custody or authoritative mutation counts were checked.
Those items are NOT_CHECKED and are not acceptance criteria for this card.

The [runtime ADR](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent)
and [security ADR](../adr/security-and-privacy.md#decision) remain binding;
[threat-model trust boundaries](../security/threat-model.md#trust-boundaries)
separate the device, OS, Agent and management plane. Agent remains authoritative;
Wing Link must not proxy data-plane traffic or supply shadow counts/state.
Agent/Desktop/Conduit are read-only references excluded from this source discovery.
No product/code/test/runner/manifest changes, credentials, sudo, device/process
operations or upstream changes are authorized. Retained testers are not task-owned.

## Candidate and exact inspected provenance

The candidate is the current worktree source graph, not HEAD, a merged APK or an
installed application. [source-snapshot.json](../../.task-evidence/t_620a6d33/source-snapshot.json)
binds exact SHA-256 bytes, line counts and HEAD for every cited source. The
selection snapshot is compared separately; drift cannot inherit previous passes.
The checker follows literal Dart import/export/part directives only. It is not a
compiler, external package resolver or native dependency verifier.

- `integration_test/hermes_m2_observer_main.dart:1-8`: main only awaits no-input
  bootstrap. No Flutter binding, providers, channel, store or app is constructed.
- `integration_test/support/m2_observer.dart:1-33`: metadata export, private result
  constructor and private unavailable runtime. No public admission/launch inputs.
- `integration_test/support/m2_metadata.dart:1-6`: external directives are exactly
  `dart:convert` and `package:uuid/uuid.dart`. Complete local closure is main,
  observer and metadata, not the fake harness or product persistence graph.
- `pubspec.yaml:9-18`; `pubspec.lock:1020-1027`: UUID declared and locked to 4.6.0.
  Lock metadata is not verification of fetched package bytes or APK contents.
- `android/app/build.gradle.kts:37-45`; `android/app/build.gradle.kts:80-94`:
  configured base application ID; debug isolation flag conditionally adds `.qa`.
  Debug signing alone does not imply debug mode. A flag or filename proves neither
  the compiled target nor merged/native contents nor installed identity.
- `test/tooling/support/m2_fake_harness.dart:1-13`;
  `test/tooling/support/m2_receipt_admission_cases.dart:75-131`;
  `test/tooling/support/m2_receipt_admission_cases.dart:152-200`: private fake
  authority, tuple, retainer and custody are test-only. Object identity, booleans,
  epoch and synthetic retention cannot witness installed admission.
- `integration_test/support/m2_metadata.dart:45-58`;
  `integration_test/support/m2_metadata.dart:68-96`;
  `integration_test/support/m2_metadata.dart:229-259`: validator bounds one
  envelope to 128 events/65536 UTF-8 bytes and refuses authoritative counters,
  ledger epoch and complete coverage. Validation does not convey authority.

Historical [handoff constraints](2026-10-06-m2-receipt-handoff-contract.md#independent-admission-distinct-from-caller-assertions)
remain useful design requirements. Their old `M2Sink.read()` and injectable
constructors are removed from today's graph; historical citations are not current
APIs and must not be revived or invoked by this proposal.

## Proposed independent measurement responsibilities

The owner names below are proposed responsibilities, NOT existing services,
implementations, credentials, approvals or assigned people. No independent owner
has supplied installed evidence. Separately scoped implementation and explicit
admission would be required before any measurement or right could exist.
The candidate, caller, envelope and fake authority cannot attest their own rights.
A future assessor must authenticate each evidence origin independently of those
objects and reject mismatches, unknown provenance and conflicting records.

Each future evidence reference must identify its measurement owner, reviewed
method/version, immutable record/content fingerprint, exact candidate identity,
target/storage incarnation, attempt/generation binding, observation ordering,
validity interval and revocation revision. A record needs independently verifiable
custody, not a caller-provided path, digest or boolean. Evidence references are
metadata only, not bearer tickets or an executable schema. No numeric freshness
TTL is invented: until a separately reviewed bounded validity policy and current
revocation check exist, freshness is UNAVAILABLE. Cross-record identities must
agree; missing data is never inferred from another row.

## Bounded candidate admission dossier

Exactly ten required facts follow. Source evidence is INSPECTED_SOURCE only;
every installed admission fact is UNAVAILABLE. The named responsibilities and
future provenance are proposals. No artifact, OS record or authority is fabricated.

| ID | Required admission fact | Proposed independent owner | Required future provenance (not supplied) | Current evidence | Installed status |
| --- | --- | --- | --- | --- | --- |
| F01 | Isolated QA package and debug mode | Package measurement reviewer | Exact APK digest plus merged package ID `com.trebuchetdynamics.hermes.wing.qa`, debuggable/build mode and component declarations; reject product/release package | Gradle configuration only, cited above | UNAVAILABLE |
| F02 | Compiled M2 entrypoint and complete delivered dependency closure | Artifact provenance reviewer | Build-input manifest, reviewed build method, compiled target attribution, same APK digest, Dart/native/plugin/component closure and excluded fake/product runtime paths | Three-file local source closure and UUID lock only | UNAVAILABLE |
| F03 | Installed artifact on disposable owned target | Installation identity witness | OS-derived installed package/version/signing/artifact identity matching F01/F02, disposable target authorization and install incarnation | No install or target readback | UNAVAILABLE |
| F04 | Exact isolated storage incarnation | Storage isolation witness | OS/sandbox-derived binding of installed QA identity to dedicated storage incarnation; reinstall/clear/reset invalidates old binding; no personal slots | No storage measurement | UNAVAILABLE |
| F05 | Immutable attempt and current/prior generation tuple | Attempt lifecycle witness | Independently registered attempt, current generation and optional distinct prior generation tied to F01–F04; frozen snapshot digest; first-generation absence vs continuation explicitly distinguished | Metadata aliases are syntactic only; fake tuple is not registration | UNAVAILABLE |
| F06 | Freshness and revocation at use and return | Admission validity witness | Reviewed bounded validity policy, independently current revocation revision and ordered checks before any permitted operation and before return/release; changed identity invalidates | No installed validity/revocation record | UNAVAILABLE |
| F07 | Separate bounded read permission | Local QA permission reviewer | Explicit read-only authorization for one attempt's metadata at F04 under F05/F06; no enumeration, paths, product storage or launch right | No installed read grant | UNAVAILABLE |
| F08 | Separate bounded write permission | Local QA permission reviewer | Independently explicit generation-bound write authorization; neither read right nor package identity implies it; release conditional on F09/F10 | No installed write grant | UNAVAILABLE |
| F09 | Exclusive receipt custody and writer fence | Receipt custody witness | Cross-process exclusion bound to same storage/attempt; independently ordered fence acquisition, prior read/validation and retention acknowledgement, no competing writer through release | Fake custody only | UNAVAILABLE |
| F10 | Retain complete prior bytes before later writer release | Independent snapshot retainer | Full immutable prior bytes retained under prior generation before current writer release; retained digest/size/sequence and acknowledgement bind unchanged tuple and custody epoch; retrievable through a separately admitted method | Fake in-memory retention only; no post-death retainer | UNAVAILABLE |

F05 records only random aliases in public evidence. No real serial/PID, private
endpoint, profile/session/run/message ID, alias map, transcript, credential, host
path, ciphertext/database dump or private-value hash belongs in this dossier.
Private identity associations must remain inside a separately reviewed witness
boundary, not ordinary diagnostics. Reviewed public artifact fingerprints are
permitted; digest syntax alone does not authorize hashing private data.

## Exclusive ordering requirements

These are requirements, not implemented actions or chosen transport:

1. Independently bind F01–F08 to one immutable tuple and recheck validity; acquire
   F09 exclusion before any writer construction or receipt access.
2. For continuation, validate the complete prior envelope against prior generation,
   never current generation. Retain complete bytes, not parsed/reconstructed events,
   a digest alone, a promise, UI state or a caller acknowledgement.
3. F10 must acknowledge that immutable snapshot under unchanged F04/F05/F06/F09
   before any later-generation writer release. Separately validate current bytes;
   never merge envelopes, rewrite generations or reuse validator state.
4. Fresh attempt: absent prior generation requires independently evidenced empty
   slot; occupied slot refuses. Continuation: declared prior requires its complete
   exact bytes; absent, corrupt, truncated or foreign prior refuses without repair.
5. Recheck revocation and all identity bindings before return/release. Repeated
   inspection cannot reread an overwritten slot or silently register a new tuple.
   A lost fence, retainer loss, changed payload or reincarnation invalidates rights.

One envelope remains <=65536 UTF-8 bytes and <=128 events. At most prior and current
means <=131072 bytes and <=256 events, with independent validation and sequence per
generation. Bounded memory in one dying client is not cross-process retention.
No public raw sink, extra slot, product-store substitution, bootstrap input,
coordinator activation or retrieval transport is selected. These absent runtime
facilities require separate scope; this contract does not authorize their creation.

## Fail-closed acceptance matrix

Document rule: require independently measured, valid and mutually consistent
F01–F10 for any future admission assessment. This rule cannot produce runtime
rights. Current source-only evidence cannot satisfy any installed fact. For this
candidate all controls remain NOT_ADMITTED; rights released are NONE, runtime is
`not_admitted` / `continuation_unavailable`, and `qualifies=false` throughout.

| Control | Failed facts/reason | Document disposition | Rights released |
| --- | --- | --- | --- |
| C00 Current refusal-only candidate | F01–F10 installed evidence absent | NOT_ADMITTED | NONE |
| C01 QA flag/package string/debug signature only | F01–F03 not measured; signing is not mode | NOT_ADMITTED | NONE |
| C02 Source digest or three-file closure offered as APK proof | F02/F03 missing compiled/merged/installed provenance | NOT_ADMITTED | NONE |
| C03 Installed identity or target changed; storage reset/reinstall | F03/F04/F05 binding mismatch | NOT_ADMITTED | NONE |
| C04 Caller aliases/booleans/private fake authority | F05 independent registration absent | NOT_ADMITTED | NONE |
| C05 Stale, revoked or unavailable current validity | F06 absent or invalid | NOT_ADMITTED | NONE |
| C06 Read right missing; write right offered instead | F07 absent; no implied read | NOT_ADMITTED | NONE |
| C07 Write right missing; read right offered instead | F08 absent; no implied write | NOT_ADMITTED | NONE |
| C08 Changed attempt/current/prior/payload or reused attempt | F05/F06 inconsistent immutable tuple | NOT_ADMITTED | NONE |
| C09 No exclusive fence, competing writer or lost custody | F09 absent/invalid | NOT_ADMITTED | NONE |
| C10 Prior declared but absent/foreign/truncated; fresh slot occupied | F05/F10 inconsistent prior evidence | NOT_ADMITTED | NONE |
| C11 Release before full retained-byte acknowledgement | F09/F10 ordering violation | NOT_ADMITTED | NONE |
| C12 Digest-only/in-client-memory/fake retention | F10 post-death immutable retention absent | NOT_ADMITTED | NONE |
| C13 Valid metadata/history flags/quiet UI imply qualification | Independent OS/history/counting evidence absent | NOT_ADMITTED | NONE |
| C14 Hypothetical complete independently verified F01–F10 | Not supplied; current runtime still refuses; future assessment needs separate scope | NOT_ADMITTED | NONE |

C14 deliberately does not promise an accepting runtime path. A future complete
dossier could be assessed as satisfying proposed evidence requirements, but even
that assessment and review issue no ticket, bootstrap rights, read/write action,
counting right or platform qualification. Never infer zero sends, session creates,
Stop or approvals from silence, a fixture, fake custody or this matrix.
`authoritative_counts_unavailable` remains independent of issuer admission.

## Executed checks and acceptance mapping

Run from repository root:

    python3 .task-evidence/t_620a6d33/check_contract.py snapshot
    python3 .task-evidence/t_620a6d33/check_contract.py verify

Task-local [validation.json](../../.task-evidence/t_620a6d33/validation.json) and
command receipts retain exact cwd/argv/stdout/stderr/exits. Checks bind source
fingerprints, source directive closure, local links/anchors, citation ranges,
all ten dossier facts and fifteen refusal rows, preserved refusal/counting markers,
and whitespace including new authored files. These are lexical document/source
checks, not Dart tests, OS measurements or a security proof. No predecessor suite
is rerun. Added-file `git diff --no-index --check` exit 1 with empty output means a
file difference, not a whitespace failure.

Acceptance 1 maps to exact inspected provenance plus F01–F10 and ordering above.
Acceptance 2 maps to C00–C14, UNAVAILABLE installed evidence, NONE rights and the
unchanged runtime/counting/Android ceiling. Acceptance 3 maps to command receipts,
helper-managed task/evidence/render readback, scoped ledger delta and authored-only
overlay branch/SHA in the native review handoff. Shared TODO/goals contents are
not claimed as wholly authored; only this task's delta is retained locally.

Task done means this documentation slice is delivered, not M2 met. If executed
document passes auto-promote M2, the helper's public load/dump API preserves
unverified before render. A resulting `M2: unverified goal has no open task`
validation diagnostic is retained, not hidden, repaired with invented backlog, or
used to force platform acceptance. Native same-card review handoff is the final
worker step; no review approval is claimed.

Executed outcomes: snapshot and verify exited 0. Eighteen source fingerprints,
seven initial links, thirteen citation ranges, ten required facts and fifteen refusal
rows passed the document checks. Helper task/evidence/render calls succeeded;
automatic M2 promotions were restored to unverified through public helper APIs.
The helper's validate command exited 1 with exactly the no-open-task diagnostic
above. This known ledger-model gap is recorded in
[ledger.json](../../.task-evidence/t_620a6d33/ledger.json), not platform evidence.
Unrelated task/goal objects and existing evidence entries were preserved.

Questions: none. Defaults retained: source-only, refusal-only, no live, no secrets,
no sudo, no issuer/runner/transport activation and no new task discovery.
