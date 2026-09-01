package app

import (
	"errors"
	"os"
	"path/filepath"
	"strings"
)

const (
	termuxPrefix = "/data/data/com.termux/files/usr"
	termuxHome   = "/data/data/com.termux/files/home"
)

type detachedHermesGatewaySpec struct {
	Path    string
	Args    []string
	Home    string
	LogPath string
}

func termuxHermesGatewaySpec(executable, home string) (detachedHermesGatewaySpec, error) {
	if err := validateTermuxHermesGatewayShape(executable, home); err != nil {
		return detachedHermesGatewaySpec{}, err
	}
	executable = filepath.Clean(strings.TrimSpace(executable))
	home = filepath.Clean(strings.TrimSpace(home))
	if !filepath.IsAbs(executable) || !filepath.IsAbs(home) {
		return detachedHermesGatewaySpec{}, errors.New("hermes gateway paths must be absolute")
	}
	logPath := filepath.Join(home, "logs", "gateway.log")
	if !pathWithin(home, logPath) {
		return detachedHermesGatewaySpec{}, errors.New("hermes gateway log escaped its home")
	}
	return detachedHermesGatewaySpec{
		Path: executable, Args: []string{"gateway"}, Home: home, LogPath: logPath,
	}, nil
}

func validateTermuxHermesGatewayShape(executable, home string) error {
	if filepath.Clean(strings.TrimSpace(os.Getenv("PREFIX"))) != termuxPrefix ||
		filepath.Clean(strings.TrimSpace(os.Getenv("HOME"))) != termuxHome ||
		filepath.Clean(strings.TrimSpace(executable)) != filepath.Join(termuxPrefix, "bin", "hermes") ||
		filepath.Clean(strings.TrimSpace(home)) != filepath.Join(termuxHome, ".hermes") {
		return errors.New("hermes gateway requires canonical Termux paths")
	}
	return nil
}

func prepareDetachedHermesGateway(spec detachedHermesGatewaySpec) (*os.File, error) {
	logDir := filepath.Dir(spec.LogPath)
	if info, err := os.Lstat(logDir); err == nil {
		if !info.IsDir() || info.Mode()&os.ModeSymlink != 0 {
			return nil, errors.New("hermes gateway log directory is unsafe")
		}
	} else if !errors.Is(err, os.ErrNotExist) {
		return nil, errors.New("could not inspect Hermes gateway log directory")
	}
	if err := os.MkdirAll(logDir, 0o700); err != nil {
		return nil, errors.New("could not create Hermes gateway log directory")
	}
	if err := os.Chmod(logDir, 0o700); err != nil {
		return nil, errors.New("could not secure Hermes gateway log directory")
	}
	if info, err := os.Lstat(spec.LogPath); err == nil {
		if !info.Mode().IsRegular() || info.Mode()&os.ModeSymlink != 0 {
			return nil, errors.New("hermes gateway log is unsafe")
		}
	} else if !errors.Is(err, os.ErrNotExist) {
		return nil, errors.New("could not inspect Hermes gateway log")
	}
	logFile, err := os.OpenFile(spec.LogPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o600)
	if err != nil {
		return nil, errors.New("could not open Hermes gateway log")
	}
	if err := logFile.Chmod(0o600); err != nil {
		_ = logFile.Close()
		return nil, errors.New("could not secure Hermes gateway log")
	}
	return logFile, nil
}

func environmentWithHermesHome(environment []string, home string) []string {
	result := make([]string, 0, len(environment)+1)
	for _, entry := range environment {
		if !strings.HasPrefix(entry, "HERMES_HOME=") {
			result = append(result, entry)
		}
	}
	return append(result, "HERMES_HOME="+home)
}

func resolveInstallerShell(platform string) string {
	if platform == "android" {
		return filepath.Join(strings.TrimSpace(os.Getenv("PREFIX")), "bin", "bash")
	}
	return "/bin/bash"
}

func validateInstallerShell(platform, shell string) error {
	if platform != "android" {
		return nil
	}
	if filepath.Clean(strings.TrimSpace(os.Getenv("PREFIX"))) != termuxPrefix ||
		filepath.Clean(shell) != filepath.Join(termuxPrefix, "bin", "bash") {
		return errors.New("hermes installer requires the canonical Termux prefix")
	}
	info, err := os.Lstat(shell)
	if err != nil || !info.Mode().IsRegular() || info.Mode()&0o111 == 0 {
		return errors.New("hermes installer shell is unavailable")
	}
	return nil
}
