package state

// Path returns the configured owner-only state file location for internal service stores.
func (s *StateStore) Path() string {
	return s.path
}

// RandomSecret returns a URL-safe random secret with an optional prefix.
func RandomSecret(size int, prefix string) (string, error) {
	return randomSecret(size, prefix)
}

// HashSecret returns the stable digest used for secret comparisons.
func HashSecret(secret string) string {
	return hashSecret(secret)
}

// MatchesHash compares a secret with its expected digest in constant time.
func MatchesHash(secret, expected string) bool {
	return matchesHash(secret, expected)
}

// SecurePath applies owner-only permissions to a state path.
func SecurePath(path string, directory bool) error {
	return secureStatePath(path, directory)
}

// PathOwnerOnly reports whether a state path is owner-only.
func PathOwnerOnly(path string, directory bool) (bool, error) {
	return statePathOwnerOnly(path, directory)
}

// AcquireLock acquires the platform state-file lock.
func AcquireLock(path string) (func() error, error) {
	return acquireStateLock(path)
}

// ReplaceFile atomically replaces a state file where supported.
func ReplaceFile(source, destination string) error {
	return replaceStateFile(source, destination)
}

// SyncDirectory persists directory metadata where supported.
func SyncDirectory(path string) error {
	return syncStateDirectory(path)
}
