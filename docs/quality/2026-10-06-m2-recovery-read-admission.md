# M2 exact-owner recovery read admission — 2026-10-06

Card: `t_3c5078de`. Ledger task: `DOC-M2-RECOVERY-READ-ADMISSION`.
Disposition: **bounded deterministic characterization delivered; unconditional recovery admission refused**.
The exact completed-status + successful history path is demonstrated. Two current
ownership ambiguities prevent treating every lease settlement as admitted recovery.
An additional declared-history-grant control exposes an admission-policy gap.
**authoritative_counts_unavailable** and **M2 unverified** remain mandatory.

## Scope and source binding

Agent is the authoritative data plane. Wing Link is neither involved nor a fallback.
The read-only reference is `hermes-agent/`, HEAD
`158fd638da1629c8e62caf9ade1515d162def8ab`; its root instructions were read before
inspection. Desktop is the separately documented `hermes-desktop/` reference;
no Desktop source or runtime was needed for this HTTP contract slice.
Wing branch is `main`, HEAD `4acdb4e1f51262ccfdca5174776eed1e3ef65188`.
These revisions describe checkouts, not installed runtimes. Dirty source bytes
are bound by [the source receipt](../../.task-evidence/t_3c5078de/source-snapshot.json),
with selected per-file hashes and a Wing input-closure digest excluding this new test.
Agent modules/tests were never imported, run or patched.

Existing production, existing tests, shared harnesses, other receipts and retained
root tester/build state remain unchanged. Only this report, the new focused test
and task-owned evidence were authored. Flutter ran in
`.task-evidence/t_3c5078de/isolated-project/`, with copied Wing sources/assets/manifests,
its own `.dart_tool` and build output, offline dependency resolution and injected
HTTP methods. No listeners, deployment, credential acquisition or inference ran.
The mirror is local execution state, not a deliverable or runtime distribution.

## Existing HTTP contract → Wing caller

| Read | Advertisement, authorization and ownership | Output, limits and error meaning |
| --- | --- | --- |
| Discovery `GET /v1/capabilities` | Agent `hermes-agent/gateway/platforms/api_server.py:2536–2575` uses authenticated Bearer discovery; static features and exact routes at `hermes-agent/gateway/platforms/api_server.py:67–102`. This checkout does not emit `schema_version`, per-endpoint scopes or query-profile metadata. Wing `lib/core/hermes/models/hermes_capabilities.dart:15–58` treats absent schema as legacy schema 1. | Runtime advertisement remains necessary; checkout inspection does not qualify a deployment. Wing's optional declared scopes are policy inputs, not grants invented for this upstream API. |
| Status `GET /v1/runs/{run_id}` | `hermes-agent/gateway/platforms/api_server_runs.py:1023–1061` authenticates before ownership lookup. API-key namespace hashes routed profile/key; room-grant namespace includes room/home/authority epoch/member/target install/profile, with exact `status` permission (`hermes-agent/gateway/platforms/api_server_runs.py:352–381`). Wing recovery uses its direct API client, not room credential acquisition. | Status includes run ID, lifecycle/timestamps and optional session/output/error/usage (`hermes-agent/gateway/platforms/api_server_runs.py:258–283`). It is execution status, not canonical history or an attempt counter. Missing, foreign-owned and ownerless runs all produce `run_not_found` 404 (`hermes-agent/gateway/platforms/api_server_runs.py:203–204`). A 404 does not distinguish those conditions. |
| Canonical history `GET /api/sessions/{session_id}/messages` | `hermes-agent/gateway/platforms/api_server.py:3294–3328` uses API-key authentication and the profile-scoped SessionDB; it is not authorized by the run-status room grant. Profile routing/auth at `hermes-agent/gateway/platforms/api_server.py:1562–1608` and `hermes-agent/gateway/platforms/api_server.py:1720–1743` binds URL-selected profile and rejects unconfigured prefixes. Session absence at `hermes-agent/gateway/platforms/api_server.py:3063–3070` is `session_not_found` 404. | Handler resolves resume lineage; response `session_id` is the resolved tip, with root→tip messages and ancestors, bounded to 500 records/page. Pagination is nonnegative limit/offset, oldest/latest. This is not a fixed byte-size guarantee or a whole-history snapshot/revision guarantee. Legitimate compression lineage means blindly rejecting every ancestor message ID would be wrong. |

Ordinary in-memory terminal status retention is 3600 seconds, SSE buffer retention
300 seconds (`hermes-agent/gateway/platforms/api_server.py:4385–4386`);
`hermes-agent/gateway/platforms/api_server_runs.py:1284–1302` expires buffers without
assuming a live task has ended. Keyed submissions may persist status with 24-hour
reservation retention and in-memory fallback
(`hermes-agent/gateway/platforms/api_server_run_idempotency.py:53–84`). Stale durable
nonterminal owners become `interrupted`
(`hermes-agent/gateway/platforms/api_server_runs.py:395–418`). Wing's `startRun`
does not send an idempotency key; these conditional guarantees cannot be attributed
to all Wing runs. No terminal-history retention duration follows from run TTL.
Interrupted/native lifecycle handling is outside the executed completed matrix.

Nearest upstream tests, inspected only:

- `hermes-agent/tests/gateway/test_api_server_runs.py:237–258`: start/status envelope.
- `hermes-agent/tests/gateway/test_api_server_runs.py:1207–1248`: ownerless and
  foreign-profile get/Stop return 404, while creating profile gets 200.
- `hermes-agent/tests/gateway/test_session_api.py:116–146`: default latest 500-record
  page and explicit oldest pagination.
- `hermes-agent/tests/gateway/test_session_api.py:232–264`: compression ancestors.
- `hermes-agent/tests/gateway/test_api_server.py:937–972`: capability/idempotency
  advertisement, not installed-runtime admission or live counting.

Wing `lib/core/hermes/policy/hermes_transport_policy.dart:27–29` and
`lib/core/hermes/policy/hermes_transport_policy.dart:73–87` require exact status
feature/method/path, schema, all declared scopes and supported declared profile context.
Recovery `lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart:2092–2182`
filters canonical base URL/profile/session, captures connection/profile generations,
checks returned run/session IDs and fetches history before terminal lease removal.
`lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart:76–109`
first discovers listed sessions, then recovers detached candidates and reads selected
history. A later bootstrap history read can occur even when status is denied/mismatched;
that read is not evidence that the failed status was accepted.

`lib/core/hermes/client/hermes_api_client.dart:227–259` requests latest history,
limit 500/offset 0. `_fetchTurns` checks generation and pagination before accepting
history/cache (`lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart:329–391`).
It does not gate `session_messages` declared scopes or preserve/validate the response
session envelope: `lib/core/hermes/models/hermes_session.dart:229–275` discards it.
`lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart:394–443`
assigns requested session to returned turns. Exact request identity and a current
async generation are necessary, but not sufficient proof of response history identity.

## Executed acceptance matrix

[Focused test](../../test/core/hermes/channel/hermes_recovery_read_admission_test.dart)
uses synthetic handles/content, an in-memory durable-store seam and injected reads.
Every mutation method (POST/PATCH/PUT/DELETE/POST stream) is counted; streams are
counted separately. No real transport or secure storage is used.
Characterization assertions deliberately record observed defects; green does not
mean those rows satisfy the desired ownership boundary or approve their behavior.

| Case | Executed observation | Admission |
| --- | --- | --- |
| Exact completed | One exact status read; two canonical-history reads (recovery + bootstrap); canonical message ID/text admitted, status output never substituted; saved lease empty | Admitted deterministic positive path only |
| Absent 404 | Lease removed; one bootstrap history read; no unreconciled guard | Absence policy characterized, NOT completed-history authority |
| Foreign/ownerless-equivalent 404 | Same status exception/result as absence: lease removed | Ownership distinction unavailable; refused as exact-owner completion |
| Status denied 403 | Lease retained; unreconciled guard true; bootstrap may read current session history | Denial retained, not accepted status |
| Wrong run / wrong session in completed status | Lease retained; no terminal recovery hydration; one bootstrap history read | Replacement status rejected |
| Completed + history denied / absent | Lease retained; recovery history fails, bootstrap also fails; no visible messages | Terminal status alone cannot settle history |
| Completed + unrelated history envelope/row | `message_b` / synthetic foreign text admitted as requested `session_a`; lease removed | Refused: response-identity defect reproduced |
| Status endpoint requires an ungranted declared scope | Zero status reads; lease retained; unreconciled guard true | Operation admission denial demonstrated |
| History endpoint requires an ungranted declared scope | Two history reads; lease removed despite missing scope | Refused under Wing's declared-scope policy; synthetic advertisement control, not a grant emitted by this Agent checkout |
| Replacement origin/profile/session lease tuple | Zero status reads for old lease; old lease retained | Tuple filtering demonstrated; no live profile multiplex claim |
| Replacement connection during pending status/history | Disconnect awaited before response release; no visible stale history and old lease retained | Async owner fence demonstrated |

All matrix cases observe **zero fixture mutation attempts**; no events stream opens
in these completed/uncertain recovery checks. Counts are fixture-only, not accepted/
rejected server accounting. The nearest existing terminal-history recreation test
also passes, demonstrating later successful read removes the retained lease.

## Precise next repair findings (not implemented here)

1. **Ambiguous status 404 releases uncertain ownership.** The handler intentionally
   conceals foreign/ownerless state behind 404; Wing's comment attributes 404 to a
   process-local registry/restart and removes the durable lease. A valid profile
   key can still be the wrong owner namespace. The two identical injected outcomes
   prove Wing cannot distinguish them, not that a real run was absent or completed.
   Next repair: retain unresolved ownership on indistinguishable 404; expose an
   accurate unresolved read outcome rather than automatically clearing the guard.
   Reconcile only with existing authoritative contracts, no new endpoint or shadow state.
2. **History response identity is unvalidated.** An unrelated synthetic envelope
   and row are published under the requested session, then terminal ownership is
   settled. Next repair: preserve authoritative response/lineage identity through
   the page model and validate accepted session lineage before caching/publishing/
   removing the lease. Preserve legitimate compaction ancestors and current-owner
   fences; arbitrary mismatch is not an authorized replacement session.
3. **Declared history admission is bypassed.** `_fetchTurns` calls the baseline read
   without checking exact advertised history operation/grants. Next repair must
   respect legacy baseline compatibility while refusing a declared ungranted
   endpoint. The synthetic control proves client policy drift, not upstream auth bypass.

No repair card was enqueued: this selected slice explicitly forbids another task.
These findings are the native reviewer/repo-docs handoff, not permission to patch
read-only production or reopen Disconnect/approval-dismissal work.

## Commands, iterations and integrity

All Flutter commands below ran inside the isolated mirror, recorded in
[commands.json](../../.task-evidence/t_3c5078de/commands.json):

```text
flutter pub get --offline                                             exit 0
 dart format test/core/hermes/channel/hermes_recovery_read_admission_test.dart
                                                                    exit 0
flutter test --concurrency=1 --reporter=expanded test/core/hermes/channel/hermes_recovery_read_admission_test.dart
                                                                    exit 0, 16 passed
flutter test --concurrency=1 --reporter=expanded test/core/hermes/channel/hermes_api_channel_test.dart --plain-name 'terminal hydration failure preserves durable retry across recreation'
                                                                    exit 0, 1 passed
flutter analyze                                                     exit 0, no issues
```

The first analyzer run exited 1 for the task-owned unawaited `disconnect` call;
awaiting it fixes the harness warning and makes ordering explicit. The initial
analyzer log/receipt are retained; corrected checks and stronger foreign-history/
grant controls were rerun. No assertion or production gate was weakened.
The initial preparation refused changed TODO bytes. Comparison found only TODO
ledger drift; all originally selected code/ADR inputs and original selection
receipt remained unchanged. The task-owned preparation check now records that
ledger drift separately, without refreshing selection or writing the shared ledger.
This is not a fresh selection, ledger-ownership release or source freshness waiver.

From repository root:

```text
python3 .task-evidence/t_3c5078de/check_recovery.py prepare
python3 .task-evidence/t_3c5078de/check_recovery.py test
python3 .task-evidence/t_3c5078de/check_recovery.py verify
```

[Validation](../../.task-evidence/t_3c5078de/validation.json) checks source/closure
fingerprints, checkout revisions, local links/citation ranges, sanitized JSON,
command-log hashes and task-scoped whitespace. These are integrity checks, not
live or Android acceptance. Runner logs contain redacted mirror/repo aliases.

## Remaining named-device proof and acceptance handoff

Keep [ANDROID-M2-DEATH-COMPLETE-01](2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01)
as the one remaining proof scenario, not another generic audit. Before execution:
name a newly owned disposable Android target/serial and QA-only package/storage;
qualify the exact APK/entrypoint and isolated cleanup; require an admitted M1
unmodified Agent run mode with explicit non-default profile/session and exact
status/history grants; acquire disposable credentials through a secret-safe path;
obtain consent for one bounded synthetic provider turn/cost; and admit a complete
accepted/rejected mutation-counter contract/continuous epoch/closed intervals.
Resolve the read findings above or preserve their refused cases explicitly.
With notifications denied, acknowledge durable lease before actual OS death,
observe completion while absent, relaunch same storage, match canonical identity/
history and prove zero restoration mutations through authoritative counters.
Expiry/revocation and wrong-owner controls remain required, not inferred from fixtures.

**NOT_CHECKED:** Android process death/keystore, named device, notifications,
credential expiry/revocation, live M1/M2, inference, runtime advertisements,
accepted/rejected counters, native-web RPC, packaging/APK/build/install, browser,
physical desktop, full suites, deployment and release. Native-web lifecycle remains
internal qualification only; no RPC/HTTP interchangeability or enabled transport
claim follows. No changed import or packaging manifest: only Flutter-test execution
of current production imports, not packaged-runtime equivalence.

| Acceptance criterion | Exact delivered evidence |
| --- | --- |
| 1. Existing routes/auth/tuple/history/bounds/errors | Source trace and upstream inspected-test ranges above; selected scoped fingerprints and checkout revisions. Ambiguous 404 explicitly not completion/count authority. |
| 2. Completed/absent/denied/replacement checks and durable settlement | New 16-case matrix + nearest one-case recreation pass; exact commands/exits and logs. Three bounded findings retained rather than production patches or weakened assertions. |
| 3. Counting ceiling, remaining scenario, changes/checks/handoff | `authoritative_counts_unavailable`, named-device prerequisites and NOT_CHECKED above; task-local handoff and validation receipts. No goal promotion or final independent approval claimed. |

Repo-docs cron `ba15b4ed8db6` reserves shared ledger maintenance. Fresh read-only
`goals.py next` still selects this task with M2 unverified; no reservation release
was observed. No shared helper mutation or TODO render was run. The exact-task
completion evidence is retained for that writer in
[handoff.json](../../.task-evidence/t_3c5078de/handoff.json); do not promote M2 or
record these fixture passes as Android acceptance. Native same-card review is the
single independent approval lane, requested after worker checks.

Commit/branch creation: **NOT_CREATED**. The earlier local-agent-commit allowance
conflicts with the task's later explicit no-commit instruction; uncommitted local
review is the conservative default. No stage, commit, push, branch/index mutation,
external action, other profile or schedule change occurred. No owner questions
are necessary for this bounded result.
