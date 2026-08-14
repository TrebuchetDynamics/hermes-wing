# Client architecture

Status: current

## Decision

Keep the Flutter client modular around small replaceable seams. Existing Riverpod providers, Hermes channel contracts, and adaptive routing are the preferred patterns because they already support production wiring and test overrides.

Share domain behavior across platforms while allowing native or adaptive presentation. Accessibility is part of the primary interaction, including an equivalent path when speech, sound, motion, pointer input, canvas, or 3D is unavailable.

Use platform-native features where practical. Voice input and speech output should prefer local processing and must clearly expose platform limitations.

## Flexible guidance

- Reuse existing seams before introducing a new abstraction or dependency.
- Libraries and route structure may change when the replacement is simpler and preserves behavior.
- Validate in proportion to the change: focused tests first, then broader platform or E2E checks when the affected behavior requires them.
- A feature may ship on one supported platform before another when availability is accurately gated and documented.
