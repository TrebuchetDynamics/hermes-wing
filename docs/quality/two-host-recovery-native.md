# Two-host selection and recovery qualification

This card qualifies a bounded CONNECTION-TWO-HOST-RECOVERY slice, not the complete
CONNECTION-SETUP-AUTH-MATRIX, CONNECTION-SAVED-WORKFLOWS or CONNECTION-PATHS milestone.
Native same-card review is the final worker handoff; approval and protected-main
integration are separate.

## Implemented behavior and ownership

The shared production-channel scenario opens two saved synthetic hosts through
Chat's public keyboard-operated contact controls. Both expose profile
`synthetic-qa` and session `synthetic-history`, with different canonical histories.
It checks A → B → A intent, B's retained draft, cancelled delayed A success and
failure, and an earlier A result after a new A intent. Old completions cannot
change the current owner, history, draft or request ledger.

A B history pagination network failure exposed a production bug: the UI's network
predicate omitted `HermesApiTransportException`'s canonical safe message,
`Hermes API network connection failed`. The only production hunk adds that string
to `_isHermesNetworkError`; both Chat recovery and connection feedback use this
predicate. Inherited error-widget, endpoint-editor and other dirty work remains
predecessor-owned. The baseline-relative patch is retained at
`.task-evidence/t_e40e9669/owned-network-reconnect.patch`.

The scenario then denies B's capabilities read, asserts sanitized restoration
failure and disconnected live state while saved profiles remain unchanged, waits
without automatic reads/reconnect, and deliberately retries. Exactly one channel
connect and one canonical messages read restore the same B/profile/session and
replacement draft. The additional health/capability/profile/session summary reads
are read-only directory refresh, not another channel connect. All mutations are
rejected and counted; no new session, send, management operation or saved-endpoint
mutation occurs.

## Reproduction and source boundary

Run `timeout 15m bash scripts/run_linux_two_host_recovery.sh` from the assembled
Wing checkout. It accepts no arguments or credentials. The launcher reuses the
remote-retry → direct-first-run → frozen predecessor runtime helpers, and the
Dart fixture reuses their bounded HTTP adapter and real API channel. Those
predecessor files are required inputs, not owned additions in this commit.
The launcher compiles and runs the production Chat screen, directory and API
channel; synthetic authority replaces HTTP responses and endpoint storage.
There are no live Agent, provider, model or management calls.

Each attempt retains a source archive, per-input ownership/hashes, copied package
and Go module closure, lockfiles, toolchain identity, commands, durations, exit
codes and logs under `.task-evidence/t_e40e9669/attempt-*/`. Upstream Agent,
Desktop and Conduit clones are excluded. The immutable entry archive wins for
all source overlaps; a separately retained web archive supplies only web,
Playwright and npm inputs missing from entry. Owned overlays and the single
production hunk are explicit. Later concurrently authored managed-SSH files are
not admitted into this candidate. This is not an integrated main/SSH build.

Temporary HOME/XDG/DBus state, Xvfb authority and displays are isolated. Native
build parallelism is two. Missing native development libraries are downloaded
and extracted without sudo. Chromium uses a short per-card scratch TMPDIR to
stay within Unix socket path limits, with one worker and no retries. The web
build disables the unused wasm dry run; the shipped JavaScript target is still
freshly release-compiled. The launcher owns and tears down process groups,
checks port release and deletes large isolated build trees.

## Acceptance evidence

Final launcher pass: `.task-evidence/t_e40e9669/attempt-h_ds5dpw/verification.json`,
339.726 seconds, exit 0. Executed source archive SHA-256:
`4435bbec54176cfa8541982a4e8548ef7986526005a7211107101508d419cd68`.
All ten recorded checks passed: four changed Dart files formatted unchanged,
`flutter analyze --no-pub`, the focused scenario, 86 combined saved/gateway
ownership widget regressions, five Python tooling tests, shell syntax, four
compiled GTK journeys, npm installation, fresh release JavaScript build and
six Chromium owner regressions. Exact argument vectors and timings are in the
receipt; browser output is `check-browser.log`. Node was v24.19.0 (not the
repository's recommended Node 22); Chromium was 152.0.7977.75. The GTK driver
checks, authenticated Xvfb teardown, browser process teardown, released ports
and deleted isolated HOME/build workspace all passed. The unchanged production
scenario's earlier captures were inspected; final captures are retained too.
Documentation-only receipt updates after execution do not change build inputs.

1. `integration_test/support/two_host_recovery_native_fixture.dart` drives
   production saved selection, same-ID owner/draft/cache assertions, public
   cancellation, late success/failure and same-ID return fencing. The focused
   widget regression executes the same scenario without screenshot capture.
2. `integration_test/linux_two_host_recovery_test.dart` executes all those paths
   in compiled Linux GTK at widths 1280 and 390, each at text scales 1 and 2.
   Selection, pagination failure, reconnect and restoration retry are reached
   with Tab/Space, not direct callback invocation. Each native receipt records
   exact owner/method/path/query reads and verifies zero forbidden reads and
   mutations. The launcher additionally checks native process ownership and
   independent wide/compact selected, denied and recovered captures.
3. The scoped format, analyzer, widget ownership regressions, Python receipt
   tests, shell syntax, Linux execution, fresh web compile and affected Chromium
   owner regressions are recorded in per-attempt verification receipts. The final
   handoff identifies the passing attempt and its exact fingerprint.

Visual inspection of retained native selected/denied/recovered captures shows B's
canonical history and replacement draft after recovery; compact 2x text wraps
without hiding the composer controls. Wide 2x denial shows the sanitized
"Conversation not restored" message and operable Retry. Captures include the
Flutter debug ribbon and Xvfb desktop background; these are debug GTK evidence,
not release layout or screen-reader qualification.

## Failed attempts and scope limits

Preparation failures are distinct from native execution: missing pkg-config
prerequisites, fixture setup/discovery errors and concurrently introduced
managed-SSH analyzer errors were corrected or excluded by the attributed entry
snapshot. The first real scenario exposed the missing network predicate and
passed after the owned fix. A later run passed all four GTK scenarios but was
terminated during the unused wasm dry run. The subsequent fresh web compile
passed; Chromium initially could not launch because its singleton socket used
a deeply nested TMPDIR. The short owned browser scratch fixes that harness issue
without changing product behavior or test expectations. Failed receipts/logs
remain available; no failure is relabeled as a pass.

The next attempt passed all GTK and Chromium checks but failed the final port
probe: accepted TCP sockets in TIME_WAIT prevented a default bind despite owned
server teardown. The corrected SO_REUSEADDR probe still rejects a live listener;
a real-socket Python regression proves both cases. These diagnosed harness
retries exceeded the nominal three-attempt guidance without repeating an
unchanged failure or weakening acceptance.

NOT_CHECKED: live authentication/OAuth, Local setup-needed matrix, managed SSH,
Android, physical secure storage, real keyboard hardware, screen readers,
release packaging and protected-main delivery. Next milestone work remains the
unqualified setup/auth and saved-workflow matrix plus integration-owner
MT-RERUN-TRAIN gates. No additional card is created by this slice.

Questions: none. No new architectural or trust-boundary default was needed.
