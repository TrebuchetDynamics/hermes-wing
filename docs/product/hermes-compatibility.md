# Hermes compatibility contract

Navivox does not promise compatibility by Hermes Agent release version. It
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
Navivox must send `profile=<validated-id>` on those HTTP and SSE operations, including
`profile=default`; servers must not fall back to `active_profile`. Machine-scoped
profile-registry operations identify their target in the path or body instead.
Missing context returns `profile_required`; malformed, unknown, or conflicting
context fails closed without disabling unrelated operations. Retries, pagination,
polling, and SSE reconnects preserve the profile value. Profile selection inside
Navivox is client context and does not mutate the CLI's active profile.

## Event-stream contract

Hermes control-plane mutations use HTTP and live updates use advertised,
profile-scoped SSE endpoints. Stream capability entries declare resumability,
event types, and terminal semantics. Events carry stable IDs and profile
identity; delivery is at least once, so clients preserve the profile and last
event ID across reconnects, deduplicate repeats, and reconcile gaps through the
authoritative GET endpoint. Unknown event types are ignored safely. Bounded idle
timeouts prevent a silent stream from appearing live indefinitely. Dashboard
WebSockets are not a Navivox transport.

A usable endpoint must also advertise at least one supported chat transport:

- `POST /api/sessions/{session_id}/chat/stream`, or
- `POST /v1/runs` plus `GET /v1/runs/{run_id}/events`

## Capability-gated endpoints

Navivox may use these only when advertised:

- `GET /health/detailed`
- `GET /v1/models`
- `GET /v1/skills`
- `GET /v1/toolsets`
- `POST /api/sessions`
- `PATCH /api/sessions/{session_id}`
- `DELETE /api/sessions/{session_id}`
- `GET /api/sessions/{session_id}/messages`
- `POST /api/sessions/{session_id}/fork`
- `GET /api/jobs`
- `POST /v1/runs/{run_id}/approval`
- `POST /v1/runs/{run_id}/stop`

Failure to load optional health, models, skills, toolsets, or jobs is reported
as unavailable inventory rather than as an empty inventory.

## Administrative mutation contract

Administrative reads return typed domain data plus an opaque `revision`.
Revisioned `PATCH`, `PUT`, and `DELETE` operations require `If-Match`; omission
returns `428 revision_required`, while stale state returns
`412 revision_conflict` and applies nothing. A successful atomic mutation
returns the new revision and separately reports any restart/reload requirement.
Secret fields return presence and safe metadata only and accept dedicated
set/remove operations that never echo values. Generic config-path and
environment-variable read/write endpoints are not Navivox contracts.

Every successful administrative mutation reports one apply disposition:
`applied`, `reload_required`, or `restart_required`. Reload and restart are
explicit server-owned operations. Restart-required flows expose active work and
drainability, reject new work after confirmed drain begins, allow cancellation
before restart, emit profile-scoped SSE progress, and finish only after health,
capability, profile, and revision verification. Flutter never runs platform
restart recipes itself.

## Disconnect and reconnect behavior

Already loaded read models may remain visible as in-memory stale snapshots with
their last successful refresh time. Drafts remain inert. Navivox does not
durably queue or automatically replay chat sends, approvals, administrative
mutations, task actions, or lifecycle commands. Reconnect refreshes capabilities,
profile context, domain revisions, and authoritative resources before enabling
mutations. Pending work is invalidated by endpoint, profile, session, credential,
or connection-generation changes.

## Resource-handle contract

Attachments and context folders use capability-advertised Hermes resource
handles. Upload, same-host path registration, and server-workspace selection
are separate operations with declared size, media-type, count, and retention
limits. Handles are opaque and profile-bound; chat and history payloads expose
only the handle plus safe display metadata. Path registration is available only
when Navivox and Hermes Agent share a host and the operator selected the path.
Remote/mobile clients upload content or select an advertised server workspace.
Missing resource capabilities hide the affected picker without disabling text
chat.

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
release-supported Navivox workflows. Capability parity requires explicit Hermes
Agent contracts and client contract tests before these surfaces are enabled;
Flutter must not substitute direct file, database, or CLI access.

## Optional Hermes One account service

Hermes One account login, cloud-agent synchronization, and backend-managed
wallets use the optional Hermes One account service directly. That HTTPS service
has its own OAuth capability and credential lifecycle; it is not an alternate
Hermes endpoint, Dashboard transport, or fallback for unavailable Hermes Agent
operations. Account-service failure must not disable Hermes chat or
administration.
