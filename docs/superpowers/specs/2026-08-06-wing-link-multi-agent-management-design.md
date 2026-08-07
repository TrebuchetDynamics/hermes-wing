# Wing Link Multi-Agent Management Design

Status: approved design
Date: 2026-08-06

## Summary

Hermes Wing currently treats Hermes profiles as agents, but the connected Hermes Agent API may advertise only the default profile even when the local Hermes installation contains additional profiles. On the current development host, `hermes profile list` reports `default`, `link`, and `mineru`, while Hermes Wing shows only `default`.

Wing Link will provide a bounded local profile-topology bridge without requiring any Hermes Agent changes. It will use Hermes Agent APIs first, supplement incomplete local inventory from validated profile directories, and use fixed Hermes CLI argument arrays only where the API does not own the operation. Running `wing-link pair` will install and start the per-user Wing Link service, pair Hermes Wing with both Hermes and Wing Link, verify connectivity, and make the merged agent inventory available without further setup commands.

This design supersedes ADR 0044 and the Wing Link local-runtime plan only where they prohibit LAN/VPN Wing Link management, profile-topology bridging, and compatibility transfer of an existing Hermes API key. The replacement boundary is narrow: Wing Link may bridge local profile topology and, when an unchanged Agent cannot issue a scoped enrollment, may transfer the existing local `API_SERVER_KEY` through the reviewed one-time broker. Hermes Agent remains authoritative for chat, sessions, runs, providers, models, skills, memory, schedules, approvals, and profile-owned runtime behavior. The compatibility credential carries full Hermes access and therefore requires explicit operator review on an encrypted VPN or isolated trusted LAN.

## Goals

- Show every local Hermes profile in Hermes Wing, including profiles omitted by the Agent API.
- Support create, clone, rename, and delete from the existing Agents UI.
- Prefer advertised Hermes APIs and use the Hermes CLI only as a bounded compatibility path.
- Require no Hermes Agent code, plugin, endpoint, or configuration change.
- Make `wing-link pair` the only setup command users need after installation.
- Work over a selected trusted LAN or encrypted VPN interface.
- Preserve profile data on Wing Link uninstall and ordinary failures.

## Non-goals

- Proxying chat or other Hermes domain traffic through Wing Link.
- Editing persona, model, skill, provider, memory, schedule, or session state through Wing Link.
- Parsing `hermes profile list`, `show`, or other human CLI output.
- Parsing profile YAML, databases, logs, or shell configuration in Flutter.
- Remote profile deployment to another machine.
- Arbitrary command execution or caller-selected executable paths.
- Making a stopped or unreachable profile appear chat-ready.

## Terminology

- **Agent:** Hermes Wing presentation term for one Hermes profile.
- **API profile:** A profile returned by the connected Hermes Agent API.
- **Local profile:** A validated profile directory discovered by Wing Link.
- **Merged profile:** One stable-ID row combining API and local evidence.
- **Profile topology:** Profile IDs plus create, clone, rename, and delete operations. It excludes profile-owned runtime configuration and content.

## Architecture

### Wing Link service

`wing-link serve` is a persistent per-user service. It opens separate listeners on loopback and one selected eligible network address, each on fixed port `8654`; it never uses a wildcard bind. Eligible network addresses are RFC 1918 IPv4, Tailscale/CGNAT `100.64.0.0/10`, or IPv6 ULA `fc00::/7`. Public, multicast, broadcast, unspecified, and link-local addresses are rejected. Tailscale is preferred, then another eligible private address. If the selected address changes, `wing-link pair` reconfigures and restarts the service before issuing a code.

Platform persistence uses the native per-user mechanism:

- Linux: systemd user service.
- macOS: LaunchAgent.
- Windows: per-user service/startup registration using native APIs.
- Termux: Termux:Boot when installed; otherwise the existing fixed `RUN_COMMAND` restart path.

The service runs as the current user and never requests root or an administrator password.

### Pair command

`wing-link pair` is the complete setup flow:

1. Discover the local Hermes executable, API origin, and credential source. Profile-root discovery is added by Plan B and is not required for Plan A pairing.
2. Install or repair the per-user Wing Link service registration.
3. Start the service and verify unauthenticated `/healthz` locally.
4. Select and validate the Tailscale or LAN interface; restart the service if its selected listener changed.
5. Create a five-minute pairing transaction and display one `wing://connect` QR containing non-secret Hermes and Wing Link origins plus the code.
6. Hermes Wing calls `POST /v1/pairing/inspect` to review endpoint, credential scope, and expiry. After Plan B is installed, the response may also include the merged profile count.
7. Hermes Wing calls `POST /v1/pairing/exchange`. Wing Link uses a scoped Agent enrollment API when advertised; otherwise it returns the existing local `API_SERVER_KEY` plus a new Wing Link control token.
8. Until acknowledgement, repeated exchange of the same unexpired code returns the same in-memory control token. This permits recovery if the app closes before secure storage completes.
9. Hermes Wing stores both credentials in platform secure storage.
10. Using the pending Wing Link token, Hermes Wing verifies authenticated `/v1/status`, Hermes connectivity, and—once the profile bridge is installed—merged profile inventory.
11. Only after verification, Hermes Wing calls `POST /v1/pairing/ack`. Acknowledgement persists the control-token hash, invalidates the code, erases the in-memory raw token, and signals the waiting `wing-link pair` command.
12. Expiry without acknowledgement erases the pending token and persists nothing. `wing-link pair` prints `pairing complete` only after the acknowledgement signal.

A code is single-use after acknowledgement. Before acknowledgement it identifies one replayable pending transaction, not a new credential issuance. No bearer credential appears in the QR, URL, terminal output, logs, clipboard, process arguments, or diagnostics.

### Profile manager

Wing Link owns one `ProfileManager` with three bounded collaborators:

1. **Hermes API client** for capability discovery and API-owned profile operations.
2. **Local inventory scanner** for stable profile IDs only.
3. **Hermes CLI runner** for fixed compatibility commands.

Flutter never chooses which executable or command to run. It sends typed profile requests; Wing Link validates them and chooses the API or fixed CLI path.

## Source precedence

### Inventory

1. Fetch capability-advertised profiles from the Hermes API.
2. Discover local profile IDs from the validated profile root.
3. Add a synthetic immutable `default` row when absent.
4. Merge by exact stable ID.
5. API metadata wins for display name, description, model, skills count, gateway state, and API revision.
6. Local-only rows use their ID as display name and are labeled `Managed by Wing Link`.

A successful API list does not suppress local supplementation. This is required because an unchanged Agent may return only `default` while other profiles exist locally.

### Mutations

Flutter sends all topology mutations to Wing Link when Wing Link is paired. The centralized `ProfileManager` alone chooses the route; Flutter never retries an Agent API mutation through Wing Link.

- For an API-owned or merged row, use an advertised API mutation when available.
- For a merged row lacking that specific advertised API mutation, use CLI only when local evidence for the row exists.
- For a local-only row omitted by the API, use the fixed CLI compatibility path.
- For create without a clone source, use the API when create is advertised; otherwise use CLI.
- For clone from an API-owned or merged source, use API create when advertised; otherwise use CLI.
- For clone from a local-only source, use CLI because the API does not own the source.
- An API-only row with no advertised mutation exposes no corresponding action.
- Never fall back to CLI after an API authorization, conflict, timeout, malformed response, or server failure. Silent fallback could duplicate a mutation.
- After every API or CLI result, including failures, rescan API and local inventory. API failures return the observed outcome (`applied`, `not_applied`, or `unknown`) and never trigger CLI fallback.

## Local inventory

Wing Link derives the profile root with the same platform rules as Hermes:

1. Compute the platform default root (`~/.hermes` on POSIX or `%LOCALAPPDATA%\\hermes` on native Windows).
2. If `HERMES_HOME` is absent, use the platform default root.
3. If `HERMES_HOME` resolves beneath the platform default root, use the platform default root.
4. If the immediate parent of a custom `HERMES_HOME` is named `profiles`, use its grandparent.
5. Otherwise treat the custom `HERMES_HOME` as the root.
6. Scan only `<root>/profiles`; `hermes config env-path` remains a credential-location command and is not used to infer sibling-profile topology.

Wing Link validates that the root and each child are regular local directories beneath the expected profile root. Inventory reads directory basenames only. It does not parse profile YAML, `.env` contents beyond the already-required local API credential lookup, databases, SOUL files, logs, or CLI tables. Symlinks, traversal, absolute caller paths, devices, and names outside the profile-name grammar are rejected.

The synthetic `default` row is always immutable. Wing Link never creates a physical default-profile directory merely to populate the UI.

## Profile identity and revisions

Profile IDs exactly mirror the installed Hermes CLI grammar: `[a-z0-9][a-z0-9_-]{0,63}`. IDs are normalized to lowercase before validation. `default` is a valid synthetic ID but cannot be created, renamed, or deleted. `hermes`, `test`, `tmp`, `root`, and `sudo` are reserved for every mutation. If a reserved directory already exists, Wing Link lists it as a read-only local warning row with no actions; rename and delete return `profile_reserved`. Other invalid directory names are excluded and reported as bounded inventory warnings rather than silently treated as manageable profiles.

Wing Link computes an opaque topology revision from the canonical sorted profile-ID inventory and the target ID. Every row includes a topology revision; API-owned rows also retain their API revision. Each advertised action carries the revision required by its chosen route. Before a CLI rename or delete Wing Link rescans and compares the topology revision. API mutations use the API revision. A mismatch returns `409 profile_inventory_changed`.

## Management API

All profile routes require `Authorization: Bearer <wing-link-control-token>` and `Cache-Control: no-store`.

### Pairing endpoints

- `POST /v1/pairing/inspect` accepts the code and returns non-secret origins, credential mode (`scoped` or `compatibility_full_access`), and expiry. `profile_count` is optional and appears only when Plan B inventory is available.
- `POST /v1/pairing/exchange` accepts the code and returns the Hermes credential plus raw Wing Link control token. Before acknowledgement, replay returns the same pending transaction.
- `POST /v1/pairing/ack` requires the pending Wing Link control token and is called only after app-side verification. It persists the hash, consumes the code, erases pending raw credentials, and signals the waiting CLI command.
- `GET /healthz` is unauthenticated and contains no inventory or configuration.
- `GET /v1/status` is authenticated and proves control-token authorization plus service health. Profile inventory is verified separately through `GET /v1/profiles` after Plan B is installed.

### `GET /v1/profiles`

Response:

```json
{
  "protocol_version": 1,
  "profiles": [
    {
      "id": "mineru",
      "name": "mineru",
      "source": "wing_link",
      "topology_revision": "wlp_example",
      "gateway_state": "unknown",
      "actions": {
        "rename": { "revision": "wlp_example" },
        "delete": { "revision": "wlp_example" }
      }
    }
  ]
}
```

`source` is `api`, `wing_link`, or `both`. `api_revision` is included only when supplied by the API. Unknown metadata remains absent or explicitly unknown; Wing Link never invents model, skill, or gateway readiness.

### `POST /v1/profiles`

Request:

```json
{ "name": "coder", "clone_from": "link" }
```

CLI compatibility command:

```text
hermes profile create coder --no-alias --clone-from link
```

A blank `clone_from` creates a fresh profile with fixed command:

```text
hermes profile create coder --no-alias
```

### `PATCH /v1/profiles/{id}`

Request:

```json
{ "name": "researcher", "revision": "wlp_..." }
```

CLI compatibility command:

```text
hermes profile rename mineru researcher
```

### `DELETE /v1/profiles/{id}`

Requires `If-Match: <revision>`. CLI compatibility command:

```text
hermes profile delete --yes mineru
```

The app retains typed-name confirmation before sending delete. Wing Link independently rejects `default`, stale revisions, invalid IDs, and unknown profiles.

## Command safety

- Resolve only the locally discovered `hermes` executable.
- Use `exec.CommandContext(path, args...)`; never a shell.
- Permit only the exact command templates in this specification.
- Apply bounded timeouts and terminate process trees on timeout.
- Redact inherited and explicit secret values from bounded output.
- Do not return raw CLI output to Flutter.
- Determine success from exit status followed by an inventory rescan.
- Serialize profile mutations to prevent overlapping CLI/API operations.

## Flutter integration

The existing Agents screen remains the management surface.

- Add a Wing Link client and secure control-token store.
- Load Agent API profiles first, then request Wing Link profiles when paired.
- Merge by stable ID using the same precedence as Wing Link.
- Show `Managed by Wing Link` on local-only rows.
- Keep New Agent, Clone, Rename, and Delete actions in the existing editor.
- When Wing Link is paired, route all topology mutations to Wing Link and send the revision advertised for that action. Wing Link owns API-versus-CLI selection.
- Without Wing Link pairing, retain the existing direct Agent API behavior and capability gates.
- Gate each action from the merged row's advertised `actions`, not solely from Agent capabilities.
- Keep Chat disabled for a local-only profile until the Agent advertises usable profile context or a reachable profile gateway. Management visibility must not imply chat readiness.
- Preserve gateway selection and client-local profile selection behavior.
- Keep the layout operable at 320 px width and 200% text scale.
- Put all app-owned strings in `lib/l10n/app_en.arb` and regenerate localization output.

## Authentication and network safety

- Wing Link control tokens are independent of Hermes credentials.
- Pairing codes are random and expire after five minutes. One pending transaction may be replayed before acknowledgement; acknowledgement consumes it permanently.
- When the Agent advertises scoped enrollment, Wing Link requests only the app's allowlisted chat, session, and administration scopes and never requests wildcard scope.
- When scoped enrollment is absent, the compatibility broker reads the existing local `API_SERVER_KEY`, labels the review `Full Hermes access`, and transfers it only after explicit confirmation. This is the approved exception to ADR 0044's prohibition on returning the superuser key.
- The compatibility key remains in memory only; Wing Link never writes another copy. Hermes Wing stores it in platform secure storage as the Hermes credential.
- Wing Link stores only acknowledged SHA-256 control-token hashes in owner-only state. Pending raw control tokens exist only in memory until acknowledgement or expiry.
- Management requests accept tokens only in the Authorization header.
- Listener addresses must belong to a current local interface and satisfy the explicit RFC 1918, CGNAT, or IPv6 ULA eligibility rules above; wildcard, multicast, broadcast, public, unspecified, and link-local addresses are rejected.
- Prefer HTTPS when configured. Plaintext HTTP is allowed only on an encrypted VPN or isolated trusted LAN after explicit confirmation in Hermes Wing.
- Outside the pairing exchange response, profile and status APIs never return Hermes credentials, Wing Link tokens, local paths, config values, or command output.
- Ordinary uninstall preserves Hermes profiles and data.

## Error handling

Stable error codes:

- `profile_invalid_name` — name violates the grammar.
- `profile_reserved` — mutation targets `default`, `hermes`, `test`, `tmp`, `root`, or `sudo` contrary to the operation rules.
- `profile_not_found` — target or clone source is absent.
- `profile_already_exists` — requested ID already exists.
- `profile_inventory_changed` — revision no longer matches.
- `profile_operation_in_progress` — another topology mutation is active.
- `profile_api_failed` — an advertised API operation failed; no CLI fallback occurred, and the response includes the rescanned observed outcome.
- `profile_cli_failed` — the fixed CLI command failed.
- `profile_inventory_unavailable` — neither safe inventory source could be read.
- `wing_link_service_unavailable` — setup could not install, start, or verify the service.

Errors contain bounded operator guidance but no secrets, paths, URLs with credentials, CLI output, or profile content.

## Testing strategy

### Go

- Inventory merges API `default` with local `link` and `mineru`.
- API metadata wins on duplicate IDs.
- A successful incomplete API list still receives local supplementation.
- API capability present routes create/rename/delete through API only.
- API errors never trigger CLI fallback.
- Local-only rows route rename/delete through exact CLI argument arrays.
- Create with and without clone uses exact fixed arguments.
- Invalid IDs, every reserved name, symlinks, traversal, stale revisions, and duplicate operations fail closed.
- Platform-default, custom-root, and profile-scoped `HERMES_HOME` fixtures all resolve the same sibling inventory as Hermes.
- Loopback plus one eligible private/VPN listener bind separately; public, wildcard, and link-local addresses fail closed.
- CLI timeout kills descendants and returns bounded sanitized errors.
- Pair installs/starts service, supports inspect/exchange/ack, replays one pending exchange after app interruption, expires unacknowledged credentials, verifies inventory, and survives terminal exit.
- Linux, macOS, Windows, and Termux service adapters have focused contract tests.

### Flutter

- API-only, Wing-Link-only, and merged profile rows render once each.
- Local-only rows show their source and correct actions.
- API metadata wins after merge.
- When paired, create/clone/rename/delete always call Wing Link; its advertised action revisions select the correct internal route.
- Without pairing, existing direct Agent API mutations remain available.
- API failure is visible with its observed outcome and never triggers CLI fallback.
- Delete still requires typed confirmation.
- Local-only Chat remains disabled until usable Agent context exists.
- Control token is stored separately and never rendered.
- Pairing resumes after app recreation without issuing duplicate credentials.
- Agents UI passes 320 px, 200% text scale, semantics, and keyboard tests.

### End-to-end receipt

A clean-host receipt must prove:

1. `wing-link pair` is the only post-install setup command.
2. The service survives terminal closure and restarts on login.
3. Hermes Wing stores Hermes and Wing Link credentials securely.
4. `default`, `link`, and `mineru` appear when only `default` comes from the Agent API.
5. Clone creates a fourth profile.
6. Rename updates the stable inventory.
7. Delete removes only the confirmed non-default profile.
8. Restart preserves and rediscovers the remaining profiles.
9. No Hermes Agent modification was installed or required.

## Implementation decomposition

This specification is delivered through two ordered implementation plans rather than one oversized change.

### Plan A — service and pairing foundation

Prerequisite for profile work:

- Replace the unavailable `serve/start/stop/restart` stubs with the authenticated service.
- Add separate loopback and selected private/VPN listeners.
- Add native per-user persistence for Linux first, then macOS, Windows, and Termux adapters behind the same contract.
- Implement inspect/exchange/ack recovery and separate Wing Link secure storage in Flutter.
- Make `wing-link pair` install, start, pair, acknowledge, and verify the service without extra commands.
- Update ADR 0044 and security documentation before enabling the network listener.

Success signal: a paired app can restart and call authenticated `/v1/status` without the terminal or pairing process remaining alive. Plan A does not claim merged-profile support.

### Plan B — profile topology bridge

Begins only after Plan A's success signal:

- Add root resolution, local inventory, merge semantics, revisions, and fixed CLI commands.
- Add API-first mutation routing and post-result reconciliation.
- Add `/v1/profiles` routes and Flutter merged inventory/actions.
- Complete the clean-host create/clone/rename/delete/restart receipt.

Success signal: `default`, `link`, and `mineru` appear when the Agent API returns only `default`, and full topology management works without Hermes Agent changes.

## Documentation and decision updates

Implementation planning must update ADR 0044, the Wing Link local-runtime plan, `CONTEXT.md`, the threat model, roadmap, README, and changelog to reflect these approved changes:

- Wing Link may expose authenticated management on a selected LAN/VPN interface.
- Wing Link may bridge local profile topology through API-first, fixed-CLI-second behavior.
- `wing-link pair` uses scoped Agent enrollment when available, otherwise the explicitly approved full-access compatibility broker, and performs complete service setup.
- The compatibility broker is the precise exception to ADR 0044's statement that Wing Link never returns the Hermes superuser key; it remains memory-only, review-gated, expiring, and limited to trusted VPN or isolated LAN pairing.
- No Hermes Agent changes are required.
- Wing Link remains prohibited from proxying chat or managing non-topology Hermes domains.
