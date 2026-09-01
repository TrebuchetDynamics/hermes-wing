package release

import (
	"crypto/ed25519"
	"crypto/rand"
	"encoding/json"
	"errors"
	"strings"
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

func TestVerifyComponentManifestValidatesOptionalWingLinkArtifact(t *testing.T) {
	publicKey, privateKey, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	now := time.Now().UTC()
	validArtifact := Artifact{
		URL:    "https://releases.example.test/wing-link/wing-link-1.2.4-linux",
		Size:   4096,
		SHA256: strings.Repeat("ab", 32),
	}

	cases := []struct {
		name     string
		artifact Artifact
		version  string
		minimum  int
	}{
		{name: "valid", artifact: validArtifact, version: "1.2.4", minimum: 1},
		{name: "non-numeric version", artifact: validArtifact, version: "1.2.4-rc1", minimum: 1},
		{name: "zero protocol generation", artifact: validArtifact, version: "1.2.4", minimum: 0},
		{name: "negative protocol generation", artifact: validArtifact, version: "1.2.4", minimum: -1},
		{name: "zero size", artifact: Artifact{URL: validArtifact.URL, Size: 0, SHA256: validArtifact.SHA256}, version: "1.2.4", minimum: 1},
		{name: "oversized artifact", artifact: Artifact{URL: validArtifact.URL, Size: maxStagedArtifact + 1, SHA256: validArtifact.SHA256}, version: "1.2.4", minimum: 1},
		{name: "short digest", artifact: Artifact{URL: validArtifact.URL, Size: 4096, SHA256: "abcd"}, version: "1.2.4", minimum: 1},
		{name: "non-hex digest", artifact: Artifact{URL: validArtifact.URL, Size: 4096, SHA256: strings.Repeat("zz", 32)}, version: "1.2.4", minimum: 1},
		{name: "plaintext URL", artifact: Artifact{URL: "http://releases.example.test/a", Size: 4096, SHA256: validArtifact.SHA256}, version: "1.2.4", minimum: 1},
		{name: "credentialed URL", artifact: Artifact{URL: "https://user:secret@releases.example.test/a", Size: 4096, SHA256: validArtifact.SHA256}, version: "1.2.4", minimum: 1},
		{name: "URL with query", artifact: Artifact{URL: "https://releases.example.test/a?token=1", Size: 4096, SHA256: validArtifact.SHA256}, version: "1.2.4", minimum: 1},
		{name: "URL without path", artifact: Artifact{URL: "https://releases.example.test", Size: 4096, SHA256: validArtifact.SHA256}, version: "1.2.4", minimum: 1},
		{name: "empty URL", artifact: Artifact{URL: "", Size: 4096, SHA256: validArtifact.SHA256}, version: "1.2.4", minimum: 1},
	}

	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			catalog := ComponentCatalog{
				Schema:          1,
				SigningKeyID:    "test-key",
				ReleaseIdentity: "test.release",
				IssuedAt:        now.Add(-time.Minute),
				ExpiresAt:       now.Add(time.Hour),
			}
			catalog.WingLink = &WingLinkComponent{
				Version:                   testCase.version,
				Linux:                     testCase.artifact,
				MinimumProtocolGeneration: testCase.minimum,
			}
			manifest, err := json.Marshal(catalog)
			if err != nil {
				t.Fatal(err)
			}
			signature := ed25519.Sign(privateKey, manifest)
			verified, err := verifyComponentManifestAt(manifest, signature, map[string]ed25519.PublicKey{"test-key": publicKey}, now)
			if testCase.name == "valid" {
				if err != nil {
					t.Fatalf("valid wing_link catalog rejected: %v", err)
				}
				if verified.WingLink == nil || verified.WingLink.Version != "1.2.4" || verified.WingLink.MinimumProtocolGeneration != 1 {
					t.Fatalf("verified wing_link component = %#v", verified.WingLink)
				}
				return
			}
			if !errors.Is(err, ErrComponentManifest) {
				t.Fatalf("error = %v, want ErrComponentManifest", err)
			}
		})
	}

	t.Run("absent wing_link stays optional", func(t *testing.T) {
		catalog := ComponentCatalog{
			Schema:          1,
			SigningKeyID:    "test-key",
			ReleaseIdentity: "test.release",
			IssuedAt:        now.Add(-time.Minute),
			ExpiresAt:       now.Add(time.Hour),
		}
		manifest, err := json.Marshal(catalog)
		if err != nil {
			t.Fatal(err)
		}
		signature := ed25519.Sign(privateKey, manifest)
		if _, err := verifyComponentManifestAt(manifest, signature, map[string]ed25519.PublicKey{"test-key": publicKey}, now); err != nil {
			t.Fatalf("catalog without wing_link rejected: %v", err)
		}
	})
}
