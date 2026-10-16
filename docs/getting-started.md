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

Wing needs an Agent that supports the chat features it uses; a healthy listener
alone does not prove it can chat. Ask the host administrator if a feature is
unavailable. Never patch Agent or install a fallback. The
[connection contract](product/desktop-connection-paths.md) has technical details.

Configure the chosen profile/provider/model through
[Agent's documentation](https://hermes-agent.nousresearch.com/docs/).
**Ready to proceed:** you have an approved endpoint, separate Agent token,
trusted transport and configured model. Only an actual reply verifies generation.

## Direct Agent connection

Have a reachable Hermes Agent API and its approved profile-bound credential.
Configure Agent and provider access through supported Agent procedures. See [Agent preparation](#prepare-your-agent).
Do not copy personal credentials or expose an API to a public interface to bypass
setup. Never copy credentials into URLs or the clipboard. Remote native HTTP requires
the existing explicit review and trusted encrypted network; browser access requires
trusted HTTPS and permitted CORS.

On Android, the fresh welcome offers these choices in order:

1. **Connect via SSH** — connect to Agent on another computer. Verify the host
   fingerprint before choosing **Trust this connection**; SSH login alone does not
   prove Agent readiness. Enter SSH details and the separate Agent token.
2. **Connect to Remote Hermes** — enter the host-provided Agent endpoint and its
   credential in the masked field. Do not guess an address or embed a token.
3. **Use this phone (Termux)** — follow **This phone** guidance or choose
   **Agent already running — skip guide**, then enter its Agent token and choose
   **Add Hermes**. The [direct Termux runbook](runbooks/android-termux-local-agent.md)
   covers manual setup; completion is not installation or readiness proof.

Android has no **Get Started** welcome action. On desktop/web, **Get Started**
opens Local; SSH and Remote remain separate choices. On Linux, review the default
`~/.hermes` metadata discovery or choose **Choose another Hermes home**. This is
not a Hermes Project or conversation working directory: it does not start Agent,
read its files, save/send the chosen path or bind its runtime to that folder.
Discovery alone does not prove installation, authentication or model readiness.
Enter the running Agent's loopback endpoint and separate masked Agent API token.
Web Local cannot inspect host folders; loopback refers to the browser's device.

Local and Remote forms offer **Test connection**, a read-only capability check.
It does not save credentials, activate Chat, send a prompt, or prove generation.
**Connect step by step** guides setup; browser setup shows Wing's exact origin for
the Agent CORS allowlist. A browser network error may hide CORS/TLS details and
does not establish that the token is wrong. Named-profile gateways may need
`/p/<profile>` in the base URL; do not append `/v1`. Wing cannot read Agent secrets.

With a saved connection, choose **Add Hermes** from Chat. **Help** explains what
to request from the host; **Copy instructions** copies public guidance only. Missing
capabilities remain unavailable. Correct denied credentials, then choose explicit retry or cancel.
Wing never silently replays a mutation. Select a supported profile/session
and model, then send one deliberate message.

For saved connections, choose **Edit saved Agent connection**. A changed Agent URL
never reuses the old credential. **Test** is read-only; **Save** confirms local
persistence, not Agent readiness. Cancel preserves the working connection.

The native SSH form offers **Private key** and **Password**. Selected imported keys
are attempt-scoped. A generated key stays in secure storage; share only **Copy public
key**, never the private key. Storage failure has no plaintext fallback. Browser SSH
is unsupported. Full-app SSH authentication on Linux/Android is not verified; a
terminal login is not proof of Wing access. See the
[SSH key guidance](product/desktop-connection-paths.md#private-key-ux-desktop-reference-and-wing-adaptations).
**Wing Link is not required.** Missing Agent capabilities do not justify a fallback.

Remote HTTPS and VPN use the Agent token, not a provider key. Browser OAuth is
unsupported; an OAuth-only server cannot use this flow. If access is denied, confirm
the endpoint and Agent token with the administrator, then retry or cancel.

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
- **Feature unavailable:** ask the Agent administrator whether it supports that
  operation. Do not install deprecated management software as a substitute.

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

This is an alpha, not a platform certification. Simulated checks use fake Agent
responses; native UI checks are not authenticated Agent sessions. Live evidence
must identify the tested build and route; one platform does not qualify another.

| Outcome | User-facing UI | Simulated / native checks | Authenticated live evidence |
| --- | --- | --- | --- |
| Chat, streaming, and tools | Android, web, Linux implemented | Android/Linux simulated; Web Chromium simulated | Full chat-to-tool workflow not verified |
| Approvals and Stop | Android, web, Linux implemented | Android/Linux simulated; Web Chromium journey | Full live journey not verified |
| Local preparation | Linux metadata-only; Android Termux guide | Android simulated; Linux GTK simulated | Termux install/auth and Linux Agent auth not verified |
| SSH | Android/Linux native interface; browser unsupported | Contract/UI checks; not full app login | Android/Linux full-app authentication not verified |
| Voice | Experimental, platform-dependent | UI/platform checks vary | No blanket microphone or acoustic qualification |
| Notifications | Not a blanket support claim | Platform checks do not prove delivery | Delivery not verified |
| Background recovery | Recovery UI is partial | Fixture checks only | Full detached-run recovery not verified |

Evidence: [Chat workflow](quality/live-desktop-daily-workflow.md),
[browser approval/Stop/recovery](runbooks/chat-production-journey.md),
[Android direct setup](quality/android-direct-setup-enrollment.md),
[Linux Local checks](quality/local-setup-enrollment-native.md),
[SSH route details](product/desktop-connection-paths.md), and
[voice routes](product/routes.md). Native secure storage varies by platform;
[Linux storage tests](quality/saved-endpoint-storage-native.md) do not certify
other backends. Screenshots and builds do not prove live authentication, inference,
microphone, screen-reader, or notification support. Fresh on-phone hosting, signed
distribution, and automatic updates remain unverified. Wing does not install or
start Agent.

[Security policy](../SECURITY.md) · [Threat model](security/threat-model.md) ·
[Project overview](../README.md) · [All documentation](README.md)
