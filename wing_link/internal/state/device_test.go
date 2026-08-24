package state

import (
	"crypto/ed25519"
	"crypto/rand"
	"errors"
	"os"
	"strings"
	"testing"
	"time"
)

func TestPendingCredentialAcknowledgmentRecoversAfterRestartWithoutRawTokenAtRest(t *testing.T) {
	now := time.Unix(1_000, 0).UTC()
	store := newTestStateStore(t, func() time.Time { return now })
	id, token, err := store.StageBearerDeviceCredential("Restarting phone", []string{ScopeHealthRead})
	if err != nil {
		t.Fatal(err)
	}
	payload, err := os.ReadFile(store.path)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(payload), token) {
		t.Fatal("raw pending bearer credential persisted")
	}
	restarted := New(store.path)
	restarted.now = func() time.Time { return now.Add(time.Minute) }
	if !restarted.AuthorizePending(id, token) {
		t.Fatal("pending credential did not recover after restart")
	}
	if restarted.Authorize(token) {
		t.Fatal("pending credential became authoritative before acknowledgment")
	}
	if err := restarted.AcknowledgeControlToken(id, token); err != nil {
		t.Fatal(err)
	}
	if !restarted.Authorize(token) {
		t.Fatal("recovered credential was not authoritative after acknowledgment")
	}
	updated, err := os.ReadFile(store.path)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(updated), `"pending_devices"`) {
		t.Fatal("committed credential retained pending transaction")
	}
}

func TestDeviceCredentialAcknowledgmentAuthorizesExactScopes(t *testing.T) {
	now := time.Unix(1_000, 0).UTC()
	store := newTestStateStore(t, func() time.Time { return now })
	publicKey, _, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	id, token, err := store.StageDeviceCredential("Pixel 9", publicKey, []string{ScopeHealthRead, ScopeLifecycleWrite})
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := store.AuthorizeDevice(token, ScopeHealthRead); ok {
		t.Fatal("pending credential received active authorization")
	}
	if err := store.AcknowledgeControlToken(id, token); err != nil {
		t.Fatal(err)
	}

	authorization, ok := store.AuthorizeDevice(token, ScopeHealthRead)
	if !ok {
		t.Fatal("acknowledged device was rejected")
	}
	if authorization.Device.ID != id || authorization.Device.Name != "Pixel 9" || authorization.Device.Legacy {
		t.Fatalf("unexpected device authorization: %+v", authorization.Device)
	}
	if _, ok := store.AuthorizeDevice(token, ScopeDiagnosticsRead); ok {
		t.Fatal("device received an ungranted scope")
	}
}

func TestDeviceCredentialCanBeRevokedIndividually(t *testing.T) {
	store := newTestStateStore(t, time.Now)
	firstID, firstToken, err := store.StageControlToken()
	if err != nil {
		t.Fatal(err)
	}
	if err := store.AcknowledgeControlToken(firstID, firstToken); err != nil {
		t.Fatal(err)
	}
	secondID, secondToken, err := store.StageControlToken()
	if err != nil {
		t.Fatal(err)
	}
	if err := store.AcknowledgeControlToken(secondID, secondToken); err != nil {
		t.Fatal(err)
	}

	if err := store.RevokeDevice(firstID); err != nil {
		t.Fatal(err)
	}
	if store.Authorize(firstToken) {
		t.Fatal("revoked device remained authorized")
	}
	if !store.Authorize(secondToken) {
		t.Fatal("individual revocation removed another device")
	}
}

func TestListDevicesNeverExposesTokenHashes(t *testing.T) {
	store := newTestStateStore(t, time.Now)
	id, token, err := store.StageControlToken()
	if err != nil {
		t.Fatal(err)
	}
	if err := store.AcknowledgeControlToken(id, token); err != nil {
		t.Fatal(err)
	}
	devices, err := store.ListDevices()
	if err != nil {
		t.Fatal(err)
	}
	if len(devices) != 1 || devices[0].ID != id || devices[0].Name == "" {
		t.Fatalf("devices = %+v", devices)
	}
	if devices[0].TokenHash != "" {
		t.Fatal("public device inventory exposed a token hash")
	}
}

func TestStageDeviceCredentialRejectsInvalidMetadata(t *testing.T) {
	store := newTestStateStore(t, time.Now)
	publicKey, _, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	cases := []struct {
		name   string
		key    ed25519.PublicKey
		scopes []string
	}{
		{name: "", key: publicKey, scopes: []string{ScopeHealthRead}},
		{name: string(make([]rune, 81)), key: publicKey, scopes: []string{ScopeHealthRead}},
		{name: "Phone", key: ed25519.PublicKey("short"), scopes: []string{ScopeHealthRead}},
		{name: "Phone", key: publicKey, scopes: nil},
		{name: "Phone", key: publicKey, scopes: []string{"shell:write"}},
		{name: "Phone", key: publicKey, scopes: []string{ScopeHealthRead, ScopeHealthRead}},
	}
	for _, testCase := range cases {
		if _, _, err := store.StageDeviceCredential(testCase.name, testCase.key, testCase.scopes); err == nil {
			t.Fatalf("accepted invalid device metadata: %+v", testCase)
		}
	}
}

func TestExpiredDeviceCredentialFailsClosed(t *testing.T) {
	now := time.Unix(1_000, 0).UTC()
	store := newTestStateStore(t, func() time.Time { return now })
	id, token, err := store.stageDeviceCredential("Temporary", nil, allControlScopes, time.Minute, true)
	if err != nil {
		t.Fatal(err)
	}
	if err := store.AcknowledgeControlToken(id, token); err != nil {
		t.Fatal(err)
	}
	now = now.Add(time.Minute)
	if _, ok := store.AuthorizeDevice(token, ScopeHealthRead); ok {
		t.Fatal("expired device remained authorized")
	}
}

func TestRevokeUnknownDeviceReportsNotFound(t *testing.T) {
	store := newTestStateStore(t, time.Now)
	if err := store.RevokeDevice("cred_missing"); !errors.Is(err, ErrDeviceNotFound) {
		t.Fatalf("RevokeDevice error = %v", err)
	}
}
