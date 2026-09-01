//go:build !windows

package state

import (
	"errors"
	"fmt"
	"os"
	"syscall"
)

func secureStatePath(path string, directory bool) error {
	mode := os.FileMode(0o600)
	if directory {
		mode = 0o700
	}
	return os.Chmod(path, mode)
}

func statePathOwnerOnly(path string, directory bool) (bool, error) {
	info, err := os.Stat(path)
	if err != nil {
		return false, err
	}
	mode := os.FileMode(0o600)
	if directory {
		mode = 0o700
	}
	return info.Mode().Perm() == mode, nil
}

func acquireStateLock(path string) (func() error, error) {
	pathInfo, statErr := os.Lstat(path)
	if statErr == nil && pathInfo.Mode()&os.ModeSymlink != 0 {
		return nil, errors.New("state lock must not be a symlink")
	}
	if statErr != nil && !os.IsNotExist(statErr) {
		return nil, statErr
	}
	file, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR|syscall.O_NOFOLLOW, 0o600)
	if err != nil {
		return nil, err
	}
	if pathInfo != nil {
		fileInfo, err := file.Stat()
		if err != nil || !os.SameFile(pathInfo, fileInfo) {
			_ = file.Close()
			if err != nil {
				return nil, err
			}
			return nil, errors.New("state lock changed while opening")
		}
	}
	if err := file.Chmod(0o600); err != nil {
		_ = file.Close()
		return nil, err
	}
	if err := syscall.Flock(int(file.Fd()), syscall.LOCK_EX); err != nil {
		_ = file.Close()
		return nil, err
	}
	return func() error {
		unlockErr := syscall.Flock(int(file.Fd()), syscall.LOCK_UN)
		return errors.Join(unlockErr, file.Close())
	}, nil
}

func replaceStateFile(source, destination string) error {
	return os.Rename(source, destination)
}

func syncStateDirectory(path string) error {
	dir, err := os.Open(path)
	if err != nil {
		return fmt.Errorf("open state directory: %w", err)
	}
	defer func() { _ = dir.Close() }()
	if err := dir.Sync(); err != nil && !errors.Is(err, syscall.EINVAL) && !errors.Is(err, syscall.ENOTSUP) {
		return fmt.Errorf("sync state directory: %w", err)
	}
	return nil
}
