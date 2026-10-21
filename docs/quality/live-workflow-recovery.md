# Exact-session live recovery: pending qualification

Task: `VERIFY-LIVE-WORKFLOW-RECOVERY`, M1.
Status: **offline regression evidence only; live acceptance NOT_CHECKED**.

## Admission and scope

At Wing baseline `eb070f1ce6a1d97d309d918e594eec5fe1428b1c`, the
[predecessor retry](live-workflow-retry-r2.md#remaining-live-acceptance) still
requires authoritative physical provider-call admission, disposable QA
authentication/grants and the actual two-process workflow. The open
`PARITY-LIVE-WORKFLOW-LIVE` entry in [the task index](../tasks/work-queue.md#current-work-queue) preserves
those requirements. Offline predecessor closeout is not a qualified live session.
The [synthetic resumed-send receipt](native-resumed-send.md) is not a substitute.

The live driver still invokes `requireQualifiedLiveBudget` before reading its
authorization input (`integration_test/linux_desktop_live_workflow_test.dart:180`);
the guard unconditionally throws `LIVE_INFERENCE_BOUND_NOT_QUALIFIED` at
`:395-400`. These source locations were inspected, not changed or invoked.
No live authentication, credential discovery, network reads, native GTK process,
inference or Agent mutation was attempted for this task. No new authorization
flow or production repair is introduced. M1 and live recovery remain unqualified.

## Bounded read-only procedure — not executed

Run only after the predecessor's **actual live** completed/Stopped runs and
intentional resumed send are qualified, using the same isolated disposable target
and a still-valid secret-safe read grant. If that target/session or grant no
longer exists, stop and obtain renewed qualification/access; do not create a
replacement session, run the generation driver or reuse personal state.

1. Bind the candidate source, native app identity and exact Agent/profile/session
   to the predecessor receipt. Obtain a fresh canonical baseline through the
   target's already qualified read operations: message identities/order and exact
   completed/cancelled run outcomes. Keep contents, credentials and private
   identities out of repository receipts. Record bounded counts and pass/fail
   comparisons, not raw history or private endpoint values.
2. Snapshot independent target-side mutation-attempt counters for sends, session
   creates, model writes, approval responses and Stop requests. If authoritative
   observation is unavailable, leave zero-mutation acceptance unqualified; an
   unchanged transcript or client-side estimate alone is insufficient.
3. Explicitly reconnect through production Wing, without Send, model reselection,
   approval or Stop. Read the same exact profile/session and canonical history/run
   outcomes again. Compare against the baseline; do not count cached rendering as
   successful reconciliation. Do not restart the shared gateway or enable inference.
4. Leave Chat for an existing non-mutating route and return. Repeat the exact
   identity/history/terminal-outcome readback. Record zero delta in **each** mutation
   counter across reconnect and route return, including failed attempts.
5. If a read naturally fails, retain the exact target and use explicit read Retry;
   assert no fallback session or mutation. Do not disrupt a live service to inject
   failure. Delayed old-owner metadata/history settlement and controlled failures
   remain deterministic checks below unless the disposable target has separately
   authorized fault controls. Read failure or missing canonical evidence means
   inconclusive live acceptance, never permission to replay prior work.

Keep execution bounded by the approved grant's lifetime and existing read limits;
no unbounded polling or automatic mutation retry. Record the named platform,
source binding, readback results, counter deltas and owned-resource teardown.
This procedure is a handoff, not a newly executable launcher or a live receipt.

## Existing recovery seams and fresh offline evidence

No executable input changed from the baseline. The existing production path:

- `lib/features/hermes_chat/gateways/hermes_gateway_directory.dart:187-191`
  retries restoration with the retained exact contact/session. `:775-856` defers
  default session selection and supplies the current activation-generation guard
  to `restoreSession`.
- `lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart:26-77`
  gates exact metadata/history reads and checks caller/selection ownership;
  `:79-134` fences history against connection, profile and selection changes.

Executed on the Linux host with Flutter 3.44.2 / Dart 3.12.2:

```sh
flutter test --no-pub --concurrency=1 test/core/hermes/channel/hermes_recovery_read_admission_test.dart test/core/hermes/channel/hermes_session_caller_admission_test.dart test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart test/features/hermes_chat/screens/hermes_chat_transcript_reconnect_test.dart --reporter expanded
flutter analyze --no-pub
git diff --check
```

Results: 99 tests passed; analyzer reported no issues; whitespace check passed.
The adversarial restoration cases retain the exact target on failed canonical
reads, exercise explicit Retry with zero mutations, and reject parked old-owner
metadata/history, including a host ownership roundtrip. Channel regressions fence
late status/history settlement and unresolved run ownership. The existing widget
reconnect/remount case reports recovery mutation delta **0**; its separate deliberate
setup sends and current-owner approval are not part of that recovery delta.
No tests were added or duplicated, and no production defect was reproduced.

Dependency caveat: `flutter pub get --offline` used the shared task package cache
and resolved SDK-compatible `intl 0.20.2`, `matcher 0.12.19`, `meta 1.18.0`,
`test 1.31.0`, `test_api 0.7.11`, `test_core 0.6.17` and `vector_math 2.2.0`.
The incidental lockfile rewrite was restored byte-for-byte before checks; no
manifest/lockfile change is included. These checks therefore qualify the available
offline package resolution, **not** reproduction of the committed lock resolution.
The committed lock SHA-256 is
`8c0c0624de03bccffd0fe05aa17cc2fc5b66e7b9c53dcaafec9ae88e65677854`.
Raw check logs and generated package metadata hashes are retained under the task's
`$TMPDIR`, not committed. The full directory suites were not repeated for this
documentation-only change; historical receipts retain their own source scope.

Only Linux-hosted unit/widget tests and static analysis were exercised here.
Native GTK/live reconnect, route return, canonical completed/Stopped/resumed-send
outcomes and independent zero-mutation counters remain pending after predecessor
qualification. Android, other native platforms, physical input, packaging and
release were not exercised. Revisit this receipt when the predecessor live receipt,
authorization, recovery implementation or relevant tests change. Local commit,
coordinator integration and live acceptance are separate outcomes.
