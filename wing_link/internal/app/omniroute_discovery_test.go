package app

import (
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

type discoveryTransport func(*http.Request) (*http.Response, error)

func (f discoveryTransport) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }
func TestOmniRouteDiscovery(t *testing.T) {
	for _, tc := range []struct {
		name, card, health string
		code               int
		want               string
	}{
		{"ready", `{"name":"OmniRoute AI Gateway","url":"private value"}`, "ok\n", 200, "serving"},
		{"key", `{"name":"OmniRoute AI Gateway"}`, "ok", 401, "authentication_required"},
		{"forbidden", `{"name":"OmniRoute AI Gateway"}`, "ok", 403, "authentication_required"},
		{"models failure", `{"name":"OmniRoute AI Gateway"}`, "ok", 500, "starting"},
		{"models missing", `{"name":"OmniRoute AI Gateway"}`, "ok", 404, "starting"},
		{"models redirect", `{"name":"OmniRoute AI Gateway"}`, "ok", 302, "starting"},
		{"models timeout", `{"name":"OmniRoute AI Gateway"}`, "ok", 0, "starting"},
		{"unrelated", `{"name":"Other"}`, "ok", 200, "unrecognized"},
		{"malformed", `{`, "ok", 200, "unrecognized"},
		{"oversized", strings.Repeat("x", 65537), "ok", 200, "unrecognized"},
		{"starting", `{"name":"OmniRoute AI Gateway"}`, "starting", 200, "starting"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			client := &http.Client{Transport: discoveryTransport(func(r *http.Request) (*http.Response, error) {
				if r.URL.Host != "127.0.0.1:20128" || r.Method != "GET" || r.Header.Get("Authorization") != "" {
					t.Fatal("unsafe request")
				}
				body := tc.card
				code := 200
				switch r.URL.Path {
				case "/healthz":
					body = tc.health
				case "/v1/models":
					if tc.code == 0 {
						return nil, context.DeadlineExceeded
					}
					body = `{"data":[]}`
					code = tc.code
				case "/.well-known/agent-card.json":
				default:
					t.Fatal("unexpected route")
				}
				return &http.Response{StatusCode: code, Body: io.NopCloser(strings.NewReader(body)), Header: make(http.Header)}, nil
			})}
			if got := discoverOmniRoute(context.Background(), client); got.Status != tc.want {
				t.Fatalf("got %s", got.Status)
			}
		})
	}
}
func TestOmniRouteDiscoveryRouteRejectsUnauthorizedAndInput(t *testing.T) {
	h := newProfileHarness(t)
	for _, tc := range []struct {
		method, path string
		auth         bool
		status       int
	}{
		{"GET", "/v1/host/omniroute", false, 401},
		{"POST", "/v1/host/omniroute", true, 405},
		{"GET", "/v1/host/omniroute?url=http://example.invalid", true, 400},
	} {
		response := h.request(t, tc.method, tc.path, nil, tc.auth, nil)
		defer response.Body.Close()
		if response.StatusCode != tc.status {
			t.Fatalf("got %d", response.StatusCode)
		}
	}
}

func TestOmniRouteDiscoveryRequiresAcknowledgedHealthGrant(t *testing.T) {
	h := newProfileHarness(t)
	server := h.handler.(*wingLinkServer)
	for _, scopes := range [][]string{{ScopeProfilesRead}, {ScopeHealthRead}} {
		id, token, err := server.state.StageBearerDeviceCredential("discovery-test", scopes)
		if err != nil {
			t.Fatal(err)
		}
		if scopes[0] == ScopeProfilesRead {
			if err := server.state.AcknowledgeControlToken(id, token); err != nil {
				t.Fatal(err)
			}
		}
		request := httptest.NewRequest("GET", "/v1/host/omniroute", nil)
		request.Header.Set("Authorization", "Bearer "+token)
		response := httptest.NewRecorder()
		server.ServeHTTP(response, request)
		if response.Code != 401 {
			t.Fatalf("unauthorized discovery: %d", response.Code)
		}
	}
}
