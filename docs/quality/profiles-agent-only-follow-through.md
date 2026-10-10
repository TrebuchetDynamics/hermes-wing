# Profiles Agent-only removal: integration handoff

## Candidate and authority

Bootstrap + Maintain follows the changed Wing branch, not a new product test run.
The canonical checkout remains at `b9eb5b3d9f6f3a433dd36cb6271ad8ec769b2319`.
Its Profiles source is byte-identical to main and still contains the legacy fallback.

The isolated candidate is `agent/wing/t_e002406c` at
`e54522c7c58b1bab2bedc2bcc77194b98f66d33b`, following initial handoff
`f368599bba6550d6bc801f7927e74008d7b849a8`. Its producer baseline is
`60f239b1c27419992cc4e5c70320c4b44ccf4771`; its ledger-only prerequisite is
`c43b1a5bf8c9e096fb3b1e896d978137622d2c4e`.
Canonical `goals.json` remains the task authority. An implementation branch need
not have byte-identical canonical ledger bytes to be a valid source input.

The branch's `docs/quality/profiles-agent-only.md` records four owned Dart paths:
Profiles screen/editor and their nearest tests. Source inspection confirms that
Profiles no longer constructs a Link client or offers Link configuration callbacks.
The unused throwing builder remains for excluded legacy callers. Native profile
creation uses supported name/clone operations, not provider configuration.
Exact operation, grants, schema and current owner remain required.

Native review run `1329` requested changes on card `t_e002406c`. Its independent
public-control probe found that `_openEditor` calls directory `refresh()` after
Cancel/save. With a stored `wingLinkPendingCredentialId`, that transitive path
invokes legacy recovery once instead of zero times. Screen-builder counters did
not cover this seam. The reviewer recorded a failing Flutter probe and a failing
targeted npm adapter rerun against matching candidate blobs. Run `1330` refused
a repeated initial-start gate against authorized edits. Same-card admission was
corrected without changing the original start guard. Rework run `1331` removed
only the post-dismissal directory refresh; existing Agent mutation reconciliation
remains authoritative. Review run `1332` approved that corrected bounded slice.
Cancel, create, edit, delete and selection/catalog fixtures count zero pending
credential recoveries, as well as zero screen Link constructions/requests.

## Evidence limits

The producer report records 55 focused widget passes, scoped analysis success,
and 48 supplementary editor-caller passes. It also records a full analyzer
failure with 21 issues in unchanged excluded input. This pass retrieved the exact
card/run anchors and retained `.task-evidence/t_e002406c/verification.json`.
Its embedded complete terminal output ends with 55 passes, scoped analysis success
and 21 full-analysis issues. All four owned historical Git blobs match its hashes.
The supplementary 48 passes remain report/card evidence only. No product check
was rerun. Matching owned blobs does not qualify a complete dependency closure or
the current tree. That initial review requested changes; the corrected slice now
has review approval, while main delivery remains unverified.

The reported analyzer failures are a missing
`integration_test/support/remote_connection_retry_native_fixture.dart` dependency
and an unimported `HermesConnectionMode` in Chat layout. Preserve those failures.
An analyzer-clean shared checkout does not repair the exact isolated candidate.
Native GTK, Chromium, Android, actual Agent authentication, provider execution,
physical storage and full Link retirement remain unqualified for this slice.
The official Desktop reference remains the read-only `hermes-agent/apps/desktop/`;
this consumer repair is not an official parity certification.

## Existing-owner continuation

[CONNECTION-LINK-REMOVAL](../../TODO.md#now--next) stays in progress under its
existing owner. Do not add another broad removal task or take its lease.
Integrate the four owned candidate paths into a frozen combined source only
through that owner. Preserve unrelated enrollment, SSH, discovery, generated
localization and saved-connection inputs. Retire or replace excluded legacy
Profiles fallback expectations without weakening authorization or erasing stores.

The editor-refresh correction and pending-credential public-control regressions
are implemented and reviewed on the isolated candidate. Preserve legacy stores
and directory contracts. The existing owner must assemble those four owned Dart
paths with explicit dependency, fixture, generated localization and lockfile inputs.
Retire excluded fallback expectations and repair the two source-closure failures
within existing ownership. The smallest next check is the pending-recovery probe
and focused Profiles/editor targets on that frozen combined candidate, followed
by full analysis. Do not rerun unchanged isolated evidence to imply integration.
MT-RERUN-TRAIN and its browser successor own broader integration qualification.
No new owner decision is needed. Remaining entry/setup/catalog and packaging
removal is not closed by this bounded Profiles result.

## Rework evidence inspected in this follow-through

This pass retrieved the exact card and runs `1331`/`1332`, then parsed the complete
embedded output in retained `rework-verification.json`. The output ends with
`+56: All tests passed!` and zero legacy recovery after cancellation. Scoped
analysis ends with no issues; full analysis ends with 21 issues. The command is
`timeout 5m npm run test -- --no-pub test/features/profiles/profiles_screen_test.dart test/features/profiles/profile_editor_sheet_test.dart .task-evidence/t_e002406c/review_pending_recovery_test.dart`.
This is targeted widget qualification, not a full-suite npm pass.

All four owned commit blobs match the receipt's SHA-256 output. Review metadata
records an independent rerun of the same 56-test target and approval at the exact
corrected commit. This pass did not rerun product tests or inspect a separate
complete reviewer terminal log. The original failure remains historical evidence,
not a current claim that the repaired branch still fails. Full analyzer failures
remain current for that candidate; matching four owned blobs cannot qualify the
whole current tree or prove a complete dependency manifest.

## Documentation verification boundary

All applicable core owners already exist: README, PRD, living ADRs, spec, owned
code-first legacy API contract, test plan, runbooks and changelog. This pass
maintains context, spec, test-plan, route/navigation and the existing task body.
Requirements and ADRs retain accepted intent. The legacy API, runbooks and
changelog retain their existing qualification and release limits; no new release
or API is introduced. BLOCKERS and the task archive are preserved.

Apply the STE-inspired profile to this scoped prose. Mechanical review covers
Markdown and protected identifiers. Meaning review preserves source capability,
producer-reported fixture checks, native/live proof, review and delivery as
separate states. Full ASD-STE100 dictionary compliance is not verified.

### Core-role accounting

- `README.md`: unchanged_verified for orientation and direct-entry support limits.
- `docs/product/prd.md`: unchanged_verified for accepted scope and connection requirements.
- `docs/adr/README.md` and relevant living product/API/runtime decisions: unchanged_verified; no new decision.
- `docs/spec.md`: maintained for isolated removal and the remaining transitive recovery defect.
- `docs/api/wing-link.openapi.yaml`: unchanged_verified for existing code-first ownership only; legacy API conformance is not requalified.
- `docs/test-plan.md`: maintained for pending-credential regression and dependency-closure checks.
- `docs/getting-started.md` and existing setup/release runbooks: unchanged for operational scope; no setup or release procedure changes here.
- `CHANGELOG.md`: unchanged; this pass introduces no runtime change or release.

No applicable missing owner requires creation. Root `TODO.md` refines only
CONNECTION-LINK-REMOVAL and corrects its stale unclaimed wording. No task ID,
lease, dependency, focus or ledger status changes. Root `goals.json` stays
byte-identical. Every non-met goal has a live task body. Coverage is two met,
17 partial, nine unmet and seven unverified. All 79 live entries remain present.
The first helper candidate is the in-progress removal task; the first open
candidate is CONNECTION-OFFICIAL-DESKTOP-PORT. Eligibility does not grant a
lease over the running removal worker's inputs. No new worker is dispatched.
Root `todo.archive.md` and `BLOCKERS.md` are preserved; no history moves or
owner question changes are needed.

### Executed documentation checks

The pinned candidate is under `.task-evidence/repo-docs-profiles-followthrough/`.
Exact current documentation dependencies were materialized there without build
artifacts; `candidate-inputs.json` records their input hashes. Targeted canonical
baselines matched under the shared Git-common-directory advisory lock before
integration. Inherited `GIT_*` overrides were removed for identity discovery.

`python3 <home>/.hermes/shared-skills/repo-docs/scripts/goals.py fmt <repo>`,
then `validate` and `render` on that canonical target, each with a fresh
`--expected-revision`, passed. Validation printed `ok`. A repeated cycle retained
identical TODO/ledger bytes. Added local links and anchors passed in the canonical
checkout and artifact-free documentation candidate: 18 checks across both targets.
Scoped `git diff --check` passed in both. The initial link-check attempt failed
because the verifier had not normalized `../` before matching the new document;
path normalization corrected the verifier before any canonical write.

Mechanical and meaning review cover only authored additions and replacements.
Existing task/source status, security boundaries and historical failures remain
unchanged. These offline Linux checks do not qualify product behavior. No app
builds/tests, installs, network/device operations, API-runtime/schema qualification,
commits, pushes, schedule/card mutations or upstream edits ran.

## Reviewed-correction maintenance verification

Mode: Bootstrap + Maintain. This follow-through updates five existing owners:
this integration handoff, `docs/spec.md`, `docs/test-plan.md`, `docs/README.md`
and the existing CONNECTION-LINK-REMOVAL body in root `TODO.md`. It replaces the
stale running-rework instruction with reviewed source and a combined-candidate
next check. It adds no task, changes no lease and claims no product completion.
The earlier documentation verification sections above retain their own snapshot.

Core-role outcomes for this follow-through:

- Orientation, `README.md`: unchanged_verified; direct-entry and alpha limits remain.
- Requirements, `docs/product/prd.md`: unchanged_verified; accepted intent is unchanged.
- Decisions, `docs/adr/README.md` and living product/API/runtime records:
  unchanged_verified; no new architectural decision is needed.
- Design, `docs/spec.md`: maintained; repaired isolated source is distinct from
  the canonical fallback and remaining integration failures.
- Owned API, `docs/api/wing-link.openapi.yaml`: unchanged_verified for its manual
  code-first ownership; no API or runtime-conformance qualification is added.
- Verification, `docs/test-plan.md`: maintained; retain the discriminating probe
  and run it next on the frozen combined source.
- Operations, `docs/getting-started.md` and existing runbooks: unchanged_verified
  for this bounded consumer correction; no deployment/setup procedure changes.
- Change history, `CHANGELOG.md`: unchanged_verified; no runtime implementation
  or released change is introduced by this documentation pass.

All applicable core owners exist. The existing task already carries the remaining
workflow, scope, acceptance, sources and ownership. Root `goals.json` is unchanged.
Coverage remains two met, 17 partial, nine unmet and seven unverified goals.
All 79 open/in-progress ledger entries have actual task bodies outside the
coverage table. Every non-met goal has live work. CONNECTION-PATHS remains the
accepted focus. `goals.py next` first returns in-progress CONNECTION-LINK-REMOVAL;
the first open entry is CONNECTION-OFFICIAL-DESKTOP-PORT. Eligibility is not
writer availability, and this pass starts no worker. `BLOCKERS.md` and the root
`todo.archive.md` are byte-identical; no completed history moves or owner questions
are needed.

The private pinned candidate is `.task-evidence/repo-docs-profiles-reviewed/candidate`.
Exact current documentary and cited source inputs were materialized without build
artifacts. Canonical baseline bytes matched under the shared Git-common-directory
lock before the five anchored replacements. Git identity discovery removed
inherited `GIT_*` overrides. Candidate inputs, card readback, patch and checks are
optional local evidence, not shipped-document dependencies.

Executed documentation checks: canonical `goals.py fmt`, `validate`, `render`,
each with a fresh `--expected-revision`, passed; validation printed `ok`.
A repeated cycle kept TODO and ledger bytes identical. Scoped `git diff --check`
passed in canonical and candidate checkouts. Local links/anchors passed 1,232
checks across both targets. The initial candidate link check found a missing
citation input, `lib/router/widgets/connection_entry_gate.dart`. Materializing
its exact canonical bytes and the remaining cited input closure corrected that
verification setup; no product source was edited or qualified.

Mechanical review covers changed Markdown, punctuation and protected identifiers.
Language/meaning review applies the STE-inspired profile only to authored prose.
It preserves the initial failure, reviewed widget correction, analyzer failures,
canonical integration, native/live qualification and main delivery as separate
states. Full ASD-STE100 dictionary compliance was not verified. No application
suite, build, install, network/device action, upstream edit, commit, push, card
mutation, schedule change or dispatch ran.
