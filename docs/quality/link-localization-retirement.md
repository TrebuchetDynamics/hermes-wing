# Agent-only localization retirement

Task: `t_421d4aaa`; consumer slice of CONNECTION-LINK-REMOVAL.
Admitted base: `e2eaa65b4b00dcd1ffd9421d0dc292c8294497d0`.
This receipt does not close the parent milestone or qualify service removal.

## Admission and boundary

Original pre-edit worker guard returned `worker_start_admitted` for this native
workspace, using manifest `pass-d792407fd551b5c9-1b692f6c845b4de09dd1c88cd742dd97.json`
and pinned SHA-256 `29a5b4cc094e1657b18f665c75957929dadae5704eb8cc08960b17943e9ec2bb`.
The original guard command and its ordering are retained in the native run tool
history; this document is not substitute admission evidence. Repository instructions
and the [accepted consumer retirement](../adr/product.md#complete-removal-including-legacy)
were inspected. No overlapping Wing card was observed in the running/ready/review
board readback. Canonical source, ledgers, upstream/runtime, service, packaging and
installers are unchanged.

## Deleted input and traced consumers

Removed 136 unused English messages and their seven metadata entries. The two
localization Dart files were regenerated with `flutter gen-l10n`, not edited by
hand. A whole-word scan of tracked client, test, integration, browser, scripts and
platform sources found no consumer for these keys outside generated localization.
The sole tooling reference, `managedByWingLink`, is a forbidden-source sentinel
in `enrollment_retirement_contract_test.dart`, not an accessor or fixture value.
Analyzer and affected tests verify that no getter dependency remains.

| Group | Messages | Traced absent consumer / retained replacement |
| --- | ---: | --- |
| Enrollment exchange, QR, computer setup, review, readiness, failure and completion | 101 | Retired controller/setup/scanner surfaces; retain current enrollment title, Local/Termux help and explicit legacy rejection. |
| Gateway trust/device/revoke | 18 | No live trust UI accessor; direct Agent connection/status controls remain. |
| Approved directory browser | 9 | No live directory browser accessor; service safety tests are preserved. |
| Profile approval/setup retry/cancel | 6 | No live compatibility approval caller; Agent editor remains unchanged. |
| Management badge/independence | 2 | No live badge/help accessor; existing Agent saved-connection explanation remains. |

Exact removed message keys (metadata with the corresponding `@` name is removed
when present):

- `directoryBrowserBackAction`
- `directoryBrowserEmptyBody`
- `directoryBrowserEmptyTitle`
- `directoryBrowserError`
- `directoryBrowserLoadMoreAction`
- `directoryBrowserLoading`
- `directoryBrowserProjectUnavailable`
- `directoryBrowserTitle`
- `directoryBrowserUnavailable`
- `enrollAgentConnected`
- `enrollBrowserPairingHelp`
- `enrollCheckReadiness`
- `enrollCleartextDialogBody`
- `enrollCleartextDialogTitle`
- `enrollCleartextNotice`
- `enrollClipboardEmpty`
- `enrollClipboardUnavailable`
- `enrollCloseAction`
- `enrollCommandCopied`
- `enrollComputerAction`
- `enrollComputerExisting`
- `enrollComputerExistingHelp`
- `enrollComputerHelp`
- `enrollComputerInstallBody`
- `enrollComputerInstallTitle`
- `enrollComputerModelBody`
- `enrollComputerModelTitle`
- `enrollComputerReady`
- `enrollComputerRequirements`
- `enrollConnectAction`
- `enrollConnectProfilesAction`
- `enrollConnectedBody`
- `enrollConnectedLocalBody`
- `enrollConnectedProfiles`
- `enrollConnectedWingLinkBody`
- `enrollConnectedWingLinkLocalBody`
- `enrollConnectingSaved`
- `enrollConnectionString`
- `enrollContinueAction`
- `enrollCopyCommand`
- `enrollCredentialsSaved`
- `enrollDeviceLabel`
- `enrollEndpointLabel`
- `enrollEnterLink`
- `enrollExchangeFailedBody`
- `enrollExchangeFailedTitle`
- `enrollExpiredBody`
- `enrollExpiredTitle`
- `enrollExpiresLabel`
- `enrollExpiryUnknown`
- `enrollExternalStepNotice`
- `enrollFailed`
- `enrollFailureAcknowledge`
- `enrollFailureAgent`
- `enrollFailureInvalid`
- `enrollFailureManagement`
- `enrollFailureNetwork`
- `enrollFailureRejected`
- `enrollFailureStorage`
- `enrollFailureTimeout`
- `enrollFailureTls`
- `enrollFailureUnsupported`
- `enrollFreshPairingHelp`
- `enrollGrantQuestion`
- `enrollHermesAgentLabel`
- `enrollImageUnavailable`
- `enrollImportQrImage`
- `enrollInspectionFailedBody`
- `enrollInspectionFailedTitle`
- `enrollInvalidLinkBody`
- `enrollInvalidLinkTitle`
- `enrollLinkInputHelp`
- `enrollManualConnectAction`
- `enrollManualConnectWarning`
- `enrollModelConfigured`
- `enrollModelMissing`
- `enrollModelSetupFinished`
- `enrollModelUnknown`
- `enrollOpenChatAction`
- `enrollOpeningScanner`
- `enrollOriginMismatch`
- `enrollPairChoiceHelp`
- `enrollPairHeading`
- `enrollPairHelp`
- `enrollPasteAnotherLink`
- `enrollPasteLink`
- `enrollPhaseAcknowledge`
- `enrollPhaseAgent`
- `enrollPhaseExchange`
- `enrollPhaseManagement`
- `enrollPhaseSave`
- `enrollProfilesLabel`
- `enrollReadinessHelp`
- `enrollReadingClipboard`
- `enrollRequestedAccess`
- `enrollReviewLink`
- `enrollSameDeviceHelper`
- `enrollSavedNotConnected`
- `enrollScanAnotherQr`
- `enrollScanPrompt`
- `enrollScanQr`
- `enrollScannerUnavailable`
- `enrollScopesNone`
- `enrollSetupHeading`
- `enrollSetupProfileAction`
- `enrollStepProgress`
- `enrollUnlabeled`
- `enrollVerifying`
- `enrollViewProfilesAction`
- `enrollWingLinkLabel`
- `gatewayManagementIndependent`
- `gatewayTrustApprovalPending`
- `gatewayTrustChangedIdentity`
- `gatewayTrustCredentialExpired`
- `gatewayTrustDetails`
- `gatewayTrustDevice`
- `gatewayTrustFingerprint`
- `gatewayTrustHostInstructions`
- `gatewayTrustLoading`
- `gatewayTrustProtocol`
- `gatewayTrustRevokeAction`
- `gatewayTrustRevokeBody`
- `gatewayTrustRevokeTitle`
- `gatewayTrustRevoked`
- `gatewayTrustRevoking`
- `gatewayTrustScopes`
- `gatewayTrustTitle`
- `gatewayTrustUnavailable`
- `gatewayTrustUpgradeRequired`
- `managedByWingLink`
- `profileApprovalExpired`
- `profileApprovalRequired`
- `profileCancelSetup`
- `profileDeletionApprovalExpired`
- `profileRetryApprovedDeletion`
- `profileRetryApprovedSetup`

## Live copy and decisions

Ten still-used values now describe delivered behavior:

- `chatSavedEndpointEditBody`: local save does not connect or change the conversation;
  a changed Agent URL needs its own credential, not a Link association.
- `gatewayStatusConnectionRequiredBody`: explicitly connect the saved Agent to load status.
- `chatConnectionDisconnectBody`: saved access survives disconnect; Agent stays running.
- `chatLayoutConnectBody`: direct Agent connection, no separate management offer.
- `chatLayoutRemoteAuthExplanation`: preserve credential-type separation, unsupported
  OAuth, explicit retry/cancel and uncertainty about denial; remove retired product branding.
- `chatLayoutCredentialBoundaryTitle` / `Body`: Agent credentials remain distinct from
  SSH authentication and provider keys; no offered management plane.
- `chatErrorConnectTlsBody`: verify changed identity through a trusted administrator
  before reconnecting, not through removed re-pairing.
- `settingsScanPairingQr`: the existing enrollment navigation offers direct Agent access.
- `chatLayoutScanQrAction`: existing legacy rejection navigation is labeled as rejection,
  not as a working QR scanner. Its old accessor name is retained because it has a
  live caller; renaming controls/routes is outside this copy-only slice.

Decision: preserve live accessor identifiers and correct their values rather than
rewrite callers or navigation. No storage, networking, grants, trust validation,
secure credentials, cancellation or mutation logic changes. Android SSH first,
Remote second, on-phone Termux third is unchanged; unsupported setup copy remains.
No new dependency, fallback state or abstraction.

## Acceptance evidence

- Discriminating RED: `flutter test --no-pub test/tooling/link_localization_retirement_contract_test.dart`
  failed for retired input and live saved-editor Link copy; the forbidden-offer
  negative control passed. First setup attempt lacked cached package configuration;
  a subsequent test had an incorrect package import, corrected to manifest name `wing`.
  These setup failures are not counted as discriminating RED.
- GREEN: the same command passed all three guard tests after regeneration. The guard
  also rejects deliberately supplied management, association, QR-scan and re-pair offers.
- `flutter gen-l10n`: passed; generated getter surface and English output match input.
- `flutter analyze --no-pub`: no issues (6.2 seconds in the first run).
- `dart format --output=none --set-exit-if-changed lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart test/tooling/link_localization_retirement_contract_test.dart`:
  checked by the finish gate.
- Focused command below: 238 tests passed (76 seconds in the first run), including
  rejected old input, Local/Termux limitations, saved edit/cancel/late result fencing,
  failed save/rename preservation, exact endpoint identity, credential isolation,
  secure/raw-store regression and retained directory-service safety contracts.
- `flutter build web --no-pub --release -t lib/main_e2e.dart`: passed (46.8 seconds
  in the first run). Existing flutter_tts Wasm dry-run and Cupertino font warnings
  remain warnings; this was a JavaScript build, not Wasm qualification.
- Chromium command below: 16 tests passed (about 90 seconds), including public
  keyboard edit/test, denial, cancel, failed save/retry and unchanged owner/storage,
  no mutation or management traffic, 390/1280 logical widths, 100/200% zoom and
  reduced motion. Existing fixtures were used unchanged.
- Initial bundled Chromium run: 14 passed, two zoom preconditions failed before
  editing (`innerWidth` 780/2560 instead of 390/1280). System Chromium honored
  the same persistent-profile zoom preferences and passed unchanged tests.
  The failed run remains in original tool history; no assertion was weakened.
- `git diff --check`: passed. Inspection found only input/generated localization,
  the new guard and this receipt; no user data, credential or private endpoint diff.

Focused acceptance command:

```sh
timeout 10m flutter test --no-pub --concurrency=1 test/features/enrollment test/features/local_setup test/features/settings test/features/gateway test/features/hermes_chat/screens/hermes_chat_saved_endpoint_edit_test.dart test/features/hermes_chat/screens/hermes_saved_endpoint_feedback_accessibility_test.dart test/features/hermes_chat/screens/hermes_chat_saved_connection_workflows_test.dart test/core/hermes/setup/saved_endpoint_edit_store_test.dart test/core/hermes/setup/secure_hermes_endpoint_store_test.dart test/tooling/enrollment_retirement_contract_test.dart test/tooling/link_localization_retirement_contract_test.dart
```

Browser acceptance command (after the named build):

```sh
CHROME_EXECUTABLE=/usr/bin/chromium PORT=18867 HERMES_E2E_PORT=18868 WING_APP_URL=http://127.0.0.1:18867/ timeout 8m bash -c 'node serve_web.mjs > .dart_tool/link-localization-server.log 2>&1 & server=$!; trap "kill $server 2>/dev/null; wait $server 2>/dev/null" EXIT; for attempt in {1..30}; do if curl --fail --silent http://127.0.0.1:18867/ > /dev/null; then break; fi; sleep 1; done; npx --no-install playwright test --config=playwright.config.mjs playwright/tests/regression/saved-endpoint-edit.spec.mjs playwright/tests/regression/browser-surfaces.spec.mjs'
```

## Source, dependencies and delivery

Flutter 3.44.2 / Dart 3.12.2; system Chromium 152.0.7977.75 on Linux;
observed Node v26.7.0 (not the repository's Node 22 target).
Dependencies were populated only from cache using `flutter pub get --offline`
and `npm ci --offline --ignore-scripts --no-audit --no-fund`; lockfiles unchanged.

- `pubspec.lock` SHA-256: `f089602c321af4a65d6f1dc70b6adef724079bedc8e4f1d0496f7b8e22641c89`
- `package-lock.json` SHA-256: `f32c4b4d226bf6cef1a1f66733d4c2e065e0656d1223e89f17ceb68f42429b63`
- English input SHA-256: `08e8f1b4d7ce9006febebe1b02c4ec32d064391be56b4f1157b26e327c7ebd78`

Finish target: `agent/wing/t_421d4aaa`. The finish helper receipt and native review
transition bind the exact full commit SHA and executable check arrays (a commit
cannot contain its own SHA). Review must verify original admission history, ref,
ancestry and cumulative five-file diff from the admitted base, then independently
check an isolated snapshot of that commit. Pending review is not approval.

Implemented: localization consumer closure. Qualified: Linux-hosted Flutter
widget/unit tests and deterministic Chromium browser journeys only. Delivered:
scoped local task commit after the finish gate; not canonical integration or remote
publication. Execution durations above are observations; review time and cost are
unknown. No supporting skill protocol was needed.

## Remaining milestone gaps

Physical Android, native GTK/keyring, live authentication/provider/inference,
Node 22 rerun, service/installer/packaging removal and complete Link retirement are
NOT_CHECKED here. A browser fixture is not native/device/provider qualification.
The QR-named live accessor/control is retained as rejection navigation, not support.
The coordinator owns independent native review, integration/publication and the
next bounded service/delivery closure slice; this worker does not close ledgers,
stop installed services or introduce another task.
