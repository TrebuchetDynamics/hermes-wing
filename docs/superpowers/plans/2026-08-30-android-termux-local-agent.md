# Android Termux Local Hermes Agent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let an Android user start in Hermes Wing, run one explicit verified command in Termux, return through the existing same-device pairing flow, and complete every setup operation Wing can safely support without turning Wing into a shell bridge or a second Hermes backend.

**Architecture:** Choose a guided handoff, not Android `RUN_COMMAND`. Wing displays a public, release-pinned bootstrap command; the user explicitly runs it in Termux. The command installs a verified Android/ARM64 Wing Link binary, Wing Link installs/adopts pinned Hermes Agent, both bind to loopback, and `wing-link pair --local --same-device` exposes only the existing code-free `/open` URL. After enrollment, Wing continues to talk directly to Hermes Agent for the data plane and directly to Wing Link for typed host management.

**Tech Stack:** Flutter 3.44.2/Dart/Riverpod/go_router/url_launcher, Android intents already present in Hermes Wing, Go 1.26 Wing Link, Hermes Agent's pinned Termux-aware installer, GitHub Actions release metadata, Flutter/Go/widget/source-contract tests, physical Android + Termux qualification.

## Global Constraints

- Hermes Agent remains an external authoritative runtime. Hermes Wing must not embed it or create shadow profile, provider, session, run, tool, schedule, Project, or gateway state.
- A paired same-device host still has two independent loopback connections and credentials: Wing → Hermes Agent and Wing → Wing Link.
- Hermes Agent and Wing Link bind only to `127.0.0.1` for this flow. HTTP is allowed only because both origins are loopback.
- The copied bootstrap command is public and may contain only immutable release identifiers, exact byte sizes, and SHA-256 digests. It must contain no API key, provider credential, bearer token, pairing code, private path, or caller-selected URL.
- Do not request `com.termux.permission.RUN_COMMAND`, set `allow-external-apps=true`, add a generic command channel, or accept command text/path/arguments from Dart. Termux documents that `RUN_COMMAND` grants third-party command execution in the Termux context and requires both a permission and `allow-external-apps=true`; that privilege is unnecessary after authenticated Wing Link exists: https://github.com/termux/termux-app/wiki/RUN_COMMAND-Intent
- Never pipe a download directly into a shell. Download the immutable installer, verify its exact SHA-256, then execute it.
- Preserve the existing pairing contract: five-minute single-use code, no-store handoff page, explicit review, separate credential storage, acknowledgment, and no bearer credential in URLs, QR, clipboard, shared text, argv, logs, or ordinary preferences.
- Android/Termux remains Hermes Agent Tier 2. Gateway and Wing Link background operation are best-effort; do not call either an Android managed service or claim boot/crash persistence. The first public prerelease is a qualification candidate, not support evidence; promote support wording only in a follow-up release after Task 7's physical receipts.
- Existing-profile provider/configuration mutation remains blocked. Wing may use only advertised Agent APIs plus the current transactional **new-profile** setup path with allowlisted provider, bounded model, stdin-only credential, rollback, readiness probing, and local host approval.
- Remote approval remains prohibited even on the same physical phone. If a sensitive setup operation requires approval, the user approves it in Termux.
- A new profile is not chat-enrolled merely because Wing Link can list it. It needs its own `/p/<profile>` credential bundle; until Hermes Agent advertises a safe scoped enrollment operation, the user must pair again after creating a new profile.
- Use only Hermes Agent's official installer from the reviewed immutable `NousResearch/hermes-agent` commit already pinned by Wing Link. Do not use the mutable website one-liner or the community-maintained APT repository in Wing's managed path; those cannot provide the same end-to-end release pin and publisher boundary.
- Preserve the official installer’s Termux detection and package order: `.[termux-all]` → `.[termux]` → base fallback with `constraints-termux.txt`. Wing Link must not reproduce Python/package installation logic; it invokes the verified installer non-interactively, then verifies `hermes --version` and authenticated capability readiness.
- Do not promise `.[all]`, local `faster-whisper`, Docker isolation, browser bootstrap, WhatsApp bootstrap, or persistent background hosting on Android. The tested Termux path may provide CLI, cron, PTY/background terminal, Telegram gateway, MCP, Honcho memory, and ACP only to the extent reported by the installed Agent version; Wing must not infer those capabilities locally.
- Edit English copy in `lib/l10n/app_en.arb` and regenerate localization Dart.
- Preserve the current dirty worktree. In particular, inspect and merge around owner changes already present in `install-wing-link.sh`, `wing_link/internal/app/bootstrap.go`, `wing_link/internal/app/pair.go`, `lib/features/enrollment/screens/hermes_enrollment_screen.dart`, the Android pairing code, and their tests. Do not reset, overwrite, stage, or commit unless separately requested.

---

## User Flow

1. In Android Wing enrollment, choose **Install Hermes Agent on this phone**.
2. Wing explains the Tier 2 limitations and links to Termux's official installation guidance. Termux publishes current installation/source warnings here: https://github.com/termux/termux-app#installation
3. Wing shows one release-pinned command and copies it only after the user taps **Copy setup command**.
4. The user opens Termux, pastes the command, and keeps Termux in the foreground while installation runs.
5. The verified installer installs/adopts Hermes Agent, configures authenticated `127.0.0.1:8642`, starts its gateway best-effort, starts Wing Link on `127.0.0.1:8654`, and prints a clickable `http://127.0.0.1:<ephemeral>/open` URL.
6. The user taps that code-free URL, then taps **Open Hermes Wing** on the no-store page. Existing `wing://connect` enrollment opens Wing for review and exchange.
7. After pairing, the user chooses one of two honest model-setup paths:
   - **Shortest path:** run `hermes setup` in Termux for the existing default profile, then use Wing for chat and supported administration.
   - **Most setup in Wing:** create a new profile in Wing with description/provider/model/write-only credential, approve the sensitive operation in Termux, retry the frozen request with the same idempotency key, then run `wing-link pair --local --same-device` once more so Wing receives that profile's own Agent credential.
8. If Android later kills Termux processes, rerun the same idempotent bootstrap command. Wing must describe this as recovery, not automatic restart.

## Scope Boundary

### Wing can complete after enrollment

- direct Agent health/capability checks, sessions, chat, runs, approvals, and every exact advertised Agent operation;
- Wing Link health and current supported typed host operations while Wing Link is alive;
- profile list/create/rename/delete through the existing bounded compatibility adapter;
- transactional **new-profile** description/provider/model/write-only credential setup;
- secure storage of independent Agent and Wing Link credentials;
- explicit re-pairing to import an updated profile bundle.

### Termux remains required for

- installing the Termux app itself and running the initial command;
- local host approval of sensitive operations;
- `hermes setup` or `hermes model` for the existing default profile, because Hermes Agent owns that configuration and exposes no reviewed existing-profile write API for Wing;
- restarting after Android kills both local processes;
- optional/experimental browser, WhatsApp, voice-extra, or other unsupported Termux work.

---

## File Structure

### New files

- `wing_link/internal/app/bootstrap_gateway.go` — pure fixed command-spec construction shared by host tests and platform wrappers.
- `wing_link/internal/app/bootstrap_gateway_android.go` — `//go:build android`; starts the Hermes gateway as a detached, best-effort Termux process with fixed executable/arguments and owner-only log output.
- `wing_link/internal/app/bootstrap_gateway_other.go` — `//go:build !android`; preserves the current managed-service gateway commands on non-Android platforms.
- `assets/config/termux_bootstrap.json` — checked-in unavailable default; release CI replaces it with the exact non-secret installer/asset metadata packaged inside the signed APK/AAB.
- `lib/features/local_setup/models/termux_bootstrap_command.dart` — validates packaged release metadata and renders the one fixed public command.
- `lib/features/local_setup/screens/termux_hermes_setup_screen.dart` — Android-only guided handoff UI; it never executes Termux commands.
- `test/features/local_setup/termux_bootstrap_command_test.dart` — command validation, pinning, and secret-exclusion checks.
- `test/features/local_setup/termux_hermes_setup_test.dart` — Android setup UX, copy action, accessibility, and unsupported-build checks.
- `docs/runbooks/android-termux-local-agent.md` — same-device install, setup choices, recovery, and qualification limits.

### Modified files

- `wing_link/internal/app/bootstrap.go`, `bootstrap_test.go` — Termux shell resolution, setup availability, and platform gateway starter seam.
- `wing_link/internal/app/inspect.go`, `inspect_test.go` — advertise setup on reviewed Android builds without calling it a managed service.
- `wing_link/internal/app/pair.go`, `pair_test.go`, `cli.go`, `cli_test.go` — `--same-device` output mode with only the code-free `/open` URL.
- `install-wing-link.sh` — permit exact Termux `--setup`, start Wing Link best-effort, and enter same-device pairing.
- `test/tooling/wing_link_distribution_contract_test.dart` — executable Termux installer contract and no-download-pipe assertions.
- `.github/workflows/release-alpha.yml` — build Wing Link first and embed exact Termux installer/asset metadata in the signed Android APK/AAB.
- `scripts/verify_release_artifacts.sh` — extract and verify the packaged Android bootstrap metadata against the released Wing Link asset.
- `lib/features/enrollment/screens/hermes_enrollment_screen.dart` — Android local-install entry and loopback completion guidance.
- `lib/router/routes/app_routes.dart`, `lib/router/providers/app_router.dart` — route `/setup/local` to the Android Termux screen or existing Linux screen.
- `lib/l10n/app_en.arb` plus generated localization Dart — exact Tier 2, copy, recovery, and setup-boundary wording.
- `test/features/enrollment/hermes_enrollment_flow_test.dart` and router tests — local-install entry, return, and no-secret rendering.
- `lib/features/profiles/widgets/profile_editor_sheet.dart`, `lib/features/profiles/screens/profiles_screen.dart`, and focused tests — preserve an approval-bound create request in memory and retry it with the exact same idempotency key.
- `pubspec.yaml` — package the canonical Termux bootstrap metadata asset.
- `docs/adr/runtime-and-delivery.md`, `docs/adr/security-and-privacy.md`, `docs/security/threat-model.md`, `docs/product/routes.md`, `docs/runbooks/android-hermes-setup.md`, `README.md` — candidate behavior first; support wording only after physical qualification.

---

### Task 1: Lock the Termux support and trust contract

**Files:**

- Modify: `docs/adr/runtime-and-delivery.md`
- Modify: `docs/adr/security-and-privacy.md`
- Modify: `docs/security/threat-model.md`
- Modify: `docs/product/routes.md`
- Create: `docs/runbooks/android-termux-local-agent.md`
- Modify: `docs/runbooks/android-hermes-setup.md`
- Modify: `README.md`
- Test: nearest existing tooling/docs contract test

**Interfaces:**

- Produces one candidate shape pending Task 7 evidence: explicit user-run verified bootstrap → loopback Agent/Wing Link → existing enrollment.
- Rejects `RUN_COMMAND`, background-service claims, and existing-profile secret/config mutation.

- [x] **Step 1: Add a failing documentation contract**

Add one source-contract test requiring all of these exact concepts:

```dart
expect(runtimeDecision, contains('Android/Termux'));
expect(runtimeDecision, contains('best-effort background'));
expect(runtimeDecision, contains('explicit user-run bootstrap'));
expect(runtimeDecision, contains('does not request Termux external-command access'));
expect(threatModel, contains('Wing and Termux remain separate app sandboxes'));
expect(termuxRunbook, contains('127.0.0.1:8642'));
expect(termuxRunbook, contains('127.0.0.1:8654'));
expect(termuxRunbook, contains('pair again'));
expect(termuxRunbook, contains('Tier 2'));
```

- [x] **Step 2: Run the contract and verify RED**

```bash
flutter test test/tooling --plain-name 'Android Termux local hosting remains bounded'
```

Expected: FAIL because same-device Termux hosting is currently explicitly unqualified and undocumented.

- [x] **Step 3: Update the living decisions**

Add this narrow decision to `runtime-and-delivery.md`:

```markdown
Android/Termux may host Wing Link and Hermes Agent only through an explicit,
user-run, release-pinned bootstrap. Both listeners remain loopback-only and
background execution is best-effort; this is not a managed-service
qualification. Hermes Wing does not request Termux external-command access.
```

In the security ADR and threat model, state that Wing and Termux are separate app sandboxes sharing only authenticated loopback sockets. Any local app may probe loopback, so Agent/Wing Link authentication remains mandatory. The bootstrap command is non-secret; raw provider credentials and pairing codes never enter it.

- [x] **Step 4: Split the runbooks clearly**

Keep `docs/runbooks/android-hermes-setup.md` for Android connecting to a remote Linux host. Put same-phone Termux hosting in `docs/runbooks/android-termux-local-agent.md`. Include the two setup choices and the required second pairing after Wing-created profiles.

- [x] **Step 5: Verify GREEN and links**

```bash
flutter test test/tooling --plain-name 'Android Termux local hosting remains bounded'
git diff --check
```

Expected: PASS; all local Markdown links resolve.

---

### Task 2: Make Wing Link bootstrap Hermes correctly on Termux

**Files:**

- Create: `wing_link/internal/app/bootstrap_gateway.go`
- Create: `wing_link/internal/app/bootstrap_gateway_android.go` with `//go:build android`
- Create: `wing_link/internal/app/bootstrap_gateway_other.go` with `//go:build !android`
- Modify: `wing_link/internal/app/bootstrap.go`
- Modify: `wing_link/internal/app/bootstrap_test.go`
- Modify: `wing_link/internal/app/inspect.go`
- Modify: `wing_link/internal/app/inspect_test.go`
- Modify: `wing_link/internal/app/pair.go`
- Modify: `wing_link/internal/app/pair_test.go`

**Interfaces:**

- Produces: `func startHermesGateway(context.Context, string, string, func(context.Context, ...string) error) error`.
- Produces: `func setupAvailableForPlatform(string) bool` returning true only for `linux` and `android`.
- Continues to download the official Hermes installer only from the reviewed immutable commit with exact size and SHA-256 checks, passing fixed `--commit`, `--skip-setup`, `--non-interactive`, and `--hermes-home` arguments.
- Preserves the existing non-Android `hermes gateway install` + `restart --all` behavior.

- [x] **Step 1: Write failing platform tests**

```go
func TestSetupAvailableForPlatform(t *testing.T) {
	for platform, want := range map[string]bool{
		"linux": true, "android": true, "darwin": false, "windows": false,
	} {
		if got := setupAvailableForPlatform(platform); got != want {
			t.Fatalf("%s: got %v want %v", platform, got, want)
		}
	}
}

func TestInstallerShellUsesTermuxPrefix(t *testing.T) {
	t.Setenv("PREFIX", "/data/data/com.termux/files/usr")
	if got := resolveInstallerShell("android"); got != "/data/data/com.termux/files/usr/bin/bash" {
		t.Fatalf("got %q", got)
	}
}
```

Put pure command-spec construction in untagged `bootstrap_gateway.go`, then add a host-runnable test proving the Android starter uses exactly:

```text
/data/data/com.termux/files/usr/bin/hermes gateway
HERMES_HOME=/data/data/com.termux/files/home/.hermes
stdout/stderr=/data/data/com.termux/files/home/.hermes/logs/gateway.log
```

The test fixture uses these canonical Termux paths; production derives the same shape from validated `PREFIX` and Hermes home values.

No shell-selected command, provider value, token, caller-selected URL, or caller-provided arguments may appear. Add a contract assertion that Android still uses the exact pinned official installer and does not reference `hermes-agent.nousresearch.com/install.sh`, `adybag14-cyber`, or an APT repository.

- [x] **Step 2: Run and verify RED**

```bash
(cd wing_link && go test ./internal/app -run 'SetupAvailable|InstallerShell|TermuxGateway' -count=1)
```

Expected: missing helpers and Android gateway path.

- [x] **Step 3: Resolve the installer shell by platform**

Replace the hardcoded POSIX `/bin/bash` selection with:

```go
func resolveInstallerShell(platform string) string {
	if platform == "android" {
		return filepath.Join(strings.TrimSpace(os.Getenv("PREFIX")), "bin", "bash")
	}
	return "/bin/bash"
}
```

Validate the Android prefix is absolute, points to the Termux package root, and resolves to a regular executable before use. Keep the installer path, pinned commit, exact size, SHA-256, host allowlist, and fixed arguments unchanged.

- [x] **Step 4: Add the Android best-effort gateway starter**

`bootstrap_gateway_android.go` must start with `//go:build android`. It consumes the tested pure spec and must:

1. create the validated Hermes home's `logs` directory mode `0700`;
2. open `gateway.log` with `0600`;
3. start the exact Hermes executable with argument `gateway`;
4. set only the inherited environment plus the validated `HERMES_HOME` value;
5. detach the child process/session without a shell;
6. release the process handle and let the existing authenticated capability probe decide success.

`bootstrap_gateway_other.go` must start with `//go:build !android` and call the existing fixed commands:

```text
hermes gateway install
hermes gateway restart --all
```

- [x] **Step 5: Use the platform starter from `BootstrapManager`**

Keep the existing healthy preflight. Only call the starter when Agent capability health is absent; always run the existing bounded verification afterward. Return `gateway_started: true` only after verification succeeds.

Also route `ensureHermesProfileMultiplex` through the same platform restart seam. On Android, apply multiplex configuration, run the fixed `hermes gateway stop`, start `hermes gateway` detached, and then use the existing bounded `/p/<profile>/v1/capabilities` probes. Do not call synchronous `hermes gateway restart` on Termux because upstream's manual fallback runs the gateway in the foreground.

- [x] **Step 6: Run host and cross-build checks**

```bash
(cd wing_link && gofmt -w internal/app/bootstrap*.go internal/app/inspect*.go)
(cd wing_link && go test ./... -count=1)
(cd wing_link && GOOS=android GOARCH=arm64 CGO_ENABLED=0 go build -trimpath -buildmode=pie -o /tmp/wing-link-android .)
```

Expected: all tests pass and the Android PIE cross-build succeeds. Cross-build is not runtime qualification.

---

### Task 3: Add a code-free same-device pairing mode and idempotent Termux installer

**Files:**

- Modify: `wing_link/internal/app/pair.go`
- Modify: `wing_link/internal/app/pair_test.go`
- Modify: `wing_link/internal/app/cli.go`
- Modify: `wing_link/internal/app/cli_test.go`
- Modify: `install-wing-link.sh`
- Modify: `test/tooling/wing_link_distribution_contract_test.dart`

**Interfaces:**

- Produces CLI flag `wing-link pair --local --same-device`.
- `--same-device` prints the code-free loopback URL produced by `pairingBroker.OpenURL` (for example `http://127.0.0.1:43123/open`) and never prints the raw `wing://connect` URI or QR.
- Termux `install-wing-link.sh --tag ... --sha256 ... --size ... --setup` performs verified install/setup/start/pair without systemd.

- [x] **Step 1: Write failing pairing tests**

```go
func TestSameDeviceOutputContainsOnlyOpenURL(t *testing.T) {
	// Build the existing broker fixture with OpenURL and a code-bearing PairingURI.
	writePairHumanOutput(&stdout, &stderr, broker, pairOptions{SameDevice: true})
	output := stdout.String() + stderr.String()
	if !strings.Contains(output, broker.OpenURL.String()) { t.Fatal("missing /open URL") }
	if strings.Contains(output, "wing://connect") || strings.Contains(output, "one-time-code") {
		t.Fatal("same-device output exposed the code-bearing handoff")
	}
}
```

Add parser tests proving `--same-device` implies local mode and conflicts with `--remote`, `--qr`, and a non-loopback `--origin`.

- [x] **Step 2: Run and verify RED**

```bash
(cd wing_link && go test ./internal/app -run 'SameDevice|Pair.*Output' -count=1)
```

- [x] **Step 3: Implement the smallest output branch**

Add one `SameDevice bool` to `pairOptions`. Do not add another pairing protocol. Reuse `pairingBroker.OpenURL`, `/open`, the existing browser page, and the existing enrollment exchange.

- [x] **Step 4: Replace the Termux setup rejection with a strict Termux path**

In `install-wing-link.sh`:

- retain ARM64-only and `$PREFIX/bin` checks;
- reject `--size` values outside `1..52428800` before any network access, even when a caller supplies the metadata;
- allow `--setup` only when `TERMUX_VERSION` and the canonical Termux `$PREFIX` are present;
- run `wing-link setup` first;
- check `http://127.0.0.1:8654/healthz`; if unavailable, start exactly `wing-link serve --listen 127.0.0.1:8654` under `nohup` with owner-only state/log directories;
- poll `/healthz` with a bounded timeout;
- run `WING_LINK_SERVICE=external wing-link pair --local --same-device` in the foreground;
- on rerun, adopt healthy Agent/Wing Link instead of starting duplicates.

Do not create a Termux:Boot script, request battery exemptions, modify `allow-external-apps`, or claim persistence.

- [x] **Step 5: Replace the old rejection test with executable fake-Termux coverage**

The shell test must use fake `wing-link`, `curl`, and `nohup` executables and assert the exact call sequence:

```text
wing-link setup
wing-link serve --listen 127.0.0.1:8654
wing-link pair --local --same-device
```

Also assert:

```dart
expect(installer, isNot(contains('curl |')));
expect(installer, isNot(contains('allow-external-apps')));
expect(installer, isNot(contains('com.termux.RUN_COMMAND')));
expect(fakeTermuxCalls, isNot(contains('systemctl')));
```

- [x] **Step 6: Run focused validation**

```bash
flutter test test/tooling/wing_link_distribution_contract_test.dart
(cd wing_link && go test ./... -count=1)
bash -n install-wing-link.sh
git diff --check
```

---

### Task 4: Bind the signed Android app to exact bootstrap metadata

**Files:**

- Create: `assets/config/termux_bootstrap.json`
- Create: `lib/features/local_setup/models/termux_bootstrap_command.dart`
- Create: `test/features/local_setup/termux_bootstrap_command_test.dart`
- Modify: `pubspec.yaml`
- Modify: `.github/workflows/release-alpha.yml`
- Modify: `scripts/verify_release_artifacts.sh`
- Modify: `test/tooling/wing_link_distribution_contract_test.dart`

**Interfaces:**

- Packages one canonical JSON object inside the signed APK/AAB with fields `available`, `tag`, `installer_commit`, `installer_sha256`, `asset_sha256`, and `asset_size`.
- Produces `TermuxBootstrapCommand.fromJson(Map<String, Object?>)` and `String get command`.
- The checked-in asset contains only `{"available":false}` so local/unqualified builds disable copy.
- Missing/invalid metadata disables the copy action; it never falls back to `latest`, `main`, an unsigned catalog, or a caller URL.

- [x] **Step 1: Write failing pure-Dart tests**

Use a fixed valid fixture and assert:

```dart
expect(command, contains('pkg install -y curl coreutils'));
expect(command, contains('raw.githubusercontent.com/TrebuchetDynamics/hermes-wing/'));
expect(command, contains('--tag v0.1.0-alpha.9'));
final digest = List.filled(64, 'a').join();
expect(command, contains('--size 1234567'));
expect(command, contains('--sha256 $digest'));
expect(command, contains('--setup'));
expect(command, isNot(allOf(contains('curl -fsSL'), contains('| bash'))));
expect(command, isNot(contains('token')));
expect(command, isNot(contains('code=')));
```

Reject non-alpha tags, non-40-character commits, non-64-character lowercase hex digests, asset sizes outside `1..52428800`, whitespace, shell metacharacters, and alternate hosts.

- [x] **Step 2: Run and verify RED**

```bash
flutter test test/features/local_setup/termux_bootstrap_command_test.dart
```

- [x] **Step 3: Implement the fixed renderer**

Render only this command shape after validation:

```dart
final command =
    'pkg install -y curl coreutils && i="\$(mktemp)" && '
    'curl --proto \'=https\' --tlsv1.2 --fail --location '
    '--connect-timeout 15 --max-time 300 --max-filesize 1048576 '
    '--output "\$i" '
    '"https://raw.githubusercontent.com/TrebuchetDynamics/hermes-wing/'
    '$installerCommit/install-wing-link.sh" && '
    'printf \'%s  %s\\n\' \'$installerSha256\' "\$i" | sha256sum -c - && '
    '"\$PREFIX/bin/bash" "\$i" --tag \'$tag\' '
    '--sha256 \'$assetSha256\' --size \'$assetSize\' --setup';
```

The renderer validates every field before building this string, caps the installer download at 1 MiB and the Wing Link asset at 50 MiB, and accepts no runtime/user values. Fix the matcher example to use `isNot(allOf(contains('curl -fsSL'), contains('| bash')))`; matcher objects cannot be combined with `&&`.

- [x] **Step 4: Package one canonical metadata asset**

Add `assets/config/termux_bootstrap.json` to `pubspec.yaml`. Load it with the Flutter asset bundle and pass its decoded map into `TermuxBootstrapCommand.fromJson`; tests inject maps directly.

In `.github/workflows/release-alpha.yml`:

1. change Android `needs` to `[validation, wing-link]`;
2. download the `wing-link-release` artifact;
3. require exactly one `wing-link-android-arm64` checksum entry;
4. compute its exact byte size and reject values above 50 MiB;
5. compute `sha256sum install-wing-link.sh` and use `${GITHUB_SHA}` as the immutable installer commit;
6. atomically replace `assets/config/termux_bootstrap.json` with canonical JSON containing those exact values;
7. run the command-model/widget tests against that asset;
8. build APK and AAB normally; both consume the same packaged file.

- [x] **Step 5: Verify metadata inside the signed artifacts**

`scripts/verify_release_artifacts.sh` must extract `assets/flutter_assets/assets/config/termux_bootstrap.json` from the exact signed APK and the corresponding Flutter asset path from the AAB, require byte-identical JSON, and compare it with the exact released Wing Link asset/checksum, installer source digest, tag, and source revision. It must fail on missing, duplicate, malformed, oversized, unavailable, or mismatched metadata. A sidecar receipt alone is not evidence that the app contains the values.

- [x] **Step 6: Run source checks**

```bash
flutter test test/features/local_setup/termux_bootstrap_command_test.dart test/tooling/wing_link_distribution_contract_test.dart
flutter build apk --debug
unzip -p build/app/outputs/flutter-apk/app-debug.apk assets/flutter_assets/assets/config/termux_bootstrap.json
bash -n scripts/verify_release_artifacts.sh
git diff --check
```

---

### Task 5: Add the Android guided setup screen without a command bridge

**Files:**

- Create: `lib/features/local_setup/screens/termux_hermes_setup_screen.dart`
- Create: `test/features/local_setup/termux_hermes_setup_test.dart`
- Modify: `lib/features/enrollment/screens/hermes_enrollment_screen.dart`
- Modify: `lib/router/routes/app_routes.dart`
- Modify: `lib/router/providers/app_router.dart`
- Modify: `lib/l10n/app_en.arb`
- Regenerate: `lib/l10n/app_localizations.dart`
- Regenerate: `lib/l10n/app_localizations_en.dart`
- Modify: `test/features/enrollment/hermes_enrollment_flow_test.dart`
- Modify: nearest router test

**Interfaces:**

- `/setup/local` renders `TermuxHermesSetupScreen` on Android and the existing `LocalHermesSetupScreen` on Linux.
- `TermuxHermesSetupScreen` loads only the packaged `assets/config/termux_bootstrap.json` and passes it to `TermuxBootstrapCommand.fromJson`.
- It may open the official Termux installation page and copy the public command after a user tap. It never inspects, launches, or executes a Termux binary.

- [x] **Step 1: Write failing widget tests**

Cover:

- Android enrollment shows **Install Hermes Agent on this phone** before manual one-profile connection.
- The setup screen shows Termux Tier 2/background limitations, states that Wing uses Hermes Agent's official verified installer, and shows the fixed two-step handoff.
- **Copy setup command** writes exactly the validated public command after one tap.
- Missing build metadata disables copy and shows **This build cannot install the matching Wing Link release**.
- No widget or semantic label contains `API_SERVER_KEY`, `Bearer`, `wing://connect`, `code=`, provider credentials, or a private host path.
- At 200% text scale and 320dp width, all actions remain reachable without overflow; touch targets remain at least 48dp.

- [x] **Step 2: Run and verify RED**

```bash
flutter test test/features/local_setup/termux_hermes_setup_test.dart test/features/enrollment/hermes_enrollment_flow_test.dart
```

- [x] **Step 3: Build the static guided screen**

Use the existing `url_launcher` dependency for one official documentation URL and `Clipboard.setData` only inside the explicit copy handler. Required order:

1. **Install Termux** — opens `https://github.com/termux/termux-app#installation`.
2. **Copy setup command** — copies only validated release metadata and fixed shell syntax.
3. **Open Termux and run it** — explanatory text, not a native command action.
4. **Tap the local link shown by Termux** — returns through existing enrollment.
5. A persistent Tier 2 note: Android may stop background processes; rerun the same command to recover.

Do not add a MethodChannel, package query, `RUN_COMMAND` permission, background clipboard read, or another dependency.

- [x] **Step 4: Route by platform**

Keep one route:

```dart
if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
  return const TermuxHermesSetupScreen();
}
if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
  return const LocalHermesSetupScreen();
}
return const HermesEnrollmentScreen();
```

Update the route comment from Linux-only to platform-specific local setup.

- [x] **Step 5: Add honest post-pairing guidance**

For a confirmed loopback enrollment, show:

```text
Hermes Agent is connected on this phone.
To configure the existing default profile, run hermes setup in Termux.
To configure more in Wing, create a new profile with its provider and model,
approve the request in Termux, retry the unchanged request, then pair once more
to enroll that profile.
```

Reuse the existing **View profiles** and **Open chat** actions; do not add a new onboarding state machine.

- [x] **Step 6: Regenerate and verify**

```bash
flutter gen-l10n
dart format lib/features/local_setup lib/features/enrollment lib/router test/features/local_setup test/features/enrollment
flutter analyze
flutter test --concurrency=1 test/features/local_setup test/features/enrollment test/router
git diff --check
```

---

### Task 6: Complete approval-bound new-profile setup in Wing

**Files:**

- Modify: `lib/features/profiles/widgets/profile_editor_sheet.dart`
- Modify: `lib/features/profiles/screens/profiles_screen.dart`
- Modify: `test/features/profiles/profile_editor_sheet_test.dart`
- Modify: `test/features/profiles/profiles_screen_test.dart`
- Modify: `lib/l10n/app_en.arb`
- Regenerate: `lib/l10n/app_localizations.dart`
- Regenerate: `lib/l10n/app_localizations_en.dart`

**Interfaces:**

- Extends `ProfileCreateCallback` with optional `String? idempotencyKey` and passes it to existing `WingLinkClient.createProfile(..., idempotencyKey:)`.
- Keeps a pending `WingLinkApprovalRequired` only in `ProfileEditorSheet` memory.
- Provider credential remains in the obscured controller only while the approval is unexpired; it is never persisted, logged, copied, or rendered and still reaches Hermes only through the existing stdin-driven compatibility path.
- Existing profiles keep `canConfigure: false`.
- A newly created but not re-enrolled profile remains visibly unavailable for Chat.

- [x] **Step 1: Write the failing approval retry test**

The fake callback must throw `WingLinkApprovalRequired` on the first call and succeed only when called again with the exact returned key:

```dart
const approvalKey = 'profile-mutation-approved-key';
expect(calls.first.idempotencyKey, isNull);
expect(calls.last.idempotencyKey, approvalKey);
expect(calls.last.providerApiKey, 'write-only-fixture');
expect(find.text('write-only-fixture'), findsNothing);
```

Before retry, assert the sheet:

- shows local commands `wing-link approvals list` and `wing-link approvals approve`;
- offers **Retry approved setup** and **Cancel setup**;
- exposes no remote approval action;
- freezes name/clone/description/provider/model/credential fields so the payload digest cannot change;
- retains no secret after approval expiry, cancel, success, or widget disposal.

Also retain regression tests proving existing-profile edit never shows credential/provider mutation.

- [x] **Step 2: Run and verify RED**

```bash
flutter test test/features/profiles/profile_editor_sheet_test.dart test/features/profiles/profiles_screen_test.dart
```

Expected: first approval is currently flattened to a generic error, the credential is cleared, and Retry generates a new idempotency key.

- [x] **Step 3: Preserve one exact pending request in memory**

In `ProfileEditorSheet`, catch `WingLinkApprovalRequired` separately. Store only its bounded IDs/key/expiry in state, retain the already obscured credential controller, freeze all payload fields, and do not run the current unconditional credential clear. **Retry approved setup** calls the same callback with the same field values and `idempotencyKey`.

If the user cancels, edits by abandoning the sheet, or retries after `expiresAt`, clear the credential and pending approval state. On success, clear both before closing. Never persist this draft for process death; an interrupted secret mutation requires fresh user intent.

- [x] **Step 4: Pass the key through Profiles**

Extend the callback in `ProfilesScreen`:

```dart
await _wingLinkClient!.createProfile(
  name: name,
  cloneFrom: cloneFrom,
  description: description,
  provider: provider,
  model: model,
  providerApiKey: providerApiKey,
  idempotencyKey: idempotencyKey,
);
```

After successful create, reload inventory but keep Chat disabled until `enrolledGatewayIdForManagedProfile` resolves an independently saved `/p/<profile>` credential. Re-pairing and refresh must enable Chat for exactly that endpoint.

- [x] **Step 5: Verify approval, enrollment, and secret handling**

```bash
flutter gen-l10n
dart format lib/features/profiles test/features/profiles
flutter test test/features/profiles/profile_editor_sheet_test.dart test/features/profiles/profiles_screen_test.dart
rg -n 'write-only-fixture|API_SERVER_KEY|Bearer ' lib test/features/profiles
```

Fixture-only matches are acceptable; production/UI matches are not. Do not add a credential-returning profile API, automatic permission expansion, remote approval, or local shadow enrollment.

---

### Task 7: Complete deterministic and physical Termux qualification

**Files:**

- Modify: `docs/quality/evidence-matrix.md` only with sanitized receipts after real execution.
- Modify: `docs/runbooks/android-termux-local-agent.md` only when runtime evidence contradicts the plan.

**Interfaces:**

- Produces a support claim no stronger than the evidence: Android/Termux Tier 2, ARM64, best-effort background.

- [x] **Step 1: Run deterministic repository checks**

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --concurrency=1
(cd wing_link && go test ./... -count=1)
(cd wing_link && GOOS=android GOARCH=arm64 CGO_ENABLED=0 go build -trimpath -buildmode=pie -o /tmp/wing-link-android .)
flutter build apk --release
flutter build web --release -t lib/main_e2e.dart
npm run web:e2e
npm audit
git diff --check
```

- [ ] **Step 2: Publish an explicitly unqualified candidate**

Run the release workflow with an alpha tag. Confirm the metadata extracted from the exact signed APK and AAB matches the published `wing-link-android-arm64` size/SHA-256 and immutable `install-wing-link.sh` source revision/digest. Release notes and in-app copy must call this a Termux qualification candidate; publication is required so the copied immutable release URL exists, but publication itself is not runtime evidence.

- [ ] **Step 3: Qualify on a physical ARM64 Android device**

Use a clean, official Termux install and the exact signed Wing APK. Record only device model, Android version, Termux version/source, Wing tag, Wing Link tag, Hermes version, and pass/fail outcomes.

Required flow:

1. Wing → local setup screen → copy command.
2. Termux → run command with no manual edits.
3. Verify Agent `127.0.0.1:8642` and Wing Link `127.0.0.1:8654` only; no non-loopback listener.
4. Tap `/open` → Wing review → confirm → credentials survive cold Wing restart.
5. Configure default with `hermes setup`; verify Wing chat.
6. Fresh rerun adopts the existing runtime/state and does not duplicate processes or rotate Wing Link identity.
7. App-first path: create a configured new profile, approve it in Termux, retry with the same idempotency key, pair again, and verify the exact `/p/<profile>` Chat endpoint.
8. Kill Termux/background processes; confirm Wing reports disconnection without replaying mutations; rerun command and reconcile authoritative server state.
9. Confirm provider credential, Agent API key, Wing Link token, pairing code, private paths, and transcript text are absent from `adb logcat`, Termux logs, Wing diagnostics, screenshots, and shell history. The public bootstrap command may remain in shell history.
10. Verify 200% text, TalkBack order, portrait/landscape, back navigation, and copy/open actions.

- [ ] **Step 4: Promote the claim only after evidence**

Commit the sanitized physical receipt and final Tier 2 wording after the candidate passes, then publish a follow-up alpha containing that evidence-backed wording. A failed candidate keeps local Termux hosting unqualified and must not be described as shipped support.

Record limitations, not upgraded claims:

Explicitly record:

- no Android managed service or boot persistence;
- no `RUN_COMMAND` integration;
- no existing-profile provider mutation in Wing;
- no automatic local approval;
- no automatic enrollment of a newly created profile;
- no support claim for voice extra, Docker, browser bootstrap, WhatsApp bootstrap, x86 Android, or non-Termux Android Python.

---

## Deferred Follow-ups

Do not include these in the initial implementation:

1. **Termux `RUN_COMMAND` automation** — reconsider only if repeated physical evidence shows the explicit bootstrap is the dominant blocker and a separate security review accepts the broad Termux privilege. Even then, expose fixed operations only; never a Dart-selected command/path/argument surface.
2. **Automatic new-profile enrollment** — wait for Hermes Agent to advertise a scoped profile enrollment/credential operation. Remove the second-pair requirement through Agent authority, not a Wing-owned credential shortcut.
3. **Boot persistence** — qualify only with actual Android/Termux lifecycle evidence and an explicit user-installed mechanism such as Termux:Boot. Do not silently install or configure it.
4. **Community APT Hermes package** — keep as an explicit alternative with its contributor-operated trust warning and documented signing fingerprint. Do not make it Wing's default or imply NousResearch/Wing signs it.

## Self-Review

- **Spec coverage:** The plan starts in Wing, uses Termux for the unavoidable sandboxed install, returns to Wing through existing secure enrollment, and identifies exactly which setup can and cannot move into Wing.
- **Authority:** Agent owns domain state; Wing Link remains host management and the existing bounded new-profile adapter.
- **Security:** No bearer/provider secret/pairing code enters the copied command, argv, clipboard, or logs. Only the public bootstrap command is copied. Both services bind loopback and remain authenticated.
- **YAGNI:** No `RUN_COMMAND`, new Android permission, native command channel, package-detection bridge, cloud relay, new dependency, or second setup state machine.
- **Type/flow consistency:** `--same-device` produces the existing `/open` handoff; enrollment stores the existing Agent/Wing Link bundle; new-profile Chat remains unavailable until a second authoritative pairing provides its own credential.
- **Evidence:** Cross-compilation proves only buildability. A Tier 2 support statement requires the physical ARM64 Termux matrix in Task 7.
