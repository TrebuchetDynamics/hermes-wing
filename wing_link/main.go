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
	case "serve", "status", "start", "stop", "restart":
		if len(args) != 1 {
			usage(stderr)
			return 2
		}
		return unavailable(args[0], stderr)
	default:
		usage(stderr)
		return 2
	}
}

func unavailable(command string, stderr io.Writer) int {
	notes := map[string]string{
		"serve":   "the Wing Link daemon is not implemented yet (ROADMAP 1.2)",
		"status":  "daemon state reporting lands with serve (ROADMAP 1.2)",
		"start":   "daemon lifecycle lands with serve (ROADMAP 1.2)",
		"stop":    "daemon lifecycle lands with serve (ROADMAP 1.2)",
		"restart": "daemon lifecycle lands with serve (ROADMAP 1.2)",
	}
	_, _ = fmt.Fprintf(stderr, "%s is unavailable in this build: %s.\n", command, notes[command])
	return 1
}

func usage(writer io.Writer) {
	_, _ = fmt.Fprintln(writer, `usage: wing-link <command>

Commands:
  serve     Run the device daemon (enrollment + command server).
  status    Report daemon and runtime state.
  pair      Create a scoped Hermes enrollment for LAN/VPN pairing.
  start     Start the daemon if it is not running.
  stop      Stop the running daemon.
  restart   Stop, then start, the daemon.
  version   Print the build version.
  help      Show this help.`)
}
