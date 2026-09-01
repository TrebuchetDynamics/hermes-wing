# Wing Link Local Runtime Bootstrap Implementation Plan

> **Status: historical implementation plan; current boundaries live in the ADRs.**
> The supervisor foundation is implemented, but this plan's older loopback-only,
> provider bootstrap, and broad profile-topology language is superseded by
> `docs/adr/runtime-and-delivery.md`. Do not use unchecked tasks as the roadmap.

> **2026-08-07 amendment:** the accepted multi-agent design extends this plan
> with an independent acknowledged control credential, a persistent per-user
> service, loopback plus one selected private/VPN listener, and an API-first
> profile-topology bridge. This amendment is historical; chat/session/run traffic remains direct to Hermes;
> see `../specs/2026-08-06-wing-link-multi-agent-management-design.md`.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a user install Hermes Wing, choose **Install Hermes on this device**, and reach a healthy local Hermes Agent on PC or Android/Termux with the recommended Donna starter profile, plus an explicit optional OmniRoute quick-start path for community free-tier providers.

**Architecture:** Replace the Bash `wing-cli` helper with a small Go host supervisor named **Wing Link**. Wing Link owns only verified installation, process lifecycle, local health, starter-profile staging through Hermes’s official distribution installer, and secure bootstrap into Hermes Agent’s existing enrollment API; Hermes Agent remains authoritative for chat and every domain operation. Desktop Wing launches the bundled binary, while Android uses Termux’s official `RUN_COMMAND` intent after one guided bootstrap and then talks to Wing Link over an authenticated loopback-only management API.

**Tech Stack:** Go 1.26 and the Go standard library (`golang.org/x/sys/windows/svc` only for Windows service hosting); Flutter 3.44.2/Dart 3.12, Riverpod 3, go_router 17, flutter_secure_storage; Android Kotlin/Java 17 and Termux `RUN_COMMAND`; existing Hermes HTTP/SSE, enrollment, and profile-distribution interfaces; Donna starter profile; OmniRoute npm 3.8.49.

## Global Constraints

- Wing Link is a host supervisor, not an agent harness, provider gateway, remote proxy, or second Hermes control plane.
- Hermes Agent remains authoritative for profiles, providers, models, memory, skills, tools, schedules, sessions, runs, approvals, gateway state, and configuration after bootstrap.
- Flutter never parses Hermes files, databases, human CLI output, or OmniRoute state.
- Wing Link invokes only fixed installer/lifecycle/configuration commands with argument arrays; it never accepts arbitrary command text from Flutter, HTTP, QR payloads, or remote input.
- The only domain-setting exceptions are the consented starter-profile install through fixed `hermes profile install` arguments and explicit fresh-install OmniRoute configuration through fixed `hermes config set` arguments. Neither path parses human output or overwrites an adopted configuration.
- The management API binds to `127.0.0.1:8654` only—never LAN, VPN, Tailscale, wildcard, or public interfaces.
- Every management request except `/healthz` and one-time enrollment exchange requires a random Wing Link control token stored by Flutter secure storage; Wing Link stores only SHA-256 token hashes.
- Wing Link enrollment codes expire after five minutes and are single-use. Bearer credentials never appear in URLs, QR codes, logs, diagnostics, clipboard content, or process arguments.
- One global install/update operation runs at a time. Concurrent starts return `409 operation_in_progress`.
- Installs are per-user and unprivileged. Wing Link never collects an admin password, installs setuid code, or bypasses Android/OS permission prompts.
- Preserve `~/.hermes`, profiles, credentials, sessions, adopted runtimes, and OmniRoute data across failure or ordinary Wing uninstall.
- Pin Hermes Agent to release `v2026.8.3`, commit `3c27eb6234bf91b8ceee9e9071591b31e9b148cb` until a reviewed Wing Link release changes the signed manifest.
- ADR 0038 remains authoritative: an embedded trusted Ed25519 public key verifies the complete release manifest before any component download; HTTPS, an embedded unsigned catalog, or an adjacent checksum is insufficient release authority.
- Pin the POSIX installer to 144190 bytes and SHA-256 `45f589461248c7a6ec3aecd7522a69dd49c5c8dbf4798ba1296af5c0c5e7ccd3`.
- Pin the Windows installer to 194624 bytes and SHA-256 `4dcbf2b665750cb578f69a6efa40770659e21821a463746f86da68af0d2bb31c`.
- The recommended Donna starter profile is selected by default but deselectable, requires explicit disclosure acceptance, and is pinned to commit `63845c197483d7bb24638a593436e5000891a134`, archive size 3985986, and SHA-256 `11002a2a8a3e91e2ec8e20a13c89ceb8324762528dc3e2263126c27700bfeb7b`.
- Donna installs only through Hermes’s profile-distribution interface. The current pinned commit lacks `distribution.yaml`, so production installation stays disabled until a reviewed signed-manifest update pins a compatible commit; direct cloning into Hermes state is prohibited.
- An existing `donna` profile is adopted without overwrite or automatic update. Starter-profile failure leaves Hermes healthy and the default profile usable.
- OmniRoute is optional, explicitly consented, and pinned to `omniroute@3.8.49` with SRI `sha512-8D+vfSVzn5LLYPdYrufe/pOGTiyMqd6D1BgE2v7FxoAhcSir3R2BSH8m80KuXHyuTz66N46+uSB4s7eGUviMFQ==`.
- Never promise unlimited or guaranteed-free AI. State that quotas, availability, privacy policies, and provider terms vary and prompts leave the device.
- OmniRoute failure never rolls back a healthy Hermes installation.
- Termux requires explicit bootstrap and user-granted `com.termux.permission.RUN_COMMAND`; Wing cannot silently install Termux or grant itself permission.
- Android invokes only `/data/data/com.termux/files/usr/bin/wing-link` with allowlisted arguments. No shell text crosses the Flutter/Kotlin channel.
- Every app-owned string goes into `lib/l10n/app_en.arb`; regenerate localization Dart rather than hand-editing it.
- Setup remains operable at 200% text scale, reports progress semantically, uses non-color status cues, and never requires speech or QR scanning.
- Preserve unrelated dirty-worktree changes, especially voice/lifecycle tests, Android fixtures, Playwright scripts, and current `wing-cli` work. Do not commit or push unless separately requested.

## File Structure

### Go module

- `wing_link/go.mod`, `main.go`, `protocol.go` — module, CLI dispatch, and JSON protocol.
- `wing_link/state.go` — owner-only state, one-time enrollment, hashed control tokens.
- `wing_link/process.go`, `operation.go` — safe subprocess execution and one-active-operation progress.
- `wing_link/components.manifest.json`, `components.manifest.sig`, `release_keys.go`, `components.go` — signed pins, trusted release keys, download, size, SHA-256, and SRI verification.
- `wing_link/hermes.go`, `starter_profile.go`, `omniroute.go` — component install/lifecycle behavior.
- `wing_link/server.go` — authenticated loopback HTTP/SSE management API.
- `wing_link/service_unix.go`, `service_windows.go` — platform service hosting.
- Matching `*_test.go` files beside each responsibility.

### Flutter and Android

- `lib/core/wing_link/{wing_link_models,wing_link_client,wing_link_launcher,secure_wing_link_store}.dart`.
- `lib/features/local_setup/providers/local_setup_provider.dart`.
- `lib/features/local_setup/screens/local_setup_screen.dart`.
- `android/.../termux/TermuxRunCommandChannel.kt` plus unit test.
- Focused tests under `test/core/wing_link/` and `test/features/local_setup/`.

### Packaging and docs

- `scripts/build_wing_link.sh`, `scripts/install-wing-link-termux.sh`.
- `packaging/wing-link/hermes-wing-link.service` and macOS launch-agent plist.
- `docs/adr/0044-wing-link-local-runtime-supervisor.md` and updated product/security/runbooks.

---

## Phase 1 — Freeze the boundary and protocol

### Task 1: Record Wing Link’s bounded authority

**Files:**

- Create: `docs/adr/0044-wing-link-local-runtime-supervisor.md`
- Modify: `CONTEXT.md`, `docs/product/prd.md`, `docs/product/hermes-desktop-parity.md`, `docs/security/threat-model.md`, `ROADMAP.md`
- Create: `test/tooling/wing_link_docs_contract_test.dart`

**Interfaces:** Produces the normative host/domain boundary consumed by all later tasks.

- [x] **Step 1: Write the failing documentation contract**

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Wing Link is a local host supervisor only', () {
    final adr = File('docs/adr/0044-wing-link-local-runtime-supervisor.md').readAsStringSync();
    expect(adr, contains('127.0.0.1:8654'));
    expect(adr, contains('Hermes Agent remains authoritative'));
    expect(adr, contains('Termux RUN_COMMAND'));
    expect(adr, contains('OmniRoute is optional'));
    expect(adr, isNot(contains('Wing Link proxies Hermes chat')));
    expect(File('CONTEXT.md').readAsStringSync(), contains('host supervisor'));
    expect(File('docs/security/threat-model.md').readAsStringSync(), contains('Wing Link control token'));
  });
}
```

- [x] **Step 2: Verify RED**

```bash
flutter test --concurrency=1 test/tooling/wing_link_docs_contract_test.dart
```

Expected: missing ADR.

- [x] **Step 3: Write ADR 0044**

Use this decision text:

```markdown
# ADR 0044: Use Wing Link as a local runtime supervisor

Status: accepted
Date: 2026-08-05

Wing Link installs, adopts, starts, stops, updates, verifies, and repairs an
external Hermes Agent runtime on supported PCs and Android/Termux. It exposes
an authenticated management API only on 127.0.0.1:8654. Hermes Agent remains
authoritative for every domain operation after bootstrap.

Wing Link does not proxy Hermes chat, duplicate Hermes authorization, expose a
remote control plane, parse human CLI output, or embed Hermes Agent. OmniRoute
is an explicit optional component whose failure cannot invalidate Hermes.
```

Record that packages may contain Wing Link but not Python/Agent/Node/OmniRoute; Android needs one bootstrap; secure pairing uses the Agent enrollment API; uninstall preserves external runtimes.

- [x] **Step 4: Reconcile project docs**

Update the named docs with these exact prohibitions:

```text
No bundled Agent.
No remote installs.
No Wing Link domain proxy.
No automatic OmniRoute installation without consent.
No bearer credential in URL or QR payload.
```

Move Roadmap installer work directly after signed artifacts; retain ADR 0038 verification and rollback gates.

- [x] **Step 5: Verify GREEN**

Run Task 1’s test. Expected: PASS.

- [x] **Step 6: Reviewer checkpoint**

Confirm only “desktop-only bootstrap” wording changes; Hermes authority and verified-install requirements remain stronger than the new ADR.

---

### Task 2: Establish Go module and JSON protocol

**Files:**

- Create: `wing_link/go.mod`, `wing_link/main.go`, `wing_link/protocol.go`, `wing_link/protocol_test.go`

**Interfaces:** Produces protocol version `1`, `Component`, `RuntimeState`, `InstallRequest`, `InstallStatus`, `OperationEvent`, `APIError`.

- [x] **Step 1: Write failing protocol tests**

```go
package main

import (
  "encoding/json"
  "testing"
)

func TestInstallRequestRejectsUnknownComponent(t *testing.T) {
  var request InstallRequest
  if err := json.Unmarshal([]byte(`{"components":["hermes","unknown"]}`), &request); err != nil { t.Fatal(err) }
  if err := request.Validate(); err == nil { t.Fatal("expected rejection") }
}

func TestOperationEventJSONIsBounded(t *testing.T) {
  event := OperationEvent{ProtocolVersion: 1, OperationID: "op_1", Phase: "download", Message: "Downloading Hermes", Percent: 25}
  got, _ := json.Marshal(event)
  const want = `{"protocol_version":1,"operation_id":"op_1","phase":"download","message":"Downloading Hermes","percent":25}`
  if string(got) != want { t.Fatalf("got %s", got) }
}
```

- [x] **Step 2: Verify RED**

```bash
cd wing_link && go test ./...
```

Expected: module/type failure.

- [x] **Step 3: Add module and exact protocol**

```go
module github.com/TrebuchetDynamics/hermes-wing/wing-link

go 1.26.0

require golang.org/x/sys v0.35.0
```

```go
type Component string
const (
  ComponentHermes Component = "hermes"
  ComponentStarterProfile Component = "starter_profile"
  ComponentOmniRoute Component = "omniroute"
)

type RuntimeState string
const (
  RuntimeAbsent RuntimeState = "absent"
  RuntimeInstalling RuntimeState = "installing"
  RuntimeStopped RuntimeState = "stopped"
  RuntimeStarting RuntimeState = "starting"
  RuntimeHealthy RuntimeState = "healthy"
  RuntimeFailed RuntimeState = "failed"
)

type InstallRequest struct {
  Components []Component `json:"components"`
  AcceptStarterProfileTerms bool `json:"accept_starter_profile_terms"`
  AcceptCommunityProviderTerms bool `json:"accept_community_provider_terms"`
}

type InstallStatus struct {
  ProtocolVersion int `json:"protocol_version"`
  State RuntimeState `json:"state"`
  HermesInstalled bool `json:"hermes_installed"`
  HermesHealthy bool `json:"hermes_healthy"`
  HermesVersion string `json:"hermes_version,omitempty"`
  StarterProfileInstalled bool `json:"starter_profile_installed"`
  StarterProfileName string `json:"starter_profile_name,omitempty"`
  StarterProfileBlockedReason string `json:"starter_profile_blocked_reason,omitempty"`
  OmniRouteInstalled bool `json:"omniroute_installed"`
  OmniRouteHealthy bool `json:"omniroute_healthy"`
  ActiveOperationID string `json:"active_operation_id,omitempty"`
  PairingURI string `json:"pairing_uri,omitempty"`
}

type OperationEvent struct {
  ProtocolVersion int `json:"protocol_version"`
  OperationID string `json:"operation_id"`
  Phase string `json:"phase"`
  Message string `json:"message"`
  Percent int `json:"percent"`
  Terminal bool `json:"terminal,omitempty"`
  ErrorCode string `json:"error_code,omitempty"`
}
```

`InstallRequest.Validate()` accepts only unique `hermes`/`starter_profile`/`omniroute`, requires Hermes for either optional component, and requires each component’s explicit disclosure acceptance.

- [x] **Step 4: Add fixed CLI dispatch**

```go
switch os.Args[1] {
case "version": fmt.Println(version)
case "serve", "status", "pair", "start", "stop", "restart": os.Exit(runCommand(os.Args[1], os.Args[2:]))
default: usage(os.Stderr); os.Exit(2)
}
```

No command accepts shell text.

- [x] **Step 5: Verify GREEN**

```bash
cd wing_link && gofmt -w *.go && go test ./... && go vet ./...
```

- [x] **Step 6: Reviewer checkpoint**

Confirmed protocol fields contain no transcript, provider key, arbitrary path, arbitrary command, or remote-origin value.

---

### Task 3: Persist owner-only control state

**Files:**

- Create: `wing_link/state.go`, `wing_link/state_test.go`

**Interfaces:** `StateStore.CreateEnrollment()`, `.ExchangeEnrollment()`, `.Authorize()`, `.RevokeAll()`; `<WingLinkHome>/state.json` mode `0600`.

- [x] **Step 1: Write failing tests**

```go
func TestEnrollmentExchangesOnceAndStoresHashes(t *testing.T) {
  now := time.Unix(1000, 0)
  store := newTestStateStore(t, func() time.Time { return now })
  enrollment, _ := store.CreateEnrollment()
  token, err := store.ExchangeEnrollment(enrollment.Code)
  if err != nil { t.Fatal(err) }
  if _, err = store.ExchangeEnrollment(enrollment.Code); !errors.Is(err, ErrEnrollmentUnavailable) { t.Fatalf("got %v", err) }
  persisted, _ := os.ReadFile(store.path)
  if bytes.Contains(persisted, []byte(enrollment.Code)) || bytes.Contains(persisted, []byte(token)) { t.Fatal("raw secret persisted") }
  if !store.Authorize(token) { t.Fatal("token rejected") }
}
```

Add expiry after five minutes, mode `0600`, malformed-state fail-closed, and changed-token rejection.

- [x] **Step 2: Verify RED**

```bash
cd wing_link && go test ./... -run Enrollment
```

- [x] **Step 3: Implement exact surface**

```go
var ErrEnrollmentUnavailable = errors.New("enrollment unavailable")
type Enrollment struct { Code string; ExpiresAt time.Time }
type StateStore struct { path string; now func() time.Time; mu sync.Mutex }
func (s *StateStore) CreateEnrollment() (Enrollment, error)
func (s *StateStore) ExchangeEnrollment(code string) (string, error)
func (s *StateStore) Authorize(token string) bool
func (s *StateStore) RevokeAll() error
```

Generate 24-byte codes and 32-byte `wlc_` tokens with `crypto/rand`. Persist SHA-256 hex only, compare constant-time, write sibling temp `0600`, fsync, rename. Reject symlinks/non-regular state paths.

- [x] **Step 4: Verify GREEN**

```bash
cd wing_link && go test ./... -run 'Enrollment|StateStore'
```

- [x] **Step 5: Reviewer checkpoint**

Confirmed fixtures and persisted state contain no raw code/token; independent review passed.

---

### Task 4: Add safe process execution and one-operation coordination

**Files:**

- Create: `wing_link/process.go`, `process_test.go`, `operation.go`, `operation_test.go`

**Interfaces:** `CommandSpec`, `runProcess()`, `OperationManager.Start()`, `.Snapshot()`, `.Subscribe()`.

- [x] **Step 1: Write failing safety tests**

```go
func TestArgumentsStayLiteral(t *testing.T) {
  script := filepath.Join(t.TempDir(), "argv.sh")
  os.WriteFile(script, []byte("#!/bin/sh\nprintf '%s\\n' \"$@\"\n"), 0700)
  var lines []string
  result := runProcess(context.Background(), CommandSpec{Path: script, Args: []string{"$(touch /tmp/injected)", "; rm -rf ~"}}, func(line string) { lines = append(lines, line) })
  if result.ExitCode != 0 || lines[0] != "$(touch /tmp/injected)" { t.Fatalf("%#v", lines) }
}

func TestManagerRejectsConcurrentInstall(t *testing.T) {
  manager := NewOperationManager()
  release := make(chan struct{})
  id, _ := manager.Start("install", func(context.Context, func(OperationEvent)) error { <-release; return nil })
  if _, err := manager.Start("install", func(context.Context, func(OperationEvent)) error { return nil }); !errors.Is(err, ErrOperationInProgress) { t.Fatalf("got %v", err) }
  close(release)
  waitForTerminal(t, manager, id)
}
```

Add timeout, ANSI stripping, 240-character bounds, secret redaction, SSE slow-subscriber, and final-event retention tests.

- [x] **Step 2: Verify RED**

```bash
cd wing_link && go test ./... -run 'Arguments|Manager'
```

- [x] **Step 3: Implement process contract**

```go
type CommandSpec struct { Path string; Args []string; Dir string; Env []string; Timeout time.Duration }
type ProcessResult struct { ExitCode int; Err error }
func runProcess(ctx context.Context, spec CommandSpec, onLine func(string)) ProcessResult
```

Use `exec.CommandContext(spec.Path, spec.Args...)`; never `sh -c`, `bash -c`, `cmd /c`, or PowerShell command text. Redact bearer/API-key/token/password/URL-userinfo patterns before emitting.

- [x] **Step 4: Implement operation manager**

```go
var ErrOperationInProgress = errors.New("operation already in progress")
func NewOperationManager() *OperationManager
func (m *OperationManager) Start(kind string, work func(context.Context, func(OperationEvent)) error) (string, error)
func (m *OperationManager) Snapshot(id string) (OperationEvent, bool)
func (m *OperationManager) Subscribe(id string) (<-chan OperationEvent, func(), bool)
```

Use random `op_` IDs and capacity-16 subscribers. Intermediate progress may drop; terminal events may not.

- [x] **Step 5: Verify GREEN**

```bash
cd wing_link && gofmt -w *.go && go test -race ./...
```

- [x] **Step 6: Reviewer checkpoint**

Confirmed no shell command composition; process arguments remain literal, secrets/output are sanitized, and process trees are bounded on supported platforms.

---

## Phase 2 — Verified components

### Task 5: Verify a signed pinned component manifest

**Files:**

- Create: `wing_link/components.manifest.json`, `components.manifest.sig`, `release_keys.go`, `components.go`, `components_test.go`
- Create: `scripts/sign_wing_link_component_manifest.sh`
- Modify: the private release runbook outside the repository to identify the offline signing-key custodian; never add the private key or seed to Git, CI variables used by pull requests, or build artifacts

**Interfaces:** `VerifyComponentManifest()`, `ComponentCatalog`, `ArtifactFor()`, `downloadVerified()`.

- [x] **Step 1: Write one failing signature test**

Generate an ephemeral Ed25519 key in the test, sign a fixed manifest fixture, and prove `VerifyComponentManifest()` accepts it. Then mutate one manifest byte and prove the same signature returns `ErrManifestSignature`. The expected result comes from Go’s `crypto/ed25519`, not production implementation logic.

- [x] **Step 2: Implement signature verification and make the test GREEN**

```go
var ErrManifestSignature = errors.New("component manifest signature invalid")
func VerifyComponentManifest(manifest, signature []byte, trustedKeys map[string]ed25519.PublicKey) (ComponentCatalog, error)
```

The signed bytes are the exact UTF-8 contents of `components.manifest.json`. Require schema `1`, a known `signing_key_id`, non-empty release identity, issuance and expiry bounds, and a trusted embedded Ed25519 public key. Verification happens before parsing artifact URLs for download.

- [ ] **Step 3: Add the reviewed production release key and signed manifest**

Run a release-authority key ceremony: generate the production Ed25519 key offline, commit only its public key and stable key ID in `release_keys.go`, have the custodian sign the reviewed manifest with `scripts/sign_wing_link_component_manifest.sh`, and independently verify the signature before review. Stop this task if no approved signing custodian or protected private-key location exists.

The signed payload pins these exact component values:

```json
{
  "schema": 1,
  "signing_key_id": "hermes-wing-release-1",
  "release_identity": "org.trebuchetdynamics.hermes-wing-link-components",
  "hermes": {
    "version": "v2026.8.3",
    "commit": "3c27eb6234bf91b8ceee9e9071591b31e9b148cb",
    "posix": {
      "url": "https://raw.githubusercontent.com/NousResearch/hermes-agent/v2026.8.3/scripts/install.sh",
      "size": 144190,
      "sha256": "45f589461248c7a6ec3aecd7522a69dd49c5c8dbf4798ba1296af5c0c5e7ccd3"
    },
    "windows": {
      "url": "https://raw.githubusercontent.com/NousResearch/hermes-agent/v2026.8.3/scripts/install.ps1",
      "size": 194624,
      "sha256": "4dcbf2b665750cb578f69a6efa40770659e21821a463746f86da68af0d2bb31c"
    }
  },
  "starter_profile": {
    "name": "donna",
    "source": "https://github.com/AtlasOmnia/donna-starter",
    "commit": "63845c197483d7bb24638a593436e5000891a134",
    "archive_url": "https://codeload.github.com/AtlasOmnia/donna-starter/tar.gz/63845c197483d7bb24638a593436e5000891a134",
    "size": 3985986,
    "sha256": "11002a2a8a3e91e2ec8e20a13c89ceb8324762528dc3e2263126c27700bfeb7b",
    "installable": false,
    "blocked_reason": "missing_distribution_manifest"
  },
  "omniroute": {
    "version": "3.8.49",
    "url": "https://registry.npmjs.org/omniroute/-/omniroute-3.8.49.tgz",
    "integrity": "sha512-8D+vfSVzn5LLYPdYrufe/pOGTiyMqd6D1BgE2v7FxoAhcSir3R2BSH8m80KuXHyuTz66N46+uSB4s7eGUviMFQ=="
  }
}
```

The release ceremony adds concrete `issued_at` and `expires_at` fields before signing; those values are release evidence, not developer-chosen placeholders.

- [ ] **Step 4: Add artifact tamper tests and download verification**

Test wrong/unknown key IDs, expired/future manifests, malformed signatures, mutable hosts, size mismatch, SHA-256 mismatch, SRI mismatch, non-installable component rejection, and redirects away from the allowlisted origin. Use HTTPS only, host-locked redirects, streamed hashing, exact byte count, owner-only temp files, and deletion on failure.

```go
var ErrArtifactVerification = errors.New("artifact verification failed")
func downloadVerified(ctx context.Context, client *http.Client, artifact Artifact, dir string) (string, error)
func verifySHA256(path string, expectedSize int64, expectedHex string) error
func verifySRI(path, expected string) error
```

- [ ] **Step 5: Verify GREEN**

```bash
cd wing_link && go test ./... -run 'Manifest|Catalog|Download|Artifact'
```

- [ ] **Step 6: Reviewer checkpoint**

Independently verify the committed signature with the trusted public key. No runtime path may trust an unsigned embedded catalog, `main`, `latest`, an npm range, an adjacent checksum alone, or a client-supplied URL.

---

### Task 6: Install/adopt/start/verify/enroll Hermes

**Files:**

- Create: `wing_link/hermes.go`, `hermes_test.go`

**Interfaces:** `HermesManager.Inspect()`, `.Install()`, `.Start()`, `.Stop()`, `.Restart()`, `.CreatePairingURI()`.

- [ ] **Step 1: Write failing lifecycle tests**

```go
func TestInstallAdoptsHealthyRuntime(t *testing.T) {
  fake := newFakeCommandRunner()
  health := healthyHermesServer(t)
  result, err := newTestHermesManager(t, fake, health.URL).Install(context.Background(), func(OperationEvent) {})
  if err != nil || !result.Adopted || fake.CallCount() != 0 { t.Fatalf("%#v %v", result, err) }
}

func TestInstallerUsesPinnedCommit(t *testing.T) {
  fake := newFakeCommandRunner(); fake.QueueSuccess()
  manager := newTestHermesManager(t, fake, "http://127.0.0.1:1")
  _, _ = manager.Install(context.Background(), func(OperationEvent) {})
  if !slices.Contains(fake.FirstCall().Args, "3c27eb6234bf91b8ceee9e9071591b31e9b148cb") { t.Fatal("missing commit") }
}
```

Add digest-before-execution, timeout, unhealthy post-install, preserve-home, and no-key-in-status/log tests.

- [ ] **Step 2: Implement discovery**

```go
type HermesInspection struct { Installed, Healthy, Fresh bool; Version, HermesHome, Executable string }
type HermesInstallResult struct { Adopted, Fresh bool; Version string }
func (m *HermesManager) Inspect(ctx context.Context) (HermesInspection, error)
```

Resolve `HERMES_HOME`, then Windows `%LOCALAPPDATA%\hermes`, otherwise `~/.hermes`; probe expected executable paths then `LookPath("hermes")`. Use `hermes --version` exit status and at most 80 sanitized characters—no config/database parsing.

- [ ] **Step 3: Execute verified installers with fixed arguments**

POSIX/Termux:

```text
/bin/bash <verified-installer> --commit 3c27eb6234bf91b8ceee9e9071591b31e9b148cb --skip-setup --non-interactive --hermes-home <validated-home>
```

Windows:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File <verified-installer> -Commit 3c27eb6234bf91b8ceee9e9071591b31e9b148cb -SkipSetup -NonInteractive -HermesHome <validated-home>
```

- [ ] **Step 4: Bootstrap only API authentication**

```go
func ensureAPIServerKey(envPath string) (key string, created bool, err error)
```

On fresh install, generate 32 random bytes and atomically add `API_SERVER_KEY` to default `.env` mode `0600`. Never overwrite non-empty existing value. This is the only direct Hermes file write because authenticated HTTP does not exist before the key.

- [ ] **Step 5: Supervise and verify gateway**

Run:

```text
hermes gateway run --external-supervisor --accept-hooks
```

Set `HERMES_HOME` and key in child environment. Poll `/health` every 500 ms up to 45 seconds, then authenticated `/v1/capabilities`. Stop only the tracked child: interrupt, wait 10 seconds, then kill.

- [ ] **Step 6: Create secure Hermes enrollment**

POST to `http://127.0.0.1:8642/v1/operator/enrollments` with in-memory superuser key and scopes:

```json
[
  "chat:read",
  "chat:write",
  "sessions:read",
  "sessions:write",
  "profiles:read",
  "providers:read",
  "providers:write",
  "models:read",
  "models:write"
]
```

Return only `wing://connect?...&code=...`. If absent, return `secure_enrollment_unavailable`; never transfer superuser key.

- [ ] **Step 7: Verify GREEN**

```bash
cd wing_link && go test -race ./... -run Hermes
```

- [ ] **Step 8: Reviewer checkpoint**

Adoption must not mutate existing install/config; failures leave prior process/data untouched; no raw key appears in fixtures.

---

### Task 7: Install the pinned Donna starter profile through Hermes

**Files:**

- Create: `wing_link/starter_profile.go`, `starter_profile_test.go`

**Interfaces:** `StarterProfileManager.Inspect()`, `.Install()`, and `.Verify()`; consumes only the signed component-manifest entry and Hermes’s profile-distribution CLI.

- [ ] **Step 1: Write failing compatibility and independence tests**

```go
func TestStarterProfileRejectsCurrentIncompatiblePinBeforeExecution(t *testing.T) {
  fake := newFakeCommandRunner()
  manager := newTestStarterProfileManager(t, fake, ComponentArtifact{
    Commit: "63845c197483d7bb24638a593436e5000891a134",
    Installable: false,
    BlockedReason: "missing_distribution_manifest",
  })
  _, err := manager.Install(context.Background(), true, func(OperationEvent) {})
  if !errors.Is(err, ErrStarterProfileIncompatible) { t.Fatalf("got %v", err) }
  if fake.CallCount() != 0 { t.Fatal("incompatible profile reached execution") }
}

func TestStarterProfileFailureKeepsHermesHealthy(t *testing.T) {
  result := composeInstallResult(healthyHermesResult(), failedStarterProfileResult())
  if !result.HermesHealthy || result.StarterProfileInstalled { t.Fatalf("%#v", result) }
}
```

Add tests for missing disclosure acceptance, existing-profile adoption without install/update, archive size/digest mismatch, traversal, absolute paths, symlinks, hardlinks, device entries, missing `distribution.yaml`, fixed CLI arguments, and post-install profile verification.

- [ ] **Step 2: Verify RED**

```bash
cd wing_link && go test ./... -run StarterProfile
```

Expected: missing starter-profile manager symbols.

- [ ] **Step 3: Implement the fail-closed compatibility gate**

```go
var ErrStarterProfileIncompatible = errors.New("starter profile is not a compatible Hermes distribution")

type StarterProfileInspection struct {
  Installed bool
  Name string
  Compatible bool
  BlockedReason string
}

func (m *StarterProfileManager) Inspect(ctx context.Context) (StarterProfileInspection, error)
func (m *StarterProfileManager) Install(ctx context.Context, accepted bool, emit func(OperationEvent)) (StarterProfileInspection, error)
func (m *StarterProfileManager) Verify(ctx context.Context) error
```

The production manifest initially records Donna commit `63845c197483d7bb24638a593436e5000891a134` as `installable: false` because its archive has `profile.yaml` but no `distribution.yaml`. Return `starter_profile_incompatible` before download or execution. Do not clone the repository directly into Hermes state and do not synthesize a distribution manifest.

A later reviewed Wing Link release may switch `installable` to `true` only after the signed component manifest pins a Donna commit whose verified archive contains a regular root `distribution.yaml` accepted by the pinned Hermes version.

- [ ] **Step 4: Stage and install a compatible pinned distribution**

Download only the signed-manifest archive URL and verify exact size and SHA-256 through Task 5. Extract with `archive/tar` and `compress/gzip` into an owner-only temporary directory; reject absolute paths, `..`, symlinks, hardlinks, devices, more than 20000 entries, or more than 128 MiB expanded data.

If fixed command `hermes profile info donna` succeeds, adopt the profile and perform no install or update. Otherwise invoke exactly:

```text
hermes profile install <verified-staged-directory> --name donna --alias --yes
```

Check exit status only; never parse human output. Restart the tracked Hermes gateway if required, verify `donna` through the advertised Hermes profile inventory, and let Flutter select it through the existing profile controller. Never change the global active profile or overwrite/update an existing `donna` profile.

Starter-profile failure produces a bounded warning and leaves healthy Hermes plus its default profile available. No automatic profile updates ship in this slice.

- [ ] **Step 5: Verify GREEN**

```bash
cd wing_link && go test -race ./... -run 'StarterProfile|CompositeInstaller'
```

- [ ] **Step 6: Reviewer checkpoint**

Confirm the current incompatible pin fails before network or command execution, a compatible fixture uses only the official Hermes installer, and no path writes directly under `~/.hermes/profiles`.

---

### Task 8: Add explicit optional OmniRoute quick start

**Files:**

- Create: `wing_link/omniroute.go`, `omniroute_test.go`

**Interfaces:** `OmniRouteManager.Install()`, `.Start()`, `.Stop()`, `.Health()`, `.ConfigureFreshHermes()`.

- [ ] **Step 1: Write failing consent/independence tests**

```go
func TestOmniRouteRequiresConsent(t *testing.T) {
  _, err := newTestOmniRouteManager(t).Install(context.Background(), false, func(OperationEvent) {})
  if !errors.Is(err, ErrCommunityProviderConsent) { t.Fatalf("got %v", err) }
}

func TestOmniRouteFailureKeepsHermesSuccess(t *testing.T) {
  result := newCompositeInstaller(successfulHermesManager(), failingOmniRouteManager()).Install(context.Background(), InstallRequest{Components: []Component{ComponentHermes, ComponentOmniRoute}, AcceptCommunityProviderTerms: true})
  if !result.HermesHealthy || result.OmniRouteHealthy { t.Fatalf("%#v", result) }
}
```

Add exact version, SRI-before-npm, secrets-in-env-not-argv, no-overwrite-existing-provider tests, and a test proving fresh Donna receives OmniRoute configuration when the starter profile installed.

- [ ] **Step 2: Install prerequisites after consent**

Termux only:

```text
pkg install -y nodejs python build-essential git
```

On PCs, validate supported Node and report `node_runtime_missing`; do not silently install system Node.

- [ ] **Step 3: Install isolated pinned package**

After SRI verification:

```text
npm install --global --prefix <WingLinkHome>/components/omniroute <verified-tarball>
```

Generate `INITIAL_PASSWORD`, `JWT_SECRET`, `API_KEY_SECRET`, `STORAGE_ENCRYPTION_KEY` with `crypto/rand`, store mode `0600`, and run `omniroute setup --non-interactive` with secrets in environment. Start with `PORT=20128`, `HOSTNAME=127.0.0.1`, fixed `DATA_DIR`; poll `/v1/models` for 45 seconds.

- [ ] **Step 4: Configure only the fresh setup profile**

When Donna installed in the same operation, use fixed arguments against that profile:

```text
hermes --profile donna config set model.provider custom --force
hermes --profile donna config set model.base_url http://127.0.0.1:20128/v1 --force
hermes --profile donna config set model.default auto --force
```

When the operator deselected Donna, apply the same three settings to the fresh default profile without `--profile donna`. Start Hermes with `OPENAI_API_KEY=omniroute-local`, select Donna through Hermes’s profile interface when present, and verify one bounded test completion through Hermes. Failure leaves Hermes usable and reports `community_provider_setup_failed` with provider-choice recovery. Never run on adopted/configured installs.

- [ ] **Step 5: Verify GREEN**

```bash
cd wing_link && go test -race ./... -run 'OmniRoute|CompositeInstaller'
```

- [ ] **Step 6: Reviewer checkpoint**

Consent cannot be implicit; OmniRoute binds loopback; no provider content or secrets enter logs.

---

## Phase 3 — Service API and launch

### Task 9: Expose authenticated loopback management API

**Files:**

- Create: `wing_link/server.go`, `server_test.go`
- Modify: `wing_link/main.go`

**Interfaces:**

- `GET /healthz`
- `POST /v1/control/enrollments/exchange`
- `GET /v1/status`
- `POST /v1/install`
- `GET /v1/operations/{id}` and `/events`
- `POST /v1/runtime/start|stop|restart`
- `POST /v1/pair`

- [ ] **Step 1: Write failing HTTP tests**

```go
func TestStatusRequiresToken(t *testing.T) {
  server := newTestServer(t)
  response, _ := http.Get(server.URL + "/v1/status")
  if response.StatusCode != http.StatusUnauthorized { t.Fatalf("%d", response.StatusCode) }
}

func TestInstallConflictIs409(t *testing.T) {
  server, token, hold := newBusyTestServer(t); defer close(hold)
  if authorizedJSON(t, server.URL+"/v1/install", token, `{"components":["hermes"]}`).StatusCode != http.StatusAccepted { t.Fatal("first rejected") }
  if authorizedJSON(t, server.URL+"/v1/install", token, `{"components":["hermes"]}`).StatusCode != http.StatusConflict { t.Fatal("missing conflict") }
}
```

Add 64 KiB body, invalid JSON, unknown fields, non-loopback rejection, SSE replay/heartbeat, no-cache, and sanitized-error tests.

- [ ] **Step 2: Implement strict listener and routing**

```go
listener, err := net.Listen("tcp4", "127.0.0.1:8654")
```

Use `http.ServeMux`, `MaxBytesReader`, `DisallowUnknownFields`, constant-time auth, `Cache-Control: no-store`. No production flag overrides host/port.

- [ ] **Step 3: Implement one-time exchange**

Request `{"code":"..."}`; response:

```json
{
  "protocol_version": 1,
  "token": "wlc_<raw-once>",
  "origin": "http://127.0.0.1:8654"
}
```

Handoff:

```text
wing://local-setup?origin=http%3A%2F%2F127.0.0.1%3A8654&code=<single-use-code>
```

- [ ] **Step 4: Stream operation SSE**

Emit `event: progress` JSON, heartbeat every 15 seconds, close after terminal. Reconnect sends latest event first.

- [ ] **Step 5: Verify GREEN**

```bash
cd wing_link && go test -race ./... -run 'Server|HTTP|SSE'
```

- [ ] **Step 6: Reviewer checkpoint**

Manual `ss`/`netstat` proves loopback-only; no query-string token is accepted.

---

### Task 10: Add services and one-command Termux bootstrap

**Files:**

- Create: `wing_link/service_unix.go`, `service_windows.go`, `service_test.go`
- Create: `packaging/wing-link/hermes-wing-link.service`, `org.trebuchetdynamics.hermes-wing-link.plist`
- Create: `scripts/install-wing-link-termux.sh`
- Create: `test/tooling/wing_link_bootstrap_contract_test.dart`

**Interfaces:** `wing-link service install|remove`; rootless Termux bootstrap; one-time handoff.

- [ ] **Step 1: Write failing bootstrap test**

```dart
test('Termux bootstrap is pinned and rootless', () {
  final script = File('scripts/install-wing-link-termux.sh').readAsStringSync();
  expect(script, startsWith('#!/data/data/com.termux/files/usr/bin/bash\nset -euo pipefail'));
  expect(script, contains('allow-external-apps=true'));
  expect(script, contains('sha256sum -c'));
  expect(script, contains('wing-link pair'));
  expect(script, isNot(contains('sudo')));
  expect(script, isNot(contains('@latest')));
});
```

- [ ] **Step 2: Implement platform services**

Linux installs user unit under `~/.config/systemd/user`; macOS installs under `~/Library/LaunchAgents`; Windows uses `x/sys/windows/svc` and native UAC; cancellation leaves no registration. Termux writes a Termux:Boot script only if addon is installed, otherwise Wing restarts through `RUN_COMMAND`.

- [ ] **Step 3: Implement bootstrap**

The script verifies Termux, ensures curl/coreutils, downloads explicit-version architecture binary and checksum from Hermes Wing release, verifies before `$PREFIX/bin/wing-link`, idempotently sets `allow-external-apps=true`, starts `wing-link serve`, then `wing-link pair --open-android`; print handoff if Android activity launch fails. No production `latest` default.

- [ ] **Step 4: Verify GREEN**

```bash
flutter test --concurrency=1 test/tooling/wing_link_bootstrap_contract_test.dart
cd wing_link && go test ./... -run Service
```

- [ ] **Step 5: Reviewer checkpoint**

Disposable-prefix rerun preserves state, uses no root, and installs neither Hermes nor OmniRoute before UI consent.

---

## Phase 4 — Flutter and Android onboarding

### Task 11: Implement Dart protocol, secure store, and HTTP/SSE client

**Files:**

- Create: `lib/core/wing_link/wing_link_models.dart`, `secure_wing_link_store.dart`, `wing_link_client.dart`
- Create: matching tests under `test/core/wing_link/`

**Interfaces:** `WingLinkStatus`, `WingLinkOperationEvent`, `WingLinkControlStore`, `WingLinkClient`.

- [ ] **Step 1: Write failing parser tests**

```dart
test('rejects remote Wing Link origin', () {
  expect(() => WingLinkStatus.fromJson({'protocol_version':1,'origin':'http://192.168.1.5:8654','state':'healthy'}), throwsFormatException);
});

test('bounds operation message', () {
  final event = WingLinkOperationEvent.fromJson({'protocol_version':1,'operation_id':'op_12345678','phase':'download','message':'x' * 1000,'percent':25});
  expect(event.message.length, 240);
});
```

- [ ] **Step 2: Implement models/store**

```dart
enum WingLinkRuntimeState { absent, installing, stopped, starting, healthy, failed }
abstract interface class WingLinkControlStore {
  Future<String?> loadToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
}
```

`SecureWingLinkControlStore` uses secure key `wing_link_control_token_v1`. Parse bounded starter-profile installed/name/blocker fields. Reject protocol !=1, non-loopback origins, unknown state, invalid `op_` ID, incoming event >4 KiB, non-`wing://connect` pairing URI, or an unknown starter-profile blocker.

- [ ] **Step 3: Implement client**

```dart
abstract interface class WingLinkClient {
  Future<String> exchangeEnrollment({required String code});
  Future<WingLinkStatus> status();
  Future<String> install({required bool includeStarterProfile, required bool acceptedStarterProfileTerms, required bool includeOmniRoute, required bool acceptedCommunityTerms});
  Stream<WingLinkOperationEvent> operationEvents(String operationId);
  Future<Uri> createHermesPairing();
  Future<void> startHermes();
  Future<void> stopHermes();
  Future<void> restartHermes();
}
```

Use `dart:io HttpClient`, fixed `127.0.0.1:8654`, 64 KiB bounds, ten-second ordinary timeout, SSE reconnect, Authorization header only, existing redaction helpers.

- [ ] **Step 4: Verify GREEN**

```bash
flutter test --concurrency=1 test/core/wing_link
flutter analyze
```

- [ ] **Step 5: Reviewer checkpoint**

Captured requests show token only in Authorization, never URI/body/error/diagnostics.

---

### Task 12: Add desktop launcher and Android Termux adapter

**Files:**

- Create: `lib/core/wing_link/wing_link_launcher.dart` and test
- Create: `android/.../termux/TermuxRunCommandChannel.kt` and test
- Modify: `MainActivity.kt`, `AndroidManifest.xml`

**Interfaces:** `WingLinkLauncher.isSupported`, `.isReady()`, `.start()`, `.openTermuxBootstrapHelp()`; MethodChannel `com.trebuchetdynamics.hermes.wing/termux_run_command` with `isTermuxInstalled`, `hasRunCommandPermission`, `startWingLink`, `openTermux`.

- [ ] **Step 1: Write failing Flutter/Kotlin tests**

Flutter asserts `start()` sends method `startWingLink` with null arguments. Kotlin asserts exact intent:

```text
package com.termux
service com.termux.app.RunCommandService
action com.termux.RUN_COMMAND
path /data/data/com.termux/files/usr/bin/wing-link
arguments [serve]
workdir /data/data/com.termux/files/home
background true
```

- [ ] **Step 2: Verify RED**

```bash
flutter test --concurrency=1 test/core/wing_link/wing_link_launcher_test.dart
cd android && ./gradlew testDebugUnitTest --tests '*TermuxRunCommandChannelTest'
```

- [ ] **Step 3: Implement desktop launch**

Resolve only packaged Wing Link; run `wing-link serve`; read at most one bounded `wing://local-setup` line. Healthy existing service wins. No executable path comes from UI/preferences.

- [ ] **Step 4: Implement Termux adapter**

Manifest:

```xml
<uses-permission android:name="com.termux.permission.RUN_COMMAND" />
<queries><package android:name="com.termux" /></queries>
```

Use documented extras and stable errors: `termux_missing`, `run_command_permission_missing`, `termux_external_apps_disabled`, `termux_start_blocked`. No Dart value may alter command/path/args.

- [ ] **Step 5: Verify GREEN**

Run Task 12 tests. Expected: PASS.

- [ ] **Step 6: Reviewer checkpoint**

Inspect intent; no command, URL, token, provider input, or path crosses from Dart.

---

### Task 13: Build resumable local setup state

**Files:**

- Create: `lib/features/local_setup/providers/local_setup_provider.dart`
- Create: `test/features/local_setup/local_setup_provider_test.dart`
- Modify: `lib/features/hermes_chat/providers/hermes_channel_provider.dart`

**Interfaces:** `LocalSetupController`, `LocalSetupState`, `localSetupControllerProvider`.

- [ ] **Step 1: Write failing state tests**

```dart
test('Hermes success survives OmniRoute failure', () async {
  final controller = LocalSetupController(launcher: FakeWingLinkLauncher.ready(), client: FakeWingLinkClient.omniRouteFailureAfterHermesSuccess(), onHermesPairing: (_) async {});
  await controller.install(includeOmniRoute: true, acceptedCommunityTerms: true);
  expect(controller.state.hermesReady, isTrue);
  expect(controller.state.omniRouteWarning, isNotNull);
  expect(controller.state.canContinue, isTrue);
});
```

Add double-tap one operation, resume existing operation, stale event, invalid pairing URI, Termux missing/permission, token clear, starter-profile incompatibility, existing Donna adoption, and Hermes-success/Donna-failure tests.

- [ ] **Step 2: Implement exact state**

```dart
enum LocalSetupPhase { checking, termuxRequired, permissionRequired, wingLinkRequired, ready, installingHermes, installingStarterProfile, installingOmniRoute, startingHermes, pairing, complete, failed }
final class LocalSetupState {
  const LocalSetupState({required this.phase, this.percent=0, this.message='', this.hermesReady=false, this.starterProfileReady=false, this.omniRouteReady=false, this.starterProfileWarning, this.omniRouteWarning, this.errorCode});
  final LocalSetupPhase phase;
  final int percent;
  final String message;
  final bool hermesReady, starterProfileReady, omniRouteReady;
  final String? starterProfileWarning, omniRouteWarning, errorCode;
  bool get canContinue => hermesReady;
}
```

Flow: probe health; fixed launcher start; exchange local code/save token; fetch/resume status; start one install; request Hermes pairing; feed existing enrollment; reload gateway; select `donna` through the existing profile controller when installed; route Chat. Disposal detaches UI only—never cancels install/stops Hermes.

- [ ] **Step 3: Verify GREEN**

```bash
flutter test --concurrency=1 test/features/local_setup/local_setup_provider_test.dart
```

- [ ] **Step 4: Reviewer checkpoint**

Background/recreation resumes authoritative operation state without duplicate install.

---

### Task 14: Make local install primary onboarding

**Files:**

- Create: `lib/features/local_setup/screens/local_setup_screen.dart` and widget test
- Modify: `hermes_chat_layout.dart`, routes, router, `app_en.arb`
- Regenerate: `app_localizations*.dart`

**Interfaces:** `/setup/local`, key `hermes-install-local`.

- [ ] **Step 1: Write failing widget tests**

```dart
testWidgets('Android presents install before remote connection', (tester) async {
  await tester.pumpWidget(buildDisconnectedHermesApp(platform: TargetPlatform.android));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('hermes-install-local')), findsOneWidget);
  expect(find.text('Install Hermes on this phone'), findsOneWidget);
  expect(find.byKey(const ValueKey('hermes-base-url-field')), findsOneWidget);
});
```

Add Donna selected-by-default/disclosure/opt-out/incompatibility, OmniRoute unchecked/disclosure, Termux guidance, progress/retry, partial success, 200% scale, semantics, and 320 px no-overflow tests.

- [ ] **Step 2: Add route outside shell**

```dart
static const localSetup = '/setup/local';
```

Register beside `/enroll` because no endpoint exists.

- [ ] **Step 3: Add install card before VPS card**

```dart
Card(
  key: const ValueKey('hermes-local-install-card'),
  child: ListTile(
    leading: const Icon(Icons.install_desktop_outlined),
    title: Text(strings.localSetupInstallTitle),
    subtitle: Text(strings.localSetupInstallBody),
    trailing: FilledButton(
      key: const ValueKey('hermes-install-local'),
      onPressed: () => context.push(AppRoutes.localSetup),
      child: Text(strings.localSetupInstallAction),
    ),
  ),
)
```

Keep manual endpoint/QR alternatives.

- [ ] **Step 4: Build guided screen**

Render Termux missing, permission missing, bootstrap command, ready options, resumable semantic progress, independent Donna/OmniRoute warnings, and completion. Donna starts selected with source, persona/skills/plugins/defaults, MIT license, and compatibility status disclosed; the user may deselect it. If the pinned commit remains incompatible, disable its selection with a clear upstream-manifest explanation rather than bypassing Hermes. OmniRoute starts unchecked and displays:

```text
OmniRoute is an independent MIT-licensed project. Free-tier quotas, availability, privacy policies, and provider terms vary. Prompts are sent to the providers OmniRoute selects.
```

Never show raw logs/secrets/paths/command output.

- [ ] **Step 5: Generate and verify**

```bash
flutter gen-l10n
flutter test --concurrency=1 test/features/local_setup test/features/hermes_chat/screens/hermes_chat_screen_test.dart
flutter analyze
```

- [ ] **Step 6: Reviewer checkpoint**

Android/desktop visual check confirms “guided local installation,” not zero-interaction; Donna is disclosed and deselectable, and OmniRoute is not preselected.

---

## Phase 5 — Packaging, migration, evidence

### Task 15: Build and bundle target binaries

**Files:**

- Create: `scripts/build_wing_link.sh`
- Modify: `linux/CMakeLists.txt`, `windows/runner/CMakeLists.txt`, `macos/Runner.xcodeproj/project.pbxproj`, `pubspec.yaml`
- Create: `test/tooling/wing_link_packaging_contract_test.dart`

**Interfaces:** Linux amd64/arm64, Android arm64, Windows amd64, macOS amd64/arm64 binaries.

- [ ] **Step 1: Write failing packaging test**

```dart
test('desktop packaging names Wing Link', () {
  expect(File('linux/CMakeLists.txt').readAsStringSync(), contains('wing-link-linux'));
  expect(File('windows/runner/CMakeLists.txt').readAsStringSync(), contains('wing-link-windows-amd64.exe'));
  expect(File('macos/Runner.xcodeproj/project.pbxproj').readAsStringSync(), contains('wing-link-darwin'));
});
```

- [ ] **Step 2: Implement deterministic build**

```bash
(
  cd wing_link
  CGO_ENABLED=0 GOOS="$goos" GOARCH="$goarch" \
    go build -trimpath -buildvcs=true \
      -ldflags "-s -w -X main.version=$version" \
      -o "$output" .
)
```

Build Android as `GOOS=android GOARCH=arm64`. Native packaging includes only matching binary. First launch copies to Wing-owned app data, verifies release digest, chmods POSIX, then executes.

- [ ] **Step 3: Verify GREEN**

```bash
./scripts/build_wing_link.sh current
flutter test --concurrency=1 test/tooling/wing_link_packaging_contract_test.dart
flutter build linux --release
```

- [ ] **Step 4: Reviewer checkpoint**

Package contains no Agent/Python/Node/Donna archive/OmniRoute archive/.env/token/private key.

---

### Task 16: Rename `wing-cli` after Go parity

**Files:**

- Create: `install-wing-link.sh`
- Modify: `wing-cli`, `install-wing-cli.sh`, package/wing CLI tests, `README.md`

**Interfaces:** canonical `wing-link`; one-release compatibility shim.

- [ ] **Step 1: Add failing shim test**

```dart
test('wing-cli is a bounded compatibility shim', () {
  final shim = File('wing-cli').readAsStringSync();
  expect(shim, contains('exec wing-link "$@"'));
  expect(shim, contains('wing-cli is deprecated; use wing-link'));
  expect(shim, isNot(contains('pairing_broker')));
  expect(shim, isNot(contains('API_SERVER_KEY')));
});
```

Keep current security tests until Go Tasks 3/6/9 cover them.

- [ ] **Step 2: Replace only after parity**

```bash
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' 'wing-cli is deprecated; use wing-link' >&2
exec wing-link "$@"
```

`install-wing-link.sh` verifies prebuilt SHA-256. Old installer delegates with rename warning for one release. README uses `wing-link status|pair|service install`.

- [ ] **Step 3: Verify GREEN**

```bash
flutter test --concurrency=1 test/tooling/wing_cli_contract_test.dart test/tooling/package_scripts_contract_test.dart
./wing-cli version
./install-wing-link.sh --help
```

- [ ] **Step 4: Reviewer checkpoint**

Manually compare dirty `wing-cli`; preserve any security behavior not covered by Go tests.

---

### Task 17: Add CI, smokes, and physical receipt

**Files:**

- Modify: `.github/workflows/hermes-platform-smoke.yml`, `package.json`, package contract test, Android setup docs, changelog
- Create: `scripts/run_wing_link_smoke.sh`, `scripts/run_termux_local_install_receipt.sh`, `docs/runbooks/wing-link-local-install.md`

**Interfaces:** reproducible Go/package smoke and redacted physical Termux receipt.

- [ ] **Step 1: Add failing script contract**

```dart
const expectedWingLinkScripts = {
  'wing-link:test': './scripts/run_wing_link_smoke.sh',
  'android:local-install-receipt': './scripts/run_termux_local_install_receipt.sh',
};
```

Require executable, `set -euo pipefail`, and `not whole-goal completion evidence`.

- [ ] **Step 2: Add CI**

Use Go 1.26.5:

```bash
cd wing_link
test -z "$(gofmt -l .)"
go vet ./...
go test -race ./...
```

Cross-build/upload Android arm64, Linux amd64/arm64, Windows amd64, macOS amd64/arm64 as unsigned CI artifacts—not releases.

- [ ] **Step 3: Add deterministic smoke**

Use temporary `WING_LINK_HOME` and fake verified installer/health servers to prove local enrollment, authenticated status, one operation, SSE reconnect, concurrent 409, current Donna incompatibility before execution, existing Donna adoption, Hermes success despite Donna or OmniRoute failure, no secret in logs, and a loopback-only listener.

- [ ] **Step 4: Define physical receipt**

```json
{
  "schema": 1,
  "android_target_type": "physical_device",
  "termux_detected": true,
  "run_command_permission_granted": true,
  "wing_link_loopback_healthy": true,
  "hermes_installed": true,
  "hermes_capabilities_verified": true,
  "starter_profile_selected": false,
  "starter_profile_installed": false,
  "starter_profile_name": "",
  "starter_profile_blocker": "missing_distribution_manifest",
  "wing_enrollment_completed": true,
  "provider_test_turn_completed": true,
  "omniroute_selected": false,
  "secrets_excluded": true
}
```

Until a compatible pinned Donna distribution exists, the physical receipt records `starter_profile_selected: false`, `starter_profile_installed: false`, and the bounded compatibility blocker instead of claiming installation. A later receipt may set Donna true only after official Hermes installation and profile-inventory verification. A separate receipt may set OmniRoute true only after disclosure and real provider completion. No transcript/token/private path/provider payload/raw command output.

- [ ] **Step 5: Run full validation**

```bash
cd wing_link && go test -race ./... && go vet ./...
cd ..
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --concurrency=1
npm run wing-link:test
flutter build apk --debug
flutter build linux --release
npm run web:e2e
npm audit --audit-level=high
```

Web/iOS must hide local install and retain remote Hermes.

- [ ] **Step 6: Record physical flow**

On clean physical Android: install Wing; choose local install; review Donna disclosure and compatibility; install/open Termux; run bootstrap; grant permission; install Hermes without OmniRoute; verify Donna through Hermes when a compatible pin exists or record the fail-closed blocker; enroll; complete one turn; kill/reopen Wing; verify health; rerun setup and verify adoption; optionally repeat with OmniRoute consent.

- [ ] **Step 7: Reviewer checkpoint**

Do not publicly claim “install Hermes on your phone” until signed package and physical receipts pass. Marketing says guided, not zero-interaction or guaranteed-free.

---

## Acceptance Matrix

| Scenario                               | Required result                                                      |
| -------------------------------------- | -------------------------------------------------------------------- |
| Existing healthy Hermes                | Adopt without installer/config mutation                              |
| Fresh PC install                       | Verified pinned installer, per-user runtime, health + capabilities   |
| Fresh Termux install                   | One bootstrap, explicit permission, rootless install, local health   |
| Missing Termux                         | Guided official install; no silent APK install                       |
| Background during install              | Wing Link continues; UI resumes events                               |
| Duplicate install tap                  | One operation; second gets conflict                                  |
| Tampered installer                     | Reject before execution and delete staged file                       |
| Current Donna pin                      | Disabled/fails before download because `distribution.yaml` is absent |
| Compatible Donna selected              | Verified archive; official Hermes install; profile `donna` selected  |
| Existing Donna                         | Adopt without overwrite or automatic update                          |
| Donna failure                          | Hermes/default profile remain usable                                 |
| OmniRoute not selected                 | No npm download/process/files                                        |
| OmniRoute selected                     | Exact 3.8.49, disclosure, loopback only                              |
| OmniRoute failure                      | Hermes usable; provider recovery shown                               |
| Existing configured Hermes + OmniRoute | Active provider unchanged                                            |
| Secure pairing                         | One-time code only; scoped Hermes token stored by Wing               |
| Wing Link token                        | Secure storage + Authorization header only                           |
| Wing uninstall/reinstall               | Runtime/data preserved and rediscovered                              |
| Web/iOS                                | Local controls hidden; remote Hermes works                           |

## Plan Self-Review

- **Coverage:** Wing Link rename/service, PC and Termux installation, `RUN_COMMAND`, bootstrap, Android onboarding, secure enrollment, pinned Donna starter profile, optional OmniRoute, packaging, migration, CI, and physical evidence map to Tasks 1–17.
- **YAGNI:** no remote Wing Link listener, chat proxy, embedded runtime, generic command API, or automatic third-party install.
- **Security:** pinned artifacts, loopback+bearer management, one-time enrollment, no arbitrary execution/superuser handoff.
- **Consistency:** protocol `1`, port `8654`, `wlc_` token, `op_` operation, `/setup/local`, `WingLinkClient`, and `LocalSetupController` remain fixed.
- **Dirty tree:** old `wing-cli` is replaced only after Go parity and manual owner-change review.

## Execution Stop Gates

1. Complete Tasks 1–5 before executing downloads.
2. Complete Task 6 security review before exposing installation in Flutter.
3. Complete Task 9 before clients receive a Wing Link token.
4. Complete Tasks 11–14 before making install primary onboarding.
5. Keep Donna installation disabled until the signed manifest pins a reviewed archive with a valid `distribution.yaml`; never substitute a mutable or direct clone.
6. Complete signed packaging and physical Termux receipt before public release claims.
7. Donna and OmniRoute remain independently recoverable; either may be unavailable without blocking a healthy Hermes installation.
