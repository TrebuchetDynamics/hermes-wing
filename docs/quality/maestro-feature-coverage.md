# Maestro feature coverage

The feature fixture runs production Flutter screens with deterministic service
doubles in an isolated Android package, `com.trebuchetdynamics.hermes.wing.qa`.
Its entrypoint and scenario controls live only under `integration_test/`; the
production entrypoint does not import them. It never connects to a live Agent,
Wing Link host, or provider. Mutations affect disposable in-memory fixture data.

Run on an explicitly selected Android device:

```bash
WING_QA_DEVICE=<adb-serial> npm run android:maestro-features
```

The runner validates YAML, builds and installs the debug fixture, and executes
the flows. Each scenario clears only the `.qa` package. Settings persistence is
tested by restarting that package without clearing it within the scenario.
Output defaults to the ignored `test-results/maestro-features` directory; set
`WING_QA_OUTPUT_DIR` to use an external temporary directory. Use a dedicated
device without another automation job driving its UI.

| Flow in `scripts/maestro/fixture/` | Behavior exercised |
| --- | --- |
| `attachments.yaml` | Synthetic text/image picker results, pending-attachment removal, prevention of a second attachment, cancellation, unsupported/big/invalid UTF-8 rejection, and submitted attachment receipts. |
| `attachment_picker_race.yaml` | A deferred picker completes after a session switch; neither session receives the stale result, and a fresh pick still works. |
| `draft_isolation.yaml` | Text and attachment drafts remain isolated and restore across session and profile identity changes; no turns are submitted. |
| `chat_groups.yaml` | Create, move a contact, rename, restart/read-back, and delete a local group while retaining the contact. Persisted group/assignment checks supplement UI assertions. |
| `composer_commands.yaml` | Emoji insertion and submission; `/sessions` and `/settings` execute locally without additional Agent submissions. |
| `transcript_export.yaml` | Exact native clipboard comparison for synthetic text and Markdown transcripts; clipboard contents are not printed. |
| `voice_language.yaml` | Spanish recognition-language selection survives restart; English and automatic modes remain selectable. |
| `providers.yaml` | Empty credential validation, write-only set/remove/probe, model assignment, revision-conflict retry, and revoked write grants on an open sheet. Dispatch counters distinguish successful mutations from blocked attempts. |
| `soul_directories.yaml` | Standalone SOUL save/read-back and concurrent-edit rejection with authoritative reload; approved opaque-root browsing, child pagination, Back, and grant revocation removing stale folders. Project creation stays unavailable. |
| `schedules.yaml` | Advertised inventory, refresh, bounded failure, and recovery. No schedule mutations are advertised. |
| `approvals_recovery.yaml` | Approval review/denial, stopping a pending approval before a new run, approve-once, connection-state recovery with profile reopening and no resubmission, and earlier transcript history. |
| `sessions.yaml` | Session pagination with an additional row, bulk selection, confirmed deletion, and deletion dispatch count. |
| `settings.yaml` | Theme and speech-output preference persistence across process restart, command-word editing/read-back after restart, and diagnostics clipboard content checks. |
| `spellcheck.yaml` | Native spellcheck toggle persistence when advertised; an explicit unavailable-capability branch otherwise. |
| `gateway_connection.yaml` | Saved-connection rename, invalid URL rejection, connection/credential update, canceled removal, and confirmed removal of a disposable connection. |
| `gateway_trust.yaml` | Self-revocation cancellation and confirmation through the production Wing Link client with injected HTTP responses. |
| `trust_errors.yaml` | Changed reported host identity, expired/revoked credentials, and unsupported protocol UI. |
| `pairing.yaml` | Invalid scanner input, expired preview without exchange, rejected exchange, and explicit paste recovery. Codes and issued credentials are generated in memory; YAML contains none. |
| `local_setup_accessibility.yaml` | Android setup command copying at 200% text scale, plus folder navigation across rotation and focused Enter activation of Back. No installer is executed. |
| `microphone_denied.yaml` | Native Android microphone/nearby-device denial, native permission-state verification, lifecycle pause, and continued text chat. Recording permission is never granted by this flow. |

`open.yaml`, `control.yaml`, and `receipt.yaml` are subflows, not standalone
scenarios. The fixture toolbar exposes bounded counters and explicit failure injection; it is
not a product navigation surface. The fixture routes reuse production screens
but do not qualify the production shell's navigation transitions.

## Other suites

`npm run android:maestro-regression` remains the live, already-paired gateway
suite. It now also invokes concurrent-session, detached-process recovery, and
chat-UX flows using the supplied gateway/profile labels. It performs live Agent
mutations and is not invoked by the isolated feature runner.

The [profile-journey suite](maestro-profiles.md) covers profile creation, setup,
chat switching, and deletion through `npm run android:maestro-profiles`.
The same-device browser/share handoff
contract, native HTTP/SSE fixture, and Waydroid voice-recognizer suite require
different entrypoints or host/native harnesses. Do not mix their YAML into one
APK run. Their prerequisites remain in the respective flow headers and
`scripts/run_waydroid_hermes_voice_maestro.sh`.

## Evidence limits

Fixture success establishes UI behavior against the injected contracts. It does
not establish live provider authentication, socket-level TLS pin enforcement,
real QR-camera decoding, native file-picker/provider integration, successful
physical speech recognition, acoustic echo cancellation, real network-loss reconciliation, Termux installation, or service
qualification. Native permission dialogs currently cancel capture through the
foreground-pause path, masking the permission-specific message. The microphone
flow verifies actual denial via the existing native diagnostics bridge and
continued text chat; it does not claim the permission-specific banner works. The
pairing flow specifically injects scanner results. Attachment flows inject
synthetic `XFile` results through the existing picker provider; profile/session
changes in the race/isolation scenarios are explicit fixture controls. History
and reconnect data in this suite are in memory, not fetched over HTTP/SSE.

TalkBack traversal and full-app hardware keyboard coverage remain outside these
Maestro scenarios. Folder navigation checks focused Back activation with Enter;
the spellcheck flow records a conditional path based on the native capability. Existing
widget/platform tests cover other parts of those boundaries; they must not be
described as Maestro device evidence. Planned or contract-gated product features
remain governed by [route status](../product/routes.md).

## Validation commands

On 2026-09-04, all 13 scenarios passed on a physical Samsung SM-S928B running
Android 16 using the isolated package, across focused reruns while developing
the suite. This was not one aggregate 13-flow invocation. Its native spellcheck capability was false, so
the unavailable branch passed; toggle persistence still needs a device exposing
that service. The live gateway suite was syntax-checked, not executed.

Static and focused Flutter validation:

```bash
dart format --output=none --set-exit-if-changed \
  integration_test/hermes_features_maestro_main.dart \
  integration_test/support/maestro/feature_channel.dart \
  lib/features/settings/screens/settings_voice_screen.dart \
  test/features/settings/settings_voice_screen_test.dart \
  test/integration/maestro_feature_fixture_test.dart
flutter analyze --no-pub
flutter test test/integration/maestro_feature_fixture_test.dart --reporter expanded
flutter test test/features/settings/settings_screen_test.dart \
  test/features/settings/settings_voice_screen_test.dart \
  test/integration/maestro_feature_fixture_test.dart --concurrency=1 --reporter expanded
bash -n scripts/run_android_maestro_features.sh scripts/run_android_maestro_regression.sh
git diff --check
```

The nearest UI checks passed (83 tests):

```bash
flutter test \
  test/features/providers/provider_credential_sheet_test.dart \
  test/features/providers/model_picker_sheet_test.dart \
  test/features/soul/soul_screen_test.dart \
  test/features/profiles/profile_directory_browser_sheet_test.dart \
  test/features/gateway/gateway_screen_test.dart \
  test/features/schedules/schedules_screen_test.dart \
  test/features/settings/settings_screen_test.dart \
  test/features/settings/settings_diagnostics_screen_test.dart \
  test/features/hermes_chat/screens/hermes_chat_approval_review_test.dart \
  --concurrency=1 --reporter=compact
```

The five voice-screen tests and four fixture tests bring the unique
focused total to 92. All 18 new or modified YAML files passed
`maestro check-syntax <flow.yaml>`.

The settings device scenario exposed a command-word save crash. Extending the
existing widget test to press Save reproduced a disposed-controller exception.
The editor now owns its controller until the closing sheet is unmounted, and
the regression test passes through the dismissal animation.

## Composer and organization expansion

Seven additional scenarios are wired into the feature runner (20 total).
Attachment bytes remain in memory; relative synthetic filenames supply the
native `XFile` name without reading or writing a host file. Image submission
checks the exact data URL, and text submission checks the exact content/name.
Group receipts read the production preferences controller after UI mutations.
Transcript receipts compare the entire synthetic text/Markdown export and
expose only booleans.

The group flow exposed a hidden accessibility action: grouped contact rows
excluded Move to group from the semantics tree. The row now retains its
descriptive label while exposing the action, with a focused regression test.

Composer hardware Tab traversal is covered by a Flutter widget test. A native
composer keyboard flow was attempted but is not included: the installed Maestro
Android driver maps `Tab` to Android key code 62 (Space), rather than 61 (Tab).
The existing folder flow confirms focused Back activation with Enter; it does
not independently establish Tab traversal. Full native keyboard navigation
still needs qualification with a driver that emits the correct key.

On 2026-09-05, all seven new scenarios passed on the physical Samsung SM-S928B
running Android 16 with the isolated package, across focused invocations. The
race, draft-isolation, and group flows passed together; the remaining four passed
in one final invocation after fixture/selector corrections. This is not evidence
of one aggregate 20-flow run. The final focused Flutter suite passed 154 tests;
`flutter analyze --no-pub`, changed-Dart formatting, YAML syntax validation,
runner shell syntax, and `git diff --check` also passed. Other platforms and the
live gateway suite were not exercised for this expansion.

Focused validation command for this expansion:

```bash
flutter test \
  test/features/hermes_chat/groups/chat_group_controller_test.dart \
  test/features/hermes_chat/gateways/gateway_contacts_view_test.dart \
  test/features/hermes_chat/composer/hermes_composer_draft_store_test.dart \
  test/features/hermes_chat/screens/hermes_chat_slash_commands_test.dart \
  test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart \
  test/features/settings/settings_voice_screen_test.dart \
  test/integration/maestro_feature_fixture_test.dart \
  --concurrency=1 --reporter compact
```
