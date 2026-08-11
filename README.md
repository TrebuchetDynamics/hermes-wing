# Hermes Wing

<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="Hermes Wing streams Hermes Agent conversations, tool activity, and approval controls across mobile and desktop">
</p>

<p align="center">
  <a href="https://github.com/TrebuchetDynamics/hermes-wing/actions/workflows/hermes-platform-smoke.yml"><img alt="Hermes platform smoke" src="https://github.com/TrebuchetDynamics/hermes-wing/actions/workflows/hermes-platform-smoke.yml/badge.svg"></a>
  <a href="#project-status"><img alt="Status: alpha" src="https://img.shields.io/badge/status-alpha-f59e0b"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-3b82f6"></a>
</p>

> [!IMPORTANT]
> Hermes Wing is alpha software. There are no signed public downloads or app
> store releases yet. Install it from source only if you are comfortable testing
> unfinished software.

Hermes Wing is a mobile-first client for
[Hermes Agent](https://github.com/NousResearch/hermes-agent). It lets you follow
conversations, inspect tool activity, answer approval requests, switch profiles,
and talk to your agent from a phone or desktop.

Wing connects to Hermes through its HTTP and SSE API. Hermes remains responsible
for sessions, tools, profiles, runs, approvals, providers, and configuration.
Wing does not read Hermes files or maintain a second copy of your agent state.

The project takes inspiration from
[Hermes Desktop](https://github.com/fathah/hermes-desktop), especially its clear
local-versus-remote setup and visual feature tour. Wing adapts those ideas for a
smaller screen and keeps all Hermes operations behind advertised API contracts.

<p align="center">
  <img src="./assets/readme/showcase.png" width="100%" alt="Hermes Wing desktop run controls and mobile gateway inventory">
</p>

<p align="center"><sub>Repository-backed examples: a streamed tool run with an inline approval on desktop, and gateway-scoped skills and toolsets on a physical Android phone.</sub></p>

## What you can do

| Area | In Wing |
| --- | --- |
| Chat | Stream replies, Markdown, reasoning summaries, tool activity, usage, and errors in the session that owns the run. |
| Sessions | Search history, rename or branch a session, export a transcript, retry a failed run, and stop active work. |
| Approvals | Review a tool request and approve once, allow it for the session, always allow it, or deny it. |
| Gateways | Save multiple Hermes endpoints, see their health and profiles, and move between local or remote agents. |
| Profiles and models | Browse capability-gated profiles, providers, models, installed skills, toolsets, and schedules. |
| Voice | Dictate a message for review, enable reply speech, and experiment with continuous conversation on supported devices. |
| Office | See an accessible overview of known gateway/profile contacts and jump into the matching chat. |

Wing hides operations that a Hermes endpoint does not advertise. A missing
permission or newer server contract appears as unavailable instead of an empty
list or a control that fails later.

## How it works

<p align="center">
  <picture>
    <source media="(max-width: 600px)" srcset="./assets/readme/runtime-flow-mobile.svg">
    <img src="./assets/readme/runtime-flow.svg" width="100%" alt="Hermes Wing reviews a trusted origin, negotiates capabilities, opens a Hermes session, and streams run events">
  </picture>
</p>

1. Wing connects to one trusted Hermes API origin.
2. It reads `/health` and `/v1/capabilities` before enabling features.
3. HTTP carries commands and resources. SSE carries typed run events.
4. After a reconnect, Wing refreshes authoritative server state. It does not
   replay local approvals or mutations automatically.

This is an API client, not a general network tunnel. A remote phone still needs a
route to the Hermes host through HTTPS, an isolated LAN, Tailscale, or another
trusted VPN/reverse proxy.

## Get started

Choose the path that matches your setup.

### Connect to an existing Hermes endpoint

You need:

- Flutter 3.44.2, the project baseline
- the SDK/toolchain for your target platform
- a running Hermes Agent API server that the device can reach

```bash
git clone https://github.com/TrebuchetDynamics/hermes-wing.git
cd hermes-wing
flutter pub get
flutter devices
flutter run -d <device-id>
```

When Wing opens, choose **Connect to Hermes** and enter the trusted endpoint plus
its API credential.

| Where Hermes runs | Endpoint example |
| --- | --- |
| Same desktop as Wing | `http://127.0.0.1:8642` |
| Host machine from an Android emulator | `http://10.0.2.2:8642` |
| Physical phone on an isolated LAN or VPN | `http://<trusted-host-ip>:8642` |
| Remote host | `https://<your-hermes-host>` |

Wing asks for explicit confirmation before sending a bearer credential to a
non-loopback plaintext HTTP endpoint. Prefer HTTPS whenever traffic leaves the
local machine.

### Set up a Hermes host and pair Android

Wing Link is the small host helper included in this repository. It can install or
adopt a pinned Hermes Agent build, prepare API authentication, start the gateway,
and create a short-lived pairing QR code. Persistent Wing Link service management
is currently implemented for Linux hosts.

Prerequisites on the host:

- Git
- Go 1.26 or newer
- network access to download the pinned Hermes installer
- a private LAN, Tailscale address, or other trusted route shared with the phone

```bash
git clone https://github.com/TrebuchetDynamics/hermes-wing.git
cd hermes-wing
./install-wing-link.sh
wing-link setup
```

The installer places `wing-link` in `~/.local/bin` by default. If that directory
is not on `PATH`, run `~/.local/bin/wing-link` or add the directory to your shell
configuration.

`wing-link setup` verifies the pinned Hermes installer size and SHA-256 before it
runs. It adopts a healthy existing Hermes installation instead of replacing it,
prepares an owner-only API credential when needed, and installs and starts the
Hermes gateway.

Finish provider/model setup with the official Hermes wizard:

```bash
hermes setup
hermes gateway restart
```

For a custom OpenAI-compatible provider, Wing Link can also create an initial
profile and non-secret provider/model configuration in one reviewable command:

```bash
wing-link setup \
  --profile work --clone-from default \
  --provider acme \
  --provider-url https://api.example.com/v1 \
  --model acme-model
```

That command does not accept provider credentials. Add secrets through Hermes's
supported setup flow or the capability-gated Providers screen after pairing.
They are never passed in Wing Link process arguments.

Pair the phone after Hermes is ready:

```bash
WING_HERMES_URL=http://<trusted-host-ip>:8642 \
WING_LINK_URL=http://<trusted-host-ip>:8654 \
wing-link pair
```

Then:

1. Open Wing on the phone.
2. Choose **Connect to Hermes** and **Scan QR code**.
3. Review the host label, Hermes origin, connection warning, and requested
   access.
4. Confirm the connection.

The pairing code is single-use and expires after five minutes. The QR contains no
Hermes or Wing Link bearer credential. `wing-link pair` installs, starts, and
checks the per-user service before showing the code, so you do not need to leave a
separate `wing-link serve` terminal open.

For the complete host checklist, see
[Android Hermes setup](docs/runbooks/android-hermes-setup.md).

## Your first trip around Wing

- **Hermes** opens the selected gateway/profile chat. The session picker keeps
  history and active runs close to the transcript.
- **Profiles** shows Hermes profiles when the endpoint advertises profile context
  and the credential has access.
- **Providers** shows configured and available providers/models without revealing
  stored API keys.
- **Tools** lists installed skills and enabled/configured toolsets for the selected
  gateway.
- **Schedules** shows jobs when Hermes advertises the read contract. Job editing
  remains unavailable without a supported administration contract.
- **Gateway** reports bounded health and readiness details.
- **Settings** controls theme, saved connections, diagnostics, and local voice
  options.

On compact screens, administrative destinations live under **More**. Desktop
layouts present the same routes in a navigation rail.

## Voice and privacy

Voice is optional and still experimental.

Wing submits completed recognized text, not captured microphone audio. Android
uses an on-device recognizer when the operating system provides one. Browser STT,
the transcript-logging Windows adapter, and devices without a suitable on-device
recognizer fail closed rather than silently changing the privacy model.

Optional local reply speech can use Pocket Speech with a user-selected Kitten or
Kokoro voice pack. Deterministic voice tests do not prove live microphone routing,
audible quality, acoustic echo cancellation, or reliable barge-in on every phone.
Those behaviors require physical-device testing.

## Security notes

- Use HTTPS for remote Hermes endpoints.
- Treat plaintext HTTP as development-only unless it stays inside a trusted
  encrypted VPN or similarly isolated network.
- Wing stores Hermes API and Wing Link credentials with each platform's secure
  storage implementation. Hardware backing and backup behavior vary by platform.
- Pairing QR codes contain a short-lived code, not a bearer credential.
- Provider keys are write-only in Wing. Inventory responses show only whether a
  key is configured and, when available, a masked hint.
- Wing Link manages installation, pairing, service lifecycle, health, and
  diagnostics. Hermes remains the authority for profiles, providers, sessions,
  and messages.
- Hermes Wing has not received an independent security audit.

Read [SECURITY.md](SECURITY.md) and the
[threat model](docs/security/threat-model.md) before using Wing outside a local or
private encrypted network.

## Troubleshooting

### Wing cannot reach Hermes

- Confirm the phone and host can reach each other through the selected LAN, VPN,
  Tailscale, or HTTPS route.
- Open the Hermes `/health` endpoint from the same network path.
- Check the hostname and port. Android emulators use `10.0.2.2` for the host, not
  `127.0.0.1`.
- Make sure a firewall or reverse proxy is not stripping SSE responses.

### Pairing expires or the QR is rejected

```bash
wing-link status
wing-link pair
```

Generate a new code after five minutes. Do not reuse an old screenshot or share a
pairing link publicly.

### A feature says unavailable

Wing enables a feature only when Hermes advertises the exact method, route, and
required scopes. Update or configure Hermes, reconnect, and check Gateway
readiness. Do not interpret an unavailable inventory as an empty inventory.

### Voice is unavailable

- Grant microphone permission to Wing.
- Check that the device has an on-device speech recognizer.
- Open **Settings → Voice & speech** and review the selected recognizer, language,
  and voice-pack state.
- Treat deterministic test audio separately from live microphone and acoustic
  behavior.

### Report a problem

Open a [GitHub issue](https://github.com/TrebuchetDynamics/hermes-wing/issues) for
bugs that do not contain sensitive information. Never post API keys, transcripts,
private endpoint URLs, pairing links, or screenshots containing credentials.
Security reports belong in the repository's private vulnerability-reporting flow;
see [SECURITY.md](SECURITY.md).

## Project status

Hermes Wing is source-distributed alpha software. Android is the best-tested
client today, but it is not a supported store release.

| Platform | Current state |
| --- | --- |
| Android | Experimental alpha. Debug builds have physical-device chat, lifecycle, Office, and inventory receipts, plus deterministic voice-loop coverage. |
| Web | Alpha and text-focused. Release builds and deterministic browser smoke are available. |
| Linux | Alpha and text-focused. Release builds and native shell checks are available. |
| Windows | Build-tested only. No supported release package. |
| iOS | Simulator build-tested only. |
| macOS | Build-tested only. |

Current limits:

- There are no signed packages, store builds, automatic updates, or supported
  release line.
- Windows, iOS, and macOS compilation does not establish runtime support.
- Linux voice input is unavailable. Speech recognition and offline behavior vary
  by device and operating-system policy.
- Hermes server audio, realtime audio, and remote transcript media are not wired
  into Wing.
- Some administrative surfaces remain read-only or unavailable until Hermes
  advertises the corresponding scoped API contract.

The [Hermes Desktop parity ledger](docs/product/hermes-desktop-parity.md) records
feature status and evidence in more detail.

## Development

End users do not need Node.js. Contributors running the full browser and
repository checks need Node.js 22 in addition to Flutter.

```bash
flutter pub get
npm ci
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --concurrency=1
flutter build web --release -t lib/main_e2e.dart
npm run web:e2e
npm audit
```

See [CONTRIBUTING.md](CONTRIBUTING.md) before sending a pull request.

## Documentation

- [Android setup](docs/runbooks/android-hermes-setup.md)
- [Documentation index](docs/README.md)
- [Hermes compatibility contract](docs/product/hermes-compatibility.md)
- [Gateway profile management](docs/product/gateway-profile-management.md)
- [Architecture decisions](docs/adr/README.md)
- [Roadmap](ROADMAP.md)
- [Alpha release runbook](docs/runbooks/release-alpha.md)
- [Changelog](CHANGELOG.md)

## License

Hermes Wing is available under the [MIT License](LICENSE).
