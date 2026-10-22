# Main offline test repair

Owning task: `MAIN-REPAIR-001`. This is repair of five observed failures, not
new product scope, flaky-test classification or native/live qualification.

## Evidence inspected

Read in place, relative to the Git common directory:
`autowork-execution/main-evidence/c746ad997d6d5c7f48eb3e69a63ba36f1df9554a/`.
Do not copy its raw files into this checkout or a commit.

- `main_check.json`: `state=red`, `result_class=TEST_FAILURE`, checked revision
  `c746ad997d6d5c7f48eb3e69a63ba36f1df9554a`, previous green
  `66c8a28e02863bc49f0c83d284e9cce712cdc04f`. Its `commits` list retains the
  integration history; the latest pair is `c746ad99` / `2d3d661d` (task docs).
- `main-check.log`: five failure records and terminal line 4765,
  `20:39 +4137 ~9 -5: Some tests failed.`
- `main-check.exit`: `1`; `main-check-reruns.log`: empty;
  `flaky_history.json`: `{}`. No isolated reruns or three-revision flaky proof
  are available. Do not infer flakiness or claim a crash before results.

| Failing test | Retained failure and investigation lead |
| --- | --- |
| `test/tooling/plan_backlog_traceability_test.dart`: every retained plan has an explicit canonical backlog disposition | Line 75: 34 mapping entries versus 35 retained plans. The current index omits `docs/plans/2026-10-21-desktop-literal-clone.md`, added by `cfe5662b`. Inspect its stated pending-admission boundary and add an honest disposition/backlog connection without inventing admission, completion or qualification. |
| `test/features/hermes_chat/screens/hermes_chat_gateway_confirmation_owner_test.dart`: Contact departure confirmation system back at 1280.0 and 390.0 | Line 368 expects a dialog after one Back. `6c82c059` deliberately consumes Back while the composer has focus. Trace the fixture focus and retain the first-Back dismissal regression; make the departure test exercise the subsequent unfocused departure path, not undo the delivered behavior. |
| `test/router/chat_workspace_overlay_test.dart`: shell /settings retains mounted chat/full location via back at 390.0 and 1200.0 | Lines 611/613 seek Chat/category-chat, which is absent without spellcheck. `7f2f166e` moved Voice to its own category; `3ecdaea0` and `dba56cad` added category deep links/URL identity. Exercise the current Voice entry while preserving nested Back, mounted Chat, exact full URL, focus, draft, scroll and zero-mutation assertions. |

These are source-backed investigation leads, not fresh reproductions or proven
product causes. Compare the failing tests with the nearest working regressions:
`hermes_chat_gateway_switch_test.dart`, `settings_screen_test.dart` and
`settings_routes_test.dart`. Prefer fixture/expectation repairs when those tests
lag intentional behavior. A demonstrated existing Wing defect in the named
shared paths may be repaired within the same boundaries; no redesign, restored
empty category, reverted composer-dismissal behavior, skip or weakened assertion.

## Linux review finding

Read both reports under Git-common
`autowork-execution/slot-data/LINUXQA-001-e41e98e5/attempt-{1,2}/report.json`.
They name candidates `ebbc3beff8a7100481695992e616b025bf68b239` and
`f61780107da910bc845bc840e63fd23463b02d11`. The second reports 17 synthetic
passes, receipt self-checks and preflight exit 0 with `ready=false`; these are
historical worker reports, not current native qualification.

The retained runner `review-findings/LINUXQA-001-e41e98e5.json` names integration
`382c45952db37672ac187565d3398d412be4686f` and findings in the same three test
files above. Its verdict is truncated; the main bundle supplies all five exact
cases. Candidate Python/quality-doc changes do not establish the cause of these
main failures. Do not reimplement or close the Linux task based on its report.

At inspection the runner status reports zero active workers but one merge-backlog
entry, with `LINUXQA-001-e41e98e5` integrating. Its record, acceptance and successor
dependencies are therefore left untouched. This repair is first in Now and has
disjoint Touches from that candidate, so the existing Linux contract need not
absorb unrelated product/test repairs. After repair, the runner can re-evaluate
the retained candidate with its normal review/full-check gates; no bypass,
coordinator receipt or manual qualification is introduced.

`CHECK-RESULTS-001` owns a different, explicitly test-repair-excluding reporting
contract. Its historical broken-reader bundles are not evidence that this new
bundle lacks results. It is not a prerequisite for this repair and its accepted
wrapper contract is not silently closed or superseded here.

## Worker checks and boundaries

Use the [documented setup](../../CONTRIBUTING.md#setup), Flutter 3.44.2 with its
matching Dart SDK, without lockfile changes. First reproduce the named failures;
retain actual results, including any changed failure inventory. Then repair only
the evidenced causes and run the focused targets, changed-file formatting,
analysis and task validation. Under the worker execution contract, the coordinator
runs the unchanged [full offline check](../../AGENTS.md#validation) on the merged tree:

```sh
flutter pub get --offline --enforce-lockfile && flutter test --no-pub --concurrency=1
```

Do not filter the full inventory, fabricate summaries, suppress nonzero exits,
change installed Autowork/Agent/SDK, or infer a green suite from focused passes.
Preserve all owner, approval, Stop, replay, focus and resource-identity fences.
The [literal-clone plan](../plans/2026-10-21-desktop-literal-clone.md) and
[Linux plan](../plans/2026-10-21-linux-feature-qualification.md) remain their
existing scoped authorities, not permission for new features or live operations.

## Worker repair evidence

Source baseline: `353f302cd4eb31c1b6be126270bb3568c8be9a3e`, isolated
`autowork/MAIN-REPAIR-001`. Toolchain: Flutter 3.44.2 framework `c9a6c48423`,
Dart 3.12.2, Linux host widget tests only; no native app or live Agent exercised.

The seven-target command below first reproduced exactly the five recorded
failures, including the refreshed native-closure traceability failure
(`PARITY-LIVE-WORKFLOW-LIVE needs exactly one task body; found 0`). After the
bounded repair it passed `+174`, exit 0, without skips or retries. Production
Chat, Settings and router code is unchanged:

- Native closure is not an archive receipt. `planTaskBody` now accepts a
  `manualClosure` done record and returns its own body, while the traceability
  caller passes the record body only for that case. Done records that still have
  a frozen checkbox entry keep the exact archive guard; malformed-record, filename
  identity, exact-body isolation and backlink checks are unchanged. No owner
  closure is reopened and no receipt, live proof or goal qualification is invented.
- `cfe5662b` added the literal-clone plan without a mapping/backlog section. Its
  disposition is **Proposal**, with new CLONE-* work still pending admission. The
  plan links this repair task only for traceability, not clone implementation; no
  task status, contract or admission is changed.
- `6c82c059` intentionally consumes focused-composer Back. The two contact cases
  now assert that first Back only dismisses focus, retaining owner, session,
  controller, draft and streaming work with zero mutations, Stop or disconnect.
  Second Back reaches the existing guarded confirmation. Stale-owner, cancellation,
  queued-work and approval coverage remains unchanged.
- `7f2f166e` separated Voice from Chat; `3ecdaea0` / `dba56cad` added category
  intent and identity. The two nested-Back cases now select Voice, verify the
  active `config:voice` route, open voice details and Back to the same category.
  Closing then returns to the identical mounted Chat/full location, draft/controller,
  scroll and focus, with no sends, Stop, disconnect, approvals or session mutations.
  Close/Escape and existing category/deep-link cases remain covered. Imperatively
  pushed overlays are inspected through `router.state.uri`; the preserved caller
  URL still uses `routeInformationProvider` as before.

Focused check (exit 0, all 174 cases passed):

```sh
flutter test --no-pub --concurrency=1 \
  test/tooling/plan_backlog_contract_test.dart \
  test/tooling/plan_backlog_traceability_test.dart \
  test/features/hermes_chat/screens/hermes_chat_gateway_confirmation_owner_test.dart \
  test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart \
  test/router/chat_workspace_overlay_test.dart \
  test/features/settings/settings_screen_test.dart \
  test/router/settings_routes_test.dart
```

`flutter pub get --offline --enforce-lockfile` exited 0 without lockfile changes;
`flutter analyze --no-pub` exited 0 with no issues. The eleven-path formatting
check from the task contract exited 0 with no changes. The focused tests and
analysis ran through `autowork-run`; no sharded repository check runner is present.

### Failed integration inventory, not acceptance

Integration `8f732bf465c9f257823a14b2b24aeab8b6a7fc33` failed its full gate with
21 failures (terminal `24:35 +4121 ~9 -21`): the recorded traceability failure
plus 20 others, beyond the truncated review verdict's four names. Twenty
failures are loopback address-in-use collisions on ports 20101/20128/20131/20132
across `managed_ssh_serve_test.dart`, `managed_ssh_serve_reads_test.dart` and
`managed_ssh_session_recovery_test.dart`, plus secondary cleanup errors and later
`core/hermes/channel` lifecycle/restoration/reads/credential and
`core/hermes/client` history-export/web-lifecycle/adversarial fixtures. The
isolated-rerun record is `incomplete=true` with an empty log, so it proves neither
flakiness nor baseline equivalence. These transport fixtures are outside this
task's unchanged Touches and are not reproduced or repaired here; resource/isolation
ownership stays with the normal runner gate. They are not reported as a passing
result and do not escalate to a product regression claim.

The full unchanged offline gate is reserved for the coordinator's merged tree,
not run or claimed by this worker. Main is **not** declared green from these
focused passes. No clone parity, Linux campaign acceptance, physical Android
IME/Back, voice, provider, native/live or release qualification follows.

## Maintainer checklist

- [x] Read all five main bundle files in place and inspect failure blocks.
- [x] Read Linux task, source plan, reports, review finding and integration status.
- [x] Check all open tasks: none owns these five repairs; reporting task excludes them.
- [x] Record one bounded repair first in Now; preserve in-flight task contracts.
- [x] Worker reconciles native closure and retained candidate, and runs the focused tests, formatting and analysis above.
- [ ] Normal review and full-check gates establish the resulting candidate's verdict.

This handoff records the bounded worker repairs above; the original docs-maintainer
pass ran ledger/link/whitespace checks only, not Flutter or native/device tests.
No task acceptance, goal or platform support is qualified.
Revisit this handoff when the main failure inventory or Linux integration state changes.
