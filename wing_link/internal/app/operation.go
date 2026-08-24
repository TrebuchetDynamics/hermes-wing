package app

import "github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/operation"

type OperationManager = operation.OperationManager
type IdempotencyRequest = operation.IdempotencyRequest

var ErrOperationInProgress = operation.ErrOperationInProgress
var ErrIdempotencyConflict = operation.ErrIdempotencyConflict

func NewOperationManager() *OperationManager {
	return operation.NewOperationManager()
}

func NewDurableOperationManager(path string) (*OperationManager, error) {
	return operation.NewDurableOperationManager(path)
}
