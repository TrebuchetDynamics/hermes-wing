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

Only task documentation is changed by this pass. No Flutter/browser/native/device
or live-Agent behavior was exercised; product repair and green main remain pending.
