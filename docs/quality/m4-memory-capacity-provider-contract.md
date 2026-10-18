# M4 Memory: capacity and provider status, not entries

Task: `DOC-M4-MEMORY-CAPACITY-CONTRACT`. **Read-only source inspection only;
not shipped support, operation activation or live/native qualification.** Start
with the [entry-read trace](m4-profile-memory-read-contract.md),
[parity status](../product/hermes-desktop-parity.md#statuses) and
[current routes](../product/routes.md).

## Verdict and inspected revisions

`GET /api/memory?profile=<profile-name>` exists in the dashboard/serve backend.
It returns the selected provider, provider discovery/setup status and two built-in
file byte sizes. It returns **neither entry inventory nor actual capacity**:
no entry count, character usage/limit, remaining allowance or external-provider
quota. The GET is also **not a passive, bounded metadata-only operation**: its
source path can hydrate secret sources, initialize home metadata, back up config,
load plugin code and run dependency-check subprocesses. None was invoked here.
There is no advertised exact operation/grant for this status read in the inspected
messaging capability table. **Keep Wing memory status/inspection unavailable**;
these findings do not assert that Agent has no other memory surfaces.

Pins obtained with `git rev-parse HEAD`, `git -C ../../hermes-agent rev-parse HEAD`
and `git -C ../../hermes-agent/apps/desktop rev-parse HEAD` from this isolated Wing
worktree:

| Tree | Revision | Evidence ceiling |
| --- | --- | --- |
| Wing baseline | `c1af068709b1edbdea3ea490df17c31ef7442527` | Production caller/gates and regression source, not a running client. |
| Agent reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Unmodified source and nearest tests; not installed-runtime evidence. |
| Official Desktop subtree | `158fd638da1629c8e62caf9ade1515d162def8ab` | Same checkout, not an independent release or execution receipt. |

The canonical checkout's read-only Agent reference is outside this worktree; its
status was clean. Relevant root/area instructions were read. No actual memory
files, provider config values, credentials, runtime databases or private payloads
were inspected. No upstream imports, tests, probes, installs, requests or services
were run. The coordinator assigned this branch/worktree; the predecessor trace
is present, and the local continuation ledger contains no matching memory claim.
This is not a fresh live tracker lease check or authority to start other tasks.

Docs map / bounded checklist:

- Existing owners: entry-read trace, parity/routes, [API/state](../adr/api-and-state.md),
  [security](../adr/security-and-privacy.md), [threat model](../security/threat-model.md)
  and [Agent immutability](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent).
- Source corpus: status handler → provider status/discovery/setup helpers → profile/auth
  scope → nearest failure/isolation tests → Desktop model/caller → Wing gates.
- Chosen slice: distinguish bytes, availability/configuration and capacity; identify
  exact authorization or absence. Provider configuration/OAuth/reset are not admitted.
- Checks: pin sources; trace claims; check changed Markdown/source targets; obtain
  independent contract/security review; run the documentation-only offline gate.

## What the status response actually means

The [handler][U1]:488–506 returns an unversioned dictionary, not a declared REST
response model. The [Desktop interface][U2]:1804–1809 types only `active`, provider
`name/description/configured`, and `builtin_files.memory/user`. The actual provider
rows have more fields ([producer][U3]:331–373); TypeScript does not validate or
strip the wire response.

| Field / outcome | Source meaning | Must not imply |
| --- | --- | --- |
| `active` | Normalized `memory.provider` from merged config. Core sentinels become an empty string ([normalizer][U3]:16–19; [sentinels][U4]:42–49). | A live initialized provider, successful credentials, usable entry API or external quota. |
| `builtin_files.memory`, `.user` | `Path.stat().st_size` for fixed `memories/MEMORY.md` and `memories/USER.md` in the scoped home; zero if `exists()` is false. No content read in this loop. | Entry count, decoded character count, token usage, capacity limit, remaining capacity, or external-provider database size. Missing and zero-byte files are indistinguishable. |
| Provider `available` | Plugin discovery loads/constructs candidates and calls `is_available()` through [probe helper][U5]:185–191; exceptions become false ([discovery][U6]:174–189). The ABC asks implementations to check config/dependencies without network ([ABC][U4]:97–104). | Remote credential validation, health, successful recall/storage, or a verified no-side-effect guarantee for arbitrary plugin implementations. |
| Provider `configured` | Every visible required normalized schema field is set, using existing config, environment lookup or defaults ([helpers][U3]:205–318). Secret fields test presence, not validity; no required fields can yield true vacuously. A missing selected plugin yields false. | Valid secrets, network access, activation, or permission to read/edit provider config. No existing field values are returned by this boolean computation. |
| Provider `status` | `missing` first; dependency failure → `unavailable`; incomplete config or unavailable-with-schema → `needs_config`; otherwise available → `ready`, else `unavailable` ([classifier][U3]:321–328). A configured-but-undiscovered selection gets a synthetic missing row. | A provider-wide inventory, remote readiness guarantee, capacity measurement or authorization grant. `active` can name a missing/unready provider. |
| Provider `setup` | Declaration metadata: Python requirements, external dependency name/install/check strings, required environment names, dependency-declaration/currentness booleans ([setup][U3]:49–88). | A bounded, redacted Wing-safe metadata envelope. Plugin-authored strings/commands are not allowlisted or length-capped here; do not copy runtime rows into receipts/diagnostics. |
| Actual built-in capacity | Separate runtime code supplies `memory_char_limit`/`user_char_limit` to `MemoryStore` ([initializer][U7]:1344–1360). [Store][U8]:220–231 measures `len(ENTRY_DELIMITER.join(entries))` against its character limit. | File bytes cannot recover this usage or remaining allowance. The status route does not instantiate/read the store for these values. External-provider quotas are not measured by this response. |
| Entry reads | Built-in graph cards and one memory chunk use separate learning-node paths, detailed in the [entry-read trace](m4-profile-memory-read-contract.md#exact-authoritative-read-trace). | `/api/memory` is not an entry list or a replacement for the detail read; neither surface establishes external-provider entry coverage. |

The separate public `/api/status` memory rollup concerns gateway/system RAM and
pressure ([RAM collector][U9]:1–7), not stored agent memory capacity. Generic
settings fields or tool-result usage text are likewise not a qualified read-only
capacity API; do not fetch config, parse files or invoke memory tools to fill the
missing status fields.

## Authorization, profile identity, effects and bounds

| Dimension | Verified source contract | Missing guarantee / disposition |
| --- | --- | --- |
| Exact operation/grant | Dashboard router declares `GET /api/memory` with optional query `profile` and no route-local memory scope ([handler][U1]:491–506). [Messaging capabilities][U10]:67–103 advertises neither this route nor a capacity/provider-status operation. | No exact advertised Wing status operation or required/granted memory-read scope. `memory_write_api=false` is not a read grant; do not invent `memory:read` or borrow another operation's authority. |
| Authentication | `/api/memory` is not public. [Middleware][U11]:690–727 requires the dashboard session token when the OAuth gate is inactive; when active, [dashboard auth][U12]:153–204 accepts a verified provider session/cookie or native OAuth bearer. The separate [machine-token seam][U13]:1–9, 28–42, 77–96 applies only to registered exact paths; production registration search found no `/api/memory` registration. | Dashboard authentication is not an exact per-operation/per-profile Wing API grant. This is not an unauthenticated endpoint or a claim that OAuth bearer is categorically rejected. Do not reuse session tokens/cookies or expand Wing's fixed native RPC seam. |
| Requested profile | [Worker wrapper][U14]:50–58 enters `_config_profile_scope`; [resolver/scope][U15]:190–199, 277–320 validates an explicit existing name and binds home plus secret context off-loop. Missing/blank/`current` retains process-home semantics; this read does not use `destructive_profile`. | No caller-specific profile grant, incarnation, revision, timestamp or owner echo in success. Name validation/existence is not authorization or delete/recreate fencing. No global `profile use`/`project use` is involved. |
| Scope effects | Secondary scope activates multiplex guards and hydrates configured secret sources before binding secrets ([scope][U15]:298–320). [Hydration][U16]:167–236 can fetch external sources and cache results. | Even before status collection, zero external effects are not guaranteed. Do not trigger hydration to obtain evidence or copy resolved data. |
| Config effects | `load_config()` can enter home initialization, parse merged/defaulted config and create a last-known-good backup ([loader][U17]:2357–2439). [Home setup][U18]:27–80 can create directories, secure permissions and seed SOUL; [backup][U19]:45–67 can copy config. | GET/read naming does not mean no filesystem writes. The handler itself does not reset memory, select a provider, save provider config or call memory mutation functions. No request was issued here. |
| Provider effects | Discovery probes candidates with skill registration disabled; subsequent `_load_memory_provider(name)` uses the default loader, which permits skill registration for the configured active provider ([loader][U6]:192–222, 340–357, 424–435). Plugin isolation may use a host process. Setup reads PM currentness; declared external checks run via `shlex.split`, `shell=False`, captured output and a 20-second timeout **per command** ([setup][U3]:74–88, 91–143). | Not merely file stats: plugin imports/constructors/registration and checks can execute. No provider `initialize()` call is present in the status helpers, but arbitrary plugin behavior is not constrained by that absence. No dependency installation is called by this status path; check commands still must not be activated by this task. |
| Bounds/failures | Exactly two fixed built-in stat targets; missing files become zero. Discovery exceptions are logged and collection can continue; availability exceptions become false, config read errors may become defaults/empty data, and dependency errors become not-installed ([helpers][U3]:74–88, 132–143, 195–201, 331–373; [config][U17]:2390–2417). Invalid/unknown explicit profile yields 400/404 ([resolver][U15]:190–199). | No provider count/string/output cap, pagination, aggregate deadline, cancellation guarantee or atomic snapshot of config/files/provider status. A stat race/read error has no handler-local sanitized error envelope. Partial discovery can look incomplete rather than fail explicitly; false/zero/ready must not be promoted to a precise deletion, credential-validation or capacity verdict. |

## Desktop and Wing callers

Desktop's [API helper][U20]:107–112 calls `profileScoped()` and the generic
native bridge. [Scope helper][U21]:55–82, 192–194 tags the ambient profile and
connection; the status helper accepts no explicit owner argument and the response
contains no authoritative identity confirmation.

The [Maintenance panel][U22]:69–82 loads status on mount, ignores initial errors
and cancels completion only on unmount. Its [memory rows][U22]:319–350 display the
active label and formatted file bytes/Empty, with adjacent reset actions. It does
not display the provider list, capacity meter or external quota from this response.
Its reset → refresh sequence is mutation behavior **outside this task**, not a
recommended Wing path. No profile/connection dependency or generation fence is
present in this component's status effect; do not infer owner-change recovery from
ambient request tagging or from the unmount guard.

Wing source search at the pinned baseline found no production `/api/memory`,
`MemoryStatusResponse`, memory-status/capacity caller or model in `lib/core/hermes/`,
`lib/features/` or `lib/router/`. Existing seams remain unchanged:

- [Channel](../../lib/core/hermes/channel/hermes_channel.dart):112–143 exposes
  SOUL, health, jobs, tools and model-provider inventory, not memory-provider
  status. Model-provider credential presence is a different resource.
- [Capability model](../../lib/core/hermes/models/hermes_capabilities.dart):53–134
  supplies schema/exact endpoint/scope/profile checks, not an implemented memory gate.
- [Policy](../../lib/core/hermes/policy/hermes_transport_policy.dart):50–52 only
  reads broad `memory_write_api`; [readiness](../../lib/core/hermes/policy/hermes_surface_readiness.dart):201–207
  always defers Memory UI. Neither promises read authorization or actual capacity.
- [Fixed native reads](../../lib/core/hermes/client/hermes_web_read_rpc.dart):35–88
  do not offer generic REST/memory dispatch. [Routes](../../lib/router/routes/app_routes.dart):3–18
  has no memory destination; documented `/memory` stays planned.

## Nearest tests and sanitized evidence ceiling

Tests below were **inspected, not executed**. No new test is appropriate for this
documentation-only trace; no upstream executable was imported.

| Nearest source | What its assertions support | What remains unproved |
| --- | --- | --- |
| [Admin endpoints][T1]:211–245, 267–290 | Authenticated disposable-home status has the three top-level keys; adjacent reset/select rejection tests exist. Plugins-hub regression verifies launch-profile secret presence under multiplex for a fake provider. | No exact status row/bounds assertion, status denial/grant test, external validation or two-profile status payload isolation. Hub proof does not transfer wholesale to this GET. |
| [Profile-scope tests][T2]:301–310, 347–379 | Named status GET activates multiplex; subsequent unnamed destructive reset refuses. Adjacent provider-selection readiness is judged in target home via a mocked status helper. | No GET A→B→A payload/error isolation, same-name recreation, stale owner or actual status-helper effects test. Mutation isolation is not status authorization. |
| [Profile unification][T3]:70–83 | Adjacent config read rejects unknown profile through shared resolver. | Not a direct memory-status unknown-profile/error regression. |
| [Setup/dependency tests][T4]:14–105, 139–154 | Disposable PM listing does not prepare dependencies; incompatible/current/drifted declarations affect dependency status; authored requirements win. | Does not establish no external-check subprocess, bounded plugin work or no writes for the whole GET. Setup/install branches are inspected only, never run here. |
| [Discovery tests][T5]:90–119, 155–178, 224–246 | Project opt-in, bundled precedence, package resolution without import and skipped unreadable user plugin. | Name/directory listing is not `discover_memory_providers()`'s availability probing; no full REST error/isolation oracle. |
| [Built-in store tests][T6]:165–180, 392–409 | Overflow tool result reports character usage; externally oversized file loads with a warning, without discarding entries. | Neither a status GET capacity response nor proof that file bytes equal usage. No contents copied here. |
| [Desktop panel test][T7]:24–35, 54–85 | Memory status is a never-resolving mock while unrelated action tailing is tested. | No status error/retry, capacity rendering or delayed profile/connection replacement test. |
| [Wing regression](../../test/core/hermes/hermes_api_test.dart):809–857 | `surface readiness does not claim unwired Hermes APIs are implemented` keeps Memory UI deferred even for future flags. | Adjacent gate source only, not an executed capacity/provider contract test. |

The prior [sanitized entry-read receipt](m4-profile-memory-read-contract.md#validation-and-qualification-ceiling)
records source/review evidence, not a successful `/api/memory` request. Focused
inspection of memory-related quality pages and tracked JSON receipt leads found
no capacity/provider runtime receipt to upgrade that ceiling. No raw status rows,
provider values, memory text, content hashes or dependency-command output were
collected or reproduced.

## Validation, remaining proof and revisit triggers

- Documentation-only offline gate: source pins/clean reference, handler/model →
  helpers/effects → error/isolation tests → Desktop/Wing caller trace; changed
  Markdown links/anchors and pinned source line targets; independent
  contract/security review; `git diff --check`. No Flutter/browser/native platform,
  live authentication, provider or Agent operation was exercised.
- Fresh-context `reviewer` approved the substantive draft with no blocking findings
  (draft SHA-256 `937ee0236a42b226c94febeec6995410b578af21e95a61cd63256f725cbc0f80`).
  Review covered both changed pages, pinned Agent/Desktop helpers/auth/effects,
  nearest test assertions and Wing gates. This validation note is the only
  post-review content addition; runtime/platform qualification remains absent.
  The temporary offline validator passed both pages (82 local/pinned source
  targets and 85 cited line ranges), with all three source pins verified and the
  Agent reference clean. Final whitespace is checked on the staged documentation.
- No M4-MEMORY status change, memory writes, shadow inventory/configuration,
  fallback file reads, provider setup/OAuth/install or upstream edits. No new
  capacity operation/scope is proposed as callable.
- Remaining proof: re-evaluate only an **unmodified**, exact advertised, bounded,
  sanitized status/capacity operation with explicit grants/current profile identity
  and disclosed effects. Keep entry inventory/detail, capacity and provider
  availability independently gated; provider presence never implies credential
  validity or write authority.
- Pending live (not offline blockers): after separate admission and a suitable
  authoritative contract, use disposable state for exact read/denial, profile
  A→B→A/recreation and owner-change recovery, declared-effect observation, and an
  accessible target-native read path. No live target is authorized by this trace.
- Re-pin/review on changes to status wire schema, stats/limits, provider discovery,
  setup/probes, config loading/hydration, profile/auth middleware, advertised
  operations, Desktop status effect or Wing action/readiness gates.

## Pinned upstream source index

[U1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/ops.py
[U2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/types/hermes.ts
[U3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_memory.py
[U4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/agent/memory_provider.py
[U5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/plugins/plugin_loader.py
[U6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/plugins/memory/__init__.py
[U7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/agent/agent_init.py
[U8]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tools/memory_tool_store.py
[U9]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/memory_status.py
[U10]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py
[U11]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server.py
[U12]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/dashboard_auth/middleware.py
[U13]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/dashboard_auth/token_auth.py
[U14]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/_common.py
[U15]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_profiles.py
[U16]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/env_loader.py
[U17]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/config.py
[U18]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/config_home.py
[U19]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/config_backups.py
[U20]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/system.ts
[U21]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/client.ts
[U22]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/command-center/maintenance.tsx
[T1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_dashboard_admin_endpoints.py
[T2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_web_routers_destructive_profile_scope.py
[T3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_web_server_profile_unification.py
[T4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_web_memory_provider_setup_install.py
[T5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/plugins/memory/test_discovery_sources.py
[T6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/tools/test_memory_tool.py
[T7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/command-center/maintenance.test.tsx
