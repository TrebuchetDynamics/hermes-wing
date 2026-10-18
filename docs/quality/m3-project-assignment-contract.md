# M3 Project assignment and session binding: contract trace

Task: `DOC-M3-PROJECT-ASSIGNMENT-CONTRACT`. **Read-only source evidence, not
runtime or platform qualification.** Start with the [creation trace](m3-project-creation-contract.md),
[intended journey](../product/prd.md#core-journeys), [route status](../product/routes.md)
and [API/state boundary](../adr/api-and-state.md).

## Verdict and inspected identities

**Primary-folder assignment exists as Agent JSON-RPC, but remains unavailable in
Wing.** `projects.set_primary` selects an attached raw path; `projects.add_folder`
can attach and promote one. Neither establishes approved directory-handle
containment, current profile incarnation, expected Project revision or durable
replay reconciliation. Session workspace movement is a **separate cwd-based
operation**, not an explicit Project-ID binding. The per-profile active Project
pointer is a third, distinct operation. Do not substitute one for another.

Pins obtained with `git rev-parse HEAD` and `git -C <reference> rev-parse HEAD`:

| Inspected checkout | Revision | Meaning |
| --- | --- | --- |
| Wing baseline | `218947ab1797e03be8f2319466986fdb5cb5ce2f` | Production callers/models and nearest tests below. |
| Agent read-only reference | `158fd638da1629c8e62caf9ade1515d162def8ab` | Source only, not the identity of an installed/connected Agent. |
| Official Desktop `apps/desktop/` | `158fd638da1629c8e62caf9ade1515d162def8ab` | Same repository/commit, not a separate qualified release. |

The local coordinator slot records this task running on its assigned isolated
branch. The predecessor's closed slot records its creation receipt integrated;
that receipt is present at the Wing baseline. These are local admission evidence,
not an external tracker lease-release claim. The sanitized creation receipt was
inspected for its scope and exclusions; it contains no executed assignment or
Project-scoped Chat receipt to inherit. No personal runtime state, credentials,
network requests, upstream execution, Project assignment or Chat activation was
needed. Existing unrelated reference state is not an implementation target.

## Primary-folder assignment ledger

| Acceptance boundary | Source-bound supported contract | Absent / unavailable guarantee |
| --- | --- | --- |
| Exact operation/model | [Project models][U1]:63–123 declare `projects.set_primary {id, path, profile?}` and `projects.add_folder {id, path, label?, is_primary=false, profile?}`. Both return `ProjectResult {project}`. `projects.update` changes display fields, not the folder assignment. | No opaque directory/grant input, expected revision, caller/device binding or idempotency-key field. These are JSON-RPC contracts, not advertised messaging-HTTP Project operations. |
| Handler/identity | [Mutator registration][U2]:27–78 resolves `id` through `get_project`, calls the domain with the resolved Project ID, then reads the Project back. [Lookup/schema][U3]:28–49, 264–270 accepts ID first, then slug; created IDs are `p_` plus random hex at 231. [Profile routing][U4]:567–626 binds the explicit named profile's runtime scope; omitted/blank profile uses launch scope for sessionless Project calls. Unknown explicit profiles fail (`4064` at [dispatch][U5]:17–42). | The input named `id` also accepts mutable/reusable slugs. Explicit profile name/home is not a profile incarnation. Result rows have Project ID/slug/path metadata but no profile identity or revision. No atomic expected-identity comparison rejects a deleted/recreated profile name. Wing must preserve exact endpoint/profile/Project identity rather than use ambient scope. |
| Authorization | [WebSocket admission][U6]:139–151, 595–613 checks chat enablement, auth and allowed requests before RPC dispatch; [dispatcher][U5]:17–42 validates declared params. | No exact Project-specific caller-grant negotiation/check is declared in these Project models/handlers. Transport authentication is not Wing operation authorization. This does not assert an unauthenticated backend or constitute a complete `serve` security audit. |
| Approved-handle containment | [Path normalization][U3]:108–111 uses `expanduser` + `abspath`; [assignment][U3]:305–375 accepts normalized host path strings. `set_primary` checks membership in that Project's attached folders. | Membership is not local root approval. No opaque grant, canonical/symlink containment revalidation, revoked-root check or child-directory-only response contract here. Attachment does not require existence; its pre-normalization blank-path rejection is not established by the post-normalization check. Do not turn native picker/discovery paths into grants. |
| Commit / primary invariant | [Domain][U3]:313–375 inserts an attached folder (`INSERT OR IGNORE`), optionally updates its label, and promotes it when requested **or when no primary exists**. Promotion clears sibling primary flags and updates `projects.primary_path` inside the same [immediate transaction][U7]:99–113. `set_primary` changes only an already attached folder. Removal promotes the oldest remaining folder or clears `primary_path`. | An un-attached `set_primary` path returns `false` in the domain, but the RPC ignores that boolean and returns the unchanged Project; a successful envelope alone is not an assignment receipt. No expected revision, conflict verdict or durable changed-payload replay rejection. The mutation and handler readback are separate; readback is not proof of the exact committed revision under competing writes. |
| Cross-Project effects / retry | Assignment targets the resolved Project row and its folders, not `create_project`, a session or the active pointer ([handler][U2]:60–78). | Create-time primary-path duplicate refusal is **not** called by add/promote. Shared folder/path ownership is not uniquely constrained by the schema. SQLite serialization protects the local write transaction, not stale-client intent or replay. Unknown outcomes require authoritative reconciliation/fresh intent, never automatic retry or a new Project. |
| Errors / privacy | Project wrapper maps missing Project to `5062`, value error to `5063`, other caught exceptions to `5061` ([handler][U2]:13–43). | Raw exception text and Project results can contain host paths. Wing requires bounded allowlisted/redacted outcomes; do not display/log raw errors or publish private folder values. |

[Messaging API endpoint/capability tables][U8]:67–103, 1745–1793, 2536–2576
advertise no Project folder assignment or session-workspace-move operation. This
absence is bounded to that surface/revision, not all Agent transports or future
releases. Run-submission idempotency does not transfer to Project writes.

## Project-to-session and Chat binding is separate

1. **Active pointer is not session binding.** `projects.set_active` writes the
   per-profile `project_meta.active_id` ([handler][U2]:117–120;
   [domain][U3]:390–399). It neither assigns a folder nor moves/creates a session.
   It is profile-wide state, not permission for Wing to issue hidden global
   `project use` / `profile use` effects.
2. **New session carries cwd, not Project identity.** [SessionCreateParams][U9]:121–157
   carries optional `profile`, `cwd`, `cwd_explicit` and a session-create-specific
   `idempotency_key`, but no Project ID/revision/grant. [Cwd resolution][U10]:25–70
   may prefer a named profile's configured cwd over non-explicit client cwd and
   may fall back when local paths are invalid. [Create handler][U11]:333–493
   creates a runtime ID plus stored key; empty local drafts normally persist on
   first prompt, while seeded/explicit remote cases can persist earlier. It
   schedules agent construction: not an inert Project read or a safe readiness
   probe, even though creation is not itself `prompt.submit`.
3. **Existing-session movement is a distinct write.**
   `session.workspace.move {session_key, cwd, profile?}` returns cwd/branch/repo
   root ([model][U9]:355–367; [handler][U11]:1086–1125). It looks up a live session
   by stored `session_key`, validates a host directory (or accepts SSH absolute/
   tilde-relative shape via [workspace helper][U10]:160–170), writes cwd and
   replaces Git identity in the requested profile's session DB, then updates the
   live session and emits `session.info`. A live draft without a row can move;
   a missing row without a live session fails. It can re-home running work.
   These DB/live updates are not one atomic Project/session transaction. The
   live lookup uses the key; DB scope separately uses `profile` ([profile DB][U4]:490–521).
   This trace does **not** establish an atomic endpoint/profile incarnation/
   Project-ID/directory/revision/transport-owner comparison for this operation.
   No implicit create/send/active-pointer call occurs in the move handler, but
   this is still an explicit filesystem-context mutation, not a read to enable.
4. **There is real but narrower concurrency protection.**
   [SessionDB][U12]:558–624 increments `git_metadata_generation` with cwd writes;
   late Git enrichment publishes only for matching session/cwd/generation. This
   rejects stale metadata, including A→B→A probes. It is not a caller-supplied
   expected revision for workspace moves and does not protect Project folder
   assignment. Its absence from the move response is not permission to invent
   a revision wire field. [Live cwd helper][U10]:769–798 pins explicit movement
   against later settle-adoption; it does not supply the missing grant contract.
5. **Reported Project is derived context.** [Project resolver][U13]:2283–2296
   computes the Project from cwd using [longest attached-folder match][U3]:462–477
   (archived Projects excluded by default). It returns ID/slug/name/primary path,
   not a persisted immutable session→Project relation. Folder reassignment can
   change that derived answer. Desktop's sidebar tree also has backend-resolved
   repository/worktree grouping ([store][U14]:53–71); neither a tree bucket nor
   a matching path proves approved containment or explicit Chat authorization.

## Official Desktop and Wing callers: owner fences do not transfer

**Desktop reference outcome.** [ProjectDialog][U15]:117–133 adds a picked folder to
an existing Project via `addProjectFolder`, independently of creation. The
[store][U14]:1200–1244 sends `projects.add_folder` with captured explicit profile,
ID/path and optional `is_primary`; its optimistic cache is reconciled afterwards.
No direct `projects.set_primary` caller was found in inspected Desktop `src`.
Do not claim an existing dedicated primary-folder picker from the RPC alone.

[Context capture][U14]:297–373 rejects gateway/profile retargeting while connecting.
However [persistOrRollback][U14]:975–1004 restores its snapshot on failure without
a current-owner check, and `addProjectFolder` does not apply the post-write owner
fence used by the separate creation path. [moveSessionToProject][U14]:707–746
resolves a Project's root locally, sends only cwd/stored session key plus optional
profile through the ambient gateway helper (284–296), then updates caches without
an equivalent captured-owner completion fence. These paths do **not** establish
stale-owner-safe assignment/binding for Wing. This is a bounded source finding,
not an executed race or a claim of unauthorized upstream access.

[enterProject / goToProject][U14]:93–137 changes sidebar scope and best-effort active
pointer; entering alone never opens a session. An explicitly requested new session
is separate. [New-session cwd][U14]:139–188 uses explicit scope/root or configured
new-session workspace; existing stored conversations are not moved by entering.
[Desktop create params][U16]:341–387 send profile and cwd provenance, not Project
identity. These are UX/reference semantics, not permission to port raw-path
selection or global active-pointer side effects.

**Wing production boundary.**

- [HermesChannel](../../lib/core/hermes/channel/hermes_channel.dart):55–115 exposes
  explicit profile/session operations, no Project folder assignment or workspace
  move. [HermesSession](../../lib/core/hermes/models/hermes_session.dart):5–80
  has neither cwd nor Project/directory identity. Searches of production
  `lib/core/hermes` and `lib/features` found no `projects.set_primary`,
  `projects.add_folder` or `session.workspace.move` caller. No shadow workdir
  or profile-revision substitution is justified.
- [API session client](../../lib/core/hermes/client/hermes_api_client.dart):210–229
  sends ID/title/model/system prompt to the scoped session-create endpoint; it
  cannot bind a Project. The [channel](../../lib/core/hermes/channel/api_channel/hermes_api_channel_sessions.dart):27–161,
  320–399 separately gates exact session creation and checks caller/connection/
  profile/selection ownership before admitting results/history. Submitted writes
  may still complete at their original Agent; rejection is not rollback.
- The [native lifecycle](../../lib/core/hermes/client/hermes_web_lifecycle.dart):98–166
  creates only a clean draft with explicit profile, no caller-selected cwd or
  Project parameters. Selection generations reject late results. Its
  [fixed RPC seam](../../lib/core/hermes/client/hermes_web_read_rpc.dart):3–88
  is not a generic Project bridge. Ordinary safe session restoration does not
  qualify Project-aware Chat.
- [Metadata-only discovery](../../lib/core/hermes/local_discovery/local_hermes_home_discovery.dart):9–40
  is not an approved-root chooser. [Routes](../product/routes.md) and the
  [threat model](../security/threat-model.md#known-gaps) correctly retain the
  Project/directory/Chat gaps. Keep assignment and Project-aware Chat unavailable;
  selecting Profiles or inspecting this receipt must not create a session, send
  a prompt, choose a global Project/profile or mutate a folder.

## Nearest tests inspected, not executed

| Test source | Evidence / limit |
| --- | --- |
| [Agent Project RPC tests][T1]:17–21, 84–139, 731–761 | Direct registered-handler creation/listing, cwd→Project and session-info projection; omitted/unknown explicit-profile behavior. Despite its name, `test_add_folder_and_for_cwd` does **not** call `projects.add_folder`; no promotion/containment/revision guarantee follows. Direct `_call` bypasses transport/dispatcher. |
| [Agent Project domain tests][T2]:41–54, 68–144 | Initial primary choice, ID/slug lookup, archived path exclusion, sequential create dedup and isolated stores. These do not prove add/set-primary concurrency, grants, symlink containment or stale-owner rejection. |
| [Agent workspace-move tests][T3]:23240–23289, 23340–23363; [agent-cwd tests][T4]:127–200 | Running-session move and bound SSH cwd handling; first/restarted/deferred-build cwd propagation preserves neighboring runtime and cached prompt. DB/provider seams include fakes; not atomic authorized Project binding or live inference qualification. |
| [Agent Git generation tests][T5]:25–105 | Two handles plus a delayed worker reject old A→B→A/same-cwd metadata publication. Actual useful ordering evidence, not expected-revision authorization for a client mutation. |
| [Desktop store tests][T6]:100–135, 631–652 | Entering Project scope and add-folder requests use intended profile while viewing All profiles. Mocks do not prove post-submit owner-race protection or Agent grants/containment. Creation-only owner-race tests must not be credited to assignment. |
| [Wing caller-admission tests](../../test/core/hermes/channel/hermes_session_caller_admission_test.dart):18–183 | Synthetic open/create/restore fences reject expired callers before request or admission; restore stays GET-only and create is explicit. These are ordinary session seams with no Project binding. No new test is appropriate for this docs-only task. |

## Remaining admission bar and update triggers

This closes only the **source trace**, not M3-PROJECT or any feature gate. Evaluate
an unmodified future contract only when it independently supplies exact operation/
authorization, explicit current endpoint/profile/Project/session identities,
approved opaque directory input with canonical containment and revocation checks,
authoritative collision/revision handling, bounded redacted outcomes and unknown-
outcome reconciliation. Binding must not create/send or change global selection
implicitly; stale-owner results must never enter a replacement caller. These are
acceptance criteria, not proposed callable routes, fields or an upstream-edit task.

No compatibility adapter, shell/CLI bridge, direct-file write or Wing-owned
workspace may fill the gaps. No additional implementation task is selected here.
Revisit this receipt when the pinned models/handlers/profile routing, directory
contracts, transaction/generation logic, Desktop/Wing callers or nearest tests
change; re-pin and obtain fresh contract/security review.

## Validation and qualification limits

- Changed Markdown paths/anchors and pinned source paths/line fragments are checked
  against local source blobs; `git diff --check` is required. No upstream tests
  were executed and no product tests were added for this documentation change.
- Independent fresh-context contract/security review found no critical or
  important issues and approved documentation-only acceptance. Two minor citation
  pinpoints were corrected against source: ID minting at line 231 and the
  assignment range including normalization at 305–309. Review did not attest
  scheduler leases, executed owner races or complete runtime authorization.
- No browser, native desktop, Android/physical device, production or live Agent
  was exercised. A future runtime journey requires a separately approved
  disposable target **and** a suitable authoritative contract. Its absence is a
  capability gap, not a failed live test or permission to activate Chat.

## Pinned upstream sources

[U1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/contracts/projects_pets.py#L21-L145
[U2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/methods_projects.py#L13-L120
[U3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/projects_db.py#L28-L477
[U4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/server.py#L490-L626
[U5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/rpc_dispatch.py#L17-L42
[U6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/web_routers/chat_ws.py
[U7]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_cli/sqlite_util.py#L99-L113
[U8]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/gateway/platforms/api_server.py
[U9]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/contracts/sessions.py#L121-L367
[U10]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/session_workdir.py
[U11]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/methods_session.py
[U12]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/hermes_state_sessions.py#L558-L624
[U13]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tui_gateway/server.py#L2283-L2296
[U14]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/projects.ts
[U15]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/chat/sidebar/project-dialog.tsx#L117-L133
[U16]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/app/session/hooks/use-session-actions/index.ts#L341-L387
[T1]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/tui_gateway/test_projects_rpc.py
[T2]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_cli/test_projects_db.py#L41-L144
[T3]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/tui_gateway/test_tui_gateway_server.py
[T4]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/tui_gateway/test_session_agent_cwd.py#L127-L200
[T5]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/tests/hermes_state/test_session_git_metadata_generation.py#L25-L105
[T6]: https://github.com/NousResearch/hermes-agent/blob/158fd638da1629c8e62caf9ade1515d162def8ab/apps/desktop/src/store/projects.test.ts
