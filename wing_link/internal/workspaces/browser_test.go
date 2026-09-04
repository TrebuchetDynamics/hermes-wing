package workspaces

import (
	"bytes"
	"encoding/base64"
	"encoding/binary"
	"errors"
	"os"
	"path/filepath"
	"slices"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

var deterministicSecretCounter atomic.Uint64

func deterministicSecret(size int, prefix string) (string, error) {
	payload := bytes.Repeat([]byte{0}, size)
	binary.BigEndian.PutUint64(payload[len(payload)-8:], deterministicSecretCounter.Add(1))
	return prefix + base64.RawURLEncoding.EncodeToString(payload), nil
}

func entryNames(entries []Entry) []string {
	names := make([]string, len(entries))
	for index, entry := range entries {
		names[index] = entry.Name
	}
	return names
}

func newBrowserWithRoot(t *testing.T, root string, now func() time.Time) (*Store, *Browser, Entry) {
	t.Helper()
	store, err := Open(filepath.Join(t.TempDir(), "grants.json"))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := store.Grant(root); err != nil {
		t.Fatal(err)
	}
	browser := NewBrowser(store, now, deterministicSecret)
	roots, err := browser.Roots("cred_phone")
	if err != nil || len(roots) != 1 {
		t.Fatalf("roots=%#v err=%v", roots, err)
	}
	return store, browser, roots[0]
}

func assertOpaqueError(t *testing.T, err error, forbidden ...string) {
	t.Helper()
	if err == nil {
		t.Fatal("expected an error")
	}
	for _, value := range forbidden {
		if value != "" && strings.Contains(err.Error(), value) {
			t.Fatalf("error exposed %q: %q", value, err)
		}
	}
}

func TestBrowserReturnsFoldersOnlyAndBindsHandlesToDevice(t *testing.T) {
	root := t.TempDir()
	for _, name := range []string{"alpha", "beta", ".hidden"} {
		if err := os.Mkdir(filepath.Join(root, name), 0o700); err != nil {
			t.Fatal(err)
		}
	}
	fileName := "secret.txt"
	if err := os.WriteFile(filepath.Join(root, fileName), []byte("secret"), 0o600); err != nil {
		t.Fatal(err)
	}
	store, err := Open(filepath.Join(t.TempDir(), "grants.json"))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := store.Grant(root); err != nil {
		t.Fatal(err)
	}
	browser := NewBrowser(store, time.Now, deterministicSecret)
	roots, err := browser.Roots("cred_phone")
	if err != nil || len(roots) != 1 || strings.Contains(roots[0].Handle, root) {
		t.Fatalf("roots=%#v err=%v", roots, err)
	}
	page, err := browser.Children("cred_phone", roots[0].Handle, 0, 50)
	if err != nil {
		t.Fatal(err)
	}
	if got := entryNames(page.Entries); !slices.Equal(got, []string{"alpha", "beta"}) {
		t.Fatalf("names=%q", got)
	}
	if slices.Contains(entryNames(page.Entries), ".hidden") {
		t.Fatal("hidden child directory was returned without an explicit grant")
	}
	if strings.Contains(strings.Join(entryNames(page.Entries), "\n"), fileName) {
		t.Fatal("regular file name was returned")
	}
	if _, err := browser.Children("cred_other", roots[0].Handle, 0, 50); !errors.Is(err, ErrHandleUnavailable) {
		t.Fatalf("another device used the handle: %v", err)
	}
}

func TestBrowserRejectsInvalidPaginationHandlesAndNames(t *testing.T) {
	browser := NewBrowser(nil, time.Now, deterministicSecret)
	validOpaqueHandle := "dirh_" + strings.Repeat("A", 32)
	for _, testCase := range []struct {
		name   string
		offset int
		limit  int
	}{
		{name: "negative offset", offset: -1, limit: 50},
		{name: "negative limit", offset: 0, limit: -1},
		{name: "oversized limit", offset: 0, limit: maxPageSize + 1},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			if _, err := browser.Children("cred_phone", validOpaqueHandle, testCase.offset, testCase.limit); !errors.Is(err, ErrHandleUnavailable) {
				t.Fatalf("pagination error=%v", err)
			}
		})
	}

	if !validDirectoryName(strings.Repeat("a", maxDirectoryNameSize)) {
		t.Fatal("maximum-length UTF-8 name was rejected")
	}
	for _, name := range []string{
		"",
		".",
		"..",
		strings.Repeat("a", maxDirectoryNameSize+1),
		string([]byte{0xff}),
		"path/name",
		`path\name`,
		"nul\x00name",
	} {
		if validDirectoryName(name) {
			t.Fatalf("invalid directory name was accepted: %q", name)
		}
	}
	for _, handle := range []string{"dirh_bad", validOpaqueHandle + "A", "dirh_" + strings.Repeat("!", 32)} {
		if validHandle(handle) {
			t.Fatalf("invalid handle was accepted: %q", handle)
		}
	}
}

func TestBrowserAllowsAnExplicitlyGrantedHiddenRoot(t *testing.T) {
	root := filepath.Join(t.TempDir(), ".approved")
	if err := os.Mkdir(root, 0o700); err != nil {
		t.Fatal(err)
	}
	_, _, entry := newBrowserWithRoot(t, root, time.Now)
	if entry.Name != ".approved" {
		t.Fatalf("explicit hidden root name=%q", entry.Name)
	}
}

func TestBrowserContainedSymlinkRetargetFailsClosed(t *testing.T) {
	parent := t.TempDir()
	root := filepath.Join(parent, "root")
	inside := filepath.Join(root, "inside")
	outside := filepath.Join(parent, "outside")
	if err := os.MkdirAll(filepath.Join(inside, "nested", "safe"), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(outside, "outside-child"), 0o700); err != nil {
		t.Fatal(err)
	}
	link := filepath.Join(root, "linked")
	if err := os.Symlink("inside", link); err != nil {
		t.Skipf("symlinks unavailable: %v", err)
	}
	_, browser, rootEntry := newBrowserWithRoot(t, root, time.Now)
	rootPage, err := browser.Children("cred_phone", rootEntry.Handle, 0, 50)
	if err != nil {
		t.Fatal(err)
	}
	if got := entryNames(rootPage.Entries); !slices.Equal(got, []string{"inside", "linked"}) {
		t.Fatalf("root names=%q", got)
	}
	var linked Entry
	for _, entry := range rootPage.Entries {
		if entry.Name == "linked" {
			linked = entry
		}
	}
	linkedPage, err := browser.Children("cred_phone", linked.Handle, 0, 50)
	if err != nil {
		t.Fatal(err)
	}
	var nested Entry
	for _, entry := range linkedPage.Entries {
		if entry.Name == "nested" {
			nested = entry
		}
	}
	if nested.Handle == "" {
		t.Fatal("nested directory was not returned through contained symlink")
	}
	if err := os.Remove(link); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink("../outside", link); err != nil {
		t.Fatal(err)
	}
	if _, err := browser.Children("cred_phone", linked.Handle, 0, 50); !errors.Is(err, ErrDirectoryUnavailable) {
		t.Fatalf("retargeted child error=%v", err)
	}
	if _, err := browser.Children("cred_phone", nested.Handle, 0, 50); !errors.Is(err, ErrDirectoryUnavailable) {
		t.Fatalf("retargeted ancestor error=%v", err)
	}
}

func TestBrowserConcurrentSymlinkRetargetNeverEscapes(t *testing.T) {
	parent := t.TempDir()
	root := filepath.Join(parent, "root")
	inside := filepath.Join(root, "inside")
	outside := filepath.Join(parent, "outside")
	if err := os.MkdirAll(filepath.Join(inside, "safe-child"), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(outside, "outside-child"), 0o700); err != nil {
		t.Fatal(err)
	}
	link := filepath.Join(root, "linked")
	if err := os.Symlink("inside", link); err != nil {
		t.Skipf("symlinks unavailable: %v", err)
	}
	_, browser, rootEntry := newBrowserWithRoot(t, root, time.Now)
	page, err := browser.Children("cred_phone", rootEntry.Handle, 0, 50)
	if err != nil {
		t.Fatal(err)
	}
	var linkedHandle string
	for _, entry := range page.Entries {
		if entry.Name == "linked" {
			linkedHandle = entry.Handle
		}
	}
	if linkedHandle == "" {
		t.Fatal("contained symlink was not listed")
	}

	stop := make(chan struct{})
	var wait sync.WaitGroup
	wait.Add(1)
	go func() {
		defer wait.Done()
		outsideTarget := "../outside"
		insideTarget := "inside"
		for {
			select {
			case <-stop:
				return
			default:
			}
			_ = os.Remove(link)
			_ = os.Symlink(outsideTarget, link)
			_ = os.Remove(link)
			_ = os.Symlink(insideTarget, link)
		}
	}()
	for index := 0; index < 300; index++ {
		page, err := browser.Children("cred_phone", linkedHandle, 0, 50)
		if err == nil && slices.Contains(entryNames(page.Entries), "outside-child") {
			close(stop)
			wait.Wait()
			t.Fatal("outside child escaped through retargeted symlink")
		}
		if err != nil && !errors.Is(err, ErrDirectoryUnavailable) {
			close(stop)
			wait.Wait()
			t.Fatalf("unexpected retarget error: %v", err)
		}
	}
	close(stop)
	wait.Wait()
}

func TestBrowserConcurrentGrantedRootReplacementNeverEscapes(t *testing.T) {
	parent := t.TempDir()
	root := filepath.Join(parent, "root")
	parked := filepath.Join(parent, "parked")
	outside := filepath.Join(parent, "outside")
	if err := os.MkdirAll(filepath.Join(root, "safe-child"), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(outside, "outside-child"), 0o700); err != nil {
		t.Fatal(err)
	}
	store, err := Open(filepath.Join(t.TempDir(), "grants.json"))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := store.Grant(root); err != nil {
		t.Fatal(err)
	}
	browser := NewBrowser(store, time.Now, deterministicSecret)

	stop := make(chan struct{})
	var wait sync.WaitGroup
	wait.Add(1)
	go func() {
		defer wait.Done()
		for {
			select {
			case <-stop:
				return
			default:
			}
			if os.Rename(root, parked) == nil {
				_ = os.Symlink(outside, root)
				_ = os.Remove(root)
				_ = os.Rename(parked, root)
			}
		}
	}()
	for index := 0; index < 300; index++ {
		roots, err := browser.Roots("cred_phone")
		if err != nil {
			close(stop)
			wait.Wait()
			t.Fatalf("roots error: %v", err)
		}
		for _, entry := range roots {
			page, childErr := browser.Children("cred_phone", entry.Handle, 0, 50)
			if childErr == nil && slices.Contains(entryNames(page.Entries), "outside-child") {
				close(stop)
				wait.Wait()
				t.Fatal("outside child escaped through replaced root")
			}
			if childErr != nil && !errors.Is(childErr, ErrDirectoryUnavailable) {
				close(stop)
				wait.Wait()
				t.Fatalf("unexpected replacement error: %v", childErr)
			}
		}
	}
	close(stop)
	wait.Wait()
}

func TestBrowserRevokedRemovedExpiredAndEvictedHandlesFailClosed(t *testing.T) {
	t.Run("revoked", func(t *testing.T) {
		root := t.TempDir()
		store, browser, entry := newBrowserWithRoot(t, root, time.Now)
		grants, err := store.List()
		if err != nil {
			t.Fatal(err)
		}
		if err := store.Revoke(grants[0].ID); err != nil {
			t.Fatal(err)
		}
		_, err = browser.Children("cred_phone", entry.Handle, 0, 50)
		if !errors.Is(err, ErrGrantRevoked) {
			t.Fatalf("revoked error=%v", err)
		}
		assertOpaqueError(t, err, root)
	})

	t.Run("removed", func(t *testing.T) {
		root := filepath.Join(t.TempDir(), "root")
		if err := os.Mkdir(root, 0o700); err != nil {
			t.Fatal(err)
		}
		_, browser, entry := newBrowserWithRoot(t, root, time.Now)
		if err := os.Remove(root); err != nil {
			t.Fatal(err)
		}
		_, err := browser.Children("cred_phone", entry.Handle, 0, 50)
		if !errors.Is(err, ErrDirectoryUnavailable) {
			t.Fatalf("removed error=%v", err)
		}
		assertOpaqueError(t, err, root)
	})

	t.Run("malformed", func(t *testing.T) {
		browser := NewBrowser(nil, time.Now, deterministicSecret)
		if _, err := browser.Children("cred_phone", "dirh_bad", 0, 50); !errors.Is(err, ErrHandleUnavailable) {
			t.Fatalf("malformed error=%v", err)
		}
	})

	t.Run("expired", func(t *testing.T) {
		root := t.TempDir()
		now := time.Unix(100, 0)
		_, browser, entry := newBrowserWithRoot(t, root, func() time.Time { return now })
		now = now.Add(handleLifetime)
		_, err := browser.Children("cred_phone", entry.Handle, 0, 50)
		if !errors.Is(err, ErrHandleUnavailable) {
			t.Fatalf("expired error=%v", err)
		}
	})

	t.Run("evicted", func(t *testing.T) {
		now := time.Unix(100, 0)
		browser := NewBrowser(nil, func() time.Time { return now }, deterministicSecret)
		first, err := browser.issue("cred_phone", "dir_AAAAAAAAAAAAAAAAAAAAAA", ".")
		if err != nil {
			t.Fatal(err)
		}
		for index := 0; index < maxLiveHandles; index++ {
			now = now.Add(time.Millisecond)
			if _, err := browser.issue("cred_phone", "dir_AAAAAAAAAAAAAAAAAAAAAA", "."); err != nil {
				t.Fatal(err)
			}
		}
		if _, err := browser.record("cred_phone", first); !errors.Is(err, ErrHandleUnavailable) {
			t.Fatalf("evicted error=%v", err)
		}
	})

	t.Run("one device cannot evict another", func(t *testing.T) {
		now := time.Unix(100, 0)
		browser := NewBrowser(nil, func() time.Time { return now }, deterministicSecret)
		victim, err := browser.issue("cred_victim", "dir_AAAAAAAAAAAAAAAAAAAAAA", ".")
		if err != nil {
			t.Fatal(err)
		}
		for index := 0; index < maxLiveHandles+100; index++ {
			now = now.Add(time.Millisecond)
			if _, err := browser.issue("cred_attacker", "dir_BBBBBBBBBBBBBBBBBBBBBB", "."); err != nil {
				t.Fatal(err)
			}
		}
		if _, err := browser.record("cred_victim", victim); err != nil {
			t.Fatalf("another device evicted victim handle: %v", err)
		}
	})

	t.Run("new device cannot evict from a full global pool", func(t *testing.T) {
		now := time.Unix(100, 0)
		browser := NewBrowser(nil, func() time.Time { return now }, deterministicSecret)
		victim, err := browser.issue("cred_device_0", "dir_AAAAAAAAAAAAAAAAAAAAAA", ".")
		if err != nil {
			t.Fatal(err)
		}
		for device := 0; device < maxLiveHandles/maxDeviceHandles; device++ {
			start := 0
			if device == 0 {
				start = 1
			}
			for index := start; index < maxDeviceHandles; index++ {
				if _, err := browser.issue(
					"cred_device_"+strconv.Itoa(device),
					"dir_BBBBBBBBBBBBBBBBBBBBBB",
					".",
				); err != nil {
					t.Fatal(err)
				}
			}
		}
		if _, err := browser.issue("cred_new", "dir_CCCCCCCCCCCCCCCCCCCCCC", "."); !errors.Is(err, ErrHandleUnavailable) {
			t.Fatalf("new device global-pool error=%v", err)
		}
		if _, err := browser.record("cred_device_0", victim); err != nil {
			t.Fatalf("full pool evicted another device: %v", err)
		}
	})
}

func TestBrowserPaginationUnicodeAndBounds(t *testing.T) {
	t.Run("pagination and Unicode", func(t *testing.T) {
		root := t.TempDir()
		for _, name := range []string{"zeta", "alpha", "éclair"} {
			if err := os.Mkdir(filepath.Join(root, name), 0o700); err != nil {
				t.Fatal(err)
			}
		}
		_, browser, rootEntry := newBrowserWithRoot(t, root, time.Now)
		first, err := browser.Children("cred_phone", rootEntry.Handle, 0, 2)
		if err != nil {
			t.Fatal(err)
		}
		if got := entryNames(first.Entries); !slices.Equal(got, []string{"alpha", "zeta"}) || first.NextOffset == nil || *first.NextOffset != 2 {
			t.Fatalf("first=%#v names=%q", first, got)
		}
		last, err := browser.Children("cred_phone", rootEntry.Handle, *first.NextOffset, 2)
		if err != nil || !slices.Equal(entryNames(last.Entries), []string{"éclair"}) || last.NextOffset != nil {
			t.Fatalf("last=%#v err=%v", last, err)
		}
		empty, err := browser.Children("cred_phone", rootEntry.Handle, 3, 2)
		if err != nil || len(empty.Entries) != 0 || empty.NextOffset != nil {
			t.Fatalf("empty=%#v err=%v", empty, err)
		}
	})

	t.Run("scan bound counts regular files", func(t *testing.T) {
		root := t.TempDir()
		for index := 0; index <= maxScannedEntries; index++ {
			name := filepath.Join(root, "file-"+leftPad(index, 5))
			if err := os.WriteFile(name, nil, 0o600); err != nil {
				t.Fatal(err)
			}
		}
		_, browser, rootEntry := newBrowserWithRoot(t, root, time.Now)
		page, err := browser.Children("cred_phone", rootEntry.Handle, 0, 50)
		if !errors.Is(err, ErrDirectoryTooLarge) || len(page.Entries) != 0 {
			t.Fatalf("page=%#v err=%v", page, err)
		}
		assertOpaqueError(t, err, root, "file-00000")
	})

	t.Run("directory bound", func(t *testing.T) {
		root := t.TempDir()
		for index := 0; index <= maxChildDirectories; index++ {
			if err := os.Mkdir(filepath.Join(root, "dir-"+leftPad(index, 4)), 0o700); err != nil {
				t.Fatal(err)
			}
		}
		_, browser, rootEntry := newBrowserWithRoot(t, root, time.Now)
		page, err := browser.Children("cred_phone", rootEntry.Handle, 0, 50)
		if !errors.Is(err, ErrDirectoryTooLarge) || len(page.Entries) != 0 {
			t.Fatalf("page=%#v err=%v", page, err)
		}
	})
}

func TestOpenRootNoSymlinksRejectsComponentsAndSwaps(t *testing.T) {
	parent := t.TempDir()
	original := filepath.Join(parent, "original")
	outside := filepath.Join(parent, "outside")
	component := filepath.Join(parent, "component")
	if err := os.Mkdir(original, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.Mkdir(outside, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(original, component); err != nil {
		t.Skipf("symlinks unavailable: %v", err)
	}
	if root, err := openRootNoSymlinks(component); err == nil {
		_ = root.Close()
		t.Fatal("symlink component was accepted")
	}

	if err := os.Remove(component); err != nil {
		t.Fatal(err)
	}
	if err := os.Rename(original, component); err != nil {
		t.Fatal(err)
	}
	// Windows path-based Stat defers file identity lookup until SameFile.
	// Capture it through a handle before the path starts changing.
	expectedRoot, err := os.OpenRoot(component)
	if err != nil {
		t.Fatal(err)
	}
	expectedInfo, err := expectedRoot.Stat(".")
	_ = expectedRoot.Close()
	if err != nil {
		t.Fatal(err)
	}
	var wait sync.WaitGroup
	stop := make(chan struct{})
	wait.Add(1)
	go func() {
		defer wait.Done()
		for {
			select {
			case <-stop:
				return
			default:
			}
			moved := component + "-moved"
			if os.Rename(component, moved) == nil {
				_ = os.Symlink(outside, component)
				_ = os.Remove(component)
				_ = os.Rename(moved, component)
			}
		}
	}()
	for index := 0; index < 250; index++ {
		root, err := openRootNoSymlinks(component)
		if err == nil {
			info, statErr := root.Stat(".")
			_ = root.Close()
			if statErr != nil || !os.SameFile(info, expectedInfo) {
				close(stop)
				wait.Wait()
				t.Fatal("opened a substituted directory identity")
			}
		}
	}
	close(stop)
	wait.Wait()
}

func leftPad(value, width int) string {
	text := strings.Repeat("0", width) + strconv.Itoa(value)
	return text[len(text)-width:]
}
