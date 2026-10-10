# Hermes Wing test plan

Status: verification strategy, not an execution receipt.
[Product requirements](product/prd.md) own product acceptance. This plan owns
verification methods. The [evidence matrix](quality/evidence-matrix.md) records
qualification; individual receipts must identify the source, target and limits.

## Scope and environments

Test the Flutter client and Wing Link without modifying Hermes Agent.
Use deterministic, redacted fakes for unit, widget and browser regressions.
Exclude upstream reference clones from Wing formatting, test scope and builds.

- Flutter unit/widget tests exercise shared behavior and provider overrides.
  They do not establish native plugin, screen-reader or physical-device behavior.
- Chromium tests use the compiled `lib/main_e2e.dart` target and deterministic
  fixture. Fixture generation is not actual provider inference.
- Native integration tests require platform tooling, isolated owned preferences
  and a real app launch. Widget remount is not process relaunch.
- Live Agent/provider tests need an approved isolated target, supported private
  authentication, exact grants and consent for network use and bounded mutations.
  Do not use personal credentials or provision a target to bypass an admission gate.
- Physical microphone, speech, accessibility and service/release checks require
  matching target receipts. Compilation is not runtime qualification.

## Risk-based scenarios

| Area | Observable expected outcome | Existing check or owner |
| --- | --- | --- |
| Connection and authorization | Invalid/revoked authority is rejected; unsupported and failed optional resources are not presented as empty supported data. | `test/core/hermes/`; [readiness audit](runbooks/hermes-readiness-audit.md) |
| Profile/session ownership | A late old-owner result cannot change the replacement profile, session, draft or history. An off-page remembered session is restored by identity, not inventory position. | `test/features/hermes_chat/gateways/`; `test/features/hermes_chat/screens/`; [daily-use matrix](plans/2026-10-03-desktop-daily-workflow.md#acceptance-matrix) |
| Streaming and reconciliation | History/run readback resolves missing or interrupted delivery; reconnect produces no implicit resend. Unknown outcomes stay fenced until reconciliation. | `test/core/hermes/`; [platform smoke](runbooks/hermes-platform-smoke.md) |
| Approval and Stop | Responses remain correlated to the actual request/run. Stale/repeated actions cannot answer a replacement request. Stop needs an authoritative terminal outcome. | [daily-use matrix](plans/2026-10-03-desktop-daily-workflow.md#acceptance-matrix); `playwright/tests/regression/desktop-daily-workflow.spec.mjs` |
| Session/queue mutation | A confirmation acts on its original owner and displayed object, not a replacement session or mutable row index. | [mutation runbook](runbooks/chat-session-mutation-intent.md); [queue runbook](runbooks/chat-queued-follow-up-intent.md) |
| Clipboard and preferences | Success is reported only after clipboard settlement; rejection is contained. Same-store settled pin commits preserve the latest deliberate choice without automatic retry. | [clipboard runbook](runbooks/chat-transcript-copy-outcomes.md); [pin-order runbook](runbooks/chat-session-pin-write-order.md) |
| Management security | Grants, revisions, local approvals and idempotency bind the exact device/resource/payload. Changed replay, revoked roots and symlink escape fail closed. | `wing_link/internal/`; [threat model](security/threat-model.md) |
| Retired OmniRoute integration | Former CLI flag/command, discovery route/capability and special profile setup are unavailable without installer/network/service actions; no bundled npm assets or release component remain. Generic Agent catalog entries and historical audit data remain valid. | `wing_link/internal/app/omniroute_retirement_test.go`; `wing_link/internal/protocol/retirement_test.go`; `test/tooling/omniroute_retirement_test.mjs`; `test/features/profiles/profile_catalog_test.dart` |
| Accessibility and adaptation | Keyboard-only operation, focus, readable text, large text and reduced motion remain usable across wide and compact layouts. No action requires sound, color, speech or canvas alone. | `test/shared/`; `test/features/`; [daily-use matrix](plans/2026-10-03-desktop-daily-workflow.md#acceptance-matrix) |
| Release and recovery | Candidate artifacts match their digests and required signatures; activation/recovery evidence belongs to the actual named platform. | [alpha release runbook](runbooks/release-alpha.md); [evidence matrix](quality/evidence-matrix.md) |

Existing test directories are coverage entry points, not proof that every scenario
is automated or passing. Inspect the nearest tests and receipts before advancing
a claim. The daily-use matrix defines more specific failure and boundary cases.

## Developer gate

From the repository root, use Flutter 3.44.2, Node.js 22 and Go 1.26 for Wing Link.
Resolve dependencies as described in [Contributing](../CONTRIBUTING.md).
Run focused tests while iterating, then checks proportional to the changed boundary.
The complete existing gate is owned by [Contributing](../CONTRIBUTING.md#required-checks).

For browser behavior, build the deterministic target before Playwright:

```bash
flutter build web --release -t lib/main_e2e.dart
npm run web:e2e
```

Do not run concurrent builds against the same output tree. Inspect fixture and
launcher arguments before a focused browser/native run. The
[native daily-use plan](plans/2026-10-03-desktop-daily-workflow.md#ordered-bounded-work)
requires fresh platform metadata and ownership checks before its launcher.

Documentation-only changes use `git diff --check` and affected local-link,
anchor, command and meaning checks. Do not launch a release, restart a service,
install packages or make destructive requests to validate documentation.

## Acceptance records and gaps

For each executed check, record the exact command, exit status, parsed result
counts where available, source identity, target and log/receipt references.
Separate passed, failed, not run and blocked checks. A receipt from a predecessor
snapshot does not prove a later dirty tree passes.

The Desktop-first daily workflow remains unaccepted where the
[parity ledger](product/hermes-desktop-parity.md) and
[restoration admission review](quality/2026-10-04-autogoal-restoration-admission-review.md)
withhold exact provider/model restoration or native/live admission. Focused Chat
repairs do not close those gates. The bounded global loaded-session slice is
independently approved; see its [runbook](runbooks/global-session-access.md).
Its retained shell fingerprint differs from the current sidebar. Historical
approval does not qualify the changed presentation. The later
[shell redesign receipt](runbooks/desktop-shell-reference-fidelity.md) records
57 focused widget passes and two compiled Chromium journeys, including global
Open/New. Its four final source fingerprints match the inspected snapshot, but
its manifest does not bind every global-session caller/test/browser input.
The receipt's later [P1 correction](runbooks/desktop-shell-reference-fidelity.md#independent-review-p1-correction)
fixes a focus outline hidden by an opaque Ink overlay. Style assertions alone
missed this defect; the augmented regression checks rendered edge pixels with
simultaneous hover and focus in both themes. Retained `focus-fix-tests.log` and
`focus-fix-browser-tests.log` record 57 widget passes and two Chromium passes.
These are executor checks, not independent finish approval or a full-suite pass.
The [fresh current-source receipt](quality/2026-10-06-global-sessions-current-check.md)
binds 521 copied inputs and a 195-file local dependency closure at review. Its command
receipt records 44 shell-widget passes, nine caller/lifetime passes, a fresh web
build and one deterministic Chromium Open/New pass, all exit 0. Fresh execution
replaces incomplete historical attribution; this documentation pass did not rerun
those checks. The [independent review receipt](../.task-evidence/t_d06ef06d/review-run/review-validation.json)
records approved bounded acceptance and independent repetition of the same checks.
All 31 executor and 27 review integrity entries remain intact. The documentation
recheck found fifteen changed inputs among the 521 recorded source fingerprints.
They include shared recovery code, channel tests and restoration/recreation tests.
The ledger preserves the completed task and bounded
review-snapshot acceptance; it does not qualify these later recovery/Stop edits.
DOC-M2-AMBIGUOUS-404 and DOC-M2-HISTORY-IDENTITY are done for their bounded repairs.
DOC-M2-HISTORY-ADMISSION is done for its bounded repair; the
[independent review verdict](../.task-evidence/t_4e4a4f7d/review-414.json) approves
that slice. DOC-M2-POST-REPAIR-CALLERS is done for bounded current-source
execution. The [post-repair receipt](quality/2026-10-06-m2-post-repair-callers.md)
records 85 focused passes, clean analysis/formatting, a fresh release build and
one compiled Chromium Open/New journey. The documentation recheck matches 518
of its 519 source inputs. `hermes_chat_death_completion_recovery_test.dart` has
changed since that receipt; the pass does not qualify this later test revision.
Independent final approval remains unverified. These deterministic checks do not
qualify M2. The delivered
[credential-denial oracle](quality/2026-10-06-m2-credential-denial-oracle.md)
records two app-level cases, 60 nearest passes and four selected channel passes.
All 428 recorded lib/test fingerprints match this snapshot. HTTP 401 denial and
public Retry retain the original lease and remembered owner. Later explicit
authority restoration admits canonical history before settlement, with zero
fixture recovery mutations. These are inspected receipts, not new test runs or
a final independent approval verdict. The later
[HTTP 403 oracle receipt](quality/2026-10-06-m2-forbidden-recovery-oracle.md)
records three app-level cases and 60 nearest passes. All 428 recorded lib/test
fingerprints match the inspected snapshot. Resource-read denial and public Retry
retain exact ownership; later explicit authority recovery admits canonical history
before settlement without fixture mutation replay. The ledger records this bounded
execution task done. The later [independent review execution receipt](../.task-evidence/t_b00feca2/review-440-tests.json)
records 63 passing cases and clean analysis. Its import-closure receipt matches
151 local dependencies and 443 analyzed files in this snapshot. This pass inspected
those receipts; it did not rerun product checks. Independent final approval remains
unverified. The delivered
[bootstrap HTTP 401 control](quality/2026-10-06-m2-bootstrap-denial-oracle.md)
records four app-level cases, 60 nearest passes and clean analysis. All 428
lib/test fingerprints, 151 local closure inputs and 443 analyzed files match
this snapshot. Required-capabilities denial and public Retry retain the exact
lease and remembered owner without mutation attempts. Explicit authority recovery
admits canonical history before settlement. This is inspected execution, not a
new product run or independent final approval. The delivered
[bootstrap HTTP 403 control](quality/2026-10-06-m2-bootstrap-forbidden-oracle.md)
records five app-level controls and 65 total passes with the nearest targets.
Its 151 local closure inputs and 443 analyzed files match the inspected snapshot.
Required-capabilities denial and public Retry retain byte-identical ownership and
remembered selection; original-authority recovery hydrates canonical history
before settlement without fixture mutation replay. This pass inspected receipts,
not a new product run or final independent approval. Synthetic denial does not
prove live expiry/revocation, Android process death or authoritative live counts.
Native desktop, live generation, full suites and full session-modal parity remain
unqualified.

The [keyboard follow-through](quality/flutter-keyboard-follow-through.md) records
an earlier failed full-suite run and later approved focused repair separately.
Passing focused checks do not establish a new full-suite result.
The later repository-root `npm run test` log records 3,386 passes and three
shell failures: two palette/selection assertions in
`test/shared/widgets/app_shell_reference_fidelity_test.dart` and a removed-brand
assertion in `test/shared/widgets/app_shell_test.dart`. See the
[retained log](../.task-evidence/repo-docs-npm-test.log) and existing
[DOC-GLOBAL-SESSIONS-CURRENT-CHECK](../TODO.md#now--next) follow-through.
This is a separate failed run, not the isolated mirror's incomplete attempt.
It does not establish a session-authority defect. Attribute the source snapshot
and reconcile these failures before claiming a current full-suite pass.

The [M2 continuity baseline](quality/2026-10-06-m2-continuity-baseline.md) records
passing deterministic channel/store checks, not Android OS-death acceptance.
The [app-level completion oracle](quality/2026-10-06-m2-death-completion-oracle.md)
now records a passing running → absent client → completed → recreated-client
check with exact owner/history restoration and zero replay. It uses deterministic
transport and mocked storage, not Android process death or a real keystore.
The existing `scripts/maestro/chat_process_recovery_qa.yaml` targets the production
package and checks active-run recovery, not completion while absent. Do not use
it as an isolated QA death-to-completion check. The
[Android preflight](quality/2026-10-06-m2-android-preflight.md) now maps package,
runner, storage and observer prerequisites for the remaining
[ANDROID-M2-DEATH-COMPLETE-01 scenario](quality/2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01).
Its offline integrity receipt matches 28 scoped source fingerprints; it is not
independent final approval or Android qualification.
The goal ledger marks [DOC-M2-ANDROID-PREFLIGHT](../TODO.md#now--next) done
for source-only preparation. Its retained receipt does not establish independent
final approval. The [counting-contract artifact](quality/2026-10-06-m2-counting-contract.md)
now traces the inspected metrics, run status, replay and authentication-audit reads.
None supplies complete accepted/rejected mutation counts, whole-attempt owner
coverage and closed observation intervals. Its disposition remains
`authoritative_counts_unavailable`. The offline integrity receipt binds 46 source
files and the document, not an installed runtime. The goal ledger now records
DOC-M2-COUNTING-CONTRACT done for that source-only slice. Its retained receipt
does not establish independent native review. The
[recovery-read admission task](../TODO.md#now--next) now has a
[source-bound characterization receipt](quality/2026-10-06-m2-recovery-read-admission.md).
Retained logs record 16 focused passes, one nearest recreation pass and clean
analysis in an isolated mirror. Green characterization assertions reproduced three
defects: ambiguous status 404 clears ownership, unrelated history is accepted under
the requested session, and an ungranted declared history scope does not prevent
reads. Required repair outcomes are retained unresolved ownership on ambiguous 404,
validated response/compaction lineage before publication or settlement, and refused
ungranted declared history reads without breaking legacy baseline compatibility.
The exact completed-status/history positive case is demonstrated, not unconditional
recovery admission. The [independent same-card review](../.task-evidence/t_3c5078de/review-validation.json)
approves the bounded characterization, not product recovery. It independently
repeats the 16 focused checks, one nearest check and clean analysis. The ledger
records that slice done. [Root TODO](../TODO.md#now--next) orders three bounded
repair oracles for ambiguous 404, history identity and declared history admission.
The later [ambiguous-404 repair receipt](quality/2026-10-06-m2-ambiguous-404.md)
records 18 focused, 78 nearest and 42 restoration passes, plus clean formatting
and analysis. Its three changed source/test hashes and retained command-log
hashes match the inspected snapshot. Both indistinguishable status errors now
retain the exact durable lease and duplicate-Send guard through Retry and channel
recreation. Later exact terminal status and canonical history settle without
replay. These are inspected executor receipts, not new runs by this documentation
pass. The [artifact-review receipt](../.task-evidence/t_3a5135a8/review-398-validation.json)
independently repeats baseline RED, 18 focused, 78 nearest and 42 restoration checks,
with clean format and analysis. The [scoped npm receipt](../.task-evidence/t_3a5135a8/review-398-npm-validation.json)
records 394 passes, not a full-suite run. All five authored fingerprints and eight
review log hashes match this snapshot. The goal ledger marks the 404 slice done
and subsequently marks history identity done. Do not duplicate completed work. These receipts
do not establish a final native approval verdict or M2 acceptance. The later
[history-identity implementation receipt](quality/2026-10-06-m2-history-identity.md)
records rejection before publication or lease settlement, with authorized
compaction-lineage positive controls. Retained logs record 48 focused, 432 nearest
and 63 caller/restoration passes, clean formatting and clean analysis. All 15
production/test/runbook fingerprints match this snapshot; the report itself has
changed since its recorded fingerprint. All 25 command-log hashes match.
The [independent review execution receipt](../.task-evidence/t_cd72a5d5/review-404-validation.json)
now binds all 16 selected source/document fingerprints, including the current report.
Its matching logs record 48 focused, 432 nearest and 63 caller passes, plus 543
scoped npm passes. The [independent review verdict](../.task-evidence/t_cd72a5d5/review-404.md)
approves the bounded implementation. DOC-M2-HISTORY-IDENTITY is done in the ledger;
this documentation pass reruns no product tests.
The later [history-admission implementation receipt](quality/2026-10-06-m2-history-admission.md)
records declared denial before history I/O, preserved legacy/granted controls and
retained ownership through recreation. All six selected source/document hashes
match; final retained logs record 64 focused, 432 nearest and 43 caller passes,
clean formatting and clean analysis. The superseded 63-test focused log is not
retained and is not acceptance evidence. The
[independent review verdict](../.task-evidence/t_4e4a4f7d/review-414.json) approves
the bounded repair. Its matching combined log records 539 focused, nearest and
caller passes; its receipt also records clean analysis and unchanged formatting.
The read-only integrity check verifies six selected source/document hashes,
441 mirror Dart files, manifests, commit contents and retained command logs.
DOC-M2-HISTORY-ADMISSION remains done in the ledger. Neither
historical characterization nor these bounded repairs qualifies Android or live recovery.
The later [post-repair caller receipt](quality/2026-10-06-m2-post-repair-callers.md)
records the separate deterministic caller/lifetime and compiled-browser pass.
HTTP 401 and HTTP 403 resource-read denial now have the bounded receipts above.
Required-capabilities HTTP 401 and HTTP 403 rejection now have completed
app-level controls. The delivered
[observer composition](quality/2026-10-06-m2-observer-composition.md) maps 185 local
source files and 775 dependency edges in its predecessor snapshot. Its retained
integrity receipt is not current-source, compiled or device evidence.
The [QA observer receipt](../.task-evidence/t_53f0d91e/report.md),
[delivery brief](quality/2026-10-06-m2-qa-delivery-admission.md),
[receipt-handoff proposal](quality/2026-10-06-m2-receipt-handoff-contract.md),
[admission trace](quality/2026-10-06-m2-coordinator-admission-trace.md),
[custody requirements](quality/2026-10-06-m2-custody-proof-review.md),
[isolated ordering oracle](quality/2026-10-06-m2-custody-ordering-oracle.md) and
[caller-closure report](quality/2026-10-06-m2-runtime-caller-closure.md)
are predecessor evidence. Their source bindings do not qualify the later privacy
migration or current runtime construction. Preserve their bounded historical results.

The delivered [default-refusal boundary](quality/2026-10-06-m2-default-refusal.md)
now executes REG-DEFAULT/INJECTION/API/POSITIVE. The actual QA main awaits the
input-free bootstrap and returns without Flutter binding, app launch or runtime I/O.
Runtime sink, journal, observer and authority injection APIs are absent.
Private fake diagnostics preserve validator, ordering, invalidation and error controls.
The retained [validation receipt](../.task-evidence/t_41606eec/validation.json)
records 44 tooling passes, clean analysis and unchanged formatting.
The [probe receipt](../.task-evidence/t_41606eec/probes.json) records 60 negative
external consumers, four positive metadata/bootstrap controls and three isolated
mutations that break their intended invariant. All 13 authored fingerprints match.
These are inspected executor receipts, not new product runs or independent approval.
The probes cover source-level refusal and library privacy, not installed plugin I/O.

QA-M2-DEFAULT-REFUSAL and DOC-M2-REFUSAL-CONTINUATION are done for their
bounded source-only slices. The [updated preflight](quality/2026-10-06-m2-refusal-continuation-preflight.md)
separates removed observation APIs from retained product storage/history seams.
DOC-M2-ISSUER-EVIDENCE-CONTRACT is done for its source-only
[admission dossier](quality/2026-10-06-m2-issuer-evidence-contract.md), not installed
admission. The dossier remains PROPOSED; all ten installed facts are UNAVAILABLE.
The delivered [package provenance brief](quality/2026-10-06-m2-package-provenance.md)
distinguishes configuration from measured package mode, compiled target and
complete delivered closure. Its retained checks are lexical source evidence,
not artifact measurement. F01/F02 remain UNAVAILABLE. The delivered
[manifest assessment contract](quality/2026-10-06-m2-manifest-assessment-contract.md)
remains PROPOSED. Its retained lexical and altered-document checks verify document
integrity, not an inspector, sandbox, XML parser, APK or Android runtime.
The future assessment must distinguish measured rejection from parser failure,
refuse changed inputs and tool closure, and discard results after isolation failure.
Even MANIFEST_FACTS_ONLY leaves the candidate NOT_ADMITTED. The delivered
[isolation preflight](quality/2026-10-06-m2-inspector-isolation-preflight.md)
records public metadata only. It does not demonstrate namespace permission,
resource enforcement, immutable-input seals or a complete pinned tool closure.
The delivered [synthetic isolation contract](quality/2026-10-06-m2-synthetic-isolation-contract.md)
defines expected refusals when exact limits or descendant cleanup cannot be
enforced. It is a PROPOSED source-only contract, not executed containment proof.
Exact cumulative CPU enforcement remains UNAVAILABLE; per-process limits, rate
controls and counter polling do not establish the aggregate ceiling.
The [delivered CPU feasibility assessment](quality/2026-10-06-m2-cpu-enforcement-feasibility.md)
finds no established exact-budget mechanism among the reviewed interfaces.
It records UNAVAILABLE / cpu_budget_unavailable and no mechanism execution.
DOC-M2-CPU-ENVELOPE-PROOF now covers its one conditional source-only proof:
finite inclusive B/L/K bounds from before setup through teardown, or the first
unbounded term. Inode-policy review remains separate. No APK, inspector or
synthetic control execution is admitted.
Wrong or absent evidence must remain NOT_ADMITTED.
Document review does not admit an installed issuer.
Runtime bootstrap
must remain `not_admitted` and `continuation_unavailable`, with `qualifies=false`.
No installed issuer, secure-storage protection/durability, cross-process custody,
packaging, private retrieval, Android process death or live target is qualified.
History admission and authoritative counting require separate evidence.
M2 remains unverified. Health totals, unchanged history and fixture counters cannot
establish zero live restoration mutations. Named-device, credential-denial and
denied-notification checks retain their separate qualification requirements.

The [M6 artifact inventory](quality/2026-10-06-m6-artifact-evidence.md) maps
receipt producers, exact verifier inputs and integrated recovery gaps. Its offline
checks are not candidate execution or installed-alpha acceptance. The delivered
[offline admission oracle](quality/2026-10-06-m6-candidate-admission.md) records
56 passing synthetic checks, including changed identity/bytes/certificate and
missing receipts. The goal ledger marks DOC-M6-CANDIDATE-ADMISSION done for that
bounded preparation; independent final approval is not established by this receipt.
The delivered [read-only comparator](runbooks/offline-release-candidate-comparison.md)
requires independent public expectations and compares the published index with
recomputed bindings. Its [source-bound receipt](../.task-evidence/t_bef84284/validation.json)
records `node --test test/tooling/compare_release_candidate_test.mjs test/tooling/release_evidence_test.mjs`: 120 passes, zero failures.
All four recorded production/test/runbook fingerprints match this snapshot.
This is retained synthetic evidence on Node v26.7.0, not a new test run or
Node 22 qualification. The goal ledger now records DOC-M6-OFFLINE-CHECKER done
for the bounded comparator slice; its retained receipt does not establish native
same-card approval. The [Node 22 proof task](../TODO.md#now--next) covers baseline
execution without treating another runtime version as a pass. Actual public candidate
comparison, signatures and installed-runtime qualification remain NOT_CHECKED.
A passing comparison does not prove install, upgrade,
rollback or applicable M1–M5 behavior on the same artifact. Those require separate
source-, artifact- and target-bound execution receipts.

The [discovery conformance receipt](quality/2026-10-06-wing-link-api-conformance.md)
now records executed offline checks for Wing Link GET `/meta` and GET `/healthz`.
All 20 recorded source fingerprints match this snapshot. The retained receipt
records passing YAML parsing, local-reference and JSON Schema checks, two scoped
Go commands, 62 recorder responses and nine rejected negative cases. The metadata
schema now requires the exact supported-generation array `[1, 2]`. Initialization
failure, negotiation precedence and dispatch boundaries are checked without sockets.
This is inspected execution evidence, not a new run by this documentation pass.
The goal ledger now records DOC-API-CONFORMANCE done for discovery only; the
receipt does not establish native same-card approval. The
[device-self conformance task](../TODO.md#now--next) covers one remaining family.
Full OpenAPI standards validation, other management families,
TLS/pinning, live transport and complete API conformance remain NOT_CHECKED.
The whole API-CONFORMANCE goal remains unverified despite this bounded pass.

Physical speech, platform screen-reader use, current-source process-death soak,
signed distribution and update/service rollback need their own matching evidence.
No new runtime check was executed by writing this test plan.
