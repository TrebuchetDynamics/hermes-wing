<a href="assets/branding/README.md"><img src="assets/branding/wing-logo-256.png" width="80" height="80" alt="Hermes Wing logo"></a>

# Hermes Wing

Chat with your Hermes assistant, follow tool activity, and approve or stop its work
from your phone, browser, or desktop. **Your Agent runs the work. Wing is the client.**

An independent Flutter port guided by [official Hermes Desktop](https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop),
for Hermes users trying an early alpha. Desktop parity is a goal, not a guarantee; no hosted assistant, provider account or model credits are included.

**[Set up your first chat](docs/getting-started.md)** ·
[Preview the connection screen](https://trebuchetdynamics.github.io/hermes-wing/app/) ·
[Platform status](docs/getting-started.md#platform-evidence-and-limits)

> [!NOTE]
> **Early alpha.** Preview the interface without an Agent. Actual chat requires your own
> authenticated Agent and configured provider. Native clients require a source build;
> public signed distribution and automatic updates remain unqualified.

<p align="center">
  <picture>
    <source media="(max-width: 600px)" srcset="./assets/readme/showcase-mobile.png">
    <img src="./assets/readme/showcase.png" width="100%" alt="Simulated desktop tool activity and phone approval for a synthetic demo repository. Not live-provider or cross-device testing.">
  </picture>
</p>

*DEMO DATA · SIMULATED SESSION. Synthetic Agent and repository; not live-provider testing,
cross-device synchronization, Desktop parity proof or the planned Bot Chat experience.*

<a id="what-can-i-do-with-it"></a>
<a id="features"></a>

## What Wing does

- **Chat and follow work.** Read streaming replies and see tool activity.
- **Stay in control.** Review Agent permission requests or stop the selected task.
- **Keep contexts separate.** Choose Agent-owned profiles and resume their conversations.
- **Connect directly.** Use a reachable Agent endpoint or the native SSH option.
  Browser SSH is unsupported; native full-app SSH qualification remains incomplete.

These controls have simulated Agent-response tests; the complete live chat, approval and reconnect
workflow is not verified. See [workflow evidence and limits](docs/quality/live-desktop-daily-workflow.md).
The [current roadmap](ROADMAP.md) prioritizes Android SSH, multi-session/profile chat,
canonical Bot Chats and touch-first polish. That priority is not a shipped-feature claim.

<a id="new-to-hermes-start-here"></a>
<a id="what-is-hermes-agent"></a>

## What is Hermes Agent?

[Hermes Agent](https://github.com/NousResearch/hermes-agent) runs the assistant,
conversations, tools, and configuration; Wing connects to your own Agent.
Agent can access files or run commands when granted tools and permissions; review each request—a visual client does not make those actions harmless.

<a id="what-do-i-need"></a>
<a id="what-do-i-need-for-the-android-setup-guide"></a>
<a id="get-the-client"></a>
<a id="getting-started"></a>
<a id="choose-your-next-step"></a>

## Choose a path

<a id="quickstart"></a>
Preview the UI, connect an existing Agent, or build a native client below.
<a id="preview-without-an-agent"></a>

### Preview the connection screen

1. [Open the web alpha](https://trebuchetdynamics.github.io/hermes-wing/app/).
2. On **Welcome to Hermes Wing**, choose **Connect to Remote Hermes** to inspect
   the form. No Agent or credential is needed just to preview it.

**Success:** the welcome screen and form appear. This is an interface, not a working assistant; the hosted build can lag the source.

### Connect an existing Hermes Agent

<a id="connect-your-assistant"></a>
Open the [web alpha](https://trebuchetdynamics.github.io/hermes-wing/app/) or
[build a native client](docs/getting-started.md#build-and-open-the-client).
Expect Welcome, or Chat for a saved connection. Follow the [first-chat guide](docs/getting-started.md). You need:

- **An enabled, reachable, authenticated Hermes Agent HTTP API—not just a CLI.**
  Wing needs compatible `/v1/capabilities` contracts for session chat and streaming, plus required grants.
  A CLI, health check or OpenAI-compatible API alone is insufficient. Follow the
  [Agent API Server guide](https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server) to enable the listener,
  set a strong Agent credential and check reachability. Default `127.0.0.1:8642` means Agent's machine, not your phone.
- **A trusted route.** Native SSH can forward to Agent's host loopback; verify the host fingerprint
  and supply the separate Agent credential. Remote access needs an administrator-approved secure endpoint;
  browsers also require trusted HTTPS and an explicit allowed Wing CORS origin.
  Never expose a public port, disable trust, or treat a VPN as authentication.
- **A configured Agent profile/provider/model.** Providers may charge and process
  conversation data; self-hosting Agent does not make inference local.

Use the Agent credential in Wing, not a provider key. Start with the guide's no-tools prompt;
a reply—not a health check or saved credential—is success. Before sending a repository task,
complete that smoke and understand the cost and tool permissions.

### Build a native client

Install Git, Flutter 3.44.2 and target development tools. Follow
[Build and open the client](docs/getting-started.md#build-and-open-the-client) for Android/Linux prerequisites and recovery.
**Success:** Wing opens to its welcome screen. Continue with the existing-Agent path above; a build does not prepare Agent, authenticate a connection or prove generation.

<a id="connect-your-agent"></a>
<a id="pair-a-phone-or-another-computer"></a>
<a id="your-first-conversation"></a>
<a id="your-first-chat"></a>
<a id="your-first-chat-on-android"></a>

## Your first chat

1. Open Wing and choose a direct route, or **Add Hermes** for an existing saved setup.
   Android offers **Connect via SSH**, **Connect to Remote Hermes**, then **Use this phone (Termux)**.
   Desktop/web offer **Get Started**; Linux Local only checks directory metadata.
   The [guide](docs/getting-started.md#direct-agent-connection) explains each route; entries do not prove installation or authentication.
2. Enter the Agent endpoint and its credential, and connect deliberately. Configure
   provider access in Agent; those are separate credentials.
3. Select your configured profile and conversation. Send:

   > Reply with one sentence introducing yourself. Do not use any tools.

**Success:** a reply appears in that conversation; wording depends on your assistant/model.
A connection test or saved credential does not prove generation. Use [recovery](docs/getting-started.md#need-help)
if there is no reply. Retry deliberately; never weaken authentication or certificates.
The optional [repository summary](docs/getting-started.md#optional-repository-summary) comes later, with a deliberately granted demo Project and provider costs understood.

<a id="project-status"></a>
<a id="platforms-and-limits"></a>
<a id="current-support"></a>
<a id="availability"></a>

## Compatibility and limits

- **Android, web and Linux are alpha paths.** Windows, macOS and iOS have limited
  runtime qualification. See [platform evidence and limits](docs/getting-started.md#platform-evidence-and-limits) per operation.
- **Browser access is limited:** Agent access-token flow only; OAuth and SSH are unsupported.
  Trusted HTTPS and permitted CORS are required; native secure storage and host folders are unavailable.
- **On-phone hosting is not fully qualified:** see [Termux setup status](docs/getting-started.md#can-everything-run-on-the-phone-instead).
  Full-app SSH, voice, notifications and away/return recovery need named-platform qualification; voice is experimental.
- Agent remains authoritative for profiles, sessions, tools and assistant state.
  [Reference details](docs/quality/official-desktop-reference.md) distinguish source, simulated and live/platform evidence.

<a id="build-the-alpha-from-source"></a>

## Build from source

Web is the recommended source-built alpha evaluation path, not proof of Android
readiness. Install Git, Flutter 3.44.2 and a browser, then run:

```bash
git clone https://github.com/TrebuchetDynamics/hermes-wing.git
cd hermes-wing
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 18997
```

When Flutter reports readiness, open **http://127.0.0.1:18997**. This downloads source/dependencies
and serves Wing on loopback only—not a deployment, Agent install, provider setup or AI conversation.
Press `q` to stop. See the [build guide](docs/getting-started.md#build-and-open-the-client) for Android/Linux prerequisites;
contributors also need Node.js 22 for browser E2E (see [CONTRIBUTING](CONTRIBUTING.md#setup)).

<a id="when-a-connection-needs-attention"></a>
<a id="need-help"></a>
<a id="if-you-get-stuck"></a>

## Help and documentation

- **Can't connect or get a reply?** Start with [troubleshooting](docs/getting-started.md#need-help).
- **Agent setup:** use [Agent documentation](https://hermes-agent.nousresearch.com/docs/) for providers, models and tools; Wing exposes only supported operations.
- **Credentials and trust:** native secure storage varies by platform. Removing a saved connection does not revoke
  its token; rotate/revoke through Agent controls. See the [threat model](docs/security/threat-model.md)
  and [security policy](SECURITY.md). No independent security audit is claimed.
- **Report a bug:** [open an issue](https://github.com/TrebuchetDynamics/hermes-wing/issues) with platform, steps
  and expected/actual behavior. Never include credentials, private endpoints or conversations.
- **More:** [all documentation](docs/README.md), [technical design](docs/spec.md), [architecture decisions](docs/adr/README.md),
  [changelog](CHANGELOG.md), [roadmap](ROADMAP.md), [work queue](TODO.md) and [contribution guide](CONTRIBUTING.md).

## License

[MIT](LICENSE). AI service access and credits are separate from the client license. Wing is independent of Nous Research; Agent provides the runtime and Desktop the product reference.
