package main

import (
	"encoding/json"
	"fmt"
)

const ProtocolVersion = 1

type Component string

const (
	ComponentHermes    Component = "hermes"
	ComponentOmniRoute Component = "omniroute"
)

type RuntimeState string

const (
	RuntimeAbsent     RuntimeState = "absent"
	RuntimeInstalling RuntimeState = "installing"
	RuntimeStopped    RuntimeState = "stopped"
	RuntimeStarting   RuntimeState = "starting"
	RuntimeHealthy    RuntimeState = "healthy"
	RuntimeFailed     RuntimeState = "failed"
)

type InstallRequest struct {
	Components                   []Component `json:"components"`
	AcceptCommunityProviderTerms bool        `json:"accept_community_provider_terms"`
}

type InstallStatus struct {
	ProtocolVersion    int          `json:"protocol_version"`
	State              RuntimeState `json:"state"`
	HermesInstalled    bool         `json:"hermes_installed"`
	HermesHealthy      bool         `json:"hermes_healthy"`
	HermesVersion      string       `json:"hermes_version,omitempty"`
	OmniRouteInstalled bool         `json:"omniroute_installed"`
	OmniRouteHealthy   bool         `json:"omniroute_healthy"`
	ActiveOperationID  string       `json:"active_operation_id,omitempty"`
	PairingURI         string       `json:"pairing_uri,omitempty"`
}

type APIError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

func (apiError APIError) MarshalJSON() ([]byte, error) {
	type wireError APIError
	apiError.Message = boundRunes(apiError.Message, 240)
	return json.Marshal(wireError(apiError))
}

type OperationEvent struct {
	ProtocolVersion int    `json:"protocol_version"`
	OperationID     string `json:"operation_id"`
	Phase           string `json:"phase"`
	Message         string `json:"message"`
	Percent         int    `json:"percent"`
	Terminal        bool   `json:"terminal,omitempty"`
	ErrorCode       string `json:"error_code,omitempty"`
}

func (event OperationEvent) MarshalJSON() ([]byte, error) {
	type wireEvent OperationEvent
	event.Message = boundRunes(event.Message, 240)
	return json.Marshal(wireEvent(event))
}

func boundRunes(value string, limit int) string {
	count := 0
	for index := range value {
		if count == limit {
			return value[:index]
		}
		count++
	}
	return value
}

func (request InstallRequest) Validate() error {
	if len(request.Components) == 0 {
		return fmt.Errorf("at least one component is required")
	}
	seen := make(map[Component]struct{}, len(request.Components))
	for _, component := range request.Components {
		if component != ComponentHermes && component != ComponentOmniRoute {
			return fmt.Errorf("unsupported component: %s", component)
		}
		if _, exists := seen[component]; exists {
			return fmt.Errorf("duplicate component: %s", component)
		}
		seen[component] = struct{}{}
	}
	if _, hasOmniRoute := seen[ComponentOmniRoute]; hasOmniRoute {
		if _, hasHermes := seen[ComponentHermes]; !hasHermes {
			return fmt.Errorf("hermes is required with OmniRoute")
		}
		if !request.AcceptCommunityProviderTerms {
			return fmt.Errorf("community provider consent is required")
		}
	}
	return nil
}
