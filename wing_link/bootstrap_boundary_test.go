package main

import (
	"context"
	"reflect"
	"testing"
)

func TestBootstrapRunsOnlySupervisorOwnedStages(t *testing.T) {
	var stages []string
	manager := &BootstrapManager{
		EnsureHermes: func(context.Context, func(OperationEvent)) (HermesInspection, error) {
			stages = append(stages, "hermes")
			return HermesInspection{Executable: "/safe/hermes", Adopted: true}, nil
		},
		EnsureAPIKey: func(context.Context) error {
			stages = append(stages, "authentication")
			return nil
		},
		EnsureAPIEndpoint: func(context.Context) error {
			stages = append(stages, "api_endpoint")
			return nil
		},
		StartGateway: func(context.Context) error {
			stages = append(stages, "gateway")
			return nil
		},
		VerifyGateway: func(context.Context) error {
			stages = append(stages, "health")
			return nil
		},
	}

	result, err := manager.Bootstrap(context.Background(), BootstrapRequest{}, nil)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(stages, []string{"hermes", "authentication", "api_endpoint", "gateway", "health"}) {
		t.Fatalf("stages = %#v", stages)
	}
	if !result.HermesInstalled || !result.HermesAdopted || !result.GatewayStarted {
		t.Fatalf("result = %#v", result)
	}
}

func TestBootstrapRequestHasNoRuntimeDomainFields(t *testing.T) {
	requestType := reflect.TypeOf(BootstrapRequest{})
	for _, forbidden := range []string{"Profile", "Provider", "Model", "Configuration"} {
		if _, exists := requestType.FieldByName(forbidden); exists {
			t.Fatalf("bootstrap request exposes runtime-owned field %q", forbidden)
		}
	}
}

func TestBootstrapResultHasNoRuntimeDomainFields(t *testing.T) {
	resultType := reflect.TypeOf(BootstrapResult{})
	for _, forbidden := range []string{"Profile", "Provider", "Model", "Configuration"} {
		if _, exists := resultType.FieldByName(forbidden); exists {
			t.Fatalf("bootstrap result exposes runtime-owned field %q", forbidden)
		}
	}
}
