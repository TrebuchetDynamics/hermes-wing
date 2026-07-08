# Navivox

Navivox is a Flutter companion for trusted local, VPN, or self-hosted Hermes Agent sessions.

## Runtime

The app targets the Hermes Agent API server, commonly on port `8642`:

- `GET /health`
- `GET /v1/capabilities`
- `GET /v1/models`
- `GET /v1/skills`
- `GET /v1/toolsets`
- `GET /api/sessions`
- `POST /api/sessions`
- `PATCH /api/sessions/{session_id}`
- `DELETE /api/sessions/{session_id}`
- `GET /api/sessions/{session_id}/messages`
- `POST /api/sessions/{session_id}/fork`
- `POST /api/sessions/{session_id}/chat/stream`
- `POST /v1/runs`
- `GET /v1/runs/{run_id}/events`
- `POST /v1/runs/{run_id}/approval`
- `POST /v1/runs/{run_id}/stop`

## Run

```bash
flutter pub get
flutter run -d <device-id>
```

Hermes endpoint hints:

- Desktop on same host: `http://127.0.0.1:8642`
- Android emulator to host: `http://10.0.2.2:8642`
- Physical Android on Tailscale/LAN/VPN: `http://<hermes-host>:8642`

## Verify

```bash
flutter analyze
flutter test --concurrency=1
flutter build web --release -t lib/main_e2e.dart
npm run web:e2e
```
