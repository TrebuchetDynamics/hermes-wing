# ADR 0019: Keep Hermes One account authority separate

Status: accepted
Date: 2026-07-13

The optional Hermes One account service remains the authority for cloud identity, cloud-agent synchronization, and backend-managed wallets. Navivox authenticates to it directly with its own OAuth credential instead of proxying those operations through Hermes Agent; ADR 0014’s single origin applies to the Hermes Agent control plane.

## Consequences

- A connected app may hold one scoped Hermes Agent credential and, after optional account sign-in, one separate Hermes One OAuth credential.
- Account device authorization and cloud wallet calls require HTTPS and platform secure storage.
- Hermes Agent does not store, proxy, or expose the Hermes One OAuth credential.
- Cloud wallet secrets remain backend-held; Navivox receives only public wallet metadata and authorized account results.
- Account and wallet availability must fail independently without breaking Hermes chat or administration.
