package operation

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestManagerRejectsConcurrentInstall(t *testing.T) {
	manager := NewOperationManager()
	release := make(chan struct{})
	id, err := manager.Start("install", func(context.Context, func(OperationEvent)) error {
		<-release
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := manager.Start("install", func(context.Context, func(OperationEvent)) error { return nil }); !errors.Is(err, ErrOperationInProgress) {
		t.Fatalf("got %v", err)
	}
	close(release)
	waitForTerminal(t, manager, id)
}

func TestManagerRetainsNormalizedTerminalSnapshot(t *testing.T) {
	manager := NewOperationManager()
	id, err := manager.Start("install", func(_ context.Context, emit func(OperationEvent)) error {
		emit(OperationEvent{
			ProtocolVersion: 99,
			OperationID:     "wrong",
			Phase:           "download",
			Message:         strings.Repeat("x", 300),
			Percent:         200,
			Terminal:        true,
		})
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	event := waitForTerminal(t, manager, id)
	if event.ProtocolVersion != ProtocolVersion || event.OperationID != id || event.Phase != PhaseCommitted || !event.Terminal || event.Percent != 100 {
		t.Fatalf("event = %#v", event)
	}
	if len([]rune(event.Message)) > 240 {
		t.Fatalf("message length = %d", len([]rune(event.Message)))
	}
}

func TestManagerDeliversTerminalEventToSlowSubscriber(t *testing.T) {
	manager := NewOperationManager()
	release := make(chan struct{})
	id, err := manager.Start("install", func(_ context.Context, emit func(OperationEvent)) error {
		for index := 0; index < 40; index++ {
			emit(OperationEvent{Phase: "download", Percent: index})
		}
		<-release
		return errors.New("failed")
	})
	if err != nil {
		t.Fatal(err)
	}
	events, cancel, ok := manager.Subscribe(id)
	if !ok {
		t.Fatal("operation missing")
	}
	defer cancel()
	close(release)
	var terminal OperationEvent
	for event := range events {
		if event.Terminal {
			terminal = event
		}
	}
	if !terminal.Terminal || terminal.ErrorCode != "operation_failed" {
		t.Fatalf("terminal = %#v", terminal)
	}
}

func TestManagerAllowsNextOperationAfterCompletion(t *testing.T) {
	manager := NewOperationManager()
	id, err := manager.Start("first", func(context.Context, func(OperationEvent)) error { return nil })
	if err != nil {
		t.Fatal(err)
	}
	waitForTerminal(t, manager, id)
	if _, err := manager.Start("second", func(context.Context, func(OperationEvent)) error { return nil }); err != nil {
		t.Fatal(err)
	}
}

func TestDurableManagerReplaysIdempotentWorkAndCancelsByContext(t *testing.T) {
	path := filepath.Join(t.TempDir(), "operations.json")
	manager, err := NewDurableOperationManager(path)
	if err != nil {
		t.Fatal(err)
	}
	digest := sha256.Sum256([]byte(`{}`))
	request := IdempotencyRequest{
		DeviceID: "cred_phone", Route: "POST /v1/setup", Key: "retry-1",
		PayloadDigest: hex.EncodeToString(digest[:]), Kind: "setup",
	}
	started := make(chan struct{})
	id, replayed, err := manager.StartIdempotent(request, func(ctx context.Context, emit func(OperationEvent)) error {
		close(started)
		<-ctx.Done()
		return ctx.Err()
	})
	if err != nil || replayed {
		t.Fatalf("start id=%q replayed=%v err=%v", id, replayed, err)
	}
	<-started
	replayedID, replayed, err := manager.StartIdempotent(request, func(context.Context, func(OperationEvent)) error {
		t.Fatal("idempotent retry executed duplicate work")
		return nil
	})
	if err != nil || !replayed || replayedID != id {
		t.Fatalf("retry id=%q replayed=%v err=%v", replayedID, replayed, err)
	}
	if !manager.Cancel(id) {
		t.Fatal("active operation was not cancelled")
	}
	event, ok := manager.Snapshot(id)
	if !ok || !event.Terminal || event.ErrorCode != "operation_cancelled" {
		t.Fatalf("cancelled event = %#v, ok=%v", event, ok)
	}

	reopened, err := NewDurableOperationManager(path)
	if err != nil {
		t.Fatal(err)
	}
	replayedID, replayed, err = reopened.StartIdempotent(request, func(context.Context, func(OperationEvent)) error {
		t.Fatal("terminal replay executed duplicate work")
		return nil
	})
	if err != nil || !replayed || replayedID != id {
		t.Fatalf("terminal replay id=%q replayed=%v err=%v", replayedID, replayed, err)
	}
}

func TestManagerBoundsCompletedOperationRetention(t *testing.T) {
	manager := NewOperationManager()
	var first, last string
	for index := 0; index <= maxRetainedOperations; index++ {
		id, err := manager.Start("install", func(context.Context, func(OperationEvent)) error { return nil })
		if err != nil {
			t.Fatal(err)
		}
		waitForTerminal(t, manager, id)
		if index == 0 {
			first = id
		}
		last = id
	}
	if _, ok := manager.Snapshot(first); ok {
		t.Fatal("oldest completed operation was retained")
	}
	if _, ok := manager.Snapshot(last); !ok {
		t.Fatal("latest completed operation was evicted")
	}
}

func waitForTerminal(t *testing.T, manager *OperationManager, id string) OperationEvent {
	t.Helper()
	deadline := time.Now().Add(2 * time.Second)
	for time.Now().Before(deadline) {
		if event, ok := manager.Snapshot(id); ok && event.Terminal {
			return event
		}
		time.Sleep(time.Millisecond)
	}
	t.Fatal("operation did not finish")
	return OperationEvent{}
}
