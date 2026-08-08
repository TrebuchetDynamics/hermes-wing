package main

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"sort"
	"strings"
	"sync"
	"time"
	"unicode"
)

const maxCustomProviders = 64

var (
	errProviderInvalid   = errors.New("provider is invalid")
	errProviderExists    = errors.New("provider already exists")
	errProviderNotFound  = errors.New("provider not found")
	errProviderChanged   = errors.New("provider changed")
	errProviderCLIFailed = errors.New("provider CLI failed")
	errProviderInventory = errors.New("provider inventory unavailable")
)

type customProviderRow struct {
	ID       string `json:"id"`
	BaseURL  string `json:"base_url"`
	Model    string `json:"model"`
	Revision string `json:"revision"`
}

type providerBackend struct {
	readHermes func(context.Context, ...string) ([]byte, error)
	runHermes  func(context.Context, ...string) error
	mu         sync.Mutex
}

func (backend *providerBackend) list(ctx context.Context, profile string) ([]customProviderRow, error) {
	backend.mu.Lock()
	defer backend.mu.Unlock()
	profile, err := normalizeProviderProfile(profile)
	if err != nil {
		return nil, err
	}
	return backend.listLocked(ctx, profile)
}

func (backend *providerBackend) listLocked(ctx context.Context, profile string) ([]customProviderRow, error) {
	document, err := backend.readProviderDocumentLocked(ctx, profile)
	if err != nil {
		return nil, err
	}
	rows := make([]customProviderRow, 0, len(document))
	for id, raw := range document {
		normalized, err := normalizeProviderID(id)
		if err != nil || normalized != id {
			continue
		}
		var entry struct {
			BaseURL string `json:"base_url"`
			Model   string `json:"model"`
		}
		if json.Unmarshal(raw, &entry) != nil {
			continue
		}
		row, err := validateCustomProvider(id, entry.BaseURL, entry.Model)
		if err != nil {
			continue
		}
		row.Revision = providerRevision(profile, row)
		rows = append(rows, row)
	}
	sort.Slice(rows, func(i, j int) bool { return rows[i].ID < rows[j].ID })
	return rows, nil
}

func (backend *providerBackend) create(ctx context.Context, profile, id, baseURL, model string) (customProviderRow, error) {
	backend.mu.Lock()
	defer backend.mu.Unlock()
	profile, err := normalizeProviderProfile(profile)
	if err != nil {
		return customProviderRow{}, err
	}
	row, err := validateCustomProvider(id, baseURL, model)
	if err != nil {
		return customProviderRow{}, err
	}
	document, err := backend.readProviderDocumentLocked(ctx, profile)
	if err != nil {
		return customProviderRow{}, err
	}
	if _, ok := document[row.ID]; ok {
		return customProviderRow{}, errProviderExists
	}
	if len(document) >= maxCustomProviders {
		return customProviderRow{}, errProviderInvalid
	}
	if err := backend.writeProviderLocked(ctx, profile, row); err != nil {
		if rollbackErr := backend.rollbackProviderCreate(profile, row.ID); rollbackErr != nil {
			return customProviderRow{}, errors.Join(err, rollbackErr)
		}
		return customProviderRow{}, err
	}
	rows, err := backend.listLocked(ctx, profile)
	persisted, exists := findCustomProvider(rows, row.ID)
	if err != nil || !exists || persisted.BaseURL != row.BaseURL || persisted.Model != row.Model {
		confirmationErr := fmt.Errorf("%w: create was not confirmed", errProviderCLIFailed)
		if rollbackErr := backend.rollbackProviderCreate(profile, row.ID); rollbackErr != nil {
			return customProviderRow{}, errors.Join(confirmationErr, err, rollbackErr)
		}
		return customProviderRow{}, errors.Join(confirmationErr, err)
	}
	return persisted, nil
}

func (backend *providerBackend) update(ctx context.Context, profile, id, baseURL, model, revision string) (customProviderRow, error) {
	backend.mu.Lock()
	defer backend.mu.Unlock()
	profile, err := normalizeProviderProfile(profile)
	if err != nil {
		return customProviderRow{}, err
	}
	row, err := validateCustomProvider(id, baseURL, model)
	if err != nil {
		return customProviderRow{}, err
	}
	rows, err := backend.listLocked(ctx, profile)
	if err != nil {
		return customProviderRow{}, err
	}
	current, ok := findCustomProvider(rows, row.ID)
	if !ok {
		return customProviderRow{}, errProviderNotFound
	}
	if strings.TrimSpace(revision) == "" || current.Revision != strings.TrimSpace(revision) {
		return customProviderRow{}, errProviderChanged
	}
	if err := backend.writeProviderLocked(ctx, profile, row); err != nil {
		if rollbackErr := backend.rollbackProviderUpdate(profile, current); rollbackErr != nil {
			return customProviderRow{}, errors.Join(err, rollbackErr)
		}
		return customProviderRow{}, err
	}
	rows, err = backend.listLocked(ctx, profile)
	persisted, exists := findCustomProvider(rows, row.ID)
	if err != nil || !exists || persisted.BaseURL != row.BaseURL || persisted.Model != row.Model {
		confirmationErr := fmt.Errorf("%w: update was not confirmed", errProviderCLIFailed)
		if rollbackErr := backend.rollbackProviderUpdate(profile, current); rollbackErr != nil {
			return customProviderRow{}, errors.Join(confirmationErr, err, rollbackErr)
		}
		return customProviderRow{}, errors.Join(confirmationErr, err)
	}
	return persisted, nil
}

func (backend *providerBackend) delete(ctx context.Context, profile, id, revision string) error {
	backend.mu.Lock()
	defer backend.mu.Unlock()
	profile, err := normalizeProviderProfile(profile)
	if err != nil {
		return err
	}
	normalized, err := normalizeProviderID(id)
	if err != nil || normalized != strings.TrimSpace(id) {
		return errProviderInvalid
	}
	rows, err := backend.listLocked(ctx, profile)
	if err != nil {
		return err
	}
	current, ok := findCustomProvider(rows, normalized)
	if !ok {
		return errProviderNotFound
	}
	if strings.TrimSpace(revision) == "" || current.Revision != strings.TrimSpace(revision) {
		return errProviderChanged
	}
	if err := backend.runHermes(ctx, "--profile", profile, "config", "unset", "providers."+normalized); err != nil {
		return errProviderCLIFailed
	}
	rows, err = backend.listLocked(ctx, profile)
	if err != nil {
		return err
	}
	if _, exists := findCustomProvider(rows, normalized); exists {
		return fmt.Errorf("%w: deletion was not confirmed", errProviderCLIFailed)
	}
	return nil
}

func (backend *providerBackend) readProviderDocumentLocked(ctx context.Context, profile string) (map[string]json.RawMessage, error) {
	if backend == nil || backend.readHermes == nil {
		return nil, errProviderInventory
	}
	payload, err := backend.readHermes(ctx, "--profile", profile, "config", "get", "providers", "--json")
	if err != nil {
		return nil, fmt.Errorf("%w: %v", errProviderInventory, err)
	}
	var document map[string]json.RawMessage
	if err := json.Unmarshal(payload, &document); err != nil || len(document) > maxCustomProviders {
		return nil, errProviderInventory
	}
	return document, nil
}

func (backend *providerBackend) writeProviderLocked(ctx context.Context, profile string, row customProviderRow) error {
	fields := [][2]string{{"name", row.ID}, {"base_url", row.BaseURL}, {"model", row.Model}}
	for _, field := range fields {
		if err := backend.runHermes(ctx, "--profile", profile, "config", "set", "--force", "providers."+row.ID+"."+field[0], field[1]); err != nil {
			return errProviderCLIFailed
		}
	}
	return nil
}

func (backend *providerBackend) rollbackProviderCreate(profile, id string) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if err := backend.runHermes(ctx, "--profile", profile, "config", "unset", "providers."+id); err != nil {
		return fmt.Errorf("%w: rollback failed", errProviderCLIFailed)
	}
	return nil
}

func (backend *providerBackend) rollbackProviderUpdate(profile string, row customProviderRow) error {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if err := backend.writeProviderLocked(ctx, profile, row); err != nil {
		return fmt.Errorf("%w: rollback failed", errProviderCLIFailed)
	}
	return nil
}

func validateCustomProvider(id, baseURL, model string) (customProviderRow, error) {
	normalized, err := normalizeProviderID(id)
	if err != nil || normalized != strings.TrimSpace(id) {
		return customProviderRow{}, errProviderInvalid
	}
	baseURL = strings.TrimSpace(baseURL)
	model = strings.TrimSpace(model)
	if len([]rune(baseURL)) > 2048 || len([]rune(model)) == 0 || len([]rune(model)) > 200 || hasControl(model) {
		return customProviderRow{}, errProviderInvalid
	}
	parsed, err := url.Parse(baseURL)
	if err != nil || (parsed.Scheme != "http" && parsed.Scheme != "https") || parsed.Hostname() == "" || parsed.User != nil || parsed.RawQuery != "" || parsed.Fragment != "" {
		return customProviderRow{}, errProviderInvalid
	}
	if !validURLPort(parsed) {
		return customProviderRow{}, errProviderInvalid
	}
	return customProviderRow{ID: normalized, BaseURL: parsed.String(), Model: model}, nil
}

func normalizeProviderID(value string) (string, error) {
	id := strings.ToLower(strings.TrimSpace(value))
	if !profileIDPattern.MatchString(id) {
		return "", errProviderInvalid
	}
	return id, nil
}

func normalizeProviderProfile(value string) (string, error) {
	profile, err := normalizeProfileID(value)
	if err != nil || profile != strings.TrimSpace(value) {
		return "", errProviderInvalid
	}
	return profile, nil
}

func providerConfigKey(value string) (id, field string, ok bool) {
	parts := strings.Split(value, ".")
	if len(parts) != 3 || parts[0] != "providers" {
		return "", "", false
	}
	id, err := normalizeProviderID(parts[1])
	return id, parts[2], err == nil && id == parts[1]
}

func providerRevision(profile string, row customProviderRow) string {
	digest := sha256.Sum256([]byte(profile + "\n" + row.ID + "\n" + row.BaseURL + "\n" + row.Model))
	return "wlpv_" + hex.EncodeToString(digest[:])
}

func findCustomProvider(rows []customProviderRow, id string) (customProviderRow, bool) {
	for _, row := range rows {
		if row.ID == id {
			return row, true
		}
	}
	return customProviderRow{}, false
}

func hasControl(value string) bool {
	return strings.IndexFunc(value, unicode.IsControl) >= 0
}

func (server *wingLinkServer) serveProviderRoute(writer http.ResponseWriter, request *http.Request) bool {
	if request.URL.Path == "/v1/providers" {
		switch request.Method {
		case http.MethodGet:
			if server.requireReadAuthorization(writer, request) {
				server.listProviders(writer, request)
			}
		case http.MethodPost:
			if server.requireAuthorization(writer, request) {
				server.createProvider(writer, request)
			}
		default:
			writer.WriteHeader(http.StatusMethodNotAllowed)
		}
		return true
	}
	id, ok := customProviderRoute(request.URL.Path)
	if !ok {
		return false
	}
	if !server.requireAuthorization(writer, request) {
		return true
	}
	switch request.Method {
	case http.MethodPatch:
		server.updateProvider(writer, request, id)
	case http.MethodDelete:
		server.deleteProvider(writer, request, id)
	default:
		writer.WriteHeader(http.StatusMethodNotAllowed)
	}
	return true
}

func (server *wingLinkServer) listProviders(writer http.ResponseWriter, request *http.Request) {
	rows, err := server.providers.list(request.Context(), request.URL.Query().Get("profile"))
	if err != nil {
		writeProviderError(writer, err)
		return
	}
	writeJSON(writer, http.StatusOK, map[string]any{"protocol_version": ProtocolVersion, "providers": rows})
}

func (server *wingLinkServer) createProvider(writer http.ResponseWriter, request *http.Request) {
	var body struct {
		ID      string `json:"id"`
		BaseURL string `json:"base_url"`
		Model   string `json:"model"`
	}
	if !decodeJSON(writer, request, &body) {
		return
	}
	row, err := server.providers.create(request.Context(), request.URL.Query().Get("profile"), body.ID, body.BaseURL, body.Model)
	if err != nil {
		writeProviderError(writer, err)
		return
	}
	writeJSON(writer, http.StatusCreated, map[string]any{"provider": row})
}

func (server *wingLinkServer) updateProvider(writer http.ResponseWriter, request *http.Request, id string) {
	var body struct {
		BaseURL  string `json:"base_url"`
		Model    string `json:"model"`
		Revision string `json:"revision"`
	}
	if !decodeJSON(writer, request, &body) {
		return
	}
	revision := strings.TrimSpace(body.Revision)
	if revision == "" {
		revision = strings.TrimSpace(request.Header.Get("If-Match"))
	}
	row, err := server.providers.update(request.Context(), request.URL.Query().Get("profile"), id, body.BaseURL, body.Model, revision)
	if err != nil {
		writeProviderError(writer, err)
		return
	}
	writeJSON(writer, http.StatusOK, map[string]any{"provider": row})
}

func (server *wingLinkServer) deleteProvider(writer http.ResponseWriter, request *http.Request, id string) {
	if err := server.providers.delete(request.Context(), request.URL.Query().Get("profile"), id, strings.TrimSpace(request.Header.Get("If-Match"))); err != nil {
		writeProviderError(writer, err)
		return
	}
	writeJSON(writer, http.StatusOK, map[string]any{"id": id, "deleted": true})
}

func customProviderRoute(path string) (string, bool) {
	parts := strings.Split(strings.Trim(path, "/"), "/")
	if len(parts) != 3 || parts[0] != "v1" || parts[1] != "providers" {
		return "", false
	}
	id, err := normalizeProviderID(parts[2])
	return id, err == nil && id == parts[2]
}

func writeProviderError(writer http.ResponseWriter, err error) {
	status, code, message := http.StatusBadRequest, "provider_invalid", "Provider configuration is invalid"
	switch {
	case errors.Is(err, errProviderExists):
		status, code, message = http.StatusConflict, "provider_already_exists", "Provider already exists"
	case errors.Is(err, errProviderNotFound):
		status, code, message = http.StatusNotFound, "provider_not_found", "Provider not found"
	case errors.Is(err, errProviderChanged):
		status, code, message = http.StatusConflict, "provider_changed", "Provider changed; refresh and retry"
	case errors.Is(err, errProviderCLIFailed), errors.Is(err, errProviderInventory):
		status, code, message = http.StatusServiceUnavailable, "provider_unavailable", "Provider management is unavailable"
	}
	writeJSON(writer, status, map[string]any{"error": APIError{Code: code, Message: message}})
}
