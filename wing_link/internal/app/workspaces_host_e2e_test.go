package app

import (
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestRemoteDirectoryLoopbackHostBrowseAndRevoke(t *testing.T) {
	statePath := filepath.Join(t.TempDir(), "state.json")
	store := newStateStore(statePath)
	token := stageDirectoryDevice(t, store, "Loopback browser", 21, []string{ScopeDirectoriesRead})

	root := filepath.Join(t.TempDir(), "repository")
	if err := os.MkdirAll(filepath.Join(root, "src"), 0o700); err != nil {
		t.Fatal(err)
	}
	fileName := "private.txt"
	if err := os.WriteFile(filepath.Join(root, fileName), []byte("secret"), 0o600); err != nil {
		t.Fatal(err)
	}
	grants, err := openDirectoryGrantStore(statePath)
	if err != nil {
		t.Fatal(err)
	}
	grant, err := grants.Grant(root)
	if err != nil {
		t.Fatal(err)
	}

	host := httptest.NewServer(newWingLinkServer(&profileBackend{}, store))
	defer host.Close()

	get := func(path string) (int, string) {
		t.Helper()
		request, err := http.NewRequest(http.MethodGet, host.URL+path, nil)
		if err != nil {
			t.Fatal(err)
		}
		request.Header.Set("Authorization", "Bearer "+token)
		response, err := http.DefaultClient.Do(request)
		if err != nil {
			t.Fatal(err)
		}
		defer func() { _ = response.Body.Close() }()
		body, err := io.ReadAll(response.Body)
		if err != nil {
			t.Fatal(err)
		}
		return response.StatusCode, string(body)
	}

	status, body := get(remoteDirectoryBasePath)
	if status != http.StatusOK || strings.Contains(body, root) || strings.Contains(body, fileName) {
		t.Fatalf("roots status=%d body=%q", status, body)
	}
	var roots remoteDirectoryList
	if err := json.Unmarshal([]byte(body), &roots); err != nil || len(roots.Directories) != 1 {
		t.Fatalf("roots=%#v err=%v", roots, err)
	}
	rootEntry := roots.Directories[0]
	if rootEntry.Handle == "" || rootEntry.Name != "repository" {
		t.Fatalf("root entry=%#v", rootEntry)
	}

	childrenPath := remoteDirectoryBasePath + "/" + rootEntry.Handle + "/children"
	status, body = get(childrenPath)
	if status != http.StatusOK || !strings.Contains(body, `"name":"src"`) ||
		strings.Contains(body, root) || strings.Contains(body, fileName) {
		t.Fatalf("children status=%d body=%q", status, body)
	}

	if err := grants.Revoke(grant.ID); err != nil {
		t.Fatal(err)
	}
	status, body = get(childrenPath)
	if status != http.StatusGone || !strings.Contains(body, `"code":"directory_revoked"`) ||
		strings.Contains(body, root) || strings.Contains(body, fileName) || strings.Contains(body, rootEntry.Handle) {
		t.Fatalf("revoked status=%d body=%q", status, body)
	}
}
