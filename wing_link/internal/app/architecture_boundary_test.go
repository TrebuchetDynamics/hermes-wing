package app

import (
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestWingLinkProfileAdapterRemainsBounded(t *testing.T) {
	forbidden := []string{
		`"profile", "use"`,
		"profile_transport",
		"writeProfileInventory",
		"httputil.NewSingleHostReverseProxy",
		"--all-profiles",
		"providerBackend",
		"/v1/providers",
		"/api/sessions",
		"/v1/runs",
		"hermes acp",
		"acp_adapter",
		"api:       newHermesProfileAPI",
		"backend.api.",
		"os.ReadDir(profilesRoot)",
	}
	err := filepath.WalkDir(filepath.Join("..", ".."), func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() || filepath.Ext(path) != ".go" || strings.HasSuffix(path, "_test.go") {
			return nil
		}
		payload, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		for _, fragment := range forbidden {
			if strings.Contains(string(payload), fragment) {
				t.Errorf("%s contains forbidden Hermes domain authority fragment %q", path, fragment)
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}
