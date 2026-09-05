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
	"regexp"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
	"unicode"

	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/audit"
	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/workspaces"
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
	Current       bool           `json:"-"`
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
	profiles              *profileBackend
	bootstrap             *BootstrapManager
	operations            *OperationManager
	approvals             *ApprovalStore
	audit                 *AuditLog
	updater               wingLinkUpdater
	state                 *StateStore
	directories           *workspaces.Browser
	hostFingerprint       string
	localPairingProofHash string
	profileMutations      sync.Mutex
}

// Hermes Agent remains the sole domain authority. Supported releases lack the
// required profile lifecycle contract, so Wing Link exposes only the fixed
// profile compatibility adapter.
const wingLinkProfileCompatibilityEnabled = true

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
	controlState := newStateStore(options.StatePath)
	hostIdentity, err := controlState.HostIdentity()
	if err != nil {
		_, _ = fmt.Fprintln(stderr, "serve: could not initialize host identity")
		return 1
	}
	operations, err := NewDurableOperationManager(
		filepath.Join(filepath.Dir(options.StatePath), "wing-link-operations.json"),
	)
	if err != nil {
		_, _ = fmt.Fprintln(stderr, "serve: could not initialize operation journal")
		return 1
	}
	server := &http.Server{
		Handler: newWingLinkServerWithOperations(
			backend, controlState, bootstrap, operations,
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
		_, _ = fmt.Fprintf(
			stdout,
			"wing-link management listening on %s://%s\n",
			managementListenerScheme(listener.Addr()),
			address,
		)
	}
	errChannel := make(chan error, len(listeners))
	for _, listener := range listeners {
		go func(listener net.Listener) {
			errChannel <- serveManagementListener(server, listener, hostIdentity)
		}(listener)
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
	return parseServeOptionsWithAdvertiseIP(args, advertiseIP)
}

func parseServeOptionsWithAdvertiseIP(
	args []string,
	discover func() (string, error),
) (serveOptions, error) {
	listenValue := strings.TrimSpace(os.Getenv("WING_LINK_LISTEN"))
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
	if listenValue == "" {
		host, err := discover()
		if err != nil {
			return serveOptions{}, err
		}
		listenValue = net.JoinHostPort(host, fmt.Sprint(defaultWingLinkPort))
	}
	listenAddress, err := net.ResolveTCPAddr("tcp", listenValue)
	if err != nil || listenAddress.IP == nil {
		return serveOptions{}, errors.New("--listen must be a valid host:port")
	}
	if !isTrustedControlPlaneIP(listenAddress.IP) {
		return serveOptions{}, errors.New("--listen must use loopback, a private LAN, NetBird, or Tailscale")
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

func newWingLinkServer(profiles *profileBackend, state *StateStore) http.Handler {
	return newWingLinkServerWithBootstrap(profiles, state, nil)
}

func newWingLinkServerWithBootstrap(profiles *profileBackend, state *StateStore, bootstrap *BootstrapManager) http.Handler {
	operations, err := NewDurableOperationManager(
		filepath.Join(filepath.Dir(state.Path()), "wing-link-operations.json"),
	)
	if err != nil {
		operations = NewOperationManager()
	}
	return newWingLinkServerWithOperations(profiles, state, bootstrap, operations)
}

func newWingLinkServerWithOperations(profiles *profileBackend, state *StateStore, bootstrap *BootstrapManager, operations *OperationManager) http.Handler {
	hostFingerprint := ""
	if identity, err := state.HostIdentity(); err == nil {
		hostFingerprint = identity.Fingerprint
	}
	approvals, approvalErr := openApprovalStore(state.Path())
	auditLog, auditErr := openAuditLog(state.Path())
	localPairingProof, proofErr := ensureLocalPairingProof(state.Path())
	if approvalErr != nil || auditErr != nil || proofErr != nil {
		return http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
			writer.Header().Set("Cache-Control", "no-store")
			writer.Header().Set("Wing-Protocol", strconv.Itoa(ProtocolVersion))
			writeJSON(writer, http.StatusServiceUnavailable, map[string]any{
				"error": APIError{Code: "host_state_unavailable", Message: "Wing Link host state is unavailable"},
			})
		})
	}
	var directories *workspaces.Browser
	if directoryStore, err := openDirectoryGrantStore(state.Path()); err == nil {
		if _, err := directoryStore.List(); err == nil {
			directories = workspaces.NewBrowser(directoryStore, time.Now, randomSecret)
		}
	}
	return &wingLinkServer{
		profiles: profiles, bootstrap: bootstrap,
		operations: operations, approvals: approvals, audit: auditLog, state: state,
		directories: directories, hostFingerprint: hostFingerprint,
		localPairingProofHash: hashSecret(localPairingProof),
	}
}

func (server *wingLinkServer) ServeHTTP(writer http.ResponseWriter, request *http.Request) {
	if operation := auditOperationForRequest(request); operation != "" {
		started := time.Now()
		deviceID := "unauthenticated"
		if token, ok := bearerToken(request); ok {
			if authorization, authorized := server.state.AuthorizeDevice(token); authorized {
				deviceID = authorization.Device.ID
			}
		}
		audited := &auditResponseWriter{ResponseWriter: writer}
		writer = audited
		defer func() {
			status := audited.status
			if status == 0 {
				status = http.StatusOK
			}
			server.recordAudit(deviceID, operation, audit.SourceNone, auditResultForStatus(status), started)
		}()
	}
	writer.Header().Set("Cache-Control", "no-store")
	writer.Header().Set("Wing-Protocol", strconv.Itoa(ProtocolVersion))
	if request.URL.Path == "/meta" && request.Method == http.MethodGet {
		additionalCapabilities := []string(nil)
		if server.directories != nil {
			additionalCapabilities = []string{
				"directories.children.read",
				"directories.roots.read",
			}
		}
		writeJSON(
			writer,
			http.StatusOK,
			currentProtocolMetadata(
				version,
				server.hostFingerprint,
				additionalCapabilities...,
			),
		)
		return
	}
	generation, ok := requestProtocolGeneration(request)
	if !ok || !supportsProtocolGeneration(generation) {
		writeJSON(writer, http.StatusUpgradeRequired, map[string]any{
			"error":                       APIError{Code: "upgrade_required", Message: "Wing Link protocol generation is not supported"},
			"minimum_protocol_generation": MinimumProtocolGeneration,
			"protocol_generation":         ProtocolVersion,
		})
		return
	}
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
		if server.requireScopeAuthorization(writer, request, ScopeDeviceSelfRead, false) {
			writeJSON(writer, http.StatusOK, map[string]any{"acknowledged": true})
		}
		return
	}
	if request.URL.Path == "/v1/status" && request.Method == http.MethodGet {
		if server.requireScopeAuthorization(writer, request, ScopeHealthRead, true) {
			writeJSON(writer, http.StatusOK, map[string]any{"status": "ok", "protocol_version": ProtocolVersion})
		}
		return
	}
	if request.URL.Path == "/v2/devices/self" {
		server.serveDeviceSelf(writer, request)
		return
	}
	if server.serveDirectoryRoute(writer, request) {
		return
	}
	if request.URL.Path == "/v1/update/status" && request.Method == http.MethodGet {
		if !server.requireScopeAuthorization(writer, request, ScopeDiagnosticsRead, false) {
			return
		}
		server.updateStatus(writer)
		return
	}
	if request.URL.Path == "/v1/update/apply" && request.Method == http.MethodPost {
		authorization, ok := server.requireDeviceAuthorization(writer, request, ScopeLifecycleWrite, false)
		if !ok {
			return
		}
		server.applyUpdate(writer, request, authorization)
		return
	}
	if request.URL.Path == "/v1/setup" && request.Method == http.MethodPost {
		authorization, ok := server.requireDeviceAuthorization(writer, request, ScopeSetupWrite, false)
		if !ok {
			return
		}
		server.startBootstrap(writer, request, authorization)
		return
	}
	if id, ok := operationRoute(request.URL.Path); ok {
		switch request.Method {
		case http.MethodGet:
			if !server.requireScopeAuthorization(writer, request, ScopeDiagnosticsRead, true) {
				return
			}
			server.operationSnapshot(writer, id)
		case http.MethodDelete:
			if !server.requireScopeAuthorization(writer, request, ScopeLifecycleWrite, false) {
				return
			}
			if !server.operations.Cancel(id) {
				writer.WriteHeader(http.StatusNotFound)
				return
			}
			writer.WriteHeader(http.StatusNoContent)
		default:
			writer.WriteHeader(http.StatusMethodNotAllowed)
		}
		return
	}
	if wingLinkProfileCompatibilityEnabled && request.URL.Path == "/v1/profiles" {
		switch request.Method {
		case http.MethodGet:
			if !server.requireScopeAuthorization(writer, request, ScopeProfilesRead, true) {
				return
			}
			server.listProfiles(writer)
		case http.MethodPost:
			authorization, ok := server.requireDeviceAuthorization(writer, request, ScopeProfilesWrite, false)
			if !ok {
				return
			}
			server.createProfile(writer, request, authorization)
		default:
			writer.WriteHeader(http.StatusMethodNotAllowed)
		}
		return
	}
	if wingLinkProfileCompatibilityEnabled {
		if id, ok := profileRoute(request.URL.Path); ok {
			authorization, authorized := server.requireDeviceAuthorization(writer, request, ScopeProfilesWrite, false)
			if !authorized {
				return
			}
			switch request.Method {
			case http.MethodPatch:
				server.renameProfile(writer, request, id)
			case http.MethodDelete:
				server.deleteProfile(writer, request, id, authorization)
			default:
				writer.WriteHeader(http.StatusMethodNotAllowed)
			}
			return
		}
	}
	writer.WriteHeader(http.StatusNotFound)
}

func (server *wingLinkServer) serveDeviceSelf(writer http.ResponseWriter, request *http.Request) {
	token, ok := bearerToken(request)
	if !ok {
		writeJSON(writer, http.StatusUnauthorized, map[string]any{
			"error": APIError{Code: "unauthorized", Message: "Wing Link device credential required"},
		})
		return
	}
	scope := ScopeDeviceSelfRead
	if request.Method == http.MethodDelete {
		scope = ScopeDeviceSelfRevoke
	} else if request.Method != http.MethodGet {
		writer.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	authorization, ok := server.state.AuthorizeDevice(token, scope)
	if !ok {
		writeJSON(writer, http.StatusUnauthorized, map[string]any{
			"error": APIError{Code: "unauthorized", Message: "Wing Link device credential lacks the required grant"},
		})
		return
	}
	if request.Method == http.MethodDelete {
		if err := server.state.RevokeDevice(authorization.Device.ID); err != nil {
			writeJSON(writer, http.StatusConflict, map[string]any{
				"error": APIError{Code: "credential_unavailable", Message: "Device credential could not be revoked"},
			})
			return
		}
		writer.WriteHeader(http.StatusNoContent)
		return
	}
	device := authorization.Device
	payload := map[string]any{
		"device_id":  device.ID,
		"name":       device.Name,
		"scopes":     device.Scopes,
		"created_at": device.CreatedAt.Format(time.RFC3339),
		"legacy":     device.Legacy,
	}
	if !device.LastUsedAt.IsZero() {
		payload["last_used_at"] = device.LastUsedAt.Format(time.RFC3339)
	}
	if !device.ExpiresAt.IsZero() {
		payload["expires_at"] = device.ExpiresAt.Format(time.RFC3339)
	}
	writeJSON(writer, http.StatusOK, payload)
}

func (server *wingLinkServer) stageControlCredential(writer http.ResponseWriter, request *http.Request) {
	host, _, err := net.SplitHostPort(request.RemoteAddr)
	proof := request.Header.Get(localPairingProofHeader)
	if err != nil || !net.ParseIP(host).IsLoopback() || !validLocalPairingProof(proof) ||
		server.localPairingProofHash == "" || !matchesHash(proof, server.localPairingProofHash) {
		writeJSON(writer, http.StatusForbidden, map[string]any{
			"error": APIError{Code: "pairing_local_only", Message: "Local pairing authority is required"},
		})
		return
	}
	var payload struct {
		Name   string   `json:"name"`
		Scopes []string `json:"scopes"`
	}
	request.Body = http.MaxBytesReader(writer, request.Body, 8<<10)
	decoder := json.NewDecoder(request.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&payload); err != nil && !errors.Is(err, io.EOF) {
		writeJSON(writer, http.StatusBadRequest, map[string]any{
			"error": APIError{Code: "invalid_request", Message: "Pairing device metadata is invalid"},
		})
		return
	}
	var id, token string
	if strings.TrimSpace(payload.Name) == "" && len(payload.Scopes) == 0 {
		id, token, err = server.state.StageControlToken()
	} else {
		id, token, err = server.state.StageBearerDeviceCredential(payload.Name, payload.Scopes)
	}
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
	if authorization, active := server.state.AuthorizeDevice(token); active {
		if authorization.Device.ID != id {
			writeJSON(writer, http.StatusUnauthorized, map[string]any{
				"error": APIError{Code: "unauthorized", Message: "Credential acknowledgment did not match this device"},
			})
			return
		}
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

func (server *wingLinkServer) requireScopeAuthorization(
	writer http.ResponseWriter,
	request *http.Request,
	scope string,
	allowPending bool,
) bool {
	_, ok := server.requireDeviceAuthorization(writer, request, scope, allowPending)
	return ok
}

func (server *wingLinkServer) requireDeviceAuthorization(
	writer http.ResponseWriter,
	request *http.Request,
	scope string,
	allowPending bool,
) (DeviceAuthorization, bool) {
	token, present := bearerToken(request)
	if present {
		if authorization, ok := server.state.AuthorizeDevice(token, scope); ok {
			return authorization, true
		}
	}
	if present && allowPending && server.state.AuthorizePendingScope(token, scope) {
		return DeviceAuthorization{}, true
	}
	writeJSON(writer, http.StatusUnauthorized, map[string]any{
		"error": APIError{Code: "unauthorized", Message: "Wing Link control credential lacks the required grant"},
	})
	return DeviceAuthorization{}, false
}

func requestProtocolGeneration(request *http.Request) (int, bool) {
	value := strings.TrimSpace(request.Header.Get("Wing-Protocol"))
	if value == "" {
		return MinimumProtocolGeneration, true
	}
	generation, err := strconv.Atoi(value)
	return generation, err == nil
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

type profileCreateRequest struct {
	Name           string `json:"name"`
	CloneFrom      string `json:"clone_from"`
	Description    string `json:"description"`
	Provider       string `json:"provider"`
	Model          string `json:"model"`
	ProviderAPIKey string `json:"provider_api_key"`
}

func (server *wingLinkServer) createProfile(writer http.ResponseWriter, request *http.Request, authorization DeviceAuthorization) {
	var body profileCreateRequest
	if !decodeJSON(writer, request, &body) {
		return
	}
	if err := validateProfileSetup(
		body.Description, body.Provider, body.Model, body.ProviderAPIKey,
	); err != nil {
		writeProfileError(writer, err)
		return
	}
	payload, _ := json.Marshal(body)
	digest := sha256.Sum256(payload)
	operationName := ApprovalOpProfileCreate
	summary := "Create a profile"
	if strings.TrimSpace(body.ProviderAPIKey) != "" {
		operationName = ApprovalOpProfileCreateSecret
		summary = "Create a profile and write a provider secret"
	}
	operationID, allowed := server.approvalGate(
		writer, request, authorization, operationName,
		"/v1/profiles", hex.EncodeToString(digest[:]), summary,
	)
	if !allowed {
		return
	}
	started := time.Now()
	err := server.operations.RunReservedSync(operationID, func(context.Context, func(OperationEvent)) error {
		return server.performCreateProfile(writer, request, body)
	})
	if errors.Is(err, ErrOperationInProgress) {
		writeProfileError(writer, errProfileOperationBusy)
	}
	result := audit.ResultSuccess
	if err != nil {
		result = audit.ResultOperationFailed
	}
	server.recordAudit(authorization.Device.ID, operationName, audit.SourceHostCLI, result, started)
}

func (server *wingLinkServer) performCreateProfile(writer http.ResponseWriter, request *http.Request, body profileCreateRequest) error {
	if !server.profileMutations.TryLock() {
		writeProfileError(writer, errProfileOperationBusy)
		return errProfileOperationBusy
	}
	defer server.profileMutations.Unlock()
	row, createErr := server.profiles.create(request.Context(), body.Name, body.CloneFrom)
	createdProfileID := row.ID
	if createErr != nil {
		if createdProfileID != "" {
			if rollbackErr := server.rollbackCreatedProfile(request.Context(), createdProfileID); rollbackErr != nil {
				createErr = errors.Join(createErr, rollbackErr)
			}
		}
		writeProfileError(writer, createErr)
		return createErr
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
		return err
	}
	row.Description = strings.TrimSpace(body.Description)
	row.Model = strings.TrimSpace(body.Model)
	writeJSON(writer, http.StatusCreated, map[string]any{"profile": row})
	return nil
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

func (server *wingLinkServer) deleteProfile(writer http.ResponseWriter, request *http.Request, id string, authorization DeviceAuthorization) {
	revision := strings.TrimSpace(request.Header.Get("If-Match"))
	digest := sha256.Sum256([]byte(id + "\x00" + revision))
	operationID, allowed := server.approvalGate(
		writer, request, authorization, ApprovalOpProfileDelete,
		"/v1/profiles/"+id, hex.EncodeToString(digest[:]),
		"Delete profile "+id,
	)
	if !allowed {
		return
	}
	started := time.Now()
	err := server.operations.RunReservedSync(operationID, func(context.Context, func(OperationEvent)) error {
		if !server.profileMutations.TryLock() {
			writeProfileError(writer, errProfileOperationBusy)
			return errProfileOperationBusy
		}
		defer server.profileMutations.Unlock()
		if err := server.profiles.delete(request.Context(), id, revision); err != nil {
			writeProfileError(writer, err)
			return err
		}
		writeJSON(writer, http.StatusOK, map[string]any{"id": id, "deleted": true})
		return nil
	})
	if errors.Is(err, ErrOperationInProgress) {
		writeProfileError(writer, errProfileOperationBusy)
	}
	result := audit.ResultSuccess
	if err != nil {
		result = audit.ResultOperationFailed
	}
	server.recordAudit(authorization.Device.ID, ApprovalOpProfileDelete, audit.SourceHostCLI, result, started)
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

func hasControl(value string) bool {
	return strings.IndexFunc(value, unicode.IsControl) >= 0
}

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
	output := strings.TrimSpace(string(response))
	// HermesCLI._ensure_tirith_security prints this fixed notice on stdout even
	// with -Q. Remove this exception when supported Hermes versions keep quiet
	// stdout clean; arbitrary diagnostics and missing model replies still fail.
	const scannerNotice = "⚠ tirith security scanner enabled but not available — command scanning will use pattern matching only"
	if line, rest, ok := strings.Cut(output, "\n"); ok && strings.TrimSpace(line) == scannerNotice {
		output = strings.TrimSpace(rest)
	}
	if err != nil || !strings.EqualFold(output, "Hi") {
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
		observedErr := backend.observedFailureLocked(ctx, "create", id, "", cause)
		var observed *profileObservedError
		if errors.As(observedErr, &observed) && observed.outcome == "applied" {
			return profileRow{ID: id}, observedErr
		}
		return profileRow{}, observedErr
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
