# ADR 0021: Freeze a final Electron retirement cutoff

Status: accepted
Date: 2026-07-13

Hermes Desktop 0.7.3 remains the stable planning baseline, but Electron retirement also requires a later named cutoff. Every user-capability delta between the baseline and that cutoff must be validated in Hermes Wing, deliberately replaced by an equivalent outcome, or explicitly deprecated before retirement; new Electron capabilities stop after the cutoff.

## Consequences

- The retirement cutoff version and commit are recorded when selected; they do not rewrite completed slice criteria retroactively.
- Post-baseline Desktop changes enter the delta ledger and are classified before retirement.
- After the cutoff, Hermes Desktop accepts critical security, data-loss, migration, and compatibility fixes but no new product capabilities.
- Critical fixes that alter user-visible behavior are mirrored in Hermes Wing or recorded in the delta ledger.
- The cutoff prevents dual feature development and a permanently moving retirement target.
