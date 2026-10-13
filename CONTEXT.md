# Hermes Wing project context

The only Desktop product reference is [Nous Research Hermes Desktop](https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop),
locally `hermes-agent/apps/desktop/`. Prior separate-app comparisons are
[withdrawn as official parity evidence](docs/quality/official-desktop-reference.md).
Existing Wing test results do not establish parity with this corrected reference.

Hermes Wing is a Flutter client pursuing Hermes Desktop product parity.
Hermes Agent owns profiles, Projects, providers, models, configuration, sessions,
runs, tools, approvals, schedules, memory and gateway state. Wing never creates a
second backend or shadow inventory. Wing Link client, service, installers and
bundling are removed; historical plans and receipts are not current setup guides.

## Connections

Local / SSH / Remote connect directly to Agent. Android welcome order is SSH,
Remote server, then Termux. Linux Local checks Hermes-home directory metadata and
allows deliberate alternate folder selection. This does not read Agent files,
select a Project, install/start Agent or prove readiness. Android uses manual
Agent preparation in the separate Termux sandbox, not external-command access.
Use [direct connection](docs/getting-started.md#direct-agent-connection).

Saved Agent endpoint/profile/session identities and credentials survive retirement.
Raw legacy records and secure slots are preserved but never used for management.
A missing Agent credential requires direct reauthentication. Changed origins must
not reuse another origin's credential. Legacy handoff input is discarded without
parsing, exchange, persistence or display; cancel preserves caller ownership.

## Authority and security

Never modify Hermes Agent, installed runtimes or upstream references. Prefer an
advertised exact Agent operation, required grants and current resource identity.
Absent operations remain unavailable; no shell bridge, direct-file mutation or
replacement management catalog is permitted. Profiles and Projects are Agent-owned,
with explicit request identities and no hidden global selection.

Server state wins after reconnect; Wing never silently replays mutations.
Revisions or authoritative concurrency checks protect edits. Persistence and
reload/restart success are separate outcomes. Agent API/provider credentials belong
in platform secure storage, not URLs, clipboards, argv, ordinary preferences,
responses, logs or diagnostics. Diagnostics redact credentials, paths and content.
Remote HTTPS validates the origin and certificate. Non-local Agent HTTP requires
explicit consent inside an authenticated encrypted VPN or isolated trusted LAN;
network location is not authorization. Native SSH verifies the host fingerprint.

Historical handoffs used a single-use pairing code expiring after five minutes,
which never contains a bearer credential, with a no-store handoff page.
These are retired inputs, not an offered pairing procedure.

## Product language and routes

A Hermes Project is an Agent-owned per-profile workspace, not a Wing-owned workdir.
Capability parity is a product/interaction goal, not evidence of qualification.
An accessible equivalent works without speech, sound, motion, pointer, canvas,
3D or color alone. Detached runs are Agent-owned and reconciled after suspension.
Route support lives in [routes](docs/product/routes.md). Missing Project assignment,
host lifecycle, remote directory browsing and peer administration remain unavailable
unless their individual authoritative Agent contracts are advertised and verified.

## Voice and qualification

Voice uses exact advertised Agent audio routes where available, otherwise supported
platform speech. Fixtures, web compilation and cross-compilation do not prove
physical microphone, acoustic, native/device, live authentication or provider support.
