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
	store := &StateStore{path: filepath.Join(t.TempDir(), "state.json")}
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
		&profileBackend{}, store, nil, manager,
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

	request, err := http.NewRequest(http.MethodPost, server.URL+"/v1/setup", strings.NewReader(`{}`))
	if err != nil {
		t.Fatal(err)
	}
	request.Header.Set("Authorization", "Bearer "+token)
	request.Header.Set("Content-Type", "application/json")
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusAccepted {
		t.Fatalf("setup status = %d", response.StatusCode)
	}
	var accepted struct {
		OperationID string `json:"operation_id"`
	}
	if err := json.NewDecoder(response.Body).Decode(&accepted); err != nil {
		t.Fatal(err)
	}
	_ = response.Body.Close()
	if accepted.OperationID == "" {
		t.Fatal("missing operation id")
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

func TestAuthenticatedBootstrapRouteRejectsRuntimeDomainFields(t *testing.T) {
	store := &StateStore{path: filepath.Join(t.TempDir(), "state.json")}
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
	server := httptest.NewServer(newWingLinkServerWithBootstrap(nil, store, nil, manager))
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

func TestHermesGatewayCommandsRestartToApplyEndpointChanges(t *testing.T) {
	commands := hermesGatewayCommands()
	want := [][]string{{"gateway", "install"}, {"gateway", "restart"}}
	if !reflect.DeepEqual(commands, want) {
		t.Fatalf("commands = %#v, want %#v", commands, want)
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
		if request.URL.Path != "/health" {
			t.Fatalf("health path = %q", request.URL.Path)
		}
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(`{"status":"ok","platform":"hermes-agent","version":"0.20.0"}`))
	}))
	defer server.Close()
	healthPort := server.Listener.Addr().(*net.TCPAddr).Port
	if err := waitForHermesAPIHealth(context.Background(), healthPort); err != nil {
		t.Fatal(err)
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
	if err := waitForHermesAPIHealth(ctx, port); err == nil {
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
