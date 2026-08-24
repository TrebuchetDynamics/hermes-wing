package operation

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
)

func TestJournalReplaysSameIdempotentRequestAndRejectsChangedPayload(t *testing.T) {
	path := filepath.Join(t.TempDir(), "operations.json")
	journal, err := OpenJournal(path)
	if err != nil {
		t.Fatal(err)
	}
	digest := sha256.Sum256([]byte(`{"action":"restart"}`))
	request := IdempotencyRequest{
		DeviceID:      "cred_phone",
		Route:         "POST /v1/setup",
		Key:           "retry-1",
		PayloadDigest: hex.EncodeToString(digest[:]),
		Kind:          "setup",
	}
	first, replayed, err := journal.Start(request)
	if err != nil || replayed {
		t.Fatalf("first start replayed=%v err=%v", replayed, err)
	}
	second, replayed, err := journal.Start(request)
	if err != nil || !replayed || second.ID != first.ID {
		t.Fatalf("retry = %#v replayed=%v err=%v", second, replayed, err)
	}
	changed := request
	changed.PayloadDigest = strings.Repeat("a", 64)
	if _, _, err := journal.Start(changed); !errors.Is(err, ErrIdempotencyConflict) {
		t.Fatalf("changed payload error = %v", err)
	}
}

func TestJournalRecoversInterruptedOperationsWithoutPersistingPayloads(t *testing.T) {
	path := filepath.Join(t.TempDir(), "operations.json")
	journal, err := OpenJournal(path)
	if err != nil {
		t.Fatal(err)
	}
	secretPayload := `{"provider_api_key":"must-not-persist"}`
	digest := sha256.Sum256([]byte(secretPayload))
	record, _, err := journal.Start(IdempotencyRequest{
		DeviceID:      "cred_phone",
		Route:         "POST /v1/setup",
		Key:           "retry-secret",
		PayloadDigest: hex.EncodeToString(digest[:]),
		Kind:          "setup",
	})
	if err != nil {
		t.Fatal(err)
	}

	reopened, err := OpenJournal(path)
	if err != nil {
		t.Fatal(err)
	}
	recovered, ok := reopened.Snapshot(record.ID)
	if !ok || !recovered.Event.Terminal || recovered.Event.ErrorCode != "operation_interrupted" || recovered.Phase != PhaseFailed {
		t.Fatalf("recovered record = %#v, ok=%v", recovered, ok)
	}
	contents, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(contents), "must-not-persist") || strings.Contains(string(contents), "provider_api_key") {
		t.Fatalf("journal persisted request payload: %s", contents)
	}
}

func TestJournalBoundsTerminalRetention(t *testing.T) {
	journal, err := OpenJournal(filepath.Join(t.TempDir(), "operations.json"))
	if err != nil {
		t.Fatal(err)
	}
	var first, last string
	for index := 0; index <= maxJournalRecords; index++ {
		digest := sha256.Sum256([]byte{byte(index)})
		record, _, err := journal.Start(IdempotencyRequest{
			DeviceID:      "cred_phone",
			Route:         "POST /v1/setup",
			Key:           "key-" + strconv.Itoa(index),
			PayloadDigest: hex.EncodeToString(digest[:]),
			Kind:          "setup",
		})
		if err != nil {
			t.Fatal(err)
		}
		if index == 0 {
			first = record.ID
		}
		last = record.ID
		if err := journal.Complete(record.ID, nil); err != nil {
			t.Fatal(err)
		}
	}
	if _, ok := journal.Snapshot(first); ok {
		t.Fatal("oldest terminal record was retained")
	}
	if _, ok := journal.Snapshot(last); !ok {
		t.Fatal("latest terminal record was evicted")
	}
}
