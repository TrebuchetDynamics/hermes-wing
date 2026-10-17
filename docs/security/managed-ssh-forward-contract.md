# Managed SSH forwarding contract

Status: source contract including DOC-BACKEND-DISCONNECT-CONTRACT recovery.
Deterministic checks are not Android/native or live Agent qualification. This
document grants no remote lifecycle authority. See the
[interruption runbook](../runbooks/managed-ssh-disconnect-recovery.md).

## Scope and source identity

One operation: authenticate an explicitly selected SSH target and forward a local
ephemeral IPv4 loopback listener to that target's `127.0.0.1:<Agent port>`.
Wing then authenticates independently to the existing Agent. No subprocess,
executable or argument vector exists in this operation. There is no remote exec,
installation, restart, token discovery, Agent-file access or Wing Link exchange.

Current Wing implementation:
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
  fingerprint confirmation for this connection. Saved conversation pointers
  additionally require the same reviewed key; this is not an OpenSSH known_hosts
  import, automatic trust grant, or host-key rotation workflow.
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

The [secure pointer store](../../lib/core/hermes/setup/secure_managed_ssh_recovery_store.dart)
retains at most 32 exact SSH host/port/user/Agent-port/protocol records, reviewed
fingerprints and selected Agent profile/optional session, with at most 32
unresolved profile/session fences per target. Navigation and clearing the current
selection never erase another session's uncertainty. It stores neither forwarding
origin nor SSH/Agent authentication. Other hosts' pointers
survive selection changes. Invalid/full/unavailable storage fails closed; there
is no plaintext fallback or silent eviction. Legacy/direct endpoint slots are
untouched by this store. No management or host-secret discovery is performed.

Retry reopens the current target for fresh authentication. Reentering the exact
same target also loads its secure pointer, including after controller recreation;
there is no automatic cold-start SSH dial or saved-SSH chooser. Every connection
still requires deliberate fingerprint review; a saved fingerprint mismatch fails
before Agent acquisition and cannot silently retarget the old conversation. A
changed host or protocol is a different owner, not permission to reuse credentials.
Empty selections retain the target without inventing a session.

Unexpected loss revokes channel ownership and retains the cached selection as an
error, not a connected/writable Agent. Explicit Disconnect closes the captured
channel before awaiting tunnel cleanup; informational state changes cannot keep
it alive, and old close completions cannot disconnect a replacement. No teardown
operation sends Agent Stop, restarts a service, or resolves a run's outcome.

Advertised API restoration defers both bootstrap and profile session selection
before restoring the exact session. Its detached-run scope is an opaque hash of
the verified SSH owner, never the ephemeral origin. An uncertainty pointer blocks
Send until matching authoritative terminal run status and history resolve the
lease. Terminal events on a healthy session-chat stream also require successful
canonical history before settlement. Local idleness, stream failure and failed
history reads never settle work; recovery handles remain available until readback
and secure settlement succeed. Unknown submissions without a resolvable run
identity remain fenced; transcript history alone is not proof of idle. No old transient lease is guessed
or migrated to a new host. Native serve restoration similarly retains uncertainty
until its canonical read/replay barrier. Neither path replays mutations.

## Android Agent transport boundary

The controller selects `connectForwardedApi` or `connectForwardedServeReads`
explicitly with the forwarded origin and separately supplied Agent credential.
The advertised API path uses its health/capabilities/session REST contract. Supported profile/history,
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
The Android SSH form deliberately selects either advertised Agent API or native
serve reads. The forwarded serve entry binds every acquisition/read to the
current SSH lease and channel owner, restores the saved exact profile/session,
and never persists its local origin/token in the Linux serve-recovery slot.
Chat still requires separate fresh-ticket and owner qualification. Before Send
or Stop, the forwarded channel awaits secure uncertainty persistence; failure
prevents that mutation. Retry never submits a prompt, settles an approval or
interrupts a run. Fresh tickets use the existing secret-safe transport, never
Desktop's credential-in-URL technique. Linux direct serve entry/restoration and
browser raw-TCP restrictions are unchanged. Platform overrides and fixtures are
not native Android support evidence.

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
