//go:build windows

package state

import (
	"errors"
	"fmt"
	"os"
	"unsafe"

	"golang.org/x/sys/windows"
)

func secureStatePath(path string, directory bool) error {
	user, err := windows.GetCurrentProcessToken().GetTokenUser()
	if err != nil {
		return err
	}
	flags := ""
	if directory {
		flags = "OICI"
	}
	descriptor, err := windows.SecurityDescriptorFromString("D:P(A;" + flags + ";FA;;;" + user.User.Sid.String() + ")")
	if err != nil {
		return err
	}
	dacl, _, err := descriptor.DACL()
	if err != nil {
		return err
	}
	return windows.SetNamedSecurityInfo(
		path,
		windows.SE_FILE_OBJECT,
		windows.DACL_SECURITY_INFORMATION|windows.PROTECTED_DACL_SECURITY_INFORMATION,
		nil,
		nil,
		dacl,
		nil,
	)
}

func statePathOwnerOnly(path string, directory bool) (bool, error) {
	user, err := windows.GetCurrentProcessToken().GetTokenUser()
	if err != nil {
		return false, err
	}
	descriptor, err := windows.GetNamedSecurityInfo(
		path,
		windows.SE_FILE_OBJECT,
		windows.DACL_SECURITY_INFORMATION,
	)
	if err != nil {
		return false, err
	}
	control, _, err := descriptor.Control()
	if err != nil {
		return false, err
	}
	if control&windows.SE_DACL_PROTECTED == 0 {
		return false, nil
	}
	dacl, _, err := descriptor.DACL()
	if err != nil {
		return false, err
	}
	if dacl == nil || dacl.AceCount != 1 {
		return false, nil
	}
	var ace *windows.ACCESS_ALLOWED_ACE
	if err := windows.GetAce(dacl, 0, &ace); err != nil {
		return false, err
	}
	expectedFlags := byte(0)
	if directory {
		expectedFlags = windows.OBJECT_INHERIT_ACE | windows.CONTAINER_INHERIT_ACE
	}
	const fileAllAccess windows.ACCESS_MASK = windows.STANDARD_RIGHTS_REQUIRED | windows.SYNCHRONIZE | 0x1ff
	aceSID := (*windows.SID)(unsafe.Pointer(&ace.SidStart))
	return ace.Header.AceType == windows.ACCESS_ALLOWED_ACE_TYPE &&
		ace.Header.AceFlags == expectedFlags && ace.Mask == fileAllAccess &&
		windows.EqualSid(aceSID, user.User.Sid), nil
}

func acquireStateLock(path string) (func() error, error) {
	file, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0o600)
	if err != nil {
		return nil, err
	}
	if err := secureStatePath(path, false); err != nil {
		_ = file.Close()
		return nil, err
	}
	var overlapped windows.Overlapped
	if err := windows.LockFileEx(windows.Handle(file.Fd()), windows.LOCKFILE_EXCLUSIVE_LOCK, 0, 1, 0, &overlapped); err != nil {
		_ = file.Close()
		return nil, err
	}
	return func() error {
		unlockErr := windows.UnlockFileEx(windows.Handle(file.Fd()), 0, 1, 0, &overlapped)
		return errors.Join(unlockErr, file.Close())
	}, nil
}

func replaceStateFile(source, destination string) error {
	sourcePath, err := windows.UTF16PtrFromString(source)
	if err != nil {
		return err
	}
	destinationPath, err := windows.UTF16PtrFromString(destination)
	if err != nil {
		return err
	}
	if _, err := os.Stat(destination); errors.Is(err, os.ErrNotExist) {
		return windows.MoveFileEx(sourcePath, destinationPath, windows.MOVEFILE_WRITE_THROUGH)
	} else if err != nil {
		return err
	}
	replaceFile := windows.NewLazySystemDLL("kernel32.dll").NewProc("ReplaceFileW")
	replaced, _, callErr := replaceFile.Call(
		uintptr(unsafe.Pointer(destinationPath)),
		uintptr(unsafe.Pointer(sourcePath)),
		0,
		0,
		0,
		0,
	)
	if replaced == 0 {
		return fmt.Errorf("ReplaceFileW: %w", callErr)
	}
	return nil
}

func syncStateDirectory(string) error {
	return nil
}
