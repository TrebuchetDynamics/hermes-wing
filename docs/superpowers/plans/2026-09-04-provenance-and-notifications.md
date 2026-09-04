# Provenance and Notifications Implementation Plan

> **For agentic workers:** Use executing-plans task-by-task. Notifications are a proposal deliverable only; no relay enrollment, infrastructure, external messages, or publishing are authorized.

**Goal:** Make conversation ownership and supported actions obvious, and specify a private notification path without inventing Agent capabilities.

**Architecture:** Refine existing chat/session identity widgets and adaptive routes. Capability claims follow reachable UI and exact advertised operations. Notifications remain outside Wing Link and resolve user intent through direct authenticated Agent state.

**Tech Stack:** Flutter 3.44.2, existing Riverpod/channel state, localization, widget/semantics tests. No notification SDK or account-service dependency in this plan.

## Global Constraints

- Follow the [program](2026-09-04-conduit-adaptation-roadmap.md), [route contract](../../product/routes.md), and product/security ADRs.
- Gateway labels are user-facing names; never expose raw private endpoints as identity badges.
- Use stable profile color only as a secondary cue alongside readable text.
- Session source is authoritative metadata, never an inference from a name, icon, local creation, or decoder fallback.
- Notification routing must not approve, clarify, send, retry, or change Agent state automatically.
- No route-status or support promotion from models, placeholders, deterministic tests, or reference-client marketing.

## Task 1: Polish visible conversation provenance and accessible recovery

**Files:** modify `lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart`, `lib/features/hermes_chat/screens/widgets/hermes_chat_status.dart`, `lib/features/hermes_chat/presentation/hermes_chat_timeline.dart`, and `lib/l10n/app_en.arb`; inspect `lib/core/hermes/models/hermes_session.dart` and `lib/features/hermes_chat/widgets/hermes_profile_identity.dart`. Tests: `test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart`, `hermes_chat_profile_switch_test.dart`, `hermes_chat_message_actions_a11y_test.dart` in the same directory, and `test/features/hermes_chat/widgets/hermes_profile_identity_test.dart`.

**Current evidence:** The gateway-switch suite already asserts a profile/gateway header. The session decoder defaults absent source to `api_server`; that default must not become proof of origin.

**Interfaces:** Use current contact/profile/session identity. Present gateway label, profile name, selected session, authoritative source when known, and detached/running/completed/reconciling state. Missing source is “Unknown source” or omitted, never fabricated Telegram/API provenance.

- [ ] Add cases with identical profile and session labels on two gateways, missing/deleted profile, unknown source, detached run completion, and failed replacement activation. Assert visible and semantic labels describe the active owner.
- [ ] Preserve source absence through the smallest model/presentation change if necessary; trace callers before changing decoding. Test explicit source versus absent source. Do not expand the Agent wire schema.
- [ ] Refine the existing header and session selector with one readable hierarchy, text labels, and accessible selected state. Expose full labels through focus/semantics when visual truncation is needed; keep private URLs out of tooltips.
- [ ] Add explicit selection before continuing a Telegram/other-client session. Opening Wing must not silently merge conversations or pick another client's session as a restoration fallback.
- [ ] Test 320 logical-pixel width, desktop keyboard navigation, 200% text, long labels, dark/light contrast, focus return after closing the session picker, and reduced motion. Approvals and Stop remain reachable without voice or pointer precision.
- [ ] Keep loading, empty, unsupported, unauthorized, failed, and reconnecting states distinct. Every actionable error offers one relevant recovery path and retains current draft/selection.
- [ ] Run `flutter gen-l10n`, `flutter analyze`, and `flutter test test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart test/features/hermes_chat/screens/hermes_chat_profile_switch_test.dart test/features/hermes_chat/screens/hermes_chat_message_actions_a11y_test.dart test/features/hermes_chat/widgets/hermes_profile_identity_test.dart`.
- [ ] After UI integration build `flutter build web --release -t lib/main_e2e.dart`, then run `npm run web:e2e`. Regenerate README/landing assets only after actual UI changes, using the documented `npm run readme:assets` workflow.

## Task 2: Keep administration and product claims truthful

**Files:** inspect `lib/features/providers/screens/providers_screen.dart`, `lib/features/tools/screens/tools_screen.dart`, `lib/features/schedules/screens/schedules_screen.dart`, `lib/features/profiles/screens/profiles_screen.dart`; update `docs/product/routes.md`, `docs/product/hermes-compatibility.md`, `docs/product/prd.md`, and `README.md` only where evidence justifies wording. Tests: corresponding feature suites and `test/core/hermes/hermes_api_test.dart`.

**Interfaces:** Each visible mutation requires exact method/route, declared and granted scope, stable resource identity, and concurrency semantics when edits collide. The transactional new-profile Wing Link exception does not authorize existing-profile configuration.

- [ ] Build a claim table for models/providers, skills/toolsets/MCP, schedules/history, Projects, Kanban, voice, and wake words: exact contract, reachable control, regression target, platform evidence, and unsupported state.
- [ ] For absent contracts, test controls remain absent or clearly explained. A registered but unadvertised route is insufficient. Existing supported mutations stay available when their exact gate passes; this is not a blanket removal.
- [ ] Cover capability revocation and resource replacement while a sheet is open. Revalidate immediately before dispatch; an optimistic local toggle cannot manufacture persistence.
- [ ] Keep optimistic administration deferred until authoritative write/revision/rollback semantics exist. If a supported action persists but reload fails, distinguish those outcomes.
- [ ] Replace broad desktop-parity/MCP/wake-word claims only if found in Wing's current docs. Conduit's reported marketing gaps are audit prompts, not proof Wing has the same defects.
- [ ] Run `flutter test test/features/providers test/features/tools test/features/schedules test/features/profiles test/core/hermes/hermes_api_test.dart` and `git diff --check`. Preserve evidence limits in route wording.

## Task 3: Write the notification contract and privacy proposal

**Files:** create `docs/product/notification-contract-proposal.md`; link from `docs/product/prd.md` and `ROADMAP.md`. Propose edits to existing security/API ADRs only if an accepted cross-cutting decision changes them. No runtime files in this task.

**Proposed boundary:** An optional Agent plugin/account service owns enrollment and routing; an explicitly selected relay transports minimal notification data. Wing Link is never a relay or decision plane. This is a proposed responsibility split, not an assertion that a usable upstream contract exists.

- [ ] Specify opt-in enrollment, visible relay identity, self-hosting, independent device revocation, retention/deletion, OS permission denial, token rotation, and relay changes. Enrollment credentials remain separate from Agent and Wing Link credentials.
- [ ] Limit payload to an opaque short-lived single-use routing handle and non-sensitive category (approval pending, completed, failed, background activity). Exclude prompts, transcripts, tool arguments, profile names, private hostnames, provider values, and raw session/run IDs.
- [ ] Define duplicate, replayed, expired, revoked, and wrong-device handles; avoid notification-fetch consuming a handle before the authorized tap. Bound lookup attempts and redact logs. No bearer credential or routing handle in shared URLs.
- [ ] Resolve a tap after authentication against the intended Agent resource. Explicit navigation outranks viewport restoration. Deleted sessions, missing gateways, offline state, denied grants, and relay outage offer safe selection/recovery; never reroute to another session.
- [ ] Require direct Agent approval/clarification after user review. No third-party relay carries decisions or mutating response data. Do not silently replay a tap-triggered mutation after reconnect.
- [ ] Document native TLS/origin/pinning expectations and browser limitations, without broad HTTPS navigation or injected WebView secrets. A custom relay URL is not an exemption from transport policy.
- [ ] Enumerate implementation gates: advertised plugin/Agent contract, exact scopes/resource routing, reviewed privacy/retention model, supported relay identity/trust, platform credentials, revocation tests, and named physical delivery evidence. Any missing gate leaves implementation blocked by contract.
- [ ] Validate local links and `git diff --check`. Record Android/iOS delivery, locked-screen privacy, and termination/resume tests as future qualification requirements; no APNs/FCM success claim from this proposal.

## Completion

Provenance polish may ship without notifications. Record UI tests separately from
physical accessibility checks and proposal status in the
[program](2026-09-04-conduit-adaptation-roadmap.md).
This documentation pass installs no SDK and changes no running product.

## Tasks 2–3 execution receipt — 2026-09-04

Task 1 is partially executed: the session decoder preserves missing source;
explicit source remains unchanged, and the existing selector renders Unknown
source instead of invented API provenance. New model tests and the existing
gateway/profile identity regressions cover that change. Existing header/profile
identity is reused rather than replaced. Voice controls and Latest activity have
localized accessible actions; the complete long-label/scale/focus/physical
accessibility matrix remains open. Browser assertions for not-found/persona
recovery were reconciled with the live accessible UI, without changing product
behavior to satisfy stale copy. See the program receipt for final browser and
asset-generation results.

Task 2: [source-backed claim table](../../product/capability-claim-audit.md)
records exact understood operations, controls, regression targets, and platform
limits. No false broad MCP/wake-word/desktop-parity wording was found to remove.
Provider credential and model assignment sheets now capture their opening
channel/origin/profile and permanently invalidate on resource roundtrip or
disconnect; action dispatch checks current capability state. Refresh/probe
completions cannot publish into a replacement owner. Regressions cover modal
profile A → B → A and capability removal. Existing revision-conflict behavior is
retained without introducing optimistic persistence or automatic replay.

`flutter test test/features/providers test/features/tools test/features/schedules test/features/profiles test/core/hermes/hermes_api_test.dart --reporter expanded`:
239 passed. Earlier runs caught in-progress tools/schedules refresh-test fixture
failures; the final combined run passed after those fixes. Targeted sheet
analyzer and formatting passed. This is deterministic Flutter evidence only;
no platform support status was promoted.

Task 3 proposal completed in
[notification-contract-proposal.md](../../product/notification-contract-proposal.md).
It specifies opt-in enrollment, separate credentials, selected/self-hosted relay,
single-use device-bound short-lived handles, deletion, revocation, retries,
explicit tap precedence, direct Agent decision review, origin/TLS constraints,
and physical delivery gates. No runtime notification implementation, SDK,
enrollment, external messages, or ADR policy changes. Local link checks and
`git diff --check` passed. Program owner links the deliverables from the roadmap
and PRD. Android/iOS delivery and lock-screen qualification remain future work.
