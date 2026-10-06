# Desktop continuation — session model read authority, 2026-10-04 01:47

## Result

**The inspected Agent API does not provide a readback of a session's confirmed
provider/model lock.** It advertises a model-lock POST and an exact-session GET,
but that GET deliberately projects model text and presence flags, not provider,
runtime or lock confirmation. Decoding the synthetic fixture's extra `runtime`
field would make the browser pass against a contract this reference does not expose.
No production fix, synthetic lock restoration, mutation replay or upstream edit
is authorized by this assessment.

This conclusion is bounded to the inspected `api_server` source at Agent
`158fd638da1629c8e62caf9ade1515d162def8ab`. It is not a negative claim about every
Agent transport, installed version or future advertised capability. Native-web
qualification remains a separate, unenabled production path; no transport migration
or privileged native implementation is proposed here.

## Ownership and scope

The [goal ledger](../plans/2026-10-03-desktop-port-goal.md) and prior occurrence's
final session release ownership. Fresh `hermes cron list` showed this continuation
running, hourly autogoal completed. Native terminal/delegation lists were empty;
OS QA census found no competing command. Single-owner source assessment leased
only ledger, this receipt and wing scratch evidence. No workers were dispatched.
Todo capability used the exposed `todo_list`; OMH-specific routing/accounting
wrappers were not exposed and were unnecessary for this direct research task.

All implementation, tests, fixture, ROADMAP and references stayed read-only.
Desktop's pre-existing deleted `.claude` entries were preserved. Agent was clean;
Desktop remained dirty. HEAD alone is not a snapshot of Wing's dirty content.
No Flutter, browser, upstream tests, builds, installs, inference, personal runtime,
credentials, cards, commits, releases or scheduler mutations were attempted.

## Indexed contract trace

1. **Advertisement and operation.**
   [Agent capability table:79–102](../../hermes-agent/gateway/platforms/api_server.py)
   advertises `session` GET `/api/sessions/{session_id}` and `session_model_lock`
   POST `/api/sessions/{session_id}/model`. The registered route table:1745–1772
   matches those paths. There is no dedicated session runtime/model-lock GET in
   this table. `/api/model/options` is profile picker inventory, not a session read:
   handler:2518–2534 builds from `load_picker_context`, with no session identifier.
   Capability response:2536–2575 advertises bearer authentication and does not
   declare a session runtime-read operation or per-endpoint grant list.
2. **Authentication/profile/session identity.**
   [Agent auth:989–997,1586–1608](../../hermes-agent/gateway/platforms/api_server.py)
   validates the request's expected bearer key before the session handler.
   Named profiles without a scoped key fail closed. Profile middleware:1675–1734
   resolves `/p/<profile>/`, rejects unserved identities, and enters that profile's
   runtime scope. This is not evidence that the fixture's `?profile=` advertisement
   applies to this unmodified source. Session lookup:3063–3070 resolves the exact
   ID in the scoped database and distinguishes absent database (503) from absent
   session (404). GET handler:3213–3219 calls the client-safe projection.
   No live auth, revocation or profile-recreation experiment ran.
3. **Read projection — decisive boundary.**
   [Agent `_session_response`:3011–3043](../../hermes-agent/gateway/platforms/api_server.py)
   includes `model` but not `provider`, `runtime`, `model_lock` or
   `browser_model_lock`. It deliberately omits full `model_config` and system
   prompts, returning presence flags plus an internal-child provenance bit.
   `has_model_config` is not confirmation of a lock or a provider identity.
4. **Acknowledged write versus persisted server behavior.**
   [Agent lock handler:3797–3826](../../hermes-agent/gateway/platforms/api_server.py)
   checks the session, persists the requested lock and returns bounded runtime
   identity with `model_lock: accepted`. Internal persistence/reuse:2093–2159
   stores the confirmed pair inside `model_config.browser_model_lock` and avoids
   rewriting a reused stored lock. That internal implementation is not a client
   read API. Turn metadata may report actual runtime, but observing an old run
   does not establish the current session lock after later external changes.
5. **Wing consumes metadata but has no authoritative restored lock read.**
   [Client GET:153–162](../../lib/core/hermes/client/hermes_api_client.dart)
   requires the exact returned session ID. [Session decoder:31–55](../../lib/core/hermes/models/hermes_session.dart)
   preserves model text, not runtime/provider/lock.
   [Restoration:15–54](../../lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart)
   gates exact GET/history operations and rejects stale connection/profile/session
   selection results. [Provider channel:172–221,358–366](../../lib/core/hermes/channel/api_channel/hermes_api_channel_providers.dart)
   adds a session lock only after POST acknowledgment and rejects late connection/
   profile generations. [Profile connection:118–139](../../lib/core/hermes/channel/api_channel/hermes_api_channel_profiles.dart)
   clears volatile locks. No durable lock cache or read restoration seam was found
   in these consumed paths. A future read would also need exact session-selection
   fencing, not merely the existing provider-operation profile fence.
6. **Picker consequence.**
   [Chat opening:1197–1233](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart)
   supplies only an accepted exact-session entry from `sessionModelLocks`.
   [Picker:33–60](../../lib/features/hermes_chat/widgets/session_model_picker_sheet.dart)
   otherwise selects the catalog current pair. After reload, `beta/shared` is
   therefore a catalog draft, not recovered session identity. Existing model-label
   restoration correctly displays metadata but must not manufacture an accepted
   pair. This explains the [previous failed browser step](2026-10-04-desktop-cron-0117-selector.md)
   without proving a server-side model reset.
7. **Fixture exceeds the inspected read contract.**
   [Daily fixture:84–87](../../playwright/support/hermes_lifecycle_fixture.mjs)
   attaches an accepted runtime to its in-memory session.
   [Server metadata:145–147,490–518](../../serve_web.mjs) spreads remaining fields,
   so the synthetic exact GET returns that runtime. Catalog:237–244 deliberately
   returns `beta/shared`. The test-only receipt:233–235 also returns `selected`;
   it is not a production API. Advertising an invented read endpoint, restoring
   from that receipt, or changing the catalog to hide this mismatch is not a fix.
8. **Desktop outcome uses a different authority mechanism.**
   [Desktop Chat:370–408](../../hermes-desktop/src/renderer/src/screens/Chat/Chat.tsx)
   restores a local per-session override and uses `persist:false` for the picker.
   [Desktop store:5–74](../../hermes-desktop/src/main/session-model-override-store.ts)
   creates `desktop_session_model_overrides` and reads/writes provider/model/base
   URL through local database access. This explains the reference user outcome,
   but copying its privileged store would create prohibited shadow state in Wing.
   Desktop reference HEAD: `2ed89070bc6c9e8231a37bb55df8a7722a3776b8`.

## Inspected tests, not executed test results

- [Agent session tests:83–112](../../hermes-agent/tests/gateway/test_session_api.py)
  require omitted model configuration and safe delegate provenance. Tests:776–913
  inspect persisted lock reuse on Chat/stream; tests:916–1004 distinguish actual
  runtime and reject confirmed mismatches. These do not assert a restored-pair GET.
- [Agent multiplex tests:35–75](../../hermes-agent/tests/gateway/test_multiplex_api_server_routing.py)
  inspect unserved-prefix rejection and scoped model identity.
- [Wing session-model tests:19–117](../../test/core/hermes/channel/hermes_api_channel_tests/session_model_tests.dart)
  cover accepted/rejected scoped writes, missing grants/unknown sessions and stale
  reconnect/profile results, not authoritative lock restoration from a read.
- [Desktop store tests:91–124](../../hermes-desktop/src/main/session-model-override-store.test.ts)
  inspect local routing persistence/clear behavior with a fake database.

No upstream test runner was invoked: doing so might write inside read-only
references and was unnecessary for this source prerequisite. `lat` is not on PATH;
no Desktop semantic search, installation, wiki update or `lat check` ran. This
occurrence changed no Desktop functionality and makes no Desktop verification claim.

## Executed evidence and limits

Scratch: `/home/xel/.hermes/profiles/wing/cache/scratch/desktop-cron-0147-runtime-pair/`.

- Admission `git status --short --branch`, QA process census, `hermes cron list`,
  reference Git status/HEAD commands: exit 0; output observed directly.
- Python AST inspection of the actual capability table and `_session_response`
  allowlist: exit 0. `authority-source-check.json` records no dedicated runtime
  GET candidates and no projected provider/runtime/lock key. This is static source
  evidence, not handler execution, an exhaustive parser run or runtime capability
  discovery. No Agent imports, execution or monkey-patches were used.
- Closing manifest/document gate: exit 0; 1,515 source hashes unchanged, 21 local
  links resolve, whitespace and scoped `git diff --check` pass. `checks.json`
  records the observed result. No complete suite replay occurred because no
  product/test sources changed.

## Ranked next steps and exit criteria

**P1 — stop interpreting a catalog draft as a restored session pair.** The confirmed
pair restoration itself is blocked on a supported advertised read contract, not
on adding a decoder for synthetic `runtime`. Keep the existing integrated picker
oracle and failed status intact. A dependency-ready bounded next task is a genuine
widget regression documenting that metadata-only restoration cannot assert a
confirmed provider/lock or emit a mutation, including identical model IDs across
providers. First lease only a new
`test/features/hermes_chat/screens/hermes_chat_model_authority_test.dart`, ledger
and new receipt; consume the production channel and existing restoration harness
read-only. Run the focused target once under exclusive Flutter ownership. Capture
actual result and zero submits/locks/creations; no intentionally false RED and no
browser retry. If current UI misrepresents confirmation, separately lease a minimal
presentation/copy fix only after intended behavioral RED, preserving original
browser confirmation/restoration/count assertions. Do not expand this into an
invented transport contract.

**P2 — exact provider/model restoration requires a separately verified contract.**
Revisit on changed Agent discovery/source or reviewed native integration authority.
Before implementation, prove exact origin/profile/session, bounded safe fields,
acknowledgment versus effective runtime semantics, authorization/revocation,
profile recreation and stale-selection fencing. Missing/error read must remain
unavailable, never fall back as confirmed identity. No model-name-to-provider
inference, persisted shadow pair or repeated model POST during recovery. Current
source alone cannot meet these criteria; no upstream modification is permitted.

Native/live/independent review and full integrated Escape/resume/count acceptance
remain open. This is a newly attributed contract blocker, not a third unchanged
browser retry. No owned QA service/process was started; none needs cleanup.

Run summary: not_available — host accounting was not exposed.
