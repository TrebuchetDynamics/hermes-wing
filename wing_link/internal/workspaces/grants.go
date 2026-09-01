package workspaces

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"unicode/utf8"

	wingstate "github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/state"
)

const (
	grantSchema   = 1
	maxGrantCount = 32
	maxPathBytes  = 4096
)

var ErrGrantNotFound = errors.New("directory grant not found")

// DirectoryGrant is host-local grant metadata. Path never belongs in a remote response.
type DirectoryGrant struct {
	ID   string `json:"id"`
	Name string `json:"name"`
	Path string `json:"path"`
}

type persistedGrants struct {
	Schema int              `json:"schema"`
	Grants []DirectoryGrant `json:"grants,omitempty"`
}

type Store struct {
	path string
}

func Open(path string) (*Store, error) {
	if path == "" || !filepath.IsAbs(path) {
		return nil, errors.New("directory grant state path must be absolute")
	}
	return &Store{path: path}, nil
}

func (s *Store) Grant(path string) (DirectoryGrant, error) {
	canonical, err := canonicalDirectory(path)
	if err != nil {
		return DirectoryGrant{}, err
	}
	var result DirectoryGrant
	err = s.withLock(func() error {
		state, err := s.load()
		if err != nil {
			return err
		}
		for _, grant := range state.Grants {
			if grant.Path == canonical {
				result = grant
				return nil
			}
		}
		if len(state.Grants) >= maxGrantCount {
			return errors.New("too many directory grants")
		}
		id, err := wingstate.RandomSecret(16, "dir_")
		if err != nil {
			return err
		}
		result = DirectoryGrant{ID: id, Name: filepath.Base(canonical), Path: canonical}
		state.Grants = append(state.Grants, result)
		return s.save(state)
	})
	return result, err
}

func (s *Store) List() ([]DirectoryGrant, error) {
	var grants []DirectoryGrant
	err := s.withLock(func() error {
		state, err := s.load()
		if err != nil {
			return err
		}
		grants = append([]DirectoryGrant(nil), state.Grants...)
		return nil
	})
	return grants, err
}

func (s *Store) Resolve(id string) (DirectoryGrant, error) {
	if !validGrantID(id) {
		return DirectoryGrant{}, ErrGrantNotFound
	}
	var resolved DirectoryGrant
	err := s.withLock(func() error {
		state, err := s.load()
		if err != nil {
			return err
		}
		for _, grant := range state.Grants {
			if grant.ID != id {
				continue
			}
			canonical, err := canonicalDirectory(grant.Path)
			if err != nil || canonical != grant.Path {
				return ErrGrantNotFound
			}
			resolved = grant
			return nil
		}
		return ErrGrantNotFound
	})
	return resolved, err
}

func (s *Store) Revoke(id string) error {
	if !validGrantID(id) {
		return ErrGrantNotFound
	}
	return s.withLock(func() error {
		state, err := s.load()
		if err != nil {
			return err
		}
		for index, grant := range state.Grants {
			if grant.ID != id {
				continue
			}
			state.Grants = append(state.Grants[:index], state.Grants[index+1:]...)
			return s.save(state)
		}
		return ErrGrantNotFound
	})
}

func canonicalDirectory(path string) (string, error) {
	if path == "" || strings.IndexByte(path, 0) >= 0 || len(path) > maxPathBytes {
		return "", errors.New("directory path is invalid")
	}
	absolute, err := filepath.Abs(path)
	if err != nil {
		return "", fmt.Errorf("resolve directory path: %w", err)
	}
	canonical, err := filepath.EvalSymlinks(absolute)
	if err != nil {
		return "", fmt.Errorf("resolve directory path: %w", err)
	}
	canonical = filepath.Clean(canonical)
	if !utf8.ValidString(canonical) || len(canonical) > maxPathBytes {
		return "", errors.New("directory path is invalid")
	}
	info, err := os.Stat(canonical)
	if err != nil {
		return "", fmt.Errorf("inspect directory: %w", err)
	}
	if !info.IsDir() {
		return "", errors.New("directory grant must name a directory")
	}
	name := filepath.Base(canonical)
	if name == "" || !utf8.ValidString(name) || len(name) > 255 {
		return "", errors.New("directory name is invalid")
	}
	return canonical, nil
}

func (s *Store) withLock(work func() error) error {
	directory := filepath.Dir(s.path)
	if err := os.MkdirAll(directory, 0o700); err != nil {
		return fmt.Errorf("create directory grant state directory: %w", err)
	}
	if err := wingstate.SecurePath(directory, true); err != nil {
		return fmt.Errorf("secure directory grant state directory: %w", err)
	}
	release, err := wingstate.AcquireLock(s.path + ".lock")
	if err != nil {
		return fmt.Errorf("lock directory grants: %w", err)
	}
	defer func() { _ = release() }()
	return work()
}

func (s *Store) load() (persistedGrants, error) {
	state := persistedGrants{Schema: grantSchema}
	info, err := os.Lstat(s.path)
	if errors.Is(err, os.ErrNotExist) {
		return state, nil
	}
	if err != nil {
		return state, fmt.Errorf("inspect directory grant state: %w", err)
	}
	if !info.Mode().IsRegular() || info.Size() > 64<<10 {
		return state, errors.New("directory grant state is invalid")
	}
	ownerOnly, err := wingstate.PathOwnerOnly(s.path, false)
	if err != nil || !ownerOnly {
		return state, errors.New("directory grant state is not owner-only")
	}
	file, err := os.Open(s.path)
	if err != nil {
		return state, fmt.Errorf("open directory grant state: %w", err)
	}
	defer func() { _ = file.Close() }()
	decoder := json.NewDecoder(io.LimitReader(file, 64<<10))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&state); err != nil {
		return state, fmt.Errorf("decode directory grant state: %w", err)
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return state, errors.New("decode directory grant state: trailing data")
	}
	if err := validateGrants(state); err != nil {
		return state, err
	}
	return state, nil
}

func validateGrants(state persistedGrants) error {
	if state.Schema != grantSchema || len(state.Grants) > maxGrantCount {
		return errors.New("invalid directory grant state")
	}
	ids := make(map[string]struct{}, len(state.Grants))
	paths := make(map[string]struct{}, len(state.Grants))
	for _, grant := range state.Grants {
		if !validGrantID(grant.ID) || grant.Path == "" || !filepath.IsAbs(grant.Path) || filepath.Clean(grant.Path) != grant.Path || len(grant.Path) > maxPathBytes || !utf8.ValidString(grant.Path) || grant.Name != filepath.Base(grant.Path) || len(grant.Name) > 255 {
			return errors.New("invalid directory grant")
		}
		if _, duplicate := ids[grant.ID]; duplicate {
			return errors.New("duplicate directory grant id")
		}
		if _, duplicate := paths[grant.Path]; duplicate {
			return errors.New("duplicate directory grant path")
		}
		ids[grant.ID] = struct{}{}
		paths[grant.Path] = struct{}{}
	}
	return nil
}

func validGrantID(id string) bool {
	if len(id) != 26 || !strings.HasPrefix(id, "dir_") {
		return false
	}
	for _, char := range id[4:] {
		if (char < 'A' || char > 'Z') && (char < 'a' || char > 'z') && (char < '0' || char > '9') && char != '-' && char != '_' {
			return false
		}
	}
	return true
}

func (s *Store) save(state persistedGrants) error {
	payload, err := json.Marshal(state)
	if err != nil {
		return fmt.Errorf("encode directory grants: %w", err)
	}
	temp, err := os.CreateTemp(filepath.Dir(s.path), ".directory-grants-*")
	if err != nil {
		return fmt.Errorf("create directory grant state: %w", err)
	}
	tempPath := temp.Name()
	defer func() { _ = os.Remove(tempPath) }()
	if err := wingstate.SecurePath(tempPath, false); err != nil {
		_ = temp.Close()
		return err
	}
	if _, err := temp.Write(payload); err != nil {
		_ = temp.Close()
		return fmt.Errorf("write directory grants: %w", err)
	}
	if err := temp.Sync(); err != nil {
		_ = temp.Close()
		return fmt.Errorf("sync directory grants: %w", err)
	}
	if err := temp.Close(); err != nil {
		return fmt.Errorf("close directory grants: %w", err)
	}
	if err := wingstate.ReplaceFile(tempPath, s.path); err != nil {
		return fmt.Errorf("replace directory grants: %w", err)
	}
	return wingstate.SyncDirectory(filepath.Dir(s.path))
}
