# Completion checklist — milestone-first autogoal

Task: optimize selection and worker contracts for usable workflows delivered to main. Preserve unrelated dirty files, existing ownership, schedules, running workers and Hermes Agent.

- [x] C1: Saved project policy defines M1 first and a vertical-slice contract. Evidence: docs/product/autogoal-workflows.md, TODO.md and CONTRIBUTING.md links.
- [x] C2: Real goals.py next selects M1 before unrelated Android/connection work. Evidence: focus readback M1; next begins PARITY-LIVE-WORKFLOW (Now), VERIFY-NATIVE-RESUMED-SEND (Next), then unrelated Android. Ledger validates. Ten focus regressions and eight existing ledger regressions passed.
- [x] C3: Shared picker, injected worker body and handoff separate implementation, exact platform/backend qualification and protected-main delivery. Evidence: 20 handoff regressions, one new workflow-body regression and four picker-policy regressions passed.
- [x] C4: Workers use focused checks; the integration owner runs broader gates against frozen candidates. Reuse requires matching source/dependencies/environment. Evidence: saved policy, worker-body regression and reviewed helper path. No claim that existing worker resource leases or operating schedules changed.
- [x] C5: Saved policy links and anchors validate; scoped shared/Wing diffs have no whitespace errors. Evidence: five local links/anchors, goal-ledger validation and final-verification.json.
- [x] C6: progress.md lists actual files, verified results and exact remaining work. Evidence: final checkpoint.
- [x] C7: Wing delivery mode cannot use the legacy direct-push/worktree-sweep path. Evidence: .hermes/merge-train.json loads through the real repo_config helper as protected-pr/worktree=false. Nineteen offline protected-delivery tests and three existing merge-train tests pass. Tests mock Git/GitHub delivery calls; remote protection or merge is not proven.

## Executed results

Final `make check` against saved orchestration code: exit 0, 28 offline suites passed, zero failed. It validated 26 skill contracts and Python/shell syntax. Two model-backed suites are explicitly excluded. Final gate wall time measured through the tool wrapper: 8.871 seconds, not an inferred runtime savings.

Exact commands, outputs and measured durations: [final-verification.json](final-verification.json). Earlier focused checks: [verification.json](verification.json).

- `goals.py validate <repo>`: ok.
- `goals.py render <repo>`: ok.
- Scoped `git diff --check` in Wing and shared-skills: pass.
- Policy local file links and anchors: five passed.
- Actual delivery helper config readback: protected-pr enabled, branches enabled, dirty-worktree phase disabled.

## Failures found and repaired

- Read-only `focus --json` was missing despite policy using it. Observed failing regression, implemented the reader, reran successfully.
- Actual worker-body injection still used daily merge wording and obsolete review escalation. Observed failing workflow-body regression, corrected the injection, reran successfully.
- Two legacy review-text assertions failed after correcting that contract. Updated them to require one corrected review request, original-card preservation, no invented approval and review-lane authority. The full suite then passed. This changed obsolete policy assertions, not product acceptance.

Full manual-review time and total retries across all child execution are not measured. Retained RED/failure observations are listed above; no fabricated aggregate. Token and monetary totals are unavailable. No cost savings inferred.

## Follow-up Wing verification

Requested `npm run test` runs `flutter test --concurrency=1`. The foreground
transport timed out after 420 seconds. The retained log is
`.task-evidence/autogoal-workflows-npm-test.log`. Before interruption, four real
widget failures were observed in session-disclosure and gateway-switch tests.
The final counter was +1614 -5; the fifth error was Flutter shutdown after the
interruption. That attempt is not a passing full-product suite. The four harness
failures were repaired without removing assertions. The fresh full background run
completed with exit 0: **3650 tests passed, zero failure entries**. Flutter reported
10:35 elapsed; the subprocess receipt measured 639.042 seconds wall time.
`.task-evidence/autogoal-workflows-npm-test-final.log` and matching `.json`
retain the exact execution evidence. This is Flutter unit/widget qualification,
not live-provider, Android-device or protected-PR delivery evidence.

## Explicitly not verified

- Live-provider generation/approval/Stop/relaunch/restored send on the requested product journey.
- Automatic authoritative provider/model-pair restoration; the existing contract remains unsupported.
- Real protected GitHub PR creation, required checks, merge and main ancestry. Offline tests are not delivery receipts.
- Actual changed worker behavior or fresh scheduled-run adoption. The cron prompt file is a template; no installed schedule/payload or worker was changed.
- Model-backed two-pass bare repo-docs bootstrap/idempotency behavior. No valid fresh fixture was supplied; model-backed runs were not substituted for the offline gate.

Execution controls: no product builds, live inference, credential copying, worker restart, cron edits, commits, pushes, real merges or remote branch-protection mutations. Focused subprocesses used explicit timeouts; make check used a 600-second tool limit. Future workers retain native 50-turn/three-attempt controls.

Existing shared-skills root checks.md/progress.md belong to separate team/STT work and were preserved. Applied concise STE-inspired wording and checked changed meanings against the accepted workflow. Full ASD-STE100 dictionary compliance was not verified.
