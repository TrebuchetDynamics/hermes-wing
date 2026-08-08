package main

import (
	"bufio"
	"bytes"
	"encoding/json"
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
	if inspect.StatusCode != http.StatusOK || !strings.Contains(string(inspect.Body), `"label":"phone"`) {
		t.Fatalf("inspect = %d %s", inspect.StatusCode, inspect.Body)
	}
	exchange := postPairBroker(t, brokerOrigin+"/v1/operator/enrollments/exchange", brokerOrigin, code)
	if exchange.StatusCode != http.StatusOK ||
		!strings.Contains(string(exchange.Body), `"token":"superuser-secret"`) ||
		!strings.Contains(string(exchange.Body), `"wing_link_token":"wlc_`) {
		t.Fatalf("exchange = %d %s", exchange.StatusCode, exchange.Body)
	}
	var issued map[string]any
	if err := json.Unmarshal(exchange.Body, &issued); err != nil {
		t.Fatal(err)
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
	statePath := filepath.Join(t.TempDir(), "state.json")
	controlState := &StateStore{path: statePath}
	controlHandler := newWingLinkServer(&profileBackend{}, controlState)
	healthServer := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if request.URL.Path == "/v1/capabilities" {
			writePairJSON(writer, http.StatusOK, map[string]any{"endpoints": map[string]any{}})
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
	token, credentialID, err := exchangeScopedHermesEnrollment(pairOptions{
		Origin: origin, ScopedEnrollmentCode: code,
	})
	if err != nil || token != "hop_scoped" || credentialID != "hoc_scoped" {
		t.Fatalf("token=%q credential=%q err=%v", token, credentialID, err)
	}
}

func serverURL(request *http.Request) string {
	return "http://" + request.Host
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

func TestPairOptionsAcceptExplicitLocalOrigin(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writePairJSON(writer, http.StatusOK, map[string]any{"endpoints": map[string]any{}})
	}))
	defer server.Close()
	t.Setenv("WING_HERMES_URL", server.URL)
	t.Setenv("WING_HERMES_TOKEN", "secret")
	t.Setenv("WING_LINK_STATE", filepath.Join(t.TempDir(), "state.json"))
	options, err := parsePairOptions(nil)
	if err != nil {
		t.Fatal(err)
	}
	if options.Origin.String() != server.URL {
		t.Fatalf("origin = %s", options.Origin)
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
		ControlState: &StateStore{path: filepath.Join(t.TempDir(), "state.json")},
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
