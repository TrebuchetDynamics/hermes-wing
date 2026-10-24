# CLONE03-LOCAL-NEXT retained check findings

## Contract and evidence

This is a check-blocker clarification for
[CLONE03-LOCAL-NEXT](../../tasks/items/CLONE03-LOCAL-NEXT.md), not another
implementation task or a new connection design. Keep every original Acceptance
item, exclusion, dependency and qualification boundary in the
[accepted handoff](plan-clone03-local-frontier.md). The task remains open;
[PARITY](../../tasks/goals/PARITY.md) remains partial.

Evidence was read in place under the Git-common `autowork-execution/` directory:

- `slot-data/CLONE03-LOCAL-NEXT/attempt-1/report.json`: candidate
  `cfcc8b01b4386fa18b39ec6796d73642d0467d7d`; reports 192 focused passes,
  direction-sensitive viewport repair and web compilation, not full-suite success.
- `slot-data/CLONE03-LOCAL-NEXT/attempt-2/report.json`: retry candidate
  `815da81bdf2e6906ab32d1be065d7c2cf7a344ff`; reports the same focused coverage
  and four connection failures reproduced before production edits on baseline
  `d0b4d1f47792df85fb5856309e1ac11b31a7bcad`, then in isolated reruns.
- `slots/CLONE03-LOCAL-NEXT.json` and
  `59ccaa24e11c48608f43bc8e82068649.{json,log}`: held integration candidate
  `f8874f9e7aa8be96e717d4fd291171ecdcf12b70`, full-check exit 1, retained
  finding that these failures are new relative to the checked base. That gate
  disagrees with the worker's baseline attribution; neither attribution waives
  repair or proves current main red/flaky. This is not an engineering-repair
  incident or a manual completion receipt.

No CLONE03 ledger-edit proposal exists in its retained attempt directories.
Nothing is automatically applied from another task's saved patch. The closed
MAIN-REPAIR-003 record stays closed; no open task duplicates these four findings.

## Bounded worker continuation

- [ ] Reconcile the retained candidate against current source; reuse working text
  direction changes rather than repeating or discarding them. Both worker reports
  name `lib/features/hermes_chat/presentation/hermes_markdown_block_viewport.dart`
  and `test/features/hermes_chat/presentation/hermes_markdown_block_viewport_test.dart`;
  include these in Touches because cached block extents must invalidate when
  direction changes. Preserve viewport ownership and inline-code selection,
  copying, safe links and link semantics.
- [ ] Resolve `hermes_chat_screen_auth_recovery_test.dart`:
  **Add Hermes groups VPN within three primary connection choices**. Its SSH
  field assertions currently expect Advanced fields immediately after choosing
  SSH (`test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart:526-538`).
  Exercise `managed-ssh-advanced` before those assertions; keep the three primary
  choices, VPN grouping, local endpoint and secret-obscuring checks intact.
- [ ] Resolve `connection_information_help_dialog_test.dart`:
  **production chooser offers safe selectable connection help**. The loop currently
  demands help in Local, SSH and Remote. Existing production composition hides
  the general help button in SSH
  (`lib/features/hermes_chat/screens/state/hermes_chat_layout.dart:187-193`),
  and `test/features/hermes_chat/screens/hermes_connection_primary_entry_test.dart:215-222`
  explicitly guards that absence. Assert the SSH absence separately, then exercise
  selectable help, keyboard activation, sanitized clipboard and focus return in
  its supported Local/Remote placements; account for the resulting copy count.
  Preserve all substantive guards, including compact/200-percent-text cases;
  do not reintroduce SSH help to satisfy the stale loop.
- [ ] Resolve both `ssh_quick_connect_test.dart` cases:
  **first verified connection remembers only with explicit consent: false** and
  **first verified connection remembers only with explicit consent: true**.
  Their input loop reaches `agent-profile` without opening Advanced
  (`test/features/hermes_chat/widgets/ssh_quick_connect_test.dart:214-225`).
  The form puts Agent port/profile in `managed-ssh-advanced`
  (`lib/features/hermes_chat/widgets/managed_ssh_connection_form.dart:811-821`).
  Exercise the existing expansion before entering hidden fields; retain host
  verification, explicit remember opt-in, exact saved profile, successful direct
  connection, and no displayed credential assertions. Restore fixture-owned
  platform overrides/resources even if an assertion fails. Do not expose Advanced
  by default, alter secure storage, or weaken consent/host trust.
- [ ] Reproduce and repair these fixture/navigation mismatches within the three
  added test paths. Run the primary-entry regression alongside them to prevent
  changing accepted connection presentation. If fresh evidence exposes a different
  cause, record it; this clarification does not authorize a connection redesign
  or unrelated production repairs. Baseline reproduction alone is not completion.
- [ ] Run all original Checks plus the added four-file connection target and the
  unchanged full check from CONTRIBUTING. Record real exits, terminal counts and
  any remaining failures in the existing frontier handoff. Focused passes do not
  replace full-suite results; do not skip/filter the full check, delete substantive
  assertions or increase timeouts. No coordinator reconciliation receipt is a
  worker prerequisite: the worker can repair these existing check blockers itself.

## Maintainer boundary

This pass changes task documentation only. No Flutter suite, browser, native
application, device, live Agent or provider is exercised or qualified here.
Native task validation, contract-preservation/source/link checks and
`git diff --check` validate this documentation change, not the retained product
candidate. The existing ROUND2 dependency still waits for CLONE03-LOCAL-NEXT.
