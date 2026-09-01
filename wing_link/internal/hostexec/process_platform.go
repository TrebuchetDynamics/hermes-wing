//go:build !windows

package hostexec

import (
	"os"
	"os/exec"
	"syscall"
)

func configureProcess(command *exec.Cmd) {
	command.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
}

func registerProcessTree(_ *os.Process) (func(), error) {
	return func() {}, nil
}

func killProcessTree(process *os.Process) error {
	return syscall.Kill(-process.Pid, syscall.SIGKILL)
}
