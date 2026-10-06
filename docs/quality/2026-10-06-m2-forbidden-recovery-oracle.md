# M2 recreated-client HTTP 403 recovery oracle

## Delivered change and boundary

Card `t_b00feca2`, goal task `DOC-M2-FORBIDDEN-RECOVERY-ORACLE`.
The inherited app oracle covered completion and HTTP 401. It now independently
executes completion, HTTP 401 and HTTP 403 through the existing production
`HermesApiChannel`, directory, providers, public Retry and serialized lease store.
Only the test fixture and assertions changed; production remains unchanged.
The status exception implements the existing `HermesApiStatusException` interface,
not a channel state setter. This is deterministic transport-seam HTTP-status
coverage, not a real network response or live authorization revocation test.

The backend records every request attempt before route/authority assertions.
Discovery/inventory remain readable; original session/run resource reads reject
with the selected status. Explicit synthetic authority restoration turns off
resource denial; public Retry performs the same production recovery path.
No new protocol, dependency, API, shadow domain state or fallback owner exists.

Source inspection confirms HTTP 401/403 share the existing authentication
classification in `hermes_gateway_directory.dart:26-41` and
`hermes_api_channel_connection.dart:3-23`. Directory activation retains the
remembered owner through failure at `hermes_gateway_directory.dart:1031-1114`.
The nearest adversarial regression separately classifies exact-owner metadata and
history HTTP 403. No demonstrated production defect required a repair.
The [server-wins/no-replay ADR](../adr/api-and-state.md) and
[remembered-session runbook](../runbooks/chat-session-restoration.md) remain binding.

## Acceptance evidence

1. The specifically named `HTTP 403 denied recreated client retries exact owner
   without replay` case passed alongside HTTP 401 and positive completion in
   `oracle.json`/`oracle.log`. Both denial controls observe three initial denied
   resource reads and six after public Retry. Assertions retain byte-identical
   serialized lease and exact origin/profile/session/run, remembered contact and
   session, empty transcript, no composer and no Send. Endpoint storage receives
   no clear/delete/save writes. No foreign/substitute history is admitted.
2. The same oracle gates canonical history after authoritative terminal status.
   While gated, transcript stays empty and the original lease remains intact;
   after release, original canonical user/assistant IDs, authors, order, text and
   completed statuses hydrate, then ownership settles. All recovery attempts are
   allowlisted GETs. One initial intentional run submission is expected; lifetime
   counters are runStarts=1, sessionCreates=0, otherMutations=0, and recovery
   mutation delta is zero during recreation, denied Retry and authorized Retry.
3. `nearest.json`/`nearest.log`: 60 nearest auth/restoration tests pass.
   `analyze.json`/`analyze.log`: analyzer reports no issues.
   `format-apply` and `format-verified`: zero formatting changes, exit 0.
   `scope.json`/`scope.log` and `import-closure.json` bind all four tested
   entrypoint closures and analyzed Dart files to current source and mirror,
   check mirror package resolution, existing manifests, local documentation links,
   task-owned whitespace and scoped `git diff --check`.
   `baseline.json`, `current-source.json`, `preservation.json` and
   `baseline-relative.patch` bind initial/final working-tree bytes, not HEAD alone.
4. Executed coverage is Linux-hosted Flutter widget testing only, with the
   Linux target-platform variant. Client/provider disposal is not Android OS death.
   M2 remains unverified and `authoritative_counts_unavailable`.
5. `ledger-commands.json` retains helper argv/cwd/exits. Scoped executed evidence
   is appended before closing the exact task to avoid the helper's automatic
   whole-goal promotion when this final synthetic task closes. Only generated
   coverage is rendered; maintained TODO prose is preserved. `agent-commit.json`
   records the isolated local agent branch/SHA, exact changed files and unchanged
   shared HEAD/branch/index. Shared inherited goal/TODO bytes are not committed.
   Same-card native review is the final implementation handoff, not approval.

## Executed commands and receipt location

All receipts are under `.task-evidence/t_b00feca2/` in the repository.
Test/analyzer cwd is its isolated `mirror/`; formatter and scope cwd is repository
root. Paired JSON/log receipts retain exact absolute cwd, argv, exit and timestamps.

```text
flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart --concurrency=1 --reporter expanded
flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart --concurrency=1 --reporter expanded
flutter analyze --no-pub
dart format test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart
dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart
python .task-evidence/t_b00feca2/verify_scope.py
```

The inherited harness was copied into this task's receipts, not edited in place.
It now refuses receipt-label reuse, verifies all executed entrypoint closures
rather than only the oracle, checks all analyzed local Dart bytes and asserts
`package:wing` resolves to the mirror. Existing offline package dependencies were
reused. No root build resources or retained root flutter_tester PID were modified
or killed. Predecessor artifacts remain historical and untouched.

Attempt accounting: each test target and analyzer ran once and passed; both
formatter commands passed without edits. An initial evidence-script preparation
call failed on a deduplicated `read_file` response before creating files; reading
the already-inspected source for the task-local copy resolved it. No product
assertion was weakened, no test failure was hidden, and no unrelated suite ran.

## Remaining qualification and questions

NOT_CHECKED: live HTTP server, real credential expiry/revocation, bootstrap-wide
denial, secure storage/keystore durability, Android OS process death, devices,
notification permission, native/live/inference, authoritative counts, full suites,
browser/native builds, packaging/install, signed distribution, deploy/release.
The [predecessor credential receipt](2026-10-06-m2-credential-denial-oracle.md)
and [Android preflight](2026-10-06-m2-android-preflight.md) remain context,
not refreshed evidence. No owner question is necessary. Default applied:
deterministic original-resource HTTP 403 refusal and explicit authority recovery;
no live credential administration or privileged action.
