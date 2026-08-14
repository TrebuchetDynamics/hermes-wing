package app

import (
	"context"
	"errors"
	"net/http"
	"strings"
)

func (server *wingLinkServer) startBootstrap(writer http.ResponseWriter, request *http.Request) {
	if server.bootstrap == nil || server.operations == nil {
		writeJSON(writer, http.StatusNotImplemented, map[string]any{
			"error": APIError{Code: "setup_unavailable", Message: "Hermes setup is unavailable"},
		})
		return
	}
	var body BootstrapRequest
	if !decodeJSON(writer, request, &body) {
		return
	}
	if err := body.Validate(); err != nil {
		writeJSON(writer, http.StatusBadRequest, map[string]any{
			"error": APIError{Code: "setup_invalid", Message: "Hermes setup request is invalid"},
		})
		return
	}
	operationID, err := server.operations.Start("setup", func(ctx context.Context, emit func(OperationEvent)) error {
		_, err := server.bootstrap.Bootstrap(ctx, body, emit)
		return err
	})
	if errors.Is(err, ErrOperationInProgress) {
		writeJSON(writer, http.StatusConflict, map[string]any{
			"error": APIError{Code: "operation_in_progress", Message: "Another setup operation is active"},
		})
		return
	}
	if err != nil {
		writeJSON(writer, http.StatusServiceUnavailable, map[string]any{
			"error": APIError{Code: "setup_unavailable", Message: "Could not start Hermes setup"},
		})
		return
	}
	writeJSON(writer, http.StatusAccepted, map[string]any{
		"protocol_version": ProtocolVersion,
		"operation_id":     operationID,
	})
}

func operationRoute(path string) (string, bool) {
	parts := strings.Split(strings.Trim(path, "/"), "/")
	if len(parts) != 3 || parts[0] != "v1" || parts[1] != "operations" ||
		!strings.HasPrefix(parts[2], "op_") || len(parts[2]) > 96 {
		return "", false
	}
	return parts[2], true
}

func (server *wingLinkServer) operationSnapshot(writer http.ResponseWriter, id string) {
	if server.operations == nil {
		writer.WriteHeader(http.StatusNotFound)
		return
	}
	event, ok := server.operations.Snapshot(id)
	if !ok {
		writer.WriteHeader(http.StatusNotFound)
		return
	}
	writeJSON(writer, http.StatusOK, event)
}
