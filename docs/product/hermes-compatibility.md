# Hermes Agent compatibility

Status: current integration contract

Verified against Hermes Agent `v0.20.0` (`2026.8.3`) and the official documentation
on 2026-08-14. Hermes Agent documentation is authoritative when this file and a
supported release differ.

- [API server](https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server)
- [Profiles](https://hermes-agent.nousresearch.com/docs/user-guide/profiles)
- [Multi-profile gateways](https://hermes-agent.nousresearch.com/docs/user-guide/multi-profile-gateways)
- [Profile commands](https://hermes-agent.nousresearch.com/docs/reference/profile-commands)
- [Installation](https://hermes-agent.nousresearch.com/docs/getting-started/installation)

Hermes Wing does not gate features from an Agent version string. It authenticates
to one canonical API origin, reads `GET /v1/capabilities`, and uses only the
method/path combinations it understands. The recorded release is test provenance,
not a feature switch. Every candidate release follows the
[release compatibility audit](../runbooks/hermes-agent-release-compatibility.md).

## Supported upstream baseline

Hermes Agent 0.20 documents these API-server surfaces relevant to Wing:

- `GET /health` and authenticated `GET /health/detailed`;
- `GET /v1/capabilities`;
- OpenAI-compatible `POST /v1/chat/completions` and `POST /v1/responses`;
- `POST /v1/runs`, run status, SSE events, approval, and stop;
- session list/create/read/update/delete/fork and session chat under
  `/api/sessions`;
- jobs list/create/read/update/delete/pause/resume/run under `/api/jobs`;
- read-only `GET /v1/models`, `GET /v1/skills`, and `GET /v1/toolsets`;
- richer read-only model/provider options through `GET /api/model/options`.

The API server uses `Authorization: Bearer <API_SERVER_KEY>`. The key grants full
access to the API server, including tools. Keep browser CORS origins narrow and do
not expose the server to an untrusted network.

## Wing capability policy

Wing treats an absent `schema_version` as schema 1 and currently understands only
schema 1. Additive unknown fields and event types are ignored. A required
operation remains hidden unless its exact method and path are advertised. If an
endpoint declares scopes, Wing also requires every declared scope before it shows
controls or begins network I/O.

This strict client policy is intentionally stronger than assuming that a route
exists because another Hermes surface uses it. Unsupported, unauthorized, and
failed optional inventory are distinct from an authoritative empty result.

A usable connection must provide:

- `GET /health`;
- `GET /v1/capabilities`;
- `GET /api/sessions`; and
- either session chat streaming or the runs-plus-events transport.

## Sessions, runs, and jobs

Wing supports the advertised session and runs APIs for chat, streaming replies,
tool progress, approvals, stop controls, reconnect, and session history. It does
not infer a mutation from a read route. Rename, delete, fork, approval, stop, and
run-status requests each require their exact advertised endpoint.

Session bulk deletion is client orchestration over exact per-session `DELETE`.
It confirms once, excludes sessions with live work, continues after an individual
failure, and reports bounded counts. Forking is likewise one confirmed exact
request; once Hermes returns a child ID, Wing selects it even if the subsequent
history refresh fails.

Hermes 0.20 documents jobs CRUD plus pause, resume, and run-now. Wing currently
uses only a capability-gated read-only job inventory. Mutation UI is roadmap work;
this is a client gap, not a missing upstream jobs contract.

## Models, providers, skills, and tools

`GET /v1/models` is the small OpenAI-compatible model list. Wing may show its
bounded IDs read-only. `GET /api/model/options` provides richer Hermes-aware
model/provider options. Hermes Agent 0.20 does not advertise an API-server model
mutation route, so persistent model/provider changes remain contract-gated.

The older Wing proposal for `/api/providers`, provider credential routes,
`/api/models/refresh`, and `/api/models/assignment` is not part of the documented
Hermes 0.20 API-server contract. Controls that depend on those routes stay hidden.
Wing must not replace them with local config or `.env` parsing.

`GET /v1/skills` and `GET /v1/toolsets` are read-only discovery routes. Wing shows
bounded inventory only. Skill installation, enable/disable, toolset mutation, and
MCP administration require separate advertised Agent contracts.

## Profiles and multiplex routing

Hermes profiles are separate Hermes homes. Agent-local profile names are not
cross-host Wing gateway IDs. Wing identifies a contact by its saved gateway
identity plus Agent-local profile name.

Hermes 0.20 does not document the proposed `/api/profiles` lifecycle and SOUL
administration routes used by older Wing plans. Direct profile administration
therefore remains unavailable unless a future supported Agent advertises an exact
compatible contract.

For current supported releases, Wing Link provides the typed compatibility
exception in the [runtime decision](../adr/runtime-and-delivery.md). The shipped
surface invokes only fixed Hermes CLI argument vectors for:

- `hermes profile list`;
- `hermes profile create`;
- `hermes profile rename`; and
- `hermes profile delete`.

For a profile created by the same request, Wing Link may additionally run fixed
description, allowlisted provider/model, stdin-only `hermes auth add`, exact
postcondition, and bounded `Hi` readiness commands. Failure deletes that newly
created profile. Existing-profile description/provider/model/credential editing
is rejected before mutation because the released CLI offers no transactional
restore contract.

During pairing it may resolve each validated profile's environment path with
fixed `hermes --profile <id> config env-path`, set
`gateway.multiplex_profiles`, restart the active default gateway, and verify one
connection per profile. It never invokes `hermes profile use`, accepts arbitrary CLI text, or stores a
shadow profile inventory. Hermes Project and general provider operations require
separate fixed contracts, authorization, and tests; they are not implied by the
current adapter.

With multiplexing enabled, one default gateway serves named profiles at
`/p/<profile>/...`. Every named prefix requires that profile's own
`API_SERVER_KEY`; the default key is rejected. Unprefixed and `/p/default/...`
routes use the default profile's key. Named profiles without their own key fail
closed.

## Audio and voice

Wing's current working tree contains capability-gated adapters for
`POST /api/audio/transcribe` and `POST /api/audio/speak`. Audio is not sent unless
`audio_api` and the exact route are advertised. Local/device transcription and
platform speech remain compatibility fallbacks.

Hermes Agent 0.20 advertises `audio_api: false` and `realtime_voice: false`, and
the official API-server documentation does not list those two `/api/audio`
routes. The client plumbing is therefore not a release-supported or end-to-end
qualified server-audio workflow. Do not use deterministic voice fixtures as
physical microphone, acoustic echo-cancellation, speech-quality, or server-audio
evidence.

## Projects and host directories

Hermes Agent 0.20 provides a per-profile `hermes project` CLI with list, create,
show, folder management, rename, set-primary, archive, and restore operations.
Projects are the authoritative way to associate a profile with a repository or
subfolder. Wing Link does not expose these operations yet.

The planned adapter will translate only locally approved opaque directory handles
into fixed per-profile Project commands. Remote clients will not submit absolute
paths, browse outside granted roots, read file contents, or change hidden global
state through `project use`.

## Detailed health

When advertised, Wing reads bounded `GET /health/detailed` status: readiness,
gateway state, workload counts, process/update metadata, and named platform
states. It discards credentials, paths, commands, queue payloads, nested unknown
fields, and raw server exceptions. Failure to load detailed health does not turn
an optional surface into an empty healthy state.

## Authentication and enrollment

The supported upstream API-server credential is `API_SERVER_KEY`. Hermes Agent's
messaging-platform DM pairing codes are a different authorization system and must
not be described as Wing API enrollment.

Wing Link pairing uses a short-lived broker code and transfers either
an Agent-issued scoped credential when an exact enrollment contract is advertised
or a clearly labeled compatibility full-access key. The QR/link never contains a
bearer token. A separate staged Wing Link control credential must be acknowledged
before supervisor mutations are authorized.

## Disconnect and reconnect

Loaded read models may remain visible as labeled in-memory stale snapshots. Wing
does not durably queue or automatically replay sends, approvals, administration,
job actions, or lifecycle operations. Reconnect refreshes trust, capabilities,
profile identity, sessions, and authoritative state before mutations are enabled.
Android backgrounding may detach from a server-owned run; foreground resume
reconciles status before attaching again.

## Planned contracts are not current support

Resource handles, same-host filesystem grants, portable backup/restore,
revisioned generic administration, Hermes One account/wallet behavior, and other
future contracts in product planning remain proposals until Hermes Agent or a
reviewed Wing Link compatibility adapter has matching runtime and contract-test
evidence. Flutter must not substitute direct server file, database, config, or
CLI access.
