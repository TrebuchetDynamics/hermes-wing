# M4 catalog selection and profile-targeted install contract

Task: `DOC-M4-DISCOVERY-SELECTION-CONTRACT`. **Read-only source receipt; no
installation, preview request, scan request or live qualification was executed.**
Start with the [catalog checkpoint](m4-discovery-catalog-contract.md),
[M4 roadmap](../../ROADMAP.md#m4--discover-and-administer-supported-agent-work)
and [route status](../product/routes.md). This follows one official optional-skill
row from local selection to `POST /api/skills/hub/install`; it does not qualify
external hub search, removal, updates, MCP or a Wing discovery UI.

## Evidence identity and docs map

Each inspected checkout was pinned with `git rev-parse HEAD` (using `git -C` for
the references). The isolated Wing worktree has no nested reference; the permanent
read-only checkout was inspected instead, without copying or changing it.

| Source | Exact revision | Evidence ceiling |
| --- | --- | --- |
| Wing baseline | `f5ae57243702d4cce593922ba186242b78b620f5` | Callers, regression sources and sanitized documentation receipts only. |
| Agent reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Handler/model/helpers, install pipeline and nearest tests; not an installed runtime. |
| Official Desktop, `apps/desktop/` | `158fd638da1629c8e62caf9ade1515d162def8ab` | Same repository/revision; interaction and transport source, not executed parity. |

- Existing pages: catalog checkpoint above, [Tools inventory](tools-inventory-evidence.md),
  [API/state ADR](../adr/api-and-state.md), [security ADR](../adr/security-and-privacy.md).
- Source corpus: official Skills master/detail, API wrapper and action store;
  dashboard install request/handler, profile subprocess, CLI, installer/provenance
  model; Wing Tools/client/channel and nearest tests.
- Missing slice: selection is not consent to install; catalog availability and
  provenance labels grant no mutation authority. Assess consent/effects, result,
  readback and failure/no-replay separately.
- Validation: source pins, local Markdown targets, independent contract/security
  review and `git diff --check`. Documentation only: no new test or test execution.

The baseline `goals.json` records the prerequisite `DOC-M4-CONTRACT-CHECKPOINT`
as Done and this follow-up as open/Next. The [task index](../tasks/work-queue.md#current-work-queue) and
[continuation ledger](../plans/2026-10-03-desktop-port-goal.md) were checked;
historical broad ACTIVE entries are not a live lease for this file. The coordinator
assigned this exact isolated task/worktree; this receipt does not claim a live
GitHub ownership check or release another worker's scope. Upstream root/area
instructions and Wing security/authority decisions were read before inspection.

## Verdict

**The official Desktop distinguishes local row selection from installation.
The inspected Agent has a named-profile install handler, but no qualified,
exact-advertised install contract for Wing is established. Keep install unavailable.**
A successful catalog read, a preview, `skills_api`, installed `/v1/skills`, a
bearer credential or an `official`/`builtin` label cannot authorize this POST.
Do not acquire a dashboard credential, retarget Wing's installed-inventory decoder,
add a shell bridge or build a shadow catalog to fill the gap. This is an evidenced
contract gap at these revisions, not a claim that Hermes cannot install skills.

## Selection is not search, preview is not installation

| Step | Actual official Desktop behavior | Boundary / missing proof |
| --- | --- | --- |
| Filter | [Skills data][D1]:35–48 filters already-loaded catalog name, description, category and tags and sorts A–Z. [Tab][D2]:114–124 first excludes installed identifiers and installed-name collisions. | Local metadata filtering is not `/hub/search`, an install request or authoritative absence. The prior catalog receipt retains unreadable-lock ambiguity. |
| Select | [Tab][D2]:137–145, 326–354 stores the row's `identifier` in component state and mounts its detail. If filtered out, the active official row becomes null, not the first available official row. [Row][D3]:469–496 separates selection and action controls. | No POST on row selection. Selection is presentation state, not an Agent profile/Project change or durable installation choice. |
| Preview | [Detail][D4]:31–36 invokes `previewSkillHub(identifier, profile)` with a scope-keyed query, five-minute stale time and `retry: false`. [API][D5]:132–138 sends `GET /api/skills/hub/preview?identifier=…`. | Selection can trigger a read, so it is not zero-I/O. [Handler][U1]:228–269 resolves metadata **and fetches a bundle**, returning SKILL.md and manifest names, not installing it. [Official source][U2]:97–146 can use live-repo/upstream-pointer fetches even for an official identifier. Do not claim preview is local-only, inert metadata or revision-pinned. |
| Install | [Tab][D2]:147–152, 326–344 and [detail][D4]:56–60 expose separate explicit **Install** buttons; each calls the same `installHubSkill(identifier, profile)`. | No confirmation modal, preview-success prerequisite or scan-approval prerequisite is wired into these buttons. They disable while the identifier is marked running. The optimistic “install started” notification precedes acknowledgement, not commit. |

The preview handler has no install call, but does not establish response byte/file
bounds or a digest binding the displayed preview to the later fetched install
bundle. The detail only renders loading/content, with no explicit preview-error
presentation, and Install remains enabled on preview failure ([D4]:31–36, 56–60,
71–83). These are source observations, not executed accessibility or error journeys.
External search and the separate scan endpoint are not activated or qualified here.

## One exact install contract, traced without invoking it

| Acceptance dimension | Supported source behavior | Missing guarantee / Wing disposition |
| --- | --- | --- |
| Operation/model | [API wrapper][D5]:148–155 sends POST `/api/skills/hub/install`, body `{identifier}`, with the capability scope. [Request model][U3]:418–420 has `identifier: str` and optional `profile`. [Handler][U1]:98–104 strips/requires a nonempty identifier and spawns `skills install <identifier> --yes`. | No bounded identifier schema, expected content digest/revision, consent receipt, idempotency key or durable operation ID in that model. Other sources/URLs are accepted by the generic pipeline; catalog membership is not enforced as authority. |
| Target | Handler chooses body profile first, then query. [Profile helper][U16]:438–450 validates an explicit existing name, including `default`, and prepends `-p <name>`. [Spawn environment][U5]:340–414 scrubs inherited profile secrets and pins the named target home; a fresh child reaches import-time skill paths. Desktop [scope helper][D6]:216–253 carries explicit connection/profile and scoped cache identity; [routing helpers][D7]:1020–1100 propagate profile query/backend routing. | Omitted/blank/`current` retains ambient semantics, not a safe Wing target. Named lookup is not a caller grant, immutable profile incarnation, expected revision or delete/recreate fence. No echoed profile identity in the spawn response. No global `profile use` or Project assignment is needed by this path. |
| Authorization | Dashboard [middleware][U6]:696–726 protects non-public `/api/` routes through its authentication seams. | Handler/model declare no exact install grant/capability descriptor for Wing. API-server [capability table][U7]:67–103 advertises installed GET `/v1/skills`, not hub install/preview or action status. Dashboard authentication, Desktop's scope-helper name and API-server credentials are not interchangeable authorities. |
| Consent/effects | The explicit Desktop button is user intent to start installation. CLI [dispatch][U8]:1387–1389 maps `--yes` to `skip_confirm`; [pipeline][U8]:743–787 still quarantines, scans and checks policy without `--force`. | `--yes` skips the CLI's [disclaimer/confirmation][U8]:649–673, 774–776. Desktop's official detail shows metadata/preview, not that disclaimer, target/effect summary or content-bound consent. Scanning is not consent or a safety guarantee: [policy][U9]:26–35, 724–739 allows all `builtin` verdicts, including dangerous. |
| Initial result | [Spawn helper][U10]:104–112 returns `{ok: true, pid, name}` after process creation. [Spawner][U5]:453–503 detaches the child with stdin closed and output appended to a registered action log. | HTTP 200 / `ok` means spawned, not installed, enabled or available to an existing session. No transactional receipt or revision; a child can continue after the client leaves. |
| Readback | [Status][U11]:346–400 returns process `running`, `exit_code`, PID and log lines. [Desktop store][D8]:85–149 polls every 1.2 seconds, flips an optimistic installed override only for exit 0 and invalidates installed-list, catalog and hub-source queries. Agent's [installer][U12]:143–203 moves files, hashes installed content and records provenance/scan verdict plus audit/usage metadata. | Process exit and invalidation are not an awaited exact-profile authoritative readback. [Lock model][U13]:274–350 is mutable file provenance, not a durable command receipt; corrupt/unreadable reads become empty. Catalog flags alone do not prove files present, enabled or matching the preview. Skill-install status has no structured commit/readback receipt; the status route's durable receipt special case is **Hermes update**, not skill install. |
| Failure/no replay | Invalid/missing named profile produces 400/404 before spawn ([U4]:190–199; [U16]:438–450); empty identifier is 400 ([U10]:115–120). Spawn exceptions become 500 with exception text ([U10]:87–112). Desktop store has one spawn call followed by status reads; nonzero status rejects without painting installed, and profile-switch epochs drop obsolete store results ([D8]:54–170). | Raw exception text/log tails are not bounded, allowlisted path/content-free diagnostics. Unknown exit/null can settle without an installed override or explicit unknown-outcome error. No cancellation/rollback, atomic install transaction, revision check or durable deduplication is established. Never infer “failed means unchanged” or replay after uncertainty. |

### Effects and failure oracle limits

The Agent pipeline can fetch network content, create hub/quarantine/scan-cache
state, and move a validated bundle into the selected profile's skills tree.
An existing lock entry skips a normal install without `--force`, but the
[installer][U12]:158–186 can replace an existing skill directory after target
checks. Move, content hash, provenance write and audit append are sequential,
not one atomic transaction. A later error therefore does not prove zero effects
or safe rollback. Do not remove/reinstall automatically to simulate recovery.
After success it can offer a blueprint suggestion (not schedule it), record
installation metrics/lifecycle and clear the **child's** prompt cache
([pipeline][U8]:564–589, 676–708, 784–787; [cache helper][U8]:113–131).
This does not prove a running Agent session reloaded its skills. Desktop's footer
says changes apply to new sessions ([D2]:347); persistence and activation remain
separate evidence cells.

There is also a concrete **exit-code oracle gap**: `_install_skill` returns normally
for missing fetch, blocked scan and an already-installed name ([U8]:719–765).
`do_install` records an outcome but returns no status; `skills_command` and
[`cmd_skills`][U14]:172–184 do not turn those outcomes into a nonzero return.
[`main`][U15]:3717–3723 treats None as success. Thus a printed refusal can take a
normal-success exit path at this pin. Desktop's mocked nonzero-exit tests do not
prove that a real refusal yields nonzero. This is source evidence only, not a
newly executed failure or an upstream patch request.

No durable no-replay contract is established by the deterministic
[action name][U16]:453–461: it is derived from verb + identifier, not profile,
request identity, consent or payload revision. [Spawner][U5]:494–502 replaces
in-memory entries without a skill-install deduplication guard. Repeating the POST
can spawn again; losing the response must not authorize repeating it. Desktop's
[transport policy][D9]:75–160, used by [`fetchJson`][D10]:5673–5680, 5769–5785,
does conservatively avoid retrying ambiguous sent POSTs, while allowing bounded
retries when provably unsent. That is a transport guarantee, not durable Agent
idempotency or authorization for manual retry/reconnect replay.

## Nearest tests and Wing callers (source-inspected, not executed)

| Seam | Evidence | Ceiling / absent oracle |
| --- | --- | --- |
| Profile install handler | [Profile tests][T1]:128–196: named install emits exact `-p … skills install … --yes`; unknown name returns 404; explicit default pins the default home despite a named launch profile. | Spawn is mocked. Not an actual two-profile install/readback, grant denial/revocation, concurrent writer, incarnation or crash/replay test. |
| Preview | [Dashboard tests][T2]:695–725: byte SKILL.md decoding/manifest and unresolved 404. | Mocked resolver, omitted profile. Not revision binding, response bounds, network consent or zero-write/cache-effects proof. |
| Install effects | [Installer test][T3]:1871–1908: quarantined skill becomes a directory and usage recording is called. [Guard tests][T4]:97–120 explicitly allow builtin/dangerous and deny forced dangerous community/trusted. | Not HTTP receipt/readback, atomic rollback, or session activation. CLI [fetch-failure tests][T5]:595–635 assert printed failure text, not process exit status. |
| Desktop action/failure | [Catalog test][T6]:424–498 checks available rows, installed/name filtering and explicit Install forwarding identifier + a scope. [Store tests][T7]:39–91 check mocked nonzero failure/no override and exit-zero override. [Transport tests][T8]:101–118, 158–178 reject ambiguous-sent POST retries. | No tested selection→preview→install consent binding, exact profile assertion in that catalog test (`expect.anything()`), real scan-refusal exit, durable readback or end-to-end no-replay. Store test stubs the profile subscription. |
| Wing installed reads | [Tools](../../lib/features/tools/screens/tools_screen.dart):126–218, 283–322 only composes installed Skills/Toolsets and owner-gated refresh. [Client](../../lib/core/hermes/client/hermes_api_client.dart):91–105 decodes installed `data`; [state policy](../../lib/core/hermes/channel/hermes_channel_state.dart):210–214, 270–284 gates exact read/schema/declared grants/profile context. No hub install/preview caller was found in Wing `lib/` or Dart tests. | No catalog-selection/install model, action-status receipt or replay path to qualify. Keep the installed model separate; read availability is not write authority. |
| Wing regressions | [Tools tests](../../test/features/tools/tools_screen_test.dart):62–84, 633–766 assert supported tabs, bounded failure and denied/unavailable inventory; [channel test](../../test/core/hermes/channel/hermes_api_channel_test.dart):1745–1783 issues exactly installed skills/toolsets refresh GETs. | Synthetic installed-read fixtures, not discovery, install denial, consent or mutation readback tests. Existing independent read support remains intact. |

## Disposition, review and update triggers

This completes the bounded source-contract assessment, **not M4-DISCOVER,
installation support or parity**. Only documentation changes; no Agent/Desktop
or Wing tests ran, no SDK was installed, no credentials or runtime state were
read, and no platform/native/browser/live journey was exercised. The sanitized
catalog receipt was inspected as history, not substituted for current source.
The [Agent immutability boundary](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent)
and independent Tools/Schedules/Connections read gates remain unchanged.

Revisit when an unmodified connected Agent advertises this exact operation with
verified authorization and explicit current profile identity, or when the traced
selection/preview/install/result contracts change. Re-pin all sources and repeat
independent review. Future acceptance must bind fresh user intent to the exact
profile/content/effects, distinguish spawned/committed/activated/unknown, perform
sanitized authoritative readback and prove no mutation replay after timeout,
reconnect, denial/revocation or owner replacement. These are requirements, not
proposed wire fields, granted permissions or implementation authorization.

Pending live, only after an eligible authoritative contract exists and a separately
authorized isolated target is available: authenticated install/denial and exact
profile readback; failure/uncertainty/no-replay and named-platform accessible
selection/consent/recovery journeys. No installation is authorized by this receipt.

Independent contract/security review: a fresh-context `reviewer` checked the
receipt against pinned Agent/Desktop/Wing sources and nearest tests. Approved for
bounded source-only conclusions with no blockers; one low-priority finding about
misaligned Desktop line citations was verified and corrected before commit.
This is task review, not a security audit or live/platform acceptance.

## Pinned upstream sources

[D1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/capabilities/skills/skills-data.ts#L35-L48
[D2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/capabilities/skills/skills-tab.tsx#L82-L359
[D3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/master-detail.tsx#L444-L508
[D4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/capabilities/skills/official-skill-detail.tsx#L18-L83
[D5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/skills.ts#L132-L155
[D6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/api/client.ts#L216-L253
[D7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/electron/connection-config.ts#L1020-L1100
[D8]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/hub-actions.ts#L54-L174
[D9]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/electron/api-transport.ts#L75-L160
[D10]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/electron/main.ts#L5673-L5785
[U1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/skills.py#L98-L269
[U2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tools/skills_hub_official.py#L97-L146
[U3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_models.py#L418-L420
[U4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_profiles.py#L190-L199
[U5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_gateway.py#L340-L503
[U6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server.py#L696-L726
[U7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py#L67-L103
[U8]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/skills_hub.py
[U9]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tools/skills_guard.py
[U10]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/_common.py#L87-L120
[U11]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/actions.py#L346-L400
[U12]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tools/skills_hub_install.py#L143-L203
[U13]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tools/skills_hub.py#L274-L350
[U14]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/main_agent_cmds.py#L172-L184
[U15]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/main.py#L3717-L3723
[U16]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_server_profiles.py#L438-L461
[T1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_web_server_skills_profiles.py#L128-L196
[T2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_dashboard_admin_endpoints.py#L695-L725
[T3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/tools/test_skills_hub.py#L1871-L1908
[T4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/tools/test_skills_guard.py#L97-L120
[T5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_skills_hub.py#L595-L635
[T6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/capabilities/index.test.tsx#L424-L498
[T7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/hub-actions.test.ts#L39-L91
[T8]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/electron/api-transport.test.ts#L101-L178
