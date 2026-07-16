# ADR 0008: Build a mobile Hermes UI with Telegram chat ergonomics

Status: superseded by ADR 0011
Date: 2026-07-07

## Context

The Hermes Desktop UI gap audit says Hermes Wing should feel like a mobile-first Hermes companion, not a full Electron clone. It should preserve Telegram chat muscle memory while borrowing Hermes Desktop structure, hierarchy, status language, and high-contrast product feel around the chat core.

## Decision

Use Hermes Desktop as a structural/status-language reference and Telegram as the mobile chat ergonomics reference. Desktop/tablet may show a Hermes dark shell, session rail, command-bar composer, status cards, and active session bar. Mobile keeps a single-pane chat, bottom composer, large touch targets, sheets/dialogs, and simple session controls.

Do not copy Electron chrome, installer/update flows, or Desktop-only navigation surfaces into the mobile app by default.

## Consequences

- UI work must check both Hermes Desktop parity and mobile chat simplicity.
- New Desktop-inspired affordances should be hidden or simplified on phones unless they are essential to the Hermes mobile journey.
- Product screenshots and E2E tests should cover both connected desktop/tablet and mobile flows.

## Evidence

- `docs/product/hermes-desktop-ui-gap.md:1-23`
- `docs/product/hermes-desktop-ui-gap.md:24-69`
- `docs/product/hermes-desktop-ui-gap.md:196-214`
- `lib/features/hermes_chat/screens/hermes_chat_screen.dart:52-55`
- `lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart`
- `lib/features/hermes_chat/screens/widgets/hermes_chat_timeline.dart`
