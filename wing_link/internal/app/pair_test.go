package app

import (
	"bufio"
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestPairingAdvertiseHostDefaultsToLoopback(t *testing.T) {
	host, err := pairingAdvertiseHost(false)
	if err != nil {
		t.Fatal(err)
	}
	if host != "127.0.0.1" {
		t.Fatalf("default pairing host = %q", host)
	}
}

func TestPairingBrokerRejectsPlaintextNonLoopbackByDefault(t *testing.T) {
	options := testPairOptions(t, "superuser-secret")
	options.Origin = &url.URL{Scheme: "http", Host: "192.0.2.1:8642"}
	if _, err := startPairingBroker(options); err == nil ||
		!strings.Contains(err.Error(), "authenticated encrypted VPN") {
		t.Fatalf("non-loopback broker error = %v", err)
	}
}

func TestPairingBrokerInspectsAndExchangesOnce(t *testing.T) {
	options := testPairOptions(t, "superuser-secret")
	origin := options.Origin
	broker, err := startPairingBroker(options)
	if err != nil {
		t.Fatal(err)
	}
	defer broker.Close()

	payload := broker.PairingURI
	if payload.Scheme != "wing" || payload.Host != "connect" || payload.Query().Get("origin") != origin.String() {
		t.Fatalf("pairing URI = %s", payload)
	}
	brokerOrigin := payload.Query().Get("broker")
	code := payload.Query().Get("code")
	if brokerOrigin == "" || code == "" {
		t.Fatalf("pairing URI = %s", payload)
	}

	inspect := postPairBroker(t, brokerOrigin+"/v1/operator/enrollments/inspect", brokerOrigin, code)
	if inspect.StatusCode != http.StatusOK ||
		!strings.Contains(string(inspect.Body), `"label":"phone"`) ||
		!strings.Contains(string(inspect.Body), `"Wing Link setup, lifecycle, health, and diagnostics"`) {
		t.Fatalf("inspect = %d %s", inspect.StatusCode, inspect.Body)
	}
	exchange := postPairBroker(t, brokerOrigin+"/v1/operator/enrollments/exchange", brokerOrigin, code)
	if exchange.StatusCode != http.StatusOK ||
		!strings.Contains(string(exchange.Body), `"token":"superuser-secret"`) ||
		!strings.Contains(string(exchange.Body), `"wing_link_token":"wlc_`) ||
		!strings.Contains(string(exchange.Body), `"setup:write"`) ||
		strings.Contains(string(exchange.Body), `"wing_link_scopes":["profiles:read"`) {
		t.Fatalf("exchange = %d %s", exchange.StatusCode, exchange.Body)
	}
	var issued map[string]any
	if err := json.Unmarshal(exchange.Body, &issued); err != nil {
		t.Fatal(err)
	}
	if _, present := issued["connections"]; present {
		t.Fatal("legacy exchange advertised an authoritative connections field")
	}
	controlToken, _ := issued["wing_link_token"].(string)
	credentialID, _ := issued["wing_link_credential_id"].(string)
	if options.ControlState.Authorize(controlToken) ||
		!options.ControlState.AuthorizePending(credentialID, controlToken) {
		t.Fatal("control token became authoritative before acknowledgment")
	}
	replay := postPairBroker(t, brokerOrigin+"/v1/operator/enrollments/exchange", brokerOrigin, code)
	if replay.StatusCode != http.StatusOK || !bytes.Equal(replay.Body, exchange.Body) {
		t.Fatalf("idempotent replay = %d %s", replay.StatusCode, replay.Body)
	}
	if err := options.ControlState.AcknowledgeControlToken(credentialID, controlToken); err != nil {
		t.Fatal(err)
	}
	if !options.ControlState.Authorize(controlToken) {
		t.Fatal("acknowledged control token was not authorized")
	}
	select {
	case <-broker.Done:
	case <-time.After(time.Second):
		t.Fatal("broker did not report exchange")
	}
}

func TestPairCommandCompletesOnlyAfterControlCredentialAcknowledgment(t *testing.T) {
	directory := t.TempDir()
	hermesPath := filepath.Join(directory, "hermes")
	script := `#!/bin/sh
if [ "$1" = "--profile" ] && [ "$3 $4" = "config env-path" ]; then /bin/printf '%s\n' "$HOME/.hermes/.env"; exit; fi
/bin/printf '%s\n' \
 ' Profile          Model                        Gateway      Alias        Distribution' \
 ' ───────────────  ───────────────────────────  ───────────  ───────────  ────────────────────' \
 '  default         —                            stopped      —            —'
`
	if err := os.WriteFile(hermesPath, []byte(script), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(directory, ".hermes"), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(directory, ".hermes", ".env"), []byte("API_SERVER_KEY=default-key\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	t.Setenv("HOME", directory)
	t.Setenv("PATH", directory)
	statePath := filepath.Join(directory, "state.json")
	controlState := newStateStore(statePath)
	controlHandler := newWingLinkServer(&profileBackend{}, controlState)
	healthServer := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if request.URL.Path == "/v1/capabilities" || request.URL.Path == "/p/default/v1/capabilities" {
			writePairJSON(writer, http.StatusOK, map[string]any{"endpoints": map[string]any{}})
			return
		}
		if request.URL.Path == "/p/wing-link-invalid-probe/v1/capabilities" {
			writer.WriteHeader(http.StatusNotFound)
			return
		}
		controlHandler.ServeHTTP(writer, request)
	}))
	defer healthServer.Close()
	t.Setenv("WING_HERMES_URL", healthServer.URL)
	t.Setenv("WING_HERMES_TOKEN", "superuser-secret")
	t.Setenv("WING_LINK_URL", healthServer.URL)
	t.Setenv("WING_LINK_SERVICE", "external")
	t.Setenv("WING_LINK_STATE", statePath)
	reader, writer := io.Pipe()
	result := make(chan int, 1)
	go func() {
		result <- pairCommand(io.Discard, writer, nil)
		_ = writer.Close()
	}()

	scanner := bufio.NewScanner(reader)
	var exchangeEndpoint, code string
	for scanner.Scan() {
		line := scanner.Text()
		if strings.Contains(line, "code valid") {
			fields := strings.Fields(line)
			exchangeEndpoint = fields[len(fields)-1]
		}
		if strings.HasPrefix(line, "pair: code: ") {
			code = strings.TrimPrefix(line, "pair: code: ")
			break
		}
	}
	if exchangeEndpoint == "" || code == "" {
		t.Fatalf("endpoint=%q code=%q", exchangeEndpoint, code)
	}
	brokerOrigin := strings.TrimSuffix(exchangeEndpoint, "/v1/operator/enrollments/exchange")
	inspect := postPairBroker(t, brokerOrigin+"/v1/operator/enrollments/inspect", brokerOrigin, code)
	if inspect.StatusCode != http.StatusOK {
		t.Fatalf("inspect status = %d", inspect.StatusCode)
	}
	exchange := postPairBroker(t, exchangeEndpoint, brokerOrigin, code)
	if exchange.StatusCode != http.StatusOK || !strings.Contains(string(exchange.Body), `"token":"superuser-secret"`) {
		t.Fatalf("exchange = %d %s", exchange.StatusCode, exchange.Body)
	}
	var issued map[string]any
	if err := json.Unmarshal(exchange.Body, &issued); err != nil {
		t.Fatal(err)
	}
	select {
	case exitCode := <-result:
		t.Fatalf("pair exited before acknowledgment with %d", exitCode)
	case <-time.After(250 * time.Millisecond):
	}
	ackRequest, err := http.NewRequest(
		http.MethodPost,
		healthServer.URL+"/v1/auth/credentials/"+issued["wing_link_credential_id"].(string)+"/ack",
		nil,
	)
	if err != nil {
		t.Fatal(err)
	}
	ackRequest.Header.Set("Authorization", "Bearer "+issued["wing_link_token"].(string))
	ackResponse, err := http.DefaultClient.Do(ackRequest)
	if err != nil {
		t.Fatal(err)
	}
	_ = ackResponse.Body.Close()
	if ackResponse.StatusCode != http.StatusOK {
		t.Fatalf("ack status = %d", ackResponse.StatusCode)
	}
	if !scanner.Scan() || !strings.Contains(scanner.Text(), "pairing complete") {
		t.Fatalf("completion message = %q", scanner.Text())
	}
	select {
	case exitCode := <-result:
		if exitCode != 0 {
			t.Fatalf("exit code = %d", exitCode)
		}
	case <-time.After(3 * time.Second):
		t.Fatal("pair command did not finish")
	}
}

func TestPairingBrokerRejectsWrongOriginAndCode(t *testing.T) {
	options := testPairOptions(t, "secret")
	origin := options.Origin
	broker, err := startPairingBroker(options)
	if err != nil {
		t.Fatal(err)
	}
	defer broker.Close()
	brokerOrigin := broker.PairingURI.Query().Get("broker")
	code := broker.PairingURI.Query().Get("code")
	for _, request := range []struct{ origin, code string }{
		{origin: "http://127.0.0.1:9999", code: code},
		{origin: origin.String(), code: "wrong"},
	} {
		response := postPairBroker(t, brokerOrigin+"/v1/operator/enrollments/inspect", request.origin, request.code)
		if response.StatusCode != http.StatusNotFound {
			t.Fatalf("status = %d", response.StatusCode)
		}
	}
}

func TestScopedHermesCapabilityFailureDoesNotFallBackToFullAccess(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusInternalServerError)
	}))
	defer server.Close()
	origin, err := normalizeOrigin(server.URL)
	if err != nil {
		t.Fatal(err)
	}
	if _, advertised, err := createScopedHermesEnrollment(origin, "full-key", "phone"); err == nil || advertised {
		t.Fatalf("advertised=%v err=%v", advertised, err)
	}
}

func TestScopedHermesEnrollmentIsPreferredWhenAdvertised(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		switch request.URL.Path {
		case "/v1/capabilities":
			writePairJSON(writer, http.StatusOK, map[string]any{
				"endpoints": map[string]any{
					"operator_enrollment_create": map[string]any{
						"method": "POST", "path": "/v1/operator/enrollments",
					},
				},
			})
		case "/v1/operator/enrollments":
			if request.Header.Get("Authorization") != "Bearer full-key" {
				writer.WriteHeader(http.StatusUnauthorized)
				return
			}
			writePairJSON(writer, http.StatusCreated, map[string]any{
				"pairing_uri": "wing://connect?origin=" + url.QueryEscape(serverURL(request)) + "&code=scoped-code",
			})
		case "/v1/operator/enrollments/exchange":
			writePairJSON(writer, http.StatusOK, map[string]any{
				"token": "hop_scoped", "credential_id": "hoc_scoped",
			})
		default:
			writer.WriteHeader(http.StatusNotFound)
		}
	}))
	defer server.Close()
	origin, err := normalizeOrigin(server.URL)
	if err != nil {
		t.Fatal(err)
	}
	code, advertised, err := createScopedHermesEnrollment(origin, "full-key", "phone")
	if err != nil {
		t.Fatal(err)
	}
	if !advertised || code != "scoped-code" {
		t.Fatalf("advertised=%v code=%q", advertised, code)
	}
	issued, err := exchangeScopedHermesEnrollment(pairOptions{
		Origin: origin, ScopedEnrollmentCode: code,
	})
	if err != nil || issued.Token != "hop_scoped" || issued.CredentialID != "hoc_scoped" {
		t.Fatalf("token=%q credential=%q err=%v", issued.Token, issued.CredentialID, err)
	}
}

func TestScopedHermesEnrollmentRequiresEveryAdvertisedCallerScope(t *testing.T) {
	var enrollmentCalls int
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		switch request.URL.Path {
		case "/v1/capabilities":
			writePairJSON(writer, http.StatusOK, map[string]any{
				"auth": map[string]any{"granted_scopes": []string{"operator:read"}},
				"endpoints": map[string]any{
					"operator_enrollment_create": map[string]any{
						"method":          "POST",
						"path":            "/v1/operator/enrollments",
						"required_scopes": []string{"operator:read", "operator:write"},
					},
				},
			})
		case "/v1/operator/enrollments":
			enrollmentCalls++
			writer.WriteHeader(http.StatusCreated)
		default:
			writer.WriteHeader(http.StatusNotFound)
		}
	}))
	defer server.Close()
	origin, err := normalizeOrigin(server.URL)
	if err != nil {
		t.Fatal(err)
	}
	if _, advertised, err := createScopedHermesEnrollment(origin, "partial-key", "phone"); err == nil || !advertised {
		t.Fatalf("advertised=%v err=%v", advertised, err)
	}
	if enrollmentCalls != 0 {
		t.Fatalf("under-scoped credential attempted enrollment: %d", enrollmentCalls)
	}
}

func TestScopedHermesEnrollmentAcceptsWildcardCallerScope(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		switch request.URL.Path {
		case "/v1/capabilities":
			writePairJSON(writer, http.StatusOK, map[string]any{
				"auth": map[string]any{"granted_scopes": []string{"*"}},
				"endpoints": map[string]any{
					"operator_enrollment_create": map[string]any{
						"method": "POST", "path": "/v1/operator/enrollments",
						"required_scopes": []string{"operator:read", "operator:write"},
					},
				},
			})
		case "/v1/operator/enrollments":
			writePairJSON(writer, http.StatusCreated, map[string]any{
				"pairing_uri": "wing://connect?origin=" + url.QueryEscape(serverURL(request)) + "&code=scoped-code",
			})
		default:
			writer.WriteHeader(http.StatusNotFound)
		}
	}))
	defer server.Close()
	origin, err := normalizeOrigin(server.URL)
	if err != nil {
		t.Fatal(err)
	}
	code, advertised, err := createScopedHermesEnrollment(origin, "full-key", "phone")
	if err != nil || !advertised || code != "scoped-code" {
		t.Fatalf("advertised=%v code=%q err=%v", advertised, code, err)
	}
}

func TestControlCredentialStagingPrecedesHermesExchange(t *testing.T) {
	var hermesExchangeCalls int
	hermes := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if request.URL.Path == "/v1/operator/enrollments/exchange" {
			hermesExchangeCalls++
			writePairJSON(writer, http.StatusOK, map[string]any{
				"token": "hop_scoped", "credential_id": "hoc_scoped",
			})
			return
		}
		writer.WriteHeader(http.StatusNotFound)
	}))
	defer hermes.Close()
	hermesOrigin, err := normalizeOrigin(hermes.URL)
	if err != nil {
		t.Fatal(err)
	}
	controlOrigin, err := normalizeOrigin("http://127.0.0.1:1")
	if err != nil {
		t.Fatal(err)
	}
	broker, err := startPairingBroker(pairOptions{
		Origin:               hermesOrigin,
		ControlOrigin:        controlOrigin,
		Label:                "phone",
		ScopedEnrollmentCode: "one-time-hermes-code",
		CredentialMode:       "scoped",
	})
	if err != nil {
		t.Fatal(err)
	}
	defer broker.Close()

	payload := broker.PairingURI
	brokerOrigin := payload.Query().Get("broker")
	response := postPairBroker(
		t,
		brokerOrigin+"/v1/operator/enrollments/exchange",
		brokerOrigin,
		payload.Query().Get("code"),
	)
	if response.StatusCode != http.StatusInternalServerError {
		t.Fatalf("status = %d body = %s", response.StatusCode, response.Body)
	}
	if hermesExchangeCalls != 0 {
		t.Fatalf("Hermes enrollment was consumed before control staging: %d calls", hermesExchangeCalls)
	}
}

func TestHermesProfileMultiplexReadyUsesPerProfileCredentials(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		expected := map[string]string{
			"/p/default/v1/capabilities": "default-key",
			"/p/sidon/v1/capabilities":   "sidon-key",
		}
		if request.URL.Path == "/p/wing-link-invalid-probe/v1/capabilities" {
			writer.WriteHeader(http.StatusNotFound)
			return
		}
		if request.Header.Get("Authorization") != "Bearer "+expected[request.URL.Path] {
			writer.WriteHeader(http.StatusUnauthorized)
			return
		}
		writer.WriteHeader(http.StatusOK)
	}))
	defer server.Close()
	origin, err := normalizeOrigin(server.URL)
	if err != nil {
		t.Fatal(err)
	}
	connections := []issuedHermesConnection{
		{ProfileID: "default", Token: "default-key"},
		{ProfileID: "sidon", Token: "sidon-key"},
	}
	if !hermesProfileMultiplexReady(origin, "root-key", connections) {
		t.Fatal("valid per-profile credentials were rejected")
	}
	connections[1].Token = "wrong"
	if hermesProfileMultiplexReady(origin, "root-key", connections) {
		t.Fatal("invalid per-profile credential was accepted")
	}
}

func TestParseHermesProfileListExtractsRows(t *testing.T) {
	rows, err := parseHermesProfileList([]byte(`
 Profile          Model                        Gateway      Alias        Distribution
 ───────────────  ───────────────────────────  ───────────  ───────────  ────────────────────
  default         —                            stopped      —            —
 ◆link            gpt-5.6-sol                  running      link-agent   —
  sidon           gpt-5.6-sol                  running      sidon        —
`))
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) != 3 || rows[0].ID != "default" || rows[0].Model != "" ||
		rows[1].ID != "link" || rows[1].Model != "gpt-5.6-sol" ||
		rows[1].GatewayState != "running" || rows[2].ID != "sidon" {
		t.Fatalf("rows = %#v", rows)
	}
}

func TestParseHermesProfileListRejectsMalformedHeader(t *testing.T) {
	_, err := parseHermesProfileList([]byte(`
Profile Model Gateway
─────── ───── ───────
default — stopped — —
`))
	if err == nil {
		t.Fatal("malformed profile-list header was accepted")
	}
}

func TestParseHermesProfileListRejectsUnknownRow(t *testing.T) {
	_, err := parseHermesProfileList([]byte(`
Profile Model Gateway Alias Distribution
─────── ───── ─────── ───── ────────────
default — stopped — —
Hermes changed this format
`))
	if err == nil {
		t.Fatal("unknown profile-list row was accepted")
	}
}

func TestParseHermesProfileListRejectsShortPlausibleRow(t *testing.T) {
	_, err := parseHermesProfileList([]byte(`
Profile Model Gateway Alias Distribution
─────── ───── ─────── ───── ────────────
intruder running
`))
	if err == nil {
		t.Fatal("short plausible profile-list row was accepted")
	}
}

func TestCompatibilityHermesEnrollmentUsesProfileCLI(t *testing.T) {
	directory := t.TempDir()
	hermesPath := filepath.Join(directory, "hermes")
	script := `#!/bin/sh
if [ "$1 $2" = "profile list" ]; then
 /bin/cat <<'EOF'
 Profile          Model                        Gateway      Alias        Distribution
 ───────────────  ───────────────────────────  ───────────  ───────────  ────────────────────
  default         —                            stopped      —            —
  sidon           gpt-5.6-sol                  running      sidon        —
EOF
 exit
fi
if [ "$1" = "--profile" ] && [ "$3 $4" = "config env-path" ]; then
 if [ "$2" = "default" ]; then /bin/printf '%s\n' "$HOME/.hermes/.env"; else /bin/printf '%s\n' "$HOME/.hermes/profiles/$2/.env"; fi
 exit
fi
exit 1
`
	if err := os.WriteFile(hermesPath, []byte(script), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(directory, ".hermes", "profiles", "sidon"), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(directory, ".hermes", ".env"), []byte("API_SERVER_KEY=default-key\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(directory, ".hermes", "profiles", "sidon", ".env"), []byte("API_SERVER_KEY=sidon-key\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	t.Setenv("HOME", directory)
	t.Setenv("PATH", directory)
	origin, err := normalizeOrigin("http://127.0.0.1:8642")
	if err != nil {
		t.Fatal(err)
	}

	issued, err := compatibilityHermesEnrollment(origin, "full-key", "BlueBlack")
	if err != nil {
		t.Fatal(err)
	}
	if issued.Token != "full-key" || len(issued.Connections) != 2 {
		t.Fatalf("issued = %#v", issued)
	}
	if issued.Connections[0].ProfileID != "default" || issued.Connections[0].Origin != "http://127.0.0.1:8642/p/default" || issued.Connections[0].Token != "full-key" || issued.Connections[0].Label != "BlueBlack · default" {
		t.Fatalf("default connection = %#v", issued.Connections[0])
	}
	if issued.Connections[1].ProfileID != "sidon" || issued.Connections[1].Origin != "http://127.0.0.1:8642/p/sidon" || issued.Connections[1].Token != "sidon-key" || issued.Connections[0].CredentialID == issued.Connections[1].CredentialID {
		t.Fatalf("sidon connection = %#v", issued.Connections[1])
	}
}

func TestScopedHermesExchangeRelaysAuthoritativeConnectionBundle(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if request.URL.Path != "/v1/operator/enrollments/exchange" {
			writer.WriteHeader(http.StatusNotFound)
			return
		}
		writePairJSON(writer, http.StatusOK, map[string]any{
			"token": "hop_default", "credential_id": "hoc_default",
			"connections": []map[string]any{
				{"profile_id": "default", "origin": serverURL(request), "token": "hop_default", "credential_id": "hoc_default", "label": "default"},
				{"profile_id": "sidon", "origin": serverURL(request) + "/p/sidon", "token": "hop_sidon", "credential_id": "hoc_sidon", "label": "sidon"},
			},
		})
	}))
	defer server.Close()
	origin, err := normalizeOrigin(server.URL)
	if err != nil {
		t.Fatal(err)
	}

	issued, err := exchangeScopedHermesEnrollment(pairOptions{
		Origin: origin, ScopedEnrollmentCode: "scoped-code",
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(issued.Connections) != 2 || issued.Connections[1].ProfileID != "sidon" || issued.Connections[1].Token != "hop_sidon" {
		t.Fatalf("issued connections = %#v", issued.Connections)
	}
}

func serverURL(request *http.Request) string {
	return "http://" + request.Host
}

func TestNormalizeOriginRejectsInvalidPorts(t *testing.T) {
	for _, origin := range []string{"http://127.0.0.1:0", "http://127.0.0.1:65536"} {
		if _, err := normalizeOrigin(origin); err == nil {
			t.Fatalf("invalid port accepted: %s", origin)
		}
	}
}

func TestNormalizeOriginRejectsWildcardHosts(t *testing.T) {
	for _, origin := range []string{"http://0.0.0.0:8642", "http://[::]:8642"} {
		if _, err := normalizeOrigin(origin); err == nil {
			t.Fatalf("wildcard origin accepted: %s", origin)
		}
	}
}

func TestPreferredPairingIPPrefersTailscale(t *testing.T) {
	addresses := []net.Addr{
		&net.IPNet{IP: net.ParseIP("192.168.1.20"), Mask: net.CIDRMask(24, 32)},
		&net.IPNet{IP: net.ParseIP("100.90.80.70"), Mask: net.CIDRMask(10, 32)},
	}
	got, err := preferredPairingIP(addresses)
	if err != nil {
		t.Fatal(err)
	}
	if got != "100.90.80.70" {
		t.Fatalf("address = %s", got)
	}
}

func TestPreferredPairingIPAcceptsPrivateIPv6OnlyHosts(t *testing.T) {
	got, err := preferredPairingIP([]net.Addr{
		&net.IPNet{IP: net.ParseIP("fd12:3456:789a::20"), Mask: net.CIDRMask(64, 128)},
	})
	if err != nil {
		t.Fatal(err)
	}
	if got != "fd12:3456:789a::20" {
		t.Fatalf("address = %s", got)
	}
}

func TestPreferredPairingIPRejectsPublicOnlyAddresses(t *testing.T) {
	_, err := preferredPairingIP([]net.Addr{
		&net.IPNet{IP: net.ParseIP("8.8.8.8"), Mask: net.CIDRMask(24, 32)},
	})
	if err == nil {
		t.Fatal("public address accepted")
	}
}

func TestReadHermesTokenFile(t *testing.T) {
	path := filepath.Join(t.TempDir(), ".env")
	if err := os.WriteFile(path, []byte("OTHER=value\nAPI_SERVER_KEY='local-secret'\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	token, err := readHermesTokenFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if token != "local-secret" {
		t.Fatalf("token = %q", token)
	}
}

func TestReadHermesTokenFileMatchesDotenvInlineComments(t *testing.T) {
	path := filepath.Join(t.TempDir(), ".env")
	if err := os.WriteFile(path, []byte("API_SERVER_KEY=local-secret # generated by Hermes\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	token, err := readHermesTokenFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if token != "local-secret" {
		t.Fatalf("token = %q", token)
	}
}

func TestDiscoverHermesTokenCreatesMissingAPIKey(t *testing.T) {
	directory := t.TempDir()
	envPath := filepath.Join(directory, ".env")
	if err := os.WriteFile(envPath, []byte("API_SERVER_ENABLED=true\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	hermesPath := filepath.Join(directory, "hermes")
	script := "#!/bin/sh\nprintf '%s\\n' \"$FAKE_HERMES_ENV_PATH\"\n"
	if err := os.WriteFile(hermesPath, []byte(script), 0o700); err != nil {
		t.Fatal(err)
	}
	t.Setenv("FAKE_HERMES_ENV_PATH", envPath)
	t.Setenv("PATH", directory)
	t.Setenv("WING_HERMES_TOKEN", "")
	t.Setenv("WING_HERMES_HOME", directory)

	token, err := discoverHermesToken()
	if err != nil {
		t.Fatal(err)
	}
	if len(token) != 64 {
		t.Fatalf("token length = %d", len(token))
	}
	persisted, err := readHermesTokenFile(envPath)
	if err != nil {
		t.Fatal(err)
	}
	if persisted != token {
		t.Fatal("generated token was not persisted")
	}
	ownerOnly, err := statePathOwnerOnly(envPath, false)
	if err != nil {
		t.Fatal(err)
	}
	if !ownerOnly {
		t.Fatal("generated token file is not owner-only")
	}
}

func TestDiscoverHermesTokenIgnoresDiagnosticPaths(t *testing.T) {
	directory := t.TempDir()
	envPath := filepath.Join(directory, "hermes.env")
	diagnosticPath := filepath.Join(directory, "diagnostic.log")
	if err := os.WriteFile(envPath, []byte("API_SERVER_ENABLED=true\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(diagnosticPath, []byte("diagnostic\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	hermesPath := filepath.Join(directory, "hermes")
	script := "#!/bin/sh\nprintf '%s\\n' \"$FAKE_HERMES_ENV_PATH\"\n/bin/sleep 0.05\nprintf '%s\\n' \"$FAKE_DIAGNOSTIC_PATH\" >&2\n"
	if err := os.WriteFile(hermesPath, []byte(script), 0o700); err != nil {
		t.Fatal(err)
	}
	t.Setenv("FAKE_HERMES_ENV_PATH", envPath)
	t.Setenv("FAKE_DIAGNOSTIC_PATH", diagnosticPath)
	t.Setenv("PATH", directory)
	t.Setenv("WING_HERMES_TOKEN", "")
	t.Setenv("WING_HERMES_HOME", directory)

	token, err := discoverHermesToken()
	if err != nil {
		t.Fatal(err)
	}
	persisted, err := readHermesTokenFile(envPath)
	if err != nil || persisted != token {
		t.Fatalf("Hermes env token = %q, error = %v", persisted, err)
	}
	if _, err := readHermesTokenFile(diagnosticPath); err == nil {
		t.Fatal("API key was written to a diagnostic path")
	}
}

func TestDiscoverHermesTokenRejectsPathOutsideHermesHome(t *testing.T) {
	home := t.TempDir()
	outside := filepath.Join(t.TempDir(), ".env")
	directory := t.TempDir()
	hermesPath := filepath.Join(directory, "hermes")
	script := "#!/bin/sh\nprintf '%s\\n' \"$FAKE_HERMES_ENV_PATH\"\n"
	if err := os.WriteFile(hermesPath, []byte(script), 0o700); err != nil {
		t.Fatal(err)
	}
	t.Setenv("FAKE_HERMES_ENV_PATH", outside)
	t.Setenv("PATH", directory)
	t.Setenv("WING_HERMES_TOKEN", "")
	t.Setenv("WING_HERMES_HOME", home)
	if _, err := discoverHermesToken(); err == nil {
		t.Fatal("outside Hermes env path was accepted")
	}
	if _, err := os.Stat(outside); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("outside path was written: %v", err)
	}
}

func TestEnsureHermesTokenFileSerializesKeyCreation(t *testing.T) {
	envPath := filepath.Join(t.TempDir(), ".env")
	if err := os.WriteFile(envPath, []byte("API_SERVER_ENABLED=true\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	unlock, err := acquireStateLock(envPath + ".wing-link.lock")
	if err != nil {
		t.Fatal(err)
	}
	done := make(chan error, 1)
	go func() {
		_, err := ensureHermesTokenFile(envPath)
		done <- err
	}()
	select {
	case err := <-done:
		t.Fatalf("key creation ignored lock: %v", err)
	case <-time.After(50 * time.Millisecond):
	}
	if err := unlock(); err != nil {
		t.Fatal(err)
	}
	select {
	case err := <-done:
		if err != nil {
			t.Fatal(err)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("key creation did not resume after lock release")
	}
}

func TestPairOperationalErrorIsActionableWithoutGlobalHelp(t *testing.T) {
	t.Setenv("WING_HERMES_TOKEN", "")
	t.Setenv("WING_HERMES_URL", "http://127.0.0.1:8642")
	t.Setenv("PATH", t.TempDir())
	var stdout, stderr bytes.Buffer
	if code := pairCommand(&stdout, &stderr, nil); code != 1 {
		t.Fatalf("exit code = %d", code)
	}
	if !strings.Contains(stderr.String(), "could not find the local Hermes API key") || strings.Contains(stderr.String(), "usage: wing-link") {
		t.Fatalf("stderr = %q", stderr.String())
	}
}

func TestPairOptionsRejectPublicOrigins(t *testing.T) {
	t.Setenv("WING_HERMES_URL", "http://8.8.8.8:8642")
	t.Setenv("WING_HERMES_TOKEN", "secret")
	if _, err := parsePairOptions(nil); err == nil {
		t.Fatal("public pairing origin accepted")
	}
}

func TestPairOptionsEnablesMultiplexAndBuildsCompatibilityConnections(t *testing.T) {
	directory := t.TempDir()
	marker := filepath.Join(directory, "multiplex-enabled")
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if _, err := os.Stat(marker); err == nil {
			switch request.URL.Path {
			case "/p/wing-link-invalid-probe/v1/capabilities":
				writer.WriteHeader(http.StatusNotFound)
				return
			case "/p/default/v1/capabilities":
				if request.Header.Get("Authorization") != "Bearer secret" {
					writer.WriteHeader(http.StatusUnauthorized)
					return
				}
			case "/p/sidon/v1/capabilities":
				if request.Header.Get("Authorization") != "Bearer sidon-key" {
					writer.WriteHeader(http.StatusUnauthorized)
					return
				}
			}
		}
		writePairJSON(writer, http.StatusOK, map[string]any{"endpoints": map[string]any{}})
	}))
	defer server.Close()
	hermesPath := filepath.Join(directory, "hermes")
	script := `#!/bin/sh
if [ "$1" = "--profile" ] && [ "$3 $4" = "config env-path" ]; then
 if [ "$2" = "default" ]; then /bin/printf '%s\n' "$HOME/.hermes/.env"; else /bin/printf '%s\n' "$HOME/.hermes/profiles/$2/.env"; fi
 exit
fi
case "$1 $2" in
 'profile list')
  /bin/printf '%s\n' \
   ' Profile          Model                        Gateway      Alias        Distribution' \
   ' ───────────────  ───────────────────────────  ───────────  ───────────  ────────────────────' \
   '  default         —                            stopped      —            —' \
   '  sidon           gpt-5.6-sol                  running      sidon        —'
  ;;
 'config set') ;;
 'gateway restart') /usr/bin/touch "$FAKE_MULTIPLEX_MARKER" ;;
 *) exit 1 ;;
esac
`
	if err := os.WriteFile(hermesPath, []byte(script), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(directory, ".hermes", "profiles", "sidon"), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(directory, ".hermes", ".env"), []byte("API_SERVER_KEY=default-key\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(directory, ".hermes", "profiles", "sidon", ".env"), []byte("API_SERVER_KEY=sidon-key\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	t.Setenv("HOME", directory)
	t.Setenv("PATH", directory)
	t.Setenv("FAKE_MULTIPLEX_MARKER", marker)
	t.Setenv("WING_HERMES_URL", server.URL)
	t.Setenv("WING_HERMES_TOKEN", "secret")
	t.Setenv("WING_LINK_STATE", filepath.Join(t.TempDir(), "state.json"))
	options, err := parsePairOptions(nil)
	if err != nil {
		t.Fatal(err)
	}
	if options.Origin.String() != server.URL || len(options.Connections) != 2 || options.Connections[0].Token != "secret" || options.Connections[1].ProfileID != "sidon" {
		t.Fatalf("options = %#v", options)
	}
	if _, err := os.Stat(marker); err != nil {
		t.Fatal("pairing did not enable Hermes profile multiplexing")
	}
}

func testPairOptions(t *testing.T, token string) pairOptions {
	t.Helper()
	origin, err := normalizeOrigin("http://127.0.0.1:8642")
	if err != nil {
		t.Fatal(err)
	}
	controlOrigin, err := normalizeOrigin("http://127.0.0.1:8654")
	if err != nil {
		t.Fatal(err)
	}
	return pairOptions{
		Origin: origin, ControlOrigin: controlOrigin,
		ControlState: newStateStore(filepath.Join(t.TempDir(), "state.json")),
		Label:        "phone", Token: token,
	}
}

type pairBrokerResponse struct {
	StatusCode int
	Body       []byte
}

func postPairBroker(t *testing.T, endpoint, origin, code string) pairBrokerResponse {
	t.Helper()
	body, err := json.Marshal(map[string]string{"origin": origin, "code": code})
	if err != nil {
		t.Fatal(err)
	}
	response, err := http.Post(endpoint, "application/json", bytes.NewReader(body))
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = response.Body.Close() }()
	responseBody, err := io.ReadAll(response.Body)
	if err != nil {
		t.Fatal(err)
	}
	return pairBrokerResponse{StatusCode: response.StatusCode, Body: responseBody}
}
