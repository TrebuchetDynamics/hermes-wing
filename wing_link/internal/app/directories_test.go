package app

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestDirectoriesCLILocallyGrantsListsAndRevokesRoots(t *testing.T) {
	statePath := filepath.Join(t.TempDir(), "state.json")
	t.Setenv("WING_LINK_STATE", statePath)
	root := filepath.Join(t.TempDir(), "repository")
	if err := os.Mkdir(root, 0o700); err != nil {
		t.Fatal(err)
	}

	var stdout, stderr bytes.Buffer
	if code := run([]string{"directories", "grant", root}, &stdout, &stderr); code != 0 {
		t.Fatalf("grant exit=%d stderr=%q", code, stderr.String())
	}
	fields := strings.Fields(stdout.String())
	if len(fields) < 2 || !strings.HasPrefix(fields[0], "dir_") || fields[1] != "repository" {
		t.Fatalf("unsafe or incomplete grant output: %q", stdout.String())
	}
	grantID := fields[0]

	stdout.Reset()
	stderr.Reset()
	if code := run([]string{"directories", "list"}, &stdout, &stderr); code != 0 {
		t.Fatalf("list exit=%d stderr=%q", code, stderr.String())
	}
	if !strings.Contains(stdout.String(), grantID) || !strings.Contains(stdout.String(), root) {
		t.Fatalf("list omitted local grant metadata: %q", stdout.String())
	}

	stdout.Reset()
	stderr.Reset()
	if code := run([]string{"directories", "revoke", grantID}, &stdout, &stderr); code != 0 {
		t.Fatalf("revoke exit=%d stderr=%q", code, stderr.String())
	}
	stdout.Reset()
	stderr.Reset()
	if code := run([]string{"directories", "list"}, &stdout, &stderr); code != 0 || !strings.Contains(stdout.String(), "No approved directory roots") {
		t.Fatalf("post-revoke list exit=%d stdout=%q stderr=%q", code, stdout.String(), stderr.String())
	}
}
