# Hermes compatibility contract

Hermes Wing does not promise compatibility by Hermes Agent release version. It
reads `/v1/capabilities` from one canonical Hermes API origin and enables only
advertised transports and surfaces. Dashboard ports and session tokens are not
client transports.

## Capability schema evolution

The capability document carries an integer `schema_version`; an absent value is
version 1. Compatible changes are additive: servers may add fields, endpoint
entries, scopes, features, and event types, while clients ignore unknown fields.
A client uses an operation only when it supports the document schema and the
operation is advertised with the expected method, path, and required scopes.
Malformed or unsupported required operations fail closed without disabling
unrelated capabilities. A new major schema or route namespace is reserved for
changes that cannot remain additive.

## Required bootstrap endpoints

- `GET /health`
- `GET /v1/capabilities`
- `GET /api/sessions`

For scoped credentials, `/v1/capabilities` reports the caller's granted scopes
and the required scopes for advertised operations. Flutter must treat those
grants as presentation input while Hermes Agent remains the enforcement point.

Milestone 0 (Remote trust foundation) and Profiles/Agents advertise these
scoped operations. Enrollment inspect/exchange are unauthenticated because the
one-time code is itself the credential (origin-bound, TTL-limited,
lockout-rate-limited); everything else requires the listed scope:

| Method | Path | Required scope |
| --- | --- | --- |
| `POST` | `/v1/operator/enrollments` | `settings:write` |
| `POST` | `/v1/operator/enrollments/inspect` | (code + origin) |
| `POST` | `/v1/operator/enrollments/exchange` | (code + origin) |
| `GET` | `/v1/operator/credentials` | `settings:read` |
| `DELETE` | `/v1/operator/credentials/{id}` | `settings:write` |
| `GET` | `/api/profiles` | `profiles:read` |
| `POST` | `/api/profiles` | `profiles:write` |
| `PATCH` | `/api/profiles/{name}` | `profiles:write` (`If-Match`) |
| `DELETE` | `/api/profiles/{name}` | `profiles:write` (`If-Match`) |
| `GET` | `/api/profiles/{name}/soul` | `profiles:read` |
| `PUT` | `/api/profiles/{name}/soul` | `profiles:write` (`If-Match`) |
| `GET` | `/api/providers` | `providers:read` |
| `PUT` | `/api/providers/{slug}/credential` | `providers:write` |
| `DELETE` | `/api/providers/{slug}/credential` | `providers:write` |
| `POST` | `/api/providers/{slug}/credential/validate` | `providers:write` |
| `GET` | `/api/models` | `models:read` |
| `POST` | `/api/models/refresh` | `models:write` |
| `PUT` | `/api/models/assignment` | `models:write` (`If-Match`) |

Profile mutations use opaque domain revisions: a missing `If-Match` returns
`428`, a stale revision returns `412` with no write, and the client refreshes
the profile list on either a successful mutation or a `412`. Gateway selection,
read-only behavior, unsupported-server handling, and the Hermes Agent ownership
boundary are documented in [Gateway profile management and limitations](gateway-profile-management.md).

Every provider-credential operation is profile-scoped through the mandatory
`?profile=` query described below (`"current"` is not accepted as a
fallback). Provider API keys are write-only: `PUT`/`DELETE
/api/providers/{slug}/credential` accept or clear a value but never return
it, `GET /api/providers` and the validate response report only `configured`
(bool) and a masked last-4-character `key_hint`, and no capability field,
error body, or log line ever carries the raw key.

The capability document advertises this profile-context contract:

```json
"profile_context": {
  "type": "query",
  "name": "profile",
  "required": true,
  "default_profile_id": "default"
}
```

Each endpoint requiring query context also reports `"profile_scoped": true`.
Hermes Wing must send `profile=<validated-id>` on those HTTP and SSE operations, including
`profile=default`; servers must not fall back to `active_profile`. Machine-scoped
profile-registry operations identify their target in the path or body instead.
Missing context returns `profile_required`; malformed, unknown, or conflicting
context fails closed without disabling unrelated operations. Retries, pagination,
polling, and SSE reconnects preserve the profile value. Profile selection inside
Hermes Wing is client context and does not mutate the CLI's active profile.

## Event-stream contract

Hermes control-plane mutations use HTTP and live updates use advertised,
profile-scoped SSE endpoints. Stream capability entries declare resumability,
event types, and terminal semantics. Events carry stable IDs and profile
identity; delivery is at least once, so clients preserve the profile and last
event ID across reconnects, deduplicate repeats, and reconcile gaps through the
authoritative GET endpoint. Unknown event types are ignored safely. Bounded idle
timeouts prevent a silent stream from appearing live indefinitely. Dashboard
WebSockets are not a Hermes Wing transport.

A usable endpoint must also advertise at least one supported chat transport:

- `POST /api/sessions/{session_id}/chat/stream`, or
- `POST /v1/runs` plus `GET /v1/runs/{run_id}/events`

Wing owns only local navigation/draft/status commands (`/new`, `/sessions`, `/clear`,
`/settings`, `/usage`, `/help`, `/agents`, `/providers`, `/model`, `/tools`,
`/skills`, `/schedules`, and `/gateway`), plus capability-gated `/persona` for
an exact scoped profile SOUL read and capability-gated `/version` for exact
scoped detailed gateway health. They execute as client actions without sending slash text as an agent turn;
`/new` uses the already-advertised session-create contract. They are disabled
while a run is active. Every unknown slash command remains an ordinary server-owned message;
Wing does not guess Hermes command semantics or claim runtime discovery without
an advertised catalog contract.

## Capability-gated endpoints

Hermes Wing may use these only when advertised:

- `GET /health/detailed` with declared and granted `gateway:read`
- `GET /v1/models`
- `GET /v1/skills`
- `GET /v1/toolsets`
- `POST /api/sessions`
- `PATCH /api/sessions/{session_id}`
- `DELETE /api/sessions/{session_id}`
- `GET /api/sessions/{session_id}/messages`
- `POST /api/sessions/{session_id}/fork`
- `GET /api/jobs` with declared and granted `tasks:read`
- `GET /v1/runs/{run_id}`
- `POST /v1/runs/{run_id}/approval`
- `POST /v1/runs/{run_id}/stop`

Failure to load optional health, models, skills, toolsets, or jobs is reported
as unavailable inventory rather than as an empty inventory. Newer scoped
servers may require `skills:read` and `tools:read`; authorization failures stay
isolated as unavailable optional inventory so legacy advertised read-only
catalogs remain compatible.

For runs, Wing accepts bounded input/output/total token counts from the
terminal SSE event. When a successful terminal event omits usage and the exact
run-status route is advertised, Wing performs one best-effort status read and
preserves the numeric usage through authoritative transcript reconciliation.
Failure to read optional usage never changes run success or retries work. After
a premature run-stream close, an advertised status read may instead reconcile a
completed bounded output. A queued or running status blocks duplicate retry and
directs the operator to reconnect; Wing never probes an unadvertised status
route.

## Administrative mutation contract

Administrative reads return typed domain data plus an opaque `revision`.
Revisioned `PATCH`, `PUT`, and `DELETE` operations require `If-Match`; omission
returns `428 revision_required`, while stale state returns
`412 revision_conflict` and applies nothing. A successful atomic mutation
returns the new revision and separately reports any restart/reload requirement.
Secret fields return presence and safe metadata only and accept dedicated
set/remove operations that never echo values. Generic config-path and
environment-variable read/write endpoints are not Hermes Wing contracts.

Every successful administrative mutation reports one apply disposition:
`applied`, `reload_required`, or `restart_required`. Reload and restart are
explicit server-owned operations. Restart-required flows expose active work and
drainability, reject new work after confirmed drain begins, allow cancellation
before restart, emit profile-scoped SSE progress, and finish only after health,
capability, profile, and revision verification. Flutter never runs platform
restart recipes itself.

## Disconnect and reconnect behavior

Already loaded read models may remain visible as in-memory stale snapshots with
their last successful refresh time. Drafts remain inert. Hermes Wing does not
durably queue or automatically replay chat sends, approvals, administrative
mutations, task actions, or lifecycle commands. Reconnect refreshes capabilities,
profile context, domain revisions, and authoritative resources before enabling
mutations. Pending work is invalidated by endpoint, profile, session, credential,
or connection-generation changes. Android backgrounding may detach the event
stream without stopping a server-owned run. Foreground resume revalidates trust
and context, fetches authoritative session/run state, and only then reconnects
the stream; it never replays local approvals, follow-ups, or mutations.

## Resource-handle contract

Attachments and context folders use capability-advertised Hermes resource
handles. Upload, same-host path registration, and server-workspace selection
are separate operations with declared size, media-type, count, and retention
limits. Handles are opaque and profile-bound; chat and history payloads expose
only the handle plus safe display metadata. Path registration is available only when Hermes Wing and Hermes Agent share a
verified host and the operator selected the path through the native picker.
The returned grant declares profile, principal, purpose, access mode, expiry,
and optional session binding without returning the path. Remembered access is a
separate confirmation. Remote, SSH-tunnelled, and mobile clients upload content
or select an advertised server workspace. Every use revalidates filesystem
identity and root containment; revocation and expiry fail closed. Missing
resource capabilities hide the affected picker without disabling text chat.

## Backup and restore contract

Hermes Agent exposes backup creation, inspection, upload, download, deletion,
and restore as typed asynchronous jobs using opaque expiring archive handles.
Portable jobs require explicit profile context and dedicated `backups:read` or
`backups:write` scopes. Capabilities declare archive modes, compatibility,
limits, retention, and whether local-only encrypted machine recovery is
available. Responses and events contain bounded metadata, hashes, counts, job
state, and apply dispositions but never server paths or secret values.

Restore stages and validates the complete archive before returning a redacted
change preview. Apply requires fresh confirmation, drains active work, creates a
verified rollback checkpoint, uses all-or-rollback semantics, and completes only
after post-reload health, capability, profile, and revision checks. Flutter does
not parse archives, execute backup commands, request force overlays, retain
passphrases, or upload exports to cloud storage automatically.

## Currently unsupported client surfaces

Hermes server audio/realtime audio, memory editing, configuration editing, jobs
administration, and the typed backup/restore contract are not yet
release-supported Hermes Wing workflows. Capability parity requires explicit Hermes
Agent contracts and client contract tests before these surfaces are enabled;
Flutter must not substitute direct file, database, or CLI access.

## Optional Hermes One account service

Hermes One account login, cloud-agent synchronization, and backend-managed
wallets use the optional Hermes One account service directly. That HTTPS service
has its own OAuth capability and credential lifecycle; it is not an alternate
Hermes endpoint, Dashboard transport, or fallback for unavailable Hermes Agent
operations. Account-service failure must not disable Hermes chat or administration. Native
clients use advertised RFC 8628 device authorization through the system browser,
with an allowed HTTPS verification origin, generic device label, server-directed
polling, expiry/cancellation, and a client-global credential in platform secure
storage. Codes and tokens never transit through Hermes Agent, URLs owned by
Hermes Wing, clipboard, logs, analytics, or migration. Web account support remains
excluded until Hermes One advertises Authorization Code + PKCE and the browser
storage boundary passes review.
