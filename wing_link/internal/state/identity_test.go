package state

import (
	"bytes"
	"crypto/ed25519"
	"encoding/json"
	"os"
	"sync"
	"testing"
	"time"
)

func TestHostIdentityPersistsAcrossStores(t *testing.T) {
	store := newTestStateStore(t, time.Now)

	first, err := store.HostIdentity()
	if err != nil {
		t.Fatal(err)
	}
	second, err := (&StateStore{path: store.path, now: time.Now}).HostIdentity()
	if err != nil {
		t.Fatal(err)
	}

	if len(first.PublicKey) != ed25519.PublicKeySize || len(first.PrivateKey) != ed25519.PrivateKeySize {
		t.Fatalf("invalid identity key sizes: public=%d private=%d", len(first.PublicKey), len(first.PrivateKey))
	}
	if first.Fingerprint == "" || first.Fingerprint != second.Fingerprint {
		t.Fatalf("fingerprints = %q, %q", first.Fingerprint, second.Fingerprint)
	}
	if !bytes.Equal(first.PublicKey, second.PublicKey) || !bytes.Equal(first.PrivateKey, second.PrivateKey) ||
		first.TLSPrivateKey == nil || second.TLSPrivateKey == nil || first.TLSPrivateKey.N.Cmp(second.TLSPrivateKey.N) != 0 {
		t.Fatal("host identity changed across stores")
	}
	ownerOnly, err := statePathOwnerOnly(store.path, false)
	if err != nil || !ownerOnly {
		t.Fatalf("identity state is not owner-only: ownerOnly=%v err=%v", ownerOnly, err)
	}
}

func TestHostIdentityConcurrentInitializationCreatesOneKey(t *testing.T) {
	store := newTestStateStore(t, time.Now)
	stores := []*StateStore{
		{path: store.path, now: time.Now},
		{path: store.path, now: time.Now},
		{path: store.path, now: time.Now},
		{path: store.path, now: time.Now},
	}
	start := make(chan struct{})
	identities := make(chan HostIdentity, len(stores))
	errors := make(chan error, len(stores))
	var wait sync.WaitGroup
	for _, candidate := range stores {
		wait.Add(1)
		go func(candidate *StateStore) {
			defer wait.Done()
			<-start
			identity, err := candidate.HostIdentity()
			if err != nil {
				errors <- err
				return
			}
			identities <- identity
		}(candidate)
	}
	close(start)
	wait.Wait()
	close(errors)
	close(identities)
	for err := range errors {
		t.Fatal(err)
	}
	var fingerprint string
	for identity := range identities {
		if fingerprint == "" {
			fingerprint = identity.Fingerprint
		}
		if identity.Fingerprint != fingerprint {
			t.Fatalf("concurrent identity changed: %q != %q", identity.Fingerprint, fingerprint)
		}
	}
}

func TestHostIdentityMigratesSchemaOneWithoutInvalidatingToken(t *testing.T) {
	store := newTestStateStore(t, time.Now)
	token := "wlc_existing"
	legacy := map[string]any{
		"schema":               1,
		"control_token_hashes": []string{hashSecret(token)},
	}
	payload, err := json.Marshal(legacy)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(store.path, payload, 0o600); err != nil {
		t.Fatal(err)
	}

	identity, err := store.HostIdentity()
	if err != nil {
		t.Fatal(err)
	}
	if identity.Fingerprint == "" || !store.Authorize(token) {
		t.Fatal("schema-one migration lost identity or authorization")
	}
	var persisted struct {
		Schema int `json:"schema"`
	}
	migrated, err := os.ReadFile(store.path)
	if err != nil {
		t.Fatal(err)
	}
	if err := json.Unmarshal(migrated, &persisted); err != nil {
		t.Fatal(err)
	}
	if persisted.Schema != 2 {
		t.Fatalf("schema = %d, want 2", persisted.Schema)
	}
	if bytes.Contains(migrated, []byte(token)) {
		t.Fatal("migration persisted a raw token")
	}
}

func TestHostIdentityRejectsMalformedPersistedTLSPrivateKey(t *testing.T) {
	store := newTestStateStore(t, time.Now)
	if _, err := store.HostIdentity(); err != nil {
		t.Fatal(err)
	}
	payload, err := os.ReadFile(store.path)
	if err != nil {
		t.Fatal(err)
	}
	var persisted map[string]any
	if err := json.Unmarshal(payload, &persisted); err != nil {
		t.Fatal(err)
	}
	persisted["host_tls_private_key"] = "not-a-private-key"
	payload, err = json.Marshal(persisted)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(store.path, payload, 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := (&StateStore{path: store.path, now: time.Now}).HostIdentity(); err == nil {
		t.Fatal("malformed host TLS identity was accepted")
	}
}

func TestHostIdentityRejectsMalformedPersistedPrivateKey(t *testing.T) {
	store := newTestStateStore(t, time.Now)
	payload := []byte(`{"schema":2,"host_identity_private_key":"not-base64"}`)
	if err := os.WriteFile(store.path, payload, 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := store.HostIdentity(); err == nil {
		t.Fatal("malformed host identity was accepted")
	}
}
