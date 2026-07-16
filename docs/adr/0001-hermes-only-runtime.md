# ADR 0001: Make Hermes Wing a Hermes-only companion

Status: superseded by ADR 0011
Date: 2026-07-07

## Context

`CONTEXT.md` defines Hermes Wing as a Flutter companion for Hermes Agent and limits active routes to `/hermes` and `/settings`. `README.md` lists Hermes Agent HTTP endpoints as the runtime surface, and `docs/product/prd.md` names legacy gateway setup, profile-contact management, external memory dashboards, and server configuration editors as non-goals.

## Decision

Hermes Wing targets Hermes Agent only. Product language, code, tests, docs, and routes should use Hermes endpoint, session, run, approval, tool progress, local voice, and local settings terminology.

Legacy Gormes/gateway/profile-contact/memory/config-admin surfaces are not part of the active app topology.

## Consequences

- The active route set stays small: `/hermes` and `/settings`.
- New work should not restore legacy gateway setup or Gormes-shaped abstractions unless a future ADR explicitly reopens that product scope.
- Documentation should be short and Hermes-only rather than carrying historical migration plans as current guidance.

## Evidence

- `CONTEXT.md:3-16`
- `README.md:3-24`
- `docs/product/prd.md:1-5`
- `docs/product/routes.md:3-6`
