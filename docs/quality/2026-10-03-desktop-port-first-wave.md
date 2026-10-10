# Desktop port first wave — 2026-10-03

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


## Delivered bounded scope

Owner priority: a 1:1 Hermes Desktop product port in Flutter. Documentation now
uses Desktop feature coverage, navigation, terminology, interactions and recovery
as the target, with responsive differences explicitly tracked rather than treated
as substitute goals. Historical milestone/card evidence remains unchanged.

Implementation: `lib/shared/widgets/app_shell.dart` now retains an in-memory
sidebar expanded choice and provides a keyboard-accessible collapse/expand toggle
at desktop widths. Collapsed destinations remain named and navigable. The new
`test/shared/widgets/app_shell_desktop_parity_test.dart` covers toggle traversal,
selected route, retained child state/draft during toggle, compact/mobile resizing,
and short windows with enlarged text. No new backend or Wing Link requirement.
Relaunch persistence is deliberately not implemented in this slice.

The existing nested-route semantics container was present in the builder's
baseline (`desktop-port-shell/app_shell.before.dart`); it was not introduced by
this wave. HEAD diff alone includes earlier work and is not wave attribution.

## Documents and audit

Updated: `ROADMAP.md`, `docs/adr/client.md`,
`docs/product/hermes-desktop-parity.md`, `docs/product/hermes-desktop-ui-gap.md`.
Plan/ownership manifest: `docs/plans/2026-10-03-desktop-port-first-wave.md`.
Audit: `docs/analysis/2026-10-03-desktop-port-next-gaps.md`.

Read-only Desktop reference:
`withdrawn reference revision`.
Collapse behavior/persistence reference:
`withdrawn source citation,670–713`.
Upstream reference code/tooling was not edited. No removal or optionality of the
current Wing Link dependencies is claimed.

## Verification evidence

Builder logs inspected by parent:
`<home>/.hermes/profiles/wing/cache/scratch/desktop-port-shell/`.

- `red.log`: original missing-toggle regression failed (0 passed, 1 failed);
  the independent reviewer inspected this historical RED, not a new RED rerun.
- `green-final.log`: 3 passed, 0 failed.
- `related.log`: 40 passed, 0 failed.
- `npm-test.log`: 2,397 passed, 0 failed; this is the builder's full-suite run,
  separate from the parent's fresh verification below.
- `format-check.log`: 2 files formatted, 0 changed.
- `analyze-final.log`: no issues found.

Independent read-only reviewer (`deleg_e8f4754e`, `sa-0-bdb66f15`) found no
high/medium bugs attributable to the wave. Reviewer independently ran
`flutter test --concurrency=1 test/shared/widgets/app_shell_desktop_parity_test.dart`
(exit 0, 3 passed) and scoped `git diff --check` (exit 0).

Parent verification logs:
`<home>/.hermes/profiles/wing/cache/scratch/desktop-port-first-wave-parent/`.
Exact commands, exits and UTC timestamps are captured in `results.json`.

- `dart format --output=none --set-exit-if-changed lib test integration_test`:
  exit 0, 2026-10-04T01:24:11.930757Z–01:24:14.651914Z.
- `flutter analyze`: exit 0,
  2026-10-04T01:24:14.652173Z–01:24:19.397753Z.
- `flutter test --concurrency=1`: exit 0,
  2026-10-04T01:24:19.398156Z–01:30:19.583594Z; **2,397 passed, 0 failed,
  0 skipped**, parsed from `test.log:2585`: `05:56 +2397: All tests passed!`.
  Machine-readable counts are recorded in `parsed-counts.json`.
- `git diff --check -- ROADMAP.md docs/product/hermes-desktop-parity.md docs/product/hermes-desktop-ui-gap.md docs/adr/client.md lib/shared/widgets/app_shell.dart`:
  exit 0, 2026-10-04T01:30:19.583893Z–01:30:19.588988Z.

Parent format summary: 399 files, 0 changed. Parent analyzer: no issues.
All four parent checks passed. The bounded first wave is implemented and locally
verified with independent source review; runtime/card acceptance remains unobserved.

## Review limits and next slices

Nested-Navigator modal semantics is a pre-existing risk/test gap: the semantic
boundary may retain sidebar exposure during an intentional nested modal. This
wave does not validate modal barriers or screen-reader execution. Resize coverage
does not prove draft retention across replacement of mobile/desktop shell layouts.

Audit-ranked next slices: exact Copy session ID, searchable keyboard-first Chat
profile picker, collapsible Pinned/Chats sections, then sidebar recents/navigation
regrouping. Each needs its own source pin, bounded implementation and evidence.

No browser/native desktop/screen-reader/live Agent execution, runtime/card
acceptance, full Desktop parity, CI/merge or release qualification is claimed.
No commits were created. Run-summary accounting is not available from this host;
no estimated token or elapsed totals are supplied.
