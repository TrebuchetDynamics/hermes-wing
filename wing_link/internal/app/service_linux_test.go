//go:build linux

package app

import (
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestExternalServiceHealthUsesLoopbackHTTPForRemoteTLSOrigin(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if request.URL.Path != "/healthz" {
			t.Fatalf("path=%q", request.URL.Path)
		}
		writer.WriteHeader(http.StatusOK)
	}))
	defer server.Close()
	loopback, err := url.Parse(server.URL)
	if err != nil {
		t.Fatal(err)
	}
	remote := &url.URL{Scheme: "https", Host: "192.168.1.20:" + loopback.Port()}
	t.Setenv("WING_LINK_SERVICE", "external")
	if err := EnsureWingLinkService(remote, &url.URL{Scheme: "http", Host: "192.168.1.20:8642"}); err != nil {
		t.Fatal(err)
	}
}

func TestWingLinkSystemdUnitPersistsExactServiceBoundaries(t *testing.T) {
	unit := wingLinkSystemdUnit(
		"/home/user/.local/lib/hermes-wing/releases/current",
		"100.100.100.100:8654",
		"http://100.100.100.100:8642",
		"/home/user/.local/bin:/usr/bin",
		"/home/user/.config/hermes-wing/state.json",
		"/srv/hermes",
	)
	for _, expected := range []string{
		"WantedBy=default.target",
		"Restart=on-failure",
		`ExecStart="/home/user/.local/lib/hermes-wing/releases/current" serve`,
		`serve --listen "100.100.100.100:8654"`,
		`WING_HERMES_URL="http://100.100.100.100:8642"`,
		`WING_LINK_STATE="/home/user/.config/hermes-wing/state.json"`,
		`WING_HERMES_HOME="/srv/hermes"`,
		"ProtectSystem=strict",
		"ProtectHome=read-only",
		"RestrictSUIDSGID=true",
		`ReadWritePaths="/home/user/.config/hermes-wing"`,
		`ReadWritePaths="/srv/hermes"`,
	} {
		if !strings.Contains(unit, expected) {
			t.Fatalf("unit missing %q:\n%s", expected, unit)
		}
	}
	if strings.Contains(unit, "API_SERVER_KEY") || strings.Contains(unit, "WING_HERMES_TOKEN") {
		t.Fatal("service unit persisted a Hermes credential")
	}

	defaultHome := wingLinkSystemdUnit(
		"/bin/wing-link", "127.0.0.1:8654", "http://127.0.0.1:8642",
		"/usr/bin", "/tmp/state", "/home/user/.hermes",
	)
	if !strings.Contains(defaultHome, `Environment=WING_HERMES_HOME="/home/user/.hermes"`) ||
		!strings.Contains(defaultHome, `ReadWritePaths="/home/user/.hermes"`) {
		t.Fatalf("resolved Hermes home is not writable:\n%s", defaultHome)
	}
}

func TestInstallCurrentServiceTargetUsesVersionedRelativeSymlink(t *testing.T) {
	root := t.TempDir()
	if err := installCurrentServiceTarget(root, "1.2.3"); err != nil {
		t.Fatal(err)
	}
	target, err := os.Readlink(filepath.Join(root, "current"))
	if err != nil {
		t.Fatal(err)
	}
	if target != filepath.Join("versions", "1.2.3", "wing-link") {
		t.Fatalf("current -> %q", target)
	}
}

func TestServeListenAddressesKeepLoopbackSeparate(t *testing.T) {
	addresses := serveListenAddresses("100.100.100.100:8654")
	if len(addresses) != 2 || addresses[0] != "127.0.0.1:8654" || addresses[1] != "100.100.100.100:8654" {
		t.Fatalf("addresses = %#v", addresses)
	}
	loopback := serveListenAddresses("127.0.0.1:8654")
	if len(loopback) != 1 || loopback[0] != "127.0.0.1:8654" {
		t.Fatalf("loopback addresses = %#v", loopback)
	}
}
