# SSH key generation, Local entry and connection Help

Status: implemented in the development worktree; native qualification and delivery remain separate.

## User-visible behavior

- Native SSH offers **Generate SSH key** with cancellation-focused consent, **Use saved Wing key**, and **Copy public key**. Generation creates one Ed25519 identity in platform secure storage, validates its readback and reuses an existing valid key. Corrupt storage or write/read failures fail closed. No private-key display, export, clipboard, plaintext fallback or automatic host authorization is provided.
- Imported key files remain attempt-scoped. Generated keys remain app-owned in the separate versioned `hermes_wing.managed_ssh.generated_ed25519.v1` namespace. Cancellation clears selection, not an already-persisted key. Concurrency is serialized on the application isolate, not across processes.
- The generated key enters the existing managed SSH credential path. Explicit host-key review and separate Agent authentication remain required. SSH key generation and raw SSH are unsupported in the browser.
- Linux Local inspects default `~/.hermes` metadata and supports deliberate folder selection. Discovery does not bind the running Agent to that folder or prove readiness.
- Android Local offers staged manual **This phone** guidance and an existing-Agent skip path. It uses loopback on explicit connection and warns about the current official native Termux package limitation. It does not install or start Agent automatically.
- Connection **Help** is selectable and has **Copy instructions**. Fixed public guidance covers username, host/IP, configurable SSH/Agent ports, Remote URL, separate authentication and public-key installation. Form secrets are not interpolated.

## Executed evidence

Parent verification used an immutable copy of tracked and untracked Wing inputs, excluding both upstream reference checkouts and runtime state. The manifest and logs remain in ignored `.task-evidence/local-key-help-integration/`.

- `python .task-evidence/local-key-help-integration/verify.py`: exit 0; offline dependency resolution, full `flutter analyze --no-pub` with no issues, and the explicit 15-target `flutter test --no-pub --concurrency=1` union with **132 passing tests**. This is a focused union, not the full repository suite.
- Test scope: production Local entry and Help, generation consent/copy/reuse/failure/stale results, existing key import and password paths, generated-key forwarding through the production controller with fake transport, host-key review, direct Remote retry, discovery and secure-store contracts with injected storage.
- The initial snapshot omitted `ROADMAP.md`, causing one documentation-contract load failure. Corrected snapshot preparation and rerun passed without changing product code.
- Current SSH widgets, key helpers, discovery, transport and localization hashes matched the passing manifest immediately after verification. The isolated source and build outputs were removed.
- Compact and wide deterministic production-widget renders were inspected. The generated-key compact view shows wrapped public data and the Copy action without private material. Local and Help were also inspected; enlarged Help keeps Close and Copy available with scrolling. SDK Roboto is layout evidence, not production typography or native execution.

## Remaining qualification

Native Linux/Android generated-key secure storage, process-relaunch persistence, native chooser, public clipboard and actual managed SSH authentication remain **NOT_CHECKED** for this increment. Terminal OpenSSH, fake transports and widget captures do not establish them. Full repository, compiled-browser and release gates did not run in this parent check. No APK was built or uploaded here; no commit or merge is claimed.

Broad Wing Link removal remains open: retained catalog, routes, pairing and packaging are not removed by the Local entry change. See [connection requirements](../product/desktop-connection-paths.md), [verification](../test-plan.md#ssh-private-key-qualification) and [backlog](../../TODO.md).
