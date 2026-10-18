# M3 Project creation: authoritative contract trace

Task: `DOC-M3-PROJECT-CONTRACT`. **Read-only source evidence, not runtime or
platform qualification.** Start with the [intended journey](../product/prd.md#core-journeys),
[current route status](../product/routes.md) and [API/state boundary](../adr/api-and-state.md).

## Verdict and source identities

An authoritative, machine-readable **`projects.create` JSON-RPC** exists in the
unmodified Agent reference. It is not an advertised Project creation operation on
the messaging HTTP API, nor a qualified Wing Project mutation. Its raw-path,
authorization, identity and concurrency guarantees do not meet Wing's directory-grant
boundary. **Keep Project creation unavailable.** Assignment and Project-scoped Chat
remain separately gated; this receipt neither implements nor qualifies them.

Pins obtained with `git rev-parse HEAD` in Wing and `git -C <reference> rev-parse HEAD`
in Agent and its Desktop subtree:

| Inspected source | Revision | Evidence meaning |
| --- | --- | --- |
| Wing baseline | `41c98306e699add960bbc7818f749222e342fdea` | Callers/models/tests below; documentation-only task. |
| Agent read-only reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Source contracts/tests, not a connected or installed runtime. |
| Official Desktop `apps/desktop/` | `158fd638da1629c8e62caf9ade1515d162def8ab` | Same repository and commit, not an independent release or parity result. |

The coordinator assigned this isolated branch; this does not claim external tracker
lease release or ownership of a later implementation task. The
[old creation plan](../plans/2026-09-01_111952-project-setup-contract.md) and
[old directory plan](../superpowers/plans/2026-08-30-directory-selection-project-readiness.md)
are superseded context, not permission to restore compatibility adapters. The
[adjacent enrollment checkpoint](m3-enrollment-profile-contract-checkpoint.md)
does not establish Project creation. No credentials, personal runtime state,
network operations, Agent mutations or upstream test execution were needed here.

## Exact operation and guarantee ledger

| Boundary | Verified source contract | Missing / not established for Wing |
| --- | --- | --- |
| Operation and input | [`ProjectsCreateParams`][U1]:73–88 registers `projects.create`. Required `name`; optional `profile`, `folders`, `slug`, `primary_path`, `description`, `icon`, `color`, `board_slug`; `use` defaults to `false`. [`ProfileParams`][U2]:231–234 makes `profile` optional. | No HTTP create method/path is advertised for Projects by the inspected messaging API. No directory-handle, grant identity, expected revision or idempotency-key field in this RPC input. Do not invent them. |
| Handler and authority | [`_projects_method` / create handler][U3]:27–43, 90–100 opens the Agent-owned per-profile store, invokes `projects_db.create_project`, optionally calls `set_active`, records a feature-use signal, then reads the row back. | This is Agent authority, not authorization for Wing to expose host workspace administration. No `projects:write` or other Project-specific caller grant check is declared in these models/handler. An authenticated transport is not an exact Wing operation grant. |
| Authentication boundary | [WebSocket RPC entry/admission][U4]:139–151, 595–613 and [auth/request helpers][U19]:202–204, 377–379 check chat enablement, authentication and host/origin/client gates. [RPC dispatch][U5]:17–42 resolves the method and validates params before invocation. | These are different from messaging-API bearer capabilities. No Project-specific grant negotiation is established by this trace. This is not a claim that the backend is unauthenticated or a complete security audit of `serve`. |
| Profile identity | [`_profile_home` / `_profile_scoped`][U6]:567–626 resolves explicit profile names and binds that profile's runtime scope. Unknown explicit names fail; omitted/blank context uses the launch profile for this sessionless create. Desktop supplies an explicit captured profile. | A profile name/home is not an opaque incarnation token. Create input/result has no expected profile incarnation or revision to reject a deleted/recreated name. Wing must not depend on ambient launch scope or global `profile use`. |
| Project and folder identities | [`ProjectInfo` / `ProjectFolder`][U1]:21–58 returns `project` (nullable for create), with `id`, `slug`, `name`, timestamps/display fields, `primary_path`, `folders[].path`, labels and primary flags. [Domain creation][U7]:220–263 mints `p_` plus random hex; [lookup][U7]:264–270 accepts ID then slug. | Paths are raw host paths, not approved-root/opaque-directory handles. Neither result nor input binds caller/device/directory-grant identity. Project rows have no revision field. Slug/name lookup is not sufficient identity or replay safety. |
| Validation and containment | [Domain][U7]:81–98, 108–111, 227–248 trims/requires a name, validates a supplied slug (1–64 lowercase alphanumerics/hyphens/underscores, no leading separator), normalizes paths via `expanduser` + `abspath`, deduplicates folder strings, and chooses explicit primary or first folder. Empty folder sets are allowed by the domain. | No canonical approved-root containment, symlink revalidation, directory-grant revocation check, existence/child-directory-only check, or per-field string/list size bound is supplied by these create models/domain. Normalization is not authorization. Never forward a caller-selected path as a substitute for a directory handle. |
| Concurrency and commit | [Schema/domain][U7]:28–49, 193–263 has unique ID/slug and a folder key `(project_id, path)`. Project plus folder inserts share [`write_txn`][U8]:99–113 (`BEGIN IMMEDIATE`, commit/rollback). Slug collision suffixing occurs inside that transaction. | Primary-path duplicate lookup happens **before** the transaction, and `primary_path` has no unique constraint. Sequential duplicate refusal is not cross-process duplicate-prevention proof. There is no expected revision, durable request deduplication, changed-payload replay rejection or status receipt. SQLite write serialization alone supplies none of those. |
| Selection, outcome and errors | `use=false` avoids the handler's active-pointer write. `use=true` calls [`set_active`][U9]:390–396 in a **separate** transaction after create. Handler errors map value errors to `5063`, missing addressed Projects to `5062`, other caught exceptions to `5061`; [dispatcher][U5] maps invalid params to `4000`, unknown method to `-32601`, missing explicit profile to `4064`. | Create plus activation/readback is not one transaction; a failed response does not prove rollback. No safe automatic retry after an unknown outcome: sequential path refusal is not an idempotency receipt (archived/folderless cases differ). Handler error strings may carry host paths or other raw details; Wing must not display/log them verbatim. |

The [messaging API endpoint table][U10]:67–110 and [capabilities handler][U10]:2536–2576
contain no Project create operation or Project-specific granted-scope contract.
Its [route table][U10]:1745–1793 likewise provides no Project creation route.
This absence is bounded to the inspected surface/revision, not every Agent transport
or future release. Run-submission idempotency advertised there does **not** transfer
to `projects.create`. The [CLI create path][U11]:12–35, 90–106, 132–147 also calls the
domain store, optionally activates, and prints human-readable output. It is not a
machine-readable Wing fallback or authority to spawn commands.

## Official Desktop outcome and Wing caller trace

**Reference outcome:** [ProjectDialog][U12]:125–179 adds folders, seeds a visible name
from the folder basename when empty, requires a nonblank name and at least one
folder, then calls `createProject` with `use: true` and enters the returned Project.
The [store][U13]:300–373, 1024–1123 captures gateway/profile across reconnect,
sends `projects.create` once with explicit `profile`, rejects retargeting, and
fences late results after an owner change. On success it caches the authoritative
row and reconciles list/tree. An optional idea may cause a separate file write;
this is not part of Agent creation atomicity. Missing-method handling marks only
the current owner unavailable. Desktop's active-pointer write and raw-path picker
are reference behavior, **not permission to copy them into Wing**. A Wing port
must retain an explicit parity gap until a safe unmodified contract exists.

**Current Wing seam:**

- [Profiles screen](../../lib/features/profiles/screens/profiles_screen.dart):276–309,
  426–465 offers **profile**, not Project, creation. Its exact conditional endpoint is
  `profile_create`, `POST /api/profiles`, with `profiles:write`; the shared gate at
  537–556 requires schema support, exact method/path, all required grants and
  supported profile context. None of that grants Project creation.
- [HermesChannel](../../lib/core/hermes/channel/hermes_channel.dart):55–115 has profile
  and session operations but no Project create/assignment method.
  [HermesProfile](../../lib/core/hermes/models/hermes_profile.dart):10–51 carries
  profile identity/revision, not a Project or directory-grant model. No Project
  creation caller/model was found in the inspected production `lib/core/hermes`
  and `lib/features/profiles` paths. Do not repurpose a profile revision as a
  Project concurrency token.
- The existing native `serve` seam is not a generic management bridge:
  [HermesWebReadClient](../../lib/core/hermes/client/hermes_web_read_client.dart):15–75,
  163–181 is loopback-bound with explicit profile and separate chat negotiation;
  [RPC connection](../../lib/core/hermes/client/hermes_web_read_rpc.dart):1–88 exposes
  fixed operations. Socket/chat admission does not qualify `projects.create`.
- [Local discovery](../../lib/core/hermes/local_discovery/local_hermes_home_discovery.dart):9–40
  inspects Hermes-home metadata only, not approved Project folders. The
  [directory-browser retirement](profile-directory-browser-retirement.md) is history,
  not proof of replacement grants. There is no Project picker to enable from these
  discovery results. [Routes](../product/routes.md) correctly leaves creation and
  Project-aware Chat unavailable.

## Nearest tests inspected (not executed)

| Source test | Evidence and limit |
| --- | --- |
| [Agent RPC tests][U14]:17–21, 84–90, 731–761 | Direct registered-handler create/list/active-pointer roundtrip; omitted/blank launch scope and unknown explicit-profile rejection. `_call` bypasses transport/dispatcher validation; these are not scoped-auth or approved-handle tests. |
| [Agent domain tests][U15]:41–54, 81–112, 128–144 | Primary-folder selection; sequential same-path refusal, explicit domain duplicate override, archived/folderless exceptions; isolation via two DB paths. No concurrent-create/crash/replay proof in these cases. |
| [Desktop store tests][U16]:417–576 | Explicit active-profile writes while viewing All profiles; reconnect does not retarget; owner change prevents idea write/cache publication; missing RPC remains unavailable. These are mocked client tests, not Agent authorization/containment proof. |
| [Desktop dialog tests][U17]:99–127 | Folder-basename naming and explicit-name preservation; successful creation enters the Project. Not Wing support or physical picker qualification. |
| [Messaging capabilities test][U18]:937–961 | Real handler response shape and advertised session/run/model operations; no Project-operation assertion. Absence above comes from the actual source tables, not this test alone. |
| [Wing Profiles test](../../test/features/profiles/profiles_screen_test.dart):284–387 | Synthetic exact-capability controls exercise **profile** lifecycle/catalog behavior with a real Wing channel; not a Project contract. No new test is warranted for this documentation-only task. |

## One bounded next slice

The successor [assignment and session-binding trace](m3-project-assignment-contract.md)
now records this separate source slice. It does not enable assignment or
Project-aware Chat, or transfer creation guarantees to either operation.

Use the already indexed **`DOC-M3-PROJECT-ASSIGNMENT-CONTRACT`**, not a new adapter
or a second creation implementation. Its scope is read-only evidence: separately
trace primary-folder assignment and Project-to-session/Chat binding against pinned
Agent handlers/models, nearest tests and Wing callers. Record exact profile/Project
identity, approved-handle containment, revision and stale-owner semantics, or their
absence; distinguish a profile-wide active pointer from an explicit session binding.
Acceptance must include no implicit create/send/global selection. Do not activate
assignment or Chat, acquire credentials, patch Agent, or infer those guarantees from
this creation transaction. That task's lease/admission belongs to the coordinator.

Creation implementation remains deferred until an **unmodified** supported Agent
contract can independently establish exact operation authorization, explicit current
profile identity, approved opaque directory input with canonical containment,
bounded redacted output and authoritative conflict/replay reconciliation. These
are acceptance gaps, not invented wire fields or a request to edit Agent. Missing
one does not authorize a shell bridge, direct-file mutation or Wing-owned workdir.

## Validation, review and update triggers

- Source pins and the handler → model/store → nearest tests → Desktop/Wing caller
  trace above are offline checks only. Changed Markdown targets and pinned source
  line ranges are checked against the local trees; `git diff --check` is required.
- Independent fresh-context contract/security review approved the source verdict
  with no material blockers: exact operation/grant separation, raw-path containment,
  explicit owner identity, pre-transaction duplicate checking, unknown outcomes and
  separate assignment/Chat gates. Two low-severity citation findings were corrected
  against source (actual `/api/ws` admission chain and domain line ranges).
- No native/browser/device/live service was exercised. Live creation qualification
  requires a separately approved disposable target and a suitable authoritative
  contract; current missing guarantees are not a failed device test or permission
  to activate an operation. M3-PROJECT remains unmet.
- Revisit when upstream operation/models/auth/profile-routing/transaction/tests,
  Wing callers/transport gates, or the living ADRs change. Re-pin and repeat review;
  do not carry this source verdict onto an uninspected runtime/release.

## Pinned upstream sources

[U1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/contracts/projects_pets.py#L21-L88
[U2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/contracts/common.py#L231-L234
[U3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/methods_projects.py#L13-L100
[U4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/chat_ws.py
[U5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/rpc_dispatch.py#L17-L42
[U6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/server.py#L567-L626
[U7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/projects_db.py#L28-L277
[U8]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/sqlite_util.py#L99-L113
[U9]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/projects_db.py#L390-L396
[U10]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py
[U11]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/projects_cmd.py#L12-L147
[U12]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/chat/sidebar/project-dialog.tsx#L125-L179
[U13]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/projects.ts
[U14]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/tui_gateway/test_projects_rpc.py
[U15]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_projects_db.py#L41-L144
[U16]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/projects.test.ts#L417-L576
[U17]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/chat/sidebar/project-dialog.test.tsx#L99-L127
[U18]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server.py#L937-L961
[U19]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_chat.py
