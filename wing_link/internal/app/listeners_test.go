package app

import (
	"crypto/tls"
	"crypto/x509"
	"net"
	"path/filepath"
	"testing"
	"time"

	wingstate "github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/state"
)

func TestListenerTLSConfigKeepsLoopbackHTTP(t *testing.T) {
	store := wingstate.New(filepath.Join(t.TempDir(), "state.json"))
	identity, err := store.HostIdentity()
	if err != nil {
		t.Fatal(err)
	}
	config, encrypted, err := listenerTLSConfig(net.ParseIP("127.0.0.1"), identity, time.Now)
	if err != nil {
		t.Fatal(err)
	}
	if encrypted || config != nil {
		t.Fatal("loopback listener unexpectedly required TLS")
	}
}

func TestListenerTLSConfigEncryptsNonLoopbackWithHostIdentity(t *testing.T) {
	store := wingstate.New(filepath.Join(t.TempDir(), "state.json"))
	identity, err := store.HostIdentity()
	if err != nil {
		t.Fatal(err)
	}
	ip := net.ParseIP("192.168.1.20")
	config, encrypted, err := listenerTLSConfig(ip, identity, time.Now)
	if err != nil {
		t.Fatal(err)
	}
	if !encrypted || config == nil || config.MinVersion != tls.VersionTLS13 || len(config.Certificates) != 1 {
		t.Fatalf("unexpected TLS config: encrypted=%v config=%+v", encrypted, config)
	}
	certificate, err := x509.ParseCertificate(config.Certificates[0].Certificate[0])
	if err != nil {
		t.Fatal(err)
	}
	publicKey, err := x509.MarshalPKIXPublicKey(&identity.TLSPrivateKey.PublicKey)
	if err != nil {
		t.Fatal(err)
	}
	if string(certificate.RawSubjectPublicKeyInfo) != string(publicKey) {
		t.Fatal("listener certificate does not match host identity")
	}
	if len(certificate.IPAddresses) == 0 || !certificate.IPAddresses[0].Equal(ip) {
		t.Fatalf("listener certificate omitted selected IP: %v", certificate.IPAddresses)
	}
}
