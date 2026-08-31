//go:build android

package app

import (
	"context"
	"errors"
	"os"
	"syscall"
)

func startHermesGateway(
	ctx context.Context,
	executable string,
	home string,
	_ func(context.Context, ...string) error,
) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	spec, err := termuxHermesGatewaySpec(executable, home)
	if err != nil {
		return err
	}
	info, err := os.Lstat(spec.Path)
	if err != nil || !info.Mode().IsRegular() || info.Mode()&0o111 == 0 {
		return errors.New("Hermes gateway executable is unavailable")
	}
	logFile, err := prepareDetachedHermesGateway(spec)
	if err != nil {
		return err
	}
	defer func() { _ = logFile.Close() }()

	devNull, err := os.Open(os.DevNull)
	if err != nil {
		return errors.New("could not open detached gateway input")
	}
	defer func() { _ = devNull.Close() }()
	process, err := os.StartProcess(
		spec.Path,
		append([]string{spec.Path}, spec.Args...),
		&os.ProcAttr{
			Env:   environmentWithHermesHome(os.Environ(), spec.Home),
			Files: []*os.File{devNull, logFile, logFile},
			Sys:   &syscall.SysProcAttr{Setsid: true},
		},
	)
	if err != nil {
		return errors.New("could not start Hermes gateway")
	}
	if err := process.Release(); err != nil {
		return errors.New("could not detach Hermes gateway")
	}
	return nil
}

func restartHermesGateway(
	ctx context.Context,
	executable string,
	home string,
	run func(context.Context, ...string) error,
) error {
	if err := run(ctx, "gateway", "stop"); err != nil {
		return err
	}
	return startHermesGateway(ctx, executable, home, run)
}
