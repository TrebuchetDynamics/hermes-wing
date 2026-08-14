package app

import "github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/hostexec"

type CommandSpec = hostexec.CommandSpec
type ProcessResult = hostexec.ProcessResult

var runProcess = hostexec.Run
var runProcessCapture = hostexec.Capture
var sanitizeOutput = hostexec.Sanitize
