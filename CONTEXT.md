# Hermes Wing project context

The only Desktop product reference is [Nous Research Hermes Desktop](https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop),
locally `hermes-agent/apps/desktop/`. Prior separate-app comparisons are
[withdrawn as official parity evidence](docs/quality/official-desktop-reference.md).
Existing Wing test results do not establish parity with this corrected reference.

Hermes Wing is a Flutter port of Hermes Desktop, not a separately designed client
with similar features. Hermes Agent owns agent state. Wing Link is the deprecated
legacy remote management API, retained until removal and never a prerequisite for Agent use.

## Product language

**Hermes Wing** — the Android, web, and desktop client. Avoid _companion_ and
_Electron clone_.

**Hermes Agent** — the authoritative runtime for profiles, projects, providers,
models, sessions, tools, schedules, memory, and gateway state.

**Wing Link** — the remote management plane for setup, pairing, lifecycle,
health, diagnostics, approved host directories, and reviewed fixed compatibility
operations. Avoid _proxy_, _shell bridge_, and _second backend_.

**Hermes Agent data plane** — direct authenticated Agent API traffic for chat,
sessions, runs, tools, approvals, and advertised administration. It does not
transit Wing Link.

**Hermes Project** — an Agent-owned, per-profile workspace with one or more
folders and a primary folder. Use this for repository/subfolder assignment;
do not invent a Wing-owned profile `workdir`.

**Directory grant** — a locally approved host root exposed by Wing Link through
opaque handles. It is not an unrestricted saved path.

**Capability parity** — a 1:1 Hermes Desktop product port: feature coverage,
welcome, navigation, screen structure, terminology, layout, visual hierarchy,
interaction and recovery behavior are the reference.
Flutter/native implementation may differ; product deviations must be explicit.
Parity is a delivery goal, not evidence of implemented or accepted behavior.

**Accessible equivalent** — a fully operable path that does not depend on 3D,
canvas, pointer, speech, motion, sound, or color alone.

**Detached run** — Agent-owned work that continues while Wing is suspended and
is reconciled on return.

## Authority rules

- Never modify Hermes Agent itself, including reference clones, installed runtimes
  or forks. Missing contracts must be handled within Wing/Wing Link's supported
  boundaries or left unavailable; see the
  [hard ADR](docs/adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent).
- Prefer the advertised Hermes Agent API.
- Wing Link is deprecated. New product flows must not use its host operations
  or compatibility catalog. Preserve existing checks until consumer retirement.
- Compatibility operations use fixed executable/argument shapes, bounded output,
  no shell, no global `profile use` or `project use`, and no shadow domain state.
- Provider secrets are write-only and must not enter argv, responses, logs, or
  diagnostics.
- Remote folder selection is rooted, handle-based, bounded, and revocable. Wing
  Link returns folders only; it never enumerates file names, metadata, or content.
- Server state wins after reconnect. Wing does not queue mutations offline; retryable
  Wing Link mutations use bounded idempotency keys and replay the same durable
  terminal operation status rather than executing twice.

## Connections

Local / SSH / Remote must connect to Agent without Wing Link prerequisites.
[Replacement requirements](docs/product/prd.md#connection-path-requirements)
and [retirement work](TODO.md#now--next) distinguish intent from current code.

### Retained legacy pairing

The following contract describes deprecated code, not supported new-user setup.
A legacy paired host has two independent connections:

1. a Hermes Agent origin and profile-bound credential; and
2. a Wing Link origin and management credential.

Wing Link serves HTTP only on loopback. Every non-loopback listener uses TLS 1.3
with a durable owner-only host identity bundle: the preserved Ed25519 host root
and a persistent Android-compatible RSA TLS key. Native Wing clients pin the reviewed TLS key's SHA-256
SPKI fingerprint; browser clients still require normally trusted HTTPS
because web code cannot override the browser trust store. A changed or missing
fingerprint fails closed and requires an explicit new pairing flow. Network
location is never authorization.

Each paired device receives a named, individually revocable bearer credential
with exact grants. The host console is the trust administrator: remote devices
may inspect and revoke only themselves, while peer revocation, permission
expansion, identity rotation, sensitive secret writes, destructive actions, and
install/update approval remain local. Current Wing Link protocol generation is 2
and implementations support only the current and immediately previous generation.

## Profile and workspace flow

Create/select profile → choose an approved host directory → create a Hermes
Project in that profile → set the chosen repository or subfolder as primary →
open Chat in that explicit profile/project context.

Profile and Project names are local to one canonical Agent origin. They are not
global Wing gateway IDs.

## Route language

- `/hermes` — connection, sessions, chat, runs, voice, approvals, and diagnostics.
- `/profiles` — profile lifecycle and project assignment.
- `/providers` — provider/model inventory and typed configuration when supported.
- `/tools` — skills, toolsets, and MCP discovery/administration.
- `/tasks` — scheduled jobs and Kanban outcomes.
- `/gateway` — host and gateway health/lifecycle.
- `/settings` — local Wing preferences and installation controls.

Route status lives in [docs/product/routes.md](docs/product/routes.md).

## Voice language

Voice input prefers an advertised exact Hermes audio route and otherwise uses
device recognition. Speech output may prefer an advertised Agent synthesis route
and falls back to platform speech. Current Hermes Agent 0.20 advertises neither
HTTP audio route; deterministic tests are not physical microphone, AEC, or
acoustic evidence.

## Security language

A pairing handoff may carry a random single-use pairing code in a QR code,
`wing://connect` intent, explicit Android share, or the ephemeral local handoff
page, which must use `Cache-Control: no-store`. The code expires after
five minutes, never contains a bearer credential, and must not be persisted,
analyzed, included in diagnostics, or written to ordinary logs. Explicit paste is a
user-initiated fallback, not background clipboard monitoring; the app drops the
raw text immediately after parsing.

Hermes API keys, Wing Link control tokens, provider credentials, and exchanged
bearer credentials remain forbidden in URLs, QR payloads, clipboards, shared
text, command arguments, and ordinary preferences. Recognized speech remains
secret, and diagnostics must redact credentials, host paths, and content.

## Legacy setup catalog (pending retirement)

The retained compatibility contract below is not the new-product direction.
New profile/model flows must use supported Agent contracts or explain missing
capabilities. [The Profiles candidate](docs/quality/profiles-agent-only-follow-through.md)
removes one consumer, but is not integrated into the canonical source.

Legacy provider/model setup autocomplete uses Wing Link's typed, profile-scoped
`model-options` read backed by Hermes Agent's advertised inventory. This approved
setup exception returns display fields only, including unconfigured providers,
without caching domain state or expanding provider mutation permissions. Chat,
sessions, runs, tools, and approvals continue to use Agent directly. See
[API and state](docs/adr/api-and-state.md#provider-model-setup-catalog).
