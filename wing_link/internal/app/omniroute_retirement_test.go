package app

import (
	"bytes"
	"net/http"
	"strings"
	"testing"
)

func TestRetiredOmniRouteIntegrationIsUnavailable(t *testing.T) {
	t.Setenv("PATH", t.TempDir())
	t.Setenv("WING_HERMES_HOME", "invalid-relative-home")
	if _, err := parseBootstrapOptions([]string{"--with-omniroute"}); err == nil {
		t.Error("retired installer flag accepted")
	}
	var out, diagnostics bytes.Buffer
	// Help cannot invoke the former runtime or touch an existing installation.
	if run([]string{"omniroute-setup", "--help"}, &out, &diagnostics) != 2 {
		t.Error("retired command still available")
	}
	for _, args := range [][]string{{"omniroute-setup"}, {"setup", "--with-omniroute"}} {
		if run(args, &out, &diagnostics) != 2 {
			t.Errorf("retired CLI action accepted: %v", args)
		}
	}
	out.Reset()
	quickStart(&out)
	usage(&out)
	if strings.Contains(strings.ToLower(out.String()), "omniroute") {
		t.Error("help still promotes retired runtime")
	}
	h := newProfileHarness(t)
	meta := h.request(t, http.MethodGet, "/meta", nil, false, nil)
	var metadata struct {
		Capabilities []string `json:"capabilities"`
	}
	decodeBody(t, meta, &metadata)
	for _, capability := range metadata.Capabilities {
		if strings.Contains(capability, "omniroute") {
			t.Error("retired discovery advertised")
		}
	}
	// Invalid input prevents the old handler from making any network request.
	for _, auth := range []bool{false, true} {
		response := h.request(t, http.MethodGet, "/v1/host/omniroute?url=invalid", nil, auth, nil)
		response.Body.Close()
		if response.StatusCode != http.StatusNotFound {
			t.Errorf("retired route status = %d", response.StatusCode)
		}
	}
	for _, key := range []string{"", "must-not-be-forwarded"} {
		response := h.request(t, http.MethodPost, "/v1/profiles", map[string]any{
			"name": "retiredqa", "provider": "omniroute", "model": "example-model", "provider_api_key": key,
		}, true, nil)
		response.Body.Close()
		if response.StatusCode != http.StatusBadRequest {
			t.Errorf("retired setup status = %d", response.StatusCode)
		}
	}
	if len(h.commands) != 0 || len(h.secretCommands) != 0 || len(h.readCommands) != 0 {
		t.Fatal("retired setup invoked Agent")
	}
}
