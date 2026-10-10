# Desktop connection paths

> Reference correction: [official Desktop authority](../quality/official-desktop-reference.md). Prior Desktop source citations and parity conclusions in this document are withdrawn. Wing test results remain historical behavior evidence only.


Status: source-backed comparison and development managed-SSH implementation.
The owner requested Local, SSH and Remote connection paths, starting with Desktop
research. This document records that research and the current key-UX gaps. It does
not qualify native Linux/Android live SSH, remote OAuth or native installation.

[Product requirements](prd.md#connection-path-requirements) own the required
outcomes. The [technical design](../spec.md#connection-path-design) owns integration
boundaries. The [test plan](../test-plan.md#connection-path-verification) owns
verification. [Root TODO](../../TODO.md#now--next) owns bounded follow-up entries.

## Source and evidence

Read-only Desktop reference: `withdrawn reference revision`.
This identifies the inspected checkout, not the latest release or a clean-tree
snapshot. Existing upstream changes were preserved. No Desktop tests, installer,
SSH connection, OAuth login or live Agent workflow ran during this research.

| Path | Desktop behavior | Source |
| --- | --- | --- |
| Local — Get Started | Detect installation, offer adoption or install/update, confirm installation, stream progress, then enter provider setup or chat. | [Welcome](../quality/official-desktop-reference.md#withdrawn-evidence), [App](../quality/official-desktop-reference.md#withdrawn-evidence), [Install](../quality/official-desktop-reference.md#withdrawn-evidence), [installer](../quality/official-desktop-reference.md#withdrawn-evidence): `checkInstallStatus`, `verifyInstall`, `runInstall`. |
| Connect via SSH | Collect host, SSH port, username and optional key-file path. Test a temporary forward, save the connection, then prepare remote service access. | [Welcome](../quality/official-desktop-reference.md#withdrawn-evidence), [IPC](../quality/official-desktop-reference.md#withdrawn-evidence): `test-ssh-connection`, `prepareSshTunnel`; [tunnel](../quality/official-desktop-reference.md#withdrawn-evidence). |
| Connect to Remote Hermes | Accept a server URL, detect token or browser OAuth authentication, authenticate and check connectivity. | [remote auth](../quality/official-desktop-reference.md#withdrawn-evidence): `probeRemoteAuthMode`, `openRemoteOAuthLogin`; [IPC](../quality/official-desktop-reference.md#withdrawn-evidence): `connect-remote-gateway`; [Hermes client](../quality/official-desktop-reference.md#withdrawn-evidence): `testRemoteConnection`. |

Desktop's [connection registry](../quality/official-desktop-reference.md#withdrawn-evidence) supports
named saved connections and Settings selection, editing, testing and removal.
Conversation identity includes connection, profile and session. Selecting another
host must not retarget an existing conversation or pending request.

## SSH is managed host access in Desktop

Desktop invokes system OpenSSH with key-file authentication, `BatchMode=yes`,
keepalives and `StrictHostKeyChecking=accept-new`. Its exposed onboarding path does
not implement a password/passphrase prompt. Host trust follows OpenSSH
trust-on-first-use, not an application fingerprint-review screen.

The forward targets remote loopback. Desktop prefers local port 18642, with an
available alternative when occupied. One global tunnel is shared. Same-target
starts are reused or deduplicated. Connection switches stop the tunnel, and
inactive SSH conversations cannot retarget it. See
[`ssh-tunnel.ts`](../quality/official-desktop-reference.md#withdrawn-evidence).

[`prepareSshTunnel`](../quality/official-desktop-reference.md#withdrawn-evidence) prefers a remote
dashboard, normally on port 9119, with dashboard-session authentication. If
unavailable or legacy mode is selected, it can enable gateway API credentials,
start or restart the gateway and forward to its API port. Dashboard and legacy
API surfaces are distinct. The onboarding form's remote service default is 8642.

[`sshStartDashboard`](../quality/official-desktop-reference.md#withdrawn-evidence) launches a remote
loopback dashboard through a shell. The remote process can outlive the local
connection. Stopping a tunnel is not proof that the remote service or Agent run
stopped. Welcome's initial tunnel test requires an existing service to answer
health/status before later preparation. Successful SSH authentication alone does
not pass that test, and health alone does not prove authenticated chat.

## Private-key UX: Desktop reference and Wing adaptations

Desktop stores a key-file **path**, not imported private-key bytes, in its
`SshConnectionConfig` and connection registry. Welcome and Settings both show a
plain optional path input with `~/.ssh/id_rsa` as the placeholder. The inspected
forms do not offer a key picker, key generation, public-key export or passphrase
field. See [Welcome](../quality/official-desktop-reference.md#withdrawn-evidence),
[ConnectionPane](../quality/official-desktop-reference.md#withdrawn-evidence),
[settings persistence](../quality/official-desktop-reference.md#withdrawn-evidence)
and [config normalization](../quality/official-desktop-reference.md#withdrawn-evidence).

The tunnel selects the supplied path or the home directory's `.ssh/id_rsa`,
checks file existence, and passes it to system OpenSSH through `-i`.
`buildSshArgs` also uses `BatchMode=yes` and `StrictHostKeyChecking=accept-new`.
No application passphrase prompt or explicit SSH-agent selection is wired in
this inspected path. An unlocked identity available to OpenSSH might work, but
that requires runtime qualification. The literal `~` placeholder is not expanded
by the inspected `existsSync` check or argument builder. Do not copy that input
ambiguity into Wing. Desktop's temporary Test checks forwarded HTTP health,
not SSH authentication alone. See
[tunnel implementation](../quality/official-desktop-reference.md#withdrawn-evidence).

Wing's native Dart transport accepts ephemeral private-key and passphrase
callbacks through `ManagedSshCredentials`. The development form now implements
Private key / Password controls, deliberate selection and encrypted-key input.
Selected content is bounded to 64 KiB, including actual streamed bytes. Cancelled,
replaced or disposed picker results cannot restore a selection. The form parses
keys before authentication and releases selected secrets on completion or failure.
OpenSSH bcrypt keys are limited to 1–64 rounds. Other unsupported formats require
explicit password fallback.
See [transport](../../lib/core/hermes/ssh/ssh_forward_io.dart) and
[form](../../lib/features/hermes_chat/widgets/managed_ssh_connection_form.dart).
The [graph/source comparison](../quality/graphify-wing-recomparison.md) is an earlier
snapshot, not the final implementation receipt. Fresh parent verification passed
72 focused Flutter tests. Native chooser and full-app qualification remain open.

Implemented first key-authentication increment; native execution not yet qualified:

- Keep Desktop's host/port, username, key choice and service-port grouping.
  Add an explicit **Private key / Password** choice instead of an ambiguous path.
- Linux: use deliberate native file selection. Read only the selected file with
  bounded size. Show a safe filename and public fingerprint, not full paths or
  private-key contents. Do not scan the user's `.ssh` directory automatically.
- Android: use the system document picker and its returned content. Do not ask
  for a Linux path, assume persistent document access, require Termux/OpenSSH,
  or copy the agent environment's private key into the phone.
- Ask for an obscured passphrase only when the selected key requires one.
  Separate wrong passphrase, unsupported key and SSH authentication failures
  through sanitized messages. Keep password fallback deliberate.
- First increment: selected key and passphrase are attempt-scoped. Clear their
  references on cancellation, failure and disposal. Retrying requires deliberate
  re-entry as needed. Do not promise remembered keys or automatic relaunch login.
- Keep explicit host fingerprint review and reject changed or unreviewed keys.
  Desktop's automatic first-use trust is not Wing's trust policy.
- Keep the Agent token separate. SSH success is not authenticated Agent readiness.
  Never bootstrap services, discover remote credentials or patch Agent.

The later owner-requested increment adds **Generate SSH key**, consent,
**Use saved Wing key** and public-only copy. Generated Ed25519 keys use a separate
versioned platform-secure-storage entry; generation validates readback and reuses
an existing valid identity without replacing it. Imported keys remain attempt-scoped.
Persistent picker access and SSH-agent integration remain future work. The
[parent receipt](../quality/connection-key-generation-help.md) records 132 focused
union tests and clean full analysis, not native secure-storage qualification. Linux and Android must each exercise
the actual app's key-authentication path and recovery against an approved host.
A terminal login from the host itself proves neither phone reachability nor Wing
key ownership. No private keys or personal credential stores were read here.

## Current Wing support and gaps

Wing Link is deprecated under the [product decision](../adr/product.md#wing-link-deprecation).
Linux Local must default to the local Hermes home with deliberate alternate-folder
selection. Android Local now provides staged same-phone setup guidance and a
deliberate existing-Agent skip path. Both are wired into the production chooser,
with selectable/copyable public connection Help. Discovery is metadata only; phone
setup is manual, not a qualified installer. Native readiness, chooser and phone
setup remain unqualified. Retained Link consumers and packaging still need removal.

Owner correction, 2026-10-07: Local, SSH and Remote must connect directly to
Hermes Agent without mandatory Wing Link installation, pairing or credentials.
This is accepted intent, not a shipped first-run redesign or managed SSH claim.

Wing now groups three primary choices in this order: **Local**, **SSH**
and **Remote**. Remote contains **Remote HTTPS** and **VPN / NetBird /
Tailscale** subchoices. Selecting Remote preserves an already selected VPN mode.
The [connection layout](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart)
and [English copy](../../lib/l10n/app_en.arb) define the presentation.
The [auth-recovery regression](../../test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart)
now expects three primary choices and nested VPN access.
The [entry-label receipt](../quality/connection-entry-labels.md) records exact
rendered labels, 13 widget passes and four fresh compiled Chromium journeys.
The Chat/Add Hermes terminology slice is qualified. The current development
worktree also routes Chat Add directly to the form and places **Add Hermes** before
optional setup/pairing in enrollment. The later [first-run receipt](../quality/direct-first-run.md)
records 123 focused widget passes, four dedicated widget passes and ten compiled
Chromium journeys on Linux. Six Agent-only traces record no management requests
or mutations. This bounded deterministic evidence does not establish main delivery
or Android/live authentication. The [native first-run receipt](../quality/direct-first-run-native.md)
adds four passing Linux GTK fixture journeys with synthetic denial, explicit
keyboard retry and zero management/mutation attempts. Managed connection parity
remains incomplete.

- Current optional management setup uses existing typed Wing Link inspect/setup operations where
  supported. See [enrollment](enrollment.md).
- Remote and VPN modes connect to an explicitly supplied Agent endpoint.
  Pairing separately establishes Wing Link management authority. Remote browser
  OAuth is not established by Desktop's OAuth implementation.
- The current development SSH form creates native Dart forwarding, explicitly
  reviews the host key and adopts the direct Agent channel. It does not require
  an external tunnel or CLI QR. Password authentication and a partial private-key
  selection path are exposed. Key acquisition/recovery acceptance, saved SSH
  relaunch and native Linux/Android live qualification remain open. See the [controller](../../lib/features/hermes_chat/providers/managed_ssh_connection_controller.dart)
  and [production panel tests](../../test/features/hermes_chat/widgets/managed_ssh_connection_panel_test.dart).

The previous four-primary-choice presentation is historical. Four transport modes
remain available through the new grouping. External-tunnel connection is an
existing path, but it is not Desktop's managed SSH onboarding.

## Planned delivery and proposed defaults

Qualify remaining native save recovery and live behavior, then deliver the implemented direct first-run entry
without a pairing detour. Reuse existing Agent authentication, secure storage and owner-fenced
recovery. Optional management failure must not gate a valid Agent connection. Missing Agent APIs are unsupported
features, not a reason to require Wing Link.

The required product outcome is three primary entry paths: **Local**, **SSH** and
**Remote**. Retain VPN connectivity within Remote rather than removing it.
Reuse current setup, enrollment, endpoint storage and channel contracts.

The implemented managed-SSH slice uses native Dart TCP forwarding to an
already-configured, authenticated Agent endpoint. It runs no OpenSSH subprocess.
Browser raw TCP is explicitly unsupported. The next key-UX increment above must
preserve explicit host trust, connection ownership and cleanup. This research
adds no remote-command or host-management authority.

Reconnect must recover the same host/profile/session without mutation replay.
Do not store an ephemeral forwarded origin as the durable remote-host identity
without defining how restart and port replacement preserve ownership. Keep Agent
and Wing Link credentials, connections and lifecycle authority separate.

Remote bootstrap, installation and service changes are separate host-management
operations. This first connection slice does not silently provision credentials,
restart a remote gateway or install Hermes. Existing Docker/WSL backend requirements
remain in the parity backlog, not in the initial SSH slice.

Desktop implementation techniques that must not be copied include arbitrary
remote shell/configuration/file access, Agent source patches and secret-bearing
command arguments or URLs. See
[`ensureSshDashboardCompatibility`](../quality/official-desktop-reference.md#withdrawn-evidence)
and the [immutable Agent boundary](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent).

Primary grouping is implemented and has bounded deterministic evidence.
The managed-SSH defaults define backlog scope, not a reviewed native contract or
shipped feature. Managed SSH, native launch, live remote authentication and full
three-path qualification remain unverified or unimplemented as stated above.
