package app

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"net/http"

	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/release"
)

type wingLinkUpdater interface {
	Apply(context.Context) (release.ApplyResult, error)
}

func (server *wingLinkServer) updateStatus(writer http.ResponseWriter) {
	state := "unavailable"
	reason := "release_keys_empty"
	if release.ProductionUpdatesAvailable() {
		reason = "activation_not_configured"
		if server.updater != nil {
			state = "idle"
			reason = ""
		}
	}
	writeJSON(writer, http.StatusOK, map[string]any{
		"state": state, "current_version": version, "reason": reason,
	})
}

func (server *wingLinkServer) applyUpdate(writer http.ResponseWriter, request *http.Request, authorization DeviceAuthorization) {
	var body struct{}
	if !decodeJSON(writer, request, &body) {
		return
	}
	if !release.ProductionUpdatesAvailable() {
		writeJSON(writer, http.StatusServiceUnavailable, map[string]any{
			"error": APIError{Code: "update_unavailable", Message: "Signed Wing Link updates are not configured on this build"},
		})
		return
	}
	if server.updater == nil {
		writeJSON(writer, http.StatusServiceUnavailable, map[string]any{
			"error": APIError{Code: "update_activation_unsupported", Message: "Safe update activation is unavailable on this service"},
		})
		return
	}
	digest := sha256.Sum256([]byte(`{}`))
	operationID, allowed := server.approvalGate(
		writer, request, authorization, ApprovalOpUpdateApply, "/v1/update/apply",
		hex.EncodeToString(digest[:]), "Install a signed Wing Link update",
	)
	if !allowed {
		return
	}
	var result release.ApplyResult
	err := server.operations.RunReservedSync(operationID, func(ctx context.Context, _ func(OperationEvent)) error {
		var applyErr error
		result, applyErr = server.updater.Apply(ctx)
		return applyErr
	})
	if err != nil {
		code := "update_verification_failed"
		status := http.StatusBadGateway
		if errors.Is(err, release.ErrUpdateRolledBack) {
			code = "update_rolled_back"
			status = http.StatusServiceUnavailable
		} else if errors.Is(err, release.ErrRollbackFailed) {
			code = "update_rollback_failed"
			status = http.StatusInternalServerError
		}
		writeJSON(writer, status, map[string]any{
			"error":        APIError{Code: code, Message: "Signed Wing Link update did not activate"},
			"operation_id": operationID,
		})
		return
	}
	writeJSON(writer, http.StatusOK, map[string]any{
		"operation_id": operationID, "from_version": result.FromVersion, "to_version": result.ToVersion,
	})
}
