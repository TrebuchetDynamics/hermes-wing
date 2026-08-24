package protocol

import (
	"encoding/json"
	"strings"
	"testing"
	"unicode/utf8"
)

func TestInstallRequestRejectsUnknownComponent(t *testing.T) {
	var request InstallRequest
	if err := json.Unmarshal([]byte(`{"components":["hermes","unknown"]}`), &request); err != nil {
		t.Fatal(err)
	}
	if err := request.Validate(); err == nil {
		t.Fatal("expected rejection")
	}
}

func TestInstallRequestRequiresAComponent(t *testing.T) {
	if err := (InstallRequest{}).Validate(); err == nil {
		t.Fatal("expected empty request rejection")
	}
}

func TestInstallRequestRejectsDuplicateComponents(t *testing.T) {
	request := InstallRequest{Components: []Component{ComponentHermes, ComponentHermes}}
	if err := request.Validate(); err == nil {
		t.Fatal("expected duplicate component rejection")
	}
}

func TestInstallRequestRequiresHermesForOmniRoute(t *testing.T) {
	request := InstallRequest{
		Components:                   []Component{ComponentOmniRoute},
		AcceptCommunityProviderTerms: true,
	}
	if err := request.Validate(); err == nil {
		t.Fatal("expected Hermes requirement")
	}
}

func TestInstallRequestRequiresCommunityProviderConsent(t *testing.T) {
	request := InstallRequest{Components: []Component{ComponentHermes, ComponentOmniRoute}}
	if err := request.Validate(); err == nil {
		t.Fatal("expected community provider consent requirement")
	}
}

func TestInstallRequestAcceptsSupportedComponents(t *testing.T) {
	requests := []InstallRequest{
		{Components: []Component{ComponentHermes}},
		{
			Components:                   []Component{ComponentHermes, ComponentOmniRoute},
			AcceptCommunityProviderTerms: true,
		},
	}
	for _, request := range requests {
		if err := request.Validate(); err != nil {
			t.Fatalf("valid request rejected: %v", err)
		}
	}
}

func TestInstallRequestRequiresStarterProfileConsent(t *testing.T) {
	request := InstallRequest{
		Components: []Component{ComponentHermes, ComponentStarterProfile},
	}
	if err := request.Validate(); err == nil {
		t.Fatal("expected starter profile consent requirement")
	}
	request.AcceptStarterProfileTerms = true
	if err := request.Validate(); err != nil {
		t.Fatalf("consented starter profile rejected: %v", err)
	}
}

func TestInstallRequestRequiresHermesForStarterProfile(t *testing.T) {
	request := InstallRequest{
		Components:                []Component{ComponentStarterProfile},
		AcceptStarterProfileTerms: true,
	}
	if err := request.Validate(); err == nil {
		t.Fatal("expected Hermes requirement")
	}
}

func TestOperationEventJSON(t *testing.T) {
	event := OperationEvent{
		ProtocolVersion: 1,
		OperationID:     "op_1",
		Phase:           "download",
		Message:         "Downloading Hermes",
		Percent:         25,
	}
	got, err := json.Marshal(event)
	if err != nil {
		t.Fatal(err)
	}
	const want = `{"protocol_version":1,"operation_id":"op_1","phase":"download","message":"Downloading Hermes","percent":25}`
	if string(got) != want {
		t.Fatalf("got %s", got)
	}
}

func TestOperationEventJSONBoundsMessagesByRune(t *testing.T) {
	got, err := json.Marshal(OperationEvent{Message: strings.Repeat("é", 300)})
	if err != nil {
		t.Fatal(err)
	}
	var decoded map[string]any
	if err := json.Unmarshal(got, &decoded); err != nil {
		t.Fatal(err)
	}
	message, ok := decoded["message"].(string)
	if !ok {
		t.Fatal("message is not a string")
	}
	if count := utf8.RuneCountInString(message); count != 240 {
		t.Fatalf("message has %d runes", count)
	}
}

func TestInstallStatusJSONOmitsEmptyOptionalFields(t *testing.T) {
	status := InstallStatus{
		ProtocolVersion: ProtocolVersion,
		State:           RuntimeHealthy,
		HermesInstalled: true,
		HermesHealthy:   true,
	}
	got, err := json.Marshal(status)
	if err != nil {
		t.Fatal(err)
	}
	const want = `{"protocol_version":2,"state":"healthy","hermes_installed":true,"hermes_healthy":true,"starter_profile_installed":false,"omniroute_installed":false,"omniroute_healthy":false}`
	if string(got) != want {
		t.Fatalf("got %s", got)
	}
}

func TestInstallStatusReportsStarterProfile(t *testing.T) {
	got, err := json.Marshal(InstallStatus{
		ProtocolVersion:         ProtocolVersion,
		State:                   RuntimeHealthy,
		HermesInstalled:         true,
		HermesHealthy:           true,
		StarterProfileInstalled: true,
		StarterProfileName:      "donna",
	})
	if err != nil {
		t.Fatal(err)
	}
	var decoded map[string]any
	if err := json.Unmarshal(got, &decoded); err != nil {
		t.Fatal(err)
	}
	if decoded["starter_profile_installed"] != true || decoded["starter_profile_name"] != "donna" {
		t.Fatalf("got %s", got)
	}
}

func TestInstallStatusReportsStarterProfileBlocker(t *testing.T) {
	got, err := json.Marshal(InstallStatus{
		ProtocolVersion:             ProtocolVersion,
		State:                       RuntimeHealthy,
		HermesInstalled:             true,
		HermesHealthy:               true,
		StarterProfileBlockedReason: "missing_distribution_manifest",
	})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(got), `"starter_profile_blocked_reason":"missing_distribution_manifest"`) {
		t.Fatalf("got %s", got)
	}
}

func TestAPIErrorJSON(t *testing.T) {
	got, err := json.Marshal(APIError{Code: "invalid_request", Message: "Invalid install request"})
	if err != nil {
		t.Fatal(err)
	}
	const want = `{"code":"invalid_request","message":"Invalid install request"}`
	if string(got) != want {
		t.Fatalf("got %s", got)
	}
}

func TestAPIErrorJSONBoundsMessages(t *testing.T) {
	got, err := json.Marshal(APIError{Code: "failed", Message: strings.Repeat("x", 300)})
	if err != nil {
		t.Fatal(err)
	}
	var decoded map[string]any
	if err := json.Unmarshal(got, &decoded); err != nil {
		t.Fatal(err)
	}
	if message := decoded["message"].(string); len(message) != 240 {
		t.Fatalf("message length = %d", len(message))
	}
}
