# Hermes Wing Next Do/Test Roadmap

> **For Hermes:** Use subagent-driven-development and test-driven-development when executing this roadmap. Do not implement the deferred Nostr Relay Link.

**Goal:** Turn the current broad, partially qualified Hermes Wing worktree into an honestly documented, physically verified Android alpha with a safe Hermes/Wing Link authority boundary, then expand installation, configuration, channels, voice, and platform support in that order.

**Architecture:** Hermes Agent remains authoritative for profiles, sessions, messages, providers, tools, schedules, approvals, and messaging semantics. Wing uses the authenticated Hermes API over HTTPS. Wing Link remains a bounded host-local installer, pairing, credential, service-lifecycle, health, and diagnostics supervisor. Channel UX stays transport-neutral. Nostr is not the core control transport.

**Primary target:** Samsung SM-S928B, ADB serial `RFCX81EJPNN`, Android API 36, package `com.trebuchetdynamics.hermes.wing`.

---

## Priority 0: Align decisions and close the current physical QA cycle

### 1. Correct architecture and roadmap documentation

**Do**

- Revise `ROADMAP.md` so Wing Link no longer owns a profile-topology or provider/config domain bridge.
- Revise `docs/research/buzz-nostr-lessons.md` to state clearly that Nostr is not Wing's primary gateway control transport.
- Keep `.hermes/plans/2026-08-10_210519-nostr-gateway-channel-roadmap.md` preserved and marked exploratory/deferred.
- Preserve Buzz lessons about channel navigation, agent identity, threads, reactions, reconnect state, mention policy, and diagnostics.
- Keep Nostr only as an optional future Hermes messaging integration or bounded receipt experiment.

**Test**

- Search for claims that Wing Link owns Hermes profiles/providers/messages or that Nostr replaces HTTPS/VPN reachability.
- Verify all authority statements agree with `docs/adr/0012-hermes-agent-domain-authority.md`.
- Run `git diff --check`.

### 2. Repair and complete the diagnostics detail probe

**Do**

- Reproduce `/tmp/hermes-wing-physical-qa/diagnostics_detail_probe.yaml` on `RFCX81EJPNN`.
- Inspect the failure screenshot and UI hierarchy for the obsolete `^Connection$` selector.
- If it is only a selector drift, repair the probe without changing production UI.
- If it exposes a product defect, write the smallest failing widget/integration regression before the minimal fix.
- Exercise Diagnostics top, details, copy/share boundaries, scrolling, Back, and error states.

**Test**

- Focused widget/controller test for any confirmed defect.
- Maestro probe passes on the pinned phone.
- No secret, endpoint credential, transcript body, tool payload, or local path appears in screenshots, hierarchy, copied diagnostics, or receipts.
- Post-flow logcat has no fatal Android, Flutter, or RenderFlex failures.

### 3. Rebuild, reinstall, and record exact current-artifact receipts

**Do**

- Build a fresh APK from the current worktree.
- Install only with explicit device selection.
- Pull the installed APK back and compare it to the newly built artifact.
- Record source state, APK size/hash, device properties, install result, package path, and bounded test outcomes.

**Test**

```bash
WING_ANDROID_DEVICE_ID=RFCX81EJPNN npm run android:live-mic-prep
adb -s RFCX81EJPNN shell dumpsys package com.trebuchetdynamics.hermes.wing
```

- Local and installed APK SHA-256 values must match.
- Microphone permission state and resumed activity must match expectations.
- Never reuse the obsolete `47d7e5...` receipt.

### 4. Run the remaining Android state matrix

**Do/Test**

- Existing/empty/unsupported/error/loading states for Chat, Profiles, Providers, Tools, Schedules, Gateway, Office, and Settings.
- Offline and auth-expired reconnect behavior.
- Multiple saved gateways and profile switching.
- Active-run gateway-switch guard.
- Android Back from every More destination.
- Light/dark/system theme.
- Portrait, landscape, and 200% font scale.
- TalkBack traversal for connect, session selection, approval, profile selection, provider secret entry, diagnostics, and voice settings.

For every confirmed defect: reproduce → failing regression → minimal fix → focused test → broad test → rebuild/reinstall → physical rerun.

---

## Priority 1: Make onboarding and distribution usable

### 5. Qualify Wing Link's complete first-run path

**Do**

- Make Wing Link setup cover install or adoption, verified Hermes bootstrap, initial profile creation, provider/model configuration, scoped API enrollment, gateway service startup, pairing, status, repair, and bounded diagnostics.
- Keep secrets write-only and out of argv, logs, QR payloads, operation events, screenshots, and receipts.
- Keep Hermes Agent authoritative; Wing Link must call typed Hermes-owned contracts/CLI setup surfaces only where explicitly designed, never parse free-form output into domain state.
- Complete Linux first. Treat Windows/macOS service adapters and Android/Termux as separate qualification tracks.

**Test**

- Clean Linux host install.
- Existing Hermes adoption without replacing home/config/profiles/credentials.
- Idempotent rerun.
- Provider/profile optional setup.
- Pairing expiry, replay, cancellation, wrong origin, wrong code, and acknowledgment.
- Service process restart and machine/user-session restart recovery.
- Tampered installer/hash failure.
- Network interruption and repair.
- No secret leakage in captured stdout/stderr or receipts.

### 6. Finish scoped credential lifecycle

**Do**

- Per-device labels.
- Exact scopes advertised and enforced by Hermes.
- Rotation and revocation.
- Revoked-device reconnect failure.
- Separate Hermes and Wing Link credentials.
- No universal Wing Link "boss key."

**Test**

- Enroll → use → rotate → old token rejected → new token accepted.
- Revoke → next operation returns 401/403 and Wing clears or quarantines stale access safely.
- Cross-profile, cross-gateway, and wrong-origin attempts fail closed.
- Concurrent refresh/mutation cannot resurrect revoked credentials.

### 7. Ship Android signed artifacts first

**Do**

- Produce signed AAB and sideload APK with checksums.
- Validate the existing release workflow against the current worktree.
- Publish an alpha prerelease only after install/upgrade receipts pass.
- Add Linux/web artifacts next; Windows/macOS/iOS remain build-tested until host-specific runtime receipts exist.

**Test**

- Clean install, upgrade with retained app state, failed/tampered upgrade, rollback policy, uninstall/reinstall behavior.
- Exact signing identity and checksum verification.
- Play Store internal-track install for AAB.
- No debug keys or private signing material in repository/artifacts/logs.

---

## Priority 2: Complete the highest-value Hermes product surfaces

### 8. Finish Agent-authoritative configuration

**Order**

1. Profiles/persona CRUD and physical receipt.
2. Providers/models configured-first UI and write-only credential receipt.
3. Skills/Discover/Tools/MCP when mutation contracts exist.
4. Memory browser and provider controls.
5. Schedule create/pause/resume/run/delete; do not claim edit without a contract.
6. Gateway lifecycle, logs, messaging-platform configuration, drain/reload/restart.
7. Resource-handle attachments/files/context folders.

**Test gate for every administrative slice**

- Exact capability and scope gating before network I/O.
- `If-Match` stale-write rejection.
- Secret non-reveal.
- Apply/reload/restart disposition.
- Active-work preservation and drain behavior.
- SSE event ID, deduplication, reconnect, and authoritative GET reconciliation where live state exists.
- Offline mutation is never queued or replayed automatically.
- Widget semantics, keyboard focus, contrast, and 200% text scale.
- Compatible real-gateway receipt on the pinned phone.

### 9. Build transport-neutral channels, DMs, and threads

**Do**

- Make channels/DMs the primary conversation navigation without replacing profiles.
- Show profiles as explicit agent participants and authority/persona contexts.
- Add threads, unread/activity projections, reactions, requester identity, approval ownership, and reconnect indicators only through Hermes-owned typed contracts.
- Default shared channels to mention-required and allowlisted policies where Hermes reports them.
- Keep the core Wing-to-gateway control path on HTTPS.

**Test**

- Channel/thread/profile/requester session scoping.
- Duplicate suppression and high-water reconnect behavior.
- Self-authored event suppression.
- Historical events never replay as new prompts.
- Approval actions remain bound to the requester, profile, session, run, and gateway.
- Transport failure cannot fabricate delivery or execution success.
- Phone and desktop adaptive navigation, Back behavior, unread semantics, and accessibility.

### 10. Improve chat clarity and failure recovery

**Do**

- Authoritative-final stream reconciliation with strict turn/event boundaries.
- Compact gateway/profile/model/tools status sheet.
- Recoverable stale setup/connection warning and repair action.
- Approval reason-flow polish and bounded diagnostics sharing.
- Rich transcript completion: selectable GFM, code copy, safe links.

**Test**

- Dropped/missing stream deltas reconciled without deleting distinct tool/reasoning segments.
- Unicode and stale-generation finals.
- SSE drop, timeout, auth expiry, process death, background/foreground, queue, retry, stop, and approval races.
- Real provider-backed current-artifact chat on the pinned phone.

---

## Priority 3: Qualify continuous voice honestly

### 11. Keep deterministic voice gates green

**Test**

- Continuous re-arm and generation ownership.
- Prompt barge-in/cancellation paths.
- Offline Whisper/Silero worker startup, cancellation, and exit.
- Pocket Speech/Kokoro model install and rollback.
- Native PCM playback ownership and release.
- English, Spanish, and mixed-language deterministic fixtures reported separately.

### 12. Run human physical acoustic qualification

**Do/Test on `RFCX81EJPNN`**

- Real spoken two-turn conversation.
- Provider-backed reply.
- Audible TTS.
- Continuous re-arm.
- Prompt and response barge-in.
- Speaker, wired headset, and Bluetooth routes.
- Acoustic echo leakage/correlation and false-interruption rates.
- First partial, final transcript, TTS first-audio, and cancellation latency.
- Long-run memory, battery, and thermal behavior.
- English/Spanish WER/CER and genuine mixed-language token error rate.

Do not claim microphone capture, audible quality, acoustic echo cancellation, or barge-in from deterministic fixtures or permission checks alone. Do not retain raw microphone PCM in ordinary receipts.

---

## Priority 4: Broader platform support and polish

### 13. Linux reference desktop

- Signed DEB/APT distribution.
- Install/update/uninstall/rollback.
- Wing Link lifecycle and repair.
- Tray, updater, native menus/windows.
- Explicit SSH trust and filesystem grants only if retained as desktop host features.
- Keyboard-only and screen-reader qualification.

### 14. Windows and macOS

- Port stable host adapter contracts.
- Signed MSIX and notarized DMG.
- Clean install, upgrade, rollback, lifecycle, and interaction receipts on real hosts.

### 15. iOS and web

- Remote-safe feature parity.
- Explicit platform exclusions for unsupported local runtime or voice features.
- Browser storage/security review before credential-bearing production use.

### 16. Product polish

- Context-aware first-launch walkthrough.
- Loading/skeleton/error transitions and reduced-motion behavior.
- Full accessibility audit.
- Reviewed localization baseline, including RTL receipts.
- Five polished theme palettes rather than a large low-quality theme catalog.

---

## Deferred / excluded

- Do not implement the custom Nostr Relay Link as Wing's primary control transport.
- Do not treat Buzz/NIP-29 channel membership as confidentiality.
- Do not proxy arbitrary Hermes HTTP, shell, configuration, chat, session, or run traffic through Wing Link.
- Do not parse Hermes config files, databases, logs, or cryptographic stores in Wing.
- Do not add client-side shadow profiles, providers, schedules, memory, or messaging semantics.
- Do not claim battle-tested behavior from unit tests, deterministic fixtures, builds, or one physical receipt.

## Broad verification gate before an alpha release

```bash
/home/xel/flutter/bin/dart format --output=none --set-exit-if-changed lib test integration_test
/home/xel/flutter/bin/flutter analyze --no-pub
/home/xel/flutter/bin/flutter test --concurrency=1
cd wing_link && go test ./... && go vet ./...
```

Then return to the repository root and run the applicable web, Android, Linux, release, Maestro, accessibility, security-redaction, and exact-artifact installation receipts. Every receipt must identify the current source and artifact and state explicitly what it does **not** prove.
