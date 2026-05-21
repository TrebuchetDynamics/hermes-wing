# Navivox App

Navivox is an Android-first Flutter app for talking to local or self-hosted Gormes agents.

It is the mobile operator console for a Gormes agent server: connect to a trusted gateway, chat with profile contacts, send text or device-transcribed voice turns, and watch assistant responses, tool activity, approvals, and recovery states stream back in a phone-friendly UI.

Navivox is intentionally not a generic server administration panel or a telephony suite. The first product loop is simple: connect to Gormes, prove the gateway is ready, and talk to an agent.

## Relationship To Gormes

- **Gormes** is the Go-native agent runtime and gateway.
- **Navivox** is the Flutter app that presents the operator experience on Android and other Flutter targets.

Gormes owns agents, sessions, tools, provider calls, secrets, config, and server-side policy. Navivox owns setup, chat, voice capture, streaming UI, tool cards, safe config presentation, and local recovery flows.

Gormes repository: <https://github.com/TrebuchetDynamics/gormes-agent>

## Status

Planning and early implementation.

Current focus:

1. Connect to a Gormes Navivox gateway with a base URL and optional token.
2. Verify `/healthz` and `/v1/navivox/status`.
3. Open the Navivox event stream.
4. Send the first text or device-transcribed voice turn.
5. Render assistant, system, tool, approval, and connection-state UI clearly.

## Gateway Surface

Navivox expects a Gormes host exposing the Navivox channel:

- `GET /healthz` — basic readiness
- `GET /v1/navivox/status` — authenticated channel readiness
- `GET /v1/navivox/sessions` — session listing
- `POST /v1/navivox/turn` — submit a user turn
- `WS /v1/navivox/stream` — stream session and assistant events

On the host side, `gormes navivox connect-info` prints reachable base URLs for setup.

## Repository Layout

```text
.
├── app/                         # Flutter app package
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

## Development

Prerequisites:

- Flutter SDK
- A Gormes gateway with the Navivox channel enabled for full connect-and-talk testing

Run checks from the Flutter package:

```bash
cd app
flutter pub get
flutter test
```

Run the app:

```bash
cd app
flutter run
```

## Security And Product Boundaries

Navivox is built for trusted local or self-hosted Gormes deployments.

Important boundaries:

- The Navivox channel is disabled by default on the Gormes side.
- Local mode should stay loopback by default.
- Public exposure requires explicit server-side confirmation.
- Tokens must not be printed in screenshots, logs, route URLs, or deep links.
- The app should not directly edit local Gormes config files.
- Raw tool arguments, stdout, secrets, and full logs should not be primary UI.

## Documentation

Start with:

- `CONTEXT.md`
- `navivox-prd.md`
- `navivox-architecture.md`
- `navivox-testing-plan.md`
- `navivox-ui-design.md`

## License

Not specified yet.
