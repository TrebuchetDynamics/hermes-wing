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
