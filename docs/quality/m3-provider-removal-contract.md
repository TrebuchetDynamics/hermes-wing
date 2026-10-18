# M3 existing-profile credential removal contract

Source-only evidence for `DOC-M3-PROVIDER-REMOVAL-CONTRACT`. Start with the
[required Agent-owned mutation contract](../adr/api-and-state.md#required-agent-owned-mutation-contract)
and the separate [replacement trace](m3-provider-credential-contract.md).
**No eligible exact-credential removal operation was found in the inspected
surfaces. Removal remains unavailable under the ADR; this document enables no
operation and qualifies no runtime.** Removal is neither replacement, provider-wide
logout, nor remote provider-key revocation.

## Scope, ownership and source pins

Read-only handler/model → nearest upstream tests → Wing client/channel/sheet
comparison, plus sanitized historical receipt inspection. No credential access,
provider writes, network probes, installs, inference, restarts or upstream edits.
Only `docs/quality/` changes. No tests were added or executed for this docs slice.

The predecessor is closed in `todo.archive.md` under `DOC-M3-PROVIDER-CONTRACT`
(coordinator closeout `974fe6e4e0bbf0e4a06849f6f8343d1303378bc6`). This worker uses
its coordinator-assigned task slot/worktree; task metadata and the coordinator
snapshot showed one active worker at inspection. No other claim was adopted.

Pins obtained with `git rev-parse HEAD` in Wing and `git -C <reference> rev-parse
HEAD` in Agent and its official `apps/desktop` subtree:

| Inspected checkout | Commit | Evidence ceiling |
| --- | --- | --- |
| Wing task baseline | `c2c4594556e0c5c4538a36e12d2f214a82fb8740` | Current caller and regression source, not executed behavior. |
| Read-only Hermes Agent reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Handler/model/test source, not installed-runtime behavior. |
| Official Desktop subtree | `158fd638da1629c8e62caf9ade1515d162def8ab` | Product interaction source, not Wing authority. |

Inspected upstream files had no local modifications. Upstream links below are
immutable at that pin; Wing links/ranges describe the baseline. Source scope:
external API capabilities, serve env/pool deletion, CLI removal, native disconnect,
Desktop clear, Wing dispatch/admission/errors and their nearest tests. This is not
a claim about every upstream release or an installed server. The
[accepted port roadmap](../../ROADMAP.md#flutter-port-execution-roadmap) keeps
missing mutation authority distinct from completed parity.

## Distinct upstream removal surfaces

### External API versus official Desktop

The [external capability table][U1]:67–102 advertises neither
`provider_credential_delete` nor Wing's `/api/providers/{slug}/credential` route;
`admin_config_rw` is false. The nearest [capability regression][U2]:939–963 checks
run/model/read contracts, not removal. Its durable **run** idempotency does not
transfer to credential operations.

Official Desktop's [clear action][U3]:157–175 asks for destructive confirmation,
calls `deleteEnvVar`, updates local presence and invalidates model-options after
resolution. Its [typed client][U4]:227–234 sends `DELETE /api/env` with a key in
the body and profile scope through the Desktop bridge. It does not consume a
credential ID, expected revision, committed revision or activation receipt.
This product outcome is not permission to substitute a different Wing route or
to port Desktop's secret-reveal path.

| Surface | Request/handler and effects | Nearest inspected regression; evidence limit |
| --- | --- | --- |
| Serve env-key delete | [`EnvVarDelete`][U5]:25–28 has key and optional profile; [handler][U6]:1035–1050 accepts body/query profile and calls the lifecycle. [Lifecycle][U7]:49–77, 143–162, 201–221 removes the env value, prunes **all** pool entries with that env source across providers, suppresses affected sources, clears model caches best-effort and scrubs value-matched config mirrors. Other-source pool entries survive the prune. | [Lifecycle tests][U8]:92–107, 264–281 check cache removal and a keyed config mirror; [managed write-guard test][U9]:115–135 checks DELETE refusal leaves env/config/auth unchanged. Not exact-ID selection, sibling/selection/suppression preservation or an expected-revision transaction. |
| Serve pool-entry delete | [Handler][U10]:431–481 addresses provider and **1-based index**, with optional profile passed through [`destructive_profile`][U20]:61–84: explicit profile is required while multiplexing; omission retains the launch profile on a single-profile host. It removes that index, then performs source-specific cleanup/suppression; cleanup and suppression can fail best-effort while the result is still `ok: true`. Returns provider, remaining `count`, `cleaned` and `hints`, not an opaque removed ID/revision. | [Admin endpoint tests][U11]:151–179 prove an env source stays suppressed after reintroduction; 181–212 prove explicit add lifts suppression. [Profile-scope tests][U12]:219–230, 291–295 prove unnamed multiplex refusal and named-home dispatch using seams (the latter uses index 0 in its fake, not valid-index behavior). Neither proves stale-index rejection, exact-ID concurrency or crash-safe replay. |
| CLI auth remove | [Command][U13]:563–589 resolves an ID, unique label or index, removes the resolved index and then runs source cleanup/suppression. [Pool helper][U14]:56–65, 84–107 uses a local lock, reindexes sibling priorities and clears the selected current ID when removed. ID lookup does not create a revision-bound transaction spanning resolution and cleanup. | [CLI tests][U15]:686–766 cover sibling priority reindexing and legacy Codex suppression migration. These are deliberately different effects, not proof of the ADR's managed-key-only removal. No CLI/stdin/shell adapter is admitted. |
| Native `model.disconnect` | [Params/result][U16]:98–110 are slug/session and slug/name/disconnected; [handler][U17]:421–446 removes every registered provider env key plus provider auth/OAuth/pool state. It preflights env write refusals, but is provider-wide disconnect, not selected-ID removal. | [Managed-install test][U9]:172–180 covers clearing manually held auth when no env value blocks it. It does not qualify exact-ID deletion, external revocation or durable retry. No Wing RPC substitution is admitted. |

### Errors and receipts are not the required secret-safe contract

- Env delete's [error wrapper][U6]:61–77 passes HTTP errors, returns `ValueError`
  text as 400 and logs unexpected exceptions before a generic 500. Its 404 is
  generated **after** the lifecycle and names the supplied env key. Since the
  lifecycle can suppress sources/clear caches even when `found` is false, this
  404 is not proof that nothing changed. The [write refusal helper][U18]:2736–2770
  can include the administrator-managed source path. Generic 500 response text
  therefore does not establish allowlisted, path-free errors or audit events.
- Env success [fields][U7]:213–221 are `ok/key/removed/pool_pruned/providers/`
  `config_scrubbed/found`. No credential value is intentionally returned by this
  lifecycle, but config-scrub entries are dotted config locations, not opaque
  credential identities. There is no resulting revision, sibling count or
  reload/restart status. Multi-store sequential writes and best-effort cleanup
  are not an all-or-nothing commit receipt.
- Pool deletion [errors/result][U10]:450–478 can return raw exception text as 400,
  and `cleaned/hints` are source-authored text. The [source cleanup model and env
  cleanup][U19]:55–69, 95–134 describe those strings; other source cleanup can
  include private file locations ([same source][U19]:138–150). These outputs are
  not the ADR's bounded allowlisted error taxonomy. A nonzero `count` describes
  the local pool snapshot, not sibling preservation at an authoritative revision.
- A second index delete after a lost response can address a different sibling
  after reindexing ([pool helper][U14]:56–65). Env delete repeats source-level
  effects, and native disconnect repeats provider-wide effects. HTTP DELETE's
  name, a store lock or a refreshed inventory cannot supply durable deduplication,
  changed-payload rejection, revocation-aware receipt access or original-outcome
  recovery. No such provider status/receipt protocol is exposed in these inspected
  request/result shapes.

## Wing removal path at the baseline

| Seam | Source-backed behavior | Missing removal guarantee |
| --- | --- | --- |
| Direct client | [Client](../../lib/core/hermes/client/hermes_api_client.dart):648–664 sends `DELETE /api/providers/{slug}/credential?profile=…&env_var=…`, no body, and parses `data` as a provider row. The generic [DELETE/timeout helpers](../../lib/core/hermes/client/hermes_api_client.dart):780–812 perform one bounded request; removal supplies no `If-Match`. | No credential ID, expected revision, profile incarnation, operation idempotency key or authoritative commit/status receipt. It does not call the upstream serve env or pool routes. |
| Channel admission/publication | [Remove](../../lib/core/hermes/channel/api_channel/hermes_api_channel_providers.dart):75–106 requires connection, `provider_credential_delete`, exact method/path, `providers:write` and every declared grant through the [shared gate](../../lib/core/hermes/channel/api_channel/hermes_api_channel_capabilities.dart):4–23. [Profile helpers](../../lib/core/hermes/channel/api_channel/hermes_api_channel_providers.dart):358–384 require supported query context and a selected profile; connection/client/profile generations fence publication. | Correct route/grant admission is necessary but does not check the ADR transaction. A stale completion is dropped, not rolled back; the original Agent may already have committed. No removal conflict refresh or unknown-outcome reconciliation is performed. |
| State/receipt | [Provider model](../../lib/core/hermes/models/hermes_provider.dart):11–60 has slug/label/auth type/env names, configured and mask-shaped hint. [Replacement into state](../../lib/core/hermes/channel/api_channel/hermes_api_channel_providers.dart):347–356 replaces an existing row by returned slug. | Provider-level presence cannot identify the removed credential or say which siblings remain. Mask filtering is not comprehensive response redaction. No committed revision, activation or remote-revocation proof. |
| Sheet visibility and intent | [State gate](../../lib/core/hermes/channel/hermes_channel_state.dart):231–286 derives `canWriteProviders` from **Set**, not Delete. [Sheet](../../lib/features/providers/widgets/provider_credential_sheet.dart):66–127, 321–348 checks owner and that flag (when capabilities are non-null); Remove appears for configured rows and dispatches the selected env name when not busy. No separate removal confirmation is present. | Set-only admission can expose Remove which the real channel then rejects; Delete-only admission cannot open Manage via that flag. This is presentation mismatch, not evidence of a network authorization bypass or independent Delete eligibility. |
| Failure/unknown outcome | [Sheet action wrapper](../../lib/features/providers/widgets/provider_credential_sheet.dart):83–101 catches all failures into fixed localized copy; success/owner checks close the sheet. Default [native transport](../../lib/core/hermes/client/platform/hermes_api_transport_io.dart):86–123 and [web transport](../../lib/core/hermes/client/platform/hermes_api_transport_web.dart):124–168 report status/network failures without returning error bodies; [status messages](../../lib/core/hermes/shared/hermes_api_http.dart):41–49 are generic. | The sheet does not echo raw server errors, but also cannot distinguish denied, stale/conflict, not found, unsupported source and unknown commit. A timeout/response parse failure after dispatch cannot be labeled “not removed.” The busy flag prevents overlapping sheet clicks, not a later unsafe retry. |

Nearest Wing tests were **inspected, not run**:

- [Client removal case](../../test/core/hermes/hermes_api_test.dart):2685–2716
  checks profile/env query and synthetic presence-only response; no revision,
  duplicate request or unknown-outcome guarantee.
- [Sheet removal case](../../test/features/providers/provider_credential_sheet_test.dart):131–144
  checks fake dispatch separately from Set/Validate. Its A→B→A cases at 57–77
  refuse all three actions; revoked capability at 39–55 tests Set, not independent
  Delete gating. The [channel late-response case](../../test/core/hermes/channel/hermes_api_channel_test.dart):1983–2024
  exercises Set, so it must not be relabeled removal-specific race evidence.
- Historical [native provider receipt](linux-e2e-2026-09-06.md#native-provider-mutation-flows)
  records synthetic set/validate/remove and revoked-write journeys. The same
  receipt's table at lines 614–616 explicitly leaves real credential changes
  unqualified because the installed Agent did not advertise the APIs. Its
  “exact removal receipt” is a fixture dispatch receipt, not an Agent revision or
  replay receipt. No private raw logs, screenshots or credential stores were read.

## ADR acceptance and unknown-outcome disposition

| Required removal contract | Finding at these pins |
| --- | --- |
| Explicit profile **incarnation**, provider, operation, selected opaque credential ID and **expected revision** | Absent from Wing removal and the env/pool/native request shapes; CLI target resolution does not supply the transaction. Even a managed manual pool row cannot make the index route eligible. |
| Identity/revision checked in the same authoritative transaction as commit, shared by relevant concurrent writers | Not exposed. Local/store locks and profile scoping are narrower; env cleanup spans multiple stores. No stale-revision or delete/recreate protection is established. |
| Only selected managed API-key removed; siblings/selection/suppressions preserved; state whether others remain | Env cleanup is source-wide; pool route reindexes and may clean/suppress external sources; native disconnect is provider-wide. Pool `count` alone is insufficient. Borrowed env, OAuth and external-store sources remain unsupported by the initial ADR. |
| Secret-safe bounded errors: unsupported operation/source, invalid input, denied authorization, stale identity/revision, conflict, not found, unknown outcome | Upstream has raw/source-dependent error/detail surfaces above; Wing suppresses details but conflates outcomes. Neither proves the required taxonomy and allowlisted audits. |
| Crash-safe idempotency, original receipt/status recovery, changed-payload rejection, revoked/expired replay denial | Absent in the inspected removal interfaces. Do not transfer run idempotency or rely on DELETE retry. No authoritative unknown-outcome reconciliation is available here. |
| Resulting committed revision separate from no reload/reload required/verified activation | Absent; presence, `ok`, count or `disconnected` is not that receipt. No implicit restart, inference, validation or remote revocation may be inferred. |

**Disposition:** keep affected existing-profile removal unavailable until an
unmodified Agent provides an individually traced eligible contract. Do not
invent request fields, use replacement/add-then-remove, switch to pool index
removal, logout, a CLI/file bridge or a Wing-owned provider store. The separate
replacement report's proposed per-operation fail-closed UI/action correction
still applies; it is not implemented by this documentation task.

For a future eligible operation, a lost response must stay **unknown** until an
authorized Agent status/original secret-free receipt reconciles the exact
operation, owner, selected ID and expected revision. A presence refresh can show
current state but cannot prove which request committed. Reconnect must not replay,
use a fresh idempotency key or retarget another credential. Changed identity,
payload or approval requires the contract's fresh authorization; this is an ADR
requirement, **not a callable protocol supplied by these sources**.

## Verification, independent review and remaining qualification

Offline checks for this slice: checkout pins; clean inspected upstream source;
handler/model/test/caller/ADR comparison; local Markdown target and immutable
source-range validation; independent contract/security review; `git diff --check`.
A fresh-context `reviewer` independently inspected this document, the ADR/security
boundaries, cited upstream handlers/models/tests, Wing callers/UI and the sanitized
historical receipt. **Approved for documentation-only scope; no Critical or Important
findings.** Two minor corrections were verified against the pinned source and
applied: pool-delete profile omission is permitted on single-profile hosts, and
the native disconnect test citation is 172–180. This is a bounded contract/security
source review, not an independent security audit or live acceptance. No application
behavior, dependencies or test fixtures changed; runtime suites are not evidence
for this source-only conclusion.

Only Linux-host source/document inspection was exercised. Deployed capability
authority, exact-ID removal, concurrent CLI/API edits, stale revisions and profile
recreation, sibling/suppression preservation, crash/timeout/changed-payload replay,
revoked callers, error/audit redaction and activation need separate isolated
runtime qualification **if an eligible contract becomes available**. Native UI,
Android/devices and provider-side revocation were not checked; removal must not
claim the latter. No credential provisioning or live removal is authorized here.

Update triggers: changes to the ADR, Agent removal handlers/models/nearest tests,
Desktop clear flow, Wing removal serialization/capability gates/provider sheet,
or new sanitized removal receipts. Re-trace and independently review before
changing an unavailable operation into a support claim.

[U1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L67-L102
[U2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server.py#L939-L963
[U3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/settings/env-credentials.tsx#L157-L175
[U4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/config.ts#L227-L234
[U5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_models.py#L25-L28
[U6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/config_env.py
[U7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/credential_lifecycle.py
[U8]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_credential_lifecycle.py
[U9]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_managed_scope_writeguard.py
[U10]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/ops.py#L431-L481
[U11]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_dashboard_admin_endpoints.py#L151-L212
[U12]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_web_routers_destructive_profile_scope.py
[U13]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/auth_commands.py#L563-L589
[U14]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/agent/credential_pool_admin.py
[U15]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_auth_commands.py#L686-L766
[U16]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/contracts/profiles_vault_complete_foreign_subagents.py#L98-L110
[U17]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/methods_complete.py#L421-L446
[U18]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/config.py#L2736-L2770
[U19]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/agent/credential_sources.py
[U20]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/_common.py#L61-L84
