package state

import (
	"crypto/ed25519"
	"encoding/base64"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
	"unicode/utf8"
)

var ErrDeviceNotFound = errors.New("device credential not found")

const (
	ScopeSetupWrite       = "setup:write"
	ScopeLifecycleWrite   = "lifecycle:write"
	ScopeHealthRead       = "health:read"
	ScopeDiagnosticsRead  = "diagnostics:read"
	ScopeProfilesRead     = "profiles:read"
	ScopeProfilesWrite    = "profiles:write"
	ScopeProvidersRead    = "providers:read"
	ScopeProvidersWrite   = "providers:write"
	ScopeDirectoriesRead  = "directories:read"
	ScopeDeviceSelfRead   = "device:self:read"
	ScopeDeviceSelfRevoke = "device:self:revoke"
)

var legacyControlScopes = []string{
	ScopeSetupWrite,
	ScopeLifecycleWrite,
	ScopeHealthRead,
	ScopeDiagnosticsRead,
	ScopeProfilesRead,
	ScopeProfilesWrite,
	ScopeProvidersRead,
	ScopeProvidersWrite,
	ScopeDeviceSelfRead,
	ScopeDeviceSelfRevoke,
}

var allControlScopes = append(
	append([]string(nil), legacyControlScopes...),
	ScopeDirectoriesRead,
)

var allowedControlScopes = func() map[string]struct{} {
	result := make(map[string]struct{}, len(allControlScopes))
	for _, scope := range allControlScopes {
		result[scope] = struct{}{}
	}
	return result
}()

type persistedDeviceCredential struct {
	ID         string   `json:"id"`
	Name       string   `json:"name"`
	TokenHash  string   `json:"token_hash"`
	PublicKey  string   `json:"public_key,omitempty"`
	Scopes     []string `json:"scopes"`
	CreatedAt  int64    `json:"created_at"`
	LastUsedAt int64    `json:"last_used_at,omitempty"`
	ExpiresAt  int64    `json:"expires_at,omitempty"`
	Legacy     bool     `json:"legacy,omitempty"`
	Bearer     bool     `json:"bearer,omitempty"`
}

// DeviceCredential is safe for local inventory and API self-inspection. The
// token hash is intentionally blank in every exported value.
type DeviceCredential struct {
	ID         string
	Name       string
	TokenHash  string
	PublicKey  ed25519.PublicKey
	Scopes     []string
	CreatedAt  time.Time
	LastUsedAt time.Time
	ExpiresAt  time.Time
	Legacy     bool
	Bearer     bool
}

type DeviceAuthorization struct {
	Device DeviceCredential
}

func (s *StateStore) StageDeviceCredential(name string, publicKey ed25519.PublicKey, scopes []string) (string, string, error) {
	return s.stageDeviceCredentialMode(name, publicKey, scopes, 0, false, false)
}

func (s *StateStore) StageBearerDeviceCredential(name string, scopes []string) (string, string, error) {
	return s.stageDeviceCredentialMode(name, nil, scopes, 0, false, true)
}

func (s *StateStore) stageDeviceCredential(name string, publicKey ed25519.PublicKey, scopes []string, lifetime time.Duration, legacy bool) (string, string, error) {
	return s.stageDeviceCredentialMode(name, publicKey, scopes, lifetime, legacy, false)
}

func (s *StateStore) stageDeviceCredentialMode(name string, publicKey ed25519.PublicKey, scopes []string, lifetime time.Duration, legacy, bearer bool) (string, string, error) {
	trimmedName := strings.TrimSpace(name)
	if !validDeviceName(trimmedName) {
		return "", "", errors.New("invalid device name")
	}
	if !legacy && !bearer && len(publicKey) != ed25519.PublicKeySize {
		return "", "", errors.New("invalid device public key")
	}
	normalizedScopes, err := normalizeDeviceScopes(scopes)
	if err != nil {
		return "", "", err
	}

	s.mu.Lock()
	defer s.mu.Unlock()
	id, err := randomSecret(16, "cred_")
	if err != nil {
		return "", "", err
	}
	token, err := randomSecret(32, "wlc_")
	if err != nil {
		return "", "", err
	}
	deviceExpiresAt := int64(0)
	if lifetime > 0 {
		deviceExpiresAt = s.currentTime().Add(lifetime).Unix()
	}
	encodedPublicKey := ""
	if len(publicKey) == ed25519.PublicKeySize {
		encodedPublicKey = base64.RawURLEncoding.EncodeToString(publicKey)
	}
	now := s.currentTime().UTC()
	pending := persistedPendingCredential{
		ID: id, Hash: hashSecret(token), ExpiresAt: now.Add(5 * time.Minute).Unix(),
		Name: trimmedName, PublicKey: encodedPublicKey, Scopes: normalizedScopes,
		CreatedAt: now.Unix(), DeviceExpiresAt: deviceExpiresAt, Legacy: legacy, Bearer: bearer,
	}
	if err := s.withFileLock(func() error {
		state, err := s.load()
		if err != nil {
			return err
		}
		prunePendingState(&state, now)
		if len(state.Devices)+len(state.ControlTokenHashes)+len(state.PendingDevices) >= maxControlTokens {
			return errors.New("too many control tokens")
		}
		state.PendingDevices = append(state.PendingDevices, pending)
		return s.save(state)
	}); err != nil {
		return "", "", err
	}
	return id, token, nil
}

func (s *StateStore) AuthorizeDevice(token string, requiredScopes ...string) (DeviceAuthorization, bool) {
	if strings.TrimSpace(token) == "" {
		return DeviceAuthorization{}, false
	}
	s.mu.Lock()
	defer s.mu.Unlock()

	var authorization DeviceAuthorization
	authorized := false
	if err := s.withFileLock(func() error {
		state, err := s.load()
		if err != nil {
			return err
		}
		now := s.currentTime().UTC()
		for index := range state.Devices {
			device := &state.Devices[index]
			if !matchesHash(token, device.TokenHash) {
				continue
			}
			if device.ExpiresAt != 0 && !now.Before(time.Unix(device.ExpiresAt, 0)) {
				return nil
			}
			if !containsEveryScope(device.Scopes, requiredScopes) {
				return nil
			}
			device.LastUsedAt = now.Unix()
			if err := s.save(state); err != nil {
				return err
			}
			authorization = DeviceAuthorization{Device: publicDevice(*device)}
			authorized = true
			return nil
		}
		for _, expected := range state.ControlTokenHashes {
			if !matchesHash(token, expected) || !containsEveryScope(legacyControlScopes, requiredScopes) {
				continue
			}
			authorization = DeviceAuthorization{Device: DeviceCredential{
				ID:        legacyDeviceID(expected),
				Name:      "Legacy paired device",
				Scopes:    append([]string(nil), legacyControlScopes...),
				CreatedAt: time.Unix(0, 0).UTC(),
				Legacy:    true,
			}}
			authorized = true
			break
		}
		return nil
	}); err != nil {
		return DeviceAuthorization{}, false
	}
	return authorization, authorized
}

func (s *StateStore) ListDevices() ([]DeviceCredential, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	var devices []DeviceCredential
	err := s.withFileLock(func() error {
		state, err := s.load()
		if err != nil {
			return err
		}
		devices = make([]DeviceCredential, 0, len(state.Devices)+len(state.ControlTokenHashes))
		for _, device := range state.Devices {
			devices = append(devices, publicDevice(device))
		}
		for _, hash := range state.ControlTokenHashes {
			devices = append(devices, DeviceCredential{
				ID:        legacyDeviceID(hash),
				Name:      "Legacy paired device",
				Scopes:    append([]string(nil), legacyControlScopes...),
				CreatedAt: time.Unix(0, 0).UTC(),
				Legacy:    true,
			})
		}
		sort.Slice(devices, func(i, j int) bool { return devices[i].ID < devices[j].ID })
		return nil
	})
	return devices, err
}

func (s *StateStore) RevokeDevice(id string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.withFileLock(func() error {
		state, err := s.load()
		if err != nil {
			return err
		}
		for index, device := range state.Devices {
			if device.ID == id {
				state.Devices = append(state.Devices[:index], state.Devices[index+1:]...)
				return s.save(state)
			}
		}
		for index, hash := range state.ControlTokenHashes {
			if legacyDeviceID(hash) == id {
				state.ControlTokenHashes = append(state.ControlTokenHashes[:index], state.ControlTokenHashes[index+1:]...)
				return s.save(state)
			}
		}
		return ErrDeviceNotFound
	})
}

func validDeviceName(name string) bool {
	return name != "" && utf8.ValidString(name) && len([]rune(name)) <= 80 && !strings.ContainsAny(name, "\x00\r\n")
}

func normalizeDeviceScopes(scopes []string) ([]string, error) {
	if len(scopes) == 0 || len(scopes) > len(allControlScopes) {
		return nil, errors.New("invalid device scopes")
	}
	seen := make(map[string]struct{}, len(scopes))
	result := make([]string, 0, len(scopes))
	for _, scope := range scopes {
		if _, ok := allowedControlScopes[scope]; !ok {
			return nil, fmt.Errorf("invalid device scope %q", scope)
		}
		if _, duplicate := seen[scope]; duplicate {
			return nil, errors.New("duplicate device scope")
		}
		seen[scope] = struct{}{}
		result = append(result, scope)
	}
	sort.Strings(result)
	return result, nil
}

func containsEveryScope(granted, required []string) bool {
	set := make(map[string]struct{}, len(granted))
	for _, scope := range granted {
		set[scope] = struct{}{}
	}
	for _, scope := range required {
		if _, ok := set[scope]; !ok {
			return false
		}
	}
	return true
}

func publicDevice(device persistedDeviceCredential) DeviceCredential {
	var publicKey ed25519.PublicKey
	if device.PublicKey != "" {
		decoded, _ := base64.RawURLEncoding.DecodeString(device.PublicKey)
		publicKey = append(ed25519.PublicKey(nil), decoded...)
	}
	result := DeviceCredential{
		ID:        device.ID,
		Name:      device.Name,
		PublicKey: publicKey,
		Scopes:    append([]string(nil), device.Scopes...),
		CreatedAt: time.Unix(device.CreatedAt, 0).UTC(),
		Legacy:    device.Legacy,
		Bearer:    device.Bearer,
	}
	if device.LastUsedAt != 0 {
		result.LastUsedAt = time.Unix(device.LastUsedAt, 0).UTC()
	}
	if device.ExpiresAt != 0 {
		result.ExpiresAt = time.Unix(device.ExpiresAt, 0).UTC()
	}
	return result
}

func legacyDeviceID(hash string) string {
	const prefixLength = 20
	if len(hash) < prefixLength {
		return "legacy_invalid"
	}
	return "legacy_" + hash[:prefixLength]
}

func validatePersistedDevice(device persistedDeviceCredential) error {
	if !strings.HasPrefix(device.ID, "cred_") || len(device.ID) > 96 || !validDeviceName(device.Name) || !validHash(device.TokenHash) {
		return errors.New("invalid device credential")
	}
	if device.CreatedAt <= 0 || device.LastUsedAt < 0 || device.ExpiresAt < 0 {
		return errors.New("invalid device timestamps")
	}
	if device.LastUsedAt != 0 && device.LastUsedAt < device.CreatedAt {
		return errors.New("invalid device last-used time")
	}
	if device.ExpiresAt != 0 && device.ExpiresAt <= device.CreatedAt {
		return errors.New("invalid device expiry")
	}
	if device.PublicKey == "" {
		if !device.Legacy && !device.Bearer {
			return errors.New("device public key is required")
		}
	} else {
		if device.Bearer {
			return errors.New("bearer device cannot contain a public key")
		}
		decoded, err := base64.RawURLEncoding.DecodeString(device.PublicKey)
		if err != nil || len(decoded) != ed25519.PublicKeySize {
			return errors.New("invalid device public key")
		}
	}
	if _, err := normalizeDeviceScopes(device.Scopes); err != nil {
		return err
	}
	return nil
}
