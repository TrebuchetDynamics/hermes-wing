package main

import (
	"bytes"
	"errors"
	"os"
	"path/filepath"
	"runtime"
	"sync"
	"testing"
	"time"
)

func newTestStateStore(t *testing.T, now func() time.Time) *StateStore {
	t.Helper()
	return &StateStore{path: filepath.Join(t.TempDir(), "state.json"), now: now}
}

func TestEnrollmentExchangesOnceAndStoresHashes(t *testing.T) {
	now := time.Unix(1000, 0)
	store := newTestStateStore(t, func() time.Time { return now })
	enrollment, err := store.CreateEnrollment()
	if err != nil {
		t.Fatal(err)
	}
	token, err := store.ExchangeEnrollment(enrollment.Code)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = store.ExchangeEnrollment(enrollment.Code); !errors.Is(err, ErrEnrollmentUnavailable) {
		t.Fatalf("got %v", err)
	}
	persisted, err := os.ReadFile(store.path)
	if err != nil {
		t.Fatal(err)
	}
	if bytes.Contains(persisted, []byte(enrollment.Code)) || bytes.Contains(persisted, []byte(token)) {
		t.Fatal("raw secret persisted")
	}
	if !store.Authorize(token) {
		t.Fatal("token rejected")
	}
}

func TestPendingControlCredentialStaysInMemoryUntilAcknowledged(t *testing.T) {
	now := time.Unix(1000, 0)
	store := newTestStateStore(t, func() time.Time { return now })
	id, token, err := store.StageControlToken()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(store.path); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("pending state was persisted: %v", err)
	}
	if !store.AuthorizePending(id, token) || (&StateStore{path: store.path}).AuthorizePending(id, token) {
		t.Fatal("pending credential escaped its staging process")
	}
	if err := store.AcknowledgeControlToken(id, token); err != nil {
		t.Fatal(err)
	}
	if !store.Authorize(token) {
		t.Fatal("acknowledged credential was not persisted")
	}
}

func TestExpiredPendingControlCredentialIsErasedOnAccess(t *testing.T) {
	now := time.Unix(1000, 0)
	store := newTestStateStore(t, func() time.Time { return now })
	id, token, err := store.StageControlToken()
	if err != nil {
		t.Fatal(err)
	}
	now = now.Add(5 * time.Minute)
	if store.AuthorizePending(id, token) || len(store.pending) != 0 {
		t.Fatal("expired pending credential remained available")
	}
}

func TestEnrollmentExpiresAfterFiveMinutes(t *testing.T) {
	now := time.Unix(1000, 0)
	store := newTestStateStore(t, func() time.Time { return now })
	enrollment, err := store.CreateEnrollment()
	if err != nil {
		t.Fatal(err)
	}
	now = now.Add(5 * time.Minute)
	if _, err := store.ExchangeEnrollment(enrollment.Code); !errors.Is(err, ErrEnrollmentUnavailable) {
		t.Fatalf("got %v", err)
	}
}

func TestStateFileIsOwnerOnly(t *testing.T) {
	store := newTestStateStore(t, time.Now)
	if _, err := store.CreateEnrollment(); err != nil {
		t.Fatal(err)
	}
	ownerOnly, err := statePathOwnerOnly(store.path, false)
	if err != nil {
		t.Fatal(err)
	}
	if !ownerOnly {
		t.Fatal("state file is not owner-only")
	}
}

func TestStateStoreFailsClosedForMalformedState(t *testing.T) {
	store := newTestStateStore(t, time.Now)
	if err := os.WriteFile(store.path, []byte("not-json"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := store.CreateEnrollment(); err == nil {
		t.Fatal("CreateEnrollment accepted malformed state")
	}
	if _, err := store.ExchangeEnrollment("code"); err == nil {
		t.Fatal("ExchangeEnrollment accepted malformed state")
	}
	if store.Authorize("wlc_token") {
		t.Fatal("Authorize accepted malformed state")
	}
	if err := store.RevokeAll(); err == nil {
		t.Fatal("RevokeAll accepted malformed state")
	}
}

func TestStateStoreRejectsChangedToken(t *testing.T) {
	store := newTestStateStore(t, time.Now)
	enrollment, err := store.CreateEnrollment()
	if err != nil {
		t.Fatal(err)
	}
	token, err := store.ExchangeEnrollment(enrollment.Code)
	if err != nil {
		t.Fatal(err)
	}
	if store.Authorize(token + "x") {
		t.Fatal("changed token accepted")
	}
}

func TestEnrollmentExchangeIsSingleUseAcrossStores(t *testing.T) {
	now := time.Unix(1000, 0)
	store := newTestStateStore(t, func() time.Time { return now })
	enrollment, err := store.CreateEnrollment()
	if err != nil {
		t.Fatal(err)
	}
	stores := []*StateStore{
		{path: store.path, now: store.now},
		{path: store.path, now: store.now},
	}
	start := make(chan struct{})
	var wg sync.WaitGroup
	var successes int
	var mu sync.Mutex
	for _, candidate := range stores {
		wg.Add(1)
		go func(candidate *StateStore) {
			defer wg.Done()
			<-start
			if _, err := candidate.ExchangeEnrollment(enrollment.Code); err == nil {
				mu.Lock()
				successes++
				mu.Unlock()
			}
		}(candidate)
	}
	close(start)
	wg.Wait()
	if successes != 1 {
		t.Fatalf("successful exchanges = %d", successes)
	}
}

func TestRevokeAllRejectsIssuedToken(t *testing.T) {
	store := newTestStateStore(t, time.Now)
	enrollment, err := store.CreateEnrollment()
	if err != nil {
		t.Fatal(err)
	}
	token, err := store.ExchangeEnrollment(enrollment.Code)
	if err != nil {
		t.Fatal(err)
	}
	if err := store.RevokeAll(); err != nil {
		t.Fatal(err)
	}
	if store.Authorize(token) {
		t.Fatal("revoked token accepted")
	}
}

func TestStateStoreRejectsSymlink(t *testing.T) {
	if runtime.GOOS == "windows" {
		t.Skip("symlink creation may require elevated privileges")
	}
	dir := t.TempDir()
	target := filepath.Join(dir, "target")
	if err := os.WriteFile(target, []byte(`{"schema":1}`), 0o600); err != nil {
		t.Fatal(err)
	}
	store := &StateStore{path: filepath.Join(dir, "state.json"), now: time.Now}
	if err := os.Symlink(target, store.path); err != nil {
		t.Fatal(err)
	}
	if _, err := store.CreateEnrollment(); err == nil {
		t.Fatal("symlink accepted")
	}
}
