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
	Request       BootstrapRequest
	JSON          bool
	JSONLines     bool
	WithOmniRoute bool
}

func parseBootstrapOptions(args []string) (bootstrapOptions, error) {
	var options bootstrapOptions
	for _, arg := range args {
		switch arg {
		case "--with-omniroute":
			if options.WithOmniRoute {
				return bootstrapOptions{}, errors.New("OmniRoute setup may be requested only once")
			}
			options.WithOmniRoute = true
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
	if options.WithOmniRoute {
		if _, _, err := omniRoutePrerequisites(); err != nil {
			_, _ = fmt.Fprintln(stderr, "setup: prerequisite check failed:", err)
			if runtime.GOOS == "android" {
				_, _ = fmt.Fprintln(stderr, "In Termux, run pkg install nodejs, then retry the same setup command.")
			}
			_, _ = fmt.Fprintln(stderr, "Hermes setup has not started. Use wing-link setup to install Hermes alone.")
			return 1
		}
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
		_, _ = fmt.Fprintf(stderr, "setup: %v\n", err)
		_, _ = fmt.Fprintln(stderr, "Run wing-link doctor to check the local installation before retrying.")
		return 1
	}
	cliResult := struct {
		BootstrapResult
		OmniRouteVersion string `json:"omniroute_version,omitempty"`
	}{BootstrapResult: result}
	if options.WithOmniRoute {
		emit(OperationEvent{Message: "Installing the locked OmniRoute runtime"})
		if err := installOmniRoute(context.Background()); err != nil {
			_, _ = fmt.Fprintln(stderr, "setup: Hermes is running, but OmniRoute installation failed:", err)
			return 1
		}
		cliResult.OmniRouteVersion = omniRouteVersion
	}
	if options.JSON || options.JSONLines {
		if err := encoder.Encode(map[string]any{"protocol_version": ProtocolVersion, "result": cliResult}); err != nil {
			return 1
		}
		return 0
	}
	_, _ = fmt.Fprintln(stdout, "Hermes Agent gateway is running.")
	if options.WithOmniRoute {
		_, _ = fmt.Fprintln(stdout, "OmniRoute is installed. Run wing-link omniroute-setup locally to configure it before starting its server.")
	}
	_, _ = fmt.Fprintln(stdout, "Provider/model setup is separate: run hermes setup before pairing if this host is not configured yet.")
	if runtime.GOOS == "android" {
		_, _ = fmt.Fprintln(stdout, "Next: keep wing-link serve --listen 127.0.0.1:8654 running in another Termux session, then run wing-link pair --local --same-device.")
	} else {
		_, _ = fmt.Fprintln(stdout, "Next: run wing-link pair to connect Hermes Wing, or wing-link pair --local for this computer.")
	}
	return 0
}
