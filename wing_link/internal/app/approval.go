package app

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/approval"
	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/audit"
)

type ApprovalStore = approval.Store

const (
	ApprovalOpProfileCreate       = approval.OpProfileCreate
	ApprovalOpProfileCreateSecret = approval.OpProfileCreateSecret
	ApprovalOpProfileRename       = approval.OpProfileRename
	ApprovalOpProfileDelete       = approval.OpProfileDelete
	ApprovalOpSetupInstall        = approval.OpSetupInstall
	ApprovalOpUpdateApply         = approval.OpUpdateApply
)

func openApprovalStore(statePath string) (*ApprovalStore, error) {
	return approval.Open(filepath.Join(filepath.Dir(statePath), "wing-link-approvals.json"))
}

func (server *wingLinkServer) approvalGate(
	writer http.ResponseWriter,
	request *http.Request,
	authorization DeviceAuthorization,
	operationName string,
	route string,
	payloadDigest string,
	summary string,
) (string, bool) {
	started := time.Now()
	tier, known := approval.RiskOf(operationName)
	if !known {
		writeJSON(writer, http.StatusForbidden, map[string]any{
			"error": APIError{Code: "approval_policy_missing", Message: "Host approval policy is unavailable"},
		})
		return "", false
	}
	if tier == approval.TierRoutine {
		return "", true
	}
	if server.approvals == nil || server.operations == nil {
		writeJSON(writer, http.StatusServiceUnavailable, map[string]any{
			"error": APIError{Code: "approval_unavailable", Message: "Host approval service is unavailable"},
		})
		return "", false
	}
	key := strings.TrimSpace(request.Header.Get("Idempotency-Key"))
	if key == "" {
		writeJSON(writer, http.StatusPreconditionRequired, map[string]any{
			"error": APIError{Code: "idempotency_key_required", Message: "This operation requires an idempotency key"},
		})
		return "", false
	}
	operationID, _, err := server.operations.ReserveIdempotent(IdempotencyRequest{
		DeviceID: authorization.Device.ID, Route: request.Method + " " + route,
		Key: key, PayloadDigest: payloadDigest, Kind: operationName,
	})
	if errors.Is(err, ErrIdempotencyConflict) {
		server.recordAudit(authorization.Device.ID, operationName, audit.SourceNone, audit.ResultIdempotencyConflict, started)
		writeJSON(writer, http.StatusConflict, map[string]any{
			"error": APIError{Code: "idempotency_conflict", Message: "Idempotency key was already used for a different request"},
		})
		return "", false
	}
	if err != nil {
		writeJSON(writer, http.StatusServiceUnavailable, map[string]any{
			"error": APIError{Code: "operation_unavailable", Message: "Could not reserve the host operation"},
		})
		return "", false
	}
	if event, ok := server.operations.Snapshot(operationID); ok && event.Terminal {
		writeJSON(writer, http.StatusAccepted, map[string]any{
			"protocol_version": ProtocolVersion,
			"operation_id":     operationID,
			"operation":        event,
			"replayed":         true,
		})
		return operationID, false
	}
	approvalRoute := request.Method + " " + route
	if _, err := server.approvals.Consume(authorization.Device.ID, approvalRoute, payloadDigest); err == nil {
		return operationID, true
	}
	pending, err := server.approvals.Request(approval.Request{
		DeviceID: authorization.Device.ID, DeviceName: authorization.Device.Name,
		Operation: operationName, Route: approvalRoute, PayloadDigest: payloadDigest,
		Summary: summary,
	}, tier, 5*time.Minute)
	if err != nil {
		writeJSON(writer, http.StatusServiceUnavailable, map[string]any{
			"error": APIError{Code: "approval_unavailable", Message: "Could not create the host approval request"},
		})
		return "", false
	}
	server.recordAudit(authorization.Device.ID, operationName, audit.SourceNone, audit.ResultApprovalRequired, started)
	writeJSON(writer, http.StatusAccepted, map[string]any{
		"error":        APIError{Code: "approval_required", Message: "Approve this operation on the Wing Link host"},
		"approval_id":  pending.ID,
		"operation_id": operationID,
		"expires_at":   pending.ExpiresAt,
	})
	return operationID, false
}

func approvalsCommand(stdout, stderr io.Writer, args []string) int {
	if len(args) == 0 {
		_, _ = fmt.Fprintln(stderr, "approvals: expected list, approve <approval-id>, or reject <approval-id>")
		return 2
	}
	statePath, err := resolveWingLinkStatePath()
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "approvals: %v\n", err)
		return 1
	}
	store, err := openApprovalStore(statePath)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "approvals: %v\n", err)
		return 1
	}
	switch args[0] {
	case "list":
		if len(args) != 1 {
			_, _ = fmt.Fprintln(stderr, "approvals list: no additional arguments are accepted")
			return 2
		}
		rows, err := store.List()
		if err != nil {
			_, _ = fmt.Fprintf(stderr, "approvals list: %v\n", err)
			return 1
		}
		if len(rows) == 0 {
			_, _ = fmt.Fprintln(stdout, "No host approval requests.")
			return 0
		}
		for _, row := range rows {
			_, _ = fmt.Fprintf(
				stdout,
				"%s\t%s\t%s\t%s\t%s\t%s\n",
				row.ID,
				row.Tier,
				row.State,
				row.Request.Operation,
				row.Request.DeviceName,
				row.Request.Summary,
			)
		}
		return 0
	case "approve", "reject":
		if len(args) != 2 {
			_, _ = fmt.Fprintf(stderr, "approvals %s: expected exactly one approval ID\n", args[0])
			return 2
		}
		row, err := store.Decide(args[1], args[0] == "approve")
		if err != nil {
			_, _ = fmt.Fprintf(stderr, "approvals %s: %v\n", args[0], err)
			return 1
		}
		decision := "Rejected"
		if row.State == approval.StateApproved {
			decision = "Approved"
		}
		_, _ = fmt.Fprintf(stdout, "%s approval %s.\n", decision, row.ID)
		return 0
	default:
		_, _ = fmt.Fprintf(stderr, "approvals: unknown command %s\n", args[0])
		return 2
	}
}
