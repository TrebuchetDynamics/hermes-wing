# M3 enrollment → new profile → explicit Chat contract checkpoint

Task: `DOC-M3-CONTRACT-CHECKPOINT`. **Source inspection only; no native/live
qualification.** Start with the [M3 outcome](../../ROADMAP.md#m3--trusted-onboarding-into-a-useful-profile-and-workspace),
[current routes](../product/routes.md), and [mutation acceptance criteria](../adr/api-and-state.md#required-agent-owned-mutation-contract).
This receipt maps the smallest isolated check; it does not enable an operation.

## Evidence identity and scope

Inspected with `git rev-parse HEAD` (and `git -C <reference> rev-parse HEAD`):

| Source | Exact revision | Meaning |
| --- | --- | --- |
| Wing task baseline | `6c4ae00d6661ba7d084fdc979f4b5045657b6a98` | Production callers and nearest tests cited below; this task changes documentation only. |
| Unmodified Agent reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Read-only source/test evidence, not the identity of an installed or connected runtime. |
| Official Desktop, `apps/desktop/` | `158fd638da1629c8e62caf9ade1515d162def8ab` | Same Git repository/revision, not an independent release or parity qualification. |

The coordinator assigned this isolated task branch. The local [task index](../../TODO.md)
at the Wing baseline places it in Next and leaves later implementation ownership
unclaimed; no live tracker lease or implementation ownership is asserted here.
No credentials were acquired, Agent operations activated, upstream tests executed,
or upstream files changed. The [July Android plan](../superpowers/plans/2026-07-13-android-auth-profiles.md)
is superseded history: its enrollment-token/routes and compatibility-adapter text
are not current contracts. The [Agent immutability boundary](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent)
remains absolute.

## Contract trace: supported seams versus missing guarantees

### 1. Direct enrollment is connection setup, not token issuance

- [Enrollment screen](../../lib/features/enrollment/screens/hermes_enrollment_screen.dart):13–50,
  55–180 opens the existing direct connection form or manual Local/Termux guide.
  Legacy handoff entry shows generic recovery; it does not inspect/exchange a code.
  Cancel pops to the caller when possible. No pairing or service bootstrap is restored.
- [Connection caller](../../lib/features/hermes_chat/screens/state/hermes_chat_connection.dart):394–492
  captures form/channel/directory/store ownership, connects to the explicit endpoint,
  then saves only after connected-state and endpoint acknowledgement. Storage failure
  is distinct from connection failure: an uncertain store result is **not** called
  rolled back and does not automatically disconnect. A successful saved connection
  returns through the directory; saving does not create an Agent profile or send text.
- [Endpoint store](../../lib/core/hermes/setup/secure_hermes_endpoint_store.dart):56–168
  commits the endpoint set with one secure-bundle write before compatibility metadata.
  Its local saved-endpoint `id` is not the Agent profile ID. Legacy **Agent-key**
  migration cleanup is not deletion of inert management credentials. Do not generalize
  secure-bundle atomicity into an Agent profile/setup transaction or physical keystore proof.
- Authoritative Agent authentication is [API-server `_check_auth`][U1]:1586–1608,
  a profile-aware bearer-key check. [Capabilities handler/table][U2]:67–110,
  2536–2576 advertises chat/session/model-option operations, but **no**
  `profiles`/`profile_create`, operator enrollment, caller `granted_scopes`, or Wing
  query `profile_context` contract. Bearer authentication alone supplies none of those.
  The nearest [capabilities test][U3]:937–961 checks the real API-server response;
  it does not establish scoped enrollment or profile creation.

**Available for isolated qualification:** explicit direct authentication, local secure
saving and explicit saved-contact selection/restoration. Android manual preparation,
native SSH, physical secure storage and live authentication each need their own target
evidence; screen/route presence proves none of them.

### 2. Wing profile creation is an exact, conditional API seam

- [Profiles screen](../../lib/features/profiles/screens/profiles_screen.dart):276–309,
  426–465, 537–556 requires schema support, exact `profile_create` **POST
  `/api/profiles`**, declared `profiles:write`, every required grant and supported
  query context when the endpoint is profile-scoped. Read/catalog visibility does
  not imply create permission. The connected channel's capability document is the
  gate, not the mere existence of a dashboard route with the same path.
- The [production constructor](../../lib/features/profiles/screens/profiles_screen.dart):453–461
  supplies **neither** `canConfigure` nor `onCreate` to
  [ProfileEditorSheet](../../lib/features/profiles/widgets/profile_editor_sheet.dart):188–201,
  421–440. The editor chooses a clone source and calls
  `channel.createProfile(name, cloneFrom)` only on Create. The optional
  configurable callback/secret fields exercised directly by editor tests are **not**
  a wired transactional setup flow in this screen.
- [Channel create/reconciliation](../../lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart):160–177,
  307–330 checks the exact operation and authorization through the
  [shared capability guard](../../lib/core/hermes/channel/api_channel/hermes_api_channel_capabilities.dart):4–25,
  executes once, then refreshes inventory with a connection-generation fence.
  A failed refresh after commit is not rollback. There is no create idempotency key,
  status reconciliation receipt or delete-on-failure transaction here.
- [API client](../../lib/core/hermes/client/hermes_api_client.dart):550–569 sends only
  trimmed `name` and optional `clone_from`; it expects a Wing-shaped profile row.
  [HermesProfile](../../lib/core/hermes/models/hermes_profile.dart):10–66 parses
  `id`, `name`, `revision`, etc.; it has no independent profile-incarnation field.
  Do not assume a name or ordinary row revision proves delete/recreate safety.

**At the inspected Agent API-server revision:** this create seam remains unavailable.
The smallest current real-runtime journey can qualify enrollment and existing-profile
Chat only where their own transport contracts allow; it cannot truthfully claim the
combined enrollment → new-profile → explicit Chat outcome.

### 3. Agent/Desktop create handlers are not the missing Wing contract

The authoritative domain exists, but on different surfaces and with different guarantees:

| Surface | Handler/model and nearest test | Supported source guarantee / limitation |
| --- | --- | --- |
| Agent profile domain | [`create_profile`][U4]:1401–1481; [`ProfileInfo`][U4]:661–695; [clone tests][U5]:150–196 | Builds a hidden staging tree, strips messaging channels unless opted in, and publishes by rename; exceptions inside staging construction remove that staging tree. Atomic-publication and source-symlink-preservation tests are not an injected setup-failure/rollback receipt. After publication, domain code can register an s6 service and notify a multiplexer. No claim of zero lifecycle effects. |
| Dashboard REST | [`ProfileCreate`][U6]:429–446; [`create_profile_endpoint`][U7]:803–873; [builder test][U8]:3052 onward | Accepts clone/provider/model/builder fields; may seed skills and create an alias wrapper. Post-create model/MCP/skill work is best-effort and returns separate outcomes plus a host path. List returns `profiles`, not Wing's `data`; create is not a revisioned Wing profile envelope. No whole-setup rollback or scoped Wing operation is established. |
| Native JSON-RPC | [`profiles.create`][U9]:305–346; [params/result models][U10]:182–226; [env-reference test][U11]:23–42; [model inheritance test][U12]:16–34 | Has explicit create options and secret-reference preservation tests, but default credential mirroring, optional shared auth, alias/skill/SOUL/model effects and best-effort post-create work. Result reports `name`, `path`, `mirrored`, `model_set`, not Wing `id`/`revision` or a durable transaction receipt. |
| Official Desktop caller | [`ensureAgentCreated`][U13]:366–445; [lazy-create tests][U14]:188–237 | Creates through `profiles.create`; the Capabilities tab can materialize the draft before Create Bot. Tests also expect canonical Chat kickoff after Create Bot. This is product-reference behavior, not evidence of Wing's explicit-no-send boundary or permission to port hidden writes. |

**Rollback verdict:** staging cleanup is narrower than rollback of an entire created
profile plus provider/model setup. Neither the Wing caller nor the inspected REST/RPC
composition establishes that combined transaction, crash-safe deduplication, exact
incarnation binding, or unchanged sibling profiles after a failed setup. Historical
Wing Link rollback-by-deletion does not qualify the current path or existing-profile
provider mutation. The [failed-setup attribution receipt](m3-setup-rollback-evidence.md)
(`DOC-M3-ROLLBACK-EVIDENCE`) traces historical compensating cleanup and names the
missing failure-specific existing-profile identity proof; it runs no operation.

### 4. Chat entry remains a separate explicit choice

[Profiles `_selectProfile`/`_openChat`](../../lib/features/profiles/screens/profiles_screen.dart):467–533
captures the connection owner, waits for selection acknowledgement, checks the exact
selected profile and only then navigates. Creation itself only reconciles inventory.
[Channel selection](../../lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart):4–157
reads inventory/sessions in the chosen profile context with generation fences; it
never calls global `profile use`/`project use` and has no prompt submission in that path.
It may load an existing session and reattach an Agent-owned detached run; that is not
a fresh prompt. The isolated new-profile check must therefore use an empty, idle
profile and assert no create/send/approval/Stop before explicit intent.

## Smallest isolated qualification check (not executed)

Use one approved disposable target and one unmodified, isolated Agent state root;
never a personal installation, shared gateway or credential harvested from another
profile. This is a future check specification, **not authorization or a runnable
provisioning recipe**. Stop at the exact missing operation rather than bypassing it.

1. **Bind identity before entry.** Record Wing commit/artifact digest, OS/build and
   device identity using a private serial-to-receipt alias; normalized Agent origin
   and host trust identity privately; Agent code revision and install identity when
   authoritatively exposed; saved endpoint ID; source profile ID; requested fresh
   profile ID and its authoritative incarnation/revision if available. Published
   evidence uses opaque aliases, never raw serials, private origins/paths or secrets.
   Inventory and Chat identities must identify the same target; a label is insufficient.
2. **Enroll directly.** Through welcome → direct authenticated form, exercise denial
   and cancel without saved changes, then one successful explicit save. Read back
   the same secure endpoint owner; distinguish connection, persistence and restoration.
   Management-slot access, pairing exchange, Agent writes and prompt count stay zero.
   Record platform secure-input/storage qualification separately from mocked tests.
3. **Gate, then create once.** Capture the connected target's exact create operation,
   all grants, source profile identity and transaction guarantees. With today's
   inspected API server, record **UNAVAILABLE**, absent operation/grants, and zero
   create requests; end the new-profile branch. A synthetic advertised capability
   exercises only client gating, never upgrades this result.
4. **Only after a suitable unmodified contract exists:** use Profiles → New Profile
   → Create with a unique disposable identity and deliberate clone/fresh choice.
   Opening/canceling the editor and catalog reads must not write. Read back exactly
   the created profile and source identity; create must not select Chat or send.
   Enumerate all intended domain effects, including inherited credentials/config,
   skills, alias, lifecycle or network effects; reject any undisclosed effect.
   A successful clone is not credential validation, activation or inference readiness.
5. **Failure leg on a separate disposable identity.** Using a supported bounded
   failure facility, prove failed setup either leaves no new profile/partial secret
   state or returns an honest partial/unknown outcome. Verify the pre-existing source
   profile/incarnation is unchanged through authorized readback; do not infer rollback
   from a toast, missing inventory row or timeout. Unknown commit outcomes must reconcile,
   never automatically retry with a new key or delete by reused name. If no safe
   failure/readback contract exists, mark rollback **UNVERIFIED** and stop that leg.
6. **Explicit Chat.** Only after successful readback, choose that profile's Chat
   action; verify device/endpoint/profile and, if present, authoritative session identity
   match. An empty profile may have `activeSessionId == null`: record authoritative
   absence, never create a session merely to satisfy this check. Switching to another
   owner or revoking authority must fence cached actions and late
   responses. No global selection, Project creation/assignment, provider mutation,
   prompt, approval or Stop is incidental. Generation after an explicit Send would be
   a separately consented live check, not required to prove navigation.

## Existing isolated checks mapped to the journey

These tests were **inspected, not run by this documentation task**. They use fakes
or deterministic fixtures; none proves real Agent setup rollback or Android security.
No new tests are needed for this documentation-only change.

| Check seam | Nearest existing target/case | What it can prove / cannot prove |
| --- | --- | --- |
| Welcome → direct form → retry/save | [direct first run](../../test/features/enrollment/hermes_direct_first_run_test.dart):30–204, `public first-run direct retry` | Keyboard journey at 390/1280 and 100/200% text; denial, explicit retry, one save, GET-only Agent traffic; Linux widget variant, not Android/live auth. |
| Manual Android setup / retained owner | [Android fixture consumer](../../test/integration/android_direct_setup_enrollment_test.dart); [bounded receipt](android-direct-setup-enrollment.md) | Public-controls deterministic journey; receipt explicitly leaves native/live authentication and physical keystore unqualified. |
| Secure local commit | [endpoint store tests](../../test/core/hermes/setup/secure_hermes_endpoint_store_test.dart):301–367 | Failed secure-bundle write preserves old enrollment; Agent-key cleanup preserves inert Link slots. Not a cross-system enrollment/profile transaction. |
| Create gate and inventory | [channel tests](../../test/core/hermes/channel/hermes_api_channel_test.dart):965–994, 1229–1355 | Synthetic success refresh; missing endpoint, missing scope declaration and missing secondary grant reject writes. Not deployed contract evidence. |
| Create payload / ownership | [editor tests](../../test/features/profiles/profile_editor_sheet_test.dart):27–84, 219–251; [mutation-owner tests](../../test/features/profiles/profiles_mutation_owner_test.dart):84–265 | Explicit create name/clone; cached controls/late completions fenced across host, authority, channel, directory, disposal and roundtrip. Configurable editor callback tests alone do not prove production setup wiring. |
| Explicit Chat | [Profiles tests](../../test/features/profiles/profiles_screen_test.dart):223–282, 1343–1450 | Failed/late selection cannot navigate; successful selection opens Chat. Not an end-to-end new-profile transaction or live reply. |
| Upstream isolation | [atomic clone test][U5]:165–184; [env-reference test][U11]; [inheritance test][U12] | Domain publication/reference preservation, not native auth, crash-safe setup rollback or Wing wire compatibility. |

## Disposition and update triggers

- Supported **client seams** are direct connection/save and conditional profile/Chat
  controls; live support depends on the selected transport and exact runtime contract.
  The combined new-profile journey and transactional rollback are **not qualified**
  by the inspected runtime. This is a completed contract-gap receipt, not M3 completion.
- Project creation/assignment/Project-to-Chat binding and existing-profile provider
  writes are separate tasks. No directory path fallback, Agent patch, second provider
  store, compatibility adapter or broader Wing Link authority is proposed.
- Historical [evidence-matrix profile/provider rows](evidence-matrix.md) still describe
  retired compatibility/new-profile behavior; they are not current support proof.
  This receipt does not rewrite or requalify those historical tests.
- Revisit when the connected Agent advertises a changed create/auth/identity contract,
  Wing's screen wires a different setup payload, rollback evidence is attributed, or
  source/artifact revisions change. Re-pin sources and repeat independent review;
  do not carry this source conclusion onto an uninspected release.
- Pending live: approved-device direct enrollment/secure storage and target-specific
  accessibility; a real isolated combined setup/rollback/Chat receipt only after its
  authoritative contract is available. No platform was exercised by this task.

## Pinned upstream sources

[U1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L1586-L1608
[U2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L67-L110
[U3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server.py#L937-L961
[U4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/profiles.py#L1401-L1481
[U5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_profile_clone_channels.py#L150-L196
[U6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_models.py#L429-L446
[U7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/profiles.py#L803-L873
[U8]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_web_server.py#L3052-L3130
[U9]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/methods_profiles.py#L305-L346
[U10]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/contracts/profiles_vault_complete_foreign_subagents.py#L182-L226
[U11]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/tui_gateway/test_profiles_create_env_refs.py#L23-L42
[U12]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/tui_gateway/test_profiles_inherit_launch_model.py#L16-L34
[U13]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/plugins/hermes-bots/create-dialog.tsx#L366-L445
[U14]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/plugins/hermes-bots/create-agent-lazy-profile.test.tsx#L188-L237
