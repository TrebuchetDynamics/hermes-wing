# Managed SSH forwarding contract

Status: bounded source contract for DOC-BACKEND-CONTRACT; native application and
live Agent qualification remain open under BACKEND-SSH-CONNECT and
BACKEND-SSH-KEY-NATIVE. This document grants no remote lifecycle authority.

## Scope and source identity

One operation: authenticate an explicitly selected SSH target and forward a local
ephemeral IPv4 loopback listener to that target's `127.0.0.1:<Agent port>`.
Wing then authenticates independently to the existing Agent. No subprocess,
executable or argument vector exists in this operation. There is no remote exec,
installation, restart, token discovery, Agent-file access or Wing Link exchange.

Wing source reviewed at `bfba2dede34612a42d971fd674effdd0f0458815`:
[adapter](../../lib/core/hermes/ssh/ssh_forward_io.dart),
[types](../../lib/core/hermes/ssh/ssh_types.dart),
[controller](../../lib/features/hermes_chat/providers/managed_ssh_connection_controller.dart),
[form](../../lib/features/hermes_chat/widgets/managed_ssh_connection_form.dart) and
[panel](../../lib/features/hermes_chat/widgets/managed_ssh_connection_panel.dart).
The [existing official comparison](../product/desktop-connection-paths.md#official-welcome-local-ssh-and-remote-trace)
pins unmodified Agent `158fd638da1629c8e62caf9ade1515d162def8ab` and its Desktop
subtree. Desktop's `electron/ssh-connection.ts`, its nearest test, and
`src/AGENTS.md` distinguish OpenSSH execution and remote lifecycle from this
smaller Dart TCP operation. That reference remains read-only; this contract does
not import Desktop shell/bootstrap authority or claim OpenSSH-config parity.

## Inputs, trust and credentials

- `ManagedSshConfig` accepts host text of 1–253 characters from its explicit
  ASCII host allowlist, username of 1–128 characters from its username allowlist,
  and SSH/Agent ports of 1–65535. It rejects URLs, path syntax and control characters.
  It is not a saved host or trust record.
- The verifier receives that attempt's configuration and SHA-256 SSH host-key
  fingerprint. Missing verifier, malformed digest and declined review fail closed.
  Password acquisition is gated on accepted trust. The panel requires deliberate
  fingerprint confirmation for this connection; persistent known-host trust and
  changed-key comparison across relaunch are not implemented by this path.
- Password, private key/passphrase and Agent credential are distinct attempt
  inputs. SSH success does not authorize Agent requests. No credential may be
  placed in a URL, argv, clipboard, diagnostic or ordinary preference. Public-key
  copy is the sole key-copy action. Legacy management credentials stay inert.
- Imported key acquisition is a deliberate native file/document selection, not a
  caller-supplied saved path or arbitrary filesystem API. The picker has no
  initial path; the reader caps both reported and streamed bytes at 64 KiB,
  validates the key and bounds supported encrypted OpenSSH KDF work. Selection
  generations reject late picker/read results after replacement or cancellation.
  This limited user-selected read does not grant directory browsing, Agent-home
  reading or path persistence. See [key reader](../../lib/features/hermes_chat/ssh_keys/managed_ssh_key_selection.dart).
- The separately consented generated identity uses existing platform secure storage
  with readback validation; failure has no plaintext fallback. Imported content,
  password and passphrase remain attempt-scoped. Controller/adapter/form cleanup
  drops owned references; Dart strings and library buffers are not securely
  zeroized. Native picker/secure-storage behavior still needs named-target proof.

## Forwarding and lifecycle

The adapter owns one attempt. Repeated Connect returns a typed busy failure;
disposal permanently rejects reuse. Connect defaults to a 20-second overall
attempt deadline, accepts only positive deadlines up to 60 seconds, and applies
handshake/authentication deadlines. Trust and credential callbacks participate in
cancellation/deadline fencing. No automatic reconnect or retry is implied.

Only after SSH authentication does Wing bind `127.0.0.1` with port `0`. The
returned URI contains no credential and is an ephemeral mapping, never a durable
host identity. Each accepted socket forwards only to remote loopback and the
configured Agent port. At most 16 local sockets are retained; excess sockets are
closed. Forward-channel opening has a 10-second timeout. Individual stream
failure closes that stream; it does not log bytes or run a remote command.

Cancel, timeout, disposal and SSH loss close owned sockets, channels and listener;
late dial/bind/channel completions are destroyed. An old lease may close only
itself, not its replacement. The controller binds adoption to an attempt generation
and exact channel origin, clears its credential references, and tears down only
its owned transport on route/mode replacement. It must not disconnect a newer
unrelated Agent connection. SSH teardown is not Agent Stop or authoritative run
completion. Agent-owned work remains uncertain until authoritative readback.

Controller disposal is terminal and idempotent: late Connect callbacks are
rejected before forwarding or credential acquisition. Explicit cancellation on
a live controller remains distinct from disposal and permits deliberate retry.
API adoption publishes its connecting generation before awaiting secure recovery
cleanup. Cancellation or replacement during that wait revokes the old attempt
before client construction or HTTP reads; controller disposal follows the same
path. Three production-channel regressions hold that cleanup pending and exercise
cancel, disposal and replacement. These are deterministic checks, not native SSH
or Android transport qualification.

Adoption-loss follow-through: the controller now watches lease loss before Agent
connection completes, including its asynchronous preflight. Loss clears attempt
credential callbacks and revokes the owning connection; late health completion
cannot advance to inventory or connected state. Replacement connections are not
disconnected and the retired lease is disposed once. Four new deterministic
regressions cover preflight/health loss and replacement ownership. The focused
SSH/form/provider/generated-key/channel union passes 403 tests with eight opt-in
SSH tests skipped; independent native source review approved the source/test
hashes. These are Linux-hosted Dart/widget checks, not native SSH qualification.

The controller also disconnects its already-adopted Agent channel on explicit
cancellation or controller disposal, before releasing the ephemeral listener.
Previously that path closed SSH but left the Agent channel marked connected.
Three deterministic regressions cover cancel, disposal and a replacement opened
while lease cleanup is pending. Route disposal alone still retains an adopted
app-scoped connection; this change does not turn transport teardown into Stop.
Cleanup remains in `finally` if channel disconnection fails.

Controller cancellation also holds Connect admission closed until Agent and
forwarding teardown settle. A rapid second panel cannot capture fresh credentials
or collide with the still-retiring adapter. Deliberate retry becomes available
after cleanup, including a reported cleanup failure; no retry is queued or replayed.
Two deterministic regressions cover pending cleanup and its success/failure exit.
This does not qualify native SSH, durable restoration or forwarded chat.

Durable identity must retain SSH host/port/user, reviewed trust and explicit Agent
profile/session separately from the ephemeral local origin. **This path does not
yet save that SSH target/trust mapping or implement cold-relaunch restoration.**
Do not save a forwarded port as an ordinary endpoint or attach its credential to a
later unrelated listener. BACKEND-SSH-CONNECT and DOC-BACKEND-DISCONNECT-CONTRACT
retain durable mapping, interruption and no-replay acceptance.

The shared Agent channel now clears its in-memory serve read credential on
disconnect or API-transport replacement. Explicit serve Retry cannot reuse the
retired credential against a replacement API origin or change its owner. Three
deterministic regressions cover both switch paths and retained same-origin Retry
after a failed serve read. This prerequisite does not enable Android serve or
persist an SSH mapping.

## Android Agent transport boundary

The explicit serve entry now claims its connection generation before awaiting
secure recovery cleanup, matching the API adoption fence. Disconnect, newer
API/serve intent and abandoned admission prevent obsolete credential-bearing reads.
Storage failure stays sanitized and leaves no credential available for Retry.
Five production-channel regressions cover that prerequisite alone; they did not
select a transport or qualify Android. The explicit read selection below is a
separate implementation slice.

In default API mode, the controller calls `HermesChannel.connect` with the forwarded origin
and separately supplied Agent credential. Production `HermesApiChannel` uses its
advertised health/capabilities/session REST contract. Supported profile/history,
Send, approval and Stop operations depend on that exact connected contract;
SSH login or HTTP health alone proves none of them.

Official Desktop instead uses `serve` REST plus `/api/ws` JSON-RPC. Wing's
existing [fixed serve reader](../../lib/core/hermes/client/hermes_web_read_client.dart)
exposes `/api/profiles`, profile-scoped `/api/sessions` and exact-session history.
Its separately authenticated lifecycle requires a fresh session ticket,
exclusive-submit support, server-request negotiation and captured runtime/stored
session identity. REST credentials/reads are not an RPC grant. Its
[channel integration](../../lib/core/hermes/channel/api_channel/hermes_api_channel_serve_chat.dart)
correlates approvals and reconciles uncertain sessions without resending mutations.
The SSH form now offers an explicit serve-read switch, off by default, with a
separate session-token label. The controller binds that selection to its current
lease and uses the fixed loopback reader on Android as well as other native
clients. API mode never guesses serve after failure. Forwarded mode loads
profiles, sessions and exact-session history only: its chat action is hidden and
channel qualification refuses it. No ticket, Send, approval or Stop is issued.
Existing local Linux chat entry remains unchanged. Forwarded origins and
credentials are never saved as local-conversation recovery pointers.

Planner's call for BACKEND-SSH-CONNECT: deliver the bounded read-only selection
before Android chat qualification. The production-channel fixture tests exercise
profile switching, credential denial, pending-read tunnel loss and replacement
with Android platform selection on a Linux host; they do not authenticate real
SSH or qualify an Android device. Shared serve adoption publishes one connecting
transition while retiring its previous transport, so the controller does not
mistake its own cleanup for an external disconnect. UI regressions check explicit
token labeling and absence of the chat action for forwarded reads.

Next: qualify the separately authenticated chat lifecycle against the current SSH
lease, captured profile/session and transient origin, including ticket denial,
owner mismatch, stale results and interruption with zero implicit mutations.
A fresh ticket must use the existing secret-safe transport, never Desktop's
credential-in-URL technique. Keep forwarded chat unavailable until that slice is
verified. Durable SSH mapping, device/native/live acceptance remain open.

## Failure oracles and qualification

Existing deterministic checks (not live acceptance):

- [adapter tests](../../test/core/hermes/ssh/managed_ssh_test.dart): input rejection,
  unsupported browser, concurrent Connect, disposal, timeout and late dial cleanup.
- [panel/controller tests](../../test/features/hermes_chat/widgets/managed_ssh_connection_panel_test.dart):
  explicit trust, late trust cancellation, mode replacement, separate Agent
  credential, adoption without endpoint persistence and replacement ownership.
- [key tests](../../test/features/hermes_chat/ssh_keys/managed_ssh_key_selection_test.dart)
  and [form tests](../../test/features/hermes_chat/widgets/managed_ssh_connection_form_test.dart):
  bounds, failed reads/unlock, cancellation and stale-selection rejection.
- [opt-in loopback SSH tests](../../test/core/hermes/ssh/managed_ssh_loopback_test.dart):
  absent/mismatched verifier, wrong password, cancelled review, transport loss,
  old-lease disposal, and key/password forwarding. They skip without their owned
  fixture; skipped tests are not host-key/authentication passes.

Run the focused adapter, panel, form, provider and key tests and `git diff --check`
when changing this boundary. Native Linux/Android full-app authentication, picker,
keystore, relaunch, actual Agent operations and interruption need their existing
approved target/access and source-bound receipts. Browser raw TCP remains
unavailable; other native targets are unqualified, not automatically supported by
`dart.library.io`. Preserve external-tunnel access where applicable. Remove or
keep an operation unavailable if its platform cannot preserve host verification,
credential isolation, loopback containment or owner-safe cleanup; never replace
it with shell, public binding or a compatibility backend.
