# Navivox App

Navivox is an Android-first Flutter app for talking to local or self-hosted Gormes agents.

It is the mobile operator console for a Gormes agent server: connect to a trusted gateway, chat with profile contacts, send text or device-transcribed voice turns, and watch assistant responses, tool activity, approvals, and recovery states stream back in a phone-friendly UI.

Navivox is intentionally not a generic server administration panel or a telephony suite. The first product loop is simple: connect to Gormes, prove the gateway is ready, talk to an agent, and inspect its memory.

## Relationship To Gormes

- **Gormes** is the Go-native agent runtime and gateway.
- **Navivox** is the Flutter app that presents the operator experience on Android and other Flutter targets.

Gormes owns agents, sessions, tools, provider calls, secrets, config, Goncho memory, and server-side policy. Navivox owns setup, chat, voice capture, streaming UI, tool cards, memory visualization, safe config presentation, and local recovery flows.

Gormes repository: <https://github.com/TrebuchetDynamics/gormes-agent>

## Status

Planning and early implementation.

Current focus:

1. Connect to a trusted Gormes Navivox gateway.
2. Send text or device-transcribed voice turns.
3. Render assistant, tool, approval, connection, and memory-state UI clearly.

## Screenshots

The screenshots below are generated from real Flutter widgets and checked by the test suite.

![Setup screen](docs/screenshots/setup.png)

![Chat screen](docs/screenshots/chat.png)

## Real-World Usage

Navivox is for mobile agent operation: hands-free chat, project briefings, incident checks, voice task capture, agent switching, and screen-reader-friendly control away from a terminal.

## Goncho Memory Console

Navivox makes Gormes memory inspectable without becoming a raw database browser. It should show memory health, counts, search results, provenance, and safe management actions such as pin, archive, correction, or mark stale.

The app reads memory through authenticated, profile-scoped Gormes APIs. It must not open SQLite directly.

## Gateway Surface

Navivox expects a Gormes host exposing the Navivox channel:

- `GET /healthz` — basic readiness
- `GET /v1/navivox/status` — authenticated channel readiness
- `GET /v1/navivox/memory/overview` — authenticated Goncho memory health and safe count summary
- `GET /v1/navivox/sessions` — session listing
- `POST /v1/navivox/turn` — submit a user turn
- `WS /v1/navivox/stream` — stream session and assistant events

On the host side, `gormes navivox connect-info` prints reachable base URLs for setup.

## Repository Layout

```text
.
├── lib/                         # Flutter app source
├── test/                        # Widget, unit, and tooling tests
├── integration_test/            # Connect-and-talk integration tests
├── web/                         # Flutter web shell
├── linux/                       # Flutter Linux runner
├── docs/screenshots/            # README screenshots generated from widgets
├── CONTEXT.md                   # Shared product language
├── navivox-architecture.md      # Architecture notes
├── navivox-chat-ui-research.md  # Chat UI research notes
├── navivox-data-model.md        # Data model notes
├── navivox-decision-record.md   # Product and technical decisions
├── navivox-library-research.md  # Flutter package research
├── navivox-prd.md               # Product requirements
├── navivox-routes.md            # App route plan
├── navivox-testing-plan.md      # Test strategy
└── navivox-ui-design.md         # UI design notes
```

## Install And Run

Prerequisites:

- Flutter SDK on `PATH`
- Android SDK or another Flutter target for local app runs
- A trusted Gormes gateway with the Navivox channel enabled for full connect-and-talk testing

Install dependencies from the repository root:

```bash
flutter pub get
```

Run the local verification gate:

```bash
flutter analyze
flutter test
```

Find available Flutter targets:

```bash
flutter devices
```

Run the app from the repository root, replacing `<device-id>` with one of the listed targets:

```bash
flutter run -d <device-id>
```

Android target notes:

- Android emulator: use `http://10.0.2.2:<port>` when the Gormes gateway is running on the host machine.
- A physical Android device cannot reach the host through `127.0.0.1`; use the host LAN, VPN, or Tailscale URL printed by `gormes navivox connect-info`.
- Keep the pairing token inside Navivox only; never paste it into issue reports, logs, screenshots, or chat transcripts.

## Connected Smoke Test

Use this only with a trusted local or self-hosted Gormes host:

1. Start or select a Gormes host with the Navivox channel enabled.
2. On the host, print the setup values:

   ```bash
   gormes navivox connect-info
   ```

3. Confirm the gateway answers `GET /healthz` and authenticated `GET /v1/navivox/status`.
4. Copy the reachable base URL into the Navivox setup screen.
5. If `connect-info` prints a token, paste it into Navivox only. Do not paste tokens into issues, logs, or screenshots.
6. Send a short text turn and confirm the app shows an assistant response, tool activity, or a clear connection recovery state.

## Troubleshooting

- If Flutter is missing, run `flutter doctor` and fix the reported SDK or platform setup before running Navivox.
- If `flutter devices` shows `No supported devices found`, start an emulator, connect an Android device, or choose another Flutter target that appears in the device list.
- If `flutter run -d <device-id>` fails after a layout move, run `flutter clean` and `flutter pub get` from the repository root. Do not delete source files while clearing generated state.
- If the setup screen shows `Connection refused`, confirm the Gormes host is running, reachable from the device, and listening on the base URL from `gormes navivox connect-info`.
- If the gateway returns `401` or `403`, refresh the setup values from `gormes navivox connect-info` and paste the token into Navivox only.

## Security And Product Boundaries

Navivox is built for trusted local or self-hosted Gormes deployments.

Important boundaries:

- Navivox is for trusted local or self-hosted Gormes deployments.
- Public exposure requires explicit server-side confirmation.
- Tokens, secrets, raw tool output, and full logs must not be primary UI.
- Config and Goncho memory are managed through authenticated Gormes APIs, not direct file or SQLite edits.
- Memory management should prefer pin/archive/mark-stale/correction flows over destructive deletion.

## Documentation

Start with:

- `CONTEXT.md`
- `navivox-prd.md`
- `navivox-architecture.md`
- `navivox-testing-plan.md`
- `navivox-ui-design.md`

## License

MIT License. See [LICENSE](LICENSE).
