# Office contact activation: official reference and accessible Wing path

## Scope and verdict

Task `t_4ef77eb0`; backlog `DOC-OFFICE-REFERENCE`; goal `OFFICE`.
Documentation only: this receipt changes no interaction, capability, fixture,
localization, dependency or route. OFFICE remains **partial**; native/live parity
is unqualified. Coordinator Wing owns ledger closure, integration and publication.

The official source inspected is Hermes Agent
`158fd638da1629c8e62caf9ade1515d162def8ab`, including `apps/desktop/`.
Wing source/test base is `92c84eb4c7d6ba7afad7d755a1e17d4d3a3a9d65`.
Root Agent, Desktop and Desktop renderer `AGENTS.md` were read before tracing
Desktop implementation. The upstream checkout was clean and remained read-only.

**Bounded absence finding:** this official Desktop checkout has no Office-named
surface/contact activation to compare directly. Filename search for `*office*`
under `apps/desktop` returned no files. Content search `office|Office` under
`apps/desktop/src` found incidental connection-test identities, an artifact-test
identity, a session-title test and a pet prompt; the only TSX match was
`src/app/pet-generate/components/empty-hint.tsx:9` (`office cat`). None defines an
Office interaction. This is evidence about this pinned checkout, not all upstream
versions. Do not substitute the retired separate Desktop app as authority.

A real, nearby official action is **Bots roster row → canonical Bot Chat**. It is
identified below to contrast ownership/session intent, not relabeled Office or
claimed as a fully traced/qualified Office equivalent. Wing's 2D contact → Chat
path already exists. Its endpoint/profile activation and failure banner have
regressions; keyboard traversal and actual-Chat focus after this entry do not have
an Office-specific executed oracle in the selected tests.

Policy: [official reference](official-desktop-reference.md),
[product boundary](../adr/product.md#decision),
[API authority](../adr/api-and-state.md#decision),
[route support](../product/routes.md#routes) and
[parity status](../product/hermes-desktop-parity.md#statuses).

## Official action and deliberate limits

Paths below are relative to the pinned Agent checkout, not a second product repo.
Permanent source: [official Desktop at the inspected revision](https://github.com/NousResearch/hermes-agent/tree/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop).

- `apps/desktop/src/plugins/hermes-bots/bot-row.tsx:228-263`: the roster's
  `RowButton` invokes `openRosterBot(bot)` on click, with an owner-qualified roster
  key and accessible busy/label attributes. `src/components/ui/row-button.tsx:9-10`
  renders a native `button`, not a canvas hit target; standard keyboard activation
  is available by construction, not newly runtime-tested here.
- `src/plugins/hermes-bots/roster-actions.ts:188-210,226-361`: fronts only a verified
  canonical registry/lineage-tip tab; an unrelated remembered side tab cannot win.
  Otherwise it prepares the exact row's source and opens its canonical chat, with
  an open-generation predicate. Stale opens cannot record a new claim. Failure
  clears the open claim, settles pending state, reports failure and can restore
  the prior group. Fronting means workspace/session selection, not proof of DOM
  composer focus. Already-open chat refresh is background/in-place.
- `src/plugins/hermes-bots/canonical-chat.ts:271-340`: owner-qualified
  `requestForBot('session.list', {profile, title: 'Bot Chat', include_hidden: true,
  limit: PROFILE_SESSION_LIST_LIMIT})` resolves the registry. Lookup errors, and
  empty results contradicting positive canonical-session evidence, fail closed
  rather than minting another chat. This is RPC, not Wing REST authorization.
- `src/AGENTS.md:65-99` describes the absent-row creation/adoption contract.
  `src/plugins/hermes-bots/bot-row-opens-canonical-chat.test.ts:47-122` is the
  inspected nearest oracle: canonical tab versus side tab, refresh in place and
  failure leaving no open claim. These upstream tests were **NOT_RUN**; no upstream
  installation, execution, spawn or backend/provider action was authorized.

Difference, not a defect inferred from naming: Wing Office opens a gateway/profile
contact's recent usable session (or a gated new session), not a named forever-chat.
Bots and Office do not have identical session intent. There is no verified
advertised Wing-facing REST canonical Bot Chat lookup/create-adopt contract in
this receipt. RPC names and UI availability cannot be used as REST grants. A
canonical-chat port would require separately verifying that exact Agent contract;
no host bridge, stored canonical pointer or upstream modification is proposed.

## Wing entry, ownership, request and result

All paths in this section are Wing files at the pinned base.

1. `lib/router/providers/app_router.dart:69-97` composes Office and Chat in
   `AppShell`. Office remains reachable without a live Agent; Chat's normal route
   goes through `ConnectionEntryGate`. `OfficeScreen` renders a searchable,
   refreshable ListView/Wrap of authoritative directory contacts, with 1/2/3
   columns according to width (`office_screen.dart:92-205`). No 3D, account,
   wallet, sound, speech, canvas or color-only action is required.
2. `lib/features/hermes_chat/gateways/gateway_contact.dart:6-19,63-84` identifies a
   contact by **gatewayId + profileId**, not display name. Endpoint config is
   resolved by that gateway ID; session identity is meaningful inside that owner.
   Office exposes an `IconButton` with tooltip Open Chat/Return to Chat, and
   enclosing name/gateway/status/session-count semantics
   (`office_screen.dart:280-287,359-371`). Tap and standard Flutter button keyboard
   activation reach the same callback. Management-only contacts disable it;
   offline status alone does not disable explicit reconnect.
3. `HermesApiGatewaySummaryLoader.load`,
   `hermes_gateway_directory.dart:71-115`, reads health/capabilities before profile
   inventory. Profile enumeration requires supported schema/query context,
   exact `GET /api/profiles`, `profiles:read` and every declared required scope.
   Session reads carry the enumerated profile. If enumeration is unavailable it
   yields the endpoint/default projection rather than fabricating a profile list.
   `:430-448` derives chat availability and fallback/path-bound contact behavior.
   Cached status is not new authorization.
4. `OfficeScreen._openContact`, `office_screen.dart:207-233`, serializes openings
   through `_openingId`, clears prior failure, and activates when the contact is
   different **or the channel is disconnected**. After awaiting it requires the
   same active contact ID and connected channel before `context.go(AppRoutes.hermes)`.
   It checks mounted context, but does not independently assert selectedProfileId,
   activeSessionId, history acknowledgement or composer focus. Already active and
   connected means return to the existing Chat, with no new directory activation.
5. `HermesGatewayDirectory.activate`, `hermes_gateway_directory.dart:757-885`,
   requires a saved/chat-available contact, increments activation and persistence
   generations, waits for prior disconnect, then connects the exact saved endpoint
   with its stored Agent credential. Failed normal connection clears its own
   activation. Nonfallback profiles use `selectProfile(profileId,
   allowDiscovered: true)`; endpoint-bound fallback contacts skip selection.
   Generations reject superseded activation results; no global `profile use` occurs.
6. The production channel profile path is
   `lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart:9-120`:
   mandatory query context unless the endpoint is already path-bound, owner/client/
   connection/profile-selection fences, scoped session/optional-inventory reads.
   `allowDiscovered` reuses directory discovery rather than another profile-list
   request. Initial selection may be a recovered detached session or first loaded
   session. Directory then tries its latest preview ID only if present in the
   freshly loaded list (`hermes_gateway_directory.dart:843-871`); latest means
   greatest parsed `lastActive`, with first row retained when timestamps do not
   distinguish (`:501-514`). A stale/missing preview is not exact restoration.
7. Normal Office activation does **not** pass `preferredSessionId`. Telegram
   targets are isolated into a new Wing session when creation is allowed, otherwise
   active selection is cleared; a profile with no preview may create a session.
   Selection of a stale/slow preview can throw and be swallowed to keep a healthy
   gateway usable. Thus connected/contact success does not guarantee that preview
   history opened. Explicit preferred-session restoration is a separate branch
   (`:824-841`) and must not be confused with this action.
8. Session selection in `hermes_api_channel_sessions.dart:57-131` requires stable
   profile and known session and fences connection/profile/session generations.
   `_fetchTurns`, `hermes_api_channel_connection.dart:334-360`, checks history-read
   authority and passes the profile to the session-message request before accepting
   results. Session creation (`hermes_api_channel_sessions.dart:291-351,573-592`)
   requires advertised `session_create`, `POST /api/sessions`, supported schema and
   all endpoint-required scopes when a capability document exists; request profile
   and context guards remain explicit. State UI gate also checks profile-scoped
   context (`hermes_channel_state.dart:133-144,244-255`). **Existing null-document
   compatibility is permissive** in `canCreateSessions` and the operation guard;
   do not describe it as strict advertised-capability proof for every transport.
   No authorization policy was changed or newly qualified by these fake tests.

## Success, failure, recovery and focus oracles

| Observable outcome | Existing check or inspected contract | Evidence boundary |
| --- | --- | --- |
| Tap selects the exact endpoint/profile and reaches Chat route | `office_screen_test.dart:273-331` checks connection, profile calls, active contact and Chat destination | Executed; destination is a Text stub, not HermesChatScreen |
| Disconnected active contact reconnects | `office_screen_test.dart:333-390` checks two connects, owner and destination | Executed with fake channel |
| Open error is bounded and sanitized; Office remains usable | `office_screen_test.dart:224-271` checks generic banner, no private error, contact still present and live-region semantics | Executed; retry-to-success/focus retention is not asserted |
| Office route is inside shell | `office_route_test.dart:14-49` | Executed; not activation/focus parity |
| Empty profile creation, Telegram isolation, reuse and exact remembered-session failure | `hermes_gateway_directory_test.dart:795-949` | Executed; directory-level fake channel |
| Prior channel is disconnected before replacement; fallback skips selection | `hermes_gateway_directory_test.dart:1183-1263` | Executed; not live transport |
| Error recovery | Banner Done dismisses failure; Refresh explicitly reloads; activation can be attempted again (`office_screen.dart:48-81,207-233`) | Source-inspected; no automatic retry/replay, no claimed focus restoration |
| Keyboard/semantics activation reaches actual Chat and focus | IconButton and tooltip semantics; native-only initial composer focus below | Office-specific integrated keyboard/focus oracle **NOT_CHECKED** |

Chat initial focus is scheduled by `_buildComposer`
(`hermes_chat_layout.dart:1697-1704`) only when `canSendTurns` is true and the initial
focus has not already been scheduled (`hermes_chat_lifecycle.dart:106-133`).
Post-frame focus requires mounted state, a focusable composer and current route.
`hermes_chat_screen.dart:276-280` restricts that automatic keyboard focus to
non-web Linux/Windows/macOS. Android and browser automatic composer focus must not
be inferred. Office has no focus node or explicit focus-restoration call. Neither
selected widget test proves Tab/Shift+Tab, Enter/Space, actual composer focus,
screen-reader operation or return-from-Chat focus retention.

## One bounded successor proposal

**Accessible Office-to-actual-Chat activation regression**, not a new Office engine
or canonical Bots feature. Preserve existing production behavior unless a failing
behavioral oracle demonstrates an in-scope defect. Reuse the actual router,
HermesGatewayDirectory and deterministic channel/store/loader overrides already
used by the Office and directory tests.

Scope reach: Office callback/card, directory activation, production profile/session
channel, actual router/ConnectionEntryGate and Chat composer lifecycle above;
`test/router/office_route_test.dart`, `test/features/office/office_screen_test.dart`,
`test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart` and existing
`test/features/hermes_chat/support/fake_hermes_channel.dart` /
`fake_hermes_gateway_directory.dart`. No config, exports, lockfiles, localization,
new fixtures/dependencies/routes/backend or Agent changes are currently indicated.

One journey should Tab to the labeled contact action, activate by Enter/Space,
assert exact owner/session and actual Chat, and check native-desktop composer focus
only when send/route gates allow it. A failing connect must keep Office and a
semantic recoverable error, clear progress, allow keyboard Refresh/retry, and then
reach that same owner without duplicate creation/send. Exercise switching owners
while an activation is pending to prove stale completions cannot navigate or focus
a replacement route. This is a **missing integrated test oracle**, not evidence
that keyboard activation is broken. No card is created and no code is implemented
here; the coordinator may accept this coherent slice. Full Office/Bots parity,
3D/account operations and live/device qualification remain separate.

## Executed checks and source identity

Pre-edit admission (before any file creation or tests) executed exactly:

```text
python3 /home/xel/git/gormes/hermes-toolset/skills/autowork/scripts/pass_workspace.py --manifest /home/xel/.hermes/profiles/wing/autowork/pass-75097766ab129a55-f3526e1818ef4c68ace4e8b45e46a1ec.json --manifest-sha256 655437847f372d5e5327f7c96d2dea8e0f9172ee06246f56d7593bae84d234bb --workspace /home/xel/.hermes/profiles/wing/cache/scratch/autowork-passes/75097766ab129a55-f3526e1818ef4c68ace4e8b45e46a1ec
```

Exit 0, `worker_start_admitted`. Original `office-source.json` SHA-256:
`ee522ca713e3d9b919857903e347ba0e8c620248e95f35da5841457fc7c87874`.
Manifest full base resolved before edits. Frozen planning inputs were context only,
not copied into source or mutated. Admission history is the original tool run;
this prose is not a substitute for it.

Actual tools: Flutter 3.44.2, framework `c9a6c48423`, engine revision
`77e2e94772`; Dart 3.12.2; DevTools 2.57.0; Node v26.7.0 (not the documented Node
22; no Node build/test used); Python 3.12.14. `git status --short --branch` was
clean detached HEAD at admission. No services or live connections were probed.

```text
timeout 5m flutter pub get --offline --enforce-lockfile
timeout 5m flutter test --no-pub test/features/office/office_screen_test.dart test/router/office_route_test.dart test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart --reporter expanded
git diff --exit-code -- pubspec.lock package-lock.json
```

All exit 0. Cached dependency resolution succeeded; both lockfiles unchanged.
The deduplicated test command passed 60 tests; runner elapsed display `00:01`.
No test retries or product edits. Directory target was selected because Office
calls its activation/owner/session policy; unrelated suites were not used as proof.

Receipt verification uses the ignored, task-local
`.dart_tool/office_receipt_check.py`: local links/anchors, pinned source fingerprints,
base/source snapshot, clean upstream identity and unchanged lockfiles. Finish gate
runs that check, the same test command, and `git diff --check`; its exact argv,
results and commit/ref belong to the native handoff rather than a self-referential
commit ID in this file. Final handoff requires `status: committed`, not a planned
commit. Whitespace of the committed diff is checked after the gate.

Ponytail full decision: reuse the existing Office/directory/UI primitives and
regressions; write only this comparison. Omitted speculative 3D, accounts, new
protocols, abstraction and behavior fixes. Evidence: pinned source trace and
executed focused tests above. No optional engineering protocol was applied.

Implemented: source-bound comparison only. Qualified: Linux-hosted Flutter fake-
channel widget/unit behavior only, not Linux GTK, Android, browser, screen reader,
live Agent/provider, packaged execution or installation. Delivered: local task
commit at handoff; canonical integration/publication and independent approval
remain pending. Next queued quick win proposal is `DOC-PERSONA-EVIDENCE`, subject
to coordinator selection/ownership; this worker does not select or enqueue it.

## Fingerprints

SHA-256 over exact inspected bytes. `hermes-agent/` rows resolve against the
read-only official checkout, not an implementation dependency. Other rows resolve
against the Wing candidate. These hashes bind evidence, not platform support.

| Source | SHA-256 |
| --- | --- |
| `lib/features/office/screens/office_screen.dart` | `58f55345e567f7e7ce954f4b4d825549a72fa617484f4fd6677cd8c83e20a0eb` |
| `lib/features/hermes_chat/gateways/gateway_contact.dart` | `6d7a5db2d6efcaf36bb8bb51482172a9f66885640325a2e444681921306d0ead` |
| `lib/features/hermes_chat/gateways/hermes_gateway_directory.dart` | `8610d9af159098c4887732a58541ce0d4cc8f10d7275f925fec995344d3f113d` |
| `lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart` | `3ed77d6a01351a4fa8acdbb35f27f1dedd17b52a1014d6ca4fc40fec67b69082` |
| `lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart` | `148816aead97af644977509989ab4f30e580ec2a628566de2e18ffcc55f0081f` |
| `lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart` | `95d53e5335af3145f0856a683ff0b3f75bbdca14c77df749e0cfa0caccffff44` |
| `lib/core/hermes/channel/hermes_channel_state.dart` | `2a21f95befa4de3c37fa2a3479480683a1f6c405a9b3f668fbec96bfa5b974dc` |
| `lib/router/providers/app_router.dart` | `f00de1fb6c9810ac6817aff3434bb4a4a79262f8d99ed275810d1f3fa5b371db` |
| `lib/features/hermes_chat/screens/state/hermes_chat_lifecycle.dart` | `19976075f4b59b4fd642280fb8d232f52a5935187e11a9d8649565345144b553` |
| `lib/features/hermes_chat/screens/state/hermes_chat_layout.dart` | `b5f9222085bbf7f9913267397d87cd5671c6e7a2b44b4011c4b0decd7cebdde4` |
| `lib/features/hermes_chat/screens/hermes_chat_screen.dart` | `1f55a4cfc90ea1b56b6276b076758286fd87cd918ab8a3c5aaf72222dbf5991c` |
| `test/features/office/office_screen_test.dart` | `5223b148fe8442fdd355a06a35fd0e8527b407e0a9e25c6957948d599de1de03` |
| `test/router/office_route_test.dart` | `e9fe3e472fba9f5f4f3d688f449b685608a7bdf9b8808173380d2090a544642c` |
| `test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart` | `79b0fcda8ba4ceafe96410685a0871ddca836c56e7576c795ab1f961eb4ae02e` |
| `pubspec.lock` | `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89` |
| `package-lock.json` | `f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63` |
| `hermes-agent/apps/desktop/src/AGENTS.md` | `4731afa2639ca69e086c52bee38037bc0f92be9060d35b59356d925c86d231dd` |
| `hermes-agent/apps/desktop/src/components/ui/row-button.tsx` | `cdde5f344a0c3dfbe6c6a12d8f7446c828db67d97faf0a48633bc88b9332e028` |
| `hermes-agent/apps/desktop/src/plugins/hermes-bots/bot-row.tsx` | `71b3214e7e84acd71f07a5889bb0838513b0856cb19899236b1ac4db382e83fd` |
| `hermes-agent/apps/desktop/src/plugins/hermes-bots/roster-actions.ts` | `c58dabe0fdec0698f19b01b3c8e0d32d6b43e8632c92efcd9079c0a9226c2b6f` |
| `hermes-agent/apps/desktop/src/plugins/hermes-bots/canonical-chat.ts` | `bf9237c88e0d448bc75381ad7ac3c0a33825f5f9a0e56e35243d9fb616c68e92` |
| `hermes-agent/apps/desktop/src/plugins/hermes-bots/bot-row-opens-canonical-chat.test.ts` | `413c4ec3dc596cb2cd332d80b9b345fb8110fd427b2515cf04c01265de03561a` |
