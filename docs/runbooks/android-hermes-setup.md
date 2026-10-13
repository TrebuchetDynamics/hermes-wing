# Android Hermes setup

Wing connects directly to Hermes Agent. Prepare the unmodified Agent using its
[official documentation](https://hermes-agent.nousresearch.com/docs/), not a Wing
host-management installer. Wing does not install, restart or reconfigure a host.

Choose **Connect via SSH**, **Connect to Remote Hermes**, or **Use this phone
(Termux)**, in that order. SSH verifies the host fingerprint; Remote retains
HTTPS and VPN choices. Enter the Agent credential in its separate masked field,
never a URL, shared text, clipboard or QR. Loopback on the phone means the phone,
not the remote host. Non-local HTTP requires explicit consent within an
authenticated encrypted VPN or isolated trusted LAN.

For same-phone preparation use the [manual Termux guide](android-termux-local-agent.md).
Termux and Wing are separate sandboxes; background operation remains unqualified.
No external-command access, management service or pairing bootstrap is offered.

Saved connections retain exact Agent identities and credentials. Missing credentials
require direct reauthentication. Old handoffs are discarded with direct-connection
guidance; Back/Cancel preserves the caller, and reconnect never replays mutations.

See [first connection and recovery](../getting-started.md#direct-agent-connection).
Deterministic fixtures and Chromium do not qualify physical Android, live SSH,
Agent authentication, provider inference or process survival.
