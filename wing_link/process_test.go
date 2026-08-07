package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"
)

func TestProcessHelper(t *testing.T) {
	if os.Getenv("GO_WANT_PROCESS_HELPER") != "1" {
		return
	}
	switch os.Getenv("PROCESS_HELPER_MODE") {
	case "arguments":
		separator := 0
		for index, argument := range os.Args {
			if argument == "--" {
				separator = index + 1
				break
			}
		}
		for _, argument := range os.Args[separator:] {
			fmt.Println(argument)
		}
	case "output":
		fmt.Printf("\x1b]0;hidden-title\x07\x1b]8;;https://example.com\x1b\\visible-link\x1b]8;;\x1b\\ \x1b[31mtoken=%s\x1b[0m\n", os.Getenv("INHERITED_TEST_TOKEN"))
		fmt.Printf("%0300d\n", 0)
	case "capture":
		fmt.Print(`{"acme":{"base_url":"https://example.test/v1","model":"m"}}`)
	case "large-capture":
		fmt.Print(strings.Repeat("x", 5000))
	case "sleep":
		time.Sleep(30 * time.Second)
	case "spawn-child":
		// nosemgrep: go.lang.security.audit.dangerous-exec-command.dangerous-exec-command -- fixed test binary and arguments.
		child := exec.Command(os.Args[0], "-test.run=TestProcessHelper")
		child.Env = append(os.Environ(), "PROCESS_HELPER_MODE=sleep")
		child.Stdout = os.Stdout
		child.Stderr = os.Stderr
		if err := child.Start(); err != nil {
			t.Fatal(err)
		}
		_ = child.Wait()
	}
	os.Exit(0)
}

func helperCommand(mode string, arguments ...string) CommandSpec {
	return CommandSpec{
		Path: os.Args[0],
		Args: append([]string{"-test.run=TestProcessHelper", "--"}, arguments...),
		Env: []string{
			"GO_WANT_PROCESS_HELPER=1",
			"PROCESS_HELPER_MODE=" + mode,
		},
	}
}

func TestArgumentsStayLiteral(t *testing.T) {
	arguments := []string{"$(touch /tmp/injected)", "; rm -rf ~"}
	var lines []string
	result := runProcess(context.Background(), helperCommand("arguments", arguments...), func(line string) {
		lines = append(lines, line)
	})
	if result.ExitCode != 0 || result.Err != nil {
		t.Fatalf("result = %#v", result)
	}
	if len(lines) != len(arguments) || lines[0] != arguments[0] || lines[1] != arguments[1] {
		t.Fatalf("lines = %#v", lines)
	}
}

func TestProcessOutputIsBoundedAndSanitized(t *testing.T) {
	const secret = "plain-random-secret"
	t.Setenv("INHERITED_TEST_TOKEN", secret)
	var lines []string
	result := runProcess(context.Background(), helperCommand("output"), func(line string) { lines = append(lines, line) })
	if result.Err != nil || len(lines) != 2 {
		t.Fatalf("result=%#v lines=%#v", result, lines)
	}
	if strings.Contains(strings.Join(lines, "\n"), secret) || strings.Contains(strings.Join(lines, "\n"), "\x1b") || strings.Contains(strings.Join(lines, "\n"), "hidden-title") {
		t.Fatalf("unsanitized lines: %#v", lines)
	}
	if !strings.Contains(lines[0], "visible-link") {
		t.Fatalf("visible OSC-8 text was removed: %#v", lines)
	}
	if len([]rune(lines[1])) != 240 {
		t.Fatalf("bounded length = %d", len([]rune(lines[1])))
	}
}

func TestProcessCaptureReturnsBoundedRawStdout(t *testing.T) {
	output, result := runProcessCapture(context.Background(), helperCommand("capture"), 4096)
	if result.Err != nil || string(output) != `{"acme":{"base_url":"https://example.test/v1","model":"m"}}` {
		t.Fatalf("result=%#v output=%q", result, output)
	}

	output, result = runProcessCapture(context.Background(), helperCommand("large-capture"), 128)
	if !errors.Is(result.Err, errProcessOutputTooLarge) || output != nil {
		t.Fatalf("result=%#v output=%q", result, output)
	}
}

func TestProcessTimeoutStopsCommandTree(t *testing.T) {
	spec := helperCommand("spawn-child")
	spec.Timeout = 100 * time.Millisecond
	started := time.Now()
	result := runProcess(context.Background(), spec, nil)
	if result.Err == nil || time.Since(started) > 2*time.Second {
		t.Fatalf("result=%#v elapsed=%s", result, time.Since(started))
	}
}
