# ADR 0018: Use adaptive Office renderers

Status: accepted
Date: 2026-07-13

Office uses one platform-independent interaction model with adaptive Flutter presentations. Android ships an accessible 2D Office first, while Linux, Windows, and macOS must provide the frozen baseline’s 3D Office experience before the Electron retirement gate opens.

## Consequences

- Agent status, selection, CEO assignment, buildings, representatives, One Chat, and account actions share contracts and state transitions.
- Android does not require a 3D engine to validate mobile Office capability parity.
- Desktop Office parity includes the interactive 3D scene, navigation, representative interactions, GPU fallback behavior, and ADR 0032's fully operable non-spatial equivalent.
- Renderers do not own Hermes profile, account, or wallet domain state.
