# M2 current-source detached-run recovery baseline — 2026-10-06

## Result and boundary

Task `t_2d1d55ab` / `DOC-M2-CONTINUITY-BASELINE`: deterministic recovery baseline
established; Android M2 acceptance remains **NOT_CHECKED / unverified**. This is
source-bound Linux-hosted Flutter test evidence, not OS process-death, real
keystore, live Agent/provider, platform, packaging or independent review evidence.
No product/test source, upstream clone, personal application, device, credentials,
installation, inference, retention, push or predecessor card was changed.

The smallest missing oracle is one **running → client process death → completed
while absent → relaunch → exact canonical history, with zero resubmission**
journey. The existing Maestro script stops at an active-run UI, not that oracle.

Baseline HEAD: `ca149a82189c8c9e5abd98b376bfeae1e43f6f3f`, dirty `main`.
The document date is the requested receipt identifier; execution timestamps are
UTC on October 6 (October 5 in the host's UTC−06 timezone).

## Existing evidence checked before running

- [Android discovery](2026-10-03-android-qualification-discovery.md), lines
  128–177 and 198–202: historical 22 channel and 36 combined store/export passes,
  explicitly not a death-to-completion oracle. Export tests do not establish
  recovery; their combined count is not reused as a store count.
- [Full Flutter receipt](2026-10-03-full-flutter-verification.md): historical
  2,394 passes on a dirty tree. Its referenced source-hash manifest was unavailable
  at the recorded scratch location when checked, so current-source equivalence
  could not be established. No full-suite repeat or inherited current pass claim.
- Current caller/test inspection, rather than historical status, determines the
  matrix below. Only focused recovery/store tests were executed anew.

## Real recovery path

Paths below are relative to the repository root.

1. `lib/features/hermes_chat/providers/hermes_channel_provider.dart:23–28`
   constructs production `HermesApiChannel` with `SecureHermesDetachedRunStore`.
   The store (`lib/core/hermes/setup/secure_hermes_detached_run_store.dart:23–54`)
   reads/writes the secure-storage slot; it keeps reconciliation metadata, not
   transcript, prompt, output or credentials. `base_url` is still sensitive owner
   metadata; sanitized fixtures do not make private origins safe to publish.
2. `lib/features/hermes_chat/gateways/hermes_gateway_directory.dart:334–367`
   loads remembered selection on startup. `activate:1031–1159` connects with
   deferred selection, selects the explicit profile and calls `restoreSession`
   with an activation-generation fence. Remembered-selection failure does not
   enter the default new-session creation branch.
3. `lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart:84–109`
   probes detached leases among the initial session inventory. This alone is
   **not** an off-page remembered-session guarantee. Explicit restoration uses
   `hermes_api_channel_sessions.dart:15–54`: authorized `getSession` if necessary,
   then `_selectSession:57–130`, which recovers the exact session before history
   admission/reattachment.
4. `hermes_api_channel_messaging.dart:2057–2182` matches canonical endpoint,
   profile and session, fences connection/profile selection, validates returned
   run/session IDs, and retains uncertain leases. Matching terminal status must
   hydrate canonical history before lease removal. HTTP 404 is a distinct
   process-local-registry absence policy, not proof of successful completion.
   Reattached terminal events hydrate history before best-effort release at
   `2015–2053`; failed hydration retains retry ownership.
5. `lib/features/hermes_chat/screens/hermes_chat_screen.dart:718–729` handles
   resume; `screens/state/hermes_chat_lifecycle.dart:4–54` reconnects recoverable
   states and reconciles the active session, with composer-owner fences. Directory
   resume (`hermes_gateway_directory.dart:1241–1248`) refreshes inventory. A
   surviving-process lifecycle callback is not an OS-death/relaunch receipt.

Agent remains authoritative, data-plane reads remain direct, and no mutation is
replayed as recovery. Native-web socket lifetime is not the advertised detached
run contract. These are the existing [client](../adr/client.md) and
[API/state](../adr/api-and-state.md) boundaries, not new architecture.

## Case-to-oracle matrix

COVERED means an assertion in the executed deterministic tests, not a platform
claim. NOT_CHECKED means this slice did not execute the named layer. UNCOVERED
means the inspected Android route has no matching acceptance oracle; it is not
an assertion that every repository test was exhaustively searched.
All channel test locations in this table are in
`test/core/hermes/channel/hermes_api_channel_tests/run_failure_tests.dart`.

| Accepted case | Current deterministic oracle | Coverage and remaining device gap |
| --- | --- | --- |
| Death/recreation preserves duplicate guard | `process recreation restores the detached-run duplicate guard`, line 1548: dispose/create channels over memory store; exactly one submission across attempted duplicate; status reads occur | COVERED channel seam; Android death and secure-store survival NOT_CHECKED |
| Exact non-default session, active stream and wrong-run events | `process recreation reopens a non-default session with an active detached run`, line 1639: selects `sess_2`, rejects duplicate send and wrong run events, then completes on matching event | COVERED in-page session/channel; full host/profile/device startup tuple NOT_CHECKED |
| Terminal history unavailable, recreation and later retry | `terminal hydration failure preserves durable retry across recreation`, line 65: lease survives history failure and recreated channel; successful later read admits canonical message IDs and releases lease | COVERED memory-store retry/history; real death during this interval NOT_CHECKED |
| Running stream closes, then authoritative completion | `reattachment reconciles terminal status after the event stream closes`, line 1922: periodic status changes running→completed, history is read, lease/guard clears | COVERED deterministic terminal recovery; absent-client server completion UNCOVERED by existing Android flow |
| Wrong endpoint must not release/authenticate foreign owner | `terminal status releases only the exact endpoint run tuple`, line 2038, and `confirmation from another endpoint cannot authenticate reconnect`, line 2803: foreign-origin lease retained, no foreign stream on transient status failure | COVERED endpoint seam; real credential/device/origin isolation NOT_CHECKED |
| Wrong run status, selected-session guard | `mismatched run status remains unconfirmed and fail-closed`, line 2858, and `session selection scopes a recovered run guard without detaching it`, line 1778: lease retained/no stream/no duplicate for mismatch; guard follows session while original subscription survives | COVERED run/session seam; real wrong-profile status/history after death NOT_CHECKED |
| Lease saved before event stream ends | `active run lease is durable before its event stream finishes`, line 1606; serialized saves, predecessor load and capacity tests below | COVERED asynchronous store seam; device commit/keystore lock/crash behavior NOT_CHECKED |
| Transient status / old or future timestamps / server restart | `reconnect keeps a detached run on transient status failure`, line 3027; `stale and future detached leases reconcile conservatively`, line 2898; `reconnect releases a detached run missing after server restart`, line 2990 | COVERED retain/404 policy; timestamp age is NOT credential expiry; real server restart NOT_CHECKED |
| Invalid/overfull storage and legacy incomplete owner | Seven secure-store tests plus two lease-model tests; `unresolved legacy blank-session lease blocks duplicate submission`, line 3062 | COVERED fail-closed validation/quarantine; secure tests use `FlutterSecureStorage.setMockInitialValues`, not Android keystore |
| Expired/revoked credential | Typed failure classification in `hermes_api_channel_connection.dart:3–23`; auth UI tests exist under `test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart` | Inspection only; these UI tests NOT_CHECKED here. Actual expiry/revocation after death UNCOVERED by existing Android flow |
| Resume / off-page startup / cross-profile selection races | Production lifecycle/directory/restore caller trace above; nearest restoration suites under `test/features/hermes_chat/gateways/` and `test/features/hermes_chat/screens/` | Source inspection only, NOT_CHECKED here; no combined Android OS-death proof inferred from separate seams |
| Notifications denied, status still usable | M2 outcome in [ROADMAP](../../ROADMAP.md#m2--leave-and-return-without-losing-ownership); existing recovery script has no denial/status oracle | UNCOVERED by inspected flow; Android permission behavior NOT_CHECKED. Push/notification tap delivery is a separate contract, not this baseline |
| Zero replay after completed relaunch | Duplicate-guard test counts one submission; other cases use memory stores and fabricated server fixtures | COVERED only the counted deterministic guard. Complete Android launch-to-terminal mutation ledger UNCOVERED by inspected flow |

## Executed focused commands and counts

All commands ran from the Wing repository root on Linux. Channel part files were
run through their parent test library, never invoked standalone. No isolated copy
or harness correction was needed. All three commands exited **0** and printed
`All tests passed!`:

```sh
flutter test --no-pub test/core/hermes/channel/hermes_api_channel_test.dart \
  --name 'process recreation|detached|terminal status releases|reattach|terminal hydration failure' \
  --concurrency=1 --reporter expanded
# 23 passed; 2026-10-06T03:00:51.218482+00:00 → 03:00:54.422199+00:00

flutter test --no-pub test/core/hermes/setup/secure_hermes_detached_run_store_test.dart \
  test/core/hermes/channel/hermes_detached_run_store_test.dart \
  --concurrency=1 --reporter expanded
# 9 passed; 2026-10-06T03:00:54.422362+00:00 → 03:00:56.679385+00:00

flutter test --no-pub test/core/hermes/channel/hermes_api_channel_test.dart \
  --name 'confirmation from another endpoint|mismatched run status remains|active run lease is durable|session selection scopes a recovered|unresolved legacy blank-session' \
  --concurrency=1 --reporter expanded
# 5 passed; 2026-10-06T03:02:01.867001+00:00 → 03:02:03.876324+00:00
```

Exact argv, exits, timestamps, expanded test names/counts and terminal counters
are saved locally under `.task-evidence/t_2d1d55ab/commands.json` and
`owner-command.json`; raw logs are `channel.log`, `store.log`, `owner.log`.
These are local uncommitted evidence, not a distributed runtime artifact.

Log SHA-256:

| Log | SHA-256 |
| --- | --- |
| channel.log | `e761010f89dc2aa4e9827346c1b12e6aaf0c9069ec61ffedf6e447698f65b663` |
| store.log | `340e07611acba1313158ae557eb528691fed45d027106973a91d11dd8218bb50` |
| owner.log | `e602407f009097919c5ad4a45f13c3bc4b794275553596daaa4db3ee778aa5c7` |

`source-before.json` and `source-after.json` bind 413 source/test/manifest/script
files; `source-changes.json` is empty. The supplemental owner check also compared
against the initial snapshot with no changes. Relevant SHA-256 fingerprints:

| Repository path | SHA-256 |
| --- | --- |
| lib/core/hermes/channel/api_channel/hermes_api_channel_messaging.dart | `cf5a16e342a6c8a083dc890fd77b002a34d1813e15b2ae4e748fc48a7783a62b` |
| lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart | `96de5eda7569e23bb63fce78c4c06bcade17a8ad95aef1f9fa8bd8b1d4973a23` |
| lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart | `3270b6461fa569dbf07796f5ca825ac99e55179829b4e97ad61f1bf7408eea17` |
| lib/core/hermes/setup/secure_hermes_detached_run_store.dart | `824b8649decc8db5d64c3bef61c219d0813e137fa08e5fcde0dcdc32a5e4816e` |
| lib/features/hermes_chat/screens/state/hermes_chat_lifecycle.dart | `9e58b6f0ac8ee61a56f5fa8aaf974a9df256ce8cbce7fad0625f36c64232ea36` |
| lib/features/hermes_chat/gateways/hermes_gateway_directory.dart | `204ea41c025387b8c214cc0415e64ff1f62af66cb932972c3dd776a81e2ac384` |
| lib/features/hermes_chat/providers/hermes_channel_provider.dart | `9bb54b5d3b460536854b9dff61c5f527e3260369582259d3bdb29f9581767ee6` |
| test/core/hermes/channel/hermes_api_channel_test.dart | `eff165060ecd6e33d395c142137288dfd701580f7974f3f51c2748fde679986c` |
| test/core/hermes/channel/hermes_api_channel_tests/run_failure_tests.dart | `5af9f88af7c880eb3c1709b99af83fffcb98f0945a6e0d167960040e923d3e89` |
| test/core/hermes/setup/secure_hermes_detached_run_store_test.dart | `fc9ca628b0269a0a2aaa69dd6f7e784287b1918fd0d4ea3976a63d987f0f8c44` |
| test/core/hermes/channel/hermes_detached_run_store_test.dart | `28ac3338df1869574d4721b6e724d863bddfe311b86b898081751534a76b2aa6` |
| scripts/maestro/chat_process_recovery_qa.yaml | `76c95bae3531c0b9b0da180a63035503e20e5f1b87eec45b6635270214689f17` |

## Exactly one future scenario: ANDROID-M2-DEATH-COMPLETE-01

This is a bounded **proposal, NOT_CHECKED**, not authorization to execute it.

Prerequisites and safe target boundary:

- Name one newly owned disposable emulator, Android version/API/ABI and unique
  adb serial in the future receipt. Android 14/API 34 x86_64 is the default target
  class, not permission to reuse a previously named AVD or personal device.
- Use only isolated `com.trebuchetdynamics.hermes.wing.qa` storage/package on that
  target, after verifying build/install/runner cleanup isolation. Never launch,
  stop, uninstall or clear the production package or another AVD.
- Require a supported M1 run-mode receipt for a separately authorized disposable,
  unmodified Agent and explicit non-default profile/session. Verify exact advertised
  run submission/status/events and canonical session-history operations/grants.
  Native live sockets do not substitute for this detached contract.
- Authorize the single bounded synthetic provider turn/cost separately; acquire
  disposable Agent credentials through the reviewed secret-safe path, never argv,
  logs, fixtures or personal key reuse. Wing Link credentials/pins stay separate.
- Prepare an allowlisted, content/credential-redacted observer for authoritative
  request counts and opaque identity aliases. Do not dump host logs, transcripts,
  private endpoints or secure-storage values. Record APK/source hashes, application
  PID/generation and target identity. Missing instrumentation is a prerequisite
  gap, not permission to fabricate counters or claim output absence means no send.

Procedure and observable oracles:

1. Deny notification permission on the owned QA target. Select the explicit owner
   tuple `(canonical Agent origin, profile, session, run)` and submit exactly one
   bounded synthetic turn. Read accepted run/session IDs and authoritative
   `running` status. Verify durable lease-write acknowledgement before death using
   an approved metadata-only observer; do not inspect secret values.
2. Background Wing; read back `running`, then force-stop **only the QA process**,
   preserving app data and keeping Agent alive. Verify PID disappearance. If the
   run completed before death, the attempt does not satisfy this scenario.
3. While Wing is absent, use authenticated direct Agent reads until the exact run
   is `completed` and the exact session contains its canonical user/assistant
   message IDs and expected synthetic-result digest. Bound the wait (for example
   120 seconds); timeout is failed acceptance, never an automatic resubmission.
4. Relaunch the same QA package/storage with notifications still denied. Assert
   remembered origin/profile/session restored, status read addresses the same run,
   canonical message IDs/order/result match server readback, no duplicate user or
   assistant entry, and no replacement session. Only after successful canonical
   hydration may the run lease/duplicate guard clear. UI status/history must be
   usable without notifications; a Reconnect label alone is insufficient.
5. Compare authoritative counters before/after relaunch: total run submission is
   exactly one; relaunch adds **zero** run starts, session-create, chat/completions
   sends, Stop or approval responses. No implicit retry, prompt replay or default
   profile/session substitution. Record redacted counters and matched identity
   booleans, not raw sensitive state.

Credential/owner failure checkpoints are bounded controls on this same scenario,
not additional generated runs: retain the same disposable completed run and saved
owner, invalidate its disposable credential through a separately authorized Agent
contract, then exercise expiry/revocation denial and a wrong-owner read attempt.
If the target cannot provide both expiry and revocation, mark the missing control
NOT_CHECKED rather than treating an HTTP 401 fixture as real expiry/revocation.
No denial may hydrate foreign history, drop unresolved ownership, replace the
session, send text or answer approvals. With separately authorized valid credentials
restored, reconcile only the original tuple by read. A different host/profile or
wrong run/session status must not authenticate this owner; leave the original
lease conservative. Record server counts across these controls too. Real secure
store survival/lock behavior and Wing Link pin enforcement, if that plane is used,
need named-target observations, not plugin presence. No push, durable drafts,
attachments, runtime upgrade or broad profile-mutating wrapper enters this scenario.

Why not run the existing script:
[`chat_process_recovery_qa.yaml`](../../scripts/maestro/chat_process_recovery_qa.yaml)
line 6 names the production app; lines 22–29 create a session and request a
2,000-word provider generation; lines 41–46 only assert still-active/Reconnect/
no-Retry/no-Stop. It has no authoritative completed-history, full identity,
mutation-count, credential-denial or denied-notification oracle. The broad Android
regression wrapper also mutates profiles. Neither is a harmless continuity probe;
no command from either was executed by this card.

## Backlog, validation and acceptance

Only the baseline task is finished; M2 is not met. Existing source/tests and
predecessor review/dismissal cards remain untouched. No new backlog/card scope
is introduced. Exact helper/validation receipts are kept in this card's local
`.task-evidence` directory alongside the source-bound test evidence.

`goals.py evidence` recorded each actual test pass while the baseline was still
in progress; `goals.py task ... done` and `goals.py render` then exited 0. Readback
confirms only the M2 evidence and this task object changed, with M2 still
`unverified`. **`goals.py validate` exits 1: `M2: unverified goal has no open task`.**
The existing model assigns M2 only this documentation task. The helper demands
an open task for every unverified goal, but this card forbids introducing a second
task or claiming unexecuted Android acceptance. JSON remains parseable; the
semantic backlog validation failure is reported, not suppressed. A separately
scoped backlog maintenance pass must represent remaining Android qualification
as open work; this baseline does not invent that authorization. Repeating tests
or promoting M2 to `met` would not fix the missing device evidence.

Validation executed by `.task-evidence/t_2d1d55ab/validate.py`: JSON parsing via
`python -m json.tool goals.json` exited 0; scoped `git diff --check -- TODO.md
goals.json docs/quality/2026-10-06-m2-continuity-baseline.md` exited 0; all six
receipt local-link paths exist; `git apply --check --whitespace=error-all
--reverse .task-evidence/t_2d1d55ab/owned.diff` exited 0 for the exact owned delta.
Because deliverables are untracked, `git diff --no-index --check /dev/null
docs/quality/2026-10-06-m2-continuity-baseline.md` additionally checked the new
receipt: exit 1 means an added-file difference, with no whitespace diagnostics.
The local validation harness initially treated that difference exit as failure;
only the owned harness interpretation was corrected, not product/tests. Final
source comparison still found zero changes across 413 fingerprinted files.
The three focused commands contain 37 distinct passing tests. No full suite,
analyzer, build, device, live target or packaged runtime was executed here.

Acceptance mapping:

1. Current-source covered/uncovered/NOT_CHECKED owner/history/replay matrix:
   caller trace, matrix, hashes and the three passing expanded commands above.
2. Exactly one safe future Android death-to-completion scenario: the scenario
   above, its authoritative tuple/history/counter oracles and credential/owner
   controls. Device/live/platform execution remains NOT_CHECKED.
3. Baseline task done with receipt reference and generated M2 row, without
   promoting Android M2 acceptance. JSON/link/scoped whitespace and local
   card-branch outcomes are recorded in the final handoff; any helper limitation
   is reported explicitly rather than inventing Android evidence.
