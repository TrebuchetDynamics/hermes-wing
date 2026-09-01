// Package audit implements the bounded privacy-safe Wing Link audit log.
//
// Audit events are strictly typed with an allowlisted field set: timestamp,
// device ID, typed operation, derived risk tier, approval source, result
// code, protocol generation, and bounded duration. Hostile content such as
// bearer tokens, pairing codes, host paths, and control characters is
// sanitized and rejected before persistence, and unknown or invalid content
// in an existing log makes it fail closed.
//
// The log is an owner-only rolling JSON-lines file bounded by MaxEvents and
// MaxBytes. Rotation rewrites the file atomically under the shared state
// primitives from internal/state so multiple processes append safely.
package audit

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"time"

	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/approval"
	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/hostexec"
	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/protocol"
	wingstate "github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/state"
)

// MaxEvents bounds the number of retained audit events.
const MaxEvents = 10_000

// MaxBytes bounds the retained audit log size.
const MaxBytes = 4 << 20

const (
	maxDeviceIDLength = 96
	maxDuration       = 10 * time.Minute
)

// RiskTier classifies audited operations. Values mirror the approval policy.
type RiskTier string

const (
	TierRoutine   RiskTier = "routine"
	TierSensitive RiskTier = "sensitive"
	TierTrust     RiskTier = "trust"
)

// ApprovalSource identifies where the authorization for an event came from.
// The host console is the only approval authority; pairing codes authorize
// enrollment exchanges only.
type ApprovalSource string

const (
	SourceNone        ApprovalSource = "none"
	SourceHostCLI     ApprovalSource = "host-cli"
	SourcePairingCode ApprovalSource = "pairing-code"
)

// Result is the typed outcome code of an audited event.
type Result string

const (
	ResultSuccess             Result = "success"
	ResultUnauthorized        Result = "unauthorized"
	ResultForbidden           Result = "forbidden"
	ResultInvalidRequest      Result = "invalid_request"
	ResultNotFound            Result = "not_found"
	ResultUpgradeRequired     Result = "upgrade_required"
	ResultApprovalRequired    Result = "approval_required"
	ResultApprovalDenied      Result = "approval_denied"
	ResultIdempotencyConflict Result = "idempotency_conflict"
	ResultOperationFailed     Result = "operation_failed"
)

// auditOperationTiers fixes the risk tier of every audited operation that is
// not already covered by the approval policy. Callers can never supply or
// downgrade a tier.
var auditOperationTiers = map[string]RiskTier{
	"health.read":             TierRoutine,
	"status.read":             TierRoutine,
	"metadata.read":           TierRoutine,
	"device.self.read":        TierRoutine,
	"device.self.revoke":      TierRoutine,
	"devices.list":            TierRoutine,
	"directory.roots.read":    TierRoutine,
	"directory.children.read": TierRoutine,
	"approvals.list":          TierRoutine,
	"pairing.inspect":         TierRoutine,
	"profile.list":            TierRoutine,
	"operation.read":          TierRoutine,
	"update.status":           TierRoutine,
	"pairing.exchange":        TierSensitive,
	"profile.update":          TierSensitive,
	"devices.revoke":          TierTrust,
	"approvals.decide":        TierTrust,
	"audit.clear":             TierTrust,
}

// TierOf returns the fixed risk tier for a typed operation. Operations from
// the approval policy always keep their approval tier.
func TierOf(operation string) (RiskTier, bool) {
	if tier, ok := approval.RiskOf(operation); ok {
		return RiskTier(tier), true
	}
	tier, ok := auditOperationTiers[operation]
	return tier, ok
}

var (
	// ErrUnknownOperation reports an operation outside the fixed vocabulary.
	ErrUnknownOperation = errors.New("unknown audit operation")
	// ErrInvalidEvent reports a field that failed validation or sanitization.
	ErrInvalidEvent = errors.New("invalid audit event")
	// ErrExceededBound reports an event or log that cannot fit its bounds.
	ErrExceededBound = errors.New("audit log exceeded its bound")
	// ErrInvalidLog reports a tampered or unreadable audit log.
	ErrInvalidLog = errors.New("invalid audit log")
	// ErrClearRequiresConfirmation guards destructive clears.
	ErrClearRequiresConfirmation = errors.New("audit clear requires explicit confirmation")
)

// deviceIDPattern allowlists the only device identifier shapes the log
// accepts: staged device credentials, migrated legacy credentials, the host
// console, and unauthenticated requesters. Path separators, whitespace,
// control characters, and arbitrary Unicode are structurally excluded.
var deviceIDPattern = regexp.MustCompile(`^(cred_[A-Za-z0-9_-]{1,90}|legacy_[0-9a-f]{1,64}|legacy_invalid|host|unauthenticated)$`)

// Record is one persisted audit event. It contains exactly the allowlisted
// fields; request bodies, authorization headers, tokens, and host paths are
// never part of a record.
type Record struct {
	Timestamp          int64          `json:"timestamp"`
	DeviceID           string         `json:"device_id"`
	Operation          string         `json:"operation"`
	RiskTier           RiskTier       `json:"risk_tier"`
	ApprovalSource     ApprovalSource `json:"approval_source"`
	Result             Result         `json:"result"`
	ProtocolGeneration int            `json:"protocol_generation"`
	DurationMS         int64          `json:"duration_ms"`
}

// Input is the caller-supplied description of one audited outcome. The
// timestamp comes from the log clock, the risk tier from the fixed policy,
// and Secrets lists additional values that must be redacted from the event
// before validation.
type Input struct {
	DeviceID           string
	Operation          string
	ApprovalSource     ApprovalSource
	Result             Result
	ProtocolGeneration int
	Duration           time.Duration
	Secrets            []string
}

// Log is a bounded owner-only rolling JSON-lines audit log. All mutations
// take an in-process mutex and the cross-process state file lock, keep a
// validated cache, and re-read the file whenever another process changed it.
type Log struct {
	mu        sync.Mutex
	path      string
	now       func() time.Time
	maxEvents int
	maxBytes  int

	events   []Record
	size     int64
	exists   bool
	tornTail bool
}

// Open validates any existing audit log at path and returns a Log handle.
// A missing, empty, tampered, non-owner-only, or out-of-bounds file fails
// closed.
func Open(path string) (*Log, error) {
	if path == "" {
		return nil, errors.New("audit path is required")
	}
	log := &Log{path: path, now: time.Now, maxEvents: MaxEvents, maxBytes: MaxBytes}
	if err := log.mutate(func() error {
		_, err := log.reloadLocked()
		return err
	}); err != nil {
		return nil, err
	}
	return log, nil
}

// Append sanitizes, validates, and durably records one audited outcome,
// rolling the log within its event and byte bounds.
func (l *Log) Append(input Input) error {
	return l.mutate(func() error {
		event, err := l.buildEvent(input)
		if err != nil {
			return err
		}
		line, err := json.Marshal(event)
		if err != nil {
			return fmt.Errorf("encode audit event: %w", err)
		}
		line = append(line, '\n')

		current, size, torn, err := l.currentLocked()
		if err != nil {
			return err
		}
		overflow := torn || !l.exists ||
			len(current)+1 > l.maxEvents || size+int64(len(line)) > int64(l.maxBytes)
		if !overflow {
			return l.appendLineLocked(line, event)
		}

		kept := current
		if len(kept)+1 > l.maxEvents || sizeOf(kept)+len(line) > l.maxBytes {
			var fits bool
			kept, fits = trimForBounds(kept, len(line), l.maxEvents, l.maxBytes)
			if !fits {
				return fmt.Errorf("%w: audit event does not fit", ErrExceededBound)
			}
		}
		final := make([]Record, 0, len(kept)+1)
		final = append(final, kept...)
		final = append(final, event)
		return l.rewriteLocked(final)
	})
}

// List returns a chronological copy of the retained events. A torn trailing
// write is dropped; any complete malformed line fails closed.
func (l *Log) List() ([]Record, error) {
	var events []Record
	err := l.mutate(func() error {
		current, _, _, err := l.currentLocked()
		if err != nil {
			return err
		}
		events = append([]Record(nil), current...)
		return nil
	})
	if err != nil {
		return nil, err
	}
	return events, nil
}

// Clear erases the audit log. It requires an explicit confirmation so a
// bare invocation cannot destroy evidence.
func (l *Log) Clear(confirmed bool) error {
	if !confirmed {
		return ErrClearRequiresConfirmation
	}
	return l.mutate(func() error { return l.rewriteLocked(nil) })
}

func (l *Log) mutate(work func() error) error {
	l.mu.Lock()
	defer l.mu.Unlock()

	directory := filepath.Dir(l.path)
	if err := os.MkdirAll(directory, 0o700); err != nil {
		return fmt.Errorf("create audit directory: %w", err)
	}
	if err := wingstate.SecurePath(directory, true); err != nil {
		return fmt.Errorf("secure audit directory: %w", err)
	}
	unlock, err := wingstate.AcquireLock(l.path + ".lock")
	if err != nil {
		return fmt.Errorf("lock audit log: %w", err)
	}
	defer func() { _ = unlock() }()
	return work()
}

// buildEvent derives the timestamp and risk tier, sanitizes free-form fields,
// and validates the resulting record.
func (l *Log) buildEvent(input Input) (Record, error) {
	tier, known := TierOf(input.Operation)
	if !known {
		return Record{}, fmt.Errorf("%w: %s", ErrUnknownOperation, hostexec.Sanitize(input.Operation, input.Secrets))
	}
	source := input.ApprovalSource
	if source == "" {
		source = SourceNone
	}
	record := Record{
		Timestamp:          l.now().UTC().Unix(),
		DeviceID:           hostexec.Sanitize(input.DeviceID, input.Secrets),
		Operation:          input.Operation,
		RiskTier:           tier,
		ApprovalSource:     source,
		Result:             input.Result,
		ProtocolGeneration: input.ProtocolGeneration,
		DurationMS:         input.Duration.Milliseconds(),
	}
	if err := record.Validate(); err != nil {
		return Record{}, err
	}
	return record, nil
}

// Validate enforces the allowlisted shapes and enum values of a record. It
// runs on both freshly built and persisted events so tampered lines fail
// closed.
func (r Record) Validate() error {
	if r.Timestamp <= 0 {
		return fmt.Errorf("%w: timestamp", ErrInvalidEvent)
	}
	if len(r.DeviceID) > maxDeviceIDLength || strings.ContainsAny(r.DeviceID, "\r\n\x00") ||
		strings.Contains(r.DeviceID, "wlc_") || strings.Contains(r.DeviceID, "appr_") ||
		!deviceIDPattern.MatchString(r.DeviceID) {
		return fmt.Errorf("%w: device id", ErrInvalidEvent)
	}
	expectedTier, known := TierOf(r.Operation)
	if !known || expectedTier != r.RiskTier {
		return fmt.Errorf("%w: operation or risk tier", ErrInvalidEvent)
	}
	if !validApprovalSource(r.ApprovalSource) {
		return fmt.Errorf("%w: approval source", ErrInvalidEvent)
	}
	if !validResult(r.Result) {
		return fmt.Errorf("%w: result", ErrInvalidEvent)
	}
	if r.ApprovalSource != SourceNone && r.RiskTier == TierRoutine {
		return fmt.Errorf("%w: routine operation cannot carry an approval", ErrInvalidEvent)
	}
	if (r.Result == ResultApprovalRequired || r.Result == ResultApprovalDenied) && r.RiskTier == TierRoutine {
		return fmt.Errorf("%w: routine operation cannot require an approval", ErrInvalidEvent)
	}
	if !protocol.SupportsProtocolGeneration(r.ProtocolGeneration) {
		return fmt.Errorf("%w: protocol generation", ErrInvalidEvent)
	}
	if r.DurationMS < 0 || r.DurationMS > maxDuration.Milliseconds() {
		return fmt.Errorf("%w: duration", ErrInvalidEvent)
	}
	return nil
}

func validApprovalSource(source ApprovalSource) bool {
	switch source {
	case SourceNone, SourceHostCLI, SourcePairingCode:
		return true
	default:
		return false
	}
}

func validResult(result Result) bool {
	switch result {
	case ResultSuccess, ResultUnauthorized, ResultForbidden, ResultInvalidRequest,
		ResultNotFound, ResultUpgradeRequired, ResultApprovalRequired, ResultApprovalDenied,
		ResultIdempotencyConflict, ResultOperationFailed:
		return true
	default:
		return false
	}
}

// currentLocked returns the retained events, on-disk size, and torn-tail
// flag after re-reading the file. Audit integrity must not depend on metadata
// such as size or modification time, which can remain unchanged after tampering.
func (l *Log) currentLocked() ([]Record, int64, bool, error) {
	if _, err := l.reloadLocked(); err != nil {
		return nil, 0, false, err
	}
	return l.events, l.size, l.tornTail, nil
}

// reloadLocked re-reads and validates the whole file, refreshing the cache.
func (l *Log) reloadLocked() ([]Record, error) {
	events, size, exists, torn, err := l.readFileLocked()
	if err != nil {
		return nil, err
	}
	l.events, l.size, l.exists, l.tornTail = events, size, exists, torn
	return append([]Record(nil), events...), nil
}

// readFileLocked reads and validates the JSON-lines file. An unterminated
// trailing line is treated as a torn write and dropped; everything else must
// parse and validate or the log fails closed.
func (l *Log) readFileLocked() ([]Record, int64, bool, bool, error) {
	info, err := os.Lstat(l.path)
	if errors.Is(err, os.ErrNotExist) {
		return nil, 0, false, false, nil
	}
	if err != nil {
		return nil, 0, false, false, fmt.Errorf("inspect audit log: %w", err)
	}
	if !info.Mode().IsRegular() {
		return nil, 0, false, false, fmt.Errorf("%w: audit log must be a regular file", ErrInvalidLog)
	}
	if info.Size() > int64(l.maxBytes) {
		return nil, 0, false, false, fmt.Errorf("%w: %d bytes", ErrExceededBound, info.Size())
	}
	ownerOnly, err := wingstate.PathOwnerOnly(l.path, false)
	if err != nil || !ownerOnly {
		return nil, 0, false, false, fmt.Errorf("%w: audit log must be owner-only", ErrInvalidLog)
	}
	data, err := os.ReadFile(l.path)
	if err != nil {
		return nil, 0, false, false, fmt.Errorf("read audit log: %w", err)
	}
	if len(data) > l.maxBytes {
		return nil, 0, false, false, fmt.Errorf("%w: %d bytes", ErrExceededBound, len(data))
	}
	torn := false
	if length := len(data); length > 0 && data[length-1] != '\n' {
		torn = true
		if index := bytes.LastIndexByte(data, '\n'); index >= 0 {
			data = data[:index+1]
		} else {
			data = nil
		}
	}
	var events []Record
	lines := bytes.Split(data, []byte{'\n'})
	for index, raw := range lines {
		if len(raw) == 0 {
			if index == len(lines)-1 {
				continue
			}
			return nil, 0, false, false, fmt.Errorf("%w: empty line %d", ErrInvalidLog, index+1)
		}
		record, err := decodeRecord(raw)
		if err != nil {
			return nil, 0, false, false, fmt.Errorf("%w: line %d: %v", ErrInvalidLog, index+1, err)
		}
		if err := record.Validate(); err != nil {
			return nil, 0, false, false, fmt.Errorf("%w: line %d: %v", ErrInvalidLog, index+1, err)
		}
		events = append(events, record)
	}
	if len(events) > l.maxEvents {
		return nil, 0, false, false, fmt.Errorf("%w: %d events", ErrExceededBound, len(events))
	}
	return events, info.Size(), true, torn, nil
}

func decodeRecord(line []byte) (Record, error) {
	var record Record
	decoder := json.NewDecoder(bytes.NewReader(line))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&record); err != nil {
		return Record{}, err
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return Record{}, errors.New("trailing data")
	}
	return record, nil
}

// appendLineLocked durably appends one pre-validated line to an existing
// in-bounds file and updates the cache.
func (l *Log) appendLineLocked(line []byte, event Record) error {
	file, err := os.OpenFile(l.path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		return fmt.Errorf("open audit log: %w", err)
	}
	writeErr := func() error {
		if err := wingstate.SecurePath(l.path, false); err != nil {
			return fmt.Errorf("secure audit log: %w", err)
		}
		if _, err := file.Write(line); err != nil {
			return fmt.Errorf("append audit event: %w", err)
		}
		return file.Sync()
	}()
	closeErr := file.Close()
	if writeErr != nil {
		return writeErr
	}
	if closeErr != nil {
		return fmt.Errorf("close audit log: %w", closeErr)
	}
	l.events = append(l.events, event)
	l.size += int64(len(line))
	l.exists = true
	l.tornTail = false
	return nil
}

// rewriteLocked atomically replaces the whole file with the given events and
// refreshes the cache.
func (l *Log) rewriteLocked(events []Record) error {
	var payload bytes.Buffer
	for _, event := range events {
		line, err := json.Marshal(event)
		if err != nil {
			return fmt.Errorf("encode audit event: %w", err)
		}
		payload.Write(line)
		payload.WriteByte('\n')
	}
	if payload.Len() > l.maxBytes {
		return fmt.Errorf("%w: %d bytes", ErrExceededBound, payload.Len())
	}
	directory := filepath.Dir(l.path)
	temporary, err := os.CreateTemp(directory, ".wing-link-audit-*")
	if err != nil {
		return fmt.Errorf("create audit temp file: %w", err)
	}
	temporaryPath := temporary.Name()
	cleanup := func() {
		_ = temporary.Close()
		_ = os.Remove(temporaryPath)
	}
	if err := wingstate.SecurePath(temporaryPath, false); err != nil {
		cleanup()
		return fmt.Errorf("secure audit temp file: %w", err)
	}
	if _, err := temporary.Write(payload.Bytes()); err != nil {
		cleanup()
		return fmt.Errorf("write audit log: %w", err)
	}
	if err := temporary.Sync(); err != nil {
		cleanup()
		return fmt.Errorf("sync audit log: %w", err)
	}
	if err := temporary.Close(); err != nil {
		_ = os.Remove(temporaryPath)
		return fmt.Errorf("close audit temp file: %w", err)
	}
	if err := wingstate.ReplaceFile(temporaryPath, l.path); err != nil {
		_ = os.Remove(temporaryPath)
		return fmt.Errorf("replace audit log: %w", err)
	}
	if err := wingstate.SyncDirectory(directory); err != nil {
		return fmt.Errorf("sync audit directory: %w", err)
	}
	l.events = events
	l.size = int64(payload.Len())
	l.exists = true
	l.tornTail = false
	return nil
}

// sizeOf computes the serialized byte size of the events.
func sizeOf(events []Record) int {
	total := 0
	for _, event := range events {
		line, err := json.Marshal(event)
		if err != nil {
			// Records always marshal; the fallback keeps accounting finite.
			total += 512
			continue
		}
		total += len(line) + 1
	}
	return total
}

// trimForBounds drops the oldest events until one more line fits both the
// event and byte bounds. It reports false when the line alone cannot fit.
func trimForBounds(events []Record, incoming int, maxEvents int, maxBytes int) ([]Record, bool) {
	kept := events
	for {
		if len(kept)+1 <= maxEvents && sizeOf(kept)+incoming <= maxBytes {
			return kept, true
		}
		if len(kept) == 0 {
			return nil, incoming <= maxBytes && maxEvents >= 1
		}
		kept = kept[1:]
	}
}
