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
  fingerprint confirmation for an unknown exact host-text/SSH-port pair, then
  readback-verified platform secure storage remembers its algorithm and digest
  (see [remembered host trust](#remembered-host-trust)). Matching pins can
  reconnect without another review. A changed algorithm/digest, malformed pin or
  unavailable storage fails closed; there is no automatic replacement, plaintext
  fallback or trust-reset control. Saved conversation pointers additionally
  require the same reviewed key. OpenSSH known_hosts is neither read nor modified;
  host-key rotation management remains unavailable.
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
still verifies the host key against explicit review or a remembered pin; a saved
fingerprint mismatch fails
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
Unexpected loss of an already-adopted tunnel uses the same cancellation path,
including its admission barrier while Agent retirement/secure cleanup is pending.
Two deterministic regressions cover that window and deliberate retry afterward;
the production-channel case asserts no fresh reads or mutations during retirement.

The same admission barrier now covers channel-origin replacement and channel
connection loss while the SSH lease is still alive. The old direct-dispose path
admitted Connect before lease cleanup finished. Retirement now marks the channel
as replaced and uses cancellation to hold retry closed without disconnecting the
new Agent owner. Two deterministic regressions hold forwarding cleanup pending,
assert no fresh credential capture or replacement mutation, complete the old lease
late, then prove deliberate retry after cleanup. These checks do not establish
native transport or durable restoration.

Concurrent unscoped cancellation callers await that same teardown, including its
failure, instead of observing completion while the owned listener is still closing.
Stale attempt-scoped cancellation remains inert and cannot join or revoke a newer
owner. Four deterministic regressions cover delayed and synchronous-listener
cancellation, hold lease cleanup pending, check that only one Agent disconnect/
lease close occurs, and prove shared success/failure settlement.
Connect remains blocked until settlement; no automatic retry is added.

The low-level adapter now also retains its attempt until socket/listener cleanup
settles. Concurrent and synchronous reentrant disconnect callers join that cleanup
instead of returning early, while Connect remains busy until retirement completes.
Three deterministic regressions cover completion ordering, rejected early redial
with deliberate retry after settlement, and reentry from socket destruction while
credential acquisition is pending. This closes the shared transport prerequisite;
it adds no automatic reconnect, persisted target or native qualification.

The shared Agent channel clears its in-memory serve read credential on
disconnect or API-transport replacement. Explicit serve Retry cannot reuse the
retired credential against a replacement API origin or change its owner. Three
deterministic regressions cover both switch paths and retained same-origin Retry
after a failed serve read.

## Terminal connection feedback

An active unsuccessful acquisition captures only an allowlisted failure category
before owned teardown clears channel state. Advertised API and explicit Android
serve bootstrap rejections retain `HermesConnectionFailureKind` through a
`ManagedSshAgentException`; SSH authentication/trust/timeout retain their separate
`ManagedSshFailure`. Recovery-storage errors are classified at the load/save
operation, never by parsing exception text. Unknown causes remain generic.
No raw response, exception, credential, endpoint or path enters the explanation.

The panel publishes persistent localized feedback only after cleanup settles,
then permits a deliberate fresh-authentication attempt. Its existing semantic
live region and Connect action are revealed through enclosing form/Chat scroll
views without animation or focus theft. Long explanations remain scrollable.
Cancellation, disposal, failed acquisition of an already-busy controller and
superseded owners are not relabeled as Agent authentication failures. A replaced
controller clears the retired form and fences its late result. No retry, fallback
protocol, remote command or Agent mutation is added. See the
[offline feedback receipt](../quality/managed-ssh-failure-feedback.md).

This repairs inspected feedback-loss mechanisms. It neither reproduces the
reported installed-phone failure nor establishes that its SSH target connects.

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

## Saved destination settings

Planner's call for BACKEND-SSH-CONNECT: provide a usable remembered destination
before adding exact profile/session recovery. The production SSH form offers
**Save SSH settings** and **Use saved SSH settings**. Saving validates only the
host, SSH port, username and remote Agent port; it also retains the explicit API
versus serve selection. It does not test SSH or authenticate Agent. One separate
versioned secure-storage slot holds these five values. Conversation pointers live
only in the host-key-bound recovery store described under
[Forwarding and lifecycle](#forwarding-and-lifecycle). It never holds passwords,
keys, key paths, Agent credentials, trust decisions or ephemeral forwarded origins. Saving replaces only this slot after explicit intent and
verifies readback; no legacy data is read or removed and no plaintext fallback
exists. App-isolate writes are serialized, not cross-process transactions.

Loading is deliberate and never initiates network work. It replaces the form's
settings and clears attempt secrets/key selection before any new Connect. Unknown,
malformed or unavailable records leave the draft and stored bytes untouched and
show sanitized status; manual setup stays available. Cancel, disposal or newer
transport/connection intent fences a delayed load. An explicitly started native
save may settle after cancellation; its obsolete result cannot change the form.
Remembered settings confer neither host trust nor Agent authorization: Connect
still verifies the host key and requires fresh permitted authentication.

Deterministic tests exercise save/load across store and form recreation, mode
restoration, secret exclusion/clearing, readback failure and delayed results. This
is Linux-hosted mocked secure storage and Flutter widget evidence, not native
keystore, cold-process restoration or actual SSH qualification. Native full-app
qualification stays open in DOC-BACKEND-DISCONNECT-CONTRACT. No canonical Bot Chat
pointer or replacement domain state is introduced. The serve choice is offered
only where the form allows serve transport (Android); elsewhere a saved serve
choice loads as the advertised API transport.

## Remembered host trust

Planner's call for BACKEND-SSH-CONNECT: complete durable host-key comparison in
its existing production panel without saving an ephemeral Agent endpoint. Official
Desktop's read-only `electron/ssh-connection.ts:22–24` uses OpenSSH accept-new and
rejects changed keys; `ssh-connection.test.ts:238–244` tests changed-key error
classification. Wing instead retains explicit first-use fingerprint review and
uses its platform secure storage, not subprocesses or the user's known_hosts.

[The store](../../lib/core/hermes/ssh/secure_managed_ssh_host_trust_store.dart)
keys a separate versioned slot by SHA-256 of the exact host text and SSH port.
Only the algorithm/digest are stored; usernames, Agent ports, local forwarded
origins, credentials and session IDs never enter that record. Host aliases are
separate trust scopes; no DNS/case/IPv6 normalization or migration is implied.
Concurrent app-isolate confirmations re-read inside the commit lane so a second
review cannot overwrite a conflicting winner. This is not cross-process CAS;
multiple writers/isolate-level trust management remain unsupported.

Cancelled/obsolete reads and reviews cannot admit a connection or begin a new
pin write. Once a current, explicit review has committed a native storage write,
that reviewed pin may finish saving despite cancellation; the obsolete attempt
still returns false and cannot authenticate or adopt Agent. Invalid/unreadable
pins remain untouched. No legacy slots are read, enumerated or deleted.

Deterministic store and production-panel regressions cover remembered trust
across store/controller recreation, changed keys, host/port isolation, corruption,
storage failure/readback, concurrent conflict and cancellation. These are mocked
secure storage plus Linux-hosted Dart/widget execution, not native keystore or
SSH/relaunch qualification. Native credential acquisition and the complete
host/profile/session recovery journey remain open under the existing tasks.

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
