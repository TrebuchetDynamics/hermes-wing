package app

import (
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
)

const (
	localPairingProofFile   = "wing-link-local-pairing.key"
	localPairingProofHeader = "X-Wing-Link-Local-Proof"
	maxLocalPairingProof    = 128
)

var localPairingProofPattern = regexp.MustCompile(`^wlp_[A-Za-z0-9_-]{43}$`)

func localPairingProofPath(statePath string) string {
	return filepath.Join(filepath.Dir(statePath), localPairingProofFile)
}

func ensureLocalPairingProof(statePath string) (string, error) {
	path := localPairingProofPath(statePath)
	directory := filepath.Dir(path)
	if err := rejectSymlinkedAncestors(directory); err != nil {
		return "", errors.New("local pairing authority directory is unsafe")
	}
	if err := os.MkdirAll(directory, 0o700); err != nil {
		return "", errors.New("could not create local pairing authority directory")
	}
	if info, err := os.Lstat(directory); err != nil || !info.IsDir() || info.Mode()&os.ModeSymlink != 0 {
		return "", errors.New("local pairing authority directory is unsafe")
	}
	if err := secureStatePath(directory, true); err != nil {
		return "", errors.New("could not secure local pairing authority directory")
	}
	ownerOnly, err := statePathOwnerOnly(directory, true)
	if err != nil || !ownerOnly {
		return "", errors.New("local pairing authority directory is not owner-only")
	}

	lockPath := path + ".lock"
	if info, lockErr := os.Lstat(lockPath); lockErr == nil {
		if !info.Mode().IsRegular() || info.Mode()&os.ModeSymlink != 0 {
			return "", errors.New("local pairing authority lock is unsafe")
		}
	} else if !errors.Is(lockErr, os.ErrNotExist) {
		return "", errors.New("could not inspect local pairing authority lock")
	}
	unlock, err := acquireStateLock(lockPath)
	if err != nil {
		return "", errors.New("could not lock local pairing authority")
	}
	defer func() { _ = unlock() }()

	if proof, err := loadLocalPairingProofPath(path); err == nil {
		return proof, nil
	} else if !errors.Is(err, os.ErrNotExist) {
		return "", err
	}
	proof, err := randomSecret(32, "wlp_")
	if err != nil || !validLocalPairingProof(proof) {
		return "", errors.New("could not generate local pairing authority")
	}
	temporary, err := os.CreateTemp(directory, ".local-pairing-*")
	if err != nil {
		return "", errors.New("could not stage local pairing authority")
	}
	temporaryPath := temporary.Name()
	defer func() { _ = os.Remove(temporaryPath) }()
	if err := secureStatePath(temporaryPath, false); err != nil {
		_ = temporary.Close()
		return "", errors.New("could not secure local pairing authority")
	}
	if _, err := io.WriteString(temporary, proof); err != nil {
		_ = temporary.Close()
		return "", errors.New("could not write local pairing authority")
	}
	if err := temporary.Sync(); err != nil {
		_ = temporary.Close()
		return "", errors.New("could not sync local pairing authority")
	}
	if err := temporary.Close(); err != nil {
		return "", errors.New("could not close local pairing authority")
	}
	if err := replaceStateFile(temporaryPath, path); err != nil {
		return "", errors.New("could not install local pairing authority")
	}
	if err := syncStateDirectory(directory); err != nil {
		return "", errors.New("could not sync local pairing authority directory")
	}
	return loadLocalPairingProofPath(path)
}

func loadLocalPairingProof(statePath string) (string, error) {
	return loadLocalPairingProofPath(localPairingProofPath(statePath))
}

func loadLocalPairingProofPath(path string) (string, error) {
	info, err := os.Lstat(path)
	if err != nil {
		return "", err
	}
	if !info.Mode().IsRegular() || info.Mode()&os.ModeSymlink != 0 || info.Size() < 1 || info.Size() > maxLocalPairingProof {
		return "", errors.New("local pairing authority is unsafe")
	}
	ownerOnly, err := statePathOwnerOnly(path, false)
	if err != nil || !ownerOnly {
		return "", errors.New("local pairing authority is not owner-only")
	}
	file, err := os.Open(path)
	if err != nil {
		return "", errors.New("could not open local pairing authority")
	}
	defer func() { _ = file.Close() }()
	payload, err := io.ReadAll(io.LimitReader(file, maxLocalPairingProof+1))
	if err != nil || len(payload) > maxLocalPairingProof {
		return "", errors.New("could not read local pairing authority")
	}
	proof := string(payload)
	if !validLocalPairingProof(proof) {
		return "", fmt.Errorf("local pairing authority is malformed")
	}
	return proof, nil
}

func validLocalPairingProof(proof string) bool {
	return localPairingProofPattern.MatchString(proof)
}
