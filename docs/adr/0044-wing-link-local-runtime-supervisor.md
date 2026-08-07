# ADR 0044: Use Wing Link as a local runtime supervisor

Status: accepted
Date: 2026-08-05

Hermes Wing needs a bounded, cross-platform way to prepare and maintain a local Hermes Agent without embedding the Agent or duplicating its domain authority.

## Decision

Wing Link is a small persistent host supervisor for supported PCs and Android/Termux. It installs, adopts, starts, stops, updates, verifies, repairs, and diagnoses an external Hermes Agent runtime.

Wing Link exposes its authenticated management API on `127.0.0.1:8654` and, after explicit pairing setup, on one selected current RFC 1918, CGNAT/Tailscale, or IPv6 ULA interface. Wildcard, public, multicast, broadcast, unspecified, and link-local listeners remain prohibited. Hermes Agent remains authoritative for runtime domain operations including chat, sessions, providers, models, memory, skills, tools, schedules, approvals, and gateway state.

Wing Link does not proxy Hermes traffic, duplicate Hermes runtime state, parse human CLI output, or embed Hermes Agent. It may bridge profile **topology** only: API-first inventory and mutations, validated local profile discovery, and fixed Hermes CLI create/clone/rename/delete vectors when the Agent does not advertise the corresponding API action. API errors never fall back to CLI. Flutter sends all paired topology mutations to Wing Link but continues to send chat/session/run traffic directly to Hermes.

## Installation and lifecycle boundary

Hermes Wing packages may contain the matching Wing Link executable. They contain no Python runtime, Hermes Agent payload, Node runtime, or OmniRoute package. Wing Link adopts a compatible existing runtime without changing its home, data, credentials, or configuration.

New and updated runtimes follow ADR 0038. Wing Link accepts only signed, version-pinned release metadata from a trusted Hermes Wing or Hermes Agent release authority, verifies complete artifact size and digest before execution, uses fixed argument vectors, defaults to unprivileged per-user installation, and activates only a healthy compatible runtime. It retains a verified rollback target when updating.

Ordinary Hermes Wing or Wing Link uninstall preserves external Hermes and OmniRoute runtimes and their data. Destructive cleanup is a separate explicit operation.

## Local management authorization

Neither loopback nor an eligible VPN/LAN interface is treated as authorization. A five-minute, single-use bootstrap transaction stages a random Wing Link control token. Flutter stores the pending credential securely, verifies direct Hermes plus Wing Link status/inventory, and acknowledges it; only then may the token authorize mutations. Wing Link stores cryptographic token hashes, never raw control tokens.

Wing Link prefers scoped Hermes enrollment when Hermes advertises it. When scoped enrollment is absent, a reviewed compatibility broker may read the existing local `API_SERVER_KEY`, label review **Full Hermes access**, and return it once over the trusted pairing channel after explicit confirmation. This is the narrow exception to the earlier superuser-key prohibition: the key stays memory-only in Wing Link, is never accepted by the management API, and is stored by Flutter only as the separate Hermes credential. The `wing://connect` payload itself contains no bearer credential.

## Android and Termux

Android uses a guided local installation because the application sandbox cannot write into Termux. The operator installs and opens Termux, grants `com.termux.permission.RUN_COMMAND`, and runs one pinned Wing Link bootstrap command.

After bootstrap, Hermes Wing invokes only the fixed Wing Link executable through Termux RUN_COMMAND with allowlisted argument vectors. No arbitrary command text, client-selected executable, or provider secret crosses the Flutter/Kotlin boundary.

## Recommended Donna starter profile

Local setup recommends the third-party Donna starter profile and selects it by default, but the operator may deselect it. The disclosure names its persona, curated skills, plugins, defaults, source, and independent MIT license.

The signed Wing Link component manifest pins the exact reviewed Donna commit and complete archive digest. Wing Link stages the verified archive and invokes Hermes Agent’s official profile-distribution installer with fixed arguments. It never clones mutable `main` content directly into `~/.hermes/profiles`, overwrites an existing `donna` profile, or silently updates a locally customized profile.

The current reviewed Donna commit lacks the `distribution.yaml` required by Hermes’s installer. The production option therefore remains compatibility-gated until a reviewed pinned commit supplies a valid distribution manifest; Wing Link does not bypass the gate with direct filesystem copying. Profile failure leaves Hermes healthy and the default profile available.

## Optional OmniRoute quick start

OmniRoute is optional and independently recoverable. Wing Link downloads and installs it only after explicit disclosure and consent, pins and verifies the exact package, binds it to loopback, and never describes community providers as unlimited or guaranteed-free.

Wing Link may apply a fixed OmniRoute model configuration only to the fresh Hermes installation created by the same operation. It does not overwrite an adopted or configured Hermes runtime. OmniRoute failure leaves a healthy Hermes installation available for normal provider setup.

## Consequences

- ADRs 0012 and 0023 now apply their host-adapter boundary to Wing Link on supported PCs and Android/Termux, not desktop alone.
- ADR 0038 remains authoritative for signed metadata, artifact verification, activation, update, and rollback; this decision does not weaken it.
- Browsers and iOS remain remote Hermes clients because they cannot host Wing Link through this design.
- Missing secure enrollment or lifecycle capabilities fail closed and remain visible compatibility blockers.
- Public copy promises guided local installation, not silent or zero-interaction installation.
