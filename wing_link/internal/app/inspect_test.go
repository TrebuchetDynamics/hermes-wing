package app

import (
	"bytes"
	"context"
	"errors"
	"reflect"
	"runtime"
	"testing"
)

func TestInspectLocalInstallationReportsMissingHermes(t *testing.T) {
	inspection := inspectLocalInstallation(
		context.Background(),
		func() (string, error) { return "", errors.New("missing") },
		func(context.Context, CommandSpec) ([]byte, ProcessResult) {
			t.Fatal("missing Hermes was executed")
			return nil, ProcessResult{}
		},
	)
	if inspection.HermesInstalled || inspection.HermesHealthy || inspection.SetupAvailable != (runtime.GOOS == "linux") {
		t.Fatalf("inspection = %#v", inspection)
	}
}

func TestInspectLocalInstallationRejectsEmptyOrPathBearingVersion(t *testing.T) {
	for _, output := range [][]byte{
		nil,
		[]byte("/private/home/.local/bin/hermes v1.2.3\n"),
		[]byte("Hermes Agent at /private/home/.hermes\n"),
	} {
		inspection := inspectLocalInstallation(
			context.Background(),
			func() (string, error) { return "/safe/hermes", nil },
			func(context.Context, CommandSpec) ([]byte, ProcessResult) { return output, ProcessResult{} },
		)
		if inspection.HermesHealthy || inspection.HermesVersion != "" {
			t.Fatalf("unsafe version accepted: %#v", inspection)
		}
	}
}

func TestInspectLocalInstallationReportsHealthyHermesWithoutPath(t *testing.T) {
	var commands []CommandSpec
	inspection := inspectLocalInstallation(
		context.Background(),
		func() (string, error) { return "/private/home/.local/bin/hermes", nil },
		func(_ context.Context, spec CommandSpec) ([]byte, ProcessResult) {
			commands = append(commands, spec)
			return []byte("Hermes Agent v1.2.3\n"), ProcessResult{}
		},
	)
	if !inspection.HermesInstalled || !inspection.HermesHealthy || inspection.HermesVersion != "Hermes Agent v1.2.3" {
		t.Fatalf("inspection = %#v", inspection)
	}
	if !reflect.DeepEqual(commands[0].Args, []string{"--version"}) {
		t.Fatalf("command = %#v", commands[0])
	}
	payload := &bytes.Buffer{}
	if code := writeInspectionJSON(payload, inspection); code != 0 {
		t.Fatalf("write code = %d", code)
	}
	if bytes.Contains(payload.Bytes(), []byte("/private/home")) {
		t.Fatalf("executable path leaked: %s", payload.String())
	}
}

func TestInspectLocalInstallationFailsClosedForBrokenHermes(t *testing.T) {
	inspection := inspectLocalInstallation(
		context.Background(),
		func() (string, error) { return "/safe/hermes", nil },
		func(context.Context, CommandSpec) ([]byte, ProcessResult) {
			return nil, ProcessResult{Err: errors.New("failed")}
		},
	)
	if !inspection.HermesInstalled || inspection.HermesHealthy {
		t.Fatalf("inspection = %#v", inspection)
	}
}
