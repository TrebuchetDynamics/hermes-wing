# ADR 0017: Retire Electron only after desktop parity

Status: accepted
Date: 2026-07-13

Hermes Desktop remains supported while Navivox ships incremental Android and desktop milestones. The Electron retirement gate opens only when the planning-baseline capability matrix and every accepted delta through ADR 0021’s retirement cutoff are reconciled on Linux, Windows, and macOS; success on the Android or Linux reference platform alone is not sufficient.

## Consequences

- Android and Linux reference releases may ship before the migration is complete.
- Every baseline desktop capability and accepted pre-cutoff delta must be validated on all three desktop targets, replaced by an equivalent outcome, explicitly deprecated, or have an approved platform exclusion.
- iOS and web completion do not block Electron retirement because Hermes Desktop does not serve those platforms.
- The parity ledger, not route count or visual resemblance, is the retirement evidence.
