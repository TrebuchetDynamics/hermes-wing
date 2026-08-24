package app

import (
	"crypto/tls"
	"net"
	"net/http"
	"time"

	wingstate "github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/state"
)

func listenerTLSConfig(ip net.IP, identity wingstate.HostIdentity, now func() time.Time) (*tls.Config, bool, error) {
	if ip.IsLoopback() {
		return nil, false, nil
	}
	certificate, err := identity.TLSCertificate(now().UTC(), []net.IP{
		ip,
		net.ParseIP("127.0.0.1"),
		net.ParseIP("::1"),
	})
	if err != nil {
		return nil, false, err
	}
	return &tls.Config{
		MinVersion:   tls.VersionTLS13,
		Certificates: []tls.Certificate{certificate},
	}, true, nil
}

func serveManagementListener(server *http.Server, listener net.Listener, identity wingstate.HostIdentity) error {
	address, ok := listener.Addr().(*net.TCPAddr)
	if !ok {
		return server.Serve(listener)
	}
	config, encrypted, err := listenerTLSConfig(address.IP, identity, time.Now)
	if err != nil {
		return err
	}
	if !encrypted {
		return server.Serve(listener)
	}
	return server.Serve(tls.NewListener(listener, config))
}

func managementListenerScheme(address net.Addr) string {
	if tcp, ok := address.(*net.TCPAddr); ok && !tcp.IP.IsLoopback() {
		return "https"
	}
	return "http"
}
