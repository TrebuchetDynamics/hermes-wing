package main

import (
	"bytes"
	"crypto/ed25519"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"time"
)

var (
	ErrManifestSignature = errors.New("component manifest signature invalid")
	ErrComponentManifest = errors.New("component manifest invalid")
)

type Artifact struct {
	URL       string `json:"url"`
	Size      int64  `json:"size"`
	SHA256    string `json:"sha256,omitempty"`
	Integrity string `json:"integrity,omitempty"`
}

type HermesComponent struct {
	Version string   `json:"version"`
	Commit  string   `json:"commit"`
	POSIX   Artifact `json:"posix"`
	Windows Artifact `json:"windows"`
}

type StarterProfileComponent struct {
	Name          string `json:"name"`
	Source        string `json:"source"`
	Commit        string `json:"commit"`
	ArchiveURL    string `json:"archive_url"`
	Size          int64  `json:"size"`
	SHA256        string `json:"sha256"`
	Installable   bool   `json:"installable"`
	BlockedReason string `json:"blocked_reason,omitempty"`
}

type OmniRouteComponent struct {
	Version   string `json:"version"`
	URL       string `json:"url"`
	Size      int64  `json:"size"`
	Integrity string `json:"integrity"`
}

type ComponentCatalog struct {
	Schema          int                      `json:"schema"`
	SigningKeyID    string                   `json:"signing_key_id"`
	ReleaseIdentity string                   `json:"release_identity"`
	IssuedAt        time.Time                `json:"issued_at"`
	ExpiresAt       time.Time                `json:"expires_at"`
	Hermes          *HermesComponent         `json:"hermes,omitempty"`
	StarterProfile  *StarterProfileComponent `json:"starter_profile,omitempty"`
	OmniRoute       *OmniRouteComponent      `json:"omniroute,omitempty"`
}

func VerifyComponentManifest(manifest, signature []byte, trustedKeys map[string]ed25519.PublicKey) (ComponentCatalog, error) {
	return verifyComponentManifestAt(manifest, signature, trustedKeys, time.Now().UTC())
}

func verifyComponentManifestAt(manifest, signature []byte, trustedKeys map[string]ed25519.PublicKey, now time.Time) (ComponentCatalog, error) {
	var envelope struct {
		SigningKeyID string `json:"signing_key_id"`
	}
	if err := json.Unmarshal(manifest, &envelope); err != nil || envelope.SigningKeyID == "" {
		return ComponentCatalog{}, ErrManifestSignature
	}
	publicKey, ok := trustedKeys[envelope.SigningKeyID]
	if !ok || len(publicKey) != ed25519.PublicKeySize || len(signature) != ed25519.SignatureSize || !ed25519.Verify(publicKey, manifest, signature) {
		return ComponentCatalog{}, ErrManifestSignature
	}

	var catalog ComponentCatalog
	decoder := json.NewDecoder(bytes.NewReader(manifest))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&catalog); err != nil {
		return ComponentCatalog{}, fmt.Errorf("%w: %v", ErrComponentManifest, err)
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return ComponentCatalog{}, fmt.Errorf("%w: trailing data", ErrComponentManifest)
	}
	if err := catalog.validate(now); err != nil {
		return ComponentCatalog{}, err
	}
	return catalog, nil
}

func (catalog ComponentCatalog) validate(now time.Time) error {
	if catalog.Schema != 1 || catalog.SigningKeyID == "" || catalog.ReleaseIdentity == "" {
		return fmt.Errorf("%w: missing release identity", ErrComponentManifest)
	}
	if catalog.IssuedAt.IsZero() || catalog.ExpiresAt.IsZero() || !catalog.ExpiresAt.After(catalog.IssuedAt) {
		return fmt.Errorf("%w: invalid validity window", ErrComponentManifest)
	}
	if catalog.IssuedAt.After(now.Add(5*time.Minute)) || !catalog.ExpiresAt.After(now) || catalog.ExpiresAt.Sub(catalog.IssuedAt) > 366*24*time.Hour {
		return fmt.Errorf("%w: release is not currently valid", ErrComponentManifest)
	}
	return nil
}
