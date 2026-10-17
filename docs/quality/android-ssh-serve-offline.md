# Android SSH serve selection — offline evidence

Date: 2026-10-17. Task: BACKEND-SSH-CONNECT. This is deterministic client
behavior evidence, **not native Android or Linux full-app qualification**.
The task's separate native-target/review acceptance remains open.

## Implemented boundary

The Android production SSH form now offers an explicit **Read an already-running
Hermes serve backend** choice. The default remains the advertised Agent API.
Changing that choice clears the old Agent token; serve selection requires its own
host-provided **Hermes serve session token**, not `API_SERVER_KEY`, an SSH password
or a provider key. Enter the actual already-running remote listener port. Wing
never guesses protocols, discovers credentials, starts Agent or runs remote shell
commands. SSH host-key review and SSH authentication still precede Agent access.

The app-scoped [controller](../../lib/features/hermes_chat/providers/managed_ssh_connection_controller.dart)
reuses the existing native forward and
[channel reader](../../lib/core/hermes/channel/api_channel/hermes_api_channel_serve_reads.dart)
for profiles, explicit profile selection, sessions and history. Connect grants
reads only. **Enable chat on this session** deliberately selects the existing
[ticket-authenticated lifecycle](../../lib/core/hermes/channel/api_channel/hermes_api_channel_serve_chat.dart).
A fresh session ticket, exclusive-submit capability, approval negotiation and
matching profile/runtime/stored session ownership remain mandatory. Denial leaves
reads intact and chat unavailable; there is no fallback to credential-in-URL RPC.

Forwarded serve recovery is memory-only while that lease remains current. Neither
the ephemeral loopback origin nor its token is saved by the durable serve recovery
store. Loss during acquisition invalidates the attempt before late reads can be
adopted. Adoption and teardown require the channel's acquired connection and
recovery generations, not merely a matching origin or first notification. A
same-origin Retry that supersedes delayed secure-storage cleanup keeps ownership.
Conversely, if replacement has reserved recovery ownership but is still clearing
secure storage, obsolete SSH reads cannot publish results or disconnect and
invalidate that replacement's pending acquisition. Cleanup checks both generations.
Loss after adoption disconnects its owned channel; Retry cannot dial the
retired loopback listener. Reconnect requires deliberate SSH acquisition and fresh
Agent authentication, never automatic Send, approval or Stop replay.

Linux's existing API SSH form, explicit local serve entry and Linux-only cold
restoration gate are unchanged. Browser and unqualified native targets do not
receive managed forwarding controls; externally managed tunnels remain usable
through the Remote Agent connection form. Native platform qualification is not
inferred from Dart IO availability or a platform override in a test.

## Source trace

Starting Wing tree: `a7a7cb88a8e39368e2410292e9ddcec142ec4f72`.
This retry reuses the scoped implementation from held candidate `98ce4f48` and
repairs the stale-read cleanup race identified during its integration review.
Read-only Agent/Desktop reference: `158fd638da1629c8e62caf9ade1515d162def8ab`.

- Existing [forwarding contract](../security/managed-ssh-forward-contract.md),
  especially its Android implementation direction. This receipt implements that
  offline direction; it does not convert the contract's pending native proof into
  a pass.
- Official Desktop `apps/desktop/electron/ssh-connection.ts` and its nearest test:
  Desktop's OpenSSH/remote lifecycle is not imported by this smaller Dart forward.
- Agent `hermes_cli/web_server_chat.py` and
  `tests/hermes_cli/test_dashboard_auth_ws_auth.py`: ticket authentication and
  secret-safe WebSocket subprotocol contract, distinct from successful REST reads.
- Agent `tests/tui_gateway/test_resume_live_profile_scope.py`: a stored session ID
  alone does not authorize adoption of another profile's runtime.

No upstream reference, installed Agent or Agent state was changed.

## Offline checks

Run the focused task targets, including
[`managed_ssh_serve_test.dart`](../../test/features/hermes_chat/providers/managed_ssh_serve_test.dart),
plus existing serve read/chat/restoration and connection-intent regressions:

```sh
flutter test --no-pub --concurrency=1 \
  test/core/hermes/ssh \
  test/features/hermes_chat/widgets/managed_ssh_connection_form_test.dart \
  test/features/hermes_chat/widgets/managed_ssh_connection_panel_test.dart \
  test/features/hermes_chat/providers/managed_ssh_provider_test.dart \
  test/features/hermes_chat/providers/managed_ssh_serve_test.dart \
  test/features/hermes_chat/ssh_keys/managed_ssh_key_selection_test.dart
flutter test --no-pub --concurrency=1 \
  test/core/hermes/channel/hermes_local_serve_reads_test.dart \
  test/core/hermes/channel/hermes_local_serve_chat_test.dart \
  test/core/hermes/channel/hermes_local_serve_restoration_test.dart \
  test/core/hermes/channel/hermes_connection_intent_test.dart
flutter analyze --no-pub
git diff --check
```

Final offline results: **58 focused passes**, with eight opt-in SSH cases skipped
in that command; **21 existing serve/connection-intent passes**; and **four SSH
host-trust/authentication/cancellation passes** with the owned fixture enabled.
Analysis, changed-Dart formatting, Python fixture compilation and diff checks pass.

The new cases exercise explicit form selection and token separation, Android-only
serve composition, profile/history reads, intentional exact-owner Send, zero
recovery-store saves, REST rejection, ticket denial, runtime profile mismatch,
same-origin replacement during delayed storage cleanup, stale reads completing
while replacement waits on secure storage, uncertain Send recovery without duplicate
submission, loss during acquisition and loss after chat qualification. The stale-read
regression failed against the held candidate and passes with recovery-generation
cleanup fencing. Tests substitute only the SSH lease in that wire journey;
HTTP/ticket/RPC and channel/controller behavior
are production code. Android is a deterministic Flutter target override on a
Linux host, not an Android runtime execution.

The owned Python SSH fixture additionally exercised missing verifier, declined
fingerprint, wrong password and cancellation during host review through dartssh2.
Its listeners use reserved worker ports when `AUTOWORK_PORT_BASE` is set. The
ordinary task test command skips its opt-in cases without `MANAGED_SSH_FIXTURE`;
skips are not passes. Its successful-forwarding cases were not run in this receipt.

## Still unqualified / unsupported

- No Android device was attached. The existing isolated Android native journey,
  actual network SSH, full-app profile/history/chat, interruption, picker and
  keystore qualification require the separately authorized device/controlled
  target. Linux full-app acceptance must likewise be preserved with named-target
  evidence; these tests do not replace it.
- The existing isolated key journey covers the advertised API read-only path,
  not this serve selection. It cannot be cited as proof of serve chat.
- Host trust is reviewed anew for each connection. Durable known-host storage,
  saved SSH target/profile/session mapping and cold SSH relaunch are not offered.
  In particular, an ephemeral forwarded port is never a durable Agent identity.
- Terminal SSH login, the owned SSH failure fixture and widget/wire tests do not
  close BACKEND-SSH-CONNECT or BACKEND-SSH-KEY-NATIVE's live/review gates.
