# One MCP configuration read: contract trace

Task: `DOC-M4-MCP-CONFIG-CONTRACT`. **Source inspection only; MCP configuration
inspection remains unavailable in Wing.** `M4-MCP` stays partial. Start with the
[toolset toggle trace](toolset-toggle-contract.md), [inventory receipt](tools-inventory-evidence.md)
and [current route status](../product/routes.md). This slice selects the structured
configured-server read **`GET /api/mcp/servers?profile=<profile-name>`**, not raw
configuration editing, MCP discovery, installation, probing, OAuth or tool execution.
No actual MCP configuration, credentials or runtime state was read.

## Source pins and docs map

Pins obtained with `git rev-parse HEAD` in each inspected checkout/subtree:

| Source | Revision | Evidence ceiling |
| --- | --- | --- |
| Wing task baseline | `2c756874562fbe80f99b75cc7ac32586dabfdd3d` | Current caller/gate and nearest tests; documentation-only change. |
| Unmodified Hermes Agent reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Read-only handler, helpers, auth and tests; clean checkout. |
| Official Desktop (`apps/desktop/` in Agent) | `158fd638da1629c8e62caf9ade1515d162def8ab` | Same repository/revision; not a second runtime authority. |

The isolated task worktree has no `hermes-agent/` entry. The permanent reference
was inspected read-only, without copying, linking, changing or executing it.
These pins describe those checkouts, not the latest release or a connected Agent's
capability advertisement. The coordinator assigned this task/branch/worktree;
this receipt does not assert a fresh live tracker lease or ownership release.

Docs map before editing:

- Existing owners: receipts above, [M4 status](../product/hermes-desktop-parity.md#statuses),
  [accepted roadmap](../../ROADMAP.md#flutter-port-execution-roadmap),
  [API/state](../adr/api-and-state.md), [security](../adr/security-and-privacy.md)
  and [Agent immutability](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent).
- Source corpus: one REST list handler/summary, config loader, profile/auth seams,
  plugin merge, Desktop consumer/model and nearest tests; Wing Tools public seams.
- Missing proof: exact advertised read/grant, confirmed profile/incarnation envelope,
  fully sanitized output and authoritative work/response bounds.
- Chosen change: this receipt and a backlink from the toolset trace. Validate pins,
  source/Markdown targets, independent contract/security review and whitespace.
  No behavior change or new test.

## Exact read and acceptance comparison

| Concern | Observed source contract | Limit / Wing disposition |
| --- | --- | --- |
| Handler and model | Agent [list handler][handler]:94–107 accepts optional query `profile`, reads `_get_mcp_servers()`, merges plugin sources and returns `{servers: [...]}` sorted by name. The [summary builder][summary]:85–106 emits `name`, `transport`, `url`, `command`, `args`, `env`, `auth`, `enabled`, `tools`, `source`, `plugin`. No FastAPI response model is declared here. | This is a configuration-derived list, not a resolved tool inventory or runtime connection result. Desktop's [TypeScript interface][desktop-model]:1747–1757 describes only a subset and types `tools` as `string[] \| null`; the handler actually passes the config value through, with no read-side validation of that field. TypeScript does not filter or validate received JSON. |
| Profile identity | Handler's `_secret_scoped(profile, _read)` binds [home plus secret scope][handler]:42–56 inside its worker. [Profile resolver][profiles]:190–199, 277–320 validates explicit names and existence (400/404), binds the requested home and secrets, then restores context. [_is_current_profile][current-profile]:31–34 treats absent/blank/`current` as the serving process's profile. | Query identity is explicit when supplied; it is not a caller-specific profile grant. No profile ID, incarnation, revision or selected-home confirmation is returned. Same-name recreation is not fenced. This dashboard query contract must not be confused with `/v1` path-profile routing or a global `profile use` side effect. |
| Exact authorization | Route is [mounted in dashboard/serve][mount]:1030. [API middleware][auth]:697–730 enforces dashboard session-token authentication when the OAuth gate is inactive; with that gate active, [gated middleware][gated-auth]:153–205 verifies provider-backed native bearer or cookie/refresh sessions. [Public paths][public-paths] do not include this read. | The handler exposes **no exact MCP configuration-read grant** or per-profile caller permission. The inspected [messaging API advertisement][capabilities]:67–103 includes `/v1/toolsets`, not `/api/mcp/servers`; it advertises no MCP-config read operation. Do not invent `mcp:read`/`tools:read`, infer permission from loopback, or reuse an API-server bearer as a dashboard credential. Authentication is not an advertised Wing operation/grant. |
| Output redaction | [_redact_mcp_env][summary]:74–82 masks every truthy env value via `redact_key(str(v))`, leaves falsy values empty and uses `***` on per-value exceptions. [redact_key][redact-key]:2916–2919 delegates to [mask_secret][mask-secret]:636–644: strip display controls; below 12 characters use `***`, otherwise retain the first four and last four characters. Headers themselves are omitted; an Authorization header can produce the `auth: header` marker. | Env **names** remain visible; masking is partial disclosure, not secret-free output. URL, command, args, tool selection, server/plugin names and other returned values have no corresponding redaction here. URLs/args can carry private endpoints, host paths or credential material. Do not acquire sample responses, publish secret prefixes/suffixes or copy this output into diagnostics/receipts. This source trace is not a vulnerability reproduction or a safe-output qualification. |
| Bounds and work | Handler returns all merged entries; `_get_mcp_servers` ([config accessor][config-accessor]:209–214) uses merged, env-expanded `load_config()`. The [loader][config-load]:2357–2437 reads/parses config without an explicit file-size cap and expands values. Summary copies the args list and passes `tools` through. | No endpoint-specific pagination, server-count cap, field/aggregate byte cap, raw query-profile length cap or overall deadline is declared in this chain. Resolved named-profile IDs do have a [64-character grammar bound][profile-grammar]:320, enforced by [name validation][profile-validation]:386–397 after trimming; this is not a raw-input or response budget. Sorting and returning a list is not bounded work; env masking does not bound names or other fields. Client inventory limits for `/v1/toolsets` do not constrain this response. |
| Meaning and side effects | [Merge helper][merge]:12–29 keeps dictionary config entries, adds filtered portable-plugin servers only for names absent from config, and attaches plugin ownership; exceptions in plugin discovery/merge are swallowed. `enabled` uses [mcp_server_enabled][enabled]:140–144 (missing/null/unparseable defaults on). | Presence/enabled is not health, discovered tools, OAuth success or effective-session availability. The GET handler does not directly probe/spawn an MCP server, install it, save its configuration or reload sessions. But this is **not a proven inert metadata-only request**: profile scope may hydrate external secret sources and activate process-wide multiplexing. That [activation][launch-policy]:33–51 freezes the launch environment and makes unscoped secret reads fail closed; request-context restoration does not undo it. The loader ensures home/creates good-config backups ([loader][config-load]:2376–2406); merge calls [plugin discovery/load][plugins]:1824–1829. No zero-external-effect guarantee is inferred or activated. |
| Failure and consistency | Missing/non-dictionary `mcp_servers` becomes `{}`; non-dictionary entries are filtered by merge. Loader can return a last-known-good/default `FailedConfigRead` on read/parse failure ([loader][config-load]:2390–2418); this handler does not inspect its error marker. Plugin failure may leave config-only results. | Empty/partial/stale results are not authoritative proof of no configuration. There is no response revision/completeness marker or snapshot spanning config and plugin discovery. No operation-specific bounded error model is declared. A read result never authorizes a later write or automatic reconnect replay. |

**Verdict:** the selected Agent/dashboard read exists, but a bounded, fully
sanitized, exact-authorized and owner-confirmed MCP configuration read is absent
from Wing's connected-Agent contract at these pins. Keep it unavailable. Do not
add a dashboard GET fallback, generic config reader, native RPC/CLI bridge,
Agent-file access or shadow MCP inventory based on this inspection.

## Official Desktop consumer, not an editor-read parity claim

[Desktop list helper][desktop-api]:70–75 calls `hermesApi` with `profileScoped()`
and `/api/mcp/servers`. [Scope helpers][desktop-scope]:75–82, 191–194 attach the
ambient selected profile and registry connection routing tag before invoking the
native bridge. Those are routing metadata, not grants or server-confirmed owner
identity.

One actual [consumer][desktop-consumer]:24–64, 241–257 loads configured names for composer
suggestions, including disabled servers, caches them for five minutes, and excludes
already configured names from suggestions. This supports the configured-server
read's existence; it is not a Wing workflow or live qualification. Suggestion
invocation, installation and OAuth are expressly outside this read-only trace.

Do not mistake this helper for the main MCP JSON editor's read. The current
[Capabilities controller][desktop-editor]:78–104 derives its servers from
`useHermesConfigRecord(profile)`/`getServers(config)`, a broader configuration
path. That path is not qualified here, nor is the separate `mcp.servers.*` RPC
summary interchangeable with this REST response. No permission to expose raw
configuration or a general config-key/path selector follows from either.

## Nearest tests and Wing caller absence

All tests below were **inspected, not executed**. No executable behavior changed.

| Source | Existing oracle | Evidence ceiling |
| --- | --- | --- |
| [Dashboard test][read-test]:33–50, `test_stdio_env_is_redacted_on_read` | Creates synthetic stdio config, GETs the list and asserts env output differs from the supplied value. | Does not assert full secrecy, URL/args redaction, bounds, denial or profile recreation; not a comprehensive safe-output oracle. |
| [Named-profile list test][profile-test]:247–268, `test_mcp_list_expands_url_ref_from_profile_secret_scope` | Two isolated homes with conflicting variable sources; named-profile GET returns that profile's expanded URL. | Not a caller-grant test, all-field redaction or A→B→A result-ownership oracle. It confirms expansion, not that expanded values are safe to return. |
| [Multiplex E2E source][scope-test]:118–132, `test_scoped_sibling_route_resolves_each_profiles_secret` | Same-host A→B→A list read checks own env canary/full value or retained suffix. | Harness starts services/sessions and MCP subprocesses; **not run or authorized here**. This isolation oracle is not full redaction or bounded-read proof. |
| [Desktop suggestion tests][desktop-test]:1–117 | Pure catalog-index/keyword/host matching and suggestion count cap. | Not a live list read, profile-auth test or server-response bound; the two-suggestion cap does not bound MCP config output. |
| [Wing inventory decoder tests](../../test/core/hermes/hermes_api_test.dart):1536–1610; [denial tests](../../test/features/tools/tools_screen_test.dart):695–765 | `/v1/toolsets` item/field limits and hidden stale inventory when exact read authority is missing. | Adjacent inventory evidence only, not MCP configuration parsing, authorization or Wing MCP parity. |

At the Wing baseline, source search across `lib/core/hermes/`, `lib/features/`
and `lib/router/` finds no MCP server-list/config caller or response model for
`/api/mcp/servers`, `listMcpServers`, `McpServerSummary` or `mcp_servers`.
The [channel read gate](../../lib/core/hermes/channel/hermes_channel_state.dart):213–216,
264–276 authorizes only exact advertised inventory reads here. The
[client](../../lib/core/hermes/client/hermes_api_client.dart):106–119 decodes
`/v1/toolsets`, whose [model](../../lib/core/hermes/models/hermes_toolset.dart):4–52
retains bounded display metadata, **not** MCP URLs, env, commands or arguments.
The [reload caller](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart):313–366
fences publication by client/profile/connection/selection/request generations.
Those fences cannot create a missing MCP contract.

The [Tools screen](../../lib/features/tools/screens/tools_screen.dart):17–20
explicitly defers MCP mutation; its current inventory is not a config viewer.
The [fixed web read RPC seam](../../lib/core/hermes/client/hermes_web_read_rpc.dart):35–60
offers ping/session IDs, not arbitrary MCP dispatch. [Readiness policy](../../lib/core/hermes/policy/hermes_surface_readiness.dart):252–260
keeps mutations unavailable without dedicated scoped contracts. Exact read
availability would still not imply installation, config write, toggling or command
execution authority.

## Revisit trigger and remaining qualification

Re-pin and re-trace when an unmodified Agent advertises an exact MCP config read
with its real required/granted authorization and supported explicit profile
context. Require a bounded, allowlisted, secret/path/private-origin-safe response
and distinguish incomplete/unreadable state from empty results. Confirm returned
owner identity and stale-owner/profile-recreation handling; review secret-source,
backup and plugin-discovery effects rather than assuming GET is inert. Trace
handler/model, scope/auth, loader/merge/redaction, Desktop consumer and Wing seam
again. These are admission requirements, not invented callable fields or grants.

A separately admitted implementation needs focused denial, bounds/redaction,
wrong/stale-owner and late-result regressions. Only after a suitable contract
exists can a separately authorized disposable native/live target qualify an
accessible read/refresh, auth denial and profile isolation/recreation. No native
app, browser, physical Android/device, live auth, provider or Agent operation was
exercised here; those future checks do not block this offline documentation slice.
MCP install/write/probe/OAuth and arbitrary commands remain excluded, not implicit
follow-ups authorized by this receipt.

Validation for this documentation-only change: checkout pins, source trace,
Markdown/source target checks, independent fresh-context contract/security review
and `git diff --check`; exact final results are recorded in the task report.
Independent fresh-context `reviewer` found no blocking contract/security issues;
its three minor source/citation clarifications (profile-name bound, persistent
multiplex activation and test-file line range) were verified and incorporated.
This review is not runtime acceptance.
No tests were added or product/upstream suites executed. The existing
[inventory receipt](tools-inventory-evidence.md) was inspected only; its past
execution is not a fresh result for this candidate.

[handler]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/mcp.py#L42-L107
[summary]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_mcp.py#L74-L106
[profiles]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_profiles.py#L190-L320
[current-profile]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_profiles.py#L31-L34
[mount]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server.py#L1030
[auth]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server.py#L697-L730
[gated-auth]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/dashboard_auth/middleware.py#L153-L205
[public-paths]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/dashboard_auth/public_paths.py
[capabilities]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L67-L103
[config-accessor]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/mcp_config.py#L209-L214
[config-load]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/config.py#L2357-L2437
[redact-key]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/config.py#L2916-L2919
[mask-secret]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/agent/redact.py#L636-L644
[merge]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/mcp_rpc_helpers.py#L12-L29
[enabled]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tools/mcp_tool_common.py#L140-L144
[plugins]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/plugins.py#L1824-L1829
[desktop-api]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/mcp.ts#L70-L75
[desktop-model]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/types/hermes.ts#L1747-L1757
[desktop-scope]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/client.ts#L75-L194
[desktop-consumer]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/suggestion-providers/mcp.ts#L24-L257
[desktop-editor]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/capabilities/mcp/use-mcp-servers.ts#L78-L104
[read-test]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_dashboard_admin_endpoints.py#L33-L50
[profile-test]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_web_server_profile_unification.py#L247-L268
[scope-test]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/e2e/core/security/test_profile_secret_scope.py#L118-L132
[desktop-test]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/suggestion-providers/mcp.test.ts#L1-L117
[profile-grammar]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_constants.py#L320
[profile-validation]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/profiles.py#L386-L397
[launch-policy]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/launch_profile_policy.py#L33-L51
