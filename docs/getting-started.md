# Your first conversation with Hermes Wing

This guide walks through **Wing on an Android phone and Hermes on a Linux
computer**. It includes the build commands and explains where to run each step.
If the names are unfamiliar, start with [What is Hermes?](../README.md#what-is-hermes-agent).

## What you need

The main path is **Hermes on a Linux computer, Wing on your Android phone**.

- **A Linux computer that stays on.** It runs the assistant. Your phone needs to
  be able to reach it while you chat.
- **The Wing app.** Android is the most exercised version. Web and desktop
  versions are available too, with different setup requirements.
- **Access to an AI provider and model.** The provider supplies the AI service;
  the model is the particular AI that generates replies. Hermes' wizard helps
  you choose and enter the required sign-in or credential.
- **A private connection between the devices.** The phone setup uses NetBird or
  Tailscale, which connect your devices through an encrypted private network.
  Set up one of them on both devices before pairing.

Wing is MIT-licensed open-source software. **Model access and provider credits
are not included.** Your provider may charge for use, and conversation data may
be sent to the provider you configure.

<details>
<summary><strong>Technical requirements for the person setting this up</strong></summary>

The tested host path uses Linux with a working **systemd user session** (the
service manager for your account), Git, `curl`, **Go 1.26 or newer**
([Go installation guide](https://go.dev/doc/install)), and internet access.

Building Wing requires **Flutter 3.44.2** and the tools for the chosen platform.
Follow the [Flutter installation guide](https://docs.flutter.dev/install) and,
for a phone build, [Android setup](https://docs.flutter.dev/platform-integration/android/setup).
This alpha still requires terminal work; someone comfortable with development
tools may need to help with the initial installation.

</details>

<a id="your-first-conversation"></a>
<a id="get-the-client"></a>

## Getting started

### 1. Get Wing ready

For the Android path, build and open Wing using the instructions below. On its
first screen, choose **Use another computer**. The app walks through computer
setup and returns you to pairing afterward.

<a id="build-the-alpha-from-source"></a>

<details>
<summary><strong>Build and open Wing on Android</strong></summary>

On your development computer, install Flutter 3.44.2 and the Android development
tools linked above. Connect your phone with USB debugging enabled, authorize the
computer on the phone, and run `flutter doctor` to check your tools.

Then run in a terminal:

```bash
git clone https://github.com/TrebuchetDynamics/hermes-wing.git
cd hermes-wing
flutter pub get
flutter devices
flutter run -d <device-id>
```

Replace `<device-id>` with the phone's ID from `flutter devices`, without the
angle brackets. These commands build and launch Wing; the next step sets up the
assistant itself.

</details>

**Just want to open the interface?** [Launch the web alpha](https://trebuchetdynamics.github.io/hermes-wing/app/).
It does not supply an assistant. Connecting through a browser also requires
trusted HTTPS and permission for the Wing website to reach your Hermes computer
(CORS). See [connection help](#need-help).

<a id="connect-your-agent"></a>
<a id="pair-a-phone-or-another-computer"></a>

### 2. Set up the assistant on your computer

Run this step **on the Linux computer that will run Hermes**, not in the phone
app. Wing Link installs Hermes or reuses a supported existing installation. Then
Hermes' setup wizard asks which provider and model to use.

<details>
<summary><strong>Show the computer setup commands</strong></summary>

If the repository is not already on this computer:

```bash
git clone https://github.com/TrebuchetDynamics/hermes-wing.git
cd hermes-wing
```

Otherwise, open a terminal in the existing `hermes-wing` folder. Run:

```bash
./install-wing-link.sh
export PATH="$HOME/.local/bin:$PATH"
hermes setup
```

The installer prepares the connections Wing needs and starts Hermes if needed.
It leaves an already-running gateway undisturbed. In the wizard, choose your
provider and model and enter any required credential directly there.

If your existing Hermes setup already has a working provider and model, skip
`hermes setup`. Use `--release` with the installer to select a published Wing
Link alpha instead of building the checkout; this is for the host helper, not a
phone app download.

</details>

**Before continuing:** setup should finish without an error, and your assistant
should have a provider and model selected. A provider credential is a secret for
accessing your AI service. Do not paste it into pairing links or GitHub issues.

### 3. Connect your phone

**Pairing** gives Wing permission to connect to your Hermes installation.
With both devices on your NetBird or Tailscale network, run this command on the
Linux computer:

```bash
wing-link pair
```

**Leave that terminal open.** On the phone, choose **I have a QR code or pairing
link**, paste the connection text from the terminal, review the computer's
identity and requested access, and confirm. Compare the displayed fingerprint
with the host's value; it is the identity check for that computer.

Use `wing-link pair --qr` if you prefer to scan a QR code from the computer's
screen. The pairing code expires after five minutes; run the command again if
it expires. Pairing may restart Hermes when it prepares the network connection.

### 4. Have your first conversation

Open **Default**, or another configured profile, and send:

> Reply with one sentence introducing yourself. Do not use any tools.

**You are ready to chat when an assistant reply appears.** Try a follow-up such
as “Make that introduction shorter.” Keep it in the same conversation.

“Paired” means your connection was saved. It does not guarantee that your
provider can answer yet. If you connect but get no reply, check provider/model
setup on the computer before pairing again.

## Common questions

### Do I need to know or install Hermes first?

No prior Hermes knowledge is needed to follow the guide. Wing Link can install
Hermes for you, and it reuses a supported existing installation. You still need
to complete the initial computer, app, and provider setup.

### Does my computer need to stay on?

Yes, when that computer is running Hermes. It must remain on and reachable for
the phone to use the assistant. Closing Wing does not move Hermes onto the phone.

<a id="same-phone-android--termux"></a>

### Can everything run on the phone instead?

There is an experimental **Use this phone** option through **Termux**, an Android
app that provides a Linux-like terminal environment. Follow the
[Termux guide](runbooks/android-termux-local-agent.md).
Android can stop background processes, and the unmodified bootstrap and persistent
hosting are not qualified. Wing does not execute commands inside Termux for you.

### Can I use the same computer for Wing and Hermes?

Yes. For the Linux desktop path, build Wing with `./scripts/install_linux.sh`,
then start it with `hermes-wing`. The installer creates the command in
`~/.local/bin`; add that directory to `PATH` if needed.
Use `wing-link pair --local` for pairing on that same computer.

### What are profiles, sessions, and runs?

A **profile** is a named assistant setup; start with Default. A **session** is
one conversation and its history. A **run** is the assistant working on one
request. An **approval** asks you to decide whether an action may proceed.
“Gateway” in Wing's connection controls refers to a saved Hermes connection.

<a id="when-a-connection-needs-attention"></a>

## Need help?

- **`wing-link` is not found:** try `~/.local/bin/wing-link inspect` on the Linux
  computer, or add `~/.local/bin` to `PATH`.
- **Phone cannot connect:** check that the computer is on, Hermes is running,
  and both devices are on the private network. `127.0.0.1` means the device you
  are using, so that address on the phone does not point to your computer.
- **Connected, but no answer:** check the provider's credentials and model choice
  with `hermes setup` on the computer. A saved connection alone is not a chat test.
- **A profile change is waiting for approval:** review `wing-link approvals list`
  locally on the Hermes computer, approve the exact request, then retry it
  unchanged in Wing.
- **Web app opens but cannot connect:** your Hermes computer must accept HTTPS
  the browser trusts and explicitly allow the Wing website to contact it (CORS).
  A native phone build can use Wing Link's certificate-review flow instead.

[Full connection troubleshooting](runbooks/android-hermes-setup.md) ·
[Profile guide](product/gateway-profile-management.md) ·
[Report a problem](https://github.com/TrebuchetDynamics/hermes-wing/issues)

When reporting a problem, include the platform, what you tried, and what happened.
Keep credentials, pairing links, and private conversations out of reports.

## Your data and permissions

Hermes keeps your assistant's state on its computer; your selected AI provider
may also process conversation data. Wing connects directly to Hermes for chat
and separately to Wing Link for computer management. Hermes remains the source of truth.
The two connections use separate credentials stored through platform secure storage.

Pairing links carry a short-lived, single-use code, never your bearer credential.
Review the computer identity before confirming. Sensitive Wing Link actions still
require local approval on the Hermes computer.

<details>
<summary><strong>Connection security and advanced setup</strong></summary>

Wing Link is the authenticated remote management API for installation, pairing,
lifecycle, health, and diagnostics. It does not forward Agent chat traffic.
Its HTTP listeners are loopback-only; remote listeners use TLS 1.3. Native Wing
pins the reviewed key; browser clients require normally trusted HTTPS. Server
state wins after reconnect, and administrative changes are not silently replayed.

Today, Wing Link's Agent-domain compatibility surface covers fixed profile
list/create/clone/rename/delete and transactional new-profile setup.
Through this compatibility path, existing-profile credential edits remain blocked;
general provider operations are planned. Hermes Project creation is not shipped.
The folder picker returns only child folders under locally approved roots through
opaque handles, never file names, file metadata, or file contents.

For custom VPN selection, follow the [full setup runbook](runbooks/android-hermes-setup.md),
including listener configuration and restart steps. Its fixed Agent command is:

```bash
hermes config set --force platforms.api_server.extra.host <trusted-vpn-ip>
```

Follow that guide when setting `WING_HERMES_URL` and `WING_LINK_URL`; never bind
the Agent API to a public interface. Manual Agent URL/token entry connects one
profile only and does not import Wing Link management.

[Wing Link contract](product/wing-link.md) · [Security policy](../SECURITY.md) ·
[Threat model](security/threat-model.md)

</details>

There has been no independent security audit.


[Back to the project overview](../README.md) · [All documentation](README.md)
