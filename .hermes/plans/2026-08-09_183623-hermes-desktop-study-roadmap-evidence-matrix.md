# Hermes Desktop Study, Wing Roadmap, and Evidence Matrix

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Adapt the highest-value user outcomes from Hermes Desktop v0.7.4 into Hermes Wing without copying Electron/CLI/filesystem ownership, while maintaining an explicit evidence matrix that prevents deterministic tests from being mislabeled as battle-tested behavior.

**Architecture:** Hermes Agent remains the authority for profiles, providers, models, skills, memory, schedules, Kanban, gateway state, and run/session data. Wing uses advertised, scoped HTTP/SSE contracts and keeps client-local presentation preferences only. Wing Link remains a separately authenticated local runtime supervisor; it must not become a second Hermes domain backend. Android retains local microphone/VAD/STT/TTS/playback ownership.

**Tech Stack:** Flutter/Dart, Riverpod, Go Wing Link, Android Kotlin, Hermes Agent HTTP/SSE contracts, Flutter tests, Maestro, Waydroid, physical Android, host-specific CI.

---

## 1. Study baseline

### Repositories

- Hermes Desktop (read-only): `/home/xel/git/gormes/hermes-desktop`
- Desktop HEAD studied: `f5d78cc` on `main`, package version `0.7.4`
- Hermes Wing: `/home/xel/git/gormes/hermes-wing`
- Earlier Wing feature-study snapshot: Desktop `8da8d212`, version `0.7.3`
- Frozen parity baseline remains `d31e52e85449b6effcfd4d037b7517541c8fadf2`; this study records deltas and does not silently move the retirement baseline.

### Current Desktop topology

The reachable renderer confirms this primary information architecture:

- Pinned: Discover, Office, Kanban, Schedules.
- Footer/admin: Providers, Gateway, Tools, Memory.
- Agents: profile switcher → Manage profiles.
- Sessions: recent sidebar plus full modal.
- Skills: embedded under Discover/Tools.
- Models: under Providers and the chat picker.
- Global Settings modal.

Primary source: `/home/xel/git/gormes/hermes-desktop/src/renderer/src/screens/Layout/Layout.tsx`.

### Important v0.7.4 deltas since the existing Wing study

1. **Office activity is tied to real running Kanban work.** Office shares one in-flight status request, rejects stale profile results, avoids overlapping polls, and derives working/idle state from running cards. Sources: `Office.tsx`, `Office.statusPolling.test.tsx`, `office3d/agents.ts`, `office3d/agents.test.ts`. The Kanban screen itself changed only cosmetically in this delta; the activity projection is the substantive new behavior.
2. **Office gained intent-to-world actions.** Chat/representative intentions are planned into missions and world actions, with routing and mission-bus tests. Sources: `office3d/interactions/worldActions.ts`, `missionBus.ts`, `core/routing.ts` and their tests.
3. **SSH mode can inspect and adapt Docker-hosted Hermes installations.** This includes target inspection, container selection, launcher setup, ownership preservation, empty-home handling, and health fallback across PID namespaces. Sources: `src/main/ssh-docker.ts`, `src/shared/ssh-docker.ts`, `SshDockerTargetSection.tsx`. This is host-only and must not become Android remote-install behavior.
4. **Provider configuration is less overwhelming.** Desktop shows configured providers first, uses Add Provider, manages models inside each provider, supports custom providers, live discovery, and context-window metadata. Sources: `ProviderKeysSection.tsx`, `Providers.tsx`, `agent-config-providers.ts` and tests.
5. **Tools/MCP has a stronger unified information architecture.** Tools, MCP, and Skills are tabs; MCP supports HTTP/stdio forms, server JSON, catalog handoff, state, testing, and logos. Source: `Tools.tsx`. Wing may copy the hierarchy only after scoped Agent contracts exist.
6. **Chat completion reconciliation handles dropped stream chunks.** `lossyText.ts` detects a damaged streamed copy of canonical final text using contiguous-run and coverage constraints rather than a loose subsequence rule. Source/test: `Chat/lossyText.ts`, `Chat/lossyText.test.ts`.
7. **Reasoning effort is now an accessible Faster↔Smarter slider.** It covers auto/minimal/low/medium/high/xhigh, keyboard arrows, Home/End, drag updates, and repeated changes without closing. Source: `Chat/ReasoningEffortPicker.tsx`.
8. **Chat presentation is clearer.** Agent avatars replace the active orb when a turn settles, timestamps accept seconds/ms/us/ns/ISO inputs, and bubble-level copy is explicit. Source: `Chat/MessageRow.tsx`.
9. **A compact live status bar exposes connection mode, gateway state, active model, skill count, and command/settings hints.** Source: `Layout/StatusBar.tsx`. Wing should adapt this into a mobile connection/status sheet or compact header, not copy a desktop footer literally.
10. **First-run entry screens and verification were redesigned.** Startup distinguishes local/remote/SSH, uses generation-style run ownership to prevent stale connection checks from winning, warms health in parallel, and turns deep local verification failure into a dismissible repair warning rather than a reinstall loop. Source: `App.tsx`; install/welcome changes under `screens/Install` and `screens/Welcome`.
11. **Hermes One can provision a one-time inference key and show credits.** Source/tests: `src/main/hermesone-provision.ts`, `.test.ts`. This is an optional account-service outcome. Wing must use a write-only scoped secret sink and must never expose or persist an account bearer or provider key in ordinary state/logs.

## 2. Adapt, defer, or exclude

| Desktop outcome                                                  | Wing decision                      | Why / required contract                                                                                                           |
| ---------------------------------------------------------------- | ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| Streamed text reconciled with authoritative final                | **Adapt early**                    | Prevents visibly corrupted/duplicated answers; preserve tool/reasoning boundaries and exact session ownership.                    |
| Agent avatar, normalized timestamp, bubble copy                  | **Adapt early**                    | High-value mobile chat clarity; mostly presentation-local.                                                                        |
| Compact live status summary                                      | **Adapt early**                    | Existing Wing gateway/model/tool inventory can feed a gateway-scoped, bounded sheet. No secret/path fields.                       |
| Configured-providers-first + per-provider models                 | **Adapt after contract**           | Requires scoped provider presence, write-only credentials, model discovery/library, revision-safe assignment. Never parse `.env`. |
| Unified Discover/Tools/MCP/Skills hierarchy                      | **Adapt after contract**           | Existing Wing read-only inventory is a base; mutations need explicit profile-scoped contracts.                                    |
| Kanban boards, lanes, task details, valid transitions            | **Adapt after task contracts**     | Requires authoritative boards/tasks/events/revisions/SSE and opaque workspace handles. Never call CLI or expose remote paths.     |
| Office working state from running task                           | **Adapt after task contracts**     | Useful in Wing’s accessible 2D Office; derive from authoritative task/run events, not polling local CLI state.                    |
| Office mission/world animation                                   | **Defer/presentation**             | Android first needs accessible action cards and 2D status. Optional desktop animation cannot replace semantic controls.           |
| One Chat per agent                                               | **Adapt selectively**              | Map to existing profile/session ownership; avoid Desktop-specific `office-{profile}` assumptions unless server returns handles.   |
| Local/remote/SSH startup race prevention and soft repair warning | **Adapt pattern**                  | Exact-generation stale-result rejection and recoverable warnings apply to enrollment/Wing Link.                                   |
| SSH Docker inspection/provisioning                               | **Desktop host-only**              | Explicitly trusted host adapter only. Do not add remote Agent installs to Android.                                                |
| Desktop direct CLI, `.env`, YAML, SQLite, PID, SSH-file access   | **Never copy**                     | Violates Hermes Agent domain authority and remote-safe architecture.                                                              |
| Desktop Dashboard WebSocket transport                            | **Never copy**                     | Wing uses canonical Hermes HTTP/SSE contracts.                                                                                    |
| Hermes One inference key provisioning                            | **Account-service/contract gated** | Needs device authorization, one-time secret handoff, write-only provider sink, revocation, and no raw-key return path.            |
| 3D Office/GPU recovery                                           | **Desktop-only later**             | Keep complete keyboard/screen-reader 2D equivalent; Android does not need Three.js parity.                                        |

## 3. Evidence vocabulary

Use these labels consistently in code reviews, roadmap updates, releases, and user-facing reports:

- **Battle-tested:** repeated real-world/production use across representative devices and failure modes, with durable incident/telemetry evidence. A passing test suite alone never qualifies.
- **Qualified:** deterministic tests plus a current executable integration/device receipt on the intended platform.
- **Deterministically tested:** unit/widget/source-contract tests pass, but no current intended-platform behavioral receipt.
- **Build/package tested:** compiles/packages/installs/launches, but the feature behavior itself was not exercised.
- **Prototype/partial:** code path exists but contracts, lifecycle guarantees, product flow, or acceptance evidence are incomplete.
- **Unverified:** no adequate evidence for the claim.
- **Planned only:** no production implementation.

Receipts must match the current source/artifact identity. A receipt from an older commit may remain historical evidence but cannot qualify changed current code.

## 4. Current Hermes Wing evidence matrix

**Important conclusion:** no Wing domain should currently be labeled broadly “battle-tested.” Several paths are strongly deterministic or device-qualified, but there is not yet repeated production evidence across representative Android/desktop environments.

| Capability                                       | Implementation state                                                                 | Best current evidence                                                                                | Classification                                              | Missing evidence                                                                                                                                                                                 |
| ------------------------------------------------ | ------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Release APK                                      | Universal release APK builds, installs, cold launches                                | Current release build; ZIP integrity; Waydroid and Samsung install/launch before/after voice changes | **Build/package tested**                                    | Signed release channel, upgrade/rollback, split/AAB delivery, representative-device matrix                                                                                                       |
| Core Hermes API/channel                          | Typed HTTP/SSE, sessions, runs, stop, approvals, reconnect                           | `hermes_api_channel_test.dart`, `hermes_api_test.dart`, Playwright live/fake API runbooks            | **Qualified for deterministic web/API paths**               | Broader live gateways, flaky-network soak, production usage                                                                                                                                      |
| Real gateway chat continuity                     | Real provider turn, second turn, stop/recovery, restore flow exists in Maestro       | `.maestro/real-gateway-regression.yaml`; historical physical receipts in parity ledger               | **Qualified where receipt matches source**                  | Re-run against current uncommitted source/artifact; multi-provider matrix                                                                                                                        |
| Multi-run/detached run ownership                 | Concurrent streams, secure opaque handles, duplicate prevention/reconciliation       | Controller/store/widget tests; parity ledger device receipts                                         | **Qualified but source-sensitive**                          | Current-head process-death/background soak on multiple Android versions                                                                                                                          |
| Rich transcript, tool/reasoning/usage, approvals | Implemented with bounded parsing/redaction                                           | rich transcript, approval, message-action, diagnostics tests                                         | **Deterministically tested; selected flows qualified**      | Canonical-final reconciliation equivalent to Desktop’s lossy stream handling; more real tool/clarify scenarios                                                                                   |
| Sessions/search/export                           | History, grouping, metadata, export, selected mutations                              | session/client tests and parity-ledger physical receipts                                             | **Qualified for covered scenarios**                         | Branch/pin/resource projects and current-head full device rerun                                                                                                                                  |
| Profiles/Agents                                  | UI and capability-gated administration paths exist                                   | agents/profile tests; earlier physical flows                                                         | **Prototype/partial**                                       | Compatible merged Agent contracts and current physical mutation receipt                                                                                                                          |
| Providers/models                                 | Read-only runtime inventory, credential sheet/model presets/diagnostics              | provider/model widget/store tests; selected historical physical inventory receipt                    | **Deterministically tested / partial**                      | Authoritative write-only administration contract, secret non-reveal E2E, current device receipt                                                                                                  |
| Tools/skills                                     | Read-only searchable bounded inventories                                             | `tools_screen_test.dart`; historical device inventory receipt                                        | **Qualified read-only; mutations absent**                   | Discover, install/remove, toolset mutation, MCP contracts and receipts                                                                                                                           |
| Schedules                                        | Read-only gateway/profile jobs inventory                                             | `schedules_screen_test.dart`; fail-closed device evidence                                            | **Deterministically tested / partial**                      | Live compatible inventory; create/pause/run/delete/edit contracts                                                                                                                                |
| Gateway                                          | Read-only bounded detailed health                                                    | `gateway_screen_test.dart`; unsupported-state physical receipt                                       | **Qualified fail-closed/read-only**                         | Lifecycle, logs, platform configuration, drain/reload/restart mutation contracts                                                                                                                 |
| Office                                           | Accessible responsive 2D directory and Chat activation                               | `office_screen_test.dart`, route tests, historical physical navigation receipt                       | **Qualified basic 2D flow / partial**                       | Task-derived activity, representative actions, One Chat semantics, accounts/wallets                                                                                                              |
| Wing Link bootstrap                              | Verified install/adoption logic, Go tests/vet, secret-safe output                    | `wing_link/bootstrap_test.go`, Wing Link client/docs tests                                           | **Deterministically tested / partial**                      | Signed artifact and complete physical Termux clean/adopt/repair/rollback receipts                                                                                                                |
| Continuous voice lifecycle                       | Persistent re-arm, exact generation ownership, barge-in/cancel paths                 | 1,040-test suite checkpoint, Waydroid Maestro lifecycle, lifecycle tests                             | **Qualified deterministic lifecycle**                       | Real spoken physical two-turn loop, acoustic barge-in, long-run soak                                                                                                                             |
| Android microphone capture                       | Native `AudioRecord`, VOICE_COMMUNICATION, PCM16 frames, native effects              | Kotlin/source contracts, deterministic engine tests                                                  | **Build/device-runtime tested**                             | Controlled real microphone routing and recorded physical receipt                                                                                                                                 |
| Offline Whisper + Silero                         | Worker-isolate Whisper and Silero VAD, cancellation/exit ownership                   | unit/source-contract tests; fixture decode/init on Waydroid and physical Samsung                     | **Qualified deterministic runtime**                         | English/Spanish WER/CER, code-switch corpus, live mic, latency/RSS/thermal                                                                                                                       |
| Offline Kokoro/Pocket Speech                     | Bilingual synthesis, post-synthesis WAV chunking, native PCM, fallback               | unit tests; Waydroid bilingual synthesis/native playback smoke                                       | **Prototype/partial; qualified deterministic runtime seam** | The engine receives a complete WAV before chunking, so synthesis itself is not incremental; physical listening quality, first-audio latency, segment seams, sustained memory/thermal remain open |
| Offline model installer                          | Immutable manifests, exact bytes/hash, staging, rollback/recovery, deletion barriers | `voice_model_pack_installer_test.dart`, Pocket Speech installer tests                                | **Deterministically tested**                                | Real interrupted network/storage/device recovery and low-space behavior                                                                                                                          |
| Native PCM playback                              | Generation-owned writes/release serialized on one executor                           | Dart/Kotlin contracts; Waydroid and physical deterministic playback smoke                            | **Qualified deterministic runtime**                         | Route changes, Bluetooth/headset matrix, physical cancellation latency                                                                                                                           |
| Echo cancellation                                | Platform AEC capability path; gated acoustic probe harness                           | `android_acoustic_echo_probe_test.dart` compiles disabled                                            | **Prototype/unverified acoustically**                       | Explicit probe run, exact render-reference evidence, leakage thresholds, route matrix                                                                                                            |
| Bilingual/code-switch speech quality             | Multilingual Auto/English/Spanish modes                                              | language-flow/segmenter tests                                                                        | **Deterministically tested configuration only**             | Genuine intra-utterance EN↔ES corpus and token error rate; never claim code-switch quality yet                                                                                                   |
| Accessibility                                    | Many widget tests include 200% scale and semantics                                   | screen-specific tests and parity ledger                                                              | **Deterministically tested / partial**                      | TalkBack, keyboard-only, screen-reader and contrast receipts on current builds                                                                                                                   |
| Linux/web/Windows/macOS/iOS                      | Platform sources and historical CI/build receipts exist                              | platform smoke runbook and workflows                                                                 | **Build-tested unevenly**                                   | Current-source signed packages, host-specific end-to-end behavior and upgrade receipts                                                                                                           |

## 5. Prioritized roadmap

### P0 — Keep evidence honest and make releases inspectable

1. Reassert ADR 0012: remove/quarantine Wing Link profile/provider/config domain fallbacks. Wing Link owns install/adopt/update/rollback, process lifecycle, pairing, transport setup, and host integration—not Hermes domain state.
2. Add contract tests proving profile/provider UI performs no Wing Link domain mutation when the Agent lacks the exact scoped contract.
3. Add one checked-in evidence ledger generated from explicit receipts, with source/artifact hash and expiry/staleness rules.
4. Re-run full tests/analyzer/release build after each architecture slice.
5. Complete APK size attribution and produce universal vs arm64 split vs AAB comparisons; do not remove offline inference libraries blindly.
6. Ship signed artifacts and CI receipts before calling releases user-ready.
7. Keep physical acoustic/performance qualification explicitly open until device access returns.

### P1 — High-value chat clarity borrowed from Desktop

1. Add authoritative-final stream reconciliation with strict turn/event boundaries.
2. Add normalized timestamps and profile avatar ownership to settled replies.
3. Add a compact gateway/profile/model/tools status sheet suitable for mobile and a footer/status bar only on desktop layouts.
4. Improve stale connection/setup warning UX: recoverable warning, repair action, and exact-generation request ownership.
5. Re-run current-source real-gateway Maestro scenarios.

### P2 — Profiles, providers, and models

1. Finish authoritative profile CRUD/persona contracts and device receipts.
2. Restructure Providers to configured-first + Add Provider.
3. Put provider-specific model discovery/selection inside provider detail.
4. Preserve Wing model presets as client-local convenience, visibly separate from Agent-owned assignments.
5. Require write-only credentials, domain revisions, stale-write rejection, validation, and explicit apply disposition.

### P3 — Discover, Skills, Tools, and MCP

1. Merge the information architecture into Discover (catalog) and Tools (installed/configured).
2. Add profile-scoped mutation contracts before showing install/remove/toggle buttons.
3. Treat stdio MCP as host-only where the Hermes runtime cannot safely own it remotely; HTTP MCP remains server-owned.
4. Add explicit risk confirmation for terminal/file/code/computer-use toolsets.

### P4 — Memory and Tasks

1. Add paginated memory entries/profile/capacity/provider controls through scoped contracts.
2. Complete schedule create/pause/resume/run/delete; do not claim edit unless an edit contract exists.
3. Add Kanban boards, eight active lanes plus archive, details/comments/events/runs, and valid revision-safe transitions.
4. Replace Desktop local-path workspaces with expiring opaque resource/worktree handles.
5. Prefer SSE + GET reconciliation; use bounded polling only as an advertised fallback.

### P5 — Gateway administration and diagnostics

1. Add scoped lifecycle/log/platform configuration contracts.
2. Require busy/drain/apply/reload/restart dispositions and preserve active work.
3. Keep diagnostics bounded and redacted; never include credentials, transcript content, tool payloads, or private paths.
4. Adapt Desktop’s compact status affordance to current route and capability state.

### P6 — Adaptive Office and optional account outcomes

1. Derive agent working/idle state from authoritative task/run activity in Wing’s 2D Office.
2. Add accessible representative/action cards and One Chat handoff before animation. Actions must be typed server-owned operations/events; never parse assistant prose or hidden text blocks as an Office command protocol.
3. Add account sync/wallet/balance only through the optional Hermes One service; Wing remains usable while signed out/offline.
4. Consider desktop 3D missions only after every action has a complete non-spatial keyboard/screen-reader equivalent.

### P7 — Host parity and Electron retirement

1. Linux first: Wing Link managed runtime, explicit SSH trust, filesystem grants, menus/tray/updater, signed packages.
2. Add SSH Docker adoption only in trusted desktop host adapters; never as Android remote installation.
3. Port stable host contracts to Windows/macOS and verify install/update/rollback.
4. Move the Electron cutoff only after the parity ledger and migration gates pass.

## 6. Implementation work packages

### Task 1: Versioned evidence ledger

**Files:**

- Create: `docs/quality/evidence-matrix.md`
- Create: `scripts/check_evidence_matrix.dart`
- Test: `test/tooling/evidence_matrix_contract_test.dart`

**Steps:**

1. Write a failing source-contract test requiring evidence class, source identity, artifact identity, platform, date, and limitations.
2. Implement schema/checker with stale receipt rejection.
3. Seed it from the matrix in this plan, preserving “unverified” states.
4. Run `flutter test test/tooling/evidence_matrix_contract_test.dart`.
5. Run analyzer and full suite.

### Task 2: Authoritative-final chat reconciliation

**Likely files:**

- Modify: `lib/core/hermes/channel/hermes_api_channel.dart`
- Modify: relevant run-event/message reconciliation under `lib/features/hermes_chat/`
- Test: `test/core/hermes/channel/hermes_api_channel_test.dart`
- Test: `test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart`

**Steps:**

1. Add RED cases for dropped middle deltas, distinct pre-tool text, distinct reasoning, Unicode, and stale generation finals.
2. Define one canonical-final reconciliation function with explicit turn/event identity.
3. Replace only demonstrably lossy streamed text; never erase distinct segments via loose subsequence matching.
4. Verify focused tests, full suite, and real-gateway Maestro continuity.

### Task 3: Adaptive status summary

**Likely files:**

- Modify: `lib/shared/widgets/app_shell.dart`
- Modify: `lib/features/hermes_chat/screens/state/hermes_chat_layout.dart`
- Create: `lib/features/status/widgets/hermes_status_summary.dart`
- Test: `test/shared/widgets/app_shell_test.dart`

**Steps:**

1. Write RED widget tests for gateway/profile/model state, unknown omission, stale state, offline state, 200% scale, and semantics.
2. Build a compact mobile sheet and desktop-only bar from existing providers; no new backend state.
3. Ensure secret/path/unknown fields cannot render.
4. Verify widgets, full suite, and portrait/landscape Maestro.

### Task 4: Configured-first Providers IA

**Likely files:**

- Modify: `lib/features/providers/screens/providers_screen.dart`
- Modify: provider models/stores under `lib/features/providers/`
- Test: `test/features/providers/providers_screen_test.dart`
- Test: `test/features/providers/provider_credential_sheet_test.dart`

**Steps:**

1. Add RED tests for configured-first list, Add Provider, per-provider models, custom endpoint validation, secret non-reveal, and stale revisions.
2. Gate every mutation behind exact advertised scope/contract.
3. Keep client presets visibly separate from server assignments.
4. Run focused tests and a compatible real-gateway secret sentinel receipt.

### Task 5: Task activity feeding Office

**Likely files:**

- Create/modify task domain under `lib/features/tasks/`
- Modify: `lib/features/office/screens/office_screen.dart`
- Test: `test/features/office/office_screen_test.dart`

**Steps:**

1. Add RED tests for running-task activity, shared request single-flight, profile switch during in-flight request, stale event rejection, and unavailable task contracts.
2. Implement Agent-authoritative task activity with SSE/GET reconciliation.
3. Keep Office fully useful when tasks are unsupported.
4. Verify focused tests, current gateway fallback, and compatible-gateway device receipt.

### Task 6: Physical voice/acoustic qualification (blocked until device access)

**Files:**

- Use: `integration_test/android_acoustic_echo_probe_test.dart`
- Use/update: `docs/runbooks/android/live-mic-smoke.md`
- Add bounded aggregate receipt tooling only; do not retain raw microphone PCM.

**Required evidence:**

- Real English/Spanish WER/CER and mixed-language token error rate.
- First partial, endpoint-to-final, TTS first-audio, and cancellation p50/p95.
- Acoustic echo correlation/leakage, false interruption, and barge-in latency by route.
- Bluetooth/wired/speaker route changes.
- Peak RSS, sustained battery, and thermal behavior.

## 7. Verification gates for every roadmap slice

Run as applicable:

```bash
/home/xel/flutter/bin/dart format <changed files>
/home/xel/flutter/bin/flutter test <focused tests>
/home/xel/flutter/bin/flutter test
/home/xel/flutter/bin/flutter analyze --no-pub
git diff --check
cd wing_link && go test ./... && go vet ./...
/home/xel/flutter/bin/flutter build apk --release
```

Then select the correct evidence tier:

- Widget/unit only → **deterministically tested**.
- APK build/install only → **build/package tested**.
- Waydroid fixture → **qualified deterministic Android lifecycle/runtime**, not physical acoustic proof.
- Physical device with injected fixture → **qualified physical ABI/runtime**, not microphone or speech-quality proof.
- Physical spoken/acoustic protocol → **qualified physical acoustic behavior**.
- Repeated representative production usage with incident evidence → only then **battle-tested**.

## 8. Risks and tradeoffs

- Desktop has useful behavior but frequently reaches it via CLI/filesystem/SQLite. Copying mechanisms would make Wing unsafe and remote-incompatible.
- A broad parity UI without Agent contracts creates fake controls; unsupported capabilities must remain absent or explicitly unavailable.
- Polling can duplicate work and land stale state. Prefer event IDs + reconciliation; where polling remains, use single-flight and exact profile/generation checks.
- Optional account/wallet features must not make Hermes Agent use dependent on Hermes One availability.
- 3D Office can consume roadmap capacity while core configuration, tasks, release engineering, and physical voice evidence remain incomplete.
- Historical receipts become stale whenever their behavior-affecting source changes. The evidence ledger must make this visible.
- “Battle-tested” is intentionally a high bar; weakening the label would obscure the exact gaps the user asked to track.

## 9. Open questions requiring product/Agent coordination

1. Which scoped Agent contracts will land first: profiles/providers, skills/MCP, memory, tasks, or gateway administration?
2. Is Hermes One a committed Wing product dependency or an optional module?
3. Should Kanban be a primary Android destination or live inside Tasks with Schedules?
4. What production usage/telemetry is acceptable for the “battle-tested” label while preserving transcript and secret privacy?
5. Which ABIs and Android minimum versions are release requirements for offline voice distribution?
