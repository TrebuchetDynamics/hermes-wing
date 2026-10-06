# M2 QA attempt/generation receipt handoff contract

Card: `t_d6c8aa4f`. Backlog: `DOC-M2-RECEIPT-HANDOFF-CONTRACT`.
Status: proposed contract only; adapter NOT_IMPLEMENTED and NOT_AUTHORIZED.
M2 remains unverified. Only offline Linux Python/Git checks are exercised.

## Acceptance and source binding

1. Define bounded typed admission and separate envelope validation, including
   shared-key ordering and immutable handoff identity.
2. Execute synthetic positive/refusal policy controls without platform access,
   storage writes, launch, fallback or qualification.
3. Bind citations, local links and inherited evidence to current source hashes.

The [delivery admission](2026-10-06-m2-qa-delivery-admission.md) and its
[approved review](../../.task-evidence/t_ccec142b/reviewer-round-1.md) are
prerequisites, not platform measurements. The checker compares every selected
predecessor input hash before inheriting its source-only conclusions, and compares
its three Dart blobs to approved commit `c141d8d727ed8a44168fc80674f05dce2cbf63aa`.
No predecessor Flutter or dependency-closure suite is rerun.

| Current seam | Consequence |
| --- | --- |
| `integration_test/hermes_m2_observer_main.dart:10-19` | Startup generates fresh attempt and generation aliases; no provisioned continuity input exists. |
| `integration_test/hermes_m2_observer_main.dart:30-54` | Observer installs the real channel/store, not a collector or coordinator. Ordinary transport must not be launched by receipt retrieval. |
| `integration_test/support/m2_observer.dart:36-73` | UUID-v4 aliases; one key `wing.qa.m2.metadata.v1.$attempt`; read returns unchecked bytes, write validates against the sink's generation. No enumeration/deletion API. |
| `integration_test/support/m2_observer.dart:89-129` | One envelope: 65536 UTF-8 bytes, 1–128 events, exact four top-level fields, schema 1, one attempt and one generation. |
| `integration_test/support/m2_observer.dart:200-293` | Strict metadata fields/types; no arbitrary strings; authoritative counts/ledger epoch/complete coverage refused. |
| `integration_test/support/m2_observer.dart:330-379` | History/canonical admission requires separate expectations; failed/unavailable observations cannot advance it. |
| `integration_test/support/m2_observer.dart:395-478` | Irreversible journal invalidation, bounded serialized snapshots, exact readback; qualifies always false. |
| `test/tooling/m2_observer_test.dart:603-640` | Inclusive 64 KiB boundary, extra envelope fields, foreign generation and arbitrary sink input refusals. |
| `test/tooling/m2_observer_test.dart:140-189` | Mixed attempts/generations, unexpected metadata and event overflow refuse. |

## Proposed typed boundary (not a public wire protocol)

Inputs are immutable in-process values, not URLs, command arguments, preferences,
QR/share payloads, native method messages or arbitrary maps. Unknown fields refuse.

- ReceiptRequest: version exactly 1; operation exactly `inspect`; attempt and
  currentGeneration required canonical lowercase UUID-v4 aliases (36 ASCII bytes).
  priorGeneration is either absent for a fresh attempt or one UUID-v4 distinct from
  currentGeneration for continuation. At most one prior generation; no lists,
  chains, timestamps, product identifiers, paths, keys or caller-selected target.
- AdmissionTicket: an opaque, ephemeral reference minted by a separately reviewed
  trusted admission authority, never constructible from caller booleans. It binds
  the exact request tuple and the independent candidate evidence described below.
  The authority checks freshness/revocation before the fixed read and before return.
  Ticket equality is bound to immutable values, not mutable caller objects.
- Current envelope is optional during the read-before-write stage, required for a
  completed two-envelope diagnostic. Each provided envelope is independently bounded
  by the existing validator limits; total prior plus current encoded bytes <=131072
  and events <=256. No truncation, sampling, repair or partial success.
- Result is either admitted metadata-only diagnostic or a bounded refusal enum:
  `invalid_input`, `not_admitted`, `changed_handoff`, `missing_prior`,
  `unexpected_prior`, `invalid_envelope`, `continuation_unavailable`.
  No raw payload/error in refusal output. History/counting stay unavailable;
  qualification is false in every result, including successful diagnostics.

Only random aliases, allowlisted synthetic metadata and reviewed public artifact
fingerprints may be carried. No real origins, profile/session/run/message IDs,
credentials, endpoints, serial/PID, alias maps, host paths, provider values,
transcripts, ciphertext/database dumps or hashes derived from private values.
A structurally valid digest is not permission to hash private data.

## Independent admission, distinct from caller assertions

Admission must independently establish the exact isolated QA package
`com.trebuchetdynamics.hermes.wing.qa`, debug mode, and compiled entrypoint
`integration_test/hermes_m2_observer_main.dart`, binding source/artifact identity,
merged components/plugin closure and the disposable target/storage instance.
The predecessor delivery table describes configuration only; none of these actual
measurements is available here. A QA-looking application_id inside an envelope,
filename, isolation flag or successful fake read does not constitute admission.

Retrieval permission is separate from package admission and from write permission.
It authorizes exactly one bounded metadata read for the admitted attempt from
that QA storage instance through M2Sink.read(), not private storage access generally.
The adapter derives the fixed key internally; callers supply no storage key/path.
There is no readAll, enumeration, adb/run-as, logcat, clipboard, share, remote
endpoint, shell, launch, fallback, deletion or product persistence-slot access.
Absent permission or evidence refuses before even the fixed read. A malformed
request or changed tuple similarly performs no read.

The private authority must register an immutable tuple (attempt, current generation,
optional prior generation, candidate/target/storage evidence identity) before use.
Reusing the same admission with any changed tuple/evidence, swapped generation or
changed payload snapshot refuses. Exact repeated inspection may return the retained
immutable diagnostic only while admission remains valid; it must not read a
potentially overwritten key again. No new ticket may silently reinterpret an old
attempt. Registration is a future private coordinator prerequisite, not state
implemented by this card or authority supplied by a caller flag.

## Fixed-key ordering and retention

M2SecureSink has only one slot per attempt. A continuation using that attempt can
replace the prior generation's only envelope. Sequence is therefore mandatory:

1. Freeze request and independently admit identity/retrieval; fence concurrent QA
   writers for this same attempt/storage. The current entrypoint has no such fence.
2. Read that fixed slot once, before constructing/starting any journal or observer
   that can write it. Validate prior bytes against (attempt, priorGeneration), never
   currentGeneration. Copy the complete validated bytes into bounded private memory.
3. If current bytes are independently supplied, freeze and validate them separately
   against (attempt, currentGeneration). Never concatenate events, rewrite generation,
   infer priorGeneration from untrusted bytes or reuse validator admission state.
   Each generation starts its own sequence at 1 and its own monotonic elapsed clock.
4. Return sanitized diagnostic only. Inspection NEVER writes. A later separately
   authorized current-generation write may proceed only after the private coordinator
   has acknowledged retention of the full prior snapshot under the unchanged tuple.
   In-memory retention is not crash durability or public receipt export permission.

Fresh case: priorGeneration absent and fixed read returns null; optional current
bytes validate against currentGeneration. Existing bytes are unexpected_prior, even
if they match currentGeneration; this is not permission to overwrite a reused attempt.
Continuation: priorGeneration present requires non-null prior bytes. Missing,
truncated or foreign bytes refuse without repair or a fresh-attempt fallback.
Missing current bytes permits only a prior-only diagnostic, not a completed pair.

Without independently admitted exclusive ordering and retention, actual continuation
is `continuation_unavailable`: skip it. The smallest separate prerequisite is a
reviewed private coordinator provisioning the immutable tuple, fencing writes and
retaining the prior snapshot before release, plus explicitly admitted collection
transport if cross-process use is intended. No extra storage keys, persistent alias
map, validator weakening or unreviewed native transport may substitute for it.
Same-attempt alias equality does not witness old PID absence/new process or continuity.

## Refusal matrix and future tests

| Control | Observable result |
| --- | --- |
| Independently admitted same attempt, distinct generations, two valid envelopes | Validate each against its own generation; diagnostic only, qualifies false. |
| Fresh attempt, absent prior and empty fixed slot | Fresh diagnostic only; no write. |
| Wrong QA package/target, caller-asserted evidence, absent retrieval permission | not_admitted before read. |
| Changed request, admission identity, payload snapshot or swapped generations | changed_handoff; no second read, no replacement of retained bytes. |
| Prior declared but null bytes; no prior declared but slot occupied | missing_prior / unexpected_prior. |
| Foreign attempt or envelope generation, merged generations | invalid_envelope. |
| Corrupt/truncated JSON, extra/secret field, empty/129 events, >65536 UTF-8 bytes, invalid aliases/types/sequence/time | invalid_envelope; no partial diagnostic. |
| Missing exclusive ordering or retention | continuation_unavailable before read/write. |
| Synthetic success, unavailable history/counting, caller OS flags | Still no qualification or platform claim. |

The card-local oracle deliberately models only this proposed admission policy and
small availability envelopes. It does NOT execute Dart M2Validator, Flutter storage,
a shipped adapter or an OS witness. Future adapter tests must call M2Validator
separately for both generations, exercise fake sink call counts/races and all existing
metadata constraints, and keep history/counting refusal intact. validateEnvelope
creates a validator without history expectations: this proposal does not grant
history admission or change that current behavior.

## Exact future write allowlist

A later explicitly authorized adapter card may propose only:

- `integration_test/support/m2_observer.dart`
- `integration_test/hermes_m2_observer_main.dart`
- `integration_test/support/m2_receipt_admission.dart` (new)
- `test/tooling/m2_receipt_admission_test.dart` (new)
- that future card's `.task-evidence/<card-id>/` directory

This is a proposal, not authorization. Production/transport/coordinator activation,
Android/Gradle/manifests/native channels/runners, Agent/Desktop/Conduit, other profiles
and arbitrary storage access remain excluded. If independent admission cannot be
supplied within that scope, keep it unavailable and specify a separate prerequisite.

## Executed evidence and coverage ceiling

Run from repository root:

    python3 .task-evidence/t_d6c8aa4f/check_contract.py snapshot
    python3 .task-evidence/t_d6c8aa4f/check_contract.py verify
    git diff --check -- docs/quality/2026-10-06-m2-receipt-handoff-contract.md .task-evidence/t_d6c8aa4f

[validation.json](../../.task-evidence/t_d6c8aa4f/validation.json) retains exact
commands/exits, computed counts, selected source hashes and scoped tracked/untracked
whitespace results. Acceptance 1 maps to source table, typed contract and ordering;
acceptance 2 to refusal matrix and synthetic oracle; acceptance 3 to integrity,
link/citation and whitespace receipts. Native review is the final worker handoff;
approval is not claimed here. No implementation files changed.

NOT_CHECKED: APK/build/entrypoint/digest, merged package/plugins, actual secure
storage/read/retrieval/protection/durability, target/device/API/ABI, OS/PID/process
death/relaunch, notifications, live Agent/run/history, credentials/auth revocation,
network/inference, authoritative credential-wide counts and zero live mutations.
Only offline tools on Linux were exercised. M2 is not promoted by these checks.
Questions: none. Defaults retained: no live execution, secrets, sudo or packaging edits.
