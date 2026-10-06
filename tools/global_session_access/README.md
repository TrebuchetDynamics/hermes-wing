# Global session access: historical diagnosis

Task `t_1c1e6f37`. Source revision
`ca149a82189c8c9e5abd98b376bfeae1e43f6f3f` plus the existing dirty worktree.
The reference Desktop checkout was confirmed at
`2ed89070bc6c9e8231a37bb55df8a7722a3776b8`.

The original run delivered no feature and withdrew its candidates. The same-card
recovery now implements passive directory-lifetime observation and caller-guarded
Open/New in the production shell, pending independent review. See the
[current recovery runbook](../../docs/runbooks/global-session-access.md) and
`.task-evidence/t_1c1e6f37/` for current code-bound evidence. The findings and
commands below describe the original run, not current acceptance status.
This directory retains a diagnostic, not an implementation or acceptance suite.
Its intentionally RED shell case is outside `test/`, so ordinary test discovery
is not changed.

## Observed boundary

- Public `HermesChannel.selectSession` and `createSession` do not accept caller
  admission (`lib/core/hermes/channel/hermes_channel.dart:69,80`). Real
  `HermesApiChannel` delayed-result characterizations show both can commit after
  the initiating presentation lifetime ends while the channel remains current.
  Exposing/propagating the existing private selection guard is a viable narrow
  extension; its absence alone is not proof an expensive refactor is required.
- Guarded `restoreSession` is not an equivalent Open operation. It clears active
  selection immediately, before authorization/history admission
  (`lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart:22`).
- Reading `hermesGatewayDirectoryProvider` constructs and starts the directory
  (`lib/features/hermes_chat/providers/hermes_channel_provider.dart:47–56`).
  Startup refreshes inventories and restores remembered contact/profile/session
  (`lib/features/hermes_chat/gateways/hermes_gateway_directory.dart:334–367`).
  A real-provider diagnostic proves that a mere read causes a summary-loader
  call, connection replacement, profile selection and session selection, without
  an explicit shell action. Dependencies are deterministic fakes; no live host
  was contacted.
- A candidate using Riverpod weak observation plus `ref.exists` seeding also
  failed the zero-work requirement: collapse/expand constructed the directory
  (expected zero constructions, observed one). The candidate's focused RED
  regression and raw output are retained in the evidence directory. This is
  evidence that this candidate is unsafe, not proof every weak-listener design
  is impossible. Installed Riverpod warns that existence-conditioned logic
  does not rerun on initialization. Removing seeding without an authoritative
  replacement leaves initial contact/restoration ownership unqualified.

The original run stopped at a bounded passive directory ownership/lifecycle seam
that exposes current ownership and synchronous invalidation without initializing
startup, inventory refresh or restoration. If that requires separating directory
construction from explicit startup, the broader lifecycle callers and startup
regressions need to be included explicitly. Do not weaken contact/disposal fences,
use restore as an Open substitute, add a shadow selection store, or treat the
unqualified candidate as shipped. This is the task's extraction/lifecycle stop
condition, not a request to modify Hermes Agent or Wing Link.

## Commands and observed results

From the repository root:

```sh
flutter test --reporter json tools/global_session_access/admission_probe_test.dart --plain-name 'RED shell'
# exit 1: expected missing global loaded-session row on the real shell at /tools
flutter test --reporter json tools/global_session_access/admission_probe_test.dart --plain-name 'characterization:'
# exit 0: four diagnostic characterizations
flutter test --concurrency=1 --reporter json test/shared/widgets/app_shell_navigation_groups_test.dart test/shared/widgets/app_shell_desktop_parity_test.dart test/shared/widgets/app_shell_test.dart
# exit 0: 22 unchanged baseline tests
flutter test --reporter json test/core/hermes/channel/hermes_api_channel_test.dart --name 'new chat completion respects|obsolete history selection cannot replace pagination or run context|stale session history failures do not escape'
# exit 0: five unchanged baseline tests
flutter test --reporter json test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart --plain-name 'startup restores'
# exit 0: two unchanged startup restoration tests
flutter analyze
# final exit 0, no issues
 dart format --output=none --set-exit-if-changed tools/global_session_access/admission_probe_test.dart
# final exit 0, zero changes
```

The withdrawn candidate had 14 successful and three failed shell tests before
its additional collapse/initialization reproducer failed. These are NOT GREEN
acceptance evidence. Initial compile/lint mistakes were corrected; raw attempted
validation logs are retained rather than presented as successful checks.
Localization was regenerated after withdrawal and the original hashes matched.

## Acceptance disposition

| Criterion | Evidence/status |
| --- | --- |
| Baseline production-shell RED | Reproduced with actual AppShell/GoRouter and loaded fake channel |
| Persistent global Open/New Session delivery | NOT_DELIVERED; candidates withdrawn |
| Exact acknowledgement, pending, failure and sticky ownership | NOT_ACCEPTED; candidate incomplete |
| Zero incidental inventory reads/selection | BLOCKED; eager-start provider and weak-seed collapse reproductions |
| Accessibility/collapse/compact/resize qualification | NOT_CHECKED for a delivered feature |
| Existing shell and selected channel/restoration baselines | Commands above passed; not feature acceptance |
| Analyzer and diagnostic formatter | Final exit 0 |
| Production preservation | Eleven pre-existing scoped files hash-identical to run baseline; override signature edits reversed |
| Fresh compiled Chromium/global-recents flow | NOT_CHECKED; no deliverable to build/qualify |
| Native/Android/screen-reader/live Agent/provider/full parity | NOT_CHECKED; no such runtime work performed |

Raw logs, exact command receipts, parsed test counts, baseline-relative and
withdrawn candidate diffs, saved candidate/test files, source revision and hashes:

`/home/xel/.hermes/profiles/wing/autogoal/global-session-access/`

No commit, staging, upstream modification, profile configuration change,
continuation resume, browser fixture modification or external publication was
performed. Product routes and predecessor parity claims were not upgraded.
