# Hermes Wing Roadmap

Priority order. Each slice ships independently. Skip nothing above the line
until the line moves. This file tracks remaining work; the
[Hermes Desktop parity ledger](docs/product/hermes-desktop-parity.md) is the
canonical source for current capability status and evidence.

---

## Phase 1 — Ship the thing (close the gap with Wingman)

Users can't adopt what they can't install.

| #   | Slice                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Why now                                                                                                                                                                                                                                         |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.1 | **Signed release artifacts** — AAB for Play Store, APK for sideload, notarized DMG, MSIX, APT/DEB                                                                                                                                                                                                                                                                                                                                                                 | No signed binaries = no users. Wingman ships APKs today.                                                                                                                                                                                        |
| 1.2 | **Wing Link local runtime** — ship the signed Go host supervisor with an independent acknowledged control credential and loopback plus one selected private/VPN listener; complete detect, adopt, verify, install, update, repair, pair, and diagnose on Android/Termux, Linux, Windows, and macOS. Initial profile/provider setup must use Hermes-owned typed interfaces; Wing Link has no Hermes domain bridge. Offer the pinned Donna starter profile only through Hermes's distribution installer. No remote installs or Hermes traffic proxy. | Guided local installation is the primary Android onboarding path and the desktop replacement path; Linux user-service/bootstrap foundations exist, while signed artifacts, non-Linux adapters, clean/adopt/repair receipts, and a compatible Donna distribution manifest remain. |
| 1.3 | **Full Agent configuration** — add/remove providers, switch models, manage skills, edit config through Agent contracts, manage memory, manage cron, manage gateway platforms — all from the GUI. No human CLI-output parsing.                                                                                                                                                                                                                                     | The entire `hermes setup` outcome lives in the app while Hermes Agent remains authoritative.                                                                                                                                                    |
| 1.4 | **LAN discovery** — mDNS/UDP broadcast or subnet scan for Hermes Agent port 8642                                                                                                                                                                                                                                                                                                                                                                                  | Mobile users shouldn't type IPs. Wingman auto-scans for 9120.                                                                                                                                                                                   |
| 1.5 | **System tray** — minimize-to-tray on desktop, tray menu for quick actions                                                                                                                                                                                                                                                                                                                                                                                        | Desktop parity. Trivial with `tray_manager` or `system_tray`.                                                                                                                                                                                   |
| 1.6 | **CI release pipeline** — GitHub Actions build matrix: Android, iOS, Linux, macOS, Windows, web                                                                                                                                                                                                                                                                                                                                                                   | Manual builds don't scale. One tag → all artifacts.                                                                                                                                                                                             |

## Phase 2 — Feature parity (match Wingman's surface area)

Close the remaining surface gaps by extending the current read-only foundations.
Keep them Agent-authoritative, not backend-duplicated.

| #   | Slice                                                                                                     | Notes                                                                                                                                                                           |
| --- | --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2.1 | **Skills management** — add advertised enable/disable actions to the existing list and search UI          | Contract-blocked upstream: Hermes Agent (verified v0.19.0) advertises only `GET /v1/skills`, no mutation endpoint. Keep `/v1/skills` authoritative; no client-side skill state. |
| 2.2 | **Memory browser** — list, search, delete memory entries                                                  | Paginated read from `/v1/memory`. Delete requires confirmation.                                                                                                                 |
| 2.3 | **Schedule management** — add create, edit, delete, and run-now actions to the existing read-only jobs UI | Show actions only when the Agent advertises them.                                                                                                                               |
| 2.4 | **File browser** — read/edit files in Hermes workspace                                                    | Uses Hermes resource handles, never raw client paths.                                                                                                                           |
| 2.5 | **Config editor** — syntax-highlighted YAML editor for config.yaml                                        | Read via Agent API, write back through domain revision `If-Match`.                                                                                                              |
| 2.8 | **Logs viewer** — stream or tail Hermes Agent logs                                                        | If Agent exposes a log endpoint; otherwise skip until it does.                                                                                                                  |

Shipped from this phase: 2.6 model presets (client-side `shared_preferences`
store with save/load/apply, capped at 32) and 2.7 provider diagnostics (the
credential validate action is a connection probe reporting round-trip latency
plus the provider's model inventory or a bounded error, commit `55b3396`).

## Phase 3 — Distribution and host integration

| #   | Slice                                                                                                                             | Notes                                                                                                              |
| --- | --------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| 3.1 | **Web distribution** — publish the existing tested Flutter web build                                                              | Same codebase, zero new backend.                                                                                   |
| 3.2 | **Wing Link lifecycle polish** — harden service restart, rollback, diagnostics, and independently recoverable optional components | Core install/lifecycle is Phase 1. This keeps the local-only supervisor reliable without growing a domain backend. |
| 3.3 | **iOS signed build** — TestFlight or App Store                                                                                    | Requires Apple Developer account + Xcode CI.                                                                       |

## Phase 4 — Differentiate (things you have that Wingman doesn't)

Double down on your advantages.

| #   | Slice                                                                                                                         | Notes                                                                  |
| --- | ----------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| 4.1 | **Continuous voice hardening** — record a repeatable physical microphone receipt and harden the existing opt-in rearming loop | Keep transcript review and TTS failure recovery visible.               |
| 4.2 | **Rich transcript polish** — finish selectable GFM markdown, code-copy controls, and link allowlisting                        | Build on the existing rich-text renderer.                              |
| 4.3 | **Adaptive Office depth** — extend the existing responsive 2D gateway workspace with an optional desktop 3D view              | Preserve an accessible 2D equivalent.                                  |
| 4.4 | **Approval UX polish** — refine the existing inline approve/deny cards and reason flow                                        | Keep requests attached to their owning session.                        |
| 4.5 | **Diagnostics sharing** — add a native share action to the existing copyable bounded diagnostics                              | Never include credentials, transcripts, tool payloads, or local paths. |
| 4.6 | **Scoped token lifecycle** — add per-device labels, rotation, and revocation beyond enrollment                                | Security differentiator. Never render stored bearer values.            |

## Phase 5 — Polish (make it feel finished)

| #   | Slice                                                                            | Notes                                                              |
| --- | -------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| 5.1 | **Theme system** — 5-10 polished themes, dark/light default, user theme picker   | Don't match Wingman's 29. Ship 5 good ones.                        |
| 5.2 | **Onboarding flow** — first-launch walkthrough, not just setup wizard            | Context-aware tips, not a tutorial dump.                           |
| 5.3 | **Animations/transitions** — route transitions, loading states, skeleton screens | Flutter makes this cheap. Use it.                                  |
| 5.4 | **Accessibility audit** — screen reader labels, contrast, keyboard nav           | Per CONTEXT.md: "accessible equivalent" is a contract requirement. |
| 5.5 | **Localization** — full i18n for baseline locale set (12 locales per CONTEXT.md) | You have `l10n/` scaffolded. Fill it.                              |

---

## What's explicitly NOT on this roadmap

- **Second domain backend** — Hermes Agent is authoritative. Wing Link is an
  independently authenticated host supervisor with no Hermes domain bridge. It
  never lists or mutates profiles/providers as a fallback and never proxies
  chat, session, message, run, approval, or configuration traffic. Prototype
  profile/provider adapters are migration debt, not an approved product path.
- **Remote Agent installs** — install target is local only: Termux Android,
  Linux, Windows, and macOS. No SSH installs or remote deployment. Users may
  bring an existing Agent; Android presents local setup first but retains remote pairing.
- **Rails web dashboard** — Flutter web covers this. Second framework = second maintenance burden.
- **29 themes** — YAGNI. 5 good ones > 29 mediocre ones.
- **Client-side config parsing** — Agent owns config. Client reads advertised interfaces only.
- **Bundled runtime stack** — packages may include Wing Link, but never Hermes
  Agent, Python, Node, or OmniRoute. External runtime data survives ordinary uninstall.
