# Independent restoration admission review — 2026-10-04

Task: `t_3da6fa16`. Verdict: **SOURCE_CONSISTENT_RUNTIME_WITHHELD**.
This closes the independent source-review gate for the 02:40 clarification, not
restoration parity, security acceptance, implementation authorization or daily-use
runtime acceptance. No consequential remaining contradiction was found in the
changed restoration admission criteria against the narrowly inspected unmodified
Agent contracts. No repair to the proposal is required by this review.

## Candidate and ownership

The reviewed [proposal](../plans/2026-10-03-desktop-local-integration-design.md)
is bound to SHA-256
`5ccb517a5777e5ecd00f940062755f5fb5fcd5ed7f50f64ea856c8ec17b9d241`.
Dirty Wing HEAD is not its identity. Initial source pins were captured before
source inspection; additional source/test files were pinned before consuming their
bodies. All consumed immutable source and predecessor receipt digests were
rechecked on verifier closure. The changing goal ledger is an ownership record,
not an immutable contract input.

Live board inspection showed this was the only running/ready/review card.
Scheduler readback showed continuation `6f218a559ed2` scheduled, not executing,
and hourly picker completed. During inspection, the
[goal ledger](../plans/2026-10-03-desktop-port-goal.md):683–694 recorded a separate
02:56 admission-record lease restricted to its ledger/ownership receipt; it
explicitly defers this exact independent-review slice to this worker. That is
non-overlapping ownership, not permission to take its lease. No schedule or lease
was changed. This run writes only this report and profile-local review artifacts
and journal. No upstream, production, existing test, fixture, oracle, proposal,
ROADMAP or goal-ledger edit was made.

## Independent comparison with the 02:25 findings

The [02:25 review](2026-10-04-desktop-cron-0225-native-model-review.md) is the
baseline; the [02:40 receipt](2026-10-04-desktop-cron-0240-design.md) and its actual
`design.diff` were read, not treated as execution of the updated contracts.

1. P1 direct read authority is now explicit at proposal:78,95,119,217–218.
   [Agent `_session_response`](../../hermes-agent/gateway/platforms/api_server.py):3011–3043
   projects model text and presence/provenance flags, not provider/runtime/lock.
   `_handle_get_session`:3213–3219 is authenticated and fetches the exact ID before
   using that projection. `_handle_session_model_lock`:3797–3826 returns accepted
   runtime only after persistence through a POST. It is not a restored read.
   The nearest [session API tests](../../hermes-agent/tests/gateway/test_session_api.py):83–112,776–848
   cover safe exact-ID projection and write-then-chat use of persisted locks;
   neither supplies a missing passive pair read. Inspected, not executed here.
   The proposal now explicitly blocks exact restored-pair acceptance and forbids
   catalog/default provider inference, synthetic confirmation, durable shadow pair
   storage and repeated lock POSTs. The earlier ambiguous initial restoration row
   no longer promises exact-pair delivery from model-only GETs.
2. P1 lazy/warm identity is corrected at proposal:115.
   [Resume branches](../../hermes-agent/tui_gateway/methods_session.py):869–1061
   prioritize a same-profile live session before selecting cold modes. Warm reuse
   touches transport/ownership; it is not a side-effect-free metadata GET.
   [Identity helpers](../../hermes-agent/tui_gateway/server.py):2305–2317,2828–2836
   prioritize pending switch display identity when live; cold lazy instead calls
   profile-model fallback without stored overrides, reopens the row and repairs
   child/watch history. Proposal:115 admits no branch and distinguishes warm
   from cold recovery. The [warm tests](../../hermes-agent/tests/tui_gateway/test_resume_live_lazy_session.py):55–107
   explicitly include pending-switch and wrong-profile cases; they are not cold
   qualification. Deferred response-path observations remain limited to that body,
   not hydration/build/next-turn acceptance.
3. P1 automatic generation and count sufficiency are corrected at
   proposal:115,218–219. Default cold/eager call
   [auto-continuation](../../hermes-agent/tui_gateway/session_auto_continue.py):58–139;
   its config defaults enabled at :22–32. Fresh crash markers can cause
   `_run_prompt_submit` with no new client submit. Live-writer ownership fences at
   :71–79,107–116 are meaningful; they do not prove every resume branch passive.
   The [nearest tests](../../hermes-agent/tests/tui_gateway/test_auto_continue.py):381–395,412–422,466–483,568–605
   cover fresh/stale/absent markers, kickoff races and another live writer.
   They were read, not run. Client mutation counts, attributed server turns and
   canonical history are now all required. No guessed opt-out, marker/config
   edits, stop-after-start workaround or Agent patch is authorized.
4. P2 broad-read substitution remains rejected at proposal:119.
   Catalog/config-provider/rendered status are not an exact acknowledged
   session-pair contract. Native resume can expose identity candidates, but not a
   qualified substitute with established authorization, current-session binding,
   pending/effective/acknowledged meaning and passive semantics. This is a bounded
   conclusion for the inspected direct and native surfaces, not a universal claim
   that no Agent release or endpoint could ever provide such a read.

Current [Wing picker admission](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart):1209–1233
requires an accepted lock with the selected exact session ID. The
[metadata authority regression](../../test/features/hermes_chat/screens/hermes_chat_model_authority_test.dart):119–157
uses duplicate catalog model IDs across providers, keeps `currentSessionModel`
null and asserts zero mutations. The changed proposal matches this behavior; it
must not upgrade catalog draft selection to confirmed restoration.

The unchanged native authentication block at proposal:99–107 remains valid.
[Ticket minting](../../hermes-agent/hermes_cli/dashboard_auth/routes.py):485–493
requires a verified dashboard Session; a process token or direct gateway key is
not that Session. [WS admission](../../hermes-agent/hermes_cli/web_server_chat.py):299–317,369–374
supports gated ticket subprotocols but the ungated branch uses a token URL.
A supported gated native-login/ticket acquisition path is still an unqualified
candidate. No safe production acquisition was demonstrated here. The
[API/state](../adr/api-and-state.md):13–36,
[runtime/delivery](../adr/runtime-and-delivery.md):10–30 and
[security/privacy](../adr/security-and-privacy.md):15–24 boundaries remain binding.

## Acceptance gate matrix

The executable matrix is profile-local `matrix.json` (directory below).
`SOURCE_CONSISTENT` means only that the reviewed design restriction matches
pinned source; it never means a callable operation or runtime acceptance.
`BLOCKED` means a known unmet prerequisite or preserved failed checkpoint.
`NOT_CHECKED` means runtime/platform behavior was not exercised by this lane.
Every gate has pinned path/range/symbol evidence, a bounded claim and exit criteria.

| Matrix gate(s) | Status | Admission / independent exit |
| --- | --- | --- |
| pair-design | SOURCE_CONSISTENT | GET metadata and POST acknowledgment are separate; no fabricated pair. |
| pair-runtime | BLOCKED | Exact supported authorized pair read, schema and current origin/profile/session identity, then isolated qualification. |
| identity-design | SOURCE_CONSISTENT | Metadata, accepted selection, pending display and effective runtime remain distinct. |
| identity-runtime | NOT_CHECKED | Wrong/missing/revoked fields and pending switch versus effective route need live evidence. |
| warm-design, lazy-design, deferred-design, cold-design, eager-design | SOURCE_CONSISTENT | Five branch descriptions match bounded inspected bodies; no branch selected/admitted. |
| warm-runtime, lazy-runtime, deferred-runtime, cold-runtime, eager-runtime | NOT_CHECKED | Qualify each branch independently, not warm as a substitute for process-death recovery. |
| continuation-design | SOURCE_CONSISTENT | Agent continuation is not Wing replay; source ownership fences retained. |
| passive-runtime | BLOCKED | Explicitly resolve auto-continuation before adopting resume as passive reconciliation. |
| auth-design | SOURCE_CONSISTENT | Native no-secret-URL/auth distinction preserved; credentials remain separate. |
| auth-runtime | BLOCKED | Qualified private acquisition, exact identity/scopes/storage lifecycle and ticket admission absent. |
| resource-design | SOURCE_CONSISTENT | Explicit origin/profile/stored/runtime identity and exact operation/all-grants/schema gates. |
| resource-runtime | NOT_CHECKED | Installed target grants/schema and stale/wrong-profile/late-result fences require isolated runtime qualification. |
| counts-design | SOURCE_CONSISTENT | Client mutations, server turns and canonical history all required. |
| counts-runtime | NOT_CHECKED | Attributed before/after counts for route recovery and process relaunch separately. |
| generation-runtime | NOT_CHECKED | Actual owner-selected `gpt-6.1-sol` / `openai-codex` generation required by [ROADMAP](../../ROADMAP.md):49–88. |
| browser-checkpoint | BLOCKED | Preserved compiled Chromium restored-picker failure at :192, 390/1280 widths. |
| browser-final | NOT_CHECKED | Subsequent Escape, explicit resume and final counts were not reached. |

The native case checklist contains five branches × absent/fresh/stale/live-owner
marker cases, all NOT_CHECKED. Each requires origin, profile, stored/runtime IDs,
pending/effective/acknowledged identity, client mutations, server turns, canonical
history and continuation attribution. Those are required observations, not invented
executed receipts. Linux native, macOS, Windows and actual inference are NOT_CHECKED
in this review; no platform was exercised beyond the host Python verifier.

## Reused evidence and preserved failures

Actual predecessor artifacts were read and pinned:

- `desktop-cron-0204-authority/verified.json`: 18 successes, zero failure/error/skip,
  460 unchanged source files; `results.json`: focused Flutter tests and analyzer
  exit 0. These are historical metadata-only fixture checks, not tests run here or
  runtime pair acceptance.
- `desktop-cron-0240-design/close.json`: nine unchanged source hashes, 68 links,
  six original lines changed, reference statuses unchanged, scoped diff exit 0.
  `design.diff` shows the new authority caveat and six scoped line replacements.
  This is a prior document gate, not native admission.
- `desktop-cron-0117-selector/parsed-browser.json`: both widths failed at
  [integrated browser oracle](../../playwright/tests/regression/desktop-daily-workflow.spec.mjs):192.
  The subsequent :193–219 stages remain NOT_CHECKED. No new browser run or oracle
  weakening was performed.

These artifacts reside under
`/home/xel/.hermes/profiles/wing/cache/scratch/`. They may be pruned: the verifier
fails closed if a pinned predecessor is missing or changed; it does not silently
replace historical evidence. The pin manifests are trust inputs, not an attestation
against an actor who can rewrite the entire package. Anchor/digest checks establish
receipt integrity, not behavioral correctness of Agent or Flutter code.

## Executed verifier checks

Artifacts: `/home/xel/.hermes/profiles/wing/autogoal/restoration-admission-review/`.
Runnable files: `verify.py`, `run_checks.py`; inputs: `matrix.json`, `pins.json`,
`additional-pins.json`, `test-pins.json`, `receipt-pins.json`; results: `checks.json`.
No third-party Python dependencies or Agent imports are used.

From `/home/xel/git/gormes/hermes-wing`:

```text
python /home/xel/.hermes/profiles/wing/autogoal/restoration-admission-review/verify.py
python /home/xel/.hermes/profiles/wing/autogoal/restoration-admission-review/run_checks.py
```

Both commands exited 0. Positive and closing verifier checks each passed:
28 pinned source/receipt files, 25 gates, 98 evidence references and 20 native
cases marked NOT_CHECKED, with `runtime_accepted: false`. Private-copy controls
promoting pair, deferred runtime, auth and generation each exited 1 with
`gate promotion`; a corrupted evidence digest exited 1 with
`digest binding mismatch`. All five controls were correctly rejected. The
original matrix remained unchanged, SHA-256
`0293e5bb015cc40a358b066b8a9907abfa16ec33aad48ef965534da6fb8b74b4`.

The verifier checks source-reference existence/range/symbol, exact SHA-256 bindings,
required gate/case coverage, evidence levels, frozen per-gate status and explicit
false runtime/auth/pair/generation/adapter/live-call admission. It is deliberately
candidate-specific: a later source change requires a new independent review, not
an automatic status upgrade. It is not a test harness for the app.

Report local-link/whitespace and report-scoped Git diff checks are recorded in
`report-checks.json`. Command:
`python /home/xel/.hermes/profiles/wing/autogoal/restoration-admission-review/check_report.py`.
The first report-check wrapper exited 1 because it incorrectly expected
`git diff --no-index --check /dev/null <new-report>` to exit 0. Git exited 1
with no diagnostics for the new-file difference, not a whitespace failure.
The new isolated wrapper now explicitly distinguishes that expected difference
from diagnostic failures; no existing product test harness was touched. The
ordinary report-scoped `git diff --check` exited 0, and explicit local-link and
trailing-whitespace checks were clean. No Flutter/browser/full-suite/upstream tests, service launch,
installation, credential access, endpoint probe, inference, adapter or test-harness
correction occurred.

## Handoff

The bounded independent review is complete when the verifier and document closure
checks pass with source immutability. Keep the failed restored-picker oracle and
all runtime gates open. This verdict authorizes no implementation or live call.
The owner may separately scope exact-pair authority/auth/target review and named
native qualification; this task neither selects a transport nor creates follow-up
cards. No minimal design repair is proposed because no consequential contradiction
remains in the changed admission criteria. Broader product parity is unfinished.
