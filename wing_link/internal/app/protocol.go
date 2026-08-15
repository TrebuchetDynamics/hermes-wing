package app

import "github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/protocol"

const ProtocolVersion = protocol.ProtocolVersion

type Component = protocol.Component

const (
	ComponentHermes         = protocol.ComponentHermes
	ComponentOmniRoute      = protocol.ComponentOmniRoute
	ComponentStarterProfile = protocol.ComponentStarterProfile
)

type RuntimeState = protocol.RuntimeState

const (
	RuntimeAbsent     = protocol.RuntimeAbsent
	RuntimeInstalling = protocol.RuntimeInstalling
	RuntimeStopped    = protocol.RuntimeStopped
	RuntimeStarting   = protocol.RuntimeStarting
	RuntimeHealthy    = protocol.RuntimeHealthy
	RuntimeFailed     = protocol.RuntimeFailed
)

type InstallRequest = protocol.InstallRequest
type InstallStatus = protocol.InstallStatus
type APIError = protocol.APIError
type OperationEvent = protocol.OperationEvent
