package app

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"runtime"
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
		_, _ = fmt.Fprintln(stderr, "Run wing-link doctor to check the local installation before retrying.")
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
		if options.JSON || options.JSONLines {
			code := "setup_failed"
			if errors.Is(err, ErrHermesPortInUse) {
				code = "gateway_port_in_use"
			}
			_ = encoder.Encode(map[string]any{
				"protocol_version": ProtocolVersion,
				"error":            map[string]string{"code": code},
			})
		}
		_, _ = fmt.Fprintf(stderr, "setup: %v\n", err)
		_, _ = fmt.Fprintln(stderr, "Run wing-link doctor to check the local installation before retrying.")
		return 1
	}
	if options.JSON || options.JSONLines {
		if err := encoder.Encode(map[string]any{"protocol_version": ProtocolVersion, "result": result}); err != nil {
			return 1
		}
		return 0
	}
	_, _ = fmt.Fprintln(stdout, "Hermes Agent gateway is running.")

	_, _ = fmt.Fprintln(stdout, "Provider/model setup is separate: run hermes setup before pairing if this host is not configured yet.")
	if runtime.GOOS == "android" {
		_, _ = fmt.Fprintln(stdout, "Next: keep wing-link serve --listen 127.0.0.1:8654 running in another Termux session, then run wing-link pair --local --same-device.")
	} else {
		_, _ = fmt.Fprintln(stdout, "Next: run wing-link pair to connect Hermes Wing, or wing-link pair --local for this computer.")
	}
	return 0
}
