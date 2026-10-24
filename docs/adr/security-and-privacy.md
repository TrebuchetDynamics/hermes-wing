# Security and privacy

Status: current decision

## Decision

Hermes Agent remains authoritative and independently authenticated. Removing Wing
Link does not authorize deleting raw user records or secure slots, merging old
management credentials with Agent credentials, weakening trust checks or exposing
Agent unauthenticated. No management fallback is offered.

Agent API keys, provider secrets and SSH credentials belong in platform secure
storage, never URLs, QR payloads, clipboards, shared text, process arguments,
ordinary preferences, responses, logs or diagnostics. Provider credentials are
write-only and require an exact advertised secret-safe Agent contract. Unsupported
secret mutation remains unavailable; never edit Agent files as a fallback.

HTTPS uses normal certificate/origin validation; native SSH checks the reviewed
host fingerprint and fails closed on change. Android permits cleartext transport
at the OS layer for private VPN addresses, but Wing requires explicit confirmation
before sending an Agent credential to a non-local HTTP origin. That consent is
only for an authenticated encrypted VPN or isolated trusted LAN; network location
is not authorization. Browser clients cannot bypass certificate validation.

Wing and Termux remain separate app sandboxes, sharing authenticated loopback
sockets only. Any local app may probe loopback; Agent authentication is mandatory.
Wing offers no external-command access, service installer or bootstrap binary.

Retired handoffs used a single-use pairing code expiring after five minutes, which
never contains a bearer credential, and a no-store handoff page. Current Wing
consumes and discards legacy intent/share input without parsing, exchange, display,
logging or persistence. Cancellation preserves the current caller and draft.

Server state wins after reconnect. Wing never queues or silently replays mutations,
approvals or configuration. Every operation requires its exact capability, grants,
resource identity and supported request context; broad versions/admin flags do not
establish authority. Destructive writes require fresh intent and authoritative
concurrency/idempotency checks. Owner/generation fences reject stale completions.
Diagnostics remain bounded and redact credentials, transcripts, private origins,
host paths and content. No arbitrary shell, config key, executable or host path
bridge may replace an unavailable Agent operation.

## Gateway sign-in and metadata QR

Current UI decision: the owner requested removal of QR creation/scanning from
connection screens. Manual HTTPS address/profile and browser sign-in remain;
removing the QR affordances does not delete saved identities or credentials.
The metadata constraints below describe the retained format and historical flow,
not an available scanner in the current login UI.

The owner approved a new direct native-gateway path: an explicitly scanned QR
carries only an HTTPS origin and literal profile ID. It is not an enrollment
credential, legacy pairing code or authorization grant. Unknown fields, embedded
keys, userinfo, paths, queries and fragments are rejected without displaying raw
input. Existing external intent/share rejection remains unchanged.

Wing initiates the gateway's advertised `native_pkce` flow in the phone's system
browser, with its own random S256 verifier/state and an ephemeral loopback callback
on that phone. The gateway alone verifies the login and issues access/refresh
tokens. Tokens stay bound to the exact HTTPS origin in platform secure storage;
they are never exchanged for an API-server key or transferred from Desktop.
Remote native REST and WSS use normal certificate validation and a fresh one-use
WebSocket ticket per dial. No mutation is retried on token refresh or reconnect.

This path does not start or publish a gateway, configure a VPN, open ports, read
Agent credential files, modify Agent, or introduce a management backend. A reachable
HTTPS gateway advertising compatible login remains a prerequisite. A QR can reveal
a private hostname/profile and should not be posted publicly even without tokens.
Camera permission is requested only by the explicit scanner; manual address entry
is the accessible equivalent. Runtime qualification must distinguish metadata scan,
login, socket negotiation, exact-session recovery and real generation.

## Opt-in Android SSH quick access

Android may retain one explicitly opted-in, successfully authenticated SSH/API
connection in a dedicated platform-secure slot. It includes the exact SSH
host/port/user, Agent port/profile and protocol, verified host fingerprint, SSH
password or private key/unlock phrase, and Agent token. Never persist a forwarded
loopback port as a reusable destination. Do not copy secrets to preferences,
clipboard, diagnostics, URLs or another connection's form.

Opening the connection screen reads the secure entry but never dials. A deliberate
**Connect to my Hermes** uses the existing forward, host-pin validation, Agent
authentication and recovery fences. A changed host fingerprint or failed Agent
authentication must not fall back to root or another credential. **Forget saved
access** deletes only this new slot; it does not revoke Agent credentials, remove
existing host pins or touch inert legacy records. Configuration editing starts
without prefilled secrets. Save completion and connection success are separate.
Reads, saves and forgetting serialize across store instances. A save rechecks
its current owner before and after writing; cancellation restores the previous
slot before another operation proceeds. The lock exists only while work is pending.
This is client-side credential reuse, not new Agent state or unattended host setup.
Initial secure entry and host approval remain required; real-device and live
network qualification are separate gates.

See [SECURITY.md](../../SECURITY.md) and the [threat model](../security/threat-model.md).
