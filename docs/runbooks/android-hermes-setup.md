# Android Hermes setup

1. Start Hermes Agent API server with an API key on an Android-reachable trusted
   VPN or isolated LAN address (normally port `8642`).
2. Build/install Wing Link:

   ```bash
   ./install-wing-link.sh
   ```

3. Pair both direct Hermes and Wing Link. This installs, starts, and verifies
   the persistent per-user service; no separate `serve` terminal is required:

   ```bash
   WING_HERMES_URL=http://<trusted-vpn-ip>:8642 \
   WING_LINK_URL=http://<trusted-vpn-ip>:8654 wing-link pair
   ```

   Open the generated `wing://connect` link or scan its QR. Review the label,
   direct Hermes origin, access, and plain-HTTP warning, then confirm. The link
   contains only a short-lived single-use code. The exchange issues separate
   Hermes and Wing Link credentials; Wing acknowledges the pending control
   credential before storing it.

4. Confirm direct Hermes `/health` and `/v1/capabilities` load. Confirm Wing Link
   `/healthz` is reachable and the Agents screen lists all local profiles.
5. Verify local profile create/clone, stable-ID rename, and typed-confirmation
   delete. Persona/SOUL editing is not a Wing Link topology operation. Chat for
   local-only profiles remains disabled unless Hermes itself advertises usable
   profile context.
6. Prefer HTTPS outside a trusted VPN/LAN. Plain HTTP with credentials requires
   explicit confirmation and can expose traffic on an untrusted network.
