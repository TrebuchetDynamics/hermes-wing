# Terminal working-directory files: feasibility without Agent changes

## Verdict

**Browse, text preview and single-file download are feasible without modifying
Hermes Agent or requiring Wing Link.** The official Desktop already consumes
Agent's existing filesystem HTTP routes for remote connections. This is a client
port, not a new Agent feature.

**The complete FILES-1–FILES-4 requirement is not yet proven.** Existing routes
are not a universal session-scoped, cwd-confined file authority. Backend type,
authentication, root selection and canonical containment need qualification.
Do not advertise all connected Agents or all terminal backends as supported.

Scope: source research only. No product implementation, personal-runtime change,
Agent modification, service launch, credential access or device operation.
The [accepted requirement](../product/prd.md#terminal-working-directory-files)
and tasks `FILES-TERMINAL-BROWSE` / `FILES-TERMINAL-DOWNLOAD` remain planned.

## Provenance

Read-only local Agent checkout: `158fd638da1629c8e62caf9ade1515d162def8ab`.
A live `git ls-remote` probe resolved main to
`1e0c7730d791f5ce855c5c78935cfea6fb1e43a9`. Relevant source files were fetched
from raw GitHub URLs pinned to that exact revision, without fetching into or
changing the reference checkout. Findings below use those fetched files unless
explicitly marked local. This is not a release-version or installed-runtime claim.

Source copies and SHA-256 manifest:
`.task-evidence/terminal-files-research/latest-manifest.json` (ignored evidence).

Official documentation checked:
- [Hermes Desktop](https://hermes-agent.nousresearch.com/docs/user-guide/desktop)
- [Desktop native sign-in](https://hermes-agent.nousresearch.com/docs/guides/desktop-native-signin)

## Existing contracts and official consumers

Agent source: [filesystem routes at the inspected revision](https://github.com/NousResearch/hermes-agent/blob/1e0c7730d791f5ce855c5c78935cfea6fb1e43a9/hermes_cli/web_routers/files.py).

- `GET /api/fs/default-cwd?profile=…`: cwd and branch. Local resolution checks
  `terminal.cwd`, then `TERMINAL_CWD`, then the server process cwd. The configured
  SSH filesystem adapter instead supplies its own cwd.
- `GET /api/fs/list?path=…&profile=…`: directory entries with `name`, `path`,
  `isDirectory`; directories sorted first and selected noise/sensitive names hidden.
- `GET /api/fs/read-text?path=…&profile=…`: text, byte size, binary flag,
  language, MIME type, path and truncation flag. Preview cap is 512 KiB; files
  exceeding the 64 MiB source ceiling are rejected. Text uses replacement UTF-8
  decoding, so this is not a byte-exact download contract.
- `GET /api/fs/download?path=…&profile=…&session_id=…`: raw file response or
  SSH-backed streaming response, with attachment disposition. Use this for exact
  binary/text bytes; do not reconstruct downloads from the text preview.

Official Desktop source:
[desktop-fs.ts](https://github.com/NousResearch/hermes-agent/blob/1e0c7730d791f5ce855c5c78935cfea6fb1e43a9/apps/desktop/src/lib/desktop-fs.ts)
uses these HTTP routes in remote mode (`readDesktopDir`, `readDesktopFileText`,
`desktopDefaultCwd`). Local mode uses Electron's native filesystem bridge.
`store/file-actions.ts::shouldOfferRemoteFileDownload` offers downloads for
individual remote files, not folders. The native
[electron/gateway-file-download.ts](https://github.com/NousResearch/hermes-agent/blob/1e0c7730d791f5ce855c5c78935cfea6fb1e43a9/apps/desktop/electron/gateway-file-download.ts)
constructs profile/session-scoped download paths, resolves the owning connection,
and saves through a deliberate native dialog with streamed temporary-file handling.
Flutter must reproduce that outcome, not import Electron implementation.

## Material limits

### 1. Correct server, not just a successful chat connection

These routes belong to `hermes serve` / the dashboard FastAPI app, registered by
`hermes_cli/web_server.py`. The inspected messaging/OpenAI-compatible adapter
`gateway/platforms/api_server.py` does not declare `/api/fs/*` routes.
Wing's current REST/SSE chat integration and SSH forwarding do not themselves
establish access to this different server contract.

A normal, unmodified serve backend is a viable target. Where a connection only
exposes the messaging API, file operations must remain unavailable unless the
owner separately provides an authenticated compatible serve endpoint. Starting
or exposing another service is an operational change, not something this research
performed or silently authorizes.

### 2. Cwd and session ownership are not interchangeable

List and text-read accept profile but **no session_id**. Download's host-local
branch validates the selected profile/session and resolves relative paths using
its stored cwd through `get_session_detail`. Its SSH branch selects the
profile's adapter before that session-resolution helper.

Local `fs_default_cwd` calls `_fs_default_cwd()` outside `_profile_scope`; adding
`profile=` alone does not prove it reads a secondary profile's local config.
Prefer the selected session's authoritative cwd where available, and qualify
profile-bound backend selection for sessionless browsing. Do not silently fall
back to Wing cwd or another profile's process cwd. A stored session cwd is also
not proof of the terminal's instantaneous cwd following every tool invocation.
The local official Desktop's focused-cwd selection can be studied in
`src/store/session-states.ts::$focusedWorkspaceCwd`; it checks session ownership
rather than blindly using a global cwd.

### 3. Root restriction is stronger than the general route contract

`web_server_files.py::_fs_path` resolves canonical paths, but does not itself
restrict them to terminal.cwd. The newer `_hosted_fs_read_guard` confines
host-local reads to a configured/hosted managed root where `locked_root` exists.
That root is not automatically the selected session's cwd; unrestricted local
mode has no such locked root. Download's session check is an ownership and
relative-resolution check, not an automatic cwd jail.

A lexical path-prefix check in Wing is not sufficient proof against symlinks or
filesystem races. Under the existing strict FILES-4 requirement, qualify an
existing server-enforced boundary aligned with the chosen root, or leave the
strict operation unsupported. Do not weaken the requirement or claim that hiding
parent navigation provides server-side confinement. Existing managed-root
configuration is not an Agent code modification, but changing the owner's
runtime configuration remains a separately authorized action.

### 4. Terminal backend support is not universal

`hermes_cli/ssh_workspace_fs.py::get_ssh_workspace_fs` selects only
`terminal.backend: ssh`; otherwise the routes use the serve host filesystem.
An SSH connection **to the Agent host** and an Agent terminal configured to
execute **on another SSH target** are distinct cases.

The existing Agent SSH adapter can list/read/stream that configured target, so
Wing need not add arbitrary SSH commands or SFTP solely for ordinary file access.
However its path normalization is not a cwd-containment guarantee, and session
scope needs separate qualification. Docker, Daytona, Modal and other terminal
backends are not established by these filesystem routes. Never show a same-named
host directory as though it were the execution environment's directory.

### 5. Authentication and native saving still need Wing work

Use the backend's actual authentication contract. Loopback serve session tokens,
native OAuth tokens and messaging API keys are not interchangeable. The official
native sign-in documentation specifies bearer headers for REST after sign-in;
non-loopback serve has its own authentication gate. SSH tunnelling supplies
transport confidentiality, not HTTP authorization. Keep strict SSH host review.
Never put credentials in download URLs or open a token-bearing URL in an external
browser; native Wing can authenticate its own HTTP stream using headers.

Linux Save As and Android document creation/save are client-side integrations.
Android cannot directly browse another app's private directories; authenticated
Agent HTTP is the appropriate boundary. Cancellation, partial-save cleanup,
filename handling, bounded transfer and saved-byte readback remain implementation
and native qualification work, not findings of successful device execution.

## Evidence and recommendation

Inspected upstream tests (not executed):
- `tests/hermes_cli/test_web_server_fs.py`: directory ordering/noise filtering,
  SSH-route delegation (fake adapter), text previews and path encoding.
- `tests/hermes_cli/test_web_server_files.py`: session-relative download bytes,
  wrong/missing profile-session rejection and sensitive file handling.
- Official Desktop filesystem/download tests: scope and native transport behavior.

Executed static check:
`python .task-evidence/terminal-files-research/check_source.py` — exit 0.
It checks downloaded source hashes, the four GET contracts, profile/session
parameter differences, hosted download guard, SSH-only adapter selection and
absence of fs routes in the messaging adapter. This is source-contract evidence,
**not an HTTP integration test or native qualification**. The read-only Agent
worktree remained clean after inspection.

Recommended first implementation: a read-only Flutter Files pane against an
explicitly compatible authenticated serve connection, using authoritative session
cwd and exact connection/profile ownership. Hide unsupported operations, especially
unqualified terminal backends and missing strict root enforcement. Then implement
raw download streaming and platform save integration. No Agent fork, plugin,
Wing Link installation, prompt submission or unrestricted client shell is needed
for the supported route. Do not close either feature task on this research alone.
