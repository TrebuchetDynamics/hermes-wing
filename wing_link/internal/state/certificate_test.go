package state

import (
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"net"
	"testing"
	"time"
)

func TestHostIdentityTLSCertificateUsesPinnedPublicKey(t *testing.T) {
	store := newTestStateStore(t, time.Now)
	identity, err := store.HostIdentity()
	if err != nil {
		t.Fatal(err)
	}
	now := time.Unix(2_000, 0).UTC()
	certificate, err := identity.TLSCertificate(now, []net.IP{net.ParseIP("127.0.0.1"), net.ParseIP("192.168.1.20")})
	if err != nil {
		t.Fatal(err)
	}
	if len(certificate.Certificate) != 1 {
		t.Fatalf("certificate chain length = %d", len(certificate.Certificate))
	}
	parsed, err := x509.ParseCertificate(certificate.Certificate[0])
	if err != nil {
		t.Fatal(err)
	}
	digest := sha256.Sum256(parsed.RawSubjectPublicKeyInfo)
	if got := hostFingerprintPrefix + base64.RawURLEncoding.EncodeToString(digest[:]); got != identity.Fingerprint {
		t.Fatal("TLS certificate does not use the pinned host TLS identity")
	}
	if !parsed.NotBefore.Before(now) || !parsed.NotAfter.After(now.Add(300*24*time.Hour)) {
		t.Fatalf("unexpected validity: %v - %v", parsed.NotBefore, parsed.NotAfter)
	}
	if parsed.IsCA {
		t.Fatal("host certificate must not be a CA")
	}
	if len(parsed.IPAddresses) != 2 || parsed.DNSNames[0] != "localhost" {
		t.Fatalf("unexpected SANs: IP=%v DNS=%v", parsed.IPAddresses, parsed.DNSNames)
	}
}

func TestHostIdentityTLSCertificateBoundsAndDeduplicatesHosts(t *testing.T) {
	store := newTestStateStore(t, time.Now)
	identity, err := store.HostIdentity()
	if err != nil {
		t.Fatal(err)
	}
	hosts := []net.IP{net.ParseIP("127.0.0.1"), net.ParseIP("127.0.0.1")}
	for index := 1; index <= 40; index++ {
		hosts = append(hosts, net.IPv4(10, 0, 0, byte(index)))
	}
	certificate, err := identity.TLSCertificate(time.Now().UTC(), hosts)
	if err != nil {
		t.Fatal(err)
	}
	parsed, err := x509.ParseCertificate(certificate.Certificate[0])
	if err != nil {
		t.Fatal(err)
	}
	if len(parsed.IPAddresses) > maxCertificateIPAddresses {
		t.Fatalf("certificate has %d IP SANs", len(parsed.IPAddresses))
	}
	seen := map[string]bool{}
	for _, ip := range parsed.IPAddresses {
		if seen[ip.String()] {
			t.Fatalf("duplicate IP SAN %s", ip)
		}
		seen[ip.String()] = true
	}
}
