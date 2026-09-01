# Hermes Wing Nostr Gateway and Channel Roadmap Implementation Plan

> **Decision status (2026-08-10): EXPLORATORY / DEFERRED.** Preserve this document as research, but do not implement the custom Nostr Relay Link as Wing's foundational gateway or control transport. Core Wing-to-gateway control remains the Hermes API over HTTPS using established secure reachability such as LAN, Tailscale, VPN, or a reviewed reverse proxy. Continue channel-centric UX as a transport-neutral product track; consider Buzz/Nostr later only as an optional Hermes messaging integration.

> **For future reconsideration only:** If the decision is explicitly reopened, use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Let Hermes Wing communicate with remote Hermes gateways through outbound, relay-mediated, authenticated and encrypted application connections—without requiring an inbound LAN, VPN, or Tailscale route for features that have a qualified native relay transport—while making channels the primary conversation surface and keeping Wing Link responsible for bootstrap, key lifecycle, bounded pairing/connectivity supervision, and revocation rather than Hermes-owned domain state.

**Architecture:** Wing, Wing Link, Hermes Agent, and any Nostr/Buzz relay remain distinct security principals. Wing Link manages the host transport identity, device enrollment, relay policy, service lifecycle, rotation, revocation, and bounded health reporting; it may process only closed, supervisor-owned pairing/health events and never ordinary chat or Hermes domain traffic. Hermes Agent remains authoritative for profiles, sessions, messages, tools, approvals, providers, schedules, and channel-to-profile routing. The first product slice proves encrypted one-to-one transport and private direct conversations. Shared NIP-29 channels follow only after their relay-visible plaintext semantics are either explicitly accepted or replaced by a reviewed group-encryption design. Relay-mediated administration is enabled only after Hermes advertises a typed, scoped native relay-control contract.

**Tech Stack:** Flutter/Dart and Riverpod in Wing; Go in Wing Link; Nostr NIP-01/NIP-42/NIP-44 concepts; NIP-46 remote-signer separation as an identity model; NIP-AB-inspired ephemeral QR pairing and SAS confirmation; Hermes Agent capability/readiness contracts; deterministic fake-relay fixtures; Flutter widget/unit/integration tests; Go unit/race/integration tests; Android physical-device qualification.

---

## 1. Decision summary

### 1.1 What the user is right about

A relay-mediated application protocol can remove the need for the phone to open a direct network route to a Hermes host. Both endpoints maintain outbound WebSocket connections to one or more reachable relays. This can replace Tailscale/VPN **reachability for the application features that have a relay transport**.

The preferred user experience is channel-centric:

- A user opens a channel or direct conversation.
- One or more Hermes profiles participate as agents in that channel.
- Threads and channel context determine the Hermes session scope.
- Continuous voice belongs to the active channel/thread, not to a globally selected profile.
- Profiles remain visible as participants, personas, and policy authorities; they do not remain the primary navigation unit.

Wing Link should remain in this repository under `wing_link/`. A separate repository is not justified now because the Flutter client, pairing contract, installer, security invariants, test fixtures, and release qualification must evolve atomically. Reconsider extraction only after Wing Link has an independent release cadence, more than one consumer, a stable versioned protocol, and separate ownership/security review.

### 1.2 Critical correction

Nostr is not a VPN and is not automatically a secure private channel.

Nostr provides signed events, public-key identities, relay-based store-and-forward delivery, and interoperable subscriptions. Security still requires explicit design for:

- private-key custody;
- relay authentication and authorization;
- end-to-end payload encryption;
- replay, duplication, delay, expiry, and reordering;
- device enrollment and revocation;
- scoped Hermes authorization;
- relay metadata leakage and retention;
- operation acceptance versus completion receipts;
- key rotation and recovery;
- offline delivery limits;
- denial of service and relay censorship.

Product copy must say **Encrypted relay connection** and disclose metadata limitations. Do not claim Signal-like forward secrecy, metadata privacy, or a general secure tunnel merely because NIP-44 is used.

### 1.3 Wing Link is a key supervisor, not one “boss key”

There must not be one universal private key. Use separate principals:

1. **Wing device controller key** — generated on the phone; private key remains in platform secure storage and is deleted on logout/revocation.
2. **Wing Link host transport key** — generated on the Hermes host; private key remains on that host and is never transferred to Wing.
3. **Hermes profile messaging key(s)** — owned by Hermes Agent and scoped per profile/platform integration.
4. **Relay operator key** — exists only for an owned relay deployment and must not equal a host, phone, or profile identity.
5. **Hermes API credential** — scoped, revocable runtime credential; never replaced by proof of Nostr key possession.

Wing Link orchestrates generation, enrollment, health, rotation, and revocation for supervisor-owned host/device transport identities. Hermes owns profile messaging identities. A valid event signature proves key possession, not permission to administer Hermes.

## 2. Frozen study baseline

- Target repository: `/home/xel/git/gormes/hermes-wing`
- Target branch: `main`
- Target commit at study time: `ab7a4f8ce53e927da785883c37931e18bf5f0eb4`
- Reference repository: `https://github.com/block/buzz`
- Frozen Buzz commit: `07a3c768d619db31fee3f0590f9433cdd1213e8f`
- Study date: 2026-08-10 UTC
- Hermes Agent audit baseline: `b50e27e6d7cd1885a37b4c468dabfab56185c329`
- Nostr NIPs audit baseline: `656cecc7c0a815b6a2b218d3b5d6f078b3f4dbab`
- Buzz desktop package version: `0.5.8`
- Buzz mobile package version: `0.0.0+1`
- Reference was inspected read-only through GitHub/raw sources and a temporary clone. This was static route/wiring analysis; Buzz was not run against a relay.

Relevant Buzz outcomes observed at the frozen baseline:

- Mobile navigation is organized around Home/channels, Activity, and Search.
- An authenticated app eagerly starts a relay session and lifecycle observer.
- The relay session handles reconnects, replay windows, event batching, duplicate suppression, visible-channel prioritization, pending event acknowledgements, and background pause/resume.
- Buzz supports NIP-29 channel/group semantics, threads, reactions, membership, typing, presence, search, and NIP-17 gift-wrapped DMs.
- Normal Buzz NIP-29 channel messages are signed plaintext. Private-channel membership prevents unauthorized client reads but does not hide content from the relay, database, backups, or operator.
- NIP-42 authenticates relay WebSocket connections; relay and channel authorization are additional checks.
- NIP-AB pairing uses ephemeral keys, a QR-carried random secret, ECDH/HKDF, six-digit SAS confirmation, transcript binding, NIP-44 encryption, duplicate rejection, strict state transitions, and a 120-second timeout.
- NIP-AB itself distinguishes one-time private-key transfer from NIP-46 ongoing remote signing.
- Buzz mobile currently stores a community `nsec` in Flutter secure storage. Wing should **not** copy that outcome for the Hermes agent or Wing Link host identity; it should copy the pairing rigor while transferring only public identities and scoped grants.

## 3. Current Wing constraints

Current paths establish the authority and migration starting point:

- `lib/features/hermes_chat/screens/hermes_chat_screen.dart` is a gateway/session-first chat surface with continuous voice.
- `lib/features/hermes_chat/gateways/gateway_contact.dart` identifies a contact by `(gatewayId, profileId)`.
- `lib/features/hermes_chat/gateways/hermes_gateway_directory.dart` builds profile contacts from Hermes endpoint summaries.
- `lib/core/hermes/channel/hermes_channel.dart` is the native HTTP/SSE Hermes client abstraction; its name must not be reused for a user-facing channel model.
- `lib/core/hermes/setup/secure_hermes_endpoint_store.dart` stores endpoint and Wing Link credentials in platform secure storage.
- `lib/router/providers/app_router.dart` makes `/hermes` the initial route and currently exposes Profiles as a separate destination.
- `wing_link/pair.go` pairs direct Hermes and Wing Link bearer credentials over a reachable HTTP endpoint.
- `wing_link/serve.go` allows loopback, private LAN, and Tailscale addresses and currently assumes direct IP reachability.
- `wing_link/state.go` persists bounded supervisor state and tokens.
- `docs/adr/0012-hermes-agent-domain-authority.md` requires Hermes Agent to remain authoritative for profiles, providers, and runtime configuration.
- `docs/adr/0014-single-origin-hermes-control-plane.md`, `docs/adr/0043-hardened-hermes-one-device-authorization.md`, and `docs/adr/0044-wing-link-local-runtime-supervisor.md` further constrain transport, device authorization, and supervisor ownership.

This roadmap must not solve missing Hermes channel/control contracts by adding profile, channel, message, provider, or schedule backends to Wing Link.

## 4. Target topology

```text
┌─────────────────────┐                 ┌─────────────────────────┐
│ Hermes Wing phone   │                 │ Hermes host             │
│                     │                 │                         │
│ device controller   │                 │ Wing Link               │
│ key (phone only)    │                 │ - host transport key    │
│ channel UI + voice  │                 │ - pairing/revocation    │
│ outbound WSS        │                 │ - relay/lifecycle health│
└──────────┬──────────┘                 │ - no domain authority   │
           │                            │           │ local only   │
           │ outbound WSS               │           ▼              │
           │                    ┌────────┴──────────────────────┐   │
           │                    │ Hermes Agent                 │   │
           │                    │ - profiles/sessions/messages │   │
           │                    │ - approvals/tools/schedules  │   │
           │                    │ - channel/profile bindings   │   │
           │                    │ - native relay adapter       │   │
           │                    └──────────┬────────────────────┘   │
           │                               │ outbound WSS            │
           ▼                               ▼                         │
   ┌────────────────────────────────────────────┐                    │
   │ Reachable Nostr/Buzz relay                 │                    │
   │ store/forward + NIP-42 + membership policy│                    │
   │ cannot be trusted for payload plaintext   │                    │
   └────────────────────────────────────────────┘                    │
```

### 4.1 Supported deployment modes

1. **Bring-your-own Buzz/Nostr community:** Wing and Hermes join the same reachable relay/community.
2. **Hosted Hermes relay service:** simplest no-VPN path; both endpoints connect outbound.
3. **User-operated public relay:** user owns DNS/TLS/availability and relay operator keys.
4. **Direct LAN/VPN/Tailscale compatibility:** retained as a rollback path until relay transport is qualified.

A relay running only on the private Hermes host does not remove the reachability problem. Wing Link may install/manage a local relay only for local testing or when a separately reachable ingress exists; do not present that as the no-VPN solution.

### 4.2 Data paths

**Private direct-conversation path:** Wing and a Hermes-owned native adapter exchange addressed, authenticated, end-to-end encrypted application events. Wing Link does not read message content. This is the first confidential conversation target.

**Shared channel path:** Standard Buzz/NIP-29 channel events are relay-visible plaintext. They may be used only when that trust model is explicitly disclosed and accepted. Confidential shared channels require a reviewed group-encryption design (for example MLS or another independently reviewed protocol); NIP-44 pairwise encryption must not be improvised into an ad hoc group protocol.

**Gateway administration path:** Wing uses the direct Hermes API—and therefore LAN/VPN/Tailscale or another direct HTTPS route—until Hermes advertises a native, typed relay-control transport. A production implementation must not wrap arbitrary HTTP, shell commands, or config edits into generic Nostr events through Wing Link. Nostr messaging alone does not replace general gateway network access.

**Bootstrap path:** Wing Link installs/adopts Hermes, generates host transport identity, configures approved relay endpoints through official Hermes operations, enrolls/revokes Wing devices, and reports bounded health.

## 5. Protocol security requirements

Before choosing a custom event kind, publish and review a versioned protocol document. Do not overload NIP-46 kind `24133` with arbitrary Hermes methods; NIP-46 is for remote signing. Do not select an unregistered custom kind without checking current upstream assignments.

Every encrypted application request must bind at least:

- protocol and schema version;
- sender device/host identity;
- intended recipient identity;
- random 128-bit-or-stronger request/operation ID;
- request type from a closed allowlist;
- issuance time and short expiry;
- credential/grant epoch;
- bounded payload and payload hash;
- required Hermes scopes;
- causal parent for progress/terminal receipts.

Every receiver must verify, in this order:

1. size and structural bounds before expensive work;
2. supported kind/version;
3. Nostr event ID and signature;
4. recipient tag and expected relay/community scope;
5. sender enrollment and non-revoked grant epoch;
6. clock skew and expiry;
7. persistent replay/idempotency state;
8. declared method and Hermes scope;
9. decrypted payload schema;
10. runtime operation preconditions/revision.

Receipts are separate states:

- relay accepted event;
- peer authenticated and accepted request;
- Hermes operation started;
- Hermes operation completed/failed;
- outcome unknown/ambiguous after timeout.

A relay `OK` frame is not a Hermes completion receipt.

## 6. Feature disposition from Buzz

| Buzz outcome                       | Wing disposition                   | Reason                                                                                                                             |
| ---------------------------------- | ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Channel-first Home                 | Adapt early                        | Matches requested conversation model.                                                                                              |
| Activity/inbox                     | Defer until channel event contract | Requires authoritative unread/activity semantics.                                                                                  |
| Search                             | Contract-gated                     | Must not download all private history for local search.                                                                            |
| NIP-29 channels/threads            | Adapt through Hermes/Buzz contract | Good interoperable message context.                                                                                                |
| NIP-42 relay auth                  | Adapt                              | Authenticates relay session but does not replace app authorization.                                                                |
| Reconnect replay + dedupe          | Adapt early                        | Required for mobile lifecycle correctness.                                                                                         |
| Visible-channel replay priority    | Adapt                              | Improves foreground recovery.                                                                                                      |
| NIP-AB pairing UX/validation       | Adapt mechanics                    | Transfer public keys and grants, not host/profile `nsec`.                                                                          |
| Mobile storage of community `nsec` | Never copy for host/profile keys   | Expands signing authority and compromise surface.                                                                                  |
| NIP-46 client/signer separation    | Adapt identity model               | Phone has disposable/scoped client key; host keeps signing/authority keys.                                                         |
| Presence/typing                    | Defer                              | Ephemeral and battery-sensitive; not core control transport.                                                                       |
| Reactions/rich content             | Defer                              | Useful after reliable channels and threads.                                                                                        |
| Relay/member admin                 | Contract-gated                     | Requires a clearly identified relay owner/admin and auditable operations.                                                          |
| NIP-17 DMs                         | Adapt later                        | Appropriate for human/private conversations, not generic administration.                                                           |
| Desktop approval cards             | Adapt through Hermes approvals     | Buzz desktop can approve/deny; Buzz mobile currently projects approval events without decision controls.                           |
| Voice huddles                      | Defer                              | Buzz desktop huddles are implemented; Buzz mobile only renders lifecycle events. Wing continuous voice is not a multiparty huddle. |
| Community/relay switching          | Adapt presentation                 | Show relay/domain provenance and never switch silently; a community is not a VPN.                                                  |

## 7. Roadmap and implementation work packages

### Task 1: Ratify authority, threat model, and terminology

**Objective:** Prevent “Nostr management” from becoming an ambiguous second Hermes backend or an unsafe universal-key design.

**Files:**

- Create: `docs/adr/0045-nostr-relay-transport-and-channel-authority.md`
- Create: `docs/security/nostr-relay-link-threat-model.md`
- Modify: `docs/adr/0012-hermes-agent-domain-authority.md`
- Modify: `docs/README.md`
- Test: `test/tooling/documentation_contract_test.dart`

**RED first:** Add documentation-contract assertions requiring explicit statements that Hermes owns profiles/channels/sessions/messages, Wing Link owns bootstrap/key lifecycle/relay health, and no universal private key exists.

**Implementation:** Record topology, principals, trust zones, STRIDE-style threats, key hierarchy, metadata limits, direct-path rollback, and non-goals. Define “channel,” “profile,” “session,” “gateway,” “device,” “host transport identity,” and “relay operator.”

**Verification:**

```bash
/home/xel/flutter/bin/flutter test test/tooling/documentation_contract_test.dart

git diff --check
```

**Gate:** Security/authority review approves the boundary before protocol or UI code begins.

### Task 2: Specify the Relay Link v1 protocol before implementation

**Objective:** Define deterministic pairing, envelope, replay, receipt, rotation, and revocation semantics without inventing undocumented wire behavior in client code.

**Files:**

- Create: `docs/protocol/nostr-relay-link-v1.md`
- Create: `docs/protocol/fixtures/nostr_relay_link_v1_vectors.json`
- Test: `test/tooling/nostr_protocol_contract_test.dart`
- Test: `wing_link/nostr_protocol_vectors_test.go`

**RED first:** Add cross-language vector tests for canonical serialization, event IDs/signatures where library APIs permit, HKDF/SAS values, expiry boundaries, recipient binding, grant epochs, duplicate IDs, and receipt correlation.

**Implementation decisions required in the document:**

- allocate or register event kinds after checking current NIP assignments;
- use established Nostr and cryptographic libraries—do not copy Buzz crypto code or write primitives;
- NIP-42 for relay authentication;
- require WSS outside loopback and reject insecure downgrade;
- NIP-44 v2 only where its properties are accepted and clearly disclosed;
- NIP-AB-inspired ephemeral pairing, but custom payload contains public keys and scoped grant data only;
- sender/recipient key separation modeled after NIP-46;
- one primary relay in v1, with optional ordered fallback only after deterministic failover semantics exist;
- strict body/event limits and no secrets in tags;
- if NIP-98 is used, bind exact HTTPS URL, method, timestamp, and mandatory payload/body hash for every enrollment or mutation; reject bodyless authorization reuse;
- fail closed unless relay membership/allowlists and Hermes grants are explicitly configured; Buzz's permissive admission defaults are not acceptable production defaults;
- persistent accepted-request replay state on the host;
- explicit ambiguous completion behavior;
- no generic shell, arbitrary URL, arbitrary HTTP, or config mutation methods.

**Verification:** Dart and Go consume the same frozen vectors and reject mutated variants.

**Gate:** Independent cryptography/protocol review. If NIP-44’s lack of forward secrecy is unacceptable for the threat model, stop and select a reviewed ratcheting/MLS/Noise-based inner channel rather than creating an ad hoc ratchet.

### Task 3: Add Nostr capability and readiness models—read only

**Objective:** Let Wing render what Hermes and Wing Link actually support before offering setup or mutation controls.

**Required upstream Hermes contract:** A versioned capability/readiness projection for relay transports, messaging channels, profile bindings, enrollment, supported event kinds/versions, signature-verification readiness, confidentiality mode, and feature states.

**Files:**

- Create: `lib/core/hermes/models/hermes_relay_transport.dart`
- Create: `lib/core/hermes/models/hermes_messaging_channel.dart`
- Modify: `lib/core/hermes/models/hermes_capabilities.dart`
- Modify: `lib/core/hermes/models/hermes_health.dart`
- Test: `test/core/hermes/models/hermes_relay_transport_test.dart`
- Test: `test/core/hermes/models/hermes_messaging_channel_test.dart`
- Test: `test/core/hermes/models/hermes_capabilities_test.dart`

**RED first:** Parse valid, absent, unknown-version, oversized, malformed, and partially supported responses. Assert unknown versions fail closed and do not enable controls.

**Implementation:** Keep status dimensions separate: configured, WSS verified, relay authenticated, inbound event signatures verified, peer enrolled, transport connected, channel synchronized, confidentiality mode (`relay_plaintext`, `pairwise_encrypted`, or reviewed group E2EE), degraded fallback, and last bounded diagnostic code.

**Gate:** If Hermes does not advertise the exact contract, Wing shows “Not supported by this Hermes version.” It must not call Wing Link or parse logs/config as fallback.

### Task 4: Create Wing Link host identity and protected state schema

**Objective:** Give Wing Link a dedicated host transport identity without exporting it or conflating it with Hermes profile or relay operator keys.

**Files:**

- Create: `wing_link/nostr_identity.go`
- Create: `wing_link/nostr_identity_test.go`
- Modify: `wing_link/state.go`
- Modify: `wing_link/state_test.go`
- Modify: `wing_link/protocol.go`
- Test: `wing_link/protocol_test.go`

**RED first:** Test first-run generation, stable reload, owner-only state permissions, atomic writes, malformed state rejection, schema migration, distinct keys per role, and zero secret material in JSON status/operation events/log output.

**Implementation:** Prefer OS keyring/credential facilities where a reviewed Go integration is supportable. If file-backed on Linux, use a dedicated owner-only secret file with atomic replacement, symlink rejection, bounded decoding, and no backup/export endpoint. Public key and fingerprint may appear in status; private key never does.

**Verification:**

```bash
cd wing_link
gofmt -w *.go
go test -race ./...
go vet ./...
```

**Gate:** Secret-scanning test proves no private key appears in stdout, stderr, argv, operation events, state snapshots returned over HTTP, or diagnostics.

### Task 5: Build relay-mediated device enrollment without key transfer

**Objective:** Pair a Wing device to Wing Link across a reachable relay using ephemeral keys, SAS confirmation, and a scoped grant while each side retains its own private key.

**Files:**

- Create: `wing_link/nostr_pairing.go`
- Create: `wing_link/nostr_pairing_test.go`
- Modify: `wing_link/pair.go`
- Modify: `wing_link/pair_test.go`
- Create: `lib/core/hermes/setup/nostr_pairing_models.dart`
- Create: `lib/core/hermes/setup/nostr_pairing_controller.dart`
- Test: `test/core/hermes/setup/nostr_pairing_controller_test.dart`
- Modify: `lib/features/enrollment/screens/hermes_enrollment_screen.dart`
- Test: `test/features/enrollment/hermes_enrollment_screen_test.dart`

**RED first:** Cover unknown versions, QR length, invalid keys/relay URLs, non-`wss` production relays, source mismatch, wrong recipient, invalid signature, duplicate offer/payload, out-of-order events, expired session, SAS denial, transcript mismatch, one-time secret reuse, abort cleanup, ambiguous completion, and app/process death.

**Implementation:** Reuse the NIP-AB state-machine lessons but send only:

- Wing device public key/fingerprint;
- Wing Link host public key/fingerprint;
- requested and granted scopes;
- device label as untrusted display metadata;
- relay list/policy;
- grant ID, epoch, issue time, and expiry/revocation metadata.

Never transfer Wing Link, Hermes profile, or relay operator private keys. Require confirmation on both devices. Pairing QR expires within 120 seconds and is single-use.

**Gate:** A malicious relay fixture cannot alter identities, silently complete pairing, replay an accepted pairing, or cause a secret to be logged.

### Task 6: Implement Wing Link relay lifecycle management

**Objective:** Make Wing Link operationally responsible for outbound pairing/health connectivity and bounded diagnostics without becoming the message/control domain backend or a general Nostr event processor.

**Files:**

- Create: `wing_link/nostr_relay_config.go`
- Create: `wing_link/nostr_pairing_relay_client.go`
- Create: `wing_link/nostr_relay_supervisor.go`
- Create: `wing_link/nostr_relay_test.go`
- Modify: `wing_link/serve.go`
- Modify: `wing_link/serve_test.go`
- Modify: `wing_link/service_linux.go`
- Modify: `wing_link/service_linux_test.go`

**RED first:** Test outbound-only pairing/health startup, NIP-42 challenge handling, WSS requirement, certificate failure, bounded reconnect backoff with jitter control, pause/shutdown, relay `NOTICE/CLOSED/OK`, rate limiting, config revision conflict, relay allowlist, malformed frame limits, rejection of every non-pairing/non-health event kind, and redacted health.

**Implementation:** Expose only typed management operations such as:

- read relay readiness;
- set an allowlisted `wss://` relay origin with revision;
- start/stop/reconnect supervisor-owned relay transport;
- list paired device public fingerprints and grant states;
- revoke a device;
- rotate host transport identity through a reviewed ceremony.

Do not expose arbitrary relay messages, SQL, shell, URLs, event kinds, or private keys.

Do not subscribe to, decrypt, route, cache, or proxy channel messages, approvals, profile events, tools, providers, schedules, or arbitrary Hermes requests. Those flows belong to a Hermes-owned adapter. Wing Link's relay client is a closed bootstrap/health exception only.

**Gate:** Wing Link can remain bound to loopback while its relay client connects outbound. No inbound public listener is required.

### Task 7: Build a deterministic hostile-relay fixture

**Objective:** Qualify behavior under the delivery semantics Nostr relays actually permit.

**Files:**

- Create: `wing_link/testdata/nostr_relay_fixture/fixture.go`
- Create: `wing_link/nostr_relay_integration_test.go`
- Create: `scripts/test_nostr_relay_link.sh`
- Test: `test/tooling/package_scripts_contract_test.dart`

**Fixture modes:**

- normal delivery;
- duplicate delivery;
- reverse order;
- delayed beyond expiry;
- dropped acceptance receipt;
- dropped terminal receipt;
- stale replay after restart;
- forged author/signature;
- wrong recipient tag;
- payload/tag mutation;
- oversized event;
- disconnect/reconnect storm;
- rate limit;
- relay refusal/censorship;
- retained event after revocation.

**Verification:**

```bash
bash scripts/test_nostr_relay_link.sh
cd wing_link && go test -race ./...
```

**Gate:** Every mutating operation is at-most-once at the Hermes boundary even when relay delivery is at-least-once. Ambiguous outcomes are displayed as ambiguous, not failed or successful.

### Task 8: Add enrollment and Nostr management UI

**Objective:** Give users a clear “Wing Link manages the connection” experience without exposing raw keys or implying that Wing Link is the relay server.

**Files:**

- Create: `lib/features/gateway/screens/nostr_link_screen.dart`
- Create: `lib/features/gateway/widgets/nostr_link_status.dart`
- Create: `lib/features/gateway/providers/nostr_link_provider.dart`
- Modify: `lib/features/gateway/screens/gateway_screen.dart`
- Modify: `lib/router/providers/app_router.dart`
- Modify: `lib/router/routes/app_routes.dart`
- Test: `test/features/gateway/nostr_link_screen_test.dart`
- Test: `test/router/gateway_route_test.dart`

**RED first:** Assert states for unsupported, not configured, pairing, SAS confirmation, connected, reconnecting, degraded, revoked, expired, rotation required, and ambiguous operation. Verify 200% text scale, narrow width, screen reader labels, back behavior, and no secret copy/display action.

**UI fields:**

- transport: Direct or Nostr relay;
- relay host and trust mode;
- Wing device fingerprint;
- Wing Link host fingerprint;
- Hermes messaging identities as separate rows;
- configured/authenticated/connected/synchronized readiness;
- last successful contact;
- paired devices and revoke actions;
- metadata privacy warning;
- direct-path fallback state.

**Gate:** Screenshots and diagnostics contain no `nsec`, ephemeral session secret, API bearer token, encrypted plaintext, full private channel identifier, or unbounded relay notice.

### Task 9: Introduce a channel directory without deleting profiles

**Objective:** Make channels the user-facing conversation destination while preserving profiles as participants and policy contexts.

**Files:**

- Create: `lib/features/hermes_chat/channels/hermes_conversation_ref.dart`
- Create: `lib/features/hermes_chat/channels/hermes_channel_directory.dart`
- Create: `lib/features/hermes_chat/channels/hermes_channel_cache.dart`
- Create: `lib/features/hermes_chat/channels/hermes_channel_list.dart`
- Test: `test/features/hermes_chat/channels/hermes_channel_directory_test.dart`
- Test: `test/features/hermes_chat/channels/hermes_channel_list_test.dart`
- Modify: `lib/features/hermes_chat/gateways/gateway_contact.dart`
- Modify: `lib/features/hermes_chat/gateways/hermes_gateway_directory.dart`
- Modify: `lib/features/hermes_chat/screens/hermes_chat_screen.dart`
- Test: `test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart`

**Model:**

```text
ConversationRef
  gatewayId
  platformId/communityId
  channelId
  optional threadId
  participant profile IDs
  optional default profile ID
  unread/read revision
  availability/synchronization state
```

Do not name this model `HermesChannel`; that name already refers to the native gateway client abstraction.

**RED first:** Test channel sorting, membership visibility, private-channel filtering, stale cache marked offline, duplicate profile participants, deleted/left channels, DM presentation, profile mentions, thread/session isolation, unknown channel versions, and migration from legacy `(gatewayId, profileId)` contacts.

**Implementation:** Profiles remain available under Profiles and in channel participant/mention controls. Existing one-profile chat is represented as a generated direct conversation during migration.

On wide layouts, threads may use a side panel; on phones, use a full-screen thread route. Preserve the outcome from Buzz without copying its desktop mechanics directly.

**Gate:** No channel list is synthesized from local profile files. If Hermes lacks an authoritative channel contract, Wing retains the current profile/session UI and labels Channels unavailable.

### Task 10: Change the primary mobile information architecture

**Objective:** Make channel conversations primary without cloning Buzz presentation mechanically.

**Files:**

- Modify: `lib/router/providers/app_router.dart`
- Modify: `lib/router/routes/app_routes.dart`
- Modify: `lib/shared/widgets/app_shell.dart`
- Modify: `lib/features/hermes_chat/screens/hermes_chat_screen.dart`
- Test: `test/shared/widgets/app_shell_test.dart`
- Create: `test/router/channel_route_test.dart`

**Proposed mobile destinations:**

- **Channels** — channel/DM list and active conversation;
- **Activity** — contract-gated approvals, mentions, scheduled results, and failures;
- **More** — Office, Profiles, Providers, Tools, Schedules, Gateway, Settings.

Search is added only after authoritative server-side search exists. Do not copy Buzz’s Home/Activity/Search tabs merely for visual parity.

**RED first:** Test deep links, Android Back, current-route reselection, channel-to-thread navigation, deleted channels, disconnected state, profile management reachability, large text, landscape, and keyboard/inset behavior.

**Gate:** Existing Profiles, Gateway, and Settings remain reachable. Navigation does not create duplicate history or exit Wing unexpectedly.

### Task 11: Define Hermes channel-to-profile session semantics upstream

**Objective:** Prevent channel UI from creating ambiguous profile/session authority.

**Required upstream Hermes behavior:**

- list channels visible to the authenticated Wing device;
- list profile participants/bindings per channel;
- establish deterministic session key from `(platform, community, channel, thread, profile, requester)`;
- enforce mention/default-profile policy;
- bind approvals to requester/channel/thread;
- expose message/event IDs and canonical final state;
- report unread/read revisions and synchronization cursors;
- support bounded history/search if advertised;
- emit revocation and membership changes;
- preserve profile-specific skills, memory, provider, and policy.

**Wing files after contract lands:**

- Modify: `lib/core/hermes/channel/hermes_channel.dart`
- Modify: `lib/core/hermes/channel/hermes_api_channel.dart`
- Modify: `lib/core/hermes/channel/hermes_channel_state.dart`
- Modify: `lib/core/hermes/models/hermes_session.dart`
- Test: `test/core/hermes/channel/hermes_api_channel_test.dart`
- Test: `test/core/hermes/channel/hermes_channel_state_test.dart`

**RED first:** Wrong profile/thread/requester, stale membership, unauthorized channel, revoked device, duplicate message event, dropped stream span, unrelated canonical final, and approval from the wrong requester must all fail closed.

**Gate:** Wing Link must not implement these semantics while waiting for Hermes.

### Task 12: Add continuous voice to the active channel context

**Objective:** Preserve Jarvis-like continuous conversation while making its target unambiguous.

**Files:**

- Modify: `lib/features/hermes_chat/controllers/hermes_voice_input_controller.dart`
- Modify: `lib/features/hermes_chat/screens/hermes_chat_screen.dart`
- Modify: `lib/features/hermes_chat/screens/state/hermes_chat_message_flow.dart`
- Modify: `lib/features/hermes_chat/screens/state/hermes_chat_lifecycle.dart`
- Test: `test/features/hermes_chat/controllers/hermes_voice_input_controller_test.dart`
- Test: `test/features/hermes_chat/controllers/hermes_continuous_voice_reply_policy_test.dart`
- Test: `integration_test/hermes_continuous_voice_android_smoke_test.dart`

**RED first:** Switch channel while listening, switch profile mention mid-draft, background/resume, relay reconnect, duplicate final, delayed response from prior channel, barge-in, TTS echo suppression, revoked channel membership, and active-thread deletion.

**Implementation:** Voice captures locally and sends text into the active channel/thread context. Do not send raw microphone audio through the Nostr relay in v1. Local TTS speaks only replies causally owned by the active channel/run. Generation guards discard stale callbacks.

**Qualification boundary:** Deterministic tests do not prove microphone routing, audible TTS, AEC, double-talk behavior, or acoustic barge-in. Preserve separate physical-device and human acoustic receipts.

### Task 13: Add relay-mediated Hermes control only through a native Hermes contract

**Objective:** Replace direct network reachability for bounded administration without making Wing Link a generic domain proxy.

**Required upstream design:** Hermes Agent owns a native relay-control adapter that accepts a closed set of typed, scoped, revisioned requests and emits correlated progress/terminal receipts. It applies the same authorization and profile boundaries as the direct API. The adapter must independently verify every inbound NIP-01 event ID and signature before trusting author, content, tags, or membership; relay delivery and NIP-42 authentication are not substitutes.

**Allowed first tracer:** Read-only capability/health request. Then one low-risk, idempotent action such as stopping an already-owned run. Do not start with provider secrets, profile deletion, arbitrary tools, or configuration.

**Wing files after upstream support:**

- Create: `lib/core/hermes/channel/hermes_relay_channel.dart`
- Create: `lib/core/hermes/channel/hermes_transport_selector.dart`
- Test: `test/core/hermes/channel/hermes_relay_channel_test.dart`
- Test: `test/core/hermes/channel/hermes_transport_selector_test.dart`
- Modify: `lib/features/hermes_chat/providers/hermes_channel_provider.dart`

**RED first:** Direct/relay capability mismatch, revoked grant, expired request, duplicate operation, relay acceptance without Hermes receipt, terminal receipt loss, profile mismatch, ungranted scope, downgrade attempt, unknown method, and transport switch during a run.

**Gate:** No generic “HTTP over Nostr,” shell command, arbitrary path, arbitrary URL, free-form method, or Wing Link profile/provider fallback. Unsupported mutations stay unavailable.

### Task 14: Rotation, revocation, recovery, and relay migration

**Objective:** Make compromised-device and relay-failure recovery operational rather than theoretical.

**Files:**

- Create: `wing_link/nostr_grants.go`
- Create: `wing_link/nostr_grants_test.go`
- Modify: `wing_link/state.go`
- Modify: `lib/features/gateway/screens/nostr_link_screen.dart`
- Test: `test/features/gateway/nostr_link_screen_test.dart`
- Create: `docs/runbooks/nostr-device-revocation.md`
- Create: `docs/runbooks/nostr-host-key-rotation.md`
- Create: `docs/runbooks/nostr-relay-migration.md`

**RED first:** Revoked device replay, old grant epoch, host rotation interrupted before/after commit, lost phone, lost host key, relay switch with queued messages, dual-relay duplicate, clock skew, and rollback to direct transport.

**Implementation:**

- immediate local revocation denylist/allowlist update;
- Hermes API credential revocation as a separate operation;
- incremented grant epoch invalidating old events;
- old/new host public-key cross-signing only during bounded rotation grace;
- re-pair if old host key is unavailable;
- relay migration through signed policy revision with explicit user confirmation;
- no private-key backup in diagnostics or QR code.

**Gate:** Recovery runbooks are exercised against fixtures before production enablement.

### Task 15: Migration and production qualification

**Objective:** Ship without silently breaking existing direct endpoint users or overstating evidence.

**Files:**

- Modify: `lib/core/hermes/setup/secure_hermes_endpoint_store.dart`
- Modify: `lib/features/hermes_chat/screens/state/hermes_chat_connection.dart`
- Test: `test/core/hermes/setup/secure_hermes_endpoint_store_test.dart`
- Test: `test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart`
- Create: `docs/runbooks/nostr-relay-link-qualification.md`
- Modify: `docs/runbooks/android/release-handoff.md`

**Migration stages:**

1. Compiled but disabled experimental transport.
2. Developer-only fake relay.
3. Read-only relay health/capabilities.
4. Opt-in channel messaging; direct API remains for administration.
5. Qualified relay control tracer.
6. Opt-in relay administration for explicitly supported operations.
7. Default channel conversation path only after soak and rollback evidence.
8. Consider removing VPN wording only after every required operation has a qualified relay path.

**Verification gates:**

```bash
/home/xel/flutter/bin/dart format --output=none --set-exit-if-changed lib test integration_test
/home/xel/flutter/bin/flutter analyze
/home/xel/flutter/bin/flutter test
cd wing_link && gofmt -w *.go && go test -race ./... && go vet ./...
git diff --check
```

Physical Android qualification must pin `RFCX81EJPNN`, rebuild/reinstall the exact APK, and verify artifact identity. Exercise:

- initial relay pairing and SAS denial/acceptance;
- airplane mode and reconnect;
- background/foreground and process death;
- relay outage/failover;
- duplicate/reordered/delayed events;
- device revocation while connected;
- host and relay rotation;
- rapid channel switching;
- landscape, 200% font scale, display scaling, keyboard/insets;
- continuous text conversation in a channel;
- battery/network behavior over a long-running session.

Human acoustic qualification remains separate for microphone capture, audible TTS, AEC, echo leakage, double-talk, and barge-in.

## 8. Evidence ladder

- **Planned only:** this document and threat model only.
- **Deterministically tested:** protocol vectors, parsers, state machines, hostile relay fixture.
- **Build/package tested:** Wing and Wing Link build/install/start.
- **Qualified:** current real relay plus physical-device receipts on intended platforms, including reconnect/revocation/rotation.
- **Battle-tested:** repeated representative use with durable operational and incident evidence.

Do not use a passing fake relay to claim real relay interoperability. Do not use deterministic voice fixtures to claim acoustic behavior.

## 9. Release blockers

The transport cannot become production-default until all are true:

- authority ADR and threat model approved;
- event kind/version allocation reviewed;
- crypto dependencies pinned and independently reviewed;
- WSS required outside loopback, with no silent transport downgrade;
- every inbound Hermes relay event has independently verified NIP-01 ID/signature before authorization or dispatch;
- no universal/master key or phone copy of host/profile `nsec`;
- persistent replay protection survives host restart;
- revocation invalidates queued retained events;
- ambiguous receipts remain ambiguous;
- relay metadata/privacy disclosure is visible;
- normal NIP-29 channel plaintext is never presented as confidential; shared-channel confidentiality has an approved group-encryption design or an explicit operator-trust disclosure;
- Hermes exposes authoritative channel and relay-control contracts;
- Wing Link does not proxy arbitrary Hermes domain traffic;
- secret redaction tests cover logs, argv, status, operations, diagnostics, screenshots, and receipts;
- physical lifecycle and reconnect qualification passes;
- rollback to direct transport is exercised;
- host key and device-loss runbooks are exercised.

## 10. Open decisions for the Nostr/Hermes teams

1. Which reachable relay is the default: hosted Hermes relay, user-owned relay, or Buzz community?
2. Is NIP-44’s no-forward-secrecy property acceptable for initial low-risk control requests, or is a reviewed ratcheting/MLS/Noise inner protocol mandatory?
3. Which custom event kinds are available and how will they be registered/versioned?
4. Does Hermes Agent implement the relay-control adapter directly, or does an official Hermes-owned plugin do so?
5. What is the canonical channel/session key and requester-binding contract?
6. Which operations are allowed over relays in v1? Recommendation: health/capabilities, messaging, run stop, and approval response only after scoped tests.
7. What relay retention/TTL guarantees can the client rely on, if any? Security must remain correct with hostile indefinite retention.
8. Is one relay enough for v1, or is ordered two-relay redundancy required? One relay is simpler and safer initially.
9. What secure storage guarantees are required per Android/iOS/Desktop platform?
10. How are push notifications delivered without leaking channel/profile metadata or creating a second delivery authority?
11. Will private channels use NIP-17/NIP-59 semantics, Buzz community controls, or a Hermes-specific encrypted envelope?
12. What exact production evidence allows direct VPN/Tailscale support to become optional rather than recommended?

## 11. Explicit non-goals for v1

- Running a general-purpose public Nostr relay inside Wing Link.
- Replacing Hermes profiles with Nostr keys.
- Exporting an agent, host, or relay operator `nsec` to the phone.
- Generic remote shell or arbitrary HTTP-over-Nostr.
- Direct mutation of Hermes config files by Wing Link.
- Raw microphone/audio streaming through Nostr.
- Full Buzz feature parity, reactions, rich content, presence, and search.
- Treating normal Buzz/NIP-29 channel plaintext as an end-to-end secure channel.
- Claiming metadata anonymity, forward secrecy, post-compromise security, or VPN-equivalent network access.
- Splitting Wing Link into a separate repository during this roadmap.

## 12. Recommended first executable vertical slice

After ADR/protocol review, implement only this tracer:

1. Wing Link generates a dedicated host transport identity.
2. Wing generates a dedicated device controller identity.
3. They pair over a deterministic fake relay using ephemeral pairing keys and SAS; no private identity is transferred.
4. Wing sends an encrypted, signed, expiring supervisor-health `ping` with a unique request ID over the closed pairing/health kind.
5. Wing Link validates kind, enrollment, recipient, signature, expiry, grant epoch, and replay state, rejecting all domain-event kinds.
6. Wing Link returns accepted and terminal `pong` receipts correlated to the request; it performs no Hermes operation.
7. Restart Wing Link and replay the same retained event; it must remain rejected.
8. Revoke the device and send a fresh event; it must be rejected.
9. Exercise the same flow over one real test relay.
10. Only then begin an upstream Hermes-owned private direct-conversation adapter; do not extend the Wing Link ping handler into channel inventory or Hermes operations.

This tracer proves the hard transport lifecycle without prematurely proxying profiles, chat, providers, schedules, or secrets.

## References

- Hermes Agent Buzz integration: <https://hermes-agent.nousresearch.com/docs/integrations/buzz>
- Block Buzz frozen baseline: <https://github.com/block/buzz/tree/07a3c768d619db31fee3f0590f9433cdd1213e8f>
- Buzz Nostr interoperability guide: <https://github.com/block/buzz/blob/07a3c768d619db31fee3f0590f9433cdd1213e8f/NOSTR.md>
- Buzz NIP-AB draft: <https://github.com/block/buzz/blob/07a3c768d619db31fee3f0590f9433cdd1213e8f/crates/buzz-core/src/pairing/NIP-AB.md>
- NIP-01: <https://github.com/nostr-protocol/nips/blob/master/01.md>
- NIP-42: <https://github.com/nostr-protocol/nips/blob/master/42.md>
- NIP-44: <https://github.com/nostr-protocol/nips/blob/master/44.md>
- NIP-46: <https://github.com/nostr-protocol/nips/blob/master/46.md>
- NIP-98: <https://github.com/nostr-protocol/nips/blob/master/98.md>
- Existing research: `docs/research/buzz-nostr-lessons.md`
- Existing authority ADR: `docs/adr/0012-hermes-agent-domain-authority.md`
