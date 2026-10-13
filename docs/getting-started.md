# Your first conversation with Hermes Wing

Wing connects directly to Hermes Agent. Bring your own Agent, provider and model;
Wing supplies the client, not a hosted assistant or model credits.
If the names are unfamiliar, start with [What is Hermes?](../README.md#what-is-hermes-agent).

## What you need

- A browser for preview, or Git, Flutter 3.44.2 and target development tools for a native build.
- For chat: an enabled, reachable, authenticated Agent HTTP API and its authorized
  Agent access token. A working Hermes CLI alone is not enough.
- A configured Agent profile, provider and model. Your provider may charge for use
  and process conversation data; self-hosting Agent does not make inference local.
- A trusted route from the Wing device to Agent. Keep secrets in the app's masked
  fields, never in URLs, copied commands, issue reports or the clipboard.

<a id="your-first-conversation"></a>
<a id="get-the-client"></a>
<a id="getting-started"></a>
<a id="build-the-alpha-from-source"></a>

## Build and open the client

### Browser

1. [Open the web alpha](https://trebuchetdynamics.github.io/hermes-wing/app/).
2. Expect **Welcome to Hermes Wing**. Choose **Connect to Remote Hermes** to
   inspect the connection form. No Agent or credential is needed to preview it.

This previews the interface, not a working assistant. The hosted alpha may lag
the source. Browser SSH and OAuth sign-in are unsupported. To chat remotely,
continue with Agent preparation below: browser-trusted HTTPS and an explicitly
allowed Wing CORS origin are required. If the page does not open, try the
[loopback-only source web build](../README.md#build-from-source).

### Native Android or Linux

Install [Flutter](https://docs.flutter.dev/install) and its tools for the target.
For Android, authorize USB debugging on your chosen device; Linux needs Flutter's
desktop development packages. Use [contributor setup](../CONTRIBUTING.md#setup).

```bash
git clone https://github.com/TrebuchetDynamics/hermes-wing.git
cd hermes-wing
flutter pub get
flutter devices
flutter run -d <device-id>
```

Replace `<device-id>` with the target listed by `flutter devices`.
**Success:** Wing opens to its welcome screen (or Chat with an existing connection).
If no target is listed or the build fails, check Flutter's target prerequisites.
These commands build Wing, not Agent, and do not configure provider access.
Linux users can alternatively run `./scripts/install_linux.sh` to build and create
`hermes-wing` in `~/.local/bin`; add that directory to `PATH` if needed.
Signed distribution and automatic updates are not verified; see the limits below.

## Prepare your Agent

Follow the [official Agent API Server guide](https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server)
to enable the HTTP API, configure a strong Agent API credential and start its
listener. The default `127.0.0.1:8642` is on the Agent host, not another device.
Do not expose a public port or put credentials in commands to work around setup.

Wing discovers `/v1/capabilities` (schema 1) and checks exact method/path,
every required grant and advertised profile context for each operation. Chat
needs session inventory/history and an advertised streaming transport: runs
(`POST /v1/runs` plus `GET /v1/runs/{run_id}/events`, with `run_submission` and
`run_events_sse`), or session chat (`POST /api/sessions/{session_id}/chat/stream`,
with `session_chat_streaming`). New conversations also require session creation.
A healthy listener or working `/v1/chat/completions` alone does not establish
Wing compatibility.
Ask the administrator for a compatible unmodified Agent if a required operation
is unavailable; do not patch Agent or install a management fallback.

Configure the chosen profile/provider/model through
[Agent's documentation](https://hermes-agent.nousresearch.com/docs/).
**Ready to proceed:** you have an approved endpoint, separate Agent token,
trusted transport and configured model. Only an actual reply verifies generation.

## Direct Agent connection

Have a reachable Hermes Agent API and its approved profile-bound credential.
Configure Agent and provider access through supported Agent procedures. See [Agent preparation](#prepare-your-agent).
Do not copy personal credentials or expose an API to a public interface to bypass
setup. Remote native HTTP requires the existing explicit review and trusted
encrypted network; browser access requires trusted HTTPS and permitted CORS.

On Android, the fresh welcome offers three separate choices in this order:

1. **Connect via SSH** — connect to Agent on another computer through Wing's
   native SSH forward. Enter its host, SSH port, username, selected private key or
   SSH password, Agent API port and separate Agent access token. Compare the host
   fingerprint with a trusted administrator before choosing **Trust this connection**;
   cancel if it differs or you cannot verify it. SSH login alone does not prove
   Agent readiness.
2. **Connect to Remote Hermes** — enter the full Agent endpoint, including its
   configured port/profile path, and its separate credential in the masked field.
   Obtain these from the host administrator; do not guess a URL or embed a token
   in it. Remote HTTPS and trusted VPN access use the same direct Agent channel.
3. **Use this phone (Termux)** — follow **This phone** guidance to prepare Agent
   yourself, or choose **Agent already running — skip guide**. Then type its
   separate Agent API token and choose **Add Hermes**. Follow the
   [direct Termux runbook](runbooks/android-termux-local-agent.md); guide completion
   is not an installation, readiness check or authenticated connection.

Android has no **Get Started** welcome action. On desktop/web, **Get Started**
opens Local; SSH and Remote remain separate choices. On Linux, review the default
`~/.hermes` metadata discovery or choose **Choose another Hermes home**. This is
not a Hermes Project or conversation working directory: it does not start Agent,
read its files, save/send the chosen path or bind its runtime to that folder.
Discovery alone does not prove installation, authentication or model readiness.
Enter the running Agent's loopback endpoint and separate masked Agent API token.
Web Local cannot inspect host folders; loopback refers to the browser's device.

Local and Remote forms offer **Test connection**, an explicit read-only capability
discovery check. It does not save credentials, activate Chat, send a prompt or
prove generation. Edit or cancel discards late results; retry is deliberate.
Browser setup shows Wing's exact origin for the Agent CORS allowlist. A browser
network failure may hide CORS, TLS or mixed-content errors and does not establish
that the token is wrong. Named-profile gateways may require `/p/<profile>` in the
Agent base URL; do not append `/v1`. Wing cannot read Agent secrets or reveal vault
entries, and autofill in one browser does not authenticate another browser.

With a saved connection, choose **Add Hermes** from Chat to open the shared
Local / SSH / Remote form. **Help** explains how to obtain connection information;
**Copy instructions** copies public guidance, not connection values or secrets.
Never copy credentials into URLs or the clipboard. Missing capabilities remain
unavailable; authentication denial or connection failure requires correction and
explicit retry or cancel, never a management fallback or automatic mutation replay.
After connecting, select the configured profile/session and supported model and
send one deliberate message. A reply, not saved credentials alone, confirms generation.

Saved Agent connections are preserved. Old pairing links cannot authenticate;
use the direct form and your separate Agent credential instead.
The native SSH form offers Private key and Password. Choose
a key file/document explicitly and enter its passphrase when required. Selected
imported keys are attempt-scoped, not saved. Alternatively, choose **Generate SSH key**,
review consent, then **Copy public key**. Add only that public key to the SSH
account on the host; never share the private key. Wing retains the generated key
in secure storage and **Use saved Wing key** deliberately selects it again.
Existing valid generated keys are reused, not replaced. Storage failure prevents
selection; there is no plaintext fallback. Cancel does not delete an already-created key.
Saved SSH connection relaunch is not verified. Browser SSH is unsupported. Real
full-app SSH authentication on Linux/Android is not verified by the reviewed evidence;
a terminal login is not proof that Wing can authenticate. See the
[key-UX plan](product/desktop-connection-paths.md#private-key-ux-desktop-reference-and-wing-adaptations).
Missing Agent APIs leave their features unavailable, not a Wing Link requirement.

Remote HTTPS and VPN use the Agent access token, not a Wing Link token or provider
API key. Browser OAuth sign-in is unsupported. An OAuth-only server cannot use
this flow. If access is denied, confirm the endpoint and Agent token with the
server administrator. Then retry explicitly or cancel. A denial does not identify
the server's sign-in method. **Wing Link is not required.** It is retired, not a
substitute for missing Agent support.

**Connection success:** the chosen Agent/profile and conversation are available.
Continue with [Start the conversation](#start-the-conversation), rather than
assuming saved credentials mean the model can reply.

## Repair a saved direct connection

Open **Add Hermes**, then choose
**Edit saved Agent connection** on the saved row. This does not switch Chat.

1. Edit the Agent endpoint or enter an obscured replacement credential.
   Saved credentials are not prefilled. A blank replacement retains the credential
   only when the canonical Agent URL is unchanged. A changed URL never reuses that
   credential. Supply the new endpoint's credential
   separately if authentication requires one.
2. Choose **Test** for direct read-only capabilities discovery. Test does not
   save, connect Chat or prove generation. Cancel discards late test feedback;
   it does not recall an already dispatched request.
3. Choose **Save** to update that saved connection, or **Cancel** to discard the
   draft. A save error keeps the draft for explicit retry. Successful Save means
   local persistence, not remote readiness; connect deliberately afterwards.

Guidance and Test/Save outcomes are keyboard focus stops and scroll into view.
Use Page Down for text beyond the dialog viewport, then Tab to return to actions.
If saving fails, keep the draft open and retry explicitly; do not delete your
working connection to diagnose it.

<a id="connect-your-agent"></a>
<a id="pair-a-phone-or-another-computer"></a>

## Start the conversation

Use the [direct connection steps](#direct-agent-connection). Select the configured
profile and session, then deliberately select a supported model when requested.
Send this once:

> Reply with one sentence introducing yourself. Do not use any tools.

**First-reply success:** an assistant reply appears in that selected conversation.
Its wording depends on your assistant and model. Saved credentials and a successful
connection probe do not prove generation. If no answer appears, use [Need help?](#need-help).

### Optional repository summary

Only after the no-tools smoke, deliberately grant a non-sensitive demo repository
through Agent's supported Project/tools setup. Wing does not create a Project or
grant filesystem access on your behalf. Understand provider cost and tool permissions
before sending: “Summarize this demo repository's structure; do not modify files,
run commands or read secrets.” Review any approval Agent actually requests; cancel
if its scope differs. Observe tool activity and revisit the same conversation in
the foreground. This is not a promise of background completion or notifications.

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

Choose **Use this phone (Termux)**, the third Android welcome choice, for manual
**This phone** preparation and direct connection. See the
[direct Termux runbook](runbooks/android-termux-local-agent.md). Wing cannot inspect
Termux files, install/configure/start Agent or guarantee background survival.
Fresh installation and persistent hosting remain unqualified. Retained installers
and historical pairing receipts are not a fallback or Agent-only installation proof.

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
Inert legacy records and secure slots are preserved, not reused or deleted.

Server state wins after reconnect. Wing must not silently resend prompts,
approvals or configuration changes. Confirm destructive or sensitive actions
explicitly. There has been no independent security audit.

## Platform evidence and limits

This is an alpha, not a platform certification. “Simulated” means tests used
fake Agent responses, not a real authenticated assistant. The linked records
identify tested source and target; later builds do not inherit live verification.

| Outcome | Android | Web | Linux | Windows / macOS / iOS |
| --- | --- | --- | --- | --- |
| Chat, streaming and tools | Implemented; simulated tests | Implemented; Chromium simulated tests | Implemented; simulated tests | Runtime not verified by reviewed evidence |
| Approvals and Stop | Implemented; full live journey not verified | Chromium simulated journey | Simulated journeys; full live workflow incomplete | Runtime not verified by reviewed evidence |
| Local preparation and saved-owner recovery | Simulated tests; native Termux installation/authentication not verified | No host folder discovery | Native GTK simulated journey; OS chooser and real authentication not verified | Runtime not verified by reviewed evidence |
| SSH | Native interface implemented; full-app real authentication not verified | Unsupported | Native interface implemented; full-app real authentication not verified | Runtime not verified by reviewed evidence |
| Voice and notifications | Experimental; no blanket reliability claim | Platform-dependent / experimental | Experimental | Runtime not verified by reviewed evidence |
| Background recovery | Full live workflow incomplete | Full live workflow incomplete | Full live workflow incomplete | Runtime not verified by reviewed evidence |

Evidence: [Chat workflow](quality/live-desktop-daily-workflow.md),
[browser approval/Stop/recovery](runbooks/chat-production-journey.md),
[Android direct setup](quality/android-direct-setup-enrollment.md),
[Linux Local native checks](quality/local-setup-enrollment-native.md),
[SSH contracts and limits](product/desktop-connection-paths.md), and
[feature/voice route details](product/routes.md).
Native secure storage varies by platform; [Linux saved-connection storage tests](quality/saved-endpoint-storage-native.md)
do not certify every backend or Android keystore. Screenshots and compiled builds
do not prove live authentication, inference, microphone or screen-reader support.
Fresh on-phone installation/persistent hosting, signed distribution and automatic
updates are not verified. Wing does not install or start Agent.

[Security policy](../SECURITY.md) · [Threat model](security/threat-model.md) ·
[Project overview](../README.md) · [All documentation](README.md)
