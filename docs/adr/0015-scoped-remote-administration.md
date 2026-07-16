# ADR 0015: Require scoped authorization for remote administration

Status: accepted
Date: 2026-07-13

Hermes Agent must enforce scoped authorization before Hermes Wing exposes mutating administration on Android. Scoped operator tokens are revocable bearer credentials with domain-level read/write grants; the legacy `API_SERVER_KEY` remains a compatibility superuser credential but is not the default Android credential.

## Consequences

- Scope domains are `chat`, `sessions`, `profiles`, `providers`, `skills`, `tools`, `memory`, `tasks`, `gateway`, and `settings`, with `domain:read` and `domain:write` grants where applicable.
- `/v1/capabilities` reports the authenticated caller’s granted scopes and each advertised operation’s required scopes.
- Hermes Agent checks scopes on every protected route; Flutter visibility and disabled states are usability aids, not authorization controls.
- Tokens support issuance, listing, rotation, and revocation without exposing stored token material.
- Secret administration can report presence and accept set/remove mutations but never returns raw secret values.
- Administration uses typed, revisioned domain resources under ADR 0028; generic config-path and environment-variable APIs are not exposed remotely.
- Existing API-server keys map to superuser access for compatibility and require explicit operator choice when enrolled on a remote client.
