# Four-repository study follow-through

Status: delivery direction adopted on 2026-10-03; bounded readiness correction
implemented, focused deterministic checks passed and the review finding was
resolved (receipt below). Broader/runtime qualification remains pending. This plan closes no
card or milestone and does not authorize
live inference, personal runtime mutation, publication or an upstream change.

## Basis and evidence labels

The [study synthesis](../analysis/understand-anything/README.md),
[Agent](../analysis/understand-anything/agent-study.md),
[Desktop](../analysis/understand-anything/desktop-study.md),
[Conduit](../analysis/understand-anything/conduit-study.md) and
[Wing](../analysis/understand-anything/wing-study.md) studies inform the existing
[roadmap](../../ROADMAP.md), not a duplicate backlog.

- **Source observed:** traced code and nearest test assertions in the named
  checkouts/dirty Wing tree; inspected tests are not passing executions.
- **Analysis-tool verified:** curated graph/schema/scanner/tool tests; not Wing or
  upstream product, authentication, device, service or release evidence.
- **Implementation verified:** exact command/result against a named source/diff
  and SDK, recorded only after execution; no such receipt is supplied by this plan.
- **Independently accepted:** same-card tester/reviewer acceptance, distinct from
  executor/self-test evidence. Preserve the roadmap's historical receipts and limits.
- **Runtime qualified:** isolated unmodified Agent/provider or named device/service/
  exact signed artifact journey, with authorized inputs and sanitized readback.
- **Blocked / unverified:** missing input or contract is explicit; compilation,
  fixtures and study pins cannot upgrade it to qualification.

## Scope and non-goals

Adopt the source-backed reporting invariant in the living ADRs, add the smallest
jobs/health/Persona readiness correction, and finish existing restoration/production
Chat acceptance before Android continuity and native/setup/release qualification.
Reporting must be no stronger than the action gate: supported schema, exact
operation/method/path, every required grant, supported profile context and current
resource identity. Read-only availability does not confer writes.

Reuse `HermesChannel`, `HermesApiChannel`, Riverpod and existing authorization
policy. Preserve the direct Agent data plane, separate Wing Link credential and
management plane, server-wins reconciliation and owner/generation admission.
Reconnect never silently replays prompts, approvals or config/security preferences;
unknown outcomes require canonical recovery, not another-transport retry or a
replacement session seeded from cached history.

Non-goals: new API capabilities, native-web production migration, broad refactors,
new owner/state services, offline mutation queues, durable draft/push expansion,
generic CLI/config/file access, shadow Agent state, existing-profile compatibility
writes, voice parity or release claims. Agent, Desktop and Conduit remain unmodified,
including source/tests, hooks and tool configuration; preserve unrelated dirty
changes and Desktop's pre-existing deletions. Missing contracts defer only their
operations, not supported text Chat/inventory.

## Files and ownership

Documentation scope for this adoption is only `ROADMAP.md`, `docs/README.md`,
`docs/adr/api-and-state.md`, `docs/adr/client.md`,
`docs/adr/runtime-and-delivery.md` and this plan. Existing sections/cards/receipts
remain; routes, AGENTS and runbooks are not edited by this documentation task.

The bounded implementation lane owns
`lib/core/hermes/policy/hermes_surface_readiness.dart` and a focused regression at
`test/core/hermes/hermes_surface_readiness_authorization_test.dart`. Read
`lib/core/hermes/channel/hermes_channel_state.dart` and
`test/core/hermes/channel/hermes_jobs_bootstrap_authorization_test.dart` as the
operational comparison, not permission to weaken or broaden action gating.
Nearest status/diagnostics callers are read-only unless a reproduced defect requires
an explicitly rescoped change. Separate restoration acceptance uses existing tests
and the existing card; it does not own these documentation or readiness files.

Before any further slice, discover current status and assign disjoint ownership.
Use the pre-task contents in
`tools/task-baselines/upstream-study-follow-through/before.json` for scoped review,
not Git HEAD alone, because pre-existing dirty work must survive. No stage, commit,
reset, cleanup or upstream hook writes.

## Ordered slices and acceptance

### 1. P0 — Exact-session restoration acceptance (M2 seam)

Continue `t_f098a32e`; its lifecycle handoff/triage blocker and missing independent
acceptance remain open. Do not reimplement or waive tester/reviewer review.

Prove page-two/exact missing selection, unsupported/denied/not-found/malformed
reads, A→B→A selection, late preference writes and draft races. Exact canonical
origin/profile/session identity must survive; zero creates/sends, no replacement
selection, stale cache/history or old preference rewrite. Repeat the compiled
Chromium restoration journey; record browser evidence separately from Android.

### 2. P0 — Live production Chat acceptance (M1)

Continue `t_38174cb7` and preserve `t_19a425b2`'s existing evidence/status. Production
remains `HermesApiChannel`. Use only the owner's approved disposable unmodified
Agent and selected `gpt-6.1-sol` / `openai-codex`, with supported private target
authentication and explicit harmless tool, network and cost limits.

Exit: generated output; controlled tool/approval allow and deny; exact request
identity/stale rejection; Stop terminal readback versus acknowledgment; controlled
loss/reconnect and a subsequent prompt without duplicate send. Tester repeats and
reviewer accepts named targets only. Fixed fixture output is not live inference.

### 3. P1 — Bounded readiness correction (M1/M4; parallel)

The study found a source-level reporting mismatch, not an executed authorization
bypass. Add a failing regression before aligning jobs/health/Persona predicates
with existing exact authorization. Compare report availability to the corresponding
operation gate: missing additional grant, unsupported schema, wrong method/path,
unsupported profile context, allowed read and read-only-without-write cases.

Exit: status and diagnostics cannot overstate operation authorization; all-grants
and profile-context denial remain fail-closed, valid reads remain accurate, and
report construction causes no requests or writes. Do not add capability fields,
relax action gates or infer administration from broad features. Record regression,
analysis and independent acceptance separately; parent appends executed receipts.

### 4. P1 — One Android process-death return (M2)

After supported M1 run evidence, use the existing secure detached-run store and
lifecycle on a named device/emulator. Prove running→completed across background,
forced process death and relaunch, expired/revoked credentials and wrong-owner
cases with exact host/profile/session/run, canonical history and zero resend.
Denied notification permission must not make status unusable. No push or durable
draft expansion; Chromium at phone width is not Android qualification.

### 5. P2 — Native output and accessibility (M5)

Qualify existing loaded-transcript copy/save/share, not full-history export or
arbitrary artifacts. Require cancel/denial, Unicode, bounds, owner change before
write, readable 200% text/reduced motion, keyboard/CJK IME and TalkBack on a named
Android target. Preserve reviewed browser and existing Linux receipts without
upgrading them to another platform or current integrated acceptance.

### 6. P2 — Trusted setup and release lifecycle (M3/M6; separate)

Setup: isolated enrollment→new-profile→explicit Chat; catalog read grants no writes,
secrets stay write-only, failed readiness removes only the newly created profile,
uncertain receipt reconciles without new-key replay, and management selection
cannot silently change Chat ownership. Verify actual Agent-owned state.

Release: separately require authorized signed artifacts, digest/size verification,
owner-only activation, actual service health and induced failed activation restoring
the previous version. Empty production trust keys mean unavailable updates, never
unsigned fallback. Exact-artifact install/upgrade/rollback/uninstall and integrated
M6 acceptance remain separate from setup, compilation and publication policy.

## Conditional HTTP/native contract checkpoint

Before changing native-web status, record a per-operation matrix: surface/origin,
exact HTTP method/path or native RPC, authentication/acquisition and credential
scope, profile/session/runtime/run identity, human-request handling, Stop,
disconnect/reconnect and qualification evidence. HTTP API keys, native dashboard
authority and Wing Link grants are not interchangeable.

Native qualification includes per-connection server-request negotiation, exact
request IDs, acknowledged settlement, open-request recovery, cancellation and
stale-response denial. No guessed FIFO target, approval replay or secret-prompt
coercion. Separately qualify detached run subscription, session-chat stream and
native socket disconnect semantics; Stop requested/local teardown is not terminal
cancellation. Do not promote internal clients to production to close a milestone.

Projects/provider writes/discovery/MCP/memory/jobs/Kanban/artifacts/push each retain
one exact unmodified-contract checkpoint. Broad native administration or a route
found in source does not establish advertised Wing support.

## Acceptance commands

Run from the Wing root with the intended Flutter 3.44.2 / Dart 3.12.2; record the
actual SDK and source/diff. These commands are required work, not pass receipts.

```bash
flutter test test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart test/features/hermes_chat/gateways/gateway_selection_write_race_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart test/features/hermes_chat/screens/hermes_chat_restoration_draft_race_test.dart --concurrency=1
flutter test test/core/hermes/hermes_surface_readiness_authorization_test.dart test/core/hermes/hermes_api_test.dart test/core/hermes/channel/hermes_jobs_bootstrap_authorization_test.dart --concurrency=1
flutter test test/core/hermes/channel/hermes_api_channel_test.dart --concurrency=1
flutter analyze
flutter build web --release -t lib/main_e2e.dart
npx playwright test playwright/tests/regression/session-restoration.spec.mjs playwright/tests/regression/production-chat-journey.spec.mjs
```

Format only changed Dart files. The focused readiness regression now exists and
its execution receipt is below. Reuse the
[restoration](../runbooks/chat-session-restoration.md),
[production Chat](../runbooks/chat-production-journey.md),
[export](../runbooks/chat-transcript-export.md) and
[release compatibility](../runbooks/hermes-agent-release-compatibility.md)
runbooks for exact harness prerequisites and live procedures. Browser fixtures do
not fulfill the live/device exits. For setup run nearest profile/editor tests and
`(cd wing_link && go test ./...)`, then isolated readback. M6 requires the full
[CONTRIBUTING gate](../../CONTRIBUTING.md#required-checks) and named runtime receipts.

Documentation acceptance: scoped `git diff --check` on the six documentation
paths, explicit trailing-whitespace checks including this untracked plan, and
local Markdown file/anchor resolution for those paths. No runtime suite is needed
to claim only documentation adoption.

## Blockers and receipt policy

- Restoration's native handoff gate and same-card independent acceptance remain.
- Owner-selected Codex inference needs supported private target authentication;
  do not substitute another provider or store secrets in metadata, argv or logs.
- Native-web idle interrupt RPC `5032` and product authority/acquisition/request/
  cancellation qualification remain conditional; deterministic tests do not close them.
- Android needs a named target/OS/API and access for death, secure storage, pinning,
  denied-notification and TalkBack evidence.
- Setup needs an explicitly isolated authorized target; release needs signing
  custody/artifacts, service access and publication permission where relevant.
- Missing exact contracts block only their individual operations; no upstream
  modification, proxy or generic compatibility fallback is an unblock option.

Each executed receipt records exact paths/source diff, SDK/tools, command/exit,
named target/OS and sanitized assertions, distinguishing self-test, independent
acceptance and runtime qualification. Sibling progress alone is not proof of
completed work.

## Executed bounded receipt

The readiness implementation changes
`lib/core/hermes/policy/hermes_surface_readiness.dart`, adds
`test/core/hermes/hermes_surface_readiness_authorization_test.dart`, and supplies
required query profile context to the existing positive Persona fixture in
`test/core/hermes/hermes_api_test.dart` (six-line scoped change preserving prior
edits). Jobs,
detailed health and Persona read/write reports now use the existing
`authorizesScopedEndpoint` helper. Operational gates/permissions, protocols and
network requests are unchanged. Persona remains read-only when read authorization
is valid but write authorization is denied.

The implementation worker observed four regression failures before each minimal
predicate correction. Parent read-back reviewed the production diff against the
pre-task snapshot and independently reran the final checks on Linux with Flutter
3.44.2 / Dart 3.12.2:

```bash
dart format --output=none --set-exit-if-changed lib/core/hermes/policy/hermes_surface_readiness.dart test/core/hermes/hermes_surface_readiness_authorization_test.dart
flutter test test/core/hermes/hermes_surface_readiness_authorization_test.dart test/core/hermes/hermes_api_test.dart test/core/hermes/channel/hermes_jobs_bootstrap_authorization_test.dart test/features/hermes_chat/diagnostics --concurrency=1 --reporter expanded
flutter analyze
```

Results after review revision: format exit 0 with no changes; **212 tests passed**
(including 34 new readiness cases); analyzer exit 0, no issues. Independent review
found that unscoped Persona endpoints still overstated edit availability without
query context. Parent observed two new missing/header-context regressions fail,
then added the same unconditional context requirement as `canEditProfileSoul`.
The first combined rerun exposed the existing positive fixture's missing context;
its six-line fixture repair preserves the intended authorized positive behavior.
The final combined rerun above is green. Independent re-review confirmed the
original P2 finding resolved by source inspection, with no new scoped correctness
findings; the reviewer did not duplicate test execution or accept tracked cards.
Parent also reran the six-file
restoration/gateway-switch command in the
[independent restoration receipt](../quality/2026-10-03-session-restoration-study-verification.md#restoration-matrix):
**116 tests passed**. That worker separately executed three filtered existing
client/channel regressions; do not count those as a new full-suite parent run.

Initial worker test loads encountered stale SDK/pub-cache roots in generated
package metadata; the implementation worker repaired those with
`flutter pub get --offline`, without tracked dependency changes. Final parent
runs above passed after repair. Existing dirty source/tests/docs were preserved;
upstream Agent and Conduit remain clean and Desktop retains its five pre-existing
`.claude` deletions.

This is deterministic Linux-hosted unit/widget and static-analysis evidence,
not browser interaction, native application, Android process death, live
Agent/provider inference, full repository gate, signed delivery or tracked
same-card acceptance. Independent source review is complete for this bounded
change; all runtime and card blockers above remain.
