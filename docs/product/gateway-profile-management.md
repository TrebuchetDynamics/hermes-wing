# Gateway profile management and limitations

## What this is

Hermes Wing can manage profiles separately on each saved gateway. Open
**Settings → Gateways → gateway menu → Manage profiles**, or open **Profiles** and
choose a gateway. The selected gateway remains authoritative for every read and
mutation.

A saved paired gateway can carry two independent connections:

- the Hermes origin and Hermes bearer credential for chat, sessions, and runs;
- the Wing Link origin and control credential for local profile topology.

Wing Link is not a Hermes reverse proxy. The Flutter client never sends chat,
session, run, approval, or model traffic through it. A paired Wing Link may
manage profile-scoped custom provider definitions through its typed Hermes CLI
adapter; provider credentials remain on the direct Hermes contract.

## Supported workflows

### Hermes-advertised profiles

When authenticated `GET /v1/capabilities` advertises the exact profile query
contract, scopes, methods, and routes, Wing uses Hermes directly:

| Operation               | Required Hermes contract                        |
| ----------------------- | ----------------------------------------------- |
| List                    | `GET /api/profiles`, `profiles:read`            |
| Create                  | `POST /api/profiles`, `profiles:write`          |
| Rename display metadata | `PATCH /api/profiles/{name}`, `profiles:write`  |
| Persona                 | `GET` and `PUT /api/profiles/{name}/soul`       |
| Delete                  | `DELETE /api/profiles/{name}`, `profiles:write` |
| Chat                    | advertised profile query context                |

The channel checks schema, scope, method, and path before network I/O. Native
rename, persona update, and delete send the opaque Hermes revision as an
optimistic-concurrency precondition.

### Wing Link local profiles

When a paired gateway has a Wing Link control credential, Profiles also supports
local Hermes CLI profiles through the separate `8654` management listener:

| Operation | Wing Link behavior                                           |
| --------- | ------------------------------------------------------------ |
| List      | reads the validated local profile topology                   |
| Create    | `hermes profile create <id> --no-alias`                      |
| Clone     | adds `--clone-from <source>` to the fixed argument array     |
| Rename    | `hermes profile rename <old> <new>`                          |
| Delete    | `hermes profile delete --yes <id>`, after typed confirmation |

Local names are stable IDs matching `[a-z0-9][a-z0-9_-]{0,63}`. Reserved
profiles, including `default`, cannot be renamed or deleted. Mutations are
serialized and require the current topology revision; stale revisions return a
conflict and must be refreshed before retrying. Wing Link rejects symlinked or
otherwise unsafe profile roots before invoking Hermes CLI.

Persona/SOUL editing is not part of the Wing Link topology API. A local-only
profile's Chat action remains disabled until Hermes advertises a usable API
profile context. Wing does not invent context, change sticky CLI state, or
route chat through Wing Link.

### Wing Link custom providers

When paired Hermes omits provider administration, the Providers screen uses
Wing Link for custom OpenAI-compatible provider definitions. List, create,
update, and delete are explicitly scoped to the selected profile and map to
fixed `hermes --profile <id> config get/set/unset` argument arrays. IDs, HTTP(S)
origins, model names, and opaque revisions are validated before execution.
Arbitrary config keys and CLI passthrough are not exposed. Credentials and
OAuth accounts remain outside this adapter because secrets must never enter
process arguments.

## Pairing and credential boundary

Run Wing Link on the Hermes host, then pair direct Hermes and the separate
control origin:

```bash
WING_HERMES_URL=http://<trusted-vpn-ip>:8642 \
WING_LINK_URL=http://<trusted-vpn-ip>:8654 wing-link pair
```

`wing-link pair` installs, starts, and verifies the per-user service before it
shows the QR; the service survives the pairing terminal. The QR contains a short-lived code, the direct Hermes origin, the one-time
broker origin, and the non-secret Wing Link origin. It contains no bearer
credential. After operator review, the compatibility broker returns the
existing Hermes API key once and stages a separate random Wing Link token. Wing
must call `POST /v1/auth/credentials/{id}/ack` with that pending token before it
becomes valid for `/v1/profiles`. The app stores the two tokens under separate
secure-storage keys; shared preferences contain only normalized non-secret
origins and labels.

All authenticated Wing Link operations use the control token. The Hermes API
key is never accepted by the Wing Link management listener. Unknown Hermes
paths return `404`; there is no proxy fallback.

## Hard limitations

### Hermes remains the runtime authority

This repository does not patch, deploy, or restart Hermes Agent. Native API
profile rows and runtime context remain Hermes-owned. Wing Link provides only
validated local topology operations around the installed Hermes CLI.

### One full Hermes channel is active at a time

Switching gateways disconnects the previous full channel before connecting the
selected gateway. Inactive gateways retain lightweight cached summaries, not
independent streaming channels.

### No offline administrative replay

Profile mutations require a live authorized endpoint. Failed or interrupted
mutations are not queued or replayed later, per
[ADR 0030](../adr/0030-no-offline-mutation-replay.md).

### Cached fallback contacts are not profile capability proof

A gateway without advertised Hermes profile discovery uses a fallback Default
profile for unscoped chat. Wing Link supplements every local profile as a
management-only row, but those rows do not gain profile-scoped chat until Hermes
advertises usable profile context.

## Troubleshooting

When **Profiles unavailable** appears:

1. Confirm the intended gateway is selected and direct Hermes is online.
2. For native profiles, inspect authenticated capabilities without recording a
   token and verify exact profile routes/scopes/query context.
3. For local profiles, verify `wing-link serve` is running at the saved control
   origin and re-pair if the independent control credential is missing or
   revoked.
4. Confirm the Wing Link host matches the Hermes host and the listener is bound
   only to loopback, a private LAN, or Tailscale.
5. Refresh after a revision conflict before retrying.

Do not work around missing capability by placing secrets in URLs, parsing
Hermes files in Flutter, exposing a dashboard port, or adding client-local
shadow profiles.

## Evidence

- `test/features/agents/agents_screen_test.dart`
- `test/features/enrollment/hermes_enrollment_flow_test.dart`
- `test/core/hermes/setup/secure_hermes_endpoint_store_test.dart`
- `test/core/wing_link/wing_link_client_test.dart`
- `wing_link/pair_test.go`
- `wing_link/serve_test.go`
- `scripts/maestro/gateway_profiles_qa.yaml`
