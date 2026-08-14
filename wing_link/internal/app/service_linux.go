//go:build linux

package app

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

const wingLinkServiceName = "hermes-wing-link.service"

func EnsureWingLinkService(controlOrigin, hermesOrigin *url.URL) error {
	if strings.EqualFold(strings.TrimSpace(os.Getenv("WING_LINK_SERVICE")), "external") {
		return verifyWingLinkHealth(controlOrigin)
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
	unit := wingLinkSystemdUnit(
		binary,
		controlOrigin.Host,
		hermesOrigin.String(),
		os.Getenv("PATH"),
		statePath,
		os.Getenv("WING_HERMES_HOME"),
		os.Getenv("HERMES_HOME"),
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
	return verifyWingLinkHealth(controlOrigin)
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
	destination := filepath.Join(userHome, ".local", "lib", "hermes-wing", "wing-link")
	if filepath.Clean(executable) == destination {
		return destination, nil
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
	return destination, nil
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

func verifyWingLinkHealth(origin *url.URL) error {
	client := &http.Client{Timeout: 2 * time.Second}
	endpoint := origin.ResolveReference(&url.URL{Path: "/healthz"})
	for attempt := 0; attempt < 20; attempt++ {
		request, err := http.NewRequestWithContext(context.Background(), http.MethodGet, endpoint.String(), nil)
		if err != nil {
			return errors.New("invalid Wing Link health endpoint")
		}
		response, err := client.Do(request)
		if err == nil {
			_ = response.Body.Close()
			if response.StatusCode == http.StatusOK {
				return nil
			}
		}
		time.Sleep(250 * time.Millisecond)
	}
	return errors.New("wing link service did not become healthy")
}

func wingLinkSystemdUnit(binary, listen, hermesOrigin, path, statePath, wingHermesHome, hermesHome string) string {
	overrides := "Environment=WING_LINK_STATE=" + systemdQuote(statePath) + "\n"
	if strings.TrimSpace(wingHermesHome) != "" {
		overrides += "Environment=WING_HERMES_HOME=" + systemdQuote(wingHermesHome) + "\n"
	}
	if strings.TrimSpace(hermesHome) != "" {
		overrides += "Environment=HERMES_HOME=" + systemdQuote(hermesHome) + "\n"
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

[Install]
WantedBy=default.target
`, systemdQuote(binary), systemdQuote(listen), systemdQuote(hermesOrigin), systemdQuote(path), overrides)
}

func systemdQuote(value string) string {
	value = strings.ReplaceAll(value, "%", "%%")
	return `"` + strings.NewReplacer(`\`, `\\`, `"`, `\"`, "\n", `\n`, "\r", `\r`).Replace(value) + `"`
}
