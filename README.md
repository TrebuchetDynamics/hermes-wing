# Hermes Wing

<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="Hermes Wing — pair once, then run trusted Hermes Agent sessions from Android, web, or desktop">
</p>

<p align="center">
  <a href="https://github.com/TrebuchetDynamics/hermes-wing/actions/workflows/hermes-platform-smoke.yml"><img alt="Hermes platform smoke" src="https://github.com/TrebuchetDynamics/hermes-wing/actions/workflows/hermes-platform-smoke.yml/badge.svg"></a>
  <a href="#project-status"><img alt="Status: alpha" src="https://img.shields.io/badge/status-alpha-f59e0b"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-3b82f6"></a>
</p>

<p align="center">
  <img src="./assets/readme/showcase.png" width="100%" alt="Hermes Wing adapting one Hermes session to its dark desktop workspace and light mobile interface">
</p>

<p align="center"><sub>Dark desktop workspace and light mobile interface — same session, same endpoint.</sub></p>

> [!IMPORTANT]
> Hermes Wing is independent, source-distributed alpha software. There are no
> signed public binaries or store releases yet.

## One Hermes session model, every screen

Hermes Wing connects phones, browsers, and desktops to a trusted Hermes Agent
endpoint. The same Flutter client keeps streamed work, tool activity, approvals,
profiles, models, and optional device speech within reach without replacing the
Hermes backend.

| Capability | What it covers |
| --- | --- |
| **Live streaming** | Session-owned concurrent streams, run handles, bounded reasoning, tool events, token usage, and stop controls |
| **Operator approval** | Review approval requests in their owning session before sensitive work continues |
| **Office** | Responsive 2D workspace of authoritative gateway contacts with availability, session counts, and direct chat |
| **Endpoint management** | Advertised agents, profiles, providers, model assignments, and bounded runtime model inspection |
| **Inventory** | Installed-skill metadata, toolset labels, scheduled jobs, gateway workload, readiness, and messaging-platform state |
| **Device speech** | On-device speech-to-text with one-step speak-and-send or long-press dictation for review before sending; optional reply TTS via Pocket Speech voice packs |
| **Adaptive layouts** | Compact mobile flow and desktop workspace from one adaptive codebase |

## From source to first session

Prerequisites: **Flutter 3.44.2**, the SDK for your target platform, and a
reachable Hermes Agent endpoint.

```bash
git clone https://github.com/TrebuchetDynamics/hermes-wing.git
cd hermes-wing
flutter pub get
flutter run -d <device-id>
```

### Install the host helper

On the machine running Hermes Agent:

```bash
./install-wing-cli.sh
wing-cli info
```

The installer puts `wing-cli` in `~/.local/bin` by default and prints a PATH
hint when needed. The helper uses Bash and Python 3. It discovers
`API_SERVER_KEY` through `hermes config env-path`, or from the
`WING_HERMES_TOKEN` environment override.

### Pair Android

With Hermes Agent reachable through Tailscale or another trusted origin:

```bash
wing-cli qr
```

In Hermes Wing, open **Connect to Hermes → Scan QR code**, review the endpoint
and access, then connect. The QR carries a short-lived, single-use handoff—not
the API key. The compatibility QR path grants the configured
`API_SERVER_KEY` superuser access and says so before scanning; it exits after
one exchange or after its timeout. Other platforms can enter the trusted
endpoint and access token manually.

| Helper command | Purpose |
| --- | --- |
| `wing-cli info` | Show the Tailscale address and Hermes endpoint without revealing a token |
| `wing-cli qr` | Render the temporary Android pairing handoff in the terminal |
| `wing-cli link` | Request a short-lived scoped `wing://` link from a Hermes enrollment endpoint |
| `wing-cli token` | Explicitly reveal the superuser key for a manual developer fallback |

Run `wing-cli help` for origin, label, scope, and environment overrides.

## How the trust path works

<p align="center">
  <picture>
    <source media="(max-width: 600px)" srcset="./assets/readme/runtime-flow-mobile.svg">
    <img src="./assets/readme/runtime-flow.svg" width="100%" alt="Hermes Wing flow from reviewed device input through Hermes sessions and streamed runs to operator approval or stop controls">
  </picture>
</p>

Hermes Wing reads `/v1/capabilities` before enabling endpoint features. Hermes
Agent remains authoritative for profiles, sessions, tools, runs, approvals, and
configuration; the client does not parse Hermes files or mirror its backend.
HTTP carries commands and resources while SSE carries typed run events.

| Target | Endpoint example |
| --- | --- |
| Same desktop host | `http://127.0.0.1:8642` |
| Android emulator → host | `http://10.0.2.2:8642` |
| Physical device or remote desktop | HTTPS, VPN, Tailscale, or isolated LAN URL |

Hermes Wing asks for explicit confirmation before sending a bearer credential
to a non-loopback plaintext HTTP endpoint. See the
[Android setup guide](docs/runbooks/android-hermes-setup.md) and
[Hermes compatibility contract](docs/product/hermes-compatibility.md).

## Multiple Hermes gateways

Hermes Wing treats each saved Hermes Agent endpoint as a gateway and shows its
Hermes profiles in one activity-ordered contact list. Only the open contact owns
the full streaming channel; inactive gateways refresh health and session
summaries over lightweight requests. Opening a contact activates that endpoint,
Hermes profile, and its latest session; older sessions remain available from
the chat header.

Session details and portable transcript exports expose only bounded
server-reported lifecycle, token/cache/reasoning, tool/API-call, and cost
metadata. Settings can rename, reconnect, remove, or update an inactive saved
gateway origin and rotate or explicitly clear its write-only access token; the
existing token is never rendered. Offline gateways remain visible from cached
non-secret summaries.

## Project status

The [Hermes Desktop parity ledger](docs/product/hermes-desktop-parity.md) is
the canonical source for capability status, milestone evidence, and the
Electron retirement gate.

| Platform | Current evidence | Status |
| --- | --- | --- |
| Android | Debug build plus physical chat/session, concurrent-stream, process-recovery, session-metadata, bulk-selection, branch, Office, and tools-inventory receipts | Experimental alpha |
| Web | Release build and deterministic browser smoke | Alpha, text-focused |
| Linux | Release build plus native-shell and transcript-context-menu receipts | Alpha, text-focused |
| Windows | Cross-target native Settings/About/window/full-screen syntax check | Build-tested only |
| iOS | Simulator debug compilation | Build-tested only |
| macOS | Debug compilation plus native Settings menu bridge | Build-tested only |

Voice input requests the operating system's recognition interface on Android,
iOS, macOS, Windows, and web. Availability and offline behavior depend on the
installed recognizer and device policy. Linux voice input is unavailable, and a
repeatable physical-device microphone receipt has not yet been recorded.

## Security boundaries

- Bearer credentials use each platform's secure-storage implementation;
  hardware backing and backup behavior vary.
- Pairing links never include bearer tokens. Android shows the endpoint and
  requested or effective access before exchange.
- Endpoint metadata is stored separately in shared preferences.
- Recognized words are excluded from diagnostic logs, and voice submits
  completed text rather than captured microphone audio.
- HTTPS is recommended for remote endpoints. Plain HTTP can expose credentials
  and conversations outside a trusted encrypted network.
- Hermes Agent capabilities and scopes enforce authorization; hidden client
  controls are not a security boundary.

Hermes Wing has not received an independent security audit. Read
[SECURITY.md](SECURITY.md) and the [threat model](docs/security/threat-model.md)
before deploying outside a local or encrypted private network.

## Compatibility and current limits

Hermes Wing negotiates compatibility instead of claiming a fixed Hermes release
range. A compatible server provides `/health`, `/v1/capabilities`, and the
advertised session or run endpoints used by the client.

- No signed packages or store distribution.
- Windows, iOS, and macOS are compilation-tested, not release-supported.
- Desktop hosts use the canonical Hermes Wing product identity. Linux,
  Windows, and macOS expose native Settings menu actions, while Ctrl/Command+,
  selects the same existing route through a bounded command/navigation bridge.
  Their native About actions display only fixed local product information, and
  Window/View actions remain local minimize/maximize/restore/full-screen
  requests; none of these controls grant Hermes Agent authority.
- Native desktop secondary-click menus can reply to or copy one visible message
  and copy the authorized active transcript as text or Markdown. They reuse the
  existing bounded transcript exporter and perform no Hermes request.
- Hermes server audio and realtime audio are not wired; voice submits text.
- Remote transcript media and client-path attachments remain deferred.
- Optional inventory can fail independently of an otherwise healthy connection;
  the UI distinguishes unavailable data from an empty result.
- Per-gateway profile management requires that gateway to advertise the scoped
  profile API. Wing does not create local shadow profiles or bypass a missing
  server capability. See [gateway profile management and limitations](docs/product/gateway-profile-management.md).

## Development

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --concurrency=1
flutter build web --release -t lib/main_e2e.dart
npm ci
npm run web:e2e
npm audit
```

Optional offline text-to-speech uses the pinned
[`pocket_speech`](https://github.com/TrebuchetDynamics/pocket-speech-dart)
package with operator-selected Kitten or Kokoro voice packs. **Settings → Local
device voice** shows download progress, installed storage, voice choice, local
preview, and reply speed without exposing model paths.

## Project map

- [Roadmap](ROADMAP.md)
- [Documentation index](docs/README.md)
- [Hermes compatibility](docs/product/hermes-compatibility.md)
- [Gateway profile management and limitations](docs/product/gateway-profile-management.md)
- [Hermes Desktop parity ledger](docs/product/hermes-desktop-parity.md)
- [Architecture decisions](docs/adr/README.md)
- [Alpha release runbook](docs/runbooks/release-alpha.md)
- [Contributing](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)

## License

Hermes Wing is available under the [MIT License](LICENSE).
