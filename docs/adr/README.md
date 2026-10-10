# Architecture decisions

These five living decisions are the current architectural guardrails for Hermes Wing. They replace the earlier set of 44 narrow ADRs, whose history remains available in Git. Historical plans may still cite the retired numbers.

1. [Product boundaries](product.md)
2. [Client architecture](client.md)
3. [API and state](api-and-state.md)
4. [Security and privacy](security-and-privacy.md)
5. [Runtime and delivery](runtime-and-delivery.md)

## How to use these decisions

- Treat domain ownership, security, privacy, data-loss prevention, and accessibility as hard boundaries.
- Treat named libraries, routes, transports, package formats, and platform techniques as defaults that may change when a simpler supported approach works.
- Prefer advertised capabilities and runtime evidence over assumptions about a platform or Hermes Agent release.
- Keep implementation detail in code, tests, plans, and runbooks rather than creating another ADR.
- Update an existing decision before adding a new one. Add a decision only for a cross-cutting choice that is expensive to reverse and is not covered here.

## Local development and testing

Use the owner's scoped test request as authorization for ordinary development
work. Do not require a second architectural approval to build an isolated QA app,
install it on the selected test device, operate its UI, or run regression tests.
Preserve the user's paired application and unrelated work.

External test tools may use ADB forwarding or an authenticated SSH tunnel to a
selected host. These tools are not Wing Link compatibility operations or shipped
native integration. Record which connection was exercised. A test tunnel does
not establish that Wing manages SSH itself.

Choose reversible implementation details and continue. Ask only when a missing
credential, device permission, destructive operation, service change or durable
trust-boundary decision actually needs the owner. Existing authorization covers
the same scoped action; do not ask for it again. OS permissions and authentication
must still succeed, and missing access must not be reported as an ADR restriction.

These development rules do not relax credential protection, profile isolation,
Agent ownership, upstream immutability, or remote-management authorization. They
do not authorize replacing a paired app, bypassing host trust, changing another
profile, restarting a shared gateway, or publishing a release. Keep runtime
support claims tied to executed evidence.
