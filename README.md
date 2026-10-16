<a href="assets/branding/README.md"><img src="assets/branding/wing-logo-256.png" width="80" height="80" alt="Hermes Wing logo"></a>

# Hermes Wing

Chat with your Hermes assistant, follow tool activity, and review approval requests
from your phone, browser, or desktop.

Wing brings the Hermes Desktop experience toward Android, web, and desktop with
Flutter-native clients. Desktop parity is a goal, not a guarantee. Your **Hermes
Agent** runs the assistant, conversations, tools, and configuration; Wing is its
client, not a hosted assistant, provider account, or source of model credits.

> [!NOTE]
> **Early alpha.** Preview the interface without an Agent. Actual chat requires
a compatible, authenticated Agent and configured provider. Native clients require
a source build; signed distribution and automatic updates are unqualified.

**[Set up your first chat](docs/getting-started.md)** ·
[Preview the connection screen](https://trebuchetdynamics.github.io/hermes-wing/app/)

<p align="center">
  <picture>
    <source media="(max-width: 600px)" srcset="./assets/readme/showcase-mobile.png">
    <img src="./assets/readme/showcase.png" width="100%" alt="Simulated desktop chat and phone decision for a synthetic demo repository.">
  </picture>
</p>

*DEMO DATA · SIMULATED SESSION. The sample Agent and repository are synthetic;
this is not live-provider testing or observed cross-device synchronization.*

<a id="what-can-i-do-with-it"></a>
<a id="features"></a>

## What Wing does

- **Chat and follow work.** Read replies and see tool activity.
- **Review decisions.** Agent tools can access files or run commands when granted;
  review each request before approving or stopping work.
- **Return to the right assistant.** Choose Agent-owned profiles and conversations.
- **Connect directly.** Use an Agent endpoint; native SSH is a separate option.
  Browser SSH is unsupported.

These controls have simulated Agent-response tests; the complete live chat,
approval, and reconnect workflow is not verified. See
[workflow evidence and limits](docs/quality/live-desktop-daily-workflow.md).

<a id="new-to-hermes-start-here"></a>
<a id="what-is-hermes-agent"></a>

## Choose a path

<a id="what-do-i-need"></a>
<a id="what-do-i-need-for-the-android-setup-guide"></a>
<a id="get-the-client"></a>
<a id="getting-started"></a>
<a id="choose-your-next-step"></a>
<a id="preview-without-an-agent"></a>

### Preview the connection screen

1. [Open the web alpha](https://trebuchetdynamics.github.io/hermes-wing/app/).
2. On **Welcome to Hermes Wing**, choose **Connect to Remote Hermes** to inspect
   the form. No Agent or credential is needed just to preview it.

**Success:** the welcome screen and form appear. This is an interface, not a working assistant; the hosted build can lag the source.

### Connect an existing Hermes Agent

First open Wing: use the [web alpha](https://trebuchetdynamics.github.io/hermes-wing/app/)
or [build a native client](docs/getting-started.md#build-and-open-the-client).
Then follow the [first-chat guide](docs/getting-started.md). You need:

- An enabled, reachable, authenticated Hermes Agent HTTP API. Wing needs Agent
  support for session chat and streaming; a working CLI, health check, or generic
  chat API alone does not prove compatibility. Follow the [Agent API Server guide](https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server).
- A trusted route. Native SSH can forward to an Agent host loopback. Remote access
  needs an approved secure endpoint; browsers additionally require trusted HTTPS
  and an allowed Wing CORS origin. Never expose a public port or disable trust.
- A configured Agent profile/provider/model. Providers may charge and process
  conversation data; self-hosting Agent does not make inference local.

Use the Agent credential in Wing, not a provider key. Start with the guide's
no-tools prompt; a reply—not a health check or saved credential—is the success
signal. Do not send a repository task until that smoke succeeds and you understand
the cost and tool permissions.

### Build a native client

Install Git, Flutter 3.44.2, and target development tools. Follow
[Build and open the client](docs/getting-started.md#build-and-open-the-client).
**Success:** Wing opens to its welcome screen. Continue with the existing-Agent
path above; a successful build is not Agent readiness or generation.

<a id="connect-your-agent"></a>
<a id="pair-a-phone-or-another-computer"></a>
<a id="your-first-conversation"></a>
<a id="your-first-chat"></a>
<a id="your-first-chat-on-android"></a>

## Your first chat

1. Open Wing and choose a direct connection route. Android offers **Connect via
   SSH**, **Connect to Remote Hermes**, then **Use this phone (Termux)**. Desktop
   and web offer **Get Started**; Linux Local discovery only checks directory
   metadata. The [guide](docs/getting-started.md#direct-agent-connection) explains
   each route and its limits.
2. Enter the Agent endpoint and its credential. Configure provider access in Agent;
   those are separate credentials.
3. Select your configured profile and conversation. Send:

   > Reply with one sentence introducing yourself. Do not use any tools.

**Success:** an assistant reply appears in that conversation. A connection test
alone does not prove generation. The optional
[repository summary](docs/getting-started.md#optional-repository-summary) comes
later and requires a deliberately granted demo Project.

<a id="project-status"></a>
<a id="platforms-and-limits"></a>
<a id="current-support"></a>
<a id="availability"></a>

## Compatibility and limits

- Android, web, and Linux are alpha paths. Other targets have limited runtime
  qualification. See the single [platform evidence and limits matrix](docs/getting-started.md#platform-evidence-and-limits).
- Browser OAuth and SSH are unsupported. Browser access requires trusted HTTPS and
  permitted CORS; it cannot access native secure storage or host folders.
- Fresh on-phone Agent installation/hosting, full app SSH authentication, voice,
  notifications, and background recovery are not blanket support claims.
- Hermes Agent remains authoritative for profiles, sessions, tools, and assistant
  state. Wing does not provide a hosted backend or guarantee Desktop parity.
  [Reference and qualification details](docs/quality/official-desktop-reference.md)
  distinguish source comparisons, simulated checks, and live/platform evidence.

<a id="build-the-alpha-from-source"></a>

## Build from source

Web is the recommended source-built alpha evaluation path, not proof of native
Android readiness. Install Git, Flutter 3.44.2, and a browser, then run:

```bash
git clone https://github.com/TrebuchetDynamics/hermes-wing.git
cd hermes-wing
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 18997
```

Open **http://127.0.0.1:18997** when Flutter reports the server is ready. It is
loopback-only, not a deployment. This builds Wing; it does not install Agent,
configure a provider, or start a conversation. Press `q` to stop it. Use the
[native build guide](docs/getting-started.md#build-and-open-the-client) for Android
or Linux prerequisites; contributors also need Node.js 22 (see
[CONTRIBUTING](CONTRIBUTING.md#setup)).

<a id="when-a-connection-needs-attention"></a>
<a id="need-help"></a>
<a id="if-you-get-stuck"></a>

## Help and documentation

- **Can't connect or get a reply?** Start with
  [troubleshooting](docs/getting-started.md#need-help).
- **Agent setup:** use [Agent documentation](https://hermes-agent.nousresearch.com/docs/)
  for providers, models, and tools. Wing exposes only supported operations.
- **Credentials and trust:** native secure storage varies by platform. Removing a
  saved connection does not revoke its token; use Agent controls to rotate/revoke.
  See the [threat model](docs/security/threat-model.md) and [security policy](SECURITY.md).
- **Report a bug:** [open an issue](https://github.com/TrebuchetDynamics/hermes-wing/issues)
  with platform, steps, and visible result. Never include credentials, private
  endpoints, or conversations.
- **More:** [technical design](docs/spec.md), [architecture decisions](docs/adr/README.md),
  [all documentation](docs/README.md), [changelog](CHANGELOG.md), [roadmap](ROADMAP.md),
  [work queue](TODO.md), and [contribution guide](CONTRIBUTING.md).

## License

[MIT](LICENSE). AI service access is separate from the client license. Wing is
independent of Nous Research; Agent provides the runtime and Desktop the reference.
