# Gateway profile management and limitations

## What this is

Hermes Wing can manage profiles and providers separately on each saved gateway,
but only when that gateway advertises the exact scoped Hermes Agent contracts.
The selected Hermes endpoint remains authoritative for every read and mutation.

Open **Settings → Gateways → gateway menu → Manage profiles**, or open
**Profiles** and choose a gateway. Provider and model controls live under
**Providers**.

A saved paired gateway may carry two independent connections:

- the Hermes origin and Hermes bearer credential for sessions, messages,
  profiles, providers, runs, approvals, and other Hermes domains;
- the Wing Link origin and control credential for bounded host-local bootstrap,
  pairing, service lifecycle, health, repair, and diagnostics.

Direct Hermes contracts are the preferred profile path and the only approved
provider path. When those profile contracts are absent, Wing Link may use only
the fixed Hermes CLI compatibility adapter in the
[runtime decision](../adr/runtime-and-delivery.md). Wing Link is not a Hermes
reverse proxy or a fallback domain API.

## Supported profile workflows

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

The client checks schema, scope, method, path, and explicit profile context
before network I/O. Rename, persona update, and delete send the opaque Hermes
domain revision as an optimistic-concurrency precondition. Missing or stale
contracts fail closed; Wing does not fall back to local files. The bounded Wing
Link profile adapter is available only through its typed compatibility surface.

A gateway without advertised profile discovery may expose one unscoped Default
contact for compatible chat. That fallback is presentation state, not evidence
that profile administration is available.

## Supported provider/model workflows

Provider and model administration also uses direct, advertised Hermes contracts:

| Operation                      | Required Hermes contract                                                   |
| ------------------------------ | -------------------------------------------------------------------------- |
| Provider inventory             | `GET /api/providers`, `providers:read`                                     |
| Set/remove/validate credential | dedicated `/api/providers/{slug}/credential` operations, `providers:write` |
| Model inventory                | `GET /api/models`, `models:read`                                           |
| Refresh models                 | `POST /api/models/refresh`, `models:write`                                 |
| Assign model                   | `PUT /api/models/assignment`, `models:write`, `If-Match`                   |

Provider credentials are write-only. Hermes reports bounded presence and masked
metadata but never returns a stored value. Wing does not pass credentials in
URLs, QR payloads, process arguments, logs, operation events, diagnostics, or
screenshots.

When only exact `GET /v1/models` is advertised, Wing may show bounded runtime
model inventory read-only. It must not infer provider mutation support from that
route.

## Compatibility migration note

The fixed Wing Link profile adapter is an approved compatibility surface for
supported Hermes releases that lack the required profile API. It delegates
list, create, rename, delete, and pairing credential discovery to bounded Hermes
CLI argument vectors and keeps no shadow profile state. The broader prototype
profile bridge and custom-provider adapter remain deprecated and quarantined;
the exception does not authorize provider, configuration, session, message,
tool, or schedule bridges.

The preserved historical design is explicitly marked superseded. New work must
follow the current [product boundary](../adr/product.md) and
[runtime boundary](../adr/runtime-and-delivery.md).

## Pairing and credential boundary

Run Wing Link on the Hermes host, then pair direct Hermes and the separate
supervisor origin:

```bash
WING_HERMES_URL=http://<trusted-vpn-ip>:8642 \
WING_LINK_URL=http://<trusted-vpn-ip>:8654 wing-link pair
```

`wing-link pair` installs, starts, and verifies the supported per-user service
before showing the QR. The QR contains a short-lived code, the direct Hermes
origin, the one-time broker origin, and the non-secret Wing Link origin. It
contains no bearer credential.

After operator review, pairing prefers a scoped Hermes enrollment and stages a
separate Wing Link control credential. The app stores the credentials under
separate secure-storage keys. Shared preferences contain only normalized
non-secret origins and labels. The Hermes credential is never accepted by the
Wing Link listener, and unknown paths return `404`; there is no proxy fallback.

The Wing Link credential authorizes supervisor operations only. It is not proof
of profile, provider, session, message, tool, schedule, approval, or messaging
platform authority.

## Hard limitations

### Hermes remains the domain authority

Hermes Agent owns profiles, providers, models, persona, sessions, messages,
tools, schedules, approvals, and messaging-platform semantics. Wing normally
uses advertised Hermes interfaces. Only Wing Link may parse the bounded Hermes
profile CLI output and credential environment files allowed by the runtime
decision; Flutter does not parse them.

### One full Hermes channel is active at a time

Switching gateways disconnects the previous full channel before connecting the
selected gateway. Inactive gateways retain lightweight cached summaries, not
independent streaming channels.

### No offline administrative replay

Profile/provider mutations require a live authorized endpoint. Failed or
interrupted mutations are not queued or replayed later, per the
[API and state decision](../adr/api-and-state.md).

### Unsupported is not empty

A missing route, missing scope, authentication failure, or incompatible profile
context appears as unavailable. Wing does not present it as an empty profile,
provider, or model list.

## Troubleshooting

When **Profiles unavailable** or **Providers unavailable** appears:

1. Confirm the intended gateway is selected and direct Hermes is online.
2. Reconnect so Wing refreshes authenticated capabilities and granted scopes.
3. Verify Hermes advertises the exact methods, routes, scopes, and mandatory
   profile query context without recording a token.
4. Refresh after a revision conflict before retrying.
5. Update or configure Hermes Agent if the required contract is absent.

Do not work around a missing contract by placing secrets in URLs, extending the
bounded Wing Link profile adapter, parsing Hermes files in Flutter, exposing a
dashboard port, or adding client-local shadow profiles/providers.

## Evidence

- `test/features/profiles/profiles_screen_test.dart`
- `test/features/providers/providers_screen_test.dart`
- `test/core/hermes/channel/hermes_api_channel_test.dart`
- `test/core/hermes/setup/secure_hermes_endpoint_store_test.dart`
- `test/tooling/hermes_domain_authority_contract_test.dart`
- `test/tooling/wing_link_docs_contract_test.dart`
