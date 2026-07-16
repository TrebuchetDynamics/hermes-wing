# Android Hermes setup

1. Start Hermes Agent API server with an API key.
2. Bind it to a trusted Android-reachable HTTPS address or an address protected by Tailscale/VPN.
3. In Hermes Wing, open `/hermes` and enter the endpoint plus the API key. Plain HTTP with credentials requires explicit confirmation and can expose traffic outside a trusted encrypted or isolated network.
4. Confirm `/health` and `/v1/capabilities` load, then create a fresh session.
