+++
schema = 1
id = "FILES-TERMINAL-BROWSE"
title = "Browse and read the selected Agent terminal working-directory files on Linux and Android"
short = "Browse and read the selected Agent terminal working-directory files on Linux and Android"
status = "open"
goal = "PARITY"
section = "Needs decision"
rank = 1000
depends_on = []
touches = ["lib/core/hermes/", "lib/features/", "lib/router/", "test/core/hermes/", "test/features/", "test/router/", "integration_test/", "playwright/tests/", "docs/quality/", "lib/l10n/app_en.arb", "lib/l10n/app_localizations.dart", "lib/l10n/app_localizations_en.dart"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "[source tracing is complete](docs/analysis/terminal-files-feasibility.md); implement the read-only Files surface through qualified authenticated `hermes serve` routes. Qualify actual file authentication, authoritative session/profile root and server-enforced canonical containment before enabling access. List/read-text lack session parameters; local default-cwd and non-SSH execution backends need explicit qualification. Messaging-API-only connections remain unsupported. No Wing Link requirement, Agent edits, arbitrary shell, host-wide browser, file writes or prompt-based retrieval."
acceptance = ["folders/files and read-only bounded text previews; exact connection/profile/session root; keyboard/touch access; loading/empty/denied/unsupported/retry states; context-change stale-result rejection; traversal/symlink denial; no incidental mutation or content logs. Linux and Android device checks remain separately recorded."]
checks = ["For changed inputs, `flutter test --no-pub --concurrency=1 test/core/hermes/ test/features/hermes_chat/`; `flutter analyze --no-pub`; `git diff --check`. Reuse unchanged source-bound receipts. Add the specified root/authentication/containment/owner-race oracles, then rebuild `flutter build web --release -t lib/main_e2e.dart` before `npm run web:e2e`. Linux/Android and actual-Agent cells require their existing target/access gates; no fixture pass qualifies live file access. Run `flutter gen-l10n` after editing English copy in `lib/l10n/app_en.arb`; never hand-edit generated localization output. Include regenerated output in analysis and the affected UI checks above."]
exclusions = []
+++

- Section: Needs decision.
- Sources: [accepted port scope](ROADMAP.md#flutter-port-execution-roadmap), [FILES-1, FILES-2 and FILES-4](docs/product/prd.md#terminal-working-directory-files), owner-confirmed terminal working directory.
- Evidence: `autowork-execution/slot-data/FILES-TERMINAL-BROWSE/attempt-1/report.json` under the Git common directory names exactly these three localization paths for the already-required accessible labels, empty/denied/unsupported states, bounded preview and root-ownership explanations. No new product behavior or live access is admitted. The worker stopped before edits; resume the existing implementation contract with localized copy and unchanged authentication/containment gates.
- Readiness: CONTRACT-UNREADY: the latest source-bound attempt established no safe positive enablement rule for exact session/profile/backend root and canonical server confinement. Localization scope is already repaired; do not repeat that repair or submit an always-disabled feature as completed Files support.
- Planner decision: skip positive Files implementation until an existing unmodified Agent contract establishes all FILES-4 guarantees. Keep the original acceptance and FILES-TERMINAL-DOWNLOAD dependency; missing API authority is not a question the owner can waive. No shell/SFTP substitute, Agent edits, incidental-write probe or speculative qualification flag. Reconsider only with new source-bound contract evidence and independent review.
- Next action: Preserve candidate 0b9cc27d9b7df5265dedd19622b106579c385ee9 and all source/worker evidence. No retry of the unchanged implementation: reconsider only after new source-bound authoritative root/authentication/confinement contract evidence and review. Keep download waiting; no shell/SFTP substitute, Agent edits or always-disabled completion claim.
- Reopened: Reopened after an owner-close correction: this is offline implementation work and belongs in Next, not in the device/live waiver.
- Owner decision: 2026-10-22: Apply the existing recorded owner deferral: positive Files implementation stays incomplete until the unmodified Agent exposes the effective selected session/profile/backend terminal root, matching authorization and canonical confinement. This is not a new permission question or a waiver; preserve acceptance, retained candidate and download dependency.
