package app

import (
	"bytes"
	"context"
	"encoding/json"
	"net"
	"net/http"
	"net/http/httptest"
	"reflect"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

func TestBareCommandAndHelpDoNotTouchRuntime(t *testing.T) {
	t.Setenv("WING_HERMES_HOME", "relative-home")
	for _, args := range [][]string{nil, {"setup", "--help"}, {"help", "setup"}, {"pair", "-h"}, {"doctor", "--help"}, {"omniroute-setup", "--help"}, {"devices", "--help"}} {
		var out, err bytes.Buffer
		if code := run(args, &out, &err); code != 0 || out.Len() == 0 || err.Len() != 0 {
			t.Fatalf("%v code=%d out=%q err=%q", args, code, out.String(), err.String())
		}
	}
	var out, err bytes.Buffer
	if code := run([]string{"help", "pasted-sensitive-value"}, &out, &err); code != 2 || strings.Contains(err.String(), "pasted-sensitive-value") {
		t.Fatal("unknown help argument exposed")
	}
}

func TestOmniRoutePrerequisitesFailBeforeHermesSetup(t *testing.T) {
	t.Setenv("PATH", t.TempDir())
	t.Setenv("WING_HERMES_HOME", "relative-home")
	var out, err bytes.Buffer
	if code := bootstrapCommand(&out, &err, []string{"--with-omniroute"}); code != 1 {
		t.Fatal(code)
	}
	if !strings.Contains(err.String(), "prerequisite check failed") || !strings.Contains(err.String(), "Hermes setup has not started") || strings.Contains(err.String(), "absolute path") {
		t.Fatalf("unexpected setup sequence: %s", err.String())
	}
}

func TestDoctorChoosesRecoveryFromObservedState(t *testing.T) {
	ready := LocalInstallationInspection{HermesInstalled: true, HermesHealthy: true, SetupAvailable: true, HermesVersion: "Hermes Agent v0.21.0"}
	broken := ready
	broken.HermesHealthy = false
	for _, tc := range []struct {
		name        string
		inspection  LocalInstallationInspection
		agent, link bool
		platform    string
		want        string
		avoid       string
	}{
		{"missing", LocalInstallationInspection{SetupAvailable: true}, false, false, "android", "wing-link setup", "hermes doctor"},
		{"broken CLI", broken, false, false, "android", "hermes doctor", "wing-link setup"},
		{"API unavailable", ready, false, true, "linux", "wing-link setup", "wing-link pair"},
		{"phone ready", ready, true, true, "android", "wing-link pair --local --same-device", "wing-link setup"},
		{"desktop listener elsewhere", ready, true, false, "linux", "wing-link status", "wing-link serve"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			steps := strings.Join(localDoctorNextSteps(tc.inspection, tc.agent, tc.link, tc.platform), "\n")
			if !strings.Contains(steps, tc.want) || strings.Contains(steps, tc.avoid) {
				t.Fatalf("steps=%s", steps)
			}
		})
	}
	report := localDoctorReport{Inspection: ready, AgentAPIReady: true, WingLinkLoopbackReady: true, NextSteps: []string{"wing-link pair --local"}}
	var out bytes.Buffer
	if writeDoctorReport(&out, report, true) != 0 {
		t.Fatal("ready check failed")
	}
	var decoded localDoctorReport
	if json.Unmarshal(out.Bytes(), &decoded) != nil || !reflect.DeepEqual(decoded, report) {
		t.Fatal("invalid JSON report")
	}
	out.Reset()
	report.AgentAPIReady = false
	if writeDoctorReport(&out, report, false) != 1 || !strings.Contains(out.String(), "could not verify authenticated access") {
		t.Fatal("failed check claimed readiness")
	}
}

func TestDoctorLoopbackProbeRejectsWrongServiceAndRedirect(t *testing.T) {
	var redirected atomic.Int32
	target := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { redirected.Add(1); w.WriteHeader(200) }))
	defer target.Close()
	for _, tc := range []struct {
		name, body string
		status     int
		want       bool
	}{
		{"ready", `{"status":"ok","protocol_version":2}`, 200, true},
		{"old supported", `{"status":"ok","protocol_version":1}`, 200, true},
		{"unrelated", `{"status":"ok"}`, 200, false},
		{"future", `{"status":"ok","protocol_version":99}`, 200, false},
		{"redirect", ``, 302, false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				if r.Header.Get("Authorization") != "" {
					t.Error("health probe sent a credential")
				}
				if tc.status == 302 {
					w.Header().Set("Location", target.URL)
				}
				w.WriteHeader(tc.status)
				_, _ = w.Write([]byte(tc.body))
			}))
			defer server.Close()
			if probeWingLinkLoopback(context.Background(), server.URL) != tc.want {
				t.Fatal("unexpected readiness")
			}
		})
	}
	if redirected.Load() != 0 {
		t.Fatal("local probe followed redirect")
	}
}

func TestAuthenticatedLocalHealthDoesNotFollowRedirect(t *testing.T) {
	var called atomic.Bool
	target := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { called.Store(true) }))
	defer target.Close()
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { http.Redirect(w, r, target.URL, http.StatusFound) }))
	defer server.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 80*time.Millisecond)
	defer cancel()
	if waitForHermesAPIHealth(ctx, server.Listener.Addr().(*net.TCPAddr).Port, "test-only") == nil {
		t.Fatal("redirect accepted")
	}
	if called.Load() {
		t.Fatal("authenticated loopback request followed redirect")
	}
}

func TestDoctorRejectsRepairAndUnknownOptions(t *testing.T) {
	t.Setenv("WING_HERMES_HOME", "relative-home")
	var out, err bytes.Buffer
	if doctorCommand(&out, &err, []string{"--fix"}) != 2 {
		t.Fatal("automatic repair flag accepted")
	}
}
