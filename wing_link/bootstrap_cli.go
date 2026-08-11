package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"strings"
)

type bootstrapOptions struct {
	Request BootstrapRequest
	JSON    bool
}

func parseBootstrapOptions(args []string) (bootstrapOptions, error) {
	var options bootstrapOptions
	var profile, cloneFrom, provider, providerURL, model string
	for index := 0; index < len(args); index++ {
		value := func(name string) (string, error) {
			index++
			if index >= len(args) || strings.TrimSpace(args[index]) == "" {
				return "", fmt.Errorf("%s requires a value", name)
			}
			return args[index], nil
		}
		var err error
		switch args[index] {
		case "--profile":
			profile, err = value("--profile")
		case "--clone-from":
			cloneFrom, err = value("--clone-from")
		case "--provider":
			provider, err = value("--provider")
		case "--provider-url":
			providerURL, err = value("--provider-url")
		case "--model":
			model, err = value("--model")
		case "--json":
			options.JSON = true
		default:
			return bootstrapOptions{}, fmt.Errorf("unknown setup option %s", args[index])
		}
		if err != nil {
			return bootstrapOptions{}, err
		}
	}
	if cloneFrom != "" && profile == "" {
		return bootstrapOptions{}, errors.New("--clone-from requires --profile")
	}
	if profile != "" {
		options.Request.Profile = &BootstrapProfile{Name: profile, CloneFrom: cloneFrom}
	}
	providerParts := 0
	for _, part := range []string{provider, providerURL, model} {
		if part != "" {
			providerParts++
		}
	}
	if providerParts != 0 && providerParts != 3 {
		return bootstrapOptions{}, errors.New("--provider, --provider-url, and --model must be supplied together")
	}
	if providerParts == 3 {
		options.Request.Provider = &BootstrapProvider{ID: provider, BaseURL: providerURL, Model: model}
	}
	if err := options.Request.Validate(); err != nil {
		return bootstrapOptions{}, err
	}
	return options, nil
}

func bootstrapCommand(stdout, stderr io.Writer, args []string) int {
	options, err := parseBootstrapOptions(args)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "setup: %v\n", err)
		return 2
	}
	home, err := resolveHermesHome()
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "setup: %v\n", err)
		return 1
	}
	manager := newProductionBootstrapManager(home, "")
	emit := func(event OperationEvent) {
		if !options.JSON && event.Message != "" {
			_, _ = fmt.Fprintln(stderr, sanitizeOutput(event.Message, nil))
		}
	}
	result, err := manager.Bootstrap(context.Background(), options.Request, emit)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "setup: %v\n", err)
		return 1
	}
	if options.JSON {
		encoder := json.NewEncoder(stdout)
		encoder.SetEscapeHTML(true)
		if err := encoder.Encode(map[string]any{"protocol_version": ProtocolVersion, "result": result}); err != nil {
			return 1
		}
		return 0
	}
	_, _ = fmt.Fprintln(stdout, "Hermes Agent is ready.")
	if result.Profile != "" {
		_, _ = fmt.Fprintf(stdout, "Profile: %s\n", result.Profile)
	}
	if result.Provider != "" {
		_, _ = fmt.Fprintf(stdout, "Provider: %s\n", result.Provider)
	}
	return 0
}
