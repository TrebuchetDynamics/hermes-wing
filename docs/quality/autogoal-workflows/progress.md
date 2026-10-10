# Progress

Task: Make autogoal optimize for usable workflows delivered to main. Primary outcome: connect → select profile/model → generate → approve → Stop → relaunch → restore → send again. Preserve existing dirty work, schedules, healthy workers and Agent immutability.

## Outputs

Wing root: <repo>
- docs/product/autogoal-workflows.md
- TODO.md and CONTRIBUTING.md (policy links and live M1 task in Now)
- goals.json (primary_milestone=M1, PARITY-LIVE-WORKFLOW in Now)
- .hermes/merge-train.json (protected-pr delivery, no dirty-worktree sweep)
- docs/quality/autogoal-workflows/checks.md
- docs/quality/autogoal-workflows/progress.md
- docs/quality/autogoal-workflows/verification.json
- docs/quality/autogoal-workflows/final-verification.json
- test/features/hermes_chat/screens/hermes_chat_session_disclosure_test.dart (lazy-child/vertical-scroll harness correction)
- test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart (lazy-child/vertical-scroll harness correction)
- .task-evidence/autogoal-workflows-npm-test-final.log and .json (full Flutter run evidence)

Shared skills root: <home>/.hermes/shared-skills
- autogoal/SKILL.md; autogoal/references/handoff.md; autogoal/references/maintenance.md
- autogoal/scripts/start_goal.py; autogoal/scripts/test_workflow_handoff.py; autogoal/scripts/test_goal_handoff.py
- extras/cron/autogoal.prompt.md (template, not installed cron payload)
- repo-docs/SKILL.md; repo-docs/scripts/goals.py; repo-docs/scripts/test_milestone_focus.py
- fleet-governor/SKILL.md; fleet-governor/references/merge-train.md
- fleet-governor/scripts/merge_train.py; fleet-governor/scripts/test_protected_delivery.py

## Completed

Real focus readback reports M1. next returns PARITY-LIVE-WORKFLOW, then VERIFY-NATIVE-RESUMED-SEND, ahead of unrelated Android/connection work. validate and render succeeded. Preserved task IDs and existing scope/usage limits. Global-session worker t_5ca5f71b was observed done, not running; no worker changed.

The vertical-slice contract and actual worker-body injection separate implemented, qualified and delivered states, list remaining milestone gaps and require matching source/platform/backend evidence. Workers use focused checks; one integration owner owns broader frozen-candidate gates. Review handoff finishes the card, not M1. Model reselection does not prove automatic pair restoration.

Strict protected delivery is implemented and configured for Wing. The real helper loads protected-pr/worktree=false. Offline tests verify no direct main push, no dirty sweep, no baseline-failure waiver, protection before candidate push, all required checks passing, normal merge without admin bypass, exact PR/head/base readback and main ancestry. Legacy delivery remains for unrelated projects.

Final make check: exit 0, 28 offline suites passed, zero failed; 26 skill contracts and syntax passed. Includes 18 ledger/focus tests, 25 worker-handoff/picker tests and 22 merge-train/protected-delivery tests. Two model-backed suites excluded. Final measured gate wall time: 8.871 seconds. Scoped shared/Wing diff checks and five policy links/anchors passed. Exact outputs and durations are retained in final-verification.json. Learned verification procedures were saved in the autogoal maintenance and merge-train references after review.

## Decisions and corrections

Keep existing M1 slices rather than duplicate cards. Add backward-compatible ledger focus and read-only query. Inspect real injected worker/delivery commands, not prose alone. Initial RED checks exposed the missing focus reader and stale worker delivery/review text. Both were corrected and rerun. Old review-policy assertions now require the accepted once-only corrected request, preserving original-card/no-bypass/review-lane invariants. No product acceptance was weakened.

## Open issues

The orchestration change is saved locally, not merged into main. No protected PR or live delivery run occurred, so remote branch protection, checks, permissions and merge remain unqualified. Existing dirty/shared work is preserved and must be attributed into small coherent PRs rather than swept. No installed cron payload, schedule or current worker was changed; future adoption is not observed worker behavior. No model-backed two-pass bare repo-docs behavioral test ran. Token/monetary totals and full manual-review duration are unavailable; no savings inferred.

Product M1 remains partial: integrated live generation/approval/Stop/relaunch/restored send is unqualified, and exact authoritative provider/model-pair restart read remains unsupported. This policy pass is not product qualification.

## Next action

Follow-up: requested `npm run test` was executed, but the foreground transport
interrupted it after 420 seconds. Four widget failures preceded interruption
(session-disclosure and gateway-switch), followed by a shutdown error. Log:
.task-evidence/autogoal-workflows-npm-test.log. The repair changed only two widget-test harnesses: date groups are scrolled into
view before asserting lazy children, and scroll finders identify the vertical list
instead of also matching nested horizontal controls. Acceptance assertions remain.
The fresh full background `npm run test` completed successfully: exit 0,
3650 tests passed, zero failure entries. Flutter elapsed time 10:35; measured
subprocess wall time 639.042 seconds. The 1500-second limit was not reached.
Log: `.task-evidence/autogoal-workflows-npm-test-final.log`.
Terminal receipt: `.task-evidence/autogoal-workflows-npm-test-final.json`.
These are Flutter unit/widget results, not live/device or main delivery evidence.

The next eligible Wing slice is PARITY-LIVE-WORKFLOW. In a fresh picker occurrence, reconcile live ownership and target authorization, then dispatch that slice or the scoped restored-send fallback if live prerequisites cannot safely proceed. Separately, the integration owner must package these local orchestration changes and attributed product slices through protected PRs, satisfy real required checks, and verify merged main before reporting delivered. No schedule edits, worker restarts, commits, pushes or real merges occurred in this pass.
