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
3. **Providers and models** — new-profile setup selects an allowlisted provider and
   bounded model string and may write a credential through `hermes auth add` stdin without ever
   returning the secret. General provider editing remains a target surface.
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

Provider and model state belongs to Hermes Agent. Wing Link may offer a typed
compatibility adapter only when the official Agent API lacks an equivalent and
the exact operation is reviewed.

- Provider IDs and configurable fields come from an allowlist or authoritative
  Agent inventory; clients cannot submit arbitrary config keys.
- Credentials are write-only: set/remove and configured/not-configured only.
- Secrets never appear in responses, command arguments, logs, diagnostics, or
  persisted Wing Link state.
- A change reports whether an Agent reload or gateway restart is required; Wing
  does not hide disruptive lifecycle work inside an ordinary save.

Credential replacement on existing profiles remains blocked. New-profile setup
uses the released stdin-driven `hermes auth add` contract and rolls back the new
profile if setup or readiness fails; direct `.env` editing remains prohibited.

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
