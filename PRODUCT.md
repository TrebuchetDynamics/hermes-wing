# Hermes Wing

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Hermes users completing daily agent work. The owner confirmed Desktop and wide-web fidelity first, with compact and mobile usability preserved.

## Product Purpose

Port Hermes Desktop's UI and product behavior to a working Flutter client. The leading journey is connection, explicit profile/model/session selection, generation, correlated approval and authoritative Stop, departure/relaunch, and exact recovery without duplicate sends.

## Operating Context

The existing Flutter application targets desktop, web and mobile. The first redesign slice is the desktop shell/sidebar; Chat follows. Implementation and named-platform qualification are separate outcomes.

## Capabilities and Constraints

Hermes Agent owns domain state. Wing Link is a separate authenticated host-management plane, not a chat proxy or arbitrary shell. Reuse existing Riverpod, channel and adaptive routing contracts. Never patch upstream references, create shadow domain state, expose unsupported mutations, or weaken identity, authorization, containment or credential handling.

## Brand Commitments

Use the name Hermes Wing. The owner explicitly pinned the checked-out Hermes Desktop implementation as the redesign reference for layout, density, typography, color roles and navigation treatment. Match faithfully in Flutter rather than retaining Wing's incumbent visual style. Missing capabilities must remain clearly unavailable.

## Evidence on Hand

- [Product requirements](docs/product/prd.md)
- [Architecture decisions](docs/adr/README.md)
- [Desktop parity ledger](docs/product/hermes-desktop-parity.md)
- Read-only reference implementation: `hermes-desktop/`.

Source, deterministic fixtures and screenshots do not establish live inference, native integration, release readiness or full parity.

## Product Principles

- Prioritize the complete daily-work journey over decorative polish.
- Match the pinned reference rather than inventing a new visual world.
- Keep exact resource identities and server authority explicit.
- Separate delivered behavior from planned or unqualified support.

## Accessibility & Inclusion

Keep keyboard operation, meaningful semantics, readable contrast, large text, reduced motion and compact/mobile navigation usable. No outcome may require pointer precision, speech, sound, color alone, canvas or 3D.
