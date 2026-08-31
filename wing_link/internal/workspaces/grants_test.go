package workspaces

import (
	"errors"
	"os"
	"path/filepath"
	"testing"
)

func TestDirectoryGrantStoreCanonicalizesDeduplicatesAndRevokes(t *testing.T) {
	root := t.TempDir()
	repository := filepath.Join(root, "repository")
	if err := os.Mkdir(repository, 0o700); err != nil {
		t.Fatal(err)
	}
	store, err := Open(filepath.Join(t.TempDir(), "directory-grants.json"))
	if err != nil {
		t.Fatal(err)
	}

	first, err := store.Grant(filepath.Join(repository, "."))
	if err != nil {
		t.Fatal(err)
	}
	if first.ID == "" || first.Name != "repository" || first.Path != repository {
		t.Fatalf("unexpected grant: %#v", first)
	}
	second, err := store.Grant(repository)
	if err != nil {
		t.Fatal(err)
	}
	if second.ID != first.ID {
		t.Fatalf("duplicate path received another handle: %q != %q", second.ID, first.ID)
	}
	grants, err := store.List()
	if err != nil {
		t.Fatal(err)
	}
	if len(grants) != 1 || grants[0] != first {
		t.Fatalf("grants = %#v", grants)
	}

	if err := store.Revoke(first.ID); err != nil {
		t.Fatal(err)
	}
	grants, err = store.List()
	if err != nil || len(grants) != 0 {
		t.Fatalf("grants=%#v err=%v", grants, err)
	}
	if err := store.Revoke(first.ID); !errors.Is(err, ErrGrantNotFound) {
		t.Fatalf("second revoke error = %v", err)
	}
}

func TestDirectoryGrantStoreResolvesSymlinksAndPersistsOwnerOnly(t *testing.T) {
	parent := t.TempDir()
	target := filepath.Join(parent, "target")
	alias := filepath.Join(parent, "alias")
	if err := os.Mkdir(target, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(target, alias); err != nil {
		t.Skipf("symlinks unavailable: %v", err)
	}
	statePath := filepath.Join(t.TempDir(), "directory-grants.json")
	store, err := Open(statePath)
	if err != nil {
		t.Fatal(err)
	}
	grant, err := store.Grant(alias)
	if err != nil {
		t.Fatal(err)
	}
	if grant.Path != target || grant.Name != "target" {
		t.Fatalf("grant = %#v", grant)
	}
	info, err := os.Stat(statePath)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm() != 0o600 {
		t.Fatalf("state mode = %o", info.Mode().Perm())
	}
	reopened, err := Open(statePath)
	if err != nil {
		t.Fatal(err)
	}
	grants, err := reopened.List()
	if err != nil || len(grants) != 1 || grants[0] != grant {
		t.Fatalf("grants=%#v err=%v", grants, err)
	}
}

func TestDirectoryGrantResolveRechecksCanonicalDirectory(t *testing.T) {
	root := filepath.Join(t.TempDir(), "repository")
	if err := os.Mkdir(root, 0o700); err != nil {
		t.Fatal(err)
	}
	store, err := Open(filepath.Join(t.TempDir(), "grants.json"))
	if err != nil {
		t.Fatal(err)
	}
	grant, err := store.Grant(root)
	if err != nil {
		t.Fatal(err)
	}
	resolved, err := store.Resolve(grant.ID)
	if err != nil || resolved != grant {
		t.Fatalf("resolved=%#v err=%v", resolved, err)
	}
	if err := os.Remove(root); err != nil {
		t.Fatal(err)
	}
	if _, err := store.Resolve(grant.ID); !errors.Is(err, ErrGrantNotFound) {
		t.Fatalf("removed directory resolve error = %v", err)
	}
}

func TestDirectoryGrantResolveRejectsRevokedAndSymlinkReplacedRoots(t *testing.T) {
	for _, testCase := range []struct {
		name   string
		mutate func(t *testing.T, store *Store, grant DirectoryGrant)
	}{
		{
			name: "revoked",
			mutate: func(t *testing.T, store *Store, grant DirectoryGrant) {
				if err := store.Revoke(grant.ID); err != nil {
					t.Fatal(err)
				}
			},
		},
		{
			name: "symlink replaced",
			mutate: func(t *testing.T, _ *Store, grant DirectoryGrant) {
				outside := filepath.Join(t.TempDir(), "outside")
				if err := os.Mkdir(outside, 0o700); err != nil {
					t.Fatal(err)
				}
				if err := os.Remove(grant.Path); err != nil {
					t.Fatal(err)
				}
				if err := os.Symlink(outside, grant.Path); err != nil {
					t.Skipf("symlinks unavailable: %v", err)
				}
			},
		},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			root := filepath.Join(t.TempDir(), "repository")
			if err := os.Mkdir(root, 0o700); err != nil {
				t.Fatal(err)
			}
			store, err := Open(filepath.Join(t.TempDir(), "grants.json"))
			if err != nil {
				t.Fatal(err)
			}
			grant, err := store.Grant(root)
			if err != nil {
				t.Fatal(err)
			}
			testCase.mutate(t, store, grant)
			if _, err := store.Resolve(grant.ID); !errors.Is(err, ErrGrantNotFound) {
				t.Fatalf("resolve error = %v", err)
			}
		})
	}
}

func TestDirectoryGrantStoreRejectsFilesAndMalformedState(t *testing.T) {
	filePath := filepath.Join(t.TempDir(), "file.txt")
	if err := os.WriteFile(filePath, []byte("content"), 0o600); err != nil {
		t.Fatal(err)
	}
	store, err := Open(filepath.Join(t.TempDir(), "directory-grants.json"))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := store.Grant(filePath); err == nil {
		t.Fatal("regular file was accepted as a directory root")
	}

	statePath := filepath.Join(t.TempDir(), "directory-grants.json")
	payload := []byte(`{"schema":1,"grants":[{"id":"dir_AAAAAAAAAAAAAAAAAAAAAA","name":"relative","path":"relative"}]}`)
	if err := os.WriteFile(statePath, payload, 0o600); err != nil {
		t.Fatal(err)
	}
	malformed, err := Open(statePath)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := malformed.List(); err == nil {
		t.Fatal("relative persisted path was accepted")
	}
}
