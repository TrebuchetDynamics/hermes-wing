package app

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/release"
)

func TestProductionBootstrapRejectsSymlinkedHermesEnvAncestor(t *testing.T) {
	home := t.TempDir()
	outside := t.TempDir()
	linked := filepath.Join(home, "linked")
	if err := os.Symlink(outside, linked); err != nil {
		t.Skipf("symlink unavailable: %v", err)
	}
	hermes := filepath.Join(t.TempDir(), "hermes")
	script := "#!/bin/sh\nprintf '%s\\n' \"$FAKE_ENV_PATH\"\n"
	if err := os.WriteFile(hermes, []byte(script), 0o700); err != nil {
		t.Fatal(err)
	}
	t.Setenv("FAKE_ENV_PATH", filepath.Join(linked, ".env"))
	manager := newProductionBootstrapManager(home, hermes)
	if err := manager.EnsureAPIKey(context.Background()); err == nil {
		t.Fatal("symlinked Hermes env ancestor was accepted")
	}
	if _, err := os.Stat(filepath.Join(outside, ".env")); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("credential file escaped Hermes home: %v", err)
	}
}

func TestBootstrapRequestValidatesEmptySupervisorRequest(t *testing.T) {
	if err := (BootstrapRequest{}).Validate(); err != nil {
		t.Fatalf("empty supervisor request rejected: %v", err)
	}
}

func TestDownloadVerifiedArtifactRejectsTamperingAndRemovesPartialFile(t *testing.T) {
	payload := []byte("verified installer")
	digest := sha256.Sum256(payload)
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		_, _ = io.Copy(writer, bytes.NewReader(payload))
	}))
	defer server.Close()

	dir := t.TempDir()
	artifact := release.Artifact{URL: server.URL, Size: int64(len(payload)), SHA256: hex.EncodeToString(digest[:])}
	path, err := downloadVerifiedArtifact(context.Background(), server.Client(), artifact, dir, []string{server.Listener.Addr().String()})
	if err != nil {
		t.Fatal(err)
	}
	info, err := os.Stat(path)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm() != 0o600 {
		t.Fatalf("mode = %o", info.Mode().Perm())
	}
	_ = os.Remove(path)

	artifact.SHA256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	if _, err := downloadVerifiedArtifact(context.Background(), server.Client(), artifact, dir, []string{server.Listener.Addr().String()}); !errors.Is(err, ErrArtifactVerification) {
		t.Fatalf("tamper error = %v", err)
	}
	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) != 0 {
		t.Fatalf("partial artifacts retained: %#v", entries)
	}
}

func TestHermesInstallerAdoptsHealthyExistingRuntimeWithoutDownload(t *testing.T) {
	var commands []CommandSpec
	installer := &HermesInstaller{
		Home:    t.TempDir(),
		Resolve: func() (string, error) { return "/safe/hermes", nil },
		Run: func(_ context.Context, spec CommandSpec, _ func(string)) ProcessResult {
			commands = append(commands, spec)
			return ProcessResult{}
		},
		Download: func(context.Context) (string, error) {
			t.Fatal("adoption downloaded an installer")
			return "", nil
		},
	}
	inspection, err := installer.Ensure(context.Background(), nil)
	if err != nil {
		t.Fatal(err)
	}
	if !inspection.Adopted || inspection.Executable != "/safe/hermes" {
		t.Fatalf("inspection = %#v", inspection)
	}
	if len(commands) != 1 || !reflect.DeepEqual(commands[0].Args, []string{"--version"}) {
		t.Fatalf("commands = %#v", commands)
	}
}

func TestHermesInstallerUsesVerifiedPinnedInstallerAndConfirmsHermes(t *testing.T) {
	home := t.TempDir()
	installerPath := filepath.Join(t.TempDir(), "install.sh")
	if err := os.WriteFile(installerPath, []byte("fixture"), 0o600); err != nil {
		t.Fatal(err)
	}
	resolveCalls := 0
	var commands []CommandSpec
	installer := &HermesInstaller{
		Home:   home,
		Commit: "0123456789abcdef0123456789abcdef01234567",
		Shell:  "/bin/bash",
		Resolve: func() (string, error) {
			resolveCalls++
			if resolveCalls == 1 {
				return "", os.ErrNotExist
			}
			return "/installed/hermes", nil
		},
		Download: func(context.Context) (string, error) { return installerPath, nil },
		Run: func(_ context.Context, spec CommandSpec, _ func(string)) ProcessResult {
			commands = append(commands, spec)
			return ProcessResult{}
		},
	}
	inspection, err := installer.Ensure(context.Background(), nil)
	if err != nil {
		t.Fatal(err)
	}
	if inspection.Adopted || inspection.Executable != "/installed/hermes" {
		t.Fatalf("inspection = %#v", inspection)
	}
	if len(commands) != 2 {
		t.Fatalf("commands = %#v", commands)
	}
	wantInstall := []string{installerPath, "--commit", installer.Commit, "--skip-setup", "--non-interactive", "--hermes-home", home}
	if commands[0].Path != "/bin/bash" || !reflect.DeepEqual(commands[0].Args, wantInstall) {
		t.Fatalf("install command = %#v", commands[0])
	}
	if commands[1].Path != "/installed/hermes" || !reflect.DeepEqual(commands[1].Args, []string{"--version"}) {
		t.Fatalf("verification command = %#v", commands[1])
	}
}

func TestHermesInstallerDoesNotPublishRawInstallerOutput(t *testing.T) {
	installerPath := filepath.Join(t.TempDir(), "install.sh")
	if err := os.WriteFile(installerPath, []byte("fixture"), 0o600); err != nil {
		t.Fatal(err)
	}
	resolveCalls := 0
	installer := &HermesInstaller{
		Home: t.TempDir(),
		Resolve: func() (string, error) {
			resolveCalls++
			if resolveCalls == 1 {
				return "", os.ErrNotExist
			}
			return "/installed/hermes", nil
		},
		Download: func(context.Context) (string, error) { return installerPath, nil },
		Run: func(_ context.Context, _ CommandSpec, emit func(string)) ProcessResult {
			if emit != nil {
				emit("installed under /home/private-user/.hermes")
			}
			return ProcessResult{}
		},
	}
	var events []OperationEvent
	if _, err := installer.Ensure(context.Background(), func(event OperationEvent) {
		events = append(events, event)
	}); err != nil {
		t.Fatal(err)
	}
	for _, event := range events {
		if strings.Contains(event.Message, "/home/private-user") {
			t.Fatalf("installer path leaked in operation event: %#v", event)
		}
	}
}

func TestParseBootstrapOptionsRejectsRuntimeDomainFlags(t *testing.T) {
	options, err := parseBootstrapOptions([]string{"--json"})
	if err != nil || !options.JSON {
		t.Fatalf("json options = %#v, %v", options, err)
	}
	for _, args := range [][]string{
		{"--profile", "work"},
		{"--provider", "acme"},
		{"--model", "model"},
	} {
		if _, err := parseBootstrapOptions(args); err == nil {
			t.Fatalf("runtime domain option accepted: %#v", args)
		}
	}
}

func TestAuthenticatedBootstrapRouteRunsSetupAndReportsOperation(t *testing.T) {
	store := newStateStore(filepath.Join(t.TempDir(), "state.json"))
	enrollment, err := store.CreateEnrollment()
	if err != nil {
		t.Fatal(err)
	}
	token, err := store.ExchangeEnrollment(enrollment.Code)
	if err != nil {
		t.Fatal(err)
	}
	manager := &BootstrapManager{
		EnsureHermes: func(context.Context, func(OperationEvent)) (HermesInspection, error) {
			return HermesInspection{Executable: "/safe/hermes", Adopted: true}, nil
		},
	}
	server := httptest.NewServer(newWingLinkServerWithBootstrap(
		&profileBackend{}, store, manager,
	))
	defer server.Close()

	body := strings.NewReader(`{"profile":{"name":"work"}}`)
	unauthorized, err := http.Post(server.URL+"/v1/setup", "application/json", body)
	if err != nil {
		t.Fatal(err)
	}
	if unauthorized.StatusCode != http.StatusUnauthorized {
		t.Fatalf("unauthorized status = %d", unauthorized.StatusCode)
	}
	_ = unauthorized.Body.Close()

	postSetup := func() struct {
		OperationID string `json:"operation_id"`
		ApprovalID  string `json:"approval_id"`
	} {
		request, err := http.NewRequest(http.MethodPost, server.URL+"/v1/setup", strings.NewReader(`{}`))
		if err != nil {
			t.Fatal(err)
		}
		request.Header.Set("Authorization", "Bearer "+token)
		request.Header.Set("Content-Type", "application/json")
		request.Header.Set("Idempotency-Key", "setup-approved-1")
		response, err := http.DefaultClient.Do(request)
		if err != nil {
			t.Fatal(err)
		}
		defer func() { _ = response.Body.Close() }()
		if response.StatusCode != http.StatusAccepted {
			t.Fatalf("setup status = %d", response.StatusCode)
		}
		var accepted struct {
			OperationID string `json:"operation_id"`
			ApprovalID  string `json:"approval_id"`
		}
		if err := json.NewDecoder(response.Body).Decode(&accepted); err != nil {
			t.Fatal(err)
		}
		return accepted
	}
	pending := postSetup()
	if pending.OperationID == "" || pending.ApprovalID == "" {
		t.Fatalf("missing pending approval metadata: %#v", pending)
	}
	approvals, err := openApprovalStore(store.Path())
	if err != nil {
		t.Fatal(err)
	}
	if _, err := approvals.Decide(pending.ApprovalID, true); err != nil {
		t.Fatal(err)
	}
	accepted := postSetup()
	if accepted.OperationID != pending.OperationID || accepted.ApprovalID != "" {
		t.Fatalf("approved operation = %#v; pending=%#v", accepted, pending)
	}

	var terminal OperationEvent
	for attempt := 0; attempt < 100; attempt++ {
		operation, err := http.NewRequest(http.MethodGet, server.URL+"/v1/operations/"+accepted.OperationID, nil)
		if err != nil {
			t.Fatal(err)
		}
		operation.Header.Set("Authorization", "Bearer "+token)
		result, err := http.DefaultClient.Do(operation)
		if err != nil {
			t.Fatal(err)
		}
		if result.StatusCode != http.StatusOK {
			t.Fatalf("operation status = %d", result.StatusCode)
		}
		if err := json.NewDecoder(result.Body).Decode(&terminal); err != nil {
			t.Fatal(err)
		}
		_ = result.Body.Close()
		if terminal.Terminal {
			break
		}
		time.Sleep(time.Millisecond)
	}
	if !terminal.Terminal || terminal.ErrorCode != "" {
		t.Fatalf("terminal = %#v", terminal)
	}
}

func TestBootstrapRouteReplaysIdempotencyKeyWithoutDuplicateWork(t *testing.T) {
	directory := t.TempDir()
	store := newStateStore(filepath.Join(directory, "state.json"))
	enrollment, err := store.CreateEnrollment()
	if err != nil {
		t.Fatal(err)
	}
	token, err := store.ExchangeEnrollment(enrollment.Code)
	if err != nil {
		t.Fatal(err)
	}
	operations, err := NewDurableOperationManager(filepath.Join(directory, "operations.json"))
	if err != nil {
		t.Fatal(err)
	}
	calls := 0
	bootstrap := &BootstrapManager{
		EnsureHermes: func(context.Context, func(OperationEvent)) (HermesInspection, error) {
			calls++
			return HermesInspection{Executable: "/safe/hermes", Adopted: true}, nil
		},
	}
	server := httptest.NewServer(newWingLinkServerWithOperations(
		&profileBackend{}, store, bootstrap, operations,
	))
	defer server.Close()

	type setupResponse struct {
		OperationID string         `json:"operation_id"`
		ApprovalID  string         `json:"approval_id"`
		Operation   OperationEvent `json:"operation"`
		Replayed    bool           `json:"replayed"`
	}
	post := func(key string) setupResponse {
		request, err := http.NewRequest(http.MethodPost, server.URL+"/v1/setup", strings.NewReader(`{}`))
		if err != nil {
			t.Fatal(err)
		}
		request.Header.Set("Authorization", "Bearer "+token)
		request.Header.Set("Content-Type", "application/json")
		request.Header.Set("Idempotency-Key", key)
		response, err := http.DefaultClient.Do(request)
		if err != nil {
			t.Fatal(err)
		}
		defer func() { _ = response.Body.Close() }()
		if response.StatusCode != http.StatusAccepted {
			t.Fatalf("setup status = %d", response.StatusCode)
		}
		var body setupResponse
		if err := json.NewDecoder(response.Body).Decode(&body); err != nil {
			t.Fatal(err)
		}
		return body
	}
	pending := post("setup-retry-1")
	approvalStore, err := openApprovalStore(store.Path())
	if err != nil {
		t.Fatal(err)
	}
	approvals, err := approvalStore.List()
	if err != nil || len(approvals) != 1 || approvals[0].Request.IdempotencyKey != "setup-retry-1" {
		t.Fatalf("approval idempotency binding = %#v, %v", approvals, err)
	}
	if _, err := approvalStore.Decide(pending.ApprovalID, true); err != nil {
		t.Fatal(err)
	}
	changedKey := post("setup-retry-2")
	if changedKey.ApprovalID == "" || changedKey.ApprovalID == pending.ApprovalID || calls != 0 {
		t.Fatalf("changed key reused approval: %#v calls=%d", changedKey, calls)
	}
	first := post("setup-retry-1")
	for attempt := 0; attempt < 100; attempt++ {
		if event, ok := operations.Snapshot(first.OperationID); ok && event.Terminal {
			break
		}
		time.Sleep(time.Millisecond)
	}
	second := post("setup-retry-1")
	if first.OperationID == "" || second.OperationID != first.OperationID ||
		!second.Replayed || second.Operation.Phase != "committed" || !second.Operation.Terminal || calls != 1 {
		t.Fatalf("first=%#v second=%#v calls=%d", first, second, calls)
	}
}

func TestAuthenticatedBootstrapRouteRejectsRuntimeDomainFields(t *testing.T) {
	store := newStateStore(filepath.Join(t.TempDir(), "state.json"))
	enrollment, err := store.CreateEnrollment()
	if err != nil {
		t.Fatal(err)
	}
	token, err := store.ExchangeEnrollment(enrollment.Code)
	if err != nil {
		t.Fatal(err)
	}
	manager := &BootstrapManager{
		EnsureHermes: func(context.Context, func(OperationEvent)) (HermesInspection, error) {
			t.Fatal("invalid request reached bootstrap")
			return HermesInspection{}, nil
		},
	}
	server := httptest.NewServer(newWingLinkServerWithBootstrap(nil, store, manager))
	defer server.Close()

	request, err := http.NewRequest(
		http.MethodPost,
		server.URL+"/v1/setup",
		strings.NewReader(`{"profile":{"name":"work"}}`),
	)
	if err != nil {
		t.Fatal(err)
	}
	request.Header.Set("Authorization", "Bearer "+token)
	request.Header.Set("Content-Type", "application/json")
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = response.Body.Close() }()
	if response.StatusCode != http.StatusBadRequest {
		t.Fatalf("status = %d; want %d", response.StatusCode, http.StatusBadRequest)
	}
}

func TestInstallerShellUsesTermuxPrefix(t *testing.T) {
	t.Setenv("PREFIX", termuxPrefix)
	if got := resolveInstallerShell("android"); got != termuxPrefix+"/bin/bash" {
		t.Fatalf("got %q", got)
	}
	if got := resolveInstallerShell("linux"); got != "/bin/bash" {
		t.Fatalf("linux shell = %q", got)
	}
}

func TestTermuxGatewaySpecUsesFixedPaths(t *testing.T) {
	t.Setenv("PREFIX", termuxPrefix)
	t.Setenv("HOME", termuxHome)
	spec, err := termuxHermesGatewaySpec(
		termuxPrefix+"/bin/hermes",
		termuxHome+"/.hermes",
	)
	if err != nil {
		t.Fatal(err)
	}
	if spec.Path != termuxPrefix+"/bin/hermes" ||
		!reflect.DeepEqual(spec.Args, []string{"gateway"}) ||
		spec.Home != "/data/data/com.termux/files/home/.hermes" ||
		spec.LogPath != "/data/data/com.termux/files/home/.hermes/logs/gateway.log" {
		t.Fatalf("spec = %#v", spec)
	}
}

func TestAndroidHermesExecutableRejectsAlternatePaths(t *testing.T) {
	t.Setenv("PREFIX", termuxPrefix)
	t.Setenv("HOME", termuxHome)
	fakeDir := t.TempDir()
	fakeHermes := filepath.Join(fakeDir, "hermes")
	if err := os.WriteFile(fakeHermes, []byte("#!/bin/sh\n"), 0o700); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PATH", fakeDir)

	canonical := filepath.Join(termuxPrefix, "bin", "hermes")
	home := filepath.Join(termuxHome, ".hermes")
	candidates, err := hermesExecutableCandidates("android", home, "")
	if err != nil || !reflect.DeepEqual(candidates, []string{canonical}) {
		t.Fatalf("candidates = %q, err = %v", candidates, err)
	}
	if _, err := hermesExecutableCandidates("android", home, fakeHermes); err == nil {
		t.Fatal("alternate absolute Hermes hint was accepted")
	}
	if _, err := resolveHermesExecutableForPlatform("android", home, ""); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("PATH Hermes should be ignored; err = %v", err)
	}

	t.Setenv("PREFIX", fakeDir)
	if _, err := hermesExecutableCandidates("android", home, ""); err == nil {
		t.Fatal("noncanonical Termux prefix was accepted")
	}
	t.Setenv("PREFIX", termuxPrefix)
	t.Setenv("HOME", fakeDir)
	if _, err := hermesExecutableCandidates("android", home, ""); err == nil {
		t.Fatal("noncanonical Termux home was accepted")
	}
	if err := validateTermuxHermesGatewayShape(canonical, filepath.Join(fakeDir, ".hermes")); err == nil {
		t.Fatal("noncanonical Hermes home was accepted")
	}
}

func TestDetachedHermesGatewayPreparationIsOwnerOnly(t *testing.T) {
	home := t.TempDir()
	spec := detachedHermesGatewaySpec{
		Path: "/fixed/hermes", Args: []string{"gateway"}, Home: home,
		LogPath: filepath.Join(home, "logs", "gateway.log"),
	}
	logFile, err := prepareDetachedHermesGateway(spec)
	if err != nil {
		t.Fatal(err)
	}
	if err := logFile.Close(); err != nil {
		t.Fatal(err)
	}
	logDirInfo, err := os.Stat(filepath.Dir(spec.LogPath))
	if err != nil {
		t.Fatal(err)
	}
	logInfo, err := os.Stat(spec.LogPath)
	if err != nil {
		t.Fatal(err)
	}
	if got := logDirInfo.Mode().Perm(); got != 0o700 {
		t.Fatalf("log directory mode = %o", got)
	}
	if got := logInfo.Mode().Perm(); got != 0o600 {
		t.Fatalf("log file mode = %o", got)
	}

	environment := environmentWithHermesHome(
		[]string{"PATH=/bin", "HERMES_HOME=/stale", "NOT_HERMES_HOME=kept"},
		home,
	)
	wantEnvironment := []string{"PATH=/bin", "NOT_HERMES_HOME=kept", "HERMES_HOME=" + home}
	if !reflect.DeepEqual(environment, wantEnvironment) {
		t.Fatalf("environment = %q, want %q", environment, wantEnvironment)
	}
}

func TestDetachedHermesGatewayPreparationRejectsSymlinks(t *testing.T) {
	t.Run("directory", func(t *testing.T) {
		home := t.TempDir()
		target := t.TempDir()
		if err := os.Symlink(target, filepath.Join(home, "logs")); err != nil {
			t.Fatal(err)
		}
		spec := detachedHermesGatewaySpec{LogPath: filepath.Join(home, "logs", "gateway.log")}
		if _, err := prepareDetachedHermesGateway(spec); err == nil {
			t.Fatal("symlinked log directory was accepted")
		}
	})
	t.Run("file", func(t *testing.T) {
		home := t.TempDir()
		logDir := filepath.Join(home, "logs")
		if err := os.Mkdir(logDir, 0o700); err != nil {
			t.Fatal(err)
		}
		target := filepath.Join(t.TempDir(), "outside.log")
		if err := os.WriteFile(target, nil, 0o600); err != nil {
			t.Fatal(err)
		}
		if err := os.Symlink(target, filepath.Join(logDir, "gateway.log")); err != nil {
			t.Fatal(err)
		}
		spec := detachedHermesGatewaySpec{LogPath: filepath.Join(logDir, "gateway.log")}
		if _, err := prepareDetachedHermesGateway(spec); err == nil {
			t.Fatal("symlinked log file was accepted")
		}
	})
}

func TestPinnedHermesInstallerIsOfficialAndImmutable(t *testing.T) {
	if !strings.Contains(pinnedHermesPOSIXURL, "raw.githubusercontent.com/NousResearch/hermes-agent/"+pinnedHermesCommit+"/scripts/install.sh") {
		t.Fatalf("installer URL is not pinned to the official source: %q", pinnedHermesPOSIXURL)
	}
	for _, forbidden := range []string{"hermes-agent.nousresearch.com/install.sh", "adybag14-cyber", "setup_apt_repo"} {
		if strings.Contains(pinnedHermesPOSIXURL, forbidden) {
			t.Fatalf("installer URL contains %q", forbidden)
		}
	}
}

func TestHermesGatewayCommandsInstallWithoutRestartingExistingProfiles(t *testing.T) {
	commands := hermesGatewayCommands()
	want := [][]string{{"gateway", "install", "--no-start-now"}, {"gateway", "start"}}
	if !reflect.DeepEqual(commands, want) {
		t.Fatalf("commands = %#v, want %#v", commands, want)
	}
}

func TestHermesAPIEnvironmentOverridesStaleRemoteEndpoint(t *testing.T) {
	path := filepath.Join(t.TempDir(), ".env")
	contents := "API_SERVER_KEY=secret\nAPI_SERVER_HOST=100.64.0.1\nAPI_SERVER_PORT=9000\nAPI_SERVER_HOST=stale\n"
	if err := os.WriteFile(path, []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := ensureHermesAPIEnvironment(path, 9864); err != nil {
		t.Fatal(err)
	}
	updated, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	text := string(updated)
	if strings.Count(text, "API_SERVER_HOST=") != 1 || !strings.Contains(text, "API_SERVER_HOST=127.0.0.1\n") ||
		strings.Count(text, "API_SERVER_PORT=") != 1 || !strings.Contains(text, "API_SERVER_PORT=9864\n") ||
		!strings.Contains(text, "API_SERVER_KEY=secret\n") {
		t.Fatalf("environment = %q", text)
	}
}

func TestHermesAPIEnvironmentCanBindDetectedTailscaleHost(t *testing.T) {
	path := filepath.Join(t.TempDir(), ".env")
	if err := os.WriteFile(path, []byte("API_SERVER_KEY=secret\nAPI_SERVER_HOST=127.0.0.1\nAPI_SERVER_PORT=8642\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := ensureHermesAPIEnvironmentHost(path, "100.90.80.70", 8642); err != nil {
		t.Fatal(err)
	}
	updated, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	text := string(updated)
	if strings.Count(text, "API_SERVER_HOST=") != 1 ||
		!strings.Contains(text, "API_SERVER_HOST=100.90.80.70\n") ||
		!strings.Contains(text, "API_SERVER_KEY=secret\n") {
		t.Fatalf("environment = %q", text)
	}
}

func TestHermesProfileMultiplexDisablesSecondaryAPIServers(t *testing.T) {
	rows := []profileRow{{ID: "default"}, {ID: "link", Current: true}, {ID: "sidon"}}
	want := [][]string{
		{"--profile", "default", "config", "set", "--force", "platforms.api_server.enabled", "false"},
		{"--profile", "sidon", "config", "set", "--force", "platforms.api_server.enabled", "false"},
	}
	commands, err := hermesSecondaryAPICommands(rows)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(commands, want) {
		t.Fatalf("commands = %#v, want %#v", commands, want)
	}
	if _, err := hermesSecondaryAPICommands([]profileRow{{ID: "default"}}); err == nil {
		t.Fatal("profile inventory without a current profile was accepted")
	}
}

func TestHermesAPIEndpointUsesFixedLocalConfigurationAndHealth(t *testing.T) {
	t.Setenv("WING_HERMES_PORT", "9864")
	port, err := resolveHermesAPIPort()
	if err != nil || port != 9864 {
		t.Fatalf("port = %d, %v", port, err)
	}
	want := [][]string{
		{"config", "set", "--force", "gateway.multiplex_profiles", "true"},
		{"config", "set", "--force", "platforms.api_server.enabled", "true"},
		{"config", "set", "--force", "platforms.api_server.extra.host", "127.0.0.1"},
		{"config", "set", "--force", "platforms.api_server.extra.port", "9864"},
	}
	if got := hermesAPIEndpointCommands(port); !reflect.DeepEqual(got, want) {
		t.Fatalf("commands = %#v", got)
	}

	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if request.URL.Path != "/v1/capabilities" {
			t.Fatalf("capabilities path = %q", request.URL.Path)
		}
		if request.Header.Get("Authorization") != "Bearer secret" {
			writer.WriteHeader(http.StatusUnauthorized)
			return
		}
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(`{"object":"hermes.api_server.capabilities","platform":"hermes-agent","endpoints":{"health":{}}}`))
	}))
	defer server.Close()
	healthPort := server.Listener.Addr().(*net.TCPAddr).Port
	if err := waitForHermesAPIHealth(context.Background(), healthPort, "secret"); err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()
	if err := waitForHermesAPIHealth(ctx, healthPort, "wrong"); err == nil {
		t.Fatal("different Hermes credential was accepted")
	}
}

func TestHermesAPIHealthRejectsUnrelatedHTTPService(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusNoContent)
	}))
	defer server.Close()
	port := server.Listener.Addr().(*net.TCPAddr).Port
	ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()
	if err := waitForHermesAPIHealth(ctx, port, "secret"); err == nil {
		t.Fatal("unrelated health service accepted as Hermes")
	}
}

func TestHermesAPIPortRejectsInvalidEnvironment(t *testing.T) {
	for _, value := range []string{"0", "65536", "not-a-port"} {
		t.Run(value, func(t *testing.T) {
			t.Setenv("WING_HERMES_PORT", value)
			if _, err := resolveHermesAPIPort(); err == nil {
				t.Fatal("invalid port accepted")
			}
		})
	}
}
