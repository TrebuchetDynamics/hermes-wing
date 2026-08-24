# Hermes Wing

<p align="center">
  <img src="./assets/readme/hero.svg" width="100%" alt="Hermes Wing running a Hermes Agent session across phone and desktop">
</p>

<p align="center">
  <a href="https://trebuchetdynamics.github.io/hermes-wing/app/"><strong>Try the web alpha</strong></a>
  ·
  <a href="#build-the-alpha-from-source"><strong>Build Android from source</strong></a>
  ·
  <a href="docs/README.md"><strong>Read the documentation</strong></a>
</p>

<p align="center">
  <a href="https://github.com/TrebuchetDynamics/hermes-wing/actions/workflows/hermes-platform-smoke.yml"><img alt="Hermes platform smoke" src="https://github.com/TrebuchetDynamics/hermes-wing/actions/workflows/hermes-platform-smoke.yml/badge.svg"></a>
  <a href="#project-status"><img alt="Status: alpha" src="https://img.shields.io/badge/status-alpha-f59e0b"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-3b82f6"></a>
</p>

## Control Hermes Agent from your phone

Hermes Wing is an independent, Android-first Flutter client for staying attached
to [Hermes Agent](https://github.com/NousResearch/hermes-agent) away from your
desk. Continue conversations, follow tool activity, answer approval requests, and
switch between trusted Hermes gateways from one app.

Start a long task on your workstation, step away, and keep control from your
phone. Wing is the interface; Hermes remains the source of truth for sessions,
tools, approvals, profiles, and configuration.

> [!NOTE]
> Hermes Wing is alpha software. Android is the best-tested client today. Signed
> packages and app-store releases are not available yet.

<p align="center">
  <picture>
    <source media="(max-width: 600px)" srcset="./assets/readme/showcase-mobile.png">
    <img src="./assets/readme/showcase.png" width="100%" alt="Hermes Wing showing a live run, tool activity, and an approval request on desktop and Android">
  </picture>
</p>

<p align="center"><sub>A Hermes run on desktop and an approval request in the mobile layout.</sub></p>

## What works today

- **Stay with long-running work.** Follow streaming replies, Markdown, reasoning,
  tool activity, and token usage while moving between sessions.
- **Intervene when it matters.** Review tool requests, approve once or for the
  session, deny them, retry failed work, or stop the active run.
- **Reach multiple agents.** Save trusted Hermes gateways, browse session history,
  and switch between profiles without moving agent state onto the device.
- **Talk naturally.** Dictate messages and optionally hear replies on supported
  Android devices. Voice remains experimental and device-dependent.
- **Use the same client elsewhere.** Web and Linux builds cover the text-first
  experience; Windows, macOS, and iOS are earlier platform targets.

Hermes Agent is a self-hosted AI agent with tools, persistent sessions, profiles,
and messaging gateways. Wing adds a dedicated visual client for conversations,
run activity, approvals, capability-gated administration, and voice. See the
[official Hermes Agent documentation](https://hermes-agent.nousresearch.com/docs/)
for Agent installation, providers, models, profiles, and gateway configuration.

## Quick start

The shortest supported path uses a Linux host with a working systemd user
session. Before starting, have:

- Git, `curl`, and Go 1.26 or newer on the host;
- network access for the Hermes Agent installation;
- an existing Hermes provider configuration or the credential needed to create
  one with `hermes setup`; and
- Hermes Wing open on the phone, browser, or desktop you want to connect.

One paste builds Wing Link from the current checkout, installs or adopts the
pinned Hermes Agent build, prepares API access, and starts the Hermes gateway:

```bash
git clone --depth 1 https://github.com/TrebuchetDynamics/hermes-wing.git
cd hermes-wing
./install-wing-link.sh --build --setup
export PATH="$HOME/.local/bin:$PATH"
```

Then complete Hermes's provider and model wizard:

```bash
hermes setup
```

Check the host before pairing:

```bash
~/.local/bin/wing-link inspect
curl --fail http://127.0.0.1:8642/health
```

Finally, open Hermes Wing and choose **Connect to Hermes**. A client on the same
host can use the loopback endpoint. For a phone or another computer, loopback
points back to that device, not to the Hermes host; follow the
[trusted-VPN pairing path](#pair-a-phone-or-another-computer) instead.

The installer is safe to run again. It validates Wing Link before installation
and adopts a supported Hermes installation instead of replacing its home,
profiles, or credentials. If host setup fails, Wing Link stays installed so
`~/.local/bin/wing-link inspect` can explain what needs attention.

> [!IMPORTANT]
> `--setup` is currently qualified only on Linux hosts with a systemd user
> session. The installer can place the Android ARM64 PIE binary in Termux, but
> guided Termux Hermes hosting is not yet qualified. For Android today, run
> Hermes on Linux and pair the phone.

## Install or try Hermes Wing

### Web alpha

[Open the web alpha](https://trebuchetdynamics.github.io/hermes-wing/app/) to
explore the current interface. To connect it to your own Hermes host, that host
must be reachable from the browser and configured for the web origin.

### Build the alpha from source

You need Flutter 3.44.2, the SDK for your target platform, and a reachable Hermes
Agent API endpoint.

```bash
git clone https://github.com/TrebuchetDynamics/hermes-wing.git
cd hermes-wing
flutter pub get
flutter devices
flutter run -d <device-id>
```

This starts a development build. For a local release-mode APK:

```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Without a complete release-signing configuration, Gradle deliberately falls
back to the debug signing key. That APK is for local testing only; do not
redistribute it. See the
[Android release handoff](docs/runbooks/android/release-handoff.md) for
trusted-tester builds, signing boundaries, and verification.

When Wing opens, choose **Connect to Hermes**. Prefer the Wing Link pairing flow
below because it imports the verified profile bundle and Wing Link management.
Entering an API URL and token manually is a one-profile fallback only; it does not
import Wing Link or other Hermes profiles. For a new host, use the setup path below.

Common development endpoints:

| Hermes location            | Endpoint                        |
| -------------------------- | ------------------------------- |
| Same desktop               | `http://127.0.0.1:8642`         |
| Host from Android emulator | `http://10.0.2.2:8642`          |
| Private LAN or VPN         | `http://<trusted-host-ip>:8642` |
| Remote HTTPS host          | `https://<your-hermes-host>`    |

Hermes Agent data-plane exposure remains a separate operator decision. Wing Link
itself permits HTTP only on loopback; non-loopback Wing Link uses TLS 1.3 and a
reviewed host fingerprint. Browser builds require normally trusted HTTPS.

### Pair a phone or another computer

[Wing Link](docs/product/wing-link.md) is the authenticated remote management API
that runs beside Hermes Agent. It can install or adopt the pinned Agent build,
prepare authentication, control the gateway, and create a short-lived pairing QR
code. It binds loopback plus a selected or automatically discovered local
private-LAN/Tailscale interface, using HTTP on loopback and TLS 1.3 with the
persistent Wing Link host identity everywhere else.

The source path needs Git, `curl`, Go 1.26 or newer, and network access.
Persistent Wing Link service management is currently implemented for Linux with
a per-user systemd service.

```bash
git clone --depth 1 https://github.com/TrebuchetDynamics/hermes-wing.git
cd hermes-wing
./install-wing-link.sh --build --setup
export PATH="$HOME/.local/bin:$PATH"
hermes setup
```

The installer defaults to `~/.local/bin`. `--build` builds the current checkout;
`--setup` then runs that installed Wing Link binary to install or adopt Hermes,
prepare API access, and start the local runtime. `hermes setup` remains the
authoritative wizard for provider, model, tools, and messaging configuration.
Today, Wing Link's Agent-domain compatibility surface is fixed profile
list/create/rename/delete plus transactional new-profile setup for an allowlisted
provider, bounded model string, and optional write-only provider credential. The special
`omniroute` provider is a fixed, keyless local adapter: it maps only to Hermes'
`custom` provider at `http://127.0.0.1:20128/v1`; enter an OmniRoute model such as
`auto/best-coding` and leave the credential field empty. It does not expose a
caller-selected base URL. General provider management, all existing-profile
provider or credential edits, and per-profile Hermes Project creation remain
unshipped. After Hermes is ready, pair the phone.

`wing-link setup` deliberately binds the Hermes Agent API to loopback. Exposing
Wing Link does **not** expose the direct Agent data plane. Before remote Android
pairing, make the Agent listener reachable on the same trusted VPN address, then
restart and verify it:

```bash
hermes config set --force platforms.api_server.extra.host <trusted-vpn-ip>
hermes gateway restart
curl --fail http://<trusted-vpn-ip>:8642/health
```

Do not bind the Agent API to a public interface. With both services reachable on
the trusted VPN address:

```bash
WING_HERMES_URL=http://<trusted-host-ip>:8642 \
WING_LINK_URL=https://<trusted-host-ip>:8654 \
~/.local/bin/wing-link pair --remote
```

Remote Wing Link pairing uses TLS 1.3 and the persistent host identity. Plaintext
Wing Link pairing is loopback-only.

For remote pairing, open Wing on Android, choose **Connect to Hermes → Scan QR
code**, and scan the displayed QR. The broker uses a self-signed identity that
native Wing verifies with the reviewed SPKI pin; browsers cannot validate that
pin. If a pairing link is already in a message, use Android **Share → Hermes
Wing**. The ordinary `/open` helper is loopback-only for same-host clients.

Review the host, access, and profile count in Hermes Wing, then confirm. The
pairing code expires after five minutes and contains no bearer credential;
exchange is idempotent until acknowledgment. Entering a Hermes API URL and token
manually is explicitly a one-profile fallback; it does not import the Wing Link
connection or the host's other Hermes profiles.

See [Android Hermes setup](docs/runbooks/android-hermes-setup.md) for VPN routing,
firewalls, service management, and recovery.

## Troubleshooting first connection

### `wing-link` is not found

The installer defaults to `~/.local/bin`. Run it by its full path or add that
directory to your shell `PATH`:

```bash
~/.local/bin/wing-link inspect
```

### The phone cannot reach `127.0.0.1`

Loopback always means the device running the client. Keep Hermes bound to
loopback for same-host use. For a phone, expose the Agent API only on a trusted
encrypted VPN address or through HTTPS, verify `/health`, and create a remote
pairing handoff as shown above. Do not bind it to a public interface.

### Hermes is healthy but Wing Link is unavailable

Check the managed user service, then restart only Wing Link if necessary:

```bash
~/.local/bin/wing-link status
~/.local/bin/wing-link restart
```

Wing Link and Hermes Agent are separate services. Restarting Wing Link does not
restart the Agent gateway; use `hermes gateway restart` only when the Agent
listener or configuration changed.

### The web alpha opens but cannot connect

The browser must be able to reach the Hermes API directly, and the Agent must
allow the exact web origin through its CORS configuration. A successful page
load proves only that the client loaded—not that your private Hermes endpoint is
reachable or authorized.

For bounded host diagnostics that do not print credentials or host paths, run:

```bash
~/.local/bin/wing-link inspect --json
```

The [Android setup runbook](docs/runbooks/android-hermes-setup.md) covers VPN
routing, firewall checks, profile multiplexing, and recovery in more detail.

## The three pieces

- **Hermes Wing** is the Flutter client on Android, web, and desktop.
- **Wing Link** is the remote management API on the Agent host for installation,
  pairing, service lifecycle, health, diagnostics, and the shipped fixed profile
  adapter, including bounded new-profile provider setup. Approved-directory and
  general provider operations are planned. It is not a general CLI or file bridge.
- **Hermes Agent** owns the agent runtime and its sessions, profiles, tools,
  providers, approvals, and configuration.

Wing connects directly to the Hermes HTTP(S) API and SSE event stream for chat
and Agent state, and separately to Wing Link for host management. It does not
keep a second copy of Agent state. The
[compatibility contract](docs/product/hermes-compatibility.md) documents the API,
permissions, and version behavior.

## Security

Wing stores credentials through platform secure storage, never puts bearer
credentials in pairing QR codes, and does not replay administrative changes after
a reconnect. New-profile provider credentials are write-only and travel to the
Hermes CLI through stdin; existing-profile credential edits remain blocked. The
planned Wing Link folder picker returns only child folders under locally approved
roots, never file entries. Use HTTPS or a trusted encrypted VPN for remote access.

Read [SECURITY.md](SECURITY.md) and the
[threat model](docs/security/threat-model.md) before exposing Hermes beyond a
private network. Hermes Wing has not received an independent security audit.

## Project status

| Platform | Current state                                                        |
| -------- | -------------------------------------------------------------------- |
| Android  | Experimental alpha and the best-tested runtime target.               |
| Web      | Public text-first alpha with release builds and browser smoke tests. |
| Linux    | Text-first alpha with release builds and native shell checks.        |
| Windows  | Build-tested; no supported package.                                  |
| iOS      | Simulator build-tested.                                              |
| macOS    | Build-tested; no supported package.                                  |

There are no signed packages, store releases, automatic updates, or supported
release line yet. Compilation on Windows, iOS, and macOS does not establish
runtime support. Physical microphone quality, echo cancellation, and barge-in
still require device testing.

## Contributing and documentation

The repository contains a Flutter client and a Go-based Wing Link helper. Start
with [CONTRIBUTING.md](CONTRIBUTING.md) for the repository map, fixture workflow,
required checks, and current contribution guidance.

- [Documentation index](docs/README.md)
- [Android setup](docs/runbooks/android-hermes-setup.md)
- [Hermes compatibility](docs/product/hermes-compatibility.md)
- [Wing Link remote management](docs/product/wing-link.md)
- [Wing Link implementation plan](docs/plans/wing-link-remote-management.md)
- [Official Hermes Agent documentation](https://hermes-agent.nousresearch.com/docs/)
- [Architecture decisions](docs/adr/README.md)
- [Roadmap](ROADMAP.md)
- [Changelog](CHANGELOG.md)

Hermes Wing takes inspiration from
[Hermes Desktop](https://github.com/fathah/hermes-desktop), particularly its
clear local and remote setup and visual product tour.

## License

Hermes Wing is available under the [MIT License](LICENSE).
