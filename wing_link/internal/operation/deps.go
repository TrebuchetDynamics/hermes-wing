package operation

import (
	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/hostexec"
	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/protocol"
	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/state"
)

type OperationEvent = protocol.OperationEvent

const ProtocolVersion = protocol.ProtocolVersion

func boundRunes(value string, limit int) string {
	return protocol.BoundRunes(value, limit)
}

func sanitizeOutput(value string, secrets []string) string {
	return hostexec.Sanitize(value, secrets)
}

func randomSecret(size int, prefix string) (string, error) {
	return state.RandomSecret(size, prefix)
}
