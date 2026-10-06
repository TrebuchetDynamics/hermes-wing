# M2 recreated-client credential-denial oracle

Card: `t_59ea67ba`. Goal task: `DOC-M2-CREDENTIAL-DENIAL-ORACLE`.
Status: implementation checks passed; independent native same-card review required.
M2 remains **unverified**. Target exercised: Linux-hosted Flutter widget tests,
including the oracle's Linux target-platform variant, not a native app journey.

## Delivered change

Extended [the existing app oracle](../../test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart)
with a second parameterized case. The original successful absent-client completion
case remains executable. The new case deliberately submits once, disposes the
screen/provider generation, completes the deterministic backend while absent,
and recreates the production channel, gateway directory and app providers over
the serialized lease fixture and remembered SharedPreferences tuple.

No production source, protocol, dependencies or reference checkouts changed.
The real `HermesApiChannel`, `HermesApiClient`, gateway summary loader, directory
startup and `GatewayContactCache` remain in use. HTTP callbacks, endpoint storage,
serialized lease storage and unavailable speech services are fixture seams, as
in the [predecessor oracle](2026-10-06-m2-death-completion-oracle.md).

## Acceptance evidence

1. The new case verifies the saved synthetic authorization header without exposing
   its value in assertion output. Discovery and inventory remain readable; exact
   session/run resources throw an exception implementing `HermesApiStatusException`
   with status 401. This exercises production HTTP authentication-error
   classification, not a channel state setter. It is a resource-read denial,
   not a claim that every bootstrap route rejects credentials.
2. After failed recreated-client restoration, the exact active contact and pending
   session remain original; active session is null and messages are empty. The
   serialized lease is byte-identical and the remembered contact/session survives.
   Endpoint clear/delete/save operations remain absent. No writable composer or
   canonical answer appears, and the accessible restoration surface remains.
3. A real tap on `hermes-session-restoration-retry` repeats denial: final execution
   recorded three denied owner reads initially and six after this public Retry.
   Each denied request uses the exact original origin/profile. Lease and remembered
   ownership remain unchanged; there is no session substitution or foreign history.
   Newer unrelated profile inventory and nonempty default-profile inventory are
   discriminators, not selectable replacements during this recovery.
4. Explicitly restoring synthetic server authority and tapping the same public
   Retry permits original-owner reads. A Completer parks the successful canonical
   history response after a run-status request. While parked, messages remain empty,
   the entire serialized lease is unchanged and remembered session remains original.
   Release hydrates canonical user/assistant IDs, authors, session IDs, order, text
   and completed status exactly once. Only then does lease storage empty, the
   unresolved guard clear, the restoration notice disappear and the composer enable.
5. Every fixture attempt is recorded before route/owner assertions or denial.
   All transport mutation seams are intercepted, including rejected attempts.
   Initial deliberate submission counters are `runStarts=1`, `sessionCreates=0`,
   `otherMutations=0`, not zero initial mutations. Counters remain identical after
   failed recreation, denied Retry and successful recovery: recovery delta zero.
   The final recovery request list is GET-only and allowlisted to discovery,
   inventory and the original session/run resources. No event reattachment,
   replacement session, send, Stop, approval response or mutation replay occurs.

These observations are fixture assertions. Live server accounting remains
`authoritative_counts_unavailable`; no new counting API or platform claim exists.
The relevant production invariants remain the
[transport qualification boundary](../adr/client.md#transport-qualification) and
[remembered recovery contract](../runbooks/chat-session-restoration.md).

## Executed verification and retained receipts

Test/analyzer cwd: `.task-evidence/t_59ea67ba/mirror`, a task-owned copy of current
Wing source using existing offline package dependencies. No root build asset or
retained root flutter_tester was used, written or killed. No download/install ran.
Exact absolute cwd, argv, exit and captured output are in paired JSON/log receipts
under `.task-evidence/t_59ea67ba/`.

Final successful commands (all exit 0):

```text
flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart --concurrency=1 --reporter expanded
flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart --concurrency=1 --reporter expanded
flutter test --no-pub test/core/hermes/channel/hermes_api_channel_test.dart --plain-name 'process recreation' --concurrency=1 --reporter expanded
flutter test --no-pub test/core/hermes/channel/hermes_api_channel_test.dart --plain-name 'terminal hydration failure preserves durable retry across recreation' --concurrency=1 --reporter expanded
flutter test --no-pub test/core/hermes/channel/hermes_api_channel_test.dart --plain-name 'active run lease is durable before its event stream finishes' --concurrency=1 --reporter expanded
flutter analyze --no-pub
```

The oracle passed two cases; nearest auth/restoration tests passed 60; selected
channel cases passed two, one and one respectively. Analyzer found no issues.
Changed-file formatter passed with zero changes after formatting. Scope validation
checks local documentation links, task-owned whitespace, scoped `git diff --check`,
and transitive local import/part/export closure equality against the tested mirror.
The sole added import is the existing HTTP status interface; widget test delivery
uses existing pubspec dependencies. No packaging correction or runtime build is
required or claimed for this test-only import.

Receipts: `oracle-final`, `nearest`, `channel-process`, `channel-hydration`,
`channel-lease`, `analyze`, `format-verified`, and `scope` JSON/log pairs.
`baseline-relative.patch` records changes against the inherited untracked oracle;
`baseline.json`, `current-source.json`, `import-closure.json` and
`preservation.json` bind inherited/current source and mirror equality, including
current dirty production bytes rather than treating HEAD as the tested source.
Predecessor receipts remain historical and untouched, not refreshed evidence.

Iteration records are retained: `format-final` exited 1 because the added assertion
needed formatting; `format-apply` corrected formatting. `channel-recreation`
exited 79 because repeated plain-name options intersect rather than union. Separate
supported plain-name invocations above executed the intended four cases. No
assertion was weakened and no production defect or repair was needed.
`scope-01` rejected a generated localization doc-comment import example; anchored
directive matching fixed the task-local closure checker, and final `scope` passed
with 142 local Dart files equal to the tested mirror. `ledger` successfully ran
all nine helper commands, then its overly strict readback assertion rejected the
helper's normal task section change and ordering. `ledger-verified` subsequently
checked the saved before/after and live ledger by task ID: only this task's
`done`/`Done` normalization and eight scoped M2 evidence entries changed. No helper
command or test was replayed to fix that assertion.

## Ledger, review and remaining qualification

Scoped goal updates use `goals.py`, append executed evidence before closing this
exact task (avoiding automatic promotion of M2), and leave M2 unverified. TODO
rendering is reserved to repo-docs; this worker does not render or edit TODO/core
product documents. The board comment coordinates this reservation. Goal ledger
readback and native review handoff are retained in task-local receipts.
Baseline-relative preservation found an external `TODO.md` change during this
run; this worker never wrote or rendered that file. Other inherited file hashes
match except the explicitly scoped oracle and helper-updated `goals.json`.
The latter is excluded from the agent commit to avoid capturing inherited ledger
bytes. The new report is the only non-evidence added file.

The permitted report-only local agent branch captures only the oracle and this
report; shared HEAD/index/branch remain unchanged. No push, merge or release is
performed. Native same-card review is the independent acceptance lane; local
implementation checks do not constitute that approval.

Remaining: independent same-card review and separately admitted Android/live
qualification as defined in the
[preflight map](2026-10-06-m2-android-preflight.md#scenario-prerequisite-and-oracle-map).

NOT_CHECKED: real credential expiry/revocation, complete bootstrap credential
rejection, 403 in this combined oracle, real secure storage/keystore survival,
Android OS process death, devices, notification permission, native/live runtime,
Agent inference and authoritative server counts, full suites, web/native builds,
packaging/install, release/deploy/publish. Fixture disposal is not process death.
No owner question is necessary. Default applied: deterministic 401 exact-resource
read denial and explicit authority restoration, not live credential administration.
