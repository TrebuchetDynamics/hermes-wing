package app

import (
	"context"

	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/hostexec"
)

type CommandSpec = hostexec.CommandSpec
type ProcessResult = hostexec.ProcessResult

func runProcess(ctx context.Context, spec CommandSpec, onLine func(string)) ProcessResult {
	return hostexec.Run(ctx, spec, onLine)
}

func runProcessCapture(ctx context.Context, spec CommandSpec, maximumBytes int) ([]byte, ProcessResult) {
	return hostexec.Capture(ctx, spec, maximumBytes)
}

func sanitizeOutput(value string, secrets []string) string {
	return hostexec.Sanitize(value, secrets)
}
