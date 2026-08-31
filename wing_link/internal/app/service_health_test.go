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

func TestEnsureExternalWingLinkServiceRejectsManagedMode(t *testing.T) {
	t.Setenv("WING_LINK_SERVICE", "")
	origin, _ := url.Parse("http://127.0.0.1:8654")
	if err := ensureExternalWingLinkService(origin); err == nil {
		t.Fatal("managed service mode was accepted")
	}
}
