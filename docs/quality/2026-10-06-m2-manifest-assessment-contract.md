# M2 partial-F01 offline manifest assessment contract

Card: `t_bcab1f7e`. Task: `DOC-M2-MANIFEST-ASSESSMENT-CONTRACT`. Goal: M2.
Status: PROPOSED source-only contract; candidate NOT_ADMITTED.
F01/F02 UNAVAILABLE. Android/full M2 remain unverified.

## Scope and evidence ceiling

This refines the [predecessor's smallest proof slice](2026-10-06-m2-package-provenance.md#exactly-one-smallest-separately-scoped-executable-proof-slice)
and [issuer dossier F01/F02](2026-10-06-m2-issuer-evidence-contract.md#bounded-candidate-admission-dossier).
It is not an inspector implementation or permission to execute one. Review approves
only this document's boundedness. [M2 exit evidence](../../ROADMAP.md#m2--leave-and-return-without-losing-ownership)
still requires Android death/relaunch, canonical history and zero duplicate sends.
The [runtime ADR](../adr/runtime-and-delivery.md#decision),
[security ADR](../adr/security-and-privacy.md#decision),
[security policy](../../SECURITY.md) and
[threat model](../security/threat-model.md#trust-boundaries) remain binding.
Hermes Agent owns domain state; Wing Link supplies no proxy, authority or counts.
Agent/Desktop/Conduit are excluded from source discovery and remain unmodified.

No APK acquisition, lookup, extraction or inspection, SDK invocation, production
implementation/tests, builds, installs, devices, private storage, credentials,
signing, authority issuance, runtime activation or live traffic occurred here.
No downloaded tool, shell bridge, alternate parser or fallback is authorized.
Current runtime remains `not_admitted`, `continuation_unavailable`,
`qualifies=false`, `authoritative_counts_unavailable`.

## Source facts, not measured package facts

[Gradle](../../android/app/build.gradle.kts), lines 37–45 and 80–94, configures
`com.trebuchetdynamics.hermes.wing`; isolated debug conditionally adds `.qa`.
Release can use debug signing: signature, filename and environment labels do not
prove Flutter debug mode. [QA main](../../integration_test/hermes_m2_observer_main.dart),
lines 1–8, calls only no-input bootstrap; [observer](../../integration_test/support/m2_observer.dart),
lines 1–33, refuses before launch. These are source facts, not compiled attribution.
The predecessor's native/plugin closure gaps remain; no inspection result is inherited.

## Reviewed prerequisites for a future assessment

A separately scoped future task must approve all of the following before opening
an APK or invoking a tool. Missing prerequisites yield UNAVAILABLE, never discovery
in build caches, devices, user storage or network locations.

1. One explicitly named public QA APK, its public provenance record and a fresh
   task-owned output area. An independent provenance reviewer supplies the expected
   SHA-256 (exactly 64 lowercase hexadecimal characters) and exact byte size, tied
   to that APK/build identity. Record public provenance revision and custody owner.
   A digest computed by the assessor from the candidate is not an independent
   expected digest; sidecar proximity, filename or caller assertion is insufficient.
   This check establishes consistency with reviewed public provenance, not signing.
2. An approved fixed local SDK inspector distribution: exact version, canonical
   executable and SHA-256, plus launcher/JVM/libraries/configuration identities.
   Pin the full transitive execution closure, not merely the `apkanalyzer` wrapper.
   No PATH resolution, caller-selected executable/flags, auto-update, provisioning,
   downloads or version probe inside assessment. Recheck tool closure before/after.
   Actual version/digests are UNAVAILABLE here; do not substitute invented pins.
3. An independently reviewed isolation adapter that enforces the limits below on
   that exact tool closure. Verify enforcement on disposable non-APK inputs before
   artifact assessment. Absent enforcement, unavailable sandbox, tool drift or
   unsupported output grammar refuses; a timeout flag alone is not isolation.
4. A version-specific strict output grammar, XML/component policy and sanitizer,
   with separately reviewed malformed/ambiguous/oversized/changed-input controls.
   Review is required before parsing untrusted APK data. No parser is supplied here.

## Immutable public input admission

The future adapter opens only the approved public input, with no symlink in its
path or parent chain, no FIFO/device/socket/directory, and no redirected URL.
Require a regular single APK of exact expected size, positive and at most
268435456 bytes (256 MiB). Reject split sets, duplicates and unsolicited inputs.
Bounded streaming hash must equal the independently expected digest before tool
execution. Freeze the approved bytes in a task-owned read-only snapshot exposed
at the fixed sandbox path `/input/candidate.apk`. Verify snapshot size/digest too.
Do not pass a caller-controlled host path to the inspector.

Prevent writers for the entire assessment: an open descriptor, chmod or read-only
bind alone cannot freeze an inode still writable elsewhere. Require a reviewed
immutable copy/snapshot mechanism with no external writable alias. Retain source
identity/size/digest checks before and after copying and after all subprocesses;
rehash the inspected snapshot after each operation. Replacement, truncation,
growth, metadata identity drift or digest drift invalidates all partial results.
If immutability cannot be established, refuse rather than accept equal endpoints
as proof against transient mutation. No repair, refresh or automatic retry.

## Fixed inspector identity and argv

Inside the reviewed sandbox the pinned executable is mounted read-only at
`/tool/bin/apkanalyzer`; its approved runtime closure is also read-only. These
are proposed fixed sandbox labels, not host paths or claims of available tools.
Cwd is the fresh empty sandbox `/work`; stdin is closed. Only these argv vectors,
executed sequentially against the same immutable snapshot, are allowed:

    ["/tool/bin/apkanalyzer", "manifest", "application-id", "/input/candidate.apk"]
    ["/tool/bin/apkanalyzer", "manifest", "debuggable", "/input/candidate.apk"]
    ["/tool/bin/apkanalyzer", "manifest", "print", "/input/candidate.apk"]

No shell, additional command, caller-selected option, install, launch, signing,
archive extraction to host disk or execution of APK contents is allowed. Manifest
reading internally decompresses data; this does not authorize general extraction.
The future task must explicitly authorize that bounded internal read, unlike this
source-only card. Do not invoke an existing release gate to obtain these facts.

## Isolation and explicit hard bounds

These are proposed conservative ceilings, not measured tool requirements. Do not
relax them at runtime; exceeding them refuses and needs separate policy review.

| Resource | Required enforcement |
| --- | --- |
| Authority | Unprivileged isolated worker; no network interfaces/egress, device access, IPC to Agent/Wing Link, home/config/credential mounts, inherited file descriptors or host write mounts |
| Environment | Cleared environment; only reviewed fixed locale `C.UTF-8`, timezone `UTC`, sandbox HOME/TMPDIR and pinned runtime locations; no proxies, tokens, JVM option injection or host search paths |
| Time | 30 seconds wall time per invocation, 90 seconds for the three invocations, 120 seconds total including hashing/parsing; 20 CPU seconds per invocation; monotonic deadlines |
| Memory/processes | 1073741824 bytes (1 GiB) aggregate memory for worker/tool descendants; at most 32 processes/threads in the sandbox; no privilege escalation |
| Scratch | At most 67108864 bytes (64 MiB) sandbox-only tmpfs; no retained tool caches; public input/tool read-only; worker-owned result writer outside the tool's writable namespace |
| Stdout/stderr | Application ID and debug query each at most 4096 stdout bytes; manifest print at most 1048576 stdout bytes; stderr at most 16384 bytes per command; enforce during capture, not after allocation |
| Manifest parsing | UTF-8 only; no DTD, external entities, XInclude, network/resource resolution; at most 10000 XML elements, depth 64 and 256 attributes per element; bounded streaming parser |
| Sanitized result | At most 65536 UTF-8 bytes; at most 256 component records, each name at most 256 ASCII bytes; overflow invalidates, never truncates to success |

On timeout, limit breach, signal or cancellation kill/reap the entire sandbox
process group and descendants, discard partial results and perform bounded cleanup.
If termination cannot be confirmed, report isolation failure and no assessment.
Closed network and read-only mounts are enforced OS properties, not promises from
the APK or inspector. Cleanup retains only allowlisted sanitized records, never
raw manifest/stdout/stderr, arbitrary binary strings, host paths or APK bytes.

## Sanitized result and refusal matrix

After exit 0 with empty stderr for all commands, strictly parse one application
ID and one literal `true`/`false` token, permitting only a single trailing LF/CRLF.
No banner, whitespace normalization, extra line, duplicate value or inferred default.
Manifest print must have exactly one manifest root and matching package, exactly
one application and explicit resolved `android:debuggable="true"`. Missing or
unresolved debug state is unknown, not false or true. Contradictory query/XML
facts refuse. Version-specific representation differences require prior grammar
review, never a permissive fallback during assessment.

Retain only reviewed public APK/tool/contract digests, expected/measured sizes,
fixed argv, sanitized cwd label, bounded exits/durations and enums. Package may
be emitted only as the exact expected `com.trebuchetdynamics.hermes.wing.qa` or
an absent/other/ambiguous enum; never emit arbitrary rejected package text.
Component inventory is sorted and unique, names canonicalized relative to that
package, restricted to its ASCII namespace, with allowlisted component kinds and
explicit exported true/false/unknown state. Foreign/resource/placeholder names or
unreviewed attributes invalidate the inventory; never silently omit them. Retain
no labels, URIs, intent payloads, metadata values, resource strings or paths.
The bounded inventory describes declarations only, not DEX/plugin behavior or
complete closure. Public digests require explicit provenance; never hash private
values as a redaction substitute. No raw parser diagnostics in receipts.

| Condition | Assessment classification | Candidate result |
| --- | --- | --- |
| Missing approved APK, independent digest, inspector pins, isolation or grammar | UNAVAILABLE / prerequisite_missing; nothing measured | NOT_ADMITTED |
| Wrong/product/other-suffix package parsed unambiguously | MEASURED_REJECTION / package_mismatch; rejected value suppressed | NOT_ADMITTED |
| Absent package in otherwise valid parsed manifest | MEASURED_REJECTION / package_absent | NOT_ADMITTED |
| Debug flag false or explicitly unresolved/absent in otherwise valid manifest | MEASURED_REJECTION / debug_false or debug_unknown | NOT_ADMITTED |
| Malformed XML/UTF-8/token, ambiguous/duplicate/banner output, contradictory commands | PARSER_FAILURE / malformed, ambiguous or inconsistent; no reliable fact inferred | NOT_ADMITTED |
| Input size/digest/type mismatch, changed input or immutable custody not established | INPUT_REFUSAL / identity_mismatch, changed_input or custody_unavailable; invalidate all results | NOT_ADMITTED |
| Nonzero tool exit, nonempty stderr, signal, timeout, output/memory/process/scratch/parser bound | INSPECTOR_FAILURE / exit, diagnostic, cancelled or limit; no measured rejection inferred | NOT_ADMITTED |
| Tool closure changed, forbidden access or cleanup/termination unconfirmed | ISOLATION_FAILURE / tool_drift or containment; no assessment | NOT_ADMITTED |
| All bounded checks pass for exact QA package and explicit true debug flag | MANIFEST_FACTS_ONLY; partial F01 observations, not admission | NOT_ADMITTED |

Parser failure means measurement could not be interpreted reliably; measured
rejection means valid bounded evidence contradicts a required fact. Never turn
inspector/parser failures into a measured package claim, nor missing evidence into
acceptance. Stop on first refusal, retain no partial-success inventory, and never
retry with a different APK, tool, grammar, flags or relaxed limits.

Even MANIFEST_FACTS_ONLY proves neither Flutter debug build mode, compiled M2
target, full Dart/native/plugin dependency closure nor absence of native side
effects. Full F01/F02 remain UNAVAILABLE; F03–F10, signing, artifact/platform gates
and authority/counts remain NOT_CHECKED. Android/full M2 remain unverified.
No result grants install, launch, storage read/write, custody or runtime rights.

## Executable document-integrity evidence only

From repository root, execute the task-local lexical helper:

    python3 .task-evidence/t_bcab1f7e/check_contract.py snapshot
    python3 .task-evidence/t_bcab1f7e/check_contract.py verify
    python3 .task-evidence/t_bcab1f7e/check_contract.py negative

[source-snapshot.json](../../.task-evidence/t_bcab1f7e/source-snapshot.json)
binds exact source/contract/helper bytes, checkout HEAD/index identity and initial
selection comparisons. [validation.json](../../.task-evidence/t_bcab1f7e/validation.json)
records source-fingerprint, local-link/anchor, required lexical markers and
all-authored-file whitespace checks. [negative-command.json](../../.task-evidence/t_bcab1f7e/negative-command.json)
retains a subprocess refusal of an isolated altered contract copy without touching
source. Exact cwd/argv/exits are retained for each command. These are document
checks only, not tests of an inspector, sandbox, XML parser, APK or Android.

[ledger.json](../../.task-evidence/t_bcab1f7e/ledger.json) records named task/evidence/
render operations through goals.py, supported load/dump preservation of M2
unverified and unrelated-object readback. Shared goals/TODO files are not wholly
owned and are excluded from the authored-only local agent-branch commit. The
helper's possible no-open-task diagnostic is a ledger-model gap, not M2 acceptance.
Native same-card review is the final step of this card; approval follows handoff.
Questions: none. Defaults applied: source-only/refusal-only; no platform exercised.
