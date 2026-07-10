# Security policy

Navivox is alpha software and has not received an independent security audit.

## Reporting a vulnerability

Use GitHub's private vulnerability-reporting flow from the repository Security
tab when available. Do not include API keys, transcripts, endpoint credentials,
or private server URLs in a public issue. If private reporting is unavailable,
open a minimal issue asking maintainers for a private contact channel without
disclosing exploit details.

Include affected versions, platform, reproduction steps, impact, and a proposed
embargo window. Maintainers will acknowledge a report when available; this
project does not currently promise a response or remediation SLA.

## Supported versions

No released version is currently supported. Security fixes target the current
`main` branch until signed releases exist.

## Deployment assumptions

- Prefer HTTPS for remote Hermes endpoints.
- Treat plaintext HTTP as development-only unless it runs inside a trusted
  encrypted VPN or similarly isolated network.
- Treat the device, operating-system speech recognizer, Hermes server, and
  downloaded speech models as separate trust boundaries.
- Rotate a Hermes API key if it may have appeared in logs, screenshots, shell
  history, or plaintext network traffic.

See [docs/security/threat-model.md](docs/security/threat-model.md) for the
current threat model and known gaps.
