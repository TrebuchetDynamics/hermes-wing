package app

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/url"
	"path/filepath"
	"strings"
	"time"
	"unicode"
)

const modelOptionsCapability = "profiles.model-options.read"
const maxModelOptionsBytes = 1 << 20

// Only catalog display fields cross the management boundary. Agent credentials,
// custom endpoints, and arbitrary upstream fields must never be forwarded.
type modelOptionProvider struct {
	Slug   string   `json:"slug"`
	Name   string   `json:"name"`
	Models []string `json:"models"`
}
type modelOptionsCatalog struct {
	Providers []modelOptionProvider `json:"providers"`
}

func validCatalogText(value string, limit int) bool {
	return value != "" && len([]rune(value)) <= limit && !strings.Contains(value, "://") && !strings.ContainsFunc(value, unicode.IsControl)
}

func decodeModelOptions(reader io.Reader) (modelOptionsCatalog, error) {
	var catalog modelOptionsCatalog
	body, err := io.ReadAll(io.LimitReader(reader, maxModelOptionsBytes+1))
	if err != nil || len(body) > maxModelOptionsBytes || json.Unmarshal(body, &catalog) != nil || catalog.Providers == nil || len(catalog.Providers) > 128 {
		return catalog, errors.New("invalid model catalog")
	}
	seen := map[string]bool{}
	total := 0
	for i := range catalog.Providers {
		row := &catalog.Providers[i]
		if !validCatalogText(row.Slug, 80) || seen[row.Slug] {
			return modelOptionsCatalog{}, errors.New("invalid catalog provider")
		}
		seen[row.Slug] = true
		if row.Name == "" {
			row.Name = row.Slug
		}
		if !validCatalogText(row.Name, 160) {
			return modelOptionsCatalog{}, errors.New("invalid catalog label")
		}
		if row.Models == nil {
			row.Models = []string{}
		}
		total += len(row.Models)
		if total > 16384 {
			return modelOptionsCatalog{}, errors.New("model catalog exceeds limit")
		}
		for _, model := range row.Models {
			if !validCatalogText(model, 200) {
				return modelOptionsCatalog{}, errors.New("invalid catalog model")
			}
		}
	}
	encoded, err := json.Marshal(catalog)
	if err != nil || len(encoded) >= maxModelOptionsBytes {
		return modelOptionsCatalog{}, errors.New("model catalog exceeds response limit")
	}
	return catalog, nil
}

func newModelOptionsReader(home string, origin *url.URL, readHermes func(context.Context, ...string) ([]byte, error)) func(context.Context, string) (modelOptionsCatalog, error) {
	// The origin is chosen locally at service startup, never from a remote request.
	client := &http.Client{Timeout: 20 * time.Second,
		Transport:     &http.Transport{Proxy: nil, TLSClientConfig: &tls.Config{MinVersion: tls.VersionTLS13}},
		CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
	}
	return func(ctx context.Context, profile string) (modelOptionsCatalog, error) {
		empty := modelOptionsCatalog{}
		if origin == nil || (origin.Scheme != "https" && !(origin.Scheme == "http" && isLoopbackHost(origin.Hostname()))) {
			return empty, errors.New("Agent catalog requires trusted HTTPS or loopback HTTP")
		}
		output, err := readHermes(ctx, "--profile", profile, "config", "env-path")
		path := strings.TrimSpace(string(output))
		if err != nil || !filepath.IsAbs(path) || strings.ContainsAny(path, "\r\n") || !pathWithin(home, path) || rejectSymlinkedAncestors(path) != nil {
			return empty, errors.New("profile credential unavailable")
		}
		// Read only: browsing a catalog must never create a credential or restart Agent.
		token, err := readHermesTokenFile(path)
		if err != nil {
			return empty, err
		}
		scoped := *origin
		scoped.Path = "/p/" + profile
		scoped.RawPath, scoped.RawQuery, scoped.Fragment = "", "", ""
		get := func(path string) (*http.Response, error) {
			target := scoped
			target.Path += path
			request, err := http.NewRequestWithContext(ctx, http.MethodGet, target.String(), nil)
			if err != nil {
				return nil, err
			}
			request.Header.Set("Authorization", "Bearer "+token)
			return client.Do(request)
		}
		response, err := get("/v1/capabilities")
		if err != nil {
			return empty, err
		}
		var capabilities struct {
			Endpoints map[string]apiEndpoint `json:"endpoints"`
			Auth      struct {
				GrantedScopes []string `json:"granted_scopes"`
			} `json:"auth"`
		}
		err = json.NewDecoder(io.LimitReader(response.Body, 256<<10)).Decode(&capabilities)
		_ = response.Body.Close()
		endpoint := capabilities.Endpoints["model_options"]
		if err != nil || response.StatusCode != http.StatusOK || endpoint.Method != http.MethodGet || endpoint.Path != "/api/model/options" {
			return empty, errors.New("Agent model catalog unavailable")
		}
		for _, required := range endpoint.RequiredScopes {
			allowed := false
			for _, granted := range capabilities.Auth.GrantedScopes {
				if granted == "*" || granted == required {
					allowed = true
				}
			}
			if !allowed {
				return empty, errors.New("Agent model catalog grant unavailable")
			}
		}
		response, err = get("/api/model/options")
		if err != nil {
			return empty, err
		}
		defer response.Body.Close()
		if response.StatusCode != http.StatusOK {
			return empty, errors.New("Agent model catalog unavailable")
		}
		return decodeModelOptions(response.Body)
	}
}

func (server *wingLinkServer) serveModelOptions(writer http.ResponseWriter, request *http.Request, profile string) {
	if !server.requireScopeAuthorization(writer, request, ScopeProfilesRead, false) {
		return
	}
	if request.Method != http.MethodGet {
		writer.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	if request.URL.RawQuery != "" {
		writer.WriteHeader(http.StatusBadRequest)
		return
	}
	if server.profiles.readModelOptions == nil {
		writer.WriteHeader(http.StatusNotImplemented)
		return
	}
	server.profileMutations.Lock()
	defer server.profileMutations.Unlock()
	rows, _, err := server.profiles.listWithWarnings()
	if err != nil {
		writeProfileError(writer, err)
		return
	}
	found := false
	for _, row := range rows {
		if row.ID == profile {
			found = true
			break
		}
	}
	if !found {
		writer.WriteHeader(http.StatusNotFound)
		return
	}
	ctx, cancel := context.WithTimeout(request.Context(), 20*time.Second)
	defer cancel()
	catalog, err := server.profiles.readModelOptions(ctx, profile)
	if err != nil {
		writeJSON(writer, http.StatusBadGateway, map[string]any{"error": APIError{Code: "model_catalog_unavailable", Message: "Hermes Agent model catalog is unavailable"}})
		return
	}
	writeJSON(writer, http.StatusOK, catalog)
}
