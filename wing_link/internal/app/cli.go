package app

import (
	"fmt"
	"io"
)

var version = "dev"

// Run dispatches the Wing Link command line.
func Run(args []string, stdout, stderr io.Writer, buildVersion string) int {
	version = buildVersion
	return run(args, stdout, stderr)
}

func run(args []string, stdout, stderr io.Writer) int {
	if len(args) == 0 {
		quickStart(stdout)
		return 0
	}
	if args[0] == "help" && len(args) == 2 {
		return commandHelp(stdout, stderr, args[1])
	}
	if len(args) == 2 && (args[1] == "--help" || args[1] == "-h") {
		return commandHelp(stdout, stderr, args[0])
	}

	switch args[0] {
	case "-h", "--help", "help":
		if len(args) != 1 {
			_, _ = fmt.Fprintln(stderr, "Use wing-link help or wing-link help <command>.")
			return 2
		}
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
	case "omniroute-setup":
		return omniRouteSetupCommand(stdout, stderr, args[1:])
	case "inspect":
		return inspectCommand(stdout, stderr, args[1:])
	case "doctor":
		return doctorCommand(stdout, stderr, args[1:])
	case "serve":
		return serveCommand(stdout, stderr, args[1:])
	case "devices":
		return devicesCommand(stdout, stderr, args[1:])
	case "directories":
		return directoriesCommand(stdout, stderr, args[1:])
	case "approvals":
		return approvalsCommand(stdout, stderr, args[1:])
	case "audit":
		return auditCommand(stdout, stderr, args[1:])
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
	_, _ = fmt.Fprintln(writer, `Wing Link
  Local supervisor for installing, pairing, and running Hermes Agent.
  Profiles, providers, and other Agent settings stay in Hermes Agent.

Usage:
  wing-link <command> [options]

Get started:
  doctor     Check the local CLI and connections, then show recovery steps.
             --json                  Print the local diagnostic report
  inspect    Check for a local Hermes Agent installation without showing paths.
             --json                  Print machine-readable output
  setup      Install or adopt Hermes Agent, secure API access, and start it.
             --with-omniroute         Also install the pinned OmniRoute runtime
             --json                  Print one JSON result
             --json-lines            Stream progress as JSON lines
  omniroute-setup  Open OmniRoute's local setup wizard after installation.
  pair       Create a secure pairing handoff for Hermes Wing.
             Prints a scannable QR and single-use paste link by default.
             --remote                Pair through NetBird, Tailscale, or a trusted VPN (default)
                                     NetBird/Tailscale API binding is configured automatically.
             --local                 Pair on this device only
             --same-device           Print only the code-free local /open URL
             --link                  Print the single-use link without the QR
             --qr                    Print a scannable QR without the link
             --origin URL            Use a specific Hermes Agent API origin
             --label NAME            Name this Hermes Wing installation

Host trust:
  devices list                 List paired device IDs, names, and grants.
  devices revoke DEVICE_ID     Revoke one paired device.
  devices revoke-all           Revoke every paired device.
  directories list             List locally approved directory roots.
  directories grant PATH       Approve one local directory root.
  directories revoke ID        Revoke one directory grant.
  approvals list               List bounded pending host approvals.
  approvals approve ID         Approve one host operation.
  approvals reject ID          Reject one host operation.
  audit                        List privacy-safe local audit events.
  audit clear --confirm        Clear the local audit log explicitly.

Managed service:
  status     Show whether the Wing Link user service is running.
  start      Start the Wing Link user service.
  stop       Stop the Wing Link user service.
  restart    Restart the Wing Link user service.

Advanced:
  serve      Run Wing Link in the foreground.
             --listen HOST:PORT       Listen on an approved local address

Other:
  version    Print the build version.
  help       Show this help.

Typical first run with NetBird or Tailscale:
  wing-link inspect
  wing-link setup
  wing-link pair

Use "wing-link pair --local" for same-host pairing. Other VPNs require the
Hermes Agent API to be bound to that VPN address and WING_HERMES_URL to name it.

Most users should not run "serve" directly. Pair installs and starts the
managed service; use status, start, stop, or restart afterward.`)
}
