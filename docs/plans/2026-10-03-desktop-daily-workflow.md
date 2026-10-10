# Desktop daily-use workflow — 2026-10-03

> Current Flutter port target: `hermes-agent/apps/desktop/`, the official Nous Research app. Follow [the plan reference policy](README.md). Re-trace official flows before claiming matched parity.

Status: owner-accepted outcome and ordering; implementation/qualification open.
Authoritative continuation ownership: [goal ledger](2026-10-03-desktop-port-goal.md).

## Accepted decisions and scope

- Owner correction, 2026-10-07: Local, SSH and Remote connect directly to Hermes
  Agent. Wing Link installation, pairing and credentials are not prerequisites.
  First-run entry must match Desktop rather than force a management setup detour.
  Direct manual access exists; its primary-entry redesign and Wing-managed SSH
  remain implementation work. Missing Agent APIs are explained as unavailable.
- Desktop-first fidelity on Flutter desktop and wide web. Preserve compact/mobile
  usability; Android adaptations follow the matched Desktop flow, not a separate
  product goal. Wide web does not acquire local process/filesystem privileges.
- Full local Desktop functionality is the target through a separately designed
  bounded native integration. Remote mode may expose a smaller, explicitly gated
  subset. Neither full parity nor native integration is implemented by this plan.
- First daily-use milestone: local connect → explicit profile/model/session →
  real Chat generation → correlated approval/authoritative stop → leave → relaunch
  and restore exactly the same session without duplicate sends.
- Copy session ID, searchable profile selection, footer/recents and sidebar polish
  support demonstrated workflow gaps. They are not the leading milestone.
- Owner requested actual start and recurring 10-minute continuation. Initial
  delegated scopes and scheduled job are recorded below, not passing executions.

Non-goals: new backend, native-web migration, arbitrary CLI, privileged Desktop
IPC copying, upstream changes, personal runtime/credential access, full tabs,
release/distribution, or automatic card transitions. Existing independent evidence
and dirty work must remain intact.

## Official lifecycle source trace

Use the [bounded knowledge findings](../analysis/official-desktop-graphify.md#bounded-knowledge-study-and-planning-consequences)
from official revision `158fd638da1629c8e62caf9ade1515d162def8ab`.
This adds source-backed acceptance leads, not execution evidence or a new milestone.

1. Trace one full send → stream → input request → Stop → disconnect → resume path.
   Record connection, profile, durable session, runtime session and lineage identity
   at each boundary. Identify the live Wing caller and nearest regression first.
2. Compare `store/gateway.ts` request routing and lease cleanup with Wing's owner
   admission. Timeout, abort, disconnect and late results must not retarget requests.
3. Trace production helpers behind `warm-resume-replay-barrier.test.tsx` before
   translating warm activation, socket loss, cold resume, REST races and background
   refresh scenarios. Recovered history and held live events must settle in canonical
   order, without duplicate sends or replayed approvals.
4. Compare captured-session interruption and pending-input cleanup in
   `use-prompt-actions/index.ts`. Prove success and failure recovery. Expired or
   withdrawn approvals must become inoperable and have an accessible explanation.
   Clearing the UI or closing a stream is not authoritative Stop.
5. Add the smallest behavior regression and production correction under existing
   task ownership. Keep pane subscriptions scoped so unrelated drafts and views
   survive streaming and background refresh. Qualify compact/wide interaction and
   named native targets separately.

Desktop paths above are within `hermes-agent/apps/desktop/src/`; the shared replay
transport is `hermes-agent/apps/shared/src/json-rpc-gateway.ts`. Production Wing
REST/SSE is not declared compatible with Desktop JSON-RPC by this plan. Preserve
actual operation gating and unsupported behavior until qualified. Existing connection
and recovery tasks own this work; do not close them on graph or source results.

## Owner update — Wing implementation and QA

The subsequent Telegram interview selected a disposable local QA Agent/profile.
Wing owns implementation, test preparation, execution, failure diagnosis and fixes.
The owner does not coordinate individual QA steps. Prioritize the complete daily-use
workflow over labels, matrix maintenance or isolated shell polish.

- Keep the personal Agent runtime, credentials, client state and system packages
  unchanged. Use isolated QA preferences, workspace and an owned display.
- Allow at most three short QA generations through separately authorized
  subscription/test access. No metered spending or purchase is authorized without
  another approval. Count and report actual usage. Do not assume tool continuations
  or failed attempts are free or automatically retry them beyond the limit.
- Default applied: harmless read-only checks and scratch-workspace-only test actions.
  The owner delegated QA rather than selecting a tool-operation option. This default
  does not authorize arbitrary host commands or external side effects.
- Wing selects reversible setup details and repairs reproduced workflow failures.
  Use supported unmodified Agent contracts. Do not copy personal credentials,
  patch Agent, weaken tests or manufacture approval/Stop support.
- Request owner input only for authentication or permissions Wing cannot complete
  safely, or spending outside the approved limit. Prepare independent work first.
  Use the supported secret-safe flow, never ordinary chat for credentials.

This records responsibility, target strategy and usage limits, not a provisioned
Agent, authenticated provider or passing workflow. The
`PARITY-NATIVE-RELAUNCH` slice is delivered for the bounded synthetic Linux workflow.
See the [receipt](../quality/native-relaunch-workflow.md).
`VERIFY-NATIVE-MODEL-RELAUNCH` delivered the
[combined native fixture](../quality/native-model-relaunch-workflow.md), not exact
provider/model persistence: the inspected Agent contract cannot read that pair.
Restart preserves model text and requires explicit re-selection.
`VERIFY-NATIVE-RESUMED-SEND` delivered
[explicit reselection and one resumed send](../quality/native-resumed-send.md)
on the restored exact session in two isolated Linux GTK processes. Restart,
Cancel and route reopening add no mutations. This is synthetic qualification;
the separately scoped `PARITY-LIVE-WORKFLOW` retains actual generation proof.
The later `M1-NATIVE-INTEGRATED-RESTART`
[integrated fixture](../quality/native-integrated-daily-restart.md) is complete
for correlated approval, uncertain Stop, canonical recovery and two-process
exact-session restart together. Compact/wide Linux GTK journeys use 200% text,
explicit model reselection and one resumed send without recovery replay.
This is frozen-source synthetic qualification, not live generation or main delivery.
Full M1 acceptance remains open.
This update creates no worker lease, resumes no schedule and authorizes no release.

## Binding architecture and native-design prerequisite

Read [client](../adr/client.md), [product](../adr/product.md),
[runtime](../adr/runtime-and-delivery.md), [API/state](../adr/api-and-state.md) and
[threat model](../security/threat-model.md). Hermes Agent remains the authority;
production Chat uses direct authenticated Agent transport, not Wing Link. Credentials
remain separate. Server state wins; no offline mutation replay or shadow state.

The native design lane must separately trace allowed unmodified Agent contracts
and describe each local operation's exact authority/resource identity, fixed
executable/argument shape where applicable, typed input/output/time bounds,
secret-safe acquisition, cancellation/recovery and removal trigger. Security review
must resolve local-only versus remote exposure, grants/revocation, concurrency,
audit redaction, secure storage and adversarial replay before implementation.
The proposed design does not automatically enable operations. Current fixed-operation
rules remain binding: no shell, caller-selected executable/config key/arbitrary host
path, direct Agent config/file/database writes, global profile/project switching,
Agent patches or broad Wing Link compatibility expansion. Missing remote contracts
block their individual operations, not all desktop-local work. A new local contract
must be explicitly reviewed rather than silently reinterpreting those rules.

## Acceptance matrix

Use the existing production channel and routing seams. Capture the exact ownership
key: canonical Agent origin/connection, profile ID, session ID, provider/model ID,
and run ID when running; include Project identity if a supported flow uses one.
Display names, catalog defaults and inventory positions are not identity proof.
Private origins/credentials/content stay out of public receipts; use redacted
labels and bounded operation/count assertions.

| Step | Required result | Failure/recovery assertions |
| --- | --- | --- |
| Connect | Explicit supported local Agent connection; record operation discovery, authentication/acquisition and current grants. Wing Link setup remains a separate management connection. | Missing/revoked authority is unavailable, not empty or silently replaced; no automatic management-to-chat credential reuse. |
| Profile/model/session | Choose exact profile and session, confirm configured provider/model through Agent readback. Search/filter changes no ownership; session-only model selection does not mutate profile/provider setup. | Send remains blocked during selection/restoration; late old-owner results cannot overwrite identity, draft, model or transcript. Unsupported model operations are explained, not simulated. |
| Generate | One deliberate harmless prompt produces actual provider output via unmodified Agent with canonical run/history readback. Actual inference uses `openai-codex` / `gpt-6.1-sol` on an approved isolated target. | Deterministic fixture text is explicitly labeled; unknown submit outcome retains ownership and offers reconciliation, never automatic resend. |
| Approve/deny | An authorized harmless tool request is tied to exact owner/run/request identity; response preserves exact Agent `request_id` where that protocol supplies it. Record acknowledged settlement and canonical continuation/denial. | Stale, cancelled, repeated and in-flight reuse cannot answer a replacement request. Approval is not FIFO guesswork or reconnection replay. |
| Stop | Stop targets the exact run; Agent terminal status and canonical history must confirm outcome before another prompt is admitted. | Request acknowledgment, socket closure and UI teardown are not authoritative cancellation. Unknown/error retains ownership and accessible Reconnect/reconciliation; no duplicate Retry. |
| Leave/relaunch | Leave route/minimize and separately terminate/relaunch the native client using isolated owned state. Restore exact remembered origin/profile/session, including a session outside inventory page one; reconcile model/history/run status. | Do not select a convenient default, create replacement sessions or resend. Running-to-terminal return is tested only on a transport that actually supports it; native live sockets are not durable detached work. |
| Resume | New explicit prompt is possible only after canonical reconciliation. Requests/counts prove exactly one send per deliberate user action and zero sends/session creations/approval responses caused by restoration. | Pending/failure keeps the pointer and supplies Retry/Choose session. Generic 404 is not deletion. Wrong owner, delayed reads/preferences, revoked auth and concurrent selection cannot transfer ownership. |

Keyboard-only operation, readable focus, compact widths, 200% text and reduced
motion remain regression requirements. Native GTK/plugin execution, browser
semantics and Android process death/accessibility are distinct qualification targets.
Do not claim physical speech, screen-reader or detached-run support from this plan.

## Ordered bounded work

1. **Fresh prerequisites, no invasive repair.** Recheck exclusive Flutter/build
   ownership, native development metadata, owned Xvfb availability and existing
   package roots. For live qualification, check only approved manifest/target/auth
   readiness, with no secret scanning or personal OAuth import. The
   [native preflight](../quality/2026-10-03-native-chat-qualification.md) recorded
   concurrent builds, missing pkg-config metadata and unset private live inputs;
   those are historical observations, not current impossibility. Do not install
   packages, delete build trees or switch provider/model to bypass them.
2. **Native deterministic workflow harness.** Initial write scope:
   `integration_test/linux_desktop_daily_workflow_test.dart` and
   `scripts/run_linux_desktop_daily_workflow_e2e.sh` (new). Use production
   `HermesApiChannel`, owned display and isolated HOME/XDG/preferences; cover exact
   off-page restoration, correlated approval/stop and request counts. Prove actual
   process relaunch separately from widget remount. Hand any reproduced producer
   gap to primary ownership with smallest regression before a code change.
3. **Native integration design/security gate in parallel.** Design-only scope:
   `docs/plans/2026-10-03-desktop-local-integration-design.md`. No native contract
   is enabled just because the document or deterministic harness exists.
4. **Integration and fresh browser regression.** Primary owner reviews returned
   artifacts and runs relevant existing channel/restoration/picker/approval tests
   under exclusive build ownership. Build compiled E2E target before Chromium
   workflow/reload tests; preserve wide and compact keyboard usability. Supporting
   UI changes are scoped to reproduced flow gaps, not a new cosmetic backlog.
5. **Actual approved target workflow.** After prerequisites and private supported
   auth clear, run harmless bounded generation/tool/approval/stop and canonical
   restoration on the named unmodified Agent target. Confirm network, billing,
   duration and cleanup consent before mutation. A discovered endpoint or job
   schedule alone is not consent. No fixture may replace this evidence.
6. **Independent acceptance and next scope.** Source/diff/artifact-bound test/review
   receipts must name what was actually exercised. Preserve existing cards; exact
   card/receipt readback resolves historical conflicts before any status claim.
   Milestone completion needs owner review and a new owner-approved next scope.

## Evidence ledger shape and current limits

| Evidence class | Required receipt / current basis |
| --- | --- |
| Source/unit/widget | Exact source/diff and focused regressions. [First-wave receipt](../quality/2026-10-03-desktop-port-first-wave.md) attributes shell toggle review/tests and the earlier 2,397-test parent run; none qualifies this workflow. |
| Fixture | Synthetic deterministic server/channel operation receipts, explicit counts and failures. [Production journey](../runbooks/chat-production-journey.md) and [restoration](../runbooks/chat-session-restoration.md) are existing bounded leads, not actual inference. |
| Native | Named OS/GTK/display/SDK/plugins, owned state, real process lifecycle and native request/readback logs. An Xvfb fixture run may be native execution but remains synthetic provider evidence. The [two-process receipt](../quality/native-relaunch-workflow.md) qualifies synthetic off-page history restoration, not model persistence, full-shell startup or live inference. |
| Browser | Fresh compiled Flutter Chromium wide/compact journey, reload and keyboard evidence; record source/artifact and fixture/real backend separately. 390px is not Android. |
| Live Agent/provider | Approved isolated target, exact provider/model/run, canonical history/terminal/request readback, zero duplicate sends and supported private auth. Actual generation is open, not inferred from fixtures or old credentials/build blockers. |
| Card/release | Same-card independent tester/reviewer and source binding, separately from code/tests. `t_f098a32e` and `t_38174cb7` are not promoted; `t_19a425b2` has inconsistent historical acceptance wording requiring exact readback. No release claim. |

Every new receipt records source/diff, artifact if applicable, SDK/tool versions,
OS/target, exact commands/exits, sanitized log locations, what failed/not-run,
operation/readback/count assertions and next action. Syntax/compilation alone does
not meet flow acceptance. This documentation task runs only scoped diff/link checks.

## Ownership, continuation and recovery

The [goal ledger](2026-10-03-desktop-port-goal.md) is the single write-lease and
execution checkpoint, not this plan. Initial ownership is native harness lane
(two new test/launcher files), native design lane (one new plan), documentation
lane (ROADMAP, client ADR, parity ledger and this plan), and primary conversation
(integration, goal ledger and new quality receipt). Producers retain ownership
until primary integration/release; no worker may repair an owned file prematurely.

Continuation job ID: `6f218a559ed2`, recorded cadence every 10 minutes with local
outputs. Creation/resume and later executions are historical entries in the goal
ledger. The [latest recorded preflight](../quality/2026-10-04-desktop-cron-0322-auth-preflight.md)
paused the job for missing provisioning; no automatic resume is authorized. This
summarizes receipts, not a fresh scheduler check or guaranteed progress. Each
scheduled tick is a fresh bounded worker, not persistence of this conversation. Read instructions, Git state, this
plan, goal ledger and latest receipts; inspect outstanding runtime handles first.
Never overlap active write leases or start concurrent Flutter/build commands.
During an active primary wave, do only safe read-only prerequisites or wait for its
receipt; do not steal ownership or duplicate dispatch.

After release, select one dependency-ready bounded task, record scope/lease before
mutation and exact commands/results/blocker/log/next action afterward in the goal
ledger. Missed ticks are skipped, not backfilled; no same-tick retry or polling
loops. Three consecutive occurrences of the same blocker/failure require pausing
that actual job and recording the precise cause. Missing owner authority, private
secret provisioning or ambiguous ownership also pauses rather than bypasses.
Resume only with resolved prerequisites and explicit ownership. Stop/pause when
required evidence is complete or owner says stop; scheduler availability and
owner-only blockers limit progress.

Documentation stop condition: these four documents consistently record accepted
baseline, workflow-first order, bounded acceptance/ownership/recovery and evidence
limits. Behavioral milestone stop condition is the complete flow matrix with
actual approved-target generation plus named native/browser receipts and owner
review, not a plan, source review or successful fixture alone.
