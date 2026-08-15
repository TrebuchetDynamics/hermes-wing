package app

import (
	"bytes"
	"strings"
	"testing"
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
		"Typical first run:",
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
