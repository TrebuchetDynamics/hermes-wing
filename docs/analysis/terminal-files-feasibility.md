# Terminal working-directory files: feasibility without Agent changes

## Verdict

Current implementation direction: the owner-selected
[managed-files root](#managed-files-root-the-owner-selected-alternative), through
`/api/files` and `/api/files/read`, enabled only for an authenticated connection
whose server advertises a non-empty `locked_root`. The terminal-cwd analysis and
deferral below remain historical evidence for a different root, not additional
prerequisites for the managed-root tasks. Neither `terminal.cwd` nor a successful
chat connection proves file confinement.

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

Historical terminal-cwd recommendation (superseded for the current managed-root
surface by the [owner-selected alternative](#managed-files-root-the-owner-selected-alternative)):
a read-only Flutter Files pane against an
explicitly compatible authenticated serve connection, using authoritative session
cwd and exact connection/profile ownership. Hide unsupported operations, especially
unqualified terminal backends and missing strict root enforcement. Then implement
raw download streaming and platform save integration. No Agent fork, plugin,
Wing Link installation, prompt submission or unrestricted client shell is needed
for the supported route. Do not close either feature task on this research alone.

## Revisit check: upstream 14e1e43a (2026-10-24)

The FILES deferral is reconsidered only with new source-bound contract evidence.
A read-only probe on 2026-10-24 resolved upstream `main` to
`14e1e43a23761b369641208e204365cd6cb9399d`, newer than the analysed
`1e0c7730…`. `hermes_cli/web_routers/files.py`, `hermes_cli/web_server_files.py`
and `tests/hermes_cli/test_web_server_fs.py` were fetched from that exact
revision through raw URLs; the reference checkout was not fetched into, reset or
otherwise changed. No Agent, service, credential or device operation was
performed.

Changed since the analysed pin:

- `_agent_fs_path` (new in `web_server_files.py`) translates a readable host path
  or a container path to its host mount for the requested profile before the
  caller's boundary guard runs.
- `fs_list` and `fs_read_text` now resolve one host target through that helper,
  so the requested profile's container volumes translate before the read
  boundary check.
- `_fs_profile_home` resolves an omitted, empty or `current` profile to the
  request's own profile and asks `_cron_profile_home` for any other one.
- Download/data-URL responses distinguish an untranslated container path
  (`SANDBOX_NOT_FOUND`) from an ordinary missing file.
- Upstream tests add cases for that translation and profile binding.

Unchanged, and still gating the strict FILES-4 requirement:

- `/api/fs/list` and `/api/fs/read-text` take `profile` only. Neither accepts a
  `session_id`, so neither can name the selected session's authoritative
  terminal root (Material limit 2).
- `_fs_path` → `_resolve_fs_candidate` resolves an absolute path as given; `cwd`
  only joins relative paths. `_hosted_fs_read_guard` refuses a target outside
  `locked_root`, and that root comes from the managed-files policy
  (`HERMES_DASHBOARD_FILES_ROOT`, or `/opt/data` for a hosted root). It is an
  operator-configured managed files root, not the selected session/profile
  terminal cwd, and it is unset for ordinary local serve (Material limit 3).
- `_fs_download_path` still uses the stored session cwd for relative
  resolution and ownership validation only; an absolute path is not confined to
  it.
- The route set is unchanged: `list`, `read-text`, `write-text`,
  `read-data-url`, `download`, `git-root`, `default-cwd`. The contract summary
  above lists the four GET routes it relied on, and `write-text` stays outside
  Wing's read-only scope.
- Upstream tests at this revision still assert ordering/noise filtering,
  container translation, profile scope, sensitive-path refusal and
  authentication. None asserts cwd confinement.

Historical terminal-root verdict: the deferral gate remained unsatisfied. No
advertised operation both names the effective selected session/profile/backend
terminal root and enforces server-side canonical confinement to it. The later
[managed-root decision](#managed-files-root-the-owner-selected-alternative)
supersedes that implementation deferral without establishing terminal-cwd support;
`FILES-TERMINAL-DOWNLOAD` still depends on completed browsing. This is a source
contract recheck only, not an HTTP, native or live qualification.

## Managed-files root: the owner-selected alternative

Owner decision, 2026-10-24 (recorded in the
[product ADR](../adr/product.md#owner-approved-files-surface-the-agents-managed-files-root)):
root the read-only Files surface at the Agent's managed-files root instead of the
terminal cwd. The contract below is what makes that implementable and safe; it is
read from the same `14e1e43a` sources.

- `GET /api/files?path=…` returns `path`, `parent`, `entries` (`name`, `path`,
  `is_directory`, `size`, `mtime`, `mime_type`) and the policy meta
  `{root, locked_root, can_change_path}`. This is not `/api/fs/list`'s camelCase
  entry format. Managed listings filter sensitive paths, not the
  `_FS_READDIR_HIDDEN` noise set. Directories sort first, and `parent` is `null`
  at the locked root, so the client gets no above-root navigation token.
  Symlink entries keep their alias name but return the resolved target path;
  broken-link placeholders have `broken_link: true` and no readable target.
- `GET /api/files/read?path=…` returns `name`, `path`, `size`, `mime_type` and a
  base64 `data_url`, capped by `_MANAGED_FILE_MAX_BYTES` (100 MiB). Use
  `/api/files/download?path=…` for exact streamed bytes and
  `/api/files/stream` for range media; never rebuild a download from a preview.
- Confinement is server-side in `_resolve_managed_path`: `..` is refused, a
  relative path joins the locked root, an absolute path must resolve under it
  (403 otherwise), the target is canonicalised with `require_exists`, and
  sensitive paths are denied on list, read and download.
- Without `locked_root` the same routes serve `default_path` with
  `can_change_path: true` and no containment. That is a different, unconfined
  policy: Wing must show the surface unavailable rather than fall back to it.
- Authentication is the serve deployment's own session/bearer contract.
  `_QUERY_TOKEN_API_PATHS` allows a `?token=` only for `/api/files/download`;
  a native client should send headers instead of putting a token in a URL.
- `write-text`, `upload`, `mkdir` and `delete` exist but stay outside Wing's
  read-only scope.
- Managed GET resolution calls `_managed_files_policy()` with its default
  `create_root=True`; Agent may create a missing configured root. Wing does not
  configure that root or call a mutation route. A prepared, pre-existing locked
  root and absence of incidental server mutations must be checked on the named
  deployment before native/live qualification; a fixture cannot establish them.

The [Wing managed-files receipt](../quality/managed-files-browse.md) records the
read-only candidate, corrected snake_case wire format, source hashes, bounded
client checks and the outstanding native/live cells. It does not establish
terminal-cwd parity.
