# ADR 0020: Do not port local wallet custody

Status: accepted
Date: 2026-07-13

Hermes Wing does not create, import, store, or automatically transfer wallet recovery phrases. Before Hermes Desktop can retire, it must provide ADR 0042's guarded one-wallet-at-a-time export path for recovery phrases encrypted by its legacy local wallet store; backend-managed cloud wallets remain the supported Hermes Wing wallet model.

## Consequences

- Legacy local wallets are migration data, not a Flutter wallet subsystem.
- Export requires explicit operator action and must not use logs, telemetry, clipboard, shared text, or automatic cloud upload.
- Hermes Wing may show public wallet metadata and backend-authorized balances without receiving wallet secrets.
- Electron retirement is blocked until the export path, its security tests, and operator migration instructions are validated on every desktop platform that stored local wallets.
