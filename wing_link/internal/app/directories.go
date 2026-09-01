package app

import (
	"fmt"
	"io"
	"path/filepath"

	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/workspaces"
)

func openDirectoryGrantStore(statePath string) (*workspaces.Store, error) {
	return workspaces.Open(filepath.Join(filepath.Dir(statePath), "wing-link-directories.json"))
}

func directoriesCommand(stdout, stderr io.Writer, args []string) int {
	if len(args) == 0 {
		_, _ = fmt.Fprintln(stderr, "directories: expected list, grant <path>, or revoke <directory-id>")
		return 2
	}
	statePath, err := resolveWingLinkStatePath()
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "directories: %v\n", err)
		return 1
	}
	store, err := openDirectoryGrantStore(statePath)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "directories: %v\n", err)
		return 1
	}
	switch args[0] {
	case "list":
		if len(args) != 1 {
			_, _ = fmt.Fprintln(stderr, "directories list: no additional arguments are accepted")
			return 2
		}
		grants, err := store.List()
		if err != nil {
			_, _ = fmt.Fprintf(stderr, "directories list: %v\n", err)
			return 1
		}
		if len(grants) == 0 {
			_, _ = fmt.Fprintln(stdout, "No approved directory roots.")
			return 0
		}
		for _, grant := range grants {
			_, _ = fmt.Fprintf(stdout, "%s\t%s\t%s\n", grant.ID, grant.Name, grant.Path)
		}
		return 0
	case "grant":
		if len(args) != 2 {
			_, _ = fmt.Fprintln(stderr, "directories grant: expected exactly one local directory path")
			return 2
		}
		grant, err := store.Grant(args[1])
		if err != nil {
			_, _ = fmt.Fprintf(stderr, "directories grant: %v\n", err)
			return 1
		}
		_, _ = fmt.Fprintf(stdout, "%s\t%s\t%s\n", grant.ID, grant.Name, grant.Path)
		return 0
	case "revoke":
		if len(args) != 2 {
			_, _ = fmt.Fprintln(stderr, "directories revoke: expected exactly one directory ID")
			return 2
		}
		if err := store.Revoke(args[1]); err != nil {
			_, _ = fmt.Fprintf(stderr, "directories revoke: %v\n", err)
			return 1
		}
		_, _ = fmt.Fprintf(stdout, "Revoked directory grant %s.\n", args[1])
		return 0
	default:
		_, _ = fmt.Fprintf(stderr, "directories: unknown command %s\n", args[0])
		return 2
	}
}
