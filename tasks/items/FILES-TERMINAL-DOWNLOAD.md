+++
schema = 1
id = "FILES-TERMINAL-DOWNLOAD"
title = "Download a selected Agent-managed root file to the Wing device with verified bytes"
short = "Download a selected Agent-managed root file to the Wing device with verified bytes"
status = "open"
goal = "PARITY"
section = "Next"
rank = 16000
depends_on = ["FILES-TERMINAL-BROWSE"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "reuse browse owner/root authorization; explicit Linux Save As and Android document-save picker, bounded/cancellable transfer, sanitized filename and destination handling. No upload, edit/delete, executable preview, recursive folder download or silent overwrite."
acceptance = ["read back saved bytes against the selected source; cancellation/denial/disconnection/owner-switch leave no claimed successful save; progress and explicit retry; test text and binary downloads and hostile filenames; native Linux and Android save receipts, not download-start-only claims."]
checks = ["For changed inputs, `flutter test --no-pub --concurrency=1 test/core/hermes/ test/features/hermes_chat/`; `flutter analyze --no-pub`; `git diff --check`. Reuse unchanged source-bound receipts.", "Add the oracles this acceptance names (read-back bytes against the selected source, cancellation/denial/disconnection/owner-switch with no claimed save, progress and explicit retry, text/binary and hostile filenames) before a save action can be enabled; a download-start receipt never substitutes for read-back.", "Rebuild `flutter build web --release -t lib/main_e2e.dart` before `npm run web:e2e` when the browser download path changes.", "Linux Save As and Android document-save picker receipts are separate native cells with their existing target/access gates; no fixture or compiled-browser pass qualifies them. Run `flutter gen-l10n` after editing English copy in `lib/l10n/app_en.arb`; never hand-edit generated localization output."]
exclusions = []
+++

- Sources: [FILES-3 and FILES-4](docs/product/prd.md#terminal-working-directory-files) and [existing raw-download contract](docs/analysis/terminal-files-feasibility.md#existing-contracts-and-official-consumers). Use the qualified owning `serve` connection and authenticated headers, not preview text or a token-bearing URL. Save-picker and byte-readback qualification remain open on both platforms.
- Ownership: unassigned.
- Section: Next. The earlier `Needs decision` note was stale after the reopen correction below; the dependency on `FILES-TERMINAL-BROWSE` still keeps this task unselectable while that gate is deferred.
- Owner decision: 2026-10-18 — Apply the existing deferral of FILES-TERMINAL-BROWSE to this dependent task. Preserve its dependency and original acceptance; no approval question, dispatch or completion is implied. Resume only when the prerequisite's stated qualification/contract gate is satisfied.
- Touches: none before conversion; ** stands for the whole repository
- Reopened: Reopened after an owner-close correction: this is offline implementation work and belongs in Next, not in the device/live waiver.
- Owner decision: 2026-10-24 — the owner-selected surface is the Agent managed-files root, so download fetches exact bytes from `/api/files/download` over the same owning connection and inherits the advertised-`locked_root` gate. The 2026-10-18 dependency on `FILES-TERMINAL-BROWSE` and the original acceptance are unchanged; no upload, edit, delete or always-disabled completion claim.
