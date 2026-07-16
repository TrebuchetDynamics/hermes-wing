# ADR 0004: Store Hermes endpoint metadata separately from API keys

Status: accepted
Date: 2026-07-07

## Context

Hermes Wing connects to trusted local, VPN, LAN, Tailscale, or self-hosted Hermes Agent endpoints. `CONTEXT.md` says API keys are secrets, while endpoint URLs are non-secret operator-controlled metadata. Setup URLs may contain copied secret material in userinfo, query strings, or fragments.

## Decision

Persist Hermes endpoint base URLs and profile metadata in shared preferences, but store API keys only in platform secure storage. Normalize endpoint URLs with `hermesPublicEndpointBaseUrl` before display or persistence so userinfo, query strings, and fragments are stripped.

Bearer credentials sent to a non-loopback cleartext HTTP endpoint require an explicit operator warning. HTTPS remains the preferred remote transport; cleartext is reserved for loopback or operator-confirmed private networks.

## Consequences

- Settings and reconnect surfaces may show endpoint origins but must never show API-key values.
- Clearing or deleting an endpoint profile must also delete the matching secure-storage key.
- New endpoint import paths must pass through the same normalization and storage split.

## Edge cases

- Malformed URLs are preserved as trimmed text for user correction rather than guessed into a new origin.
- Copied URLs with userinfo, query strings, or fragments must not persist those secret-bearing parts.
- Missing shared preferences or secure storage should fail closed to an empty endpoint store.

## Evidence

- `CONTEXT.md:14-16`
- `README.md:33-37`
- `lib/core/hermes/setup/hermes_endpoint_store.dart:1-59`
- `lib/core/hermes/setup/secure_hermes_endpoint_store.dart:8-22`
- `lib/core/hermes/setup/secure_hermes_endpoint_store.dart:48-90`
- `lib/core/hermes/setup/secure_hermes_endpoint_store.dart:198-221`
