# M2 recreated-client bootstrap authentication-denial oracle

## Delivered change and boundary

Card `t_15da6893`; task `DOC-M2-BOOTSTRAP-DENIAL-ORACLE`.
The inherited app recreation oracle now has a separately named bootstrap
capabilities HTTP 401 control, alongside positive completion and resource-only
HTTP 401/403 controls. Only the inherited test and this report change; no
production repair was necessary. The production `HermesApiChannel`, directory,
providers, public Retry and serialized lease storage are exercised, not mocked
channel state setters. The deterministic HTTP transport callback throws the
existing typed status exception at `/v1/capabilities`, a required production
bootstrap read before inventory and detached-resource recovery.

This closes the bounded bootstrap-denial regression gap, not live authentication
qualification. Hermes Agent remains domain authority; no Wing Link traffic,
protocol, dependency, shadow state or fallback owner is introduced. The
[server-wins/no-replay decision](../adr/api-and-state.md) remains binding.

## Acceptance evidence

1. The separately named `bootstrap capabilities HTTP 401 denied recreated client
   retains exact owner without replay` case executes after one intentional
   submission, client/provider disposal and synthetic backend completion while
   absent. `_Backend._record` counts requests before authorization/route rejection.
   The bootstrap control rejects capabilities, not session/run resources.
   `expectBootstrapOnly` verifies typed connection authentication failure and only
   GET health/capabilities attempts before recovery, both on recreation and public
   Retry. Execution observed two denied bootstrap reads initially (including the
   production directory summary loader), then three after Retry. Byte-identical
   serialized lease and original origin/profile/session/run plus remembered
   contact/session survive. No foreign history, composer or Send is admitted;
   endpoint clear/delete/save counters remain zero.
2. Explicit synthetic original-owner authority recovery removes denial and uses
   the public Retry. Canonical history is held after authoritative terminal run
   status: the transcript stays empty and the lease remains byte-identical.
   Releasing history admits exactly the canonical user/assistant IDs, authors,
   order, text and completed statuses, then clears unresolved ownership. All
   recovery attempts are allowlisted GETs; no foreign/substitute history or event
   reattachment is permitted. Lifetime fixture counters are runStarts=1,
   sessionCreates=0, otherMutations=0; recovery mutation delta is zero. This
   accounts for attempted session creation, chat sends, Stop and approval writes
   as well as run submission; it is not live authoritative accounting.
   `oracle-fixed.json/log` retains four passing cases, including all predecessor
   controls. Predecessor receipts themselves remain unchanged.
3. `nearest.json/log` retains 60 passing nearest authentication/restoration cases.
   `analyze.json/log` reports no issues, exit 0. Formatter apply and verified
   receipts retain exact commands and exits. `scope.json/log` and
   `import-closure.json` prove current-source equality for all four executed test
   entrypoint closures, analyzed local Dart bytes and existing manifests, with
   `package:wing` resolving inside this task's isolated mirror. Baseline/current
   source fingerprints, preservation receipt and baseline-relative patch bind
   inherited dirty sources rather than pretending they equal HEAD. Scoped
   whitespace and local report links are checked. No root build/display resources
   or retained root tester were reused or killed.
4. Exercised platform: Linux-hosted Flutter widget tests with Linux target-platform
   variant, deterministic callbacks and in-memory serialized storage. M2 remains
   unverified and `authoritative_counts_unavailable`.
5. `agent-commit.json` records the local task-only `agent/wing/t_15da6893` branch
   SHA and equality of committed test/report bytes to current sources; checked-out
   HEAD, branch and real index remain unchanged. `ledger-commands.json` records
   supported task/evidence/render helper commands and `ledger-after.json` verifies
   M2 remains unverified and unrelated ledger state/prose unchanged. Native
   same-card review is the final implementation handoff, not independent approval.

## Commands and retained receipts

Receipts are under `.task-evidence/t_15da6893/`. Each command receipt records
absolute cwd, argv, timestamps and exit; logs retain actual output. Flutter tests
and analysis run in that directory's freshly copied source-closed `mirror/`;
formatter and scope verification run at repository root. No installs or pub
resolution changes were needed; existing offline dependencies were reused.

```text
dart format test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart
dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart
flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart --concurrency=1 --reporter expanded
flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart --concurrency=1 --reporter expanded
flutter analyze --no-pub
python .task-evidence/t_15da6893/verify_scope.py
```

Attempt accounting: initial oracle compilation failed because the new enum
assertion lacked its channel-contract import (`oracle.json/log`, exit 1). Added
that existing import; the fresh current-source rerun passed all four cases
(`oracle-fixed.json/log`, exit 0). Nearest tests and analyzer each ran once and
passed. Formatting applied one scoped file; final format verification changed
zero files. No product assertion was weakened and no production defect is claimed.

## Remaining qualification and questions

NOT_CHECKED: real HTTP server, live credential revocation/expiry, Android OS death,
keystore/secure-storage durability, live HTTP/inference, devices, notifications,
physical/native or browser interaction, native/browser builds, packaging/install,
signed distribution, release/deploy and full suites. The
[resource-only predecessor](2026-10-06-m2-forbidden-recovery-oracle.md) remains
historical bounded evidence; this receipt does not upgrade its qualification
ceilings. No owner decision is required. Default applied: synthetic required
capabilities HTTP 401 rejection, explicit original-authority restoration and
isolated Linux-hosted widget execution; no privileged or live credential action.
