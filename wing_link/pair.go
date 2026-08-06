package main

import (
	"bufio"
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
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/mdp/qrterminal/v3"
	"rsc.io/qr"
)

var errPairUsage = errors.New("invalid pair arguments")

type pairOptions struct {
	Origin *url.URL
	Label  string
	Token  string
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
		_ = broker.server.Close()
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
	qrterminal.GenerateHalfBlock(broker.PairingURI.String(), qr.M, stdout)
	_, _ = fmt.Fprintf(stderr, "pair: code: %s\n", broker.PairingURI.Query().Get("code"))

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
		"origin": {options.Origin.String()},
		"broker": {brokerOrigin},
		"code":   {code},
	}
	done := make(chan struct{})
	state := struct {
		sync.Mutex
		consumed bool
	}{}
	var signalOnce sync.Once
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
		if err := decoder.Decode(&payload); err != nil || payload.Origin != options.Origin.String() || !matchesHash(payload.Code, hashSecret(code)) || !time.Now().Before(expiresAt) {
			writePairJSON(writer, http.StatusNotFound, map[string]any{"error": "pairing code unavailable"})
			return
		}
		state.Lock()
		defer state.Unlock()
		if state.consumed {
			writePairJSON(writer, http.StatusGone, map[string]any{"error": "pairing code already used"})
			return
		}
		switch request.URL.Path {
		case "/v1/operator/enrollments/inspect":
			writePairJSON(writer, http.StatusOK, map[string]any{
				"label":      options.Label,
				"origin":     options.Origin.String(),
				"scopes":     []string{"*"},
				"expires_at": expiresAt.Unix(),
			})
		case "/v1/operator/enrollments/exchange":
			state.consumed = true
			writePairJSON(writer, http.StatusOK, map[string]any{
				"token":         options.Token,
				"label":         options.Label,
				"credential_id": "api_server_key",
			})
			signalOnce.Do(func() { close(done) })
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
	local := false
	for index := 0; index < len(args); index++ {
		switch args[index] {
		case "--lan":
			// Network/VPN is the default; retained for compatibility.
		case "--local":
			local = true
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
		host := "127.0.0.1"
		if !local {
			host, err = advertiseIP()
			if err != nil {
				return pairOptions{}, err
			}
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
	token, err := discoverHermesToken()
	if err != nil {
		return pairOptions{}, err
	}
	return pairOptions{Origin: origin, Label: label, Token: token}, nil
}

func discoverHermesToken() (string, error) {
	if token := strings.TrimSpace(os.Getenv("WING_HERMES_TOKEN")); token != "" {
		return token, nil
	}
	hermes, err := exec.LookPath("hermes")
	if err != nil {
		return "", errors.New("could not find the local Hermes API key; install/configure Hermes or set WING_HERMES_TOKEN")
	}
	var lines []string
	result := runProcess(context.Background(), CommandSpec{
		Path:    hermes,
		Args:    []string{"config", "env-path"},
		Timeout: 5 * time.Second,
	}, func(line string) {
		if line = strings.TrimSpace(line); line != "" {
			lines = append(lines, line)
		}
	})
	if result.Err == nil {
		for index := len(lines) - 1; index >= 0; index-- {
			if token, err := readHermesTokenFile(lines[index]); err == nil {
				return token, nil
			}
		}
	}
	return "", errors.New("could not find the local Hermes API key; run Hermes setup or set WING_HERMES_TOKEN")
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
		value = strings.TrimSpace(value)
		if len(value) >= 2 && ((value[0] == '\'' && value[len(value)-1] == '\'') || (value[0] == '"' && value[len(value)-1] == '"')) {
			value = value[1 : len(value)-1]
		}
		if value != "" {
			return value, nil
		}
	}
	return "", errors.New("hermes API key is not configured")
}

func normalizeOrigin(value string) (*url.URL, error) {
	origin, err := url.Parse(strings.TrimSpace(value))
	if err != nil || origin.Host == "" || origin.User != nil || (origin.Scheme != "http" && origin.Scheme != "https") || (origin.Path != "" && origin.Path != "/") || origin.RawQuery != "" || origin.Fragment != "" {
		return nil, errors.New("origin must be an http(s) origin without credentials, path, query, or fragment")
	}
	if origin.Port() == "0" {
		return nil, errors.New("origin must use a valid TCP port")
	}
	return &url.URL{Scheme: origin.Scheme, Host: origin.Host}, nil
}

// advertiseIP prefers Tailscale, then the first non-loopback IPv4.
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
		ip := network.IP.To4()
		if ip == nil || ip.IsLoopback() || !ip.IsGlobalUnicast() {
			continue
		}
		if ip[0] == 100 && ip[1] >= 64 && ip[1] <= 127 {
			return ip.String(), nil
		}
		if fallback == "" {
			fallback = ip.String()
		}
	}
	if fallback == "" {
		return "", errors.New("no LAN/VPN IPv4 found; use --local or --origin")
	}
	return fallback, nil
}

func isLoopbackHost(host string) bool {
	return strings.EqualFold(host, "localhost") || net.ParseIP(host).IsLoopback()
}
