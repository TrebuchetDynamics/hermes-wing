# Physical provider setup and chat — 2026-09-05

Hermes Wing created and enrolled a provider-configured profile on a physical
Samsung SM-S928B running Android 16. Real Hermes Agent inference used OpenRouter
and `openai/gpt-4.1-mini`; the provider responses were not fixtures.

The production Flutter entry point ran in a debug APK. Real Agent and Wing Link
processes ran on Linux against an isolated test-owned Hermes home. The phone
reached their independent authenticated loopback listeners through USB reverse
mappings. This does not qualify remote TLS or physical audio.

## Setup and regression evidence

An existing authorized OpenRouter credential was provisioned into the isolated
base profile with the real Hermes authentication CLI through stdin. The phone
then created `provider20260905`, cloning that base profile and selecting
OpenRouter, `openai/gpt-4.1-mini`, and a description. Hermes performed the clone
and owned the resulting configuration and credential. The UI credential field
was left blank: this receipt does not qualify entering a new secret on Android.

The real run exposed three defects, each covered by a failing-then-passing
regression test:

- Quiet Hermes readiness output included one fixed security-scanner startup
  notice before its successful `Hi` response. Wing Link now accepts that exact
  known notice once; arbitrary diagnostics, missing replies, extra output, and
  repeated notices still fail and roll back the new profile. Security scanning
  and the readiness deadline remain enabled.
- Named-profile pairing validated credentials against the default home instead
  of the configured Hermes home. Containment now uses the configured root.
  Tests reject outside roots, prefix siblings, the unrelated default home, and
  symlink escapes without mutating the rejected file.
- The enrollment screen replaced the Android event-channel subscription used by
  the app shell. Closing enrollment canceled later warm handoffs. Both consumers
  now share one stream without caching payloads. After successful two-profile
  enrollment and closing that screen, a second real handoff opened the review;
  that additional review was canceled without exchanging credentials.

An earlier model, `z-ai/glm-5.3-flash`, exceeded the bounded readiness deadline
on a retry and the attempted profile was rolled back. The successfully tested
model was `openai/gpt-4.1-mini`. OmniRoute authentication and existing-profile
provider mutation were not qualified or changed.

## Chat and cleanup evidence

The phone created a new chat in the named profile and received a real answer.
A second prompt referred to the first answer without repeating it; the second
answer matched. After stopping and relaunching the app without clearing data,
both turns reloaded and a third real prompt received its expected answer.

Switching to default showed neither named-profile answer. Switching back restored
the named conversation. Read-only inspection of Agent-owned storage confirmed
three user turns and three assistant replies in the same session, matching
OpenRouter model-usage records, persisted provider/model configuration, and no
named-profile answer markers in the default database.

Maestro asserted these UI outcomes. Two initial automation selectors failed:
the composer hint was unavailable after sending, and relaunch resumed chat
instead of opening the directory. Corrected selectors passed against the same
app; neither failure was reported as a product defect.

The profile was deleted through Wing's typed confirmation and the exact locally
approved deletion retry. The host consumed that approval and the profile was
absent. The two saved Agent connections were removed through the phone UI
(including Settings removal for the now-offline named profile); Settings then
showed no saved gateways. Both test Wing Link device credentials were revoked.
The isolated services were stopped, only owned USB mappings were removed, and
the temporary Hermes credential home was deleted. The original user profile
listing was unchanged.

## Validation

- `dart format --output=none --set-exit-if-changed lib test integration_test`:
  324 files, zero changes.
- `flutter analyze`: no issues.
- `flutter test test/app/hermes_connect_intent_stream_test.dart test/app/wing_app_connect_intent_test.dart test/features/enrollment`:
  94 passed.
- `flutter test --concurrency=1`: 1,551 passed.
- `(cd wing_link && go test ./...)`: passed.
- `flutter build apk --debug -t lib/main.dart`: passed; installed and exercised
  on the physical Samsung without clearing app data.
- `flutter build web --release -t lib/main_e2e.dart`: passed.
- `npm run web:e2e`: 46 passed, including two screenshot checks.
- `npm audit`: zero vulnerabilities.
- `git diff --check`: passed.

## Artifact

The tested APK SHA-256 is
`d8baa2be39fe209d1686ead4dec0ec6011c729e6d7c97057c99664bc45825d3a`.
Its worktree base was `92a3d418b425d6ef095eb304e1f2ba18cfcd0392`, with
uncommitted changes from concurrent sessions. It includes the shared Android
handoff fix. It is a debug validation artifact, not a signed release.

Private runtime state, logs, accessibility trees, screenshots, credentials, and
synthetic transcripts remain outside the repository. This report contains only
redacted qualification facts. Deterministic provider/model fixture work in the concurrent `hw2` session is
separate from this real-provider receipt. Concurrent enrollment changes made
after these validation runs are not qualified by this report.

## PR CI follow-up

The first PR workflow completed all 124 Flutter suites but its strict machine
result parser rejected dependency-resolution chatter printed by Flutter before
the JSON events. The CI test command now uses `--no-pub`; the preceding explicit
`flutter pub get` remains responsible for dependency installation. No parser
validation was relaxed.

An isolated checkout of the PR source plus this command fix passed the actual
`node scripts/ci_test_receipt.mjs` command with coverage: 124/124 suites and
1,663 completed results (including suite-loading events). All 47 Node tooling
tests passed. These results are separate from the earlier shared-worktree and
physical-device receipts.
