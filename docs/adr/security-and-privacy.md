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

See [SECURITY.md](../../SECURITY.md) and the [threat model](../security/threat-model.md).
