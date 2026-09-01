package app

import (
	"fmt"
	"io"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/audit"
)

type AuditLog = audit.Log

func openAuditLog(statePath string) (*AuditLog, error) {
	return audit.Open(filepath.Join(filepath.Dir(statePath), "wing-link-audit.jsonl"))
}

func (server *wingLinkServer) recordAudit(
	deviceID string,
	operation string,
	source audit.ApprovalSource,
	result audit.Result,
	started time.Time,
) {
	if server.audit == nil {
		return
	}
	duration := time.Since(started)
	if duration < 0 {
		duration = 0
	}
	_ = server.audit.Append(audit.Input{
		DeviceID: deviceID, Operation: operation, ApprovalSource: source,
		Result: result, ProtocolGeneration: ProtocolVersion, Duration: duration,
	})
}

type auditResponseWriter struct {
	http.ResponseWriter
	status int
}

func (writer *auditResponseWriter) WriteHeader(status int) {
	if writer.status == 0 {
		writer.status = status
	}
	writer.ResponseWriter.WriteHeader(status)
}

func (writer *auditResponseWriter) Write(payload []byte) (int, error) {
	if writer.status == 0 {
		writer.status = http.StatusOK
	}
	return writer.ResponseWriter.Write(payload)
}

func auditOperationForRequest(request *http.Request) string {
	switch {
	case request.Method == http.MethodGet && request.URL.Path == "/v1/status":
		return "status.read"
	case request.Method == http.MethodGet && request.URL.Path == "/v1/profiles":
		return "profile.list"
	case request.Method == http.MethodGet && request.URL.Path == "/v1/update/status":
		return "update.status"
	case request.Method == http.MethodGet && request.URL.Path == remoteDirectoryBasePath:
		return "directory.roots.read"
	case request.Method == http.MethodGet && isRemoteDirectoryChildrenPath(request.URL.Path):
		return "directory.children.read"
	case request.Method == http.MethodGet && request.URL.Path == "/v2/devices/self":
		return "device.self.read"
	case request.Method == http.MethodDelete && request.URL.Path == "/v2/devices/self":
		return "device.self.revoke"
	case request.Method == http.MethodGet && strings.HasPrefix(request.URL.Path, "/v1/operations/"):
		return "operation.read"
	default:
		return ""
	}
}

func auditResultForStatus(status int) audit.Result {
	switch {
	case status >= 200 && status < 300:
		return audit.ResultSuccess
	case status == http.StatusBadRequest:
		return audit.ResultInvalidRequest
	case status == http.StatusUnauthorized:
		return audit.ResultUnauthorized
	case status == http.StatusForbidden:
		return audit.ResultForbidden
	case status == http.StatusNotFound:
		return audit.ResultNotFound
	default:
		return audit.ResultOperationFailed
	}
}

func auditCommand(stdout, stderr io.Writer, args []string) int {
	statePath, err := resolveWingLinkStatePath()
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "audit: %v\n", err)
		return 1
	}
	log, err := openAuditLog(statePath)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "audit: %v\n", err)
		return 1
	}
	if len(args) == 0 {
		events, err := log.List()
		if err != nil {
			_, _ = fmt.Fprintf(stderr, "audit: %v\n", err)
			return 1
		}
		if len(events) == 0 {
			_, _ = fmt.Fprintln(stdout, "No Wing Link audit events.")
			return 0
		}
		for _, event := range events {
			_, _ = fmt.Fprintf(
				stdout, "%d\t%s\t%s\t%s\t%s\t%s\t%d\t%dms\n",
				event.Timestamp, event.DeviceID, event.Operation, event.RiskTier,
				event.ApprovalSource, event.Result, event.ProtocolGeneration, event.DurationMS,
			)
		}
		return 0
	}
	if len(args) == 2 && args[0] == "clear" && args[1] == "--confirm" {
		if err := log.Clear(true); err != nil {
			_, _ = fmt.Fprintf(stderr, "audit clear: %v\n", err)
			return 1
		}
		_, _ = fmt.Fprintln(stdout, "Cleared Wing Link audit log.")
		return 0
	}
	_, _ = fmt.Fprintln(stderr, "audit: use no arguments to list, or clear --confirm")
	return 2
}
