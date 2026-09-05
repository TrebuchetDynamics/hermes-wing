package app

import (
	"bytes"
	"context"
	_ "embed"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

const omniRouteVersion = "3.8.50"

// The entire dependency closure is integrity-pinned, not just the top-level npm package.
//
//go:embed omniroute_assets/package.json
var omniRouteManifest []byte

//go:embed omniroute_assets/package-lock.json
var omniRouteLock []byte

func omniRouteRoot() (string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return "", errors.New("could not locate the local runtime directory")
	}
	root := filepath.Join(home, ".local", "share", "hermes-wing", "omniroute")
	if err := rejectSymlinkedAncestors(root); err != nil {
		return "", errors.New("unsafe OmniRoute installation directory")
	}
	return root, nil
}

func omniRouteNode() (string, error) {
	if runtime.GOOS == "windows" {
		return "", errors.New("OmniRoute installation is currently available on POSIX hosts only")
	}
	node, err := exec.LookPath("node")
	if err != nil {
		return "", errors.New("install Node.js 22.22.2+, 24, 25, or 26 first")
	}
	output, result := runProcessCapture(context.Background(), CommandSpec{Path: node, Args: []string{"--version"}, Timeout: 10 * time.Second}, 1024)
	var major, minor, patch int
	_, scanErr := fmt.Sscanf(strings.TrimSpace(string(output)), "v%d.%d.%d", &major, &minor, &patch)
	if result.Err != nil || scanErr != nil || !(major >= 24 && major < 27 || major == 22 && (minor > 22 || minor == 22 && patch >= 2)) {
		return "", errors.New("OmniRoute requires Node.js >=22.22.2 <23 or >=24 <27")
	}
	return node, nil
}

func omniRouteCLI(root string) string {
	return filepath.Join(root, "node_modules", "omniroute", "bin", "omniroute.mjs")
}

func installOmniRoute(ctx context.Context) error {
	root, err := omniRouteRoot()
	if err != nil {
		return err
	}
	node, npm, err := omniRoutePrerequisites()
	if err != nil {
		return err
	}
	return installOmniRouteAt(ctx, root, node, npm, runProcess)
}

func omniRoutePrerequisites() (string, string, error) {
	node, err := omniRouteNode()
	if err != nil {
		return "", "", err
	}
	npm, err := exec.LookPath("npm")
	if err != nil {
		return "", "", errors.New("install npm alongside Node.js first")
	}
	npm, err = filepath.EvalSymlinks(npm)
	// Invoke npm with Node explicitly: Android native execution of script shebangs
	// differs from execution inside the interactive Termux shell.
	if err != nil || filepath.Base(npm) != "npm-cli.js" {
		return "", "", errors.New("could not resolve the installed npm CLI")
	}
	return node, npm, nil
}

type omniRouteRunner func(context.Context, CommandSpec, func(string)) ProcessResult

func installOmniRouteAt(ctx context.Context, root, node, npm string, run omniRouteRunner) error {
	if err := rejectSymlinkedAncestors(root); err != nil {
		return errors.New("unsafe OmniRoute installation directory")
	}
	if err := os.MkdirAll(root, 0700); err != nil {
		return errors.New("could not create OmniRoute installation directory")
	}
	if err := secureStatePath(root, true); err != nil {
		return errors.New("OmniRoute installation directory must be owner-only")
	}
	unlock, err := acquireStateLock(filepath.Join(root, "install.lock"))
	if err != nil {
		return errors.New("could not lock OmniRoute installation")
	}
	defer unlock()
	destination := filepath.Join(root, omniRouteVersion)
	if _, err := os.Lstat(destination); err == nil {
		if rejectSymlinkedAncestors(destination) != nil {
			return errors.New("unsafe installed OmniRoute runtime")
		}
		installedLock, err := os.ReadFile(filepath.Join(destination, "package-lock.json"))
		if err != nil || !bytes.Equal(installedLock, omniRouteLock) {
			return errors.New("existing OmniRoute runtime does not match the reviewed lock")
		}
		return probeOmniRoute(ctx, destination, node, run)
	} else if !errors.Is(err, os.ErrNotExist) {
		return errors.New("could not inspect installed OmniRoute runtime")
	}
	stage, err := os.MkdirTemp(root, ".install-")
	if err != nil {
		return errors.New("could not stage OmniRoute installation")
	}
	defer os.RemoveAll(stage)
	for name, data := range map[string][]byte{"package.json": omniRouteManifest, "package-lock.json": omniRouteLock} {
		if err := os.WriteFile(filepath.Join(stage, name), data, 0600); err != nil {
			return errors.New("could not stage the OmniRoute dependency lock")
		}
	}
	spec := CommandSpec{Path: node, Args: []string{npm, "ci", "--ignore-scripts", "--omit=dev", "--no-audit", "--no-fund", "--registry=https://registry.npmjs.org", "--cache=" + filepath.Join(stage, ".npm-cache")}, Dir: stage, Timeout: 20 * time.Minute}
	// Dependency output is not a diagnostics contract. Do not forward it or any
	// inherited npm credentials to the console or remote operation event stream.
	if result := run(ctx, spec, nil); result.Err != nil {
		return errors.New("locked npm installation failed; no runtime was activated")
	}
	if err := probeOmniRoute(ctx, stage, node, run); err != nil {
		return err
	}
	if err := os.RemoveAll(filepath.Join(stage, ".npm-cache")); err != nil {
		return errors.New("could not remove the staging cache")
	}
	if err := os.Rename(stage, destination); err != nil {
		return errors.New("could not activate the verified OmniRoute runtime")
	}
	return nil
}

func probeOmniRoute(ctx context.Context, directory, node string, run omniRouteRunner) error {
	probe, err := os.MkdirTemp("", "wing-omniroute-probe-")
	if err != nil {
		return errors.New("could not create the runtime probe directory")
	}
	defer os.RemoveAll(probe)
	for _, arg := range []string{"--version", "--help"} {
		spec := CommandSpec{Path: node, Args: []string{omniRouteCLI(directory), arg}, Dir: directory, Env: []string{"DATA_DIR=" + probe, "XDG_CACHE_HOME=" + probe, "NO_UPDATE_NOTIFIER=1", "CI=1"}, Timeout: 90 * time.Second}
		if result := run(ctx, spec, nil); result.Err != nil {
			return errors.New("OmniRoute CLI readiness check failed; no new runtime was activated")
		}
	}
	return nil
}

func omniRouteSetupCommand(stdout, stderr io.Writer, args []string) int {
	if len(args) != 0 {
		_, _ = fmt.Fprintln(stderr, "omniroute-setup accepts no options")
		return 2
	}
	root, err := omniRouteRoot()
	if err != nil {
		_, _ = fmt.Fprintln(stderr, err)
		return 1
	}
	node, err := omniRouteNode()
	if err != nil {
		_, _ = fmt.Fprintln(stderr, err)
		return 1
	}
	directory := filepath.Join(root, omniRouteVersion)
	if rejectSymlinkedAncestors(directory) != nil {
		_, _ = fmt.Fprintln(stderr, "unsafe OmniRoute installation")
		return 1
	}
	if _, err := os.Stat(omniRouteCLI(directory)); err != nil {
		_, _ = fmt.Fprintln(stderr, "Run wing-link setup --with-omniroute first.")
		return 1
	}
	// This is a local, interactive operator wizard, never a remote management route.
	// Credential input stays on the terminal and is never a command argument.
	command := exec.Command(node, omniRouteCLI(directory), "setup")
	command.Stdin, command.Stdout, command.Stderr = os.Stdin, stdout, stderr
	command.Env = append(os.Environ(), "HOST=127.0.0.1", "HOSTNAME=127.0.0.1", "PORT=20128", "REQUIRE_API_KEY=true", "NO_UPDATE_NOTIFIER=1")
	if err := command.Run(); err != nil {
		_, _ = fmt.Fprintln(stderr, "OmniRoute local setup did not complete")
		return 1
	}
	return 0
}
