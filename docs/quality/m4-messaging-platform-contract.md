# M4 Platforms: health reads versus one Telegram admin operation

Task: `DOC-M4-PLATFORM-CONTRACT`. **Source-only contract/security evidence, not
shipped platform administration, live activation or native qualification.** Start
with [current routes](../product/routes.md), the [parity ledger](../product/hermes-desktop-parity.md#statuses)
and the [API/state boundary](../adr/api-and-state.md).

## Verdict and source identities

Wing can project messaging-platform **status** from its existing detailed-health
read. That does not authorize **`PUT /api/messaging/platforms/telegram` with
`enabled=false` for one explicitly named profile**. The official Desktop/Agent
reference implements that configuration operation, but not the operation-bound
local approval, stable resource authorization, concurrency and reconciliation
contract required by Wing. **Keep messaging-platform administration unavailable.**
This is an evidenced missing *eligible Wing contract*, not a claim that upstream
has no platform administration.

Pins obtained with `git rev-parse HEAD`, `git -C <Agent-reference> rev-parse HEAD`
and `git -C <Agent-reference>/apps/desktop rev-parse HEAD`:

| Inspected source | Revision | Evidence ceiling |
| --- | --- | --- |
| Wing baseline | `625b2fa2f641891c3bb37136112e5ad8823cd7ba` | Caller/model/gates and regression source; no behavior changed. |
| Unmodified Agent reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Authoritative handler/model/writer/auth and nearest tests; not an installed runtime. |
| Official Desktop subtree | `158fd638da1629c8e62caf9ade1515d162def8ab` | Same repository/revision; product interaction reference, not another independent release. |

The canonical checkout's read-only `hermes-agent/` reference was inspected outside
this isolated worktree because it is absent here; reference status was clean.
Root/area instructions were read. No credentials, actual Agent configuration,
private runtime state, live requests, upstream executable tests or services were
accessed/activated. The examples below are wire-shape descriptions, not commands
to run.

Docs map and work boundary:

- Existing owners: routes/parity above, [security ADR](../adr/security-and-privacy.md),
  [threat model](../security/threat-model.md), [Agent immutability](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent),
  and the existing [health authorization trace](diagnostics-read-contract.md).
- Corpus: API-server health/capability/auth handler, dashboard messaging model,
  profile/auth/writer seams, Desktop Messaging view/API and Wing Connections.
- Slice: health projection versus one **enablement-only Telegram disable**. No
  credential/allowlist edits, pairing/peer trust expansion, connection testing,
  gateway start/stop/restart/drain, installation or lifecycle mutation is executed
  or proposed as a fallback. The update's possible rescan effect is recorded, not
  qualified as lifecycle support.
- Validation: pin and trace sources, check Markdown/source targets, independent
  contract/security review, `git diff --check`. No new tests for documentation.

Ownership: the coordinator assigned this exact branch/worktree/task; its local
execution-slot metadata and live worker process were present. The baseline
[task index](../tasks/work-queue.md#current-work-queue) reserves this slice before its dependent host-lifecycle
follow-up; the [continuation ledger](../plans/2026-10-03-desktop-port-goal.md)
had no matching task claim. This is local admission evidence, **not** a fresh
external tracker lease check, ownership release or permission to start other work.

## Health is a read, not platform administration

| Read | Source-backed meaning | What it does not establish |
| --- | --- | --- |
| `GET /health` | [API-server handlers][U1]:2452–2454 returns `status`, `platform`, `version`; no detailed readiness probe. | No Telegram readiness, configuration visibility, local approval or mutation authority. |
| `GET /health/detailed` | [Handler][U1]:2456–2499 uses `_require_auth`, reads runtime status, adds the live API adapter metrics and readiness/work counts; returns `platforms`, gateway state, workload, timestamps and PID. [Bearer check][U1]:1586–1608 uses the selected expected API key. | Runtime platform entries are observations, not authorization handles or immutable Telegram/profile identities. This handler copies the runtime map, not a declared bounded per-platform configuration schema. It gives no write grant or proof that saving configuration has activated it. |
| `GET /api/messaging/platforms` | Desktop's [API helper][U2]:18–23 calls the dashboard [handler][U3]:817–832 in `_profile_scope(profile)`. [Payload producer][U3]:199–310 combines configured/enabled state, liveness, runtime state/errors and environment-field presence/previews. | Not equivalent to Wing's health-only read. Response also carries `env_path` and `gateway_start_command`; platform data may include home-channel/ingress metadata and credential previews. It is not an approved secret-free Wing health contract. No path, command or preview is authority to execute anything. |

The dashboard status path can invoke its configured health probe through
`resolve_gateway_liveness` ([payload][U3]:214–219; [probe][U4]:23–42). Profile
scope may hydrate secret sources ([scope][U5]:277–320), and catalog building
performs plugin discovery ([catalog][U6]:234–255). Thus even this richer GET is
not proven to be a pure, zero-external-effect metadata read. None was issued here.
Configured, enabled, connected and persisted are distinct facts; a stopped
runtime's retained error is not necessarily current configuration failure.

### Wing public seam and bounds

- [Client](../../lib/core/hermes/client/hermes_api_client.dart):58–65 reads basic
  and detailed health; [URI](../../lib/core/hermes/client/hermes_api_config.dart):42
  is `/health/detailed`, with no selected-profile query argument.
- [Bootstrap](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart):78–101
  conditionally loads detailed health only for the exact advertised endpoint and
  declared grants. Explicit refresh uses [state authorization](../../lib/core/hermes/channel/hermes_channel_state.dart):191–192,
  264–276 (supported schema, exact method/path, all declared scopes and supported
  context for profile-scoped operations), then [channel refresh](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart):240–272
  fences connection/request generations and clears current failures safely.
- [Connections](../../lib/features/gateway/screens/gateway_screen.dart):307–344,
  412–446 binds Refresh to selected management/Chat owner, channel, origin,
  profile, connection status and current read authority; stale completion cannot
  publish into a replacement owner. Its [platform card](../../lib/features/gateway/screens/gateway_screen.dart):724–752
  is name/status text, not a toggle or an editable configuration form.
- [Health model](../../lib/core/hermes/models/hermes_health.dart):3–5, 30–43,
  143–169 sorts and projects at most 32 platform entries with 80-character bounded
  name/status fields and strips controls/whitespace. This is a **client projection
  bound**, not an upstream response-byte/work bound: it first materializes/sorts
  the incoming map. Other top-level health strings have different bounds; do not
  call the entire response bounded or secret-safe solely because this card is.
- [Readiness](../../lib/core/hermes/policy/hermes_surface_readiness.dart):63–68,
  224–229 requires explicit `gateway:read` for its health availability row and
  always defers Messaging gateways. Action/state authorization instead enforces
  scopes **if declared**. The pinned API-server [endpoint table][U1]:78–103
  advertises health without a named `gateway:read` requirement. This known
  projection/action distinction is already recorded in the health trace above;
  this task does not repair it or infer admin authority from either predicate.

No production `/api/messaging/platforms` or `updateMessagingPlatform` caller was
found in `lib/core/hermes/`, `lib/features/gateway/` or `lib/router/` at this Wing
pin. Existing run approvals are not platform-configuration approval receipts.

## One exact admin operation: disable Telegram configuration

**Selected shape:** `PUT /api/messaging/platforms/telegram?profile=<explicit-name>`;
body has only `enabled: false` (`env` and `clear_env` default empty; no body-profile
override). This is an existing upstream operation, **not an admitted Wing route**.
Enabling, replacing tokens, editing allowed users and testing a connection are
separate operations and receive no permission from this trace.

| Acceptance dimension | Supported by inspected source | Missing guarantee / Wing disposition |
| --- | --- | --- |
| Handler and model | [Pydantic model][U7]:61–67 has optional `enabled`, `env`, `clear_env`, `profile`. [PUT handler][U3]:876–933 requires a known catalog platform, computes `target_profile = body.profile or profile`, validates all supplied environment edits before writing, then writes enablement. Empty env/clear lists mean this selected request does not replace/remove secrets. | The route is a broader configuration door, not a disable-only schema. No expected revision, incarnation, approval or idempotency fields appear in its declared model/handler. Do not expose arbitrary environment keys through Wing or treat the sample as an available operation. |
| Resource identity | Catalog [lookup][U3]:156–164 verifies `telegram` exists. [Catalog metadata][U6]:24–30 identifies Telegram's fixed fields. [Resolver/scope][U5]:190–199, 242–320 validates an explicit existing profile name and binds its home/secret scope for the write. | Catalog ID and profile **name** are locators, not a principal-bound stable authorization handle, profile/adapter incarnation or revision. Missing/blank/`current` has ambient semantics; body profile wins over query. No echoed profile identity in the response, no same-name delete/recreate fence, no Hermes Project binding. Explicit naming prevents ambient selection, not stale-resource authorization. |
| Authentication versus authorization | [Dashboard middleware][U8]:690–727 protects `/api/` with the session-token path or the active dashboard-auth gate. [OAuth gate][U9]:153–180 also supports provider-verified native bearer authentication. | Authentication is not an advertised exact platform-write grant. This PUT has no operation/resource-specific principal authorization check or local approval validation. The separate [machine-token seam][U10]:28–42, 75–96 applies only to registered exact paths; no production registration for this route was found under `hermes_cli/`. Do not reuse API-server Bearer credentials, dashboard sessions or broad `admin_config_rw` as a write grant. |
| Local approval | Desktop [switch][U11]:941–959 is labeled for the current platform state and invokes `handleToggle`; [handler][U11]:359–386 submits `{enabled}` immediately. | A switch click is user intent, not **host-local approval bound to requester/device, route, exact operation, stable profile/platform resource, revision and payload digest**. Neither this handler nor the declared request verifies such approval. Missing approval leaves the operation unavailable; no new Wing approval store, shell bridge or peer trust mechanism is authorized. |
| Persistence and concurrency | [Enablement helper][U6]:332–333 delegates to [config writer][U12]:2146–2154, which loads config, sets `platforms.telegram.enabled` and calls `save_config`. [Save][U12]:2509–2553 uses its process lock, fail-closed read and atomic replacement path. Selected request never uses global `profile use` or `project use`. | Atomic file replacement/process locking is not an expected-revision transaction spanning competing CLI/API writers or profile recreation. No authoritative compare-and-set receipt or durable deduplication record is returned. `save_config` also has a managed-config early-return branch; `{ok:true}` is not an unconditional readback-verified persistence claim for every environment. |
| Runtime effects and outcome | After `_apply`, [PUT][U3]:923–946 calls `_notify_multiplexer_hot_serve(target_profile)` and returns `{ok:true, platform:"telegram", hot_served:boolean}`. [Notifier][U13]:109–126 asks a live default gateway to rescan and recognizes a returned served-profile list. | This is **not guaranteed save-only**: the notification path runs even for disable-only requests and can cause live adapter reconfiguration. `hot_served=true` is notification/rescan response evidence, not a correlated Telegram disconnected/activation receipt. `false` does not roll back the saved setting or prove failure. No start/stop/restart/drain is qualified; no lifecycle action was activated here. |
| Retry, errors and privacy | Unknown platform gives 404; invalid profile gives 400/404; environment edits use catalog allowlisting. PUT logs names/keys, not field values, and wraps unexpected failures in fixed HTTP 500 detail ([handler][U3]:876–933). | No crash/timeout status lookup or durable request identity, changed-payload replay rejection, revoked-caller receipt policy, or cross-writer conflict outcome is declared. Boolean assignment alone does not make retries harmless: they can target a recreated resource or trigger rescan again. Reconnect must only reconcile reads; never auto-replay this write. Do not log real profile names, private endpoints, config paths, previews or payloads in Wing evidence. |

The API-server [capability table][U1]:67–103, 2537–2578 advertises neither this
platform PUT nor the dashboard platform inventory. `admin_config_rw=false` is
supporting negative context, not the reason to substitute a different write API.
There is no exact advertised operation/grant to wire here. Keep
[Connections' contract-gated administration](../product/routes.md) unchanged;
[Agent immutability](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent)
forbids patching the reference or filling these gaps with direct files/CLI shell
execution, retired Wing Link, a shadow catalog or a second backend.

## Official Desktop interaction and nearest tests (inspected only)

Desktop's Messaging view loads scoped platform rows, selects a platform and
shows its enabled switch. [Read caller][U11]:183–222 ignores a late successful
read from another profile. [Update caller][U2]:33–43 carries `profileScoped(profile)`;
[scope helper][U14]:75–82 supplies the explicit renderer routing tag, not a Wing
HTTP authorization mechanism. After success the [toggle handler][U11]:359–386
updates the matching local row, reports enabled/disabled and delegates outcome
handling. [Settlement][U11]:172–181 schedules a fresh read for `hot_served`, or
shows restart-needed otherwise. That reference experience is evidence of product
intent, not proof of an authoritative apply receipt or all mutation-owner races.
Restart handling is outside this slice and must not be copied into Wing.

| Nearest regression source | What its assertions cover | Evidence ceiling |
| --- | --- | --- |
| [API-server health tests][U15]:826–875 | Detailed-health runtime fields including Telegram state and API metrics; public health does not invoke readiness probes. | Mocked runtime/probes; not platform update authority, byte bounds or fresh execution here. |
| [Messaging profile tests][U16]:42–58, 69–90, 139–195 | Session-authenticated test client; named-profile read excludes root credential presence; unknown profile 404; Telegram config/env write and readback stay in target home. | Read/write isolation evidence, not local approval, same-name reincarnation, denied platform grant or disable-only transaction proof. No test data/secrets copied into this receipt. |
| [Enablement/hot-serve tests][U16]:239–266, 284–340 | Disable-only API-server platform config save (adjacent generic route); Telegram explicit false/true read semantics; mocked rescan notification on scoped and pooled named-profile writes and no hot-serve claim for default. | Telegram's bool writer is shared; this is not a live Telegram disable or adapter-disconnection receipt. No durable replay/crash or concurrent-writer proof. |
| [Stale-runtime tests][U17]:46–77 | A stopped gateway drops old platform errors; durable operator stop outranks retained startup failure. | Dashboard inventory status interpretation, not a platform mutation receipt or Wing health parity. |
| [Desktop Messaging tests][U18]:129–143, 169–296 | Explicit profile on reads, accessible enable-switch label, placeholder reset and late profile-A read rejection under profile B. | Mocked API; no server-side approval/resource authorization or save/activation qualification. |
| [Wing Connections tests](../../test/features/gateway/gateway_screen_test.dart):348–499 and [health parser tests](../../test/core/hermes/hermes_api_test.dart):1253–1373 | Read-only platform/readiness display, refresh, stale failure rejection, basic fallback, declared gateway-read denial, bounded/malformed platform projection. [Readiness regression](../../test/core/hermes/hermes_api_test.dart):809–875 keeps Messaging gateways deferred. | Existing deterministic regression **source**, not tests run in this documentation task. No platform-admin implementation or qualified native/live messaging behavior. |

## Validation and qualification ceiling

- Pins and handler/model → auth/profile/config writer/rescan → nearest upstream
  tests → Desktop/Wing callers were traced above. No runtime code or test changed.
- A temporary offline validator checked 23 local Markdown/source targets and
  anchors, 18 pinned upstream paths and 62 cited source line ranges, plus the
  Wing/Agent/Desktop pins and clean reference status. No network probe was used.
- Fresh-context independent `reviewer` run
  `d7c7f21d-2eb8-44df-b5cb-98a82d5b6d3e` accepted the source-only contract/security
  draft (SHA-256 `abced23d38052c065c5e04829a6086319104982122f520c64f1f6b6181064123`),
  with no Critical/Important findings. Its two Minor findings were a parser
  citation range and this prospective validation entry; both were verified and
  corrected. The review did not independently attest external worker/lease state.
  Final edits correct the citation and record evidence, not change the contract.
- `git diff --check` and staged `git diff --cached --check` pass for the final
  documentation candidate. No executable tests were added or run. Source
  consistency and review cannot qualify an installed service.
- No Flutter/browser/native app, device, live Agent authentication, Telegram
  account/bot, credential storage or actual platform mutation was exercised.
- Pending live: only after a suitable **unmodified**, exactly advertised and
  separately admitted contract exists, qualify authenticated read/denial, local
  approval binding, resource-recreation/conflict/replay rejection, correlated
  persistence versus activation and accessible target-native recovery on a
  disposable target. These are separate live prerequisites, not offline blockers
  or permission to acquire credentials/activate operations now.
- Re-pin on changes to messaging models/routes, auth/profile identity, config
  writer, multiplexer notification, capability advertisement, Desktop caller or
  Wing gates. Do not transfer this finding to an uninspected runtime/version.

## Pinned upstream sources

[U1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py
[U2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/messaging.ts
[U3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/messaging.py
[U4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_gateway.py
[U5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_profiles.py
[U6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_messaging.py
[U7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_models.py
[U8]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server.py
[U9]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/dashboard_auth/middleware.py
[U10]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/dashboard_auth/token_auth.py
[U11]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/messaging/index.tsx
[U12]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/config.py
[U13]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/gateway_multiplex_served.py
[U14]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/client.ts
[U15]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/gateway/test_api_server.py
[U16]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_web_server_messaging_profiles.py
[U17]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_web_server_messaging_stale_runtime.py
[U18]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/messaging/index.test.tsx
