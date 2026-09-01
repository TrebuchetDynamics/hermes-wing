package app

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/release"
)

const (
	pinnedHermesCommit              = "60dc87fd108b4da6d674dd8a260f0e77fef22e88"
	pinnedHermesPOSIXURL            = "https://raw.githubusercontent.com/NousResearch/hermes-agent/60dc87fd108b4da6d674dd8a260f0e77fef22e88/scripts/install.sh"
	pinnedHermesPOSIXSize     int64 = 134649
	pinnedHermesPOSIXSHA256         = "c5ba7e89627577fab914514736ecfb3359b66956ca00199bfef616ca35953cb9"
	pinnedHermesWindowsURL          = "https://raw.githubusercontent.com/NousResearch/hermes-agent/60dc87fd108b4da6d674dd8a260f0e77fef22e88/scripts/install.ps1"
	pinnedHermesWindowsSize   int64 = 179412
	pinnedHermesWindowsSHA256       = "5af3faec3d2387923fd09aab3fe25410932c3898c93a76012c3d960041eec425"
)

var (
	ErrArtifactVerification = errors.New("artifact verification failed")
	ErrHermesInstall        = errors.New("hermes installation failed")
	ErrBootstrapInvalid     = errors.New("bootstrap request is invalid")
)

type BootstrapRequest struct{}

func (BootstrapRequest) Validate() error { return nil }

type HermesInspection struct {
	Executable string `json:"-"`
	Version    string `json:"version,omitempty"`
	Adopted    bool   `json:"adopted"`
}

type BootstrapResult struct {
	HermesInstalled bool   `json:"hermes_installed"`
	HermesAdopted   bool   `json:"hermes_adopted"`
	HermesVersion   string `json:"hermes_version,omitempty"`
	GatewayStarted  bool   `json:"gateway_started"`
}

type HermesInstaller struct {
	Home     string
	Commit   string
	Shell    string
	Resolve  func() (string, error)
	Download func(context.Context) (string, error)
	Run      func(context.Context, CommandSpec, func(string)) ProcessResult
}

func (installer *HermesInstaller) Ensure(ctx context.Context, emit func(OperationEvent)) (HermesInspection, error) {
	if installer == nil || installer.Resolve == nil || installer.Run == nil || installer.Download == nil {
		return HermesInspection{}, ErrHermesInstall
	}
	if executable, err := installer.Resolve(); err == nil && installer.healthy(ctx, executable) {
		return HermesInspection{Executable: executable, Adopted: true}, nil
	}
	emitBootstrap(emit, "download", "Downloading verified Hermes installer", 15)
	path, err := installer.Download(ctx)
	if err != nil {
		return HermesInspection{}, fmt.Errorf("%w: %v", ErrHermesInstall, err)
	}
	defer func() { _ = os.Remove(path) }()
	emitBootstrap(emit, "install", "Installing Hermes Agent", 45)
	spec := installer.installCommand(path)
	if err := validateInstallerShell(runtime.GOOS, spec.Path); err != nil {
		return HermesInspection{}, fmt.Errorf("%w: %v", ErrHermesInstall, err)
	}
	if result := installer.Run(ctx, spec, nil); result.Err != nil {
		return HermesInspection{}, ErrHermesInstall
	}
	executable, err := installer.Resolve()
	if err != nil || !installer.healthy(ctx, executable) {
		return HermesInspection{}, ErrHermesInstall
	}
	emitBootstrap(emit, "verify", "Verified Hermes Agent", 70)
	return HermesInspection{Executable: executable}, nil
}

func (installer *HermesInstaller) healthy(ctx context.Context, executable string) bool {
	if strings.TrimSpace(executable) == "" {
		return false
	}
	result := installer.Run(ctx, CommandSpec{Path: executable, Args: []string{"--version"}, Env: []string{"HERMES_HOME=" + installer.Home}, Timeout: 30 * time.Second}, nil)
	return result.Err == nil
}

func (installer *HermesInstaller) installCommand(path string) CommandSpec {
	commit := installer.Commit
	if commit == "" {
		commit = pinnedHermesCommit
	}
	if runtime.GOOS == "windows" {
		shell := installer.Shell
		if shell == "" {
			shell = "powershell.exe"
		}
		return CommandSpec{Path: shell, Args: []string{"-NoProfile", "-ExecutionPolicy", "Bypass", "-File", path, "-Commit", commit, "-SkipSetup", "-NonInteractive", "-HermesHome", installer.Home}, Timeout: 20 * time.Minute}
	}
	shell := installer.Shell
	if shell == "" {
		shell = "/bin/bash"
	}
	return CommandSpec{Path: shell, Args: []string{path, "--commit", commit, "--skip-setup", "--non-interactive", "--hermes-home", installer.Home}, Timeout: 20 * time.Minute}
}

type BootstrapManager struct {
	EnsureHermes      func(context.Context, func(OperationEvent)) (HermesInspection, error)
	EnsureAPIKey      func(context.Context) error
	EnsureAPIEndpoint func(context.Context) error
	GatewayHealthy    func(context.Context) bool
	StartGateway      func(context.Context) error
	VerifyGateway     func(context.Context) error
	RunHermes         func(context.Context, ...string) error
	RunHermesSecret   func(context.Context, []byte, ...string) error
	ReadHermes        func(context.Context, ...string) ([]byte, error)
}

func (manager *BootstrapManager) Bootstrap(ctx context.Context, request BootstrapRequest, emit func(OperationEvent)) (BootstrapResult, error) {
	if err := request.Validate(); err != nil {
		return BootstrapResult{}, err
	}
	if manager == nil || manager.EnsureHermes == nil {
		return BootstrapResult{}, ErrHermesInstall
	}
	inspection, err := manager.EnsureHermes(ctx, emit)
	if err != nil {
		return BootstrapResult{}, err
	}
	result := BootstrapResult{HermesInstalled: true, HermesAdopted: inspection.Adopted, HermesVersion: inspection.Version}
	if manager.EnsureAPIKey != nil {
		emitBootstrap(emit, "authentication", "Securing Hermes API access", 92)
		if err := manager.EnsureAPIKey(ctx); err != nil {
			return BootstrapResult{}, fmt.Errorf("%w: API authentication", ErrHermesInstall)
		}
	}
	if manager.EnsureAPIEndpoint != nil {
		emitBootstrap(emit, "api_endpoint", "Configuring local Hermes API endpoint", 94)
		if err := manager.EnsureAPIEndpoint(ctx); err != nil {
			return BootstrapResult{}, fmt.Errorf("%w: API endpoint", ErrHermesInstall)
		}
	}
	gatewayReady := manager.GatewayHealthy != nil && manager.GatewayHealthy(ctx)
	if gatewayReady {
		emitBootstrap(emit, "gateway", "Hermes gateway already healthy", 96)
	} else if manager.StartGateway != nil {
		emitBootstrap(emit, "gateway", "Starting Hermes gateway if needed", 96)
		if err := manager.StartGateway(ctx); err != nil {
			return BootstrapResult{}, fmt.Errorf("%w: gateway", ErrHermesInstall)
		}
		gatewayReady = true
	}
	if manager.VerifyGateway != nil {
		emitBootstrap(emit, "health", "Verifying Hermes gateway health", 98)
		if err := manager.VerifyGateway(ctx); err != nil {
			return BootstrapResult{}, fmt.Errorf("%w: gateway health", ErrHermesInstall)
		}
	}
	result.GatewayStarted = gatewayReady
	emitBootstrap(emit, "complete", "Hermes gateway is running", 100)
	return result, nil
}

func newProductionBootstrapManager(home, hermesHint string) *BootstrapManager {
	resolver := func() (string, error) { return resolveHermesExecutable(home, hermesHint) }
	runner := func(ctx context.Context, spec CommandSpec, onLine func(string)) ProcessResult {
		return runProcess(ctx, spec, onLine)
	}
	artifact := pinnedHermesArtifact()
	installer := &HermesInstaller{
		Home: home, Commit: pinnedHermesCommit, Shell: resolveInstallerShell(runtime.GOOS),
		Resolve: resolver, Run: runner,
		Download: func(ctx context.Context) (string, error) {
			return downloadVerifiedArtifact(
				ctx, &http.Client{Timeout: 2 * time.Minute}, artifact, os.TempDir(),
				[]string{"raw.githubusercontent.com"},
			)
		},
	}
	runHermes := func(ctx context.Context, args ...string) error {
		executable, err := resolver()
		if err != nil {
			return err
		}
		result := runProcess(ctx, CommandSpec{Path: executable, Args: args, Env: []string{"HERMES_HOME=" + home}, Timeout: 90 * time.Second}, nil)
		return result.Err
	}
	runHermesSecret := func(ctx context.Context, input []byte, args ...string) error {
		defer func() {
			for index := range input {
				input[index] = 0
			}
		}()
		executable, err := resolver()
		if err != nil {
			return err
		}
		result := runProcess(ctx, CommandSpec{
			Path: executable, Args: args, Env: []string{"HERMES_HOME=" + home},
			Input: input, Timeout: 90 * time.Second,
		}, nil)
		return result.Err
	}
	readHermes := func(ctx context.Context, args ...string) ([]byte, error) {
		executable, err := resolver()
		if err != nil {
			return nil, err
		}
		output, result := runProcessCapture(ctx, CommandSpec{Path: executable, Args: args, Env: []string{"HERMES_HOME=" + home}, Timeout: 30 * time.Second}, 256*1024)
		return output, result.Err
	}
	verifyGateway := func(ctx context.Context) error {
		port, err := resolveHermesAPIPort()
		if err != nil {
			return err
		}
		output, err := readHermes(ctx, "config", "env-path")
		path := strings.TrimSpace(string(output))
		if err != nil || !filepath.IsAbs(path) || strings.ContainsAny(path, "\r\n") ||
			!pathWithin(home, path) || rejectSymlinkedAncestors(path) != nil {
			return ErrHermesInstall
		}
		token, err := readHermesTokenFile(path)
		if err != nil {
			return err
		}
		return waitForHermesAPIHealth(ctx, port, token)
	}
	return &BootstrapManager{
		EnsureHermes: installer.Ensure,
		EnsureAPIKey: func(ctx context.Context) error {
			output, err := readHermes(ctx, "config", "env-path")
			path := strings.TrimSpace(string(output))
			if err != nil || !filepath.IsAbs(path) || strings.ContainsAny(path, "\r\n") ||
				!pathWithin(home, path) || rejectSymlinkedAncestors(path) != nil {
				return ErrHermesInstall
			}
			_, err = ensureHermesTokenFile(path)
			return err
		},
		EnsureAPIEndpoint: func(ctx context.Context) error {
			port, err := resolveHermesAPIPort()
			if err != nil {
				return err
			}
			output, err := readHermes(ctx, "profile", "list")
			if err != nil {
				return err
			}
			rows, err := parseHermesProfileList(output)
			if err != nil {
				return err
			}
			secondaryCommands, err := hermesSecondaryAPICommands(rows)
			if err != nil {
				return err
			}
			for _, args := range append(hermesAPIEndpointCommands(port), secondaryCommands...) {
				if err := runHermes(ctx, args...); err != nil {
					return err
				}
			}
			output, err = readHermes(ctx, "config", "env-path")
			path := strings.TrimSpace(string(output))
			if err != nil || !filepath.IsAbs(path) || strings.ContainsAny(path, "\r\n") ||
				!pathWithin(home, path) || rejectSymlinkedAncestors(path) != nil {
				return ErrHermesInstall
			}
			return ensureHermesAPIEnvironment(path, port)
		},
		GatewayHealthy: func(ctx context.Context) bool {
			preflightCtx, cancel := context.WithTimeout(ctx, 750*time.Millisecond)
			defer cancel()
			return verifyGateway(preflightCtx) == nil
		},
		StartGateway: func(ctx context.Context) error {
			executable, err := resolver()
			if err != nil {
				return err
			}
			return startHermesGateway(ctx, executable, home, runHermes)
		},
		VerifyGateway: verifyGateway,
		RunHermes:     runHermes, RunHermesSecret: runHermesSecret,
		ReadHermes: readHermes,
	}
}

func resolveHermesAPIPort() (int, error) {
	value := strings.TrimSpace(os.Getenv("WING_HERMES_PORT"))
	if value == "" {
		return 8642, nil
	}
	port, err := strconv.Atoi(value)
	if err != nil || port < 1 || port > 65535 {
		return 0, errors.New("WING_HERMES_PORT must be a valid TCP port")
	}
	return port, nil
}

func hermesGatewayCommands() [][]string {
	// `start` is idempotent for an existing service; `start --all` would kill
	// active profile processes before starting them.
	return [][]string{{"gateway", "install", "--no-start-now"}, {"gateway", "start"}}
}

func hermesSecondaryAPICommands(rows []profileRow) ([][]string, error) {
	commands := make([][]string, 0, len(rows))
	current := 0
	for _, row := range rows {
		if row.Current {
			current++
			continue
		}
		commands = append(commands, []string{
			"--profile", row.ID, "config", "set", "--force", "platforms.api_server.enabled", "false",
		})
	}
	if current != 1 {
		return nil, errors.New("hermes profile inventory has no unique current profile")
	}
	return commands, nil
}

func ensureHermesAPIEnvironment(path string, port int) error {
	return ensureHermesAPIEnvironmentHost(path, "127.0.0.1", port)
}

func ensureHermesAPIEnvironmentHost(path, host string, port int) error {
	if net.ParseIP(host) == nil {
		return errors.New("invalid Hermes API host")
	}
	if port < 1 || port > 65535 {
		return errors.New("invalid Hermes API port")
	}
	unlock, err := acquireStateLock(path + ".wing-link.lock")
	if err != nil {
		return errors.New("could not lock the Hermes environment file")
	}
	defer func() { _ = unlock() }()
	info, err := os.Lstat(path)
	if err != nil || !info.Mode().IsRegular() {
		return errors.New("hermes environment file is unavailable")
	}
	contents, err := os.ReadFile(path)
	if err != nil {
		return errors.New("hermes environment file is unavailable")
	}
	var payload []byte
	for _, line := range strings.Split(string(contents), "\n") {
		trimmed := strings.TrimSpace(strings.TrimPrefix(strings.TrimSpace(line), "export "))
		key, _, _ := strings.Cut(trimmed, "=")
		key = strings.TrimSpace(key)
		if key == "API_SERVER_HOST" || key == "API_SERVER_PORT" || line == "" {
			continue
		}
		payload = append(payload, line...)
		payload = append(payload, '\n')
	}
	payload = fmt.Appendf(payload, "API_SERVER_HOST=%s\nAPI_SERVER_PORT=%d\n", host, port)
	return writeHermesTokenFile(path, payload)
}

func hermesAPIEndpointCommands(port int) [][]string {
	return [][]string{
		{"config", "set", "--force", "gateway.multiplex_profiles", "true"},
		{"config", "set", "--force", "platforms.api_server.enabled", "true"},
		{"config", "set", "--force", "platforms.api_server.extra.host", "127.0.0.1"},
		{"config", "set", "--force", "platforms.api_server.extra.port", strconv.Itoa(port)},
	}
}

func waitForHermesAPIHealth(ctx context.Context, port int, token string) error {
	healthCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()
	client := &http.Client{Timeout: 2 * time.Second}
	endpoint := fmt.Sprintf("http://127.0.0.1:%d/v1/capabilities", port)
	ticker := time.NewTicker(250 * time.Millisecond)
	defer ticker.Stop()
	for {
		request, err := http.NewRequestWithContext(healthCtx, http.MethodGet, endpoint, nil)
		if err == nil {
			request.Header.Set("Authorization", "Bearer "+token)
			response, requestErr := client.Do(request)
			if requestErr == nil {
				var capabilities struct {
					Object    string                     `json:"object"`
					Platform  string                     `json:"platform"`
					Endpoints map[string]json.RawMessage `json:"endpoints"`
				}
				decodeErr := json.NewDecoder(io.LimitReader(response.Body, 1<<20)).Decode(&capabilities)
				_ = response.Body.Close()
				if response.StatusCode >= http.StatusOK && response.StatusCode < http.StatusMultipleChoices &&
					decodeErr == nil && capabilities.Object == "hermes.api_server.capabilities" &&
					capabilities.Platform == "hermes-agent" && len(capabilities.Endpoints) > 0 {
					return nil
				}
			}
		}
		select {
		case <-healthCtx.Done():
			return errors.New("hermes API did not become healthy")
		case <-ticker.C:
		}
	}
}

func pinnedHermesArtifact() release.Artifact {
	if runtime.GOOS == "windows" {
		return release.Artifact{URL: pinnedHermesWindowsURL, Size: pinnedHermesWindowsSize, SHA256: pinnedHermesWindowsSHA256}
	}
	return release.Artifact{URL: pinnedHermesPOSIXURL, Size: pinnedHermesPOSIXSize, SHA256: pinnedHermesPOSIXSHA256}
}

func resolveHermesExecutable(home, hint string) (string, error) {
	return resolveHermesExecutableForPlatform(runtime.GOOS, home, hint)
}

func resolveHermesExecutableForPlatform(platform, home, hint string) (string, error) {
	candidates, err := hermesExecutableCandidates(platform, home, hint)
	if err != nil {
		return "", err
	}
	for _, candidate := range candidates {
		if candidate == "" {
			continue
		}
		info, err := os.Stat(candidate)
		if err == nil && info.Mode().IsRegular() && (platform == "windows" || info.Mode().Perm()&0o111 != 0) {
			return candidate, nil
		}
	}
	return "", os.ErrNotExist
}

func hermesExecutableCandidates(platform, home, hint string) ([]string, error) {
	if platform == "android" {
		canonical := filepath.Join(termuxPrefix, "bin", "hermes")
		if err := validateTermuxHermesGatewayShape(canonical, home); err != nil {
			return nil, err
		}
		if candidate := filepath.Clean(strings.TrimSpace(hint)); strings.TrimSpace(hint) != "" && candidate != canonical {
			return nil, errors.New("alternate Hermes executable is not allowed on android")
		}
		return []string{canonical}, nil
	}

	candidates := []string{strings.TrimSpace(hint)}
	if found, err := exec.LookPath("hermes"); err == nil {
		candidates = append(candidates, found)
	}
	if userHome, err := os.UserHomeDir(); err == nil {
		candidates = append(candidates, filepath.Join(userHome, ".local", "bin", executableName("hermes")))
	}
	if prefix := strings.TrimSpace(os.Getenv("PREFIX")); prefix != "" {
		candidates = append(candidates, filepath.Join(prefix, "bin", executableName("hermes")))
	}
	return append(candidates, filepath.Join(home, "hermes-agent", "venv", "bin", executableName("hermes"))), nil
}

func executableName(name string) string {
	if runtime.GOOS == "windows" {
		return name + ".exe"
	}
	return name
}

func downloadVerifiedArtifact(ctx context.Context, client *http.Client, artifact release.Artifact, dir string, allowedHosts []string) (path string, err error) {
	parsed, err := url.Parse(artifact.URL)
	if err != nil || parsed.User != nil || parsed.RawQuery != "" || parsed.Fragment != "" || artifact.Size <= 0 || len(artifact.SHA256) != 64 {
		return "", ErrArtifactVerification
	}
	allowed := false
	for _, host := range allowedHosts {
		allowed = allowed || strings.EqualFold(parsed.Host, host)
	}
	isLoopbackTest := strings.HasPrefix(parsed.Host, "127.0.0.1:") || strings.HasPrefix(parsed.Host, "[::1]:")
	if !allowed || (parsed.Scheme != "https" && (parsed.Scheme != "http" || !isLoopbackTest)) {
		return "", ErrArtifactVerification
	}
	copyClient := *client
	copyClient.CheckRedirect = func(request *http.Request, _ []*http.Request) error {
		if !strings.EqualFold(request.URL.Scheme, parsed.Scheme) || !strings.EqualFold(request.URL.Host, parsed.Host) {
			return ErrArtifactVerification
		}
		return nil
	}
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, parsed.String(), nil)
	if err != nil {
		return "", ErrArtifactVerification
	}
	response, err := copyClient.Do(request)
	if err != nil {
		return "", fmt.Errorf("%w: download", ErrArtifactVerification)
	}
	defer func() { _ = response.Body.Close() }()
	if response.StatusCode != http.StatusOK {
		return "", ErrArtifactVerification
	}
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return "", err
	}
	file, err := os.CreateTemp(dir, ".artifact-*")
	if err != nil {
		return "", err
	}
	artifactPath := file.Name()
	path = artifactPath
	defer func() {
		_ = file.Close()
		if err != nil {
			_ = os.Remove(artifactPath)
			path = ""
		}
	}()
	if err = file.Chmod(0o600); err != nil {
		return "", err
	}
	hash := sha256.New()
	written, copyErr := io.Copy(io.MultiWriter(file, hash), io.LimitReader(response.Body, artifact.Size+1))
	if copyErr != nil || written != artifact.Size || hex.EncodeToString(hash.Sum(nil)) != strings.ToLower(artifact.SHA256) {
		return "", ErrArtifactVerification
	}
	if err = file.Sync(); err != nil {
		return "", err
	}
	if err = file.Close(); err != nil {
		return "", err
	}
	return path, nil
}

func emitBootstrap(emit func(OperationEvent), phase, message string, percent int) {
	if emit != nil {
		emit(OperationEvent{Phase: phase, Message: message, Percent: percent})
	}
}
