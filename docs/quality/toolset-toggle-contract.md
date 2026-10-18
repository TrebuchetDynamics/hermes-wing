# One toolset toggle: contract trace

Status: **source inspection only; Wing enable/disable remains unavailable**.
Task: `DOC-M4-MCP-CONTRACT`; outcome: `M4-MCP` remains partial.
Start with the [existing inventory receipt](tools-inventory-evidence.md) for the
read-only journey. This slice traces the built-in `web` toolset, not MCP
configuration, installation, secrets, provider setup or arbitrary commands.
No operation was activated and no credential or Agent state was acquired.

## Identity and evidence boundary

Pins obtained with `git rev-parse HEAD` in each inspected reference:

| Source | Revision | Scope |
| --- | --- | --- |
| Wing task baseline | `25c7ae24392ad22f9442111e1a7014a9f0fa09eb` | Current callers, models and nearest tests; documentation-only change. |
| Hermes Agent | `158fd638da1629c8e62caf9ade1515d162def8ab` | Read-only authoritative handler/model and tests. Inspected checkout was clean. |
| Official Desktop (`apps/desktop/` in Agent) | `158fd638da1629c8e62caf9ade1515d162def8ab` | Same repository/revision, not a separate implementation authority. |

The task worktree has no `hermes-agent/` entry; the permanent reference checkout
was inspected read-only, without copying, linking, patching or executing it.
Upstream links below are immutable revision permalinks. Wing local links refer to
the baseline above. These are checkout findings, not a latest-release claim or a
capability advertisement by a connected Agent.

## Official Desktop outcome and exact write

The official [Tools tab][desktop-tab] (lines 80–103) offers an on/off
switch per toolset, names the action, optimistically changes the scoped cache and
reverts/notifies on rejection. Its [footer][desktop-footer] (184–196) says changes
apply to new sessions.
The [Desktop regression][desktop-test] (129–142) clicks the enabled Web Search
switch and expects `setToolsetEnabled('web', false)`. This is the reference outcome,
not an executed Wing or Desktop journey in this task.

The [Desktop API helper][desktop-api] (12–34) sends
`PUT /api/tools/toolsets/{encodeURIComponent(name)}` with body `{enabled}` and
`capabilityScoped(profile)`. The [scope helper][desktop-scope] (197–249) supports an
explicit connection/profile pair; the [scope regression][desktop-scope-test]
(163–176) verifies both reach the bridge on reads and writes. Connection identity
is Desktop routing metadata, not a grant. Wing must not copy Electron's privileged
bridge or reuse an Agent data-plane credential as a dashboard credential.

For the concrete built-in name `web`, the authoritative contract is:

| Concern | Observed guarantee / limit |
| --- | --- |
| Handler and model | Agent [tools router][handler], `toggle_toolset` (280–342), and [ToolsetToggle][model] (491–493): required `enabled: bool`, optional body `profile`; optional query `profile`. No revision, incarnation or idempotency field. |
| Toolset identity | `_require_known_toolset` (205–210) accepts only the effective configurable set; unknown names raise HTTP 400. `web` is an exact registry key, not its translated label or an individual resolved tool name ([registry][registry], 66–68). |
| Profile identity | Handler uses `body.profile or profile`: a nonempty body wins over the query; disagreement is not rejected. [`_is_current_profile`][current-profile] (31–34) treats absent/empty/`current` as the serving process's profile; explicit names resolve through validation/existence checks (400/404). Home and secret scope are bound for the work, not a global profile-selection command ([profile helpers][profiles], 190–200, 243–322). No profile-incarnation precondition is exposed. |
| Platform identity | For `web`, `_toolset_configuration_platform` selects `cli`, not `api_server` ([registry][registry], 145–149). The handler has no caller-selected platform parameter. It reads the resolved CLI selection, adds/discards `web`, and saves it. This is not a write to Wing's gateway inventory platform. |
| Authentication / grant | The route is [mounted][mount] in the dashboard/`serve` API (1035) and falls under its `/api/` [authentication middleware][auth] (697–730). The loopback mode checks the dashboard session token; gated mode delegates to the verified dashboard bearer/cookie session ([gated auth][gated-auth], 153–205). The [public allowlist][public-paths] does not include this route. The handler/model expose **no exact per-toolset write grant** and no `required_scopes`/`granted_scopes` advertisement for Wing. Do not invent `tools:write`, infer authority from loopback or transfer the `/v1` bearer contract. |
| Persistence / siblings | `_save_platform_tools` writes the selected platform list, preserves existing non-configurable/non-default entries, records known toolsets and reconciles `agent.disabled_toolsets` for enabled selections ([resolver/save][save], 741–780). It also clears the `no_mcp` sentinel; this shared-helper side effect prevents assuming a strictly isolated one-bit edit. No MCP operation is authorized by this trace. |
| Conflict behavior | `config_write_scope` holds the profile scope and process-local mutation lock around the read/modify/save ([write scope][write-scope], 23–37; [lock definition][mutation-lock], 892). `save_config` has another process-local `RLock` and atomic replacement ([config lock][config-lock], 159–164; [save_config][config-save], 2509–2553). These are not expected-revision checks shared across CLI/API processes. No stale-edit conflict response or durable replay receipt is exposed by this operation. Serialized calls still have no client-staleness precondition. |
| Result / activation | Response is `{ok, name, platform, enabled, post_setup_started}` after saving; it has no resulting revision, effective-session readback or reload/restart acknowledgement. Enable may separately start best-effort provider post-setup; failure to spawn does not fail the toggle ([handler][handler], 313–342). A retry can revisit that path: setting a boolean is not durable request deduplication. Persistence, setup completion and active-session availability must not be conflated. |

For `web`, the nearest enable test expects no pending post-setup/spawn at its
fixture state; it is **not** a universal no-side-effects promise for all toolsets.
No post-setup implementation, command execution, installation or MCP mutation is
part of this task.

## Why inventory does not authorize this write

The API-server [capability document][capabilities] (2536–2575) publishes endpoint
method/path descriptors; its [endpoint table][endpoint-table] (78–95) includes
`toolsets: GET /v1/toolsets`, not the Desktop PUT. The inspected advertisement
contains bearer authentication but no toolset grant/profile-context fields. It
cannot authorize a different route merely because the same name appears there.

The authenticated [inventory handler][inventory] (2967–2994) resolves
`_get_platform_tools(config, 'api_server', include_default_mcp_servers=False)` and
returns `{object: 'list', platform: 'api_server', data: [...]}` with enabled,
configured and resolved names. Desktop's CLI selection is a **different resource**;
a CLI save is not proof that this API-server inventory or its sessions changed.
The [resolver][save] (590–677) also applies suppression and platform-specific
selection. Inventory metadata, configured presence and discovered tool names are
not write authorization, effective runtime readiness or consent to setup.

Wing's current chain is deliberately read-only:

- [Channel gate](../../lib/core/hermes/channel/hermes_channel_state.dart),
  213–216, 264–276: supported capability schema, exact GET/path, all declared
  grants, and supported query context when declared profile-scoped. Missing
  scope declarations do not synthesize a grant.
- [API client](../../lib/core/hermes/client/hermes_api_client.dart), 106–119:
  `listToolsets` performs the scoped GET and decodes bounded metadata.
  [Profile URI handling](../../lib/core/hermes/client/hermes_api_config.dart),
  132–151: explicit query scope unless an enrolled path-profile already binds
  it, in which case a different profile is rejected. This does not prove that
  upstream `/v1` supports query-based named-profile selection.
- [Reload caller](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart),
  312–366: stable connected owner required; profile/client/connection/selection/
  request generations fence publication. Refresh is a read, not mutation replay.
- [Inventory model](../../lib/core/hermes/models/hermes_toolset.dart), 4–52:
  only bounded display metadata, including a normalized/truncated name; no
  platform, write grant or revision. A display-safe name is not a verified
  mutation identity.
- [Tools screen](../../lib/features/tools/screens/tools_screen.dart), 517–726:
  local search and resolved-tool disclosure, no enable/disable action.
  [Readiness policy](../../lib/core/hermes/policy/hermes_surface_readiness.dart),
  252–260: dedicated scoped write contracts are still required.

**Verdict:** a Desktop/dashboard toggle exists upstream, but an exact advertised,
authorized, profile/platform-bound and conflict-safe toolset toggle is absent
from Wing's connected-Agent contract at these pins. Do not add a PUT caller, native
RPC/CLI fallback, direct-file edit, shadow toolset selection or optimistic Wing
write state on this evidence. [Living API](../adr/api-and-state.md) and
[security](../adr/security-and-privacy.md) decisions govern; historical parity
wording does not restore retired management adapters.

## Nearest tests: inspected, not executed

| Source | What the existing oracle covers | What it does not establish here |
| --- | --- | --- |
| [Desktop capability tests][desktop-test], 129–165; [scope tests][desktop-scope-test], 163–176 | Web switch-off calls the named helper; explicit connection/profile metadata reaches mocked bridge. | Live authentication, backend conflict handling, Wing parity. |
| [Toggle handler tests][toggle-tests], 49–156 | Enable can start setup, disable does not, spawn failure still returns success, and `web` at this fixture has no pending setup. | Revision conflicts, stale/deleted/recreated profiles, durable retries or current-session activation. |
| [Shared save test][save-test], 242–265 | Selection removes an unchecked built-in and preserves existing MCP/custom names with save patched. | Cross-process lost-update protection or end-to-end profile isolation. |
| [Platform route test][platform-test], 3137–3172 | Restricted toolsets write their own platform, not CLI, and read back via dashboard inventory. | CLI/API-server platform equivalence for `web`. |
| [API-server tests][inventory-tests], 937–1049 | Advertised read endpoint and mocked resolved tools/enabled/configured envelope. | Mutation availability or write grants. |
| [Wing screen tests](../../test/features/tools/tools_screen_test.dart), 695–765; [decoder tests](../../test/core/hermes/hermes_api_test.dart), 1536–1638 | Denied/unsupported inventories hide stale names; public metadata/counts are bounded. | A mutation seam, native/live Agent qualification or exact unmodified write identities. |

No product behavior changed, so no test was added and no upstream/Wing product
suite was run. Evidence is limited to offline source/link/whitespace verification
and independent contract/security review; exact final results belong to the task
report. No native app, browser, Android, provider or live service was exercised.

## Revisit trigger and remaining qualification

Revisit when an unmodified Agent advertises an exact toggle with its real grants,
explicit current profile **and platform** identity, authoritative concurrency check,
and bounded persistence/activation/retry outcomes. Validate the operation's setup
side effects and require separate consent where applicable; do not implement a
client-side lock or read-before-write as a substitute. Trace changed handler,
model, auth path, shared save helper and tests again, not just the route name.
Discovery alone must never open a write gate.

A future bounded implementation needs independent contract/security review plus
regressions for denial, wrong/stale owner, profile recreation, concurrent edits,
uncertain response/retry and no reconnect replay. Only after those contracts exist
can a separately authorized isolated native/live target qualify enable, disable
and exact authoritative readback, distinguishing saved state from new-session
activation. Those future proofs do not hold this documentation slice. MCP config
read is covered separately by the [MCP configuration-read trace](mcp-config-read-contract.md)
(`DOC-M4-MCP-CONFIG-CONTRACT`); neither trace authorizes MCP installation, secret
access or arbitrary commands. See [route status](../product/routes.md)
and [M4-MCP status](../product/hermes-desktop-parity.md#statuses).

[desktop-tab]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/capabilities/toolsets/toolsets-tab.tsx#L80-L103
[desktop-footer]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/capabilities/toolsets/toolsets-tab.tsx#L184-L196
[desktop-test]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/capabilities/index.test.tsx#L129-L165
[desktop-api]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/toolsets.ts#L12-L34
[desktop-scope]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/client.ts#L197-L249
[desktop-scope-test]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/hermes-capability-scope.test.ts#L163-L176
[handler]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/tools.py#L205-L342
[model]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_models.py#L491-L493
[registry]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/tools_config.py#L66-L149
[profiles]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_profiles.py#L190-L322
[current-profile]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_profiles.py#L31-L34
[auth]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server.py#L697-L730
[mount]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server.py#L1035
[mutation-lock]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server.py#L892
[gated-auth]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/dashboard_auth/middleware.py#L153-L205
[public-paths]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/dashboard_auth/public_paths.py
[save]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/tools_config.py#L590-L780
[write-scope]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/_common.py#L23-L37
[config-lock]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/config.py#L159-L164
[config-save]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/config.py#L2509-L2553
[capabilities]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L2536-L2575
[endpoint-table]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L78-L95
[inventory]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L2967-L2994
[toggle-tests]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_web_routers_tools_install_on_enable.py#L49-L156
[save-test]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_tools_config.py#L242-L265
[platform-test]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_web_server.py#L3137-L3172
[inventory-tests]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server.py#L937-L1049
