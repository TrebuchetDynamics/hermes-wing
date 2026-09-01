package app

import (
	"bytes"
	"crypto/ed25519"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/approval"
	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/audit"
)

func TestRunRejectsUnknownCommands(t *testing.T) {
	var stdout, stderr bytes.Buffer
	if code := run([]string{"shell"}, &stdout, &stderr); code != 2 {
		t.Fatalf("exit code = %d", code)
	}
	if stdout.Len() != 0 {
		t.Fatalf("unexpected stdout: %q", stdout.String())
	}
	if !strings.Contains(stderr.String(), "Usage:") {
		t.Fatalf("missing usage: %q", stderr.String())
	}
}

func TestRunPrintsVersion(t *testing.T) {
	var stdout, stderr bytes.Buffer
	if code := run([]string{"version"}, &stdout, &stderr); code != 0 {
		t.Fatalf("exit code = %d", code)
	}
	if stdout.String() != version+"\n" || stderr.Len() != 0 {
		t.Fatalf("stdout=%q stderr=%q", stdout.String(), stderr.String())
	}
}

func TestHelpExplainsTheNormalServiceWorkflow(t *testing.T) {
	var stdout, stderr bytes.Buffer
	if code := run([]string{"help"}, &stdout, &stderr); code != 0 {
		t.Fatalf("exit code = %d", code)
	}
	for _, want := range []string{
		"Wing Link\n  Local supervisor",
		"Managed service:",
		"Typical first run with Tailscale:",
		"wing-link pair --local",
		"--remote                Pair through Tailscale or a trusted VPN (default)",
		"Tailscale API binding is configured automatically",
		"Prints a single-use paste link by default",
		"--local                 Pair on this device only",
		"--same-device           Print only the code-free local /open URL",
		"--qr                    Print a scannable QR instead of the link",
		"WING_HERMES_URL to name it",
		`Most users should not run "serve" directly`,
	} {
		if !strings.Contains(stdout.String(), want) {
			t.Fatalf("help missing %q:\n%s", want, stdout.String())
		}
	}
	if stderr.Len() != 0 {
		t.Fatalf("unexpected stderr: %q", stderr.String())
	}
}

func TestServiceCommandsRejectExtraArgumentsWithoutExecution(t *testing.T) {
	for _, command := range []string{"status", "start", "stop", "restart"} {
		var stdout, stderr bytes.Buffer
		if code := run([]string{command, "extra"}, &stdout, &stderr); code != 2 {
			t.Fatalf("%s exit code = %d", command, code)
		}
		if stdout.Len() != 0 || !strings.Contains(stderr.String(), "Usage:") {
			t.Fatalf("%s stdout=%q stderr=%q", command, stdout.String(), stderr.String())
		}
	}
}

func TestDevicesCLIListsAndIndividuallyRevokesWithoutSecrets(t *testing.T) {
	statePath := filepath.Join(t.TempDir(), "state.json")
	t.Setenv("WING_LINK_STATE", statePath)
	store := newStateStore(statePath)
	id, token, err := store.StageDeviceCredential(
		"Pixel 9",
		ed25519.PublicKey(bytes.Repeat([]byte{9}, ed25519.PublicKeySize)),
		[]string{ScopeHealthRead, ScopeDeviceSelfRead},
	)
	if err != nil {
		t.Fatal(err)
	}
	if err := store.AcknowledgeControlToken(id, token); err != nil {
		t.Fatal(err)
	}

	var stdout, stderr bytes.Buffer
	if code := run([]string{"devices", "list"}, &stdout, &stderr); code != 0 {
		t.Fatalf("list exit=%d stderr=%q", code, stderr.String())
	}
	if !strings.Contains(stdout.String(), id) || !strings.Contains(stdout.String(), "Pixel 9") || !strings.Contains(stdout.String(), ScopeHealthRead) {
		t.Fatalf("list omitted safe device metadata: %q", stdout.String())
	}
	if strings.Contains(stdout.String(), token) || strings.Contains(stdout.String(), "token_hash") || strings.Contains(stdout.String(), "public_key") {
		t.Fatalf("list leaked credential material: %q", stdout.String())
	}

	stdout.Reset()
	stderr.Reset()
	if code := run([]string{"devices", "revoke", id}, &stdout, &stderr); code != 0 {
		t.Fatalf("revoke exit=%d stderr=%q", code, stderr.String())
	}
	if store.Authorize(token) {
		t.Fatal("revoked CLI credential remained authorized")
	}
}

func TestAuditCLIListsSafeFieldsAndRequiresConfirmedClear(t *testing.T) {
	statePath := filepath.Join(t.TempDir(), "state.json")
	t.Setenv("WING_LINK_STATE", statePath)
	log, err := openAuditLog(statePath)
	if err != nil {
		t.Fatal(err)
	}
	if err := log.Append(audit.Input{
		DeviceID: "cred_phone", Operation: approval.OpProfileDelete,
		ApprovalSource: audit.SourceHostCLI, Result: audit.ResultSuccess,
		ProtocolGeneration: ProtocolVersion, Duration: time.Millisecond,
	}); err != nil {
		t.Fatal(err)
	}
	var stdout, stderr bytes.Buffer
	if code := run([]string{"audit"}, &stdout, &stderr); code != 0 {
		t.Fatalf("audit exit=%d stderr=%q", code, stderr.String())
	}
	if !strings.Contains(stdout.String(), "cred_phone") || !strings.Contains(stdout.String(), "profile.delete") {
		t.Fatalf("audit omitted safe fields: %q", stdout.String())
	}
	stdout.Reset()
	stderr.Reset()
	if code := run([]string{"audit", "clear"}, &stdout, &stderr); code != 2 {
		t.Fatalf("unconfirmed clear exit=%d", code)
	}
	stdout.Reset()
	stderr.Reset()
	if code := run([]string{"audit", "clear", "--confirm"}, &stdout, &stderr); code != 0 {
		t.Fatalf("confirmed clear exit=%d stderr=%q", code, stderr.String())
	}
	events, err := log.List()
	if err != nil || len(events) != 0 {
		t.Fatalf("events=%#v err=%v", events, err)
	}
}

func TestApprovalsCLIListsAndApprovesWithoutPayloads(t *testing.T) {
	statePath := filepath.Join(t.TempDir(), "state.json")
	t.Setenv("WING_LINK_STATE", statePath)
	store, err := openApprovalStore(statePath)
	if err != nil {
		t.Fatal(err)
	}
	pending, err := store.Request(approval.Request{
		DeviceID: "cred_phone", DeviceName: "Pixel 9",
		Operation: approval.OpSetupInstall, Route: "POST /v1/setup",
		PayloadDigest: strings.Repeat("d", 64), IdempotencyKey: "setup-cli-1",
		Summary: "Install managed runtime",
	}, approval.TierTrust, 5*time.Minute)
	if err != nil {
		t.Fatal(err)
	}

	var stdout, stderr bytes.Buffer
	if code := run([]string{"approvals", "list"}, &stdout, &stderr); code != 0 {
		t.Fatalf("list exit=%d stderr=%q", code, stderr.String())
	}
	if !strings.Contains(stdout.String(), pending.ID) || !strings.Contains(stdout.String(), "Install managed runtime") || strings.Contains(stdout.String(), pending.Request.PayloadDigest) {
		t.Fatalf("unsafe approval list output: %q", stdout.String())
	}

	stdout.Reset()
	stderr.Reset()
	if code := run([]string{"approvals", "approve", pending.ID}, &stdout, &stderr); code != 0 {
		t.Fatalf("approve exit=%d stderr=%q", code, stderr.String())
	}
	rows, err := store.List()
	if err != nil || len(rows) != 1 || rows[0].State != approval.StateApproved {
		t.Fatalf("approval rows=%#v err=%v", rows, err)
	}
}

func TestRunRejectsExtraArguments(t *testing.T) {
	for _, test := range []struct {
		args    []string
		message string
	}{
		{args: []string{"pair", "version"}, message: "unknown option version"},
		{args: []string{"serve", "--port", "9000"}, message: "unknown option --port"},
	} {
		var stdout, stderr bytes.Buffer
		if code := run(test.args, &stdout, &stderr); code != 2 {
			t.Fatalf("%v exit code = %d", test.args, code)
		}
		if stdout.Len() != 0 || !strings.Contains(stderr.String(), test.message) {
			t.Fatalf("%v stdout=%q stderr=%q", test.args, stdout.String(), stderr.String())
		}
	}
}
