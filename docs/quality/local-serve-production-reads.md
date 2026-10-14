# WING-TASK-405: local serve read connection

Status: implemented candidate, pending independent native exact-candidate review.
This receipt does not close CONNECTION-PATHS, authorize publication, or qualify a
live Agent, inference, Android, secret acquisition, keyboard/IME, or keychain.

## Product outcome and scope

On Linux Local, deliberately select **Read an already-running Hermes serve
backend**, open the existing advanced endpoint field, and enter that backend's
session token in the masked field. Connect composes Agent-owned profiles, sessions
and history into the existing Chat controls. Denial and unavailable read contracts
remain errors; Cancel abandons the request; retry requires another explicit
Connect. Late completions cannot replace a newer connection. Profile selection
carries an explicit `profile` query and never changes the Agent's active profile.

Only exact fixed REST reads are promoted. No process starts, generic RPC bridge,
CLI fallback, remote/browser/Android mode, ticket negotiation, mutation, approval,
Stop, or inference is enabled. The gateway API client is absent while serve reads
are selected. The read-only marker is not a grant, capability document, or schema
advertisement. Session mutations and Chat are unavailable even though legacy
REST behavior otherwise treats an absent capability document permissively.

Credentials are manually supplied through the existing masked, no-suggestions
field and held ephemerally by the origin-bound reader. Selecting the serve option
clears gateway credentials. This slice does not read Agent secret files, mint a
token, use a provider/API_SERVER_KEY credential, or save a serve token into gateway
records. Existing secure endpoint storage and inert legacy records are unchanged.
The form explicitly explains that this read connection is not saved across
relaunch. Persistent serve restoration is not claimed; WING-TASK-407 owns that
subsequent outcome. Real host token acquisition is NOT_CHECKED.

## Inspected official contract

Read-only upstream checkout: `158fd638da1629c8e62caf9ade1515d162def8ab`.

- `hermes_cli/web_server.py:452-463`: default loopback REST accepts the server
  session token via Bearer (or its dedicated session header). Wing uses Bearer.
- `hermes_cli/dashboard_auth/middleware.py:153-175`: gated REST instead verifies
  a provider session bearer. These credentials are not interchangeable.
- `hermes_cli/dashboard_auth/routes.py:469-493`: ticket minting requires an
  authenticated session; a default loopback static token does not establish one.
- `hermes_cli/web_server_chat.py:250-374`: default loopback WebSocket accepts a
  token URL, whereas gated mode accepts a one-use ticket subprotocol. Wing does
  not put a session token in a URL, and does not promote this WS leg.
- `hermes_cli/web_routers/profiles.py:83-99,786-800`: fixed `GET /api/profiles`
  uses `name` identity and `display_name`; host paths and extras are discarded.
- Existing read DTOs validate `GET /api/sessions?profile=...&limit=...&offset=...`
  and `GET /api/sessions/{id}/messages?profile=...&limit=...&offset=...&order=latest`.
  Pagination, bounded bytes, redacted errors, redirects and identity checks remain.
- Official Desktop `apps/desktop/electron/dashboard-token.ts` and
  `host-published-token.ts` were inspected, not copied as credential acquisition.
  Their privileged attach/discovery behavior is not implemented here.

## Executed evidence

- `flutter pub get --offline --enforce-lockfile`: passed in the task workspace.
- `flutter gen-l10n`: generated the English output; no generated source was edited
  manually.
- `flutter analyze --no-pub`: passed after correcting initial formatting/lint info.
- `flutter test --no-pub --concurrency=1` with web-read, adversarial web-read,
  local-serve channel, local-serve production controls and secure endpoint-store
  targets: 65 passed. The completion helper repeats these and the nearest existing
  channel/connection regressions before its scoped commit.
- `python3 -B integration_test/run_linux_local_serve_reads.py`: isolated native
  Linux GTK app compiled and passed against its task-owned authenticated fixture.
  Receipt: six GET requests, zero mutations, zero credential saves; authentication
  denial, missing operation, cancellation and explicit retry observed. Captured
  profile `default`, session `default-session`. Source manifest SHA256
  `c3b2eaf20bbbb5279d1018e0a82f63904177a5288689bfac8342ff8cb4f13762`.
  Successful rehearsal duration: 39.291 seconds. The completion helper repeats the
  journey on the final frozen candidate; its receipt binds the final checks/ref.
- Native builds reuse copied user-space development packages; no system packages,
  installed services or live configuration were changed. SDK/packages and source
  are copied into owned isolation; personal HOME/XDG/DBus are not inherited.
- Native text input uses the repository's registered test-text-input pattern.
  The first two native rehearsals failed because unregistered native IME editing
  replaced the retry token; the second rehearsal identified the field mismatch.
  Registering test text input fixed the harness, not Agent auth. Native hardware
  keyboard/IME qualification remains NOT_CHECKED.
- Initial widget compile failed for a missing `Size` import; a later widget run
  identified the collapsed advanced field, then debug platform-override teardown.
  These harness issues were repaired; the subsequent widget journey passed.
- An early pub/analyze invocation ran in canonical rather than task cwd and is not
  candidate evidence. It changed no Wing source; canonical's unrelated goals.json
  change was preserved. All acceptance commands thereafter use explicit task cwd.

## Remaining and method choice

Ponytail: reuse the existing channel, bounded web-read DTO/client, Local form,
profile/session/transcript composition and isolated Linux helper functions. Add
only a fixed read branch and the browser-unavailable seam; no second state store,
transport registry, secret acquisition service, dependency or automatic fallback.

Independent review, coordinator integration/publication and live acceptance are
separate and pending. WING-TASK-406 mutation/lifecycle wiring stays blocked until
WING-TASK-405 acceptance closes. No upstream files were modified. No full-suite,
provider, real-secret, physical keychain, web runtime or Android check is claimed.
