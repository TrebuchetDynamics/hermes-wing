package app

import (
	"bufio"
	"bytes"
	"context"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/tls"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"html"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"slices"
	"strconv"
	"strings"
	"testing"
	"time"
)

func TestPairingAdvertiseHostUsesLoopbackForExplicitLocalMode(t *testing.T) {
	host, err := pairingAdvertiseHost(false)
	if err != nil {
		t.Fatal(err)
	}
	if host != "127.0.0.1" {
		t.Fatalf("local pairing host = %q", host)
	}
}

func TestPairOptionsDefaultToRemoteAndQRWithExplicitLinkOverride(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		switch request.URL.Path {
		case "/v1/capabilities":
			writePairJSON(writer, http.StatusOK, map[string]any{
				"endpoints": map[string]any{
					"operator_enrollment_create": map[string]any{"method": http.MethodPost, "path": "/v1/operator/enrollments"},
				},
			})
		case "/v1/operator/enrollments":
			writePairJSON(writer, http.StatusCreated, map[string]any{"pairing_uri": "wing://connect?code=test-code"})
		default:
			writer.WriteHeader(http.StatusNotFound)
		}
	}))
	defer server.Close()
	port := server.Listener.Addr().(*net.TCPAddr).Port
	t.Setenv("WING_HERMES_URL", "")
	t.Setenv("WING_HERMES_PORT", strconv.Itoa(port))
	t.Setenv("WING_HERMES_TOKEN", "secret")
	t.Setenv("WING_LINK_URL", "http://127.0.0.1:8654")
	t.Setenv("WING_LINK_STATE", filepath.Join(t.TempDir(), "state.json"))

	for _, test := range []struct {
		args       []string
		wantRemote bool
		wantLink   bool
		wantQR     bool
	}{
		{wantRemote: true, wantLink: true, wantQR: true},
		{args: []string{"--local"}, wantRemote: false, wantLink: true, wantQR: true},
		{args: []string{"--link"}, wantRemote: true, wantLink: true, wantQR: false},
		{args: []string{"--qr"}, wantRemote: true, wantLink: false, wantQR: true},
		{args: []string{"--same-device"}, wantRemote: false, wantLink: true, wantQR: true},
	} {
		observedRemote := false
		options, err := parsePairOptionsWithAdvertiseHost(test.args, func(remote bool) (pairingAdvertiseAddress, error) {
			observedRemote = remote
			return pairingAdvertiseAddress{Host: "127.0.0.1"}, nil
		})
		if err != nil {
			t.Fatal(err)
		}
		if observedRemote != test.wantRemote {
			t.Fatalf("args %v remote = %t, want %t", test.args, observedRemote, test.wantRemote)
		}
		if options.PrintLink != test.wantLink {
			t.Fatalf("args %v print link = %t, want %t", test.args, options.PrintLink, test.wantLink)
		}
		if options.PrintQR != test.wantQR {
			t.Fatalf("args %v print QR = %t, want %t", test.args, options.PrintQR, test.wantQR)
		}
	}
}

func TestPairOptionsRejectSameDeviceConflicts(t *testing.T) {
	for _, args := range [][]string{
		{"--same-device", "--remote"},
		{"--same-device", "--qr"},
		{"--same-device", "--origin", "http://192.168.1.20:8642"},
	} {
		if _, err := parsePairOptionsWithAdvertiseHost(args, func(bool) (pairingAdvertiseAddress, error) {
			return pairingAdvertiseAddress{Host: "127.0.0.1"}, nil
		}); !errors.Is(err, errPairUsage) {
			t.Fatalf("args %v: err = %v", args, err)
		}
	}
}

func TestSameDeviceOutputContainsOnlyOpenURL(t *testing.T) {
	pairingURI, err := url.Parse("wing://connect?broker=http%3A%2F%2F127.0.0.1%3A43001&code=one-time-code")
	if err != nil {
		t.Fatal(err)
	}
	openURL, err := url.Parse("http://127.0.0.1:43001/open")
	if err != nil {
		t.Fatal(err)
	}
	broker := &pairingBroker{PairingURI: pairingURI, OpenURL: openURL}
	var stdout, stderr bytes.Buffer
	writePairHumanOutput(&stdout, &stderr, broker, pairOptions{SameDevice: true})

	output := stdout.String() + stderr.String()
	if stdout.String() != openURL.String()+"\n" {
		t.Fatalf("stdout = %q", stdout.String())
	}
	if strings.Contains(output, "wing://connect") || strings.Contains(output, "one-time-code") {
		t.Fatalf("same-device output exposed code-bearing handoff: %q", output)
	}
}

func TestPairHumanOutputPrintsOneTimeLinkAndQRByDefault(t *testing.T) {
	pairingURI, err := url.Parse("wing://connect?broker=https%3A%2F%2F100.64.0.8%3A43001&code=one-time")
	if err != nil {
		t.Fatal(err)
	}
	broker := &pairingBroker{PairingURI: pairingURI}
	options := testPairOptions(t, "superuser-secret")
	options.PrintLink = true
	options.PrintQR = true
	var stdout, stderr bytes.Buffer

	writePairHumanOutput(&stdout, &stderr, broker, options)

	if !strings.Contains(stdout.String(), pairingURI.String()+"\n") {
		t.Fatalf("stdout missing pairing link = %q", stdout.String())
	}
	if !strings.Contains(stderr.String(), "Paste pairing link") ||
		!strings.Contains(stderr.String(), "single-use") ||
		!strings.Contains(stderr.String(), "Scan this QR in Hermes Wing:") {
		t.Fatalf("missing manual-link guidance: %q", stderr.String())
	}
	if strings.Contains(stderr.String(), pairingURI.String()) {
		t.Fatal("pairing link was duplicated into diagnostics")
	}
}

func TestPairHumanOutputLeadsWithAndroidSafeURL(t *testing.T) {
	pairingURI, err := url.Parse("wing://connect?broker=http%3A%2F%2F127.0.0.1%3A43001&code=one-time&origin=http%3A%2F%2F127.0.0.1%3A8642")
	if err != nil {
		t.Fatal(err)
	}
	openURL, err := url.Parse("http://127.0.0.1:43001/open")
	if err != nil {
		t.Fatal(err)
	}
	broker := &pairingBroker{PairingURI: pairingURI, OpenURL: openURL}
	options := testPairOptions(t, "superuser-secret")
	options.PrintQR = true
	var stdout, stderr bytes.Buffer

	writePairHumanOutput(&stdout, &stderr, broker, options)

	output := stderr.String()
	if !strings.Contains(output, "On the same device, open:") {
		t.Fatal("missing same-device instruction")
	}
	if !strings.Contains(output, broker.OpenURL.String()) {
		t.Fatal("missing ordinary handoff URL")
	}
	if strings.Contains(output, "pair: code:") {
		t.Fatal("raw code must not be printed separately")
	}
	if strings.Contains(output, broker.PairingURI.String()) {
		t.Fatal("raw wing URI must not be printed")
	}
	if strings.Index(output, broker.OpenURL.String()) > strings.Index(output, "Scan this QR in Hermes Wing:") {
		t.Fatal("same-device path must be presented before QR")
	}
	if !strings.Contains(output, "Review the host, access, and profile count in Hermes Wing, then confirm.") {
		t.Fatal("missing review instruction")
	}
	if !strings.Contains(output, "Leave this command running") ||
		!strings.Contains(output, "Ctrl-C") {
		t.Fatalf("missing wait/cancel instruction: %q", output)
	}
	if stdout.Len() == 0 {
		t.Fatal("missing QR output")
	}
}

func TestPairingBrokerUsesPinnedTLSWithoutVPNOptIn(t *testing.T) {
	options := testPairOptions(t, "superuser-secret")
	options.Origin = &url.URL{Scheme: "http", Host: "0.0.0.0:8642"}
	broker, err := startPairingBroker(options)
	if err != nil {
		t.Fatal(err)
	}
	defer broker.Close()
	brokerOrigin := broker.PairingURI.Query().Get("broker")
	if broker.OpenURL != nil {
		t.Fatalf("remote self-signed broker advertised browser URL %q", broker.OpenURL)
	}
	if !strings.HasPrefix(brokerOrigin, "https://") {
		t.Fatalf("broker origin = %q; want HTTPS", brokerOrigin)
	}
	expectedFingerprint := broker.PairingURI.Query().Get("host_fingerprint")
	if broker.TLSCertificate == nil {
		t.Fatal("remote broker did not retain its TLS certificate")
	}
	roots := x509.NewCertPool()
	roots.AddCert(broker.TLSCertificate)
	client := &http.Client{Transport: &http.Transport{TLSClientConfig: &tls.Config{
		MinVersion: tls.VersionTLS13,
		RootCAs:    roots,
		VerifyConnection: func(connection tls.ConnectionState) error {
			if _, ok := connection.PeerCertificates[0].PublicKey.(*rsa.PublicKey); !ok {
				return errors.New("pairing certificate did not use the durable TLS key")
			}
			digest := sha256.Sum256(connection.PeerCertificates[0].RawSubjectPublicKeyInfo)
			got := "sha256/" + base64.RawURLEncoding.EncodeToString(digest[:])
			if got != expectedFingerprint {
				return fmt.Errorf("pairing identity mismatch: %s", got)
			}
			return nil
		},
	}}}
	body, err := json.Marshal(map[string]string{
		"origin": brokerOrigin,
		"code":   broker.PairingURI.Query().Get("code"),
	})
	if err != nil {
		t.Fatal(err)
	}
	request, err := http.NewRequest(http.MethodPost, brokerOrigin+"/v1/operator/enrollments/inspect", bytes.NewReader(body))
	if err != nil {
		t.Fatal(err)
	}
	request.Header.Set("Content-Type", "application/json")
	response, err := client.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = response.Body.Close() }()
	if response.StatusCode != http.StatusOK {
		t.Fatalf("pinned TLS inspect status = %d", response.StatusCode)
	}
}

func TestPairingBrokerInspectionReportsBoundedConnectionCountWithoutCredentials(t *testing.T) {
	options := testPairOptions(t, "superuser-secret")
	options.CredentialMode = "compatibility_full_access"
	for index := 0; index < 9; index++ {
		options.Connections = append(options.Connections, issuedHermesConnection{
			ProfileID:    fmt.Sprintf("profile-%d", index),
			Origin:       fmt.Sprintf("http://127.0.0.1:8642/p/profile-%d", index),
			Token:        fmt.Sprintf("profile-token-%d", index),
			CredentialID: fmt.Sprintf("credential-%d", index),
			Label:        fmt.Sprintf("Profile %d", index),
		})
	}
	broker, err := startPairingBroker(options)
	if err != nil {
		t.Fatal(err)
	}
	defer broker.Close()

	brokerOrigin := broker.PairingURI.Query().Get("broker")
	response := postPairBroker(
		t,
		brokerOrigin+"/v1/operator/enrollments/inspect",
		brokerOrigin,
		broker.PairingURI.Query().Get("code"),
	)
	if response.StatusCode != http.StatusOK {
		t.Fatalf("inspect = %d %s", response.StatusCode, response.Body)
	}
	var preview map[string]any
	if err := json.Unmarshal(response.Body, &preview); err != nil {
		t.Fatal(err)
	}
	if got := int(preview["connection_count"].(float64)); got != 9 {
		t.Fatalf("connection_count = %d, want 9", got)
	}
	fingerprint := broker.PairingURI.Query().Get("host_fingerprint")
	if fingerprint == "" || preview["host_fingerprint"] != fingerprint {
		t.Fatalf("host fingerprint was not bound across the pairing request: uri=%q preview=%v", fingerprint, preview["host_fingerprint"])
	}
	for _, forbidden := range []string{"connections", "token", "credential_id", "profile_id"} {
		if _, present := preview[forbidden]; present {
			t.Fatalf("inspection exposed %q", forbidden)
		}
	}
	body := string(response.Body)
	if strings.Contains(body, "profile-token-") || strings.Contains(body, "credential-") {
		t.Fatalf("inspection exposed credential material: %s", body)
	}
}

func TestPairingBrokerRejectsCompatibilityBundlesOverOneHundredConnections(t *testing.T) {
	options := testPairOptions(t, "superuser-secret")
	options.CredentialMode = "compatibility_full_access"
	for index := 0; index < 101; index++ {
		options.Connections = append(options.Connections, issuedHermesConnection{
			ProfileID: fmt.Sprintf("profile-%d", index),
		})
	}

	broker, err := startPairingBroker(options)
	if broker != nil || err == nil || !strings.Contains(err.Error(), "at most 100 connections") {
		t.Fatalf("startPairingBroker() = (%v, %v), want nil compatibility bundle limit error", broker, err)
	}
}

func TestPairingBrokerInspectionDefaultsScopedEnrollmentToOneConnection(t *testing.T) {
	options := testPairOptions(t, "superuser-secret")
	options.CredentialMode = "scoped"
	options.Connections = []issuedHermesConnection{{ProfileID: "ignored"}}
	broker, err := startPairingBroker(options)
	if err != nil {
		t.Fatal(err)
	}
	defer broker.Close()

	brokerOrigin := broker.PairingURI.Query().Get("broker")
	response := postPairBroker(
		t,
		brokerOrigin+"/v1/operator/enrollments/inspect",
		brokerOrigin,
		broker.PairingURI.Query().Get("code"),
	)
	var preview map[string]any
	if err := json.Unmarshal(response.Body, &preview); err != nil {
		t.Fatal(err)
	}
	if got := int(preview["connection_count"].(float64)); got != 1 {
		t.Fatalf("connection_count = %d, want 1", got)
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
		!strings.Contains(string(exchange.Body), `"profiles:read"`) ||
		!strings.Contains(string(exchange.Body), `"directories:read"`) ||
		!strings.Contains(string(exchange.Body), `"device:self:revoke"`) {
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
	devices, err := options.ControlState.ListDevices()
	if err != nil {
		t.Fatal(err)
	}
	if len(devices) != 1 || devices[0].Name != "phone" || !devices[0].Bearer || !slices.Contains(devices[0].Scopes, ScopeProfilesWrite) || !slices.Contains(devices[0].Scopes, ScopeDirectoriesRead) {
		t.Fatalf("paired device metadata = %#v", devices)
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
	proof, err := loadLocalPairingProof(statePath)
	if err != nil {
		t.Fatal(err)
	}
	reader, writer := io.Pipe()
	result := make(chan int, 1)
	go func() {
		result <- pairCommand(io.Discard, writer, nil)
		_ = writer.Close()
	}()

	scanner := bufio.NewScanner(reader)
	var openURL string
	var pairOutput strings.Builder
	for scanner.Scan() {
		line := scanner.Text()
		pairOutput.WriteString(line + "\n")
		if strings.Contains(line, "On the same device, open:") {
			if !scanner.Scan() {
				t.Fatal("missing ordinary handoff URL")
			}
			line = scanner.Text()
			pairOutput.WriteString(line + "\n")
			openURL = strings.TrimSpace(strings.TrimPrefix(line, "pair:"))
		}
		if strings.Contains(line, "Review the host, access, and profile count") {
			break
		}
	}
	if openURL == "" {
		t.Fatal("pair output did not include the ordinary handoff URL")
	}
	openResponse, err := http.Get(openURL)
	if err != nil {
		t.Fatal(err)
	}
	openBody, err := io.ReadAll(openResponse.Body)
	_ = openResponse.Body.Close()
	if err != nil {
		t.Fatal(err)
	}
	hrefStart := strings.Index(string(openBody), `href="`)
	if hrefStart < 0 {
		t.Fatalf("open page missing intent link: %s", openBody)
	}
	href := string(openBody)[hrefStart+len(`href="`):]
	hrefEnd := strings.IndexByte(href, '"')
	if hrefEnd < 0 {
		t.Fatalf("open page has malformed intent link: %s", openBody)
	}
	intentURI, err := url.Parse(html.UnescapeString(href[:hrefEnd]))
	if err != nil {
		t.Fatal(err)
	}
	brokerOrigin := intentURI.Query().Get("broker")
	code := intentURI.Query().Get("code")
	if brokerOrigin == "" || code == "" {
		t.Fatalf("intent URI omitted broker or code: %s", intentURI)
	}
	exchangeEndpoint := brokerOrigin + "/v1/operator/enrollments/exchange"
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
	pairOutput.WriteString(scanner.Text() + "\n")
	if strings.Contains(pairOutput.String(), proof) {
		t.Fatal("pair command output exposed the local pairing proof")
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

type pairRoundTripFunc func(*http.Request) (*http.Response, error)

func (roundTrip pairRoundTripFunc) RoundTrip(request *http.Request) (*http.Response, error) {
	return roundTrip(request)
}

func TestScopedHermesRemoteTransportFailureExplainsLoopbackSetup(t *testing.T) {
	origin, err := normalizeOrigin("http://192.0.2.8:8642")
	if err != nil {
		t.Fatal(err)
	}
	client := &http.Client{Transport: pairRoundTripFunc(func(*http.Request) (*http.Response, error) {
		return nil, errors.New("connection refused")
	})}

	_, advertised, err := createScopedHermesEnrollmentWithClient(client, origin, "full-key", "phone")
	if err == nil || advertised {
		t.Fatalf("advertised=%v err=%v", advertised, err)
	}
	message := err.Error()
	for _, want := range []string{"selected remote origin", "setup binds it to loopback", "WING_HERMES_URL", "--local"} {
		if !strings.Contains(message, want) {
			t.Fatalf("error missing %q: %q", want, message)
		}
	}
	if strings.Contains(message, origin.Host) {
		t.Fatalf("error exposed private origin: %q", message)
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
	controlState := newStateStore(filepath.Join(t.TempDir(), "state.json"))
	hostIdentity, err := controlState.HostIdentity()
	if err != nil {
		t.Fatal(err)
	}
	broker, err := startPairingBroker(pairOptions{
		Origin:               hermesOrigin,
		ControlOrigin:        controlOrigin,
		HostIdentity:         hostIdentity,
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
	if len(rows) != 3 || rows[0].ID != "default" || rows[0].Model != "" || rows[0].Current ||
		rows[1].ID != "link" || rows[1].Model != "gpt-5.6-sol" || !rows[1].Current ||
		rows[1].GatewayState != "running" || rows[2].ID != "sidon" || rows[2].Current {
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
 ◆sidon           gpt-5.6-sol                  running      sidon        —
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
	if err := os.WriteFile(filepath.Join(directory, ".hermes", "profiles", "sidon", ".env"), []byte("API_SERVER_KEY=full-key\n"), 0o600); err != nil {
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
	if issued.Connections[1].ProfileID != "sidon" || issued.Connections[1].Origin != "http://127.0.0.1:8642/p/sidon" || issued.Connections[1].Token != "full-key" || issued.Connections[0].CredentialID == issued.Connections[1].CredentialID {
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

func TestPreferredPairingIPPrefersDefaultNetBirdOverlay(t *testing.T) {
	addresses := []net.Addr{
		&net.IPNet{IP: net.ParseIP("192.168.1.20"), Mask: net.CIDRMask(24, 32)},
		&net.IPNet{IP: net.ParseIP("100.100.20.30"), Mask: net.CIDRMask(10, 32)},
	}
	got, err := preferredPairingIP(addresses)
	if err != nil {
		t.Fatal(err)
	}
	if got != "100.100.20.30" {
		t.Fatalf("address = %s", got)
	}
}

func TestOverlayVPNIPRecognizesNetBirdAndTailscaleRanges(t *testing.T) {
	for _, address := range []string{
		"100.100.20.30",
		"fd7a:115c:a1e0::1",
	} {
		if !isOverlayVPNIP(net.ParseIP(address)) {
			t.Fatalf("overlay VPN address rejected: %s", address)
		}
	}
	if isOverlayVPNIP(net.ParseIP("192.168.1.20")) {
		t.Fatal("private LAN address classified as an overlay VPN address")
	}
}

func TestPreferredPairingAddressSelectsIdentifiedCustomNetBirdRange(t *testing.T) {
	selection, err := preferredPairingAddress(
		[]net.Addr{
			&net.IPNet{IP: net.ParseIP("192.168.1.20"), Mask: net.CIDRMask(24, 32)},
		},
		[]meshVPNAddress{{Provider: "NetBird", IP: net.ParseIP("10.80.1.7")}},
	)
	if err != nil {
		t.Fatal(err)
	}
	if selection.Host != "10.80.1.7" || !selection.AutomaticHermesBinding {
		t.Fatalf("selection = %#v", selection)
	}
}

func TestPreferredPairingAddressUsesNetBirdIPv4OnDualStackHost(t *testing.T) {
	selection, err := preferredPairingAddress(nil, []meshVPNAddress{
		{Provider: "NetBird", IP: net.ParseIP("fd00:1234::7")},
		{Provider: "NetBird", IP: net.ParseIP("10.80.1.7")},
	})
	if err != nil {
		t.Fatal(err)
	}
	if selection.Host != "10.80.1.7" || !selection.AutomaticHermesBinding {
		t.Fatalf("selection = %#v", selection)
	}
}

func TestPreferredPairingAddressRejectsDistinctMeshVPNProviders(t *testing.T) {
	_, err := preferredPairingAddress(nil, []meshVPNAddress{
		{Provider: "NetBird", IP: net.ParseIP("10.80.1.7")},
		{Provider: "Tailscale", IP: net.ParseIP("100.90.8.7")},
	})
	if err == nil || !strings.Contains(err.Error(), "multiple mesh VPN addresses") {
		t.Fatalf("err = %v", err)
	}
}

func TestDiscoverMeshVPNAddressesRejectsUntrustedOrNonlocalOutput(t *testing.T) {
	for _, test := range []struct {
		name    string
		address string
		local   bool
	}{
		{name: "public", address: "203.0.113.7", local: true},
		{name: "nonlocal", address: "10.80.1.7", local: false},
	} {
		t.Run(test.name, func(t *testing.T) {
			_, err := discoverMeshVPNAddressesWith(
				func(name string) (string, error) {
					if name == "netbird" {
						return "/usr/bin/netbird", nil
					}
					return "", errors.New("not installed")
				},
				func(_ context.Context, spec CommandSpec, _ int) ([]byte, ProcessResult) {
					if slices.Equal(spec.Args, []string{"status", "--ipv4"}) {
						return []byte(test.address + "\n"), ProcessResult{}
					}
					return nil, ProcessResult{ExitCode: 1, Err: errors.New("unavailable")}
				},
				func(net.IP) bool { return test.local },
			)
			if err == nil || !strings.Contains(err.Error(), "untrusted or nonlocal") {
				t.Fatalf("err = %v", err)
			}
		})
	}
}

func TestDiscoverMeshVPNAddressesSupportsNetBirdIPv4OnlyWithBoundedFixedProbes(t *testing.T) {
	type call struct {
		spec    CommandSpec
		maximum int
	}
	var calls []call
	addresses, err := discoverMeshVPNAddressesWith(
		func(name string) (string, error) { return "/usr/bin/" + name, nil },
		func(_ context.Context, spec CommandSpec, maximum int) ([]byte, ProcessResult) {
			calls = append(calls, call{spec: spec, maximum: maximum})
			if strings.HasSuffix(spec.Path, "/netbird") {
				if slices.Equal(spec.Args, []string{"status", "--ipv4"}) {
					return []byte("10.80.1.7\n"), ProcessResult{}
				}
				return nil, ProcessResult{}
			}
			return nil, ProcessResult{ExitCode: 1, Err: errors.New("not connected")}
		},
		func(ip net.IP) bool { return ip.String() == "10.80.1.7" },
	)
	if err != nil {
		t.Fatal(err)
	}
	if len(addresses) != 1 || addresses[0].Provider != "NetBird" || addresses[0].IP.String() != "10.80.1.7" {
		t.Fatalf("addresses = %#v", addresses)
	}
	if len(calls) != 3 || !slices.Equal(calls[0].spec.Args, []string{"status", "--ipv4"}) ||
		!slices.Equal(calls[1].spec.Args, []string{"status", "--ipv6"}) ||
		calls[0].spec.Timeout != 3*time.Second || calls[0].maximum != 256 {
		t.Fatalf("calls = %#v", calls)
	}
}

func TestDiscoverMeshVPNAddressesSupportsNetBirdIPv6Only(t *testing.T) {
	addresses, err := discoverMeshVPNAddressesWith(
		func(name string) (string, error) {
			if name == "netbird" {
				return "/usr/bin/netbird", nil
			}
			return "", errors.New("not installed")
		},
		func(_ context.Context, spec CommandSpec, _ int) ([]byte, ProcessResult) {
			if slices.Equal(spec.Args, []string{"status", "--ipv6"}) {
				return []byte("fd00:1234::7\n"), ProcessResult{}
			}
			return nil, ProcessResult{}
		},
		func(ip net.IP) bool { return ip.String() == "fd00:1234::7" },
	)
	if err != nil {
		t.Fatal(err)
	}
	if len(addresses) != 1 || addresses[0].Provider != "NetBird" || addresses[0].IP.String() != "fd00:1234::7" {
		t.Fatalf("addresses = %#v", addresses)
	}
}

func TestDiscoverMeshVPNAddressesRejectsTimedOutProviderProbe(t *testing.T) {
	_, err := discoverMeshVPNAddressesWith(
		func(name string) (string, error) {
			if name == "netbird" {
				return "/usr/bin/netbird", nil
			}
			return "", errors.New("not installed")
		},
		func(context.Context, CommandSpec, int) ([]byte, ProcessResult) {
			return nil, ProcessResult{ExitCode: -1, Err: context.DeadlineExceeded}
		},
		func(net.IP) bool { return true },
	)
	if err == nil || !strings.Contains(err.Error(), "NetBird") {
		t.Fatalf("err = %v", err)
	}
}

func TestDiscoverMeshVPNAddressesRejectsOversizedProviderOutput(t *testing.T) {
	_, err := discoverMeshVPNAddressesWith(
		func(name string) (string, error) {
			if name == "netbird" {
				return "/usr/bin/netbird", nil
			}
			return "", errors.New("not installed")
		},
		func(context.Context, CommandSpec, int) ([]byte, ProcessResult) {
			return bytes.Repeat([]byte{'1'}, 256), ProcessResult{ExitCode: -1, Err: errors.New("output too large")}
		},
		func(net.IP) bool { return true },
	)
	if err == nil || !strings.Contains(err.Error(), "NetBird") {
		t.Fatalf("err = %v", err)
	}
}

func TestPrepareAutomaticHermesOriginBindsUnreachableDefaultNetBirdAddress(t *testing.T) {
	origin, err := normalizeOrigin("http://100.100.20.30:8642")
	if err != nil {
		t.Fatal(err)
	}
	probes := 0
	configured := 0
	err = prepareAutomaticHermesOrigin(true, origin, func() int {
		probes++
		if configured == 0 {
			return 0
		}
		return http.StatusOK
	}, func() error {
		configured++
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if configured != 1 || probes != 2 {
		t.Fatalf("configured=%d probes=%d", configured, probes)
	}
}

func TestPrepareAutomaticHermesOriginDoesNotExposeUnverifiedOrExplicitOrigins(t *testing.T) {
	for _, test := range []struct {
		automatic bool
		origin    string
	}{
		{automatic: false, origin: "http://100.100.20.30:8642"},
		{automatic: false, origin: "http://10.0.0.8:8642"},
	} {
		origin, err := normalizeOrigin(test.origin)
		if err != nil {
			t.Fatal(err)
		}
		called := false
		if err := prepareAutomaticHermesOrigin(test.automatic, origin, func() int {
			called = true
			return 0
		}, func() error {
			called = true
			return nil
		}); err != nil {
			t.Fatal(err)
		}
		if called {
			t.Fatalf("automatic=%v origin=%s triggered exposure", test.automatic, test.origin)
		}
	}
}

func TestConfigureHermesVPNOriginUsesFixedCommandShapes(t *testing.T) {
	var commands [][]string
	run := func(_ context.Context, spec CommandSpec, _ func(string)) ProcessResult {
		commands = append(commands, append([]string(nil), spec.Args...))
		return ProcessResult{}
	}
	updatedEnvironment := false
	if err := configureHermesVPNOriginWithRunner("/usr/bin/hermes", "100.100.20.30", true, run, func() error {
		updatedEnvironment = true
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	want := [][]string{
		{"config", "set", "--force", "platforms.api_server.extra.host", "100.100.20.30"},
		{"gateway", "restart"},
	}
	if !slices.EqualFunc(commands, want, slices.Equal) {
		t.Fatalf("commands = %#v, want %#v", commands, want)
	}
	if !updatedEnvironment {
		t.Fatal("Hermes API environment was not updated before restart")
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

func TestAndroidPairHermesResolverUsesOnlyCanonicalTermuxPaths(t *testing.T) {
	fakeDir := t.TempDir()
	fakeHermes := filepath.Join(fakeDir, "hermes")
	if err := os.WriteFile(fakeHermes, []byte("#!/bin/sh\n"), 0o700); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PATH", fakeDir)
	t.Setenv("PREFIX", termuxPrefix)
	t.Setenv("HOME", termuxHome)
	t.Setenv("WING_HERMES_HOME", filepath.Join(termuxHome, ".hermes"))

	if _, _, err := resolvePairHermesExecutableForPlatform("android"); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("PATH Hermes should be ignored by pairing; err = %v", err)
	}

	t.Setenv("WING_HERMES_HOME", filepath.Join(fakeDir, ".hermes"))
	if _, _, err := resolvePairHermesExecutableForPlatform("android"); err == nil {
		t.Fatal("pairing accepted a noncanonical Android Hermes home")
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
	if !strings.Contains(stderr.String(), "local Hermes API key") || strings.Contains(stderr.String(), "usage: wing-link") {
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
   ' ◆default         —                            stopped      —            —' \
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

func TestStageControlCredentialDoesNotRedirectOwnerProof(t *testing.T) {
	statePath := filepath.Join(t.TempDir(), "state.json")
	t.Setenv("WING_LINK_STATE", statePath)
	if _, err := ensureLocalPairingProof(statePath); err != nil {
		t.Fatal(err)
	}
	redirected := false
	target := httptest.NewServer(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		redirected = true
	}))
	defer target.Close()
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.Header().Set("Location", target.URL)
		writer.WriteHeader(http.StatusTemporaryRedirect)
	}))
	defer server.Close()
	origin, err := url.Parse(server.URL)
	if err != nil {
		t.Fatal(err)
	}
	if _, _, err := stageControlCredential(origin, "Phone", []string{ScopeHealthRead}); err == nil {
		t.Fatal("redirecting credential staging unexpectedly succeeded")
	}
	if redirected {
		t.Fatal("local pairing proof followed a redirect")
	}
}

func TestStageControlCredentialUsesLoopbackHTTPAndOwnerProofForRemoteTLSOrigin(t *testing.T) {
	statePath := filepath.Join(t.TempDir(), "state.json")
	t.Setenv("WING_LINK_STATE", statePath)
	proof, err := ensureLocalPairingProof(statePath)
	if err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if request.URL.Path != "/v1/pairing/control-credentials" || request.Method != http.MethodPost {
			t.Fatalf("request=%s %s", request.Method, request.URL.Path)
		}
		if request.Header.Get(localPairingProofHeader) != proof {
			t.Fatal("request omitted the owner-only local pairing proof")
		}
		writeJSON(writer, http.StatusOK, map[string]any{"credential_id": "cred_test", "token": "wlc_test"})
	}))
	defer server.Close()
	origin, err := url.Parse(server.URL)
	if err != nil {
		t.Fatal(err)
	}
	origin.Scheme = "https"
	id, token, err := stageControlCredential(origin, "Phone", []string{ScopeHealthRead})
	if err != nil || id != "cred_test" || token != "wlc_test" {
		t.Fatalf("id=%q token=%q err=%v", id, token, err)
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

func TestProfileTokenUsesConfiguredHomeContainment(t *testing.T) {
	for _, kind := range []string{"configured", "outside", "prefix sibling", "default home", "symlink escape"} {
		t.Run(kind, func(t *testing.T) {
			root := t.TempDir()
			home := filepath.Join(root, "configured")
			native := filepath.Join(root, "native")
			t.Setenv("HOME", native)
			if err := os.MkdirAll(home, 0o700); err != nil {
				t.Fatal(err)
			}
			envPath := filepath.Join(home, "profiles", "coder", ".env")
			switch kind {
			case "outside", "symlink escape":
				envPath = filepath.Join(root, "outside", ".env")
			case "prefix sibling":
				envPath = filepath.Join(home+"-other", ".env")
			case "default home":
				envPath = filepath.Join(native, ".hermes", "profiles", "coder", ".env")
			}
			if err := os.MkdirAll(filepath.Dir(envPath), 0o700); err != nil {
				t.Fatal(err)
			}
			const initial = "OTHER=value\n"
			if err := os.WriteFile(envPath, []byte(initial), 0o600); err != nil {
				t.Fatal(err)
			}
			target := envPath
			if kind == "symlink escape" {
				linked := filepath.Join(home, "linked")
				if err := os.Symlink(filepath.Dir(envPath), linked); err != nil {
					t.Skip("symlinks unavailable")
				}
				envPath = filepath.Join(linked, ".env")
			}
			executable := filepath.Join(root, "hermes")
			if err := os.WriteFile(executable, []byte("#!/bin/sh\nprintf '%s\\n' \"$FAKE_HERMES_ENV_PATH\"\n"), 0o700); err != nil {
				t.Fatal(err)
			}
			t.Setenv("FAKE_HERMES_ENV_PATH", envPath)
			token, err := hermesProfileToken(executable, home, "coder")
			if kind == "configured" {
				if err != nil || len(token) != 64 {
					t.Fatalf("configured home rejected: %v", err)
				}
			} else {
				if err == nil || token != "" {
					t.Fatal("credential path escaped the configured home")
				}
				contents, readErr := os.ReadFile(target)
				if readErr != nil || string(contents) != initial {
					t.Fatal("rejected path was mutated")
				}
			}
		})
	}
}
