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
  fingerprint confirmation for an unknown exact host-text/SSH-port pair, then
  readback-verified platform secure storage remembers its algorithm and digest.
  Matching pins can reconnect without another review. A changed algorithm/digest,
  malformed pin or unavailable storage fails closed; there is no automatic
  replacement, plaintext fallback or trust-reset control. OpenSSH known_hosts is
  neither read nor modified. Host-key rotation management remains unavailable.
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

Durable identity must retain SSH host/port/user, reviewed trust and explicit Agent
profile/session separately from the ephemeral local origin. **This path saves a
host-key pin, but not the SSH target/Agent-credential/profile/session mapping or
cold-relaunch restoration.**
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
clients. API mode never guesses serve after failure. Initial forwarded mode loads
profiles, sessions and exact-session history without mutations. A deliberate
**Enable chat on this session** action now negotiates the existing fixed chat
contract: a fresh ticket in WebSocket subprotocols (never URL credentials), exact
exclusive-submit and approval-request support, then captured profile and durable/
runtime session identity. Ticket denial or missing negotiation leaves reads
available and Send disabled. SSH or REST success does not authorize chat.
Forwarded origins and credentials are never saved as local-conversation recovery
pointers, including before Send, approval or Stop. Existing local Linux recovery
persistence stays separate.

Planner's call for BACKEND-SSH-CONNECT: extend the existing separately authenticated
lifecycle rather than introduce another transport or persist an ephemeral port.
The prior read-only slice remains its historical qualification. Its production
channel now permits explicit chat negotiation while connected; the shared UI
uses the same action gate. Authentication and protocol semantics were traced to
read-only Agent `158fd638da1629c8e62caf9ade1515d162def8ab`:
`hermes_cli/dashboard_auth/routes.py:485–493` mints session-authenticated single-use
tickets; `hermes_cli/web_server_chat.py:207–222,299–316` accepts one ticket-bearing
subprotocol and reflects only the stable protocol. Nearest upstream coverage is
`tests/hermes_cli/test_dashboard_auth_ws_auth.py`. Agent remains unmodified.

Linux-hosted deterministic production-channel checks with Android platform
selection cover ticket denial, missing exclusive-submit support, exact-owner Send,
approval and Stop, profile replacement, held qualification during tunnel loss or
origin replacement, and uncertain-send reconciliation with zero replay. No
forwarded recovery pointer is saved. Widget checks retain the explicit action
gate. These fixtures do not authenticate real SSH, execute Agent inference or
qualify an Android device. Native/full-app SSH and durable mapping, trust and
relaunch acceptance remain open under the existing tasks; reconnect after tunnel
loss still requires deliberate SSH setup rather than reopening a retired port.

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
