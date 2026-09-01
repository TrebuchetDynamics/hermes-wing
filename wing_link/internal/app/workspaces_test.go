package app

import (
	"bytes"
	"crypto/ed25519"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"
	"time"

	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/audit"
	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/workspaces"
)

func stageDirectoryDevice(t *testing.T, store *StateStore, name string, seed byte, scopes []string) string {
	t.Helper()
	id, token, err := store.StageDeviceCredential(
		name,
		ed25519.PublicKey(bytes.Repeat([]byte{seed}, ed25519.PublicKeySize)),
		scopes,
	)
	if err != nil {
		t.Fatal(err)
	}
	if err := store.AcknowledgeControlToken(id, token); err != nil {
		t.Fatal(err)
	}
	return token
}

func directoryTestStatePath(t *testing.T) string {
	t.Helper()
	directory, err := filepath.EvalSymlinks(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	return filepath.Join(directory, "state.json")
}

func fetchDirectoryRoot(t *testing.T, handler http.Handler, token string) remoteDirectory {
	t.Helper()
	request := httptest.NewRequest(http.MethodGet, remoteDirectoryBasePath, nil)
	request.Header.Set("Authorization", "Bearer "+token)
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusOK {
		t.Fatalf("roots status=%d body=%q", response.Code, response.Body.String())
	}
	var payload remoteDirectoryList
	if err := json.Unmarshal(response.Body.Bytes(), &payload); err != nil || len(payload.Directories) != 1 {
		t.Fatalf("roots=%#v err=%v", payload, err)
	}
	return payload.Directories[0]
}

func TestRemoteDirectoryRoutesReturnHandlesAndNamesOnly(t *testing.T) {
	statePath := directoryTestStatePath(t)
	store := newStateStore(statePath)
	credentialID, token, err := store.StageDeviceCredential(
		"Folder browser",
		ed25519.PublicKey(bytes.Repeat([]byte{9}, ed25519.PublicKeySize)),
		[]string{ScopeDirectoriesRead},
	)
	if err != nil {
		t.Fatal(err)
	}
	if err := store.AcknowledgeControlToken(credentialID, token); err != nil {
		t.Fatal(err)
	}
	root := filepath.Join(t.TempDir(), "repository")
	child := filepath.Join(root, "src")
	if err := os.MkdirAll(child, 0o700); err != nil {
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
	if _, err := grants.Grant(root); err != nil {
		t.Fatal(err)
	}
	handler := newWingLinkServer(&profileBackend{}, store)

	request := httptest.NewRequest(http.MethodGet, "/v2/directories", nil)
	request.Header.Set("Authorization", "Bearer "+token)
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusOK {
		t.Fatalf("roots status=%d body=%q", response.Code, response.Body.String())
	}
	var roots struct {
		Directories []struct {
			Handle string `json:"handle"`
			Name   string `json:"name"`
		} `json:"directories"`
	}
	if err := json.Unmarshal(response.Body.Bytes(), &roots); err != nil || len(roots.Directories) != 1 {
		t.Fatalf("roots=%#v err=%v", roots, err)
	}

	request = httptest.NewRequest(
		http.MethodGet,
		"/v2/directories/"+url.PathEscape(roots.Directories[0].Handle)+"/children?offset=0&limit=50",
		nil,
	)
	request.Header.Set("Authorization", "Bearer "+token)
	response = httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusOK || !strings.Contains(response.Body.String(), `"name":"src"`) {
		t.Fatalf("children status=%d body=%q", response.Code, response.Body.String())
	}
	for _, forbidden := range []string{root, child, fileName} {
		if strings.Contains(response.Body.String(), forbidden) {
			t.Fatalf("response exposed %q: %q", forbidden, response.Body.String())
		}
	}
	if response.Header().Get("Cache-Control") != "no-store" || response.Header().Get("Wing-Protocol") == "" {
		t.Fatalf("missing response safety headers: %v", response.Header())
	}

	auditLog, err := openAuditLog(statePath)
	if err != nil {
		t.Fatal(err)
	}
	events, err := auditLog.List()
	if err != nil || len(events) != 2 || events[0].Operation != "directory.roots.read" || events[1].Operation != "directory.children.read" {
		t.Fatalf("audit=%#v err=%v", events, err)
	}
	auditBytes, err := os.ReadFile(filepath.Join(filepath.Dir(statePath), "wing-link-audit.jsonl"))
	if err != nil {
		t.Fatal(err)
	}
	for _, forbidden := range []string{root, child, fileName, roots.Directories[0].Handle, "src"} {
		if strings.Contains(string(auditBytes), forbidden) {
			t.Fatalf("audit exposed %q: %q", forbidden, auditBytes)
		}
	}
}

func TestRemoteDirectoryRoutesEnforceScopeAndStrictRequests(t *testing.T) {
	statePath := directoryTestStatePath(t)
	store := newStateStore(statePath)
	directoryToken := stageDirectoryDevice(t, store, "Folder browser", 10, []string{ScopeDirectoriesRead})
	healthToken := stageDirectoryDevice(t, store, "Health only", 11, []string{ScopeHealthRead})
	root := filepath.Join(t.TempDir(), "repository")
	if err := os.MkdirAll(filepath.Join(root, "src"), 0o700); err != nil {
		t.Fatal(err)
	}
	grants, err := openDirectoryGrantStore(statePath)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := grants.Grant(root); err != nil {
		t.Fatal(err)
	}
	handler := newWingLinkServer(&profileBackend{}, store)
	rootEntry := fetchDirectoryRoot(t, handler, directoryToken)
	childrenPath := remoteDirectoryBasePath + "/" + rootEntry.Handle + "/children"

	for _, testCase := range []struct {
		name   string
		method string
		path   string
		body   string
		token  string
		status int
		code   string
	}{
		{name: "missing token", method: http.MethodGet, path: remoteDirectoryBasePath, status: http.StatusUnauthorized, code: "unauthorized"},
		{name: "missing scope", method: http.MethodGet, path: remoteDirectoryBasePath, token: healthToken, status: http.StatusUnauthorized, code: "unauthorized"},
		{name: "malformed handle", method: http.MethodGet, path: remoteDirectoryBasePath + "/dirh_bad/children", token: directoryToken, status: http.StatusNotFound, code: "directory_unavailable"},
		{name: "negative offset", method: http.MethodGet, path: childrenPath + "?offset=-1", token: directoryToken, status: http.StatusBadRequest, code: "invalid_request"},
		{name: "large offset", method: http.MethodGet, path: childrenPath + "?offset=1001", token: directoryToken, status: http.StatusBadRequest, code: "invalid_request"},
		{name: "zero limit", method: http.MethodGet, path: childrenPath + "?limit=0", token: directoryToken, status: http.StatusBadRequest, code: "invalid_request"},
		{name: "large limit", method: http.MethodGet, path: childrenPath + "?limit=101", token: directoryToken, status: http.StatusBadRequest, code: "invalid_request"},
		{name: "unknown query", method: http.MethodGet, path: childrenPath + "?path=src", token: directoryToken, status: http.StatusBadRequest, code: "invalid_request"},
		{name: "duplicate query", method: http.MethodGet, path: childrenPath + "?offset=0&offset=1", token: directoryToken, status: http.StatusBadRequest, code: "invalid_request"},
		{name: "malformed query", method: http.MethodGet, path: childrenPath + "?offset=0;path=src", token: directoryToken, status: http.StatusBadRequest, code: "invalid_request"},
		{name: "root query", method: http.MethodGet, path: remoteDirectoryBasePath + "?offset=0", token: directoryToken, status: http.StatusBadRequest, code: "invalid_request"},
		{name: "body", method: http.MethodGet, path: childrenPath, body: `{}`, token: directoryToken, status: http.StatusBadRequest, code: "invalid_request"},
		{name: "trailing path", method: http.MethodGet, path: childrenPath + "/more", token: directoryToken, status: http.StatusBadRequest, code: "invalid_request"},
		{name: "post roots", method: http.MethodPost, path: remoteDirectoryBasePath, status: http.StatusMethodNotAllowed},
		{name: "patch roots", method: http.MethodPatch, path: remoteDirectoryBasePath, status: http.StatusMethodNotAllowed},
		{name: "delete roots", method: http.MethodDelete, path: remoteDirectoryBasePath, status: http.StatusMethodNotAllowed},
		{name: "post children", method: http.MethodPost, path: childrenPath, status: http.StatusMethodNotAllowed},
		{name: "patch children", method: http.MethodPatch, path: childrenPath, status: http.StatusMethodNotAllowed},
		{name: "delete children", method: http.MethodDelete, path: childrenPath, status: http.StatusMethodNotAllowed},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			var body *strings.Reader
			if testCase.body != "" {
				body = strings.NewReader(testCase.body)
			} else {
				body = strings.NewReader("")
			}
			request := httptest.NewRequest(testCase.method, testCase.path, body)
			if testCase.token != "" {
				request.Header.Set("Authorization", "Bearer "+testCase.token)
			}
			response := httptest.NewRecorder()
			handler.ServeHTTP(response, request)
			if response.Code != testCase.status || (testCase.code != "" && !strings.Contains(response.Body.String(), `"code":"`+testCase.code+`"`)) {
				t.Fatalf("status=%d body=%q", response.Code, response.Body.String())
			}
			if response.Header().Get("Cache-Control") != "no-store" || response.Header().Get("Wing-Protocol") == "" {
				t.Fatalf("missing safety headers: %v", response.Header())
			}
		})
	}

	malformedRootQuery := httptest.NewRequest(http.MethodGet, remoteDirectoryBasePath, nil)
	malformedRootQuery.URL.RawQuery = "%zz"
	malformedRootQuery.Header.Set("Authorization", "Bearer "+directoryToken)
	malformedRootResponse := httptest.NewRecorder()
	handler.ServeHTTP(malformedRootResponse, malformedRootQuery)
	if malformedRootResponse.Code != http.StatusBadRequest || !strings.Contains(malformedRootResponse.Body.String(), `"code":"invalid_request"`) {
		t.Fatalf("malformed root query status=%d body=%q", malformedRootResponse.Code, malformedRootResponse.Body.String())
	}

	auditLog, err := openAuditLog(statePath)
	if err != nil {
		t.Fatal(err)
	}
	events, err := auditLog.List()
	if err != nil {
		t.Fatal(err)
	}
	if !slices.ContainsFunc(events, func(event audit.Record) bool {
		return event.Operation == "directory.children.read" && event.Result == audit.ResultInvalidRequest
	}) {
		t.Fatalf("invalid directory request was not typed in audit: %#v", events)
	}
}

func TestRemoteDirectoryHandlesExpireBindToDeviceAndObserveRevocation(t *testing.T) {
	statePath := directoryTestStatePath(t)
	store := newStateStore(statePath)
	firstToken := stageDirectoryDevice(t, store, "First phone", 12, []string{ScopeDirectoriesRead})
	secondToken := stageDirectoryDevice(t, store, "Second phone", 13, []string{ScopeDirectoriesRead})
	root := filepath.Join(t.TempDir(), "repository")
	if err := os.MkdirAll(filepath.Join(root, "src"), 0o700); err != nil {
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
	handler, ok := newWingLinkServer(&profileBackend{}, store).(*wingLinkServer)
	if !ok {
		t.Fatal("expected a healthy Wing Link server")
	}
	rootEntry := fetchDirectoryRoot(t, handler, firstToken)
	childrenPath := remoteDirectoryBasePath + "/" + rootEntry.Handle + "/children"

	wrongDevice := httptest.NewRequest(http.MethodGet, childrenPath, nil)
	wrongDevice.Header.Set("Authorization", "Bearer "+secondToken)
	wrongResponse := httptest.NewRecorder()
	handler.ServeHTTP(wrongResponse, wrongDevice)
	if wrongResponse.Code != http.StatusNotFound || strings.Contains(wrongResponse.Body.String(), rootEntry.Handle) {
		t.Fatalf("wrong-device status=%d body=%q", wrongResponse.Code, wrongResponse.Body.String())
	}

	if err := grants.Revoke(grant.ID); err != nil {
		t.Fatal(err)
	}
	revoked := httptest.NewRequest(http.MethodGet, childrenPath, nil)
	revoked.Header.Set("Authorization", "Bearer "+firstToken)
	revokedResponse := httptest.NewRecorder()
	handler.ServeHTTP(revokedResponse, revoked)
	if revokedResponse.Code != http.StatusGone || !strings.Contains(revokedResponse.Body.String(), `"code":"directory_revoked"`) {
		t.Fatalf("revoked status=%d body=%q", revokedResponse.Code, revokedResponse.Body.String())
	}

	if _, err := grants.Grant(root); err != nil {
		t.Fatal(err)
	}
	now := time.Unix(100, 0)
	handler.directories = workspaces.NewBrowser(grants, func() time.Time { return now }, randomSecret)
	removed := fetchDirectoryRoot(t, handler, firstToken)
	if err := os.RemoveAll(root); err != nil {
		t.Fatal(err)
	}
	removedRequest := httptest.NewRequest(http.MethodGet, remoteDirectoryBasePath+"/"+removed.Handle+"/children", nil)
	removedRequest.Header.Set("Authorization", "Bearer "+firstToken)
	removedResponse := httptest.NewRecorder()
	handler.ServeHTTP(removedResponse, removedRequest)
	if removedResponse.Code != http.StatusConflict || !strings.Contains(removedResponse.Body.String(), `"code":"directory_unavailable"`) {
		t.Fatalf("removed status=%d body=%q", removedResponse.Code, removedResponse.Body.String())
	}
	if err := os.MkdirAll(filepath.Join(root, "src"), 0o700); err != nil {
		t.Fatal(err)
	}
	expiring := fetchDirectoryRoot(t, handler, firstToken)
	now = now.Add(15 * time.Minute)
	expiredRequest := httptest.NewRequest(http.MethodGet, remoteDirectoryBasePath+"/"+expiring.Handle+"/children", nil)
	expiredRequest.Header.Set("Authorization", "Bearer "+firstToken)
	expiredResponse := httptest.NewRecorder()
	handler.ServeHTTP(expiredResponse, expiredRequest)
	if expiredResponse.Code != http.StatusNotFound || !strings.Contains(expiredResponse.Body.String(), `"code":"directory_unavailable"`) {
		t.Fatalf("expired status=%d body=%q", expiredResponse.Code, expiredResponse.Body.String())
	}
}

func TestRemoteDirectoryTooLargeReturnsNoPartialInventory(t *testing.T) {
	for _, testCase := range []struct {
		name     string
		populate func(*testing.T, string)
	}{
		{
			name: "total entries",
			populate: func(t *testing.T, root string) {
				for index := 0; index <= 4096; index++ {
					if err := os.WriteFile(filepath.Join(root, fmt.Sprintf("file-%04d", index)), nil, 0o600); err != nil {
						t.Fatal(err)
					}
				}
			},
		},
		{
			name: "child directories",
			populate: func(t *testing.T, root string) {
				for index := 0; index <= 1000; index++ {
					if err := os.Mkdir(filepath.Join(root, fmt.Sprintf("dir-%04d", index)), 0o700); err != nil {
						t.Fatal(err)
					}
				}
			},
		},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			statePath := directoryTestStatePath(t)
			store := newStateStore(statePath)
			token := stageDirectoryDevice(t, store, "Folder browser", 14, []string{ScopeDirectoriesRead})
			root := t.TempDir()
			testCase.populate(t, root)
			grants, err := openDirectoryGrantStore(statePath)
			if err != nil {
				t.Fatal(err)
			}
			if _, err := grants.Grant(root); err != nil {
				t.Fatal(err)
			}
			handler := newWingLinkServer(&profileBackend{}, store)
			rootEntry := fetchDirectoryRoot(t, handler, token)
			request := httptest.NewRequest(http.MethodGet, remoteDirectoryBasePath+"/"+rootEntry.Handle+"/children", nil)
			request.Header.Set("Authorization", "Bearer "+token)
			response := httptest.NewRecorder()
			handler.ServeHTTP(response, request)
			if response.Code != http.StatusConflict || !strings.Contains(response.Body.String(), `"code":"directory_too_large"`) || strings.Contains(response.Body.String(), `"directories"`) {
				t.Fatalf("status=%d body=%q", response.Code, response.Body.String())
			}
		})
	}
}

func TestMetadataAdvertisesOnlyAvailableDirectoryReads(t *testing.T) {
	statePath := directoryTestStatePath(t)
	handler := newWingLinkServer(&profileBackend{}, newStateStore(statePath))
	request := httptest.NewRequest(http.MethodGet, "/meta", nil)
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusOK || !strings.Contains(response.Body.String(), `"directories.roots.read"`) || !strings.Contains(response.Body.String(), `"directories.children.read"`) || strings.Contains(response.Body.String(), "projects") {
		t.Fatalf("metadata status=%d body=%q", response.Code, response.Body.String())
	}
}

func TestDirectoryStateFailureOmitsCapabilitiesWithoutDisablingWingLink(t *testing.T) {
	statePath := directoryTestStatePath(t)
	store := newStateStore(statePath)
	token := stageDirectoryDevice(t, store, "Folder browser", 15, []string{ScopeDirectoriesRead})
	directoryState := filepath.Join(filepath.Dir(statePath), "wing-link-directories.json")
	if err := os.WriteFile(directoryState, []byte(`{"schema":1,"unexpected":true}`), 0o600); err != nil {
		t.Fatal(err)
	}
	handler := newWingLinkServer(&profileBackend{}, store)

	metadataRequest := httptest.NewRequest(http.MethodGet, "/meta", nil)
	metadataResponse := httptest.NewRecorder()
	handler.ServeHTTP(metadataResponse, metadataRequest)
	if metadataResponse.Code != http.StatusOK || strings.Contains(metadataResponse.Body.String(), "directories.") {
		t.Fatalf("metadata status=%d body=%q", metadataResponse.Code, metadataResponse.Body.String())
	}

	directoryRequest := httptest.NewRequest(http.MethodGet, remoteDirectoryBasePath, nil)
	directoryRequest.Header.Set("Authorization", "Bearer "+token)
	directoryResponse := httptest.NewRecorder()
	handler.ServeHTTP(directoryResponse, directoryRequest)
	if directoryResponse.Code != http.StatusNotFound || !strings.Contains(directoryResponse.Body.String(), `"code":"directory_unavailable"`) {
		t.Fatalf("directory status=%d body=%q", directoryResponse.Code, directoryResponse.Body.String())
	}
}
