# ADR 0007: Keep a native HermesChannel instead of a legacy WingChannel adapter

Status: accepted
Date: 2026-07-07

## Context

Hermes Wing is now Hermes-only. The active Hermes API concepts are endpoints, sessions, runs, approvals, tool progress, stop controls, and local voice transcript submission. The previous Gormes-era `WingChannel` shape included legacy profile, gateway, memory, and configuration concepts that are outside the active product scope.

## Decision

Do not implement Hermes as an adapter behind the legacy `WingChannel` interface. Use `HermesChannel` as the public app seam for Hermes behavior, with `HermesApiChannel` as the production implementation. `HermesApiChannel` may be internally split by responsibility, but callers should continue to depend on `HermesChannel`.

## Consequences

- Hermes UI and tests are shaped around Hermes sessions and runs instead of relabeled Gormes concepts.
- The public seam remains small enough to test and override with fakes.
- Internal channel files can be refactored without changing UI imports or provider overrides.
- Reintroducing legacy channel compatibility requires a future ADR because it would broaden the product model.

## Evidence

- `CONTEXT.md:3-16`
- `docs/product/prd.md:1-5`
- `lib/core/hermes/channel/hermes_channel.dart:11-60`
- `lib/core/hermes/channel/hermes_api_channel.dart:24-152`
- `lib/features/hermes_chat/providers/hermes_channel_provider.dart:29-37`
- `lib/main_e2e.dart:53-58`
