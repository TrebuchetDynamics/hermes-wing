# Milestone 2 — Providers & Models — Design

**Date:** 2026-07-14
**Status:** Approved
**Depends on:** milestone 1 (Profiles/Agents); reuses the milestone-0 scoped-token,
`If-Match`, capability-advertisement, and profile-scoping patterns.
**Roadmap row:** hermes-desktop-parity.md milestone 2 — "Provider presence/set/remove,
discovery, saved models, active model, and auxiliary task-model overrides without
secret reveal."

## What it does

A scoped, profile-aware contract for LLM provider credentials and model selection.
Expose the existing `hermes_cli` provider/model domain functions over authorized HTTP,
then build the Flutter client. The phone is a **key-setter and model-switcher, never a
key-reader**.

## Decisions

| Decision | Choice |
|---|---|
| Secret model | Write-only + presence: set/remove/validate a provider key and see `configured` + a masked last-4 hint; the raw key is never returned by any endpoint. The Dashboard's `reveal_env_var` is NOT mirrored to the API server. |
| Scopes | Two new domains: `providers:read|write`, `models:read|write` (least privilege — model-switching grantable without credential management). |
| Discovery | Cache-first: `GET /api/models` serves the server's cached catalog with no outbound call; a distinct `POST /api/models/refresh` (models:write) triggers the one live manifest fetch. |
| Profile scoping | Provider credentials and model assignments are profile-scoped in the domain layer, so all these operations carry the mandatory `?profile=` query, per milestone 0. |

## Server contract (hermes-agent)

Reuses existing domain functions; adds no `hermes_cli` behavior. All mutations
`:write`-gated via `_authorize`; assignment changes use `If-Match` optimistic
concurrency; capabilities advertises each endpoint with `required_scopes` and
`profile_scoped: true`.

- **Providers** (`provider_catalog`, `set_env_var`, `remove_env_var`,
  `validate_provider_credential`):
  - `GET /api/providers` (`providers:read`) → catalog descriptors + per-provider
    presence (`configured: bool`, masked last-4 hint).
  - `PUT /api/providers/{slug}/credential` (`providers:write`) → write-only key set;
    returns updated presence only.
  - `DELETE /api/providers/{slug}/credential` (`providers:write`).
  - `POST /api/providers/{slug}/credential/validate` (`providers:write`) → pass/fail
    only.
- **Models** (`get_catalog`, `set_model_assignment`, `get_auxiliary_models`):
  - `GET /api/models` (`models:read`) → cached catalog + saved/active + auxiliary
    assignments.
  - `POST /api/models/refresh` (`models:write`) → the single gated outbound manifest
    fetch (`get_catalog(force_refresh=True)`).
  - `PUT /api/models/assignment` (`models:write`, `If-Match`) → assign main and/or
    auxiliary task slots.

## Secret handling (core invariant)

`PUT credential` hands the key to `set_env_var` and returns only presence. Presence =
`configured` + masked last-4 (the single small derived disclosure). `validate` returns
pass/fail. No response body, log line, error message, or capability field ever contains
a raw key. Extends the milestone-0 diagnostic redaction list to cover provider keys.

## Client (wing)

New `/providers` route in the More sheet (milestone-1 `/agents` pattern):
- provider list with `configured` badges;
- a write-only credential entry sheet — obscured field, set/remove/validate actions,
  never renders an existing key;
- a model picker for main + auxiliary slots.

Typed `HermesProvider` / `HermesModelAssignment`, client-local, capability/scope-gated
mutation visibility (`auth.allows('providers:write')` / `models:write`),
reconnect-generation guarded, mandatory profile query on all operations.

## Error handling

Missing `If-Match` on assignment → 428; stale → 412 no write. Unadvertised endpoint /
missing profile context → fail before network. Provider not in catalog → 404. Validate
failure surfaces pass/fail, never the key or the upstream error verbatim if it could
echo the key.

## Testing

- Server: per-endpoint contract tests; a **secret-never-escapes test** (set a key, then
  assert it is absent from every list/validate/capabilities/error body and logs); an
  end-to-end receipt (set provider → validate → assign model → confirm active, all
  without reveal).
- Client: provider/model parsing, write-only credential flow (token never rendered),
  scope-gated visibility, reconnect race, cache-first discovery.

## Out of scope (YAGNI)

Mixture-of-Agents (MoA) config, the multi-key credential pool, OAuth-provider
connect/disconnect, per-session `/model` hot-swap. None appear in the milestone-2
roadmap line; each is a later milestone if pursued.
