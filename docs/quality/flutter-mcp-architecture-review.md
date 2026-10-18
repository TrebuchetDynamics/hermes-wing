# Bounded Flutter MCP architecture review

Read-only assessment for **DEV-001-c7**, using the [accepted tooling plan](../plans/2026-10-18-flutter-mcp-architecture.md).
Start with the [existing SSH feedback plan](../plans/2026-10-18-ssh-failure-feedback.md), not a new architecture layer.
No product behavior was reproduced or changed. Findings below are source inspection
and test-assertion review, not executed test results or native SSH qualification.

## Evidence identity and tooling

- Captured Wing commit: `2ddbb51b69044c71411e32168750a9a92db4c731`;
  tree: `0e5e0f692aa269528eda2a9ff5a14c09d6ec43e5`.
  `git status --short` was empty before and immediately after MCP inspection.
- Installed SDK: Flutter checkout `c9a6c484230f8b5e408ec57be1ef71dee1e77020`;
  `dart --version`: Dart SDK 3.12.2 stable, Linux x64, built
  `Tue Jun 9 01:11:39 2026 -0700`. Dart executable SHA-256:
  `c03ad868b5c53e31461b0fef22dc6eb6aeb56b7567efff6ca488ce9c4a6f8a6a`.
- `dart mcp-server --help` succeeded. Two temporary stdio sessions (inventory,
  then review) used exactly
  `dart mcp-server --disable=all --enable=analyze_files,lsp,roots`.
  Both initialized `dart and flutter tooling` 0.1.4 with protocol `2024-11-05`.
  Each `tools/list` contained **only** `roots`, `analyze_files`, `lsp`.
- Client `roots/list` supplied only this isolated task workspace;
  `tools/call roots` added only that same URI. No other workspace or upstream
  checkout was selected. Roots are scope, **not an OS sandbox**: LSP also returned
  ancestor-checkout duplicate symbols. Only task-workspace URI matches were used
  and checked against direct source; ancestor matches are not review evidence.
  Do not infer hermetic package resolution from the selected root.
- `tools/call lsp` with `command=resolveWorkspaceSymbol` resolved the six names
  below. Ranges are zero-based start/end positions from MCP; declarations are
  one-based direct-source lines. Some ranges include documentation comments.

| Exact symbol | Task-workspace source | MCP range | Declaration |
| --- | --- | --- | --- |
| `HermesApiChannel` | [channel] | 44:0–946:1 | 47 |
| `ManagedSshConnectionController` | [controller] | 26:0–445:1 | 28 |
| `managedSshConnectionControllerProvider` | [controller] | 12:0–20:2 | 13 |
| `ManagedSshConnectionPanel` | [panel] | 15:0–30:1 | 16 |
| `ManagedSshConnectionForm` | [form] | 98:0–132:1 | 100 |
| `LocalizedManagedSshConnectionForm` | [localized form] | 9:0–101:1 | 11 |

- `tools/call analyze_files` passed `applyFixes=false` and one root with seven
  explicit paths: the five source files in the table plus
  [API connection] and [serve reads]. Result: **`No errors`**, `isError=false`.
  Direct source confirms these are the channel library/parts, controller and
  presentation modules; no diagnostic conflict was found. This is not a
  whole-project analyzer pass. A clean analyzer does not establish good
  architecture, runtime correctness or native SSH qualification.
- Bounded request/result, source-hash and SDK identity receipts remain in private
  task scratch evidence, not repository fixtures. Protocol logging was not enabled.
  Both owned servers exited with code 0 after stdin closed; their process groups
  had no surviving processes. No persistent connector was installed or configured.
  Temporary MCP access is not persistent native connector installation.

## Caller, ownership and failure handoffs

```text
Chat layout → panel → localized form → form.onSubmit → panel._submit
  → Riverpod controller → reviewed SSH forward → channel acquisition
  → API bootstrap OR explicitly selected Android serve reads
  → connected owner, or joined cancellation/lease cleanup → panel feedback
```

**Facts.** [Chat layout] lines 278–289 owns the panel's navigation callbacks.
[Channel provider] lines 24–40 owns the production `HermesApiChannel` and its
reactive state projection. [Forward provider] lines 7–18 owns an app-scoped
forward independently of screen lifetime. [Controller] lines 13–21 reuses these
providers and registers disposal; lines 64–285 orchestrate credentials, reviewed
fingerprint, tunnel, captured channel owner and exact recovery selection.
[Chat screen] lines 917–921 reads reconnect state only if the controller exists.

The controller subscribes to tunnel loss before Agent acquisition (lines
166–194). Generation/owner guards reject late adoption; `_changed` retires a
replaced lease without disconnecting the replacement (lines 344–385).
`cancel(attemptId:)` shares pending cancellation, revokes credentials/ownership
before yielding, disconnects only its captured owner, then disposes the lease
(lines 388–437). Panel cancellation/disposal uses the acquired attempt ticket,
while its own generation fences late UI completion ([panel] lines 42–143).
These are complementary lifetimes, not evidence for merging all state into UI.

**Failure path.** [API connection] lines 3–23 classify 401/403 as Agent
authentication failure; lines 198–212 publish typed channel error state rather
than throw it to the caller. [Serve reads] lines 98–107 similarly publish
`_serveFailure(error)`; its mapping is at lines 355–368. Unsuccessful current
adoption awaits `cancel()` and returns `false` ([controller] lines 239–247).
Channel disconnect resets to a fresh `HermesChannelState` ([session teardown]
lines 4–24), removing the typed failure. The boolean cannot carry that reason.
The panel maps `false` to generic copy unless it captured a trust failure;
exceptions get only its small SSH allowlist ([panel] lines 54–62, 102–123).
The localized adapter passes copy/state through; the form renders the sanitized
summary as a live region above Connect ([localized form] lines 93–99;
[form] lines 826–845).

This supports the previously planned classification-loss mechanism. It does
**not** establish why a real phone failed, that every failure is silent, or that
cleanup should stop clearing sensitive channel state.

## Nearest tests: assertions inspected, not run

| Existing seam/test | What its assertions cover | What they do not establish |
| --- | --- | --- |
| [Channel connection tests] 550–623 | Bounded failure without throw; typed 401, incompatible response, network/TLS/timeout categories | Classification surviving controller teardown into visible UI |
| [Panel/controller tests] 250–302; 311–378 | Real channel 401 rejection, no root fallback, lease close and credential clearing; joined/reentrant cancellation including cleanup errors | Localized Agent-authentication feedback after held teardown |
| [Panel/controller tests] 1431–1575 | Generic sanitized transport feedback, stale trust, replacement protection, failed adoption cleanup, attempt-ticket fencing and cancel preserving existing Agent | A composed production-channel failure-to-form explanation |
| [Serve tests] 117–169 | No guessed serve fallback, denied credential closes lease, held read/tunnel loss and replacement fencing | Serve failure category rendered by real panel/form |
| [Recovery tests] 266–284, 436–460 | Cancellation during secure recovery cannot dial/adopt or erase replacement owner | A new feedback result obeying the same ownership fences |
| [Form tests] 167–299, 301–378 | Secret clearing, safe late completion/cancel, retained draft, keyboard traversal at 320×480 and 200% text | New terminal feedback/retry revealed after user scrolls away during pending work |

## Two bounded recommendations, one existing implementation plan

Both belong to **WING-001-b3** in the [SSH feedback plan](../plans/2026-10-18-ssh-failure-feedback.md#smallest-complete-implementation).
No additional implementation task or refactor is approved here.

1. **Medium; strong recommendation (judgment): retain an owned, allowlisted failure
   outcome through cleanup at the existing controller interface.** The inspected
   failure handoff above is the evidence, not a runtime reproduction. Reuse
   `ManagedSshFailure`/`HermesConnectionFailureKind`; keep channel reset and joined
   cleanup. Do not parse raw error strings or add a global last-error cache.
   Dependency category: **mock** at the external SSH/Agent seam, using existing
   deterministic forward/client adapters; no new port is justified.
   Deletion test: deleting the controller moves lease/owner/recovery complexity
   into callers, so retain this deep module. Carrying the outcome there improves
   locality and gives the panel leverage without another state authority.
   Validation target: the already-planned composed 401/403 production-channel,
   held-cleanup, localized-panel case, with zero success calls and stale/cancel
   rejection; extend for explicit serve denial. Update every caller if its return
   contract changes (the only production `connectSsh` caller is the panel).
2. **Low; worth exploring (judgment): reveal owned terminal feedback using the
   existing form summary.** Dependency category: **in-process** presentation.
   The summary/live region exists, but [form] lines 313–374 and 637–645 show no
   terminal-error reveal coordination; current compact tests cover navigation,
   not that transition. This is an inspected accessibility risk, not a reproduced
   hidden-message bug. Deletion test: removing the form or localized adapter
   moves validation/secret handling or product copy into callers; preserve both.
   Add only the minimum scroll/focus coordination if the planned regression
   demonstrates the gap. Locality stays in form presentation; leverage is an
   accessible next action for both API and serve failures. Acceptance is the
   existing plan's 320×480/200%-text, scroll-away-during-pending, hit-tested retry
   check without test-side `ensureVisible` manufacturing visibility.

**Top recommendation:** execute the first correction through WING-001-b3, with
its composed regression before changing behavior. Preserve Riverpod, channel
capability gates, host trust, explicit transport/profile identity and Agent
ownership. No new architecture layer, backend or transport fallback is warranted.

## Verification and limits

No `codebase-map-understand.md` was found; the assessment used live committed
source, the client/API/security/runtime ADRs, threat model and existing plans.
`git rev-parse HEAD HEAD^{tree}`, status, SDK/help, restricted inventory, symbol
resolution and scoped analysis were executed. Source/test/platform hashes and
manifest/lock hashes were rechecked unchanged; only this report and the plan link
are changed. Changed Markdown links/source line references and `git diff --check`
were checked. No source, dependency, installation or configuration edits occurred.

Per task scope, no Flutter tests, full product gate, build, runtime attachment,
app launch, live Agent, device or upstream checkout was exercised. Existing
analyzer/test gates remain authoritative for later implementation; this review
neither replaces them nor claims a new pass. Native SSH, secure storage, actual
keyboard/IME/screen-reader feedback and live reachability remain unverified here
and retain their existing qualification tasks. Revisit after controller return,
channel teardown, ownership, form feedback or SDK tool-inventory changes.

[channel]: ../../lib/core/hermes/channel/hermes_api_channel.dart
[controller]: ../../lib/features/hermes_chat/providers/managed_ssh_connection_controller.dart
[panel]: ../../lib/features/hermes_chat/widgets/managed_ssh_connection_panel.dart
[form]: ../../lib/features/hermes_chat/widgets/managed_ssh_connection_form.dart
[localized form]: ../../lib/features/hermes_chat/widgets/localized_managed_ssh_connection_form.dart
[API connection]: ../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart
[serve reads]: ../../lib/core/hermes/channel/api_channel/hermes_api_channel_serve_reads.dart
[session teardown]: ../../lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart
[Chat layout]: ../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart
[Chat screen]: ../../lib/features/hermes_chat/screens/hermes_chat_screen.dart
[Channel provider]: ../../lib/features/hermes_chat/providers/hermes_channel_provider.dart
[Forward provider]: ../../lib/features/hermes_chat/providers/managed_ssh_provider.dart
[Channel connection tests]: ../../test/core/hermes/channel/hermes_api_channel_tests/connection_tests.dart
[Panel/controller tests]: ../../test/features/hermes_chat/widgets/managed_ssh_connection_panel_test.dart
[Serve tests]: ../../test/features/hermes_chat/providers/managed_ssh_serve_reads_test.dart
[Recovery tests]: ../../test/features/hermes_chat/providers/managed_ssh_session_recovery_test.dart
[Form tests]: ../../test/features/hermes_chat/widgets/managed_ssh_connection_form_test.dart
