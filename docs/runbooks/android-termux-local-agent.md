# Android/Termux direct Hermes Agent setup

Status: manual guidance and direct connection; automatic installation unavailable.

The Android welcome keeps SSH first, Remote second and **Use this phone (Termux)**
third. The phone choice now uses the existing Android Local preparation and direct
Agent connection form. It neither installs a management service nor returns to
pairing. Existing saved records and independent secure Agent credentials remain
unchanged. See [connection routes](../product/routes.md) and the
[retirement decision](../adr/product.md#complete-removal-including-legacy).

## Prepare this phone

1. Install or open Termux using its
   [official installation guide](https://github.com/termux/termux-app#installation).
2. Read the current
   [official Agent Termux documentation](https://hermes-agent.nousresearch.com/docs/getting-started/termux).
   Follow its current installation steps, package warnings and platform limits;
   installation guidance can change independently of Wing. Wing offers no tested
   fresh installer, copied bootstrap command or automatic fallback. Fresh
   installation and persistent background operation are not qualified by Wing.
   Debian/proot remains a separate, unqualified path.
3. If Agent is already installed, check `hermes --version` and `hermes doctor`
   yourself in Termux. Choose **Agent is installed — configure it**, or explicitly
   skip guidance if Agent is already running.

## Configure and start Agent

Run `hermes setup` yourself for provider/model configuration. Follow the
[official authenticated API documentation](https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server)
to enable the API and set a strong Agent API credential in Agent-owned
configuration. Keep the listener on `127.0.0.1:8642`; loopback still requires
Agent authentication. Do not put credentials in command arguments, URLs or the
clipboard. Run `hermes gateway` in the foreground and keep Termux open.

Wing cannot inspect Termux's files, configure or start Agent, or prove readiness
from completion of guidance. Android can suspend or stop the process; persistent
background operation is not qualified.

## Return to Wing

Choose **I started Agent — continue to connection** to reveal the existing
masked Agent token field for `http://127.0.0.1:8642`. Type the Agent API token,
not a provider key or dashboard token. **Add Hermes** explicitly checks the
connection and uses the existing secure persistence owner. Missing capability,
authentication denial and transport errors remain in that form; correct the
Agent setup or token and explicitly retry. Guide completion sends no message
and saves no credential. Back to guidance or cancel does not replay mutations.

The old bootstrap renderer and its copy/pairing controls are removed from this
entry. Legacy packaging metadata, installers, explicit handoff parsing and Linux
setup are separate retirement work, not a fallback for this phone flow.
[Past physical bootstrap evidence](../quality/termux-entrypoint-physical-2026-09-05.md)
is historical and does not qualify this replacement. Android-platform widget
fixtures do not prove physical installation, process survival or live Agent
authentication.
