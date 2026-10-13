# Schedules inventory: source-bound failure evidence

Status: offline evidence receipt; native/live qualification NOT_CHECKED.
Task: `DOC-M4-SCHEDULE-INVENTORY-EVIDENCE` / `t_76097e23`; goal M4 remains partial.
Only this receipt is new. No schedule administration or runtime behavior changes.
See [route support](../product/routes.md), [API authority](../adr/api-and-state.md),
[M4](../../ROADMAP.md#m4--discover-and-administer-supported-agent-work) and the
unchanged predecessor [Tools receipt](tools-inventory-evidence.md).

## Source and execution identity

- Wing admitted base: `416d3e21fce1c266b46c35fe47a7473a12f18c0c`.
- Original initial `pass_workspace.py` guard returned `worker_start_admitted`,
  exit 0, before tests or edits. Original pass-manifest SHA-256:
  `ab56e2dcd886b1f7c95dd31f9e856e56e1a9b62b48bd6e24e41b3e5b19610032`.
  Original `schedules-source.json` SHA-256:
  `78f31a6a5797e2b61b52bc28b08981469fd1b8684298ae1ade450643177a1cd9`.
  The native card retains the exact command/workspace, ordering and finish/ref receipt;
  these hashes alone are not admission or review proof.
- Frozen manifest planning context, not the worker's older TODO copy, supplies this
  accepted Next task. Its TODO SHA-256 is
  `a66bb919c26765e427cc956d54e565281aaa728331002d0681184217fdaddfc2`;
  goals SHA-256 is `523279fcf874f16318bfe04baabd684f544522ec54312aa5fdd1dd378c8406ff`.
  Both frozen strings matched the original source manifest. No ledger is changed.
  The generic ROADMAP heading's missing `Status: Accepted` is a metadata limitation,
  not retraction of the existing TODO task. Owner easy-tasks-first ordering is unchanged.
- Exercised Linux x86_64 Flutter widget/unit runner: Flutter 3.44.2 framework
  `c9a6c48423`, engine revision `77e2e94772`, Dart 3.12.2, DevTools 2.57.0.
  Node reports 26.7.0, not documented Node 22; no Node/browser check was run.
- `timeout 5m flutter pub get --offline --enforce-lockfile` returned exit 0 using
  cached packages. Both tracked lockfiles and manifests remained unchanged. No
  install, upgrade or network package fetch was requested. Generated test/build
  outputs are disposable, not deliverables.

SHA-256 inputs (verified against the admitted executable source; receipt-only
changes do not requalify a different source, test, dependency or environment):

| File | SHA-256 |
| --- | --- |
| `lib/features/schedules/screens/schedules_screen.dart` | `73630774e5476cdf400e748fb15b61efb3754f169105b6eabbb521c85a2c53ec` |
| `lib/core/hermes/channel/hermes_api_channel.dart` | `e636eb3a54b56c671f56a7eedb61112516ab97bdbda7d2cf0a0311ac2b752c1b` |
| `lib/core/hermes/channel/hermes_channel_state.dart` | `2a21f95befa4de3c37fa2a3479480683a1f6c405a9b3f668fbec96bfa5b974dc` |
| `lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart` | `95d53e5335af3145f0856a683ff0b3f75bbdca14c77df749e0cfa0caccffff44` |
| `lib/core/hermes/channel/api_channel/hermes_api_channel_inventory.dart` | `11c382c9f02c52ea5c86b87fe0239e4d8028663735329d79aede3b5e1bbe436a` |
| `lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart` | `3ed77d6a01351a4fa8acdbb35f27f1dedd17b52a1014d6ca4fc40fec67b69082` |
| `lib/core/hermes/client/hermes_api_client.dart` | `f94d1a8502646caeec1f4bd6b5d4fdc2a30b4b3074d457c47e6dc86b91b3b128` |
| `lib/core/hermes/client/hermes_api_config.dart` | `ec818a5ee9de04b49c4657d97d0590f79d04a131c05e21e4a9783468d8e364cc` |
| `lib/core/hermes/models/hermes_capabilities.dart` | `8368782c1cbe2cf4a65d184d22eb7e2641b1e4eb07111b946344ae8ada32a7d3` |
| `lib/core/hermes/models/hermes_job.dart` | `66a05a9a10fe9fa5bdebc0a19c7bfd4731c33f5c446356b434e9fccf84af2654` |
| `test/features/schedules/schedules_screen_test.dart` | `daa7e8fce2d14d645a04ed740ac2db8d2a9d1bcc59dbedbd8918ebb3d881f58c` |
| `test/features/schedules/schedules_ownership_test.dart` | `01a0ffdc029ff045ba78656be0e8019df3a4ea79459e6c36dcd04ff99b62b97e` |
| `test/features/schedules/schedules_client_ownership_test.dart` | `f98059f17fa55b1d35dadb7f768fa59699f60b4198e8b6c9ddd5017568c482b6` |
| `test/router/schedules_route_test.dart` | `47ebdfdf183c85320416cc9d46240e61c6f63045d80305c192c0e20d2c4db4eb` |
| `test/core/hermes/channel/hermes_jobs_bootstrap_authorization_test.dart` | `62a051b909e9a44c50fd99406960601799dc4cd349d2564acd7432e94c2be61a` |
| `test/features/hermes_chat/support/fake_hermes_channel.dart` | `fa89019191f06d849b23922544897a42e4e4b73b65028b07b857e923405ced2b` |
| `playwright/tests/regression/schedule-search.spec.mjs` | `fec76476be8780ceb32141f7aa1ad065aaf34e0a2793871579bf715d45eab7c8` |
| `docs/runbooks/schedule-search.md` | `3fcf22a50757515562eb22136f2951bc3a50c22bccbaefe5dd7f23b8b9f7f6e9` |
| `docs/quality/tools-inventory-evidence.md` | `816bb386bc110f2d884097f609112b7ad2f51672601f173ad97866485af515d1` |
| `pubspec.yaml` | `7986bd3eaa967657f453e08f0522a4254496393699dc9640a7aba7de4cf1a43a` |
| `pubspec.lock` | `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89` |
| `package.json` | `c5acb3d1eae19f0f20c119745fd3ee5b0677457e01e9b14fcd3d8f1266b4e833` |
| `package-lock.json` | `f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63` |

## Exact read contract and its runtime limit

The [state policy](../../lib/core/hermes/channel/hermes_channel_state.dart)
lines 201–202, 244–264 and
[capability model](../../lib/core/hermes/models/hermes_capabilities.dart)
lines 58, 74–84, 118–122 require schema 1, the named `jobs` endpoint with exact
`GET /api/jobs`, explicitly declared and granted `tasks:read`, and every additional
required grant (including the existing wildcard rule). A `profile_scoped`
descriptor additionally requires `type=query`, `name=profile`, `required=true`,
`default_profile_id=default`. Genuinely unscoped advertisements do not gain that
context requirement. Broad `admin` or version/feature flags grant nothing.

The [screen](../../lib/features/schedules/screens/schedules_screen.dart):535–538
also requires connected, settled profile selection. The
[shared inventory loader](../../lib/core/hermes/channel/api_channel/hermes_api_channel_inventory.dart):44–55
uses the same `canReadJobs` policy for connect/select bootstrap, intentionally
without requiring already-settled connection/selection. Denial skips the jobs
request, creates no invented optional read error and leaves other authorized
inventory usable. Denied inventory is unavailable, not an authorized empty list.

The [client](../../lib/core/hermes/client/hermes_api_client.dart):190–207 sends
only a jobs GET, with explicit selected profile and `include_disabled=true`, and
keeps at most 128 decoded entries with nonempty IDs. The
[API config](../../lib/core/hermes/client/hermes_api_config.dart):132–151 preserves
an enrolled `/p/<profile>` identity and rejects a different requested ID; otherwise
it adds the explicit profile query. The 128-entry bound is not a pagination or
complete-large-inventory claim. Search/display bound name to 120 characters, ID
to 128 and schedule to 160; raw job errors become a generic notice, not searchable
or rendered diagnostics. Filtering never changes the job's authoritative status.

Read-only Agent reference inspected at `158fd638da1629c8e62caf9ade1515d162def8ab`:
`gateway/platforms/api_server.py:78–102,2536–2575` does NOT advertise `jobs` in
`_CAPABILITY_ENDPOINTS`, nor the scopes/profile-context contract used by these
fakes. Its registered jobs handler exists at lines 1780, 3888–3897; the guard at
3836–3850 authenticates first and rejects unavailable cron, and the handler accepts
`include_disabled`. Handler existence is not a capability grant: Wing must keep
Schedules unavailable for that inspected catalog, not infer support or probe a
hidden route. Nearest inspected upstream tests are
`tests/gateway/test_api_server.py:937–963` (catalog) and
`tests/gateway/test_api_server_jobs.py:83–98` (mocked list envelope); NOT_RUN here.
The predecessor Tools catalog differs: skills/toolsets are advertised. Its receipt
and qualification remain unchanged; Tools support cannot be transferred to jobs.
Query-profile simulations below do not qualify upstream path-profile routing or
live bearer rejection. No upstream source/runtime was modified or started.

## One failure journey, mapped to executed oracles

Journey: open Schedules for owner A, explicitly refresh, then change owner while
that read is pending. Owner B's denied read must stay unavailable with no jobs
request. If B instead has an authorized read that fails, hide cached cards and
controls, show bounded failure/Retry, and recover only with a fresh B action.
A's cached callbacks and late success/failure must not read for or recover B.
This is a composition of the following executed deterministic oracles, not one
live end-to-end recording combining every transition.

1. Owner changes and obsolete results.
   Screen lines 172–217 synchronously track channel identity, host, profile,
   connection status, selecting and exact read availability. Any change replaces
   the owner token, clears query/filter/failure/pending state and advances refresh
   generation, including A→B→A before rebuild. Equivalent capabilities and ordinary
   same-owner inventory changes retain local controls. Lines 219–237 check the
   current provider/token/authority before dispatch and before accepting completion;
   duplicates cannot start overlapping screen reads. Already-issued reads may
   finish at A; no cancellation/rollback claim is made.

   Executed [screen tests](../../test/features/schedules/schedules_screen_test.dart):
   `old jobs success cannot return after owner change` and its failure counterpart
   (lines 195–264) use the actual channel/client with injected transport and distinct
   host owners: controls reset, B's job remains, A's job/error never returns.
   `authority loss hides stale matches and controls; empty is distinct` proves
   missing operation/grant, disconnect/loading and optional failure hide old matches.

   Executed [ownership tests](../../test/features/schedules/schedules_ownership_test.dart):
   `old completion false/true cannot restore replacement failed inventory` and
   `replacement clears failed owner and stale Retry before rebuild` prove an old
   completion cannot restore failed B inventory; stale Retry increments neither
   owner's read counter. The latter records A=1, B=0 before fresh B refresh.
   Cached button/pull/retry rejection across host/profile/selecting/disconnect/grant/
   operation loss and roundtrip, identical-ID channel replacement and disposal are
   covered too. These fakes prove callback/UI ownership, not transport isolation.

2. Exact denied-read admission.
   Executed [client ownership tests](../../test/features/schedules/schedules_client_ownership_test.dart):
   `actual explicit jobs admission rejects schema/context/method/path/extra grant
   without jobs I/O` hide refresh and reject `loadJobs` with zero additional GETs.
   `actual jobs profile transition fences callbacks/completion false/true` captures
   five jobs GETs: default bootstrap, old default refresh, writer bootstrap,
   default bootstrap, fresh default refresh. Every receipt carries
   `include_disabled=true`; cached actions add no reads. Old completion cannot
   replace current jobs/errors or unlock the fresh pending spinner.

   Executed [bootstrap tests](../../test/core/hermes/channel/hermes_jobs_bootstrap_authorization_test.dart):
   connect/select denial matrix covers schema, absent/wrong operation, method/path,
   missing primary grant/declaration, admin-only, extra missing grant and unsupported
   profile context. Absolute jobs request history is empty; jobs/errors stay empty,
   direct load rejects before extra I/O, and connection stays usable. Enrolled-path
   unsupported-context cases also issue zero jobs requests. Authorized scoped,
   unscoped, extra-grant/wildcard, 128-job and delayed bootstrap/request-generation
   cases execute in the same target.

3. Current authorized failure and explicit recovery.
   [Reload](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart):241–275
   rejects disconnected/unsettled/denied state before request-generation acquisition.
   It captures client, connection/profile-selection/request generations and profile;
   only the current result publishes jobs or clears/adds a sanitized jobs error.
   Current failure empties jobs and rethrows; stale failure cannot publish.
   [Profile selection](../../lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart):71–84,113–135
   publishes bootstrap inventory only for its current selection. Screen lines 270–305
   distinguish disconnected/loading, capability unavailable and authorized read failure;
   failure uses a localized live-region empty state with Retry, not raw diagnostics.

   `load failure is distinct and does not expose raw errors` (screen test:740–766)
   hides old cards and recovers via one explicit `loadJobs` call. `ordinary updates
   retain pending state and duplicate admission` (ownership test:438–475) proves one
   pending read despite button/pull duplicates, preserved same-owner query, bounded
   failure and explicit recovery. `authorized profile bootstrap failure is optional
   and explicit retry recovers` (bootstrap test:244–274) keeps the selected writer,
   usable connection/other inventories, empty jobs and sanitized network failure;
   exactly three jobs receipts are default bootstrap, failed writer bootstrap,
   explicit writer retry. Actual-channel denied/failure/success widgets at 390/1280
   pixels, 200% text and reduced motion prove zero denied jobs GETs; failure has one
   GET before Retry and two after recovery, with zero recorded POST mutations.
   Ownership keyboard cases exercise Enter refresh, Space Retry and progress/Retry
   semantics at both widths. This is not native screen-reader qualification.

The [route test](../../test/router/schedules_route_test.dart) confirms `/tasks`
renders in the actual shell while disconnected. Read-only rendering, local
search/filter/clear no-I/O and no New task are separately asserted by the screen
target. There is no create/edit/run/pause/resume/delete/Kanban qualification.
Mutation assertions are bounded fake request/call counters, not a live audit.

## Commands and results

Executed in the isolated admitted workspace, unchanged executable source:

```text
timeout 5m flutter pub get --offline --enforce-lockfile
PASS, exit 0; both lockfiles retained.
timeout 5m flutter test --no-pub test/features/schedules/schedules_screen_test.dart test/features/schedules/schedules_ownership_test.dart test/features/schedules/schedules_client_ownership_test.dart test/router/schedules_route_test.dart --reporter expanded
PASS, exit 0; 97 cases; All tests passed! runner elapsed 00:11.
timeout 5m flutter test --no-pub test/core/hermes/channel/hermes_jobs_bootstrap_authorization_test.dart --reporter expanded
PASS, exit 0; 59 cases; All tests passed! runner elapsed 00:02.
```

The bootstrap target is the directly relevant extra channel/client target needed
to attribute denied connect/select and actual-channel bounded failure/recovery.
The two targets are disjoint; finish-gate replay is not additional unique coverage.
Receipt hashes, changed local link targets and `git diff --check` are required
finish checks; exact argv/results and local task commit belong to the native card.
No test retries/failures occurred in these initial runs. Review duration/cost are
unknown. Independent same-card review remains required; this receipt is not approval,
canonical integration, publication or delivery proof.

## Historical browser evidence and the missing live oracle

[Schedule search runbook](../runbooks/schedule-search.md):52–98,119–161 records
older compiled Chromium fixture journeys at 390/1280: one bootstrap GET, zero
local-control reads/mutations, three explicit success/failure/Retry GETs, with
profile/default and include-disabled receipts. The
[current browser oracle](../../playwright/tests/regression/schedule-search.spec.mjs):26–38,106–133
injects the scoped catalog/jobs and a 503 response, asserts bounded recovery,
exact four total jobs GETs and zero non-GET requests/page errors. Inspected, NOT_RUN
here. These are historical synthetic receipts, not fresh browser evidence at this
candidate; source fingerprints do not replace a build or execution. Historical
large-suite totals and old pending/accepted review labels are not promoted to this
card's execution or review status.

Missing oracle: a source-bound installed Linux Wing journey against separately
authorized isolated, authenticated, unmodified Agent owners, proving real capability/
bearer denial, A→B pending-read isolation and B's explicit authorized failure/Retry
with exact owner-scoped request readbacks, zero mutations and keyboard/accessible
recovery. First verify that the target actually advertises the required jobs/grants/
profile contract. The inspected reference does not; for it, the available bounded
live journey is unavailable/no jobs dispatch, not successful inventory. If no
unmodified target supplies the contract, retain unavailable and report the precise
contract gap; never patch Agent or add a shadow scheduler. This oracle is NOT_CHECKED,
not failed/passed from widgets or historical Chromium. No live successor is created
or dispatched by this documentation-only card.

M4 remains partial: live/native jobs inventory and each supported administration
operation need distinct evidence. Browser, physical Android, installed native UI,
real auth/owner routing, screen reader and schedule mutations are NOT_CHECKED here.
The owner-selected next candidate remains `DOC-DIAGNOSTICS-BACKUP-CONTRACT`, subject
to current selector and review/ledger closure; the coordinator alone owns closure
and authorized integration/delivery. Tools qualification is neither expanded nor
withdrawn by this receipt.

## Smallest-change decision

Ponytail full applied directly using the supplied session rules and bundled
`autowork/references/ponytail.md`: add one receipt; reuse existing screen/channel/
client/capability policy, deterministic fakes, complete existing tests and historical
browser receipt. Skip new production/test logic, dependencies, config, abstractions,
exports/localization and speculative administration. No connected caller/fixture
changes are needed because no contract changes. No user data is read, mutated,
exported or discarded. Full-suite/build/platform checks would exceed this read-only
slice's evidence boundary and are not substituted for the missing live oracle.
