# ADR 0044: Use Wing Link as a local runtime supervisor

Status: accepted
Date: 2026-08-05

Hermes Wing needs a bounded, cross-platform way to prepare and maintain a local Hermes Agent without embedding the Agent or duplicating its domain authority.

## Decision

Wing Link is a small persistent host supervisor for supported PCs and Android/Termux. It installs, adopts, starts, stops, updates, verifies, repairs, and diagnoses an external Hermes Agent runtime.

Wing Link exposes an authenticated management API only on `127.0.0.1:8654`. Hermes Agent remains authoritative for every domain operation after bootstrap, including chat, sessions, profiles, providers, models, memory, skills, tools, schedules, approvals, and gateway state.

Wing Link does not proxy Hermes chat, duplicate Hermes authorization, expose a remote control plane, parse human CLI output, or embed Hermes Agent. Flutter reaches Hermes domain behavior through the existing capability-advertised Hermes interfaces.

## Installation and lifecycle boundary

Hermes Wing packages may contain the matching Wing Link executable. They contain no Python runtime, Hermes Agent payload, Node runtime, or OmniRoute package. Wing Link adopts a compatible existing runtime without changing its home, data, credentials, or configuration.

New and updated runtimes follow ADR 0038. Wing Link accepts only signed, version-pinned release metadata from a trusted Hermes Wing or Hermes Agent release authority, verifies complete artifact size and digest before execution, uses fixed argument vectors, defaults to unprivileged per-user installation, and activates only a healthy compatible runtime. It retains a verified rollback target when updating.

Ordinary Hermes Wing or Wing Link uninstall preserves external Hermes and OmniRoute runtimes and their data. Destructive cleanup is a separate explicit operation.

## Local management authorization

The management listener is loopback-only, but loopback is not treated as authorization. A five-minute, single-use bootstrap code exchanges for a random Wing Link control token. Flutter stores that token in platform secure storage; Wing Link stores only its cryptographic hash.

Wing Link creates a scoped Hermes enrollment through Hermes Agent’s existing enrollment API and returns only the one-time `wing://connect` pairing payload. It never returns, proxies, logs, or persists the Hermes superuser API key.

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
