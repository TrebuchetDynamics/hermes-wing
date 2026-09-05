# Physical real-service profile lifecycle — 2026-09-05

The profile lifecycle passed on a physical Samsung SM-S928B running Android 16,
using the production Flutter entry point and real installed Hermes Agent and
Wing Link executables. This was not the deterministic profile fixture.

The Agent and Wing Link ran against an isolated, task-owned Hermes home on
Linux. The phone reached their independent authenticated loopback listeners over
USB reverse mappings. This qualifies the real management lifecycle over that
transport; it does not qualify remote TLS, provider/model readiness, chat, or
physical audio.

## Physical results

| Step | Evidence |
| --- | --- |
| Pair | Opened the real five-minute, no-store handoff, reviewed the two connections and access, and confirmed enrollment on the phone. The broker exited successfully. |
| Baseline | Phone showed the real Wing Link-managed default profile. |
| Create/clone | Created `cycle20260905` by cloning default in Wing. Both the phone and the real Hermes CLI listed the new profile. |
| Rename | Renamed it to `cycle20260905renamed` through Wing. The CLI confirmed the new identity. |
| Relaunch | After stopping and relaunching Wing, pairing remained available and the renamed profile reloaded from the host; the old identity was absent. |
| Delete confirmation | Entered the exact renamed profile name on the phone. Wing displayed the local host-approval instructions. |
| Unapproved retry | Retried on the phone before approval. The profile still existed and the host retained exactly the same pending request ID. |
| Approved retry | Approved only that exact deletion with the local Wing Link CLI, then tapped **Retry approved deletion** on the phone. |
| Final inventory | Wing returned to the default-only list. The approval was consumed and both test-profile directory names were absent. |
| Cleanup | Removed the task's saved connection through Wing's disconnect confirmation, verified the empty directory screen, revoked its named Wing Link credential locally, stopped the temporary services, and removed only the task-owned USB reverse mappings. The user's original profile listing was unchanged. |

Rename, relaunch, delete confirmation, unapproved retry, and approved retry were
asserted by Maestro. Pairing, initial create, and final connection removal were
driven through the physical Android UI with fresh accessibility-tree evidence
and host checks. An initial cleanup automation attempt collided with another
fixture run; connection removal was subsequently completed and verified through
the app UI.

## Fix exercised on hardware

The profile editor previously discarded Wing Link deletion approvals. Each retry
generated a new idempotency key and could not consume the approved request.
The editor now retains the request key, freezes editing while approval is
pending, displays host approval instructions, and offers an explicit retry.
Expiry requires a new confirmation. Both profile-screen deletion callbacks
forward the retained key. The phone never grants host approval.

The widget regression verifies the same profile, revision, and key on retry.
Removing the approval handling makes it fail; restoring it passes. The real
phone/host cycle independently verified pending-request reuse and consumption.

## Validation

- `flutter gen-l10n`: passed.
- `dart format --output=none --set-exit-if-changed lib test integration_test`:
  323 files, zero changes.
- `flutter analyze`: final run passed with no issues.
- `flutter test test/features/profiles test/core/wing_link`: 87 passed.
- `flutter test --concurrency=1`: resumed full run, 1,545 passed.
- `(cd wing_link && go test ./...)`: passed.
- `flutter build apk --debug -t lib/main.dart`: passed; installed as an update
  without clearing the original app's data and exercised on the named phone.
- `flutter build web --release -t lib/main_e2e.dart`: passed.
- `npm run web:e2e`: 45 passed, including two screenshot checks.
- `npm audit`: zero vulnerabilities.
- `git diff --check`: passed.

The first full Flutter run had one gateway-contact semantics failure. The
concurrent `hw2` work fixed that behavior; the nearest 15 tests and the resumed
full suite then passed. Concurrent fixture work also briefly produced an analyze
warning, which was resolved before the final clean run.

## Artifact and boundaries

The tested APK SHA-256 was
`f8fee17fc400a9b07f31b9e8651751a31d444d14bc5a88d4f776843d2ae1f7b8`.
The shared worktree was based on commit
`92a3d418b425d6ef095eb304e1f2ba18cfcd0392` and contained uncommitted work from
both sessions. The APK includes the deletion retry fix; subsequent edits changed
approval/expiry wording, covered by the final Flutter checks. This is a debug
validation artifact, not a signed release.

No provider credential was provisioned and no provider inference was requested.
The cloned profile correctly remained unconfigured and not enrolled for chat.
Configured new-profile setup/readiness, successful profile chat, and existing
platform/audio limitations are not upgraded by this receipt. The host's existing
non-test gateways were neither restarted nor reconfigured.

Private logs, accessibility trees, runtime state, and screenshots remain outside
the repository. The companion JSON contains only redacted qualification facts.
