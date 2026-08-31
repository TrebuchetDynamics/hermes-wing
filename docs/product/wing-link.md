# Wing Link

Status: current behavior plus approved target

Wing Link is the authenticated **remote management API** that runs beside Hermes
Agent. Hermes Wing uses it for host operations that the Agent API cannot perform.
Chat, sessions, runs, tools, and approvals continue to use Hermes Agent directly;
Wing Link is not a chat proxy or a second copy of Agent state.

## How it connects

```text
Hermes Wing ── data plane ─────────────▶ Hermes Agent API
     │                                      (authoritative agent state)
     └──── management plane ───────────▶ Wing Link
                                            │
                                            ├─ fixed Hermes CLI operations
                                            └─ approved host directories
```

Wing Link and Hermes Agent run on the same host. The service automatically selects
a local private/Tailscale address when available and also binds loopback;
`--listen` can select an exact loopback, private-LAN, or Tailscale address. HTTP is
loopback-only. Every non-loopback listener uses TLS 1.3 tied to the durable Wing
Link host identity. Native clients pin its reviewed SHA-256 SPKI fingerprint;
browser clients require normally trusted HTTPS. Each device receives a separate,
named, scoped, individually revocable Wing Link credential, and a Hermes API key
is never accepted by Wing Link.

Wing Link exposure and Hermes Agent exposure are separate. `wing-link setup`
configures the Agent API on `127.0.0.1`; Wing Link does not proxy it. A remote Wing
client therefore needs an independently reachable direct Agent origin, provided
by a trusted VPN address or HTTPS reverse proxy and verified before pairing.

Pairing gives Wing two independently verified connections:

- a profile-bound Hermes Agent origin and credential; and
- a Wing Link origin and management credential.

For VPS deployments, Agent chat and run traffic may use an advertised
HTTPS/WebSocket transport through a TLS 1.3 reverse proxy or a private VPN. The
connection remains direct from Wing to Hermes Agent; Wing Link never relays the
Agent data plane. ACP is an optional local desktop stdio transport, not a remote
Wing Link tunnel. Wing reuses ACP's session, event, and approval semantics while
keeping its privileged terminal/file toolset out of remote connections.

## Current implementation

The current Linux implementation provides:

- install or adopt a pinned Hermes Agent runtime;
- configure API bootstrap and profile multiplexing;
- start, stop, restart, inspect, and diagnose the managed services;
- short-lived QR pairing without bearer tokens in the QR;
- persistent pinned host identity and named per-device credentials;
- host-local approval for install, secret-write, and destructive operations;
- durable idempotent operation tracking and explicit cancellation;
- current/previous protocol-generation negotiation; and
- profile list, create/clone, rename, and delete through fixed Hermes CLI
  argument vectors; and
- remote browsing of locally approved child folders through device-bound,
  expiring opaque handles without returning paths or file names.

Persistent service management is Linux/systemd-user only. New-profile setup can
write an allowlisted provider, bounded model string, and provider credential
through fixed Hermes CLI operations. Existing-profile provider editing, profile
persona editing, directory selection, Project creation, and Project assignment
are not shipped behavior. Approved folder browsing is read-only and ephemeral.

## Target management surface

Wing Link will expose typed, capability-advertised operations in four areas:

1. **Setup and runtime** — installation, adoption, provider/model readiness,
   gateway settings, lifecycle, health, repair, and diagnostics.
2. **Profiles** — list, create/clone, rename, describe, and delete. Hermes Agent
   remains authoritative; Wing Link delegates only reviewed fixed operations.
3. **Agent-owned providers and models** — Wing uses Hermes Agent's advertised
   provider/model APIs directly. Wing Link does not expose provider inventory,
   custom-provider CRUD, or general provider configuration. The only compatibility
   exception is transactional new-profile setup, which may select an allowlisted
   provider and bounded model string and write a credential through `hermes auth
add` stdin without ever returning the secret.
4. **Projects and folders** — browsing explicitly approved host directories is
   implemented; creating or updating a Hermes Project remains blocked on an
   advertised Agent contract.

Every response advertises what this Wing Link build and installed Agent release
can actually perform. Unsupported operations are absent or return a stable
unsupported error; they are never simulated with Wing-owned domain state.

## Profile-to-folder use case

Hermes Agent 0.20 models a workspace as a per-profile **Project** with one or more
folders and a primary folder. Wing should use that model instead of inventing a
profile `workdir` field.

The intended flow is:

1. Create or choose a Hermes profile.
2. Choose an approved directory root on the Hermes host.
3. Browse folder names below that root using opaque handles, not client-supplied
   absolute paths. Regular files are not returned.
4. Select a repository or subdirectory.
5. Create a Hermes Project in the selected profile and make that directory its
   primary folder.
6. Start sessions in that project only when the direct Agent session contract can
   carry the selected Project or working directory explicitly.

Project creation and project-scoped chat are separate capabilities. If the
supported Agent can persist a Project but cannot start a remote session in that
context, Wing shows the assignment and keeps **Start in Project** unavailable; it
does not use `project use` or a hidden process-global working directory.

Current Desktop RPC and human-readable `hermes project` output are reference
evidence, not remote compatibility contracts. Wing Link must not parse or invoke
them for Project mutation. A separately reviewed adapter is considered only
after bounded machine-readable input/output and explicit profile identity exist;
it must never invoke `project use` as hidden global state and must be removed when
the minimum supported Agent release advertises equivalent operations.

For example, the picker may show `git → gormes → gancho`; selecting `gancho`
returns a directory handle that can become the Project's primary folder. It does
not show the files inside `gancho`.

## Folder-selection boundary

Wing Link is a **folder picker**, not a file browser. It returns folders only. It
does not enumerate file names or metadata and cannot read, upload, edit, delete,
or download file contents.

- A local operator configures roots with `wing-link directories grant <local-root>`,
  inspects them with `wing-link directories list`, and revokes them with
  `wing-link directories revoke <directory-id>`. These commands are host-local.
- The API returns opaque root and directory handles plus bounded display names.
- Requests cannot contain absolute paths, `..`, drive prefixes, or shell text.
- Every lookup resolves and revalidates containment; symlinks cannot escape a
  granted root.
- Hidden and sensitive directories are excluded by policy unless explicitly
  granted.
- Folder results are paginated and bounded; diagnostics redact host paths.
- A grant can be revoked without deleting the underlying directory or project.
- The selected handle may be used only for a typed Hermes Project folder
  operation.

## Provider boundary

Provider and model state belongs to Hermes Agent and is accessed through its
advertised APIs. Wing Link exposes no provider inventory, custom-provider CRUD,
or general provider configuration endpoints.

Credential replacement on existing profiles remains blocked. The only setup
exception is transactional new-profile setup, which uses an allowlisted provider,
a bounded model string, and the released stdin-driven `hermes auth add` contract;
it rolls back the new profile if setup or readiness fails. Direct `.env` editing
remains prohibited.

## Non-goals

Wing Link will not provide:

- arbitrary shell, executable, Hermes CLI, config-key, or path execution;
- a reverse proxy for chat or other Agent data-plane traffic;
- a general remote file manager;
- Wing-owned copies of profiles, projects, providers, or sessions; or
- public-internet plaintext administration.

See the [implementation plan](../plans/wing-link-remote-management.md),
[runtime decision](../adr/runtime-and-delivery.md), and
[security decision](../adr/security-and-privacy.md).
