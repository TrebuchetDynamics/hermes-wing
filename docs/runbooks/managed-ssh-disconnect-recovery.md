# Managed SSH interruption and explicit recovery

Status: DOC-BACKEND-DISCONNECT-CONTRACT offline implementation. Native Android,
physical keystore, Wi-Fi loss and live Agent acceptance remain **NOT_CHECKED**.
Android away/process-death qualification remains a separate task.

## Behavior and source

- The [forward](../../lib/core/hermes/ssh/ssh_forward_io.dart) closes only its own
  sockets/channels/listener. It runs no child process, remote shell or service
  command. Here, “child exit” means loss of the owned SSH transport.
- The [controller](../../lib/features/hermes_chat/providers/managed_ssh_connection_controller.dart)
  captures acquisition ownership, fences late trust/storage/network completions,
  and revokes the owned channel before awaiting explicit teardown. An old close
  cannot tear down a newer channel, including one at the same local origin.
- The [secure pointer](../../lib/core/hermes/setup/secure_managed_ssh_recovery_store.dart)
  preserves host, ports, user, protocol, reviewed fingerprint and exact Agent
  profile/optional stored session. It contains no forwarding port or credential.
  Host switches preserve other pointers; changed fingerprints fail closed.
  Unresolved profile/session fences are separate from the current navigation
  pointer, so selecting another conversation or clearing selection cannot erase
  uncertain work.
- After unexpected loss, public Chat Retry reopens the same SSH target with blank
  authentication fields. Supply fresh SSH authentication and the Agent credential,
  then review the host key. No automatic SSH dial or credential reuse occurs.
  Ordinary Disconnect retains the pointer; deliberate reentry of the same target
  restores it. There is no new saved-host catalog or automatic cold-start dial.
- The [channel](../../lib/core/hermes/channel/hermes_api_channel.dart) restores
  exact sessions, never page-zero substitutes. Advertised API runs use a stable,
  opaque SSH-owner scope in detached-run persistence. Matching terminal status
  **and** canonical history are required before unlocking an uncertain run.
  Unknown submissions with no resolvable run identity stay fenced. Native serve
  uses its existing lazy resume, canonical history and replay barrier. Recovery
  performs zero Send, approval response, Stop, session creation or service restart.

Storage rejection has no plaintext fallback. Forwarded Send/Stop uncertainty
persistence is awaited before mutation. The pointer store is bounded to 32 targets;
capacity exhaustion (including the 32 unresolved-session limit per target) does
not silently evict saved identities. Only authoritative terminal/history readback
settles an API fence, including a reattached run that completes in place; failed
streams or history reads cannot certify idle. The feature does
not implement host-key rotation or guess ownership of historical transient leases.

## When Connect fails

Keep the SSH target fields and inspect the persistent explanation above **Connect
via SSH**. Agent access rejection refers to the independently supplied Agent
API/serve credential, not the SSH password or provider key. An incompatible
response requires checking the Agent listener port and the explicitly selected
API/serve surface; Wing does not try another protocol. SSH authentication, trust,
timeout and established secure-storage failures have separate allowlisted copy.
An unknown cause stays generic rather than inventing a diagnosis.

The form reveals terminal feedback through its enclosing scroll views and exposes
it as a semantic live region. Long text remains scrollable to Connect. Wait for
owned cleanup to settle, reenter authentication (or select the key again), and
retry deliberately. Target settings remain; attempt secrets are cleared. Cancel,
route/mode/controller replacement and old completions do not transfer the old
attempt's feedback or authority to a new owner. There is no automatic retry,
probe, remote service action or replay of prompts, approvals or Stop.

The [feedback receipt](../quality/managed-ssh-failure-feedback.md) distinguishes
deterministic evidence and the held offline gate from the still-unreproduced
installed-phone report. Repairing feedback does not prove target connectivity.

## Offline checks

Run serialized fixture tests within the worker's assigned port range. If a port
is occupied, do not stop its listener: select a free subrange of that same range.
Use the assigned `AUTOWORK_PORT_BASE` from the task environment; do not copy
another worker's concrete ports. Ensure the entire fixture allocation stays in
the assigned 100-port range.

```sh
flutter test --no-pub --concurrency=1 test/core/hermes/ssh \
  test/features/hermes_chat/providers/managed_ssh_provider_test.dart
flutter test --no-pub --concurrency=1 \
  test/features/hermes_chat/providers/managed_ssh_serve_test.dart \
  test/features/hermes_chat/widgets/managed_ssh_connection_panel_test.dart \
  test/features/hermes_chat/widgets/managed_ssh_connection_form_test.dart \
  test/core/hermes/setup/secure_managed_ssh_recovery_store_test.dart \
  test/core/hermes/channel
flutter analyze --no-pub
git diff --check
```

These are Linux-host deterministic tests, including an Android platform override;
not Android execution. Opt-in adapter SSH tests skip without their owned fixture.

## Named native journey: Android SSH fixture interruption → explicit Retry

Prepared in [the full-app native target](../../integration_test/managed_ssh_key_native_test.dart)
and [owned fixture controls](../../integration_test/support/managed_ssh_key_native_fixture.dart).
This is an extended existing harness, not a result receipt. Use the existing
[`run_managed_ssh_key_native.sh`](../../scripts/run_managed_ssh_key_native.sh)
Android lane only on a separately approved disposable app/device with its explicit
ADB-reverse mapping. Keep artifacts under the task temporary directory and reuse
shared cached toolchains; never replace the paired app or use personal SSH keys,
known_hosts, Agent data, services or credentials. Inspect the launcher plan and
isolation before enabling its opt-in native run.

1. Connect through production managed SSH and select fixture profile `qa-key` /
   session `qa-history`; retain GET-only counters and the original local mapping.
2. Abort only the fixture's authenticated SSH connections, leaving the SSH and
   Agent fixture listeners available. Require disconnected/error state with the
   exact profile/session retained and no background Agent requests.
3. Tap visible Retry. Require the same host/SSH port/user/Agent port and blank
   SSH/Agent authentication. Deliberately reacquire the key/token and review the
   same out-of-band fingerprint.
4. Require a replacement local forwarding port and exact profile/session/history
   without selecting a default session or sending any mutation. Disconnect, then
   deliberately reconnect again to prove the saved pointer survives teardown.
5. Require zero mutation attempts, forbidden reads, shell/exec, remote forward,
   approval and Stop; zero live SSH connections after final Disconnect. Fresh
   selection and exact restoration may have different bounded GET counts.

The native harness substitutes document acquisition and pointer persistence, so
it cannot qualify Android SAF, keychain durability, cold restart or live Agent
work. Separately interrupt Wi-Fi/tunnel reachability on an approved Android
live-Agent target, exercise explicit Retry with an uncertain turn, and verify
Agent-owned readback with zero prompt/approval/Stop/service-restart replay. Record
only bounded redacted receipts, never raw URLs, credentials, keys or transcripts.
See the [security contract](../security/managed-ssh-forward-contract.md) and
[connection verification matrix](../test-plan.md#connection-path-verification).
