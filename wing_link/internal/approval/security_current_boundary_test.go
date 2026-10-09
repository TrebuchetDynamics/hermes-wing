package approval

import (
	"errors"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// A mismatch must be rejected while the approval is still spendable, and must
// not consume it. Testing mismatches only after consumption hides broken binding.
func TestCurrentSecurityApprovalMismatchPreservesExactUnspentRequest(t *testing.T) {
	for _, field := range []string{"device", "route", "digest", "key"} {
		t.Run(field, func(t *testing.T) {
			path := filepath.Join(t.TempDir(), "approvals.json")
			store, err := Open(path)
			if err != nil {
				t.Fatal(err)
			}
			request := Request{
				DeviceID: "cred_control", DeviceName: "Synthetic control",
				Operation: OpProfileDelete, Route: "DELETE /v1/profiles/control",
				PayloadDigest: strings.Repeat("a", 64), IdempotencyKey: "control-delete-1",
				Summary: "Delete synthetic profile",
			}
			pending, err := store.Request(request, TierSensitive, 5*time.Minute)
			if err != nil {
				t.Fatal(err)
			}
			if _, err := store.Decide(pending.ID, true); err != nil {
				t.Fatal(err)
			}
			changed := request
			switch field {
			case "device":
				changed.DeviceID = "cred_other"
			case "route":
				changed.Route = "DELETE /v1/profiles/other"
			case "digest":
				changed.PayloadDigest = strings.Repeat("b", 64)
			case "key":
				changed.IdempotencyKey = "control-delete-2"
			}
			if _, err := store.Consume(changed.DeviceID, changed.Route, changed.PayloadDigest, changed.IdempotencyKey); !errors.Is(err, ErrApprovalRequired) {
				t.Fatalf("mismatched %s authorized an unspent approval: %v", field, err)
			}
			// Reopen to verify rejection preserved the durable approval, not just
			// an in-memory object, before accepting the original exact request.
			reopened, err := Open(path)
			if err != nil {
				t.Fatal(err)
			}
			rows, err := reopened.List()
			if err != nil || len(rows) != 1 || rows[0].ID != pending.ID || rows[0].State != StateApproved {
				t.Fatalf("mismatch did not preserve approved state: rows=%v err=%v", rows, err)
			}
			consumed, err := reopened.Consume(request.DeviceID, request.Route, request.PayloadDigest, request.IdempotencyKey)
			if err != nil || consumed.ID != pending.ID || consumed.State != StateConsumed {
				t.Fatalf("exact request could not consume original approval: state=%v err=%v", consumed.State, err)
			}
			if _, err := reopened.Consume(request.DeviceID, request.Route, request.PayloadDigest, request.IdempotencyKey); !errors.Is(err, ErrApprovalRequired) {
				t.Fatalf("exact request reused consumed approval: %v", err)
			}
		})
	}
}
