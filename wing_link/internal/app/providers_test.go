package app

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"reflect"
	"testing"
	"time"
)

func TestCustomProviderCRUDUsesFixedHermesConfigCommands(t *testing.T) {
	entries := map[string]map[string]any{}
	var commands [][]string
	backend := &providerBackend{
		readHermes: func(_ context.Context, args ...string) ([]byte, error) {
			if !reflect.DeepEqual(args, []string{"--profile", "default", "config", "get", "providers", "--json"}) {
				return nil, errors.New("unexpected read command")
			}
			return json.Marshal(entries)
		},
		runHermes: func(_ context.Context, args ...string) error {
			commands = append(commands, append([]string(nil), args...))
			if len(args) < 2 || !reflect.DeepEqual(args[:2], []string{"--profile", "default"}) {
				return errors.New("missing profile scope")
			}
			args = args[2:]
			if len(args) == 5 && reflect.DeepEqual(args[:3], []string{"config", "set", "--force"}) {
				key, value := args[3], args[4]
				id, field, ok := providerConfigKey(key)
				if !ok {
					return errors.New("unexpected config key")
				}
				entry := entries[id]
				if entry == nil {
					entry = map[string]any{}
					entries[id] = entry
				}
				entry[field] = value
				return nil
			}
			if len(args) == 3 && reflect.DeepEqual(args[:2], []string{"config", "unset"}) {
				id, _, ok := providerConfigKey(args[2] + ".unused")
				if !ok {
					return errors.New("unexpected config key")
				}
				delete(entries, id)
				return nil
			}
			return errors.New("unexpected command")
		},
	}

	created, err := backend.create(context.Background(), "default", "acme", "https://api.example.test/v1", "acme-model")
	if err != nil {
		t.Fatal(err)
	}
	if created.ID != "acme" || created.BaseURL != "https://api.example.test/v1" || created.Model != "acme-model" || created.Revision == "" {
		t.Fatalf("created = %#v", created)
	}
	if len(commands) != 3 {
		t.Fatalf("create commands = %#v", commands)
	}
	for _, command := range commands {
		if len(command) != 7 || !reflect.DeepEqual(command[:5], []string{"--profile", "default", "config", "set", "--force"}) {
			t.Fatalf("unsafe create command = %#v", command)
		}
	}

	updated, err := backend.update(context.Background(), "default", "acme", "https://new.example.test/v1", "acme-v2", created.Revision)
	if err != nil {
		t.Fatal(err)
	}
	if updated.BaseURL != "https://new.example.test/v1" || updated.Model != "acme-v2" || updated.Revision == created.Revision {
		t.Fatalf("updated = %#v", updated)
	}

	if err := backend.delete(context.Background(), "default", "acme", updated.Revision); err != nil {
		t.Fatal(err)
	}
	rows, err := backend.list(context.Background(), "default")
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) != 0 {
		t.Fatalf("rows after delete = %#v", rows)
	}
	if got := commands[len(commands)-1]; !reflect.DeepEqual(got, []string{"--profile", "default", "config", "unset", "providers.acme"}) {
		t.Fatalf("delete command = %#v", got)
	}
}

func TestCustomProviderInventoryExcludesUnsafeURLsAndScopesRevisions(t *testing.T) {
	backend := &providerBackend{
		readHermes: func(context.Context, ...string) ([]byte, error) {
			return []byte(`{
				"safe":{"base_url":"https://api.example.test/v1","model":"v1"},
				"unsafe":{"base_url":"https://user:secret@example.test/v1?token=secret","model":"v1"}
			}`), nil
		},
	}
	defaultRows, err := backend.list(context.Background(), "default")
	if err != nil {
		t.Fatal(err)
	}
	coderRows, err := backend.list(context.Background(), "coder")
	if err != nil {
		t.Fatal(err)
	}
	if len(defaultRows) != 1 || defaultRows[0].ID != "safe" {
		t.Fatalf("default rows = %#v", defaultRows)
	}
	if defaultRows[0].Revision == coderRows[0].Revision {
		t.Fatal("provider revision did not include profile identity")
	}
	if _, err := backend.create(
		context.Background(), "default", "unsafe",
		"https://replacement.example.test/v1", "v2",
	); !errors.Is(err, errProviderExists) {
		t.Fatalf("unsafe existing ID was not preserved: %v", err)
	}
}

func TestCustomProviderUpdateRollsBackPartialCLIChanges(t *testing.T) {
	entries := map[string]map[string]any{
		"acme": {"name": "acme", "base_url": "https://old.example.test/v1", "model": "v1"},
	}
	failNewModel := true
	ctx, cancel := context.WithCancel(context.Background())
	backend := &providerBackend{
		readHermes: func(context.Context, ...string) ([]byte, error) { return json.Marshal(entries) },
		runHermes: func(commandContext context.Context, args ...string) error {
			args = args[2:]
			if len(args) != 5 || !reflect.DeepEqual(args[:3], []string{"config", "set", "--force"}) {
				return errors.New("unexpected command")
			}
			id, field, ok := providerConfigKey(args[3])
			if !ok {
				return errors.New("unexpected config key")
			}
			if field == "model" && args[4] == "v2" && failNewModel {
				failNewModel = false
				cancel()
				return errors.New("injected write failure")
			}
			if commandContext.Err() != nil {
				return commandContext.Err()
			}
			entries[id][field] = args[4]
			return nil
		},
	}
	rows, err := backend.list(context.Background(), "default")
	if err != nil {
		t.Fatal(err)
	}
	_, err = backend.update(
		ctx, "default", "acme",
		"https://new.example.test/v1", "v2", rows[0].Revision,
	)
	if !errors.Is(err, errProviderCLIFailed) {
		t.Fatalf("update error = %v", err)
	}
	if entries["acme"]["base_url"] != "https://old.example.test/v1" || entries["acme"]["model"] != "v1" {
		t.Fatalf("partial update was not rolled back: %#v", entries["acme"])
	}
}

func TestCustomProviderRouteRequiresWingLinkAuthorization(t *testing.T) {
	if !wingLinkProviderFallbacksEnabled {
		t.Skip("legacy provider domain routes are quarantined")
	}
	backend := &providerBackend{
		readHermes: func(context.Context, ...string) ([]byte, error) {
			return []byte(`{"acme":{"base_url":"https://api.example.test/v1","model":"v1"}}`), nil
		},
	}
	store := &StateStore{path: filepath.Join(t.TempDir(), "state.json"), now: time.Now}
	enrollment, err := store.CreateEnrollment()
	if err != nil {
		t.Fatal(err)
	}
	token, err := store.ExchangeEnrollment(enrollment.Code)
	if err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(newWingLinkServer(&profileBackend{}, store, backend))
	defer server.Close()

	response, err := http.Get(server.URL + "/v1/providers?profile=default")
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusUnauthorized {
		t.Fatalf("unauthorized status = %d", response.StatusCode)
	}
	_ = response.Body.Close()

	request, err := http.NewRequest(http.MethodGet, server.URL+"/v1/providers?profile=default", nil)
	if err != nil {
		t.Fatal(err)
	}
	request.Header.Set("Authorization", "Bearer "+token)
	response, err = http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusOK {
		t.Fatalf("authorized status = %d", response.StatusCode)
	}
	var body struct {
		Providers []customProviderRow `json:"providers"`
	}
	if err := json.NewDecoder(response.Body).Decode(&body); err != nil {
		t.Fatal(err)
	}
	_ = response.Body.Close()
	if len(body.Providers) != 1 || body.Providers[0].ID != "acme" {
		t.Fatalf("providers = %#v", body.Providers)
	}
}

func TestCustomProviderCRUDRejectsUnsafeInputBeforeHermes(t *testing.T) {
	commands := 0
	backend := &providerBackend{
		readHermes: func(context.Context, ...string) ([]byte, error) { return []byte(`{}`), nil },
		runHermes:  func(context.Context, ...string) error { commands++; return nil },
	}
	for _, test := range []struct {
		id, baseURL, model string
	}{
		{"../escape", "https://api.example.test/v1", "model"},
		{"acme", "file:///tmp/provider", "model"},
		{"acme", "https://:443/v1", "model"},
		{"acme", "https://api.example.test:65536/v1", "model"},
		{"acme", "https://user:secret@example.test/v1", "model"},
		{"acme", "https://api.example.test/v1?token=secret", "model"},
		{"acme", "https://api.example.test/v1", ""},
	} {
		if _, err := backend.create(context.Background(), "default", test.id, test.baseURL, test.model); !errors.Is(err, errProviderInvalid) {
			t.Fatalf("create(%q, %q, %q) error = %v", test.id, test.baseURL, test.model, err)
		}
	}
	if commands != 0 {
		t.Fatalf("invalid requests ran Hermes %d times", commands)
	}
}

func TestCustomProviderCreateConfirmsPersistence(t *testing.T) {
	reads := 0
	backend := &providerBackend{
		readHermes: func(context.Context, ...string) ([]byte, error) {
			reads++
			return []byte(`{}`), nil
		},
		runHermes: func(context.Context, ...string) error { return nil },
	}

	if _, err := backend.create(context.Background(), "default", "acme", "https://api.example.test/v1", "v1"); err == nil {
		t.Fatal("create succeeded although the provider was not persisted")
	}
	if reads != 2 {
		t.Fatalf("inventory reads = %d, want preflight plus confirmation", reads)
	}
}

func TestCustomProviderUpdateConfirmsPersistence(t *testing.T) {
	const inventory = `{"acme":{"base_url":"https://old.example.test/v1","model":"old"}}`
	reads := 0
	backend := &providerBackend{
		readHermes: func(context.Context, ...string) ([]byte, error) {
			reads++
			return []byte(inventory), nil
		},
		runHermes: func(context.Context, ...string) error { return nil },
	}
	current, err := validateCustomProvider("acme", "https://old.example.test/v1", "old")
	if err != nil {
		t.Fatal(err)
	}

	if _, err := backend.update(
		context.Background(), "default", "acme",
		"https://new.example.test/v1", "new", providerRevision("default", current),
	); err == nil {
		t.Fatal("update succeeded although the provider was not changed")
	}
	if reads != 2 {
		t.Fatalf("inventory reads = %d, want preflight plus confirmation", reads)
	}
}

func TestCustomProviderDeleteConfirmsRemoval(t *testing.T) {
	const inventory = `{"acme":{"base_url":"https://api.example.test/v1","model":"v1"}}`
	reads := 0
	backend := &providerBackend{
		readHermes: func(context.Context, ...string) ([]byte, error) {
			reads++
			return []byte(inventory), nil
		},
		runHermes: func(context.Context, ...string) error { return nil },
	}
	row, err := validateCustomProvider("acme", "https://api.example.test/v1", "v1")
	if err != nil {
		t.Fatal(err)
	}

	err = backend.delete(context.Background(), "default", "acme", providerRevision("default", row))
	if err == nil {
		t.Fatal("delete succeeded although the provider remains in inventory")
	}
	if reads != 2 {
		t.Fatalf("inventory reads = %d, want preflight plus confirmation", reads)
	}
}

func TestCustomProviderCreateRespectsInventoryLimit(t *testing.T) {
	entries := make(map[string]map[string]any, maxCustomProviders)
	for index := 0; index < maxCustomProviders; index++ {
		entries[fmt.Sprintf("p%02d", index)] = map[string]any{
			"base_url": "https://api.example.test/v1",
			"model":    "v1",
		}
	}
	commands := 0
	backend := &providerBackend{
		readHermes: func(context.Context, ...string) ([]byte, error) { return json.Marshal(entries) },
		runHermes:  func(context.Context, ...string) error { commands++; return nil },
	}
	if _, err := backend.create(
		context.Background(), "default", "overflow",
		"https://api.example.test/v1", "v1",
	); !errors.Is(err, errProviderInvalid) {
		t.Fatalf("create error = %v", err)
	}
	if commands != 0 {
		t.Fatalf("limit overflow ran Hermes %d times", commands)
	}
}

func TestCustomProviderCRUDRequiresCurrentRevision(t *testing.T) {
	entries := map[string]map[string]any{
		"acme": {"name": "acme", "base_url": "https://api.example.test/v1", "model": "v1"},
	}
	commands := 0
	backend := &providerBackend{
		readHermes: func(context.Context, ...string) ([]byte, error) { return json.Marshal(entries) },
		runHermes:  func(context.Context, ...string) error { commands++; return nil },
	}
	if _, err := backend.update(context.Background(), "default", "acme", "https://api.example.test/v1", "v2", "stale"); !errors.Is(err, errProviderChanged) {
		t.Fatalf("update error = %v", err)
	}
	if err := backend.delete(context.Background(), "default", "acme", "stale"); !errors.Is(err, errProviderChanged) {
		t.Fatalf("delete error = %v", err)
	}
	if commands != 0 {
		t.Fatalf("stale requests ran Hermes %d times", commands)
	}
}
