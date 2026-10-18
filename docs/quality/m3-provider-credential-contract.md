# M3 existing-profile credential replacement contract recheck

Source-only evidence for `DOC-M3-PROVIDER-CONTRACT`. Start with the
[required Agent-owned mutation contract](../adr/api-and-state.md#required-agent-owned-mutation-contract).
**Replacement remains unavailable; this report does not enable or qualify any
provider operation.** Current Wing Set/Remove/Validate shapes cannot establish
that contract. Exact route/grant checks are necessary, not sufficient. See the
[separate removal trace](m3-provider-removal-contract.md) for env-key deletion,
pool-index removal, disconnect, failure receipts and unknown-outcome gaps.

## Scope and source identities

Read-only handler/model → nearest upstream test → Wing client/channel/widget
trace. No credential acquisition, provider request, inference, restart, Agent edit
or compatibility operation was performed. Only this quality document changes.
The coordinator's task slot was running for this task, worktree and baseline at
entry; no other task was selected or adopted.

Pins obtained with `git rev-parse HEAD` in Wing and `git -C <reference> rev-parse
HEAD` for Agent and its `apps/desktop` subtree:

| Inspected source | Commit | Evidence ceiling |
| --- | --- | --- |
| Wing task baseline | `43e229ceace200a49ebd7f99628d21a887523566` | Live caller and regression source; no tests executed here. |
| Read-only Hermes Agent reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Handler/model/test source at this checkout, not installed-runtime behavior. |
| Official Desktop subtree in that Agent reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Product interaction reference only; not evidence that Wing has its authority. |

The inspected upstream implementation/test files had no local modifications.
Upstream links below are immutable GitHub source links at that pin. Wing links
are repository-local; line ranges describe the baseline above. Recheck on source
or ADR drift rather than repinning old conclusions without another trace.
The [superseded provider plan](../superpowers/plans/2026-07-14-milestone2-providers-models.md)
explains the retained request shapes; it is not proof of a shipped Agent API.
The ADR's older reference/runtime pins are historical findings, not these pins.

## Authoritative upstream trace

### External Agent API is not Desktop's administration API

- [API-server capability table, lines 67–102](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L67-L102)
  advertises `/v1/models`, `/api/model/options` and session model locking, not
  Wing's `/api/providers`, credential Set/Remove/Validate or `/api/models/assignment`.
  `admin_config_rw` is false. The
  [capability handler, lines 2537–2575](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L2537-L2575)
  emits that table; run-submission idempotency there is not provider idempotency.
- Nearest [API capability regression, lines 939–963](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server.py#L939-L963)
  checks read/model-options and run contracts. It does not establish an
  existing-profile credential mutation contract.
- Official Desktop's [provider settings, lines 30–34 and 80–96](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/settings/providers-settings.tsx#L30-L96)
  compose env-credential UI. Its [save/clear lifecycle, lines 106–174](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/settings/env-credentials.tsx#L106-L174)
  saves values and confirms deletion separately. Its
  [typed API, lines 204–263](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/config.ts#L204-L263)
  uses `/api/env` and `/api/providers/validate` through the Desktop bridge.
  These are different contracts, not fallback names for Wing's external routes.

### Current secret writers and probes do not replace one selected credential

| Upstream authority | Handler/model and nearest tests | Supported source behavior / missing ADR guarantee |
| --- | --- | --- |
| Desktop/serve env save and remove | [EnvVarUpdate/Delete models, lines 15–28](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_models.py#L15-L28); [PUT handler, lines 328–353](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/config_env.py#L328-L353); [DELETE handler, lines 1035–1050](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/config_env.py#L1035-L1050); [lifecycle tests, lines 118–235](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_credential_lifecycle.py#L118-L235) | Input is env key/value and optional profile, not selected credential ID, profile incarnation, expected revision or idempotency key. Tests exercise mirror rotation and pool materialization, not exact-ID replacement or durable replay. |
| Unified lifecycle behind env save/remove | [lifecycle implementation, lines 49–221](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/credential_lifecycle.py#L49-L221); [cache-delete test, lines 92–107](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_credential_lifecycle.py#L92-L107) | Save writes env, rotates value-matched config mirrors, unsuppresses that env source and loads provider pools. Remove prunes that env source across pools, suppresses it, clears affected model caches and scrubs matching mirrors; other-source pool entries are retained by the prune. Auth-store locking in the prune is not an expected-revision transaction across these writers. These deliberately broader effects cannot be relabeled selected-ID replacement/removal. |
| Native `model.save_key` / `model.disconnect` | [declared params/results, lines 84–110](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/contracts/profiles_vault_complete_foreign_subagents.py#L84-L110); [handlers, lines 372–446](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/methods_complete.py#L372-L446); [save-key tests, lines 17437–17520](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/tui_gateway/test_tui_gateway_server.py#L17437-L17520) | Save uses the provider's first registered env variable and the same lifecycle; it returns an inventory row with `authenticated`, not a revision-bound remote validation receipt. Disconnect removes every provider env key and clears provider auth including OAuth/pool state. Neither declares the required exact-ID/revision/idempotency inputs. No Wing RPC substitution is admitted. |
| CLI auth add/remove/status | [add, lines 348–412](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth_commands.py#L348-L412); [remove, lines 563–589](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth_commands.py#L563-L589); [status, lines 665–691](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth_commands.py#L665-L691); [manual-add test, lines 93–115](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_auth_commands.py#L93-L115); [remove test, lines 686–734](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_auth_commands.py#L686-L734) | Add creates a pool entry, clearing provider source suppressions for non-custom providers, not replacing a selected ID. Remove resolves a target, removes its index, then performs source-specific cleanup/suppression. Status reports auth state; it is not the ADR's selected-revision remote validation. Do not construct add-then-remove replacement or a shell/stdin adapter from these commands. |
| Desktop remote probe | [POST handler, lines 965–1032](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/config_env.py#L965-L1032); same `EnvVarUpdate` model; [nearest endpoint-probe tests, lines 33–145](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_web_routers_endpoint_probe.py#L33-L145) | Probes a supplied draft value, not an opaque stored credential ID/revision. Returns `ok/reachable/message`; missing probe yields `ok: true, reachable: false`, so `ok` alone is not acceptance. Tests cover local endpoint HTTP status/base resolution with fake transport, not the ADR four-way stored-credential result, separate billing consent or inference readiness. |

The adjacent [Desktop model assignment handler, lines 317–368](https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/models.py#L317-L368)
is `/api/model/set`, not Wing's `/api/models/assignment`. It has model-cost warning
and preparation/network work as well as config locking. Neither its name nor a
client `If-Match` proves the ADR's shared authoritative transaction across all
writers. It is not a credential replacement fallback.

## Wing dispatch and exact gates at the baseline

Common channel admission: connected client; supported capability schema; exact
operation name, method and path; declared `providers:write` and **every** required
grant; supported mandatory `profile` query context; nonblank selected profile.
See [scoped endpoint gate](../../lib/core/hermes/channel/api_channel/hermes_api_channel_capabilities.dart)
lines 4–25, [profile context gate](../../lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart)
lines 339–347, and [capability decoder](../../lib/core/hermes/models/hermes_capabilities.dart)
lines 59–85, 118–122. These gates do not verify credential concurrency semantics.

| Action | Current wire dispatch | Exact channel capability | Missing from request/receipt |
| --- | --- | --- | --- |
| Set | `PUT /api/providers/{slug}/credential?profile=…`, body `env_var/value` | `provider_credential_set`, `PUT`, that exact template, `providers:write` plus all declared grants | No add-versus-replace distinction, credential ID, expected revision, profile incarnation, idempotency key or committed/activation receipt. |
| Remove | `DELETE /api/providers/{slug}/credential?profile=…&env_var=…` | `provider_credential_delete`, `DELETE`, that exact template, same scope rules | No exact credential ID/revision/incarnation/key; provider presence does not report which sibling entries remain or prove remote revocation. |
| Validate | `POST /api/providers/{slug}/credential/validate?profile=…`, empty body | `provider_credential_validate`, `POST`, that exact template plus `/validate`, same scope rules | Targets only slug, not env selection, draft value, credential ID or revision. Boolean `ok` and free-text `detail` do not encode accepted/rejected/unavailable/inconclusive or effects consent. |

Sources: [direct client](../../lib/core/hermes/client/hermes_api_client.dart)
lines 634–677 and 737–800;
[channel methods](../../lib/core/hermes/channel/api_channel/hermes_api_channel_providers.dart)
lines 38–135; [provider/probe models](../../lib/core/hermes/models/hermes_provider.dart)
lines 11–75. Credential writes do not pass `If-Match`; transport helpers issue
one bounded call, not a durable replay/status protocol. The provider model has
slug/label/auth type/env names/presence/masked hint, no credential inventory or
revision. Mask-shape filtering is not proof that arbitrary server labels/details
cannot disclose secrets, nor does the ADR automatically admit last-four hints.

Set/Remove check connection/client/profile-selection generations before state
publication; this rejects stale results, not an already dispatched Agent write.
Validate returns the client future without the same channel completion guard;
the sheet does pre/post owner checks. Neither is server concurrency protection.

### Presentation gate mismatch and consent/effects

- [State visibility](../../lib/core/hermes/channel/hermes_channel_state.dart)
  lines 231–286 derives `canWriteProviders` **only from Set**. It checks schema,
  exact endpoint, all grants and supported query context when `profile_scoped`
  is declared; the action path always requires profile query context. It does
  not attest the ADR mutation contract.
- [Providers screen](../../lib/features/providers/screens/providers_screen.dart)
  lines 317–365 and 582–596 uses that flag for Manage on API-key rows. OAuth rows
  stay host-sign-in guidance, not an API-key sheet. No real upstream provider
  routes at this pin means the external API leaves management unavailable.
- [Credential sheet](../../lib/features/providers/widgets/provider_credential_sheet.dart)
  lines 47–166, 321–348 checks connection/host/profile ownership and the same Set
  flag (only when capabilities are non-null). Once opened, Validate and Set are
  enabled whenever not busy; Remove additionally requires `configured`. There
  are no independent Delete/Validate visibility gates. Thus Set-only authority
  exposes controls the real channel will subsequently reject; Delete-only or
  Validate-only authority cannot open the sheet via Manage. This is presentation
  drift, not proof of a network authorization bypass.
- Input is obscured and starts blank. Set and Remove are separate calls and close
  after success; neither automatically validates or assigns a model. Validate is
  explicit and stays in the sheet; its result detail is bounded/redacted, latency
  is client round-trip time, and displayed model IDs come from already-loaded
  inventory. There is no separate network/billing disclosure/consent or binding
  of the displayed verdict to a tested credential revision. Editing the input or
  env selection does not establish a new tested credential.
- [Model picker](../../lib/features/providers/widgets/model_picker_sheet.dart)
  lines 360–402 and [channel assignment](../../lib/core/hermes/channel/api_channel/hermes_api_channel_providers.dart)
  lines 264–326 keep assignment separate, sending provider/model together with
  the inventory revision as `If-Match`; a 412 refreshes inventory and rethrows.
  This is client behavior, not upstream atomicity, activation or inference proof.

## ADR comparison and bounded fail-closed correction

**Supported at source level:** separate explicit Set, Remove, Validate and
assignment dispatch; write-only entry presentation; exact channel route/grant
checks; profile query identity; stale-result fences on Set/Remove; assignment
precondition and 412 read reconciliation. None establishes safe existing-profile
replacement, add preservation or remote validation.

**Unavailable:** bounded edit state with opaque credential IDs/revision and
profile incarnation; exact-ID replacement/removal; preservation of sibling
credentials/selection/suppressions; authoritative concurrent-writer checks;
crash-safe, changed-payload-resistant, revocation-aware idempotency and unknown
outcome reconciliation; revision-bound four-way validation with separately
consented effects; committed revision versus reload/restart receipts; qualified
all-or-nothing assignment. Borrowed env/external/OAuth sources are not admitted
for this initial managed-API-key contract.

Smallest proposed follow-through (not implemented by this docs task):

1. Keep affected existing-profile Add/Replace/Remove/Validate unavailable at both
   action and UI boundaries until an **unmodified** Agent contract is individually
   traced and meets the ADR. Legacy route/grant advertisement alone must not
   re-enable Set as replacement. Do not add guessed wire fields, a provider store,
   a client-only revision, CLI/file fallback or Wing Link operation. If no
   eligible contract exists, refuse before credential dispatch and explain why.
2. Share exact **per-operation** eligibility between UI and channel. Do not use
   Set permission to imply Delete/Validate authority; recheck current ownership
   and that operation at click time and completion. Missing/unknown capabilities
   must fail closed, including direct sheet construction. Preserve read-only
   inventory/runtime-model paths and unavailable controls, not fabricated setup.
3. Keep Add, Replace, Remove, provider/model assignment and Validate outcomes
   separate. Never implement replacement as add-then-remove, removal as logout
   or revocation, saving as validation, or validation as inference readiness.
   A later eligible Validate needs disclosed network/billing effects, separate
   consent, selected ID/revision and four authoritative outcomes; do not retrofit
   those meanings onto `ok/detail`. Persistence must not imply reload/restart.

### Nearest regressions for that correction

Existing tests below were **inspected, not run**; fixture success is not a server
contract. Extend the nearest public seam only when implementing the correction,
with at most one focused case per changed behavior and no duplicate tests.

| Seam | Existing baseline evidence | Bounded missing regression |
| --- | --- | --- |
| Client serialization | [hermes_api_test.dart](../../test/core/hermes/hermes_api_test.dart), lines 2637–2740: Set body/presence, Remove profile/env query, Validate `ok/detail`; 2858 onward: assignment `If-Match`. | No eligible replacement serialization exists. Keep these as shape evidence, not admission tests. Only after verifying a real contract, test its exact request/secret-free receipt; do not invent protocol fixtures now. |
| Channel action boundary | [hermes_api_channel_test.dart](../../test/core/hermes/channel/hermes_api_channel_test.dart), lines 1936–2024: write-only state and late profile result; 2088–2221: assignment precondition/conflict; 2224–2300: extra model-read grant denial and read-only Set/model-write denial. | One refusal case over Set/Remove/Validate with legacy routes and grants but no eligible contract: zero PUT/DELETE/validation POST and unchanged state. Existing read-only coverage does not exercise all three provider methods. Preserve assignment conflict handling independently. |
| Sheet action eligibility | [provider_credential_sheet_test.dart](../../test/features/providers/provider_credential_sheet_test.dart), lines 39–77: revoked Set capability and A→B→A actions; 79–166: blank masked entry and distinct Set/Remove/Validate; 239–267: bounded/redacted detail. | One focused case at the public sheet for missing/insufficient exact action authority, including null capability: no dispatch through cached controls. A follow-on eligible contract must test revision/owner loss, not just Set flag loss. |
| Route/unavailable presentation | [providers_screen_test.dart](../../test/features/providers/providers_screen_test.dart), lines 503–558: omitted APIs/direct-only path; 586–608: OAuth guidance; 644–685: broad write/read-only visibility. | Extend unavailable coverage for a legacy Set-only advertisement: no replacement sheet or implied Remove/Validate, while authorized inventory remains readable. Keep model assignment and OAuth guidance distinct. |

## Verification and review boundary

Required checks for this slice: source pins and clean inspected upstream files;
handler/model/test/caller comparison above; changed Markdown targets; independent
contract/security review; `git diff --check`. No new test is warranted for a
source-only document.

Independent contract/security review: a fresh-context `reviewer` agent inspected
this document, the ADR/security boundaries and the cited source/test ranges.
Disposition: **approved for the bounded documentation-only slice**, with no
critical or important findings. Four minor citation-range corrections were
verified against file lengths/gate implementation and applied: lifecycle ends
at 221, provider model at 75, sheet at 348, and state admission spans through
286. This is a source review, not an independent security audit or product/live
acceptance.

Only Linux-host source inspection and document checks are in scope. Android,
native UI, deployed capability advertisements, secret transport/storage, actual
provider validation/billing, concurrency/replay across processes, runtime
activation and live Linux journeys remain **NOT_CHECKED**. Any future qualification
requires its own isolated target, exact operation/authority and effects consent;
this report supplies none of those grants.

Update triggers: changes to the ADR, the pinned Agent handlers/models/tests,
Desktop credential lifecycle, Wing API client/capability gates/provider sheet or
model assignment. Re-run the trace and independent review before changing an
unavailable operation into a support claim.
