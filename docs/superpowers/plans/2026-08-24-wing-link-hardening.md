# Wing Link Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn Wing Link into a production Linux-first, local-first management plane with pinned host identity, encrypted non-loopback transport, device-scoped credentials, host-rooted approvals, compatible versioned protocols, recoverable transactions and updates, and bounded privacy-safe auditing.

**Architecture:** Hermes Agent remains authoritative for profiles and all domain state. Wing Link owns only host trust, pairing, lifecycle, approved host operations, transaction journals, and audit metadata. Loopback may remain HTTP; every non-loopback listener uses a self-signed certificate from a persistent owner-only host identity bundle (preserved Ed25519 host root plus Android-compatible RSA TLS key) whose TLS SPKI native Wing clients pin during pairing. The host CLI is the only trust administrator; remote devices receive named capability grants and risk-tiered operations.

**Tech Stack:** Go 1.26 standard-library crypto/x509/ed25519, atomic owner-only JSON state, systemd user services, Flutter/Dart `dart:io` pinned HTTPS transport, `flutter_secure_storage`, Riverpod, Go race/fuzz tests, Flutter widget/integration tests, Waydroid.

## Global Constraints

- Preserve all unrelated dirty and untracked files; do not commit unless the user explicitly requests it.
- Hermes Agent remains authoritative; Wing Link must not add profile/project/provider shadow state.
- No shell execution, arbitrary executable/path/config-key input, or unbounded output.
- Provider secrets, bearer tokens, pairing codes, private keys, host paths, and content never enter URLs, logs, audit events, diagnostics, argv, or ordinary preferences.
- The host console/CLI is the sole root of trust.
- Non-loopback Wing Link management traffic must be TLS; loopback HTTP remains allowed.
- Support protocol generations N and N-1 only; older clients receive typed `upgrade_required` responses.
- Linux is the only qualified Wing Link service platform in this plan.
- Use TDD for each behavior slice and run `go test -race ./...` after every Go task.

---

### Task 1: Persistent host identity and state-schema migration

**Files:**
- Create: `wing_link/internal/state/identity.go`
- Create: `wing_link/internal/state/identity_test.go`
- Modify: `wing_link/internal/state/state.go`
- Modify: `wing_link/internal/state/state_test.go`
- Modify: `wing_link/internal/state/exports.go`
- Modify: `wing_link/internal/app/state.go`

**Interfaces:**
- Produces: `type HostIdentity struct { PublicKey ed25519.PublicKey; PrivateKey ed25519.PrivateKey; TLSPrivateKey *rsa.PrivateKey; Fingerprint string }`
- Produces: `func (s *StateStore) HostIdentity() (HostIdentity, error)`
- Produces state schema 2 with `devices`, while accepting and migrating schema 1 `control_token_hashes` into restricted legacy device records.

- [x] Write tests proving first access creates one owner-only persistent Ed25519 host root and RSA TLS identity, repeated and concurrent access returns the same TLS fingerprint, malformed keys fail closed, and state JSON never contains pairing codes or raw tokens.
- [x] Run `go test ./internal/state -run 'HostIdentity|Migration'` and verify RED.
- [x] Implement `HostIdentity()` using `ed25519.GenerateKey(rand.Reader)` plus a persistent RSA-2048 TLS key, base64url owner-only encoding, SHA-256 TLS-SPKI fingerprinting, the existing state lock, atomic replacement, and directory fsync.
- [x] Change persisted state to schema 2 and decode schema 1 through a dedicated legacy wire struct; reject unknown schemas and oversized/duplicate device rows.
- [x] Run focused tests, then `go test -race ./...`.

### Task 2: Named device credentials, capability grants, and individual revocation

**Files:**
- Create: `wing_link/internal/state/device.go`
- Create: `wing_link/internal/state/device_test.go`
- Modify: `wing_link/internal/state/state.go`
- Modify: `wing_link/internal/app/serve.go`
- Modify: `wing_link/internal/app/serve_test.go`
- Modify: `wing_link/internal/app/cli.go`
- Modify: `wing_link/internal/app/cli_test.go`

**Interfaces:**
- Produces: `DeviceCredential { ID, Name, TokenHash, PublicKey, Scopes, CreatedAt, LastUsedAt, ExpiresAt, Legacy }`.
- Produces: `StageDeviceCredential(name string, publicKey []byte, scopes []string) (id, token string, err error)`.
- Produces: `AuthorizeDevice(token string, requiredScopes ...string) (DeviceAuthorization, bool)`.
- Produces: `ListDevices()`, `RevokeDevice(id)`, and self-revocation.
- CLI commands: `wing-link devices list`, `wing-link devices revoke <device-id>`, and `wing-link devices revoke-all` are local-only state operations.

- [x] Write failing state tests for bounded names, public keys, allowed scope vocabulary, expiry, last-used updates, per-device revoke, self-revoke, legacy restricted grants, and fail-closed duplicate IDs.
- [x] Implement immutable allowed scope constants and constant-time token authorization returning device identity plus grants.
- [x] Replace route-wide boolean authorization with exact read/write scope checks; pending credentials may call only verification and acknowledgment routes.
- [x] Add authenticated `GET /v2/devices/self` and `DELETE /v2/devices/self`; do not expose peer inventory remotely.
- [x] Add host-local CLI listing and individual revocation without printing token hashes or public keys.
- [x] Run state/app/CLI tests and `go test -race ./...`.

### Task 3: Pinned host TLS and secure pairing

**Files:**
- Create: `wing_link/internal/state/certificate.go`
- Create: `wing_link/internal/state/certificate_test.go`
- Create: `wing_link/internal/app/listeners.go`
- Create: `wing_link/internal/app/listeners_test.go`
- Modify: `wing_link/internal/app/serve.go`
- Modify: `wing_link/internal/app/pair.go`
- Modify: `wing_link/internal/app/pair_test.go`
- Modify: `wing_link/internal/app/service_linux.go`
- Modify: `wing_link/internal/app/service_linux_test.go`

**Interfaces:**
- Produces: `HostIdentity.TLSCertificate(now time.Time, hosts []net.IP) (tls.Certificate, error)` with certificate SPKI equal to the pinned persistent RSA TLS public key; the separate Ed25519 key remains in the same owner-only identity bundle.
- Pairing URI and inspect response add `host_fingerprint`; exchange response adds `device_id`, `device_scopes`, and `protocol_generation`.
- Loopback listener uses HTTP. Non-loopback listener uses TLS 1.3 with the identity certificate.

- [x] Write failing certificate tests for stable SPKI fingerprint, SAN bounding, TLS 1.3, expiry window, changed-key rejection, and no private key in certificate output.
- [x] Write listener tests proving loopback HTTP works, non-loopback plaintext fails, and non-loopback TLS presents the persistent identity.
- [x] Implement dual serving: `server.Serve` for loopback and `server.ServeTLS` with in-memory identity certificate for the selected LAN/Tailscale listener.
- [x] For remote pairing, serve the ephemeral broker over TLS using the same host identity and include the fingerprint in the `wing://connect` URI before any credential exchange. Keep loopback same-device handoff HTTP.
- [x] Update service generation and health probing to use loopback HTTP internally while advertising HTTPS externally.
- [x] Run focused tests and `go test -race ./...`.

### Task 4: N/N-1 protocol negotiation and typed contracts

**Files:**
- Create: `wing_link/internal/protocol/metadata.go`
- Create: `wing_link/internal/protocol/metadata_test.go`
- Modify: `wing_link/internal/protocol/protocol.go`
- Modify: `wing_link/internal/app/serve.go`
- Modify: `wing_link/internal/app/serve_test.go`
- Modify: `lib/core/wing_link/wing_link_client.dart`
- Modify: `test/core/wing_link/wing_link_client_test.dart`

**Interfaces:**
- Current generation is 2; supported generations are `[1, 2]`.
- Public unauthenticated `GET /meta` returns only version, supported generations, host fingerprint, and bounded capability identifiers.
- Requests send `Wing-Protocol: 2`; responses send `Wing-Protocol`.
- Unsupported generations return HTTP 426 with `APIError{Code:"upgrade_required"}` and supported generation bounds.

- [x] Write RED Go tests for metadata bounds, N/N-1 acceptance, absent-header generation-1 compatibility, future/too-old rejection, and typed 426 bodies.
- [x] Implement centralized protocol middleware before authenticated route dispatch.
- [x] Write RED Dart tests for metadata parsing, negotiation, upgrade-required handling, and unknown capability tolerance.
- [x] Implement `WingLinkMetadata` and negotiation in `WingLinkClient`; generation 2 is preferred and generation 1 remains readable.
- [x] Run Go race tests and focused Flutter tests.

### Task 5: Native pinned HTTPS client and secure enrollment persistence

**Files:**
- Create: `lib/core/wing_link/wing_link_transport.dart`
- Create: `lib/core/wing_link/wing_link_transport_io.dart`
- Create: `lib/core/wing_link/wing_link_transport_stub.dart`
- Create: `test/core/wing_link/wing_link_transport_io_test.dart`
- Modify: `lib/core/wing_link/wing_link_client.dart`
- Modify: `lib/core/hermes/setup/hermes_endpoint_store.dart`
- Modify: `lib/core/hermes/setup/secure_hermes_endpoint_store.dart`
- Modify: `lib/features/enrollment/models/hermes_enrollment_payload.dart`
- Modify: `lib/features/enrollment/providers/hermes_enrollment_provider.dart`
- Modify: corresponding enrollment/store tests
- Modify: `pubspec.yaml`, `pubspec.lock`

**Interfaces:**
- `WingLinkTransport` accepts an expected SHA-256 SPKI fingerprint and verifies it both in `badCertificateCallback` and after successful TLS handshakes.
- `HermesEndpointConfig` gains secure `wingLinkHostFingerprint` and non-secret `wingLinkDeviceId`.
- Pair parsing requires the fingerprint for non-loopback HTTPS and rejects fingerprint changes on re-enrollment without a new explicit pairing flow.

- [x] Add `crypto` as a direct dependency and write native transport tests using two self-signed certificates: matching pin succeeds, changed pin fails before response parsing, HTTP non-loopback fails, and loopback HTTP remains allowed.
- [x] Implement conditional IO transport; web requires normally trusted HTTPS and cannot bypass browser certificate validation.
- [x] Extend secure endpoint bundle serialization and migration without writing fingerprint/token material to ordinary preferences.
- [x] Extend enrollment inspect/exchange validation so fingerprint, control origin, and device ID remain identical across the transaction.
- [x] Run secure-store, enrollment, Wing Link client tests, `flutter analyze`, and randomized focused tests.

### Task 6: Idempotent durable operations and atomic pairing transactions

**Files:**
- Create: `wing_link/internal/operation/journal.go`
- Create: `wing_link/internal/operation/journal_test.go`
- Modify: `wing_link/internal/operation/operation.go`
- Modify: `wing_link/internal/operation/operation_test.go`
- Modify: `wing_link/internal/app/operation.go`
- Modify: `wing_link/internal/app/serve.go`
- Modify: `wing_link/internal/app/pair.go`
- Modify: related app tests

**Interfaces:**
- Mutations require bounded `Idempotency-Key` and optional `If-Match` revision.
- Durable operation phases: `pending`, `approved`, `running`, `committed`, `failed`, `cancelled`.
- Same device + route + idempotency key + payload digest returns the same operation/result; a changed payload returns HTTP 409 `idempotency_conflict`.
- Pairing bundle acknowledgment is one durable transaction keyed by one Wing Link credential ID.

- [x] Write RED tests for retry identity, payload conflicts, restart recovery, terminal replay, bounded retention, cancellation, stale revision, and no secret-bearing payload persistence.
- [x] Implement an owner-only atomic JSON operation journal containing only operation metadata and SHA-256 payload digests.
- [x] Extend `OperationManager` with `StartIdempotent`, `Cancel`, and recovery of nonterminal records as explicit failed/retryable outcomes.
- [x] Route setup/update/destructive operations through the journal; keep read operations synchronous.
- [x] Persist pairing transaction status so all profile members share one acknowledgment and recovery state.
- [x] Run operation/app race tests.

### Task 7: Risk-tiered host approvals

**Files:**
- Create: `wing_link/internal/approval/approval.go`
- Create: `wing_link/internal/approval/approval_test.go`
- Create: `wing_link/internal/app/approval.go`
- Create: `wing_link/internal/app/approval_test.go`
- Modify: `wing_link/internal/app/serve.go`
- Modify: `wing_link/internal/app/cli.go`
- Modify: `wing_link/internal/app/cli_test.go`
- Modify: `wing_link/internal/protocol/protocol.go`

**Interfaces:**
- Risk tiers: `routine`, `sensitive`, `trust`.
- Sensitive/trust requests create an expiring approval containing requester device ID, typed operation, payload digest, and bounded public summary—never the secret or host path.
- CLI: `wing-link approvals list`, `approve <id>`, `reject <id>`; only the local process can mutate approval state.

- [x] Write RED tests for risk classification, expiry, exact digest binding, one-use approval, requester binding, restart persistence, and redaction.
- [x] Implement fixed operation-to-risk mapping; callers cannot supply or downgrade risk.
- [x] Return HTTP 202 `approval_required` with an operation/approval ID for unapproved sensitive operations.
- [x] Implement local CLI review with fixed fields and no arbitrary payload rendering.
- [x] Require approval for trust changes, permission expansion, install/update, directory grants, secret writes, and destructive profile actions; routine health/status and granted restart remain remote. (Unimplemented trust, permission-expansion, and directory-grant route families remain fail-closed rather than bypassing approval.)
- [x] Run approval/app race tests.

### Task 8: Bounded privacy-safe audit log

**Files:**
- Create: `wing_link/internal/audit/audit.go`
- Create: `wing_link/internal/audit/audit_test.go`
- Modify: `wing_link/internal/app/serve.go`
- Modify: `wing_link/internal/app/cli.go`
- Modify: `wing_link/internal/app/cli_test.go`

**Interfaces:**
- Audit events contain timestamp, device ID, typed operation, risk tier, approval source, result code, protocol generation, and bounded duration.
- Owner-only rolling JSON-lines file, maximum 10,000 events and 4 MiB; rotation is atomic.
- CLI `wing-link audit` prints bounded events locally; no remote audit-list endpoint.

- [x] Write RED tests injecting tokens, paths, pairing codes, and oversized Unicode into every field; assert exclusion/redaction and bounds.
- [x] Implement allowlisted fields and enum values rather than generic maps.
- [x] Add middleware recording authenticated outcomes without request bodies or authorization headers.
- [x] Add local-only CLI display and clear operations; clear requires explicit `--confirm`.
- [x] Run audit/app race tests.

### Task 9: Signed Linux update staging and rollback

**Files:**
- Create: `wing_link/internal/release/updater.go`
- Create: `wing_link/internal/release/updater_test.go`
- Modify: `wing_link/internal/release/components.go`
- Modify: `wing_link/internal/app/service_linux.go`
- Modify: `wing_link/internal/app/service_linux_test.go`
- Modify: `wing_link/internal/app/serve.go`
- Modify: `wing_link/internal/app/serve_test.go`

**Interfaces:**
- Signed catalog gains an optional Linux `wing_link` artifact with version, size, SHA-256, URL, and minimum protocol generation.
- Updater stages to an owner-only versioned path, verifies size/digest/signature, atomically switches a `current` symlink, restarts, health-checks through loopback, and restores `previous` on failure.
- Update always requires host approval; an empty production release-key set makes update unavailable, not insecure.

- [x] Write RED tests for signature, digest, size, downgrade, future protocol, interrupted download, failed restart, failed health check, successful activation, and rollback.
- [x] Implement bounded HTTPS download with redirects disabled and fsync before activation.
- [x] Change the systemd unit to execute the stable `current` target and harden it with `ProtectSystem=strict`, `ProtectHome=read-only`, `RestrictSUIDSGID=true`, and only required writable paths.
- [x] Expose typed update status/operation routes behind approval; never accept arbitrary manifest URLs from remote clients.
- [ ] Run release/app race tests and a temporary-systemd integration harness where available. (Race tests pass; temporary-systemd activation evidence remains.)

### Task 10: Device, approval, and compatibility UX in Hermes Wing

**Files:**
- Create: `lib/core/wing_link/models/wing_link_device.dart`
- Create: `lib/core/wing_link/models/wing_link_approval.dart`
- Modify: `lib/core/wing_link/wing_link_client.dart`
- Modify: `lib/features/gateway/gateway_screen.dart`
- Modify: relevant localization ARB/generated files
- Create/modify corresponding client and widget tests

**Interfaces:**
- Gateway screen shows the current device identity, granted scopes, host fingerprint status, protocol compatibility, pending operation state, and actionable host-confirmation instructions.
- Remote UI may self-revoke but cannot list/revoke peers, approve requests, rotate host identity, or expand permissions.

- [x] Write widget tests for trusted, changed-fingerprint, upgrade-required, approval-pending, self-revoked, and expired credential states across 100% and 200% text scale.
- [x] Add bounded models/client parsing and explicit errors without rendering secrets, private URLs, or host paths.
- [x] Add current-device and self-revoke controls plus host CLI instructions for peer administration and approvals.
- [x] Run focused tests, `flutter analyze`, and randomized Flutter suite.

### Task 11: Documentation, compatibility removal rules, and release evidence

**Files:**
- Modify: `CONTEXT.md`
- Modify: `README.md`
- Modify: `docs/adr/runtime-and-delivery.md`
- Modify: `docs/adr/security-and-privacy.md`
- Modify: `docs/security/threat-model.md`
- Modify: `docs/runbooks/android-hermes-setup.md`
- Modify: `docs/quality/evidence-matrix.md`
- Modify: tooling docs-contract tests

- [x] Document the host-console trust root, fingerprint review/rotation/reinstall recovery, TLS rules, device revocation, approval tiers, N/N-1 policy, Linux-only qualification, audit exclusions, update rollback, and web trusted-HTTPS limitation.
- [x] Add a compatibility-adapter registry with authoritative Agent endpoint, removal trigger, and supported release window; no adapter is permanent.
- [x] Update threat cases for stolen device, LAN impersonation, host-key loss, stale clients, approval replay, audit injection, and update compromise.
- [x] Run docs/tooling tests and scan docs for forbidden claims and secret examples.

### Task 12: Complete verification and Waydroid evidence

**Files:**
- Create or modify only sanitized `.maestro` flows when executable evidence requires them; never retain credentials, QR contents, or private screenshots.

- [x] Run `gofmt -w` on scoped Go files and `go test -race ./...`, `go vet ./...`, plus state/protocol decoder fuzz tests.
- [x] Run `dart format --output=none --set-exit-if-changed lib test integration_test`, `flutter analyze`, and `flutter test --concurrency=1 --test-randomize-ordering-seed=random`.
- [x] Run web release build and browser tests; document the trusted-certificate prerequisite rather than bypassing browser TLS. (Full Chromium suite passed after the image gained its GLib runtime dependency: 37 passed, 1 explicitly opt-in live-Agent test skipped.)
- [x] Build Android APK, install only to the pinned Waydroid target, and verify: pinned pairing, reconnect, wrong-certificate rejection, N/N-1 compatibility, self-revoke, pending host approval, profile-bundle recovery, rotation/re-pair, and cold relaunch persistence.
  - [x] Debug APK built and installed only to the exact Waydroid target; explicit cold launch passed.
  - [x] Live TLS 1.3 pairing, one-profile exchange, pending-credential acknowledgment, reconnect, cold secure-storage persistence, stale-certificate rejection, deliberate host TLS-key rotation, and explicit re-pair all passed.
  - [x] Live Android qualification exposed and fixed three production defects: remote pairing staged over TLS loopback instead of HTTP, external-service health probed remote self-signed TLS instead of loopback, and enrollment inspect/exchange bypassed the pinned transport. It also exposed Dart/Waydroid rejecting Ed25519 TLS before certificate pin callbacks; the persistent pin is now the Android-compatible RSA TLS key in the owner-only host identity bundle.
  - [x] Live N/N-1 pairing passed by completing a generation-1 handoff against the generation-2 service; current-generation pairing passed separately.
  - [x] Live self-revoke passed through the Gateway trust UI and removed the active device from owner-only host state; a live on-device integration probe staged and acknowledged a bounded credential and received the typed host-approval-required response without exposing identifiers or credentials.
- [x] Run Linux service integration tests for restart, signed staging, health rollback, and state-file permissions. (A transient service ran under the active user systemd manager, survived an explicit restart with a changed PID and healthy endpoint, and retained mode `0600`; signed staging and rollback filesystem paths pass the injected Go integration suite.)
- [x] Inspect final scoped diff, verify unrelated dirty changes remain intact, and report severity receipts and any evidence limitations.
