# Matrix messaging lessons for Hermes Wing and Wing Link

Status: research recommendation
Source reviewed: <https://hermes-agent.nousresearch.com/docs/user-guide/messaging/matrix>
Reviewed: 2026-08-10

## Executive conclusion

Hermes Agent's Matrix adapter is not adequately represented by a platform name and
one status string. Matrix has user-visible policy, session-topology, security,
media, encryption, approval, and diagnostic state. Hermes Agent must remain the
authority for all of it, but Wing can become a substantially better operator UI
once Hermes advertises a bounded messaging-platform contract.

Wing Link should not become a second Matrix configurator or parse Hermes files.
Its useful role is to install the required Hermes feature set, invoke explicit
Hermes setup/validation contracts, transport secrets through a write-only channel,
and verify that the configured adapter reaches the requested readiness state.

## What the Matrix guide establishes

### Behavior is platform policy

Matrix behavior includes:

- DMs respond without a mention; rooms require a mention by default.
- Rooms can be allowlisted or exempted from the mention requirement.
- Real Matrix threads have isolated context.
- Automatic threading is independently configurable for rooms and DMs.
- Shared-room sessions are isolated per user by default.
- Room, thread, and auto session scopes have materially different behavior.
- Named-session resume is room-bound unless cross-room resume is explicit.
- Known `!command` aliases compensate for clients that reserve `/commands`.
- Processing reactions, approvals, and model selection can be interactive.
- Thinking/tool progress is editable and threaded to avoid timeline flooding.

A generic `connected` badge cannot explain how a Matrix deployment will behave.

### Security has multiple independent gates

The guide defines independent controls for:

- allowed users;
- allowed rooms;
- free-response rooms;
- ignored bridge/appservice user patterns;
- notice-event processing;
- room-wide mentions;
- requester-bound approvals;
- admin-style Matrix tools;
- public room creation;
- inbound and outbound media size;
- accepted `mxc://` media sources;
- E2EE mode (`off`, `optional`, or `required`);
- recovery-key/cross-signing readiness.

Wing must not compress these into a single security toggle. Optional E2EE is also
not equivalent to required E2EE: optional mode may continue unencrypted, while
required mode fails closed.

### Readiness is richer than process health

A Matrix adapter can be running while still unusable because of:

- invalid homeserver or access token (`whoami` failure);
- missing `mautrix` encryption extras or `libolm`;
- an unverified or stale encryption device identity;
- undecryptable encrypted-room events;
- host clock skew causing every live event to be dropped as old;
- allowlists that exclude the current user or room;
- a missing mention in a mention-gated room;
- a bot account that has not joined the room.

These are actionable readiness states, not generic log messages.

### Delivery and session provenance matter

Matrix supports a configured home room for proactive cron/reminder delivery. A
conversation also has provenance that affects safety and continuity: room ID,
thread root, sender-isolation mode, and effective session scope. Wing should be
able to show that provenance without exposing message bodies or unbounded room
metadata.

## Current Hermes Wing gap

`HermesGatewayPlatformStatus` currently retains only:

```text
name
status
```

The Gateway screen renders those two strings in a read-only card. This is safe and
bounded, but it cannot distinguish:

- configured from authenticated and syncing;
- plaintext from optional or required E2EE;
- a healthy connection from a clock-skew drop loop;
- room-scoped from thread-scoped sessions;
- locked-down allowlists from an open deployment;
- enabled reactions/approvals from unavailable controls;
- a configured home delivery room from no proactive destination.

This limitation is correct until Hermes advertises a richer contract. Wing must
not infer the missing state by reading `.env`, `config.yaml`, logs, Matrix stores,
or CLI prose.

## Recommended Hermes Agent contract

Add a capability-gated, scoped, revisioned messaging-platform API before adding a
Matrix administration UI. The exact route belongs to Hermes Agent; Wing should not
invent a client-local authority. A useful bounded read model would include:

```text
platform ID and display label
configured / authenticated / connected / syncing state
last bounded transition time and redacted reason code
adapter capability flags (threads, reactions, approvals, model picker,
  progress panes, images, files, audio, video, diagnostics)
encryption mode and effective encryption readiness
session scope and per-user isolation mode
mention requirement and auto-thread policy
counts for allowed users, rooms, and free-response rooms (not the identifiers)
home destination configured: yes/no (not the room ID by default)
media byte limit
requester-bound approval policy
diagnostic checks with stable IDs and bounded remediation labels
revision token for mutation
```

Sensitive values must remain write-only and absent from reads, diagnostics,
errors, analytics, screenshots, and exported receipts.

A later mutation contract should use exact declared/granted scopes, revision
preconditions, typed fields, and explicit apply/restart semantics. It should
separate ordinary policy from secrets and destructive encryption recovery.

## Recommended Hermes Wing improvements

### 1. Messaging platform detail screen

Turn each Gateway platform row into a read-only detail route only when the richer
contract is advertised. For Matrix, show:

- connection and sync state;
- E2EE mode plus effective readiness;
- room/thread session policy;
- mention and auto-thread behavior;
- allowlist counts and whether both user and room restrictions are active;
- reaction/approval/model-picker support;
- media limit;
- home-room configured status;
- bounded, actionable diagnostic checks.

Do not show access tokens, recovery keys, room IDs, user IDs, device IDs, message
bodies, crypto-store paths, or raw logs.

### 2. Conversation provenance

When Hermes exposes it, show a compact source label for Matrix-backed sessions:
room versus DM, thread-bound versus room-bound, and isolated-per-user versus
shared. Require explicit confirmation for any cross-room resume operation. This
prevents a user from assuming that two room contexts share one transcript.

### 3. Approval and model-picker clarity

When a run originated in Matrix, show whether interactive reaction controls are
available and whether approval is requester-bound. Wing should continue to use
Hermes's authoritative approval contract; it must not emulate Matrix reactions or
broaden who can approve.

### 4. Actionable diagnostics

Map stable Hermes diagnostic IDs to specific guidance, for example:

- authentication/whoami failed;
- clock unsynchronized or old-event drop loop;
- encryption dependency unavailable;
- device verification required;
- stale encryption identity;
- room/user blocked by policy;
- mention required;
- bot not joined;
- media limit exceeded.

Keep raw exception text bounded and redacted. A generic `degraded` label is not
enough for these cases.

### 5. Safe setup wizard

Only after Hermes supplies write contracts, add a review-first wizard with
separate steps for:

1. homeserver origin and account identity;
2. write-only access token or password credential;
3. allowed users and rooms;
4. mention/thread/session behavior;
5. E2EE mode with a clear downgrade warning for `optional`;
6. optional write-only recovery key;
7. media and Matrix-tool policy;
8. validation and explicit apply/restart.

The UI should default to both user and room allowlists for a private deployment,
requester-bound approvals, disabled room-wide mentions, ignored notices, disabled
admin-style Matrix tools, and no public room creation.

## Recommended Wing Link improvements

### 1. Add an explicit messaging bootstrap phase

Core bootstrap currently installs/adopts Hermes, creates an optional profile and
provider, ensures API authentication, and starts the gateway. A future messaging
phase should be independent and opt-in so core setup remains usable without
Matrix.

Wing Link may:

- ensure the pinned Hermes build includes the requested Matrix/E2EE feature set;
- check host prerequisites such as `libolm` through a Hermes-owned readiness
  command or contract;
- invoke an official non-interactive Hermes messaging setup operation;
- restart/apply through Hermes lifecycle commands;
- verify bounded platform readiness after apply.

Wing Link must not implement Matrix protocol logic or own Matrix state.

### 2. Never accept secrets as ordinary CLI arguments

Matrix access tokens, passwords, recovery keys, and proxy keys must not appear in
process arguments, shell history, operation events, JSON responses, or logs. Use a
write-only authenticated request body, inherited secret file descriptor/stdin, or
another Hermes-supported secret input mechanism. Preserve Wing Link's existing
provider rule that credentials are not accepted as setup arguments.

### 3. Do not directly edit Hermes configuration

ADR 0012 keeps configuration authority in Hermes Agent. Wing Link should not
write Matrix variables into `.env`, parse `config.yaml`, inspect the crypto store,
or interpret free-form gateway logs. If Hermes lacks a setup/readiness contract,
that contract must be added upstream first.

The existing API-key bootstrap is a narrowly bounded bootstrap exception. It
should not become precedent for general platform configuration.

### 4. Treat encryption recovery as a separate dangerous workflow

Deleting a Matrix crypto store can permanently lose encryption identity and may
require a new access token/device. Wing Link must never offer a generic “reset
Matrix” action that deletes this state. Any future recovery operation needs:

- Hermes-owned diagnosis;
- explicit destructive consequences;
- typed confirmation;
- no automatic retry;
- a post-recovery verification receipt.

### 5. Preserve proxy-mode trust boundaries

The documented Matrix proxy deployment separates E2EE protocol handling from the
host agent. Wing should display the effective topology and HTTPS/private-network
warning if Hermes advertises it, but Wing Link must not silently expose the host
API on `0.0.0.0` or generate a proxy key without explicit review.

## Suggested implementation order

1. **Upstream contract:** add bounded messaging inventory/detail and stable
   diagnostic IDs to Hermes Agent.
2. **Wing read-only UI:** parse hostile payloads defensively and add Matrix detail
   plus remediation guidance behind exact capability/scope checks.
3. **Contract receipts:** prove configured/authenticated/syncing/E2EE states,
   redaction, unknown-field discard, bounds, and unsupported/failure separation.
4. **Upstream mutation API:** typed, revisioned policy writes plus write-only secret
   operations and explicit apply lifecycle.
5. **Wing setup UI:** review-first Matrix wizard with fail-closed defaults.
6. **Wing Link bootstrap:** optional prerequisite/install/apply/verify orchestration
   through Hermes commands/contracts only.
7. **Physical QA:** validate narrow phone layout, 200% text, secret-safe
   screenshots, Android Back, process restart, and stale/failed readiness states.

## High-value tests

- Unknown platforms and fields are discarded or bounded without crashing.
- Matrix status never renders tokens, recovery keys, device IDs, room IDs, message
  bodies, filesystem paths, or raw diagnostic payloads.
- `optional` E2EE is never presented as equivalent to `required` and healthy.
- Authentication success without sync readiness is not shown as connected/ready.
- Clock-skew drop-loop diagnostics produce an actionable but redacted warning.
- Allowlist counts render without revealing identifiers.
- Cross-room resume requires an explicit authoritative operation and confirmation.
- Requester-bound approval state is visible but cannot be weakened client-side.
- Unsupported contracts show `Unavailable`, not an empty Matrix inventory.
- A failed apply preserves the previous authoritative revision and reports whether
  restart occurred.
- Wing Link secret inputs never appear in argv, stdout/stderr, operation events,
  process listings, or JSON receipts.
