package state

import (
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"errors"
	"math/big"
	"net"
	"time"
)

const maxCertificateIPAddresses = 16

// TLSCertificate creates a bounded self-signed server certificate whose SPKI is
// the persistent pinned host identity. The private key never leaves the process.
func (identity HostIdentity) TLSCertificate(now time.Time, hosts []net.IP) (tls.Certificate, error) {
	if len(identity.PublicKey) == 0 || len(identity.PrivateKey) == 0 || identity.TLSPrivateKey == nil {
		return tls.Certificate{}, errors.New("host identity is unavailable")
	}
	serialLimit := new(big.Int).Lsh(big.NewInt(1), 128)
	serial, err := rand.Int(rand.Reader, serialLimit)
	if err != nil {
		return tls.Certificate{}, err
	}
	if serial.Sign() == 0 {
		serial = big.NewInt(1)
	}
	ipAddresses := boundedUniqueIPs(hosts)
	template := &x509.Certificate{
		SerialNumber: serial,
		Subject: pkix.Name{
			CommonName:   "Hermes Wing Link",
			Organization: []string{"Hermes Wing Link"},
		},
		NotBefore:             now.UTC().Add(-5 * time.Minute),
		NotAfter:              now.UTC().Add(365 * 24 * time.Hour),
		KeyUsage:              x509.KeyUsageDigitalSignature,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
		BasicConstraintsValid: true,
		IsCA:                  false,
		DNSNames:              []string{"localhost"},
		IPAddresses:           ipAddresses,
	}
	der, err := x509.CreateCertificate(rand.Reader, template, template, &identity.TLSPrivateKey.PublicKey, identity.TLSPrivateKey)
	if err != nil {
		return tls.Certificate{}, err
	}
	leaf, err := x509.ParseCertificate(der)
	if err != nil {
		return tls.Certificate{}, err
	}
	return tls.Certificate{
		Certificate: [][]byte{der},
		PrivateKey:  identity.TLSPrivateKey,
		Leaf:        leaf,
	}, nil
}

func boundedUniqueIPs(hosts []net.IP) []net.IP {
	result := make([]net.IP, 0, min(len(hosts), maxCertificateIPAddresses))
	seen := make(map[string]struct{}, len(hosts))
	for _, host := range hosts {
		if host == nil {
			continue
		}
		normalized := host.To16()
		if normalized == nil {
			continue
		}
		key := normalized.String()
		if _, duplicate := seen[key]; duplicate {
			continue
		}
		seen[key] = struct{}{}
		result = append(result, append(net.IP(nil), normalized...))
		if len(result) == maxCertificateIPAddresses {
			break
		}
	}
	return result
}
