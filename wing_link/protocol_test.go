package main

import (
	"bytes"
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
	const want = `{"protocol_version":1,"state":"healthy","hermes_installed":true,"hermes_healthy":true,"omniroute_installed":false,"omniroute_healthy":false}`
	if string(got) != want {
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

func TestRunRejectsUnknownCommands(t *testing.T) {
	var stdout, stderr bytes.Buffer
	if code := run([]string{"shell"}, &stdout, &stderr); code != 2 {
		t.Fatalf("exit code = %d", code)
	}
	if stdout.Len() != 0 {
		t.Fatalf("unexpected stdout: %q", stdout.String())
	}
	if !strings.Contains(stderr.String(), "usage: wing-link") {
		t.Fatalf("missing usage: %q", stderr.String())
	}
}

func TestRunPrintsVersion(t *testing.T) {
	var stdout, stderr bytes.Buffer
	if code := run([]string{"version"}, &stdout, &stderr); code != 0 {
		t.Fatalf("exit code = %d", code)
	}
	if stdout.String() != version+"\n" || stderr.Len() != 0 {
		t.Fatalf("stdout=%q stderr=%q", stdout.String(), stderr.String())
	}
}

func TestRunRecognizesOnlyFixedCommands(t *testing.T) {
	for _, command := range []string{"serve", "status", "pair", "start", "stop", "restart"} {
		var stdout, stderr bytes.Buffer
		if code := run([]string{command}, &stdout, &stderr); code != 1 {
			t.Fatalf("%s exit code = %d", command, code)
		}
		if stdout.Len() != 0 || !strings.Contains(stderr.String(), command+" is unavailable") {
			t.Fatalf("%s stdout=%q stderr=%q", command, stdout.String(), stderr.String())
		}
	}
}
