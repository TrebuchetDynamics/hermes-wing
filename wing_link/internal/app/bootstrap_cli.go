package app

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
)

type bootstrapOptions struct {
	Request   BootstrapRequest
	JSON      bool
	JSONLines bool
}

func parseBootstrapOptions(args []string) (bootstrapOptions, error) {
	var options bootstrapOptions
	for _, arg := range args {
		switch arg {
		case "--json":
			if options.JSON || options.JSONLines {
				return bootstrapOptions{}, errors.New("setup output mode may be supplied only once")
			}
			options.JSON = true
		case "--json-lines":
			if options.JSON || options.JSONLines {
				return bootstrapOptions{}, errors.New("setup output mode may be supplied only once")
			}
			options.JSONLines = true
		default:
			return bootstrapOptions{}, fmt.Errorf("unknown setup option %s", arg)
		}
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
	encoder := json.NewEncoder(stdout)
	encoder.SetEscapeHTML(true)
	emit := func(event OperationEvent) {
		if options.JSONLines {
			_ = encoder.Encode(map[string]any{
				"protocol_version": ProtocolVersion,
				"event":            event,
			})
		} else if !options.JSON && event.Message != "" {
			_, _ = fmt.Fprintln(stderr, sanitizeOutput(event.Message, nil))
		}
	}
	result, err := manager.Bootstrap(context.Background(), options.Request, emit)
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "setup: %v\n", err)
		return 1
	}
	if options.JSON || options.JSONLines {
		if err := encoder.Encode(map[string]any{"protocol_version": ProtocolVersion, "result": result}); err != nil {
			return 1
		}
		return 0
	}
	_, _ = fmt.Fprintln(stdout, "Hermes Agent is ready.")
	return 0
}
