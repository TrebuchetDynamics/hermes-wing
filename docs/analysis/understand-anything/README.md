# Four-repository study: design and roadmap input

## Decision summary

Preserve Wing's existing direct Agent data plane and separate Wing Link management plane. Improve the fidelity of capability reporting, finish current-source recovery/Chat qualification, and qualify mobile continuity before expanding administration or voice. This is a **proposal**, not an accepted architectural change, completed milestone or product qualification.

The reference clients are useful for outcomes and race policies, not as authority for the connected Agent's capabilities. Keep Hermes Agent, Desktop and Conduit unmodified upstream software. Missing contracts defer their individual operations; they do not justify patches, broad CLI fallbacks or a second domain backend.

## What was actually analyzed

Understand Anything was cloned under `tools/understand-anything` at `1d7418b8abfa543744ae029e63a482aee03f9022`. Its core was built and its shipped scanner and real parser APIs were exercised. Hermes subagents performed the grounded semantic studies using the tool's file-analysis, architecture, tour and review methodology. This was not a Claude plugin slash-command invocation or an exhaustive per-function LLM analysis.

- [Agent study](agent-study.md) and [graph](agent-graph.json): runtime authority, distinct HTTP/native contracts, profiles, runs, requests, Projects and administration.
- [Conduit study](conduit-study.md) and [graph](conduit-graph.json): mobile identity/recovery, native authentication, cache policies and optional relay/provider topology.
- [Desktop study](desktop-study.md) and [graph](desktop-graph.json): streaming/reconciliation, human requests, session models and privileged host assumptions.
- [Wing study](wing-study.md) and [graph](wing-graph.json): the **dirty working tree**, actual production wiring, ownership gates, tests and milestone gaps.
- [Tool execution report](tooling-report.md) and [machine-readable census](tooling/summary.json): exclusions, snapshot commits, parser limitations and reproducible commands.

The four graphs are curated learning maps. Scanner inventory totals are not semantic graph coverage. Wing was not atomically frozen: its focused study and separate census used different exclusions/times (888 versus 884 files). Those are distinct observations, not interchangeable totals. Study-local early tooling blockers were subsequently resolved by the tooling task; the final parent validation used the built upstream Zod schema on all four graphs.

## Comparative design findings

### 1. Resource identity must survive every asynchronous boundary

Agent separates profiles, durable sessions, execution runs and native runtime sessions. Conduit explicitly separates durable identity from positively confirmed runtime aliases; Desktop scopes refreshes and request routing to their original connection/session. Wing already fences channel, directory and preference-write admission.

**Wing implication:** preserve the current canonical origin/profile/session/run/request tuple and generation checks. Restore an exact selected session even when absent from the first inventory page. A refreshed catalog is not permission to adopt another conversation. Preserve drafts/presentation state without seeding a replacement Agent session from cached history.

Evidence: [Agent §§2–3](agent-study.md), [Conduit reconciliation](conduit-study.md), [Desktop §§2–4](desktop-study.md), [Wing strengths 2–3 and restoration slice](wing-study.md).

### 2. Connection loss, stop requested and server termination are different states

Agent's detached run subscription, session-chat SSE and native WebSocket have distinct disconnect semantics. HTTP Stop can be provisional and a late completion remains authoritative. Desktop has transport-specific teardown but not uniform terminal readback. Wing already keeps uncertain ownership until canonical reconciliation.

**Wing implication:** keep truthful stopping/outcome-unknown states, forbid ambiguous prompt replay and prove each selected transport's disconnect contract separately. Do not treat a native socket as a durable detached-run guarantee or local teardown as confirmed cancellation.

Evidence: [Agent §§3–4](agent-study.md), [Desktop cancellation](desktop-study.md), [Wing Stop and M1/M2](wing-study.md).

### 3. Human requests need exact correlation and acknowledged settlement

Desktop's stronger Dashboard path separates display IDs from upstream request identity and acknowledges responses. Its Runs refusal reflects that client's compatibility assumption, not proof about today's Agent checkout. The current Agent study traces exact request handling and native peer-to-peer RPC negotiation. Conduit has useful stale-decision fixtures but also a separate relay decision path.

**Wing implication:** independently qualify the exact installed Agent operation, request ID, connection/profile/session/run scope and stale-response behavior. Native protocol investigation must include capability negotiation and open-request restoration. No approval replay, guessed FIFO target, secret-prompt coercion or Wing Link/relay decision authority.

Evidence: [Agent §5](agent-study.md), [Desktop §3](desktop-study.md), [Conduit decision and push sections](conduit-study.md). The apparent Desktop/Agent disagreement is a version/surface qualification question, not grounds to automatically disable or enable Wing.

### 4. Availability wording must match the operational gate

Parent inspection confirmed that `lib/core/hermes/policy/hermes_surface_readiness.dart` uses hand-written jobs/health/Persona predicates weaker than its existing `authorizesEndpoint` helper. The operational `_allowsEndpoint` in `lib/core/hermes/channel/hermes_channel_state.dart` also checks every required grant and supported profile context.

**Wing implication:** the smallest concrete implementation candidate is a readiness-report regression and scoped predicate alignment. This is a source-level reporting mismatch, **not an executed authorization-bypass reproduction**. No new schema, transport or authorization service is necessary.

Evidence and proposed checks: [Wing ranked finding P1 and slice C](wing-study.md). Agent's implemented-but-unadvertised job administration also demonstrates why guessed endpoints and broad feature flags cannot substitute for exact discovery.

### 5. Borrow presentation patterns, not privileged authority

Desktop launches CLI processes, edits Agent configuration and accesses Agent SQLite. Conduit exposes broad native configuration/filesystem calls and automatically reasserts persisted approval-bypass preferences after reconnect. Its push/live voice topology also reaches plugins, relays and providers outside ordinary direct chat.

**Wing implication:** retain conversation-only Agent-confirmed models, stable transcript presentation, staged connection repair and display-only cache patterns where appropriate. Reject global profile switching, raw host paths, generic config/CLI access, shadow provider/session state, implicit security-setting replay and unsupported voice/push claims. Existing Wing Link rooted folder grants remain folder-only.

Evidence: [Desktop §§4–6](desktop-study.md), [Conduit recommendations and exclusions](conduit-study.md), [Wing authority/setup boundaries](wing-study.md).

## Recommended delivery order

Use existing roadmap milestones/cards; do not create duplicate work or rewrite ongoing dirty roadmap changes from this study.

1. **P0 — Finish exact-session restoration acceptance (M2 seam).** Independently exercise page-two/missing/denied/malformed recovery, A→B→A selection, late preference writes and draft races. Exit: exact canonical ownership, no replacement session, no creates/sends or stale cache/selection writes.
2. **P0 — Qualify one real production Chat journey (M1).** Use the owner's approved disposable unmodified Agent target and selected provider/model. Exit: generated output, controlled tool/approval allow and deny, terminal Stop readback, reconnect and a subsequent prompt with no duplicate send. Missing private authentication remains a blocker; fixtures are not inference.
3. **P1 — Align readiness with exact authorization (M1/M4).** Test missing extra grants, unsupported schema, wrong method/path and unsupported profile context. Exit: status/diagnostics agree with the live gate without issuing requests or granting writes. Implement only after a failing regression.
4. **P1 — Prove one Android process-death return (M2).** Exit: running→completed background/death/relaunch, expired/revoked credential and wrong-owner cases preserve identity without resend; status remains usable with notifications denied. No push/durable draft expansion in this slice.
5. **P2 — Qualify existing native output/accessibility (M5).** Exit: save/share cancel and denial, Unicode, owner change, readable enlarged text, keyboard/CJK IME and screen-reader operation on a named device. Loaded-transcript export is not full-history or arbitrary artifact retrieval.
6. **P2 — Qualify isolated trusted setup and release lifecycle separately (M3/M6).** Verify new-profile rollback affects only the new profile and catalog reads do not confer writes. Separately require signed artifact inputs and real activation/health/rollback evidence before a distribution claim.

### Conditional contract checkpoints

Keep native-web migration separate from the working production path until authorization, request negotiation, cancellation and recovery are qualified. Projects, existing-profile provider writes, discovery/MCP, memory, Kanban, job mutations, artifacts and push each need their exact unmodified authoritative contract and security acceptance. An unavailable operation does not block unrelated supported inventory or text Chat.

Do not add a broad refactor milestone based on file size alone. Shared-state Dart parts and repeated owner bookkeeping are maintenance risk concentrations, not demonstrated defects. Prefer one reproduced transition and its nearest regression; extract pure presentation only when touched behavior makes it useful.

## Verification and limits

The parent executed `node docs/analysis/understand-anything/tooling/validate-graphs.mjs` after all workers finished. All four graphs passed the actual upstream schema with no repairs/dropped items. Parent read-back also confirmed Agent and Conduit remain clean, Desktop retains exactly its five pre-existing `.claude` deletions, and the Understand Anything checkout has no tracked modifications.

The parent also reran the shipped scanner wrapper: Wing 884 files / 24 parser samples, Agent 15,237 / 17, Conduit 424 / 6, Desktop 948 / 6; all repeat scans were byte-identical and upstream statuses preserved. Wing's additional-ignore count rose from 21 in the first execution to 30 after concurrent analysis files existed; retained inventory remained 884. The current machine-readable summary reflects the rerun, while the tooling report preserves the first execution receipt.

Parent reruns of the tooling report's exact two Vitest commands passed: scanner/extraction CLI/outcomes **111 tests**; schema/Dart/Swift **156 tests**. These are **analysis-tool tests**, not Wing or upstream product qualification. Source studies inspected nearest tests but did not execute Flutter, Go, iOS, Electron, live Agent/provider, physical device, service, speech or release journeys. No dashboard interaction was exercised. No roadmap milestone, security audit or platform parity is declared complete.

### Reproduce analysis validation

From Wing root, with the tool dependencies/core built as described in [tooling-report.md](tooling-report.md):

```bash
node docs/analysis/understand-anything/tooling/validate-graphs.mjs
node docs/analysis/understand-anything/tooling/run-scans.mjs
```

The scanner writes only to the analysis directory and excludes nested reference/tool repositories from Wing inputs. Study source pins identify checkouts; they are not claims about installed runtimes or perpetually latest upstream state.
