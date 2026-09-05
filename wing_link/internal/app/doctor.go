package app

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"runtime"
	"time"
)

type localDoctorReport struct {
	ProtocolVersion       int                         `json:"protocol_version"`
	Inspection            LocalInstallationInspection `json:"installation"`
	AgentAPIReady         bool                        `json:"agent_api_ready"`
	WingLinkLoopbackReady bool                        `json:"wing_link_loopback_ready"`
	NextSteps             []string                    `json:"next_steps"`
}

func localDoctorNextSteps(inspection LocalInstallationInspection, agentReady, linkReady bool, platform string) []string {
	steps := []string{}
	if !inspection.HermesInstalled {
		if inspection.SetupAvailable {
			steps = append(steps, "wing-link setup")
		} else {
			steps = append(steps, "Install Hermes Agent with its platform installer, then run wing-link doctor")
		}
	} else if !inspection.HermesHealthy {
		// Do not recommend reinstalling over an unexplained broken CLI.
		steps = append(steps, "hermes --version", "hermes doctor")
	} else if !agentReady {
		steps = append(steps, "wing-link setup")
	}
	if !linkReady {
		if platform == "android" {
			steps = append(steps, "wing-link serve --listen 127.0.0.1:8654 (in another Termux session)")
		} else {
			steps = append(steps, "wing-link status (check for a managed or non-loopback listener)")
		}
	}
	if inspection.HermesHealthy && agentReady && linkReady {
		if platform == "android" {
			steps = append(steps, "wing-link pair --local --same-device")
		} else {
			steps = append(steps, "wing-link pair --local")
		}
	}
	return steps
}

func probeWingLinkLoopback(ctx context.Context, endpoint string) bool {
	// No proxy or redirect: a local diagnostic must not follow an untrusted
	// loopback response onto the network. No credential is sent by this probe.
	transport := &http.Transport{Proxy: nil, DisableKeepAlives: true}
	defer transport.CloseIdleConnections()
	client := &http.Client{Transport: transport, Timeout: 2 * time.Second, CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return false
	}
	response, err := client.Do(request)
	if err != nil {
		return false
	}
	defer response.Body.Close()
	var health struct {
		Status   string `json:"status"`
		Protocol int    `json:"protocol_version"`
	}
	err = json.NewDecoder(io.LimitReader(response.Body, 4096)).Decode(&health)
	return err == nil && response.StatusCode == http.StatusOK && health.Status == "ok" && (health.Protocol == ProtocolVersion || health.Protocol == ProtocolVersion-1)
}

func writeDoctorReport(stdout io.Writer, report localDoctorReport, jsonOutput bool) int {
	if jsonOutput {
		if json.NewEncoder(stdout).Encode(report) != nil {
			return 1
		}
	} else {
		_, _ = fmt.Fprintln(stdout, "Wing Link local checks")
		switch {
		case !report.Inspection.HermesInstalled:
			_, _ = fmt.Fprintln(stdout, "Hermes CLI: not installed")
		case !report.Inspection.HermesHealthy:
			_, _ = fmt.Fprintln(stdout, "Hermes CLI: installed, but its version check failed")
		default:
			_, _ = fmt.Fprintln(stdout, "Hermes CLI:", report.Inspection.HermesVersion)
		}
		if report.AgentAPIReady {
			_, _ = fmt.Fprintln(stdout, "Local Agent API: authenticated check passed")
		} else {
			_, _ = fmt.Fprintln(stdout, "Local Agent API: could not verify authenticated access")
		}
		if report.WingLinkLoopbackReady {
			_, _ = fmt.Fprintln(stdout, "Wing Link loopback listener: responding")
		} else {
			_, _ = fmt.Fprintln(stdout, "Wing Link default loopback listener: not verified (remote listeners are not checked)")
		}
		_, _ = fmt.Fprintln(stdout, "Provider credentials and a model response are not checked.\n\nNext steps:")
		for _, step := range report.NextSteps {
			_, _ = fmt.Fprintln(stdout, "  "+step)
		}
	}
	if !report.Inspection.HermesHealthy || !report.AgentAPIReady || !report.WingLinkLoopbackReady {
		return 1
	}
	return 0
}

func doctorCommand(stdout, stderr io.Writer, args []string) int {
	if len(args) > 1 || len(args) == 1 && args[0] != "--json" {
		_, _ = fmt.Fprintln(stderr, "Usage: wing-link doctor [--json]")
		return 2
	}
	home, err := resolveHermesHome()
	if err != nil {
		_, _ = fmt.Fprintln(stderr, "doctor: could not resolve a safe local Hermes home")
		return 1
	}
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	inspection := inspectLocalInstallation(ctx, func() (string, error) { return resolveHermesExecutable(home, "") }, func(ctx context.Context, spec CommandSpec) ([]byte, ProcessResult) {
		spec.Env = []string{"HERMES_HOME=" + home}
		return runProcessCapture(ctx, spec, 16*1024)
	})
	agentReady := false
	if inspection.HermesHealthy {
		checkCtx, checkCancel := context.WithTimeout(ctx, 5*time.Second)
		agentReady = newProductionBootstrapManager(home, "").VerifyGateway(checkCtx) == nil
		checkCancel()
	}
	linkReady := probeWingLinkLoopback(ctx, "http://127.0.0.1:8654/healthz")
	report := localDoctorReport{ProtocolVersion: ProtocolVersion, Inspection: inspection, AgentAPIReady: agentReady, WingLinkLoopbackReady: linkReady, NextSteps: localDoctorNextSteps(inspection, agentReady, linkReady, runtime.GOOS)}
	return writeDoctorReport(stdout, report, len(args) == 1)
}
