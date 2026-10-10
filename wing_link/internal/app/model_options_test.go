package app

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func TestModelOptionsRouteAuthorizationIdentityAndErrors(t *testing.T) {
	h := newProfileHarness(t)
	server := h.handler.(*wingLinkServer)
	calls := 0
	server.profiles.readModelOptions = func(_ context.Context, profile string) (modelOptionsCatalog, error) {
		calls++
		if profile != "default" {
			t.Fatalf("wrong profile %q", profile)
		}
		return modelOptionsCatalog{Providers: []modelOptionProvider{{Slug: "unconfigured", Name: "Unconfigured", Models: []string{"example/model"}}}}, nil
	}
	for _, tc := range []struct {
		path, method string
		auth         bool
		status       int
	}{
		{"/v1/profiles/default/model-options", "GET", false, 401},
		{"/v1/profiles/absent/model-options", "GET", true, 404},
		{"/v1/profiles/default/model-options?url=ignored", "GET", true, 400},
		{"/v1/profiles/default/model-options", "POST", true, 405},
		{"/v1/profiles/default/model-options", "GET", true, 200},
	} {
		response := h.request(t, tc.method, tc.path, nil, tc.auth, nil)
		if response.StatusCode != tc.status {
			t.Fatalf("%s status %d", tc.path, response.StatusCode)
		}
		if response.Header.Get("Cache-Control") != "no-store" {
			t.Fatal("catalog cached")
		}
		_ = response.Body.Close()
	}
	if calls != 1 || len(h.commands) != 0 {
		t.Fatal("unauthorized read or mutation")
	}
	server.profiles.readModelOptions = func(context.Context, string) (modelOptionsCatalog, error) {
		return modelOptionsCatalog{}, errors.New("sensitive upstream diagnostic")
	}
	response := h.request(t, "GET", "/v1/profiles/default/model-options", nil, true, nil)
	defer response.Body.Close()
	body, _ := io.ReadAll(response.Body)
	if response.StatusCode != 502 || strings.Contains(string(body), "sensitive") {
		t.Fatal("unsafe catalog error")
	}
}

func TestModelOptionsReaderUsesProfileAuthorityAndProjectsDisplayFields(t *testing.T) {
	home := t.TempDir()
	env := filepath.Join(home, "profile.env")
	if err := os.WriteFile(env, []byte("API_SERVER_KEY=fixture-key\n"), 0600); err != nil {
		t.Fatal(err)
	}
	paths := []string{}
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		paths = append(paths, r.URL.Path)
		if r.Header.Get("Authorization") != "Bearer fixture-key" {
			t.Error("missing Agent credential")
		}
		if r.URL.Path == "/p/link/v1/capabilities" {
			_, _ = io.WriteString(w, `{"endpoints":{"model_options":{"method":"GET","path":"/api/model/options"}}}`)
		} else if r.URL.Path == "/p/link/api/model/options" {
			_, _ = io.WriteString(w, `{"api_key":"must-not-forward","providers":[{"slug":"new-provider","name":"New provider","models":["one","two"],"authenticated":false,"base_url":"must-not-forward"},{"slug":"empty","models":[]}]}`)
		} else {
			t.Errorf("unexpected path %s", r.URL.Path)
			w.WriteHeader(404)
		}
	}))
	defer upstream.Close()
	origin, _ := url.Parse(upstream.URL)
	reader := newModelOptionsReader(home, origin, func(_ context.Context, args ...string) ([]byte, error) {
		if !reflect.DeepEqual(args, []string{"--profile", "link", "config", "env-path"}) {
			t.Fatalf("unexpected command %v", args)
		}
		return []byte(env), nil
	})
	h := newProfileHarness(t)
	h.handler.(*wingLinkServer).profiles.readModelOptions = reader
	response := h.request(t, http.MethodGet, "/v1/profiles/link/model-options", nil, true, nil)
	if response.StatusCode != http.StatusOK {
		t.Fatalf("catalog response %d", response.StatusCode)
	}
	var catalog modelOptionsCatalog
	decodeBody(t, response, &catalog)
	body, _ := json.Marshal(catalog)
	if len(catalog.Providers) != 2 || strings.Contains(string(body), "must-not-forward") {
		t.Fatal("catalog lost provider or leaked metadata")
	}
	if !reflect.DeepEqual(paths, []string{"/p/link/v1/capabilities", "/p/link/api/model/options"}) {
		t.Fatal(paths)
	}
}

func TestModelOptionsReaderRejectsRedirectsAndUnsafeCredentialPaths(t *testing.T) {
	home := t.TempDir()
	env := filepath.Join(home, ".env")
	if err := os.WriteFile(env, []byte("API_SERVER_KEY=fixture-key\n"), 0600); err != nil {
		t.Fatal(err)
	}
	redirected := false
	target := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { redirected = true }))
	defer target.Close()
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { http.Redirect(w, r, target.URL, 302) }))
	defer upstream.Close()
	origin, _ := url.Parse(upstream.URL)
	reader := newModelOptionsReader(home, origin, func(context.Context, ...string) ([]byte, error) { return []byte(env), nil })
	if _, err := reader(context.Background(), "default"); err == nil || redirected {
		t.Fatal("followed redirect")
	}
	reader = newModelOptionsReader(home, origin, func(context.Context, ...string) ([]byte, error) {
		return []byte(filepath.Join(t.TempDir(), "outside.env")), nil
	})
	if _, err := reader(context.Background(), "default"); err == nil {
		t.Fatal("accepted outside credential path")
	}
}

func TestModelOptionsBoundsRejectRatherThanTruncate(t *testing.T) {
	for _, body := range []string{`{}`, `{"providers":[{"slug":"x","models":["bad\nmodel"]}]}`, `{"providers":[{"slug":"x"},{"slug":"x"}]}`, strings.Repeat(" ", maxModelOptionsBytes+1)} {
		if _, err := decodeModelOptions(strings.NewReader(body)); err == nil {
			t.Fatal("invalid catalog accepted")
		}
	}
	models := make([]string, 300)
	for i := range models {
		models[i] = "example/model"
	}
	body, _ := json.Marshal(modelOptionsCatalog{Providers: []modelOptionProvider{{Slug: "all", Name: "All", Models: models}}})
	catalog, err := decodeModelOptions(strings.NewReader(string(body)))
	if err != nil || len(catalog.Providers[0].Models) != 300 {
		t.Fatal("catalog silently truncated")
	}
}

func TestModelOptionsRequiresAcknowledgedProfileGrant(t *testing.T) {
	h := newProfileHarness(t)
	server := h.handler.(*wingLinkServer)
	server.profiles.readModelOptions = func(context.Context, string) (modelOptionsCatalog, error) {
		t.Fatal("catalog invoked without grant")
		return modelOptionsCatalog{}, nil
	}
	for _, scopes := range [][]string{{ScopeHealthRead}, {ScopeProfilesRead}} {
		id, token, err := server.state.StageBearerDeviceCredential("catalog-test", scopes)
		if err != nil {
			t.Fatal(err)
		}
		if scopes[0] == ScopeHealthRead {
			if err := server.state.AcknowledgeControlToken(id, token); err != nil {
				t.Fatal(err)
			}
		}
		r := httptest.NewRequest("GET", "/v1/profiles/default/model-options", nil)
		r.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		server.ServeHTTP(w, r)
		if w.Code != 401 {
			t.Fatalf("grant/pending status %d", w.Code)
		}
	}
}

func TestModelOptionsAuditContainsOnlyOperationName(t *testing.T) {
	r := httptest.NewRequest("GET", "/v1/profiles/default/model-options", nil)
	if got := auditOperationForRequest(r); got != "profile.model-options.read" {
		t.Fatal(got)
	}
}

func TestSetupCapabilitiesAreAdvertisedByServer(t *testing.T) {
	h := newProfileHarness(t)
	server := h.handler.(*wingLinkServer)
	server.profiles.readModelOptions = func(context.Context, string) (modelOptionsCatalog, error) { return modelOptionsCatalog{}, nil }
	response := h.request(t, "GET", "/meta", nil, false, nil)
	defer response.Body.Close()
	var metadata struct {
		Capabilities []string `json:"capabilities"`
	}
	if err := json.NewDecoder(response.Body).Decode(&metadata); err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{modelOptionsCapability} {
		found := false
		for _, got := range metadata.Capabilities {
			if got == want {
				found = true
			}
		}
		if !found {
			t.Fatalf("missing advertised capability %s", want)
		}
	}
}
