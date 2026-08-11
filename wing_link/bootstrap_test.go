package main

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"
)

func TestBootstrapRequestValidatesInitialProfileAndProvider(t *testing.T) {
	valid := BootstrapRequest{
		Profile: &BootstrapProfile{Name: "work", CloneFrom: "default"},
		Provider: &BootstrapProvider{
			ID: "acme", BaseURL: "https://api.example.test/v1", Model: "acme-v1",
		},
	}
	if err := valid.Validate(); err != nil {
		t.Fatalf("valid request rejected: %v", err)
	}
	for _, request := range []BootstrapRequest{
		{Profile: &BootstrapProfile{Name: "../escape"}},
		{Provider: &BootstrapProvider{ID: "acme", BaseURL: "file:///tmp/api", Model: "v1"}},
		{Provider: &BootstrapProvider{ID: "acme", BaseURL: "https://api.example.test/v1"}},
	} {
		if err := request.Validate(); err == nil {
			t.Fatalf("invalid request accepted: %#v", request)
		}
	}
}

func TestDownloadVerifiedArtifactRejectsTamperingAndRemovesPartialFile(t *testing.T) {
	payload := []byte("verified installer")
	digest := sha256.Sum256(payload)
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		_, _ = writer.Write(payload)
	}))
	defer server.Close()

	dir := t.TempDir()
	artifact := Artifact{URL: server.URL, Size: int64(len(payload)), SHA256: hex.EncodeToString(digest[:])}
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

func TestParseBootstrapOptionsRequiresCompleteProviderTuple(t *testing.T) {
	options, err := parseBootstrapOptions([]string{
		"--profile", "work", "--clone-from", "default",
		"--provider", "acme", "--provider-url", "https://api.example.test/v1", "--model", "acme-v1",
	})
	if err != nil {
		t.Fatal(err)
	}
	if options.Request.Profile == nil || options.Request.Profile.Name != "work" || options.Request.Provider == nil || options.Request.Provider.ID != "acme" {
		t.Fatalf("options = %#v", options)
	}
	if _, err := parseBootstrapOptions([]string{"--provider", "acme"}); err == nil {
		t.Fatal("partial provider accepted")
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
		RunHermes:     func(context.Context, ...string) error { return nil },
		ReadHermes:    func(context.Context, ...string) ([]byte, error) { return []byte(`{}`), nil },
		ProfileExists: func(context.Context, string) bool { return false },
	}
	server := httptest.NewServer(newWingLinkServerWithBootstrap(
		&profileBackend{home: t.TempDir()}, store, nil, manager,
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

func TestBootstrapConfiguresProfileBeforeProviderWithFixedHermesArguments(t *testing.T) {
	var commands [][]string
	profiles := map[string]bool{"default": true}
	apiKeyEnsured := false
	gatewayStarted := false
	manager := &BootstrapManager{
		EnsureHermes: func(context.Context, func(OperationEvent)) (HermesInspection, error) {
			return HermesInspection{Executable: "/safe/hermes", Adopted: true}, nil
		},
		EnsureAPIKey: func(context.Context) error {
			apiKeyEnsured = true
			return nil
		},
		StartGateway: func(context.Context) error {
			if !apiKeyEnsured {
				return errors.New("gateway started before API authentication")
			}
			gatewayStarted = true
			return nil
		},
		RunHermes: func(_ context.Context, args ...string) error {
			commands = append(commands, append([]string(nil), args...))
			if len(args) >= 3 && reflect.DeepEqual(args[:2], []string{"profile", "create"}) {
				profiles[args[2]] = true
			}
			return nil
		},
		ReadHermes: func(_ context.Context, args ...string) ([]byte, error) {
			commands = append(commands, append([]string(nil), args...))
			if reflect.DeepEqual(args, []string{"--profile", "work", "config", "get", "providers", "--json"}) {
				if len(commands) < 6 {
					return []byte(`{}`), nil
				}
				return []byte(`{"acme":{"name":"acme","base_url":"https://api.example.test/v1","model":"acme-v1"}}`), nil
			}
			return nil, errors.New("unexpected read")
		},
		ProfileExists: func(_ context.Context, id string) bool { return profiles[id] },
	}
	result, err := manager.Bootstrap(context.Background(), BootstrapRequest{
		Profile:  &BootstrapProfile{Name: "work", CloneFrom: "default"},
		Provider: &BootstrapProvider{ID: "acme", BaseURL: "https://api.example.test/v1", Model: "acme-v1"},
	}, nil)
	if err != nil {
		t.Fatal(err)
	}
	if result.Profile != "work" || result.Provider != "acme" || !result.HermesAdopted || !result.GatewayStarted || !gatewayStarted {
		t.Fatalf("result = %#v", result)
	}
	if len(commands) == 0 || !reflect.DeepEqual(commands[0], []string{"profile", "create", "work", "--no-alias", "--clone-from", "default"}) {
		t.Fatalf("profile was not configured first: %#v", commands)
	}
}
