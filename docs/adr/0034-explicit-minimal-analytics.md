# ADR 0034: Require explicit consent for minimal analytics

Status: accepted
Date: 2026-07-13

Navivox product analytics is disabled by default on every build and platform. It creates no analytics identifier, queues no event, and sends no analytics request until the operator explicitly opts in after seeing the recipient and data categories. The configured official build does not imply consent.

## Event contract

Analytics uses a closed event-name and property allowlist. Eligible data is limited to coarse application version, platform family, enumerated route names, and enumerated feature names or outcomes needed to measure product reliability. Callers cannot attach arbitrary strings or maps.

Analytics never contains prompts, transcripts, generated content, recognized speech, approvals, tool arguments or results, errors containing user data, endpoint origins or hostnames, profile/account/session/resource identifiers, URLs, filesystem paths, connection metadata, credentials, wallet or transaction activity, contact data, or precise user-entered values.

Session replay, automatic page-view capture, advertising attribution, fingerprinting, and third-party enrichment are prohibited.

## Consent lifecycle

- Consent is a local client preference and is not inferred from Hermes Agent, Hermes One, an earlier Electron installation, or another device.
- Opt-in creates a random app-install analytics identifier only when the first allowed event is emitted.
- Opt-out immediately stops transmission, drops any pending analytics events, and deletes the local identifier.
- Re-enabling creates a new unrelated identifier; no historical events are backfilled.
- Analytics failure never blocks product behavior and never falls back to logs containing user content.
- Crash reports and diagnostic bundles remain separate explicit user-reviewed exports; analytics consent does not authorize their upload.

Hermes Desktop's configured-build default-on behavior is intentionally not preserved.
