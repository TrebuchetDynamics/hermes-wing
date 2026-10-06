# M2 bounded QA fixed-slot custody proof review

Status: source-only requirements reviewed; implementation NOT_AUTHORIZED.
M2 remains unverified. No installed independent authority exists in this review.

## Authority and source baseline

The [approved admission trace](2026-10-06-m2-coordinator-admission-trace.md#exactly-one-proposed-next-proof-slice)
and [approved handoff contract](2026-10-06-m2-receipt-handoff-contract.md#independent-admission-distinct-from-caller-assertions)
are the baseline, not implementation permission. Preserve Agent ownership,
separate Agent/Wing Link credentials, no upstream changes, and secret-free metadata.
Only the trace's four QA Dart seams and a future card's evidence are proposed;
`integration_test/support/m2_receipt_admission.dart` and
`test/tooling/m2_receipt_admission_test.dart` are absent intended artifacts, not
files created by this review. No packaging, runners or native transport is approved.

Source citations below are bound by full-file and line-range fingerprints in the
[card binding](../../.task-evidence/t_321431fe/binding.json). The
[validation receipt](../../.task-evidence/t_321431fe/validation.json) records offline
execution and negative integrity controls, not executable custody behavior.

## Complete present caller closure

| Present path | Source | Required future closure |
| --- | --- | --- |
| QA main constructs raw secure sink/journal and passes journal to app | `integration_test/hermes_m2_observer_main.dart:10-19` | Registration/admission/inspection must precede writer construction; default runtime authority absent, fail closed with no app observer startup. |
| Public M2ObserverApp accepts arbitrary journal; provider creates observer/channel and starts observer | `integration_test/hermes_m2_observer_main.dart:25-54` | Runtime composition must accept only boundary-issued writer capability, not a caller journal or fake issuer injection. Keep explicit widget-test composition separate. |
| Public M2Sink combines read and write; public M2SecureSink constructor derives key from attempt; read unchecked, write validates | `integration_test/support/m2_observer.dart:46-72` | Raw secure sink and construction become library-private within the QA custody library; no public raw read/write constructor or underlying sink getter. Only fixed operations through separate capabilities. |
| Public journal constructor/sink; record starts commit; flush reads after writes | `integration_test/support/m2_observer.dart:385-479` | Runtime journal accepts only released current writer facade. Its existing algorithm, validation and post-write flush stay intact; flush is not prior inspection. Do not expose raw sink through journal.sink. |
| start, state and delegate load/save observations all reach record | `integration_test/support/m2_observer.dart:497-507`; `integration_test/support/m2_observer.dart:537-653` | Fence observer creation/start as well as sink operations. All paths share one issued writer identity; coordinationKey is the product delegate's key, not QA custody. |
| MemorySink and journal/observer setup; two additional fresh journal constructors | `test/tooling/m2_observer_test.dart:23-48`; `test/tooling/m2_observer_test.dart:73-84`; `test/tooling/m2_observer_test.dart:255-294` | Preserve explicit isolated test-fake path. Test helpers carry no runtime issuer registration or secure storage factory. |
| Widget composition uses mocked preferences/storage and public app journal | `test/tooling/m2_observer_test.dart:555-600` | Migrate explicit fake composition if authorized later; mocked storage is not package admission. |
| Tests directly construct secure sink for alias/envelope refusal | `test/tooling/m2_observer_test.dart:603-640` | Future scoped source contracts must show no public raw construction; port these refusal observations to guarded operations without weakening validator tests. Existing test file edits require explicit scope approval if migration is needed. |

A Wing-only Dart caller search found these three actual definition/caller files;
its exact matches are retained in binding.json. Later proof must repeat the search,
inspect imports/exports/part relationships and public constructors, and assert every
runtime writer path is closed. String matching alone is not a language-level proof.

Dart privacy is library-scoped, not directory-scoped. Proposed custody types and raw
sink must share a deliberate private library boundary (for example, a reviewed part
relationship within the allowlisted support files); merely prefixing a constructor
in another library cannot grant safe access. No public factory accepting arbitrary
M2Sink, authority interface implementation, journal, bool or dynamic map may reach
secure runtime I/O. A sealed opaque handle with private construction is necessary
but insufficient: the custodian must also verify object identity in its private
issuance registry, so an implementer cannot spoof authority by implementing a type.
Test fakes stay in isolated tests, injected into a fake-only coordinator with no
secure factory. No test issuer can be selected by main, a build flag, environment,
caller metadata or production provider override. No real issuer is installed.

Scope gap: the four-file future allowlist excludes the existing observer test file.
If closing public constructors requires migrating those tests, seek a separate
explicit amendment; do not preserve an unsafe runtime API merely to keep them
compiling. This review neither edits the file nor grants that amendment.

## Typed issuance and custody contract

REQ-ISSUE: Authority issuance is a private, independent operation. It establishes
QA package exactly com.trebuchetdynamics.hermes.wing.qa, debug compiled entrypoint
integration_test/hermes_m2_observer_main.dart, reviewed source/artifact identity,
merged component/plugin closure and disposable target/storage identity. Caller
booleans, optional envelope application_id, aliases and OS flags are not evidence.
Only an isolated test issuer can supply synthetic authority for the proposed proof.
Runtime requests without a separately admitted issuer refuse before I/O.

REQ-TUPLE: Freeze the full tuple before registration: schema version 1, operation
inspect, canonical UUID-v4 attempt/current generation, optional distinct prior
generation, authority-instance identity and revocation epoch, reviewed candidate
source/artifact/entrypoint/package/debug/component/plugin evidence identities,
disposable target identity, storage-instance identity and fixed-slot ownership
identity. Include independently granted read and write rights and their identities,
exclusive custodian registration identity, and immutable optional current payload
snapshot. No caller-selected keys/paths, product IDs, real endpoint/PID/serial,
secret values or private-data hashes. Evidence is private typed identity, not an
unbounded wire record or proposed protocol field. Payload changes are tuple drift.

REQ-RIGHTS: Package admission, one prior read and current writer release are separate
rights. Read cannot confer write; retention acknowledgement cannot confer write.
Writer right cannot bypass inspection or grant enumeration. Exact tuple and issuer
registry membership, validity and epoch must be checked before read, after awaited
read, after awaited retention, before diagnostic return, at release and at every
writer operation. Rights revocation prevents new I/O; already-issued I/O cannot be
retroactively undone and must not produce a successful diagnostic/release.

REQ-REGISTER: Register one immutable tuple per (storage instance, attempt fixed slot)
before acquiring read. A second registration, even an identical tuple with another
handle, refuses; exact inspection replay uses the original registry entry. Claim
exclusive in-process custody before the read and retain it across all awaits.
No generation can acquire a second writer. A consumed/revoked registration is not
reopened under the same attempt; use a new random attempt only by explicit action,
never refusal fallback. No persistence map or second storage key.

REQ-RETAIN: After the one fixed read, independently validate prior against attempt
and priorGeneration, and supplied current against attempt and currentGeneration
with separate M2Validator.validateEnvelope calls. Each begins sequence 1 and its own
nondecreasing elapsed clock. Retain the complete exact encoded prior string (UTF-8
bytes preserved, including accepted whitespace), privately immutable, not decoded
and re-encoded. A typed acknowledgement binds that exact snapshot, full tuple,
registry identity and epoch; empty-slot fresh admission has an explicit empty
acknowledgement, not fictitious prior bytes. Do not return raw snapshots or arbitrary
exceptions. Failed read/validation/retention invalidates the entry permanently.

REQ-RELEASE: Inspection writes nothing and never starts observer or journal. Only an
explicit separately write-authorized operation may consume an exact retained
acknowledgement and issue one current-generation writer facade. Release must check
unchanged tuple/epoch and acknowledgement identity, not caller-provided equality
flags. Wrong, missing, stale or replayed release yields zero new writes and no new
writer. Later writer writes/flush readbacks are not additional inspection reads;
track these counters separately. A journal may write several coalesced snapshots,
but only the single released owner may do so. Failure must not release custody to a
competing writer while any old authorized write is pending. No second release after
completion; retain private diagnostic until invalidation, never reread prior slot.

REQ-BOUNDS: Preserve `integration_test/support/m2_observer.dart:89-129` and
`integration_test/support/m2_observer.dart:200-379`: 65536 UTF-8 bytes, 1..128
events per envelope; total two envelopes <=131072 bytes and <=256 events.
No merging, truncation, sampling, repair, generation inference or validator reuse.
Metadata allowlists, strict aliases/types/enums, exact owner, monotonic sequence/time,
acknowledgement consistency, history refusal and authoritative-count refusal stay
unchanged. `validateEnvelope` has no admitted history expectations; custody does not
add them. Journal freezing, irreversible invalidation, bounded coalescing and flush
snapshot equality remain unchanged. A stored envelope does not prove continuity.

## Required deterministic observation matrix

Every row is a future Dart proof requirement, NOT an executed result here. R means
cumulative fixed prior inspection reads; W means underlying slot writes caused by
inspection/release attempt. All rows assert zero enumeration/deletion/launch/fallback,
no product mutations and no raw exception/payload leakage. Those are fake counters,
not a claim of zero live mutations. Refusals do not change retained snapshots.

| ID | Controlled condition | Discriminating observation |
| --- | --- | --- |
| OBS-PAIR | Independently fake-issued distinct prior/current with valid full envelopes | R=1 W=0; two separate validator calls with their own generations; byte-exact retained prior; diagnostic only. Explicit separately authorized release issues one writer; its first record may then W=1. |
| OBS-PRIOR | Valid continuation with current absent | R=1 W=0; prior-only diagnostic, no completed pair or automatic writer. Later supplied changed snapshot cannot mutate registration. |
| OBS-REPLAY | Same handle/tuple repeated during pending read and after retention or writer overwrite | Concurrent inspect shares one pending operation; R remains 1, W=0 additional; after success returns immutable retained diagnostic without reread. Invalid/revoked handle never returns cached success. |
| OBS-FRESH | No prior declared, null slot | R=1 W=0; fresh diagnostic and exact empty acknowledgement; separate valid release required. |
| OBS-OCCUPIED | No prior declared, any occupied slot even current-matching bytes | unexpected_prior; R=1 W=0, no overwrite or adoption. |
| OBS-AUTH | Absent, caller-minted, foreign issuer, revoked before read, wrong package/debug/entrypoint/target/storage, missing evidence | not_admitted; R=0 W=0; no journal/observer construction/start. Test fake authority is unavailable through runtime main. |
| OBS-RIGHTS | Missing read grant or missing exclusive/retention capability | not_admitted or continuation_unavailable respectively; R=0 W=0. Valid read-only admission may inspect, but missing write right refuses release with zero new reads/writes. |
| OBS-DRIFT | Change each immutable tuple field or payload snapshot individually; swapped/equal generations, malformed alias/version/operation/unknown input | changed_handoff or invalid_input before read: R=0 W=0; after read: zero additional R/W, retained bytes unchanged. |
| OBS-REGISTER | Same storage/attempt registered again, same or different tuple/issuer; competing current generation | refuse second registration before second read; first pending/success snapshot unchanged; R<=1 globally W=0. Different fake sink wrappers for the same slot must share custody identity. |
| OBS-RELEASE | Before retention, wrong/missing ack, wrong generation/tuple/epoch/issuer, consumed replay or stale registration | refuse; zero additional R/W, no writer constructed; legitimate first release consumes acknowledgement once. |
| OBS-MISSING | Prior declared but null | missing_prior; R=1 W=0; no fresh fallback. |
| OBS-INVALID | Each envelope independently foreign attempt/generation, swapped/mixed generations, corrupt/truncated JSON, wrong wrapper/extra secret field, missing required metadata, wrong type/enum/alias, sequence gap/regression/time regression, inconsistent ack/owner, forbidden history/counts | invalid_envelope; R<=1 W=0; current can be validated before read and rejected with R=0; never partial diagnostic or replacement of prior. Supply prior-valid/current-invalid and converse separately. |
| OBS-BOUNDS | Per-envelope 65536 bytes and 128 valid events inclusive; 65537 or 129, empty events, pair aggregate bounds | Exact inclusive cases accepted diagnostically; overflow refuses, W=0. Count UTF-8, not code units; no truncation. Existing validator still rejects semantic invalidity within limits. |
| OBS-READFAIL | Fixed read throws or held read completes after revocation/tuple drift | One attempted read, W=0; sanitized terminal refusal, no retention acknowledgement/release, no retry or reread. |
| OBS-RETAINFAIL | Retention throws, returns wrong/incomplete snapshot ack, or rights revoked/drift after awaited retention | R=1 W=0; terminal refusal, no successful diagnostic or writer; preserve any already captured exact snapshot until private disposal. |
| OBS-READRACE | Completer holds first read; request writer A and competing writer B/second registration | Before completion R=1 W=0, no writer; after valid read still W=0 until matching retention ack. Failed read leaves both writers refused. |
| OBS-RETAINRACE | Completer holds retention after validation; request release/competing writer; revoke while held | R=1 W=0 through hold; late ack cannot release revoked owner; no success after revoke. Do not merely compare final slot equality. |
| OBS-TWOWRITERS | Two journals targeting one fake physical slot through distinct facades; only A owns admitted tuple | B construction/start or every attempted write refused before underlying I/O; after A release only A writes. Hold A write, attempt B, fail/revoke A then complete pending write: no B release while A pending, no transferred ownership or successful stale flush. Existing one-journal maximumActive test is insufficient. |
| OBS-CEILING | Synthetic success, caller old_pid_absent/new_generation flags or unadmitted cross-process continuation | qualifies=false; history_admission_unavailable and authoritative_counts_unavailable persist; cross-process continuation_unavailable, no storage access granted. |

Use completers rather than timers; assert counters and writer existence before and
after each await. No wall-clock success inference. Parameterize each drift/invalid
field rather than a single representative; prove prior/current validation state is
independent and rejected metadata cannot partially advance either validator. Test
read/release reentrancy and revocation at every asynchronous boundary. Separate
inspection R from journal.flush readbacks so a future test cannot hide a reread.

## Review outcome, execution and ceilings

This specification closes the design's public caller/fake-authority loopholes and
makes exact retention-before-release observable. It does not install enforcement.
The four-file future allowlist can demonstrate isolated in-process behavior only;
it cannot provide independent installed candidate/storage measurements, fence a
second process, or survive custodian process death. Actual cross-process use stays
continuation_unavailable until a separately reviewed authority and transport
controls every writer. A mutex or fake issuer is not platform custody.

Executed from repository root:

    python3 .task-evidence/t_321431fe/check_review.py snapshot
    python3 .task-evidence/t_321431fe/check_review.py verify
    git diff --check -- docs/quality/2026-10-06-m2-custody-proof-review.md .task-evidence/t_321431fe

The checker binds requirements/matrix, selected live callers/tests, predecessor
receipts, citations and local links. Isolated negative controls reject source drift,
missing refusal/ordering coverage, invalid citation and invalid link/anchor. They
check artifact integrity, not Dart custody semantics. Reuse unchanged predecessor
policy/product evidence only after fingerprint checks; do not rerun or upgrade it.

Acceptance 1: caller closure and REQ-ISSUE through REQ-REGISTER; actual source table
and binding. Acceptance 2: REQ-RETAIN through REQ-BOUNDS and OBS matrix; specified,
not executed Dart coverage. Acceptance 3: validation.json source-integrity PASS,
commands/exits, predecessor fingerprints and explicit ceilings. Native same-card
review handoff is this card's final step; approval is not claimed by this document.
No implementation authorization, new counting authority or product acceptance.

NOT_CHECKED: APK/package/plugin/compiled target/install/device/API/ABI/storage,
protection/durability/OS/death/relaunch, live credentials/auth revocation, network,
inference/history/counts and zero live mutations. Only offline tools on Linux ran.
Questions: none. Default retained: no implementation/runtime activation; scope gap
must be addressed in a separately authorized future card, not by expanding this one.
