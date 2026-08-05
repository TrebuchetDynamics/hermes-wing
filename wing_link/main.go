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
	case "version":
		if len(args) != 1 {
			usage(stderr)
			return 2
		}
		_, _ = fmt.Fprintln(stdout, version)
		return 0
	case "serve", "status", "pair", "start", "stop", "restart":
		return runCommand(args[0], args[1:], stderr)
	default:
		usage(stderr)
		return 2
	}
}

func runCommand(command string, _ []string, stderr io.Writer) int {
	_, _ = fmt.Fprintf(stderr, "%s is unavailable in this build\n", command)
	return 1
}

func usage(writer io.Writer) {
	_, _ = fmt.Fprintln(writer, "usage: wing-link <serve|status|pair|start|stop|restart|version>")
}
