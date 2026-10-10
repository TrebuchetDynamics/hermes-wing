# Your first conversation with Hermes Wing

Wing connects directly to Hermes Agent. **Wing Link is not required.**
Wing Link is deprecated. This guide describes the existing direct path.
Retained management procedures are not a supported new-user setup path.
The development chooser implements Linux Hermes-home discovery and Android
guided same-phone setup. Native discovery, chooser and phone setup remain
unqualified.
If the names are unfamiliar, start with [What is Hermes?](../README.md#what-is-hermes-agent).

## Direct Agent connection

Have a reachable Hermes Agent API and its approved profile-bound credential.
Configure Agent and provider access through supported Agent procedures. See the
[official Agent documentation](https://hermes-agent.nousresearch.com/docs/).
Do not copy personal credentials or expose an API to a public interface to bypass
setup. Remote native HTTP requires the existing explicit review and trusted
encrypted network; browser access requires trusted HTTPS and permitted CORS.

In the current development worktree:

1. On a fresh launch, choose **Get Started** for Local, **Connect via SSH**, or
   **Connect to Remote Hermes** from the welcome screen. With a saved connection,
   choose **Add Hermes** from Chat. Older builds use **I have a QR code or pairing link**,
   then **Connect one profile manually**. None of these direct paths needs pairing.
2. For Linux Local, review default Hermes-home discovery or choose another folder;
   this does not start Agent or bind its runtime to that folder. For Android Local,
   follow **This phone** guidance or skip for an already-running Agent, then enter
   its separate credential. For Remote, enter the Agent endpoint and credential.
   **Help** explains how to obtain connection information and offers **Copy instructions**. For native SSH,
   enter host, SSH port, username, a selected private key or password, Agent port and its separate access
   token. Verify the host fingerprint before trusting the connection. Wing owns
   the forward; no external tunnel or CLI QR is needed. This uses the direct
   Agent channel, not Wing Link.
3. Select the configured profile/session and supported model, then send one
   deliberate message. A reply, not saved credentials alone, confirms generation.

The development chooser keeps **Optional setup and pairing** separate from direct
connection. The [first-run receipt](quality/direct-first-run.md) records passing
widget and compiled Chromium checks on Linux, including explicit authentication
retry without management requests. This pass inspects that evidence; it does not
rerun those checks. The [native first-run receipt](quality/direct-first-run-native.md)
also records Linux GTK fixture journeys. The
[welcome recovery receipt](quality/desktop-welcome-recovery.md) adds keyboard
Back/cancel, explicit connection retry and saved-owner restoration in a fresh
Linux process. Its endpoint store is synthetic, not physical keychain proof.
Main delivery, Android and live authentication remain open.
The managed SSH form offers Private key and Password in this worktree. Choose
a key file/document explicitly and enter its passphrase when required. Selected
imported keys are attempt-scoped, not saved. Alternatively, choose **Generate SSH key**,
review consent, then **Copy public key**. Add only that public key to the SSH
account on the host; never share the private key. Wing retains the generated key
in secure storage and **Use saved Wing key** deliberately selects it again.
Existing valid generated keys are reused, not replaced. Storage failure prevents
selection; there is no plaintext fallback. Cancel does not delete an already-created key.
Saved SSH connection relaunch remains planned. Browser SSH is unsupported. Native Linux
and Android full-app SSH authentication remain NOT_CHECKED; terminal login is not
app qualification. See the
[key-UX plan](product/desktop-connection-paths.md#private-key-ux-desktop-reference-and-wing-adaptations).
Missing Agent APIs leave their features unavailable, not a Wing Link requirement.

Remote HTTPS and VPN use the Agent access token, not a Wing Link token or provider
API key. Browser OAuth sign-in is unsupported. An OAuth-only server cannot use
this flow. If access is denied, confirm the endpoint and Agent token with the
server administrator. Then retry explicitly or cancel. A denial does not identify
the server's sign-in method. The [explanation receipt](quality/remote-auth-explanation.md)
records widget and Linux GTK fixture checks, not live authentication or Android qualification.

Legacy pairing controls remain in development code pending removal. Do not use
them as a prerequisite or substitute for a missing Agent capability.

## Repair a saved direct connection

In the current development worktree, open **Add Hermes**, then choose
**Edit saved Agent connection** on the saved row. This does not switch Chat.

1. Edit the Agent endpoint or enter an obscured replacement credential.
   Saved credentials are not prefilled. A blank replacement retains the credential
   only when the canonical Agent URL is unchanged. A changed URL never reuses that
   credential and removes the saved Wing Link association. Supply its credential
   separately if authentication requires one.
2. Choose **Test** for direct read-only capabilities discovery. Test does not
   save, connect Chat or prove generation. Cancel discards late test feedback;
   it does not recall an already dispatched request.
3. Choose **Save** to update that saved connection, or **Cancel** to discard the
   draft. A save error keeps the draft for explicit retry. Successful Save means
   local persistence, not remote readiness; connect deliberately afterwards.

The [editor receipt](quality/saved-endpoint-edit.md) records passing widgets and
compiled Chromium fixtures. The [native editor receipt](quality/saved-endpoint-edit-native.md)
also records passing Linux GTK fixture journeys with fake endpoint storage.
The later [real-storage receipt](quality/saved-endpoint-storage-native.md) records
passing isolated Linux GTK secure-storage repair, explicit retry after write denial
and persistence across two processes. It qualifies its frozen candidate, not every
keyring failure or later editor change. Android and live authentication remain
unqualified. Complete credential guidance and Test/Save outcomes are keyboard
focus stops in the later [feedback correction](quality/saved-endpoint-feedback-accessibility.md).
New outcomes receive focus and scroll into view. Use Page Down when the text
exceeds the dialog viewport, then Tab to return to actions. Linux GTK fixture
checks cover compact/wide windows at 100/200% text, not screen readers or the
real-storage backend after this editor change. This workflow requires no Wing Link connection.

## What you need

- A running, reachable Hermes Agent and its approved profile-bound credential.
- A Wing build for the chosen platform. The web alpha supplies the interface,
  not an assistant, provider account or model.
- A configured provider and model. Model access and credits are not included.
  Your provider may charge for use and process conversation data.
- A trusted connection. Remote browser access needs trusted HTTPS and permitted
  CORS. Native remote access must satisfy the existing transport review.

Agent installation and provider configuration belong to the
[official Agent documentation](https://hermes-agent.nousresearch.com/docs/).
Wing does not require a Wing Link service, token or pairing bootstrap.

<a id="your-first-conversation"></a>
<a id="get-the-client"></a>
<a id="getting-started"></a>
<a id="build-the-alpha-from-source"></a>

## Build and open the client

Use Flutter 3.44.2 and the development tools for your chosen platform. See
[contributor setup](../CONTRIBUTING.md#setup) and the
[Flutter installation guide](https://docs.flutter.dev/install).
For Android, enable USB debugging and authorize your development computer.

```bash
git clone https://github.com/TrebuchetDynamics/hermes-wing.git
cd hermes-wing
flutter pub get
flutter devices
flutter run -d <device-id>
```

Replace `<device-id>` with a target listed by `flutter devices`. These commands
build and launch Wing. They do not install Agent or configure provider access.
For Linux packaging, `./scripts/install_linux.sh` builds the client and creates
`hermes-wing` in `~/.local/bin`. Add that directory to `PATH` if needed.

[Open the web alpha](https://trebuchetdynamics.github.io/hermes-wing/app/) to inspect
its interface. Chat still needs your reachable Agent and browser connection access.

<a id="connect-your-agent"></a>
<a id="pair-a-phone-or-another-computer"></a>

## Start the conversation

Use the [direct connection steps](#direct-agent-connection). Select the configured
profile and session, then deliberately select a supported model when requested.
Send a short message and check for an assistant reply. Saved credentials and a
successful connection probe do not prove that generation works.

## Common questions

### Do I need to know or install Hermes first?

No prior Hermes knowledge is required, but Wing needs a running Agent. Follow
supported Agent installation and provider setup before connecting. Wing's current
Local discovery does not start Agent or prove that installation is ready.

### Does my computer need to stay on?

Yes, when that computer runs Agent. It must remain reachable while you chat.
Closing Wing does not move Agent onto the phone.

<a id="same-phone-android--termux"></a>

### Can everything run on the phone instead?

Guided same-phone Android setup is accepted replacement work, not a qualified
installation or background-hosting path. The current **This phone** guidance can
lead into direct connection to an already-running Agent. Retained Termux scripts
still include deprecated management setup and are not the recommended path.
Do not treat their historical pairing receipts as Agent-only installation proof.

### Can I use the same computer for Wing and Hermes?

Yes. Run Agent through supported Agent procedures and open Wing on that computer.
Use Local to enter its approved loopback endpoint and separate Agent credential.
No management pairing is needed.

### What are profiles, sessions, and runs?

A **profile** is a named assistant setup. A **session** is a conversation and its
history. A **run** is Agent working on a request. An **approval** asks you to decide
whether an action may proceed. Agent owns these resources.

<a id="when-a-connection-needs-attention"></a>

## Need help?

- **Cannot connect:** check that Agent is running and the endpoint is reachable
  from the Wing device. `127.0.0.1` refers to that device, not another computer.
- **Access denied:** confirm the Agent endpoint and token with its administrator.
  Retry explicitly or cancel. OAuth-only authentication is unsupported here.
- **Connected, but no answer:** check the configured provider/model through
  supported Agent procedures. A saved connection alone is not a generation test.
- **Web interface cannot connect:** Agent must offer browser-trusted HTTPS and
  explicitly permit the Wing website through CORS. Do not bypass browser trust.
- **Saving failed:** distinguish live connection from confirmed persistence.
  Use the explicit save retry or [saved-connection repair](#repair-a-saved-direct-connection).
- **Operation unavailable:** inspect the connected Agent's exact capability.
  Do not install deprecated management software to simulate missing support.

[Report a problem](https://github.com/TrebuchetDynamics/hermes-wing/issues) with
platform, actions and visible result. Keep credentials, private endpoints and
conversations out of reports.

## Your data and permissions

Agent remains the source of truth for assistant state. Your chosen provider may
process conversation data. Wing connects directly to Agent and stores credentials
through platform secure storage. Secure-storage qualification varies by platform.
Retained legacy management credentials remain separate until migration; this
guide does not delete them or authorize changing personal runtime state.

Server state wins after reconnect. Wing must not silently resend prompts,
approvals or configuration changes. Confirm destructive or sensitive actions
explicitly. There has been no independent security audit.

[Security policy](../SECURITY.md) · [Threat model](security/threat-model.md) ·
[Project overview](../README.md) · [All documentation](README.md)
