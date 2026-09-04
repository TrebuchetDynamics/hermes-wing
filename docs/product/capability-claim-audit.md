# Capability claim audit

Snapshot: working tree, 2026-09-04. This is a local source/test audit, not an
upstream release certification or physical-platform receipt. Existing dirty
changes were retained. Runtime advertisement and grants remain authoritative.

| Surface | Exact understood contract and scope | Reachable control and unsupported state | Regression evidence | Platform limit |
| --- | --- | --- | --- | --- |
| Runtime models | `GET /v1/models`, all declared grants | Read-only model list; unsupported inventory explained | `test/features/providers/providers_screen_test.dart`, `test/core/hermes/hermes_api_test.dart` | Deterministic Flutter only in this pass |
| Session model choice | `GET /api/model/options`, `POST /api/sessions/{session_id}/model`, all declared grants and explicit session | Backend-confirmed session picker; no profile-wide mutation inferred | Core API channel session-model tests | No new physical receipt |
| Provider credentials | `GET /api/providers` with `providers:read`; exact credential set/delete/validate operations with `providers:write` | Write-only credential sheet only when gated; no OAuth key impersonation; proposed admin routes absent on documented baseline remain unavailable | `test/features/providers/providers_screen_test.dart`, `provider_credential_sheet_test.dart` | Tests do not prove a deployed Agent advertises these operations |
| Model assignment | `GET /api/models` with `models:read`; `PUT /api/models/assignment` and `POST /api/models/refresh` with `models:write`; assignment revision | Assignment sheet and refresh only for understood operations; conflict is shown without manufacturing persistence | `test/features/providers/model_picker_sheet_test.dart`, core provider/model tests | No production model-write claim |
| Skills and toolsets | `GET /v1/skills`, `GET /v1/toolsets`, every declared scope | Search/read/refresh; no skill/toolset mutation controls | `test/features/tools/tools_screen_test.dart` | Deterministic inventory only |
| MCP | No implemented MCP administration contract | Administration/discovery remain unavailable/planned | Tools suite verifies unsupported inventories; no MCP mutation path asserted | No MCP administration claim |
| Schedules/history | `GET /api/jobs`, declared and granted `tasks:read` | Job inventory; create/edit/pause/run/delete and independent run-history administration remain unavailable | `test/features/schedules/schedules_screen_test.dart` | Existing upstream jobs APIs do not by themselves qualify Wing mutation UI |
| Projects | No accepted advertised Project creation contract in current Wing integration | Approved handle-based child-folder browsing may be offered; Project creation and Project-aware chat remain gated | `test/features/profiles/profiles_screen_test.dart`, Wing Link suites | Folder browsing is not Project authority |
| Kanban | No implemented exact contract | No mutation UI | Schedule suite and route inventory | Planned only |
| Voice | Advertised `POST /api/audio/transcribe` / `POST /api/audio/speak` with audio policy; platform adapter fallback; chat/stop use exact direct Agent contracts | Microphone, text fallback, explicit read aloud/stop; local capture ownership tested separately from audio quality | `test/features/hermes_chat/voice`, `test/features/voice/services/speech`, core voice suite | No new mic, AEC, Bluetooth, barge-in, or thermal qualification |
| Wake words | No reviewed wake-word adapter/model execution path | Local command phrase during active capture is not wake-word listening | Voice controller command tests | No wake-word support claim |

The live gates are in
[channel state](../../lib/core/hermes/channel/hermes_channel_state.dart),
[surface readiness](../../lib/core/hermes/policy/hermes_surface_readiness.dart),
and their feature clients. Client dispatch still checks each exact operation;
a broad write badge does not authorize another route. Native and compatibility
profile lifecycle stay within the [runtime decision](../adr/runtime-and-delivery.md).
The new-profile compatibility exception does not authorize existing-profile
provider configuration.

The inspected README, PRD, and compatibility text do not claim working wake-word
or MCP mutation support or unrestricted desktop parity. No such wording was
invented to remove. Preserve the limitations in [routes](routes.md) and
[compatibility](hermes-compatibility.md).

Capability revocation and modal resource replacement are separate from inventory
loading races. Tests must verify revalidation before dispatch and stale completion
rejection while a sheet is open. Revision conflicts do not authorize automatic
retry, and optimistic administration stays deferred without authoritative
revision/rollback semantics. Persistence and subsequent reload outcomes must
remain distinct; an inventory refresh is not proof that a prior write failed.

See the [execution receipt](../superpowers/plans/2026-09-04-provenance-and-notifications.md)
for current commands/results and remaining scenarios. No product support status
was promoted by this audit.
