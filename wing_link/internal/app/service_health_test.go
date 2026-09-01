package app

import (
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"
)

func TestEnsureExternalWingLinkServiceVerifiesLoopbackHealth(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if request.URL.Path != "/healthz" {
			t.Fatalf("path = %q", request.URL.Path)
		}
		writer.WriteHeader(http.StatusOK)
	}))
	defer server.Close()
	origin, err := url.Parse(server.URL)
	if err != nil {
		t.Fatal(err)
	}

	t.Setenv("WING_LINK_SERVICE", "external")
	if err := ensureExternalWingLinkService(origin); err != nil {
		t.Fatal(err)
	}
}

func TestVerifyWingLinkHealthDoesNotFollowRedirects(t *testing.T) {
	target := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		writer.WriteHeader(http.StatusOK)
	}))
	defer target.Close()
	redirect := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		writer.Header().Set("Location", target.URL)
		writer.WriteHeader(http.StatusTemporaryRedirect)
	}))
	defer redirect.Close()
	origin, err := url.Parse(redirect.URL)
	if err != nil {
		t.Fatal(err)
	}

	if err := verifyWingLinkHealth(origin); err == nil {
		t.Fatal("redirected health check unexpectedly succeeded")
	}
}

func TestEnsureExternalWingLinkServiceRejectsManagedMode(t *testing.T) {
	t.Setenv("WING_LINK_SERVICE", "")
	origin, _ := url.Parse("http://127.0.0.1:8654")
	if err := ensureExternalWingLinkService(origin); err == nil {
		t.Fatal("managed service mode was accepted")
	}
}
