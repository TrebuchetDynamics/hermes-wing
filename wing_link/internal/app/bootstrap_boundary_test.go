package app

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

func TestBootstrapAdoptsHealthyGatewayWithoutRestart(t *testing.T) {
	var messages []string
	manager := &BootstrapManager{
		EnsureHermes: func(context.Context, func(OperationEvent)) (HermesInspection, error) {
			return HermesInspection{Executable: "/safe/hermes", Adopted: true}, nil
		},
		GatewayHealthy: func(context.Context) bool { return true },
		StartGateway: func(context.Context) error {
			t.Fatal("healthy gateway was restarted")
			return nil
		},
		VerifyGateway: func(context.Context) error { return nil },
	}

	result, err := manager.Bootstrap(context.Background(), BootstrapRequest{}, func(event OperationEvent) {
		messages = append(messages, event.Message)
	})
	if err != nil {
		t.Fatal(err)
	}
	if !result.GatewayStarted {
		t.Fatalf("result = %#v", result)
	}
	if !reflect.DeepEqual(messages, []string{"Hermes gateway already healthy", "Verifying Hermes gateway health", "Hermes gateway is running"}) {
		t.Fatalf("messages = %#v", messages)
	}
}

func TestBootstrapRequestHasNoRuntimeDomainFields(t *testing.T) {
	assertNoRuntimeDomainFields(t, reflect.TypeOf(BootstrapRequest{}))
}

func TestBootstrapResultHasNoRuntimeDomainFields(t *testing.T) {
	assertNoRuntimeDomainFields(t, reflect.TypeOf(BootstrapResult{}))
}

func assertNoRuntimeDomainFields(t *testing.T, valueType reflect.Type) {
	t.Helper()
	for index := range valueType.NumField() {
		switch field := valueType.Field(index).Name; field {
		case "Profile", "Provider", "Model", "Configuration":
			t.Fatalf("bootstrap type exposes runtime-owned field %q", field)
		}
	}
}
