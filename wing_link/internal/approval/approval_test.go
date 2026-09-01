package approval

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestRiskClassificationFailsClosedAndMatchesFixedPolicy(t *testing.T) {
	cases := map[string]RiskTier{
		OpProfileCreate:       TierRoutine,
		OpProfileCreateSecret: TierSensitive,
		OpProfileRename:       TierRoutine,
		OpProfileDelete:       TierSensitive,
		OpSetupInstall:        TierTrust,
		OpDirectoryGrant:      TierSensitive,
		OpTrustRotateIdentity: TierTrust,
		OpDeviceScopeExpand:   TierTrust,
		OpLifecycleRestart:    TierRoutine,
	}
	for operation, want := range cases {
		if got, ok := RiskOf(operation); !ok || got != want {
			t.Fatalf("RiskOf(%q) = %q, %v; want %q", operation, got, ok, want)
		}
	}
	if _, ok := RiskOf("client.supplied.risk"); ok {
		t.Fatal("unknown operation received a risk tier")
	}
}

func TestApprovalRejectsSubsecondTTLThatCannotSurviveUnixPersistence(t *testing.T) {
	store, err := Open(filepath.Join(t.TempDir(), "approvals.json"))
	if err != nil {
		t.Fatal(err)
	}
	_, err = store.Request(Request{
		DeviceID: "cred_phone", DeviceName: "Pixel", Operation: OpProfileDelete,
		Route: "DELETE /v1/profiles/qa", PayloadDigest: strings.Repeat("a", 64),
		IdempotencyKey: "delete-subsecond-1", Summary: "Delete profile qa",
	}, TierSensitive, time.Nanosecond)
	if err == nil {
		t.Fatal("subsecond TTL was accepted")
	}
}

func TestApprovalIsDigestBoundOneUseAndPersistent(t *testing.T) {
	path := filepath.Join(t.TempDir(), "approvals.json")
	store, err := Open(path)
	if err != nil {
		t.Fatal(err)
	}
	request := Request{
		DeviceID: "cred_phone", DeviceName: "Pixel", Operation: OpProfileDelete,
		Route: "/v1/profiles/qa", PayloadDigest: strings.Repeat("a", 64),
		IdempotencyKey: "delete-qa-1", Summary: "Delete profile qa",
	}
	approval, err := store.Request(request, TierSensitive, 5*time.Minute)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := store.Decide(approval.ID, true); err != nil {
		t.Fatal(err)
	}

	reopened, err := Open(path)
	if err != nil {
		t.Fatal(err)
	}
	consumed, err := reopened.Consume(request.DeviceID, request.Route, request.PayloadDigest, request.IdempotencyKey)
	if err != nil || consumed.State != StateConsumed {
		t.Fatalf("consume = %#v, %v", consumed, err)
	}
	if _, err := reopened.Consume(request.DeviceID, request.Route, request.PayloadDigest, request.IdempotencyKey); !errors.Is(err, ErrApprovalRequired) {
		t.Fatalf("second consume error = %v", err)
	}
	if _, err := reopened.Consume(request.DeviceID, request.Route, strings.Repeat("b", 64), request.IdempotencyKey); !errors.Is(err, ErrApprovalRequired) {
		t.Fatalf("changed digest error = %v", err)
	}
	info, err := os.Stat(path)
	if err != nil || info.Mode().Perm()&0o077 != 0 {
		t.Fatalf("approval mode = %v, err=%v", info.Mode(), err)
	}
}

func TestRejectedApprovalCanBeReplacedByAOneUseHostDecision(t *testing.T) {
	store, err := Open(filepath.Join(t.TempDir(), "approvals.json"))
	if err != nil {
		t.Fatal(err)
	}
	request := Request{
		DeviceID: "cred_phone", DeviceName: "Pixel", Operation: OpProfileDelete,
		Route: "DELETE /v1/profiles/qa", PayloadDigest: strings.Repeat("e", 64),
		IdempotencyKey: "delete-qa-2", Summary: "Delete profile qa",
	}
	first, err := store.Request(request, TierSensitive, time.Minute)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := store.Decide(first.ID, false); err != nil {
		t.Fatal(err)
	}
	second, err := store.Request(request, TierSensitive, time.Minute)
	if err != nil || second.ID == first.ID {
		t.Fatalf("replacement=%#v err=%v", second, err)
	}
	if _, err := store.Decide(second.ID, true); err != nil {
		t.Fatal(err)
	}
	if _, err := store.Consume(request.DeviceID, request.Route, request.PayloadDigest, request.IdempotencyKey); err != nil {
		t.Fatal(err)
	}
}

func TestApprovalBindsDeduplicationAndConsumptionToIdempotencyKey(t *testing.T) {
	store, err := Open(filepath.Join(t.TempDir(), "approvals.json"))
	if err != nil {
		t.Fatal(err)
	}
	request := Request{
		DeviceID: "cred_phone", DeviceName: "Pixel", Operation: OpProfileDelete,
		Route: "DELETE /v1/profiles/qa", PayloadDigest: strings.Repeat("f", 64),
		IdempotencyKey: "delete-exact-1", Summary: "Delete profile qa",
	}
	first, err := store.Request(request, TierSensitive, time.Minute)
	if err != nil {
		t.Fatal(err)
	}
	changed := request
	changed.IdempotencyKey = "delete-exact-2"
	second, err := store.Request(changed, TierSensitive, time.Minute)
	if err != nil || second.ID == first.ID {
		t.Fatalf("changed-key approval=%#v err=%v", second, err)
	}
	if _, err := store.Decide(first.ID, true); err != nil {
		t.Fatal(err)
	}
	if _, err := store.Consume(request.DeviceID, request.Route, request.PayloadDigest, changed.IdempotencyKey); !errors.Is(err, ErrApprovalRequired) {
		t.Fatalf("changed key consumed approval: %v", err)
	}
	if _, err := store.Consume(request.DeviceID, request.Route, request.PayloadDigest, request.IdempotencyKey); err != nil {
		t.Fatal(err)
	}
}

func TestLegacyApprovalLoadsButCannotAuthorizeKeyedMutation(t *testing.T) {
	path := filepath.Join(t.TempDir(), "approvals.json")
	now := time.Now().UTC()
	payload, err := json.Marshal(persistedWire{Schema: approvalSchema, Approvals: []Approval{{
		ID: "appr_legacy", Tier: TierSensitive, State: StateApproved,
		CreatedAt: now.Unix(), ExpiresAt: now.Add(time.Minute).Unix(),
		Request: Request{
			DeviceID: "cred_phone", DeviceName: "Pixel", Operation: OpProfileDelete,
			Route: "DELETE /v1/profiles/qa", PayloadDigest: strings.Repeat("a", 64),
			Summary: "Legacy delete",
		},
	}}})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, payload, 0o600); err != nil {
		t.Fatal(err)
	}
	store, err := Open(path)
	if err != nil {
		t.Fatalf("legacy load failed: %v", err)
	}
	if _, err := store.Consume("cred_phone", "DELETE /v1/profiles/qa", strings.Repeat("a", 64), "delete-new-1"); !errors.Is(err, ErrApprovalRequired) {
		t.Fatalf("legacy approval authorized keyed request: %v", err)
	}
}

func TestApprovalExpiresAndStoredMetadataIsBoundedAndRedacted(t *testing.T) {
	path := filepath.Join(t.TempDir(), "approvals.json")
	store, err := Open(path)
	if err != nil {
		t.Fatal(err)
	}
	now := time.Unix(1_800_000_000, 0).UTC()
	store.now = func() time.Time { return now }
	approval, err := store.Request(Request{
		DeviceID: "cred_phone", DeviceName: strings.Repeat("P", 200),
		Operation: OpSetupInstall, Route: "/v1/setup",
		PayloadDigest:  strings.Repeat("c", 64),
		IdempotencyKey: "setup-install-1",
		Summary:        "token=wlc_secret " + strings.Repeat("x", 500),
	}, TierTrust, time.Minute)
	if err != nil {
		t.Fatal(err)
	}
	now = now.Add(2 * time.Minute)
	if _, err := store.Decide(approval.ID, true); !errors.Is(err, ErrApprovalRequired) {
		t.Fatalf("expired decision error = %v", err)
	}
	contents, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(contents), "wlc_secret") || len(contents) > maxApprovalBytes {
		t.Fatalf("approval metadata was unsafe or unbounded: %s", contents)
	}
}
