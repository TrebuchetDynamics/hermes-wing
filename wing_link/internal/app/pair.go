package app

import (
	"bufio"
	"bytes"
	"context"
	"crypto/rand"
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
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/mdp/qrterminal/v3"
	"rsc.io/qr"
)

var errPairUsage = errors.New("invalid pair arguments")

type pairOptions struct {
	Origin               *url.URL
	ControlOrigin        *url.URL
	ControlState         *StateStore
	Label                string
	Token                string
	ScopedEnrollmentCode string
	CredentialMode       string
	Connections          []issuedHermesConnection
}

type issuedHermesConnection struct {
	ProfileID    string `json:"profile_id"`
	Origin       string `json:"origin"`
	Token        string `json:"token"`
	CredentialID string `json:"credential_id"`
	Label        string `json:"label"`
}

type issuedHermesEnrollment struct {
	Token        string                   `json:"token"`
	CredentialID string                   `json:"credential_id"`
	Connections  []issuedHermesConnection `json:"connections,omitempty"`
}

type apiEndpoint struct {
	Method         string   `json:"method"`
	Path           string   `json:"path"`
	RequiredScopes []string `json:"required_scopes"`
}

type pairingBroker struct {
	PairingURI *url.URL
	Done       <-chan struct{}
	server     *http.Server
	listener   net.Listener
	closeOnce  sync.Once
}

func (broker *pairingBroker) Close() {
	broker.closeOnce.Do(func() {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		_ = broker.server.Shutdown(ctx)
		_ = broker.listener.Close()
	})
}

func pairCommand(stdout, stderr io.Writer, args []string) int {
	options, err := parsePairOptions(args)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "pair: %v\n", err)
		if errors.Is(err, errPairUsage) {
			return 2
		}
		return 1
	}
	if err := EnsureWingLinkService(options.ControlOrigin, options.Origin); err != nil {
		_, _ = fmt.Fprintf(stderr, "pair: wing_link_service_unavailable: %v\n", err)
		return 1
	}
	broker, err := startPairingBroker(options)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "pair: %v\n", err)
		return 1
	}
	defer broker.Close()
	expiresAt := time.Now().Add(5 * time.Minute)
	_, _ = fmt.Fprintf(stderr, "pair: code valid for 5m0s at %s/v1/operator/enrollments/exchange\n", broker.PairingURI.Query().Get("broker"))
	if options.Origin.Scheme == "http" && !isLoopbackHost(options.Origin.Hostname()) {
		_, _ = fmt.Fprintln(stderr, "pair: plaintext HTTP requires confirmation in Wing; prefer a trusted VPN")
	}
	_, _ = fmt.Fprintf(stderr, "pair: label %q, Hermes %s, Wing Link %s\n", options.Label, options.Origin, options.ControlOrigin)
	_, _ = fmt.Fprintln(stderr, "pair:")
	_, _ = fmt.Fprintln(stderr, "pair: Connect on the phone with Hermes Wing:")
	_, _ = fmt.Fprintln(stderr, "pair:   1. Open Hermes Wing and choose Connect to Hermes.")
	_, _ = fmt.Fprintln(stderr, "pair:   2. Scan the QR code below, or share/paste this link into the app:")
	_, _ = fmt.Fprintf(stderr, "pair:      %s\n", broker.PairingURI.String())
	_, _ = fmt.Fprintln(stderr, "pair:   3. Review the label, endpoint, and access, then confirm.")
	_, _ = fmt.Fprintln(stderr, "pair: The link and code are single-use and expire in 5m.")
	_, _ = fmt.Fprintf(stderr, "pair: code: %s\n", broker.PairingURI.Query().Get("code"))
	qrterminal.GenerateHalfBlock(broker.PairingURI.String(), qr.M, stdout)

	timer := time.NewTimer(time.Until(expiresAt))
	defer timer.Stop()
	select {
	case <-broker.Done:
		_, _ = fmt.Fprintln(stderr, "pair: pairing complete")
		return 0
	case <-timer.C:
		_, _ = fmt.Fprintln(stderr, "pair: timed out without redemption")
		return 1
	}
}

func startPairingBroker(options pairOptions) (*pairingBroker, error) {
	brokerIP := net.ParseIP(options.Origin.Hostname())
	if brokerIP == nil {
		return nil, errors.New("pairing broker origin must be a local interface IP address")
	}
	if !brokerIP.IsLoopback() && os.Getenv("WING_LINK_PAIRING_OVER_ENCRYPTED_VPN") != "1" {
		return nil, errors.New("non-loopback pairing requires WING_LINK_PAIRING_OVER_ENCRYPTED_VPN=1 on an authenticated encrypted VPN")
	}
	code, err := randomSecret(24, "")
	if err != nil {
		return nil, err
	}
	expiresAt := time.Now().Add(5 * time.Minute)
	listener, err := net.Listen("tcp", net.JoinHostPort(options.Origin.Hostname(), "0"))
	if err != nil {
		return nil, errors.New("could not bind the Hermes LAN/VPN address; use --origin with a local interface address")
	}
	port := listener.Addr().(*net.TCPAddr).Port
	brokerOrigin := (&url.URL{
		Scheme: "http",
		Host:   net.JoinHostPort(options.Origin.Hostname(), strconv.Itoa(port)),
	}).String()
	query := url.Values{
		"origin":  {options.Origin.String()},
		"broker":  {brokerOrigin},
		"control": {options.ControlOrigin.String()},
		"code":    {code},
	}
	done := make(chan struct{})
	type issuedPairing struct {
		credentialID string
		controlToken string
		response     map[string]any
	}
	state := struct {
		sync.Mutex
		issued *issuedPairing
	}{}
	var watchOnce sync.Once
	mux := http.NewServeMux()
	handler := func(writer http.ResponseWriter, request *http.Request) {
		writer.Header().Set("Cache-Control", "no-store")
		writer.Header().Set("Content-Type", "application/json")
		if request.Method != http.MethodPost {
			writePairJSON(writer, http.StatusMethodNotAllowed, map[string]any{"error": "invalid request"})
			return
		}
		request.Body = http.MaxBytesReader(writer, request.Body, 4<<10)
		var payload struct {
			Origin string `json:"origin"`
			Code   string `json:"code"`
		}
		decoder := json.NewDecoder(request.Body)
		decoder.DisallowUnknownFields()
		if err := decoder.Decode(&payload); err != nil || payload.Origin != brokerOrigin || !matchesHash(payload.Code, hashSecret(code)) || !time.Now().Before(expiresAt) {
			writePairJSON(writer, http.StatusNotFound, map[string]any{"error": "pairing code unavailable"})
			return
		}
		state.Lock()
		defer state.Unlock()
		switch request.URL.Path {
		case "/v1/operator/enrollments/inspect":
			scopes := []string{"Full Hermes access", "Wing Link setup, lifecycle, health, and diagnostics"}
			accessLabel := "Full Hermes access"
			if options.CredentialMode == "scoped" {
				scopes = append(append([]string(nil), wingScopedHermesScopes...), "Wing Link setup, lifecycle, health, and diagnostics")
				accessLabel = "Scoped Hermes access"
			}
			writePairJSON(writer, http.StatusOK, map[string]any{
				"label":            options.Label,
				"origin":           options.Origin.String(),
				"wing_link_origin": options.ControlOrigin.String(),
				"credential_mode":  options.CredentialMode,
				"access_label":     accessLabel,
				"scopes":           scopes,
				"expires_at":       expiresAt.Unix(),
			})
		case "/v1/operator/enrollments/exchange":
			if state.issued == nil {
				// Stage the expiring, non-authoritative Wing Link credential first.
				// Consuming Hermes' one-time enrollment before this step could orphan
				// an active Hermes credential when control staging fails.
				var controlCredentialID, controlToken string
				var err error
				if options.ControlState != nil {
					controlCredentialID, controlToken, err = options.ControlState.StageControlToken()
				} else {
					controlCredentialID, controlToken, err = stageControlCredential(options.ControlOrigin)
				}
				if err != nil {
					writePairJSON(writer, http.StatusInternalServerError, map[string]any{"error": "could not issue Wing Link control token"})
					return
				}

				hermesIssued := issuedHermesEnrollment{
					Token: options.Token, CredentialID: "api_server_key",
					Connections: options.Connections,
				}
				if options.CredentialMode == "scoped" {
					hermesIssued, err = exchangeScopedHermesEnrollment(options)
					if err != nil {
						writePairJSON(writer, http.StatusBadGateway, map[string]any{"error": "could not exchange scoped Hermes enrollment"})
						return
					}
				}
				response := map[string]any{
					"token":                   hermesIssued.Token,
					"label":                   options.Label,
					"credential_id":           hermesIssued.CredentialID,
					"wing_link_origin":        options.ControlOrigin.String(),
					"wing_link_token":         controlToken,
					"wing_link_credential_id": controlCredentialID,
					"wing_link_scopes":        wingLinkControlScopes,
				}
				if len(hermesIssued.Connections) > 0 {
					response["connections"] = hermesIssued.Connections
				}
				state.issued = &issuedPairing{
					credentialID: controlCredentialID,
					controlToken: controlToken,
					response:     response,
				}
			}
			issued := state.issued
			writePairJSON(writer, http.StatusOK, issued.response)
			watchOnce.Do(func() {
				go waitForControlAcknowledgment(options, issued.controlToken, expiresAt, done)
			})
		default:
			writePairJSON(writer, http.StatusNotFound, map[string]any{"error": "not found"})
		}
	}
	mux.HandleFunc("/v1/operator/enrollments/inspect", handler)
	mux.HandleFunc("/v1/operator/enrollments/exchange", handler)
	server := &http.Server{
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
	}
	broker := &pairingBroker{
		PairingURI: &url.URL{Scheme: "wing", Host: "connect", RawQuery: query.Encode()},
		Done:       done,
		server:     server,
		listener:   listener,
	}
	go func() { _ = server.Serve(listener) }()
	return broker, nil
}

func waitForControlAcknowledgment(options pairOptions, token string, expiresAt time.Time, done chan<- struct{}) {
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()
	for time.Now().Before(expiresAt) {
		authorized := false
		if options.ControlState != nil {
			authorized = options.ControlState.Authorize(token)
		} else {
			authorized = controlTokenAuthorized(options.ControlOrigin, token)
		}
		if authorized {
			close(done)
			return
		}
		<-ticker.C
	}
}

func controlTokenAuthorized(controlOrigin *url.URL, token string) bool {
	request, err := http.NewRequest(http.MethodGet, controlOrigin.ResolveReference(&url.URL{Path: "/v1/pairing/acknowledged"}).String(), nil)
	if err != nil {
		return false
	}
	request.Header.Set("Authorization", "Bearer "+token)
	response, err := (&http.Client{Timeout: 2 * time.Second}).Do(request)
	if err != nil {
		return false
	}
	defer func() { _ = response.Body.Close() }()
	return response.StatusCode == http.StatusOK
}

func writePairJSON(writer http.ResponseWriter, status int, payload map[string]any) {
	writer.WriteHeader(status)
	_ = json.NewEncoder(writer).Encode(payload)
}

func parsePairOptions(args []string) (pairOptions, error) {
	label, err := os.Hostname()
	if err != nil || strings.TrimSpace(label) == "" {
		label = "Hermes Wing"
	}
	originValue := strings.TrimSpace(os.Getenv("WING_HERMES_URL"))
	remote := false
	for index := 0; index < len(args); index++ {
		switch args[index] {
		case "--remote", "--lan":
			remote = true
		case "--local":
			remote = false
		case "--origin":
			index++
			if index >= len(args) {
				return pairOptions{}, fmt.Errorf("%w: --origin requires a URL", errPairUsage)
			}
			originValue = args[index]
		case "--label":
			index++
			if index >= len(args) || strings.TrimSpace(args[index]) == "" {
				return pairOptions{}, fmt.Errorf("%w: --label requires a value", errPairUsage)
			}
			label = strings.TrimSpace(args[index])
		default:
			return pairOptions{}, fmt.Errorf("%w: unknown option %s", errPairUsage, args[index])
		}
	}
	if len([]rune(label)) > 80 {
		return pairOptions{}, fmt.Errorf("%w: --label must be at most 80 characters", errPairUsage)
	}
	if originValue == "" {
		host, hostErr := pairingAdvertiseHost(remote)
		if hostErr != nil {
			return pairOptions{}, hostErr
		}
		port := 8642
		if value := strings.TrimSpace(os.Getenv("WING_HERMES_PORT")); value != "" {
			port, err = strconv.Atoi(value)
			if err != nil || port < 1 || port > 65535 {
				return pairOptions{}, errors.New("WING_HERMES_PORT must be a valid TCP port")
			}
		}
		originValue = "http://" + net.JoinHostPort(host, strconv.Itoa(port))
	}
	origin, err := normalizeOrigin(originValue)
	if err != nil {
		return pairOptions{}, err
	}
	if err := requireTrustedOriginHost(origin.Hostname()); err != nil {
		return pairOptions{}, err
	}
	originIP := net.ParseIP(origin.Hostname())
	if originIP != nil && !originIP.IsLoopback() && !remote {
		return pairOptions{}, fmt.Errorf("%w: non-loopback pairing requires --remote", errPairUsage)
	}
	controlValue := strings.TrimSpace(os.Getenv("WING_LINK_URL"))
	if controlValue == "" {
		controlValue = origin.Scheme + "://" + net.JoinHostPort(origin.Hostname(), strconv.Itoa(defaultWingLinkPort))
	}
	controlOrigin, err := normalizeOrigin(controlValue)
	if err != nil {
		return pairOptions{}, fmt.Errorf("invalid Wing Link control origin: %w", err)
	}
	if !strings.EqualFold(controlOrigin.Hostname(), origin.Hostname()) {
		return pairOptions{}, errors.New("control origin must use the Hermes host")
	}
	externalService := strings.EqualFold(strings.TrimSpace(os.Getenv("WING_LINK_SERVICE")), "external")
	if controlOrigin.Port() != strconv.Itoa(defaultWingLinkPort) && !externalService {
		return pairOptions{}, fmt.Errorf("wing link control origin must use port %d", defaultWingLinkPort)
	}
	if controlOrigin.Scheme == "https" && !externalService {
		return pairOptions{}, errors.New("https wing link origins require an externally managed TLS service")
	}
	if err := requireTrustedOriginHost(controlOrigin.Hostname()); err != nil {
		return pairOptions{}, err
	}
	token, err := discoverHermesToken()
	if err != nil {
		return pairOptions{}, err
	}
	scopedCode, scopedAdvertised, err := createScopedHermesEnrollment(origin, token, label)
	if err != nil {
		return pairOptions{}, err
	}
	credentialMode := "compatibility_full_access"
	var connections []issuedHermesConnection
	if scopedAdvertised {
		credentialMode = "scoped"
	} else {
		issued, err := compatibilityHermesEnrollment(origin, token, label)
		if err != nil {
			return pairOptions{}, err
		}
		connections = issued.Connections
		if err := ensureHermesProfileMultiplex(origin, token, connections); err != nil {
			return pairOptions{}, err
		}
	}
	return pairOptions{
		Origin: origin, ControlOrigin: controlOrigin,
		Label: label, Token: token,
		ScopedEnrollmentCode: scopedCode, CredentialMode: credentialMode,
		Connections: connections,
	}, nil
}

func pairingAdvertiseHost(remote bool) (string, error) {
	if !remote {
		return "127.0.0.1", nil
	}
	return advertiseIP()
}

var wingLinkControlScopes = []string{
	"setup:write", "lifecycle:write", "health:read", "diagnostics:read",
}

var wingScopedHermesScopes = []string{
	"chat:write", "sessions:read", "sessions:write", "runs:read", "runs:write",
	"approvals:write", "profiles:read", "profiles:write", "providers:read",
	"providers:write", "models:read", "models:write", "skills:read",
	"tools:read", "jobs:read", "health:read",
}

func createScopedHermesEnrollment(origin *url.URL, token, label string) (string, bool, error) {
	client := &http.Client{Timeout: 10 * time.Second}
	var capabilities struct {
		Endpoints map[string]apiEndpoint `json:"endpoints"`
		Auth      struct {
			GrantedScopes []string `json:"granted_scopes"`
		} `json:"auth"`
	}
	if err := pairJSONRequest(client, origin, token, http.MethodGet, "/v1/capabilities", nil, &capabilities); err != nil {
		return "", false, fmt.Errorf("inspect Hermes enrollment capabilities: %w", err)
	}
	endpoint, advertised := capabilities.Endpoints["operator_enrollment_create"]
	if !advertised || endpoint.Method != http.MethodPost || endpoint.Path != "/v1/operator/enrollments" {
		return "", false, nil
	}
	grantedScopes := make(map[string]struct{}, len(capabilities.Auth.GrantedScopes))
	for _, scope := range capabilities.Auth.GrantedScopes {
		grantedScopes[scope] = struct{}{}
	}
	_, wildcard := grantedScopes["*"]
	for _, scope := range endpoint.RequiredScopes {
		if _, granted := grantedScopes[scope]; !granted && !wildcard {
			return "", true, fmt.Errorf("hermes credential lacks required enrollment scope %q", scope)
		}
	}
	var response struct {
		PairingURI string `json:"pairing_uri"`
	}
	if err := pairJSONRequest(client, origin, token, http.MethodPost, endpoint.Path, map[string]any{
		"label": label, "origin": origin.String(), "scopes": wingScopedHermesScopes,
	}, &response); err != nil {
		return "", true, err
	}
	pairingURI, err := url.Parse(response.PairingURI)
	if err != nil || pairingURI.Query().Get("code") == "" {
		return "", true, errors.New("hermes scoped enrollment returned invalid data")
	}
	return pairingURI.Query().Get("code"), true, nil
}

func ensureHermesProfileMultiplex(origin *url.URL, token string, connections []issuedHermesConnection) error {
	if len(connections) == 0 {
		return errors.New("hermes profile inventory is empty")
	}
	if hermesProfileMultiplexReady(origin, token, connections) {
		return nil
	}
	hermes, err := exec.LookPath("hermes")
	if err != nil {
		return errors.New("could not find Hermes profile CLI")
	}
	commands := [][]string{
		{"config", "set", "--force", "gateway.multiplex_profiles", "true"},
		{"gateway", "restart"},
	}
	for _, args := range commands {
		result := runProcess(context.Background(), CommandSpec{
			Path: hermes, Args: args, Timeout: 90 * time.Second,
		}, nil)
		if result.Err != nil {
			return errors.New("could not enable Hermes profile routing")
		}
	}
	deadline := time.Now().Add(30 * time.Second)
	for time.Now().Before(deadline) {
		if hermesProfileMultiplexReady(origin, token, connections) {
			return nil
		}
		time.Sleep(250 * time.Millisecond)
	}
	return errors.New("hermes profile routing did not become ready")
}

func hermesProfileMultiplexReady(origin *url.URL, token string, connections []issuedHermesConnection) bool {
	if pairRequestStatus(origin, token, "/p/wing-link-invalid-probe/v1/capabilities") != http.StatusNotFound {
		return false
	}
	for _, connection := range connections {
		if pairRequestStatus(origin, connection.Token, "/p/"+connection.ProfileID+"/v1/capabilities") != http.StatusOK {
			return false
		}
	}
	return true
}

func pairRequestStatus(origin *url.URL, token, path string) int {
	request, err := http.NewRequest(http.MethodGet, origin.ResolveReference(&url.URL{Path: path}).String(), nil)
	if err != nil {
		return 0
	}
	request.Header.Set("Authorization", "Bearer "+token)
	response, err := (&http.Client{Timeout: 2 * time.Second}).Do(request)
	if err != nil {
		return 0
	}
	defer func() { _ = response.Body.Close() }()
	return response.StatusCode
}

func parseHermesProfileList(output []byte) ([]profileRow, error) {
	scanner := bufio.NewScanner(bytes.NewReader(output))
	scanner.Buffer(make([]byte, 4096), 256<<10)
	rows := make([]profileRow, 0)
	seen := make(map[string]struct{})
	phase := 0
	for scanner.Scan() {
		fields := strings.Fields(scanner.Text())
		if len(fields) == 0 {
			continue
		}
		switch phase {
		case 0:
			if strings.Join(fields, " ") != "Profile Model Gateway Alias Distribution" {
				return nil, errors.New("hermes profile list returned invalid header")
			}
			phase = 1
			continue
		case 1:
			if !isHermesProfileListSeparator(fields) {
				return nil, errors.New("hermes profile list returned invalid separator")
			}
			phase = 2
			continue
		}
		if len(fields) != 5 ||
			(fields[2] != "running" && fields[2] != "stopped") {
			return nil, errors.New("hermes profile list returned invalid row")
		}
		state := fields[2]
		model := fields[1]
		if model == "—" {
			model = ""
		}
		rawID := strings.TrimPrefix(fields[0], "◆")
		id, err := normalizeProfileID(rawID)
		if err != nil || id != rawID {
			return nil, errors.New("hermes profile list returned invalid data")
		}
		if _, duplicate := seen[id]; duplicate {
			return nil, errors.New("hermes profile list returned duplicate profiles")
		}
		seen[id] = struct{}{}
		rows = append(rows, profileRow{ID: id, Name: id, Model: model, GatewayState: state})
	}
	if err := scanner.Err(); err != nil || phase != 2 || len(rows) == 0 {
		return nil, errors.New("hermes profile list returned invalid data")
	}
	return rows, nil
}

func isHermesProfileListSeparator(fields []string) bool {
	if len(fields) != 5 {
		return false
	}
	for _, field := range fields {
		if field == "" {
			return false
		}
		for _, character := range field {
			if character != '─' {
				return false
			}
		}
	}
	return true
}

func compatibilityHermesEnrollment(origin *url.URL, token, label string) (issuedHermesEnrollment, error) {
	hermes, err := exec.LookPath("hermes")
	if err != nil {
		return issuedHermesEnrollment{}, errors.New("could not find Hermes profile CLI")
	}
	output, result := runProcessCapture(context.Background(), CommandSpec{
		Path: hermes, Args: []string{"profile", "list"}, Timeout: 30 * time.Second,
	}, 256<<10)
	if result.Err != nil {
		return issuedHermesEnrollment{}, errors.New("could not list Hermes profiles")
	}
	rows, err := parseHermesProfileList(output)
	if err != nil {
		return issuedHermesEnrollment{}, err
	}
	sort.Slice(rows, func(left, right int) bool { return rows[left].ID < rows[right].ID })
	connections := make([]issuedHermesConnection, 0, len(rows))
	for _, row := range rows {
		profileToken := token
		if row.ID != "default" {
			profileToken, err = hermesProfileToken(hermes, row.ID)
			if err != nil {
				return issuedHermesEnrollment{}, err
			}
		}
		profileOrigin := *origin
		profileOrigin.Path = "/p/" + row.ID
		connections = append(connections, issuedHermesConnection{
			ProfileID: row.ID, Origin: profileOrigin.String(), Token: profileToken,
			CredentialID: "api_server_key:" + row.ID,
			Label:        label + " · " + row.ID,
		})
	}
	return issuedHermesEnrollment{
		Token: token, CredentialID: "api_server_key", Connections: connections,
	}, nil
}

func hermesProfileToken(hermes, profileID string) (string, error) {
	output, result := runProcessCapture(context.Background(), CommandSpec{
		Path: hermes, Args: []string{"--profile", profileID, "config", "env-path"},
		Timeout: 30 * time.Second,
	}, 4096)
	path := strings.TrimSpace(string(output))
	home, err := defaultHermesHome()
	if result.Err != nil || err != nil || !filepath.IsAbs(path) ||
		strings.ContainsAny(path, "\r\n") || !pathWithin(home, path) ||
		rejectSymlinkedAncestors(filepath.Dir(path)) != nil {
		return "", errors.New("hermes profile credential path is unavailable")
	}
	token, err := ensureHermesTokenFile(path)
	if err != nil {
		return "", errors.New("could not prepare Hermes profile credential")
	}
	return token, nil
}

func exchangeScopedHermesEnrollment(options pairOptions) (issuedHermesEnrollment, error) {
	var response issuedHermesEnrollment
	err := pairJSONRequest(
		&http.Client{Timeout: 10 * time.Second}, options.Origin, "", http.MethodPost,
		"/v1/operator/enrollments/exchange",
		map[string]any{"origin": options.Origin.String(), "code": options.ScopedEnrollmentCode},
		&response,
	)
	if err != nil || response.Token == "" {
		return issuedHermesEnrollment{}, errors.New("scoped Hermes enrollment exchange failed")
	}
	return response, nil
}

func stageControlCredential(controlOrigin *url.URL) (string, string, error) {
	var response struct {
		CredentialID string `json:"credential_id"`
		Token        string `json:"token"`
	}
	loopbackHost := "127.0.0.1"
	if strings.Contains(controlOrigin.Hostname(), ":") {
		loopbackHost = "::1"
	}
	loopbackOrigin := &url.URL{Scheme: controlOrigin.Scheme, Host: net.JoinHostPort(loopbackHost, controlOrigin.Port())}
	if err := pairJSONRequest(
		&http.Client{Timeout: 10 * time.Second}, loopbackOrigin, "", http.MethodPost,
		"/v1/pairing/control-credentials", struct{}{}, &response,
	); err != nil || response.CredentialID == "" || response.Token == "" {
		return "", "", errors.New("wing link control credential staging failed")
	}
	return response.CredentialID, response.Token, nil
}

func pairJSONRequest(client *http.Client, origin *url.URL, token, method, path string, body any, target any) error {
	var payload io.Reader
	if body != nil {
		encoded, err := json.Marshal(body)
		if err != nil {
			return err
		}
		payload = bytes.NewReader(encoded)
	}
	request, err := http.NewRequest(method, origin.ResolveReference(&url.URL{Path: path}).String(), payload)
	if err != nil {
		return err
	}
	if token != "" {
		request.Header.Set("Authorization", "Bearer "+token)
	}
	request.Header.Set("Content-Type", "application/json")
	response, err := client.Do(request)
	if err != nil {
		return errors.New("hermes enrollment request failed")
	}
	defer func() { _ = response.Body.Close() }()
	if response.StatusCode < 200 || response.StatusCode >= 300 {
		return fmt.Errorf("hermes enrollment returned HTTP %d", response.StatusCode)
	}
	if err := json.NewDecoder(io.LimitReader(response.Body, 1<<20)).Decode(target); err != nil {
		return errors.New("hermes enrollment returned invalid data")
	}
	return nil
}

func discoverHermesToken() (string, error) {
	if token := strings.TrimSpace(os.Getenv("WING_HERMES_TOKEN")); token != "" {
		return token, nil
	}
	hermes, err := exec.LookPath("hermes")
	if err != nil {
		return "", errors.New("could not find the local Hermes API key; install/configure Hermes or set WING_HERMES_TOKEN")
	}
	output, result := runProcessCapture(context.Background(), CommandSpec{
		Path:    hermes,
		Args:    []string{"config", "env-path"},
		Timeout: 5 * time.Second,
	}, 4096)
	path := strings.TrimSpace(string(output))
	home, homeErr := resolveHermesHome()
	if result.Err == nil && homeErr == nil && filepath.IsAbs(path) &&
		!strings.ContainsAny(path, "\r\n") && pathWithin(home, path) &&
		rejectSymlinkedAncestors(path) == nil {
		if token, err := ensureHermesTokenFile(path); err == nil {
			return token, nil
		}
	}
	return "", errors.New("could not prepare the local Hermes API key")
}

func ensureHermesTokenFile(path string) (string, error) {
	if token, err := readHermesTokenFile(path); err == nil {
		return token, nil
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return "", errors.New("hermes environment directory is unavailable")
	}
	unlock, err := acquireStateLock(path + ".wing-link.lock")
	if err != nil {
		return "", errors.New("could not lock the Hermes environment file")
	}
	defer func() { _ = unlock() }()
	if token, err := readHermesTokenFile(path); err == nil {
		return token, nil
	}
	info, err := os.Lstat(path)
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return "", errors.New("hermes environment file is unavailable")
	}
	if err == nil && !info.Mode().IsRegular() {
		return "", errors.New("hermes environment file is unavailable")
	}
	contents, err := os.ReadFile(path)
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return "", errors.New("hermes environment file is unavailable")
	}
	keyBytes := make([]byte, 32)
	if _, err := rand.Read(keyBytes); err != nil {
		return "", errors.New("could not generate a Hermes API key")
	}
	token := hex.EncodeToString(keyBytes)
	prefix := ""
	if len(contents) > 0 && contents[len(contents)-1] != '\n' {
		prefix = "\n"
	}
	payload := append([]byte(nil), contents...)
	payload = fmt.Appendf(payload, "%sAPI_SERVER_KEY=%s\n", prefix, token)
	if err := writeHermesTokenFile(path, payload); err != nil {
		return "", err
	}
	return token, nil
}

func writeHermesTokenFile(path string, payload []byte) error {
	temp, err := os.CreateTemp(filepath.Dir(path), ".hermes-env-*")
	if err != nil {
		return errors.New("could not stage the Hermes API key")
	}
	tempPath := temp.Name()
	defer func() { _ = os.Remove(tempPath) }()
	if err := secureStatePath(tempPath, false); err != nil {
		_ = temp.Close()
		return errors.New("could not secure the Hermes environment file")
	}
	if _, err := temp.Write(payload); err != nil {
		_ = temp.Close()
		return errors.New("could not save the Hermes API key")
	}
	if err := temp.Sync(); err != nil {
		_ = temp.Close()
		return errors.New("could not save the Hermes API key")
	}
	if err := temp.Close(); err != nil {
		return errors.New("could not save the Hermes API key")
	}
	if err := replaceStateFile(tempPath, path); err != nil {
		return errors.New("could not save the Hermes API key")
	}
	if err := syncStateDirectory(filepath.Dir(path)); err != nil {
		return errors.New("could not save the Hermes API key")
	}
	return nil
}

func readHermesTokenFile(path string) (string, error) {
	info, err := os.Lstat(path)
	if err != nil || !info.Mode().IsRegular() {
		return "", errors.New("hermes environment file is unavailable")
	}
	file, err := os.Open(path)
	if err != nil {
		return "", errors.New("hermes environment file is unavailable")
	}
	defer func() { _ = file.Close() }()
	scanner := bufio.NewScanner(file)
	scanner.Buffer(make([]byte, 4096), 64<<10)
	for scanner.Scan() {
		line := strings.TrimSpace(strings.TrimPrefix(strings.TrimSpace(scanner.Text()), "export "))
		key, value, ok := strings.Cut(line, "=")
		if !ok || strings.TrimSpace(key) != "API_SERVER_KEY" {
			continue
		}
		value = parseHermesEnvValue(value)
		if value != "" {
			return value, nil
		}
	}
	return "", errors.New("hermes API key is not configured")
}

func parseHermesEnvValue(value string) string {
	value = strings.TrimSpace(value)
	if len(value) >= 2 && (value[0] == '\'' || value[0] == '"') {
		if end := strings.IndexByte(value[1:], value[0]); end >= 0 {
			return value[1 : end+1]
		}
	}
	for _, marker := range []string{" #", "\t#"} {
		if index := strings.Index(value, marker); index >= 0 {
			value = value[:index]
		}
	}
	return strings.TrimSpace(value)
}

func normalizeOrigin(value string) (*url.URL, error) {
	origin, err := url.Parse(strings.TrimSpace(value))
	if err != nil || origin.Host == "" || origin.User != nil || (origin.Scheme != "http" && origin.Scheme != "https") || (origin.Path != "" && origin.Path != "/") || origin.RawQuery != "" || origin.Fragment != "" {
		return nil, errors.New("origin must be an http(s) origin without credentials, path, query, or fragment")
	}
	if !validURLPort(origin) {
		return nil, errors.New("origin must use a valid TCP port")
	}
	if ip := net.ParseIP(origin.Hostname()); ip != nil && ip.IsUnspecified() {
		return nil, errors.New("origin must identify one interface, not a wildcard address")
	}
	return &url.URL{Scheme: origin.Scheme, Host: origin.Host}, nil
}

func validURLPort(value *url.URL) bool {
	port := value.Port()
	if port == "" {
		return true
	}
	number, err := strconv.Atoi(port)
	return err == nil && number >= 1 && number <= 65535
}

// advertiseIP prefers Tailscale, then the first private LAN address.
func advertiseIP() (string, error) {
	addresses, err := net.InterfaceAddrs()
	if err != nil {
		return "", fmt.Errorf("discover network address: %w", err)
	}
	return preferredPairingIP(addresses)
}

func preferredPairingIP(addresses []net.Addr) (string, error) {
	fallback := ""
	for _, address := range addresses {
		network, ok := address.(*net.IPNet)
		if !ok {
			continue
		}
		ip := network.IP
		if ip == nil || ip.IsLoopback() || !ip.IsGlobalUnicast() {
			continue
		}
		if ipv4 := ip.To4(); ipv4 != nil && ipv4[0] == 100 && ipv4[1] >= 64 && ipv4[1] <= 127 {
			return ipv4.String(), nil
		}
		if ip.IsPrivate() && fallback == "" {
			fallback = ip.String()
		}
	}
	if fallback == "" {
		return "", errors.New("no LAN/VPN address found; use --local or --origin")
	}
	return fallback, nil
}

func requireTrustedOriginHost(host string) error {
	if strings.EqualFold(host, "localhost") {
		return nil
	}
	addresses, err := net.LookupIP(host)
	if err != nil || len(addresses) == 0 {
		return errors.New("pairing origin host could not be resolved")
	}
	for _, address := range addresses {
		if !isTrustedControlPlaneIP(address) {
			return errors.New("pairing origins must use loopback, a private LAN, or Tailscale")
		}
		if !isLocalInterfaceIP(address) {
			return errors.New("pairing origin is not assigned to this host")
		}
	}
	return nil
}

func isLoopbackHost(host string) bool {
	return strings.EqualFold(host, "localhost") || net.ParseIP(host).IsLoopback()
}
