# API and state

Status: current decision

## Decision

The retained implementation uses two typed planes. Wing Link is deprecated under
the [product decision](product.md#wing-link-deprecation), not removed yet. New
product flows must not require its compatibility APIs or model catalog. Keep the
following legacy contracts enforced until retirement:


- Hermes Agent APIs for authoritative domain and run state; and
- Wing Link for authenticated host management and reviewed compatibility
  operations missing from the Agent API, plus the typed setup catalog read below.

Capability discovery determines which operations Wing offers. A broad version or
`admin` flag is insufficient: mutations require the exact operation,
authorization, and current resource identity.

Readiness, status and diagnostics must report no stronger availability than the
corresponding action gate. For each operation require the supported schema, exact
method/path (or qualified native RPC), every required grant, supported profile
context and current resource identity. A primary read grant or broad feature flag
alone is insufficient; read availability never implies write permission. Use the
existing authorization policy and cross-projection denial regressions rather than
a second readiness authority. The [four-repository study](../analysis/understand-anything/README.md)
identified jobs/health/Persona reporting drift at source level, not an executed
authorization bypass; the [follow-through plan](../plans/2026-10-03-study-follow-through.md)
scopes its correction.

Server state wins after reconnect. Cached reads and drafts may remain visible,
but Wing never silently replays a mutation. Destructive, secret, filesystem, and
lifecycle operations require fresh intent or an idempotent contract. Reconnect is
read/reconciliation, not permission to resend prompts, approvals or cached
configuration/security preferences. Unknown submission outcomes remain unknown
until authoritative recovery; do not retry through another transport or seed a
replacement session from cached history. An explicit retry must satisfy the
selected operation's verified idempotency and authorization contract; guarantees
from run submission do not transfer to native RPC or administration.

Host folder selection uses server-issued opaque handles rooted in locally approved
directories. Results contain child folders only, never file entries. Clients
never send arbitrary absolute paths. Every lookup revalidates canonical
containment and grant status.

Profile-to-folder assignment uses Agent-owned Hermes Projects. Profile, project,
and directory identities remain explicit on every request; no operation changes a
global active profile or project as a side effect.

Use revisions or another authoritative concurrency check where edits can collide.
Report reload/restart requirements separately from persistence success.

## Provider model setup catalog

Provider/model autocomplete in profile setup reads Hermes Agent's full advertised
inventory through Wing Link's typed `GET /v1/profiles/{id}/model-options` API.
This is an explicit setup-management exception to direct Agent administration;
it does not move chat, sessions, runs, tools, or approvals through Wing Link.

Agent remains the catalog authority. Wing Link requires its own `profiles:read`
grant, verifies the requested profile still exists, and checks Agent's exact
`model_options` capability before reading `/p/{id}/api/model/options` with the
host's separate profile credential. The locally configured Agent origin is fixed;
remote callers cannot select an upstream URL, path, command, or configuration key.
Only provider slugs/names and model IDs are returned. No domain cache, credentials,
provider URLs, restart, credential creation, or provider mutation is involved.

Unconfigured providers remain visible for setup. Catalog visibility does not
authorize a provider write: existing secret, profile setup, and capability gates
remain in force. Chat's model picker retains its configured-provider policy.
If the catalog is unavailable, setup reports the error and offers retry or manual
entry; it never substitutes a Wing-maintained list of providers or models.

## Existing-profile provider compatibility direction

Status: provider-first design direction accepted on 2026-09-07; not implemented
or advertised. This records the next bounded compatibility slice, not shipping
support or permission to modify personal runtime state.

Extend Wing Link's reviewed compatibility operations to existing-profile provider
management only where a supported Hermes CLI or Agent API contract has been
verified. Hermes Agent remains authoritative. Direct writes to Agent-owned files
or databases, Persona and schedule adapters, arbitrary config keys, and generic
command execution are outside this accepted slice.

The implementation must satisfy these conditions before an operation is exposed:

- Advertise each verified Wing Link operation independently. A setup catalog read
  or new-profile setup capability does not grant existing-profile write access.
  Wing must select the correct management adapter without advertising synthetic
  Agent capabilities or routing Agent chat traffic through Wing Link.
- Bind authorization, local sensitive-write approval and idempotency to the exact
  device, profile identity, operation, resource revision and payload digest. Keep
  request bodies and credentials out of journals and audit records.
- Use fixed executable/argument shapes and bounded inputs, output and duration.
  Credentials remain write-only and use stdin, never argv or environment values.
  Verify add, replace, remove and validation semantics separately; command names
  alone do not prove the intended credential-store behavior.
- Keep saving, remote credential validation/inference, and gateway reload/restart
  as separate explicit actions with separate outcomes. Saving must not silently
  incur an inference request or restart a gateway.
- Verify concurrency against Agent/CLI edits as well as other Wing Link calls.
  A Wing Link mutex alone is not authoritative concurrency protection. Establish
  the supported transaction or conflict-checking mechanism before offering a
  combined provider/model mutation; report uncertain or partial outcomes honestly
  and reconcile authoritative state without automatic mutation replay.

Do not reuse the current new-profile transaction unchanged. Its
[setup implementation](../../wing_link/internal/app/serve.go) writes provider and
model settings sequentially, then performs an inference readiness probe; its
caller can roll back by deleting the newly created profile. Deleting an existing
profile is not a valid rollback. The existing
[setup tests](../../wing_link/internal/app/serve_test.go) prove only the current
new-profile contract, not safe existing-profile replacement.

Before implementation, trace each candidate through the installed Agent
source and nearest upstream tests, then add adapter-boundary tests for stale
revisions, external edits, revoked grants, approval replay, command failure and
secret redaction. Only verified operations may proceed to isolated live Linux UI
qualification. Record the supported Agent release window and removal trigger when
the equivalent authoritative Agent API becomes available. Until these checks are
met, the existing unavailable-state UI remains correct.

### Required Agent-owned mutation contract

Status: capability acceptance criteria, specified on 2026-09-07; not an upstream
implementation plan and not shipped support. The
[hard Agent immutability boundary](runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent)
prohibits modifying Agent to satisfy these criteria. Evaluate only contracts
provided by unmodified upstream releases.

The source review of reference `4f22543509` and installed `24f5a60ed1` found
that `auth add` appends a pool entry and clears source suppressions; it does not
replace a selected credential. `auth remove` removes an entry and can perform
source-specific cleanup. `auth status` is not remote credential validation.
Auth-store writes have cross-process locking and merge protection, but these do
not expose an expected-revision transaction. Config read/modify/write and atomic
file replacement do not provide equivalent cross-process conflict protection.
These are source-review findings, not executed runtime qualification.

An eligible authoritative contract must distinguish these outcomes:

| Operation | Required semantics |
| --- | --- |
| Read edit state | Return bounded provider/model metadata, opaque credential IDs, supported actions and an opaque revision; never secrets, secret hashes, source paths or provider URLs. |
| Add credential | Create one explicitly selected provider credential; preserve existing entries, selection and source suppressions. Return its opaque ID and new revision. |
| Replace credential | Replace only the selected credential ID at the expected revision. Preserve its identity and unrelated entries; never implement as an exposed add-then-remove sequence. |
| Remove credential | Remove only the selected credential ID. State whether other credentials remain; do not claim provider-wide logout or remote provider-key revocation. Reject sources whose cleanup cannot meet these guarantees. |
| Assign provider/model | Commit the validated provider/model pair together, or commit neither. No credential change, fallback provider selection, inference or restart. |
| Validate credential | Explicit, separately authorized bounded remote check for the selected credential and revision. Distinguish accepted, rejected, unavailable and inconclusive; never treat stored presence as validation. |

The first contract covers Agent-managed API-key entries only. Borrowed environment
keys, external credential stores and OAuth sources remain unsupported for mutation
unless individually specified and qualified. No implicit unsuppression, credential
import, provider-wide logout or external credential revocation is permitted.
Validation must disclose any network or billing effect before consent; saving
alone must never trigger it. A validation result applies only to the tested
credential revision and does not prove model inference readiness.

Every mutation carries explicit profile identity including its incarnation,
provider identity, operation, expected revision and idempotency key; credential
replacement/removal additionally carries the credential ID. Credential bytes are
write-only input. A local compatibility command must accept a bounded structured
stdin payload, emit bounded secret-free structured output and run without a shell
or interactive prompt. Wire names, size/deadline limits and protocol schemas must
be verified against a supported unmodified Agent contract before adapter
implementation; these are requirements, not invented callable routes or flags.

Agent must check revision and identity inside the same authoritative transaction
that commits the mutation. Relevant CLI, API and runtime credential/config writers
must participate in that concurrency mechanism. Deleting/recreating a profile or
credential invalidates prior requests. A Wing Link mutex, a preflight read or a
post-write readback is not a substitute. Combined credential and model saves are
not part of the initial contract; the UI must report their separate outcomes.

Idempotency must survive a crash between commit and response: the same authorized
request returns its original secret-free receipt, while changed-payload replay
fails. Durable deduplication metadata must not contain request bodies or raw
secrets; any secret-dependent binding must resist offline guessing. Agent owns
commit reconciliation, and Wing Link retains only bounded operation metadata,
not a second provider store. Unknown outcomes require status reconciliation, not
automatic execution with a new key. Revoked callers cannot obtain receipts or
execute retries. Expired deduplication records must not permit an old request to
execute again silently.

Receipts distinguish committed state and resulting revision from runtime
activation: no reload requested, reload required, or separately verified reload
outcome. Errors distinguish unsupported operation/source, invalid input, denied
authorization, stale identity/revision, conflict, not found and unknown outcome.
Errors and audit events contain only allowlisted metadata, never upstream raw
output, credentials or private paths. Local approval remains bound to requester,
operation, resource, expected revision and payload; changes require fresh approval.

Prefer direct advertised Agent administration with its own authorization. Only a
verified fixed local CLI contract may justify the Wing Link compatibility adapter;
Wing Link must not proxy an available Agent administration API. Each compatibility
operation needs a qualified release window and is removed when the equivalent
authoritative advertised API provides these guarantees.

Acceptance requires behavioral tests for concurrent CLI/API edits, stale revisions,
profile delete/recreate, exact-ID replacement/removal, preserved sibling credentials
and suppressions, all-or-nothing provider/model assignment, crash/timeout replay,
changed-payload replay, revoked authorization, stdin/output redaction and zero
implicit inference/restart. Then qualify the supported operations through live
Linux UI journeys using isolated Agent state; fixtures alone are insufficient.

The proposed upstream implementation checkpoint is withdrawn. Further work is
limited to Wing/Wing Link changes over verified, unmodified Agent contracts.
Until a supported authoritative contract meets these criteria, keep the affected
existing-profile provider operations unavailable. Never modify Hermes Agent or
implement a direct-file fallback to enable them.
