# Hash-suffixed plan task IDs: offline validation

This records verification of [PLANGAP-001-2f's accepted scope](../plans/2026-10-18-plan-traceability-ids.md#scope), not product or live-platform qualification.

## Recovered source

Assigned baseline `a1f0b7614080505ffa3c65b9b35beead8abbf304` already contains the
three-file parser candidate. Its delta from `36f4155f87e4c6ddaa1123a1c9baba0989081663`
has SHA-256 `3d92402b64126b7f92cc4fcf99415662ee06c125e375e80aa0efaa1c62251c27`.
No duplicate parser implementation or new test cases were added during recovery.

The three parser files and both prerequisite Chat test files match these exact
members of assembled tree `a2213ffd78bf6a485e09de0d218cc617f273a78e`:

| File | Git blob |
| --- | --- |
| `test/tooling/plan_backlog_contract_test.dart` | `3cbd2f2bf87b46c8274928b859b4243573854ccd` |
| `test/tooling/plan_backlog_traceability_test.dart` | `c51974caca6f7cae539f868bb7a58959b40215f8` |
| `test/tooling/support/plan_backlog_contract.dart` | `d8e30cb18093bd2eb5e4d283e8435f851d3d6622` |
| `test/features/hermes_chat/screens/hermes_chat_layout_width_test.dart` | `57440c9c05b4ea020b216675af2cf4161a0d5d15` |
| `test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart` | `5841eb19af112a473835873b3b3e01ea8c9a1a36` |

This verifies those five members, not equality of the entire assembly or reuse of
its broader test receipts. No Chat source was imported by this recovery.

## Regression evidence

The existing [mapping extraction](../../test/tooling/plan_backlog_traceability_test.dart)
and [body marker extraction](../../test/tooling/support/plan_backlog_contract.dart)
use `[A-Za-z0-9][A-Za-z0-9_-]*`. Literal delimiters and exact ID equality remain;
there is no case conversion, substring matching or new parser abstraction.

On this input, temporarily restoring only the two former uppercase-only ID
expressions reproduced six failures: the MCP plan had no recognized task, hashed
bodies were missing, and a hashed neighbor's link leaked into an uppercase body.
Restoring the exact baseline expressions returned **13/13 passes** with:

```sh
flutter test --no-pub test/tooling/plan_backlog_contract_test.dart test/tooling/plan_backlog_traceability_test.dart
```

The [existing contract cases](../../test/tooling/plan_backlog_contract_test.dart)
exercise both `TASK-ONE` and `DEV-001-c7`: unchecked live open/in-progress bodies;
checked x/X live/archive done bodies; missing/duplicate bodies; invalid states;
checkbox/location mismatches; and adjacent/prefix-neighbor link isolation.
The real inventory test discovers all 33 retained plans in this snapshot and
retains its disposition, ledger-membership, duplicate/missing-plan and direct
primary-body/bare-plan backlink checks. The inventory remains dynamic, not a
hard-coded count.

Focused formatting, repository-wide formatting and `flutter analyze --no-pub`
passed on the restored source. Broader offline gate results belong to the worker
report, not a claim that these tooling tests qualify application behavior.
Revalidate when either extraction site, body grammar, ledger IDs or plan inventory
changes; follow the [plan coverage policy](../plans/README.md#plan-to-task-coverage).
