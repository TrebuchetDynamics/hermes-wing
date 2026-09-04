package release

import (
	"bytes"
	"context"
	"crypto/ed25519"
	"crypto/rand"
	"crypto/sha256"
	"crypto/tls"
	"crypto/x509"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"io/fs"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"
)

var (
	errInjectedRestart = errors.New("injected restart failure")
	errInjectedHealth  = errors.New("injected health failure")
	errInjectedBody    = errors.New("injected interrupted body")
	errInjectedSync    = errors.New("injected directory sync failure")
)

type updateFixture struct {
	ctx          context.Context
	publicKey    ed25519.PublicKey
	privateKey   ed25519.PrivateKey
	trustedKeys  map[string]ed25519.PublicKey
	root         string
	artifact     []byte
	manifest     []byte
	signature    []byte
	manifestHits *int
	fetchHits    *int
	restartCalls *int
	healthCalls  *int
	calls        *[]string
}

func newUpdateFixture(t *testing.T) *updateFixture {
	t.Helper()
	publicKey, privateKey, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	root, err := filepath.EvalSymlinks(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	manifestHits, fetchHits, restartCalls, healthCalls := 0, 0, 0, 0
	return &updateFixture{
		ctx:          context.Background(),
		publicKey:    publicKey,
		privateKey:   privateKey,
		trustedKeys:  map[string]ed25519.PublicKey{"release-key": publicKey},
		root:         root,
		artifact:     []byte("wing-link linux binary payload 1.2.4"),
		manifestHits: &manifestHits,
		fetchHits:    &fetchHits,
		restartCalls: &restartCalls,
		healthCalls:  &healthCalls,
		calls:        &[]string{},
	}
}

func (f *updateFixture) signCatalog(t *testing.T, catalog ComponentCatalog) {
	t.Helper()
	manifest, err := json.Marshal(catalog)
	if err != nil {
		t.Fatal(err)
	}
	f.manifest = manifest
	f.signature = ed25519.Sign(f.privateKey, manifest)
}

func (f *updateFixture) wingLinkCatalog(t *testing.T, version string, minimumProtocolGeneration int, artifact Artifact) ComponentCatalog {
	t.Helper()
	now := time.Now().UTC()
	return ComponentCatalog{
		Schema:          1,
		SigningKeyID:    "release-key",
		ReleaseIdentity: "test.wing-link",
		IssuedAt:        now.Add(-time.Minute),
		ExpiresAt:       now.Add(time.Hour),
		WingLink: &WingLinkComponent{
			Version:                   version,
			Linux:                     artifact,
			MinimumProtocolGeneration: minimumProtocolGeneration,
		},
	}
}

func (f *updateFixture) validArtifact(t *testing.T) Artifact {
	t.Helper()
	digest := sha256.Sum256(f.artifact)
	return Artifact{
		URL:    "https://releases.example.test/wing-link/wing-link-linux",
		Size:   int64(len(f.artifact)),
		SHA256: hex.EncodeToString(digest[:]),
	}
}

func (f *updateFixture) defaultCatalog(t *testing.T) ComponentCatalog {
	t.Helper()
	return f.wingLinkCatalog(t, "1.2.4", 2, f.validArtifact(t))
}

func (f *updateFixture) config(version string, protocolGeneration int) Config {
	return Config{
		Root:               f.root,
		CurrentVersion:     version,
		ProtocolGeneration: protocolGeneration,
		TrustedKeys:        f.trustedKeys,
		ManifestSource: func(context.Context) ([]byte, []byte, error) {
			*f.manifestHits++
			return f.manifest, f.signature, nil
		},
		FetchArtifact: func(_ context.Context, _ string, _ int64) (io.ReadCloser, error) {
			*f.fetchHits++
			return io.NopCloser(bytes.NewReader(f.artifact)), nil
		},
		Restart: func(context.Context) error {
			*f.restartCalls++
			*f.calls = append(*f.calls, "restart")
			return nil
		},
		HealthCheck: func(context.Context) error {
			*f.healthCalls++
			*f.calls = append(*f.calls, "health")
			return nil
		},
	}
}

// seedActivatedVersion installs a staged version plus current/previous links so
// activation tests exercise a realistic prior layout.
func seedActivatedVersion(t *testing.T, root, version string) {
	t.Helper()
	versionDir := filepath.Join(root, versionsDirName, version)
	if err := os.MkdirAll(versionDir, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(versionDir, wingLinkBinary), []byte("old binary "+version), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(filepath.Join(versionsDirName, version, wingLinkBinary), filepath.Join(root, currentLinkName)); err != nil {
		t.Fatal(err)
	}
}

func linkTarget(t *testing.T, path string) string {
	t.Helper()
	target, err := os.Readlink(path)
	if err != nil {
		t.Fatalf("readlink %s: %v", filepath.Base(path), err)
	}
	return target
}

func assertPerm(t *testing.T, path string, want os.FileMode) {
	t.Helper()
	info, err := os.Stat(path)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm() != want {
		t.Fatalf("%s permissions = %o, want %o", filepath.Base(path), info.Mode().Perm(), want)
	}
}

func TestParseVersionIsStrictlyNumeric(t *testing.T) {
	for _, valid := range []string{"0.0.0", "1.2.3", "10.20.30", "18446744073709551615.0.0"} {
		if _, err := ParseVersion(valid); err != nil {
			t.Fatalf("ParseVersion(%q) error = %v", valid, err)
		}
	}
	for _, invalid := range []string{
		"", "1", "1.2", "1.2.3.4", "v1.2.3", "1.2.x", "01.2.3", "1.02.3", "1.2.03",
		"+1.2.3", "-1.2.3", "1.2.-3", "1.2.3-rc1", "1.2.3+build", "1..3", "..", "1.2.",
		" 1.2.3", "1.2.3 ", "1_0.2.3", "18446744073709551616.0.0",
	} {
		if _, err := ParseVersion(invalid); !errors.Is(err, ErrInvalidVersion) {
			t.Fatalf("ParseVersion(%q) error = %v, want ErrInvalidVersion", invalid, err)
		}
	}
}

func TestVersionCompareIsNumericNotLexicographic(t *testing.T) {
	cases := []struct {
		left, right string
		want        int
	}{
		{"1.2.3", "1.2.3", 0},
		{"1.2.4", "1.2.3", 1},
		{"1.2.3", "1.2.4", -1},
		{"1.2.10", "1.2.9", 1},
		{"1.10.0", "1.9.99", 1},
		{"2.0.0", "1.999.999", 1},
		{"0.0.1", "0.0.0", 1},
		{"1.0.0", "0.9.9", 1},
	}
	for _, testCase := range cases {
		left, err := ParseVersion(testCase.left)
		if err != nil {
			t.Fatal(err)
		}
		right, err := ParseVersion(testCase.right)
		if err != nil {
			t.Fatal(err)
		}
		if got := left.Compare(right); got != testCase.want {
			t.Fatalf("%s.Compare(%s) = %d, want %d", testCase.left, testCase.right, got, testCase.want)
		}
	}
}

func TestApplyFailsClosedBeforeNetworkWhenTrustedKeyMapEmpty(t *testing.T) {
	fixture := newUpdateFixture(t)
	fixture.signCatalog(t, fixture.defaultCatalog(t))
	seedActivatedVersion(t, fixture.root, "1.2.3")
	config := fixture.config("1.2.3", 2)

	for name, keys := range map[string]map[string]ed25519.PublicKey{
		"empty map":       {},
		"nil map":         nil,
		"production keys": trustedReleaseKeys,
	} {
		config.TrustedKeys = keys
		updater, err := NewUpdater(config)
		if err != nil {
			t.Fatalf("%s: NewUpdater error = %v", name, err)
		}
		result, err := updater.Apply(fixture.ctx)
		if !errors.Is(err, ErrUpdateUnavailable) {
			t.Fatalf("%s: Apply error = %v, want ErrUpdateUnavailable", name, err)
		}
		if result != (ApplyResult{}) {
			t.Fatalf("%s: result = %#v, want zero", name, result)
		}
		if *fixture.manifestHits != 0 || *fixture.fetchHits != 0 {
			t.Fatalf("%s: network seams called (manifest=%d fetch=%d)", name, *fixture.manifestHits, *fixture.fetchHits)
		}
	}
}

func TestApplyRejectsDowngradeReinstallAndFutureProtocol(t *testing.T) {
	cases := []struct {
		name          string
		current       string
		target        string
		minimumProto  int
		hostProto     int
		want          error
		wantManifest  int
		wantFetchCall bool
	}{
		{name: "downgrade", current: "1.2.3", target: "1.2.2", minimumProto: 1, hostProto: 2, want: ErrDowngrade, wantManifest: 1},
		{name: "reinstall", current: "1.2.3", target: "1.2.3", minimumProto: 1, hostProto: 2, want: ErrReinstall, wantManifest: 1},
		{name: "future protocol", current: "1.2.3", target: "1.2.4", minimumProto: 3, hostProto: 2, want: ErrProtocolUnsupported, wantManifest: 1},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			fixture := newUpdateFixture(t)
			fixture.signCatalog(t, fixture.wingLinkCatalog(t, testCase.target, testCase.minimumProto, fixture.validArtifact(t)))
			seedActivatedVersion(t, fixture.root, "1.2.3")
			updater, err := NewUpdater(fixture.config(testCase.current, testCase.hostProto))
			if err != nil {
				t.Fatal(err)
			}
			if _, err := updater.Apply(fixture.ctx); !errors.Is(err, testCase.want) {
				t.Fatalf("Apply error = %v, want %v", err, testCase.want)
			}
			if *fixture.manifestHits != testCase.wantManifest {
				t.Fatalf("manifest calls = %d, want %d", *fixture.manifestHits, testCase.wantManifest)
			}
			if *fixture.fetchHits != 0 {
				t.Fatalf("artifact download attempted (%d calls) despite refusal", *fixture.fetchHits)
			}
			// A refused update must never stage anything beyond the seeded
			// current version directory.
			entries, err := os.ReadDir(filepath.Join(fixture.root, versionsDirName))
			if err != nil {
				t.Fatal(err)
			}
			for _, entry := range entries {
				if entry.Name() != "1.2.3" {
					t.Fatalf("refused update staged %q", entry.Name())
				}
			}
		})
	}
}

func TestApplyRejectsUnsignedManifestAndMissingLinuxArtifact(t *testing.T) {
	fixture := newUpdateFixture(t)
	fixture.signCatalog(t, fixture.defaultCatalog(t))
	seedActivatedVersion(t, fixture.root, "1.2.3")
	config := fixture.config("1.2.3", 2)

	tampered := append([]byte(nil), fixture.signature...)
	tampered[0] ^= 1
	savedSignature := fixture.signature
	fixture.signature = tampered
	updater, err := NewUpdater(config)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := updater.Apply(fixture.ctx); !errors.Is(err, ErrManifestSignature) {
		t.Fatalf("tampered signature error = %v, want ErrManifestSignature", err)
	}
	fixture.signature = savedSignature

	now := time.Now().UTC()
	withoutWingLink := ComponentCatalog{
		Schema:          1,
		SigningKeyID:    "release-key",
		ReleaseIdentity: "test.wing-link",
		IssuedAt:        now.Add(-time.Minute),
		ExpiresAt:       now.Add(time.Hour),
	}
	fixture.signCatalog(t, withoutWingLink)
	if _, err := updater.Apply(fixture.ctx); !errors.Is(err, ErrUpdateUnavailable) {
		t.Fatalf("missing wing_link artifact error = %v, want ErrUpdateUnavailable", err)
	}
	if *fixture.fetchHits != 0 {
		t.Fatalf("artifact download attempted without a wing_link release")
	}
}

func TestUpdaterRejectsChangedStagingAndExternalActivationTargets(t *testing.T) {
	root := t.TempDir()
	artifact := []byte("verified")
	digest := sha256.Sum256(artifact)
	path := filepath.Join(root, "wing-link")
	if err := os.WriteFile(path, artifact, 0o700); err != nil {
		t.Fatal(err)
	}
	contract := Artifact{Size: int64(len(artifact)), SHA256: hex.EncodeToString(digest[:])}
	if err := verifyStagedArtifact(path, contract); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte("tampered"), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := verifyStagedArtifact(path, contract); !errors.Is(err, ErrArtifactVerification) {
		t.Fatalf("tampered stage error=%v", err)
	}
	if err := os.Symlink("/tmp/attacker", filepath.Join(root, currentLinkName)); err != nil {
		t.Fatal(err)
	}
	fixture := newUpdateFixture(t)
	fixture.root = root
	fixture.signCatalog(t, fixture.defaultCatalog(t))
	updater, err := NewUpdater(fixture.config("1.2.3", 2))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := updater.Apply(context.Background()); !errors.Is(err, ErrUpdateState) {
		t.Fatalf("external target error=%v", err)
	}
	if *fixture.manifestHits != 0 || *fixture.fetchHits != 0 {
		t.Fatal("unsafe activation target triggered network access")
	}
}

func TestApplyStagesOwnerOnlyAndActivatesAtomically(t *testing.T) {
	fixture := newUpdateFixture(t)
	fixture.signCatalog(t, fixture.defaultCatalog(t))
	seedActivatedVersion(t, fixture.root, "1.2.3")
	if err := os.Symlink(filepath.Join(versionsDirName, "1.2.2", wingLinkBinary), filepath.Join(fixture.root, previousLinkName)); err != nil {
		t.Fatal(err)
	}

	updater, err := NewUpdater(fixture.config("1.2.3", 2))
	if err != nil {
		t.Fatal(err)
	}
	result, err := updater.Apply(fixture.ctx)
	if err != nil {
		t.Fatal(err)
	}

	stagedPath := filepath.Join(fixture.root, versionsDirName, "1.2.4", wingLinkBinary)
	if result.StagedPath != stagedPath || result.FromVersion != "1.2.3" || result.ToVersion != "1.2.4" {
		t.Fatalf("result = %#v", result)
	}
	staged, err := os.ReadFile(stagedPath)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(staged, fixture.artifact) {
		t.Fatal("staged artifact content mismatch")
	}
	assertPerm(t, fixture.root, 0o700)
	assertPerm(t, filepath.Join(fixture.root, versionsDirName), 0o700)
	assertPerm(t, filepath.Join(fixture.root, versionsDirName, "1.2.4"), 0o700)
	// Owner-only and executable: the systemd unit execs the current target.
	assertPerm(t, stagedPath, 0o700)

	if got, want := linkTarget(t, filepath.Join(fixture.root, currentLinkName)), filepath.Join(versionsDirName, "1.2.4", wingLinkBinary); got != want {
		t.Fatalf("current -> %s, want %s", got, want)
	}
	if got, want := linkTarget(t, filepath.Join(fixture.root, previousLinkName)), filepath.Join(versionsDirName, "1.2.3", wingLinkBinary); got != want {
		t.Fatalf("previous -> %s, want %s", got, want)
	}
	if *fixture.restartCalls != 1 || *fixture.healthCalls != 1 {
		t.Fatalf("restart calls = %d, health calls = %d, want 1 and 1", *fixture.restartCalls, *fixture.healthCalls)
	}
	if len(*fixture.calls) != 2 || (*fixture.calls)[0] != "restart" || (*fixture.calls)[1] != "health" {
		t.Fatalf("activation order = %v, want restart before health", *fixture.calls)
	}
}

func TestApplyRejectsSymlinkedVersionDirectory(t *testing.T) {
	fixture := newUpdateFixture(t)
	fixture.signCatalog(t, fixture.defaultCatalog(t))
	versionsRoot := filepath.Join(fixture.root, versionsDirName)
	if err := os.MkdirAll(versionsRoot, 0o700); err != nil {
		t.Fatal(err)
	}
	outside := t.TempDir()
	if err := os.Symlink(outside, filepath.Join(versionsRoot, "1.2.4")); err != nil {
		t.Fatal(err)
	}

	updater, err := NewUpdater(fixture.config("1.2.3", 2))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := updater.Apply(fixture.ctx); !errors.Is(err, ErrUpdateState) {
		t.Fatalf("symlinked version directory error=%v", err)
	}
	if *fixture.fetchHits != 0 {
		t.Fatal("symlinked version directory triggered artifact fetch")
	}
	if _, err := os.Stat(filepath.Join(outside, wingLinkBinary)); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("artifact escaped update root, stat error=%v", err)
	}
}

func TestApplyRejectsSymlinkedUpdateRootAncestor(t *testing.T) {
	fixture := newUpdateFixture(t)
	fixture.signCatalog(t, fixture.defaultCatalog(t))
	parent := t.TempDir()
	outside := t.TempDir()
	link := filepath.Join(parent, "linked")
	if err := os.Symlink(outside, link); err != nil {
		t.Fatal(err)
	}
	fixture.root = filepath.Join(link, "releases")

	updater, err := NewUpdater(fixture.config("1.2.3", 2))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := updater.Apply(fixture.ctx); !errors.Is(err, ErrUpdateState) {
		t.Fatalf("symlinked update root ancestor error=%v", err)
	}
	if *fixture.fetchHits != 0 {
		t.Fatal("symlinked update root ancestor triggered artifact fetch")
	}
	if _, err := os.Stat(filepath.Join(outside, "releases")); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("update root escaped through ancestor, stat error=%v", err)
	}
}

func TestApplyRestagesOverLeftoverFailedStaging(t *testing.T) {
	fixture := newUpdateFixture(t)
	fixture.signCatalog(t, fixture.defaultCatalog(t))
	leftoverDir := filepath.Join(fixture.root, versionsDirName, "1.2.4")
	if err := os.MkdirAll(leftoverDir, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(leftoverDir, wingLinkBinary), []byte("truncated leftover"), 0o700); err != nil {
		t.Fatal(err)
	}

	updater, err := NewUpdater(fixture.config("1.2.3", 2))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := updater.Apply(fixture.ctx); err != nil {
		t.Fatal(err)
	}
	staged, err := os.ReadFile(filepath.Join(leftoverDir, wingLinkBinary))
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(staged, fixture.artifact) {
		t.Fatal("leftover staged artifact was not replaced")
	}
}

func TestApplyRejectsDigestSizeAndInterruptFailuresWithoutActivating(t *testing.T) {
	corrupt := append([]byte(nil), fixtureArtifactBytes()...)
	corrupt[0] ^= 1
	short := []byte("too short")
	overlong := append([]byte(nil), fixtureArtifactBytes()...)
	overlong = append(overlong, "extra bytes beyond the signed size"...)

	interrupted := io.MultiReader(
		bytes.NewReader(fixtureArtifactBytes()[:5]),
		errReader{err: errInjectedBody},
	)

	cases := []struct {
		name    string
		payload io.Reader
	}{
		{name: "digest mismatch", payload: bytes.NewReader(corrupt)},
		{name: "size short", payload: bytes.NewReader(short)},
		{name: "size overlong", payload: bytes.NewReader(overlong)},
		{name: "interrupted body", payload: interrupted},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			fixture := newUpdateFixture(t)
			fixture.artifact = fixtureArtifactBytes()
			fixture.signCatalog(t, fixture.defaultCatalog(t))
			seedActivatedVersion(t, fixture.root, "1.2.3")
			config := fixture.config("1.2.3", 2)
			config.FetchArtifact = func(_ context.Context, _ string, _ int64) (io.ReadCloser, error) {
				*fixture.fetchHits++
				return io.NopCloser(testCase.payload), nil
			}
			updater, err := NewUpdater(config)
			if err != nil {
				t.Fatal(err)
			}
			if _, err := updater.Apply(fixture.ctx); !errors.Is(err, ErrArtifactVerification) {
				t.Fatalf("Apply error = %v, want ErrArtifactVerification", err)
			}
			if got, want := linkTarget(t, filepath.Join(fixture.root, currentLinkName)), filepath.Join(versionsDirName, "1.2.3", wingLinkBinary); got != want {
				t.Fatalf("current -> %s, want %s", got, want)
			}
			if *fixture.restartCalls != 0 {
				t.Fatalf("restart called after failed verification")
			}
			entries, err := os.ReadDir(filepath.Join(fixture.root, versionsDirName, "1.2.4"))
			if err != nil {
				t.Fatal(err)
			}
			for _, entry := range entries {
				if strings.HasPrefix(entry.Name(), ".stage-") {
					t.Fatalf("temporary staging file %s leaked", entry.Name())
				}
			}
		})
	}
}

func TestApplyRollsBackOnRestartFailure(t *testing.T) {
	fixture := newUpdateFixture(t)
	fixture.signCatalog(t, fixture.defaultCatalog(t))
	seedActivatedVersion(t, fixture.root, "1.2.3")
	config := fixture.config("1.2.3", 2)
	config.Restart = func(context.Context) error {
		*fixture.restartCalls++
		return errInjectedRestart
	}
	updater, err := NewUpdater(config)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := updater.Apply(fixture.ctx); !errors.Is(err, ErrUpdateRolledBack) || !errors.Is(err, errInjectedRestart) {
		t.Fatalf("Apply error = %v, want ErrUpdateRolledBack wrapping the restart failure", err)
	}
	if got, want := linkTarget(t, filepath.Join(fixture.root, currentLinkName)), filepath.Join(versionsDirName, "1.2.3", wingLinkBinary); got != want {
		t.Fatalf("current -> %s, want %s after rollback", got, want)
	}
	if _, err := os.Lstat(filepath.Join(fixture.root, previousLinkName)); !errors.Is(err, fs.ErrNotExist) {
		t.Fatalf("previous link state after rollback = %v, want absent", err)
	}
	if *fixture.healthCalls != 0 {
		t.Fatal("health check ran although restart failed")
	}
}

func TestActivationRollsBackWhenDirectorySyncFails(t *testing.T) {
	fixture := newUpdateFixture(t)
	seedActivatedVersion(t, fixture.root, "1.2.3")
	updater, err := NewUpdater(fixture.config("1.2.3", 2))
	if err != nil {
		t.Fatal(err)
	}
	calls := 0
	updater.syncDirectory = func(path string) error {
		calls++
		if calls == 1 {
			return errInjectedSync
		}
		return syncDirectory(path)
	}
	staged := filepath.Join(fixture.root, versionsDirName, "1.2.4", wingLinkBinary)
	if err := os.MkdirAll(filepath.Dir(staged), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(staged, fixture.artifact, 0o700); err != nil {
		t.Fatal(err)
	}
	current := filepath.Join(versionsDirName, "1.2.3", wingLinkBinary)
	if err := updater.activate(context.Background(), staged, current, ""); !errors.Is(err, ErrUpdateRolledBack) || !errors.Is(err, errInjectedSync) {
		t.Fatalf("activate error = %v, want rollback wrapping sync failure", err)
	}
	if got := linkTarget(t, filepath.Join(fixture.root, currentLinkName)); got != current {
		t.Fatalf("current -> %s, want %s after rollback", got, current)
	}
	if _, err := os.Lstat(filepath.Join(fixture.root, previousLinkName)); !errors.Is(err, fs.ErrNotExist) {
		t.Fatalf("previous link state after rollback = %v, want absent", err)
	}
	if *fixture.restartCalls != 0 || *fixture.healthCalls != 0 {
		t.Fatal("restart or health check ran after activation sync failed")
	}
}

func TestApplyRollsBackOnHealthFailure(t *testing.T) {
	fixture := newUpdateFixture(t)
	fixture.signCatalog(t, fixture.defaultCatalog(t))
	seedActivatedVersion(t, fixture.root, "1.2.3")
	if err := os.Symlink(filepath.Join(versionsDirName, "1.2.2", wingLinkBinary), filepath.Join(fixture.root, previousLinkName)); err != nil {
		t.Fatal(err)
	}
	config := fixture.config("1.2.3", 2)
	config.HealthCheck = func(context.Context) error {
		*fixture.healthCalls++
		return errInjectedHealth
	}
	updater, err := NewUpdater(config)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := updater.Apply(fixture.ctx); !errors.Is(err, ErrUpdateRolledBack) || !errors.Is(err, errInjectedHealth) {
		t.Fatalf("Apply error = %v, want ErrUpdateRolledBack wrapping the health failure", err)
	}
	if got, want := linkTarget(t, filepath.Join(fixture.root, currentLinkName)), filepath.Join(versionsDirName, "1.2.3", wingLinkBinary); got != want {
		t.Fatalf("current -> %s, want %s after rollback", got, want)
	}
	if got, want := linkTarget(t, filepath.Join(fixture.root, previousLinkName)), filepath.Join(versionsDirName, "1.2.2", wingLinkBinary); got != want {
		t.Fatalf("previous -> %s, want %s after rollback", got, want)
	}
	if *fixture.restartCalls != 1 || *fixture.healthCalls != 1 {
		t.Fatalf("restart = %d, health = %d, want 1 and 1", *fixture.restartCalls, *fixture.healthCalls)
	}
}

func TestApplyRollbackOnFirstActivationRemovesCurrentLink(t *testing.T) {
	fixture := newUpdateFixture(t)
	fixture.signCatalog(t, fixture.defaultCatalog(t))
	config := fixture.config("1.2.3", 2)
	config.HealthCheck = func(context.Context) error { return errInjectedHealth }
	updater, err := NewUpdater(config)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := updater.Apply(fixture.ctx); !errors.Is(err, ErrUpdateRolledBack) {
		t.Fatalf("Apply error = %v, want ErrUpdateRolledBack", err)
	}
	for _, name := range []string{currentLinkName, previousLinkName} {
		if _, err := os.Lstat(filepath.Join(fixture.root, name)); !errors.Is(err, fs.ErrNotExist) {
			t.Fatalf("%s after first-activation rollback = %v, want absent", name, err)
		}
	}
}

func TestApplyFailsClosedOnCorruptLayoutBeforeNetwork(t *testing.T) {
	fixture := newUpdateFixture(t)
	fixture.signCatalog(t, fixture.defaultCatalog(t))
	if err := os.WriteFile(filepath.Join(fixture.root, currentLinkName), []byte("regular file"), 0o600); err != nil {
		t.Fatal(err)
	}
	updater, err := NewUpdater(fixture.config("1.2.3", 2))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := updater.Apply(fixture.ctx); !errors.Is(err, ErrUpdateState) {
		t.Fatalf("Apply error = %v, want ErrUpdateState", err)
	}
	if *fixture.manifestHits != 0 || *fixture.fetchHits != 0 {
		t.Fatalf("network seams called on corrupt layout (manifest=%d fetch=%d)", *fixture.manifestHits, *fixture.fetchHits)
	}
}

func TestNewUpdaterValidatesConfiguration(t *testing.T) {
	fixture := newUpdateFixture(t)
	base := fixture.config("1.2.3", 2)

	invalid := []struct {
		name   string
		mutate func(config *Config)
	}{
		{"empty root", func(config *Config) { config.Root = " " }},
		{"invalid current version", func(config *Config) { config.CurrentVersion = "1.2" }},
		{"zero protocol generation", func(config *Config) { config.ProtocolGeneration = 0 }},
		{"missing manifest source", func(config *Config) { config.ManifestSource = nil }},
		{"missing restart", func(config *Config) { config.Restart = nil }},
		{"missing health check", func(config *Config) { config.HealthCheck = nil }},
	}
	for _, testCase := range invalid {
		config := base
		testCase.mutate(&config)
		if _, err := NewUpdater(config); !errors.Is(err, ErrUpdateConfig) {
			t.Fatalf("%s: NewUpdater error = %v, want ErrUpdateConfig", testCase.name, err)
		}
	}
}

func TestHTTPSFetcherRejectsPlaintextRedirectAndBadResponses(t *testing.T) {
	payload := []byte("signed linux artifact bytes")
	server := httptest.NewTLSServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		switch request.URL.Path {
		case "/artifact":
			writer.Header().Set("Content-Length", strconv.Itoa(len(payload)))
			_, _ = io.Copy(writer, bytes.NewReader(payload))
		case "/redirect":
			writer.Header().Set("Location", "https://example.invalid/artifact")
			writer.WriteHeader(http.StatusFound)
		case "/notfound":
			writer.WriteHeader(http.StatusNotFound)
		case "/wrong-length":
			writer.Header().Set("Content-Length", "4096")
			_, _ = io.Copy(writer, bytes.NewReader(payload))
		default:
			writer.WriteHeader(http.StatusNotFound)
		}
	}))
	defer server.Close()

	pool := x509.NewCertPool()
	pool.AddCert(server.Certificate())
	fetch := HTTPSArtifactFetcher(&http.Client{Transport: &http.Transport{TLSClientConfig: &tls.Config{
		MinVersion: tls.VersionTLS13,
		RootCAs:    pool,
	}}})
	ctx := context.Background()

	body, err := fetch(ctx, server.URL+"/artifact", int64(len(payload)))
	if err != nil {
		t.Fatal(err)
	}
	downloaded, err := io.ReadAll(body)
	_ = body.Close()
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(downloaded, payload) {
		t.Fatal("fetched artifact bytes mismatch")
	}

	plaintext := strings.Replace(server.URL, "https://", "http://", 1) + "/artifact"
	if _, err := fetch(ctx, plaintext, int64(len(payload))); !errors.Is(err, ErrArtifactVerification) {
		t.Fatalf("plaintext error = %v, want ErrArtifactVerification", err)
	}
	if _, err := fetch(ctx, server.URL+"/redirect", int64(len(payload))); !errors.Is(err, ErrArtifactVerification) {
		t.Fatalf("redirect error = %v, want ErrArtifactVerification", err)
	}
	if _, err := fetch(ctx, server.URL+"/notfound", int64(len(payload))); !errors.Is(err, ErrArtifactVerification) {
		t.Fatalf("not-found error = %v, want ErrArtifactVerification", err)
	}
	if _, err := fetch(ctx, server.URL+"/wrong-length", int64(len(payload))); !errors.Is(err, ErrArtifactVerification) {
		t.Fatalf("wrong-length error = %v, want ErrArtifactVerification", err)
	}
}

// fixtureArtifactBytes returns a deterministic payload so digest failures can
// reference the same bytes the fixture signed.
func fixtureArtifactBytes() []byte {
	return []byte("wing-link linux binary payload 1.2.4")
}

// errReader always fails, letting io.MultiReader simulate a body that dies
// mid-download after a partial read.
type errReader struct{ err error }

func (reader errReader) Read([]byte) (int, error) { return 0, reader.err }
