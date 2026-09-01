//go:build linux && !android

package app

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/release"
)

const wingLinkServiceName = "hermes-wing-link.service"

func EnsureWingLinkService(controlOrigin, hermesOrigin *url.URL) error {
	if strings.EqualFold(strings.TrimSpace(os.Getenv("WING_LINK_SERVICE")), "external") {
		return ensureExternalWingLinkService(controlOrigin)
	}
	systemctl, err := exec.LookPath("systemctl")
	if err != nil {
		return errors.New("systemd user services are unavailable; set WING_LINK_SERVICE=external only for an already managed service")
	}
	binary, err := installServiceBinary()
	if err != nil {
		return err
	}
	configDir, err := os.UserConfigDir()
	if err != nil {
		return errors.New("could not locate the user configuration directory")
	}
	unitDir := filepath.Join(configDir, "systemd", "user")
	if err := os.MkdirAll(unitDir, 0o700); err != nil {
		return errors.New("could not create the user service directory")
	}
	statePath, err := resolveWingLinkStatePath()
	if err != nil {
		return err
	}
	hermesHome, err := resolveHermesHome()
	if err != nil {
		return err
	}
	unit := wingLinkSystemdUnit(
		binary,
		controlOrigin.Host,
		hermesOrigin.String(),
		os.Getenv("PATH"),
		statePath,
		hermesHome,
	)
	unitPath := filepath.Join(unitDir, wingLinkServiceName)
	if err := writeOwnerOnlyFile(unitPath, []byte(unit)); err != nil {
		return errors.New("could not install the Wing Link user service")
	}
	if err := runSystemctl(systemctl, "daemon-reload"); err != nil {
		return err
	}
	if err := runSystemctl(systemctl, "enable", "--now", wingLinkServiceName); err != nil {
		return err
	}
	if err := runSystemctl(systemctl, "restart", wingLinkServiceName); err != nil {
		return err
	}
	return verifyWingLinkHealth(loopbackControlOrigin(controlOrigin))
}

func WingLinkServiceCommand(command string, stdout io.Writer) error {
	systemctl, err := exec.LookPath("systemctl")
	if err != nil {
		return errors.New("systemd user services are unavailable")
	}
	switch command {
	case "start", "restart":
		if err := runSystemctl(systemctl, command, wingLinkServiceName); err != nil {
			return err
		}
		origin, _ := url.Parse("http://127.0.0.1:8654")
		return verifyWingLinkHealth(origin)
	case "stop":
		return runSystemctl(systemctl, command, wingLinkServiceName)
	case "status":
		state := ""
		result := runProcess(context.Background(), CommandSpec{
			Path: systemctl, Args: []string{"--user", "is-active", wingLinkServiceName},
			Timeout: 10 * time.Second,
		}, func(line string) { state = strings.TrimSpace(line) })
		if state == "" {
			state = "inactive"
		}
		_, _ = fmt.Fprintln(stdout, state)
		return result.Err
	default:
		return errors.New("unsupported service command")
	}
}

func installServiceBinary() (string, error) {
	executable, err := os.Executable()
	if err != nil {
		return "", errors.New("could not locate the Wing Link executable")
	}
	userHome, err := os.UserHomeDir()
	if err != nil {
		return "", errors.New("could not locate the user home")
	}
	releaseVersion := version
	if _, err := release.ParseVersion(releaseVersion); err != nil {
		releaseVersion = "0.0.0"
	}
	releasesRoot := filepath.Join(userHome, ".local", "lib", "hermes-wing", "releases")
	destination := filepath.Join(releasesRoot, "versions", releaseVersion, "wing-link")
	current := filepath.Join(releasesRoot, "current")
	if filepath.Clean(executable) == destination {
		if err := installCurrentServiceTarget(releasesRoot, releaseVersion); err != nil {
			return "", err
		}
		return current, nil
	}
	if err := os.MkdirAll(filepath.Dir(destination), 0o700); err != nil {
		return "", errors.New("could not create the Wing Link service directory")
	}
	source, err := os.Open(executable)
	if err != nil {
		return "", errors.New("could not open the Wing Link executable")
	}
	defer func() { _ = source.Close() }()
	temp, err := os.CreateTemp(filepath.Dir(destination), ".wing-link-*")
	if err != nil {
		return "", errors.New("could not stage the Wing Link service executable")
	}
	tempPath := temp.Name()
	defer func() { _ = os.Remove(tempPath) }()
	if err := temp.Chmod(0o700); err != nil {
		_ = temp.Close()
		return "", errors.New("could not secure the Wing Link service executable")
	}
	if _, err := io.Copy(temp, source); err != nil {
		_ = temp.Close()
		return "", errors.New("could not copy the Wing Link service executable")
	}
	if err := temp.Sync(); err != nil {
		_ = temp.Close()
		return "", errors.New("could not sync the Wing Link service executable")
	}
	if err := temp.Close(); err != nil {
		return "", errors.New("could not close the Wing Link service executable")
	}
	if err := os.Rename(tempPath, destination); err != nil {
		return "", errors.New("could not install the Wing Link service executable")
	}
	if err := installCurrentServiceTarget(releasesRoot, releaseVersion); err != nil {
		return "", err
	}
	return current, nil
}

func installCurrentServiceTarget(releasesRoot, releaseVersion string) error {
	if err := os.MkdirAll(releasesRoot, 0o700); err != nil {
		return errors.New("could not create the Wing Link releases directory")
	}
	temporary := filepath.Join(releasesRoot, ".current.tmp")
	_ = os.Remove(temporary)
	target := filepath.Join("versions", releaseVersion, "wing-link")
	if err := os.Symlink(target, temporary); err != nil {
		return errors.New("could not stage the Wing Link service target")
	}
	if err := os.Rename(temporary, filepath.Join(releasesRoot, "current")); err != nil {
		_ = os.Remove(temporary)
		return errors.New("could not activate the Wing Link service target")
	}
	return nil
}

func writeOwnerOnlyFile(path string, payload []byte) error {
	temp, err := os.CreateTemp(filepath.Dir(path), ".unit-*")
	if err != nil {
		return err
	}
	tempPath := temp.Name()
	defer func() { _ = os.Remove(tempPath) }()
	if err := temp.Chmod(0o600); err != nil {
		_ = temp.Close()
		return err
	}
	if _, err := temp.Write(payload); err != nil {
		_ = temp.Close()
		return err
	}
	if err := temp.Close(); err != nil {
		return err
	}
	return os.Rename(tempPath, path)
}

func runSystemctl(path string, args ...string) error {
	result := runProcess(context.Background(), CommandSpec{
		Path: path, Args: append([]string{"--user"}, args...), Timeout: 30 * time.Second,
	}, nil)
	if result.Err != nil {
		return errors.New("wing link user service command failed")
	}
	return nil
}

func wingLinkSystemdUnit(binary, listen, hermesOrigin, path, statePath, hermesHome string) string {
	overrides := "Environment=WING_LINK_STATE=" + systemdQuote(statePath) + "\n" +
		"Environment=WING_HERMES_HOME=" + systemdQuote(hermesHome) + "\n"
	writablePaths := []string{filepath.Dir(statePath), hermesHome}
	for _, writablePath := range writablePaths {
		overrides += "ReadWritePaths=" + systemdQuote(writablePath) + "\n"
	}
	return fmt.Sprintf(`[Unit]
Description=Hermes Wing Link profile management
After=network-online.target

[Service]
Type=simple
ExecStart=%s serve --listen %s
Environment=WING_HERMES_URL=%s
Environment=PATH=%s
%sRestart=on-failure
RestartSec=2
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
RestrictSUIDSGID=true

[Install]
WantedBy=default.target
`, systemdQuote(binary), systemdQuote(listen), systemdQuote(hermesOrigin), systemdQuote(path), overrides)
}

func systemdQuote(value string) string {
	value = strings.ReplaceAll(value, "%", "%%")
	return `"` + strings.NewReplacer(`\`, `\\`, `"`, `\"`, "\n", `\n`, "\r", `\r`).Replace(value) + `"`
}
