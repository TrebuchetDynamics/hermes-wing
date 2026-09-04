package app

import (
	"bufio"
	"bytes"
	"context"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
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
	HostIdentity         HostIdentity
	Label                string
	Token                string
	ScopedEnrollmentCode string
	CredentialMode       string
	Connections          []issuedHermesConnection
	PrintLink            bool
	PrintQR              bool
	SameDevice           bool
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
	PairingURI     *url.URL
	OpenURL        *url.URL
	TLSCertificate *x509.Certificate
	Done           <-chan struct{}
	server         *http.Server
	listener       net.Listener
	closeOnce      sync.Once
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
	writePairHumanOutput(stdout, stderr, broker, options)

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

func writePairHumanOutput(stdout, stderr io.Writer, broker *pairingBroker, options pairOptions) {
	_, _ = fmt.Fprintln(stderr, "pair: Pair with Hermes Wing (expires in 5 minutes)")
	_, _ = fmt.Fprintln(stderr, "pair:")
	if options.SameDevice {
		_, _ = fmt.Fprintln(stderr, "pair: Open this local link on the same device:")
		if broker.OpenURL != nil {
			_, _ = fmt.Fprintln(stdout, broker.OpenURL.String())
		}
		_, _ = fmt.Fprintln(stderr, "pair: Review the host and access in Hermes Wing, then confirm.")
		_, _ = fmt.Fprintln(stderr, "pair: Leave this command running; it exits after confirmation. Press Ctrl-C to cancel.")
		return
	}
	if broker.OpenURL != nil {
		_, _ = fmt.Fprintln(stderr, "pair: On the same device, open:")
		_, _ = fmt.Fprintf(stderr, "pair:   %s\n", broker.OpenURL)
		_, _ = fmt.Fprintln(stderr, "pair:")
	}
	if options.PrintLink {
		_, _ = fmt.Fprintln(stderr, "pair: In Hermes Wing, choose Paste pairing link and paste this single-use link:")
		_, _ = fmt.Fprintln(stdout, broker.PairingURI.String())
	}
	if options.PrintQR {
		_, _ = fmt.Fprintln(stderr, "pair: Scan this QR in Hermes Wing:")
		qrterminal.GenerateHalfBlock(broker.PairingURI.String(), qr.M, stdout)
	}
	_, _ = fmt.Fprintln(stderr, "pair:")
	_, _ = fmt.Fprintln(stderr, "pair: Leave this command running; it exits after confirmation. Press Ctrl-C to cancel.")
	_, _ = fmt.Fprintln(stderr, "pair: Review the host, access, and profile count in Hermes Wing, then confirm.")
	if options.Origin.Scheme == "http" && !isLoopbackHost(options.Origin.Hostname()) {
		_, _ = fmt.Fprintln(stderr, "pair: Plaintext HTTP requires confirmation in Wing; prefer a trusted VPN.")
	}
}

func startPairingBroker(options pairOptions) (*pairingBroker, error) {
	if options.CredentialMode == "compatibility_full_access" && len(options.Connections) > 100 {
		return nil, errors.New("compatibility pairing supports at most 100 connections")
	}
	brokerIP := net.ParseIP(options.Origin.Hostname())
	if brokerIP == nil {
		return nil, errors.New("pairing broker origin must be a local interface IP address")
	}
	hostIdentity := options.HostIdentity
	if hostIdentity.Fingerprint == "" && options.ControlState != nil {
		var err error
		hostIdentity, err = options.ControlState.HostIdentity()
		if err != nil {
			return nil, errors.New("could not initialize pairing host identity")
		}
	}
	if hostIdentity.Fingerprint == "" {
		return nil, errors.New("pairing host identity is unavailable")
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
	brokerScheme := "http"
	if !brokerIP.IsLoopback() {
		brokerScheme = "https"
	}
	brokerOriginURL := &url.URL{
		Scheme: brokerScheme,
		Host:   net.JoinHostPort(options.Origin.Hostname(), strconv.Itoa(port)),
	}
	brokerOrigin := brokerOriginURL.String()
	query := url.Values{
		"origin":              {options.Origin.String()},
		"broker":              {brokerOrigin},
		"control":             {options.ControlOrigin.String()},
		"host_fingerprint":    {hostIdentity.Fingerprint},
		"protocol_generation": {strconv.Itoa(ProtocolVersion)},
		"code":                {code},
	}
	pairingURI := &url.URL{Scheme: "wing", Host: "connect", RawQuery: query.Encode()}
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
			connectionCount := 1
			if options.CredentialMode == "compatibility_full_access" {
				connectionCount = len(options.Connections)
				if connectionCount < 1 {
					connectionCount = 1
				}
			}
			scopes := []string{
				"Full Hermes access",
				"Wing Link setup, lifecycle, health, and diagnostics",
				"Wing Link profile compatibility and device self-revocation",
			}
			accessLabel := "Full Hermes access"
			if options.CredentialMode == "scoped" {
				scopes = append(
					append([]string(nil), wingScopedHermesScopes...),
					"Wing Link setup, lifecycle, health, and diagnostics",
					"Wing Link profile compatibility and device self-revocation",
				)
				accessLabel = "Scoped Hermes access"
			}
			writePairJSON(writer, http.StatusOK, map[string]any{
				"label":               options.Label,
				"origin":              options.Origin.String(),
				"wing_link_origin":    options.ControlOrigin.String(),
				"credential_mode":     options.CredentialMode,
				"access_label":        accessLabel,
				"scopes":              scopes,
				"connection_count":    connectionCount,
				"host_fingerprint":    hostIdentity.Fingerprint,
				"protocol_generation": ProtocolVersion,
				"expires_at":          expiresAt.Unix(),
			})
		case "/v1/operator/enrollments/exchange":
			if state.issued == nil {
				// Stage the expiring, non-authoritative Wing Link credential first.
				// Consuming Hermes' one-time enrollment before this step could orphan
				// an active Hermes credential when control staging fails.
				var controlCredentialID, controlToken string
				var err error
				if options.ControlState != nil {
					controlCredentialID, controlToken, err = options.ControlState.StageBearerDeviceCredential(
						options.Label,
						wingLinkControlScopes,
					)
				} else {
					controlCredentialID, controlToken, err = stageControlCredential(
						loopbackControlOrigin(options.ControlOrigin),
						options.Label,
						wingLinkControlScopes,
					)
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
					"device_id":               controlCredentialID,
					"device_scopes":           wingLinkControlScopes,
					"host_fingerprint":        hostIdentity.Fingerprint,
					"protocol_generation":     ProtocolVersion,
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
	var openURL *url.URL
	if brokerIP.IsLoopback() {
		mux.HandleFunc("/open", handlePairOpen(pairingURI, expiresAt))
		openURL = brokerOriginURL.ResolveReference(&url.URL{Path: "/open"})
	}
	mux.HandleFunc("/v1/operator/enrollments/inspect", handler)
	mux.HandleFunc("/v1/operator/enrollments/exchange", handler)
	server := &http.Server{
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
	}
	var tlsCertificate *x509.Certificate
	serve := func() error { return server.Serve(listener) }
	if !brokerIP.IsLoopback() {
		config, _, err := listenerTLSConfig(brokerIP, hostIdentity, time.Now)
		if err != nil {
			_ = listener.Close()
			return nil, errors.New("could not initialize the pairing TLS identity")
		}
		tlsCertificate = config.Certificates[0].Leaf
		serve = func() error { return server.Serve(tls.NewListener(listener, config)) }
	}
	broker := &pairingBroker{
		PairingURI:     pairingURI,
		OpenURL:        openURL,
		TLSCertificate: tlsCertificate,
		Done:           done,
		server:         server,
		listener:       listener,
	}
	go func() { _ = serve() }()
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
			authorized = controlTokenAuthorized(
				loopbackControlOrigin(options.ControlOrigin),
				token,
			)
		}
		if authorized {
			close(done)
			return
		}
		<-ticker.C
	}
}

func loopbackControlOrigin(controlOrigin *url.URL) *url.URL {
	loopback := "127.0.0.1"
	if net.ParseIP(controlOrigin.Hostname()).To4() == nil {
		loopback = "::1"
	}
	return &url.URL{
		Scheme: "http",
		Host:   net.JoinHostPort(loopback, controlOrigin.Port()),
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
	return parsePairOptionsWithAdvertiseHost(args, pairingAdvertiseAddressForMode)
}

func parsePairOptionsWithAdvertiseHost(
	args []string,
	advertiseHost func(bool) (pairingAdvertiseAddress, error),
) (pairOptions, error) {
	label, err := os.Hostname()
	if err != nil || strings.TrimSpace(label) == "" {
		label = "Hermes Wing"
	}
	originValue := strings.TrimSpace(os.Getenv("WING_HERMES_URL"))
	remote := true
	printLink := true
	printQR := true
	sameDevice := false
	remoteExplicit := false
	qrExplicit := false
	originExplicit := false
	for index := 0; index < len(args); index++ {
		switch args[index] {
		case "--remote", "--lan":
			remote = true
			remoteExplicit = true
		case "--local":
			remote = false
		case "--same-device":
			sameDevice = true
			remote = false
		case "--link":
			printLink = true
			printQR = false
		case "--qr":
			printLink = false
			printQR = true
			qrExplicit = true
		case "--origin":
			originExplicit = true
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
	if sameDevice && (remoteExplicit || qrExplicit) {
		return pairOptions{}, fmt.Errorf("%w: --same-device conflicts with --remote and --qr", errPairUsage)
	}
	automaticOrigin := originValue == ""
	automaticHermesBinding := false
	if originValue == "" {
		selection, hostErr := advertiseHost(remote)
		if hostErr != nil {
			return pairOptions{}, hostErr
		}
		host := selection.Host
		automaticHermesBinding = selection.AutomaticHermesBinding
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
	originIP := net.ParseIP(origin.Hostname())
	if originIP != nil && !originIP.IsLoopback() && !remote {
		if sameDevice && originExplicit {
			return pairOptions{}, fmt.Errorf("%w: --same-device requires a loopback --origin", errPairUsage)
		}
		return pairOptions{}, fmt.Errorf("%w: non-loopback pairing requires --remote", errPairUsage)
	}
	if err := requireTrustedOriginHost(origin.Hostname()); err != nil {
		return pairOptions{}, err
	}
	controlValue := strings.TrimSpace(os.Getenv("WING_LINK_URL"))
	if controlValue == "" {
		controlScheme := "http"
		if !isLoopbackHost(origin.Hostname()) {
			controlScheme = "https"
		}
		controlValue = controlScheme + "://" + net.JoinHostPort(origin.Hostname(), strconv.Itoa(defaultWingLinkPort))
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
	if err := requireTrustedOriginHost(controlOrigin.Hostname()); err != nil {
		return pairOptions{}, err
	}
	token, err := discoverHermesToken()
	if err != nil {
		return pairOptions{}, err
	}
	if err := prepareAutomaticHermesOrigin(
		automaticOrigin && automaticHermesBinding,
		origin,
		func() int { return pairRequestStatus(origin, token, "/v1/capabilities") },
		func() error { return configureHermesVPNOrigin(origin, automaticHermesBinding) },
	); err != nil {
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
	statePath, err := resolveWingLinkStatePath()
	if err != nil {
		return pairOptions{}, err
	}
	hostIdentity, err := newStateStore(statePath).HostIdentity()
	if err != nil {
		return pairOptions{}, errors.New("could not initialize Wing Link host identity")
	}
	return pairOptions{
		Origin: origin, ControlOrigin: controlOrigin,
		HostIdentity: hostIdentity,
		Label:        label, Token: token,
		ScopedEnrollmentCode: scopedCode, CredentialMode: credentialMode,
		Connections: connections, PrintLink: printLink, PrintQR: printQR, SameDevice: sameDevice,
	}, nil
}

func pairingAdvertiseHost(remote bool) (string, error) {
	selection, err := pairingAdvertiseAddressForMode(remote)
	return selection.Host, err
}

func pairingAdvertiseAddressForMode(remote bool) (pairingAdvertiseAddress, error) {
	if !remote {
		return pairingAdvertiseAddress{Host: "127.0.0.1"}, nil
	}
	return advertiseAddress()
}

func prepareAutomaticHermesOrigin(automatic bool, origin *url.URL, probe func() int, configure func() error) error {
	if !automatic {
		return nil
	}
	if probe() != 0 {
		return nil
	}
	if err := configure(); err != nil {
		return err
	}
	deadline := time.Now().Add(30 * time.Second)
	for time.Now().Before(deadline) {
		if probe() != 0 {
			return nil
		}
		time.Sleep(250 * time.Millisecond)
	}
	return errors.New("agent API did not become reachable over NetBird or Tailscale")
}

func configureHermesVPNOrigin(origin *url.URL, verifiedMeshVPN bool) error {
	host := origin.Hostname()
	if !verifiedMeshVPN && !isOverlayVPNIP(net.ParseIP(host)) {
		return errors.New("automatic Hermes API binding requires a NetBird or Tailscale address")
	}
	port, err := strconv.Atoi(origin.Port())
	if err != nil || port < 1 || port > 65535 {
		return errors.New("automatic Hermes API binding requires an explicit port")
	}
	hermes, err := exec.LookPath("hermes")
	if err != nil {
		return errors.New("could not find Hermes CLI to enable mesh VPN pairing")
	}
	output, result := runProcessCapture(context.Background(), CommandSpec{
		Path: hermes, Args: []string{"config", "env-path"}, Timeout: 5 * time.Second,
	}, 4096)
	path := strings.TrimSpace(string(output))
	home, homeErr := resolveHermesHome()
	if result.Err != nil || homeErr != nil || !filepath.IsAbs(path) ||
		strings.ContainsAny(path, "\r\n") || !pathWithin(home, path) ||
		rejectSymlinkedAncestors(path) != nil {
		return errors.New("could not locate Hermes API environment for mesh VPN pairing")
	}
	return configureHermesVPNOriginWithRunner(hermes, host, verifiedMeshVPN, runProcess, func() error {
		return ensureHermesAPIEnvironmentHost(path, host, port)
	})
}

func configureHermesVPNOriginWithRunner(
	hermes, host string,
	verifiedMeshVPN bool,
	run func(context.Context, CommandSpec, func(string)) ProcessResult,
	updateEnvironment func() error,
) error {
	if !verifiedMeshVPN && !isOverlayVPNIP(net.ParseIP(host)) {
		return errors.New("automatic Hermes API binding requires a NetBird or Tailscale address")
	}
	if result := run(context.Background(), CommandSpec{
		Path: hermes, Args: []string{"config", "set", "--force", "platforms.api_server.extra.host", host}, Timeout: 90 * time.Second,
	}, nil); result.Err != nil {
		return errors.New("could not enable Hermes API access over the mesh VPN")
	}
	if err := updateEnvironment(); err != nil {
		return errors.New("could not update Hermes API environment for the mesh VPN")
	}
	if result := run(context.Background(), CommandSpec{
		Path: hermes, Args: []string{"gateway", "restart"}, Timeout: 90 * time.Second,
	}, nil); result.Err != nil {
		return errors.New("could not restart Hermes API for the mesh VPN")
	}
	return nil
}

func isOverlayVPNIP(ip net.IP) bool {
	if ip == nil {
		return false
	}
	if ipv4 := ip.To4(); ipv4 != nil {
		return ipv4[0] == 100 && ipv4[1] >= 64 && ipv4[1] <= 127
	}
	ipv6 := ip.To16()
	return ipv6 != nil &&
		ipv6[0] == 0xfd && ipv6[1] == 0x7a && ipv6[2] == 0x11 &&
		ipv6[3] == 0x5c && ipv6[4] == 0xa1 && ipv6[5] == 0xe0
}

var wingLinkControlScopes = []string{
	ScopeSetupWrite,
	ScopeLifecycleWrite,
	ScopeHealthRead,
	ScopeDiagnosticsRead,
	ScopeProfilesRead,
	ScopeProfilesWrite,
	ScopeDirectoriesRead,
	ScopeDeviceSelfRead,
	ScopeDeviceSelfRevoke,
}

var wingScopedHermesScopes = []string{
	"chat:write", "sessions:read", "sessions:write", "runs:read", "runs:write",
	"approvals:write", "profiles:read", "profiles:write", "providers:read",
	"providers:write", "models:read", "models:write", "skills:read",
	"tools:read", "jobs:read", "health:read",
}

func createScopedHermesEnrollment(origin *url.URL, token, label string) (string, bool, error) {
	return createScopedHermesEnrollmentWithClient(&http.Client{Timeout: 10 * time.Second}, origin, token, label)
}

func createScopedHermesEnrollmentWithClient(client *http.Client, origin *url.URL, token, label string) (string, bool, error) {
	var capabilities struct {
		Endpoints map[string]apiEndpoint `json:"endpoints"`
		Auth      struct {
			GrantedScopes []string `json:"granted_scopes"`
		} `json:"auth"`
	}
	if err := pairJSONRequest(client, origin, token, http.MethodGet, "/v1/capabilities", nil, &capabilities); err != nil {
		if errors.Is(err, errHermesEnrollmentRequestFailed) && !isLoopbackHost(origin.Hostname()) {
			return "", false, errors.New("inspect Hermes enrollment capabilities: Hermes Agent API is unreachable at the selected remote origin; setup binds it to loopback by default—bind it to a trusted VPN address and set WING_HERMES_URL, or use --local for same-device pairing")
		}
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
	hermes, home, err := resolvePairHermesExecutable()
	if err != nil {
		return errors.New("could not find Hermes profile CLI")
	}
	runHermes := func(ctx context.Context, args ...string) error {
		result := runProcess(ctx, CommandSpec{
			Path: hermes, Args: args, Env: []string{"HERMES_HOME=" + home}, Timeout: 90 * time.Second,
		}, nil)
		return result.Err
	}
	if err := runHermes(context.Background(), "config", "set", "--force", "gateway.multiplex_profiles", "true"); err != nil {
		return errors.New("could not enable Hermes profile routing")
	}
	if err := restartHermesGateway(context.Background(), hermes, home, runHermes); err != nil {
		return errors.New("could not restart Hermes profile routing")
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
		current := strings.HasPrefix(fields[0], "◆")
		rawID := strings.TrimPrefix(fields[0], "◆")
		id, err := normalizeProfileID(rawID)
		if err != nil || id != rawID {
			return nil, errors.New("hermes profile list returned invalid data")
		}
		if _, duplicate := seen[id]; duplicate {
			return nil, errors.New("hermes profile list returned duplicate profiles")
		}
		seen[id] = struct{}{}
		rows = append(rows, profileRow{ID: id, Name: id, Model: model, GatewayState: state, Current: current})
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
	hermes, home, err := resolvePairHermesExecutable()
	if err != nil {
		return issuedHermesEnrollment{}, errors.New("could not find Hermes profile CLI")
	}
	output, result := runProcessCapture(context.Background(), CommandSpec{
		Path: hermes, Args: []string{"profile", "list"}, Env: []string{"HERMES_HOME=" + home}, Timeout: 30 * time.Second,
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
			profileToken, err = hermesProfileToken(hermes, home, row.ID)
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

func hermesProfileToken(hermes, home, profileID string) (string, error) {
	output, result := runProcessCapture(context.Background(), CommandSpec{
		Path: hermes, Args: []string{"--profile", profileID, "config", "env-path"},
		Env: []string{"HERMES_HOME=" + home}, Timeout: 30 * time.Second,
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

func stageControlCredential(controlOrigin *url.URL, name string, scopes []string) (string, string, error) {
	statePath, err := resolveWingLinkStatePath()
	if err != nil {
		return "", "", errors.New("wing link local pairing authority is unavailable")
	}
	proof, err := loadLocalPairingProof(statePath)
	if err != nil {
		return "", "", errors.New("wing link local pairing authority is unavailable")
	}
	var response struct {
		CredentialID string `json:"credential_id"`
		Token        string `json:"token"`
	}
	loopbackHost := "127.0.0.1"
	if strings.Contains(controlOrigin.Hostname(), ":") {
		loopbackHost = "::1"
	}
	loopbackOrigin := &url.URL{Scheme: "http", Host: net.JoinHostPort(loopbackHost, controlOrigin.Port())}
	client := &http.Client{
		Timeout:       10 * time.Second,
		CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
	}
	if err := pairJSONRequestWithHeaders(
		client, loopbackOrigin, "", http.MethodPost,
		"/v1/pairing/control-credentials", map[string]any{"name": name, "scopes": scopes}, &response,
		map[string]string{localPairingProofHeader: proof},
	); err != nil || response.CredentialID == "" || response.Token == "" {
		return "", "", errors.New("wing link control credential staging failed")
	}
	return response.CredentialID, response.Token, nil
}

var errHermesEnrollmentRequestFailed = errors.New("hermes enrollment request failed")

func pairJSONRequest(client *http.Client, origin *url.URL, token, method, path string, body any, target any) error {
	return pairJSONRequestWithHeaders(client, origin, token, method, path, body, target, nil)
}

func pairJSONRequestWithHeaders(client *http.Client, origin *url.URL, token, method, path string, body any, target any, headers map[string]string) error {
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
	for name, value := range headers {
		request.Header.Set(name, value)
	}
	request.Header.Set("Content-Type", "application/json")
	response, err := client.Do(request)
	if err != nil {
		return errHermesEnrollmentRequestFailed
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
	hermes, home, err := resolvePairHermesExecutable()
	if err != nil {
		return "", errors.New("could not find the local Hermes API key; install/configure Hermes or set WING_HERMES_TOKEN")
	}
	output, result := runProcessCapture(context.Background(), CommandSpec{
		Path:    hermes,
		Args:    []string{"config", "env-path"},
		Env:     []string{"HERMES_HOME=" + home},
		Timeout: 5 * time.Second,
	}, 4096)
	path := strings.TrimSpace(string(output))
	if result.Err == nil && filepath.IsAbs(path) &&
		!strings.ContainsAny(path, "\r\n") && pathWithin(home, path) &&
		rejectSymlinkedAncestors(path) == nil {
		if token, err := ensureHermesTokenFile(path); err == nil {
			return token, nil
		}
	}
	return "", errors.New("could not prepare the local Hermes API key")
}

func resolvePairHermesExecutable() (string, string, error) {
	return resolvePairHermesExecutableForPlatform(runtime.GOOS)
}

func resolvePairHermesExecutableForPlatform(platform string) (string, string, error) {
	home, err := resolveHermesHome()
	if err != nil {
		return "", "", err
	}
	if platform == "android" {
		hermes, err := resolveHermesExecutableForPlatform(platform, home, "")
		if err != nil {
			return "", "", err
		}
		return hermes, home, nil
	}
	hermes, err := exec.LookPath("hermes")
	if err != nil {
		return "", "", err
	}
	return hermes, home, nil
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

type pairingAdvertiseAddress struct {
	Host                   string
	AutomaticHermesBinding bool
}

type meshVPNAddress struct {
	Provider string
	IP       net.IP
}

type meshVPNProbe struct {
	Provider   string
	Executable string
	Arguments  []string
}

var meshVPNProbes = []meshVPNProbe{
	{Provider: "NetBird", Executable: "netbird", Arguments: []string{"status", "--ipv4"}},
	{Provider: "NetBird", Executable: "netbird", Arguments: []string{"status", "--ipv6"}},
	{Provider: "Tailscale", Executable: "tailscale", Arguments: []string{"ip", "-4"}},
}

func discoverMeshVPNAddresses() ([]meshVPNAddress, error) {
	return discoverMeshVPNAddressesWith(exec.LookPath, runProcessCapture, isLocalInterfaceIP)
}

func discoverMeshVPNAddressesWith(
	lookPath func(string) (string, error),
	capture func(context.Context, CommandSpec, int) ([]byte, ProcessResult),
	isLocal func(net.IP) bool,
) ([]meshVPNAddress, error) {
	addresses := make([]meshVPNAddress, 0, len(meshVPNProbes))
	for _, probe := range meshVPNProbes {
		executable, err := lookPath(probe.Executable)
		if err != nil {
			continue
		}
		output, result := capture(context.Background(), CommandSpec{
			Path: executable, Args: probe.Arguments, Timeout: 3 * time.Second,
		}, 256)
		if result.Err != nil || result.ExitCode != 0 {
			if errors.Is(result.Err, context.DeadlineExceeded) || len(output) > 0 {
				return nil, fmt.Errorf("%s VPN address probe failed safely", probe.Provider)
			}
			continue
		}
		if len(output) == 0 {
			continue
		}
		fields := strings.Fields(string(output))
		if len(fields) != 1 {
			return nil, fmt.Errorf("%s returned an invalid VPN address", probe.Provider)
		}
		ip := net.ParseIP(fields[0])
		if ip == nil || !ip.IsGlobalUnicast() || !isTrustedControlPlaneIP(ip) || !isLocal(ip) {
			return nil, fmt.Errorf("%s returned an untrusted or nonlocal VPN address", probe.Provider)
		}
		addresses = append(addresses, meshVPNAddress{Provider: probe.Provider, IP: ip})
	}
	return addresses, nil
}

func preferredPairingAddress(addresses []net.Addr, meshAddresses []meshVPNAddress) (pairingAdvertiseAddress, error) {
	byProvider := make(map[string]net.IP, len(meshAddresses))
	for _, candidate := range meshAddresses {
		if candidate.IP == nil {
			continue
		}
		current := byProvider[candidate.Provider]
		if current == nil || (current.To4() == nil && candidate.IP.To4() != nil) {
			byProvider[candidate.Provider] = candidate.IP
		}
	}
	unique := make(map[string]struct{}, len(byProvider))
	for _, ip := range byProvider {
		unique[ip.String()] = struct{}{}
	}
	if len(unique) > 1 {
		return pairingAdvertiseAddress{}, errors.New("multiple mesh VPN addresses detected; set WING_HERMES_URL and WING_LINK_URL to the intended local address")
	}
	for host := range unique {
		return pairingAdvertiseAddress{Host: host, AutomaticHermesBinding: true}, nil
	}
	host, err := preferredPairingIP(addresses)
	if err != nil {
		return pairingAdvertiseAddress{}, err
	}
	return pairingAdvertiseAddress{
		Host:                   host,
		AutomaticHermesBinding: isOverlayVPNIP(net.ParseIP(host)),
	}, nil
}

// advertiseAddress prefers a positively identified mesh VPN, then the safe
// address-class fallback used by earlier Wing Link releases.
func advertiseIP() (string, error) {
	selection, err := advertiseAddress()
	return selection.Host, err
}

func advertiseAddress() (pairingAdvertiseAddress, error) {
	addresses, err := net.InterfaceAddrs()
	if err != nil {
		return pairingAdvertiseAddress{}, fmt.Errorf("discover network address: %w", err)
	}
	meshAddresses, err := discoverMeshVPNAddresses()
	if err != nil {
		return pairingAdvertiseAddress{}, err
	}
	return preferredPairingAddress(addresses, meshAddresses)
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
			return errors.New("pairing origins must use loopback, a private LAN, NetBird, or Tailscale")
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
