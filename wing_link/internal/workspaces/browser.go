package workspaces

import (
	"errors"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"
	"unicode/utf8"
)

const (
	handleLifetime       = 15 * time.Minute
	maxLiveHandles       = 2048
	maxDeviceHandles     = 256
	defaultPageSize      = 50
	maxPageSize          = 100
	maxScannedEntries    = 4096
	maxChildDirectories  = 1000
	maxDirectoryNameSize = 255
)

var (
	ErrHandleUnavailable    = errors.New("directory handle unavailable")
	ErrGrantRevoked         = errors.New("directory grant revoked")
	ErrDirectoryUnavailable = errors.New("directory unavailable")
	ErrDirectoryTooLarge    = errors.New("directory too large")
)

type Entry struct {
	Handle string
	Name   string
}

type Page struct {
	Entries    []Entry
	NextOffset *int
}

type handleRecord struct {
	deviceID     string
	grantID      string
	relativePath string
	expires      time.Time
}

type Browser struct {
	store  *Store
	now    func() time.Time
	random func(int, string) (string, error)

	mu      sync.Mutex
	handles map[string]handleRecord
}

func NewBrowser(store *Store, now func() time.Time, random func(int, string) (string, error)) *Browser {
	return &Browser{store: store, now: now, random: random, handles: make(map[string]handleRecord)}
}

func (b *Browser) Roots(deviceID string) ([]Entry, error) {
	if !validDeviceID(deviceID) || b.store == nil || b.now == nil || b.random == nil {
		return nil, ErrDirectoryUnavailable
	}
	grants, err := b.store.List()
	if err != nil {
		return nil, ErrDirectoryUnavailable
	}
	type candidate struct {
		grantID string
		name    string
	}
	candidates := make([]candidate, 0, len(grants))
	for _, grant := range grants {
		resolved, err := b.store.Resolve(grant.ID)
		if err != nil || !validDirectoryName(resolved.Name) {
			continue
		}
		root, err := openRootNoSymlinks(resolved.Path)
		if err != nil {
			continue
		}
		_ = root.Close()
		candidates = append(candidates, candidate{grantID: resolved.ID, name: resolved.Name})
	}
	sort.Slice(candidates, func(i, j int) bool {
		if candidates[i].name == candidates[j].name {
			return candidates[i].grantID < candidates[j].grantID
		}
		return candidates[i].name < candidates[j].name
	})
	entries := make([]Entry, 0, len(candidates))
	for _, candidate := range candidates {
		handle, err := b.issue(deviceID, candidate.grantID, ".")
		if err != nil {
			return nil, ErrDirectoryUnavailable
		}
		entries = append(entries, Entry{Handle: handle, Name: candidate.name})
	}
	return entries, nil
}

func (b *Browser) Children(deviceID, handle string, offset, limit int) (Page, error) {
	if offset < 0 || limit < 0 || limit > maxPageSize {
		return Page{}, ErrHandleUnavailable
	}
	if limit == 0 {
		limit = defaultPageSize
	}
	record, err := b.record(deviceID, handle)
	if err != nil {
		return Page{}, err
	}
	grant, err := b.store.Resolve(record.grantID)
	if err != nil {
		grants, listErr := b.store.List()
		if listErr != nil {
			return Page{}, ErrDirectoryUnavailable
		}
		for _, current := range grants {
			if current.ID == record.grantID {
				return Page{}, ErrDirectoryUnavailable
			}
		}
		return Page{}, ErrGrantRevoked
	}
	root, err := openRootNoSymlinks(grant.Path)
	if err != nil {
		return Page{}, ErrDirectoryUnavailable
	}
	defer func() { _ = root.Close() }()
	parent, err := root.OpenRoot(record.relativePath)
	if err != nil {
		return Page{}, ErrDirectoryUnavailable
	}
	defer func() { _ = parent.Close() }()

	file, err := parent.Open(".")
	if err != nil {
		return Page{}, ErrDirectoryUnavailable
	}
	defer func() { _ = file.Close() }()

	type candidate struct {
		name         string
		relativePath string
	}
	candidates := make([]candidate, 0)
	total := 0
	for {
		batchSize := min(256, maxScannedEntries-total+1)
		batch, readErr := file.ReadDir(batchSize)
		total += len(batch)
		if total > maxScannedEntries {
			return Page{}, ErrDirectoryTooLarge
		}
		for _, directoryEntry := range batch {
			name := directoryEntry.Name()
			if !validChildDirectoryName(name) {
				continue
			}
			probe, openErr := parent.OpenRoot(name)
			if openErr != nil {
				continue
			}
			_ = probe.Close()
			candidates = append(candidates, candidate{
				name:         name,
				relativePath: filepath.Join(record.relativePath, name),
			})
			if len(candidates) > maxChildDirectories {
				return Page{}, ErrDirectoryTooLarge
			}
		}
		if errors.Is(readErr, io.EOF) {
			break
		}
		if readErr != nil {
			return Page{}, ErrDirectoryUnavailable
		}
	}

	sort.Slice(candidates, func(i, j int) bool { return candidates[i].name < candidates[j].name })
	if offset >= len(candidates) {
		return Page{Entries: []Entry{}}, nil
	}
	end := offset + limit
	if end > len(candidates) {
		end = len(candidates)
	}
	entries := make([]Entry, 0, end-offset)
	for _, candidate := range candidates[offset:end] {
		childHandle, issueErr := b.issue(deviceID, record.grantID, candidate.relativePath)
		if issueErr != nil {
			return Page{}, ErrDirectoryUnavailable
		}
		entries = append(entries, Entry{Handle: childHandle, Name: candidate.name})
	}
	var nextOffset *int
	if end < len(candidates) {
		next := end
		nextOffset = &next
	}
	return Page{Entries: entries, NextOffset: nextOffset}, nil
}

func (b *Browser) issue(deviceID, grantID, relativePath string) (string, error) {
	b.mu.Lock()
	defer b.mu.Unlock()
	now := b.now()
	b.pruneExpiredLocked(now)
	for b.deviceHandleCountLocked(deviceID) >= maxDeviceHandles {
		b.evictEarliestForDeviceLocked(deviceID)
	}
	if len(b.handles) >= maxLiveHandles {
		if b.deviceHandleCountLocked(deviceID) == 0 {
			return "", ErrHandleUnavailable
		}
		b.evictEarliestForDeviceLocked(deviceID)
	}
	for attempts := 0; attempts < 4; attempts++ {
		handle, err := b.random(24, "dirh_")
		if err != nil {
			return "", err
		}
		if !validHandle(handle) {
			return "", ErrHandleUnavailable
		}
		if _, exists := b.handles[handle]; exists {
			continue
		}
		b.handles[handle] = handleRecord{
			deviceID: deviceID, grantID: grantID, relativePath: relativePath,
			expires: now.Add(handleLifetime),
		}
		return handle, nil
	}
	return "", ErrHandleUnavailable
}

func (b *Browser) record(deviceID, handle string) (handleRecord, error) {
	if !validDeviceID(deviceID) || !validHandle(handle) {
		return handleRecord{}, ErrHandleUnavailable
	}
	b.mu.Lock()
	defer b.mu.Unlock()
	record, ok := b.handles[handle]
	if !ok || record.deviceID != deviceID || !b.now().Before(record.expires) {
		if ok && !b.now().Before(record.expires) {
			delete(b.handles, handle)
		}
		return handleRecord{}, ErrHandleUnavailable
	}
	return record, nil
}

func (b *Browser) pruneExpiredLocked(now time.Time) {
	for handle, record := range b.handles {
		if !now.Before(record.expires) {
			delete(b.handles, handle)
		}
	}
}

func (b *Browser) deviceHandleCountLocked(deviceID string) int {
	count := 0
	for _, record := range b.handles {
		if record.deviceID == deviceID {
			count++
		}
	}
	return count
}

func (b *Browser) evictEarliestForDeviceLocked(deviceID string) {
	var selected string
	var expires time.Time
	for handle, record := range b.handles {
		if record.deviceID != deviceID {
			continue
		}
		if selected == "" || record.expires.Before(expires) || (record.expires.Equal(expires) && handle < selected) {
			selected = handle
			expires = record.expires
		}
	}
	if selected != "" {
		delete(b.handles, selected)
	}
}

func openRootNoSymlinks(absolute string) (*os.Root, error) {
	if absolute == "" || !filepath.IsAbs(absolute) || filepath.Clean(absolute) != absolute {
		return nil, ErrDirectoryUnavailable
	}
	volume := filepath.VolumeName(absolute)
	filesystemRoot := volume + string(filepath.Separator)
	current, err := os.OpenRoot(filesystemRoot)
	if err != nil {
		return nil, ErrDirectoryUnavailable
	}
	remainder := strings.TrimPrefix(absolute, filesystemRoot)
	for _, component := range strings.Split(remainder, string(filepath.Separator)) {
		if component == "" {
			continue
		}
		info, err := current.Lstat(component)
		if err != nil || !info.IsDir() || info.Mode()&os.ModeSymlink != 0 {
			_ = current.Close()
			return nil, ErrDirectoryUnavailable
		}
		next, err := current.OpenRoot(component)
		if err != nil {
			_ = current.Close()
			return nil, ErrDirectoryUnavailable
		}
		openedInfo, err := next.Stat(".")
		if err != nil || !os.SameFile(info, openedInfo) {
			_ = next.Close()
			_ = current.Close()
			return nil, ErrDirectoryUnavailable
		}
		latestInfo, err := current.Lstat(component)
		if err != nil || !os.SameFile(info, latestInfo) || latestInfo.Mode()&os.ModeSymlink != 0 {
			_ = next.Close()
			_ = current.Close()
			return nil, ErrDirectoryUnavailable
		}
		_ = current.Close()
		current = next
	}
	return current, nil
}

func validDirectoryName(name string) bool {
	return name != "" && name != "." && name != ".." && utf8.ValidString(name) &&
		len([]byte(name)) <= maxDirectoryNameSize && !strings.ContainsAny(name, "\x00/\\")
}

func validChildDirectoryName(name string) bool {
	return validDirectoryName(name) && !strings.HasPrefix(name, ".")
}

func validDeviceID(deviceID string) bool {
	return deviceID != "" && len(deviceID) <= 128 && !strings.ContainsAny(deviceID, "\x00\r\n")
}

func validHandle(handle string) bool {
	if len(handle) != 37 || !strings.HasPrefix(handle, "dirh_") {
		return false
	}
	for _, char := range handle[5:] {
		if (char < 'A' || char > 'Z') && (char < 'a' || char > 'z') &&
			(char < '0' || char > '9') && char != '-' && char != '_' {
			return false
		}
	}
	return true
}
