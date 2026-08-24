package approval

import (
	"encoding/json"
	"errors"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/hostexec"
	"github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/protocol"
	wingstate "github.com/TrebuchetDynamics/hermes-wing/wing-link/internal/state"
)

const (
	approvalSchema      = 1
	maxApprovalBytes    = 64 << 10
	maxApprovalRecords  = 128
	maxPendingApprovals = 64
)

type RiskTier string

const (
	TierRoutine   RiskTier = "routine"
	TierSensitive RiskTier = "sensitive"
	TierTrust     RiskTier = "trust"

	OpProfileCreate       = "profile.create"
	OpProfileCreateSecret = "profile.create.secret"
	OpProfileRename       = "profile.rename"
	OpProfileDelete       = "profile.delete"
	OpSetupInstall        = "setup.install"
	OpUpdateApply         = "update.apply"
	OpDirectoryGrant      = "directory.grant"
	OpTrustRotateIdentity = "trust.rotate_identity"
	OpDeviceScopeExpand   = "device.scope_expand"
	OpLifecycleRestart    = "lifecycle.restart"
)

var riskPolicy = map[string]RiskTier{
	OpProfileCreate:       TierRoutine,
	OpProfileCreateSecret: TierSensitive,
	OpProfileRename:       TierRoutine,
	OpProfileDelete:       TierSensitive,
	OpSetupInstall:        TierTrust,
	OpUpdateApply:         TierTrust,
	OpDirectoryGrant:      TierSensitive,
	OpTrustRotateIdentity: TierTrust,
	OpDeviceScopeExpand:   TierTrust,
	OpLifecycleRestart:    TierRoutine,
}

func RiskOf(operation string) (RiskTier, bool) {
	tier, ok := riskPolicy[operation]
	return tier, ok
}

type State string

const (
	StatePending  State = "pending"
	StateApproved State = "approved"
	StateRejected State = "rejected"
	StateExpired  State = "expired"
	StateConsumed State = "consumed"
)

var (
	ErrApprovalRequired = errors.New("approval required")
	ErrApprovalNotFound = errors.New("approval not found")
)

type Request struct {
	DeviceID      string `json:"device_id"`
	DeviceName    string `json:"device_name"`
	Operation     string `json:"operation"`
	Route         string `json:"route"`
	PayloadDigest string `json:"payload_digest"`
	Summary       string `json:"summary"`
}

type Approval struct {
	ID        string   `json:"id"`
	Tier      RiskTier `json:"tier"`
	Request   Request  `json:"request"`
	CreatedAt int64    `json:"created_at"`
	ExpiresAt int64    `json:"expires_at"`
	State     State    `json:"state"`
	DecidedAt int64    `json:"decided_at,omitempty"`
	DecidedBy string   `json:"decided_by,omitempty"`
}

type persistedWire struct {
	Schema    int        `json:"schema"`
	Approvals []Approval `json:"approvals,omitempty"`
}

type Store struct {
	path string
	now  func() time.Time
}

func Open(path string) (*Store, error) {
	store := &Store{path: path, now: time.Now}
	if _, err := store.load(); err != nil {
		return nil, err
	}
	return store, nil
}

func (s *Store) Request(request Request, tier RiskTier, ttl time.Duration) (Approval, error) {
	expectedTier, known := RiskOf(request.Operation)
	if !known || expectedTier != tier || (tier != TierSensitive && tier != TierTrust) || ttl <= 0 || ttl > 15*time.Minute {
		return Approval{}, errors.New("invalid approval policy")
	}
	request = sanitizeRequest(request)
	if err := validateRequest(request); err != nil {
		return Approval{}, err
	}
	var result Approval
	err := s.mutate(func(approvals *[]Approval) error {
		now := s.now().UTC()
		sweepExpired(*approvals, now)
		pending := 0
		for _, approval := range *approvals {
			if approval.State == StatePending || approval.State == StateApproved {
				pending++
				if approval.Request.DeviceID == request.DeviceID && approval.Request.Route == request.Route && approval.Request.PayloadDigest == request.PayloadDigest {
					result = approval
					return nil
				}
			}
		}
		if pending >= maxPendingApprovals {
			return errors.New("too many pending approvals")
		}
		id, err := wingstate.RandomSecret(16, "appr_")
		if err != nil {
			return err
		}
		result = Approval{
			ID: id, Tier: tier, Request: request,
			CreatedAt: now.Unix(), ExpiresAt: now.Add(ttl).Unix(), State: StatePending,
		}
		*approvals = append(*approvals, result)
		trimApprovals(approvals)
		return nil
	})
	return result, err
}

func (s *Store) List() ([]Approval, error) {
	var result []Approval
	err := s.mutate(func(approvals *[]Approval) error {
		sweepExpired(*approvals, s.now().UTC())
		result = append([]Approval(nil), (*approvals)...)
		return nil
	})
	return result, err
}

func (s *Store) Decide(id string, approve bool) (Approval, error) {
	var result Approval
	err := s.mutate(func(approvals *[]Approval) error {
		now := s.now().UTC()
		sweepExpired(*approvals, now)
		for index := range *approvals {
			approval := &(*approvals)[index]
			if approval.ID != id {
				continue
			}
			if approval.State == StateExpired {
				return ErrApprovalRequired
			}
			if approval.State != StatePending {
				return errors.New("approval is not pending")
			}
			if approve {
				approval.State = StateApproved
			} else {
				approval.State = StateRejected
			}
			approval.DecidedAt = now.Unix()
			approval.DecidedBy = "host-cli"
			result = *approval
			return nil
		}
		return ErrApprovalNotFound
	})
	return result, err
}

func (s *Store) Consume(deviceID, route, payloadDigest string) (Approval, error) {
	var result Approval
	err := s.mutate(func(approvals *[]Approval) error {
		now := s.now().UTC()
		sweepExpired(*approvals, now)
		for index := range *approvals {
			approval := &(*approvals)[index]
			if approval.Request.DeviceID != deviceID || approval.Request.Route != route || approval.Request.PayloadDigest != payloadDigest {
				continue
			}
			if approval.State != StateApproved {
				continue
			}
			approval.State = StateConsumed
			approval.DecidedAt = now.Unix()
			approval.DecidedBy = "host-cli"
			result = *approval
			return nil
		}
		return ErrApprovalRequired
	})
	return result, err
}

func (s *Store) mutate(update func(*[]Approval) error) error {
	if err := os.MkdirAll(filepath.Dir(s.path), 0o700); err != nil {
		return err
	}
	if err := wingstate.SecurePath(filepath.Dir(s.path), true); err != nil {
		return err
	}
	unlock, err := wingstate.AcquireLock(s.path + ".lock")
	if err != nil {
		return err
	}
	defer func() { _ = unlock() }()
	approvals, err := s.load()
	if err != nil {
		return err
	}
	if err := update(&approvals); err != nil {
		return err
	}
	return s.save(approvals)
}

func (s *Store) load() ([]Approval, error) {
	info, err := os.Lstat(s.path)
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	if !info.Mode().IsRegular() {
		return nil, errors.New("approval store must be a regular file")
	}
	ownerOnly, err := wingstate.PathOwnerOnly(s.path, false)
	if err != nil || !ownerOnly {
		return nil, errors.New("approval store must be owner-only")
	}
	file, err := os.Open(s.path)
	if err != nil {
		return nil, err
	}
	defer func() { _ = file.Close() }()
	decoder := json.NewDecoder(io.LimitReader(file, maxApprovalBytes+1))
	decoder.DisallowUnknownFields()
	var wire persistedWire
	if err := decoder.Decode(&wire); err != nil || wire.Schema != approvalSchema || len(wire.Approvals) > maxApprovalRecords {
		return nil, errors.New("invalid approval store")
	}
	var extra any
	if err := decoder.Decode(&extra); !errors.Is(err, io.EOF) {
		return nil, errors.New("invalid approval store")
	}
	ids := make(map[string]struct{}, len(wire.Approvals))
	for _, approval := range wire.Approvals {
		if err := validateApproval(approval); err != nil {
			return nil, err
		}
		if _, exists := ids[approval.ID]; exists {
			return nil, errors.New("duplicate approval ID")
		}
		ids[approval.ID] = struct{}{}
	}
	return append([]Approval(nil), wire.Approvals...), nil
}

func (s *Store) save(approvals []Approval) error {
	payload, err := json.Marshal(persistedWire{Schema: approvalSchema, Approvals: approvals})
	if err != nil || len(payload) > maxApprovalBytes {
		return errors.New("approval store exceeded its bound")
	}
	directory := filepath.Dir(s.path)
	temporary, err := os.CreateTemp(directory, ".wing-link-approvals-*")
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
	if err := wingstate.ReplaceFile(temporaryPath, s.path); err != nil {
		_ = os.Remove(temporaryPath)
		return err
	}
	return wingstate.SyncDirectory(directory)
}

func sanitizeRequest(request Request) Request {
	request.DeviceName = protocol.BoundRunes(hostexec.Sanitize(request.DeviceName, nil), 80)
	request.Summary = protocol.BoundRunes(hostexec.Sanitize(request.Summary, nil), 200)
	return request
}

func validateRequest(request Request) error {
	if !bounded(request.DeviceID, 96) || !bounded(request.Operation, 64) || !bounded(request.Route, 128) ||
		len(request.PayloadDigest) != 64 || !lowerHex(request.PayloadDigest) ||
		len([]rune(request.DeviceName)) > 80 || len([]rune(request.Summary)) > 200 {
		return errors.New("invalid approval request")
	}
	if _, ok := RiskOf(request.Operation); !ok {
		return errors.New("unknown approval operation")
	}
	return nil
}

func validateApproval(approval Approval) error {
	if !strings.HasPrefix(approval.ID, "appr_") || !bounded(approval.ID, 96) || approval.CreatedAt <= 0 || approval.ExpiresAt <= approval.CreatedAt ||
		(approval.Tier != TierSensitive && approval.Tier != TierTrust) || !validState(approval.State) {
		return errors.New("invalid approval record")
	}
	return validateRequest(approval.Request)
}

func validState(state State) bool {
	switch state {
	case StatePending, StateApproved, StateRejected, StateExpired, StateConsumed:
		return true
	default:
		return false
	}
}

func sweepExpired(approvals []Approval, now time.Time) {
	for index := range approvals {
		if (approvals[index].State == StatePending || approvals[index].State == StateApproved) && !now.Before(time.Unix(approvals[index].ExpiresAt, 0)) {
			approvals[index].State = StateExpired
		}
	}
}

func trimApprovals(approvals *[]Approval) {
	for len(*approvals) > maxApprovalRecords {
		remove := -1
		for index, approval := range *approvals {
			if approval.State != StatePending && approval.State != StateApproved {
				remove = index
				break
			}
		}
		if remove < 0 {
			return
		}
		*approvals = append((*approvals)[:remove], (*approvals)[remove+1:]...)
	}
}

func bounded(value string, maximum int) bool {
	if value == "" || len(value) > maximum || strings.ContainsAny(value, "\r\n\x00") {
		return false
	}
	return true
}

func lowerHex(value string) bool {
	for _, character := range value {
		if (character < '0' || character > '9') && (character < 'a' || character > 'f') {
			return false
		}
	}
	return true
}
