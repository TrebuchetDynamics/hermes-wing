package operation

import (
	"context"
	"errors"
	"sync"
)

var ErrOperationInProgress = errors.New("operation already in progress")

const maxRetainedOperations = 64

type operationRecord struct {
	latest      OperationEvent
	subscribers map[chan OperationEvent]struct{}
	cancel      context.CancelFunc
}

type OperationManager struct {
	mu         sync.Mutex
	activeID   string
	operations map[string]*operationRecord
	completed  []string
	journal    *Journal
}

func NewOperationManager() *OperationManager {
	return &OperationManager{operations: make(map[string]*operationRecord)}
}

func NewDurableOperationManager(path string) (*OperationManager, error) {
	journal, err := OpenJournal(path)
	if err != nil {
		return nil, err
	}
	manager := &OperationManager{
		operations: make(map[string]*operationRecord),
		journal:    journal,
	}
	for _, record := range journal.Records() {
		manager.operations[record.ID] = &operationRecord{
			latest:      record.Event,
			subscribers: make(map[chan OperationEvent]struct{}),
		}
		if record.Event.Terminal {
			manager.completed = append(manager.completed, record.ID)
		}
	}
	return manager, nil
}

func (m *OperationManager) Start(kind string, work func(context.Context, func(OperationEvent)) error) (string, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.activeID != "" {
		return "", ErrOperationInProgress
	}
	id, err := randomSecret(16, "op_")
	if err != nil {
		return "", err
	}
	m.startLocked(id, boundRunes(kind, 64), work)
	return id, nil
}

func (m *OperationManager) ReserveIdempotent(request IdempotencyRequest) (string, bool, error) {
	if m.journal == nil {
		return "", false, errors.New("durable operation journal is unavailable")
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	if existing, found, err := m.journal.Lookup(request); found || err != nil {
		return existing.ID, found, err
	}
	record, replayed, err := m.journal.Start(request)
	if err != nil || replayed {
		return record.ID, replayed, err
	}
	m.operations[record.ID] = &operationRecord{
		latest:      record.Event,
		subscribers: make(map[chan OperationEvent]struct{}),
	}
	return record.ID, false, nil
}

func (m *OperationManager) RunReserved(id string, work func(context.Context, func(OperationEvent)) error) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.activeID != "" {
		return ErrOperationInProgress
	}
	record, ok := m.operations[id]
	if !ok || record.latest.Terminal {
		return errors.New("reserved operation is unavailable")
	}
	if m.journal != nil {
		_ = m.journal.Update(id, PhaseApproved, OperationEvent{Phase: PhaseApproved})
	}
	m.startLocked(id, record.latest.Phase, work)
	return nil
}

func (m *OperationManager) StartIdempotent(request IdempotencyRequest, work func(context.Context, func(OperationEvent)) error) (string, bool, error) {
	id, replayed, err := m.ReserveIdempotent(request)
	if err != nil || replayed {
		return id, replayed, err
	}
	if err := m.RunReserved(id, work); err != nil {
		return "", false, err
	}
	return id, false, nil
}

func (m *OperationManager) RunReservedSync(id string, work func(context.Context, func(OperationEvent)) error) error {
	m.mu.Lock()
	if m.activeID != "" {
		m.mu.Unlock()
		return ErrOperationInProgress
	}
	record, ok := m.operations[id]
	if !ok || record.latest.Terminal {
		m.mu.Unlock()
		return errors.New("reserved operation is unavailable")
	}
	ctx, cancel := context.WithCancel(context.Background())
	record.cancel = cancel
	m.activeID = id
	if m.journal != nil {
		_ = m.journal.Update(id, PhaseRunning, OperationEvent{Phase: PhaseRunning})
	}
	m.mu.Unlock()

	var workErr error
	func() {
		defer func() {
			if recover() != nil {
				workErr = errors.New("operation panicked")
			}
		}()
		workErr = work(ctx, func(event OperationEvent) { m.emit(id, event) })
	}()
	m.complete(id, workErr)
	return workErr
}

func (m *OperationManager) startLocked(id, phase string, work func(context.Context, func(OperationEvent)) error) {
	ctx, cancel := context.WithCancel(context.Background())
	m.activeID = id
	m.operations[id] = &operationRecord{
		latest: OperationEvent{
			ProtocolVersion: ProtocolVersion,
			OperationID:     id,
			Phase:           phase,
		},
		subscribers: make(map[chan OperationEvent]struct{}),
		cancel:      cancel,
	}
	go m.run(ctx, id, work)
}

func (m *OperationManager) run(ctx context.Context, id string, work func(context.Context, func(OperationEvent)) error) {
	var workErr error
	func() {
		defer func() {
			if recover() != nil {
				workErr = errors.New("operation panicked")
			}
		}()
		workErr = work(ctx, func(event OperationEvent) { m.emit(id, event) })
	}()
	m.complete(id, workErr)
}

func (m *OperationManager) emit(id string, event OperationEvent) {
	m.mu.Lock()
	defer m.mu.Unlock()
	record, ok := m.operations[id]
	if !ok || record.latest.Terminal {
		return
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
	event.Terminal = false
	event.ErrorCode = ""
	record.latest = event
	if m.journal != nil {
		_ = m.journal.Update(id, PhaseRunning, event)
	}
	m.publish(record, event, false)
}

func (m *OperationManager) complete(id string, err error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	record, ok := m.operations[id]
	if !ok {
		return
	}
	if record.latest.Terminal {
		if m.activeID == id {
			m.activeID = ""
		}
		return
	}
	event := OperationEvent{
		ProtocolVersion: ProtocolVersion,
		OperationID:     id,
		Phase:           PhaseCommitted,
		Message:         "Complete",
		Percent:         100,
		Terminal:        true,
	}
	if err != nil {
		event.Phase = "failed"
		event.Message = "Operation failed"
		event.ErrorCode = "operation_failed"
	}
	record.latest = event
	if m.journal != nil {
		_ = m.journal.Complete(id, err)
	}
	m.publish(record, event, true)
	if m.activeID == id {
		m.activeID = ""
	}
	m.completed = append(m.completed, id)
	if len(m.completed) > maxRetainedOperations {
		oldest := m.completed[0]
		m.completed = m.completed[1:]
		delete(m.operations, oldest)
	}
}

func (m *OperationManager) publish(record *operationRecord, event OperationEvent, terminal bool) {
	for subscriber := range record.subscribers {
		if terminal {
			select {
			case subscriber <- event:
			default:
				select {
				case <-subscriber:
				default:
				}
				select {
				case subscriber <- event:
				default:
				}
			}
			close(subscriber)
			delete(record.subscribers, subscriber)
			continue
		}
		select {
		case subscriber <- event:
		default:
		}
	}
}

func (m *OperationManager) Cancel(id string) bool {
	m.mu.Lock()
	defer m.mu.Unlock()
	record, ok := m.operations[id]
	if !ok || record.latest.Terminal {
		return false
	}
	if record.cancel != nil {
		record.cancel()
	}
	event := OperationEvent{
		ProtocolVersion: ProtocolVersion,
		OperationID:     id,
		Phase:           PhaseCancelled,
		Message:         "Operation cancelled",
		Terminal:        true,
		ErrorCode:       "operation_cancelled",
	}
	record.latest = event
	if m.journal != nil {
		_ = m.journal.Cancel(id)
	}
	m.publish(record, event, true)
	m.completed = append(m.completed, id)
	if len(m.completed) > maxRetainedOperations {
		oldest := m.completed[0]
		m.completed = m.completed[1:]
		delete(m.operations, oldest)
	}
	// Keep the active slot occupied until the worker observes cancellation and exits.
	return true
}

func (m *OperationManager) Snapshot(id string) (OperationEvent, bool) {
	m.mu.Lock()
	defer m.mu.Unlock()
	record, ok := m.operations[id]
	if !ok {
		return OperationEvent{}, false
	}
	return record.latest, true
}

func (m *OperationManager) Subscribe(id string) (<-chan OperationEvent, func(), bool) {
	m.mu.Lock()
	defer m.mu.Unlock()
	record, ok := m.operations[id]
	if !ok {
		return nil, func() {}, false
	}
	subscriber := make(chan OperationEvent, 16)
	subscriber <- record.latest
	if record.latest.Terminal {
		close(subscriber)
		return subscriber, func() {}, true
	}
	record.subscribers[subscriber] = struct{}{}
	var once sync.Once
	cancel := func() {
		once.Do(func() {
			m.mu.Lock()
			defer m.mu.Unlock()
			if _, exists := record.subscribers[subscriber]; exists {
				delete(record.subscribers, subscriber)
				close(subscriber)
			}
		})
	}
	return subscriber, cancel, true
}
