# ADR 0003: Route through a small Hermes and Settings shell

Status: superseded by ADR 0011
Date: 2026-07-07

## Context

The current product context names only `/hermes` and `/settings` as active routes. `go_router` is the routing package. The router redirects `/` to `/hermes`, wraps routes in `AppShell`, and exposes route helpers for Hermes and Settings path-prefix matching.

## Decision

Use `go_router` with a single shell route and two app destinations: Hermes and Settings. `/hermes` is the initial and primary route; `/settings` contains local installation preferences.

## Consequences

- Navigation stays aligned with the Hermes-only product scope.
- More routes require a product decision and should not be added merely to mirror Hermes Desktop or legacy Gormes screens.
- Route matching should use prefix helpers so query parameters and sublocations do not break selected-state logic.

## Evidence

- `CONTEXT.md:5-12`
- `docs/product/routes.md:3-6`
- `pubspec.yaml:13`
- `lib/router/routes/app_routes.dart:3-30`
- `lib/router/providers/app_router.dart:10-41`
