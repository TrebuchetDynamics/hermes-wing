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
  private/VPN listener, fixed profile list/create/rename/delete, and remote
  browsing of locally approved child folders only through opaque handles.
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
- Keep local directory grants and ephemeral remote browsing through opaque
  handles fail-closed; never persist navigation handles in Wing.
- Create and manage per-profile Hermes Projects for repositories or subfolders
  only after Hermes Agent advertises an explicit machine-readable contract.
- Carry explicit profile/project identity; never call global `profile use` or
  `project use`.

**Done when:** from a paired phone, a user can create a profile, select an approved
repository or subfolder, and create the authoritative Hermes Project without
unrestricted host filesystem access. Starting Chat there remains gated on an
explicit direct-Agent Project/working-directory contract. Project-aware Chat remains gated.

### 4. Release and primary experience

- Keep Markdown, code copy, approvals, reconnect, and accessibility dependable.
- Produce one versioned, verified alpha package with install/upgrade/uninstall
  evidence before expanding stores or platforms.
- Record physical-device voice evidence before expanding acoustic claims.

## Engineering quality (audit remediation, 2026-08)

A technical audit (in [docs/superpowers/plans/2026-08-17-audit-remediation.md](docs/superpowers/plans/2026-08-17-audit-remediation.md))
flagged the channel god-object, brittle meta-tests, and vendored forks as the
main technical debt. This track addresses those findings plus the hardening
items they surface; feature work above stays on the product tracks.

- [ ] **Baseline (Milestone 0).** Land the in-flight pocket_speech removal while
      preserving an unrelated dirty worktree; rerun the complete validation gate
      and record results in the evidence matrix.
- [x] **Vendored forks (Milestone 0).** Removed the obsolete vendored speech
      recognition fork and use the hosted `speech_to_text` 7.4.0 package.
- [ ] **Cache-key hygiene (Milestone 1).** Replace `sha256(apiKey)` in the
      in-memory `_recentTurnKey` with a non-secret discriminator.
- [ ] **Taxonomy tests (Milestone 1).** Retire the 7 tautological taxonomy tests
      in favor of behavioral widget coverage or a single route-resolution test.
- [ ] **Channel services (Milestone 2).** Extract the approvals and session
      concerns out of the `HermesApiChannel` part files into injectable,
      independently testable services.
- [ ] **Contract-test surface (Milestone 2).** Shrink `test/tooling/` from 17
      source-contract files to 3-5 high-value ones; convert the rest to
      behavioral tests.
- [ ] **Property tests + lints (Milestone 3).** Add property-based coverage for
      redaction and URL validation, enrich the linter, and document the channel
      lifecycle states.

## Next

| Area         | Next safe slice                                                                        |
| ------------ | -------------------------------------------------------------------------------------- |
| Folders      | Browsing is shipped; selection remains gated on authoritative Hermes Project creation. |
| Providers    | Typed defaults, then secret-safe credential set/remove.                                |
| Projects     | Multi-folder management, archive/restore, and project-aware Chat.                      |
| Skills/tools | Mutate only through advertised Agent APIs.                                             |
| Memory       | Browse/search/delete with confirmation and Agent authority.                            |
| Schedules    | Add advertised CRUD/pause/resume/run with confirmation.                                |
| Platforms    | Add a native Wing Link service adapter with real runtime evidence.                     |

## Later

- project-aware folder selection without exposing file names or contents;
- per-device credential rotation and broader local grant administration;
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
