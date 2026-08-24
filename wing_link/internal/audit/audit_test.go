package audit

import (
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func validInput() Input {
	return Input{
		DeviceID:           "cred_phone",
		Operation:          "profile.delete",
		ApprovalSource:     SourceHostCLI,
		Result:             ResultSuccess,
		ProtocolGeneration: 2,
		Duration:           25 * time.Millisecond,
	}
}

func TestAuditPersistsOnlyAllowlistedBoundedFieldsOwnerOnly(t *testing.T) {
	path := filepath.Join(t.TempDir(), "audit.jsonl")
	log, err := Open(path)
	if err != nil {
		t.Fatal(err)
	}
	log.now = func() time.Time { return time.Unix(1_800_000_000, 0) }
	if err := log.Append(validInput()); err != nil {
		t.Fatal(err)
	}
	reopened, err := Open(path)
	if err != nil {
		t.Fatal(err)
	}
	events, err := reopened.List()
	if err != nil || len(events) != 1 {
		t.Fatalf("events=%#v err=%v", events, err)
	}
	event := events[0]
	if event.Timestamp != 1_800_000_000 || event.RiskTier != TierSensitive || event.DurationMS != 25 {
		t.Fatalf("event=%#v", event)
	}
	info, err := os.Stat(path)
	if err != nil || info.Mode().Perm()&0o077 != 0 {
		t.Fatalf("mode=%v err=%v", info.Mode(), err)
	}
	contents, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	for _, forbidden := range []string{"request_body", "authorization", "token", "host_path"} {
		if strings.Contains(string(contents), forbidden) {
			t.Fatalf("audit log contains forbidden field %q: %s", forbidden, contents)
		}
	}
}

func TestAuditRejectsSecretsPathsPairingCodesAndUnknownOperations(t *testing.T) {
	path := filepath.Join(t.TempDir(), "audit.jsonl")
	log, err := Open(path)
	if err != nil {
		t.Fatal(err)
	}
	for _, hostile := range []string{
		"wlc_secret", "pairing-code-123", "/home/alice/private", "cred_ok\nforged", strings.Repeat("界", 5000),
	} {
		input := validInput()
		input.DeviceID = hostile
		input.Secrets = []string{hostile}
		if err := log.Append(input); !errors.Is(err, ErrInvalidEvent) {
			t.Fatalf("hostile %q error=%v", hostile, err)
		}
	}
	input := validInput()
	input.Operation = "client.supplied.operation"
	if err := log.Append(input); !errors.Is(err, ErrUnknownOperation) {
		t.Fatalf("unknown operation error=%v", err)
	}
	if contents, err := os.ReadFile(path); err == nil && len(contents) != 0 {
		t.Fatalf("rejected events reached disk: %s", contents)
	}
}

func TestAuditRollsOldestEventsAndRequiresConfirmedClear(t *testing.T) {
	path := filepath.Join(t.TempDir(), "audit.jsonl")
	log, err := Open(path)
	if err != nil {
		t.Fatal(err)
	}
	log.maxEvents = 3
	for index := 0; index < 5; index++ {
		input := validInput()
		input.Duration = time.Duration(index) * time.Millisecond
		if err := log.Append(input); err != nil {
			t.Fatal(err)
		}
	}
	events, err := log.List()
	if err != nil || len(events) != 3 || events[0].DurationMS != 2 || events[2].DurationMS != 4 {
		t.Fatalf("rolled events=%#v err=%v", events, err)
	}
	if err := log.Clear(false); !errors.Is(err, ErrClearRequiresConfirmation) {
		t.Fatalf("unconfirmed clear error=%v", err)
	}
	if err := log.Clear(true); err != nil {
		t.Fatal(err)
	}
	events, err = log.List()
	if err != nil || len(events) != 0 {
		t.Fatalf("cleared events=%#v err=%v", events, err)
	}
}

func TestAuditFailsClosedOnTamperedCompleteLineButDropsTornTail(t *testing.T) {
	path := filepath.Join(t.TempDir(), "audit.jsonl")
	log, err := Open(path)
	if err != nil {
		t.Fatal(err)
	}
	if err := log.Append(validInput()); err != nil {
		t.Fatal(err)
	}
	file, err := os.OpenFile(path, os.O_APPEND|os.O_WRONLY, 0)
	if err != nil {
		t.Fatal(err)
	}
	_, _ = file.WriteString(`{"authorization":"Bearer secret"}`)
	_ = file.Close()
	reopened, err := Open(path)
	if err != nil {
		t.Fatal(err)
	}
	events, err := reopened.List()
	if err != nil || len(events) != 1 {
		t.Fatalf("torn-tail events=%#v err=%v", events, err)
	}
	if err := os.WriteFile(path, []byte("{\"authorization\":\"Bearer secret\"}\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := Open(path); !errors.Is(err, ErrInvalidLog) {
		t.Fatalf("tampered complete line error=%v", err)
	}
}
