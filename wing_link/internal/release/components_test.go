package release

import (
	"crypto/ed25519"
	"crypto/rand"
	"encoding/json"
	"errors"
	"testing"
	"time"
)

func TestVerifyComponentManifestAcceptsSignedBytesAndRejectsMutation(t *testing.T) {
	publicKey, privateKey, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	now := time.Now().UTC().Truncate(time.Second)
	manifest, err := json.Marshal(ComponentCatalog{
		Schema:          1,
		SigningKeyID:    "test-key",
		ReleaseIdentity: "test.release",
		IssuedAt:        now.Add(-time.Minute),
		ExpiresAt:       now.Add(time.Hour),
	})
	if err != nil {
		t.Fatal(err)
	}
	signature := ed25519.Sign(privateKey, manifest)
	catalog, err := verifyComponentManifestAt(manifest, signature, map[string]ed25519.PublicKey{"test-key": publicKey}, now)
	if err != nil {
		t.Fatal(err)
	}
	if catalog.ReleaseIdentity != "test.release" {
		t.Fatalf("catalog = %#v", catalog)
	}

	mutated := append([]byte(nil), manifest...)
	mutated[len(mutated)-1] ^= 1
	if _, err := verifyComponentManifestAt(mutated, signature, map[string]ed25519.PublicKey{"test-key": publicKey}, now); !errors.Is(err, ErrManifestSignature) {
		t.Fatalf("mutation error = %v", err)
	}
}

func TestVerifyComponentManifestRejectsUnknownKeyAndInvalidLifetime(t *testing.T) {
	publicKey, privateKey, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	now := time.Now().UTC().Truncate(time.Second)
	manifest, err := json.Marshal(ComponentCatalog{
		Schema:          1,
		SigningKeyID:    "unknown",
		ReleaseIdentity: "test.release",
		IssuedAt:        now.Add(-time.Minute),
		ExpiresAt:       now.Add(time.Hour),
	})
	if err != nil {
		t.Fatal(err)
	}
	signature := ed25519.Sign(privateKey, manifest)
	if _, err := verifyComponentManifestAt(manifest, signature, map[string]ed25519.PublicKey{"test-key": publicKey}, now); !errors.Is(err, ErrManifestSignature) {
		t.Fatalf("unknown-key error = %v", err)
	}

	expired := ComponentCatalog{
		Schema:          1,
		SigningKeyID:    "test-key",
		ReleaseIdentity: "test.release",
		IssuedAt:        now.Add(-2 * time.Hour),
		ExpiresAt:       now.Add(-time.Hour),
	}
	manifest, err = json.Marshal(expired)
	if err != nil {
		t.Fatal(err)
	}
	signature = ed25519.Sign(privateKey, manifest)
	if _, err := verifyComponentManifestAt(manifest, signature, map[string]ed25519.PublicKey{"test-key": publicKey}, now); err == nil {
		t.Fatal("expired manifest accepted")
	}
}
