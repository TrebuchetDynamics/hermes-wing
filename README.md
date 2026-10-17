<a href="assets/branding/README.md"><img src="assets/branding/wing-logo-256.png" width="80" height="80" alt="Hermes Wing logo"></a>

# Hermes Wing

Chat with your Hermes assistant, follow its tools, and approve or stop its work
from your phone, browser, or desktop. **Your Agent runs the work. Wing is the client.**

An independent Flutter port guided by
[official Hermes Desktop](https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop),
for Hermes users comfortable trying an early alpha—not a hosted assistant service.
Desktop parity is a goal, not a guarantee; no provider account or model credits are included.

**[Set up your first chat](docs/getting-started.md)** ·
[Preview the connection screen](https://trebuchetdynamics.github.io/hermes-wing/app/) ·
[Platform status](docs/getting-started.md#platform-evidence-and-limits)

> [!NOTE]
> **Early alpha.** Actual chat requires your own authenticated Agent and configured provider.
> Native clients require a source build; public signed distribution and automatic
> updates remain unqualified.

<p align="center">
  <picture>
    <source media="(max-width: 600px)" srcset="./assets/readme/showcase-mobile.png">
    <img src="./assets/readme/showcase.png" width="100%" alt="Simulated Wing interface: desktop tool activity beside a phone approval request. Not live-provider or cross-device testing.">
  </picture>
</p>

*DEMO DATA · SIMULATED SESSION. These existing captures illustrate the interface,
not live-provider testing or observed cross-device synchronization. They are an
older UI fixture, not proof of current Desktop parity or the planned Bot Chat experience.*

<a id="what-can-i-do-with-it"></a>
<a id="features"></a>

## Implemented features

- **Follow a conversation:** streaming replies and visible tool activity.
- **Stay in control:** review Agent permission requests or stop the selected task.
- **Keep contexts separate:** choose an Agent-owned profile and resume its conversations.
- **Connect directly:** use a reachable Agent endpoint or the native SSH option.
  Browser SSH is unsupported; native full-app SSH qualification remains incomplete.

These controls are tested with simulated Agent responses; we haven't verified the
whole live chat-to-approval-to-reconnect workflow. See [workflow evidence and limits](docs/quality/live-desktop-daily-workflow.md).
The [current roadmap](ROADMAP.md) prioritizes Android SSH, multi-session/profile chat,
canonical Bot Chats and touch-first polish. That priority is not a shipped-feature claim.

<a id="new-to-hermes-start-here"></a>

## What is Hermes Agent?

[Hermes Agent](https://github.com/NousResearch/hermes-agent) runs the assistant,
conversations, tools, and configuration. Wing connects to your own Agent; it does
not host one. Agent can act on files or run commands when you grant the relevant
tools and permissions—a visual client does not make those actions harmless.

<a id="what-do-i-need"></a>
<a id="what-do-i-need-for-the-android-setup-guide"></a>
<a id="get-the-client"></a>
<a id="getting-started"></a>
<a id="choose-your-next-step"></a>

## Quickstart

**Choose your starting point:** preview the UI below, build a native client, or
open the [web alpha](https://trebuchetdynamics.github.io/hermes-wing/app/) to connect an existing Agent.

<a id="preview-without-an-agent"></a>

### Preview the connection screen

[Open the web alpha](https://trebuchetdynamics.github.io/hermes-wing/app/) and choose
**Connect to Remote Hermes** from **Welcome to Hermes Wing**. No credential is
needed just to view the form. **Success:** the form is visible. This previews the
interface, not a working assistant. The hosted preview can lag repository `main`.

### Build a native client

Install Git, Flutter 3.44.2 and your target's development tools, then follow
[Build and open the client](docs/getting-started.md#build-and-open-the-client) for Android/Linux.
**Success:** Wing opens to its welcome screen. Building Wing does not prepare Agent,
authenticate a connection or prove generation. Check the guide's target prerequisites if it fails.

### Connect your assistant

First obtain and open Wing through the web alpha or native build above. Expect
**Welcome to Hermes Wing**, or Chat when a saved connection is already available.
Before connecting, you need:

- **An enabled, authenticated Hermes Agent HTTP API—not just a working CLI.**
  Follow the [Agent API Server guide](https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server)
  to enable the listener, set a strong Agent credential and check reachability.
  Local defaults use `127.0.0.1:8642`: loopback means Agent's machine, not your phone.
  Wing needs compatible `/v1/capabilities` session contracts, supported streaming
  and every required grant. A CLI, health check or OpenAI-compatible endpoint alone is insufficient.
- **A trusted route.** Native SSH forwarding can keep Agent on its host loopback;
  verify the SSH host fingerprint and supply the separate Agent credential.
  Direct remote access needs an administrator-approved secure endpoint; browsers
  also need trusted HTTPS and an explicit allowed Wing CORS origin. Do not open a
  public port, disable trust checks, or treat a VPN as authentication.
- **Provider access you are willing to use.** Providers may charge and process
  conversation data. Self-hosting Agent does not make every AI request local.

<a id="connect-your-agent"></a>
<a id="pair-a-phone-or-another-computer"></a>
<a id="your-first-conversation"></a>
<a id="your-first-chat"></a>
<a id="your-first-chat-on-android"></a>

## Your first chat

1. Open the direct form using **Connect to Remote Hermes**, or **Add Hermes** for
   an existing saved setup. Native Android also offers SSH and on-phone Termux;
   those entries do not prove installation or authentication succeeded.
2. Enter the Agent endpoint and its credential—not a provider API key—and connect
   deliberately. Configure the provider in Agent.
3. Select your configured profile and conversation. Send:

   > Reply with one sentence introducing yourself. Do not use any tools.

**Success:** an assistant reply appears in that conversation. Its wording depends
on your assistant/model. Saving credentials or passing a probe does not prove generation.
Use the [complete connection guide](docs/getting-started.md#direct-agent-connection)
for Local/SSH setup and saved-connection repair, or [recovery](docs/getting-started.md#need-help)
if there is no reply. Retry deliberately; never weaken authentication or certificates.
Then try the [optional repository summary](docs/getting-started.md#optional-repository-summary)
only with a deliberately granted demo Project and provider costs understood.

<a id="project-status"></a>
<a id="platforms-and-limits"></a>
<a id="current-support"></a>
<a id="availability"></a>

## Compatibility and limits

- **Android, web and Linux are alpha paths.** Windows, macOS and iOS have limited
  runtime qualification. Check [platform evidence and limits](docs/getting-started.md#platform-evidence-and-limits) per operation.
- **Browser authentication is limited:** Agent access-token flow only; browser OAuth and SSH are unsupported.
- **On-phone hosting is not fully qualified:** see [Termux setup status](docs/getting-started.md#can-everything-run-on-the-phone-instead).
- **Voice is experimental.** Away-and-return recovery and notification delivery still
  need named-platform qualification; no blanket support or completed Desktop parity is claimed.
  [Reference and qualification details](docs/quality/official-desktop-reference.md) separate source, fixture and live/platform evidence.

<a id="build-the-alpha-from-source"></a>

## Build from source

**Web is the recommended source-built alpha evaluation path**, not proof of Android
readiness. With Git, Flutter 3.44.2 and a browser installed:

```bash
git clone https://github.com/TrebuchetDynamics/hermes-wing.git
cd hermes-wing
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 18997
```

When Flutter reports the server is ready, open **http://127.0.0.1:18997**.
This downloads source/dependencies and serves Wing on loopback only—not a deployment,
Agent install, provider setup or AI conversation. Press `q` to stop the development server.
For Android/Linux prerequisites use the [build guide](docs/getting-started.md#build-and-open-the-client).
Contributors also use Node.js 22 for browser E2E tooling; see [CONTRIBUTING.md](CONTRIBUTING.md).

<a id="when-a-connection-needs-attention"></a>
<a id="need-help"></a>
<a id="if-you-get-stuck"></a>

## Help and documentation

**Credentials and trust:** native credentials use platform secure storage; support
varies by platform. Removing a saved connection does not revoke its server token.
Rotate/revoke compromised access through Agent-owned controls. See the
[threat model](docs/security/threat-model.md) and [security policy](SECURITY.md);
no independent security audit is claimed.

- **Get unstuck:** [troubleshooting](docs/getting-started.md#need-help).
- **Configure Agent:** [official docs](https://hermes-agent.nousresearch.com/docs/) for providers, models and tools; Wing exposes only supported operations.
- **Report a bug:** [issues](https://github.com/TrebuchetDynamics/hermes-wing/issues)—platform, steps and expected/actual behavior. Never attach credentials, private endpoints or conversations.
- **Explore:** [all documentation](docs/README.md), [technical design](docs/spec.md), [architecture decisions](docs/adr/README.md).
- **Contribute:** [guide](CONTRIBUTING.md), [changelog](CHANGELOG.md), [roadmap](ROADMAP.md), [work queue](TODO.md).

## License

[MIT](LICENSE). AI service access and credits are separate from the client license.
Wing is independent of Nous Research; Agent provides the runtime and Desktop the product reference.
