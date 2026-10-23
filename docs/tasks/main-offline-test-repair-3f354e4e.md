# Repair the recorded main failures at 3f354e4e

Task: `MAIN-REPAIR-003`; goal: `INTEGRATION`.

## Evidence

All five files were read in place under Git-common
`autowork-execution/main-evidence/3f354e4e0d50e60f5392a4879ce54f42beea09a4/`:

- `main_check.json`: `red`, `TEST_FAILURE`; checked revision and red-since
  `3f354e4e0d50e60f5392a4879ce54f42beea09a4`; previous green
  `9ca06dca7065c3d047f2e4f909937b6147a2dcf4`.
- `main-check.log`: package resolution completed; terminal line 5517 is
  `21:43 +4142 ~9 -45: Some tests failed.` The final five-name display is truncated;
  the metadata and all `[E]` entries identify **45 failures in 17 files**.
- `main-check.exit`: `1`.
- `main-check-reruns.log`: empty; `flaky_history.json`: `{}`.
  No isolated rerun, three-revision pass history or flaky classification exists.

This is new red-main evidence, not the earlier pre-result package crash. It does
not establish that the named tests contain product defects. No bundle was copied,
package provisioned or Flutter test rerun by this maintainer pass.

Commits listed by the bundle since the previous green (newest first):
`3f354e4e`, `9fc42c09`, `38808ce0`, `8739c6ae`, `3ccaea06`, `1246b4c5`,
`9fa722f6`, `7a2f0e40`, `7603dcdd`, `aeffb602`, `39672361`, `3439d990`,
`f5a00c40`, `88a2a07b`, `dda745da`, `0eea6c2d`, `cd59c936`, `b3875e60`,
`1684d76a`, `3f431935`. These are provenance, not a causal verdict.

### Failing inventory

Paths below are repository-relative; names are from the retained metadata.
Variants are grouped without removing any case.

| Test file | Failing names / variants | Count |
| --- | --- | ---: |
| `test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart` | `primary paths retain owner: TargetPlatform.android` at 390.0/1280.0 and 1.0/2.0 | 4 |
| `test/features/hermes_chat/screens/compact_connection_presentation_test.dart` | `SSH entry keeps a single heading and clears navigation/keyboard at 1.0 text` and `2.0 text`, both `TargetPlatform.android` | 2 |
| `test/features/hermes_chat/screens/hermes_ssh_no_cli_test.dart` | `Android SSH and Remote entry do not require CLI QR setup` | 1 |
| `test/features/hermes_chat/providers/managed_ssh_serve_test.dart` | `Android SSH separates REST authentication from ticket and owner authorization` | 1 |
| `test/features/hermes_chat/providers/managed_ssh_serve_reads_test.dart` | `API remains default and does not guess serve after failure` | 1 |
| `test/features/hermes_chat/providers/managed_ssh_session_recovery_test.dart` | `recreated controller restores secure exact owner after a new authenticated lease`; `changed agentPort cannot inherit another SSH owner`; `missing exact profile cannot silently select default`; `pending profile switch does not pair new profile with old session` | 4 |
| `test/features/hermes_chat/widgets/connection_information_help_dialog_test.dart` | `production chooser offers safe selectable connection help` | 1 |
| `test/features/hermes_chat/widgets/managed_ssh_generated_key_ui_test.dart` | All 13 cases listed below | 13 |
| `test/features/enrollment/hermes_welcome_recovery_test.dart` | `welcome keyboard recovery width` 1280.0/390.0, text 1.0/2.0, all `TargetPlatform.android` | 4 |
| `test/core/hermes/channel/hermes_serve_credential_lifetime_test.dart` | `serve Retry never sends retired credentials to an API replacement; disconnect=false` | 1 |
| `test/core/hermes/channel/hermes_serve_cleanup_ownership_test.dart` | `serve cleanup wait cannot overtake disconnect ownership` | 1 |
| `test/core/hermes/channel/hermes_local_serve_restoration_test.dart` | `unknown Stop remains owned while running, recovery never repeats Stop` | 1 |
| `test/core/hermes/channel/hermes_local_serve_chat_test.dart` | `submission timeout preserves uncertainty and explicit recovery never replays` | 1 |
| `test/core/hermes/channel/hermes_local_serve_reads_test.dart` | `paged export lease rejects selection roundtrips and disconnect without changing chat` | 1 |
| `test/core/hermes/client/hermes_web_lifecycle_test.dart` | `uncertain submission reconnect gets fresh ticket, canonical state, no mutation replay`; `sequence gap requires reconciliation rather than partial projection`; `recovery checkpoint cannot cross origin or profile` | 3 |
| `test/core/hermes/client/hermes_session_history_export_test.dart` | `offset`, `returned`, `nonInteger` each followed by `discards paged attempt; explicit retry starts at zero` | 3 |
| `test/core/hermes/client/hermes_web_read_adversarial_test.dart` | `REST status 500 fails closed and redacts body/location`; `REST rejects message-session without a partial page`; `REST rejects numeric-id without a partial page` | 3 |

The 13 generated-key UI failures are:

1. `production panel exposes deliberate generation only in private-key mode`
2. `consent cancel defaults to refusal with zero store effects`
3. `consent keyboard defaults to refusal with zero store effects`
4. `consent barrier defaults to refusal with zero store effects`
5. `generated key is the actual managed-forward private callback, public clipboard only`
6. `form drops private selection at submission before callback completion`
7. `canceling selected generated key discloses retention and revokes captured copy`
8. `reopened production panel deliberately reuses saved key without generation or overwrite`
9. `generate-key secure storage failure is sanitized and cannot submit`
10. `use-generated-key secure storage failure is sanitized and cannot submit`
11. `late generated result after cancel remains retained but never selects or connects`
12. `late generated result after password remains retained but never selects or connects`
13. `late generated result after dispose remains retained but never selects or connects`

## Bounded repair

Diagnose and repair these existing failures at their shared seams, not by changing
product scope, reverting accepted mobile connection behavior or weakening assertions.
Two observed groups guide investigation; neither is a proven root cause:

- **25 connection widget failures:** `pumpAndSettle timed out`, including the
  generated-key mount at line 100, primary-entry keyboard activation at line 293,
  compact mount at line 139 and welcome activation at line 102. Inspect the new
  secure saved-access load and existing provider overrides. The panel now calls
  `_loadSaved()` from `initState` and waits for the Android secure-store read
  before clearing `_loading` (`managed_ssh_connection_panel.dart:55-86`);
  generated-key `mount` overrides only the connection controller
  (`managed_ssh_generated_key_ui_test.dart:82-87`). Determine missing deterministic
  storage responses versus an actual production settlement defect. Retain real
  keyboard traversal, compact/large-text, consent, redaction and cancellation proof;
  longer timeouts or replacing settlement checks with widget presence are not fixes.
- **20 socket/fixture failures:** address-in-use on loopback ports 20101, 20128,
  20131 or 20132, sometimes followed by uninitialized teardown or double disposal.
  `integration_test/support/local_serve_read_fixture.dart:18-23` uses a bounded
  `AUTOWORK_PORT_BASE` counter; `test/core/hermes/support/fixture_server.dart:3-17`
  has another per-isolate counter. Inspect allocation, isolate/process overlap,
  resource load and complete owned-server cleanup, including partial setup.
  Respect assigned ranges; never kill an unrelated listener or edit the installed
  runner. Do not infer broken Stop/replay/export semantics from a bind failure.

Source changes since green include `3f431935` and `cd59c936` (saved SSH store,
connection panel/form), and `1684d76a` (enrollment, gateway/channel/web-reader
wiring). The task Touches includes the failing tests, their shared fixture/mount
helpers and those relevant changed production seams; it is an allowed footprint,
not a request to edit every file. Start with deterministic fixture corrections.
A product correction is permitted only for a reproduced existing defect traced to
these seams; preserve [API/state authority](../adr/api-and-state.md),
[transport qualification](../adr/client.md#transport-qualification),
[secure quick access](../adr/security-and-privacy.md#opt-in-android-ssh-quick-access)
and the [accepted gateway candidate](../product/enrollment.md#android-gateway-sign-in-candidate).
No new capability, credential authority, upstream patch or platform claim is added.

Reproduce with the supported Flutter 3.44.2 setup and the runner's assigned range,
then run the affected files together and the unchanged complete offline check:

```bash
flutter pub get --offline --enforce-lockfile && flutter test --no-pub --concurrency=1
```

Record actual source/SDK, fixture environment, commands, exits, terminal counts and
remaining failures here. Focused or isolated passes do not replace the full gate.
If an unrelated existing failure still stops the gate, retain its exact evidence;
do not fabricate success, filter tests or silently widen scope. Record unsupported
or unexercised targets separately. Normal independent review and integration gates
remain required; no new coordinator handoff or owner receipt is a prerequisite for
investigating these already-recorded failures.

## Queue and preserved work

No open task covers this inventory. `MAIN-REPAIR-001` and `MAIN-REPAIR-002` are
closed for earlier, different failures. The running
[CHECK-PACKAGES-001](../../tasks/items/CHECK-PACKAGES-001.md) explicitly excludes
named-test repair; its current record, recovery page and candidate are untouched.
Its attempt-1 report names `5b48375d` and leaves the merged full gate pending;
the slot now records running attempt 2 on this revision. This bundle does not
close or qualify that task. The new repair goes first in Now under the explicit
red-main instruction and has disjoint Touches from package recovery and the
running-marked Linux Chat qualification. No existing task rank or dependency changes.

## Saved ledger proposals

Both complete saved proposals were compared with current records, archived Sources
and accepted scope, adjacent reports and the current Tab report. Resolve paths
relative to Git-common `autowork-execution/`:

- `slot-data/PARITYUPDATE-005-11/attempt-1/ledger-edit.patch`: retired `TODO.md`
  coverage changes from browser task to its `-LIVE` successor, removal of completed
  `PLANGAP-001-2f` and `VERIFY-CHAT-TRANSCRIPT-NATIVE` coverage, and removal of the
  latter from retired `goals.json` priority order. Report: `7f5c64c9`.
- `slot-history/DOC-PARITY-TAB-CONTRACT/8/slot-data/attempt-1/ledger-edit.patch`:
  only the same browser-successor/plan-task coverage refresh. Adjacent report:
  `187cdc8c`; current Tab report: later `e564642d`.

**Drop both proposals.** All five named parent/task records are already done;
`PARITYUPDATE-005-11-LIVE` and `MT-VERIFY-BROWSER-GATES-LIVE` are manually closed by
the owner's 2026-10-22 waiver, not live-qualified. Their accepted
[roadmap](../../ROADMAP.md#flutter-port-execution-roadmap),
[inventory proof](../quality/shell-inventory-keyboard-qualification.md#acceptance-map),
[Android priority](../plans/2026-10-03-desktop-port-goal.md#android-ssh-multi-session-priority)
and [parity evidence boundary](../product/hermes-desktop-parity.md#reference-and-evidence-boundary)
supply no missing current-store edit. Preserve newer closures and all qualification
limits; neither patch was applied or deleted and no goal proof was changed.

## Maintainer checklist

- [x] Read all five current bundle files in place; compare the full failure inventory
  with open task coverage and inspect relevant source/fixture seams.
- [x] Review saved ledger proposals against current records, Sources and reports;
  drop obsolete edits without reopening completed work.
- [x] Add one bounded repair through the task CLI, first in Now, without modifying
  running/awaiting-integration tasks.
- [x] Validate the task store, changed local links, failure inventory, disjoint
  active footprints and whitespace; inspect the diff before one local commit.

Maintainer validation: native `tasks validate --worktree .` passed with 297 tasks,
36 goals and the same two existing drafts. A read-only Python check verified 16
local links/Sources anchors, the 45-failure/17-file inventory and table counts,
commit references, declared paths, full-check command, first-Now ordering,
disjoint protected task footprints and nine preserved closures. Existing tracked
files were unchanged. Independent fresh-context read-only review found no blocker;
product correctness, repair effectiveness and native/live behavior were not judged.
`git diff --check` passed; the staged diff is checked again before commit.

Only task documentation was changed by the maintainer pass above. Its receipt did
not exercise Flutter/browser/native/device or live-Agent behavior. The subsequent
worker repair and its narrower executed evidence follow.

## Worker repair evidence

### Source, reproduction and causes

The worker started clean on `autowork/MAIN-REPAIR-003` at
`d42430728c2f5d5a7f54c0c2d31d3504495131b4`. `flutter --version --machine`
returned Flutter **3.44.2**, framework `c9a6c484230f8b5e408ec57be1ef71dee1e77020`,
engine `77e2e94772b6eb43759e34ed1ad7da4674e19cab`, Dart **3.12.2**, exit 0.
Checkout-local metadata was prepared with
`flutter pub get --offline --enforce-lockfile` (exit 0, no lockfile change).
All five original evidence files were read in place; no evidence bundle is
included in the change.

The assigned `AUTOWORK_PORT_BASE=20100` reserves **20100–20199**. Read-only
`ss -ltn '( sport >= 20100 and sport <= 20199 )'` showed existing listeners at
**20101, 20128, 20131 and 20132**, matching the recorded socket failures.
Their owners were not inferred, contacted or terminated. A host-load sample
reported 24 logical CPUs, load averages 5.94/6.15/6.39 and 43,026,152 kB available
memory. These are context, not historical load measurements or a flaky verdict.

Running the 17-file task inventory on the unchanged worker baseline (with
`--reporter expanded` for logging) reproduced
**all 45 names in the inventory, with no extra or missing names**:
`01:35 +144 -45: Some tests failed.`, exit **1**. The same 25 widget timeouts and
20 bind failures were present, including secondary uninitialized/double-disposal
teardown errors. The original single-case generated-key mount also failed in
isolation before any change.

Confirmed shared causes and bounded corrections:

- Android connection mounts used the real saved-access secure-store read without
  a deterministic platform response. The panel correctly remains busy until that
  read settles. The generated-key mount passed all 14 existing tests when only
  `sshQuickConnectStoreProvider` was overridden. Six mounts now use
  [a deterministic saved-access fake](../../test/features/hermes_chat/support/fake_ssh_quick_connect_store.dart)
  through that existing provider. Unexpected save/delete effects fail rather than
  persisting anything. Existing keyboard, large-text, consent, clipboard and caller
  ownership assertions are unchanged. A focused
  [saved-access case](../../test/features/hermes_chat/widgets/ssh_quick_connect_test.dart)
  covers pending reads, sanitized error settlement and late completion after caller
  cancellation with no connection effects. Real store save/forget tests remain.
- Both fixture allocators attempted one counter-selected port. Isolate-local
  counters were not port ownership; an occupied candidate failed before the
  uncertainty, Stop, recovery or malformed-read assertions ran. The
  [shared support-only allocator](../../integration_test/support/fixture_server.dart)
  now retains a successful exclusive bind, skips only address-in-use errors and
  scans at most 60 candidates in **20120–20179** for this assignment. Offsets
  0–19 and 80–99 stay outside this HTTP fixture pool. The existing offset is a
  starting hint, not a reservation. Without an assigned range, OS allocation is
  retained; malformed assigned ranges fail closed. The old unit-test import
  re-exports this same allocator. No `shared: true`, probe-close-rebind, foreign
  listener cleanup or out-of-range fallback is used.
- [Read fixture cleanup](../../integration_test/support/local_serve_read_fixture.dart)
  is safe before start, after allocation failure and on repeated close; duplicate
  start cannot overwrite a live server. Chat cleanup releases held history/submit,
  fences late socket writes and closes owned HTTP resources in `finally`.
  Setup cleanup is registered as each resource is acquired, so a later failed bind
  cannot dispose a previous test's channel or strand an earlier fixture.
  [Public-seam regressions](../../test/core/hermes/support/fixture_server_test.dart)
  hold owners in two isolates and a separate Dart process, rotate through more
  than one pool length, verify the original listener still responds, exhaust the
  pool without escaping it, retry after releasing an owned port, and verify held
  chat-history shutdown. The allocation and partial-start regressions failed
  against the old fixtures. Removing the history-release correction also makes
  its regression fail; the correction was restored before final checks.

No Agent API, credential authority, accepted SSH/gateway behavior or owner/replay
invariant changed. The production connection panel delta is **formatting only**:
its pre-existing indentation failed the task's explicit 35-file format check.
`git diff --ignore-all-space` confirms no semantic panel delta.

### Executed checks and remaining gate

The exact named affected-file command for the repaired candidate (the baseline
used the same inventory with `--reporter expanded`; no test-name filters) is:

```bash
flutter test --no-pub --concurrency=1 test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart test/features/hermes_chat/screens/compact_connection_presentation_test.dart test/features/hermes_chat/screens/hermes_ssh_no_cli_test.dart test/features/hermes_chat/providers/managed_ssh_serve_test.dart test/features/hermes_chat/providers/managed_ssh_serve_reads_test.dart test/features/hermes_chat/providers/managed_ssh_session_recovery_test.dart test/features/hermes_chat/widgets/connection_information_help_dialog_test.dart test/features/hermes_chat/widgets/managed_ssh_generated_key_ui_test.dart test/features/enrollment/hermes_welcome_recovery_test.dart test/core/hermes/channel/hermes_serve_credential_lifetime_test.dart test/core/hermes/channel/hermes_serve_cleanup_ownership_test.dart test/core/hermes/channel/hermes_local_serve_restoration_test.dart test/core/hermes/channel/hermes_local_serve_chat_test.dart test/core/hermes/channel/hermes_local_serve_reads_test.dart test/core/hermes/client/hermes_web_lifecycle_test.dart test/core/hermes/client/hermes_session_history_export_test.dart test/core/hermes/client/hermes_web_read_adversarial_test.dart
```

The repaired candidate's terminal result is **`01:05 +189: All tests passed!`,
exit 0**. The earlier baseline failures are accounted for by exact name, not
classified as flaky or hidden as unrelated failures.

Additional affected-boundary commands:

```bash
flutter test --no-pub --concurrency=1 --reporter expanded test/core/hermes/support/fixture_server_test.dart test/features/hermes_chat/widgets/ssh_quick_connect_test.dart test/features/hermes_chat/widgets/managed_ssh_connection_panel_test.dart test/features/hermes_chat/widgets/platform_local_connection_behavior_test.dart test/features/hermes_chat/widgets/platform_local_connection_panel_test.dart test/core/hermes/ssh/secure_ssh_quick_connect_store_test.dart test/core/hermes/client/hermes_web_read_test.dart test/core/hermes/client/platform/hermes_api_transport_io_test.dart test/features/enrollment/gateway_https_flow_test.dart test/core/hermes/channel/hermes_remote_gateway_test.dart test/features/hermes_chat/bots/bot_chat_navigation_test.dart test/features/hermes_chat/bots/bot_chat_channel_test.dart test/features/hermes_chat/screens/hermes_chat_session_workspace_test.dart
flutter test --no-pub --concurrency=4 --reporter expanded test/features/hermes_chat/providers/managed_ssh_serve_test.dart test/features/hermes_chat/providers/managed_ssh_serve_reads_test.dart test/features/hermes_chat/providers/managed_ssh_session_recovery_test.dart test/core/hermes/client/hermes_web_lifecycle_test.dart test/core/hermes/client/hermes_session_history_export_test.dart test/core/hermes/client/hermes_web_read_adversarial_test.dart
```

The adjacent 13-module check returned **`00:46 +148: All tests passed!`, exit 0**;
the six-module overlap check returned **`00:06 +119: All tests passed!`, exit 0**.
Long-capable test/analysis invocations used `autowork-run timeout 600` around the
commands. These counts are separate selections, not an aggregate full-suite total.

Other final check results (full command strings are retained in the worker report):

| Command / scope | Result | Exit |
| --- | --- | ---: |
| Task Checks' exact 35-path `dart format --output=none --set-exit-if-changed` command | 35 files, 0 changed | 0 |
| Same format flags on the four new Dart support/test files | 4 files, 0 changed | 0 |
| `flutter analyze` | No issues found | 0 |
| `autowork tasks validate --worktree .` | 297 tasks, 36 goals; two unchanged existing drafts | 0 |
| Scoped documentation readback, local links and recorded-inventory comparison | Passing; no unsupported full-gate claim | 0 |
| Docs Sync `docs.py stale .` and `docs.py check .` | No role manifest; no manifest coverage inferred | 0 each |
| `git diff --check` | No whitespace errors | 0 |

Independent read-only review confirmed preserved assertions and the whitespace-only
production delta. Its one test-hygiene finding was corrected: consecutive-port
inequality applies only to the reserved allocator, not OS-assigned ephemeral ports,
which may legitimately repeat after close. Live-owner uniqueness remains checked
in both modes. Unreserved-mode runtime qualification was not part of the worker's
assigned-port test runs.

No task records, shared history, dependency/lockfile or upstream checkout
were edited. Scoped Docs Sync Maintain updates this evidence owner only; the
inspected API/state, transport/security ADRs and enrollment candidate need no
product wording change.

**The complete offline gate is not a worker result.** The execution contract
explicitly assigns the unchanged
`flutter pub get --offline --enforce-lockfile && flutter test --no-pub --concurrency=1`
command to the coordinator on the merged tree. Its exit, terminal counts and any
remaining failures must be recorded after that run. Do not infer green main,
integration or goal acceptance from these focused passes. No Android device,
browser, native application or live Agent/gateway was exercised; Android/Linux
widget variants and loopback Dart fixtures ran on the Linux Flutter test host only.
