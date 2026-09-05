package app

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"time"
)

const omniRouteDiscoveryCapability = "host.omniroute.discover"

type omniRouteDiscovery struct {
	Status string `json:"status"`
}

// Discovery only fingerprints the fixed host-local service. It conveys neither
// trust in that process nor permission to send it any Agent/provider credential.
func discoverOmniRoute(ctx context.Context, client *http.Client) omniRouteDiscovery {
	get := func(path string) (int, []byte) {
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, strings.TrimSuffix(omniRouteBaseURL, "/v1")+path, nil)
		if err != nil {
			return 0, nil
		}
		response, err := client.Do(req)
		if err != nil {
			return 0, nil
		}
		defer response.Body.Close()
		body, err := io.ReadAll(io.LimitReader(response.Body, 65537))
		if err != nil || len(body) > 65536 {
			return response.StatusCode, nil
		}
		return response.StatusCode, body
	}
	status, body := get("/.well-known/agent-card.json")
	if status == 0 {
		return omniRouteDiscovery{"unavailable"}
	}
	var card struct {
		Name string `json:"name"`
	}
	if status != 200 || json.Unmarshal(body, &card) != nil || card.Name != "OmniRoute AI Gateway" {
		return omniRouteDiscovery{"unrecognized"}
	}
	status, body = get("/healthz")
	if status != 200 || strings.TrimSpace(string(body)) != "ok" {
		return omniRouteDiscovery{"starting"}
	}
	status, _ = get("/v1/models")
	if status == 401 || status == 403 {
		return omniRouteDiscovery{"authentication_required"}
	}
	if status != http.StatusOK {
		return omniRouteDiscovery{"starting"}
	}
	// Liveness and catalog access do not prove inference/provider readiness.
	return omniRouteDiscovery{"serving"}
}

func (server *wingLinkServer) serveOmniRouteDiscovery(writer http.ResponseWriter, request *http.Request) {
	if !server.requireScopeAuthorization(writer, request, ScopeHealthRead, false) {
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
	ctx, cancel := context.WithTimeout(request.Context(), 3*time.Second)
	defer cancel()
	client := &http.Client{Timeout: 3 * time.Second, Transport: &http.Transport{Proxy: nil}, CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	defer client.CloseIdleConnections()
	writeJSON(writer, http.StatusOK, discoverOmniRoute(ctx, client))
}
