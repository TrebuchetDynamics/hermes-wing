package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"
)

type profileHarness struct {
	server   *httptest.Server
	token    string
	home     string
	commands [][]string
}

func newProfileHarness(t *testing.T) *profileHarness {
	t.Helper()
	home := filepath.Join(t.TempDir(), ".hermes")
	if err := os.MkdirAll(filepath.Join(home, "profiles", "link"), 0o700); err != nil {
		t.Fatal(err)
	}
	harness := &profileHarness{home: home}
	backend := &profileBackend{
		home: home,
		runHermes: func(_ context.Context, args ...string) error {
			harness.commands = append(harness.commands, append([]string(nil), args...))
			profiles := filepath.Join(home, "profiles")
			switch {
			case len(args) >= 4 && reflect.DeepEqual(args[:2], []string{"profile", "create"}):
				return os.Mkdir(filepath.Join(profiles, args[2]), 0o700)
			case len(args) == 4 && reflect.DeepEqual(args[:2], []string{"profile", "rename"}):
				return os.Rename(filepath.Join(profiles, args[2]), filepath.Join(profiles, args[3]))
			case len(args) == 4 && reflect.DeepEqual(args[:3], []string{"profile", "delete", "--yes"}):
				return os.RemoveAll(filepath.Join(profiles, args[3]))
			default:
				return errors.New("unexpected command")
			}
		},
	}
	store := &StateStore{path: filepath.Join(t.TempDir(), "state.json"), now: time.Now}
	enrollment, err := store.CreateEnrollment()
	if err != nil {
		t.Fatal(err)
	}
	harness.token, err = store.ExchangeEnrollment(enrollment.Code)
	if err != nil {
		t.Fatal(err)
	}
	harness.server = httptest.NewServer(newWingLinkServer(backend, store))
	t.Cleanup(harness.server.Close)
	return harness
}

func (h *profileHarness) request(t *testing.T, method, path string, body any, authorized bool, headers map[string]string) *http.Response {
	t.Helper()
	var payload []byte
	var err error
	if body != nil {
		payload, err = json.Marshal(body)
		if err != nil {
			t.Fatal(err)
		}
	}
	request, err := http.NewRequest(method, h.server.URL+path, bytes.NewReader(payload))
	if err != nil {
		t.Fatal(err)
	}
	request.Header.Set("Content-Type", "application/json")
	if authorized {
		request.Header.Set("Authorization", "Bearer "+h.token)
	}
	for name, value := range headers {
		request.Header.Set(name, value)
	}
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	return response
}

func decodeBody(t *testing.T, response *http.Response, target any) {
	t.Helper()
	defer func() { _ = response.Body.Close() }()
	if err := json.NewDecoder(response.Body).Decode(target); err != nil {
		t.Fatal(err)
	}
}

func TestPendingCredentialCanVerifyReadsButCannotMutateBeforeAcknowledgment(t *testing.T) {
	store := &StateStore{path: filepath.Join(t.TempDir(), "state.json"), now: time.Now}
	credentialID, token, err := store.StageControlToken()
	if err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(newWingLinkServer(
		&profileBackend{home: t.TempDir()},
		store,
	))
	defer server.Close()

	request, err := http.NewRequest(http.MethodGet, server.URL+"/v1/profiles", nil)
	if err != nil {
		t.Fatal(err)
	}
	request.Header.Set("Authorization", "Bearer "+token)
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusOK {
		t.Fatalf("pending verification status = %d", response.StatusCode)
	}
	_ = response.Body.Close()

	acknowledged, err := http.NewRequest(http.MethodGet, server.URL+"/v1/pairing/acknowledged", nil)
	if err != nil {
		t.Fatal(err)
	}
	acknowledged.Header.Set("Authorization", "Bearer "+token)
	response, err = http.DefaultClient.Do(acknowledged)
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusUnauthorized {
		t.Fatalf("pre-ack status = %d", response.StatusCode)
	}
	_ = response.Body.Close()

	mutation, err := http.NewRequest(
		http.MethodPost,
		server.URL+"/v1/profiles",
		strings.NewReader(`{"name":"blocked"}`),
	)
	if err != nil {
		t.Fatal(err)
	}
	mutation.Header.Set("Authorization", "Bearer "+token)
	response, err = http.DefaultClient.Do(mutation)
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusUnauthorized {
		t.Fatalf("pending mutation status = %d", response.StatusCode)
	}
	_ = response.Body.Close()

	ack, err := http.NewRequest(
		http.MethodPost,
		server.URL+"/v1/auth/credentials/"+credentialID+"/ack",
		http.NoBody,
	)
	if err != nil {
		t.Fatal(err)
	}
	ack.Header.Set("Authorization", "Bearer "+token)
	response, err = http.DefaultClient.Do(ack)
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusOK {
		t.Fatalf("ack status = %d", response.StatusCode)
	}
	_ = response.Body.Close()

	response, err = http.DefaultClient.Do(acknowledged)
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusOK {
		t.Fatalf("post-ack status = %d", response.StatusCode)
	}
	_ = response.Body.Close()

	response, err = http.DefaultClient.Do(request.Clone(context.Background()))
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusOK {
		t.Fatalf("acknowledged management status = %d", response.StatusCode)
	}
	_ = response.Body.Close()
}

func TestManagementAPIUsesIndependentControlTokenAndDoesNotProxyHermes(t *testing.T) {
	harness := newProfileHarness(t)

	unauthorized := harness.request(t, http.MethodGet, "/v1/profiles", nil, false, nil)
	if unauthorized.StatusCode != http.StatusUnauthorized {
		t.Fatalf("unauthorized status = %d", unauthorized.StatusCode)
	}
	_ = unauthorized.Body.Close()

	profiles := harness.request(t, http.MethodGet, "/v1/profiles", nil, true, nil)
	if profiles.StatusCode != http.StatusOK {
		t.Fatalf("profiles status = %d", profiles.StatusCode)
	}
	var listed struct {
		Profiles []profileRow `json:"profiles"`
	}
	decodeBody(t, profiles, &listed)
	if len(listed.Profiles) != 2 || listed.Profiles[0].ID != "default" || listed.Profiles[1].ID != "link" {
		t.Fatalf("profiles = %#v", listed.Profiles)
	}

	proxied := harness.request(t, http.MethodPost, "/v1/chat/completions", map[string]any{}, true, nil)
	if proxied.StatusCode != http.StatusNotFound {
		t.Fatalf("Hermes route status = %d, want 404", proxied.StatusCode)
	}
	_ = proxied.Body.Close()
}

func TestProfileInventoryMergesAPIFirstAndRoutesAdvertisedCreateWithoutCLIFallback(t *testing.T) {
	apiProfiles := map[string]map[string]any{
		"default": {"id": "default", "name": "API Default", "revision": "api-d"},
		"remote":  {"id": "remote", "name": "Remote", "revision": "api-r"},
	}
	failCreate := false
	apiServer := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if request.Header.Get("Authorization") != "Bearer hermes-secret" {
			writer.WriteHeader(http.StatusUnauthorized)
			return
		}
		switch request.URL.Path {
		case "/v1/capabilities":
			writeJSON(writer, http.StatusOK, map[string]any{
				"schema_version": 1,
				"auth":           map[string]any{"granted_scopes": []string{"profiles:read", "profiles:write"}},
				"endpoints": map[string]any{
					"profiles":       map[string]any{"method": "GET", "path": "/api/profiles", "required_scopes": []string{"profiles:read"}},
					"profile_create": map[string]any{"method": "POST", "path": "/api/profiles", "required_scopes": []string{"profiles:write"}},
				},
			})
		case "/api/profiles":
			if request.Method == http.MethodGet {
				profiles := make([]map[string]any, 0, len(apiProfiles))
				for _, profile := range apiProfiles {
					profiles = append(profiles, profile)
				}
				writeJSON(writer, http.StatusOK, map[string]any{"object": "list", "data": profiles})
				return
			}
			if failCreate {
				writer.WriteHeader(http.StatusBadGateway)
				return
			}
			var body map[string]any
			if err := json.NewDecoder(request.Body).Decode(&body); err != nil {
				writer.WriteHeader(http.StatusBadRequest)
				return
			}
			id, _ := body["name"].(string)
			apiProfiles[id] = map[string]any{"id": id, "name": id, "revision": "api-new"}
			writeJSON(writer, http.StatusCreated, map[string]any{"profile": apiProfiles[id]})
		default:
			writer.WriteHeader(http.StatusNotFound)
		}
	}))
	defer apiServer.Close()
	origin, err := url.Parse(apiServer.URL)
	if err != nil {
		t.Fatal(err)
	}
	commands := 0
	backend := &profileBackend{
		home: newProfileHarnessHome(t),
		api:  newHermesProfileAPI(origin, "hermes-secret"),
		runHermes: func(context.Context, ...string) error {
			commands++
			return nil
		},
	}
	backend.api.client = apiServer.Client()

	rows, err := backend.list()
	if err != nil {
		t.Fatal(err)
	}
	defaultRow, ok := findProfileRow(rows, "default")
	if !ok || defaultRow.Source != "both" || defaultRow.Name != "API Default" || defaultRow.APIRevision != "api-d" {
		t.Fatalf("API row did not win merge: %#v", defaultRow)
	}
	if _, ok := findProfileRow(rows, "link"); !ok {
		t.Fatalf("local-only profile missing from merge: %#v", rows)
	}
	remoteRow, ok := findProfileRow(rows, "remote")
	if !ok || remoteRow.Source != "api" {
		t.Fatalf("API-only source = %#v", remoteRow)
	}
	if _, err := backend.create(context.Background(), "created", "default"); err != nil {
		t.Fatal(err)
	}
	if commands != 0 {
		t.Fatalf("advertised API create invoked CLI %d times", commands)
	}

	failCreate = true
	if _, err := backend.create(context.Background(), "failed", "default"); !errors.Is(err, errProfileAPIFailed) {
		t.Fatalf("API failure = %v", err)
	}
	if commands != 0 {
		t.Fatal("API failure fell back to CLI")
	}
}

func newProfileHarnessHome(t *testing.T) string {
	t.Helper()
	home := filepath.Join(t.TempDir(), ".hermes")
	if err := os.MkdirAll(filepath.Join(home, "profiles", "link"), 0o700); err != nil {
		t.Fatal(err)
	}
	return home
}

func TestProfileCreateRenameAndDeleteUseFixedHermesArguments(t *testing.T) {
	harness := newProfileHarness(t)
	created := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{"name": "7qa-agent", "clone_from": "link"}, true, nil)
	if created.StatusCode != http.StatusCreated {
		t.Fatalf("create status = %d", created.StatusCode)
	}
	var createBody struct {
		Profile profileRow `json:"profile"`
	}
	decodeBody(t, created, &createBody)

	renamed := harness.request(t, http.MethodPatch, "/v1/profiles/7qa-agent", map[string]any{
		"name": "maestro_qa", "revision": createBody.Profile.Revision,
	}, true, nil)
	if renamed.StatusCode != http.StatusOK {
		t.Fatalf("rename status = %d", renamed.StatusCode)
	}
	var renameBody struct {
		Profile profileRow `json:"profile"`
	}
	decodeBody(t, renamed, &renameBody)

	deleted := harness.request(t, http.MethodDelete, "/v1/profiles/maestro_qa", nil, true, map[string]string{"If-Match": renameBody.Profile.Revision})
	if deleted.StatusCode != http.StatusOK {
		t.Fatalf("delete status = %d", deleted.StatusCode)
	}
	_ = deleted.Body.Close()

	want := [][]string{
		{"profile", "create", "7qa-agent", "--no-alias", "--clone-from", "link"},
		{"profile", "rename", "7qa-agent", "maestro_qa"},
		{"profile", "delete", "--yes", "maestro_qa"},
	}
	if !reflect.DeepEqual(harness.commands, want) {
		t.Fatalf("commands = %#v, want %#v", harness.commands, want)
	}
}

func TestProfileGrammarAllowsSixtyFourCharactersAndRejectsReservedNames(t *testing.T) {
	harness := newProfileHarness(t)
	name := "1" + strings.Repeat("a", 63)
	response := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{"name": name}, true, nil)
	if response.StatusCode != http.StatusCreated {
		t.Fatalf("64-character name status = %d", response.StatusCode)
	}
	_ = response.Body.Close()

	for _, invalidName := range []string{"root"} {
		response := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{"name": invalidName}, true, nil)
		if response.StatusCode != http.StatusBadRequest {
			t.Fatalf("invalid name %q status = %d", invalidName, response.StatusCode)
		}
		_ = response.Body.Close()
	}
}

func TestProfileCreatePropagatesUnsafeInventoryErrorsWithoutRunningHermes(t *testing.T) {
	harness := newProfileHarness(t)
	if err := os.RemoveAll(filepath.Join(harness.home, "profiles")); err != nil {
		t.Fatal(err)
	}
	outside := t.TempDir()
	if err := os.Symlink(outside, filepath.Join(harness.home, "profiles")); err != nil {
		t.Fatal(err)
	}
	response := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{"name": "unsafe"}, true, nil)
	if response.StatusCode != http.StatusServiceUnavailable {
		t.Fatalf("unsafe inventory status = %d", response.StatusCode)
	}
	_ = response.Body.Close()
	if len(harness.commands) != 0 {
		t.Fatalf("unsafe create ran Hermes: %#v", harness.commands)
	}
}

func TestProfileCreateRejectsSymlinkedProfileChild(t *testing.T) {
	harness := newProfileHarness(t)
	if err := os.Symlink(t.TempDir(), filepath.Join(harness.home, "profiles", "unsafe")); err != nil {
		t.Fatal(err)
	}
	response := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{"name": "newprofile"}, true, nil)
	if response.StatusCode != http.StatusServiceUnavailable {
		t.Fatalf("symlink child status = %d", response.StatusCode)
	}
	_ = response.Body.Close()
	if len(harness.commands) != 0 {
		t.Fatalf("symlink child ran Hermes: %#v", harness.commands)
	}
}

func TestProfileMutationRejectsStaleRevision(t *testing.T) {
	harness := newProfileHarness(t)
	response := harness.request(t, http.MethodDelete, "/v1/profiles/link", nil, true, map[string]string{"If-Match": "stale"})
	if response.StatusCode != http.StatusConflict {
		t.Fatalf("stale revision status = %d", response.StatusCode)
	}
	_ = response.Body.Close()
	if len(harness.commands) != 0 {
		t.Fatalf("stale mutation ran Hermes: %#v", harness.commands)
	}
}
