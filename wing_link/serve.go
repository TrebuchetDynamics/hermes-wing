package main

import (
	"bytes"
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
	"time"
)

const defaultWingLinkPort = 8654

var profileIDPattern = regexp.MustCompile(`^[a-z0-9][a-z0-9_-]{0,63}$`)
var reservedProfileIDs = map[string]struct{}{
	"default": {}, "hermes": {}, "test": {}, "tmp": {}, "root": {}, "sudo": {},
}

type serveOptions struct {
	Listen       string
	Home         string
	Hermes       string
	StatePath    string
	HermesOrigin *url.URL
	HermesToken  string
}

type profileAction struct {
	Revision string `json:"revision"`
}

type profileActions struct {
	Rename *profileAction `json:"rename,omitempty"`
	Delete *profileAction `json:"delete,omitempty"`
}

type profileRow struct {
	ID               string         `json:"id"`
	Name             string         `json:"name"`
	Source           string         `json:"source"`
	Revision         string         `json:"revision"`
	TopologyRevision string         `json:"topology_revision"`
	APIRevision      string         `json:"api_revision,omitempty"`
	Description      string         `json:"description,omitempty"`
	Model            string         `json:"model,omitempty"`
	SkillsCount      int            `json:"skills_count,omitempty"`
	GatewayState     string         `json:"gateway_state"`
	Actions          profileActions `json:"actions"`
	localEvidence    bool
}

type profileBackend struct {
	home      string
	api       *hermesProfileAPI
	runHermes func(context.Context, ...string) error
	mu        sync.Mutex
	warnings  []string
}

type wingLinkServer struct {
	profiles   *profileBackend
	providers  *providerBackend
	bootstrap  *BootstrapManager
	operations *OperationManager
	state      *StateStore
}

// Hermes Agent is the sole profile/provider/configuration authority. The
// legacy adapters remain compiled only for rollback compatibility; Wing Link
// does not expose their routes.
const wingLinkDomainFallbacksEnabled = false

func serveCommand(stdout, stderr io.Writer, args []string) int {
	options, err := parseServeOptions(args)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "serve: %v\n", err)
		return 2
	}
	bootstrap := newProductionBootstrapManager(options.Home, options.Hermes)
	runHermes := bootstrap.RunHermes
	backend := &profileBackend{
		home:      options.Home,
		api:       newHermesProfileAPI(options.HermesOrigin, options.HermesToken),
		runHermes: runHermes,
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
			_, _ = fmt.Fprintf(stderr, "serve: %v\n", err)
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
	hermesToken := ""
	if hermes != "" {
		hermesToken, err = discoverHermesToken()
		if err != nil {
			return serveOptions{}, err
		}
	}
	return serveOptions{
		Listen: listenAddress.String(), Home: home, Hermes: hermes, StatePath: statePath,
		HermesOrigin: hermesOrigin, HermesToken: hermesToken,
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
	if wingLinkDomainFallbacksEnabled && request.URL.Path == "/v1/profiles" {
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
	if wingLinkDomainFallbacksEnabled && server.providers != nil && server.serveProviderRoute(writer, request) {
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
		Name      string `json:"name"`
		CloneFrom string `json:"clone_from"`
	}
	if !decodeJSON(writer, request, &body) {
		return
	}
	row, err := server.profiles.create(request.Context(), body.Name, body.CloneFrom)
	if err != nil {
		writeProfileError(writer, err)
		return
	}
	writeJSON(writer, http.StatusCreated, map[string]any{"profile": row})
}

func (server *wingLinkServer) renameProfile(writer http.ResponseWriter, request *http.Request, id string) {
	var body struct {
		Name     string `json:"name"`
		Revision string `json:"revision"`
	}
	if !decodeJSON(writer, request, &body) {
		return
	}
	revision := strings.TrimSpace(body.Revision)
	if revision == "" {
		revision = strings.TrimSpace(request.Header.Get("If-Match"))
	}
	row, err := server.profiles.rename(request.Context(), id, body.Name, revision)
	if err != nil {
		writeProfileError(writer, err)
		return
	}
	writeJSON(writer, http.StatusOK, map[string]any{"profile": row})
}

func (server *wingLinkServer) deleteProfile(writer http.ResponseWriter, request *http.Request, id string) {
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
	errProfileInvalidName   = errors.New("profile name is invalid")
	errProfileReserved      = errors.New("profile name is reserved")
	errProfileNotFound      = errors.New("profile not found")
	errProfileExists        = errors.New("profile already exists")
	errProfileChanged       = errors.New("profile inventory changed")
	errUnsafeProfilePath    = errors.New("profile path is not a regular local resource")
	errProfileAPIFailed     = errors.New("profile API failed")
	errProfileCLIFailed     = errors.New("profile CLI failed")
	errProfileOperationBusy = errors.New("profile operation in progress")
	errInventoryUnavailable = errors.New("profile inventory unavailable")
)

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
	rows, _, err := backend.mergedInventoryLocked(context.Background())
	return rows, append([]string(nil), backend.warnings...), err
}

func (backend *profileBackend) listLocalLocked() ([]profileRow, error) {
	backend.warnings = nil
	ids := []string{"default"}
	profilesRoot := filepath.Join(backend.home, "profiles")
	if err := requireRealDirectory(profilesRoot); err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return backend.rowsForIDs(ids), nil
		}
		return nil, err
	}
	entries, err := os.ReadDir(profilesRoot)
	if err != nil {
		return nil, err
	}
	for _, entry := range entries {
		id, idErr := normalizeProfileID(entry.Name())
		if idErr != nil || id != entry.Name() {
			if len(backend.warnings) < 8 {
				backend.warnings = append(backend.warnings, "Excluded a profile directory with an invalid name")
			}
			continue
		}
		if entry.Type()&os.ModeSymlink != 0 || !entry.IsDir() {
			return nil, errUnsafeProfilePath
		}
		if id != "default" {
			ids = append(ids, id)
		}
	}
	return backend.rowsForIDs(ids), nil
}

func (backend *profileBackend) mergedInventoryLocked(ctx context.Context) ([]profileRow, apiProfileCapabilities, error) {
	localRows, err := backend.listLocalLocked()
	if err != nil {
		return nil, apiProfileCapabilities{}, fmt.Errorf("%w: %v", errInventoryUnavailable, err)
	}
	if backend.api == nil {
		return localRows, apiProfileCapabilities{}, nil
	}
	apiInventory, err := backend.api.inventory(ctx)
	if err != nil {
		return nil, apiProfileCapabilities{}, fmt.Errorf("%w: %v", errProfileAPIFailed, err)
	}
	merged := make(map[string]profileRow, len(localRows)+len(apiInventory.rows))
	for _, row := range localRows {
		merged[row.ID] = row
	}
	for _, apiRow := range apiInventory.rows {
		if _, ok := merged[apiRow.ID]; ok {
			apiRow.Source = "both"
			apiRow.localEvidence = true
		}
		merged[apiRow.ID] = apiRow
	}
	ids := make([]string, 0, len(merged))
	for id := range merged {
		ids = append(ids, id)
	}
	sort.Strings(ids)
	inventory := strings.Join(ids, "\n")
	rows := make([]profileRow, 0, len(ids))
	for _, id := range ids {
		row := merged[id]
		topologyRevision := "wlp_" + hashSecret(inventory+"\x00"+id)
		row.Revision = topologyRevision
		row.TopologyRevision = topologyRevision
		if _, reserved := reservedProfileIDs[id]; reserved {
			row.Actions = profileActions{}
		}
		if row.localEvidence {
			if _, reserved := reservedProfileIDs[id]; !reserved {
				if row.Actions.Rename == nil || row.Actions.Rename.Revision != row.APIRevision {
					row.Actions.Rename = &profileAction{Revision: topologyRevision}
				}
				if row.Actions.Delete == nil || row.Actions.Delete.Revision != row.APIRevision {
					row.Actions.Delete = &profileAction{Revision: topologyRevision}
				}
			}
		}
		rows = append(rows, row)
	}
	return rows, apiInventory.capabilities, nil
}

func (backend *profileBackend) rowsForIDs(ids []string) []profileRow {
	sort.Strings(ids)
	inventory := strings.Join(ids, "\n")
	rows := make([]profileRow, 0, len(ids))
	for _, id := range ids {
		revision := "wlp_" + hashSecret(inventory+"\x00"+id)
		row := profileRow{
			ID: id, Name: id, Source: "wing_link", Revision: revision,
			TopologyRevision: revision, GatewayState: "unknown", localEvidence: true,
		}
		if _, reserved := reservedProfileIDs[id]; !reserved {
			row.Actions = profileActions{
				Rename: &profileAction{Revision: revision},
				Delete: &profileAction{Revision: revision},
			}
		}
		rows = append(rows, row)
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
	rows, capabilities, err := backend.mergedInventoryLocked(ctx)
	if err != nil {
		return profileRow{}, err
	}
	if _, exists := findProfileRow(rows, id); exists {
		return profileRow{}, errProfileExists
	}
	cloneIsLocalOnly := false
	if cloneID != "" {
		cloneRow, exists := findProfileRow(rows, cloneID)
		if !exists {
			return profileRow{}, errProfileNotFound
		}
		cloneIsLocalOnly = cloneRow.Source == "wing_link"
	}
	if capabilities.create && !cloneIsLocalOnly {
		if err := backend.api.create(ctx, id, cloneID); err != nil {
			cause := fmt.Errorf("%w: %v", errProfileAPIFailed, err)
			return profileRow{}, backend.observedFailureLocked(ctx, "create", id, "", cause)
		}
		return backend.rowAfterMutationLocked(ctx, id)
	}
	args := []string{"profile", "create", id, "--no-alias"}
	if cloneID != "" {
		args = append(args, "--clone-from", cloneID)
	}
	if err := backend.runHermes(ctx, args...); err != nil {
		cause := fmt.Errorf("%w: %v", errProfileCLIFailed, err)
		return profileRow{}, backend.observedFailureLocked(ctx, "create", id, "", cause)
	}
	return backend.rowAfterMutationLocked(ctx, id)
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
	rows, _, err := backend.mergedInventoryLocked(ctx)
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
	if row.APIRevision != "" && action.Revision == row.APIRevision {
		if err := backend.api.rename(ctx, currentID, replacementID, revision); err != nil {
			cause := fmt.Errorf("%w: %v", errProfileAPIFailed, err)
			return profileRow{}, backend.observedFailureLocked(ctx, "rename", currentID, replacementID, cause)
		}
		if renamed, err := backend.rowAfterMutationLocked(ctx, replacementID); err == nil {
			return renamed, nil
		}
		return backend.rowAfterMutationLocked(ctx, currentID)
	}
	if _, exists := findProfileRow(rows, replacementID); exists {
		return profileRow{}, errProfileExists
	}
	if err := backend.runHermes(ctx, "profile", "rename", currentID, replacementID); err != nil {
		cause := fmt.Errorf("%w: %v", errProfileCLIFailed, err)
		return profileRow{}, backend.observedFailureLocked(ctx, "rename", currentID, replacementID, cause)
	}
	return backend.rowAfterMutationLocked(ctx, replacementID)
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
	rows, _, err := backend.mergedInventoryLocked(ctx)
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
	if row.APIRevision != "" && action.Revision == row.APIRevision {
		if err := backend.api.delete(ctx, profileID, revision); err != nil {
			cause := fmt.Errorf("%w: %v", errProfileAPIFailed, err)
			return backend.observedFailureLocked(ctx, "delete", profileID, "", cause)
		}
		return backend.confirmDeletedLocked(ctx, profileID)
	}
	if err := backend.runHermes(ctx, "profile", "delete", "--yes", profileID); err != nil {
		cause := fmt.Errorf("%w: %v", errProfileCLIFailed, err)
		return backend.observedFailureLocked(ctx, "delete", profileID, "", cause)
	}
	return backend.confirmDeletedLocked(ctx, profileID)
}

func (backend *profileBackend) confirmDeletedLocked(ctx context.Context, id string) error {
	rows, _, err := backend.mergedInventoryLocked(ctx)
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
	if rows, _, err := backend.mergedInventoryLocked(ctx); err == nil {
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
	rows, _, err := backend.mergedInventoryLocked(ctx)
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

func requireRealDirectory(path string) error {
	info, err := os.Lstat(path)
	if err != nil {
		return err
	}
	if !info.IsDir() || info.Mode()&os.ModeSymlink != 0 {
		return errUnsafeProfilePath
	}
	return nil
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
	case errors.Is(err, errProfileReserved):
		status, code, message = http.StatusBadRequest, "profile_reserved", "Reserved profiles cannot be changed"
	case errors.Is(err, errProfileNotFound):
		status, code, message = http.StatusNotFound, "profile_not_found", "Profile not found"
	case errors.Is(err, errProfileExists):
		status, code, message = http.StatusConflict, "profile_already_exists", "Profile already exists"
	case errors.Is(err, errProfileChanged):
		status, code, message = http.StatusConflict, "profile_inventory_changed", "Profile inventory changed; refresh and retry"
	case errors.Is(err, errProfileOperationBusy):
		status, code, message = http.StatusConflict, "profile_operation_in_progress", "Another profile operation is in progress"
	case errors.Is(err, errProfileAPIFailed):
		status, code, message = http.StatusBadGateway, "profile_api_failed", "Hermes profile API operation failed"
	case errors.Is(err, errProfileCLIFailed):
		status, code, message = http.StatusBadGateway, "profile_cli_failed", "Hermes profile CLI operation failed"
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

type httpDoer interface {
	Do(*http.Request) (*http.Response, error)
}

type hermesProfileAPI struct {
	origin *url.URL
	token  string
	client httpDoer
}

type apiProfileCapabilities struct {
	list   bool
	create bool
	rename bool
	delete bool
}

type apiProfileInventory struct {
	rows         []profileRow
	capabilities apiProfileCapabilities
}

type apiEndpoint struct {
	Method         string   `json:"method"`
	Path           string   `json:"path"`
	RequiredScopes []string `json:"required_scopes"`
}

func newHermesProfileAPI(origin *url.URL, token string) *hermesProfileAPI {
	if origin == nil || strings.TrimSpace(token) == "" {
		return nil
	}
	return &hermesProfileAPI{
		origin: origin,
		token:  token,
		client: &http.Client{Timeout: 20 * time.Second},
	}
}

func (api *hermesProfileAPI) inventory(ctx context.Context) (apiProfileInventory, error) {
	capabilities, err := api.capabilities(ctx)
	if err != nil || !capabilities.list {
		return apiProfileInventory{capabilities: capabilities}, err
	}
	var envelope struct {
		Profiles []struct {
			ID             string `json:"id"`
			Name           string `json:"name"`
			Revision       string `json:"revision"`
			Description    string `json:"description"`
			Model          string `json:"model"`
			SkillsCount    int    `json:"skills_count"`
			GatewayRunning bool   `json:"gateway_running"`
		} `json:"data"`
	}
	if err := api.requestJSON(ctx, http.MethodGet, "/api/profiles", nil, "", &envelope); err != nil {
		return apiProfileInventory{}, err
	}
	rows := make([]profileRow, 0, len(envelope.Profiles))
	for _, profile := range envelope.Profiles {
		id, err := normalizeProfileID(profile.ID)
		if err != nil || id != strings.ToLower(profile.ID) {
			continue
		}
		state := "stopped"
		if profile.GatewayRunning {
			state = "running"
		}
		row := profileRow{
			ID: id, Name: strings.TrimSpace(profile.Name), Source: "api",
			Revision: profile.Revision, APIRevision: profile.Revision,
			Description: profile.Description, Model: profile.Model,
			SkillsCount: profile.SkillsCount, GatewayState: state,
		}
		if row.Name == "" {
			row.Name = id
		}
		if capabilities.rename && profile.Revision != "" {
			row.Actions.Rename = &profileAction{Revision: profile.Revision}
		}
		if capabilities.delete && id != "default" && profile.Revision != "" {
			row.Actions.Delete = &profileAction{Revision: profile.Revision}
		}
		rows = append(rows, row)
	}
	return apiProfileInventory{rows: rows, capabilities: capabilities}, nil
}

func (api *hermesProfileAPI) capabilities(ctx context.Context) (apiProfileCapabilities, error) {
	var document struct {
		SchemaVersion int `json:"schema_version"`
		Auth          struct {
			GrantedScopes []string `json:"granted_scopes"`
		} `json:"auth"`
		Endpoints map[string]apiEndpoint `json:"endpoints"`
	}
	if err := api.requestJSON(ctx, http.MethodGet, "/v1/capabilities", nil, "", &document); err != nil {
		return apiProfileCapabilities{}, err
	}
	if document.SchemaVersion != 1 {
		return apiProfileCapabilities{}, nil
	}
	granted := make(map[string]struct{}, len(document.Auth.GrantedScopes))
	for _, scope := range document.Auth.GrantedScopes {
		granted[scope] = struct{}{}
	}
	allows := func(scope string) bool {
		if _, ok := granted["*"]; ok {
			return true
		}
		_, ok := granted[scope]
		return ok
	}
	has := func(name, method, path, scope string) bool {
		endpoint, ok := document.Endpoints[name]
		if !ok || endpoint.Method != method || endpoint.Path != path || !allows(scope) {
			return false
		}
		for _, required := range endpoint.RequiredScopes {
			if required == scope {
				return true
			}
		}
		return len(endpoint.RequiredScopes) == 0
	}
	return apiProfileCapabilities{
		list:   has("profiles", http.MethodGet, "/api/profiles", "profiles:read"),
		create: has("profile_create", http.MethodPost, "/api/profiles", "profiles:write"),
		rename: has("profile_update", http.MethodPatch, "/api/profiles/{name}", "profiles:write"),
		delete: has("profile_delete", http.MethodDelete, "/api/profiles/{name}", "profiles:write"),
	}, nil
}

func (api *hermesProfileAPI) create(ctx context.Context, id, cloneFrom string) error {
	body := map[string]any{"name": id}
	if cloneFrom != "" {
		body["clone_from"] = cloneFrom
	}
	return api.requestJSON(ctx, http.MethodPost, "/api/profiles", body, "", &struct{}{})
}

func (api *hermesProfileAPI) rename(ctx context.Context, id, name, revision string) error {
	return api.requestJSON(
		ctx, http.MethodPatch, "/api/profiles/"+url.PathEscape(id),
		map[string]any{"name": name}, revision, &struct{}{},
	)
}

func (api *hermesProfileAPI) delete(ctx context.Context, id, revision string) error {
	var envelope struct {
		Deleted bool `json:"deleted"`
	}
	if err := api.requestJSON(
		ctx, http.MethodDelete, "/api/profiles/"+url.PathEscape(id),
		nil, revision, &envelope,
	); err != nil {
		return err
	}
	if !envelope.Deleted {
		return errors.New("hermes did not confirm profile deletion")
	}
	return nil
}

func (api *hermesProfileAPI) requestJSON(
	ctx context.Context,
	method, path string,
	body any,
	revision string,
	responseBody any,
) error {
	var payload io.Reader
	if body != nil {
		encoded, err := json.Marshal(body)
		if err != nil {
			return err
		}
		payload = bytes.NewReader(encoded)
	}
	endpoint := api.origin.ResolveReference(&url.URL{Path: path})
	request, err := http.NewRequestWithContext(ctx, method, endpoint.String(), payload)
	if err != nil {
		return err
	}
	request.Header.Set("Authorization", "Bearer "+api.token)
	request.Header.Set("Accept", "application/json")
	if body != nil {
		request.Header.Set("Content-Type", "application/json")
	}
	if revision != "" {
		request.Header.Set("If-Match", revision)
	}
	response, err := api.client.Do(request)
	if err != nil {
		return errors.New("hermes profile API request failed")
	}
	defer func() { _ = response.Body.Close() }()
	if response.StatusCode < 200 || response.StatusCode >= 300 {
		return fmt.Errorf("hermes profile API returned HTTP %d", response.StatusCode)
	}
	if responseBody == nil || response.StatusCode == http.StatusNoContent {
		return nil
	}
	decoder := json.NewDecoder(io.LimitReader(response.Body, 1<<20))
	if err := decoder.Decode(responseBody); err != nil {
		return errors.New("hermes profile API returned invalid data")
	}
	return nil
}
