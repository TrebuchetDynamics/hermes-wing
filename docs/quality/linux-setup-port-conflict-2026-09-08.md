# Linux setup progress and occupied-port recovery — 2026-09-08

## Observed failure

The installed Linux app displayed a generic installing message until setup failed.
Read-only checks found a healthy Hermes CLI and a Python static HTTP server on
the expected local API port, 8642. Its HTTP responses were not Hermes capability
responses. The existing doctor reported Agent API readiness false and Wing Link
loopback readiness true. The unrelated listener was left running.

The bootstrap path treated failed authenticated health as a reason to configure
and restart Hermes, then waited for health on the occupied port. A regression
with an occupied loopback listener reproduced three mutation attempts. The UI
also discarded stage identifiers and the process adapter discarded structured
terminal errors, leaving only a generic failure message.

## Change

- After verifying an existing installation and checking gateway health, bootstrap
  checks whether the expected loopback port can be bound before credential or
  endpoint changes and gateway restart. An address-in-use error fails closed;
  other bind errors remain generic failures. A healthy authenticated gateway skips
  the port check and is reused without restart.
- Local JSON/JSON-lines setup failures include a bounded error code. Wing accepts
  the known `gateway_port_in_use` code for recovery copy and never displays raw
  host stderr or server-provided error text. Older generic failures still work.
- Setup displays allowlisted, localized stages and progress, including detection,
  download, installation, endpoint setup, gateway startup, and health verification.
  The lengthy architecture paragraph was replaced with one setup instruction.
- **Stop setup** waits for process cancellation, including cancellation requested
  before process startup completes. **Check again** inspects the installation;
  it does not silently rerun setup. Failed setup also offers connection options.
- The completed Linux bundle was installed locally. With the conflicting listener
  still running, its real `wing-link setup --json-lines` stopped in **1.07 seconds**
  with stages `inspect`, `preflight` and code `gateway_port_in_use`; it did not
  enter authentication, endpoint configuration, or gateway restart.

No upstream Agent code, arbitrary command interface, remote path input, or domain
state was added. The preflight is an early diagnostic, not a port reservation;
the final authenticated health verification still handles a listener race.

## Validation

The occupied-port mutation regression, discarded-code regression, and missing
stage/recovery widget regression failed before the fixes. Focused Flutter setup
and Wing Link tests passed (54 tests), as did `flutter analyze` and
`(cd wing_link && go test ./...)`. `scripts/install_linux.sh` built and installed
the native Linux release, and the installed helper reproduced the bounded,
non-mutating port-conflict result on this host.

The full `flutter test --concurrency=1` suite passed **1,656 tests**. Repository
Dart formatting verification passed without changes, and `npm audit` reported
zero vulnerabilities. The installed native app was relaunched and exposed one
Linux desktop window.

The release E2E web build passed all eight browser suites on rerun: **46 passed,
1 skipped**. The initial `npm run web:e2e` run stopped on an Office accessibility
tree startup timeout (including its automatic retry); the isolated Office rerun
and subsequent full suite both passed without code changes. README assets
regenerated and were visually reviewed using an isolated deterministic server;
the first capture attempt sharing the browser test fixture timed out after that
fixture was reset. `git diff --check` passed.

Successful adoption on this host remains dependent on freeing the occupied port.
No successful setup, microphone, or other-platform runtime qualification is implied.
