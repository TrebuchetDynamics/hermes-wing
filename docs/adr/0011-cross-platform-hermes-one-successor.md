# ADR 0011: Make Navivox the cross-platform Hermes One successor

Status: accepted
Date: 2026-07-13

Navivox is the canonical cross-platform Flutter successor to Hermes Desktop, not only a mobile companion. “Full port” means capability parity: preserve user outcomes with Flutter and Hermes Agent interfaces rather than reproducing Electron code, while platform-gating host capabilities such as local installation, process control, files, SSH, and updates where they cannot be provided safely.

## Consequences

- Desktop targets pursue complete Hermes Desktop capability parity.
- Mobile and web expose remote, mobile-safe equivalents and hide unsupported host controls.
- New surfaces remain capability-gated against Hermes Agent instead of assuming one server version.
- The existing Hermes session/run language and security boundaries remain in force.
- ADRs 0001, 0003, and 0008 are superseded where they constrain Navivox to companion-only scope, two routes, or a non-port policy.
