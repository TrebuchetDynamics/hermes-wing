# Hermes Wing project context

Hermes Wing is an independent Flutter client for Hermes Agent. Hermes Agent owns
agent state. Wing Link is the authenticated remote management API that runs on
the Hermes host.

## Product language

**Hermes Wing** — the Android, web, and desktop client. Avoid *companion* and
*Electron clone*.

**Hermes Agent** — the authoritative runtime for profiles, projects, providers,
models, sessions, tools, schedules, memory, and gateway state.

**Wing Link** — the remote management plane for setup, pairing, lifecycle,
health, diagnostics, approved host directories, and reviewed fixed compatibility
operations. Avoid *proxy*, *shell bridge*, and *second backend*.

**Hermes Agent data plane** — direct authenticated Agent API traffic for chat,
sessions, runs, tools, approvals, and advertised administration. It does not
transit Wing Link.

**Hermes Project** — an Agent-owned, per-profile workspace with one or more
folders and a primary folder. Use this for repository/subfolder assignment;
do not invent a Wing-owned profile `workdir`.

**Directory grant** — a locally approved host root exposed by Wing Link through
opaque handles. It is not an unrestricted saved path.

**Capability parity** — equivalent user outcomes using platform-native
implementation, not a line-for-line Desktop port.

**Accessible equivalent** — a fully operable path that does not depend on 3D,
canvas, pointer, speech, motion, sound, or color alone.

**Detached run** — Agent-owned work that continues while Wing is suspended and
is reconciled on return.

## Authority rules

- Prefer the advertised Hermes Agent API.
- Use Wing Link only for host work or a reviewed typed compatibility operation
  missing from the Agent API.
- Compatibility operations use fixed executable/argument shapes, bounded output,
  no shell, no global `profile use` or `project use`, and no shadow domain state.
- Provider secrets are write-only and must not enter argv, responses, logs, or
  diagnostics.
- Remote folder selection is rooted, handle-based, bounded, and revocable. Wing
  Link returns folders only; it never enumerates file names, metadata, or content.
- Server state wins after reconnect; mutations are never queued or replayed.

## Connections

A paired host has two independent connections:

1. a Hermes Agent origin and profile-bound credential; and
2. a Wing Link origin and management credential.

Wing Link currently serves HTTP on loopback plus a selected or automatically
discovered local private-LAN/Tailscale interface. Non-loopback plaintext requires
explicit review; use trusted HTTPS or an encrypted VPN remotely. Plain
public-internet HTTP is not supported.

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

Bearer credentials, Wing Link control tokens, pairing codes, provider keys, and
recognized speech are secrets. Never place them in URLs, QR payloads, logs,
clipboards, shared text, command arguments, or ordinary preferences. Diagnostics
must redact host paths and content.
