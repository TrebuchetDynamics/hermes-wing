package app

import (
	"fmt"
	"io"
	"runtime"
)

func quickStart(writer io.Writer) {
	_, _ = fmt.Fprintln(writer, "Wing Link — set up Hermes and connect Hermes Wing.\n\nStart here:\n  wing-link doctor                 Check what needs attention\n  wing-link setup --with-omniroute  Install Hermes and the locked OmniRoute runtime")
	if runtime.GOOS == "android" {
		_, _ = fmt.Fprintln(writer, "  wing-link pair --local --same-device  Connect Wing on this phone")
	} else {
		_, _ = fmt.Fprintln(writer, "  wing-link pair                   Connect Wing over your LAN or VPN")
	}
	_, _ = fmt.Fprintln(writer, "\nUse wing-link setup for Hermes alone.\nUse wing-link help <command> for examples. No changes were made.")
}

func commandHelp(stdout, stderr io.Writer, command string) int {
	help, ok := commandHelpText[command]
	if !ok {
		// Never echo an unknown argument: it may have been a pasted credential.
		_, _ = fmt.Fprintln(stderr, "No help for that command. Run wing-link help to list commands.")
		return 2
	}
	_, _ = fmt.Fprintln(stdout, help)
	return 0
}

var commandHelpText = map[string]string{
	"setup": `Usage: wing-link setup [--with-omniroute] [--json | --json-lines]

Install or adopt Hermes Agent, secure its API, and start its gateway.
Healthy installations are reused. Existing provider/model settings stay in Hermes.

  wing-link setup --with-omniroute  Also install the locked OmniRoute runtime
  wing-link setup --json-lines      Show progress for automation

OmniRoute requires Node.js >=22.22.2 <23 or >=24 <27, plus npm.
Setup installs OmniRoute but does not start its server.
Then run wing-link omniroute-setup locally to configure it.
Configure the Hermes default profile with hermes model, then pair Wing.
If setup fails, run wing-link doctor before retrying.`,
	"doctor": `Usage: wing-link doctor [--json]

Read-only checks for the Hermes CLI, authenticated local Agent API, and
Wing Link's default loopback listener. Prints concrete next steps.
No installation, restart, pairing code, or credential mutation is performed.
Remote listeners, model credentials, and a real chat response are not tested.
Exit 0 means these local checks passed; exit 1 means attention is needed.`,
	"inspect": `Usage: wing-link inspect [--json]

Check whether the Hermes executable is installed and its version command works.
Use wing-link doctor to also check the local connections and get recovery steps.`,
	"pair": `Usage: wing-link pair [--local | --remote] [--same-device | --link | --qr]
                      [--origin URL] [--label NAME]

  wing-link pair --local --same-device  Connect Wing on this Android phone
  wing-link pair --local                Connect on the same computer
  wing-link pair                       Connect another device over LAN or VPN

Run wing-link setup first. On Termux, keep the local Wing Link listener running
in another terminal: wing-link serve --listen 127.0.0.1:8654
The handoff expires after five minutes. Review the host and access in Wing.
If it expires, run the same pairing command again. Never paste API keys here.`,
	"serve": `Usage: wing-link serve [--listen HOST:PORT]

Run the management listener in the foreground.
On this Android phone: wing-link serve --listen 127.0.0.1:8654
Keep that terminal open; use another terminal for pairing.
Android background operation is best-effort. Non-loopback listeners require TLS.
On a managed Linux installation, use wing-link start instead.`,
	"omniroute-setup": `Usage: wing-link omniroute-setup

Open the installed OmniRoute runtime's local configuration wizard.
First install it with wing-link setup --with-omniroute.
Enter credentials directly in the wizard, never in command arguments.
This does not configure Hermes profiles or start OmniRoute's server.`,
	"version":     "Usage: wing-link version\n\nPrint the Wing Link build version.",
	"status":      "Usage: wing-link status\n\nCheck the managed Wing Link service. Use wing-link doctor for local connection checks.",
	"start":       "Usage: wing-link start\n\nStart the managed Wing Link service. For Termux, see wing-link help serve.",
	"stop":        "Usage: wing-link stop\n\nStop the managed Wing Link service.",
	"restart":     "Usage: wing-link restart\n\nRestart the managed Wing Link service. This does not reinstall Hermes.",
	"devices":     "Usage: wing-link devices list | revoke DEVICE_ID | revoke-all\n\nManage device access locally. Revoking access does not delete Hermes profiles.",
	"directories": "Usage: wing-link directories list | grant PATH | revoke ID\n\nManage locally approved folder roots. Remote clients use opaque handles.",
	"approvals":   "Usage: wing-link approvals list | approve ID | reject ID\n\nReview requests on the host. Approvals bind the exact request and are not reusable for changed input.",
	"audit":       "Usage: wing-link audit | audit clear --confirm\n\nRead redacted host events, or explicitly clear the local audit log.",
}
