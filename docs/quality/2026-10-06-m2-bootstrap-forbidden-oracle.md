# M2 required-capabilities HTTP 403 recreation oracle

> Reference correction: [official Desktop authority](official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


## Delivered change and boundary

Card `t_df29f3c6`, task `DOC-M2-BOOTSTRAP-FORBIDDEN-ORACLE` adds the
missing required-capabilities HTTP 403 control to
`test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart`.
All four inherited controls remain: positive completion, resource HTTP 401,
resource HTTP 403, and bootstrap HTTP 401. The shared denial assertion also now
checks byte-identical serialized remembered selection, not only decoded identity.
No production code, dependency, API, packaging or upstream reference was changed.

The existing connection path requires `client.capabilities()` before detached-run
recovery. Its typed HTTP 401/403 classification is authentication failure
(`lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart`).
The transport fixture rejects at that required read, rather than injecting a
channel or directory state. No production defect was found or fixed.
Permanent reference locations are `hermes-agent/` and `withdrawn source citation`; neither
was edited. No deeper upstream contract change is claimed.

## Acceptance evidence

1. Five distinct oracle controls executed successfully, together with the three
   required nearest authentication/restoration targets: 65 passing tests, exit 0
   (`.task-evidence/t_df29f3c6/tests.json` and `tests.log`). This reruns the four
   predecessor controls; predecessor receipts are not substituted for execution.
2. Bootstrap HTTP 403 logs two initial denied capabilities attempts and three
   cumulative attempts after public Retry. The fixture records every transport
   attempt before rejection. Both denial checkpoints retain the byte-identical
   durable origin/profile/session/run lease and serialized remembered selection;
   decoded exact identity is independently asserted. Send/composer are absent,
   transcript empty, no canonical history is admitted and only GET health or
   capabilities routes occur. No endpoint credential deletion/save is attempted.
3. Explicit synthetic restoration of the original authority uses the same public
   Retry. The canonical history gate retains the original lease until hydration;
   then the canonical user and assistant IDs, order, roles, completed status and
   original session identity are asserted before settled writable UI. Every
   control reports lifetime runStarts=1, sessionCreates=0, otherMutations=0;
   recovery mutation delta=0. Foreign/substitute history and event reattachment
   routes are excluded by the request allowlist.
4. Analyzer exit 0, no issues; scoped format exit 0, zero changed files. Scope
   verification checks local document links, whitespace and scoped git diff.
   Import closure and analyzer input hashes match checked-out bytes and the
   task-local mirror. Package config/graph and pubspec/lock are source-equal;
   the Wing package resolves to the mirror and external package roots/manifests
   exist. Input fingerprints, baseline-relative patch, command cwd/argv/exits
   and preservation receipts are retained in the task evidence directory.
5. M2 remains unverified and `authoritative_counts_unavailable`. These are
   deterministic Linux-hosted Flutter widget tests at the injected HTTP seam,
   not an actual HTTP server or physical platform qualification.
6. The task-only local branch commit receipt and supported goal helper receipts
   are retained as `agent-commit.json` and `ledger-commands.json` respectively.
   The helper writes only this task's completion and bounded M2 evidence;
   final integrity verifies unrelated source preservation and qualification
   ceilings. Native same-card review is the final worker handoff, not approval.

## Executed checks and receipts

Tests and analyzer cwd:
`<repo>/.task-evidence/t_df29f3c6/mirror`.
Formatting and scope cwd: `<repo>`.

```text
flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart --concurrency=1 --reporter expanded
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart
python .task-evidence/t_df29f3c6/verify_scope.py
```

The fresh mirror copies current lib/test/integration_test/assets and manifests,
reusing existing offline package metadata without pub resolution or installs.
It does not use or disturb the retained root test process. `import-closure.json`
and `final-integrity.json` bind checked-out input and package bytes to executed
checks; `baseline-relative.patch` isolates this card from inherited dirty work.
The import delivery boundary is Flutter widget execution through existing
`flutter_test` dependencies, not installed or packaged runtime delivery.
All acceptance test/analyzer runs passed on the first attempt. An earlier
format check preceded the added byte-identity assertion; `format-final.json`
is the final-byte format check. No failing assertion was weakened.

Ledger attempt: closing the final bounded M2 task before recording passing
evidence triggered the CLI helper's automatic `met` promotion. The ledger
verification correctly failed (exit 1); this is not a test failure. The
`restore_ceiling.py` receipt records use of the supported helper module's
`load`/`dump` normalization functions to restore `unverified`, followed by
CLI `render` and exact unrelated-state/prose comparison (exit 0). No helper
source was changed and no qualification evidence was invented. The required
`authoritative_counts_unavailable` ceiling remains unchanged.

## Remaining qualification and questions

NOT_CHECKED: Android OS process death, secure-storage/keystore durability,
live authorization/revocation, real HTTP, inference, devices, notifications,
physical/native/browser interaction, platform builds, packaging/install,
signed distribution, deploy/release and full suites. No new platform or
runtime delivery support is claimed. See the
[predecessor bootstrap record](2026-10-06-m2-bootstrap-denial-oracle.md#remaining-qualification-and-questions)
and [acceptance gaps](../test-plan.md#acceptance-records-and-gaps).

No owner question is required. Default applied: synthetic capabilities HTTP 403,
original-authority restoration and isolated Linux-hosted widget execution;
no live, privileged, destructive or external action.
