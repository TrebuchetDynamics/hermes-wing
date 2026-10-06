# M2 QA runtime writer caller closure

Card: `t_481b1474`. Backlog: `DOC-M2-RUNTIME-CALLER-CLOSURE`.
Status: source-bound preparation only; runtime migration NOT_AUTHORIZED.
M2 remains unverified; qualifies=false. No installed authority is inferred.

## Discovery and completeness boundary

The offline [integrity checker](../../.task-evidence/t_481b1474/check_integrity.py)
scans allowlisted Wing source, test, scripts, native host, web, Playwright and CI
roots for writer types and entrypoint/module references. Its
[binding](../../.task-evidence/t_481b1474/binding.json) retains the exact file
manifest, full-file SHA-256 fingerprints, all matching lines and resolved Dart
import/export/part edges, including transitive local dependencies and incoming
edges to the implicated libraries. Full-file and line-range citation hashes bind
this report to the actual dirty working tree, not merely Git HEAD.

The direct definition/caller set is four Dart files: the QA main, observer support,
observer tests and receipt-admission tests. The predecessor review's three-file
inventory predates the last test and is no longer a complete current inventory.
The oracle's entrypoint string is evidence metadata, not a call to main. No other
matching runner, CI/native host or script reference was discovered in the bounded
scan. All four libraries use imports, not exports or parts; the inbound graph has
no barrel export/part path to them. All imported local modules resolve; external
Flutter/plugin packages terminate the source graph at their manifest dependencies.
This is textual source closure with inspected matching callers, NOT compiler,
reflection/dynamic-call, generated/package/plugin, installed binary, external
consumer or cross-process closure. Arbitrary future consumers can still import
public Dart APIs. No upstream/tools/build/vendor/private-state tree was scanned.
No Agent contract or Desktop parity change is proposed; their confirmed read-only
reference locations are `hermes-agent/` and `hermes-desktop/` per AGENTS.md.

## Present reachable paths

### PATH-MAIN — unadmitted bootstrap

`integration_test/hermes_m2_observer_main.dart:1-19` imports the support module,
initializes Flutter binding, generates aliases, constructs M2SecureSink and
M2Journal and runs M2ObserverApp. Alias syntax is not authority. There is no prior
inspection, custody registration, retention acknowledgement or writer release.
Construction alone does not perform QA read/write, but the public objects enable
it. Provider construction subsequently calls start, which immediately records and
starts a QA write. Main must eventually refuse before sink/plugin, journal,
observer/channel construction and runApp when no admitted authority exists.

### PATH-APP — injectable provider composition

`integration_test/hermes_m2_observer_main.dart:25-54` defines the public const
M2ObserverApp constructor and public journal field. Any caller journal can be
passed, including one wrapping a raw secure sink or caller-implemented M2Sink.
The provider creates M2StoreObserver with a real SecureHermesDetachedRunStore,
constructs HermesApiChannel, calls observer.start, registers changed() and invokes
observeState from channel notifications. Disposal removes the listener and disposes
the channel; it does not retroactively retract a journal write. Nested scopes do
not establish custody. The widget test proves override composition, not admission.

### PATH-SINK — public plugin boundary

`integration_test/support/m2_observer.dart:46-72` exposes M2Sink.read/write and the
public M2SecureSink constructor. The fixed QA key depends on attempt, not generation:
two generations under one attempt address the same slot. The storage field is
private, but direct read is unchecked and direct valid-envelope write reaches
FlutterSecureStorage. Validation limits metadata, not storage rights. The concrete
sink is final; the public interface can be implemented by arbitrary callers.
No delete/enumerate API exists on M2Sink. Direct FlutterSecureStorage use by arbitrary
external code cannot be prevented by a Dart library proof; do not claim OS custody.

### PATH-JOURNAL — public writer and readback reachability

`integration_test/support/m2_observer.dart:385-442` exposes the journal constructor,
public sink field, event(), record(), flags and irreversible valid invalidation.
A caller can access journal.sink.read/write directly. record accepts valid metadata,
starts _commit and returns before plugin completion. `_commit` at
`integration_test/support/m2_observer.dart:444-479` coalesces snapshots, awaits
sink.write and flush awaits the worker then reads the same sink. flush on a fresh
valid journal still attempts a read before invalidating mismatched/empty data.
Flush equality is post-write evidence, never prior-inspection/retention authority.
Single-journal serialization does not exclude a second journal or direct sink.
qualifies is hard-coded false; valid=false is evidence invalidation, not admission.

### PATH-OBSERVER — all observation-to-writer edges

`integration_test/support/m2_observer.dart:483-529` exposes the observer constructor,
public delegate/journal and start() -> two availability records -> journal._commit.
bind validates product owner shape and associates channel/fence; it does not
record, admit storage or prevent startup writes before binding. coordinationKey
forwards the product delegate identity, not a QA fixed-slot custody registry.
`integration_test/support/m2_observer.dart:537-582` observeState either binds a
unique candidate, invalidates a mismatched owner/fence, or records state.
`integration_test/support/m2_observer.dart:584-654` load/save first await the product
delegate; exceptions record failure and rethrow. Successful paths call
_observeLeases, which records load/write ack, and on exact-owner disappearance
records removal and history-unavailable. Thus start, state, load/save failure,
load/save success, removal and availability reach the same journal writer.
Owner/generation fences are not checked before the product delegate load/save.

The delegate's separate product persistence boundary is
`lib/core/hermes/setup/secure_hermes_detached_run_store.dart:10-55`, through
`lib/core/hermes/channel/hermes_detached_run_store.dart:74-84`. The channel receives
that interface. These product operations are not QA inspection reads; source
integrity here neither authorizes nor executes them. Refusal bootstrap must avoid
creating the app/channel/delegate graph, rather than merely suppressing metadata
records while allowing the real app to start. No product store migration is granted.

### PATH-TEST — existing public-API consumers

`test/tooling/m2_observer_test.dart:1-84` imports both QA libraries, implements
MemorySink and Delegate, and creates a journal/observer for every test setup.
`test/tooling/m2_observer_test.dart:255-299` adds fresh journal/observer callers
for foreign-owner and fence tests. These memory paths do not prove runtime custody.
`test/tooling/m2_observer_test.dart:555-600` mocks storage/preferences and pumps
the public M2ObserverApp with a memory journal; this is a caller-injection path.
`test/tooling/m2_observer_test.dart:603-640` directly constructs the secure sink
for malformed aliases and invalid-envelope refusal. It never tests a valid raw
write or direct read refusing for lack of authority. Those tests need migration,
not preservation of an unsafe constructor merely to keep tests compiling.

### PATH-ORACLE — private fake authority is not delivery

`test/tooling/m2_receipt_admission_test.dart:1-136` imports only observer support
plus Dart/test packages and defines private _Slot, _Authority and _Tuple.
`test/tooling/m2_receipt_admission_test.dart:270-347` releases a private _Writer
implementing the public M2Sink and supplies it to the public M2Journal. Those
checks guard the fake _Writer/_Custody, not raw M2SecureSink, public journal.sink,
M2ObserverApp or main. There is no runtime import of this test library. Test-only
entrypoint/package/debug fields and object identities cannot issue installed
rights. Public validator construction/envelope/aliases are metadata helpers with
no plugin I/O; they must remain distinguished from authority issuance.

## Named bypasses requiring future closure

### BYPASS-RAW — constructors and exposed sink

An importer can construct raw secure sink then read, write a valid envelope,
construct an arbitrary journal then record/flush, or use journal.sink directly.
A second generation/journal can address the same attempt slot without shared
custody. Malformed-envelope refusal does not discriminate this bypass. Make raw
sink construction and access library-private; remove the raw sink getter from
runtime journal reachability and route every read/write through registry-checked
released capability operations. No public factory may restore these paths.

### BYPASS-INJECTION — caller authority and observer startup

Caller flags, valid aliases, application_id/debug/source strings, a synthetic
M2Sink implementation, a fake writer, arbitrary M2Journal or provider override
must not select runtime storage/issuer or trigger main/app startup. The present
public app/observer constructors accept arbitrary journals. A guarded facade
alone is insufficient if app composition still accepts unregistered objects.
Runtime entry must require opaque private issuance-registry membership and default
to not_admitted/continuation_unavailable before graph construction. Fake-only
composition must have no secure factory, main selector, environment/build flag
or production provider escape hatch.

### BYPASS-IMPORT — library privacy and delivery

Dart privacy is per library. Both QA files and both test consumers are presently
independent libraries with public constructors. An export, part or public factory
added later can reopen access; source rules must resolve alias imports, package:wing
URIs, relative paths, export chains, conditional branches and part/part-of edges,
not only grep for unqualified constructor calls. Deliberately choose a private
support-library boundary for custody/raw sink, without exposing a factory that
accepts caller-owned authority/sink. A sealed type alone is not registry identity.
Packaging/component/plugin/install closure remains a separate unadmitted boundary.

## Smallest future executable no-bypass regression

This is a specified missing test, NOT executed here. One focused runtime-boundary
suite should test the actual guarded entry/composition and library surface, not
copy another _Custody model. No real plugin, device or credentials are needed.
Use a denied default runtime authority and fake-only side-effect spies inaccessible
from production. The regression needs the following inseparable observations:

### REG-DEFAULT — real default refusal before any I/O

Call the actual QA bootstrap/composition used by main with runtime issuance absent.
Assert sanitized terminal not_admitted/continuation_unavailable; raw sink/plugin
factory creations=0, writer releases=0, journal constructions=0, observer
constructions/start calls=0, channel/delegate creations=0, runApp calls=0,
inspection reads=0, journal readbacks=0, writes=0, deletes/enumerations=0 and
fallback launches=0. Assert immediately, after awaited refusal and after draining
scheduled callbacks with deterministic completers, not timers. Construction
counters matter: a zero final write count alone can hide latent startup work.
Do not execute the present main or mock a platform store and call that admission.
The present main would violate the construction/start invariants; it was not run.

### REG-INJECTION — same entry rejects every public alternative

Through that same entry, independently attempt caller-minted metadata/flags,
foreign/revoked or fake-only issued capability, raw/fake sink, arbitrary journal,
app/provider override, and a second facade for the same physical slot. APIs that
no longer accept these inputs must fail an isolated external-consumer compile
probe; remaining typed requests must refuse with unchanged zero counters.
A counterfeit that implements a permitted interface must fail registry identity,
not be accepted on type/equality alone. Hold read/retention in the admitted
fake-only composition and attempt premature startup/release plus competitor B;
no writer construction/start/write before exact retained acknowledgement. Revoke
at awaits; late completion cannot release or start runtime work. No secure factory
exists in this positive fake-only path, even when fake authority succeeds.

### REG-API — no external raw construction escape

An isolated temporary Dart consumer imports the actual QA public surface through
relative and resolved export paths and attempts raw sink construction/read/write,
raw journal sink access/construction, arbitrary app/observer journal injection and
fake authority selection. Expected analyzer compile refusals must name the
intended inaccessible member/type (not missing unrelated dependencies). The
allowed metadata/validator consumer must compile as a positive control. Resolve
all discovered imports/exports/parts and assert the only runtime creation path is
the guarded bootstrap; any new path fails the closure contract. This compile
negative plus executable counter test is the smallest honest no-bypass claim:
main-only counter assertions cannot close a public raw constructor.

### REG-POSITIVE — avoid a vacuous never-executed test

Reuse the admitted private test-only ordering oracle for its own diagnostic scope:
one inspection read, exact prior retention, explicit separate write release,
then exactly the released writer's first valid record reaches one fake write.
Use separate inspection/readback counters. Do not make that fake authority usable
by runtime main. The new boundary counters must be proven sensitive with isolated
mutations removing the bootstrap gate, reopening raw construction and accepting
a foreign writer; each must fail its intended invariant. This retains predecessor
ordering coverage while adding actual runtime refusal/API-closure coverage.

## Required future amendment and scope limits

Future authorized changes must include `integration_test/hermes_m2_observer_main.dart`
(guarded bootstrap and app composition), `integration_test/support/m2_observer.dart`
(private raw sink and journal capability boundary), the proposed
`integration_test/support/m2_receipt_admission.dart` (currently absent; deliberate
library privacy if approved), and `test/tooling/m2_receipt_admission_test.dart`
(actual boundary regression, not merely a fake model). Explicitly amend the earlier
four-file allowlist to also include `test/tooling/m2_observer_test.dart`: migrate
its setup/fresh constructors/widget injection/direct sink refusal tests while
preserving validator, coalescing, invalidation and delegate behavior checks.
No new test filename/API/signature is assumed as already available. No coordinator,
issuer, source/test/packaging edit or runtime activation is authorized by this card.
Default runtime continues to lack independent installed authority; a future
in-process source regression cannot authorize cross-process continuation.

## Executed artifact evidence and acceptance

Commands from repository root, captured with exact exits in
[execution receipts](../../.task-evidence/t_481b1474/execution.json):

    python3 .task-evidence/t_481b1474/check_integrity.py snapshot
    python3 .task-evidence/t_481b1474/check_integrity.py verify
    git diff --check -- docs/quality/2026-10-06-m2-runtime-caller-closure.md .task-evidence/t_481b1474

The [validation receipt](../../.task-evidence/t_481b1474/validation.json) checks
source fingerprints, discovered paths/directives, report citations/local links and
all named bypass/regression observations. In-memory isolated overrides demonstrate
rejection of source drift, removed bypass, removed regression, invalid citation,
missing local link and invalid anchor, then originals are verified again. These
are artifact-integrity tests, NOT Dart runtime enforcement. Snapshot fixes the
inspected baseline; verify never silently refreshes it.

Acceptance 1: PATH and BYPASS sections plus binding discovery map every present
local writer consumer and import/export/part surface within the stated bounds.
Acceptance 2: REG sections specify the smallest discriminating actual-boundary
refusal/compile-negative check and precise future caller/test migration amendment.
Acceptance 3: executed integrity/negative controls, hashes, citations, links and
scoped whitespace evidence; no unrelated Flutter suite rerun or physical QA run.

Retained predecessor [acceptance](../../.task-evidence/t_40dcd771/acceptance.json),
[binding](../../.task-evidence/t_40dcd771/binding.json) and
[final source receipt](../../.task-evidence/t_40dcd771/final.json) are hash checked
against current selected sources and oracle test. Their 18 fake-only passes are
carried forward, not newly executed or upgraded. The
[ordering follow-through](2026-10-06-m2-custody-ordering-oracle.md#qualification-limits-and-next-proof)
and [custody contract](2026-10-06-m2-custody-proof-review.md#complete-present-caller-closure)
remain governing prerequisites, not runtime delivery evidence.

Ceilings: continuation_unavailable, history_admission_unavailable and
authoritative_counts_unavailable. Android/storage/cross-process/live NOT_CHECKED;
secure plugin I/O, platform protection/durability, process death/relaunch,
installed authority, device/API/ABI, package/component/build/delivery, network,
credentials, inference/history/counts and zero live mutations NOT_CHECKED.
Only offline artifact tools on Linux were exercised. M2 unverified is preserved
through goals.py helper APIs; completing this documentation task is not milestone
qualification. A no-open-task ledger validation failure, if produced, is retained
honestly rather than inventing tasks or claiming M2 met. Ledger changes are not
included in the card's authored-artifact commit.

Questions: none. Defaults: no live, no secrets, no sudo, no implementation.
Native same-card review handoff is the final step of this card's goal; review
approval is not claimed here. No follow-up card or reviewer subagent is created.
