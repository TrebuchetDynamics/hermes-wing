# Navivox TODO

[RESOLVED] Navivox-side Termux-to-Navivox pairing handoff without camera — 2026-05-24
  resolved: 2026-05-24
  result: Android now accepts `navivox://connect?...` VIEW intents and text/plain ACTION_SEND payloads, forwards initial and foreground intents into Flutter, fills the setup form through existing connect-info parsing, preserves explicit `websocket_url`, and keeps tokens out of notices/logging. Gormes still needs the Termux `am start ...` command-side launcher.

[RESOLVED] Stable Gormes gateway identity for Pairing handoff — 2026-05-25
  resolved: 2026-06-07
  result: Navivox now parses authenticated `gateway_id` from gateway status, persists non-secret saved-session metadata keyed by Gateway identity, and keeps credential key aliases based on Gateway identity instead of URLs/tokens/machine names.
  evidence: `NavivoxGatewayStatus.gatewayId` / `.hasGatewayIdentity` in `lib/core/gateway/capabilities/navivox_gateway_capabilities.dart`; session persistence stores `SessionPreferenceKeys.gatewayId`; gateway channel writes `status.gatewayId` on connect; E2E coverage in `test/e2e/gateway_identity_e2e_test.dart` proves authenticated status identity/label persistence.
  validation: `test/core/gateway/navivox_gateway_protocol_test.dart`, `test/core/session/session_persistence_service_test.dart`, and `test/e2e/gateway_identity_e2e_test.dart` cover the app-side identity contract.
  owner: Navivox app owner / Gormes gateway owner

[RESOLVED] Pairing handoff source trust classification — 2026-05-25
  resolved: 2026-06-07
  result: Android-originated handoffs now preserve source metadata into Flutter, distinguishing direct app-open links from shared text and QR/image imports for auto-connect policy.
  evidence: `PairingHandoffIntentParser` tags `ACTION_VIEW` and `ACTION_SEND`; `NavivoxPlatformConnectIntentPayload` normalizes payload/source; `SetupQrImageImport.source` feeds `PairingHandoffFlow.shouldAutoConnect()`.
  validation: `android/app/src/test/kotlin/com/trebuchetdynamics/navivox/pairing/PairingHandoffIntentParserTest.kt`, `test/features/servers/setup/sources/navivox_connect_intent_source_regression_test.dart`, and `test/features/servers/pairing/pairing_handoff_flow_test.dart` cover source classification and shared-text no-auto-connect behavior.
  owner: Navivox app owner / Android owner

[RESOLVED] Pairing handoff bridge-stopped recovery copy — 2026-05-25
  resolved: 2026-06-07
  result: Direct pairing-link auto-connect failures now show pairing-specific recovery copy, keep fields populated, stop retrying automatically, and do not render the token.
  evidence: setup applies `PairingHandoffSource.directAppOpen` through `PairingHandoffFlow`; failed direct app-open tests assert `Pairing needs attention` and `Could not connect from the pairing link.` without the secret token.
  validation: `test/features/servers/setup/flows/navivox_connect_and_talk_test.dart` covers direct app-open failure and token non-leakage.
  owner: Navivox app owner / Gormes gateway owner

[RESOLVED] Pairing handoff auto-connect and active-gateway confirmation — 2026-05-25
  resolved: 2026-06-07
  result: Direct app-open Pairing handoffs auto-connect only when no active gateway exists; shared text and QR/image imports fill fields and wait; active-gateway handoffs require confirmation before probing or switching.
  evidence: `PairingHandoffFlow.shouldAutoConnect()` gates on source plus active-gateway state, and `requiresActiveGatewayConfirmation()` covers every handoff source when a gateway is active.
  validation: `test/features/servers/pairing/pairing_handoff_flow_test.dart` and `test/features/servers/setup/flows/navivox_connect_and_talk_test.dart` cover no-active-gateway auto-connect, shared-text manual connect, and token-safe failure behavior.
  owner: Navivox app owner / Gormes gateway owner

[PLANNED] Pairing handoff setup-intent routing — 2026-05-25
  problem: accepted Pairing handoff semantics allow Gormes to suggest a high-level setup landing target, but Navivox currently parses connection fields plus optional Profile contact routing and does not route post-connect based on setup intent fields.
  evidence: no live app parser references currently exist for `setup_handoff`, `setup_sections`, or `setup_entry_screen`; config-admin itself is now wired, but descriptor-provided setup intent is still not carried through Pairing handoff as a suggestion.
  acceptance: carry setup intent through Pairing handoff as a suggestion only; after successful connection, capability-gate any setup/config destination against the Gormes capability document; if unsupported, land on normal Profile contacts/config entry; never enable config mutation from descriptor fields alone.
  owner: Navivox app owner / Gormes gateway owner
  next check: Pairing handoff setup-intent routing slice.

[RESOLVED] Optional Pairing handoff and reconnect Profile contact routing — 2026-05-25
  resolved: 2026-06-07
  result: Pairing handoff imports retain optional `server_id`/`profile_id` as post-connect route intent and open the Profile contact only when the connected gateway reports the exact contact.
  evidence: `SetupQrImageImport` carries `serverId`/`profileId`; `PairingHandoffFlow.afterConnect()` maps reported contacts to `OpenChatThread` and otherwise falls back to the chats list; manual connection edits reset the imported landing target.
  validation: `test/features/servers/pairing/pairing_handoff_flow_test.dart` covers successful target routing and manual-edit reset.
  owner: Navivox app owner / Gormes gateway owner

[PLANNED] Durable Navivox connection credential storage — 2026-05-25
  problem: accepted Pairing handoff semantics should create/update durable Gormes gateway metadata after successful connection, but Pairing handoff tokens are bootstrap-only and Navivox currently has no secure device credential storage or gateway-issued durable credential protocol.
  evidence: setup/connect code keeps tokens in memory; `shared_preferences` is present for non-secret voice settings only; there is no secure storage dependency, token vault abstraction, device credential issuance endpoint, or reconnect proof flow yet.
  acceptance: keep Pairing handoff tokens short-lived/bootstrap-only; after successful authenticated setup on Android, durable credential issuance happens automatically immediately after authenticated connect plus capability/transport proof and before any chat turn, with clear non-modal post-connect notice/settings status such as `Reconnect saved for this gateway` and `Reconnect: saved on this Android install`, never showing token or credential IDs in normal UI; credential IDs may appear only in advanced diagnostics/export and should be redacted or truncated by default for support correlation without broad cross-context leakage; if issuance fails, Pairing handoff still completes because Navivox connected successfully, chat may continue session-only, and Navivox shows `Connected for this session; reconnect not saved` recovery copy without undoing the active connection; Navivox may perform one bounded automatic retry for transient issuance failure, then stops and leaves manual retry in gateway/settings, with no infinite retry loop; manual retry may use existing active session auth when still connected and scopes/capabilities allow issuance, otherwise it requires a new Pairing handoff; Gormes issues a revocable/rotatable Navivox device credential through a separate mutating endpoint, not `/v1/navivox/status`, bound to authenticated Gateway identity and a Navivox-generated random non-secret app install identity stored with non-secret metadata, not secure storage and not a hardware/user fingerprint; the endpoint accepts Pairing handoff token auth for initial issuance/re-pair and existing durable credential auth only for self-rotation of that install, not minting extra active credentials for other installs; self-rotation re-evaluates current gateway policy and caps new scopes to the previous credential scopes so rotation cannot expand privileges, while Pairing handoff re-pair can issue current default scopes, then invalidates the one-time Pairing handoff token when used or forces it to expire very soon; reinstalling Navivox creates a new install identity and therefore a new credential while old credentials remain server-revocable; static-token/admin auth remains separate legacy/non-Pairing semantics; gold-standard credential is one device public/private key challenge per Gormes gateway, with each private key kept in platform keystore/secure storage under an alias based on authenticated `gateway_id` when available, using a temporary local record ID only before Gateway identity proof, and each public key registered only with that gateway; challenge auth uses Gormes-issued short-TTL single-use nonces rather than signing arbitrary request bodies, with Navivox signing canonical JSON bytes, not ad-hoc concatenated strings, containing stable fields such as gateway ID, install ID, credential ID, nonce, issued/expiry times, intended action, and audience; Gormes/Navivox tests should include fixed signature vectors; Gormes consumes a nonce on successful auth, expires unused nonces quickly, rejects reuse, and may mark repeated reuse as suspicious; REST API calls and WebSocket auth should use short-lived non-persisted access/session tokens minted through the REST challenge flow and scoped to the gateway, credential, scopes, and stream connection where applicable; durable credential issuance and reconnect may use plain HTTP only for loopback/local bridge, while non-loopback exposure requires HTTPS or an authenticated private-network posture such as Tailscale/WireGuard as advertised by capability/status transport security metadata; Navivox refuses durable credential issuance/reconnect by default on insecure non-loopback HTTP instead of warning-only, though session-only Pairing handoff/manual connection may remain available for explicit recovery; Android/Termux same-device transport must use the explicit authenticated Pairing handoff `base_url`/`websocket_url` as connection authority and must not assume app loopback reaches Termux loopback or rewrite to loopback for persistence/security classification unless authenticated gateway capability/status confirms the exposure mode; descriptor URLs may be used only for preflight obvious-insecure checks, while final durable credential eligibility and transport-security classification must come from authenticated status/capabilities because descriptors can be stale or forged; Gormes status/capabilities should expose detailed transport-security fields plus a simple effective enum/gate, e.g. `effective_security` as `loopback`, `private_network`, `tls`, or `insecure`, `exposure_mode`, TLS flag, private-network provider such as Tailscale/WireGuard, and `durable_credentials_allowed`; REST access tokens default to about 5 minutes, while WebSocket stream tokens are single-connection-attempt tokens with no more than about 60 seconds to open the stream; active WebSocket lifetime is controlled by credential revocation/session close after handshake; Navivox repeats the challenge flow when tokens expire; first slice uses short TTL plus underlying credential revoke to invalidate minted tokens, not individual token revocation, avoiding per-request nonce signing and private-key signing inside WebSocket subprotocol/header constraints; key aliases never include base URLs, tokens, usernames, machine names, or paths; first durable persistence slice must include `/v1/navivox/capabilities` advertisement for durable credential support, including separate mutating credential issuance endpoint, supported auth methods such as `pairing_token` plus `device_key_challenge` or interim `device_bearer`, list/revoke endpoints, scope support, and explicit web durable reconnect unsupported/disabled status; credential scope storage in the Gormes credential record defaults the initial Android credential to the current Navivox capability set or a coarse `navivox` scope; include a minimal authenticated Gormes API to issue/list/revoke Navivox device credentials, capability-gated for Navivox clients and scoped so first-slice Navivox can view/revoke its own install while Gormes CLI/admin may list/revoke all installs; polished all-device management UI can follow later; revocation prevents all future auth immediately and should close active WebSocket streams authenticated by the revoked credential in the same slice when bounded, otherwise active stream closure is an explicit follow-up blocker before claiming full revocation semantics; Android durable reconnect is silent by default after app start, relying on platform keystore protection; config-admin actions do not require fresh Pairing handoff or per-action re-auth in the first slice and instead rely on credential scopes plus existing Gormes policy, with biometrics/device-unlock or re-auth for sensitive config/secret edits reserved for a future explicit high-security setting; first implementation should go straight to ECDSA P-256 with SHA-256 keypair challenge through a small Android-native keystore MethodChannel for non-exportable private-key generation/signing if Android secure key APIs are feasible from Flutter/native bridge, with RSA-PSS fallback only if Android compatibility testing forces it; Navivox sends public keys to Gormes as JWK protocol payloads with algorithm metadata such as `kty: EC`, `crv: P-256`, base64url `x`/`y`, `alg: ES256`, and optional Gormes-assigned `kid`; a simple bearer device token is allowed only as a bounded first slice if keypair integration is the schedule risk, explicitly marked interim in capabilities/docs, and stored only in platform secure storage; avoid broad secure-storage dependencies for the first Android keypair slice unless the native bridge proves impractical; future iOS support should use a parallel Keychain/Secure Enclave adapter; Navivox never stores device credentials in `shared_preferences`; persist non-secret Gateway identity/display/base URL/explicit WebSocket URL/last-connected/capability-summary metadata through a small repository abstraction backed initially by `shared_preferences`; durable credential metadata belongs only to gateway auth/admin state and local gateway metadata, never Gormes memory, Profile contact state, Transcript surface, sessions, run records, or agent-visible records; reconnect loads metadata plus secure credential, authenticates `/v1/navivox/status`, proves the same Gateway identity before updating metadata, and falls back to a new Pairing handoff if the credential is missing/expired/revoked even when Gateway identity matches; when the same `gateway_id` is restored without the public-key credential registry, Navivox keeps non-secret metadata and treats it as a known gateway that needs a new Pairing handoff; credential failure never auto-deletes gateway metadata, only explicit `forget gateway` does; if the Gateway identity changed after Gormes config reset, Navivox treats it as a different gateway; Gormes config reset invalidates durable credentials unless the operator explicitly preserves/restores both Gateway identity and credential registry during backup or migration; normal Gormes backup/export may include opaque-public Gateway identity by default for same-gateway restore/migration, while reset/regenerate identity must be explicit; Gormes backup/export must not include the credential registry by default, and should include it only in an explicit `preserve paired Navivox devices` mode; Flutter web gets no durable credential issuance or silent durable reconnect initially and may keep only session credentials plus non-secret metadata unless a future explicit opt-in/risk-copy design is accepted; Navivox `forget gateway` tries remote revocation for only this app install credential by default when reachable, always deletes local credential and non-secret metadata, and reports when remote revoke is pending/unconfirmed without retaining local secrets; normal UI does not offer a separate `forget local only` action because it invites leftover server grants, though emergency/debug wording can explain local deletion if remote revoke is unreachable; all-device revoke is reserved for Gormes CLI/admin or future management UI, and first durable credential slice should include Gormes CLI emergency commands to revoke this install, revoke by credential ID, and revoke all Navivox credentials for the gateway, with confirmation prompts for destructive actions and `--yes` support for scripted exact/broad revokes; Navivox UI `forget gateway` uses its own confirmation sheet; add tests proving secrets are not written to shared preferences, browser local storage, logs, routes, notices, screenshots, or transcript state.
  owner: Navivox app owner / Gormes gateway owner / security owner
  next check: durable connection credential protocol slice.

[RESOLVED] Android release signing config — 2026-05-24
  resolved: 2026-06-07
  result: Android release builds now select a keystore-backed signing config when ignored local properties or CI environment secrets provide all release signing values, while retaining debug signing only as an explicit local smoke-build fallback.
  evidence: `android/app/build.gradle.kts` reads `navivox.release.*` local properties or `NAVIVOX_RELEASE_*` environment variables; `docs/runbooks/android/release-handoff.md` documents local/CI signing setup and warns not to distribute fallback debug-signed release artifacts; `android/.gitignore` excludes `local.properties`, `key.properties`, `*.keystore`, and `*.jks`.
  validation: `./android/gradlew -p android :app:tasks` passed; `flutter build apk --release` passed and produced `build/app/outputs/flutter-apk/app-release.apk`.
  owner: Navivox app owner / release owner

[RESOLVED] Navivox config-admin channel wiring — 2026-05-24
  resolved: 2026-06-07
  result: Navivox now has typed config-admin client methods, channel refresh/apply wiring, capability gating, validation/diff/apply flow handling, and redacted config UI behavior.
  evidence: `NavivoxGatewayClient.configAdminSchema/configAdminValues/diffConfigAdmin/validateConfigAdmin/applyConfigAdmin`; `GatewayNavivoxChannel.refreshConfigAdmin()` and `applyConfigAdmin()`; `sendConfigSet()` / `sendConfigSecretSet()` route through config-admin when advertised.
  validation: `test/core/gateway/config_admin/navivox_gateway_config_admin_test.dart`, `test/core/gateway/navivox_gateway_protocol_test.dart`, `test/core/channel/gateway/runtime/channel_test.dart`, `test/features/config/apply/*`, and `test/features/config/screens/config_screen_test.dart` cover client, channel, validation, reload/pending state, and UI flows.
  owner: Navivox app owner / Gormes gateway owner

[RESOLVED] Navivox voice-profile settings wiring — 2026-05-24
  resolved: 2026-06-07
  result: Navivox now reads and validates Gormes profile-scoped voice profiles, capability-gates the config voice-profile card, surfaces provider/credential state without secrets, and preserves local continuous voice semantics.
  evidence: `NavivoxGatewayClient.voiceProfiles()` and `.validateVoiceProfile()`; `GatewayNavivoxChannel.voiceProfiles()` and `.validateVoiceProfile()`; `ProfileVoiceProfileCard`, coordinator, and presentation modules.
  validation: `test/core/gateway/voice/navivox_gateway_voice_test.dart`, `test/core/gateway/navivox_gateway_protocol_test.dart`, `test/features/profiles/*profile_voice_profile*`, and `test/features/config/screens/profile_voice_profile_test.dart` cover read/validate, invalid provider, missing credential/recovery copy, and UI apply behavior.
  owner: Navivox app owner / Gormes gateway owner

[PLANNED] Navivox approval response protocol — 2026-05-24
  problem: Navivox renders approval-required events, but `GatewayNavivoxChannel` cannot resolve approve/deny choices durably; current approval actions still report that tool approvals are unavailable.
  evidence: updated Gormes Navivox capabilities advertise `approval_required` events, and `../gormes-agent/internal/channels/navivox/channel.go` can broadcast approval requests, but no Navivox approve/deny HTTP or stream message surface is advertised for returning the operator decision.
  acceptance: wait for Gormes to advertise a stable approve/deny action or endpoint, add a typed client/channel adapter only for that advertised surface, preserve risk copy and approval IDs, reject stale approvals safely, and add tests for approve, deny, stale/missing ID, and no-secret logging.
  owner: Navivox app owner / Gormes gateway owner
  next check: next safety/approval protocol slice.

[RESOLVED] Gateway session and run-record UI wiring — 2026-05-24
  resolved: 2026-06-07
  result: Navivox now capability-gates run-record inspection, fetches redacted run-record snapshots through the channel, and exposes transcript/voice diagnostics UI with unavailable fallback behavior.
  evidence: `NavivoxGatewayClient.sessions()` / `.session()` / `.runRecord()`; `GatewayNavivoxChannel.runRecord()`; `runRecordInspectionAvailable` in channel state; transcript message actions call `channel.runRecord()`; `ProfileVoiceProfileCard` can inspect profile voice run evidence.
  validation: `test/core/gateway/navivox_gateway_protocol_test.dart`, `test/core/channel/gateway/runtime/channel_test.dart`, `test/features/chat/actions/chat_run_record_inspection_test.dart`, and `test/features/config/screens/profile_voice_profile_test.dart` cover client reads, capability gating, UI inspection, and unavailable behavior.
  owner: Navivox app owner / Gormes gateway owner

[PLANNED] Composer attachment upload and media picker wiring — 2026-05-24
  problem: the Transcript surface exposes Telegram-style attachment rows, but local file upload, photo/video picking, workspace-file selection, and Gormes gateway handoff are not durable product behavior yet.
  evidence: `lib/features/chat/transcript_composer_presentation.dart` exposes upload/media rows as disabled-copy affordances; current composer tests verify the sheet and row presentation but not upload dispatch. Updated Gormes Navivox capabilities advertise attachments as unavailable until `/v1/navivox/uploads`, with raw local paths rejected.
  acceptance: wait for Gormes to advertise opaque upload IDs and a non-empty MIME allowlist, keep secrets/local file paths out of logs, add tests for operator intent emission, and wire upload/media rows only when the capability document enables `/v1/navivox/uploads`.
  owner: Navivox app owner / Gormes gateway owner
  next check: next attachment/upload slice.

[RESOLVED] Navivox Profile contact create-from-seed UI wiring — 2026-05-24
  resolved: 2026-06-07
  result: Agents/Profile contact creation now opens a capability-gated create-from-seed sheet, uses the channel/client profile-seed endpoint, requires explicit workspace confirmation, refreshes contacts after apply, and keeps local paths/tokens out of normal logs/UI echoes.
  evidence: `NavivoxChannel.profileSeed()`; `GatewayNavivoxChannel.profileSeed()`; `NavivoxGatewayClient.profileSeed()`; `ProfileSeedSheet`; Agents and Profile Contacts screens expose `Create from seed` actions.
  validation: `test/core/gateway/navivox_gateway_protocol_test.dart`, `test/features/profiles/profile_seed_flow_test.dart`, `test/features/profiles/actions/profile_seed_coordinator_test.dart`, `test/features/agents/screens/agents_screen_test.dart`, and `test/features/chat/profile_contacts/profile_contact_list_test.dart` cover client payloads, UI draft/apply, workspace confirmation, and contact selection after apply.
  owner: Navivox app owner / Gormes gateway owner

[RESOLVED] Gormes Navivox API capability contract — 2026-05-24
  resolved: 2026-05-24
  evidence: updated `../gormes-agent/internal/channels/navivox/capabilities.go` and `capabilities_test.go` add authenticated `/v1/navivox/capabilities`, link it from `/v1/navivox/status`, advertise `/healthz`, `/v1/navivox/profile-seed`, attachment unavailability, voice profile support, canonical `/v1/navivox/stream`, and dashboard-profile API deprecation.
  validation: Navivox app now parses `capabilities_url` plus the capability document shape in `test/core/gateway/navivox_gateway_protocol_test.dart`; full app validation remains green.
  owner: Navivox app owner / Gormes gateway owner

[RESOLVED] Web setup accessibility blocks keyboard/screen-reader connect flow — 2026-05-22 18:55 CST
  resolved: 2026-05-22 19:25 CST
  evidence: setup now exposes `Gateway base URL field`, `Pairing token field`, `Import pairing QR image`, `Show pairing token`, and `Connect and talk` in the Flutter web accessibility tree after semantics activation; `agent-browser find text "Connect and talk" click`, `find text "Import pairing QR image" click`, and `find text "Show pairing token" click` all exited 0; pressing Enter in the token field fired `/v1/navivox/status`.
  validation: `flutter analyze`, `flutter test`, `flutter build web`, and browser QA against `http://127.0.0.1:8765/#/setup` passed for this slice.
  owner: Navivox app owner / Mineru

[BLOCKED] Android Pairing handoff and continuous voice live smoke — 2026-05-27
  blocker: this host has no responsive Android target; previous emulator attempts timed out on `adb shell`, so it cannot prove Android OS intent delivery, microphone permission prompts, speech-recognition availability, or a real live phrase capture.
  evidence: Pairing handoff has Dart/JVM/provider-smoke coverage and optional/manual docs in `docs/runbooks/android/pairing-handoff-smoke.md` and `docs/runbooks/android/pairing-handoff-instrumentation.md`; continuous voice docs in `docs/runbooks/android/release-handoff.md` still say this host is not valid Android evidence until a responsive target is connected.
  acceptance: on a responsive physical USB-debuggable Android device or healthy emulator, run Pairing handoff before voice. Tier 1 import-only: `ACTION_SEND text/plain` with a sentinel Pairing handoff token fills setup fields, waits for operator action, and does not render the token; QR/image import follows the same no-probe/no-token-leak rule. Direct `ACTION_VIEW navivox://connect?...` is tested only with active-gateway confirmation or another no-probe guard unless a live gateway is intentionally available. Tier 2 live Gormes: direct cold-start and warm-start `ACTION_VIEW` connect successfully, active-gateway handoff asks confirmation before probing/switching, requested Profile contact landing happens only when reported by the gateway, and tokens/credentials do not appear in UI, screenshots, logs, transcripts, or failure copy. Continuous voice: after live Pairing handoff, `adb shell true` returns quickly, at least one Android `RecognitionService` exists, an online Profile contact opens, mic permission is granted if prompted, one short spoken phrase becomes a local transcript bubble and a sent Gormes turn, with no token/credential leakage.
  owner: local Android test environment / Juan.
  workaround/pivot: keep code-level `flutter analyze`, `flutter test --concurrency=1`, JVM Pairing handoff parser tests, and optional provider smoke green until a responsive Android target is available.
  next check: rerun with responsive Android target before claiming Android runtime validation.

[RESOLVED] Commit/push screenshot iteration 1 repeated agent-list message slice — 2026-05-22 16:23 CST
  resolved: 2026-05-22 16:45 CST
  evidence: `flutter analyze`, `flutter test`, and `git diff --check` all passed after fixing stale E2E/control finders, the profile-contact back-button expectation, and the README setup screenshot golden.
  owner: Navivox app owner / Mineru

[BLOCKED] Commit/push Transcript surface plan and context updates — 2026-05-20 20:56 CST
  blocker: `navivox-app` is untracked inside parent repo `/home/xel/git/sages-openclaw`, so committing only plan/context files would add a partial project tree.
  evidence: `git rev-parse --show-toplevel` => `/home/xel/git/sages-openclaw`; `git status --short -- /home/xel/git/sages-openclaw/workspace-mineru/navivox-app` => `?? workspace-mineru/navivox-app/`.
  unblocks when: Juan or owning agent decides whether `navivox-app` should be tracked whole, moved to its own repo, added as a submodule, or ignored.
  owner: Juan / repository owner
  workaround/pivot: saved the implementation plan and context wording without staging a partial commit; wait for ownership decision before commit/push.
  next check: 2026-05-21 10:00 CST

[BLOCKED] Run Subagent-Driven Development execution — 2026-05-20 21:02 CST
  blocker: current pi harness has no Agent/subagent dispatch tool, so fresh implementer/spec-review/code-review subagents cannot be launched.
  evidence: available tool surface in this session is file/command tools (`read`, `bash`, `edit`, `write`, `multi_tool_use.parallel`); no Agent/TodoWrite dispatch tool is exposed.
  unblocks when: this work runs in a subagent-capable harness, or Juan approves switching to inline execution.
  owner: harness / Juan
  workaround/pivot: prepared Task 1 subagent dispatch packet at `docs/superpowers/plans/2026-05-20-transcript-surface-task1-subagent-packet.md`.
  next check: 2026-05-21 10:00 CST

[BLOCKED] Commit/push Voice run lifecycle spec — 2026-05-21 08:34 CST
  blocker: `navivox-app` is untracked inside parent repo `/home/xel/git/sages-openclaw`, so committing the Voice run spec would require adding a partial project tree.
  evidence: `git status --short -- workspace-mineru/navivox-app` => `?? workspace-mineru/navivox-app/`.
  unblocks when: Juan or owning agent decides whether `navivox-app` should be tracked whole, moved to its own repo, added as a submodule, or ignored.
  owner: Juan / repository owner
  workaround/pivot: saved design spec at `docs/superpowers/specs/2026-05-20-voice-run-lifecycle-design.md` without staging a partial commit.
  next check: 2026-05-21 10:00 CST

[BLOCKED] Commit/push Voice run lifecycle implementation plan — 2026-05-21 08:39 CST
  blocker: `navivox-app` is untracked inside parent repo `/home/xel/git/sages-openclaw`, so committing the implementation plan would require adding a partial project tree.
  evidence: `git status --short -- workspace-mineru/navivox-app` => `?? workspace-mineru/navivox-app/`.
  unblocks when: Juan or owning agent decides whether `navivox-app` should be tracked whole, moved to its own repo, added as a submodule, or ignored.
  owner: Juan / repository owner
  workaround/pivot: saved implementation plan at `docs/superpowers/plans/2026-05-21-voice-run-lifecycle.md` without staging a partial commit.
  next check: 2026-05-21 10:00 CST

[BLOCKED] Commit/push Voice run lifecycle implementation — 2026-05-21 08:53 CST
  blocker: `navivox-app` is untracked inside parent repo `/home/xel/git/sages-openclaw`, so committing the validated implementation would require adding a partial project tree.
  evidence: `git status --short -- workspace-mineru/navivox-app` => `?? workspace-mineru/navivox-app/`; full `flutter test` passed locally after the implementation.
  unblocks when: Juan or owning agent decides whether `navivox-app` should be tracked whole, moved to its own repo, added as a submodule, or ignored.
  owner: Juan / repository owner
  workaround/pivot: completed and validated the client-local Voice run lifecycle implementation without staging a partial commit.
  next check: 2026-05-21 10:00 CST

[BLOCKED] Commit/push navivox-loop iteration 1 voice failure-reason slice — 2026-05-21 09:01 CST
  blocker: `navivox-app` is untracked inside parent repo `/home/xel/git/sages-openclaw`, so committing the validated iteration slice would require adding a partial project tree.
  evidence: `git status --short -- workspace-mineru/navivox-app` => `?? workspace-mineru/navivox-app/`; `flutter analyze`, `flutter test`, and `git diff --check -- workspace-mineru/navivox-app` all exited 0 in this iteration.
  unblocks when: Juan or owning agent decides whether `navivox-app` should be tracked whole, moved to its own repo, added as a submodule, or ignored.
  owner: Juan / repository owner
  workaround/pivot: completed the timeout failure-reason slice and left it unstaged.
  next check: 2026-05-21 10:00 CST

[BLOCKED] Navivox full gate for Pi delivery-loop extension — 2026-05-21 08:52 CST
  blocker: full repo gate is red from pre-existing Navivox app test/model drift and unrelated root whitespace outside the extension slice.
  evidence: `flutter analyze` reports undefined getter `voiceCapability` in `app/test/core/channel/gateway_navivox_channel_test.dart:149-152`; `flutter test` reports `loads profile contacts from snapshot and applies gateway updates` expected `available`, actual `unavailable`; unscoped `git diff --check` reports trailing whitespace in `.sisyphus/plans/gormes-port-master-plan.md:3` and `:5`.
  unblocks when: Navivox voice capability expectations are reconciled with `NavivoxProfileContact`, and unrelated root whitespace is fixed or excluded by an agreed gate scope.
  owner: Navivox app owner / root workspace owner
  workaround/pivot: completed the extension slice with focused contract test and scoped `git diff --check -- workspace-mineru/navivox-app`; did not modify unrelated app/root WIP.
  next check: 2026-05-21 10:00 CST
