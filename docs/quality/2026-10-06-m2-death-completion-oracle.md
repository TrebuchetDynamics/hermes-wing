# M2 deterministic absent-client completion oracle

Card: `t_e0af7ad4`. Task: `DOC-M2-DEATH-COMPLETE-ORACLE`.
Target: Linux-hosted Flutter widget test, Linux target-platform variant.
Status: deterministic slice passed; Android M2 remains **unverified**.

## Delivered change and authority

Added [the app-level oracle](../../test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart).
Before this slice, channel/store recovery and fake presentation restoration were
separate evidence. This test joins production startup, remembered selection,
terminal reconciliation and visible canonical history across two independent
client/provider lifetimes. No production contracts or reference sources changed.

The screen is `HermesChatScreen`. Its fresh Riverpod container uses the real
`hermesGatewayDirectoryProvider` (including eager `start()`), real
`HermesGatewayDirectory`, real `HermesApiGatewaySummaryLoader`, real
`GatewayContactCache` against mocked SharedPreferences, and real
`HermesApiChannel` / `HermesApiClient`. Only HTTP transport callbacks, endpoint
storage, serialized detached-lease fixture storage, and unavailable voice
services are replaced. The backend is deterministic and in-process; no live
Agent, provider, socket server, authentication or inference is involved. There
is no fake directory method that injects recovered UI state.

`hermes_channel_provider.dart:57–69` starts the production directory;
`hermes_gateway_directory.dart:334–367` restores remembered contact/session;
`hermes_api_channel_messaging.dart:2092–2182` resolves the exact detached tuple,
fetches canonical turns before removing the lease and persists its removal.
The fixture advertises existing HTTP capability shapes, not actual upstream
availability. No transport, backend or platform support claim is added.

## Acceptance evidence

1. One run is submitted through the visible composer/Send button in explicit
   synthetic origin/profile/session context. The independent backend is still
   `running`, the channel is streaming, and serialized storage contains the exact
   `(origin, profile, session, run)` lease before client disposal. The entire
   screen tree and first ProviderContainer are removed. Backend completion occurs
   only with the client marked absent; request counts stay unchanged during that
   interval and durable fixture ownership survives. A fresh container automatically
   restores the remembered owner and session despite a newer session in inventory.
   A parked history response after authoritative status read proves the lease
   still exists before canonical hydration. After release, exact canonical
   user/assistant IDs, authors, session IDs, order, content and completed status
   match; each synthetic text appears once in the UI, the composer is usable,
   restoration notice is gone, and the lease/duplicate guard clears.
2. Authoritative fixture counters before/after relaunch are equal:
   `runStarts=1`, `sessionCreates=0`, `otherMutations=0`; recovery mutation delta
   is zero. `otherMutations` covers chat/completions sends, Stop, approval responses
   and any other non-GET operation. All transport methods are intercepted; unknown
   requests fail rather than reaching a live service. Run/history reads require
   the exact synthetic origin and non-default profile; foreign session/history
   paths are not implemented. Default-profile inventory reads are permitted only
   because production connection bootstrap performs them, and return no sessions;
   no default-session selection/history or mutation is permitted. Recovery must
   include reads of the exact run status and canonical session messages.
   A duplicate run submission fails its one-submission assertion and recovery
   counter check; wrong/missing/duplicated history fails exact tuple and UI checks.
3. Exact executed commands, exits, logs and source fingerprints are below.
   Only this task is marked done; M2 stays unverified. No named device was tested.

## Executed verification

All commands ran in the Wing repository; final checks exited 0:

```text
flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart --concurrency=1 --reporter expanded
flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_session_restoration_test.dart test/features/hermes_chat/gateways/hermes_gateway_restoration_adversarial_test.dart --concurrency=1 --reporter expanded
flutter analyze
dart format --output=none --set-exit-if-changed test/features/hermes_chat/screens/hermes_chat_death_completion_recovery_test.dart
```

The oracle passed one test; the nearest suite passed 51 tests. Analyzer reported
no issues. Scoped whitespace checks and local-link checks are recorded separately.
Raw sanitized logs and argv/exit receipts are local artifacts under
`.task-evidence/t_e0af7ad4/`: `oracle-verified.{json,log}`,
`nearest-regressions.{json,log}`, `analyze-verified.{json,log}`,
`format.{json,log}`, `ledger-commands.json`, and `source-hashes.json`.
Fingerprints bind 200 files (all current Wing `lib/*.dart` descendants plus the
oracle, nearest tests, endpoint fake and manifests) at observed HEAD
`4acdb4e1f51262ccfdca5174776eed1e3ef65188`. The dirty worktree, not HEAD alone,
is the tested source. No commit/stage/push or shared branch/index operation ran.

Harness iteration corrected missing imports/model getter names, allowed the
production default-profile inventory bootstrap without allowing default history,
and pumped after composer input before tapping the rebuilt enabled Send button.
An analyzer flow-control brace finding was fixed. Earlier bounded failures remain
in `oracle-02` through `oracle-04` and `analyze` receipts; assertions and production
code were not weakened. Final verification follows those harness corrections.

## Ledger ceiling and remaining qualification

Live board readback before ledger edits showed this as the only running Wing
card. `goals.py evidence` ran while this task was still in progress, then
`goals.py task ... done` and `goals.py render` ran. Recording passes after marking
all M2 tasks done would automatically promote M2 to `met`, which would be false.
Readback comparison confirms only M2 evidence and this task object changed in
`goals.json`; the generated table and this task's checkbox/receipt were updated.
M2 remains `unverified`.

`goals.py validate` exits 1: `M2: unverified goal has no open task`. As with the
baseline, the helper requires open work for an unverified goal. This card forbids
a second task and explicitly requires closing only this deterministic slice.
The validation failure is reported, not suppressed; no Android acceptance or
extra backlog task is invented to satisfy the helper. Ledger JSON is parseable.

Remaining named-device check: **ANDROID-M2-DEATH-COMPLETE-01** in the
[baseline scenario](2026-10-06-m2-continuity-baseline.md#exactly-one-future-scenario-android-m2-death-complete-01).
It requires an owned disposable QA Android target and package, a separately
admitted unmodified Agent/M1 run contract, secret-safe disposable authentication,
bounded inference consent, confirmed running lease before verified PID death,
independent authoritative completed history while absent, relaunch with
notifications denied, and observer-backed identity/history/no-replay counters.
Real credential expiry/revocation, wrong-owner denial and secure-store survival
must be qualified on that target as described by the baseline.

NOT_CHECKED: Android OS process death, physical/emulated named device, real
keystore, expiry/revocation, denied notification permission, native packaged
runtime, packaging/install, live M1, provider inference, push and persisted
drafts. No builds or installs ran. No owner questions are needed for this bounded
slice. Default applied: deterministic disposal/recreation only, not platform
qualification.
