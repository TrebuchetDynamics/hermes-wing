package app

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"regexp"
	"runtime"
	"strings"
	"time"
)

type LocalInstallationInspection struct {
	ProtocolVersion int    `json:"protocol_version"`
	Platform        string `json:"platform"`
	HermesInstalled bool   `json:"hermes_installed"`
	HermesHealthy   bool   `json:"hermes_healthy"`
	HermesVersion   string `json:"hermes_version,omitempty"`
	WingLinkVersion string `json:"wing_link_version"`
	SetupAvailable  bool   `json:"setup_available"`
}

type inspectionRunner func(context.Context, CommandSpec) ([]byte, ProcessResult)

func inspectLocalInstallation(
	ctx context.Context,
	resolve func() (string, error),
	run inspectionRunner,
) LocalInstallationInspection {
	inspection := LocalInstallationInspection{
		ProtocolVersion: ProtocolVersion,
		Platform:        runtime.GOOS,
		WingLinkVersion: version,
		SetupAvailable:  setupAvailableForPlatform(runtime.GOOS),
	}
	executable, err := resolve()
	if err != nil || strings.TrimSpace(executable) == "" {
		return inspection
	}
	inspection.HermesInstalled = true
	output, result := run(ctx, CommandSpec{
		Path:    executable,
		Args:    []string{"--version"},
		Timeout: 30 * time.Second,
	})
	if result.Err != nil {
		return inspection
	}
	version := parsedHermesVersion(output)
	if version == "" {
		return inspection
	}
	inspection.HermesHealthy = true
	inspection.HermesVersion = version
	return inspection
}

func setupAvailableForPlatform(platform string) bool {
	return platform == "linux" || platform == "android"
}

var hermesVersionPattern = regexp.MustCompile(`(?m)^Hermes Agent v[0-9]+(?:\.[0-9]+){1,3}(?:$|[[:space:]])`)

func parsedHermesVersion(output []byte) string {
	match := hermesVersionPattern.Find(output)
	return strings.TrimSpace(string(match))
}

func writeInspectionJSON(writer io.Writer, inspection LocalInstallationInspection) int {
	encoder := json.NewEncoder(writer)
	encoder.SetEscapeHTML(true)
	if err := encoder.Encode(inspection); err != nil {
		return 1
	}
	return 0
}

func inspectCommand(stdout, stderr io.Writer, args []string) int {
	jsonOutput := false
	for _, arg := range args {
		if arg != "--json" || jsonOutput {
			_, _ = fmt.Fprintln(stderr, "inspect: only one optional --json flag is supported")
			return 2
		}
		jsonOutput = true
	}
	home, err := resolveHermesHome()
	if err != nil {
		_, _ = fmt.Fprintln(stderr, "inspect: could not resolve the Hermes home")
		return 1
	}
	inspection := inspectLocalInstallation(
		context.Background(),
		func() (string, error) { return resolveHermesExecutable(home, "") },
		func(ctx context.Context, spec CommandSpec) ([]byte, ProcessResult) {
			return runProcessCapture(ctx, spec, 16*1024)
		},
	)
	if jsonOutput {
		return writeInspectionJSON(stdout, inspection)
	}
	if !inspection.HermesInstalled {
		_, _ = fmt.Fprintln(stdout, "Hermes Agent is not installed.")
		return 0
	}
	if !inspection.HermesHealthy {
		_, _ = fmt.Fprintln(stdout, "Hermes Agent was found but is not healthy.")
		return 1
	}
	_, _ = fmt.Fprintf(stdout, "Hermes Agent is ready: %s\n", inspection.HermesVersion)
	return 0
}
