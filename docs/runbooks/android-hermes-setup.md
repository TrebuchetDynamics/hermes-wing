# Android Hermes setup

This runbook pairs Android with a Linux Hermes host that has a functioning
systemd user session. Android/Termux Wing Link service hosting is not qualified.

1. Install Wing Link and prepare Hermes on the Linux host:

   ```bash
   ./install-wing-link.sh --build --setup
   ```

2. Complete Hermes configuration. Wing Link has installed or adopted the runtime
   and prepared API access; Hermes owns provider, model, tools, and messaging setup:

   ```bash
   hermes setup
   ```

3. `wing-link setup` binds the Hermes Agent API to `127.0.0.1`. Wing Link's remote
   listener does not forward the Agent API. Before pairing Android, bind the
   Agent API to the host's trusted VPN address, restart it, and verify direct
   reachability:

   ```bash
   hermes config set --force platforms.api_server.extra.host <trusted-vpn-ip>
   hermes gateway restart
   curl --fail http://<trusted-vpn-ip>:8642/health
   ```

   Never bind the Agent API to a public interface. Prefer a Tailscale or other
   encrypted VPN address; otherwise use a trusted HTTPS reverse proxy.

4. Pair both direct Hermes and Wing Link. This installs, starts, and verifies
   the persistent per-user service; no separate `serve` terminal is required:

   ```bash
   WING_HERMES_URL=http://<trusted-vpn-ip>:8642 \
   WING_LINK_URL=http://<trusted-vpn-ip>:8654 \
   WING_LINK_PAIRING_OVER_ENCRYPTED_VPN=1 \
   wing-link pair --remote
   ```

   Open the generated `wing://connect` link or scan its QR. Review the label,
   direct Hermes origin, access, and plain-HTTP warning, then confirm. The link
   contains only a short-lived code and no bearer credential. Exchange is
   idempotent until acknowledgment and issues separate
   Hermes and Wing Link credentials; Wing acknowledges the pending control
   credential before storing it.

5. Confirm direct Hermes `/health` and `/v1/capabilities` load. Confirm Wing Link
   `/healthz` is reachable and the Profiles screen lists the paired local profiles.
   In multiplex mode each named profile uses `/p/<profile>/...` and its own
   `API_SERVER_KEY`; the default key must not authenticate a named prefix.
6. Verify local profile create/clone, rename, and typed-confirmation delete through
   Wing Link's fixed Hermes CLI adapter. A rename changes the Agent-local profile
   name; Wing's saved gateway identity remains endpoint-scoped. Persona,
   provider, directory, and Hermes Project administration are planned Wing Link
   operations, not current behavior.
7. The planned repository flow is profile → approved directory → per-profile
   Hermes Project. Do not expose arbitrary host paths or use `profile use` or
   `project use` as hidden global state.
8. Prefer HTTPS outside a trusted VPN/LAN. Plain HTTP with credentials requires
   explicit confirmation and can expose traffic on an untrusted network.
