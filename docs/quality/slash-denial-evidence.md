# Unavailable slash action and supported recovery

## Result and scope

`DOC-SLASH-DENIAL-EVIDENCE`, native card `t_80f707ab`, goal `SLASH-CATALOG`.
Concrete action: read the selected Agent profile's SOUL with Wing's local
`/persona` command when the selected connection does not advertise or authorize
that read. Wing hides the local action; it does **not** show a composer denial.
Sending the literal instead follows ordinary chat. Existing fake-channel tests
prove zero specialized SOUL reads, not zero message sends or live network I/O.
This satisfies the accepted missing-check alternative, not full slash parity.

Only this evidence document changes. Connected scope inspected: composer producer
and message flow, channel interface/API implementation/client, readiness and
Diagnostics, standalone Persona and embedded profile editor, localization and
nearest fake-channel tests. No caller, fixture, export, config, lock, route,
command implementation or ledger changes are needed for this documentation slice.
No user data is deleted or migrated; no secrets, installs, service changes,
upstream edits, shell dispatch or live inference are involved. Coordinator `wing`
owns review-gated integration and canonical ledger closure; the goal remains
partial under the [parity statuses](../product/hermes-desktop-parity.md#statuses).

## Source identity

Wing immutable admitted base: `6a27a22c3f567b0aedb11041fb3b117ec54c818c`.
The original pinned startup guard returned `worker_start_admitted` before design,
tests or the first write. Original argv and ordering are in the native run;
manifest SHA-256 `176e2ffb4b4bd606802d6c243165a65c7847c87e1d87acfd18fd1a103da84bbd`.
Frozen helper bundle SHA-256
`b563ca96b27bdadb4a8ddb81881b94fad82ac87478b6e057f2f04d9dbad9860c`.
The finish receipt binds the exact owned commit/ref; this document does not
pretend to know that future commit's hash.

Official read-only Agent/Desktop checkout:
`158fd638da1629c8e62caf9ade1515d162def8ab`, clean at inspection. Root, gateway,
Desktop and Desktop/src instructions were read before the respective source
inspection. This is checkout evidence, not the selected installed Agent's state.
Linux-hosted Flutter `3.44.2`, framework `c9a6c48423`, Dart `3.12.2` was exercised.
No browser or native application was launched.

Fingerprints relative to Wing root, SHA-256:

| Source | SHA-256 |
| --- | --- |
| `lib/features/hermes_chat/screens/state/hermes_chat_layout.dart` | `44e0fabf948b07035ccd84999dcd28dbcc7b3adbe7e6eeb7923aa30538d8439f` |
| `lib/features/hermes_chat/composer/hermes_chat_message_flow.dart` | `838124adfbd9b856e5b256c1b981c5966ea9fe4fab858a9a40d5307f35a94342` |
| `lib/core/hermes/channel/hermes_channel_state.dart` | `2a21f95befa4de3c37fa2a3479480683a1f6c405a9b3f668fbec96bfa5b974dc` |
| `lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart` | `3ed77d6a01351a4fa8acdbb35f27f1dedd17b52a1014d6ca4fc40fec67b69082` |
| `lib/features/soul/screens/soul_screen.dart` | `1455386a1d648a7601cb8a01de8b5ed4ba55eae719bb1289aaa11eb868854406` |
| `test/features/hermes_chat/screens/hermes_chat_slash_commands_test.dart` | `8d309e5a18cdf5c98ffd098aafadf637fd7b24f20c50e527cb7fdf1b9c1f1f48` |
| `test/core/hermes/hermes_surface_readiness_authorization_test.dart` | `e4bd51c1ba60875e138b35ad2027352689b603b718ba0756268c79e0ce8d324e` |
| `test/features/soul/soul_screen_test.dart` | `625da3b07d276b25719613effc35b791244951882814c375176cea8a552d5252` |
| `pubspec.lock` | `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89` |
| `package-lock.json` | `f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63` |

## Denial, fallback and exact authorization

1. [Composer producer](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart):2230–2345
   includes `/persona` only if `canReadProfileSoul` and a selected profile ID exist.
   Matching is trimmed, case-insensitive, exact bare text; there is no argument
   parser. `/help` lists only available local commands. Missing capability or
   grant hides the Persona suggestion, rather than disabling it with an explanation.
2. The same file:2165–2176 checks profile ID and read permission again before
   `readProfileSoul(profileId)`; after the await it checks mounted state and selected
   profile ID. This is not proof of a same-ID changed-endpoint generation fence.
3. [Channel state](../../lib/core/hermes/channel/hermes_channel_state.dart):204–209,
   244–264 requires supported schema, operation `profile_soul`, exact
   `GET /api/profiles/{name}/soul`, advertised and granted `profiles:read`, and
   every additional endpoint-required scope. A profile-scoped endpoint also
   requires supported query profile context. Read permission does not grant write.
4. `lib/core/hermes/channel/hermes_api_channel.dart`:344–345 delegates to
   `api_channel/hermes_api_channel_profiles.dart`:265–275. The real API caller
   requires a connected client, exact scoped endpoint/grants, then profile context
   before I/O. `api_channel/hermes_api_channel_capabilities.dart`:4–23 throws on
   unsupported contract or missing authorization. Client
   `lib/core/hermes/client/hermes_api_client.dart`:596–601 constructs the SOUL URI
   and explicit profile-scoped URI for the passed profile ID. Owner is the Agent
   profile on the selected connection, not a Wing file or global profile switch.
   The caller's profile-context requirement is stricter than the read-menu gate
   for an unscoped advertised endpoint; menu visibility alone is not I/O success.
5. [Message flow](../../lib/features/hermes_chat/composer/hermes_chat_message_flow.dart):25–87
   attempts local commands only without staged attachments. A hidden/unrecognized
   slash literal returns false and follows normal send/steer/queue handling.
   `/persona` is therefore not a safe way to test denial without sending a prompt.
   Active-turn and unsettled-restoration guards still apply; they do not turn
   fallback text into authorized slash execution.

The inspected official Agent HTTP `_CAPABILITY_ENDPOINTS` producer in
`gateway/platforms/api_server.py`:67–102 advertises neither SOUL nor authoritative
command catalog/completion/dispatch endpoints. Thus this source does not promise
that `/persona` can become available on that server. An advertised exact contract
on a selected unmodified Agent is required, never a broad version/admin flag.
The [predecessor map](slash-catalog-contract.md#authoritative-producers-and-the-missing-transport-contract)
traces the separate JSON-RPC producers; those are not Wing HTTP routes. Official
Desktop `src/lib/desktop-slash-commands.ts`:189–258 has local actions/pickers, and
`src/lib/desktop-slash-registry.json`:65 contains `/personality`, not `/persona`.
Wing's local SOUL read is not evidence of Desktop `/personality` execution parity.
No upstream test or runtime dispatch was executed here.

## Visible disclosure and recovery actually offered

The composer offers no unsupported-command warning, recovery button or guarantee
of zero chat dispatch for this action. This is an explicit missing check/UX
boundary, not an invented denial behavior.

Existing disclosure outside the composer:

- `lib/core/hermes/policy/hermes_surface_readiness.dart`:230–241 reports
  `Persona/SOUL` as Deferred when the read is denied, with
  “Persona/SOUL remains hidden until the gateway advertises the exact scoped
  profile soul contract.” Chat status exposes this readiness model and Diagnostics
  exports it. Reporting is exercised by the authorization suite below, not by a
  native navigation journey. Read-only is distinct from edit availability.
- [Standalone Persona](../../lib/features/soul/screens/soul_screen.dart):56–87
  shows “Persona editing unavailable” and “This gateway did not advertise scoped
  SOUL read and write operations for the selected profile.” It does not load the
  editor while `canEditProfileSoul` is false. That unavailable branch has no Retry
  or bypass button. It is an edit gate, not the slash read gate: both exact GET/read
  and PUT/write contracts, query profile context, connected/not-selecting state
  and all grants are needed for editing. Copy is in `lib/l10n/app_en.arb`:1036–1037;
  it does not enumerate every possible grant/context denial.

Safe supported recovery: do not Send the unavailable literal. Use existing
`/clear` to clear the composer only, or edit/delete the draft normally. To inspect
profile selection use existing `/profiles`, which opens Profiles without sending
that literal. This navigation does not grant SOUL access; the embedded editor is
also gated by `canEditProfileSoul`. If disconnected, standalone Persona offers
“Open chat”; if no selected profile exists it offers “Open profiles”. After a
selected unmodified Agent actually supplies the exact authorized contracts,
select the intended profile explicitly and invoke the now-visible read action
with fresh intent. There is no supported local way to manufacture that contract,
no automatic replay and no promise that reconnection fixes missing capabilities.
Preserve [Agent authority and no replay](../adr/api-and-state.md#decision).

## Executed evidence and missing proof

Initial checks in the admitted workspace, all PASS with no failure retry:

- `flutter pub get --offline --enforce-lockfile` — cached resolution; locks unchanged.
- `timeout 5m flutter test --no-pub test/features/hermes_chat/screens/hermes_chat_slash_commands_test.dart --reporter expanded`
  — 48 tests; test runner reported 8 seconds. At :1020–1064 the missing read grant
  hides Persona and leaves `readProfileSoulCalls` empty before submission. At
  :1066–1092 absent advertisement plus Send leaves that list empty **and** adds
  `/persona` to active messages. At :960–1018 authorized read calls the selected
  `coder` profile and does not add the literal to messages. Existing `/clear` and
  Profiles tests exercise local no-send recovery; the historical “agents” test
  title refers to the actual `/profiles` token.
- `timeout 180s flutter test --no-pub test/core/hermes/hermes_surface_readiness_authorization_test.dart --reporter expanded`
  — 34 tests; read/write readiness matches schema, method, path, context, primary
  and additional grant denial. These are state/reporting oracles, not network I/O.
- `timeout 180s flutter test --no-pub test/features/soul/soul_screen_test.dart --reporter expanded`
  — 9 tests; :143–159 proves visible unavailable title and zero fake SOUL reads
  when contract is absent. The suite also covers disconnected/missing-profile
  recovery, query-context and additional-scope denials.
- `git diff --exit-code -- pubspec.lock package-lock.json` — PASS.

The finish gate reruns the three test commands, lock comparison, standard-library
local Markdown target/anchor, source-fingerprint and whitespace checks, and
`git diff --check`. Exact argv/results and elapsed durations are retained in its
receipt. Source fingerprints are pinned above; predecessor executed results are
context only, not substituted for this run. Total time, review time and cost are
not measured.

Zero specialized reads is proven only at the existing fake channel seam. The
missing checks are (a) composer disclosure/recovery for unavailable slash input,
(b) real transport-spy proof of no SOUL/catalog/dispatch request after denied
submission, including grant-denied Send and stale-owner cases, and (c) native/live
Agent end-to-end qualification. Zero total dispatch is expressly false in the
unadvertised Send fixture. Full analysis/suite, browser/native application,
Android, live authentication/provider/inference, upstream tests and service or
packaged delivery are **NOT_CHECKED**. No passing fixture closes those gaps.

## Acceptance and handoff

- Concrete unavailable action, exact method/path/grants/owner: denial/fallback map
  above and pinned consumers; no speculative Agent operation.
- Unsupported disclosure and zero-dispatch proof or missing check: composer lacks
  disclosure; readiness/standalone disclose their own gates; fake zero SOUL reads
  and ordinary message submission are separately proved, missing transport checks
  are named explicitly.
- Supported recovery: clear/edit draft, local Profiles navigation, existing
  disconnected/missing-profile buttons; no authority escalation or silent resend.
- Checks and source/commit: immutable admission, fingerprints, fresh focused tests
  and finish receipt. One independent native same-card review remains required.
  This is implemented documentation and bounded offline test evidence, not
  integrated, published or native/live-qualified delivery. Canonical TODO/goals
  closure belongs to the coordinator after review.

Next coherent slice recommendation: source-bind the remaining unavailable
argument-command recovery to a currently supported surface (for example Desktop
`/resume` versus Wing's local `/sessions`), including the same disclosure-versus-
chat-fallback distinction. It is a proposal, not a new card or accepted order
change. Full dynamic slash parity still requires an advertised authorized
unmodified Agent transport contract; SLASH-CATALOG remains partial.

Decision (Ponytail full): reuse existing producers and three nearest suites;
deliver one evidence document, not new denial code, commands, tests, routes,
dependencies or a shell fallback. This is the smallest complete admitted outcome;
required authorization and review checks are retained.
