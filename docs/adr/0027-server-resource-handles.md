# ADR 0027: Use server-issued resource handles

Status: accepted
Date: 2026-07-13

Attachments and context folders cross the Hermes Wing–Hermes boundary as opaque server-issued resource handles, never arbitrary client filesystem paths. Clients upload bounded content or, on a local desktop connected to the same host, ask a host adapter to register an operator-selected path with Hermes Agent.

## Consequences

- Handles are bound to a profile, resource type, owner/session where applicable, and lifecycle policy.
- Hermes validates names, sizes, media types, canonical paths, permissions, and allowed roots before issuing a handle.
- Remote and mobile clients cannot register paths from their own filesystems; they upload content or choose an advertised server workspace.
- Chat, runs, history, retries, and context-folder selection refer to handles and safe metadata, not private absolute paths.
- Deleting or expiring a handle follows documented retention rules and cannot escape its profile boundary.
- Capabilities advertise upload, same-host path registration, workspace selection, limits, and supported resource types independently.
- Same-host path registration follows ADR 0041's native-picker grant, isolation, retention, revocation, and path-safety rules.
