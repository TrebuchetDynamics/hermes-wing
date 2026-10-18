# M4 Memory: one profile-memory chunk read

Task: `DOC-M4-MEMORY-CONTRACT`. **Read-only source evidence, not shipped memory
support, operation activation or native/live qualification.** Start with the
[parity status](../product/hermes-desktop-parity.md#statuses),
[current routes](../product/routes.md) and [API/state boundary](../adr/api-and-state.md).

## Verdict and source identities

Official Desktop can prefill a memory editor with
**`GET /api/learning/node?id=<node-id>&profile=<profile-name>`**. The Agent
resolves one built-in `MEMORY.md` or `USER.md` chunk. It does **not** supply a
bounded, exact-grant, incarnation-bound Wing memory read: content and underlying
file reads are uncapped, node IDs are not profile identities, and the messaging
API does not advertise this operation. **Keep memory inspection unavailable in
Wing.** This finding is not a claim that Agent has no memory read anywhere.

Pins obtained with `git rev-parse HEAD`, `git -C <Agent-reference> rev-parse HEAD`
and `git -C <Agent-reference>/apps/desktop rev-parse HEAD`:

| Inspected tree | Revision | Evidence ceiling |
| --- | --- | --- |
| Wing baseline | `fa82a4b4f1a223dd962494ea4e2d70b5d14a9a5b` | Current caller/gate and regression source; documentation-only change. |
| Unmodified Agent reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Handler, resolver/parser and nearest tests, not an installed runtime. |
| Official Desktop subtree | `158fd638da1629c8e62caf9ade1515d162def8ab` | Same repository/revision; interaction reference, not separate release evidence. |

The read-only reference is the canonical checkout's `hermes-agent/`, outside this
isolated worktree; its status was clean. Relevant root/area instructions were
read. No credentials, actual memory files, runtime databases or private payloads
were accessed. No Agent request, executable upstream test or service was started.

Docs map:

- Existing owners: parity/routes above, [Agent immutability](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent),
  [security decision](../adr/security-and-privacy.md) and [threat model](../security/threat-model.md).
- Source corpus: Desktop node-detail caller, Agent REST handler, built-in memory
  chunk resolver/parser, profile/auth seams, nearest tests and Wing public seams.
- Chosen slice: one already named built-in memory node, especially a `USER.md`
  chunk (`source=profile`). Graph construction is supporting ID evidence, not an
  additional inventory operation proposed for Wing.
- Missing guarantees: exact advertised read/grant, owner/incarnation envelope,
  response/read bounds and unambiguous read failures.
- Validation: source pins/trace, Markdown/source targets, independent
  contract/security review and whitespace check. No behavior changes or new tests.

Ownership: the coordinator assigned this task/branch/worktree. The local execution
slot records it running and its worker process was present. The baseline
[task index](../../TODO.md) lists this task and a dependent capacity/provider
follow-up; the inspected [continuation ledger](../plans/2026-10-03-desktop-port-goal.md)
has no matching memory-task claim. This is local admission evidence, **not** a
fresh live tracker lease check, ownership release or authority to start other work.

## Exact authoritative read trace

| Acceptance dimension | Supported by inspected source | Unavailable guarantee / disposition |
| --- | --- | --- |
| Operation and schema | [REST handler][U1]:689–703 calls `node_detail(id)` through `_learning_mutation` and `scoped_to_thread`. Success for memory is `{ok:true, kind:"memory", id, label, content}` ([resolver][U2]:139–148). Desktop's [TypeScript interface/caller][U3]:55–67 expects `ok`, `kind`, `label`, `content`; actual wire also carries `id`. | No declared versioned REST response model, memory-only endpoint or advertised Wing operation. The shared node door also accepts skills. TypeScript is not response validation. Do not invent a memory operation name or scope. |
| Required grant | Production [mount/auth][U4]:690–727, 1010–1034 protects `/api/`. Dashboard session authentication includes [native OAuth bearer verification][U21]:153–180 when `auth_required` is active. Separately, the machine-[token seam][U5]:1–9, 28–42, 78–96 applies only to registered exact paths; no production registration for `/api/learning/node` was found in the inspected source. | The selected handler declares no memory-read scope or profile-specific caller grant. Dashboard authentication is not Wing API authorization. [Messaging capabilities][U6]:67–103 advertises neither this node read nor an entry inventory; `memory_write_api=false` says nothing affirmative about read permission. Do not reuse another transport's credential or broaden Wing's native seam. |
| Profile identity | `profile` query reaches [worker scope][U7]:40–48; [profile resolution/scope][U8]:31–34, 190–199, 242–320 validates explicit names, resolves an existing home and binds home plus secret scope. The memory file is resolved under `get_hermes_home()` at call time ([resolver][U2]:54–83). | Missing/blank/`current` retains the dashboard's own-profile semantics. `memory:profile:…` means the `USER.md` source **within** that home, not a selected profile name, caller grant or Hermes Project. Success echoes no endpoint/profile/incarnation/revision. Same-name profile recreation and same-text nodes across homes are not fenced by the node ID. |
| Entry identity | [ID producer][U9]:143–185 emits `memory:<source>:<combined-index>:<fingerprint>`; `memory` maps to `MEMORY.md`, `profile` to `USER.md`. Combined order is memory then user. Fingerprint is the first 12 hex characters of SHA-256 over stripped full entry text. Resolver uses the first matching fingerprint in the selected source file. | This is content matching, not an opaque authorization handle or immutable entry ID. With a fingerprint the position is not the lookup authority; duplicate text resolves first match and digest collisions are not separately checked. Legacy three-part IDs still resolve by position and can identify a different same-source chunk after list drift. Never mint IDs client-side or treat a digest as redacted metadata safe for logs. |
| Bounds | One success returns one stripped chunk, with the first line clipped to 80 characters as `label` ([detail][U2]:145–148). Graph card `body` alone is clipped to 1,200 characters ([producer][U9]:161–185). | Detail `content` has no character/byte cap; input `id` has no explicit max length. [Parser][U10]:491–518 reads the entire source file before splitting on `\n§\n`; no file-size, entry-count, deadline or pagination contract here. A single-entry result is not bounded work or bounded bytes. Graph preview truncation and mutation budgets do not constrain this read. |
| Failure and consistency | Missing file, malformed ID, stale fingerprint or invalid legacy index becomes `{ok:false,message}` via `_dispatch` ([resolver][U2]:27–83, 130–143); REST maps non-ok to HTTP 404. Successful detail is a read-only lookup; this memory branch does not call `_mutate_memory`, write a file or initialize a provider. | `_read_file` turns read/decode failure into an empty list ([parser][U10]:491–518), which can surface as stale/index-not-found rather than read failure. Malformed/stale/missing cases share 404, not a precise deletion verdict. There is no read lock or snapshot/revision spanning graph → detail, and legacy resolution reads source plus cards separately. Raw messages may include the requested ID; no sanitized bounded error envelope is promised. Request profile scope also builds/hydrates secret context ([scope][U8]:277–320), so a pure, zero-external-effect request guarantee is not established by the chunk function alone. |

### Desktop caller sequence (not executed)

1. [Graph producer][U9]:218–255 returns built-in memory cards/node IDs. This
   is not provider-wide entry enumeration; this read does not inspect external
   memory-provider databases or prove those providers' visibility.
2. [Node context menu][U11]:42–85 calls `getLearningNode(target.id)` on explicit
   Edit and uses its content as editor prefill. [API helper][U3]:62–67 carries
   `capabilityScoped(profile)`. With no explicit scope, [scope helper][U12]:75–82,
   219–235 uses ambient profile/connection routing. The renderer hands those tags
   to the native bridge; this is not a new Wing-native integration contract.
3. The Agent REST handler runs the domain detail function in the requested scope.
   Fingerprinted lookup reads only the fixed selected memory source; no arbitrary
   caller-selected file path is accepted by this memory branch.
4. Desktop's context menu bumps an epoch and clears editor state on profile switch,
   rejecting an old successful prefill. That local protection is not server-side
   identity confirmation or proof of all connection/authority races. Save/Delete,
   graph inventory, file browsing and provider setup are outside this slice.

`GET /api/memory` is **not an entry read**: [handler][U13]:488–506 returns active
provider, discovered provider statuses and built-in file byte sizes;
[Desktop model][U14]:1804–1809 calls it `MemoryStatusResponse`. File size is not
entry count, capacity limit, remaining capacity or access to contents. Detailed
capacity/provider reporting is intentionally reserved for the next task below.

## Nearest tests inspected, not executed

| Source/cases | Evidence in test source | Ceiling |
| --- | --- | --- |
| [Domain tests][U15]:27–42, 51–85, 220–255 | Disposable built-in files; kind parsing and skill detail; real fingerprinted edit/delete follows the clicked text after list shift and refuses reuse after content disappears. | Shared resolver evidence, not an executed or direct memory-detail GET test. Write-budget tests are not read bounds. No HTTP grants, two-profile detail isolation, profile recreation, oversized content or read-error oracle here. |
| [Graph tests][U16]:38–58, 64–81 | Memory delimiter cards and memory-kind nodes; graph edge/cluster integrity. | Not pagination, detail bounds, external-provider coverage or authorization. |
| [REST scope tests][U17]:26–61, 88–126 | Authenticated isolated default/named homes; query-profile learning-node **writes** leave the other same-named skill unchanged. | Nearest shared routing seam, not a memory-node GET A→B→A or denial test; no stronger read guarantee inferred from mutation coverage. |
| [Desktop menu test][U18]:1–38 | Mocked API/profile-switch hook and keyboard activation of Delete confirmation. | No real memory-detail result, read bounds or delayed-profile-prefill regression in this file. |

## Wing caller and regression trace

No production memory-node caller/model was found in `lib/core/hermes/`,
`lib/features/` or `lib/router/` for `/api/learning`, `learning.detail`,
`LearningNode`, `memory:profile` or `/api/memory`. The absence is specific to these
inspected seams and revision, not a claim about all possible Agent surfaces.

- [Channel contract](../../lib/core/hermes/channel/hermes_channel.dart):112–137
  has profile SOUL, health, jobs and tool inventory reads, not memory entries.
  SOUL/persona text is a different resource, not a `USER.md` memory substitute.
- [Capability model](../../lib/core/hermes/models/hermes_capabilities.dart):53–89,
  94–134 requires supported schema 1, exact method/path and declared scope for
  scoped operations, with explicit supported query-profile context. These are
  existing building blocks, not an implemented memory gate.
- [Memory policy](../../lib/core/hermes/policy/hermes_transport_policy.dart):50–52
  only reads the broad `memory_write_api` flag. [Readiness](../../lib/core/hermes/policy/hermes_surface_readiness.dart):201–207
  always defers Memory UI, even if that flag is true. Its phrase “memory API is
  advertised” must not be treated as evidence of this exact read or any grant.
- [Route constants](../../lib/router/routes/app_routes.dart):3–18 have no memory
  destination; `/memory` is planned in route documentation, not a callable UI.
  [Native fixed RPC seam](../../lib/core/hermes/client/hermes_web_read_rpc.dart):35–88
  exposes ping/session IDs, not generic learning-detail or REST dispatch.
- Nearest [Wing regression](../../test/core/hermes/hermes_api_test.dart):809–857,
  `surface readiness does not claim unwired Hermes APIs are implemented`, asserts
  Memory UI remains deferred for future feature flags. This is adjacent source
  evidence, not a memory authorization/bounds test or a fresh test-run result.

Agent also registers [`learning.detail`][U19]:1433–1448 over the same domain
function, with a [separate RPC result model][U20]:311–333. That existence is not
an advertised or qualified Wing method; its transport/profile contract is not
qualified by this REST slice and it is not an authorized fallback.

Current living ADRs override the older parity ledger's retired compatibility
wording. No shell bridge, direct Agent-file/database fallback, shadow entries,
provider installation or upstream modification may fill these gaps. Do not log,
persist, include in diagnostics or copy actual chunk content/content fingerprints
into receipts. This task changes neither runtime code nor M4-MEMORY status.

## One next read-only slice

Use the already indexed **`DOC-M4-MEMORY-CAPACITY-CONTRACT`**, after its own
coordinator admission; do not start it here. Trace the metadata-only
`GET /api/memory` status model and Desktop caller separately from entry reads.
Record which values are file bytes, provider availability/configuration or actual
capacity/limits, with exact profile and authorization evidence or precise absence.
Check authoritative bounds and nearest error/isolation tests; do not equate a
configured provider with usable credentials or a ready entry API. Exclude provider
config values/secrets, OAuth, dependency probes/installs, reset, writes, credential
acquisition and live requests. If a status read internally invokes probes or
hydration, record that effect from source, never activate it to obtain evidence.

## Validation and qualification ceiling

- Source pins and handler → resolver/parser → nearest tests → Desktop/Wing caller
  trace recorded above. Local Markdown/source targets and cited line-range bounds
  were checked with a temporary offline validator; no network link probe was used.
- Independent fresh-context `reviewer` approved the substantive source-only
  contract/security draft (run `259b2412-9605-46ef-b176-3511df941bd8`, draft
  SHA-256 `c028dd6315f43cba3efa7773f767b634dc05775ea5b157936de66252f615fc25`).
  No blocking findings. One low-severity authentication clarification was verified
  against the middleware/registration source and incorporated above. Final edits
  clarify that distinction and record checks/review, not runtime acceptance.
- `git diff --check` is the final whitespace gate. No executable test is added or
  run for this documentation-only change; upstream tests were inspected only.
- No Flutter/browser/native app, physical device, live authentication, provider
  or Agent operation was exercised. Source review adds no platform qualification.
- Pending live: authenticated bounded read/denial, profile isolation/recreation,
  owner-change recovery and an accessible target-native inspection path, **only
  after** a suitable unmodified operation and separately admitted disposable target
  exist. These are not offline blockers or authorization to activate operations.
- Revisit and re-pin on changes to learning-node handler/resolver/IDs, memory
  parsing/bounds, profile/auth scoping, advertised operations, Desktop caller or
  Wing gates. Do not transfer this result to an uninspected runtime release.

## Pinned upstream sources

[U1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/status.py
[U2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/agent/learning_mutations.py
[U3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/skills.ts
[U4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server.py
[U5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/dashboard_auth/token_auth.py
[U6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L67-L103
[U7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/_common.py#L40-L48
[U8]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_profiles.py
[U9]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/agent/learning_graph.py
[U10]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tools/memory_tool_store.py#L491-L518
[U11]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/starmap/node-context-menu.tsx#L42-L85
[U12]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/client.ts
[U13]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/ops.py#L488-L506
[U14]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/types/hermes.ts#L1804-L1809
[U15]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/agent/test_learning_mutations.py
[U16]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/agent/test_learning_graph.py
[U17]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_web_server_skills_profiles.py#L26-L126
[U18]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/starmap/node-context-menu.test.tsx#L1-L38
[U19]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/methods_tools.py#L1433-L1448
[U20]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/contracts/tools_mcp_plugins.py#L311-L333
[U21]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/dashboard_auth/middleware.py#L153-L180
