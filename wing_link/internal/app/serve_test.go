package app

import (
	"bytes"
	"context"
	"crypto/ed25519"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"reflect"
	"slices"
	"sort"
	"strings"
	"syscall"
	"testing"
)

func TestProtocolMetadataAndNMinusOneNegotiation(t *testing.T) {
	store := newStateStore(filepath.Join(t.TempDir(), "state.json"))
	handler := newWingLinkServer(&profileBackend{}, store)

	metadataRequest := httptest.NewRequest(http.MethodGet, "/meta", nil)
	metadataResponse := httptest.NewRecorder()
	handler.ServeHTTP(metadataResponse, metadataRequest)
	if metadataResponse.Code != http.StatusOK ||
		!strings.Contains(metadataResponse.Body.String(), `"protocol_generation":2`) ||
		!strings.Contains(metadataResponse.Body.String(), `"minimum_protocol_generation":1`) ||
		!strings.Contains(metadataResponse.Body.String(), `"host_fingerprint":"sha256/`) {
		t.Fatalf("metadata = %d %s", metadataResponse.Code, metadataResponse.Body.String())
	}

	for generation, want := range map[string]int{
		"":  http.StatusOK,
		"1": http.StatusOK,
		"2": http.StatusOK,
		"0": http.StatusUpgradeRequired,
		"3": http.StatusUpgradeRequired,
		"x": http.StatusUpgradeRequired,
	} {
		request := httptest.NewRequest(http.MethodGet, "/healthz", nil)
		if generation != "" {
			request.Header.Set("Wing-Protocol", generation)
		}
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, request)
		if response.Code != want {
			t.Fatalf("generation %q status = %d; want %d", generation, response.Code, want)
		}
		if response.Header().Get("Wing-Protocol") != "2" {
			t.Fatalf("generation %q omitted response protocol header", generation)
		}
	}
}

func TestServeListenErrorExplainsAnOccupiedAddress(t *testing.T) {
	var stderr bytes.Buffer
	writeServeListenError(&stderr, "127.0.0.1:8654", syscall.EADDRINUSE)
	for _, want := range []string{
		"serve: 127.0.0.1:8654 is already in use",
		"wing-link status",
		"wing-link restart",
	} {
		if !strings.Contains(stderr.String(), want) {
			t.Fatalf("error missing %q: %q", want, stderr.String())
		}
	}
}

type profileHarness struct {
	server              *httptest.Server
	handler             http.Handler
	token               string
	commands            [][]string
	secretCommands      [][]string
	secretInputBytes    []int
	secretErr           error
	readinessResponse   string
	readCommands        [][]string
	profiles            map[string]string
	readErr             error
	failReadAfterCreate bool
	failCreateApplied   bool
	retainRenameSource  bool
	cancelRequest       context.CancelFunc
	approvals           *ApprovalStore
	requestSequence     int
}

func renderProfileList(profiles map[string]string) []byte {
	ids := make([]string, 0, len(profiles))
	for id := range profiles {
		ids = append(ids, id)
	}
	sort.Strings(ids)
	var output strings.Builder
	output.WriteString("Profile Model Gateway Alias Distribution\n")
	output.WriteString("──────── ───── ─────── ───── ────────────\n")
	for _, id := range ids {
		_, _ = fmt.Fprintf(&output, "%s — %s — —\n", id, profiles[id])
	}
	return []byte(output.String())
}

func newProfileHarness(t *testing.T) *profileHarness {
	t.Helper()
	harness := &profileHarness{
		profiles: map[string]string{"default": "stopped", "link": "running"},
	}
	backend := &profileBackend{
		revisionSalt: "test-revision-salt",
		readHermes: func(_ context.Context, args ...string) ([]byte, error) {
			harness.readCommands = append(harness.readCommands, append([]string(nil), args...))
			if harness.readErr != nil {
				return nil, harness.readErr
			}
			if len(args) == 8 && reflect.DeepEqual(args[2:], []string{"chat", "-Q", "--source", "tool", "-q", "Reply with exactly: Hi"}) {
				response := harness.readinessResponse
				if response == "" {
					response = "Hi"
				}
				return []byte(response + "\n"), nil
			}
			if reflect.DeepEqual(args, []string{"--profile", "notreadyqa", "config", "get", "model.provider"}) {
				return []byte("openrouter\n"), nil
			}
			if reflect.DeepEqual(args, []string{"--profile", "notreadyqa", "config", "get", "model.default"}) {
				return []byte("openai/gpt-5.2\n"), nil
			}
			if reflect.DeepEqual(args, []string{"--profile", "readyqa", "config", "get", "model.provider"}) {
				return []byte("openrouter\n"), nil
			}
			if reflect.DeepEqual(args, []string{"--profile", "readyqa", "config", "get", "model.default"}) {
				return []byte("openai/gpt-5.2\n"), nil
			}
			if reflect.DeepEqual(args, []string{"--profile", "omniqa", "config", "get", "model.provider"}) {
				return []byte("custom\n"), nil
			}
			if reflect.DeepEqual(args, []string{"--profile", "omniqa", "config", "get", "model.base_url"}) {
				return []byte("http://127.0.0.1:20128/v1\n"), nil
			}
			if reflect.DeepEqual(args, []string{"--profile", "omniqa", "config", "get", "model.default"}) {
				return []byte("auto/best-coding\n"), nil
			}
			if reflect.DeepEqual(args, []string{"--profile", "cancelledqa", "config", "get", "model.provider"}) {
				return []byte("openrouter\n"), nil
			}
			if reflect.DeepEqual(args, []string{"--profile", "cancelledqa", "config", "get", "model.default"}) {
				return []byte("openai/gpt-5.2\n"), nil
			}
			if reflect.DeepEqual(args, []string{"--profile", "brokenqa", "config", "get", "model.provider"}) {
				return []byte("openrouter\n"), nil
			}
			if reflect.DeepEqual(args, []string{"--profile", "brokenqa", "config", "get", "model.default"}) {
				return []byte("openai/gpt-5.2\n"), nil
			}
			if reflect.DeepEqual(args, []string{"--profile", "link", "config", "get", "model.provider"}) {
				return []byte("anthropic\n"), nil
			}
			if reflect.DeepEqual(args, []string{"--profile", "link", "config", "get", "model.default"}) {
				return []byte("claude-sonnet-4\n"), nil
			}
			if !reflect.DeepEqual(args, []string{"profile", "list"}) {
				return nil, errors.New("unexpected read command")
			}
			return renderProfileList(harness.profiles), nil
		},
		runHermes: func(ctx context.Context, args ...string) error {
			harness.commands = append(harness.commands, append([]string(nil), args...))
			if ctx.Err() != nil {
				return ctx.Err()
			}
			switch {
			case len(args) >= 4 && reflect.DeepEqual(args[:2], []string{"profile", "create"}):
				harness.profiles[args[2]] = "stopped"
				if harness.failCreateApplied {
					return errors.New("create reported failure after applying")
				}
				if harness.failReadAfterCreate {
					harness.readErr = errors.New("persistent post-create inventory failure")
				}
				return nil
			case len(args) == 4 && reflect.DeepEqual(args[:2], []string{"profile", "rename"}):
				state, ok := harness.profiles[args[2]]
				if !ok {
					return errors.New("profile not found")
				}
				if !harness.retainRenameSource {
					delete(harness.profiles, args[2])
				}
				harness.profiles[args[3]] = state
				return nil
			case len(args) == 4 && reflect.DeepEqual(args[:3], []string{"profile", "delete", "--yes"}):
				delete(harness.profiles, args[3])
				return nil
			case len(args) == 5 && reflect.DeepEqual(args[:2], []string{"profile", "describe"}):
				return nil
			case len(args) == 7 && reflect.DeepEqual(args[2:6], []string{"config", "set", "--force", "model.provider"}):
				return nil
			case len(args) == 7 && reflect.DeepEqual(args[2:6], []string{"config", "set", "--force", "model.default"}):
				return nil
			case len(args) == 7 && reflect.DeepEqual(args[2:6], []string{"config", "set", "--force", "model.base_url"}):
				return nil
			case len(args) == 5 && reflect.DeepEqual(args[2:4], []string{"auth", "status"}):
				return nil
			default:
				return errors.New("unexpected command")
			}
		},
		runHermesSecret: func(_ context.Context, input []byte, args ...string) error {
			harness.secretCommands = append(harness.secretCommands, append([]string(nil), args...))
			harness.secretInputBytes = append(harness.secretInputBytes, len(input))
			if harness.cancelRequest != nil {
				harness.cancelRequest()
			}
			return harness.secretErr
		},
	}
	store := newStateStore(filepath.Join(t.TempDir(), "state.json"))
	enrollment, err := store.CreateEnrollment()
	if err != nil {
		t.Fatal(err)
	}
	harness.token, err = store.ExchangeEnrollment(enrollment.Code)
	if err != nil {
		t.Fatal(err)
	}
	harness.handler = newWingLinkServer(backend, store)
	harness.approvals, err = openApprovalStore(store.Path())
	if err != nil {
		t.Fatal(err)
	}
	harness.server = httptest.NewServer(harness.handler)
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
	h.requestSequence++
	idempotencyKey := fmt.Sprintf("profile-test-%d", h.requestSequence)
	doRequest := func() *http.Response {
		request, err := http.NewRequest(method, h.server.URL+path, bytes.NewReader(payload))
		if err != nil {
			t.Fatal(err)
		}
		request.Header.Set("Content-Type", "application/json")
		if authorized {
			request.Header.Set("Authorization", "Bearer "+h.token)
		}
		if method == http.MethodPost || method == http.MethodPatch || method == http.MethodDelete {
			request.Header.Set("Idempotency-Key", idempotencyKey)
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
	response := doRequest()
	if response.StatusCode == http.StatusAccepted && h.approvals != nil {
		responseBody, err := io.ReadAll(response.Body)
		if err != nil {
			t.Fatal(err)
		}
		_ = response.Body.Close()
		var pending struct {
			ApprovalID string `json:"approval_id"`
		}
		if json.Unmarshal(responseBody, &pending) == nil && pending.ApprovalID != "" {
			if _, err := h.approvals.Decide(pending.ApprovalID, true); err != nil {
				t.Fatal(err)
			}
			return doRequest()
		}
		response.Body = io.NopCloser(bytes.NewReader(responseBody))
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

func TestWingLinkProfileRoutesAreExposedButProviderRoutesStayQuarantined(t *testing.T) {
	var commands [][]string
	backend := &profileBackend{
		runHermes: func(_ context.Context, args ...string) error {
			commands = append(commands, append([]string(nil), args...))
			return nil
		},
	}
	store := newStateStore(filepath.Join(t.TempDir(), "state.json"))
	enrollment, err := store.CreateEnrollment()
	if err != nil {
		t.Fatal(err)
	}
	token, err := store.ExchangeEnrollment(enrollment.Code)
	if err != nil {
		t.Fatal(err)
	}
	handler := newWingLinkServer(backend, store, &providerBackend{})
	cases := []struct {
		method string
		path   string
		body   string
		status int
	}{
		{http.MethodGet, "/v1/profiles", "", http.StatusUnauthorized},
		{http.MethodGet, "/v1/providers?profile=default", "", http.StatusNotFound},
	}
	for _, testCase := range cases {
		request := httptest.NewRequest(
			testCase.method,
			testCase.path,
			strings.NewReader(testCase.body),
		)
		if testCase.status != http.StatusUnauthorized {
			request.Header.Set("Authorization", "Bearer "+token)
		}
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, request)
		if response.Code != testCase.status {
			t.Fatalf("%s %s status = %d; want %d", testCase.method, testCase.path, response.Code, testCase.status)
		}
	}
	if len(commands) != 0 {
		t.Fatalf("quarantined domain route ran Hermes: %#v", commands)
	}
}

func TestDeviceScopesAreEnforcedPerRoute(t *testing.T) {
	store := newStateStore(filepath.Join(t.TempDir(), "state.json"))
	credentialID, token, err := store.StageDeviceCredential(
		"Health display",
		ed25519.PublicKey(bytes.Repeat([]byte{7}, ed25519.PublicKeySize)),
		[]string{ScopeHealthRead},
	)
	if err != nil {
		t.Fatal(err)
	}
	if err := store.AcknowledgeControlToken(credentialID, token); err != nil {
		t.Fatal(err)
	}
	handler := newWingLinkServer(
		&profileBackend{
			revisionSalt: "scope-test-salt",
			readHermes: func(context.Context, ...string) ([]byte, error) {
				return renderProfileList(map[string]string{"default": "stopped"}), nil
			},
		},
		store,
	)
	for _, testCase := range []struct {
		method string
		path   string
		status int
	}{
		{http.MethodGet, "/v1/status", http.StatusOK},
		{http.MethodGet, "/v1/profiles", http.StatusUnauthorized},
		{http.MethodPost, "/v1/setup", http.StatusUnauthorized},
	} {
		request := httptest.NewRequest(testCase.method, testCase.path, strings.NewReader(`{}`))
		request.Header.Set("Authorization", "Bearer "+token)
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, request)
		if response.Code != testCase.status {
			t.Fatalf("%s %s status = %d; want %d", testCase.method, testCase.path, response.Code, testCase.status)
		}
	}
}

func TestSignedUpdateRoutesFailClosedWithEmptyProductionKeys(t *testing.T) {
	store := newStateStore(filepath.Join(t.TempDir(), "state.json"))
	enrollment, err := store.CreateEnrollment()
	if err != nil {
		t.Fatal(err)
	}
	token, err := store.ExchangeEnrollment(enrollment.Code)
	if err != nil {
		t.Fatal(err)
	}
	handler := newWingLinkServer(&profileBackend{}, store)
	status := httptest.NewRequest(http.MethodGet, "/v1/update/status", nil)
	status.Header.Set("Authorization", "Bearer "+token)
	statusResponse := httptest.NewRecorder()
	handler.ServeHTTP(statusResponse, status)
	if statusResponse.Code != http.StatusOK || !strings.Contains(statusResponse.Body.String(), `"state":"unavailable"`) || !strings.Contains(statusResponse.Body.String(), `"reason":"release_keys_empty"`) {
		t.Fatalf("update status=%d body=%s", statusResponse.Code, statusResponse.Body.String())
	}
	apply := httptest.NewRequest(http.MethodPost, "/v1/update/apply", strings.NewReader(`{}`))
	apply.Header.Set("Authorization", "Bearer "+token)
	apply.Header.Set("Content-Type", "application/json")
	applyResponse := httptest.NewRecorder()
	handler.ServeHTTP(applyResponse, apply)
	if applyResponse.Code != http.StatusServiceUnavailable || !strings.Contains(applyResponse.Body.String(), `"code":"update_unavailable"`) {
		t.Fatalf("update apply=%d body=%s", applyResponse.Code, applyResponse.Body.String())
	}
}

func TestServerFailsClosedWhenAuditLogIsUnsafe(t *testing.T) {
	directory := t.TempDir()
	store := newStateStore(filepath.Join(directory, "state.json"))
	if err := os.WriteFile(filepath.Join(directory, "wing-link-audit.jsonl"), []byte("{}\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	handler := newWingLinkServer(&profileBackend{}, store)
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, httptest.NewRequest(http.MethodGet, "/healthz", nil))
	if response.Code != http.StatusServiceUnavailable || !strings.Contains(response.Body.String(), "host_state_unavailable") {
		t.Fatalf("unsafe audit state response = %d %s", response.Code, response.Body.String())
	}
	if response.Header().Get("Cache-Control") != "no-store" || response.Header().Get("Wing-Protocol") == "" {
		t.Fatalf("unsafe audit state response omitted safety headers: %v", response.Header())
	}
}

func TestDeviceCanInspectAndRevokeOnlyItself(t *testing.T) {
	store := newStateStore(filepath.Join(t.TempDir(), "state.json"))
	credentialID, token, err := store.StageDeviceCredential(
		"Pixel 9",
		ed25519.PublicKey(bytes.Repeat([]byte{8}, ed25519.PublicKeySize)),
		[]string{ScopeHealthRead, ScopeDeviceSelfRead, ScopeDeviceSelfRevoke},
	)
	if err != nil {
		t.Fatal(err)
	}
	if err := store.AcknowledgeControlToken(credentialID, token); err != nil {
		t.Fatal(err)
	}
	handler := newWingLinkServer(&profileBackend{}, store)

	inspect := httptest.NewRequest(http.MethodGet, "/v2/devices/self", nil)
	inspect.Header.Set("Authorization", "Bearer "+token)
	inspectResponse := httptest.NewRecorder()
	handler.ServeHTTP(inspectResponse, inspect)
	if inspectResponse.Code != http.StatusOK || !strings.Contains(inspectResponse.Body.String(), `"device_id":"`+credentialID+`"`) || strings.Contains(inspectResponse.Body.String(), "token_hash") {
		t.Fatalf("self inspection = %d %s", inspectResponse.Code, inspectResponse.Body.String())
	}

	revoke := httptest.NewRequest(http.MethodDelete, "/v2/devices/self", nil)
	revoke.Header.Set("Authorization", "Bearer "+token)
	revokeResponse := httptest.NewRecorder()
	handler.ServeHTTP(revokeResponse, revoke)
	if revokeResponse.Code != http.StatusNoContent {
		t.Fatalf("self revoke = %d %s", revokeResponse.Code, revokeResponse.Body.String())
	}
	if store.Authorize(token) {
		t.Fatal("self-revoked device remained authorized")
	}
	auditLog, err := openAuditLog(store.Path())
	if err != nil {
		t.Fatal(err)
	}
	events, err := auditLog.List()
	if err != nil || len(events) != 2 || events[0].Operation != "device.self.read" || events[1].Operation != "device.self.revoke" || events[1].DeviceID != credentialID {
		t.Fatalf("self-device audit=%#v err=%v", events, err)
	}
}

func TestPendingCredentialCanVerifyReadsButCannotMutateBeforeAcknowledgment(t *testing.T) {
	if !wingLinkProfileCompatibilityEnabled {
		t.Skip("legacy profile domain routes are quarantined")
	}
	store := newStateStore(filepath.Join(t.TempDir(), "state.json"))
	credentialID, token, err := store.StageControlToken()
	if err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(newWingLinkServer(
		&profileBackend{
			revisionSalt: "pending-test-salt",
			readHermes: func(context.Context, ...string) ([]byte, error) {
				return renderProfileList(map[string]string{"default": "stopped"}), nil
			},
		},
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
	if !wingLinkProfileCompatibilityEnabled {
		t.Skip("legacy profile domain routes are quarantined")
	}
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

func TestProfileInventoryUsesOnlyFixedHermesList(t *testing.T) {
	harness := newProfileHarness(t)
	response := harness.request(t, http.MethodGet, "/v1/profiles", nil, true, nil)
	if response.StatusCode != http.StatusOK {
		t.Fatalf("profile list status = %d", response.StatusCode)
	}
	_ = response.Body.Close()
	if !reflect.DeepEqual(harness.readCommands, [][]string{{"profile", "list"}}) {
		t.Fatalf("read commands = %#v", harness.readCommands)
	}
	if len(harness.commands) != 0 {
		t.Fatalf("profile list invoked mutation commands: %#v", harness.commands)
	}
}

func TestProfileCreateRenameAndDeleteUseFixedHermesArguments(t *testing.T) {
	if !wingLinkProfileCompatibilityEnabled {
		t.Skip("legacy profile domain routes are quarantined")
	}
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

func TestProfileCreateConfiguresDescriptionProviderModelAndWriteOnlyCredential(t *testing.T) {
	harness := newProfileHarness(t)
	const secret = "provider-secret-must-not-enter-arguments"
	created := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{
		"name": "readyqa", "clone_from": "link",
		"description": "Physical lifecycle profile",
		"provider":    "openrouter", "model": "openai/gpt-5.2",
		"provider_api_key": secret,
	}, true, nil)
	if created.StatusCode != http.StatusCreated {
		t.Fatalf("create status = %d", created.StatusCode)
	}
	var createBody struct {
		Profile profileRow `json:"profile"`
	}
	decodeBody(t, created, &createBody)
	if createBody.Profile.Description != "Physical lifecycle profile" ||
		createBody.Profile.Model != "openai/gpt-5.2" {
		t.Fatalf("created profile = %#v", createBody.Profile)
	}

	want := [][]string{
		{"profile", "create", "readyqa", "--no-alias", "--clone-from", "link"},
		{"profile", "describe", "readyqa", "--text", "Physical lifecycle profile"},
		{"--profile", "readyqa", "config", "set", "--force", "model.provider", "openrouter"},
		{"--profile", "readyqa", "config", "set", "--force", "model.default", "openai/gpt-5.2"},
		{"--profile", "readyqa", "auth", "status", "openrouter"},
	}
	if !reflect.DeepEqual(harness.commands, want) {
		t.Fatalf("commands = %#v, want %#v", harness.commands, want)
	}
	smoke := []string{"--profile", "readyqa", "chat", "-Q", "--source", "tool", "-q", "Reply with exactly: Hi"}
	if !slices.ContainsFunc(harness.readCommands, func(command []string) bool {
		return reflect.DeepEqual(command, smoke)
	}) {
		t.Fatalf("read commands missing readiness smoke: %#v", harness.readCommands)
	}
	secretArgs := [][]string{{"--profile", "readyqa", "auth", "add", "openrouter", "--type", "api-key", "--label", "wing-link"}}
	if !reflect.DeepEqual(harness.secretCommands, secretArgs) || !reflect.DeepEqual(harness.secretInputBytes, []int{len(secret) + 1}) {
		t.Fatalf("secret commands=%#v input bytes=%#v", harness.secretCommands, harness.secretInputBytes)
	}
	if strings.Contains(fmt.Sprint(harness.commands, harness.secretCommands), secret) {
		t.Fatal("provider secret entered Hermes argv")
	}
}

func TestProfileCreateConfiguresFixedLoopbackOmniRouteAdapter(t *testing.T) {
	harness := newProfileHarness(t)
	created := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{
		"name": "omniqa", "clone_from": "link",
		"description": "Physical OmniRoute profile",
		"provider":    "omniroute", "model": "auto/best-coding",
	}, true, nil)
	if created.StatusCode != http.StatusCreated {
		t.Fatalf("create status = %d", created.StatusCode)
	}
	_ = created.Body.Close()

	want := [][]string{
		{"profile", "create", "omniqa", "--no-alias", "--clone-from", "link"},
		{"profile", "describe", "omniqa", "--text", "Physical OmniRoute profile"},
		{"--profile", "omniqa", "config", "set", "--force", "model.provider", "custom"},
		{"--profile", "omniqa", "config", "set", "--force", "model.base_url", "http://127.0.0.1:20128/v1"},
		{"--profile", "omniqa", "config", "set", "--force", "model.default", "auto/best-coding"},
	}
	if !reflect.DeepEqual(harness.commands, want) {
		t.Fatalf("commands = %#v, want %#v", harness.commands, want)
	}
	if len(harness.secretCommands) != 0 {
		t.Fatalf("OmniRoute setup unexpectedly handled a secret: %#v", harness.secretCommands)
	}
}

func TestProfileCreateRejectsOmniRouteCredentialBeforeMutation(t *testing.T) {
	harness := newProfileHarness(t)
	response := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{
		"name": "omniqa", "provider": "omniroute", "model": "auto/best-coding",
		"provider_api_key": "must-not-be-forwarded",
	}, true, nil)
	if response.StatusCode != http.StatusBadRequest {
		t.Fatalf("status = %d", response.StatusCode)
	}
	_ = response.Body.Close()
	if len(harness.commands) != 0 || len(harness.secretCommands) != 0 {
		t.Fatalf("invalid setup spawned commands: %#v %#v", harness.commands, harness.secretCommands)
	}
}

func TestProfileCreateRejectsUnallowlistedProviderBeforeMutation(t *testing.T) {
	harness := newProfileHarness(t)
	response := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{
		"name": "unsafeqa", "provider": "arbitrary-plugin", "model": "model",
	}, true, nil)
	if response.StatusCode != http.StatusBadRequest {
		t.Fatalf("status = %d", response.StatusCode)
	}
	_ = response.Body.Close()
	if len(harness.commands) != 0 || len(harness.secretCommands) != 0 {
		t.Fatalf("invalid setup spawned commands: %#v %#v", harness.commands, harness.secretCommands)
	}
}

func TestProfileCreateRollsBackWhenPostCreateInventoryReadFails(t *testing.T) {
	harness := newProfileHarness(t)
	harness.failReadAfterCreate = true
	response := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{
		"name": "orphanqa",
	}, true, nil)
	if response.StatusCode != http.StatusServiceUnavailable {
		t.Fatalf("status = %d", response.StatusCode)
	}
	_ = response.Body.Close()
	if _, exists := harness.profiles["orphanqa"]; exists {
		t.Fatal("profile survived failed post-create inventory read")
	}
	wantLast := []string{"profile", "delete", "--yes", "orphanqa"}
	if len(harness.commands) == 0 || !reflect.DeepEqual(harness.commands[len(harness.commands)-1], wantLast) {
		t.Fatalf("commands = %#v", harness.commands)
	}
}

func TestProfileCreateRollsBackWhenCLIReportsAppliedFailure(t *testing.T) {
	harness := newProfileHarness(t)
	harness.failCreateApplied = true
	response := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{
		"name": " AppliedQA ",
	}, true, nil)
	if response.StatusCode != http.StatusBadGateway {
		t.Fatalf("status = %d", response.StatusCode)
	}
	_ = response.Body.Close()
	if _, exists := harness.profiles["appliedqa"]; exists {
		t.Fatal("profile survived an applied create failure")
	}
	want := [][]string{
		{"profile", "create", "appliedqa", "--no-alias"},
		{"profile", "delete", "--yes", "appliedqa"},
	}
	if !reflect.DeepEqual(harness.commands, want) {
		t.Fatalf("commands = %#v, want %#v", harness.commands, want)
	}
}

func TestProfileCreateRollsBackWhenProviderCredentialSetupFails(t *testing.T) {
	harness := newProfileHarness(t)
	harness.secretErr = errors.New("credential rejected")
	response := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{
		"name": "brokenqa", "provider": "openrouter", "model": "openai/gpt-5.2",
		"provider_api_key": "not-accepted",
	}, true, nil)
	if response.StatusCode != http.StatusServiceUnavailable {
		t.Fatalf("status = %d", response.StatusCode)
	}
	_ = response.Body.Close()
	if _, exists := harness.profiles["brokenqa"]; exists {
		t.Fatal("partially configured profile survived failed setup")
	}
	wantLast := []string{"profile", "delete", "--yes", "brokenqa"}
	if len(harness.commands) == 0 || !reflect.DeepEqual(harness.commands[len(harness.commands)-1], wantLast) {
		t.Fatalf("commands = %#v", harness.commands)
	}
}

func TestRoutineProfileCreateReplaysExactKeyWithoutApprovalOrMutation(t *testing.T) {
	harness := newProfileHarness(t)
	missingKeyRequest := httptest.NewRequest(
		http.MethodPost,
		"/v1/profiles",
		strings.NewReader(`{"name":"missingkey"}`),
	)
	missingKeyRequest.Header.Set("Authorization", "Bearer "+harness.token)
	missingKeyRequest.Header.Set("Content-Type", "application/json")
	missingKeyResponse := httptest.NewRecorder()
	harness.handler.ServeHTTP(missingKeyResponse, missingKeyRequest)
	if missingKeyResponse.Code != http.StatusPreconditionRequired || len(harness.commands) != 0 {
		t.Fatalf("missing key status=%d commands=%#v", missingKeyResponse.Code, harness.commands)
	}

	headers := map[string]string{"Idempotency-Key": "routine-create-replay"}
	first := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{
		"name": "RoutineQA",
	}, true, headers)
	if first.StatusCode != http.StatusCreated {
		t.Fatalf("first status = %d", first.StatusCode)
	}
	_ = first.Body.Close()

	replay := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{
		"name": "RoutineQA",
	}, true, headers)
	if replay.StatusCode != http.StatusAccepted {
		t.Fatalf("replay status = %d", replay.StatusCode)
	}
	var replayBody struct {
		Replayed  bool           `json:"replayed"`
		Operation OperationEvent `json:"operation"`
	}
	decodeBody(t, replay, &replayBody)
	if !replayBody.Replayed || !replayBody.Operation.Terminal || replayBody.Operation.Phase != "committed" {
		t.Fatalf("replay = %#v", replayBody)
	}
	if len(harness.commands) != 1 {
		t.Fatalf("routine create mutated %d times: %#v", len(harness.commands), harness.commands)
	}
	pending, err := harness.approvals.List()
	if err != nil || len(pending) != 0 {
		t.Fatalf("routine create prompted for approval: %#v err=%v", pending, err)
	}

	conflict := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{
		"name": "differentqa",
	}, true, headers)
	if conflict.StatusCode != http.StatusConflict {
		t.Fatalf("conflict status = %d", conflict.StatusCode)
	}
	_ = conflict.Body.Close()
	if len(harness.commands) != 1 {
		t.Fatalf("conflicting replay mutated: %#v", harness.commands)
	}
}

func TestSensitiveProfileMutationsWaitForHostApproval(t *testing.T) {
	harness := newProfileHarness(t)
	request := httptest.NewRequest(
		http.MethodPost,
		"/v1/profiles",
		strings.NewReader(`{"name":"guarded","provider":"openrouter","model":"openai/gpt-5.2","provider_api_key":"write-only"}`),
	)
	request.Header.Set("Authorization", "Bearer "+harness.token)
	request.Header.Set("Content-Type", "application/json")
	request.Header.Set("Idempotency-Key", "guarded-create")
	response := httptest.NewRecorder()
	harness.handler.ServeHTTP(response, request)
	if response.Code != http.StatusAccepted || len(harness.commands) != 0 || len(harness.secretCommands) != 0 {
		t.Fatalf("status=%d commands=%#v secret=%#v body=%s", response.Code, harness.commands, harness.secretCommands, response.Body.String())
	}
	if strings.Contains(response.Body.String(), "write-only") {
		t.Fatalf("approval response leaked provider secret: %s", response.Body.String())
	}
}

func TestProfileCreateRollbackSurvivesRequestCancellation(t *testing.T) {
	harness := newProfileHarness(t)
	harness.secretErr = errors.New("credential setup cancelled")
	const rawPayload = `{"name":"cancelledqa","provider":"openrouter","model":"openai/gpt-5.2","provider_api_key":"secret-value"}`
	pendingRequest := httptest.NewRequest(http.MethodPost, "/v1/profiles", strings.NewReader(rawPayload))
	pendingRequest.Header.Set("Authorization", "Bearer "+harness.token)
	pendingRequest.Header.Set("Content-Type", "application/json")
	pendingRequest.Header.Set("Idempotency-Key", "cancelled-create")
	pendingResponse := httptest.NewRecorder()
	harness.handler.ServeHTTP(pendingResponse, pendingRequest)
	var pending struct {
		ApprovalID string `json:"approval_id"`
	}
	if err := json.NewDecoder(pendingResponse.Body).Decode(&pending); err != nil || pending.ApprovalID == "" {
		t.Fatalf("pending approval = %#v err=%v body=%s", pending, err, pendingResponse.Body.String())
	}
	if _, err := harness.approvals.Decide(pending.ApprovalID, true); err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	harness.cancelRequest = cancel
	payload := strings.NewReader(rawPayload)
	request := httptest.NewRequest(http.MethodPost, "/v1/profiles", payload).WithContext(ctx)
	request.Header.Set("Authorization", "Bearer "+harness.token)
	request.Header.Set("Content-Type", "application/json")
	request.Header.Set("Idempotency-Key", "cancelled-create")
	response := httptest.NewRecorder()
	harness.handler.ServeHTTP(response, request)
	if len(harness.secretCommands) != 1 || ctx.Err() == nil {
		t.Fatalf("configuration did not cancel the request: secret_commands=%d context=%v status=%d body=%s", len(harness.secretCommands), ctx.Err(), response.Code, response.Body.String())
	}
	if _, exists := harness.profiles["cancelledqa"]; exists {
		t.Fatal("cancelled request left its new profile behind")
	}
	wantLast := []string{"profile", "delete", "--yes", "cancelledqa"}
	if len(harness.commands) == 0 || !reflect.DeepEqual(harness.commands[len(harness.commands)-1], wantLast) {
		t.Fatalf("commands = %#v", harness.commands)
	}
}

func TestProfileCreateRollsBackWhenReadinessDoesNotAnswerHi(t *testing.T) {
	harness := newProfileHarness(t)
	harness.readinessResponse = "No API key found"
	response := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{
		"name": "notreadyqa", "provider": "openrouter", "model": "openai/gpt-5.2",
	}, true, nil)
	if response.StatusCode != http.StatusBadGateway {
		t.Fatalf("status = %d", response.StatusCode)
	}
	_ = response.Body.Close()
	if _, exists := harness.profiles["notreadyqa"]; exists {
		t.Fatal("profile survived a false-positive readiness command")
	}
}

func TestProfileUpdateRejectsExistingConfigurationBeforeMutation(t *testing.T) {
	harness := newProfileHarness(t)
	listed := harness.request(t, http.MethodGet, "/v1/profiles", nil, true, nil)
	var inventory struct {
		Profiles []profileRow `json:"profiles"`
	}
	decodeBody(t, listed, &inventory)
	link, ok := findProfileRow(inventory.Profiles, "link")
	if !ok {
		t.Fatal("link profile missing")
	}
	response := harness.request(t, http.MethodPatch, "/v1/profiles/link", map[string]any{
		"name": "link", "revision": link.Revision,
		"description": "Updated description", "provider": "anthropic",
		"model": "claude-sonnet-4", "provider_api_key": "updated-secret",
	}, true, nil)
	if response.StatusCode != http.StatusBadRequest {
		t.Fatalf("status = %d", response.StatusCode)
	}
	_ = response.Body.Close()
	if len(harness.commands) != 0 || len(harness.secretCommands) != 0 {
		t.Fatalf("rejected update mutated profile: commands=%#v secret=%#v", harness.commands, harness.secretCommands)
	}
}

func TestProfileGrammarAllowsSixtyFourCharactersAndRejectsReservedNames(t *testing.T) {
	if !wingLinkProfileCompatibilityEnabled {
		t.Skip("legacy profile domain routes are quarantined")
	}
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

func TestProfileCreatePropagatesCLIListErrorsWithoutRunningMutation(t *testing.T) {
	harness := newProfileHarness(t)
	harness.readErr = errors.New("list failed")
	response := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{"name": "unavailable"}, true, nil)
	if response.StatusCode != http.StatusServiceUnavailable {
		t.Fatalf("unavailable inventory status = %d", response.StatusCode)
	}
	_ = response.Body.Close()
	if len(harness.commands) != 0 {
		t.Fatalf("failed list ran a mutation: %#v", harness.commands)
	}
}

func TestProfileCreateRejectsMalformedCLIInventory(t *testing.T) {
	harness := newProfileHarness(t)
	harness.profiles = map[string]string{"INVALID!": "running"}
	response := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{"name": "newprofile"}, true, nil)
	if response.StatusCode != http.StatusServiceUnavailable {
		t.Fatalf("malformed inventory status = %d", response.StatusCode)
	}
	_ = response.Body.Close()
	if len(harness.commands) != 0 {
		t.Fatalf("malformed inventory ran a mutation: %#v", harness.commands)
	}
}

func TestDecodeJSONRejectsBodyBeyondLimit(t *testing.T) {
	body := `{"value":"ok"}` + strings.Repeat(" ", 64<<10)
	request := httptest.NewRequest(http.MethodPost, "/", strings.NewReader(body))
	response := httptest.NewRecorder()
	var target struct {
		Value string `json:"value"`
	}

	if decodeJSON(response, request, &target) {
		t.Fatal("oversized request body was accepted")
	}
	if response.Code != http.StatusBadRequest {
		t.Fatalf("status = %d", response.Code)
	}
}

func TestProfileMutationRejectsStaleRevision(t *testing.T) {
	if !wingLinkProfileCompatibilityEnabled {
		t.Skip("legacy profile domain routes are quarantined")
	}
	harness := newProfileHarness(t)
	response := harness.request(t, http.MethodDelete, "/v1/profiles/link", nil, true, map[string]string{"If-Match": "stale"})
	if response.StatusCode != http.StatusPreconditionFailed {
		t.Fatalf("stale revision status = %d", response.StatusCode)
	}
	_ = response.Body.Close()
	if len(harness.commands) != 0 {
		t.Fatalf("stale mutation ran Hermes: %#v", harness.commands)
	}
}

func TestProfileRenameRejectsIncompletePostcondition(t *testing.T) {
	harness := newProfileHarness(t)
	harness.retainRenameSource = true
	listed := harness.request(t, http.MethodGet, "/v1/profiles", nil, true, nil)
	var inventory struct {
		Profiles []profileRow `json:"profiles"`
	}
	decodeBody(t, listed, &inventory)
	link, ok := findProfileRow(inventory.Profiles, "link")
	if !ok {
		t.Fatal("link profile missing")
	}
	response := harness.request(t, http.MethodPatch, "/v1/profiles/link", map[string]any{
		"name": "renamed", "revision": link.Revision,
	}, true, nil)
	if response.StatusCode != http.StatusBadGateway {
		t.Fatalf("incomplete rename status = %d; want %d", response.StatusCode, http.StatusBadGateway)
	}
	_ = response.Body.Close()
}

func TestProfileTopologyChangeInvalidatesIssuedRevision(t *testing.T) {
	harness := newProfileHarness(t)
	listed := harness.request(t, http.MethodGet, "/v1/profiles", nil, true, nil)
	var inventory struct {
		Profiles []profileRow `json:"profiles"`
	}
	decodeBody(t, listed, &inventory)
	link, ok := findProfileRow(inventory.Profiles, "link")
	if !ok {
		t.Fatal("link profile missing")
	}
	harness.profiles["external"] = "stopped"
	response := harness.request(t, http.MethodDelete, "/v1/profiles/link", nil, true, map[string]string{"If-Match": link.Revision})
	if response.StatusCode != http.StatusPreconditionFailed {
		t.Fatalf("topology conflict status = %d", response.StatusCode)
	}
	_ = response.Body.Close()
	if len(harness.commands) != 0 {
		t.Fatalf("topology conflict ran Hermes: %#v", harness.commands)
	}
}

func TestProfileDeleteRecreateChangesOpaqueRevision(t *testing.T) {
	harness := newProfileHarness(t)
	listed := harness.request(t, http.MethodGet, "/v1/profiles", nil, true, nil)
	var inventory struct {
		Profiles []profileRow `json:"profiles"`
	}
	decodeBody(t, listed, &inventory)
	link, ok := findProfileRow(inventory.Profiles, "link")
	if !ok {
		t.Fatal("link profile missing")
	}
	deleted := harness.request(t, http.MethodDelete, "/v1/profiles/link", nil, true, map[string]string{"If-Match": link.Revision})
	if deleted.StatusCode != http.StatusOK {
		t.Fatalf("delete status = %d", deleted.StatusCode)
	}
	_ = deleted.Body.Close()
	created := harness.request(t, http.MethodPost, "/v1/profiles", map[string]any{"name": "link"}, true, nil)
	if created.StatusCode != http.StatusCreated {
		t.Fatalf("recreate status = %d", created.StatusCode)
	}
	var createBody struct {
		Profile profileRow `json:"profile"`
	}
	decodeBody(t, created, &createBody)
	if createBody.Profile.Revision == link.Revision {
		t.Fatal("delete/recreate reused the old revision")
	}
}

func TestProfileMutationRequiresRevision(t *testing.T) {
	harness := newProfileHarness(t)
	response := harness.request(t, http.MethodDelete, "/v1/profiles/link", nil, true, nil)
	if response.StatusCode != http.StatusPreconditionRequired {
		t.Fatalf("missing revision status = %d", response.StatusCode)
	}
	_ = response.Body.Close()
	if len(harness.commands) != 0 {
		t.Fatalf("missing revision ran Hermes: %#v", harness.commands)
	}
}
