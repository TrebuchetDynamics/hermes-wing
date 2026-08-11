package main

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"
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
	ErrHermesInstall        = errors.New("Hermes installation failed")
	ErrBootstrapInvalid     = errors.New("bootstrap request is invalid")
)

type BootstrapProfile struct {
	Name      string `json:"name"`
	CloneFrom string `json:"clone_from,omitempty"`
}

type BootstrapProvider struct {
	ID      string `json:"id"`
	BaseURL string `json:"base_url"`
	Model   string `json:"model"`
}

type BootstrapRequest struct {
	Profile  *BootstrapProfile  `json:"profile,omitempty"`
	Provider *BootstrapProvider `json:"provider,omitempty"`
}

func (request BootstrapRequest) Validate() error {
	if request.Profile != nil {
		if _, err := mutableProfileID(request.Profile.Name); err != nil {
			return fmt.Errorf("%w: profile", ErrBootstrapInvalid)
		}
		if strings.TrimSpace(request.Profile.CloneFrom) != "" {
			if _, err := normalizeProfileID(request.Profile.CloneFrom); err != nil {
				return fmt.Errorf("%w: clone source", ErrBootstrapInvalid)
			}
		}
	}
	if request.Provider != nil {
		if _, err := validateCustomProvider(request.Provider.ID, request.Provider.BaseURL, request.Provider.Model); err != nil {
			return fmt.Errorf("%w: provider", ErrBootstrapInvalid)
		}
	}
	return nil
}

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
	Profile         string `json:"profile,omitempty"`
	Provider        string `json:"provider,omitempty"`
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
	EnsureHermes  func(context.Context, func(OperationEvent)) (HermesInspection, error)
	EnsureAPIKey  func(context.Context) error
	StartGateway  func(context.Context) error
	RunHermes     func(context.Context, ...string) error
	ReadHermes    func(context.Context, ...string) ([]byte, error)
	ProfileExists func(context.Context, string) bool
}

func (manager *BootstrapManager) Bootstrap(ctx context.Context, request BootstrapRequest, emit func(OperationEvent)) (BootstrapResult, error) {
	if err := request.Validate(); err != nil {
		return BootstrapResult{}, err
	}
	if manager == nil || manager.EnsureHermes == nil || manager.RunHermes == nil || manager.ReadHermes == nil {
		return BootstrapResult{}, ErrHermesInstall
	}
	inspection, err := manager.EnsureHermes(ctx, emit)
	if err != nil {
		return BootstrapResult{}, err
	}
	result := BootstrapResult{HermesInstalled: true, HermesAdopted: inspection.Adopted, HermesVersion: inspection.Version}
	profile := "default"
	if request.Profile != nil {
		profile, _ = mutableProfileID(request.Profile.Name)
		if manager.ProfileExists != nil && manager.ProfileExists(ctx, profile) {
			return BootstrapResult{}, errProfileExists
		}
		args := []string{"profile", "create", profile, "--no-alias"}
		if clone := strings.TrimSpace(request.Profile.CloneFrom); clone != "" {
			args = append(args, "--clone-from", clone)
		}
		emitBootstrap(emit, "profile", "Creating Hermes profile", 78)
		if err := manager.RunHermes(ctx, args...); err != nil {
			return BootstrapResult{}, fmt.Errorf("%w: %v", errProfileCLIFailed, err)
		}
		if manager.ProfileExists != nil && !manager.ProfileExists(ctx, profile) {
			return BootstrapResult{}, fmt.Errorf("%w: profile was not persisted", errProfileCLIFailed)
		}
		result.Profile = profile
	}
	if request.Provider != nil {
		emitBootstrap(emit, "provider", "Configuring Hermes provider", 88)
		backend := &providerBackend{runHermes: manager.RunHermes, readHermes: manager.ReadHermes}
		row, err := backend.create(ctx, profile, request.Provider.ID, request.Provider.BaseURL, request.Provider.Model)
		if err != nil {
			return BootstrapResult{}, err
		}
		result.Provider = row.ID
		if result.Profile == "" {
			result.Profile = profile
		}
	}
	if manager.EnsureAPIKey != nil {
		emitBootstrap(emit, "authentication", "Securing Hermes API access", 92)
		if err := manager.EnsureAPIKey(ctx); err != nil {
			return BootstrapResult{}, fmt.Errorf("%w: API authentication", ErrHermesInstall)
		}
	}
	if manager.StartGateway != nil {
		emitBootstrap(emit, "gateway", "Starting Hermes gateway", 96)
		if err := manager.StartGateway(ctx); err != nil {
			return BootstrapResult{}, fmt.Errorf("%w: gateway", ErrHermesInstall)
		}
		result.GatewayStarted = true
	}
	emitBootstrap(emit, "complete", "Hermes setup complete", 100)
	return result, nil
}

func newProductionBootstrapManager(home, hermesHint string) *BootstrapManager {
	resolver := func() (string, error) { return resolveHermesExecutable(home, hermesHint) }
	runner := func(ctx context.Context, spec CommandSpec, onLine func(string)) ProcessResult {
		return runProcess(ctx, spec, onLine)
	}
	artifact := pinnedHermesArtifact()
	installer := &HermesInstaller{
		Home: home, Commit: pinnedHermesCommit, Resolve: resolver, Run: runner,
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
	readHermes := func(ctx context.Context, args ...string) ([]byte, error) {
		executable, err := resolver()
		if err != nil {
			return nil, err
		}
		output, result := runProcessCapture(ctx, CommandSpec{Path: executable, Args: args, Env: []string{"HERMES_HOME=" + home}, Timeout: 30 * time.Second}, 256*1024)
		return output, result.Err
	}
	return &BootstrapManager{
		EnsureHermes: installer.Ensure,
		EnsureAPIKey: func(ctx context.Context) error {
			output, err := readHermes(ctx, "config", "env-path")
			path := strings.TrimSpace(string(output))
			if err != nil || !filepath.IsAbs(path) || strings.ContainsAny(path, "\r\n") || !pathWithin(home, path) {
				return ErrHermesInstall
			}
			_, err = ensureHermesTokenFile(path)
			return err
		},
		StartGateway: func(ctx context.Context) error {
			if err := runHermes(ctx, "gateway", "install"); err != nil {
				return err
			}
			return runHermes(ctx, "gateway", "start")
		},
		RunHermes: runHermes, ReadHermes: readHermes,
		ProfileExists: func(_ context.Context, id string) bool {
			if id == "default" {
				return true
			}
			info, err := os.Stat(filepath.Join(home, "profiles", id))
			return err == nil && info.IsDir()
		},
	}
}

func pinnedHermesArtifact() Artifact {
	if runtime.GOOS == "windows" {
		return Artifact{URL: pinnedHermesWindowsURL, Size: pinnedHermesWindowsSize, SHA256: pinnedHermesWindowsSHA256}
	}
	return Artifact{URL: pinnedHermesPOSIXURL, Size: pinnedHermesPOSIXSize, SHA256: pinnedHermesPOSIXSHA256}
}

func resolveHermesExecutable(home, hint string) (string, error) {
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
	candidates = append(candidates, filepath.Join(home, "hermes-agent", "venv", "bin", executableName("hermes")))
	for _, candidate := range candidates {
		if candidate == "" {
			continue
		}
		info, err := os.Stat(candidate)
		if err == nil && info.Mode().IsRegular() && (runtime.GOOS == "windows" || info.Mode().Perm()&0o111 != 0) {
			return candidate, nil
		}
	}
	return "", os.ErrNotExist
}

func executableName(name string) string {
	if runtime.GOOS == "windows" {
		return name + ".exe"
	}
	return name
}

func downloadVerifiedArtifact(ctx context.Context, client *http.Client, artifact Artifact, dir string, allowedHosts []string) (path string, err error) {
	parsed, err := url.Parse(artifact.URL)
	if err != nil || parsed.User != nil || parsed.RawQuery != "" || parsed.Fragment != "" || artifact.Size <= 0 || len(artifact.SHA256) != 64 {
		return "", ErrArtifactVerification
	}
	allowed := false
	for _, host := range allowedHosts {
		allowed = allowed || strings.EqualFold(parsed.Host, host)
	}
	isLoopbackTest := strings.HasPrefix(parsed.Host, "127.0.0.1:") || strings.HasPrefix(parsed.Host, "[::1]:")
	if !allowed || parsed.Scheme != "https" && !(parsed.Scheme == "http" && isLoopbackTest) {
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
