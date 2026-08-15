package app

import (
	"context"
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
	"regexp"
	"runtime"
	"sort"
	"strings"
	"sync"
	"syscall"
	"time"
)

const defaultWingLinkPort = 8654
const omniRouteBaseURL = "http://127.0.0.1:20128/v1"

var profileIDPattern = regexp.MustCompile(`^[a-z0-9][a-z0-9_-]{0,63}$`)
var reservedProfileIDs = map[string]struct{}{
	"default": {}, "hermes": {}, "test": {}, "tmp": {}, "root": {}, "sudo": {},
}
var supportedProfileSetupProviders = map[string]struct{}{
	"nous": {}, "fireworks": {}, "openrouter": {}, "moa": {}, "novita": {},
	"lmstudio": {}, "anthropic": {}, "openai-codex": {}, "openai-api": {},
	"alibaba": {}, "xai-oauth": {}, "xiaomi": {}, "tencent-tokenhub": {},
	"nvidia": {}, "copilot": {}, "copilot-acp": {}, "huggingface": {},
	"gemini": {}, "vertex": {}, "deepseek": {}, "xai": {}, "zai": {},
	"kimi-coding": {}, "kimi-coding-cn": {}, "stepfun": {}, "minimax": {},
	"minimax-oauth": {}, "minimax-cn": {}, "ollama-cloud": {}, "arcee": {},
	"gmi": {}, "kilocode": {}, "opencode-zen": {}, "opencode-go": {},
	"bedrock": {}, "azure-foundry": {}, "ai-gateway": {}, "qwen-oauth": {},
	"omniroute": {},
}

type serveOptions struct {
	Listen       string
	Home         string
	Hermes       string
	StatePath    string
	HermesOrigin *url.URL
}

type profileAction struct {
	Revision string `json:"revision"`
}

type profileActions struct {
	Rename *profileAction `json:"rename,omitempty"`
	Delete *profileAction `json:"delete,omitempty"`
}

type profileRow struct {
	ID               string `json:"id"`
	Name             string `json:"name"`
	Source           string `json:"source"`
	Revision         string `json:"revision"`
	TopologyRevision string `json:"topology_revision"`

	Description   string         `json:"description,omitempty"`
	Model         string         `json:"model,omitempty"`
	SkillsCount   int            `json:"skills_count,omitempty"`
	GatewayState  string         `json:"gateway_state"`
	Actions       profileActions `json:"actions"`
	localEvidence bool
}

type profileBackend struct {
	runHermes          func(context.Context, ...string) error
	runHermesSecret    func(context.Context, []byte, ...string) error
	readHermes         func(context.Context, ...string) ([]byte, error)
	revisionSalt       string
	mutationGeneration uint64
	mu                 sync.Mutex
	warnings           []string
}

type wingLinkServer struct {
	profiles         *profileBackend
	providers        *providerBackend
	bootstrap        *BootstrapManager
	operations       *OperationManager
	state            *StateStore
	profileMutations sync.Mutex
}

// Hermes Agent remains the sole domain authority. Supported releases lack the
// required profile lifecycle contract, so Wing Link exposes only the fixed
// profile compatibility adapter. Provider fallbacks remain quarantined.
const wingLinkProfileCompatibilityEnabled = true
const wingLinkProviderFallbacksEnabled = false

func serveCommand(stdout, stderr io.Writer, args []string) int {
	options, err := parseServeOptions(args)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "serve: %v\n", err)
		return 2
	}
	bootstrap := newProductionBootstrapManager(options.Home, options.Hermes)
	runHermes := bootstrap.RunHermes
	backend := &profileBackend{
		runHermes:       runHermes,
		runHermesSecret: bootstrap.RunHermesSecret,
		readHermes:      bootstrap.ReadHermes,
	}
	backend.revisionSalt, err = randomSecret(16, "")
	if err != nil {
		_, _ = fmt.Fprintln(stderr, "serve: could not initialize profile revision authority")
		return 1
	}
	providers := &providerBackend{
		runHermes:  runHermes,
		readHermes: bootstrap.ReadHermes,
	}
	server := &http.Server{
		Handler: newWingLinkServerWithBootstrap(
			backend, &StateStore{path: options.StatePath}, providers, bootstrap,
		),
		ReadHeaderTimeout: 5 * time.Second, ReadTimeout: 30 * time.Second,
		WriteTimeout: 30 * time.Second, IdleTimeout: 90 * time.Second,
	}
	addresses := serveListenAddresses(options.Listen)
	listeners := make([]net.Listener, 0, len(addresses))
	for _, address := range addresses {
		listener, err := net.Listen("tcp", address)
		if err != nil {
			for _, opened := range listeners {
				_ = opened.Close()
			}
			writeServeListenError(stderr, address, err)
			return 1
		}
		listeners = append(listeners, listener)
		_, _ = fmt.Fprintf(stdout, "wing-link management listening on http://%s\n", address)
	}
	errChannel := make(chan error, len(listeners))
	for _, listener := range listeners {
		go func(listener net.Listener) { errChannel <- server.Serve(listener) }(listener)
	}
	if err := <-errChannel; !errors.Is(err, http.ErrServerClosed) {
		_ = server.Close()
		_, _ = fmt.Fprintf(stderr, "serve: %v\n", err)
		return 1
	}
	return 0
}

func writeServeListenError(writer io.Writer, address string, err error) {
	if errors.Is(err, syscall.EADDRINUSE) {
		_, _ = fmt.Fprintf(writer, `serve: %s is already in use

Wing Link may already be running.
  Check it:    wing-link status
  Restart it:  wing-link restart
`, address)
		return
	}
	_, _ = fmt.Fprintf(writer, "serve: %v\n", err)
}

func parseServeOptions(args []string) (serveOptions, error) {
	listenValue := strings.TrimSpace(os.Getenv("WING_LINK_LISTEN"))
	if listenValue == "" {
		host, err := advertiseIP()
		if err != nil {
			return serveOptions{}, err
		}
		listenValue = net.JoinHostPort(host, fmt.Sprint(defaultWingLinkPort))
	}
	for index := 0; index < len(args); index++ {
		switch args[index] {
		case "--listen":
			index++
			if index >= len(args) {
				return serveOptions{}, errors.New("--listen requires host:port")
			}
			listenValue = args[index]
		default:
			return serveOptions{}, fmt.Errorf("unknown option %s", args[index])
		}
	}
	listenAddress, err := net.ResolveTCPAddr("tcp", listenValue)
	if err != nil || listenAddress.IP == nil {
		return serveOptions{}, errors.New("--listen must be a valid host:port")
	}
	if !isTrustedControlPlaneIP(listenAddress.IP) {
		return serveOptions{}, errors.New("--listen must use loopback, a private LAN, or a Tailscale address")
	}
	if !isLocalInterfaceIP(listenAddress.IP) {
		return serveOptions{}, errors.New("--listen address is not assigned to this host")
	}
	home, err := resolveHermesHome()
	if err != nil {
		return serveOptions{}, err
	}
	hermes, _ := exec.LookPath("hermes")
	statePath, err := resolveWingLinkStatePath()
	if err != nil {
		return serveOptions{}, err
	}
	hermesOriginValue := strings.TrimSpace(os.Getenv("WING_HERMES_URL"))
	if hermesOriginValue == "" {
		hermesOriginValue = "http://" + net.JoinHostPort(listenAddress.IP.String(), "8642")
	}
	hermesOrigin, err := normalizeOrigin(hermesOriginValue)
	if err != nil {
		return serveOptions{}, fmt.Errorf("invalid Hermes origin: %w", err)
	}
	if !strings.EqualFold(hermesOrigin.Hostname(), listenAddress.IP.String()) {
		return serveOptions{}, errors.New("hermes and wing link must use the same host")
	}
	return serveOptions{
		Listen: listenAddress.String(), Home: home, Hermes: hermes, StatePath: statePath,
		HermesOrigin: hermesOrigin,
	}, nil
}

func resolveHermesHome() (string, error) {
	defaultHome, err := defaultHermesHome()
	if err != nil {
		return "", err
	}
	home := strings.TrimSpace(os.Getenv("WING_HERMES_HOME"))
	if home == "" {
		home = strings.TrimSpace(os.Getenv("HERMES_HOME"))
		if home != "" && pathWithin(defaultHome, home) {
			home = defaultHome
		} else if filepath.Base(filepath.Dir(home)) == "profiles" {
			home = filepath.Dir(filepath.Dir(home))
		}
	}
	if home == "" {
		home = defaultHome
	}
	if !filepath.IsAbs(home) {
		return "", errors.New("hermes home must be an absolute path")
	}
	home = filepath.Clean(home)
	if err := rejectSymlinkedAncestors(home); err != nil {
		return "", errors.New("hermes home has an unsafe path")
	}
	return home, nil
}

func defaultHermesHome() (string, error) {
	if runtime.GOOS == "windows" {
		localAppData := strings.TrimSpace(os.Getenv("LOCALAPPDATA"))
		if localAppData == "" {
			return "", errors.New("could not locate the Hermes home")
		}
		return filepath.Join(localAppData, "hermes"), nil
	}
	userHome, err := os.UserHomeDir()
	if err != nil {
		return "", errors.New("could not locate the Hermes home")
	}
	return filepath.Join(userHome, ".hermes"), nil
}

func pathWithin(root, candidate string) bool {
	relative, err := filepath.Rel(filepath.Clean(root), filepath.Clean(candidate))
	return err == nil && relative != ".." && !strings.HasPrefix(relative, ".."+string(filepath.Separator))
}

func rejectSymlinkedAncestors(path string) error {
	current := filepath.Clean(path)
	for {
		info, err := os.Lstat(current)
		if err == nil && info.Mode()&os.ModeSymlink != 0 {
			return errUnsafeProfilePath
		}
		if err != nil && !errors.Is(err, os.ErrNotExist) {
			return err
		}
		parent := filepath.Dir(current)
		if parent == current {
			return nil
		}
		current = parent
	}
}

func resolveWingLinkStatePath() (string, error) {
	if value := strings.TrimSpace(os.Getenv("WING_LINK_STATE")); value != "" {
		if !filepath.IsAbs(value) {
			return "", errors.New("wing link state path must be absolute")
		}
		return filepath.Clean(value), nil
	}
	configDir, err := os.UserConfigDir()
	if err != nil {
		return "", errors.New("could not locate the user configuration directory")
	}
	return filepath.Join(configDir, "hermes-wing", "wing-link-state.json"), nil
}

func serveListenAddresses(selected string) []string {
	address, err := net.ResolveTCPAddr("tcp", selected)
	if err != nil || address.IP.IsLoopback() {
		return []string{selected}
	}
	loopback := "127.0.0.1"
	if address.IP.To4() == nil {
		loopback = "::1"
	}
	return []string{net.JoinHostPort(loopback, fmt.Sprint(address.Port)), selected}
}

func isLocalInterfaceIP(ip net.IP) bool {
	if ip.IsLoopback() {
		return true
	}
	addresses, err := net.InterfaceAddrs()
	if err != nil {
		return false
	}
	for _, address := range addresses {
		var candidate net.IP
		switch value := address.(type) {
		case *net.IPNet:
			candidate = value.IP
		case *net.IPAddr:
			candidate = value.IP
		}
		if candidate != nil && candidate.Equal(ip) {
			return true
		}
	}
	return false
}

func isTrustedControlPlaneIP(ip net.IP) bool {
	if ip.IsLoopback() || ip.IsPrivate() {
		return true
	}
	ipv4 := ip.To4()
	return ipv4 != nil && ipv4[0] == 100 && ipv4[1] >= 64 && ipv4[1] <= 127
}

func newWingLinkServer(profiles *profileBackend, state *StateStore, providers ...*providerBackend) http.Handler {
	var provider *providerBackend
	if len(providers) > 0 {
		provider = providers[0]
	}
	return newWingLinkServerWithBootstrap(profiles, state, provider, nil)
}

func newWingLinkServerWithBootstrap(profiles *profileBackend, state *StateStore, provider *providerBackend, bootstrap *BootstrapManager) http.Handler {
	return &wingLinkServer{
		profiles: profiles, providers: provider, bootstrap: bootstrap,
		operations: NewOperationManager(), state: state,
	}
}

func (server *wingLinkServer) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	writer.Header().Set("Cache-Control", "no-store")
	if request.URL.Path == "/healthz" && request.Method == http.MethodGet {
		writeJSON(writer, http.StatusOK, map[string]any{"status": "ok", "protocol_version": ProtocolVersion})
		return
	}
	if request.URL.Path == "/v1/pairing/control-credentials" && request.Method == http.MethodPost {
		server.stageControlCredential(writer, request)
		return
	}
	if id, ok := pendingCredentialRoute(request.URL.Path); ok && request.Method == http.MethodPost {
		server.acknowledgeCredential(writer, request, id)
		return
	}
	if request.URL.Path == "/v1/pairing/acknowledged" && request.Method == http.MethodGet {
		if server.requireAuthorization(writer, request) {
			writeJSON(writer, http.StatusOK, map[string]any{"acknowledged": true})
		}
		return
	}
	if request.URL.Path == "/v1/status" && request.Method == http.MethodGet {
		if server.requireReadAuthorization(writer, request) {
			writeJSON(writer, http.StatusOK, map[string]any{"status": "ok", "protocol_version": ProtocolVersion})
		}
		return
	}
	if request.URL.Path == "/v1/setup" && request.Method == http.MethodPost {
		if !server.requireAuthorization(writer, request) {
			return
		}
		server.startBootstrap(writer, request)
		return
	}
	if id, ok := operationRoute(request.URL.Path); ok && request.Method == http.MethodGet {
		if !server.requireReadAuthorization(writer, request) {
			return
		}
		server.operationSnapshot(writer, id)
		return
	}
	if wingLinkProfileCompatibilityEnabled && request.URL.Path == "/v1/profiles" {
		switch request.Method {
		case http.MethodGet:
			if !server.requireReadAuthorization(writer, request) {
				return
			}
			server.listProfiles(writer)
		case http.MethodPost:
			if !server.requireAuthorization(writer, request) {
				return
			}
			server.createProfile(writer, request)
		default:
			writer.WriteHeader(http.StatusMethodNotAllowed)
		}
		return
	}
	if wingLinkProfileCompatibilityEnabled {
		if id, ok := profileRoute(request.URL.Path); ok {
			if !server.requireAuthorization(writer, request) {
				return
			}
			switch request.Method {
			case http.MethodPatch:
				server.renameProfile(writer, request, id)
			case http.MethodDelete:
				server.deleteProfile(writer, request, id)
			default:
				writer.WriteHeader(http.StatusMethodNotAllowed)
			}
			return
		}
	}
	if wingLinkProviderFallbacksEnabled && server.providers != nil && server.serveProviderRoute(writer, request) {
		return
	}
	writer.WriteHeader(http.StatusNotFound)
}

func (server *wingLinkServer) stageControlCredential(writer http.ResponseWriter, request *http.Request) {
	host, _, err := net.SplitHostPort(request.RemoteAddr)
	if err != nil || !net.ParseIP(host).IsLoopback() {
		writeJSON(writer, http.StatusForbidden, map[string]any{
			"error": APIError{Code: "pairing_local_only", Message: "Pairing credential staging is local only"},
		})
		return
	}
	id, token, err := server.state.StageControlToken()
	if err != nil {
		writeJSON(writer, http.StatusServiceUnavailable, map[string]any{
			"error": APIError{Code: "credential_unavailable", Message: "Could not stage control credential"},
		})
		return
	}
	writeJSON(writer, http.StatusCreated, map[string]any{"credential_id": id, "token": token})
}

func pendingCredentialRoute(path string) (string, bool) {
	parts := strings.Split(strings.Trim(path, "/"), "/")
	if len(parts) != 5 || parts[0] != "v1" || parts[1] != "auth" ||
		parts[2] != "credentials" || parts[4] != "ack" ||
		!strings.HasPrefix(parts[3], "cred_") {
		return "", false
	}
	return parts[3], true
}

func (server *wingLinkServer) acknowledgeCredential(writer http.ResponseWriter, request *http.Request, id string) {
	authorization := strings.TrimSpace(request.Header.Get("Authorization"))
	const prefix = "Bearer "
	token := strings.TrimSpace(strings.TrimPrefix(authorization, prefix))
	if !strings.HasPrefix(authorization, prefix) {
		writeJSON(writer, http.StatusUnauthorized, map[string]any{
			"error": APIError{Code: "unauthorized", Message: "Pending Wing Link credential required"},
		})
		return
	}
	if server.state.Authorize(token) {
		writeJSON(writer, http.StatusOK, map[string]any{"credential_id": id, "acknowledged": true})
		return
	}
	if !server.state.AuthorizePending(id, token) {
		writeJSON(writer, http.StatusUnauthorized, map[string]any{
			"error": APIError{Code: "unauthorized", Message: "Pending Wing Link credential required"},
		})
		return
	}
	if err := server.state.AcknowledgeControlToken(id, token); err != nil {
		writeJSON(writer, http.StatusConflict, map[string]any{
			"error": APIError{Code: "credential_unavailable", Message: "Pending credential is unavailable"},
		})
		return
	}
	writeJSON(writer, http.StatusOK, map[string]any{"credential_id": id, "acknowledged": true})
}

func (server *wingLinkServer) requireReadAuthorization(writer http.ResponseWriter, request *http.Request) bool {
	token, ok := bearerToken(request)
	if !ok || !server.state.Authorize(token) && !server.state.AuthorizePendingToken(token) {
		writeJSON(writer, http.StatusUnauthorized, map[string]any{
			"error": APIError{Code: "unauthorized", Message: "Wing Link control token required"},
		})
		return false
	}
	return true
}

func (server *wingLinkServer) requireAuthorization(writer http.ResponseWriter, request *http.Request) bool {
	token, ok := bearerToken(request)
	if !ok || !server.state.Authorize(token) {
		writeJSON(writer, http.StatusUnauthorized, map[string]any{
			"error": APIError{Code: "unauthorized", Message: "Wing Link control token required"},
		})
		return false
	}
	return true
}

func bearerToken(request *http.Request) (string, bool) {
	authorization := strings.TrimSpace(request.Header.Get("Authorization"))
	const prefix = "Bearer "
	if !strings.HasPrefix(authorization, prefix) {
		return "", false
	}
	token := strings.TrimSpace(strings.TrimPrefix(authorization, prefix))
	return token, token != ""
}

func (server *wingLinkServer) listProfiles(writer http.ResponseWriter) {
	rows, warnings, err := server.profiles.listWithWarnings()
	if err != nil {
		writeProfileError(writer, err)
		return
	}
	writeJSON(writer, http.StatusOK, map[string]any{
		"protocol_version": ProtocolVersion,
		"profiles":         rows,
		"warnings":         warnings,
	})
}

func (server *wingLinkServer) createProfile(writer http.ResponseWriter, request *http.Request) {
	var body struct {
		Name           string `json:"name"`
		CloneFrom      string `json:"clone_from"`
		Description    string `json:"description"`
		Provider       string `json:"provider"`
		Model          string `json:"model"`
		ProviderAPIKey string `json:"provider_api_key"`
	}
	if !decodeJSON(writer, request, &body) {
		return
	}
	if err := validateProfileSetup(
		body.Description, body.Provider, body.Model, body.ProviderAPIKey,
	); err != nil {
		writeProfileError(writer, err)
		return
	}
	if !server.profileMutations.TryLock() {
		writeProfileError(writer, errProfileOperationBusy)
		return
	}
	defer server.profileMutations.Unlock()
	row, err := server.profiles.create(request.Context(), body.Name, body.CloneFrom)
	if err != nil {
		if row.ID != "" {
			if rollbackErr := server.rollbackCreatedProfile(request.Context(), row.ID); rollbackErr != nil {
				err = errors.Join(err, rollbackErr)
			}
		}
		writeProfileError(writer, err)
		return
	}
	if err := server.profiles.configure(
		request.Context(), row.ID, body.Description, body.Provider, body.Model,
		body.ProviderAPIKey,
	); err != nil {
		if row.ID == "" {
			err = errors.Join(err, errProfilePostcondition)
		} else if rollbackErr := server.rollbackCreatedProfile(request.Context(), row.ID); rollbackErr != nil {
			err = errors.Join(err, rollbackErr)
		}
		writeProfileError(writer, err)
		return
	}
	writeJSON(writer, http.StatusCreated, map[string]any{"profile": row})
}

func (server *wingLinkServer) rollbackCreatedProfile(requestContext context.Context, id string) error {
	rollbackContext, cancelRollback := context.WithTimeout(
		context.WithoutCancel(requestContext), 30*time.Second,
	)
	defer cancelRollback()
	return server.profiles.deleteCreated(rollbackContext, id)
}

func (server *wingLinkServer) renameProfile(writer http.ResponseWriter, request *http.Request, id string) {
	var body struct {
		Name           string `json:"name"`
		Revision       string `json:"revision"`
		Description    string `json:"description"`
		Provider       string `json:"provider"`
		Model          string `json:"model"`
		ProviderAPIKey string `json:"provider_api_key"`
	}
	if !decodeJSON(writer, request, &body) {
		return
	}
	revision := strings.TrimSpace(body.Revision)
	if revision == "" {
		revision = strings.TrimSpace(request.Header.Get("If-Match"))
	}
	if err := validateProfileSetup(
		body.Description, body.Provider, body.Model, body.ProviderAPIKey,
	); err != nil {
		writeProfileError(writer, err)
		return
	}
	if strings.TrimSpace(body.Description) != "" ||
		strings.TrimSpace(body.Provider) != "" ||
		strings.TrimSpace(body.Model) != "" || body.ProviderAPIKey != "" {
		writeProfileError(writer, errProfileInvalidSetup)
		return
	}
	if !server.profileMutations.TryLock() {
		writeProfileError(writer, errProfileOperationBusy)
		return
	}
	defer server.profileMutations.Unlock()
	target, err := mutableProfileID(body.Name)
	if err != nil {
		writeProfileError(writer, err)
		return
	}
	var row profileRow
	if target == id {
		row, err = server.profiles.requireRevision(request.Context(), id, revision)
	} else {
		row, err = server.profiles.rename(request.Context(), id, target, revision)
	}
	if err != nil {
		writeProfileError(writer, err)
		return
	}
	writeJSON(writer, http.StatusOK, map[string]any{"profile": row})
}

func (server *wingLinkServer) deleteProfile(writer http.ResponseWriter, request *http.Request, id string) {
	if !server.profileMutations.TryLock() {
		writeProfileError(writer, errProfileOperationBusy)
		return
	}
	defer server.profileMutations.Unlock()
	if err := server.profiles.delete(request.Context(), id, strings.TrimSpace(request.Header.Get("If-Match"))); err != nil {
		writeProfileError(writer, err)
		return
	}
	writeJSON(writer, http.StatusOK, map[string]any{"id": id, "deleted": true})
}

func profileRoute(path string) (string, bool) {
	parts := strings.Split(strings.Trim(path, "/"), "/")
	if len(parts) != 3 || parts[0] != "v1" || parts[1] != "profiles" {
		return "", false
	}
	id, err := normalizeProfileID(parts[2])
	return id, err == nil
}

type profileObservedError struct {
	cause   error
	outcome string
}

func (err *profileObservedError) Error() string { return err.cause.Error() }
func (err *profileObservedError) Unwrap() error { return err.cause }

var (
	errProfileInvalidName      = errors.New("profile name is invalid")
	errProfileReserved         = errors.New("profile name is reserved")
	errProfileNotFound         = errors.New("profile not found")
	errProfileExists           = errors.New("profile already exists")
	errProfileRevisionRequired = errors.New("profile revision is required")
	errProfileChanged          = errors.New("profile inventory changed")
	errUnsafeProfilePath       = errors.New("profile path is not a regular local resource")

	errProfileCLIFailed     = errors.New("profile CLI failed")
	errProfilePostcondition = errors.New("profile postcondition failed")
	errProfileOperationBusy = errors.New("profile operation in progress")
	errInventoryUnavailable = errors.New("profile inventory unavailable")
	errProfileSetupFailed   = errors.New("profile setup failed")
	errProfileInvalidSetup  = errors.New("profile setup is invalid")
)

func validateProfileSetup(description, provider, model, providerAPIKey string) error {
	description = strings.TrimSpace(description)
	provider = strings.ToLower(strings.TrimSpace(provider))
	model = strings.TrimSpace(model)
	_, providerSupported := supportedProfileSetupProviders[provider]
	if len([]rune(description)) > 500 || hasControl(description) ||
		(provider == "") != (model == "") ||
		(provider != "" && (!providerSupported || len([]rune(model)) > 200 || hasControl(model))) ||
		(provider == "omniroute" && providerAPIKey != "") ||
		(providerAPIKey != "" && provider == "") ||
		len(providerAPIKey) > 16<<10 || strings.ContainsAny(providerAPIKey, "\r\n\x00") {
		return errProfileInvalidSetup
	}
	return nil
}

func (backend *profileBackend) configure(
	ctx context.Context,
	profile, description, provider, model, providerAPIKey string,
) error {
	backend.mu.Lock()
	defer backend.mu.Unlock()
	profile, err := normalizeProfileID(profile)
	if err != nil {
		return err
	}
	description = strings.TrimSpace(description)
	provider = strings.ToLower(strings.TrimSpace(provider))
	model = strings.TrimSpace(model)
	if err := validateProfileSetup(description, provider, model, providerAPIKey); err != nil {
		return err
	}
	effectiveProvider := provider
	if provider == "omniroute" {
		effectiveProvider = "custom"
	}
	if description != "" {
		if err := backend.runHermes(ctx, "profile", "describe", profile, "--text", description); err != nil {
			return errProfileSetupFailed
		}
	}
	if provider == "" {
		return nil
	}
	if err := backend.runHermes(ctx, "--profile", profile, "config", "set", "--force", "model.provider", effectiveProvider); err != nil {
		return errProfileSetupFailed
	}
	if provider == "omniroute" {
		if err := backend.runHermes(ctx, "--profile", profile, "config", "set", "--force", "model.base_url", omniRouteBaseURL); err != nil {
			return errProfileSetupFailed
		}
	}
	if err := backend.runHermes(ctx, "--profile", profile, "config", "set", "--force", "model.default", model); err != nil {
		return errProfileSetupFailed
	}
	if backend.readHermes == nil {
		return errProfileSetupFailed
	}
	configuredProvider, err := backend.readHermes(ctx, "--profile", profile, "config", "get", "model.provider")
	if err != nil || strings.TrimSpace(string(configuredProvider)) != effectiveProvider {
		return errProfilePostcondition
	}
	if provider == "omniroute" {
		configuredBaseURL, err := backend.readHermes(ctx, "--profile", profile, "config", "get", "model.base_url")
		if err != nil || strings.TrimSpace(string(configuredBaseURL)) != omniRouteBaseURL {
			return errProfilePostcondition
		}
	}
	configuredModel, err := backend.readHermes(ctx, "--profile", profile, "config", "get", "model.default")
	if err != nil || strings.TrimSpace(string(configuredModel)) != model {
		return errProfilePostcondition
	}
	if providerAPIKey != "" {
		if backend.runHermesSecret == nil {
			return errProfileSetupFailed
		}
		input := append([]byte(providerAPIKey), '\n')
		if err := backend.runHermesSecret(
			ctx, input, "--profile", profile, "auth", "add", provider,
			"--type", "api-key", "--label", "wing-link",
		); err != nil {
			return errProfileSetupFailed
		}
		if err := backend.runHermes(ctx, "--profile", profile, "auth", "status", provider); err != nil {
			return errProfilePostcondition
		}
	}
	response, err := backend.readHermes(
		ctx, "--profile", profile, "chat", "-Q", "--source", "tool", "-q",
		"Reply with exactly: Hi",
	)
	if err != nil || !strings.EqualFold(strings.TrimSpace(string(response)), "Hi") {
		return errProfilePostcondition
	}
	return nil
}

func (backend *profileBackend) requireRevision(
	ctx context.Context, profile, revision string,
) (profileRow, error) {
	if !backend.mu.TryLock() {
		return profileRow{}, errProfileOperationBusy
	}
	defer backend.mu.Unlock()
	profile, err := mutableProfileID(profile)
	if err != nil {
		return profileRow{}, err
	}
	if strings.TrimSpace(revision) == "" {
		return profileRow{}, errProfileRevisionRequired
	}
	rows, err := backend.listCLILocked(ctx)
	if err != nil {
		return profileRow{}, err
	}
	row, exists := findProfileRow(rows, profile)
	if !exists {
		return profileRow{}, errProfileNotFound
	}
	if row.Revision != revision {
		return profileRow{}, errProfileChanged
	}
	return row, nil
}

func normalizeProfileID(value string) (string, error) {
	id := strings.ToLower(strings.TrimSpace(value))
	if !profileIDPattern.MatchString(id) {
		return "", errProfileInvalidName
	}
	return id, nil
}

func mutableProfileID(value string) (string, error) {
	id, err := normalizeProfileID(value)
	if err != nil {
		return "", err
	}
	if _, reserved := reservedProfileIDs[id]; reserved {
		return "", errProfileReserved
	}
	return id, nil
}

func (backend *profileBackend) list() ([]profileRow, error) {
	rows, _, err := backend.listWithWarnings()
	return rows, err
}

func (backend *profileBackend) listWithWarnings() ([]profileRow, []string, error) {
	backend.mu.Lock()
	defer backend.mu.Unlock()
	rows, err := backend.listCLILocked(context.Background())
	return rows, append([]string(nil), backend.warnings...), err
}

func (backend *profileBackend) listCLILocked(ctx context.Context) ([]profileRow, error) {
	backend.warnings = nil
	if backend.readHermes == nil {
		return nil, fmt.Errorf("%w: profile list is unavailable", errInventoryUnavailable)
	}
	output, err := backend.readHermes(ctx, "profile", "list")
	if err != nil {
		return nil, fmt.Errorf("%w: %v", errInventoryUnavailable, err)
	}
	rows, err := parseHermesProfileList(output)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", errInventoryUnavailable, err)
	}
	return backend.decorateCLIRows(rows), nil
}

func (backend *profileBackend) decorateCLIRows(rows []profileRow) []profileRow {
	sort.Slice(rows, func(left, right int) bool { return rows[left].ID < rows[right].ID })
	var inventory strings.Builder
	for _, row := range rows {
		_, _ = fmt.Fprintf(&inventory, "%s\x00%s\n", row.ID, row.GatewayState)
	}
	generation := fmt.Sprintf("%d", backend.mutationGeneration)
	for index := range rows {
		row := &rows[index]
		revision := "wlp_" + hashSecret(
			backend.revisionSalt+"\x00"+generation+"\x00"+inventory.String()+"\x00"+row.ID,
		)
		row.Name = row.ID
		row.Source = "cli"
		row.Revision = revision
		row.TopologyRevision = revision
		row.localEvidence = true
		if _, reserved := reservedProfileIDs[row.ID]; !reserved {
			row.Actions = profileActions{
				Rename: &profileAction{Revision: revision},
				Delete: &profileAction{Revision: revision},
			}
		}
	}
	return rows
}

func (backend *profileBackend) create(ctx context.Context, name, cloneFrom string) (profileRow, error) {
	if !backend.mu.TryLock() {
		return profileRow{}, errProfileOperationBusy
	}
	defer backend.mu.Unlock()
	id, err := mutableProfileID(name)
	if err != nil {
		return profileRow{}, err
	}
	cloneID := ""
	if strings.TrimSpace(cloneFrom) != "" {
		cloneID, err = normalizeProfileID(cloneFrom)
		if err != nil {
			return profileRow{}, err
		}
	}
	rows, err := backend.listCLILocked(ctx)
	if err != nil {
		return profileRow{}, err
	}
	if _, exists := findProfileRow(rows, id); exists {
		return profileRow{}, errProfileExists
	}
	if cloneID != "" {
		if _, exists := findProfileRow(rows, cloneID); !exists {
			return profileRow{}, errProfileNotFound
		}
	}
	args := []string{"profile", "create", id, "--no-alias"}
	if cloneID != "" {
		args = append(args, "--clone-from", cloneID)
	}
	if err := backend.runHermes(ctx, args...); err != nil {
		cause := fmt.Errorf("%w: %v", errProfileCLIFailed, err)
		return profileRow{}, backend.observedFailureLocked(ctx, "create", id, "", cause)
	}
	backend.mutationGeneration++
	row, err := backend.rowAfterMutationLocked(ctx, id)
	if err != nil {
		return profileRow{ID: id}, err
	}
	return row, nil
}

func (backend *profileBackend) rename(ctx context.Context, current, replacement, revision string) (profileRow, error) {
	if !backend.mu.TryLock() {
		return profileRow{}, errProfileOperationBusy
	}
	defer backend.mu.Unlock()
	currentID, err := mutableProfileID(current)
	if err != nil {
		return profileRow{}, err
	}
	replacementID, err := mutableProfileID(replacement)
	if err != nil {
		return profileRow{}, err
	}
	if strings.TrimSpace(revision) == "" {
		return profileRow{}, errProfileRevisionRequired
	}
	rows, err := backend.listCLILocked(ctx)
	if err != nil {
		return profileRow{}, err
	}
	row, exists := findProfileRow(rows, currentID)
	if !exists {
		return profileRow{}, errProfileNotFound
	}
	action := row.Actions.Rename
	if action == nil {
		return profileRow{}, errProfileReserved
	}
	if revision != action.Revision {
		return profileRow{}, errProfileChanged
	}
	if _, exists := findProfileRow(rows, replacementID); exists {
		return profileRow{}, errProfileExists
	}
	if err := backend.runHermes(ctx, "profile", "rename", currentID, replacementID); err != nil {
		cause := fmt.Errorf("%w: %v", errProfileCLIFailed, err)
		return profileRow{}, backend.observedFailureLocked(ctx, "rename", currentID, replacementID, cause)
	}
	backend.mutationGeneration++
	return backend.rowAfterRenameLocked(ctx, currentID, replacementID)
}

func (backend *profileBackend) delete(ctx context.Context, id, revision string) error {
	if !backend.mu.TryLock() {
		return errProfileOperationBusy
	}
	defer backend.mu.Unlock()
	profileID, err := mutableProfileID(id)
	if err != nil {
		return err
	}
	if strings.TrimSpace(revision) == "" {
		return errProfileRevisionRequired
	}
	rows, err := backend.listCLILocked(ctx)
	if err != nil {
		return err
	}
	row, exists := findProfileRow(rows, profileID)
	if !exists {
		return errProfileNotFound
	}
	action := row.Actions.Delete
	if action == nil {
		return errProfileReserved
	}
	if revision != action.Revision {
		return errProfileChanged
	}
	if err := backend.runHermes(ctx, "profile", "delete", "--yes", profileID); err != nil {
		cause := fmt.Errorf("%w: %v", errProfileCLIFailed, err)
		return backend.observedFailureLocked(ctx, "delete", profileID, "", cause)
	}
	backend.mutationGeneration++
	return backend.confirmDeletedLocked(ctx, profileID)
}

func (backend *profileBackend) deleteCreated(ctx context.Context, id string) error {
	if !backend.mu.TryLock() {
		return errProfileOperationBusy
	}
	defer backend.mu.Unlock()
	profileID, err := mutableProfileID(id)
	if err != nil {
		return err
	}
	if err := backend.runHermes(ctx, "profile", "delete", "--yes", profileID); err != nil {
		return fmt.Errorf("%w: %v", errProfileCLIFailed, err)
	}
	backend.mutationGeneration++
	return backend.confirmDeletedLocked(ctx, profileID)
}

func (backend *profileBackend) confirmDeletedLocked(ctx context.Context, id string) error {
	rows, err := backend.listCLILocked(ctx)
	if err != nil {
		return err
	}
	if _, exists := findProfileRow(rows, id); exists {
		return errors.New("profile deletion was not confirmed")
	}
	return nil
}

func (backend *profileBackend) observedFailureLocked(
	ctx context.Context,
	kind, currentID, replacementID string,
	cause error,
) error {
	outcome := "unknown"
	if rows, err := backend.listCLILocked(ctx); err == nil {
		_, currentExists := findProfileRow(rows, currentID)
		_, replacementExists := findProfileRow(rows, replacementID)
		switch kind {
		case "create":
			if currentExists {
				outcome = "applied"
			} else {
				outcome = "not_applied"
			}
		case "delete":
			if currentExists {
				outcome = "not_applied"
			} else {
				outcome = "applied"
			}
		case "rename":
			if replacementExists && !currentExists {
				outcome = "applied"
			} else if currentExists && !replacementExists {
				outcome = "not_applied"
			}
		}
	}
	return &profileObservedError{cause: cause, outcome: outcome}
}

func findProfileRow(rows []profileRow, id string) (profileRow, bool) {
	for _, row := range rows {
		if row.ID == id {
			return row, true
		}
	}
	return profileRow{}, false
}

func (backend *profileBackend) rowAfterMutationLocked(ctx context.Context, id string) (profileRow, error) {
	rows, err := backend.listCLILocked(ctx)
	if err != nil {
		return profileRow{}, err
	}
	for _, row := range rows {
		if row.ID == id {
			return row, nil
		}
	}
	return profileRow{}, errProfileNotFound
}

func (backend *profileBackend) rowAfterRenameLocked(ctx context.Context, sourceID, replacementID string) (profileRow, error) {
	rows, err := backend.listCLILocked(ctx)
	if err != nil {
		return profileRow{}, err
	}
	replacement, replacementExists := findProfileRow(rows, replacementID)
	_, sourceExists := findProfileRow(rows, sourceID)
	if !replacementExists || sourceExists {
		return profileRow{}, errProfilePostcondition
	}
	return replacement, nil
}

func decodeJSON(writer http.ResponseWriter, request *http.Request, target any) bool {
	decoder := json.NewDecoder(http.MaxBytesReader(writer, request.Body, 64<<10))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		writeJSON(writer, http.StatusBadRequest, map[string]any{
			"error": APIError{Code: "invalid_request", Message: "Request body is invalid"},
		})
		return false
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		writeJSON(writer, http.StatusBadRequest, map[string]any{
			"error": APIError{Code: "invalid_request", Message: "Request body has trailing data"},
		})
		return false
	}
	return true
}

func writeProfileError(writer http.ResponseWriter, err error) {
	status := http.StatusInternalServerError
	code := "profile_operation_failed"
	message := "Profile operation failed"
	switch {
	case errors.Is(err, errProfileInvalidName):
		status, code, message = http.StatusBadRequest, "profile_invalid_name", "Profile names must match [a-z0-9][a-z0-9_-]{0,63}"
	case errors.Is(err, errProfileInvalidSetup):
		status, code, message = http.StatusBadRequest, "profile_setup_invalid", "Profile setup fields are invalid"
	case errors.Is(err, errProfileReserved):
		status, code, message = http.StatusBadRequest, "profile_reserved", "Reserved profiles cannot be changed"
	case errors.Is(err, errProfileNotFound):
		status, code, message = http.StatusNotFound, "profile_not_found", "Profile not found"
	case errors.Is(err, errProfileExists):
		status, code, message = http.StatusConflict, "profile_already_exists", "Profile already exists"
	case errors.Is(err, errProfileRevisionRequired):
		status, code, message = http.StatusPreconditionRequired, "profile_revision_required", "Profile revision is required"
	case errors.Is(err, errProfileChanged):
		status, code, message = http.StatusPreconditionFailed, "profile_inventory_changed", "Profile inventory changed; refresh and retry"
	case errors.Is(err, errProfileOperationBusy):
		status, code, message = http.StatusConflict, "profile_operation_in_progress", "Another profile operation is in progress"

	case errors.Is(err, errProfileCLIFailed):
		status, code, message = http.StatusBadGateway, "profile_cli_failed", "Hermes profile CLI operation failed"
	case errors.Is(err, errProfileSetupFailed):
		status, code, message = http.StatusServiceUnavailable, "profile_setup_failed", "Hermes profile setup failed"
	case errors.Is(err, errProfilePostcondition):
		status, code, message = http.StatusBadGateway, "profile_postcondition_failed", "Hermes profile mutation postcondition failed"
	case errors.Is(err, errInventoryUnavailable), errors.Is(err, errUnsafeProfilePath):
		status, code, message = http.StatusServiceUnavailable, "profile_inventory_unavailable", "Profile inventory is unavailable"
	}
	payload := map[string]any{"error": APIError{Code: code, Message: message}}
	var observed *profileObservedError
	if errors.As(err, &observed) {
		payload["outcome"] = observed.outcome
	}
	writeJSON(writer, status, payload)
}

func writeJSON(writer http.ResponseWriter, status int, value any) {
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(status)
	_ = json.NewEncoder(writer).Encode(value)
}
