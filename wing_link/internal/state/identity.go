package state

import (
	"crypto/ed25519"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"errors"
	"fmt"
)

const hostFingerprintPrefix = "sha256/"

// HostIdentity is Wing Link's persistent trust anchor. Callers must not expose
// PrivateKey outside the owner-only host process.
type HostIdentity struct {
	PublicKey     ed25519.PublicKey
	PrivateKey    ed25519.PrivateKey
	TLSPrivateKey *rsa.PrivateKey
	Fingerprint   string
}

// HostIdentity returns the stable host identity, creating it atomically on the
// first call. The private key is stored only in Wing Link's owner-only state.
func (s *StateStore) HostIdentity() (HostIdentity, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	var identity HostIdentity
	err := s.withFileLock(func() error {
		state, err := s.load()
		if err != nil {
			return err
		}
		changed := false
		if state.HostIdentityPrivateKey == "" {
			_, privateKey, err := ed25519.GenerateKey(rand.Reader)
			if err != nil {
				return fmt.Errorf("generate host identity: %w", err)
			}
			state.HostIdentityPrivateKey = base64.RawURLEncoding.EncodeToString(privateKey)
			changed = true
		}
		if state.HostTLSPrivateKey == "" {
			privateKey, err := rsa.GenerateKey(rand.Reader, 2048)
			if err != nil {
				return fmt.Errorf("generate host TLS identity: %w", err)
			}
			encoded, err := x509.MarshalPKCS8PrivateKey(privateKey)
			if err != nil {
				return fmt.Errorf("encode host TLS identity: %w", err)
			}
			state.HostTLSPrivateKey = base64.RawURLEncoding.EncodeToString(encoded)
			changed = true
		}
		if changed {
			if err := s.save(state); err != nil {
				return err
			}
		}
		identity, err = decodeHostIdentity(state.HostIdentityPrivateKey, state.HostTLSPrivateKey)
		return err
	})
	if err != nil {
		return HostIdentity{}, err
	}
	return identity, nil
}

func decodeHostIdentity(encoded, encodedTLS string) (HostIdentity, error) {
	privateKey, err := base64.RawURLEncoding.DecodeString(encoded)
	if err != nil || len(privateKey) != ed25519.PrivateKeySize {
		return HostIdentity{}, errors.New("invalid host identity private key")
	}
	privateCopy := append(ed25519.PrivateKey(nil), privateKey...)
	publicKey, ok := privateCopy.Public().(ed25519.PublicKey)
	if !ok || len(publicKey) != ed25519.PublicKeySize {
		return HostIdentity{}, errors.New("invalid host identity public key")
	}
	publicCopy := append(ed25519.PublicKey(nil), publicKey...)
	tlsDER, err := base64.RawURLEncoding.DecodeString(encodedTLS)
	if err != nil {
		return HostIdentity{}, errors.New("invalid host TLS private key")
	}
	parsedTLS, err := x509.ParsePKCS8PrivateKey(tlsDER)
	if err != nil {
		return HostIdentity{}, errors.New("invalid host TLS private key")
	}
	tlsPrivateKey, ok := parsedTLS.(*rsa.PrivateKey)
	if !ok || tlsPrivateKey.N.BitLen() < 2048 || tlsPrivateKey.Validate() != nil {
		return HostIdentity{}, errors.New("invalid host TLS private key")
	}
	spki, err := x509.MarshalPKIXPublicKey(&tlsPrivateKey.PublicKey)
	if err != nil {
		return HostIdentity{}, errors.New("invalid host TLS public key")
	}
	digest := sha256.Sum256(spki)
	return HostIdentity{
		PublicKey: publicCopy, PrivateKey: privateCopy, TLSPrivateKey: tlsPrivateKey,
		Fingerprint: hostFingerprintPrefix + base64.RawURLEncoding.EncodeToString(digest[:]),
	}, nil
}
