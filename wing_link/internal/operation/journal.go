package operation

import (
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

const (
	journalSchema     = 1
	maxJournalBytes   = 256 << 10
	maxJournalRecords = 128

	PhasePending   = "pending"
	PhaseApproved  = "approved"
	PhaseRunning   = "running"
	PhaseCommitted = "committed"
	PhaseFailed    = "failed"
	PhaseCancelled = "cancelled"
)

var ErrIdempotencyConflict = errors.New("idempotency key already used with different payload")

type IdempotencyRequest struct {
	DeviceID      string
	Route         string
	Key           string
	PayloadDigest string
	Kind          string
}

type JournalRecord struct {
	ID            string         `json:"id"`
	DeviceID      string         `json:"device_id"`
	Route         string         `json:"route"`
	Key           string         `json:"idempotency_key"`
	PayloadDigest string         `json:"payload_digest"`
	Kind          string         `json:"kind"`
	Phase         string         `json:"phase"`
	CreatedAt     int64          `json:"created_at"`
	UpdatedAt     int64          `json:"updated_at"`
	Event         OperationEvent `json:"event"`
}

type journalWire struct {
	Schema  int             `json:"schema"`
	Records []JournalRecord `json:"records,omitempty"`
}

type Journal struct {
	mu      sync.Mutex
	path    string
	now     func() time.Time
	records []JournalRecord
}

func OpenJournal(path string) (*Journal, error) {
	journal := &Journal{path: path, now: time.Now}
	if err := journal.load(); err != nil {
		return nil, err
	}
	changed := false
	now := journal.now().UTC().Unix()
	for index := range journal.records {
		record := &journal.records[index]
		if terminalJournalPhase(record.Phase) {
			continue
		}
		record.Phase = PhaseFailed
		record.UpdatedAt = now
		record.Event = OperationEvent{
			ProtocolVersion: ProtocolVersion,
			OperationID:     record.ID,
			Phase:           PhaseFailed,
			Message:         "Operation interrupted by host restart",
			Terminal:        true,
			ErrorCode:       "operation_interrupted",
		}
		changed = true
	}
	if changed {
		if err := journal.saveLocked(); err != nil {
			return nil, err
		}
	}
	return journal, nil
}

func (j *Journal) Lookup(request IdempotencyRequest) (JournalRecord, bool, error) {
	if err := validateIdempotencyRequest(request); err != nil {
		return JournalRecord{}, false, err
	}
	j.mu.Lock()
	defer j.mu.Unlock()
	return j.lookupLocked(request)
}

func (j *Journal) lookupLocked(request IdempotencyRequest) (JournalRecord, bool, error) {
	for _, record := range j.records {
		if record.DeviceID != request.DeviceID || record.Route != request.Route || record.Key != request.Key {
			continue
		}
		if record.PayloadDigest != request.PayloadDigest {
			return JournalRecord{}, false, ErrIdempotencyConflict
		}
		return record, true, nil
	}
	return JournalRecord{}, false, nil
}

func (j *Journal) Start(request IdempotencyRequest) (JournalRecord, bool, error) {
	if err := validateIdempotencyRequest(request); err != nil {
		return JournalRecord{}, false, err
	}
	j.mu.Lock()
	defer j.mu.Unlock()
	if record, found, err := j.lookupLocked(request); found || err != nil {
		return record, found, err
	}
	id, err := journalID()
	if err != nil {
		return JournalRecord{}, false, err
	}
	now := j.now().UTC().Unix()
	record := JournalRecord{
		ID:            id,
		DeviceID:      request.DeviceID,
		Route:         request.Route,
		Key:           request.Key,
		PayloadDigest: request.PayloadDigest,
		Kind:          request.Kind,
		Phase:         PhasePending,
		CreatedAt:     now,
		UpdatedAt:     now,
		Event: OperationEvent{
			ProtocolVersion: ProtocolVersion,
			OperationID:     id,
			Phase:           PhasePending,
		},
	}
	j.records = append(j.records, record)
	j.trimLocked()
	if err := j.saveLocked(); err != nil {
		j.records = j.records[:len(j.records)-1]
		return JournalRecord{}, false, err
	}
	return record, false, nil
}

func (j *Journal) Update(id, phase string, event OperationEvent) error {
	if !validJournalPhase(phase) {
		return errors.New("invalid operation phase")
	}
	j.mu.Lock()
	defer j.mu.Unlock()
	index := j.indexLocked(id)
	if index < 0 {
		return errors.New("operation not found")
	}
	record := &j.records[index]
	if terminalJournalPhase(record.Phase) {
		return nil
	}
	event.ProtocolVersion = ProtocolVersion
	event.OperationID = id
	event.Phase = boundRunes(event.Phase, 64)
	event.Message = sanitizeOutput(event.Message, nil)
	if event.Percent < 0 {
		event.Percent = 0
	} else if event.Percent > 100 {
		event.Percent = 100
	}
	if !terminalJournalPhase(phase) {
		event.Terminal = false
		event.ErrorCode = ""
	}
	record.Phase = phase
	record.UpdatedAt = j.now().UTC().Unix()
	record.Event = event
	j.trimLocked()
	return j.saveLocked()
}

func (j *Journal) Complete(id string, operationErr error) error {
	event := OperationEvent{
		ProtocolVersion: ProtocolVersion,
		OperationID:     id,
		Phase:           PhaseCommitted,
		Message:         "Complete",
		Percent:         100,
		Terminal:        true,
	}
	phase := PhaseCommitted
	if operationErr != nil {
		phase = PhaseFailed
		event.Phase = PhaseFailed
		event.Message = "Operation failed"
		event.ErrorCode = "operation_failed"
	}
	return j.Update(id, phase, event)
}

func (j *Journal) Cancel(id string) error {
	return j.Update(id, PhaseCancelled, OperationEvent{
		Phase:     PhaseCancelled,
		Message:   "Operation cancelled",
		Terminal:  true,
		ErrorCode: "operation_cancelled",
	})
}

func (j *Journal) Records() []JournalRecord {
	j.mu.Lock()
	defer j.mu.Unlock()
	return append([]JournalRecord(nil), j.records...)
}

func (j *Journal) Snapshot(id string) (JournalRecord, bool) {
	j.mu.Lock()
	defer j.mu.Unlock()
	index := j.indexLocked(id)
	if index < 0 {
		return JournalRecord{}, false
	}
	return j.records[index], true
}

func (j *Journal) indexLocked(id string) int {
	for index := range j.records {
		if j.records[index].ID == id {
			return index
		}
	}
	return -1
}

func (j *Journal) trimLocked() {
	for len(j.records) > maxJournalRecords {
		remove := -1
		for index := range j.records {
			if terminalJournalPhase(j.records[index].Phase) {
				remove = index
				break
			}
		}
		if remove < 0 {
			return
		}
		j.records = append(j.records[:remove], j.records[remove+1:]...)
	}
}

func (j *Journal) load() error {
	info, err := os.Lstat(j.path)
	if errors.Is(err, os.ErrNotExist) {
		return nil
	}
	if err != nil {
		return err
	}
	if !info.Mode().IsRegular() || info.Mode().Perm()&0o077 != 0 {
		return errors.New("operation journal must be an owner-only regular file")
	}
	file, err := os.Open(j.path)
	if err != nil {
		return err
	}
	defer func() { _ = file.Close() }()
	decoder := json.NewDecoder(io.LimitReader(file, maxJournalBytes+1))
	decoder.DisallowUnknownFields()
	var wire journalWire
	if err := decoder.Decode(&wire); err != nil {
		return errors.New("invalid operation journal")
	}
	if err := ensureJSONEOF(decoder); err != nil || wire.Schema != journalSchema || len(wire.Records) > maxJournalRecords {
		return errors.New("invalid operation journal")
	}
	ids := make(map[string]struct{}, len(wire.Records))
	keys := make(map[string]struct{}, len(wire.Records))
	for _, record := range wire.Records {
		if err := validateJournalRecord(record); err != nil {
			return err
		}
		if _, exists := ids[record.ID]; exists {
			return errors.New("duplicate operation ID")
		}
		ids[record.ID] = struct{}{}
		key := record.DeviceID + "\x00" + record.Route + "\x00" + record.Key
		if _, exists := keys[key]; exists {
			return errors.New("duplicate idempotency key")
		}
		keys[key] = struct{}{}
	}
	j.records = append([]JournalRecord(nil), wire.Records...)
	return nil
}

func (j *Journal) saveLocked() error {
	directory := filepath.Dir(j.path)
	if err := os.MkdirAll(directory, 0o700); err != nil {
		return err
	}
	if err := os.Chmod(directory, 0o700); err != nil {
		return err
	}
	payload, err := json.Marshal(journalWire{Schema: journalSchema, Records: j.records})
	if err != nil || len(payload) > maxJournalBytes {
		return errors.New("operation journal exceeded its bound")
	}
	temporary, err := os.CreateTemp(directory, ".wing-link-operations-*")
	if err != nil {
		return err
	}
	temporaryPath := temporary.Name()
	cleanup := func() {
		_ = temporary.Close()
		_ = os.Remove(temporaryPath)
	}
	if err := temporary.Chmod(0o600); err != nil {
		cleanup()
		return err
	}
	if _, err := temporary.Write(payload); err != nil {
		cleanup()
		return err
	}
	if err := temporary.Sync(); err != nil {
		cleanup()
		return err
	}
	if err := temporary.Close(); err != nil {
		_ = os.Remove(temporaryPath)
		return err
	}
	if err := os.Rename(temporaryPath, j.path); err != nil {
		_ = os.Remove(temporaryPath)
		return err
	}
	dir, err := os.Open(directory)
	if err == nil {
		err = dir.Sync()
		_ = dir.Close()
	}
	return err
}

func validateIdempotencyRequest(request IdempotencyRequest) error {
	if !boundedIdentifier(request.DeviceID, 96) || !boundedIdentifier(request.Key, 128) ||
		len(request.Route) == 0 || len(request.Route) > 128 || strings.ContainsAny(request.Route, "\r\n\x00") ||
		len(request.Kind) == 0 || len(request.Kind) > 64 || strings.ContainsAny(request.Kind, "\r\n\x00") ||
		len(request.PayloadDigest) != 64 || !isLowerHex(request.PayloadDigest) {
		return errors.New("invalid idempotency request")
	}
	return nil
}

func validateJournalRecord(record JournalRecord) error {
	if !strings.HasPrefix(record.ID, "op_") || !boundedIdentifier(record.ID, 96) || record.CreatedAt <= 0 || record.UpdatedAt < record.CreatedAt || !validJournalPhase(record.Phase) {
		return errors.New("invalid operation record")
	}
	return validateIdempotencyRequest(IdempotencyRequest{
		DeviceID: record.DeviceID, Route: record.Route, Key: record.Key,
		PayloadDigest: record.PayloadDigest, Kind: record.Kind,
	})
}

func validJournalPhase(phase string) bool {
	switch phase {
	case PhasePending, PhaseApproved, PhaseRunning, PhaseCommitted, PhaseFailed, PhaseCancelled:
		return true
	default:
		return false
	}
}

func terminalJournalPhase(phase string) bool {
	return phase == PhaseCommitted || phase == PhaseFailed || phase == PhaseCancelled
}

func boundedIdentifier(value string, maximum int) bool {
	if value == "" || len(value) > maximum {
		return false
	}
	for _, runeValue := range value {
		if runeValue < 0x21 || runeValue > 0x7e {
			return false
		}
	}
	return true
}

func isLowerHex(value string) bool {
	for _, character := range value {
		if character < '0' || character > '9' {
			if character < 'a' || character > 'f' {
				return false
			}
		}
	}
	return true
}

func journalID() (string, error) {
	bytes := make([]byte, 16)
	if _, err := rand.Read(bytes); err != nil {
		return "", fmt.Errorf("generate operation ID: %w", err)
	}
	return "op_" + base64.RawURLEncoding.EncodeToString(bytes), nil
}

func ensureJSONEOF(decoder *json.Decoder) error {
	var extra any
	if err := decoder.Decode(&extra); errors.Is(err, io.EOF) {
		return nil
	}
	return errors.New("trailing operation journal data")
}
