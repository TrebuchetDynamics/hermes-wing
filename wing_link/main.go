package main

import (
	"fmt"
	"io"
	"os"
)

var version = "dev"

func main() {
	os.Exit(run(os.Args[1:], os.Stdout, os.Stderr))
}

func run(args []string, stdout, stderr io.Writer) int {
	if len(args) == 0 {
		usage(stderr)
		return 2
	}

	switch args[0] {
	case "-h", "--help", "help":
		usage(stdout)
		return 0
	case "version":
		if len(args) != 1 {
			usage(stderr)
			return 2
		}
		_, _ = fmt.Fprintln(stdout, version)
		return 0
	case "pair":
		return pairCommand(stdout, stderr, args[1:])
	case "setup":
		return bootstrapCommand(stdout, stderr, args[1:])
	case "inspect":
		return inspectCommand(stdout, stderr, args[1:])
	case "serve":
		return serveCommand(stdout, stderr, args[1:])
	case "status", "start", "stop", "restart":
		if len(args) != 1 {
			usage(stderr)
			return 2
		}
		if err := WingLinkServiceCommand(args[0], stdout); err != nil {
			_, _ = fmt.Fprintf(stderr, "%s: %v\n", args[0], err)
			return 1
		}
		return 0
	default:
		usage(stderr)
		return 2
	}
}

func usage(writer io.Writer) {
	_, _ = fmt.Fprintln(writer, `usage: wing-link <command>

Commands:
  serve     Run the independent Wing Link profile control plane.
            Options: --listen HOST:PORT
  status    Report daemon and runtime state.
  inspect   Detect the local Hermes installation without exposing paths.
            Options: [--json]
  setup     Install or adopt pinned Hermes Agent, secure API access, and start
            the gateway. Runtime-owned provider/profile setup follows through
            Hermes APIs.
            Options: [--json | --json-lines]
  pair      Pair direct Hermes and independent Wing Link credentials.
  start     Start the daemon if it is not running.
  stop      Stop the running daemon.
  restart   Stop, then start, the daemon.
  version   Print the build version.
  help      Show this help.`)
}
