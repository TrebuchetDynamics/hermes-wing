package app

import (
	"fmt"
	"io"
	"strings"
)

func devicesCommand(stdout, stderr io.Writer, args []string) int {
	if len(args) == 0 {
		_, _ = fmt.Fprintln(stderr, "devices: expected list, revoke <device-id>, or revoke-all")
		return 2
	}
	statePath, err := resolveWingLinkStatePath()
	if err != nil {
		_, _ = fmt.Fprintf(stderr, "devices: %v\n", err)
		return 1
	}
	store := newStateStore(statePath)
	switch args[0] {
	case "list":
		if len(args) != 1 {
			_, _ = fmt.Fprintln(stderr, "devices list: no additional arguments are accepted")
			return 2
		}
		devices, err := store.ListDevices()
		if err != nil {
			_, _ = fmt.Fprintf(stderr, "devices list: %v\n", err)
			return 1
		}
		if len(devices) == 0 {
			_, _ = fmt.Fprintln(stdout, "No paired Wing devices.")
			return 0
		}
		for _, device := range devices {
			_, _ = fmt.Fprintf(
				stdout,
				"%s\t%s\t%s\n",
				device.ID,
				device.Name,
				strings.Join(device.Scopes, ","),
			)
		}
		return 0
	case "revoke":
		if len(args) != 2 {
			_, _ = fmt.Fprintln(stderr, "devices revoke: expected exactly one device ID")
			return 2
		}
		if err := store.RevokeDevice(args[1]); err != nil {
			_, _ = fmt.Fprintf(stderr, "devices revoke: %v\n", err)
			return 1
		}
		_, _ = fmt.Fprintf(stdout, "Revoked device %s.\n", args[1])
		return 0
	case "revoke-all":
		if len(args) != 1 {
			_, _ = fmt.Fprintln(stderr, "devices revoke-all: no additional arguments are accepted")
			return 2
		}
		if err := store.RevokeAll(); err != nil {
			_, _ = fmt.Fprintf(stderr, "devices revoke-all: %v\n", err)
			return 1
		}
		_, _ = fmt.Fprintln(stdout, "Revoked all paired Wing devices.")
		return 0
	default:
		_, _ = fmt.Fprintf(stderr, "devices: unknown command %s\n", args[0])
		return 2
	}
}
