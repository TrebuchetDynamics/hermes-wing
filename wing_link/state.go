package main

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
	stateSchema      = 1
	maxControlTokens = 16
)

type Enrollment struct {
	Code      string
	ExpiresAt time.Time
}

type StateStore struct {
	path    string
	now     func() time.Time
	mu      sync.Mutex
	pending map[string]pendingControlToken
}

type pendingControlToken struct {
	Hash      string `json:"hash"`
	ExpiresAt int64  `json:"expires_at"`
}

type persistedState struct {
	Schema             int      `json:"schema"`
	EnrollmentHash     string   `json:"enrollment_hash,omitempty"`
	EnrollmentExpires  int64    `json:"enrollment_expires,omitempty"`
	ControlTokenHashes []string `json:"control_token_hashes,omitempty"`
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
		if err := validate(&state); err != nil {
			return err
		}
		token, err = randomSecret(32, "wlc_")
		if err != nil {
			return err
		}
		state.ControlTokenHashes = append(state.ControlTokenHashes, hashSecret(token))
		if len(state.ControlTokenHashes) > maxControlTokens {
			state.ControlTokenHashes = state.ControlTokenHashes[len(state.ControlTokenHashes)-maxControlTokens:]
		}
		return s.save(state)
	})
	if err != nil {
		return "", err
	}
	return token, nil
}

func (s *StateStore) StageControlToken() (string, string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.removeExpiredPendingLocked()
	if len(s.pending) >= maxControlTokens {
		return "", "", errors.New("too many pending control tokens")
	}
	id, err := randomSecret(16, "cred_")
	if err != nil {
		return "", "", err
	}
	token, err := randomSecret(32, "wlc_")
	if err != nil {
		return "", "", err
	}
	if s.pending == nil {
		s.pending = make(map[string]pendingControlToken)
	}
	s.pending[id] = pendingControlToken{
		Hash: hashSecret(token), ExpiresAt: s.currentTime().Add(5 * time.Minute).Unix(),
	}
	return id, token, nil
}

func (s *StateStore) AcknowledgeControlToken(id, token string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.removeExpiredPendingLocked()
	pending, ok := s.pending[id]
	if !ok || !matchesHash(token, pending.Hash) {
		return ErrEnrollmentUnavailable
	}
	if err := s.withFileLock(func() error {
		state, err := s.load()
		if err != nil {
			return err
		}
		state.ControlTokenHashes = append(state.ControlTokenHashes, pending.Hash)
		if len(state.ControlTokenHashes) > maxControlTokens {
			state.ControlTokenHashes = state.ControlTokenHashes[len(state.ControlTokenHashes)-maxControlTokens:]
		}
		return s.save(state)
	}); err != nil {
		return err
	}
	delete(s.pending, id)
	return nil
}

func (s *StateStore) AuthorizePending(id, token string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.removeExpiredPendingLocked()
	pending, ok := s.pending[id]
	return ok && matchesHash(token, pending.Hash)
}

func (s *StateStore) AuthorizePendingToken(token string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.removeExpiredPendingLocked()
	for _, pending := range s.pending {
		if matchesHash(token, pending.Hash) {
			return true
		}
	}
	return false
}

func (s *StateStore) removeExpiredPendingLocked() {
	for id, pending := range s.pending {
		if !s.currentTime().Before(time.Unix(pending.ExpiresAt, 0)) {
			delete(s.pending, id)
		}
	}
}

func (s *StateStore) Authorize(token string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()

	authorized := false
	if err := s.withFileLock(func() error {
		state, err := s.load()
		if err != nil {
			return err
		}
		for _, expected := range state.ControlTokenHashes {
			authorized = authorized || matchesHash(token, expected)
		}
		return nil
	}); err != nil {
		return false
	}
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
		s.pending = nil
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
	decoder := json.NewDecoder(io.LimitReader(file, 64<<10))
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
	if state.Schema != stateSchema {
		return errors.New("unsupported state schema")
	}
	if state.EnrollmentHash != "" && !validHash(state.EnrollmentHash) {
		return errors.New("invalid enrollment hash")
	}
	if len(state.ControlTokenHashes) > maxControlTokens {
		return errors.New("too many control tokens")
	}
	for _, hash := range state.ControlTokenHashes {
		if !validHash(hash) {
			return errors.New("invalid control token hash")
		}
	}
	return nil
}

func (s *StateStore) save(state persistedState) error {
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
