# Wing Link CLI guide

Running `wing-link` without arguments prints a short first-run guide and exits
successfully without changing the host. Use `wing-link help` for every command,
or `wing-link help setup` / `wing-link setup --help` for focused instructions.

## Check before changing anything

```bash
wing-link doctor
wing-link doctor --json
```

Doctor checks the Hermes executable, the authenticated local Agent API using the
existing credential, and Wing Link's default loopback health endpoint. Checks
have bounded durations and outputs. Local HTTP probes do not follow redirects
or use environment HTTP proxies.

The report contains safe version/status fields and suggested next commands;
it excludes credentials, host paths, raw process output, and HTTP response bodies.
It never installs, starts, restarts, pairs, or repairs automatically. A missing
CLI suggests setup; a broken CLI suggests `hermes --version` and `hermes doctor`
before reinstalling; healthy local connections suggest the appropriate local
pairing command for the platform.

This is a local connection check. A non-loopback or custom-port Wing Link listener
may be running even when its default loopback check fails. Check `wing-link status`
for a managed service. Model credentials, provider readiness, and a real chat
response are not tested. `inspect` remains the narrower executable/version check.

Doctor exits 0 when all its local checks pass, 1 when attention is needed or a
check cannot complete, and 2 for invalid arguments. JSON output uses the same
exit codes and includes `next_steps`.

## Setup and next steps

```bash
wing-link setup --with-omniroute
```

OmniRoute's Node/npm prerequisites are checked before Hermes setup begins. If
they are missing, fix them and rerun the same command, or use `wing-link setup`
for Hermes alone. The locked installation behavior is described in the
[Termux runbook](android-termux-local-agent.md#optional-omniroute-installation).

Successful setup prints the next pairing command for the platform. On Android,
keep `wing-link serve --listen 127.0.0.1:8654` running in another Termux session,
then use `wing-link pair --local --same-device`. On a managed Linux host, use
`wing-link pair` for another device or `wing-link pair --local` for this computer.

Setup does not choose a model or configure an existing Hermes profile. Use the
local Hermes CLI for that configuration and OmniRoute's local wizard for its
own credentials. Android background hosting remains best-effort.
