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
}

type OperationManager struct {
	mu         sync.Mutex
	activeID   string
	operations map[string]*operationRecord
	completed  []string
}

func NewOperationManager() *OperationManager {
	return &OperationManager{operations: make(map[string]*operationRecord)}
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
	m.activeID = id
	m.operations[id] = &operationRecord{
		latest: OperationEvent{
			ProtocolVersion: ProtocolVersion,
			OperationID:     id,
			Phase:           boundRunes(kind, 64),
		},
		subscribers: make(map[chan OperationEvent]struct{}),
	}
	go m.run(id, work)
	return id, nil
}

func (m *OperationManager) run(id string, work func(context.Context, func(OperationEvent)) error) {
	var workErr error
	func() {
		defer func() {
			if recover() != nil {
				workErr = errors.New("operation panicked")
			}
		}()
		workErr = work(context.Background(), func(event OperationEvent) { m.emit(id, event) })
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
	m.publish(record, event, false)
}

func (m *OperationManager) complete(id string, err error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	record, ok := m.operations[id]
	if !ok {
		return
	}
	event := OperationEvent{
		ProtocolVersion: ProtocolVersion,
		OperationID:     id,
		Phase:           "complete",
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
