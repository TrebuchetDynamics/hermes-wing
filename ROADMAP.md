# Hermes Wing Roadmap

Hermes Wing is an alpha client for Hermes Agent. This roadmap lists remaining
product work; shipped changes belong in [CHANGELOG.md](CHANGELOG.md).

## Product rules

- Hermes Agent remains authoritative for agent and project state.
- Wing Link is the remote management plane, not a chat proxy or second backend.
- Expose only exact advertised or reviewed typed operations.
- Never expose arbitrary CLI, config keys, host paths, or file contents.
- Require evidence before platform, release, voice, or security claims.

## Current baseline

- Direct Agent chat, sessions, streaming runs, tool activity, approvals, and stop.
- Saved gateways, profile switching, health, provider/model inventory, and jobs
  inventory where supported.
- Wing Link install/adopt, pairing, lifecycle, diagnostics, Linux user service,
  private/VPN listener, and fixed profile list/create/rename/delete.
- Android-first Flutter client with web and desktop alpha targets.

## Now

### 1. Reliable Agent compatibility

- Keep supported Hermes Agent fixtures and capability tests current.
- Adapt read-only `/api/model/options` and advertised jobs operations; keep model
  mutation hidden until an exact route is advertised.
- Remove assumptions about unshipped profile, scope, revision, and HTTP audio APIs.
- Keep unsupported, unauthorized, empty, and failed states distinct.

### 2. Remote Wing Link management

- Document and version Wing Link capabilities by exact operation.
- Qualify setup, pairing, lifecycle, restart/recovery, and VPN access on Linux.
- Add credential rotation and clear separation from Agent API credentials.
- Keep provider setup typed and write-only; block secret mutation until Hermes has
  a secret-safe noninteractive contract.

### 3. Profiles, directories, and Projects

- Add profile show/description only through fixed reviewed contracts.
- Configure local directory roots; browse them remotely with opaque handles.
- Create and manage per-profile Hermes Projects for repositories or subfolders.
- Carry explicit profile/project identity; never call global `profile use` or
  `project use`.

**Done when:** from a paired phone, a user can create a profile, select an approved
repository or subfolder, and create the authoritative Hermes Project without
unrestricted host filesystem access. Starting Chat there remains gated on an
explicit direct-Agent Project/working-directory contract.

### 4. Release and primary experience

- Keep Markdown, code copy, approvals, reconnect, and accessibility dependable.
- Produce one versioned, verified alpha package with install/upgrade/uninstall
  evidence before expanding stores or platforms.
- Record physical-device voice evidence before expanding acoustic claims.

## Next

| Area | Next safe slice |
| --- | --- |
| Folders | Select approved directories for Hermes Projects; never list files. |
| Providers | Typed defaults, then secret-safe credential set/remove. |
| Projects | Multi-folder management, archive/restore, and project-aware Chat. |
| Skills/tools | Mutate only through advertised Agent APIs. |
| Memory | Browse/search/delete with confirmation and Agent authority. |
| Schedules | Add advertised CRUD/pause/resume/run with confirmation. |
| Platforms | Add a native Wing Link service adapter with real runtime evidence. |

## Later

- project-aware folder selection without Wing Link file browsing;
- per-device credential scopes, rotation, and revocation;
- opt-in notifications for detached runs;
- richer accessible Office interactions; and
- additional signed stores and packages.

## Not planned

- Arbitrary shell, executable, Hermes CLI, config-key, or path execution.
- Proxying Agent chat/sessions/runs through Wing Link.
- Wing-owned copies of profiles, Projects, providers, or sessions.
- File listing, preview, reading, or editing through Wing Link.
- Bundling Hermes Agent, Python, Node, or provider runtimes inside Wing.
- Platform support inferred from compilation alone.

See [Wing Link](docs/product/wing-link.md) and its
[implementation plan](docs/plans/wing-link-remote-management.md).
