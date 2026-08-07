//go:build linux

package main

import (
	"strings"
	"testing"
)

func TestWingLinkSystemdUnitPersistsExactServiceBoundaries(t *testing.T) {
	unit := wingLinkSystemdUnit(
		"/home/user/.local/lib/hermes-wing/wing-link",
		"100.100.100.100:8654",
		"http://100.100.100.100:8642",
		"/home/user/.local/bin:/usr/bin",
		"/home/user/.config/hermes-wing/state.json",
		"/srv/hermes",
		"",
	)
	for _, expected := range []string{
		"WantedBy=default.target",
		"Restart=on-failure",
		`serve --listen "100.100.100.100:8654"`,
		`WING_HERMES_URL="http://100.100.100.100:8642"`,
		`WING_LINK_STATE="/home/user/.config/hermes-wing/state.json"`,
		`WING_HERMES_HOME="/srv/hermes"`,
	} {
		if !strings.Contains(unit, expected) {
			t.Fatalf("unit missing %q:\n%s", expected, unit)
		}
	}
	if strings.Contains(unit, "API_SERVER_KEY") || strings.Contains(unit, "WING_HERMES_TOKEN") {
		t.Fatal("service unit persisted a Hermes credential")
	}

	legacyHome := wingLinkSystemdUnit(
		"/bin/wing-link", "127.0.0.1:8654", "http://127.0.0.1:8642",
		"/usr/bin", "/tmp/state", "", "/srv/hermes/profiles/link",
	)
	if !strings.Contains(legacyHome, `Environment=HERMES_HOME="/srv/hermes/profiles/link"`) ||
		strings.Contains(legacyHome, "WING_HERMES_HOME") {
		t.Fatalf("legacy Hermes home lost normalization semantics:\n%s", legacyHome)
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
