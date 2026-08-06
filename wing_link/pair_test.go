package main

import (
	"bytes"
	"encoding/json"
	"io"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestPairingBrokerInspectsAndExchangesOnce(t *testing.T) {
	origin, err := normalizeOrigin("http://127.0.0.1:8642")
	if err != nil {
		t.Fatal(err)
	}
	broker, err := startPairingBroker(pairOptions{Origin: origin, Label: "phone", Token: "superuser-secret"})
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

	inspect := postPairBroker(t, brokerOrigin+"/v1/operator/enrollments/inspect", origin.String(), code)
	if inspect.StatusCode != http.StatusOK || !strings.Contains(string(inspect.Body), `"label":"phone"`) {
		t.Fatalf("inspect = %d %s", inspect.StatusCode, inspect.Body)
	}
	exchange := postPairBroker(t, brokerOrigin+"/v1/operator/enrollments/exchange", origin.String(), code)
	if exchange.StatusCode != http.StatusOK || !strings.Contains(string(exchange.Body), `"token":"superuser-secret"`) {
		t.Fatalf("exchange = %d %s", exchange.StatusCode, exchange.Body)
	}
	replay := postPairBroker(t, brokerOrigin+"/v1/operator/enrollments/exchange", origin.String(), code)
	if replay.StatusCode != http.StatusGone {
		t.Fatalf("replay status = %d", replay.StatusCode)
	}
	select {
	case <-broker.Done:
	case <-time.After(time.Second):
		t.Fatal("broker did not report exchange")
	}
}

func TestPairingBrokerRejectsWrongOriginAndCode(t *testing.T) {
	origin, err := normalizeOrigin("http://127.0.0.1:8642")
	if err != nil {
		t.Fatal(err)
	}
	broker, err := startPairingBroker(pairOptions{Origin: origin, Label: "phone", Token: "secret"})
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

func TestPairOptionsDefaultToReachableNetwork(t *testing.T) {
	t.Setenv("WING_HERMES_URL", "http://100.100.100.100:8642")
	t.Setenv("WING_HERMES_TOKEN", "secret")
	options, err := parsePairOptions(nil)
	if err != nil {
		t.Fatal(err)
	}
	if options.Origin.String() != "http://100.100.100.100:8642" {
		t.Fatalf("origin = %s", options.Origin)
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
