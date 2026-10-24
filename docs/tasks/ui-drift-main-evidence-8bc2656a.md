# UI-DRIFT-REPAIR-001: main evidence at 8bc2656a

This is an evidence supplement for the existing
[UI-DRIFT-REPAIR-001](../../tasks/items/UI-DRIFT-REPAIR-001.md), not a new task,
repair contract, closure or qualification receipt. Start with that task's unchanged
Scope, Acceptance, Checks and Exclusions.

## Bundle inspected in place

Git-common directory reference:
`autowork-execution/main-evidence/8bc2656ab08e60baa7f4ba01a1b792e29229d30f/`.
Read `main_check.json`, `main-check.log`, `main-check.exit`,
`main-check-reruns.log` and `flaky_history.json` there; do not copy the bundle
into the repository.

- Checked revision: `8bc2656ab08e60baa7f4ba01a1b792e29229d30f`.
- Previous green: `e64f652bff5556e9d6201a0f25b717c160f79a4b`;
  red since `d0b4d1f47792df85fb5856309e1ac11b31a7bcad`.
- Dispatch names commit `8bc2656a`, which adds this task, not product code.
  Bundle history since green also names `ee7ba740`, `d0b4d1f4`, `ac665838`,
  `8a5bdca2`, `1d31d9c0`, `caf12e55`, `61e47dbf`, `588718f8` and `61743180`.
  Full titles remain in `main_check.json`.
- Log line 4820: `45:45 +4218 ~9 -4: Some tests failed.`; exit **1**.
- Isolated main reruns: none (`main-check-reruns.log` empty).
  Flaky history: `{}`; metadata flaky list: `[]`.
- Classification: `TEST_FAILURE`, not a pre-result crash or established flaky test.
  This bundle does not exercise the task's separate browser cluster B.

All four failures match the existing task's cluster A:

| Test file under `test/features/hermes_chat/` | Case | Bundle diagnostic |
| --- | --- | --- |
| `screens/hermes_chat_screen_auth_recovery_test.dart` | Add Hermes groups VPN within three primary connection choices | Lines 1912–1933: missing `managed-ssh-agent-port`; assertion at test line 538. |
| `widgets/connection_information_help_dialog_test.dart` | production chooser offers safe selectable connection help | Lines 2336–2357: missing `connection-information-help`; assertion at test line 33. |
| `widgets/ssh_quick_connect_test.dart` | first verified connection remembers only with explicit consent: false | Lines 2397–2419: `Bad state: No element` at `ensureVisible`, test line 224. |
| `widgets/ssh_quick_connect_test.dart` | first verified connection remembers only with explicit consent: true | Lines 2422–2444: same missing-element failure at test line 224. |

## Source trace and current candidate

Commit `588718f8` changed the SSH entry. Current source keeps optional Agent
port/profile under Advanced in
`lib/features/hermes_chat/widgets/managed_ssh_connection_form.dart:811–821`,
and hides general help in SSH in
`lib/features/hermes_chat/screens/state/hermes_chat_layout.dart:187–193`.
The intentional behavior is guarded by
`test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart:215–222`
and described in [Routes](../product/routes.md). The three failing test files
still access these controls without the corresponding supported navigation.
These paths and the failing tests are already in the existing task's Touches;
its Checks already include the unchanged full offline check:

```bash
flutter pub get --enforce-lockfile && flutter test --no-pub --concurrency=1
```

The task's attempt-1 report, read in place at Git-common
`autowork-execution/slot-data/UI-DRIFT-REPAIR-001/attempt-1/report.json`,
names candidate `aed3e7df2c5a0ef900c9f12374ce2ec4f7979ac7`. Its actual diff
changes the three named widget test files, the overlay browser spec and two
quality documents, without product-code changes. It is not an ancestor of this
maintainer checkout's `d4a18b13452db507471d81871c2d8c85e5792234`.

The worker reports 28 focused cluster-A passes and four focused browser variants
passing, plus a completed browser run of 91 passes and one pre-existing live
opt-in skip. Its feature-suite invocation timed out after 1338 passes; a later
65-module run reports 683 passes. Those are worker-reported, differently scoped
results, not a terminal pass of the original feature command or the full offline
check. No full-offline terminal result is supplied by that report. This maintainer
pass ran no Flutter, browser, native, device or live-Agent checks.

## Disposition and update trigger

At inspection, Git-common `autowork-execution/slots/UI-DRIFT-REPAIR-001.json`
still records state `running`; the worker process is absent and its candidate
report exists. Do not infer release, integration or closure from process exit.
The task is already first in Now, with the full check and all four failures
covered. Preserve its record while the slot/candidate remains in flight; no
second repair task, reordering, dependency change or manual closure is justified.
The overlapping retained CLONE03 task and CHAT-FIDELITY goal remain unchanged.

After the slot is released, refresh the existing task's Evidence through
`autowork tasks field` with this bundle reference and the actual resulting
review/integration/full-check evidence, if still relevant. Preserve newer closure
or planning, the original acceptance and browser cluster B. Until then, the
Evidence-field refresh is blocked by the prohibition on editing in-flight tasks,
not by a missing owner decision. This note supplies evidence only; it does not
restart a worker, waive a gate or establish green main.
