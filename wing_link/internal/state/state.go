package state

import (
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sync"
	"time"
)

var ErrEnrollmentUnavailable = errors.New("enrollment unavailable")

const (
	stateSchema      = 2
	maxControlTokens = 16
)

type Enrollment struct {
	Code      string
	ExpiresAt time.Time
}

type StateStore struct {
	path string
	now  func() time.Time
	mu   sync.Mutex
}

// New creates a secure Wing Link state store at path.
func New(path string) *StateStore {
	return &StateStore{path: path}
}

type persistedPendingCredential struct {
	ID              string   `json:"id"`
	Hash            string   `json:"token_hash"`
	ExpiresAt       int64    `json:"expires_at"`
	Name            string   `json:"name"`
	PublicKey       string   `json:"public_key,omitempty"`
	Scopes          []string `json:"scopes"`
	CreatedAt       int64    `json:"created_at"`
	DeviceExpiresAt int64    `json:"device_expires_at,omitempty"`
	Legacy          bool     `json:"legacy,omitempty"`
	Bearer          bool     `json:"bearer,omitempty"`
}

type persistedState struct {
	Schema                 int                          `json:"schema"`
	EnrollmentHash         string                       `json:"enrollment_hash,omitempty"`
	EnrollmentExpires      int64                        `json:"enrollment_expires,omitempty"`
	ControlTokenHashes     []string                     `json:"control_token_hashes,omitempty"`
	Devices                []persistedDeviceCredential  `json:"devices,omitempty"`
	PendingDevices         []persistedPendingCredential `json:"pending_devices,omitempty"`
	HostIdentityPrivateKey string                       `json:"host_identity_private_key,omitempty"`
	HostTLSPrivateKey      string                       `json:"host_tls_private_key,omitempty"`
}

func (s *StateStore) CreateEnrollment() (Enrollment, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	var enrollment Enrollment
	err := s.withFileLock(func() error {
		state, err := s.load()
		if err != nil {
			return err
		}
		code, err := randomSecret(24, "")
		if err != nil {
			return err
		}
		enrollment = Enrollment{Code: code, ExpiresAt: s.currentTime().Add(5 * time.Minute)}
		state.EnrollmentHash = hashSecret(code)
		state.EnrollmentExpires = enrollment.ExpiresAt.Unix()
		return s.save(state)
	})
	return enrollment, err
}

func (s *StateStore) ExchangeEnrollment(code string) (string, error) {
	return s.issueControlToken(func(state *persistedState) error {
		if state.EnrollmentHash == "" || !s.currentTime().Before(time.Unix(state.EnrollmentExpires, 0)) || !matchesHash(code, state.EnrollmentHash) {
			return ErrEnrollmentUnavailable
		}
		state.EnrollmentHash = ""
		state.EnrollmentExpires = 0
		return nil
	})
}

func (s *StateStore) IssueControlToken() (string, error) {
	return s.issueControlToken(func(*persistedState) error { return nil })
}

func (s *StateStore) issueControlToken(validate func(*persistedState) error) (string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	var token string
	err := s.withFileLock(func() error {
		state, err := s.load()
		if err != nil {
			return err
		}
		now := s.currentTime().UTC()
		pruneExpiredDevices(&state, now)
		if err := validate(&state); err != nil {
			return err
		}
		token, err = randomSecret(32, "wlc_")
		if err != nil {
			return err
		}
		if len(state.ControlTokenHashes)+len(state.Devices) >= maxControlTokens {
			return errors.New("too many control tokens")
		}
		state.ControlTokenHashes = append(state.ControlTokenHashes, hashSecret(token))
		return s.save(state)
	})
	if err != nil {
		return "", err
	}
	return token, nil
}

func (s *StateStore) StageControlToken() (string, string, error) {
	return s.stageDeviceCredential(
		"Hermes Wing device",
		nil,
		legacyControlScopes,
		0,
		true,
	)
}

func (s *StateStore) AcknowledgeControlToken(id, token string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.withFileLock(func() error {
		state, err := s.load()
		if err != nil {
			return err
		}
		now := s.currentTime().UTC()
		prunePendingState(&state, now)
		pruneExpiredDevices(&state, now)
		index := -1
		var pending persistedPendingCredential
		for candidate := range state.PendingDevices {
			if state.PendingDevices[candidate].ID == id && matchesHash(token, state.PendingDevices[candidate].Hash) {
				index = candidate
				pending = state.PendingDevices[candidate]
				break
			}
		}
		if index < 0 {
			return ErrEnrollmentUnavailable
		}
		if len(state.Devices)+len(state.ControlTokenHashes) >= maxControlTokens {
			return errors.New("too many control tokens")
		}
		state.Devices = append(state.Devices, persistedDeviceCredential{
			ID: id, Name: pending.Name, TokenHash: pending.Hash, PublicKey: pending.PublicKey,
			Scopes: append([]string(nil), pending.Scopes...), CreatedAt: pending.CreatedAt,
			ExpiresAt: pending.DeviceExpiresAt, Legacy: pending.Legacy, Bearer: pending.Bearer,
		})
		state.PendingDevices = append(state.PendingDevices[:index], state.PendingDevices[index+1:]...)
		return s.save(state)
	})
}

func (s *StateStore) AuthorizePending(id, token string) bool {
	return s.authorizePending(token, func(pending persistedPendingCredential) bool { return pending.ID == id })
}

func (s *StateStore) AuthorizePendingToken(token string) bool {
	return s.AuthorizePendingScope(token)
}

func (s *StateStore) AuthorizePendingScope(token string, requiredScopes ...string) bool {
	return s.authorizePending(token, func(pending persistedPendingCredential) bool {
		return containsEveryScope(pending.Scopes, requiredScopes)
	})
}

func (s *StateStore) authorizePending(token string, predicate func(persistedPendingCredential) bool) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	authorized := false
	_ = s.withFileLock(func() error {
		state, err := s.load()
		if err != nil {
			return err
		}
		prunePendingState(&state, s.currentTime().UTC())
		for _, pending := range state.PendingDevices {
			if predicate(pending) && matchesHash(token, pending.Hash) {
				authorized = true
				break
			}
		}
		return s.save(state)
	})
	return authorized
}

func pruneExpiredDevices(state *persistedState, now time.Time) {
	kept := state.Devices[:0]
	for _, device := range state.Devices {
		if device.ExpiresAt != 0 && !now.Before(time.Unix(device.ExpiresAt, 0)) {
			continue
		}
		kept = append(kept, device)
	}
	state.Devices = kept
}

func prunePendingState(state *persistedState, now time.Time) {
	kept := state.PendingDevices[:0]
	for _, pending := range state.PendingDevices {
		if now.Before(time.Unix(pending.ExpiresAt, 0)) {
			kept = append(kept, pending)
		}
	}
	state.PendingDevices = kept
}

func (s *StateStore) Authorize(token string) bool {
	_, authorized := s.AuthorizeDevice(token)
	return authorized
}

func (s *StateStore) RevokeAll() error {
	s.mu.Lock()
	defer s.mu.Unlock()

	return s.withFileLock(func() error {
		state, err := s.load()
		if err != nil {
			return err
		}
		state.EnrollmentHash = ""
		state.EnrollmentExpires = 0
		state.ControlTokenHashes = nil
		state.Devices = nil
		state.PendingDevices = nil
		return s.save(state)
	})
}

func (s *StateStore) currentTime() time.Time {
	if s.now != nil {
		return s.now()
	}
	return time.Now()
}

func (s *StateStore) withFileLock(work func() error) error {
	if s.path == "" {
		return errors.New("state path is required")
	}
	dir := filepath.Dir(s.path)
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return fmt.Errorf("create state directory: %w", err)
	}
	if err := secureStatePath(dir, true); err != nil {
		return fmt.Errorf("secure state directory: %w", err)
	}
	release, err := acquireStateLock(s.path + ".lock")
	if err != nil {
		return fmt.Errorf("lock state: %w", err)
	}
	defer func() { _ = release() }()
	return work()
}

func (s *StateStore) load() (persistedState, error) {
	state := persistedState{Schema: stateSchema}
	info, err := os.Lstat(s.path)
	if errors.Is(err, os.ErrNotExist) {
		return state, nil
	}
	if err != nil {
		return state, fmt.Errorf("inspect state: %w", err)
	}
	if !info.Mode().IsRegular() {
		return state, errors.New("state path is not a regular file")
	}
	if info.Size() > 64<<10 {
		return state, errors.New("state file is too large")
	}
	ownerOnly, err := statePathOwnerOnly(s.path, false)
	if err != nil {
		return state, fmt.Errorf("inspect state permissions: %w", err)
	}
	if !ownerOnly {
		return state, errors.New("state file is not owner-only")
	}
	file, err := os.Open(s.path)
	if err != nil {
		return state, fmt.Errorf("open state: %w", err)
	}
	defer func() { _ = file.Close() }()
	return decodePersistedState(io.LimitReader(file, 64<<10))
}

func decodePersistedState(reader io.Reader) (persistedState, error) {
	state := persistedState{Schema: stateSchema}
	decoder := json.NewDecoder(reader)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&state); err != nil {
		return state, fmt.Errorf("decode state: %w", err)
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return state, errors.New("decode state: trailing data")
	}
	if err := validatePersistedState(state); err != nil {
		return state, err
	}
	return state, nil
}

func validatePersistedState(state persistedState) error {
	if state.Schema != 1 && state.Schema != stateSchema {
		return errors.New("unsupported state schema")
	}
	if state.Schema == 1 && state.HostIdentityPrivateKey != "" {
		return errors.New("legacy state contains a host identity")
	}
	if state.EnrollmentHash != "" && !validHash(state.EnrollmentHash) {
		return errors.New("invalid enrollment hash")
	}
	if len(state.ControlTokenHashes)+len(state.Devices) > maxControlTokens || len(state.PendingDevices) > maxControlTokens {
		return errors.New("too many control tokens")
	}
	seenHashes := make(map[string]struct{}, len(state.ControlTokenHashes)+len(state.Devices))
	seenDeviceIDs := make(map[string]struct{}, len(state.Devices))
	for _, hash := range state.ControlTokenHashes {
		if !validHash(hash) {
			return errors.New("invalid control token hash")
		}
		if _, duplicate := seenHashes[hash]; duplicate {
			return errors.New("duplicate control token hash")
		}
		seenHashes[hash] = struct{}{}
	}
	for _, device := range state.Devices {
		if err := validatePersistedDevice(device); err != nil {
			return err
		}
		if _, duplicate := seenDeviceIDs[device.ID]; duplicate {
			return errors.New("duplicate device credential id")
		}
		if _, duplicate := seenHashes[device.TokenHash]; duplicate {
			return errors.New("duplicate control token hash")
		}
		seenDeviceIDs[device.ID] = struct{}{}
		seenHashes[device.TokenHash] = struct{}{}
	}
	for _, pending := range state.PendingDevices {
		candidate := persistedDeviceCredential{
			ID: pending.ID, Name: pending.Name, TokenHash: pending.Hash, PublicKey: pending.PublicKey,
			Scopes: pending.Scopes, CreatedAt: pending.CreatedAt, ExpiresAt: pending.DeviceExpiresAt,
			Legacy: pending.Legacy, Bearer: pending.Bearer,
		}
		if err := validatePersistedDevice(candidate); err != nil || pending.ExpiresAt <= pending.CreatedAt {
			return errors.New("invalid pending device credential")
		}
		if _, duplicate := seenDeviceIDs[pending.ID]; duplicate {
			return errors.New("duplicate device credential id")
		}
		if _, duplicate := seenHashes[pending.Hash]; duplicate {
			return errors.New("duplicate control token hash")
		}
		seenDeviceIDs[pending.ID] = struct{}{}
		seenHashes[pending.Hash] = struct{}{}
	}
	if state.HostIdentityPrivateKey == "" && state.HostTLSPrivateKey != "" {
		return errors.New("host TLS identity is missing its signing identity")
	}
	if state.HostIdentityPrivateKey != "" {
		if state.HostTLSPrivateKey == "" {
			decoded, err := base64.RawURLEncoding.DecodeString(state.HostIdentityPrivateKey)
			if err != nil || len(decoded) != 64 {
				return errors.New("invalid host identity private key")
			}
		} else if _, err := decodeHostIdentity(state.HostIdentityPrivateKey, state.HostTLSPrivateKey); err != nil {
			return err
		}
	}
	return nil
}

func (s *StateStore) save(state persistedState) error {
	state.Schema = stateSchema
	payload, err := json.Marshal(state)
	if err != nil {
		return fmt.Errorf("encode state: %w", err)
	}
	temp, err := os.CreateTemp(filepath.Dir(s.path), ".state-*")
	if err != nil {
		return fmt.Errorf("create state temp file: %w", err)
	}
	tempPath := temp.Name()
	defer func() { _ = os.Remove(tempPath) }()
	if err := secureStatePath(tempPath, false); err != nil {
		_ = temp.Close()
		return fmt.Errorf("secure state temp file: %w", err)
	}
	if _, err := temp.Write(payload); err != nil {
		_ = temp.Close()
		return fmt.Errorf("write state: %w", err)
	}
	if err := temp.Sync(); err != nil {
		_ = temp.Close()
		return fmt.Errorf("sync state: %w", err)
	}
	if err := temp.Close(); err != nil {
		return fmt.Errorf("close state: %w", err)
	}
	if err := replaceStateFile(tempPath, s.path); err != nil {
		return fmt.Errorf("replace state: %w", err)
	}
	return syncStateDirectory(filepath.Dir(s.path))
}

func randomSecret(size int, prefix string) (string, error) {
	value := make([]byte, size)
	if _, err := rand.Read(value); err != nil {
		return "", fmt.Errorf("generate secret: %w", err)
	}
	return prefix + base64.RawURLEncoding.EncodeToString(value), nil
}

func hashSecret(secret string) string {
	digest := sha256.Sum256([]byte(secret))
	return hex.EncodeToString(digest[:])
}

func matchesHash(secret, expected string) bool {
	actual := hashSecret(secret)
	return subtle.ConstantTimeCompare([]byte(actual), []byte(expected)) == 1
}

func validHash(value string) bool {
	decoded, err := hex.DecodeString(value)
	return err == nil && len(decoded) == sha256.Size
}
