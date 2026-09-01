package app

import (
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"
)

func TestAndroidIntentURIKeepsTheReviewedWingPayload(t *testing.T) {
	pairing, err := url.Parse("wing://connect?broker=http%3A%2F%2F100.64.0.8%3A43001&code=one-time&origin=http%3A%2F%2F100.64.0.8%3A8642")
	if err != nil {
		t.Fatal(err)
	}
	want := "intent://connect?broker=http%3A%2F%2F100.64.0.8%3A43001&code=one-time&origin=http%3A%2F%2F100.64.0.8%3A8642#Intent;scheme=wing;package=com.trebuchetdynamics.hermes.wing;end"
	if got := androidIntentURI(pairing); got != want {
		t.Fatalf("intent URI = %q, want %q", got, want)
	}
	if got := directWingURI(pairing); got != pairing.String() {
		t.Fatalf("direct URI = %q, want %q", got, pairing)
	}
}

func TestPairOpenURLIsServedByThePairingBroker(t *testing.T) {
	broker, err := startPairingBroker(testPairOptions(t, "superuser-secret"))
	if err != nil {
		t.Fatal(err)
	}
	defer broker.Close()
	if broker.OpenURL == nil || broker.OpenURL.Path != "/open" {
		t.Fatalf("open URL = %v, want broker /open URL", broker.OpenURL)
	}
	if got, want := broker.OpenURL.Scheme+"://"+broker.OpenURL.Host, broker.PairingURI.Query().Get("broker"); got != want {
		t.Fatalf("open URL origin = %q, want %q", got, want)
	}
	client := &http.Client{Timeout: 2 * time.Second}
	response, err := client.Get(broker.OpenURL.String())
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = response.Body.Close() }()
	if response.StatusCode != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.StatusCode, http.StatusOK)
	}
}

func TestPairOpenPageRejectsNonGETRequests(t *testing.T) {
	pairing, _ := url.Parse("wing://connect?code=one-time")
	response := httptest.NewRecorder()
	handlePairOpen(pairing, time.Now().Add(5*time.Minute))(response, httptest.NewRequest(http.MethodPost, "/open", nil))
	if response.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusMethodNotAllowed)
	}
	if response.Header().Get("Allow") != http.MethodGet {
		t.Fatal("missing GET Allow header")
	}
	if response.Header().Get("Cache-Control") != "no-store" {
		t.Fatal("missing no-store on rejected request")
	}
}

func TestPairOpenPageReturnsGoneAfterExpiry(t *testing.T) {
	pairing, _ := url.Parse("wing://connect?code=one-time")
	response := httptest.NewRecorder()
	handlePairOpen(pairing, time.Now().Add(-time.Second))(response, httptest.NewRequest(http.MethodGet, "/open", nil))
	if response.Code != http.StatusGone {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusGone)
	}
	if response.Header().Get("Cache-Control") != "no-store" {
		t.Fatal("missing no-store on expired request")
	}
}

func TestPairOpenPageIsSecureResponsiveAndLaunchesWing(t *testing.T) {
	pairing, _ := url.Parse("wing://connect?origin=http%3A%2F%2F100.64.0.8%3A8642&code=one-time")
	response := httptest.NewRecorder()
	handlePairOpen(pairing, time.Now().Add(5*time.Minute))(response, httptest.NewRequest(http.MethodGet, "/open", nil))
	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}
	for name, want := range map[string]string{
		"Cache-Control":           "no-store",
		"Pragma":                  "no-cache",
		"Referrer-Policy":         "no-referrer",
		"Content-Security-Policy": "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'none'",
		"Content-Type":            "text/html; charset=utf-8",
		"X-Content-Type-Options":  "nosniff",
	} {
		if got := response.Header().Get(name); got != want {
			t.Errorf("%s = %q, want %q", name, got, want)
		}
	}
	body := response.Body.String()
	for _, required := range []string{
		"Open Hermes Wing",
		androidWingPackage,
		"wing://connect?",
		"Single-use pairing request",
		"min-height: 48px",
		":focus-visible",
		"prefers-color-scheme: dark",
		"orientation: landscape",
		"prefers-reduced-motion: reduce",
	} {
		if !strings.Contains(body, required) {
			t.Errorf("page missing %q", required)
		}
	}
	if strings.Contains(body, "api_server_key") || strings.Contains(body, "Bearer ") {
		t.Fatal("bearer material rendered")
	}
}

func TestPairOpenPageUsesBrowserPortableWingURIAsThePrimaryAction(t *testing.T) {
	pairing, _ := url.Parse("wing://connect?code=one-time")
	response := httptest.NewRecorder()
	handlePairOpen(pairing, time.Now().Add(5*time.Minute))(response, httptest.NewRequest(http.MethodGet, "/open", nil))
	body := response.Body.String()

	primary := `<a class="primary" href="wing://connect?code=one-time">Open Hermes Wing</a>`
	fallback := `href="intent://connect?code=one-time#Intent;scheme=wing;package=` + androidWingPackage + `;end"`
	if !strings.Contains(body, primary) {
		t.Fatalf("portable Wing URI is not the primary launch action: %s", body)
	}
	if !strings.Contains(body, fallback) {
		t.Fatalf("Android intent URI fallback is missing: %s", body)
	}
}

func TestPairOpenPageEscapesPairingURI(t *testing.T) {
	pairing := &url.URL{Scheme: "wing", Host: "connect", RawQuery: `code=one-time" onclick="alert(1)`}
	response := httptest.NewRecorder()
	handlePairOpen(pairing, time.Now().Add(5*time.Minute))(response, httptest.NewRequest(http.MethodGet, "/open", nil))
	body := response.Body.String()
	if strings.Contains(body, `" onclick="`) || strings.Contains(body, "<script") {
		t.Fatalf("pairing URI was not HTML escaped: %s", body)
	}
	if !strings.Contains(body, "%22%20onclick%3d%22alert%281%29") {
		t.Fatalf("escaped pairing payload missing from launch links: %s", body)
	}
}
