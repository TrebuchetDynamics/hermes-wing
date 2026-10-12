# Hermes Wing

Chat with your Hermes assistant, follow its tool activity, and approve or stop its
work—from your phone, browser, or desktop.

For Hermes users who want a visual app and are comfortable trying an early alpha.
Wing connects to your own **Hermes Agent**; it does not include a hosted assistant,
provider account, or model credits.

> [!NOTE]
> **Early alpha.** You can preview the interface now. Actual chat requires your own
> authenticated Agent and configured provider. Native clients require a source build;
> public signed distribution and automatic updates remain unqualified.

**[Try the web interface](https://trebuchetdynamics.github.io/hermes-wing/app/)** ·
**[Set up your first chat](docs/getting-started.md)**

<p align="center">
  <picture>
    <source media="(max-width: 600px)" srcset="./assets/readme/showcase-mobile.png">
    <img src="./assets/readme/showcase.png" width="100%" alt="Desktop chat with tool activity, alongside a phone screen showing a permission request.">
  </picture>
</p>

*Actual app screens with sample conversations and simulated responses—not live-provider test evidence.*

<a id="what-can-i-do-with-it"></a>

## Features

- **Chat and follow work.** Read streaming replies and see tool activity.
- **Approve or stop actions.** Review permission requests when Agent sends them,
  or stop the selected conversation's current task.
- **Keep assistant setups separate.** Choose an Agent-owned profile and resume its
  conversations without treating another profile as the same assistant.
- **Connect directly.** Use a reachable Agent endpoint; native SSH provides a
  separate connection option. Browser SSH is unsupported.

<a id="new-to-hermes-start-here"></a>

## What is Hermes Agent?

[Hermes Agent](https://github.com/NousResearch/hermes-agent) runs the assistant,
conversations, tools, and configuration. Wing is the app you use to interact with
it. Agent can act on files or run commands when you grant the relevant tools and
permissions; a visual client does not make those actions harmless.

<a id="what-do-i-need"></a>
<a id="what-do-i-need-for-the-android-setup-guide"></a>
<a id="get-the-client"></a>
<a id="getting-started"></a>
<a id="choose-your-next-step"></a>

## Quickstart

### Preview without an Agent

1. [Open the web alpha](https://trebuchetdynamics.github.io/hermes-wing/app/).
2. You should see **Welcome to Hermes Wing**. Choose **Connect to Remote Hermes**
   to inspect the connection form; no credential is needed just to view it.

**Success:** the welcome screen and connection form are visible. This previews the
interface, not a working assistant. The hosted preview can lag repository `main`.

### Connect your assistant

Before connecting, you need:

- A running, reachable Hermes Agent with a configured provider/model and its
  approved Agent access credential. Use [official Agent setup](https://hermes-agent.nousresearch.com/docs/).
- A trusted connection. Browser remote access requires trusted HTTPS and permitted
  CORS. A VPN is optional, not authentication. Never disable transport checks or
  expose Agent publicly just to make setup easier.
- Provider access you are willing to use. **Providers may charge and process your
  conversation data.** Running Agent yourself does not make every AI request local.

<a id="connect-your-agent"></a>
<a id="pair-a-phone-or-another-computer"></a>
<a id="your-first-conversation"></a>
<a id="your-first-chat"></a>
<a id="your-first-chat-on-android"></a>

## Your first chat

1. Open Wing's direct connection form. Use **Connect to Remote Hermes** for a
   reachable remote Agent, or **Add Hermes** when you already have a saved connection.
   Native Android also offers separate SSH and on-phone Termux entry; these do not
   establish that installation or authentication has succeeded.
2. Enter your Agent endpoint and its credential, then connect deliberately. This
   is an Agent credential, not your provider API key. Configure the provider in Agent.
3. Select your configured profile and conversation. Send:

   > Reply with one sentence introducing yourself. Do not use any tools.

**Success:** an assistant reply appears in that conversation. Saving credentials or
passing a connection probe alone does not prove generation works. There is no fixed
expected reply: its wording depends on your configured assistant and model.

Follow the [complete connection guide](docs/getting-started.md#direct-agent-connection)
for native Local/SSH setup, saved-connection repair, and authentication limits.

<a id="project-status"></a>
<a id="platforms-and-limits"></a>
<a id="current-support"></a>
<a id="availability"></a>

## Compatibility and limits

- **Android, web, and Linux are alpha paths.** Windows, macOS, and iOS have limited
  runtime qualification. Check the [feature/platform status](docs/product/routes.md)
  before relying on a particular operation.
- **Browser authentication is limited.** The direct flow uses an Agent access token;
  browser OAuth sign-in and browser SSH are unsupported.
- **On-phone hosting is not fully qualified.** See [Termux setup status](docs/getting-started.md#can-everything-run-on-the-phone-instead).
- **Voice, away-and-return recovery, and notifications are not blanket support
  claims.** Voice is experimental; background recovery and notification delivery
  still need the qualification described in the [roadmap](ROADMAP.md).
- **Desktop parity is a goal, not a completed claim.** Wing is an independent
  Flutter port guided by [official Hermes Desktop](https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop).
  [Reference and qualification details](docs/quality/official-desktop-reference.md)
  distinguish source comparisons, fixtures, and live/platform evidence.

<a id="build-the-alpha-from-source"></a>

## Build from source

For the browser client, install **Git and Flutter 3.44.2** and have a browser
available. Run:

```bash
git clone https://github.com/TrebuchetDynamics/hermes-wing.git
cd hermes-wing
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 18997
```

When Flutter prints that the app is being served, open
**http://127.0.0.1:18997** in your browser. The server is loopback-only; it is not
a deployment. These commands download source and dependencies, but do not install
Agent, configure a provider, or start an AI conversation. Press `q` in the terminal
to stop the development server.

For Android/Linux builds and platform prerequisites, use the
[build guide](docs/getting-started.md#build-and-open-the-client).
Contributors also use Node.js 22 for browser E2E tooling; see
[CONTRIBUTING.md](CONTRIBUTING.md) for setup and exact checks.

<a id="when-a-connection-needs-attention"></a>
<a id="need-help"></a>
<a id="if-you-get-stuck"></a>

## Help and documentation

- **Can't connect or get a reply?** Start with [troubleshooting](docs/getting-started.md#need-help).
- **Configuration:** use [Agent documentation](https://hermes-agent.nousresearch.com/docs/)
  for providers, models, and Agent tools; Wing exposes only supported operations.
- **Report a bug:** [open an issue](https://github.com/TrebuchetDynamics/hermes-wing/issues)
  with your platform, steps, and expected/actual behavior. Never attach credentials,
  private endpoints, or private conversations. See [security guidance](SECURITY.md).
- **Understand the design:** [technical design](docs/spec.md),
  [architecture decisions](docs/adr/README.md), and [all documentation](docs/README.md).
- **Follow or contribute:** [changelog](CHANGELOG.md), [roadmap](ROADMAP.md),
  [current work queue](TODO.md), and [contribution guide](CONTRIBUTING.md).

## License

[MIT](LICENSE). AI service access and credits are separate from the client license.
Hermes Wing is independent of Nous Research; Hermes Agent provides the runtime and
Hermes Desktop provides the product reference.
