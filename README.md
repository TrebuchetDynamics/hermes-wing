# Hermes Wing

<p align="center">
  <picture>
    <source media="(max-width: 600px)" srcset="./assets/readme/overview-mobile.svg">
    <img src="./assets/readme/overview.svg" width="100%" alt="Hermes Wing puts your AI assistant within reach. Use Wing on your phone while Hermes Agent runs on your computer.">
  </picture>
</p>

**An app for chatting with your own AI assistant—from your phone, browser, or desktop.**
Ask for help, follow the assistant's work, and respond when it asks for permission
to act. The assistant runs on a computer you control; Wing is the app you use to
reach it.

**New to Hermes?** You do not need an existing installation. The
[getting-started guide](docs/getting-started.md) explains the pieces and walks
through setting them up.

<p align="center">
  <a href="#what-is-hermes-agent"><strong>Understand the basics</strong></a> ·
  <a href="docs/getting-started.md"><strong>Set up your first chat</strong></a> ·
  <a href="https://trebuchetdynamics.github.io/hermes-wing/app/"><strong>Try the web alpha</strong></a>
</p>

> [!NOTE]
> **Early alpha:** opening the web app shows the interface, but it does not
> provide an AI assistant or model access. Android currently requires a developer
> build; there is no app-store installation yet.

<a id="new-to-hermes-start-here"></a>

## What is Hermes Agent?

[Hermes Agent](https://github.com/NousResearch/hermes-agent) is free, open-source
software for running a personal AI assistant. It can answer questions, help plan
work, and—with the right tools and permissions—work with files or run commands
on its computer.

**An “agent” is an assistant that can take actions as well as write replies.**
What Hermes can do depends on how you configure it. You choose the AI service it
uses and the tools it can access.

**Hermes Wing gives that assistant a visual app.** You can chat without using
the computer's terminal, see tool activity, return to earlier conversations, and
review the permission requests Hermes sends. The computer running Hermes still
needs to stay on and reachable.

### A simple example

Imagine you want help planning a small website. In Wing, you ask:

> Help me turn my website idea into three practical steps. Ask me what you need to know first.

You reply to the assistant's questions, then ask:

> Turn the first step into a checklist.

That is enough to start: a conversation and a follow-up. You can reopen the
conversation later. Tasks involving files or commands need the corresponding
tools and access configured in Hermes first.

## See the app

<p align="center">
  <picture>
    <source media="(max-width: 600px)" srcset="./assets/readme/showcase-mobile.png">
    <img src="./assets/readme/showcase.png" width="100%" alt="Wing shows a conversation and tool activity on desktop, and an approval request in the phone layout.">
  </picture>
</p>

<p align="center"><sub>Actual app screens using sample conversations and simulated responses. The phone view shows a request for permission.</sub></p>

- **Chat and continue later.** Replies appear as they arrive; previous
  conversations remain available from Hermes.
- **Follow the work.** See tool activity, review an approval when Hermes asks,
  or stop the current task.
- **Keep setups separate.** Switch between saved Hermes connections and named
  assistant configurations, called profiles. Start with **Default**.
- **Speak when supported.** Android voice input and spoken replies are
  experimental; typing remains available.

<a id="your-first-conversation"></a>
<a id="get-the-client"></a>
<a id="getting-started"></a>

## Choose your next step

**I am completely new.** Start with [Your first conversation](docs/getting-started.md).
The main path uses a Linux computer for Hermes and an Android phone for Wing.
The guide explains prerequisites, app installation, AI setup, and pairing—the
step that gives your phone permission to connect.

**I already use Hermes.** Keep your existing installation. Follow the
[connection steps](docs/getting-started.md#3-connect-your-phone), using Wing Link
to prepare pairing. A supported existing Hermes installation can be reused.

**I just want to look around.** [Open the web alpha](https://trebuchetdynamics.github.io/hermes-wing/app/).
You can open the interface without building an app. To actually chat, you still
need your own reachable Hermes installation and a configured AI provider.
Browser connections also need trusted HTTPS and permission for the Wing website
to contact your Hermes computer.

### The setup, in four steps

1. **Get Wing on your device.** The guide includes the Android build steps.
2. **Prepare the computer running Hermes.** Wing Link can install Hermes or
   reuse a supported installation; Hermes' wizard helps you choose your AI.
3. **Pair the devices.** Create a short-lived link on the computer, review it
   in Wing, and confirm. The remote-phone path uses NetBird or Tailscale for a
   private connection between your devices.
4. **Send a message.** Open Default and ask the assistant to introduce itself.
   An actual reply—not just a “paired” message—confirms that chat is working.

**Expect some initial technical setup.** This alpha needs a Linux computer with
its user service manager, development tools for the phone build, and access to
an AI service. The [full checklist](docs/getting-started.md#what-you-need) is for
you or the person helping you install it.

## Questions you might have

### What are Wing, Agent, and Wing Link?

| Name | What you use it for |
| --- | --- |
| **Hermes Wing** | The app you open to chat and follow work. |
| **Hermes Agent** | The software on your computer that runs the assistant and keeps its conversations. |
| **Wing Link** | The setup and management helper that connects Wing to your Hermes computer. |

Chat travels directly between Wing and Hermes Agent. Wing Link handles setup
and supported computer-management tasks separately. Hermes remains the source of truth.

### Does this include an AI model? Does it cost money?

Wing is MIT-licensed open-source software. **AI service access and credits are
not included.** You choose a **provider**, the service supplying the AI, and a
**model**, the particular AI that generates replies. Your provider may charge
for use. Hermes' setup wizard helps configure that connection.

### Where do my conversations go?

Hermes keeps conversation state on the computer running it. The provider you
configure may also receive and process conversation data. Running Hermes on
your own computer does not automatically make every AI request local.

### Can everything run on my phone?

There is an experimental **Use this phone** option with **Termux**, an Android
app that provides a Linux-like terminal environment. Android may stop its
background processes, so this path needs extra care.
[Read the phone-only limitations](docs/runbooks/android-termux-local-agent.md).

### Is it ready for everyday use?

It is an **experimental alpha**. Android is the most exercised client, and real
phone chat has been tested. There are no signed app packages, store releases,
automatic updates, or supported release line yet. Voice and other platforms
have additional limits below.

<a id="when-a-connection-needs-attention"></a>
<a id="need-help"></a>

## If you get stuck

- **The phone cannot connect:** check that the Hermes computer is on and both
  devices are connected to the private network.
- **The pairing link expired:** create a new one and leave the pairing terminal
  open while confirming it in Wing.
- **Wing says paired, but there is no answer:** check the provider credentials
  and model setup on the Hermes computer. Pairing and a working AI response are
  separate checks.

[Step-by-step troubleshooting](docs/getting-started.md#need-help) ·
[Report a problem](https://github.com/TrebuchetDynamics/hermes-wing/issues)

Include your platform, what you tried, and what happened. Keep credentials,
pairing links, and private conversations out of reports.

<a id="project-status"></a>
<a id="platforms-and-limits"></a>

## Current support

| Platform | Status |
| --- | --- |
| **Android** | Most exercised client, including real phone chat and profile tests. Voice is experimental. |
| **Web / Linux** | Text-first alpha, with browser regressions, builds, and Linux native shell checks. |
| **Windows / macOS** | Desktop build-tested; equivalent runtime support is not qualified. |
| **iOS** | Simulator build-tested; physical-device runtime support is not qualified. |

A real Samsung test covered provider setup, chat follow-ups, app restart, and
profile isolation with Hermes and Wing Link on Linux over USB. This is not
remote-network or microphone qualification.
[Read the test evidence](docs/quality/provider-chat-physical-2026-09-05.md).

Available controls depend on the operations your installed Hermes supports.
[Feature status](docs/product/routes.md) · [Roadmap](ROADMAP.md) ·
[Security policy](SECURITY.md)

<a id="build-the-alpha-from-source"></a>
<a id="connect-your-agent"></a>
<a id="pair-a-phone-or-another-computer"></a>

## Setup reference and contributing

[Beginner setup and build commands](docs/getting-started.md) ·
[All documentation](docs/README.md) · [Contributing](CONTRIBUTING.md) ·
[Architecture](docs/adr/README.md) · [Changelog](CHANGELOG.md)

Hermes Wing is an independent project. Thanks to
[NousResearch's Hermes Agent](https://github.com/NousResearch/hermes-agent) for
the assistant runtime and [Hermes Desktop](https://github.com/fathah/hermes-desktop)
for interaction and setup inspiration.

[MIT licensed](LICENSE).
