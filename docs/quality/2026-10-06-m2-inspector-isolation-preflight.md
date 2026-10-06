# M2 inspector isolation preflight

Card: `t_909a35ba`. Task: `DOC-M2-INSPECTOR-ISOLATION-PREFLIGHT`. Goal: M2.
Status: preflight delivered; enforcement NOT_ESTABLISHED; candidate NOT_ADMITTED.
F01/F02 UNAVAILABLE. Android/full M2 remain unverified.

## Scope and evidence ceiling

This assesses the [reviewed prerequisites](2026-10-06-m2-manifest-assessment-contract.md#reviewed-prerequisites-for-a-future-assessment),
[immutable input](2026-10-06-m2-manifest-assessment-contract.md#immutable-public-input-admission)
and [hard bounds](2026-10-06-m2-manifest-assessment-contract.md#isolation-and-explicit-hard-bounds),
not an APK. The [package provenance brief](2026-10-06-m2-package-provenance.md#exactly-one-smallest-separately-scoped-executable-proof-slice)
and [M2 exit evidence](../../ROADMAP.md#m2--leave-and-return-without-losing-ownership)
remain separate. The [runtime ADR](../adr/runtime-and-delivery.md#decision),
[security ADR](../adr/security-and-privacy.md#decision), [security policy](../../SECURITY.md)
and [threat model](../security/threat-model.md#trust-boundaries) govern this work.

Executed checks read only explicitly named public SDK/tool locations and public
kernel metadata. No PATH/environment discovery, private caches/state, APK lookup,
acquisition or inspection, inspector/JVM execution, sandbox activation, network,
provisioning, installs, sudo, builds, devices or production source/test edits.
Agent/Desktop/Conduit were excluded from discovery and remain untouched. Hermes
Agent remains domain authority; Wing Link gains no new compatibility operation.

The live [observer](../../integration_test/support/m2_observer.dart), lines 6–16
and 25–32, still refuses; [QA main](../../integration_test/hermes_m2_observer_main.dart),
lines 1–8, supplies no authority. Runtime remains `not_admitted`,
`continuation_unavailable`, `qualifies=false`, `authoritative_counts_unavailable`.
Metadata presence and document checks are not sandbox enforcement or APK facts.

## Executed public metadata observations

Exact allowlisted probes are in the [task helper](../../.task-evidence/t_909a35ba/check_preflight.py).
Its receipts use repository-relative argv, a sanitized cwd label and public-tool
labels, not resolved host paths, environment values or raw OS diagnostics.

| Check | Observed fact | Evidence ceiling |
| --- | --- | --- |
| Effective privilege and kernel | Worker is unprivileged; kernel release `7.0.0-31-generic`. | No namespace, seccomp or resource-control behavior exercised. |
| Named SDK locations | System SDK launcher is a regular file with executable bits and no set-ID bits; alternate named public location is absent. | Absence is only at the named location; no cache or wider SDK discovery. |
| SDK source metadata | `source.properties` declares revision `19.0`; launcher is 5763 bytes. Both observed SHA-256 values are retained. | Declared SDK revision is not an executed inspector version or reviewed distribution identity. |
| Launcher source | Classpath assignment at line 67 names `apkanalyzer-classpath.jar`; Java selection assignments at lines 73, 75, 84, 116. `JAVA_HOME`, `JAVA_OPTS`, `DEFAULT_JVM_OPTS`, `CLASSPATH` references exist. Named classpath JAR is regular. | Lexical wrapper facts only. No JAR traversal or JVM/native/library/configuration closure pin. |
| Java and isolation tools | System Java entry is an unresolved symlink. Bubblewrap and systemd-run entries are regular executable-bit files, without set-ID bits. | No symlink target, version, dependency identity, unit, namespace or tool invocation measured. |
| User namespaces | Public sysctls report unprivileged userns clone enabled (`1`) and max user namespaces `236328`; AppArmor unprivileged-userns restriction is `1`. | Permission is not demonstrated; AppArmor policy can restrict creation despite sysctl enablement. No policy bypass proposed. |
| Cgroup v2 | Public root controller list includes `memory`, `pids`, `cpu`; root `cgroup.kill` is absent at its named location. | No delegated child cgroup examined/created. Root absence does not prove a child lacks kill support. Effective delegation, write rights and limits remain UNAVAILABLE. |
| Immutable-input API | Python exposes `memfd_create`, but none of the six probed fcntl sealing symbols. | API visibility, not kernel seal enforcement. No memfd created, no seals applied; no numeric-constant fallback. |

[metadata.json](../../.task-evidence/t_909a35ba/metadata.json) and
[tool-metadata.json](../../.task-evidence/t_909a35ba/tool-metadata.json) retain these
observations. [probe-command.json](../../.task-evidence/t_909a35ba/probe-command.json)
and [closure-command.json](../../.task-evidence/t_909a35ba/closure-command.json)
record exit 0. A successful metadata probe means its read completed, not that the
assessed prerequisite passed. Unexpected metadata is suppressed, not interpreted.

## Full public SDK closure admission

A wrapper digest alone cannot pin this inspector. Observed wrapper and properties
fingerprints are measurements of public files, not independent approved pins.
The `latest` label is mutable even though no symlink was observed in its inspected
parent chain; never approve it solely by name. Approved execution requires all of:

1. Independent reviewed SDK provenance and exact distribution/version; immutable
   materialization identity; wrapper and every transitive JAR/classpath member.
2. Canonical fixed JVM executable, Java runtime modules/configuration, native
   libraries, dynamic loader and library resolution closure, including libraries
   loaded at runtime. A system Java symlink or wrapper classpath name is insufficient.
3. Bubblewrap/isolation supervisor executable, loader/library closure and reviewed
   seccomp policy; the parser and sanitizer are part of the trusted closure too.
4. An empty inherited environment and descriptor set; only reviewed fixed locale
   `C.UTF-8`, timezone `UTC`, sandbox HOME/TMPDIR and runtime locations. No host
   PATH, proxy, Java option injection, user configuration or caches. The wrapper's
   environment hooks must be made inert through fixed invocation/environment.
5. Closure size/digest verification before and after each operation; no host-writable
   alias to mounted tool bytes. Read-only binds alone do not prevent outside writers.
   Any drift refuses; no auto-update, alternate parser/tool or retry with relaxed flags.

These exact approved pins, independent provenance and measured transitive closure
are UNAVAILABLE. No invented JVM/SDK version, digest or closure completeness claim
is supplied. SDK availability does not authorize inspector execution.

## Candidate enforcement path and prerequisite map

Candidate only: unprivileged user/mount/PID/network/IPC namespaces (a pinned,
reviewed Bubblewrap adapter), a separately delegated cgroup v2 encompassing the
supervisor and all descendants before first exec, and an independently reviewed
sealed-input adapter. This is not an implemented or admitted adapter. systemd-run
presence does not prove user-service availability/delegation and is not a fallback.
If any required mechanism is unavailable, refuse the entire assessment.

| Contract bound | Concrete enforcement prerequisite | Current disposition |
| --- | --- | --- |
| No network/device/Agent or Wing Link IPC/private mounts | New namespaces with no usable interfaces/egress; deny network/IPC syscalls by reviewed seccomp, drop capabilities and enforce no-new-privileges; minimal allowlisted mount tree, no host devices, home/config, host sockets or writable host mounts. Close inherited FDs and stdin; never share host PID/proc or namespace handles. | Tool entry exists; namespace creation, LSM approval, seccomp and mount containment UNAVAILABLE. JVM compatibility must be proved under this exact denial policy, not by adding access exceptions. |
| 30 seconds each, 90 seconds across three commands, 120 seconds end-to-end | External supervisor with monotonic absolute deadlines, started before hashing and including setup, capture, parse, reap and cleanup; sequential fixed argv; kill on first deadline. A worker watchdog must remain schedulable and outside the tool's writable namespace. | No supervisor or timing enforcement exercised. Per-command timeout alone misses hashing/parsing and descendant cleanup. |
| 20 CPU seconds per invocation | Reviewed descendant-inclusive cumulative CPU budget. `RLIMIT_CPU` alone is per process; `cpu.max` is a rate, not a total CPU budget. `cpu.stat` polling detects usage but can overshoot; it is not accepted as exact hard-ceiling enforcement without separately reviewed accounting semantics that satisfy the unchanged contract. | Exact aggregate CPU enforcement prerequisite UNAVAILABLE; do not substitute rate limiting or quietly add tolerance. |
| 1073741824 aggregate memory bytes (1 GiB) | Delegated cgroup v2 `memory.max`, no unaccounted swap (`memory.swap.max=0`), all supervisor/tool/parser descendants and sealed-input memory charged to it before allocation; OOM/refusal monitoring. JVM heap flags or per-process address limits are insufficient. | Controllers visible, effective delegation/write rights/accounting UNAVAILABLE. |
| 32 processes/threads, no privilege escalation | Delegated `pids.max=32`, all children inside before exec, no migration escape; namespace containment, dropped capabilities, no-new-privileges and reviewed syscall policy. JVM threads count; cannot raise ceiling to accommodate startup. | pids controller visible; child enforcement and constrained JVM operation UNAVAILABLE. |
| 67108864 scratch bytes (64 MiB) | Isolated tmpfs with fixed size and separately reviewed inode bound; only scratch writable to tool, no host-backed writable mounts/caches. tmpfs charges must also fit aggregate memory. Result writer outside tool namespace, but inside accounted trusted worker boundary. | No mount or quota exercised; inode policy not supplied by predecessor, therefore requires review rather than an invented accepted limit. |
| 4096 stdout bytes for each small query; 1048576 for manifest; 16384 stderr each | Concurrent bounded pipe reads, count raw bytes before decoding/allocation; stop immediately on overflow on either pipe, kill all descendants; no raw persisted output. Nonempty stderr refuses even below its bound. | Capture/supervisor implementation UNAVAILABLE. Post-exit truncation and pipe deadlock are not enforcement. |
| UTF-8; 10000 elements, depth 64, 256 attributes/element; no DTD/entities/XInclude/resolution | Pinned version-specific streaming parser: reject unsafe XML constructs and non-UTF-8 before expansion; count limits incrementally; total input already bounded; no resource/URL resolvers. Parse package/debug tokens and cross-check XML under the predecessor's exact grammar. | Parser identity, grammar, malformed/ambiguous/expansion controls UNAVAILABLE; general-purpose XML defaults not accepted. |
| 65536 sanitized UTF-8 result bytes, 256 components, 256 ASCII bytes/name | Trusted serializer outside tool write namespace, count before append; allowlisted fields/enums, strict canonical expected-package namespace, sorted unique components. Overflow invalidates rather than truncates; raw diagnostics/manifest/paths never retained. | Sanitizer/component policy and result-writer isolation UNAVAILABLE. |
| Cancellation/limit breach, kill/reap/cleanup | PID-namespace supervision plus delegated `cgroup.kill` or equivalently reviewed descendant-kill mechanism; termination and `cgroup.events` populated=0 confirmation, reap adopted children, bounded teardown under total deadline. If confirmation fails: ISOLATION_FAILURE, no assessment. | Root kill absence is not child evidence; delegated kill, race/escape resistance and bounded cleanup UNAVAILABLE. A process-group kill alone misses escaped descendants. |

No limit is relaxed and no runtime operation is authorized by this map. Killing
only the direct JVM, moving processes into a cgroup after launch, accepting empty
stderr after truncation, or treating visible sysctls as successful isolation would
violate the contract. Equal before/after hashes alone cannot prove immutability.

## Immutable public input without artifact access

Expected independent APK digest, size and public provenance/custody owner are
UNAVAILABLE. No APK was named, found, opened, hashed, copied or assessed.

The future input prerequisite remains one nonsymlink regular public APK with
positive exact expected size, at most 268435456 bytes. Symlink-free parent-chain
and file identity checks need race-resistant descriptor-relative open/validation,
not a path check followed by a separate open. Stream-copy and hash within the
120 seconds total and memory budget; preserve source identity/size/digest checks
before/after copy and after subprocesses. A transient writer can evade endpoint
hashes: independently reviewed source custody must prevent mutation during copy.

Candidate freeze mechanism: private memfd snapshot, remove writable mappings,
apply and verify `F_SEAL_WRITE`, grow/shrink and seal-set locks before any tool
exec, expose only the sealed bytes read-only at fixed `/input/candidate.apk`,
and rehash after each operation. This is a proposed Linux mechanism, not a
Python implementation or observed kernel guarantee. Require no external writable
alias, prevent tool access to mutation/control handles and prove seal behavior on
public synthetic bytes. `chmod`, open descriptor, read-only bind, `F_SEAL_FUTURE_WRITE`
alone or matching final hashes do not satisfy freeze. If this exact path cannot
meet the approved SDK's file access needs and limits, refuse, not fall back to a
mutable file. Input allocation must be accounted alongside JVM and parser memory.

## Exactly one next proof slice

Proposed next slice, NOT permission to execute: implement and qualify only the
unprivileged isolation/immutable-input adapter on deterministic public synthetic
non-APK fixtures, without running apkanalyzer/JVM or accepting a candidate.
Independently review the named adapter/closure and exact cumulative CPU semantics
first. Include denied network/IPC/private mounts, environment/FD injection,
sealed-input mutation, child/thread and memory exhaustion, output overflow,
deadline/cancellation, detached descendants and cleanup failure controls. Each
must enforce the unchanged bounds or return UNAVAILABLE/ISOLATION_FAILURE, never
claim APK facts. No provisioning, sudo, downloads, APKs, builds/devices, secrets,
Agent/Wing Link activation or authority issuance is part of that proposal.

This is one bounded prerequisite qualification slice, not the earlier manifest
measurement slice. Missing delegation, LSM permission, seal support or an exact
CPU-budget mechanism stays an explicit unavailable result. Later manifest reading
requires separate artifact/provenance, complete SDK closure, parser and sanitizer
admission. Even passing synthetic controls would not prove Flutter debug mode,
compiled M2 target, native/plugin closure, signing, F03–F10 or installed custody.
Android/full M2 remain unverified and candidate remains NOT_ADMITTED.

## Verification and handoff

Executed from repository root:

    python3 .task-evidence/t_909a35ba/check_preflight.py probe
    python3 .task-evidence/t_909a35ba/check_preflight.py closure
    python3 .task-evidence/t_909a35ba/check_preflight.py snapshot
    python3 .task-evidence/t_909a35ba/check_preflight.py verify

[snapshot-command.json](../../.task-evidence/t_909a35ba/snapshot-command.json),
[source-snapshot.json](../../.task-evidence/t_909a35ba/source-snapshot.json),
[verify-command.json](../../.task-evidence/t_909a35ba/verify-command.json) and
[validation.json](../../.task-evidence/t_909a35ba/validation.json) bind the selected
source/predecessor receipt bytes, authored brief/helper and public metadata.
The checker verifies local links/anchors and every task-owned file's whitespace,
including new files. Its marker checks are lexical document integrity, not a
security policy proof, inspector test or parser/isolation regression suite.
The initial lexical check failed because a required phrase crossed a Markdown
line break. The helper now normalizes whitespace for marker checks only; exact
fingerprints remain byte-sensitive. Initial snapshot and failed command receipts
are retained separately, not relabeled as a pass.

[ledger.json](../../.task-evidence/t_909a35ba/ledger.json) retains exact helper-managed
task/evidence/render commands, scoped task readback and unrelated-object preservation.
M2 stays unverified through supported goals.load/dump even if goals.py auto-promotes
on document passes. A no-open-task validation diagnostic is a ledger-model gap,
not M2 success. Shared goals/TODO changes are excluded from the authored-only local
agent-branch commit; user work and predecessor evidence are preserved.
Native same-card review is this card's final step; approval is not claimed.

Questions: none. Defaults applied: preflight/refusal-only, no installs or runtime
rights. Public Linux metadata was read; no sandbox, APK or application platform
was exercised. F01/F02 UNAVAILABLE; Android/full M2 remain unverified.
