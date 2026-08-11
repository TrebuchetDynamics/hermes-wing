# Buzz and Nostr lessons for Hermes Wing

Status: archived research — core transport decision closed
Reviewed: 2026-08-10

## Executive conclusion

Buzz demonstrates a compelling model for an agent-native collaborative workspace: humans and agents have first-class identities, share channels, and leave signed event receipts. Hermes supports Buzz through three deliberately different topologies: a desktop-managed Hermes runtime, an ACP relay bridge, and a native Hermes gateway platform.[1]

Hermes Wing should learn from that topology and identity model, and should expose Buzz clearly when Hermes advertises it. Wing should **not** become a general Nostr client, move Hermes domain state onto relays, or replace the authenticated Hermes API with Nostr events.

### Final architecture decision

For the core Wing-to-gateway connection, Nostr is out of scope. Hermes API over HTTPS remains the control plane, reached through loopback, an isolated LAN, Tailscale/VPN, or a reviewed HTTPS reverse proxy. The custom Nostr Relay Link remains deferred and must not be implemented from this research archive.

The decision is based on protocol boundaries, not on whether Nostr is useful in
other contexts:

- Normal NIP-29 group events expose their event `content` to the relay; group membership and signatures do not encrypt it. Such channel content is not confidential from the relay operator.[2][7]
- Nostr signatures prove event authorship and integrity, not authorization to
  perform a Hermes operation, freshness, successful application, or relay
  honesty.[2]
- NIP-44 explicitly lacks forward secrecy and post-compromise security, and it
  does not define device grants, operation scopes, replay recovery, revocation,
  durable delivery, or authoritative completion receipts.[4]
- A relay may delay, reorder, replay, retain, censor, or drop events. Rebuilding
  deterministic administration over that substrate would create a second
  control protocol and expand Wing Link beyond its host-supervisor boundary.

Channel-first navigation, DMs, threads, reactions, explicit agent identities,
unread/activity projections, reconnect high-water marks, and safe mention or
allowlist defaults remain valuable **transport-neutral UX lessons**. They do not
require Nostr in Wing's core connection.

The best near-term path is:

1. support Buzz as a capability-rich Hermes messaging platform;
2. show the runtime/transport topology and signed agent identity safely;
3. expose delivery, mention, access, transport, and diagnostic policy through Hermes-owned contracts;
4. keep Nostr private keys on the Hermes host, not in Wing;
5. consider Nostr-signed portable receipts later, but only as an export or interoperability layer—not the control plane.

## What Buzz gets right

### 1. It distinguishes three integration topologies

The Buzz integration does not pretend that every connection is equivalent. Buzz Desktop can spawn Hermes locally, `buzz-acp` can bridge a relay channel to `hermes acp`, or Hermes can join Buzz as a native gateway platform.[1]

This is a valuable UX lesson for Wing Link. Setup should say:

- **where Hermes runs**;
- **who owns the transport**;
- **which identity speaks in the workspace**;
- **which Hermes features survive that topology**;
- **where permissions and approvals are enforced**.

A generic “Connected to Buzz” state hides too much. The native gateway topology retains Hermes memory, skills, approvals, cron, and sessions, while an ACP-hosted runtime has a different lifecycle and permission owner.[1]

### 2. Agents are identities, not webhook aliases

Buzz models every human or agent as a Nostr keypair. Messages are signed events, and the relay/community controls membership. Buzz describes humans, agents, workflows, reactions, approvals, and git events as one searchable event substrate.[5]

For Wing, this suggests showing an agent identity card with:

- display name;
- abbreviated public key/`npub`;
- relay/community origin;
- Hermes profile that owns the identity;
- connection transport;
- verification and membership state.

The private key must never be displayed, copied into diagnostics, included in screenshots, or stored in ordinary Flutter preferences.

### 3. Identity ownership is scoped and exclusive

Hermes recommends a dedicated Nostr keypair for the native Buzz gateway and locks the `(relay, pubkey)` pair so two Hermes profiles cannot accidentally drive the same identity.[1] The adapter implements that scoped lock before starting inbound delivery.[6]

This should become a general Wing setup principle: identity ownership must be explicit and conflicts must fail closed. Wing should display “identity already owned by another profile” rather than treating it as a transient connection error.

### 4. The event model supplies durable receipts

Nostr events include an author public key, timestamp, kind, tags, content, ID, and Schnorr signature. The event ID is a hash of canonical serialized event data.[2] That gives Buzz stable identifiers for replies, deduplication, audit references, and signed authorship.

Wing can borrow the receipt model even outside Nostr:

- stable operation/event ID;
- authoritative actor identity;
- source gateway/profile;
- creation and completion time;
- request revision or causal parent;
- accepted/rejected result;
- bounded redacted detail.

A receipt is useful even when it remains in Hermes rather than being published to a relay.

### 5. Safe shared-channel defaults matter

Hermes recommends private access by default, mention-gated shared channels, no intermediate assistant chatter, and no tool-progress spam. DMs dispatch without mentions; watched channels require the agent to be addressed.[1]

Wing should surface these as understandable policy, not raw environment variables:

- **Who can invoke this agent?** Private allowlist / all community members
- **When does it answer in channels?** Mentions only / every message
- **What appears publicly?** Final answers / progress / tool activity
- **Where do proactive messages go?** Home channel

The review screen should flag `allow all users` and `respond to every channel message` as broad exposure.

### 6. Transport fallback is useful only when visible

The current native adapter prefers an authenticated Nostr WebSocket and can fall back to CLI polling in automatic mode.[1][6] Forced WebSocket mode fails when authentication cannot be established, while automatic mode trades latency for availability.[6]

Wing should show the **effective** transport, not merely the requested mode:

- WebSocket authenticated
- Polling fallback active
- Forced WebSocket failed
- Reconnecting

It should also show the latency implication of polling and provide a stable remediation code for authentication or CLI failures.

### 7. Restart behavior must avoid replay

The adapter seeds channel high-water marks on connect so old history is not replayed into the agent; it also tracks bounded event IDs and suppresses self-authored echoes.[6]

That is directly relevant to Wing's mobile reconnect UX. A reconnect should never imply that every historical event will become a new agent turn. Hermes should expose whether catch-up was seeded, replayed, or intentionally skipped.

## Documentation and contract lesson

The detailed Buzz messaging page currently contains both a description of native WebSocket delivery and a stale limitation saying inbound is polling-only. The current integration overview and adapter source describe WebSocket-first delivery with polling fallback.[1][6]

This is evidence that Wing should not encode platform behavior from prose documentation. Hermes should advertise a revisioned capability/readiness contract, and documentation should ideally be generated or tested against the adapter declaration.

## Optional Nostr experiments, if the decision is reopened

The ideas below are preserved for optional Hermes messaging integration or
exported-receipt research. They are not current implementation recommendations.

### Portable signed identity

Nostr gives each participant a secp256k1 keypair and makes signed events the basic protocol object.[2] A dedicated agent key can provide a portable public identity across compatible relays and clients.

Useful Wing applications could include:

- displaying and verifying a Hermes/Buzz agent public identity;
- scanning an `npub` or relay invitation;
- verifying signed receipts exported by Hermes;
- linking a public agent identity to a Hermes profile;
- interoperating with Buzz or future Nostr-based workspaces through Hermes adapters.

### Event-oriented interoperability

Nostr's relay model uses WebSocket subscriptions with filters over IDs, authors, kinds, tags, and time ranges.[2] That can support loosely coupled notifications, workflow events, public status, or portable audit references without requiring every consumer to call the Hermes API.

However, custom event kinds need a published schema, versioning, size bounds, replay rules, authorization rules, and compatibility tests. “It is signed” does not make an event semantically safe or authorized.

### Signed HTTP authorization—limited use

NIP-98 defines short-lived signed HTTP authorization events bound to an exact URL and HTTP method, optionally including a hash of the request body.[3]

That could eventually authenticate a Nostr identity to a narrowly scoped Hermes enrollment or interoperability endpoint. It should not replace Wing's existing pairing and scoped-token model by default because:

- possession of the long-lived Nostr private key grants signing authority;
- URL canonicalization and time-window validation must be exact;
- replay protection and one-time enrollment semantics still need server state;
- Hermes scopes, revocation, device labels, and token rotation remain necessary;
- a Nostr identity is not automatically authorized to control a Hermes profile.

If explored, use NIP-98 only to prove identity during enrollment, then mint the existing short-lived/scoped Hermes credential.

## What Nostr should not replace

### Not the Hermes control plane

Hermes remains authoritative for profiles, providers, sessions, tools, schedules, approvals, memory, and gateway state. These domains need typed reads, revisioned mutations, explicit scopes, conflict handling, bounded errors, and streaming lifecycle state.

Publishing commands as relay events would add eventual consistency, replay, duplicate delivery, relay availability, event retention, and authorization ambiguity to operations that currently require deterministic results.

### Not a substitute for secure messaging

NIP-44 defines encrypted payloads, but its own specification lists no forward secrecy, no post-compromise security, visible timestamps, relay/IP metadata exposure, and limited size hiding. It recommends specialized E2EE messaging software for high-risk situations.[4]

Therefore Wing must not label generic Nostr encrypted messaging as equivalent to Signal-style modern secure messaging. Buzz membership and signed events provide provenance and access control, but public/signed transport is not confidentiality.

### Not a wallet-like key vault in Wing

An `nsec` is long-lived signing authority. Putting the same agent key on both the Hermes host and the phone expands the compromise surface and makes exclusive identity ownership difficult.

Recommended model:

- Hermes host generates or imports the agent key;
- Hermes stores it through profile-scoped secret handling;
- Wing receives only the public key and bounded readiness state;
- signing occurs on the Hermes host;
- key rotation is an explicit dangerous workflow;
- no raw key appears in Wing Link argv, operation events, logs, QR codes, clipboard, or diagnostics.

If phone-side signing is ever required for a **human** identity, use a separate mobile key, hardware-backed secure storage where available, biometric/user-presence policy, export/recovery design, and a formal threat model. Do not reuse the agent key.

## Recommended Hermes contract for Buzz

Add a capability-gated messaging platform detail contract with bounded fields:

```text
platform: buzz
integration_mode: native_gateway | acp_bridge | managed_runtime
configured / authenticated / connected state
relay origin and community label (sanitized)
agent display name and abbreviated public identity
effective inbound transport and fallback reason
watched channel count and DM discovery state
home delivery configured: yes/no
mention requirement
access mode and allowed-user count
interim-message and tool-progress policy
identity-lock owner/conflict state
last event/high-water readiness (no message content)
capabilities: text, threads, reactions, images, cron delivery
diagnostic checks with stable codes
```

Do not expose the private key, credential-file path, full channel IDs, message content, raw CLI output, or unrestricted relay notices.

## Recommended Wing UI

### Gateway → Buzz detail

Show:

- topology badge: **Native gateway**, **ACP bridge**, or **Desktop managed**;
- agent identity and relay/community;
- connection and effective transport;
- “Polling fallback” warning when applicable;
- access and mention policy;
- channel count and home-delivery status;
- capabilities;
- identity conflict or membership diagnostics.

### Setup review

When Hermes eventually provides mutation contracts, review:

1. integration topology;
2. relay origin;
3. dedicated agent identity creation/import;
4. community membership verification;
5. watched channels;
6. private allowlist versus community-wide access;
7. mention behavior;
8. public output/progress policy;
9. home delivery channel;
10. transport policy;
11. apply/restart and post-apply readiness.

Secrets must be write-only. Identity creation should default to a new dedicated key, not reuse a human key.

### Session provenance

Buzz-origin sessions should show community/channel/DM provenance, thread parent, agent public identity, and event receipt ID only when Hermes provides bounded fields. Cross-channel resume should require explicit confirmation.

## Recommended Wing Link role

Wing Link may:

- install/adopt the pinned Hermes build;
- start, stop, repair, and diagnose the Hermes service;
- pair Wing through separate scoped Hermes and supervisor credentials;
- report bounded Hermes-owned plugin/readiness status without parsing a Nostr
  key store or free-form logs.

Wing Link must not:

- implement Nostr event processing;
- directly edit general Buzz/Hermes configuration;
- parse free-form CLI output as product state;
- accept or transfer Nostr private keys;
- create keys without an explicit recovery/ownership review;
- put an `nsec` in argv or a QR pairing payload;
- silently switch integration topology;
- treat polling fallback as full WebSocket health.

## Optional future order, not the current roadmap

Do not begin these items unless the core-transport decision is explicitly
reopened or Hermes Agent exposes Buzz as an ordinary optional messaging platform.

1. Add upstream Buzz detail/readiness and integration-topology contracts.
2. Add a read-only Wing Buzz detail screen.
3. Add redaction, hostile-payload, identity-conflict, reconnect, and fallback tests.
4. Add typed policy mutation and write-only secret operations upstream.
5. Add a review-first Wing setup surface.
6. Keep all Nostr identity, key, transport, and messaging semantics inside the
   Hermes-owned integration.
7. Physically test public-key display, 200% text, offline/reconnect,
   WebSocket-to-poll fallback, and Android lifecycle.
8. Prototype Nostr-signed exported receipts separately; do not couple them to
   core control-plane work or Wing Link.

## High-value verification cases

- Two profiles cannot drive one `(relay, pubkey)` identity.
- Reconnect does not replay historical channel events as new prompts.
- Self-authored events never create agent loops.
- Duplicate event IDs produce at most one agent turn.
- Automatic transport fallback is visible and does not claim WebSocket health.
- Forced WebSocket mode fails closed on authentication failure.
- Private mode with an empty allowlist does not become community-wide access.
- Agent output suppresses intermediate tool details by default.
- Public diagnostics never include `nsec`, credential paths, message bodies, or full channel IDs.
- Unknown Nostr kinds/tags are bounded and ignored unless explicitly supported.
- NIP-98 enrollment rejects stale timestamps, URL/method mismatches, body-hash mismatches, replay, and unauthorized public keys.
- Encrypted Nostr payloads are not marketed as forward-secret messaging.

## Sources

[1] https://hermes-agent.nousresearch.com/docs/integrations/buzz — Hermes Agent Buzz Integration
[2] https://github.com/nostr-protocol/nips/blob/master/01.md — NIP-01 Basic Protocol Flow
[3] https://github.com/nostr-protocol/nips/blob/master/98.md — NIP-98 HTTP Auth
[4] https://github.com/nostr-protocol/nips/blob/master/44.md — NIP-44 Encrypted Payloads
[5] https://github.com/block/buzz — Block Buzz
[6] https://github.com/NousResearch/hermes-agent/blob/main/plugins/platforms/buzz/adapter.py — Hermes Agent Buzz Adapter
[7] https://github.com/nostr-protocol/nips/blob/master/29.md — NIP-29 Relay-based Groups
