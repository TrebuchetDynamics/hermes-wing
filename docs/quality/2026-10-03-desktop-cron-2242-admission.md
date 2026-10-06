# Desktop continuation — build admission and browser prerequisites

Occurrence: 2026-10-03 22:42 local. Read-only source work and owned documentation,
not another validation run or milestone acceptance.

## Admission

Initial `git status --short --branch` and filtered process census exited 0.
The census observed `flutter test --concurrency=1`, PID 1517074, with compiler
1517119 and tester 1521572 in this worktree. No Flutter command, browser build,
fixture service or implementation writer was started by this occurrence.
Delegation and terminal-handle tools returned empty lists, which do not override
an actual competing OS process. A single bounded PID attribution command later
found the process absent and exited 1 (`/proc/1517074/cwd` no longer existed).
That is not evidence of its owner, test counts or successful completion. No
same-tick qualification retry was attempted.

The previous wave is released in the [goal ledger](../plans/2026-10-03-desktop-port-goal.md).
This occurrence claimed only that ledger, this receipt and wing scratch evidence;
all implementation, tests, fixtures, ROADMAP and upstreams stayed read-only.
The next producer scope from the [fixture receipt](2026-10-03-desktop-cron-2231-fixture.md)
is unchanged. This is the first admission-blocked occurrence after fixture work,
not three consecutive failures. No scheduler mutation or pause was attempted.

## Concrete source prerequisites for the next browser spec

These are inspected source contracts, not executed UI results:

1. The [daily wrapper](../../scripts/support/desktop_daily_workflow_fixture.mjs):
   lines 103–107 and 137–150 cap authoritative inventory pages at **one**, place
   `e2e-hermes-session` second, and omit it from page zero. The new journey must
   explicitly click **Load more sessions** before selecting that exact target;
   copying the ordinary Chat journey's search-only selection will not suffice.
   Lines 153–159 append exact metadata/read receipts without resetting state.
2. The [production Chat journey](../../playwright/tests/regression/production-chat-journey.spec.mjs):
   lines 88–101 provide real saved-contact setup and explicit session selection;
   lines 22–47 provide actual focused-editor filling; lines 127–150 distinguish
   Stop acknowledgment from terminal cancellation and explicit reconciliation.
   For the combined journey the stopped run is `run_2`, not this reference's
   `run_3`; retain exact run/request assertions rather than copying ordinals.
3. The [picker journey](../../playwright/tests/regression/session-model-picker.spec.mjs):
   lines 33–47 provide exact alpha raw-pair selection, rejected confirmation and
   explicit retry. Stop at **two** lock attempts; lines 48–56 deliberately reconfirm
   on reopen and would introduce an unintended third mutation in this regression.
   If testing model persistence on reopen, inspect then Escape instead of Use.
4. The [restoration journey](../../playwright/tests/regression/session-restoration.spec.mjs):
   lines 30–42 read only the real cache's non-secret owner pointer; lines 125–134
   bound metadata observations around reload. Reuse that ownership proof without
   its seed/reset helper or its unrelated `synthetic-restoration-050` identity.
   Assert a new exact metadata read for `e2e-hermes-session` and canonical history
   while page zero still omits it. Mutation-count snapshots must match both
   before/after navigation and before/after reload, not just final totals.
5. The [Node combined fixture test](../../playwright/support/hermes_desktop_daily_fixture_test.mjs):
   lines 65–106 demonstrate the single `desktop-daily` seed, exact model/runtime
   readback and `run_2` stopping-to-cancelled protocol. This is inspected test
   source; the previous receipt owns its execution evidence.

Next bounded acceptance remains 390px/1280px saved-contact/profile/session →
explicit model confirmation → first correlated approval → second prompt/Stop →
canonical terminal reconciliation → leave/reload exact owner → third deliberate
prompt/approval. Require three submits, two approvals, one Stop, two lock attempts,
zero unexpected mutations and zero restoration mutations. Build a fresh E2E
artifact before Chromium, then run nearest legacy fixture browser cases with
retries disabled. One owner, ordered dependency after the fixture prerequisite;
no parallel handoff or process-local child is needed.

## Checks and limits

Scratch evidence:
`/home/xel/.hermes/profiles/wing/cache/scratch/desktop-cron-2242-admission/`.
`source-before.json` binds five inspected sources for the documentation gate.
Close checks compare those hashes, validate local receipt links and Markdown
whitespace, and run scoped `git diff --check`. Commands/results are captured in
`checks.json`; no Flutter/analyzer/Node behavioral/browser gate ran here.

No services or displays were launched, so there are no owned QA resources to
terminate. No upstream/tool install, inference, personal runtime/auth access,
production edit, credential copying, commit, card acceptance or release occurred.
Native execution and approved live-provider qualification remain separate open
gates. Next occurrence must establish fresh exclusive ownership before claiming
the exact new browser spec and compiled execution scope.

Run summary: not_available — host accounting was not exposed.
