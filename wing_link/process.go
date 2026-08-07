package main

import (
	"bufio"
	"bytes"
	"context"
	"errors"
	"io"
	"os"
	"os/exec"
	"regexp"
	"strings"
	"sync"
	"time"
)

type CommandSpec struct {
	Path    string
	Args    []string
	Dir     string
	Env     []string
	Timeout time.Duration
}

type ProcessResult struct {
	ExitCode int
	Err      error
}

var errProcessOutputTooLarge = errors.New("process output exceeded the limit")

type boundedCapture struct {
	buffer   bytes.Buffer
	limit    int
	exceeded bool
}

func (capture *boundedCapture) Write(value []byte) (int, error) {
	remaining := capture.limit - capture.buffer.Len()
	if len(value) > remaining {
		capture.exceeded = true
	}
	if remaining > 0 {
		if len(value) < remaining {
			remaining = len(value)
		}
		_, _ = capture.buffer.Write(value[:remaining])
	}
	return len(value), nil
}

var (
	terminalEscapePattern = regexp.MustCompile(`\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07\x1b]*(?:\x07|\x1b\\)|[@-_])`)
	controlPattern        = regexp.MustCompile(`[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]`)
	credentialPattern     = regexp.MustCompile(`(?i)\b(bearer\s+|(?:api[_-]?key|token|password|secret)\s*[:=]\s*)([^\s]+)`)
	urlUserInfoPattern    = regexp.MustCompile(`(?i)(https?://)[^/\s:@]+:[^/\s@]+@`)
)

func runProcess(ctx context.Context, spec CommandSpec, onLine func(string)) ProcessResult {
	if spec.Timeout > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, spec.Timeout)
		defer cancel()
	}
	// nosemgrep: go.lang.security.audit.dangerous-exec-command.dangerous-exec-command -- callers provide verified, fixed executable paths and argument arrays; no shell is used.
	cmd := exec.CommandContext(ctx, spec.Path, spec.Args...)
	cmd.Dir = spec.Dir
	cmd.Env = append(os.Environ(), spec.Env...)
	configureProcess(cmd)
	cmd.Cancel = func() error {
		if cmd.Process == nil {
			return os.ErrProcessDone
		}
		return killProcessTree(cmd.Process)
	}

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return ProcessResult{ExitCode: -1, Err: err}
	}
	stderr, err := cmd.StderrPipe()
	if err != nil {
		return ProcessResult{ExitCode: -1, Err: err}
	}
	if err := cmd.Start(); err != nil {
		return ProcessResult{ExitCode: -1, Err: err}
	}
	cleanupProcessTree, err := registerProcessTree(cmd.Process)
	if err != nil {
		_ = cmd.Process.Kill()
		_ = cmd.Wait()
		return ProcessResult{ExitCode: -1, Err: err}
	}
	defer cleanupProcessTree()

	secrets := secretEnvironmentValues(cmd.Env)
	var outputMu sync.Mutex
	emit := func(line string) {
		if onLine == nil {
			return
		}
		line = sanitizeOutput(line, secrets)
		outputMu.Lock()
		onLine(line)
		outputMu.Unlock()
	}
	errorsByStream := make(chan error, 2)
	go func() { errorsByStream <- readProcessLines(stdout, emit) }()
	go func() { errorsByStream <- readProcessLines(stderr, emit) }()

	streamErr := errors.Join(<-errorsByStream, <-errorsByStream)
	waitErr := cmd.Wait()
	if ctx.Err() != nil {
		return ProcessResult{ExitCode: exitCode(waitErr), Err: ctx.Err()}
	}
	return ProcessResult{ExitCode: exitCode(waitErr), Err: errors.Join(waitErr, streamErr)}
}

func runProcessCapture(ctx context.Context, spec CommandSpec, maximumBytes int) ([]byte, ProcessResult) {
	if maximumBytes <= 0 {
		return nil, ProcessResult{ExitCode: -1, Err: errProcessOutputTooLarge}
	}
	if spec.Timeout > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, spec.Timeout)
		defer cancel()
	}
	// nosemgrep: go.lang.security.audit.dangerous-exec-command.dangerous-exec-command -- callers provide verified, fixed executable paths and argument arrays; no shell is used.
	cmd := exec.CommandContext(ctx, spec.Path, spec.Args...)
	cmd.Dir = spec.Dir
	cmd.Env = append(os.Environ(), spec.Env...)
	configureProcess(cmd)
	cmd.Cancel = func() error {
		if cmd.Process == nil {
			return os.ErrProcessDone
		}
		return killProcessTree(cmd.Process)
	}
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return nil, ProcessResult{ExitCode: -1, Err: err}
	}
	stderr, err := cmd.StderrPipe()
	if err != nil {
		return nil, ProcessResult{ExitCode: -1, Err: err}
	}
	if err := cmd.Start(); err != nil {
		return nil, ProcessResult{ExitCode: -1, Err: err}
	}
	cleanupProcessTree, err := registerProcessTree(cmd.Process)
	if err != nil {
		_ = cmd.Process.Kill()
		_ = cmd.Wait()
		return nil, ProcessResult{ExitCode: -1, Err: err}
	}
	defer cleanupProcessTree()

	capture := &boundedCapture{limit: maximumBytes}
	streams := make(chan error, 2)
	go func() { _, err := io.Copy(capture, stdout); streams <- err }()
	go func() { _, err := io.Copy(io.Discard, stderr); streams <- err }()
	streamErr := errors.Join(<-streams, <-streams)
	waitErr := cmd.Wait()
	if capture.exceeded {
		streamErr = errors.Join(streamErr, errProcessOutputTooLarge)
	}
	if ctx.Err() != nil {
		return nil, ProcessResult{ExitCode: exitCode(waitErr), Err: ctx.Err()}
	}
	result := ProcessResult{ExitCode: exitCode(waitErr), Err: errors.Join(waitErr, streamErr)}
	if result.Err != nil {
		return nil, result
	}
	return append([]byte(nil), capture.buffer.Bytes()...), result
}

func readProcessLines(reader io.Reader, emit func(string)) error {
	buffered := bufio.NewReaderSize(reader, 4096)
	for {
		var line []byte
		for {
			part, prefix, err := buffered.ReadLine()
			if len(line) < 4096 {
				remaining := 4096 - len(line)
				if len(part) > remaining {
					part = part[:remaining]
				}
				line = append(line, part...)
			}
			if err != nil {
				if len(line) > 0 {
					emit(string(line))
				}
				if errors.Is(err, io.EOF) {
					return nil
				}
				return err
			}
			if !prefix {
				emit(string(line))
				break
			}
		}
	}
}

func sanitizeOutput(value string, secrets []string) string {
	value = terminalEscapePattern.ReplaceAllString(value, "")
	value = controlPattern.ReplaceAllString(value, "")
	for _, secret := range secrets {
		value = strings.ReplaceAll(value, secret, "[REDACTED]")
	}
	value = credentialPattern.ReplaceAllString(value, "${1}[REDACTED]")
	value = urlUserInfoPattern.ReplaceAllString(value, "${1}[REDACTED]@")
	return boundRunes(value, 240)
}

func secretEnvironmentValues(environment []string) []string {
	var values []string
	for _, entry := range environment {
		key, value, ok := strings.Cut(entry, "=")
		upper := strings.ToUpper(key)
		if ok && value != "" && (strings.Contains(upper, "TOKEN") || strings.Contains(upper, "KEY") || strings.Contains(upper, "SECRET") || strings.Contains(upper, "PASSWORD")) {
			values = append(values, value)
		}
	}
	return values
}

func exitCode(err error) int {
	if err == nil {
		return 0
	}
	var exitError *exec.ExitError
	if errors.As(err, &exitError) {
		return exitError.ExitCode()
	}
	return -1
}
