# M2 declared history-read admission — 2026-10-06

Card: `t_4e4a4f7d`. Ledger task: `DOC-M2-HISTORY-ADMISSION`.
Disposition: bounded shared-path repair, ready for native same-card review.
**M2 remains unverified; authoritative_counts_unavailable.**

## Delivered change and authority

Before this repair, a declared `session_messages` endpoint requiring an ungranted
scope was read twice during completed-run recovery/bootstrap. Its transcript was
admitted and the terminal durable lease removed. Now shared history hydration
and earlier-message pagination reject that operation before history I/O, cache,
model-history, transcript or lease settlement. A failed bootstrap explicitly
retains the unresolved-run flag and error-state Send refusal. Recreation retains
the same lease; a later authorized exact-owner/compaction read settles it without
replaying a mutation.

The existing `_capabilityEndpointAuthorized` helper remains the exact method/path,
supported-schema and all-required-grants authority. The history gate also reuses
the existing declared profile-scoped query/enrolled-path predicate. No new scope,
field, endpoint, transport, dependency or shadow state was introduced. A supported
legacy capability document omitting the baseline history advertisement still
permits ordinary history hydration/pagination. Null or unsupported documents do
not authorize a read. Strict remembered/off-page restoration still requires its
explicit advertised operations; lineage proof still requires fresh authorized
metadata/history probes. Those predecessor boundaries were not weakened.

## Inspected reference and shared caller trace

Read-only reference locations were confirmed as `hermes-agent/` and
`hermes-desktop/`; their root instructions were read. No reference or installed
runtime was patched or executed. This is an HTTP contract repair, not an Electron
interaction port. Agent `gateway/platforms/api_server.py:94,1768,3294–3328` registers
and authenticates the baseline history read, resolves the canonical compression
tip and bounds pages to 500 rows. The current checkout advertises the exact route;
the omitted-advertisement positive control preserves Wing's existing legacy
baseline behavior, not a fabricated claim about that checkout. Inspected upstream
`tests/gateway/test_session_api.py:116–146,232–264` covers bounded pagination and
compression ancestors. Required/granted scopes here are synthetic Wing policy
inputs, not newly asserted upstream server grants or a server authorization bypass.

The caller trace was recorded on the card before production edits:

- `_fetchTurns` is shared by connection bootstrap, profile/session selection,
  mutation-result hydration, event/terminal reconciliation and detached recovery.
- Bootstrap discovers capabilities before publishing channel state. Its call and
  detached recovery therefore pass the authoritative discovered document explicitly.
  Connected/profile-selection consumers already have that document in state.
- `_loadEarlierMessages` is the only other channel page consumer; it applies the
  same gate inside its error-handled read path and preserves good history/offset.
- Recovery catches failed terminal hydration before durable removal. Bootstrap
  retains that unresolved result even when its later history read fails.
- Existing connection/profile/session/caller generation fences, response identity
  and lineage checks remain. An explicit post-recovery connection check prevents
  publishing the old bootstrap outcome after replacement.

The three changed production files are existing parts of
`lib/core/hermes/channel/hermes_api_channel.dart:29–35`, with existing capability
imports. No import, part, manifest or packaging dependency was added; no delivery
closure correction is warranted. Flutter tests exercise these real imports, not a
packaged/native build claim.

## Captured baseline and discriminating regression

Task-owned evidence is under `.task-evidence/t_4e4a4f7d/`:

- [Baseline source receipt](../../.task-evidence/t_4e4a4f7d/baseline.json), original
  full-file bytes under `original/`, inherited tracked diff/status and Wing file
  fingerprints distinguish this delta from inherited dirty changes.
- [Command receipts](../../.task-evidence/t_4e4a4f7d/commands.json) bind every execution
  to source hashes, exact arguments, exit codes and SHA-256 log hashes.
- The first focused pass (63 tests) was superseded after adding the recreation
  control; its log label was reused. Its old hash receipt remains but that log is
  not retained or used for acceptance. Final focused 64-test log and all other
  acceptance logs are retained and independently hash-checked by the runner.
- [Task-relative delta](../../.task-evidence/t_4e4a4f7d/task-delta.patch) is the review
  diff, not the entire inherited HEAD-to-worktree diff.
- `validation.json` checks log integrity, source/mirror equality, preserved
  inherited files, scoped whitespace and local report links.

The intended ungranted-history oracle was installed before production editing.
Captured-baseline RED exited 1: expected zero history reads, observed two. The
same oracle/test bytes on repaired source exited 0. The final focused run retains
that oracle and adds a distinct recreation/unresolved-flag/authorized-compaction
control; no RED assertion was weakened. The RED was a behavioral failure, not
compile, import or harness failure.

Final coverage includes declared ungranted scope, wrong method, wrong path,
unsupported schema and unsupported declared profile context (zero history I/O);
exact explicitly granted scopes and omitted legacy advertisements; current-session
selection/pagination refusal without replacing history/offset; durable recreation
then authorized compaction; malformed/foreign identity; compression proof; late
connection/lineage/status/history replacement; caller invalidation and gateway
profile/session/origin replacement. Denied recovery observes zero mutation attempts
and no streams. The death-completion widget is deterministic client disposal, not
real OS process death. Expiry/revocation and runtime grants remain unqualified.

## Executed commands and results

All Flutter commands ran in `.task-evidence/t_4e4a4f7d/isolated-project/`, with
copied Wing sources/assets/manifests, offline dependency resolution and its own
build/test state. Retained root tester PID 96817 was never signalled. Upstream
references and parked approval-dismissal/disconnect-confirmation tests were not
copied into execution scope. No live request, listener, credential acquisition,
inference, install or browser/native exercise occurred.

```text
flutter pub get --offline                                             exit 0
flutter test --no-pub --concurrency=1 --reporter=expanded
  test/core/hermes/channel/hermes_recovery_read_admission_test.dart
  --plain-name 'ungranted history refuses hydration'
  captured baseline RED                                               exit 1 (0 versus 2 reads)
  identical oracle GREEN                                              exit 0 (1 passed)
flutter test --no-pub --concurrency=1 --reporter=expanded
  test/core/hermes/channel/hermes_recovery_read_admission_test.dart
  test/core/hermes/client/hermes_history_identity_test.dart
  test/core/hermes/channel/hermes_session_caller_admission_test.dart     exit 0 (64 passed)
flutter test --no-pub --concurrency=1 --reporter=expanded
  test/core/hermes/channel/hermes_api_channel_test.dart
  test/core/hermes/hermes_api_test.dart                                 exit 0 (432 passed)
flutter test --no-pub --concurrency=1 --reporter=expanded
  test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart
  test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart
  test/features/hermes_chat/gateways/hermes_directory_lifetime_test.dart
  test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart
                                                                      exit 0 (43 passed)
flutter analyze --no-pub                                               exit 0 (no issues)
dart format --output=none --set-exit-if-changed
  lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart
  lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart
  lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart
  test/core/hermes/channel/hermes_recovery_read_admission_test.dart      exit 0 (unchanged)
```

Root reproduction: `python3 .task-evidence/t_4e4a4f7d/check_history.py verify`.
The runner performs task-relative `git diff --no-index --check` and local-link
checks; it does not conflate inherited root diffs with this scoped patch.

## Acceptance and review handoff

| Criterion | Source-bound evidence |
| --- | --- |
| 1. Declared denial before read/effects; legacy/granted controls; owners/no replay | Shared gate in connection and pagination; explicit discovered document in detached recovery; RED/GREEN oracle; final focused 64-case target set and 43 caller tests, including durable recreation and authorized compaction. |
| 2. Format/analyze/nearest tests, hashes, retained dirty work and bounded claims | Exact commands/exits above; command/source fingerprints; validation and task-relative delta; nearest 432 tests; no changed imports or packaging manifests. |
| 3. Exact-task ledger and single independent lane | Supported goals.py exact-task update only after validation; M2 stays unverified. Shared goal evidence/TODO rendering belongs to reserved repo-docs cron ba15b4ed8db6; handoff.json carries exact executed commands and current fingerprints. Native same-card review is the sole independent approval lane, not yet approval. |

NOT_CHECKED: live Agent/network/inference, server accepted/rejected mutation
counters, named Android device/keystore/OS death/notifications, physical/native
desktop interaction, browser, full suites, packaged runtime/build/APK, release,
deployment and credential expiry/revocation. The predecessor's named-device and
counting prerequisites remain unchanged; no M2 or Desktop parity promotion follows.
No new task or extra reviewer was created. No owner choice changes the bounded
implementation. Any local-branch receipt is recorded separately in the handoff;
shared HEAD/index, push/merge/rebase/amend and publication are not part of this repair.
