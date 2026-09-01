package release

import (
	"context"
	"crypto/ed25519"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"time"
)

// Updater errors are typed so routes can translate them into stable contract
// codes. Error messages never contain host paths, release URLs, or key
// material; only bounded reasons.
var (
	ErrUpdateUnavailable    = errors.New("wing link update unavailable")
	ErrInvalidVersion       = errors.New("wing link version invalid")
	ErrDowngrade            = errors.New("wing link update would downgrade")
	ErrReinstall            = errors.New("wing link update would reinstall the current version")
	ErrProtocolUnsupported  = errors.New("wing link update needs an unsupported protocol generation")
	ErrArtifactVerification = errors.New("wing link artifact verification failed")
	ErrUpdateState          = errors.New("wing link update state invalid")
	ErrUpdateRolledBack     = errors.New("wing link update rolled back")
	ErrRollbackFailed       = errors.New("wing link update rollback failed")
	ErrUpdateConfig         = errors.New("wing link updater configuration invalid")
)

const (
	// versionsDirName, currentLinkName, and previousLinkName define the update
	// layout under Config.Root:
	//
	//   <root>/versions/<version>/wing-link   staged, owner-only artifacts
	//   <root>/current                        symlink to the active artifact
	//   <root>/previous                       symlink to the last active artifact
	versionsDirName   = "versions"
	currentLinkName   = "current"
	previousLinkName  = "previous"
	wingLinkBinary    = "wing-link"
	maxStagedArtifact = 1 << 30 // 1 GiB hard ceiling for any signed Linux artifact

	// DefaultActivationTimeout bounds the restart plus health-check window
	// before the updater rolls an activation back.
	DefaultActivationTimeout = 90 * time.Second
)

// Version is a strict numeric semantic version: exactly three canonical
// non-negative integer components with no prefix, suffix, or metadata.
type Version struct {
	Major uint64
	Minor uint64
	Patch uint64
}

// ParseVersion parses "major.minor.patch" with numeric components only. It
// rejects anything the updater cannot compare strictly and numerically:
// missing or extra components, non-digits, leading zeros, signs, "v" prefixes,
// pre-release/build suffixes, and components that overflow 64 bits.
func ParseVersion(value string) (Version, error) {
	parts := strings.Split(value, ".")
	if len(parts) != 3 {
		return Version{}, fmt.Errorf("%w: %q is not major.minor.patch", ErrInvalidVersion, value)
	}
	var parsed Version
	for index, part := range parts {
		if !canonicalNumber(part) {
			return Version{}, fmt.Errorf("%w: component %q", ErrInvalidVersion, part)
		}
		number, err := strconv.ParseUint(part, 10, 64)
		if err != nil {
			return Version{}, fmt.Errorf("%w: component %q", ErrInvalidVersion, part)
		}
		switch index {
		case 0:
			parsed.Major = number
		case 1:
			parsed.Minor = number
		case 2:
			parsed.Patch = number
		}
	}
	return parsed, nil
}

func canonicalNumber(value string) bool {
	if value == "" {
		return false
	}
	if value != "0" && value[0] == '0' {
		return false
	}
	for i := 0; i < len(value); i++ {
		if value[i] < '0' || value[i] > '9' {
			return false
		}
	}
	return true
}

// Compare returns -1, 0, or 1 when v is older than, equal to, or newer than
// other, comparing major, then minor, then patch numerically.
func (v Version) Compare(other Version) int {
	for _, component := range [3]struct{ left, right uint64 }{
		{v.Major, other.Major},
		{v.Minor, other.Minor},
		{v.Patch, other.Patch},
	} {
		switch {
		case component.left < component.right:
			return -1
		case component.left > component.right:
			return 1
		}
	}
	return 0
}

func (v Version) String() string {
	return strconv.FormatUint(v.Major, 10) + "." + strconv.FormatUint(v.Minor, 10) + "." + strconv.FormatUint(v.Patch, 10)
}

// ManifestSource returns the signed component manifest bytes and their
// detached signature. Production implementations fetch both over verified
// HTTPS; tests inject fixtures.
type ManifestSource func(ctx context.Context) (manifest, signature []byte, err error)

// ArtifactFetcher opens the release artifact body for a URL with a declared
// exact size. Implementations must refuse non-HTTPS schemes and redirects and
// must never return more bytes than a bounded read of the declared size.
type ArtifactFetcher func(ctx context.Context, artifactURL string, declaredSize int64) (io.ReadCloser, error)

// RestartFunc restarts the Wing Link service onto the active target. It is an
// injected seam so the updater core stays dependency-free and testable.
type RestartFunc func(ctx context.Context) error

// HealthCheckFunc probes the restarted service (loopback in production) and
// returns nil only when the new generation is serving.
type HealthCheckFunc func(ctx context.Context) error

// Config wires the updater. All functions are injected seams; TrustedKeys is
// the production (or test) release-key map and may legitimately be empty, in
// which case Apply fails closed before any network access.
type Config struct {
	Root               string
	CurrentVersion     string
	ProtocolGeneration int
	TrustedKeys        map[string]ed25519.PublicKey
	ManifestSource     ManifestSource
	FetchArtifact      ArtifactFetcher
	HTTPClient         *http.Client
	Restart            RestartFunc
	HealthCheck        HealthCheckFunc
	ActivationTimeout  time.Duration
}

type Updater struct {
	config        Config
	syncDirectory func(string) error
}

// NewUpdater validates the static configuration. An empty trusted release-key
// map is accepted here so status surfaces can report "unavailable"; Apply is
// the fail-closed gate.
func NewUpdater(config Config) (*Updater, error) {
	if strings.TrimSpace(config.Root) == "" {
		return nil, fmt.Errorf("%w: root is required", ErrUpdateConfig)
	}
	if _, err := ParseVersion(config.CurrentVersion); err != nil {
		return nil, fmt.Errorf("%w: current version: %v", ErrUpdateConfig, err)
	}
	if config.ProtocolGeneration < 1 {
		return nil, fmt.Errorf("%w: protocol generation must be positive", ErrUpdateConfig)
	}
	if config.ManifestSource == nil {
		return nil, fmt.Errorf("%w: manifest source is required", ErrUpdateConfig)
	}
	if config.Restart == nil {
		return nil, fmt.Errorf("%w: restart is required", ErrUpdateConfig)
	}
	if config.HealthCheck == nil {
		return nil, fmt.Errorf("%w: health check is required", ErrUpdateConfig)
	}
	if config.FetchArtifact == nil {
		config.FetchArtifact = HTTPSArtifactFetcher(config.HTTPClient)
	}
	if config.ActivationTimeout <= 0 {
		config.ActivationTimeout = DefaultActivationTimeout
	}
	return &Updater{config: config, syncDirectory: syncDirectory}, nil
}

// ApplyResult reports a successful update.
type ApplyResult struct {
	FromVersion string
	ToVersion   string
	StagedPath  string
}

// Apply verifies a signed catalog against the trusted release keys, refuses
// downgrades, reinstalls, and future protocol generations, stages the Linux
// artifact into an owner-only versioned path with exact size and SHA-256
// verification, atomically switches the current/previous symlinks, restarts,
// health-checks, and rolls the symlinks back when either injected step fails.
//
// It fails closed with ErrUpdateUnavailable before any network access when the
// trusted release-key map is empty: an unconfigured key set makes updates
// unavailable, never insecure.
func (u *Updater) Apply(ctx context.Context) (ApplyResult, error) {
	if len(u.config.TrustedKeys) == 0 {
		return ApplyResult{}, ErrUpdateUnavailable
	}
	// Validate the on-disk layout before touching the network so a corrupt
	// update root never triggers a download.
	previousTarget, err := u.existingTarget(previousLinkName)
	if err != nil {
		return ApplyResult{}, err
	}
	currentTarget, err := u.existingTarget(currentLinkName)
	if err != nil {
		return ApplyResult{}, err
	}

	manifest, signature, err := u.config.ManifestSource(ctx)
	if err != nil {
		return ApplyResult{}, fmt.Errorf("wing link update manifest: %w", err)
	}
	catalog, err := VerifyComponentManifest(manifest, signature, u.config.TrustedKeys)
	if err != nil {
		return ApplyResult{}, err
	}
	if catalog.WingLink == nil {
		return ApplyResult{}, ErrUpdateUnavailable
	}
	component := catalog.WingLink

	current, err := ParseVersion(u.config.CurrentVersion)
	if err != nil {
		return ApplyResult{}, err
	}
	target, err := ParseVersion(component.Version)
	if err != nil {
		return ApplyResult{}, err
	}
	switch target.Compare(current) {
	case -1:
		return ApplyResult{}, fmt.Errorf("%w: %s is older than %s", ErrDowngrade, target, current)
	case 0:
		return ApplyResult{}, fmt.Errorf("%w: %s", ErrReinstall, current)
	}
	if component.MinimumProtocolGeneration > u.config.ProtocolGeneration {
		return ApplyResult{}, fmt.Errorf("%w: artifact requires generation %d, host speaks at most %d", ErrProtocolUnsupported, component.MinimumProtocolGeneration, u.config.ProtocolGeneration)
	}
	if err := validateLinuxArtifact(component.Linux); err != nil {
		return ApplyResult{}, err
	}

	stagedPath, err := u.stage(ctx, target, component.Linux)
	if err != nil {
		return ApplyResult{}, err
	}
	if err := verifyStagedArtifact(stagedPath, component.Linux); err != nil {
		return ApplyResult{}, err
	}
	activationCtx, cancel := context.WithTimeout(ctx, u.config.ActivationTimeout)
	defer cancel()
	if err := u.activate(activationCtx, stagedPath, currentTarget, previousTarget); err != nil {
		return ApplyResult{}, err
	}
	return ApplyResult{
		FromVersion: current.String(),
		ToVersion:   target.String(),
		StagedPath:  stagedPath,
	}, nil
}

// validateLinuxArtifact enforces the signed Wing Link Linux artifact contract:
// exact positive bounded size, lowercase-or-uppercase 64-hex SHA-256, and a
// plain absolute HTTPS URL without credentials, query, or fragment.
func validateLinuxArtifact(artifact Artifact) error {
	if artifact.Size <= 0 || artifact.Size > maxStagedArtifact {
		return fmt.Errorf("%w: artifact size", ErrArtifactVerification)
	}
	digest := strings.ToLower(strings.TrimSpace(artifact.SHA256))
	if len(digest) != sha256.Size*2 || !isHex(digest) {
		return fmt.Errorf("%w: artifact sha256", ErrArtifactVerification)
	}
	parsed, err := url.Parse(artifact.URL)
	if err != nil || parsed.Scheme != "https" || parsed.User != nil || parsed.Host == "" || parsed.RawQuery != "" || parsed.Fragment != "" || parsed.Path == "" {
		return fmt.Errorf("%w: artifact URL", ErrArtifactVerification)
	}
	return nil
}

func isHex(value string) bool {
	for i := 0; i < len(value); i++ {
		c := value[i]
		if (c < '0' || c > '9') && (c < 'a' || c > 'f') {
			return false
		}
	}
	return true
}

// stage downloads the artifact through the injected fetcher into an
// owner-only versioned directory, verifies the exact size and SHA-256, fsyncs
// the file, and renames it into place before syncing the directory.
func (u *Updater) stage(ctx context.Context, version Version, artifact Artifact) (string, error) {
	if err := ensureOwnerOnlyDirectory(u.config.Root); err != nil {
		return "", err
	}
	versionsRoot := filepath.Join(u.config.Root, versionsDirName)
	if err := ensureOwnerOnlyDirectory(versionsRoot); err != nil {
		return "", err
	}
	versionDir := filepath.Join(versionsRoot, version.String())
	if err := ensureOwnerOnlyDirectory(versionDir); err != nil {
		return "", err
	}

	body, err := u.config.FetchArtifact(ctx, artifact.URL, artifact.Size)
	if err != nil {
		return "", err
	}
	defer func() { _ = body.Close() }()

	temporary, err := os.CreateTemp(versionDir, ".stage-*")
	if err != nil {
		return "", err
	}
	temporaryPath := temporary.Name()
	committed := false
	defer func() {
		if !committed {
			_ = temporary.Close()
			_ = os.Remove(temporaryPath)
		}
	}()
	if err := temporary.Chmod(0o700); err != nil {
		return "", err
	}
	digest := sha256.New()
	written, copyErr := io.Copy(io.MultiWriter(temporary, digest), io.LimitReader(body, artifact.Size+1))
	if copyErr != nil {
		return "", fmt.Errorf("%w: interrupted download", ErrArtifactVerification)
	}
	if written != artifact.Size {
		return "", fmt.Errorf("%w: size mismatch", ErrArtifactVerification)
	}
	actual := hex.EncodeToString(digest.Sum(nil))
	expected := strings.ToLower(strings.TrimSpace(artifact.SHA256))
	if subtle.ConstantTimeCompare([]byte(actual), []byte(expected)) != 1 {
		return "", fmt.Errorf("%w: digest mismatch", ErrArtifactVerification)
	}
	if err := temporary.Sync(); err != nil {
		return "", err
	}
	if err := temporary.Close(); err != nil {
		return "", err
	}
	stagedPath := filepath.Join(versionDir, wingLinkBinary)
	if err := os.Rename(temporaryPath, stagedPath); err != nil {
		return "", err
	}
	committed = true
	if err := syncDirectory(versionDir); err != nil {
		return "", err
	}
	return stagedPath, nil
}

func verifyStagedArtifact(path string, artifact Artifact) error {
	info, err := os.Lstat(path)
	if err != nil || !info.Mode().IsRegular() || info.Mode().Perm()&0o077 != 0 || info.Size() != artifact.Size {
		return fmt.Errorf("%w: staged artifact changed", ErrArtifactVerification)
	}
	file, err := os.Open(path)
	if err != nil {
		return fmt.Errorf("%w: staged artifact unavailable", ErrArtifactVerification)
	}
	defer func() { _ = file.Close() }()
	digest := sha256.New()
	written, err := io.Copy(digest, io.LimitReader(file, artifact.Size+1))
	if err != nil || written != artifact.Size {
		return fmt.Errorf("%w: staged artifact size", ErrArtifactVerification)
	}
	actual := hex.EncodeToString(digest.Sum(nil))
	expected := strings.ToLower(strings.TrimSpace(artifact.SHA256))
	if subtle.ConstantTimeCompare([]byte(actual), []byte(expected)) != 1 {
		return fmt.Errorf("%w: staged artifact digest", ErrArtifactVerification)
	}
	return nil
}

// activate atomically repoints the current symlink at the staged artifact,
// records the previous one, fsyncs the update root, then restarts and
// health-checks through the injected seams. Any restart or health failure
// restores both symlinks to their pre-activation targets.
func (u *Updater) activate(ctx context.Context, stagedPath, currentTarget, previousTarget string) error {
	relative, err := filepath.Rel(u.config.Root, stagedPath)
	if err != nil {
		return err
	}
	if err := replaceSymlink(u.config.Root, currentLinkName, relative); err != nil {
		return err
	}
	if currentTarget != "" {
		if err := replaceSymlink(u.config.Root, previousLinkName, currentTarget); err != nil {
			return errors.Join(fmt.Errorf("%w: previous link", ErrRollbackFailed), u.restoreLinks(currentTarget, previousTarget))
		}
	}
	if err := u.syncDirectory(u.config.Root); err != nil {
		if rollbackErr := u.restoreLinks(currentTarget, previousTarget); rollbackErr != nil {
			return errors.Join(fmt.Errorf("%w: sync activation: %w", ErrRollbackFailed, err), rollbackErr)
		}
		return fmt.Errorf("%w: sync activation: %w", ErrUpdateRolledBack, err)
	}

	var outcome error
	if err := u.config.Restart(ctx); err != nil {
		outcome = fmt.Errorf("restart: %w", err)
	} else if err := u.config.HealthCheck(ctx); err != nil {
		outcome = fmt.Errorf("health check: %w", err)
	}
	if outcome == nil {
		return nil
	}
	if rollbackErr := u.restoreLinks(currentTarget, previousTarget); rollbackErr != nil {
		return errors.Join(fmt.Errorf("%w: %w", ErrRollbackFailed, outcome), rollbackErr)
	}
	return fmt.Errorf("%w: %w", ErrUpdateRolledBack, outcome)
}

// restoreLinks returns current and previous to their recorded targets,
// removing them entirely when they did not exist before activation.
func (u *Updater) restoreLinks(currentTarget, previousTarget string) error {
	var failures []error
	if currentTarget == "" {
		if err := removePath(filepath.Join(u.config.Root, currentLinkName)); err != nil {
			failures = append(failures, err)
		}
	} else if err := replaceSymlink(u.config.Root, currentLinkName, currentTarget); err != nil {
		failures = append(failures, err)
	}
	if previousTarget == "" {
		if err := removePath(filepath.Join(u.config.Root, previousLinkName)); err != nil {
			failures = append(failures, err)
		}
	} else if err := replaceSymlink(u.config.Root, previousLinkName, previousTarget); err != nil {
		failures = append(failures, err)
	}
	if len(failures) > 0 {
		return errors.Join(failures...)
	}
	return u.syncDirectory(u.config.Root)
}

// existingTarget returns the symlink target of a layout entry, the empty
// string when it does not exist, or ErrUpdateState when the entry exists but
// is not a symlink.
func (u *Updater) existingTarget(name string) (string, error) {
	path := filepath.Join(u.config.Root, name)
	info, err := os.Lstat(path)
	if errors.Is(err, fs.ErrNotExist) {
		return "", nil
	}
	if err != nil {
		return "", err
	}
	if info.Mode()&os.ModeSymlink == 0 {
		return "", fmt.Errorf("%w: %q is not a symlink", ErrUpdateState, name)
	}
	target, err := os.Readlink(path)
	if err != nil {
		return "", err
	}
	clean := filepath.Clean(target)
	parts := strings.Split(filepath.ToSlash(clean), "/")
	if filepath.IsAbs(target) || clean != target || len(parts) != 3 || parts[0] != versionsDirName || parts[2] != wingLinkBinary {
		return "", fmt.Errorf("%w: %q target is outside versioned releases", ErrUpdateState, name)
	}
	if _, err := ParseVersion(parts[1]); err != nil {
		return "", fmt.Errorf("%w: %q target version is invalid", ErrUpdateState, name)
	}
	return target, nil
}

func ensureOwnerOnlyDirectory(path string) error {
	if err := rejectSymlinkedAncestors(path); err != nil {
		return err
	}
	if info, err := os.Lstat(path); err == nil {
		if !info.IsDir() {
			return fmt.Errorf("%w: staging path is not a directory", ErrUpdateState)
		}
	} else if !errors.Is(err, fs.ErrNotExist) {
		return err
	}
	if err := os.MkdirAll(path, 0o700); err != nil {
		return err
	}
	if err := rejectSymlinkedAncestors(path); err != nil {
		return err
	}
	info, err := os.Lstat(path)
	if err != nil {
		return err
	}
	if !info.IsDir() {
		return fmt.Errorf("%w: staging path is not a directory", ErrUpdateState)
	}
	return os.Chmod(path, 0o700)
}

func rejectSymlinkedAncestors(path string) error {
	current := filepath.Clean(path)
	for {
		info, err := os.Lstat(current)
		if err == nil {
			if info.Mode()&os.ModeSymlink != 0 {
				return fmt.Errorf("%w: staging path contains a symlink", ErrUpdateState)
			}
		} else if !errors.Is(err, fs.ErrNotExist) {
			return err
		}
		parent := filepath.Dir(current)
		if parent == current {
			return nil
		}
		current = parent
	}
}

// replaceSymlink atomically points name at target by renaming a fresh
// temporary symlink over it.
func replaceSymlink(directory, name, target string) error {
	suffix := make([]byte, 8)
	if _, err := rand.Read(suffix); err != nil {
		return err
	}
	temporary := filepath.Join(directory, "."+name+".tmp-"+hex.EncodeToString(suffix))
	if err := os.Symlink(target, temporary); err != nil {
		return err
	}
	if err := os.Rename(temporary, filepath.Join(directory, name)); err != nil {
		_ = os.Remove(temporary)
		return err
	}
	return nil
}

func removePath(path string) error {
	if err := os.Remove(path); err != nil && !errors.Is(err, fs.ErrNotExist) {
		return err
	}
	return nil
}

// syncDirectory flushes directory metadata changes (renames, symlink
// replacement) to stable storage. Filesystems that cannot fsync directories
// report unsupported or invalid-argument, which is not an update failure.
func syncDirectory(path string) error {
	directory, err := os.Open(path)
	if err != nil {
		return fmt.Errorf("open update directory: %w", err)
	}
	defer func() { _ = directory.Close() }()
	if err := directory.Sync(); err != nil && !errors.Is(err, errors.ErrUnsupported) && !errors.Is(err, syscall.EINVAL) {
		return fmt.Errorf("sync update directory: %w", err)
	}
	return nil
}

// HTTPSArtifactFetcher returns an ArtifactFetcher that downloads over HTTPS
// only, refuses every redirect, requires an exact 200 response, and rejects a
// declared content length that disagrees with the signed artifact size before
// any body byte is read.
func HTTPSArtifactFetcher(client *http.Client) ArtifactFetcher {
	return func(ctx context.Context, artifactURL string, declaredSize int64) (io.ReadCloser, error) {
		if declaredSize <= 0 {
			return nil, fmt.Errorf("%w: artifact size", ErrArtifactVerification)
		}
		parsed, err := url.Parse(artifactURL)
		if err != nil || parsed.Scheme != "https" || parsed.User != nil || parsed.Host == "" || parsed.RawQuery != "" || parsed.Fragment != "" {
			return nil, fmt.Errorf("%w: artifact URL", ErrArtifactVerification)
		}
		noRedirects := client
		if noRedirects == nil {
			noRedirects = &http.Client{}
		}
		bounded := *noRedirects
		bounded.CheckRedirect = func(*http.Request, []*http.Request) error {
			return errors.New("wing link artifact redirect refused")
		}
		request, err := http.NewRequestWithContext(ctx, http.MethodGet, parsed.String(), nil)
		if err != nil {
			return nil, fmt.Errorf("%w: request", ErrArtifactVerification)
		}
		response, err := bounded.Do(request)
		if err != nil {
			return nil, fmt.Errorf("%w: fetch", ErrArtifactVerification)
		}
		if response.StatusCode != http.StatusOK {
			_ = response.Body.Close()
			return nil, fmt.Errorf("%w: status %d", ErrArtifactVerification, response.StatusCode)
		}
		if response.ContentLength >= 0 && response.ContentLength != declaredSize {
			_ = response.Body.Close()
			return nil, fmt.Errorf("%w: content length", ErrArtifactVerification)
		}
		return response.Body, nil
	}
}
