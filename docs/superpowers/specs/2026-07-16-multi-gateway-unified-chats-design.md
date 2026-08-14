# Multi-Gateway Unified Chats — Design

**Date:** 2026-07-16
**Status:** Implemented foundation; historical design

Current routing keeps the endpoint-scoped gateway identity plus Agent-local
profile name. Supported releases may populate profiles through Wing Link's fixed
compatibility adapter and verified `/p/<profile>` connections rather than the
proposed direct profile API.

## Goal

Hermes Wing presents a Telegram-style contact list spanning every saved Hermes Agent gateway. If one gateway exposes three agent profiles and another exposes two, the user sees five contacts in one activity-ordered list. Opening a contact selects that gateway and profile, opens its latest session, and gives only that chat a full streaming connection.

## Product decisions

| Decision | Choice |
|---|---|
| Contact identity | Stable `(gatewayId, agentProfileId)` pair. Equal profile names on different gateways remain distinct. |
| Gateways without profiles | Show one fallback contact for the gateway's default agent. |
| Contact ordering | Latest session activity across all gateways. |
| Session behavior | Open the latest session by default; expose older sessions from the chat header. |
| Inactive gateways | Refresh health, profiles, and session summaries without maintaining SSE streams. |
| Offline behavior | Keep cached contacts visible with offline state and last refresh time. |
| Active streaming | Exactly one full `HermesChannel`: the currently open contact. |
| Enrollment | QR enrollment appends or updates one gateway; it never replaces unrelated saved gateways. |

## Architecture

### Multi-gateway coordinator

A client-side coordinator loads all `HermesEndpointConfig` profiles from `HermesEndpointStore`. Each saved endpoint becomes a gateway keyed by its existing stable endpoint ID. The coordinator owns lightweight refresh state per gateway but never stores bearer credentials in contact projections, logs, diagnostics, or shared preferences.

Gateway refreshes are bounded to three concurrent requests. Each refresh obtains:

1. health and capabilities;
2. available Hermes profiles/agents;
3. session summaries and latest activity for each profile.

Refresh occurs on application launch, foreground resume, pull-to-refresh, and every 60 seconds while foregrounded. Inactive gateways do not hold SSE connections.

### Gateway runtime state

Each runtime contains:

- gateway ID, label, and public endpoint origin;
- online, refreshing, offline, or error status;
- last successful refresh time;
- capability snapshot;
- profile summaries;
- session summaries grouped by profile;
- cached non-secret contact projections.

A gateway failure updates only that runtime. It cannot clear healthy gateway data or fail the whole contact list.

### Unified contact projection

`GatewayContact` is a non-secret read model containing:

- gateway ID and gateway label;
- profile ID and profile display name;
- latest session ID, preview, and activity time;
- cached session count;
- gateway connection state and last refresh time.

Contacts are deduplicated by `(gatewayId, profileId)` and sorted by descending latest activity. Missing activity sorts after active contacts while preserving deterministic gateway/profile ordering. A gateway without profile capability produces one default-profile contact.

### Active chat ownership

Selecting a contact creates or reconfigures the single active `HermesChannel` with that gateway's secure credential and profile context. The channel opens the contact's latest session. A connection-generation token guards every asynchronous callback so late responses or stream events from the previous gateway cannot enter the newly selected chat.

Switching away from an active run, pending approval, or in-flight user submission requires confirmation. A safe switch closes the old stream before activating the new contact. Background server work remains authoritative and is reconciled when that contact is reopened.

## UI and interaction

The Hermes route starts with one Telegram-style contact list across all gateways. Each row shows:

- profile/agent name;
- gateway label;
- latest session preview and timestamp;
- online, refreshing, or offline state.

Tapping a row opens its latest session. The chat header shows both profile and gateway identity; tapping the header opens that contact's older Hermes sessions. Back returns to the unified list while lightweight refresh continues.

Settings remains the gateway-management surface: QR enrollment, rename, reconnect, remove, and health. Removing a gateway deletes only its local metadata, secure credential, and cached contacts.

## Data flow

1. Load saved gateway metadata; resolve each credential from secure storage only when constructing that gateway's request client.
2. Refresh gateway summaries with bounded concurrency.
3. Merge successful and cached gateway projections into one contact list.
4. Select a contact and activate its gateway/profile channel.
5. Open the latest session or create one only through an explicit user action.
6. Refresh the selected contact after run/session changes so list ordering reflects new activity.
7. On resume, revalidate every gateway lightly and reconcile the active contact fully.

## Error handling

- One unavailable gateway leaves its cached contacts visible and marked offline.
- Invalid or revoked credentials mark only that gateway as authentication-failed and offer reconnect.
- Unsupported profile APIs produce one default contact rather than hiding the gateway.
- Empty session history opens a new-chat state; it does not create a session until the user sends or explicitly creates one.
- Stale refresh responses are discarded by gateway refresh generation.
- Stale active-channel events are discarded by active connection generation.
- Removing the active gateway returns to the contact list after explicit confirmation.

## Security boundaries

- Credentials stay per gateway in platform secure storage.
- Contact IDs and cache keys always include gateway ID; profile or session IDs are never treated as globally unique.
- No credential is copied into coordinator state, contact previews, logs, diagnostics, or analytics.
- Gateway labels are displayed alongside ambiguous profile names to prevent cross-gateway action mistakes.
- Mutations use the selected gateway's advertised capabilities and scopes; permissions from one gateway never authorize another.

## Validation

### Coordinator and model tests

- merge contacts from gateways with three and two profiles into five stable contacts;
- deterministic identity and latest-activity ordering;
- same profile ID or name on different gateways remains distinct;
- fallback default contact when profile APIs are unavailable;
- partial gateway failure retains cached contacts and does not block healthy refresh;
- refresh concurrency is bounded;
- stale refresh generations are ignored.

### Active channel tests

- selecting a contact uses the correct gateway credential and profile context;
- only the active contact owns a streaming channel;
- switching closes the prior stream and rejects its late events;
- active run/approval switching requires confirmation;
- latest session opens by default and older sessions remain selectable;
- no session is created merely by viewing an empty contact.

### UI and security tests

- unified list renders five contacts from the two-gateway fixture;
- rows show gateway labels, status, previews, and timestamps;
- offline contacts remain visible;
- QR enrollment appends a gateway;
- deleting one gateway preserves all others;
- credentials never appear in contact models, rendered text, logs, or diagnostics.

## Out of scope

- A unified cross-gateway unread/read-receipt protocol; Hermes does not expose reliable client read state yet.
- Simultaneous SSE streams for inactive gateways.
- A server-side aggregation gateway.
- Cross-gateway session moves, shared profile IDs, or merged conversations.
- Restoring the planned `/gateway` messaging-platform administration surface; this design concerns multiple Hermes Agent endpoints.
