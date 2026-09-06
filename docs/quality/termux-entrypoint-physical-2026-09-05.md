# Standalone Termux installer physical test — 2026-09-05

Target: physical Samsung SM-S928B, Android 16, ARM64, Termux Google Play
`googleplay.2026.06.21`. Commands ran inside Termux through its normal terminal.
No external-command permission was enabled. The development script was transferred
through an ADB loopback connection and its SHA-256 checked before execution;
runtime artifacts came from the script's real immutable HTTPS URLs.

## Existing installation

The first `bash install-termux.sh` run completed with exit 0 in 216 seconds,
including manual browser pairing. It installed/checked Termux packages, verified
the pinned downloads, adopted Hermes, built Wing Link on the phone, and paired
through the code-free browser handoff into the production Wing app. Wing reported
one connected profile. The original native launcher and the default profile's
configuration and environment files were byte-for-byte unchanged. Agent `/health`
and Wing Link `/healthz` both returned HTTP 200.

This device already had the repaired installation described in the
[earlier physical report](android-termux-install-2026-09-05.md). This run does not
qualify installation into an empty Termux environment.

## Explicit Hermes update

`bash install-termux.sh --update-hermes` runs the official installer for reviewed
revision `afc3d9d34c9c3b01fa2e1332d2c66a5b5fabae3f`, even when Hermes exists.
The test reinstalled that same revision; it was not an upgrade from an older
Agent release.

The first update run exited 1 after 421 seconds. The upstream installer replaced
the native launcher with a shell wrapper. Both a Bash invocation and direct
venv Python invocation of Hermes `--version` succeeded, while the Go direct-exec
probe failed. The new guard stopped before Wing Link could trigger another
installation. Configuration remained unchanged and both existing services
continued returning HTTP 200.

The entrypoint now handles this failure for launchers installed by the current
run: it builds a native executable that clears Python environment overrides and
executes the fixed Hermes venv and entrypoint with the original arguments. It
probes the candidate before atomically activating it, then probes the installed
command again. Adopt-only runs do not rewrite an existing launcher.

A second update completed the upstream installation but rejected the candidate
because Android changed the Go probe's argument list. A focused device test
confirmed that selecting the executable through a private process environment
value avoids that probe bug. The C native launcher then passed the real Go
`--version` check against the updated Hermes installation.

The final complete `--update-hermes` run passed with exit 0 in 546 seconds,
including browser pairing. The native launcher repair ran automatically, Wing
Link built and completed setup, and the production Wing app reported one paired,
connected profile. Both health endpoints returned HTTP 200. Default configuration
and environment files remained byte-for-byte unchanged. A separate final Go
probe returned exit 0 for the installed native executable; the Agent checkout
matched the reviewed revision. No manual launcher replacement was needed in this
final run.

Tested script SHA-256:
`1f52ea6bdfa66b07be12bb6392ae6ff456c2b9e59460944922a2ccee246a5484`.
Private phone test files were removed after final verification.

## Validation and limits

- `node --test test/tooling/termux_installer_test.mjs`: 17 passing, including
  integrity rejection, existing-install adoption, explicit update, launcher
  repair and rejected-candidate paths, plus a real Go probe test with extra
  Android-style arguments. Installer subprocesses are fixtures in
  this suite; the physical run supplies actual runtime evidence.
- `flutter test test/features/local_setup/termux_bootstrap_command_test.dart test/tooling/wing_link_distribution_contract_test.dart`:
  17 passing.
- `bash -n install-termux.sh` and `git diff --check`: passing.
- Real pinned artifact verification also passed on Linux using `--verify-only`.

No fresh-install, reboot/background persistence, provider inference, microphone,
or audio qualification is claimed by this test. Screenshots and private runtime
logs are excluded from Git; pairing codes and credentials are excluded from the
sanitized test receipts.
