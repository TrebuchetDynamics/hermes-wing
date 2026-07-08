# Android Hermes setup

1. Start Hermes Agent API server with an API key.
2. Bind it to a trusted Android-reachable address such as Tailscale or LAN.
3. In Navivox, open `/hermes` and enter `http://<hermes-host>:8642` plus the API key.
4. Confirm `/health` and `/v1/capabilities` load, then create a fresh session.
