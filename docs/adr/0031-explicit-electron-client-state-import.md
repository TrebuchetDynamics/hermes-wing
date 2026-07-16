# ADR 0031: Import Electron client state explicitly

Status: accepted
Date: 2026-07-13

On first desktop launch, Hermes Wing may detect Hermes Desktop client state and offer a previewable, explicit, one-time import. It adopts an existing supported `HERMES_HOME` in place and imports only allowlisted non-secret client preferences and connection metadata. It does not copy Hermes domain state or silently import credentials.

## Import manifest

Eligible items are limited to validated endpoint origins and labels, connection mode and non-secret transport settings, appearance and language preferences, and update preferences that have a Hermes Wing equivalent. The preview identifies each item and whether it will be imported, skipped, or requires reconfiguration without exposing private values or paths.

The importer excludes API keys, scoped tokens, Hermes One OAuth data, wallet data, recovery phrases, environment values, private key paths, context-folder paths, transcripts, databases, caches, logs, analytics consent and identifiers, and unsupported settings. Hermes Wing requires fresh scoped enrollment, Hermes One sign-in, and any analytics opt-in.

## Safety and lifecycle

- Import requires operator confirmation and never runs merely because legacy state was detected.
- The importer validates and normalizes every accepted value before writing it through Hermes Wing's normal stores.
- A source fingerprint and importer schema version make retries idempotent; a retry never duplicates endpoint profiles or overwrites newer Hermes Wing choices without confirmation.
- The receipt records only item categories and outcomes, not values, credentials, usernames, endpoint user information, or filesystem paths.
- Import never modifies or deletes Hermes Desktop data. The retirement or uninstall flow remains separate.
- Existing `HERMES_HOME` domain state remains owned by the external Hermes Agent and is verified through its health and capability interfaces rather than parsed by Flutter.
