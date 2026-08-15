package app

import "github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/operation"

type OperationManager = operation.OperationManager

var ErrOperationInProgress = operation.ErrOperationInProgress

func NewOperationManager() *OperationManager {
	return operation.NewOperationManager()
}
