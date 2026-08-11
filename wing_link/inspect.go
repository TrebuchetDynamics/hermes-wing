package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
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
		SetupAvailable:  runtime.GOOS == "linux",
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
	inspection.HermesHealthy = true
	inspection.HermesVersion = firstSafeLine(output)
	return inspection
}

func firstSafeLine(output []byte) string {
	for _, line := range strings.Split(string(output), "\n") {
		line = strings.TrimSpace(sanitizeOutput(line, nil))
		if line == "" {
			continue
		}
		runes := []rune(line)
		if len(runes) > 120 {
			runes = runes[:120]
		}
		return string(runes)
	}
	return ""
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
