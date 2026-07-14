# ADR 0022: Evolve parity APIs through additive capabilities

Status: accepted
Date: 2026-07-13

Hermes Agent parity contracts evolve additively on the canonical API origin and are advertised per operation by `/v1/capabilities`. The capability document carries a small integer `schema_version`; clients treat an absent value as version 1, ignore unknown fields, and require both a supported schema and the advertised operation before use.

## Consequences

- Hermes Agent release versions do not determine client compatibility.
- Existing paths remain stable while optional fields, operations, scopes, and event types are added.
- Unsupported or malformed required operations fail closed without disabling unrelated capabilities.
- A new major schema or route namespace is introduced only for an incompatible contract that cannot be represented additively.
- No separate monolithic Desktop API is created.
