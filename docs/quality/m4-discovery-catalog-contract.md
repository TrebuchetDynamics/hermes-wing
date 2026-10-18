# M4 profile-targeted discovery catalog contract checkpoint

Task: `DOC-M4-CONTRACT-CHECKPOINT`. **Read-only source inspection; no operation
activation or native/live qualification.** Start with [M4](../../ROADMAP.md#m4--discover-and-administer-supported-agent-work),
[current route support](../product/routes.md), and [API authority](../adr/api-and-state.md).
This receipt inspects **one read**, `GET /api/skills/hub/official`, before any
Wing UI or write proposal. It does not qualify search across external sources,
selection/preview, installation, MCP, generic commands or a shadow inventory.

## Evidence identity and docs map

Pinned with `git rev-parse HEAD` for Wing and `git -C <reference> rev-parse HEAD`
for each reference:

| Source | Exact revision | Evidence ceiling |
| --- | --- | --- |
| Wing baseline | `46c19207bd22ad345066a44dfb9c7f12c17e72e6` | Existing callers and regression sources; only this documentation changes. |
| Unmodified Agent reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Handler/model/test source, not an installed runtime identity. |
| Official Desktop, `apps/desktop/` | `158fd638da1629c8e62caf9ade1515d162def8ab` | Same repository/revision; product reference, not runtime/parity qualification. |

- Existing pages: [Tools inventory evidence](tools-inventory-evidence.md),
  [toolset toggle contract](toolset-toggle-contract.md), route support and M4 above.
- Source corpus: Agent dashboard REST handler/helpers and optional-skill model;
  official Desktop caller/tests; Wing Tools/client/channel and nearest regressions.
- Missing slice: distinguish available-to-install catalog metadata from installed
  `/v1/skills` inventory, including profile targeting, grants, bounds and failures.
- Validation: source identities/citations, changed Markdown targets, independent
  contract/security review and `git diff --check`. No executable behavior changes,
  so no new tests or runtime test execution are required for this receipt.

The coordinator assigned this isolated worker/branch. The baseline [task index](../../TODO.md)
places this task in Next, with no inspection dependency and implementation ownership
unclaimed; its selection/install follow-up depends on this checkpoint. This is not
an assertion of a live GitHub lease or authority over another worker. Root and
area reference instructions were read before deep inspection. No credentials were
acquired, upstream files changed, services started, or Agent/Desktop tests executed.
The [Agent immutability boundary](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent)
is unchanged.

## Verdict: catalog exists upstream; unavailable as a qualified Wing operation

The official Desktop has a real profile-targeted optional-skills catalog read.
That is **not** an advertised, bounded, exact-grant discovery contract on Wing's
inspected API-server transport. Wing has no caller/model for this catalog read.
Do not infer discovery from `skills_api`, a bearer credential, `skills:read`,
installed inventory visibility, a matching REST hostname, or Desktop TypeScript types.
No operation/grant name is invented here to bridge the gap.

| Acceptance dimension | Supported source guarantee | Missing guarantee / disposition |
| --- | --- | --- |
| Exact operation | Dashboard/serve mounts `GET /api/skills/hub/official`; handler returns `{"skills": [...]}` ([handler][U1], [mount][U2]). | API-server capability table advertises installed `skills: GET /v1/skills`, not this hub route ([table][U3], [capability response][U4]). Different server surfaces are not interchangeable. |
| Schema/bounds | Row allowlist is `name`, `description`, `source`, `identifier`, `trust_level`, `repo`, `tags`, plus derived `category` and `installed` ([payload][U5], [handler][U1]). Local scan truncates descriptions to 200 characters ([scanner][U6]). | No versioned catalog envelope, row-count/page bound, tag/name/identifier length bound or strict response validation is established by this handler/`SkillMeta` ([model][U7]). A finite checkout is not a protocol limit. |
| Profile targeting | Explicit `?profile=<name>` selects the named profile's hub provenance lock; names are validated and missing names produce 404 ([lock helper][U8], [resolver][U9]). Catalog content itself is shared optional-skill metadata, not a per-profile catalog copy. | Omitted/blank/`current` means the backend's current profile ([current helper][U10]); it is not a safe inferred Wing identity. No echoed profile/incarnation/revision binds the response to a resource lifetime. |
| Exact grants | Dashboard HTTP middleware authenticates non-public `/api/` routes; session-header/legacy bearer handling is separate from the API-server key ([auth helpers][U11], [middleware][U12]). | The handler declares no per-operation required scopes/caller grants or Wing capability descriptor. Authentication and target-name resolution do not prove a caller is granted discovery for that profile. Do not reuse or acquire a dashboard token as a fallback. |
| Failure | Invalid named profile: 400; absent named profile: 404; unexpected handler exception: 502, with existing HTTP exceptions preserved ([resolver][U9], [handler][U1], [error wrapper][U13]). | Unreadable/corrupt hub lock becomes an empty installed map; unreadable skill files are skipped. Thus `installed: false`/missing row is not authoritative absence. Unexpected error detail interpolates exception text; bounded secret/path-free failure is not established. |

**Disposition:** evidenced unavailable operation for Wing at these pinned sources,
not a claim that Hermes has no skill discovery anywhere. Keep existing Tools,
Schedules and Connections reads independently gated; no UI, install, fallback
adapter or Agent changes follow from this receipt.

## Authoritative read trace and failure limits

1. [Handler][U1] reads `_installed_hub_identifiers(profile)`, enumerates
   `OptionalSkillSource().list_local()`, derives category from the identifier and
   marks `installed` by identifier membership. It returns metadata, not SKILL.md
   bodies, host paths, lock entries or a selected installation target.
2. [Optional source][U14] uses [`list_local()`][U25] → `_scan_all()`, not its network-aware
   `search()`/`fetch()` branches. The read scans local optional-skill frontmatter;
   it does not call the install pipeline. The `SkillMeta.path`/`extra` fields are
   not in the handler's allowlist. `trust_level: builtin` labels provenance, not
   execution safety, consent or permission to install.
3. [Lock helper][U8] passes an explicit named-profile lock path to `HubLockFile`,
   returning selected provenance fields internally. The [lock reader][U15] returns
   its empty shape on JSON/read errors ([list projection][U26]); the helper also
   catches other non-HTTP exceptions as `{}`. The route can therefore return 200 with all flags false
   when installation provenance is unreadable. It does not attest all installed
   skills or guarantee that a skill reported installed is still present/enabled.
4. [Scanner][U6] skips unreadable/undecodable files. Missing or partial local
   catalog and lock failures are not reported as separate degraded states. The
   [error wrapper][U13] logs unexpected exceptions and returns prefix + exception
   text; Wing must not display/store that raw detail. This is a contract limitation,
   not an exploit claim or a new security finding requiring activation.

### Nearest upstream and official Desktop tests (inspected, not run)

| Source/case | What it establishes in source | What it does not establish |
| --- | --- | --- |
| [Dashboard catalog test][U16], `test_lists_full_catalog_with_installed_flags` | Patched local metadata and patched installed map yield categories and true/false flags in `skills`. | No real two-profile lock isolation, size bound, grant/revocation check or failed-lock distinction; request omits profile. |
| [Unknown-profile regression][U17], `test_unknown_profile_is_the_scopes_404` | Includes this exact GET with `profile=no-such-profile`; expects 404 rather than a catch-all 500. | Not profile authorization, delete/recreate binding or concurrent A→B→A proof. |
| [Optional metadata tests][U18] | Repo-root-relative metadata and exclusion of nested support skills through source methods. | Not wire-schema validation or a complete/degraded-catalog receipt. |
| [Dashboard auth test][U19], `test_unauthenticated_api_blocked` | Middleware denial on other protected API routes. | Does not directly exercise this catalog's credential denial/revocation. |
| [Desktop catalog test][U20] | Mocked catalog hides already-installed rows/name collisions and renders available rows. | Not authoritative install/readback, exact grants, live profile routing or Wing parity. |

## Official Desktop outcome, without inheriting its authority

[Desktop `getOfficialSkills`][U21] passes a capability scope to its native API
bridge for this exact GET. [Scope helper][U22] carries connection/profile ownership;
its name does not mean an advertised Agent grant was checked. The
[Skills tab][U23] keys the query by that scope, uses a 60-second stale time and
`retry: false`, then filters already-installed identifiers and name collisions
before local query filtering. It renders optional catalog rows alongside the
installed list in Capabilities → Skills; this is the reference discovery outcome,
not proof that Wing's planned `/discover` route ships.

[Desktop row type][U24] describes category/description/identifier/installed/name/tags
at compile time. It does not validate server JSON or impose the missing bounds.
The tab consumes only `data` for this query and defaults absent data to `[]`;
that does not establish an explicit empty-versus-failed-catalog presentation.
Selection, detail/preview and install effects are deliberately not traced here;
the [selection/install follow-up](m4-discovery-selection-contract.md) separately
assesses that contract, consent, result/readback and failure/no-replay gaps without
executing an installation. Catalog availability grants no install authority.

## Wing caller and regression trace: installed inventory only

- [Tools composition](../../lib/features/tools/screens/tools_screen.dart):283–322
  has installed Skills and Toolsets tabs, not an optional-skills catalog. Its
  [refresh/owner gate](../../lib/features/tools/screens/tools_screen.dart):126–218
  captures channel/host/profile/status/selection/read authority and rejects stale
  actions. No `hub/official` caller exists in the inspected `lib/core/hermes/`,
  `lib/features/tools/` or `lib/router/` paths.
- [State authorization](../../lib/core/hermes/channel/hermes_channel_state.dart):210–214,
  270–284 requires the supported schema, exact installed route/method, every
  declared grant and supported query context for an endpoint marked profile-scoped.
  [Capability parser](../../lib/core/hermes/models/hermes_capabilities.dart):25–29,
  56–85, 119–126, 157–159 treats missing schema as 1 and absent scopes as empty,
  not as an invented discovery grant. Synthetic `skills:read` in regressions is
  not evidence that upstream implements that permission.
- [API client](../../lib/core/hermes/client/hermes_api_client.dart):91–105 expects
  installed `data`, caps entries at 128 and constructs
  [HermesSkill](../../lib/core/hermes/models/hermes_skill.dart):4–30 (bounded
  name/description/category only). It cannot consume `skills` with discovery
  identifiers, tags, provenance and installed flags as an equivalent model.
  Do not retarget its URL or silently decode the other envelope as empty inventory.
- [Profile URI policy](../../lib/core/hermes/client/hermes_api_config.dart):132–151
  preserves an enrolled `/p/<profile>` identity and rejects a mismatch; otherwise
  it adds explicit `profile`. This is a client rule, not proof that the API server
  implements dashboard query routing for discovery.
- [Shared inventory bootstrap](../../lib/core/hermes/channel/api_channel/hermes_api_channel_inventory.dart):16–66
  and [refresh](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart):313–371
  independently gate supported installed reads; refresh fences client, connection,
  profile-selection and request generations. There is no catalog write/replay.

Nearest Wing regression sources, **not executed by this docs-only task**:

| Public seam | Existing regression | Evidence ceiling |
| --- | --- | --- |
| API decode | [API tests](../../test/core/hermes/hermes_api_test.dart):1521–1534, `skills inventory bounds the number of returned skills` | Installed `data` count bound, not discovery schema support. |
| Channel refresh | [Channel tests](../../test/core/hermes/channel/hermes_api_channel_test.dart):1745–1783, `loadToolInventory refreshes exact advertised read routes` | Exactly installed skills/toolsets GETs, no hub request. |
| Profile ownership/failure | [Channel tests](../../test/core/hermes/channel/hermes_api_channel_test.dart):763–841, 880–963, late-selection and failed-refresh cases | Stale profile cannot replace current skills; failed new-profile reads do not reuse old inventory. Synthetic query-profile fixtures, not real upstream isolation. |
| Tools UI denial/recovery | [Tools tests](../../test/features/tools/tools_screen_test.dart):62–84, 633–766 | Only supported inventory tabs; bounded refresh error; failed reads, missing grants and unavailable inventory do not display stale metadata as empty/success. Not a discovery denial oracle. |

## Closeout and update triggers

This completes a bounded **contract-gap inspection**, not M4-DISCOVER or platform
qualification. No platform, native UI, browser, provider or live Agent was exercised.
No executable regression was added: behavior is unchanged. Existing inventories
are not frozen or requalified by this receipt.

Revisit when an unmodified connected Agent advertises the exact discovery read and
its authorization/profile contract, catalog schema/bounds/failure semantics change,
or Wing adds a qualified caller. Re-pin sources and repeat independent review;
do not carry this result onto an uninspected runtime. Future offline acceptance
must distinguish denied/unavailable/failed/empty/partial catalog, preserve exact
owner identity, and treat cached or late metadata as non-authoritative after
identity/grant loss. These are acceptance requirements, not invented wire fields.

Pending live: target-specific authenticated discovery/read-denial, profile isolation
and accessible native journeys **only after** an eligible authoritative contract
exists. No credentials, provisioning or operation activation is authorized here.
Install, removal, MCP, memory, scheduling and host/platform operations retain their
own independent gates and evidence requirements.

Independent contract/security review: a fresh-context `reviewer` inspected this
receipt against the pinned handler/helpers/model/tests, Desktop caller and Wing
caller/regressions. **Approved for bounded source-only evidence; no findings or
corrections required.** It confirmed the authentication/grant distinction,
profile targeting, bounds and lock-failure ambiguity, and the native/live ceiling.
This is task review, not an independent security audit or live acceptance.

## Pinned upstream sources

[U1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/skills.py#L123-L144
[U2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server.py#L1032-L1034
[U3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L67-L103
[U4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L2536-L2576
[U5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/skills.py#L78-L82
[U6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tools/skills_hub_official.py#L266-L279
[U7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tools/skills_hub_models.py#L26-L38
[U8]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_profiles.py#L464-L480
[U9]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_profiles.py#L190-L199
[U10]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_profiles.py#L31-L34
[U11]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server.py#L452-L463
[U12]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server.py#L696-L726
[U13]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/_common.py#L87-L101
[U14]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tools/skills_hub_official.py#L34-L68
[U15]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tools/skills_hub.py#L274-L303
[U16]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_dashboard_admin_endpoints.py#L653-L687
[U17]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_web_unknown_profile_404.py#L1-L31
[U18]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/tools/test_skills_hub.py#L1013-L1048
[U19]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_web_server.py#L1761-L1779
[U20]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/capabilities/index.test.tsx#L424-L484
[U21]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/skills.ts#L99-L107
[U22]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/client.ts#L197-L253
[U23]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/capabilities/skills/skills-tab.tsx#L82-L124
[U24]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/types/hermes.ts#L1196-L1206
[U25]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tools/skills_hub_official.py#L143-L146
[U26]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tools/skills_hub.py#L349-L350
