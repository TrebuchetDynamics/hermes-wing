# Gateway, profile, and Project management

Status: current behavior plus planned Wing Link expansion

## Identity and authority

A saved gateway is one canonical Hermes Agent origin. Profile names are local to
that origin; `coder` on two hosts means two different contacts. When pairing
imports profile-bound `/p/<profile>` endpoints from one Wing Link device, Wing
presents them as one host connection with a profile count rather than as separate
gateways. The profile credentials and explicit request context remain distinct.

Hermes Agent owns profiles, Projects, providers, models, sessions, and tools.
Wing Link performs host management and reviewed fixed compatibility operations;
it keeps no shadow inventory.

A paired host has two credentials:

- a direct, profile-bound Hermes Agent credential; and
- a separate Wing Link management credential.

## Current profile path

Hermes Agent 0.20 documents profile lifecycle through CLI. Current Wing Link uses
fixed argument vectors for:

| Outcome         | Hermes command                       |
| --------------- | ------------------------------------ |
| List            | `hermes profile list`                |
| Create or clone | `hermes profile create ...`          |
| Rename          | `hermes profile rename <old> <new>`  |
| Delete          | `hermes profile delete --yes <name>` |

It invokes no shell, validates identifiers, bounds output and time, and never
calls `hermes profile use`.

Pairing may enable `gateway.multiplex_profiles`, restart the default gateway, and
verify each named profile at `/p/<profile>/...` with that profile's own
`API_SERVER_KEY`. The default key cannot authenticate a named profile.

## Planned profile editing

Wing will add profile show/description only when a fixed machine-readable Hermes
contract is proven. Persona/SOUL editing must use an authoritative typed Agent or
CLI operation; Wing Link will not become a raw profile-file editor.

## Repository and subfolder assignment

Hermes Agent 0.20 provides per-profile Projects. A Project can contain multiple
folders and one primary folder. This is the authoritative model for assigning a
profile to a repository or subfolder.

Planned Wing flow:

1. Create or select a profile.
2. Browse a locally approved directory root through Wing Link opaque handles.
3. Select a repository or subfolder.
4. Create a Hermes Project in that profile and make the folder primary.
5. Open sessions in the explicit profile/Project context only if the direct Agent
   session API advertises that input; otherwise keep project-scoped Chat disabled.

The adapter may use fixed per-profile `hermes project` operations for list,
create, show, add/remove folder, rename, set-primary, archive, and restore. It
must never use `project use` as hidden global state.

## Provider and model behavior

Current Agent APIs provide model inventory/options and model selection. Wing must
prefer them when advertised.

Wing Link has no provider-configuration adapter. Provider and model state stays
in Hermes Agent and is accessed through its advertised APIs. Remote provider-key
mutation remains blocked until Hermes offers a noninteractive secret contract
that does not expose values in argv or require direct `.env` editing.

## Remote boundary

Wing Link runs on the Agent host. It serves HTTP only on loopback and TLS 1.3 on
the selected private-LAN, NetBird, or Tailscale interface, using its durable host identity and
a dedicated named management credential. Native clients pin the reviewed SPKI;
browser clients require normally trusted HTTPS. Wing Link does not proxy Agent
chat or accept Agent API keys.

`wing-link setup` leaves the direct Hermes Agent API bound to `127.0.0.1`.
Remote pairing requires the operator to expose that separate Agent listener on a
trusted VPN address or HTTPS reverse proxy first. Making Wing Link reachable does
not make the Agent data plane reachable.

Folder selection is limited to locally approved roots, opaque handles, bounded
child-folder names, containment checks, and revocation. Wing Link does not return
regular file entries, file metadata, or file contents.

## Troubleshooting

1. Run `hermes profile list` and `hermes project list` on the host.
2. Confirm each named profile has its own `API_SERVER_KEY`.
3. Confirm multiplexing and the `/p/<profile>/health` route.
4. Run `wing-link status` and pair again if endpoints changed.
5. If a capability is absent, do not work around it with a raw path, command,
   config key, or copied credential.

See [Wing Link](wing-link.md) and the
[implementation plan](../plans/wing-link-remote-management.md).
