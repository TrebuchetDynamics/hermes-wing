package app

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestLocalPairingProofIsOwnerOnlyAndRejectsUnsafeFiles(t *testing.T) {
	statePath := filepath.Join(t.TempDir(), "state.json")
	proof, err := ensureLocalPairingProof(statePath)
	if err != nil {
		t.Fatal(err)
	}
	if !validLocalPairingProof(proof) {
		t.Fatal("generated proof is malformed")
	}
	path := localPairingProofPath(statePath)
	info, err := os.Lstat(path)
	if err != nil {
		t.Fatal(err)
	}
	if !info.Mode().IsRegular() || info.Mode().Perm() != 0o600 || info.Mode()&os.ModeSymlink != 0 {
		t.Fatalf("proof mode = %v", info.Mode())
	}
	loaded, err := loadLocalPairingProof(statePath)
	if err != nil || loaded != proof {
		t.Fatalf("loaded proof did not match: err=%v", err)
	}

	missingState := filepath.Join(t.TempDir(), "state.json")
	if _, err := loadLocalPairingProof(missingState); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("missing proof error = %v", err)
	}
	malformedState := filepath.Join(t.TempDir(), "state.json")
	if err := os.WriteFile(localPairingProofPath(malformedState), []byte("not-a-proof"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := ensureLocalPairingProof(malformedState); err == nil {
		t.Fatal("malformed proof was accepted")
	}

	unsafeState := filepath.Join(t.TempDir(), "state.json")
	target := filepath.Join(t.TempDir(), "target")
	if err := os.WriteFile(target, []byte(proof), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Dir(unsafeState), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(target, localPairingProofPath(unsafeState)); err != nil {
		t.Skipf("symlinks unavailable: %v", err)
	}
	if _, err := ensureLocalPairingProof(unsafeState); err == nil {
		t.Fatal("symlinked proof was accepted")
	}
}

func TestControlCredentialStagingRequiresExactLocalProof(t *testing.T) {
	statePath := filepath.Join(t.TempDir(), "state.json")
	store := newStateStore(statePath)
	handler := newWingLinkServer(&profileBackend{}, store)
	proof, err := loadLocalPairingProof(statePath)
	if err != nil {
		t.Fatal(err)
	}

	request := func(candidate, remoteAddr string) *httptest.ResponseRecorder {
		payload := strings.NewReader(`{"name":"Phone","scopes":["health:read"]}`)
		req := httptest.NewRequest(http.MethodPost, "/v1/pairing/control-credentials", payload)
		req.RemoteAddr = remoteAddr
		req.Header.Set("Content-Type", "application/json")
		if candidate != "" {
			req.Header.Set(localPairingProofHeader, candidate)
		}
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, req)
		return response
	}

	for name, attempt := range map[string]struct {
		proof      string
		remoteAddr string
	}{
		"missing": {remoteAddr: "127.0.0.1:43210"},
		"wrong": {
			proof:      "wlp_" + strings.Repeat("A", 43),
			remoteAddr: "127.0.0.1:43210",
		},
		"non-loopback": {proof: proof, remoteAddr: "192.0.2.1:43210"},
	} {
		response := request(attempt.proof, attempt.remoteAddr)
		if response.Code != http.StatusForbidden {
			t.Fatalf("%s proof status = %d", name, response.Code)
		}
		if (attempt.proof != "" && strings.Contains(response.Body.String(), attempt.proof)) || strings.Contains(response.Body.String(), proof) {
			t.Fatalf("%s response exposed local proof", name)
		}
	}

	response := request(proof, "127.0.0.1:43210")
	if response.Code != http.StatusCreated {
		t.Fatalf("valid proof status = %d body=%s", response.Code, response.Body.String())
	}
	var body map[string]any
	if err := json.Unmarshal(response.Body.Bytes(), &body); err != nil {
		t.Fatal(err)
	}
	if body["credential_id"] == "" || body["token"] == "" {
		t.Fatalf("credential response = %#v", body)
	}
	if strings.Contains(response.Body.String(), proof) {
		t.Fatal("credential response exposed local proof")
	}
}
