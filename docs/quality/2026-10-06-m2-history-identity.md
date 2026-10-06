# M2 canonical history identity

Task: `t_cd72a5d5` / `DOC-M2-HISTORY-IDENTITY`. Implementation evidence for native
same-card review, not final approval. Goal M2 remains **unverified**;
`authoritative_counts_unavailable` remains the accounting ceiling.

## Delivered change

Previously, an unrelated history envelope or row could enter the requested
session's transcript/pagination/model-history caches and remove a terminal run's
durable lease. The shared HTTP page boundary now rejects malformed or unrelated
identity before returning a page to any of those consumers. Failure retains the
lease; bootstrap reports an incompatible connection and refuses Send. Earlier
pagination retains the good transcript and offset, reports failure, and permits
an explicit read retry. Later exact history settles without mutation replay.

The model retains the existing authoritative `session_id` envelope. It requires
`object: list`, bounded string envelope/row owners and a list of at most 500 map
rows. No ownerless, numeric, normalized, silently dropped or foreign-tail rows
can bypass validation. Pagination defaults for supported exact-owner legacy
pages are unchanged. Actual Agent source always supplies envelope and row
identities; missing identities in old synthetic fixtures were not an upstream
legacy contract and are now rejected.

Exact pages need no additional reads. A differing row owner or resolved tip is
accepted only through fresh Agent evidence on the same client/profile:

1. Require supported, advertised GET session metadata and history operations,
   every declared grant and supported profile context.
2. Walk backward from the envelope's exact metadata, stopping at 100 distinct
   sessions. Every accepted parent must have ended `compression`.
3. Read a bounded one-row history probe for each parent. Its canonical envelope
   must resolve to the original page's tip. Parent pointers alone cannot authorize
   fork/reset/delegate history; divergent resolution fails closed.
4. Require both the requested session and all row owners to occur on the proven
   chain. Ignore response-supplied lineage lists and client inventory/cache claims.

Malformed parent metadata is rejected before normalization. Missing metadata,
unsupported grants, cycles, non-compression edges, divergent tips or over-bound
proof fail without partial admission. The probes are read-only identity evidence;
their rows are never merged into the requested page or caches. There is no new
API, protocol field, dependency, domain state, transport, mutation or replay.
Unverified non-compression continuation redirects remain unavailable rather than
being guessed from a parent pointer.

## Source authority and caller closure

Read-only Agent reference revision: `158fd638da1629c8e62caf9ade1515d162def8ab`.
The reference Agent/Desktop instructions and Wing CONTEXT, CONTRIBUTING, ADR
index/client/API/runtime, security policy and threat model were inspected. Agent,
Desktop and Conduit were not changed or executed.

Authority traced:

- `hermes-agent/gateway/platforms/api_server.py:3295-3328`: existing-session check,
  canonical resume resolution, root-to-tip ancestor rows, resolved envelope and
  bounded pagination. `3011-3043` and `3214-3219` expose parent/end-reason metadata
  without model configuration or its private fork markers.
- `hermes-agent/hermes_state_messages.py:1463-1502`: authoritative resume
  resolution excludes branch/delegate/reset/tool children. `1669-1695` verifies
  compression ancestors rather than treating every parent as lineage.
- `hermes-agent/hermes_state_compression.py:749-761`: compression parent predicate.
- `hermes-agent/tests/gateway/test_session_api.py:232-284`: root-to-tip compression
  outcome and explicit branch marker. The safe metadata API does not expose that
  marker, so Wing does not invent a metadata-only branch classifier.
- `hermes-agent/tests/hermes_state/test_resolve_resume_session_id.py:61-84`:
  a compressed remembered parent resolves to its live continuation even when it
  retains messages. These upstream tests were inspected, not run.

Changed production files are only the existing session model and HTTP client.
`sessionMessages()` delegates to `sessionMessagesPage()`. The two direct page
consumers are `_fetchTurns` and earlier-history pagination. `_fetchTurns` is used
by connect, profile selection, session selection/create/delete/fork, direct/run
completion hydration, detached terminal recovery, reattachment hydration and
foreground reconciliation. Existing connection/profile/session/caller fences
run after the now-complete client future and before admission. Existing terminal
recovery catches history failure before durable removal. `_turnsFromHistory` may
present proven ancestor rows in the selected transcript; it no longer receives
unvalidated HTTP rows. `getSession` also serves off-page restoration, covered by
the restoration suites below. No production channel or messaging change was
necessary.

## Discriminating evidence and acceptance map

| Acceptance | Artifact and executed observation |
| --- | --- |
| 1: independent envelope and row rejection | `hermes_history_identity_test.dart` separately rejects foreign envelopes with exact rows, foreign rows with exact envelopes, empty foreign pages, absent/numeric owners, non-map/oversized rows and untrusted lineage claims. Recovery and pagination controls independently run against predecessor production bytes: four behavioral failures, not compilation failures; current production passes. |
| 1: pre-admission and durable ownership | `hermes_recovery_read_admission_test.dart` checks empty transcript/pagination on rejected bootstrap, unchanged lease, duplicate Send refusal and zero fixture mutations/streams. Earlier-page substitution preserves good transcript/offset and retries the same offset. Source inspection confirms the shared boundary returns before recent-turn/model-history/pagination cache writes. |
| 1: compaction and baseline positive controls | Exact pages preserve defaults with one read. Multi-hop ancestors and old-handle resolved tips pass with authoritative metadata/probes; branch/non-compression/cycle/malformed-parent controls fail. Verified ancestor terminal recovery clears the lease with zero replay. |
| 2: owner replacement and retry | Parked lineage proof across disconnect keeps the lease and publishes nothing. Existing origin/profile/session/status/history and caller-generation tests pass; an explicit profile control proves every metadata/probe read stays on the requested origin/profile. Recreated channel with later exact history settles the retained lease with zero mutations/streams. |
| 2: regressions | Focused client/recovery: 48 passed. Nearest model/client/channel: 432 passed. Restoration/caller/lifetime/picker ownership: 63 passed. Changed-file formatter passes; Flutter analyzer reports no issues. |
| 3: source-bound receipt | Task-local before/after fingerprints, exact command arrays, exits and log SHA-256s are in the receipts below. No goal/platform/build/release acceptance is inferred from unit/widget tests. Native review is requested separately. |

All counts above are Linux Flutter unit/widget fixture counts, not server
accepted/rejected mutation accounting or OS process-death evidence.

## Commands, iterations and integrity

All Flutter checks ran in a task-owned isolated Wing mirror containing only Wing
source/tests/assets and package manifests, with offline dependency resolution.
No upstream repositories, shared builds, private runtime data or excluded original
Disconnect/approval-dismissal evidence were used. Those original suites were not
run; their mirror-only test copies were removed before final analyzer verification.
The retained predecessor tester PID 96817 was observed and never signalled.

[Exact commands and exits](../../.task-evidence/t_cd72a5d5/commands.json),
[before snapshot](../../.task-evidence/t_cd72a5d5/before.json), and
[final validation/fingerprints](../../.task-evidence/t_cd72a5d5/validation.json)
are the canonical detailed receipt. Runner:
`python3 .task-evidence/t_cd72a5d5/check_identity.py`.

Executed final checks:

- `dart format --output=none --set-exit-if-changed` on the 14 changed Dart files:
  exit 0, zero changes; exact file array is in `format-check-fixed.log`'s receipt.
- `flutter test --no-pub --concurrency=1 --reporter=expanded
  test/core/hermes/client/hermes_history_identity_test.dart
  test/core/hermes/channel/hermes_recovery_read_admission_test.dart`: exit 0,
  48 passed (`final-focused-fixed.log`).
- `flutter test --no-pub --concurrency=1 --reporter=expanded
  test/core/hermes/hermes_api_test.dart
  test/core/hermes/channel/hermes_api_channel_test.dart`: exit 0,
  432 passed (`final-nearest.log`).
- `flutter test --no-pub --concurrency=1 --reporter=expanded` with the six exact
  targets in `final-callers.log`'s receipt: session caller admission, deterministic
  death/completion recovery, gateway restoration, adversarial restoration,
  directory lifetime and session-picker load ownership: exit 0, 63 passed.
- `flutter analyze --no-pub`: exit 0, no issues (`final-analyze-fixed.log`).
- Task-baseline-relative `git diff --no-index --check` for each authored file:
  checked by the receipt verifier, avoiding unrelated shared-worktree changes.

Initial nearest/caller runs exposed synthetic histories missing envelope/row
identity or reusing session-one history for session two. The focused fixtures
were corrected to the actual Agent contract; their behavior assertions remain.
The original combined wrong-history characterization is now a rejection assertion.
A new enum import fixed a test-harness compile error; its failed logs are retained
but do not count as RED evidence. Four subsequently executed independent
behavioral RED failures are in `red-independent-final.log`. The final current
test bytes were also rerun against predecessor production bytes in
`red-source-bound.log` (four behavioral failures), then restored production passed
48 tests in `green-source-bound.log`; these command receipts include input hashes.
An analyzer
flow-control style warning was fixed; failed and corrected receipts remain.
No production gate or assertion was weakened to obtain GREEN.
The first local commit attempt aborted because `.log` is repository-ignored;
the helper had not written its ref. Rather than alter the ignore policy or force
stage, `logs.json` archives the exact log text and verified hashes for the task
branch. Local raw logs remain available at their original receipt paths.

Predecessor receipt `t_3a5135a8/review-398-validation.json` was verified before
editing: all seven logs and five source hashes matched. Its original bytes and
receipt digest remain recorded. Only unchanged inputs can carry evidence forward;
this task reruns the affected seams rather than claiming that old hashes qualify
changed code. Task delta is relative to saved dirty-file baselines, preserving
inherited edits in scoped files and unrelated worktree state.

## Review, ledger and limits

Shared TODO/goals rendering belongs to repo-docs; no shared ledger was edited.
Reserved-writer handoff after native approval:
`python ~/.hermes/shared-skills/repo-docs/scripts/goals.py task <repo>
DOC-M2-HISTORY-IDENTITY done`, then record each exact passing check from
`commands.json` with `goals.py evidence <repo> M2 --kind executed --ref
"<exact command>" --result pass`, then `goals.py render <repo>`.
Keep M2 unverified and the accounting ceiling unchanged. The task-local commit
receipt records the authorized local agent branch/SHA without changing checked-out
HEAD/index; its scoped snapshots retain inherited dirty bytes, not a claim that
those predecessor changes were authored here.

**NOT_CHECKED:** live Agent/network/credentials/inference, Android/device/keystore,
OS death, notifications, authoritative mutation counters, physical desktop,
native-web production qualification, product builds, packaged execution, browser,
full suites, Wing Link, signing, release, deployment or publish. Imports and
packaging boundaries did not change, so no packaging closure repair was added.
Declared-history-grant admission for exact baseline history remains the separate
DOC-M2-HISTORY-ADMISSION slice; its existing characterization is retained, not
waived or claimed fixed here.

Questions: none. Existing supported contracts/defaults applied; native same-card
review is the remaining approval lane, not a blocker or live-M2 acceptance.
