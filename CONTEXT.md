# Navivox Context

Navivox is the Flutter companion for Hermes Agent. Product language, routes, tests, and docs should describe Hermes endpoints, Hermes sessions, Hermes runs, local device speech-to-text, approvals, tool progress, and local settings.

## Active routes

- `/hermes` — Hermes Agent connection, sessions, chat, runs, voice transcript submission, approvals, stop controls, and diagnostics.
- `/settings` — local voice preferences for this install.

## Endpoint language

Use **Hermes endpoint** or **Hermes Agent API server** for the trusted server. Use **session** for the durable conversation lane. Use **run** for streamed work with events, approvals, and stop controls.

## Security posture

API keys are secrets. Endpoint URLs are non-secret metadata but still operator-controlled. Prefer loopback, LAN, VPN, Tailscale, or TLS URLs. Do not log API keys or pairing secrets.
