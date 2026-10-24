+++
schema = 1
id = "FILES-TERMINAL-BROWSE"
title = "Browse and read Agent-managed root files on Linux and Android"
short = "Browse and read Agent-managed root files on Linux and Android"
status = "open"
goal = "PARITY"
section = "Next"
rank = 1000
depends_on = []
touches = ["lib/core/hermes/", "lib/features/", "lib/router/", "test/core/hermes/", "test/features/", "test/router/", "integration_test/", "playwright/tests/", "docs/quality/", "lib/l10n/app_en.arb", "lib/l10n/app_localizations.dart", "lib/l10n/app_localizations_en.dart"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "Owner-selected managed-files root: implement the read-only Files surface against authenticated `hermes serve` managed-files routes (`/api/files`, `/api/files/read`) over the owning connection. Enable it only when the server advertises a non-empty `locked_root`; never fall back to an unconfined `can_change_path` policy. Read-only: listings and bounded previews, with no upload, mkdir, delete, write-text, shell, host-wide browser, Agent edits, prompt retrieval or terminal/Project root substitution. Desktop's terminal-cwd Files outcome is not claimed."
acceptance = ["folders/files and read-only bounded text previews rooted at the advertised locked root, with the owning connection/identity context; keyboard/touch access; loading/empty/denied/unsupported/retry states; context-change stale-result rejection; server-policy denial proof for `..`, absolute outside-root paths, symlinks and sensitive paths; explicitly unavailable when the policy reports no locked root; no incidental mutation, credential exposure or file-content logs. Linux and Android device checks remain separately recorded."]
checks = ["For changed inputs, `flutter test --no-pub --concurrency=1 test/core/hermes/ test/features/hermes_chat/`; `flutter analyze --no-pub`; `git diff --check`. Reuse unchanged source-bound receipts.", "Add the oracles this contract names before enabling the surface: advertised-`locked_root` gating, `..`/absolute-outside refusal, sensitive-path denial, stale-context rejection and bounded preview. An unlocked `can_change_path` response must render unavailable, never browse.", "Rebuild `flutter build web --release -t lib/main_e2e.dart` before `npm run web:e2e` when the browser path changes. Linux/Android and actual-Agent cells require their existing target/access gates; no fixture pass qualifies live file access.", "Run `flutter gen-l10n` after editing English copy in `lib/l10n/app_en.arb`; never hand-edit generated localization output. Include regenerated output in analysis and the affected UI checks above."]
exclusions = []
+++

- Sources: [accepted port scope](ROADMAP.md#flutter-port-execution-roadmap), [FILES-1, FILES-2 and FILES-4](docs/product/prd.md#terminal-working-directory-files), and the [owner-approved Files surface](docs/adr/product.md#owner-approved-files-surface-the-agents-managed-files-root).
- Section: Next. The read-only surface is admitted offline; live enablement still needs a serve deployment whose managed-files policy advertises a locked root.
- History: the terminal-root requirement was deferred by the owner on 2026-10-22; three dispatched attempts ended with zero changed files, and the [upstream recheck](docs/analysis/terminal-files-feasibility.md#revisit-check-upstream-14e1e43a-2026-10-24) confirmed that no unmodified Agent operation names the session/profile/backend terminal root with canonical confinement. Those attempts remain readable under the Git common directory at `autowork-execution/slot-history/FILES-TERMINAL-BROWSE/`; no candidate commit exists to preserve.
- Contract: the [managed-files contract](docs/analysis/terminal-files-feasibility.md#managed-files-root-the-owner-selected-alternative) is the authority: policy meta `{root, locked_root, can_change_path}` on every response, server-side `..`/absolute/symlink/sensitive-path containment, `parent: null` at the locked root, and exact bytes from `/api/files/download` rather than a preview.
- Owner decision: 2026-10-24 — root the read-only Files surface at the Agent's managed-files root behind the advertised `locked_root` gate, superseding the 2026-10-22 terminal-root deferral. Read-only scope, FILES-4 redaction, FILES-3 verified-byte download and the separate Linux/Android save cells are unchanged; no Agent edit, runtime configuration change or unconfined fallback.
- Next action: implement the gated read-only listing/preview surface and its oracles, then keep `FILES-TERMINAL-DOWNLOAD` dependent for verified-byte saving. Desktop's terminal-cwd Files outcome stays unclaimed.
