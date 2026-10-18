# Bounded desktop-local integration design

## Backlog connection

Disposition: **source-reviewed proposal; no privileged implementation authorization**.
Owner: `DOC-NATIVE-DESIGN-REVIEW`. The dependent
`DOC-NATIVE-FAILURE-BOUNDARY` task still owns deeper failure-containment review;
this document does not execute or close that task. See the
[task bodies](../../TODO.md#now--next) and
[plan-to-task coverage](README.md#plan-to-task-coverage).

The [contract/security evidence](../quality/native-local-integration-contract-review.md)
records source identities, exact handlers/models, nearest tests, Wing callers,
independent review and qualification limits. The original 2026-10-03 proposal is
preserved in [Git history](https://github.com/TrebuchetDynamics/hermes-wing/blob/fd0289808ab5a245f67760ccf3d8d44f8ec351be/docs/plans/2026-10-03-desktop-local-integration-design.md),
not implementation authority. Its separate-Desktop comparison was
[withdrawn](../quality/official-desktop-reference.md#withdrawn-evidence).
Its suggested Link reuse, setup/pairing and compatibility adapters are superseded
by the living ADRs, not deferred fallback options.

## Review conclusion

**Narrow the first host-local operation to the existing Linux metadata-only
Hermes-home inspection and deliberate native folder chooser.** No process broker,
installation/version probe, new coordinator, daemon or management service is
needed for this operation. The chooser is ephemeral and is not an Agent Project
selector, directory grant, runtime selector or proof of an installed/running Agent.
It must not bind the authenticated endpoint to the selected folder.

The next user action remains explicit authentication to an independently prepared
Agent through existing Wing connection composition. Saved Agent credentials stay
in platform secure storage; missing credentials require direct reauthentication.
Do not scan Agent files, adopt Desktop's backend ledger/token discovery, mint keys,
configure a gateway or start a process to make Connect succeed.

The official Desktop outcome is local connection to its Agent backend, including
owned launch/attach and recovery. Wing's metadata-only/manual preparation is a
**remaining product gap**, not full Desktop parity. Official
`apps/desktop/electron/preload.ts:39-46` and
`main.ts:15581-15658` route connection requests to backend resolution;
`backend-command.ts:20-26` builds `serve` arguments. These are interaction/source
references, not authorization to copy privileged Electron IPC.

Binding decisions: [product](../adr/product.md), [client](../adr/client.md),
[API/state](../adr/api-and-state.md), [runtime/delivery](../adr/runtime-and-delivery.md),
[security/privacy](../adr/security-and-privacy.md),
[threat model](../security/threat-model.md) and [security policy](../../SECURITY.md).
No living decision is changed by this review.

## Already authorized versus proposed or unavailable

“Existing” below means present source under existing gates, not newly executed
native/live qualification. The [route status](../product/routes.md) remains the
current support index.

| Operation | Disposition and authority | Fixed input / identity | Secret acquisition |
| --- | --- | --- | --- |
| Linux default Hermes-home discovery | Existing metadata-only Wing/OS operation; first bounded slice | `LocalHermesHomeDiscovery.inspectDefault()`; Linux device HOME, no caller executable or flags | None |
| Choose alternate Hermes home | Existing native chooser followed by metadata inspection; not host browsing | `getDirectoryPath()` → `inspectSelected(directory)` only after deliberate local selection; volatile panel generation | None; path never becomes credential/runtime authority |
| Connect an already prepared Agent API | Existing direct authenticated `HermesChannel.connect`; exact advertised operations/grants remain required | Normalized origin, explicit connection attempt, then Agent profile/session/run identities; no folder parameter | User-supplied Agent credential or same-origin saved Agent credential from secure storage; no legacy management slot |
| Read an already-running local serve backend | Existing separate native REST surface, not gateway API fallback or launch | `connectLocalServeReads(baseUrl, credential)`; numeric loopback origin, explicit profile and stored session reads | User-supplied credential accepted by that surface; read connection alone does not save a gateway record |
| Enable fixed chat on that serve session | Existing separate ticket/negotiation gate, not permission derived from REST success | `connectLifecycleForProduct()`; exact stored/runtime owner; exclusive-submit and approval-request negotiation | Authenticated dashboard Session credential → fresh one-use ticket in WS subprotocol, never URL; static local token does not satisfy this mint contract |
| Remember/recover deliberately enabled serve chat | Existing secure exact-owner pointer and reconciliation barrier; not domain-state storage | Origin/profile/stored/runtime identities and uncertainty fence; canonical history/replay before input | Dedicated secure recovery slot; not a gateway credential conversion |
| Select a saved local connection through a new coordinator | Old proposal withdrawn as unnecessary for first slice | Reuse existing form/directory/channel owner fences; no new public host method | No new secret reader |
| Launch/attach/stop/install/update Agent | **Unavailable for this proposed local slice**; privileged design/security decision still required | No Wing executable/argv/cwd/env/port interface admitted; official Desktop shape is evidence only | No acquisition, environment-token copying or token URL fallback authorized |
| Profile/provider/config/Project/directory/memory/admin writes | Only individually advertised, authorized Agent operations already supported by Wing; no new native administration | Explicit resource identities, authoritative concurrency/idempotency; no raw keys, paths, generic RPC or global `profile use` / `project use` | Provider secrets require exact write-only secret-safe Agent API; no file/CLI compatibility fallback |

No operation here reintroduces Wing Link. Inert raw legacy records and management
secure slots remain preserved and unused. Android manual Termux preparation, SSH
forwarding, remote access, file export and other OS integrations retain their own
existing gates; Linux source review does not extend them.

## Fixed shapes and bounds

### First operation: existing metadata inspection

```text
inspectDefault() -> LocalHermesHomeInspection
inspectSelected(directoryFromLocalChooser) -> LocalHermesHomeInspection
LocalHermesHomeInspection = {status, canonicalPath?}
status = supported | unsupported | absent | notDirectory | unreadable
```

Source: `lib/core/hermes/local_discovery/` and
`lib/features/hermes_chat/widgets/platform_local_connection_panel.dart`.
`inspectSelected` is an internal local-chooser seam, **not** an arbitrary-path API
for a remote caller, URL/deep link, Agent request or future process bridge.

- Linux only. Default is the platform user home plus `.hermes`; invalid/missing
  HOME does not fall back to cwd. Selected input must be absolute, at most 4096
  characters, with no C0 or DEL characters.
- IO resolves symlinks and stats the canonical directory; it does not enumerate,
  read contents or execute anything. Canonicalization is not containment/ownership
  proof: symlinks may resolve outside the original folder. No authority is granted.
- Only the ephemeral local UI receives the canonical path. No path persistence,
  remote transmission, diagnostics, Project assignment or credential association.
- Panel generation/mounted/enabled checks reject late default/chooser/inspection
  results. One chooser is active at a time; mode changes and disposal invalidate
  result admission. Cancellation neither connects nor saves.
- **Unavailable guarantee:** the current metadata seam has no explicit IO deadline,
  hard cancellation or output-path-size bound after canonicalization. Validation
  of input length is not a bound on the resolved path or OS latency. Any expansion
  must address these in the dependent failure-boundary review; this review does
  not assert the old helper's 30-second/256-KiB limits apply.

### Direct connection and native serve are separate contracts

API requests use their exact advertised method/path/schema, every required grant
and current resource identity. An installed handler or broad admin/version flag
is not runtime advertisement. Origin changes must not reuse another origin's
credential. Secure persistence success and authenticated connection success are
separate outcomes.

Existing native read client bounds: origin `http` with numeric `127.0.0.1` or `::1`,
no userinfo/query/fragment/non-root path; profile/session grammar
`^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$`; supplied credential nonempty, at most 8192
characters, no CR/LF; timeout positive and at most 30 seconds (default 10);
response maximum 1 MiB, at most eight concurrent HTTP requests. Redirects/proxies
are not credential-forwarding fallbacks. These are Wing client bounds, not Agent
or OS guarantees.

`POST /api/auth/ws-ticket` with `{}` uses Authorization for the selected dashboard
Session; response ticket/TTL must validate. Upgrade is `/api/ws` without a secret
query, offering `hermes-gateway-v1` and `hermes-gateway-ticket.<ticket>`; only the
stable protocol may be selected. `gateway.capabilities {}` must report
`per_session_exclusive_submit: true`; `client.capabilities {server_requests: true}`
must support approval requests. No invented `profile` negotiation field.

Existing recovery calls `session.resume {profile, session_id: stored, lazy: true}`,
then exact-runtime replay/history barriers. This is not a new admission of every
resume mode: default/eager/cold hydration and Agent-owned continuation must not be
inferred passive. Product entry exposes bounded text submit, current once/deny
approval and runtime interrupt, not arbitrary RPC, config/model-default writes,
new-session creation or attachments. The API session-model contract and native
model operations must be reviewed independently; catalog/model text alone cannot
prove a restored effective provider/model pair.

## Failure and recovery contract

| Failure or transition | Required/current behavior | Guarantee not established here |
| --- | --- | --- |
| Missing/not-directory/unreadable/unsupported metadata | Enum-only UI state; explicit chooser/manual connection remains separate; never launch or claim readiness | Installation/authentication/readiness from a directory result |
| Permission error, changed symlink, slow IO | Sanitize exception; re-inspect metadata each call; stale results rejected | Filesystem snapshot, hard cancellation, containment, fixed completion time |
| Chooser cancel, mode change, disposal | Preserve current connection/draft; discard late path result; no save or Agent action | Cancellation undoing OS work already in progress |
| Missing/locked secure storage or absent credential | Explain and require explicit unlock/direct authentication; no plaintext or legacy management recovery | Hardware-backed storage or successful OS keyring access on any named target |
| Wrong origin/profile/session, stale form/owner | Reject adoption; no automatic fallback to another endpoint/session or global profile switch | An in-process type boundary containing compromised Wing/same-user malware |
| Native ticket denied or negotiation missing | Reads do not acquire write authority; fixed chat unavailable; explicit retry only | Static dashboard token, gateway key and dashboard Session interchangeability |
| Lost Send/approval/Stop acknowledgment or socket loss | Preserve uncertainty; exact-owner canonical reconciliation; no implicit mutation replay or alternate-transport resend | Stop receipt as terminal result, detached-run durability or zero Agent-owned continuation |
| Save/reload/connection partial result | Report the operation actually observed, not rollback or readiness by inference; retain saved identity | Transactional rollback of Agent state or setup/restart, none of which this slice performs |

No raw exception, stdout/stderr, private endpoint/path, transcript or credential
belongs in diagnostics. No operation is activated, no credential acquired, and no
personal runtime or secure slot inspected in this task.

## Admission, rollback and removal criteria

1. **Retain first-slice boundaries.** Changes to metadata inspection must reuse the
   existing providers/platform seam and its public regressions. Expanded path,
   process, secret or persistent authority requires a separate operation review,
   not another method on a general broker.
2. **Privileged implementation remains gated.** The next design/security decision
   must name one official Desktop outcome and an unmodified installed-Agent
   handler/model plus nearest tests and Wing caller; fix executable/argv and
   environment authority, resource identity, private credential acquisition,
   consent, concurrency/idempotency, bounded failure/cleanup and removal trigger.
   Do not manufacture a contract by patching Agent or using direct files.
3. **Disable rather than broaden.** Metadata UI can be removed/disabled without
   migrating saved Agent identities/credentials or stopping Agent. If a selected
   transport loses its required contract, its operation stays unavailable; do not
   downgrade authentication or retry writes through another surface.
4. **Replacement/removal triggers.** Supersede manual metadata guidance only after
   an exact safe Agent contract and separately reviewed Wing implementation are
   qualified. Retire any future narrow adapter when an equivalent authoritative
   API is qualified, or disable it on contract/auth/identity drift. Removal must
   preserve saved access and inert user records; never delete personal runtime
   state. There is no shipped coordinator/helper in this proposal to sunset.
5. **Qualification remains separate.** Source/test inspection is offline evidence,
   not executed upstream tests, native/live acceptance, signing, packaging or
   Linux/macOS/Windows/Android qualification. Re-pin and re-trace changed sources
   before implementation. Named-target private-auth, lifecycle, failure and
   upgrade/recovery receipts remain future work.

## Review record

See [the evidence receipt](../quality/native-local-integration-contract-review.md)
for the acceptance checklist, exact source pins, supported/unavailable guarantees,
independent contract/security review and final documentation checks. No ADR change,
privileged implementation, upstream edit or platform-support claim is proposed.
