# Android Hermes setup

This runbook pairs Android with a remote Linux Hermes host that has a functioning
systemd user session. For the same-phone Tier 2 candidate, use the separate
[Android/Termux local Agent runbook](android-termux-local-agent.md).

## Before you start

Have Git, `curl`, Go 1.26 or newer, network access, a trusted encrypted VPN, and
Hermes Wing on the Android device. Clone the repository on the Linux host and
enter its root directory:

```bash
git clone --depth 1 https://github.com/TrebuchetDynamics/hermes-wing.git
cd hermes-wing
```

1. Install Wing Link and prepare Hermes on the Linux host. Setup starts the
   gateway only if needed and leaves an already-running gateway undisturbed:

   ```bash
   ./install-wing-link.sh
   export PATH="$HOME/.local/bin:$PATH"
   ```

2. Complete Hermes configuration. Wing Link has installed or adopted the runtime
   and prepared API access; Hermes owns provider, model, tools, and messaging setup:

   ```bash
   hermes setup
   ```

3. `wing-link setup` initially binds the Hermes Agent API to `127.0.0.1`. Wing
   Link's remote listener does not forward the Agent API. With Tailscale active,
   bare pairing safely detects the local Tailscale address, binds Hermes to it,
   restarts the gateway, and continues automatically:

   ```bash
   wing-link pair --label "My Android device"
   ```

   The command prints the handoff and stays in the foreground until Wing
   confirms it. Leave this terminal open while you paste or scan the handoff;
   press `Ctrl-C` only to cancel and create a new one.

   Automatic exposure is limited to a locally detected Tailscale address. Never
   bind the Agent API to a public interface. For another encrypted VPN or trusted
   HTTPS reverse proxy, bind Hermes explicitly and set `WING_HERMES_URL` and
   `WING_LINK_URL` to its phone-reachable origins before pairing.

4. The pairing command installs, starts, and verifies the persistent per-user
   Wing Link service; no separate `serve` terminal is required.

   The default command prints both a pasteable handoff line and a QR. In Wing choose
   **Paste pairing link** and paste it. To scan from another screen instead, run:

   ```bash
   wing-link pair --qr --label "My Android device"
   ```

   The default link and QR are both five-minute, single-use handoffs, not bearer
   credentials; do not persist or publish them. Native Wing verifies the
   self-signed broker with the reviewed SPKI
   pin; a browser cannot do so. If a pairing link is already in a message, use
   Android **Share → Hermes Wing**. The ordinary `/open` helper is loopback-only
   for same-host clients.

   Review the host, access,
   profile count, protocol generation, and SHA-256 host fingerprint in Wing, then
   confirm. A changed fingerprint requires a new explicit pairing review. The handoff
   contains only a short-lived code and no bearer credential. Exchange is
   idempotent until acknowledgment and issues separate Hermes credentials plus a
   pending Wing Link credential. Wing first stores the endpoint bundle with that
   pending marker, acknowledges it, then persists the bundle without the marker.
   Wing Link persists its server-side control credential only after acknowledgment.
   Entering a Hermes API URL and token manually is a one-profile fallback only; it
   does not import Wing Link or other Hermes profiles.

5. Confirm direct Hermes `/health` and `/v1/capabilities` load. Confirm Wing Link
   `/healthz` is reachable and the Profiles screen lists the paired local profiles.
   In multiplex mode each named profile uses `/p/<profile>/...` and its own
   `API_SERVER_KEY`; the default key must not authenticate a named prefix.
6. Verify local profile create/clone, rename, and typed-confirmation delete through
   Wing Link's fixed Hermes CLI adapter. A create request may also set a
   description, allowlisted provider, bounded model string, and optional write-only
   credential;
   setup failure rolls back that new profile. Existing-profile provider or
   credential edits are not shipped. A rename changes the Agent-local profile
   name; Wing's saved gateway identity remains endpoint-scoped. Persona,
   directory, and Hermes Project administration remain planned Wing Link
   operations.
7. The planned repository flow is profile → approved directory → per-profile
   Hermes Project. Do not expose arbitrary host paths or use `profile use` or
   `project use` as hidden global state.
8. Wing Link uses HTTP only on loopback and TLS 1.3 remotely. Native Android Wing
   verifies the reviewed SPKI pin. Web Wing requires normally trusted HTTPS.
9. Install/update, provider-secret writes, and destructive profile actions pause
   for local host approval. Review them with `wing-link approvals list`, then use
   `wing-link approvals approve <id>` or `reject <id>`; never approve from remote UI.

## Recovery checks

Run these on the Linux host; they do not require exposing credentials:

```bash
~/.local/bin/wing-link inspect
~/.local/bin/wing-link status
curl --fail http://127.0.0.1:8642/health
```

- If `wing-link` is not found, use the full `~/.local/bin/wing-link` path.
- If local Agent health works but the phone cannot connect, verify the trusted
  VPN address with `curl` from another device. `127.0.0.1` on the phone is the
  phone itself.
- If Wing Link is stopped, use `wing-link restart`. This does not restart Hermes
  Agent. Use `hermes gateway restart` only after changing the Agent listener or
  Agent configuration.
- Use `wing-link devices list` to inspect safe local trust metadata and
  `wing-link devices revoke <device-id>` for a stolen device. Revoke-all is a
  local recovery action and does not delete Agent profiles or data.
- If pairing expired, create a new handoff. Never copy a bearer credential into
  a QR code, URL, issue, or diagnostic log.
- A reinstall that preserves the complete owner-only Wing Link state preserves the
  TLS fingerprint. Upgrading a pre-hardening state that has only the legacy
  Ed25519 key generates the persistent Android-compatible TLS key once and therefore
  requires explicit re-pairing; it must never be silently accepted as the old pin.
  If state or either host key is lost or intentionally rotated, every
  pinned client must fail closed. Review the replacement fingerprint at the host,
  revoke obsolete device entries, and complete a new explicit pairing flow; never
  accept an identity change as an automatic reconnect.
- If a named profile fails while the default profile works, verify that the named
  profile has its own API key and that the client uses `/p/<profile>/...`.
