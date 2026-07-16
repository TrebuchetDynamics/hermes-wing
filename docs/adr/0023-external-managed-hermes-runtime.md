# ADR 0023: Manage an external Hermes runtime

Status: accepted
Date: 2026-07-13

Hermes Wing desktop packages contain Flutter and platform host adapters, not an embedded Python distribution or Hermes Agent payload. Desktop host adapters discover an existing Hermes installation or invoke the official installer, preserve the selected Hermes home, and verify the resulting runtime through health and capability contracts.

## Consequences

- Hermes Wing and Hermes Agent retain independent release, update, and rollback lifecycles.
- Existing installations and operator-selected Hermes homes are first-class migration paths.
- Host adapters own installer invocation, process lifecycle, secure local connection setup, and actionable recovery when verification fails.
- Domain behavior remains behind Hermes Agent interfaces after bootstrap; Flutter does not parse runtime files or CLI output.
- Desktop package acceptance verifies both a clean install and adoption of an existing supported installation through ADR 0038's authenticated, version-pinned lifecycle.
