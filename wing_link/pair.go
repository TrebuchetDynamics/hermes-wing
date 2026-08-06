package main

import (
	"bufio"
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
	"strconv"
	"strings"
	"time"

	"github.com/mdp/qrterminal/v3"
	"rsc.io/qr"
)

var errPairUsage = errors.New("invalid pair arguments")

var pairingScopes = []string{
	"chat:read",
	"chat:write",
	"sessions:read",
	"sessions:write",
	"profiles:read",
}

type pairOptions struct {
	Origin *url.URL
	Label  string
	Token  string
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
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	pairing, err := createHermesPairing(ctx, http.DefaultClient, options)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "pair: %v\n", err)
		return 1
	}
	_, _ = fmt.Fprintf(stderr, "pair: one-time Hermes enrollment for %s\n", options.Origin)
	if options.Origin.Scheme == "http" && !isLoopbackHost(options.Origin.Hostname()) {
		_, _ = fmt.Fprintln(stderr, "pair: plaintext HTTP requires confirmation in Wing; prefer a trusted VPN")
	}
	qrterminal.GenerateHalfBlock(pairing.String(), qr.M, stdout)
	_, _ = fmt.Fprintf(stderr, "pair: code: %s\n", pairing.Query().Get("code"))
	return 0
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

func createHermesPairing(ctx context.Context, client *http.Client, options pairOptions) (*url.URL, error) {
	body, err := json.Marshal(map[string]any{
		"label":  options.Label,
		"origin": options.Origin.String(),
		"scopes": pairingScopes,
	})
	if err != nil {
		return nil, errors.New("could not encode enrollment request")
	}
	endpoint := options.Origin.ResolveReference(&url.URL{Path: "/v1/operator/enrollments"})
	request, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint.String(), bytes.NewReader(body))
	if err != nil {
		return nil, errors.New("could not create enrollment request")
	}
	request.Header.Set("Authorization", "Bearer "+options.Token)
	request.Header.Set("Content-Type", "application/json")

	lockedClient := *client
	lockedClient.CheckRedirect = func(*http.Request, []*http.Request) error {
		return http.ErrUseLastResponse
	}
	response, err := lockedClient.Do(request)
	if err != nil {
		return nil, fmt.Errorf("could not reach Hermes at %s", options.Origin)
	}
	defer func() { _ = response.Body.Close() }()
	if response.StatusCode < 200 || response.StatusCode >= 300 {
		return nil, fmt.Errorf("hermes enrollment failed (%d)", response.StatusCode)
	}
	var payload struct {
		PairingURI string `json:"pairing_uri"`
	}
	decoder := json.NewDecoder(io.LimitReader(response.Body, 64<<10))
	if err := decoder.Decode(&payload); err != nil {
		return nil, errors.New("hermes enrollment response was not valid JSON")
	}
	pairing, err := url.Parse(payload.PairingURI)
	if err != nil || pairing.Scheme != "wing" || pairing.Host != "connect" || pairing.User != nil || pairing.Fragment != "" {
		return nil, errors.New("hermes enrollment response did not include a valid pairing URI")
	}
	query := pairing.Query()
	if len(query["origin"]) != 1 || len(query["code"]) != 1 || len(query["token"]) != 0 || len(query["broker"]) > 1 {
		return nil, errors.New("hermes enrollment response contained ambiguous pairing parameters")
	}
	code := query.Get("code")
	if code == "" || len(code) > 128 {
		return nil, errors.New("hermes enrollment response did not include a valid pairing code")
	}
	pairingOrigin, err := normalizeOrigin(query.Get("origin"))
	if err != nil || pairingOrigin.String() != options.Origin.String() {
		return nil, errors.New("hermes enrollment response origin did not match the request")
	}
	return pairing, nil
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
