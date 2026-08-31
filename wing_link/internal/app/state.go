package app

import wingstate "github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/state"

type StateStore = wingstate.StateStore
type HostIdentity = wingstate.HostIdentity
type DeviceAuthorization = wingstate.DeviceAuthorization

const (
	ScopeSetupWrite       = wingstate.ScopeSetupWrite
	ScopeLifecycleWrite   = wingstate.ScopeLifecycleWrite
	ScopeHealthRead       = wingstate.ScopeHealthRead
	ScopeDiagnosticsRead  = wingstate.ScopeDiagnosticsRead
	ScopeProfilesRead     = wingstate.ScopeProfilesRead
	ScopeProfilesWrite    = wingstate.ScopeProfilesWrite
	ScopeProvidersRead    = wingstate.ScopeProvidersRead
	ScopeProvidersWrite   = wingstate.ScopeProvidersWrite
	ScopeDirectoriesRead  = wingstate.ScopeDirectoriesRead
	ScopeDeviceSelfRead   = wingstate.ScopeDeviceSelfRead
	ScopeDeviceSelfRevoke = wingstate.ScopeDeviceSelfRevoke
)

func newStateStore(path string) *StateStore {
	return wingstate.New(path)
}

func randomSecret(size int, prefix string) (string, error) {
	return wingstate.RandomSecret(size, prefix)
}

func hashSecret(secret string) string {
	return wingstate.HashSecret(secret)
}

func matchesHash(secret, expected string) bool {
	return wingstate.MatchesHash(secret, expected)
}

func secureStatePath(path string, directory bool) error {
	return wingstate.SecurePath(path, directory)
}

func statePathOwnerOnly(path string, directory bool) (bool, error) {
	return wingstate.PathOwnerOnly(path, directory)
}

func acquireStateLock(path string) (func() error, error) {
	return wingstate.AcquireLock(path)
}

func replaceStateFile(source, destination string) error {
	return wingstate.ReplaceFile(source, destination)
}

func syncStateDirectory(path string) error {
	return wingstate.SyncDirectory(path)
}
