+++
schema = 1
id = "FILES-TERMINAL-DOWNLOAD"
title = "Download a selected terminal working-directory file to the Wing device with verified bytes"
short = "Download a selected terminal working-directory file to the Wing device with verified bytes"
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
exclusions = []
+++

- Sources: [FILES-3 and FILES-4](docs/product/prd.md#terminal-working-directory-files) and [existing raw-download contract](docs/analysis/terminal-files-feasibility.md#existing-contracts-and-official-consumers). Use the qualified owning `serve` connection and authenticated headers, not preview text or a token-bearing URL. Save-picker and byte-readback qualification remain open on both platforms.
- Ownership: unassigned.
- Section: Needs decision.
- Owner decision: 2026-10-18 — Apply the existing deferral of FILES-TERMINAL-BROWSE to this dependent task. Preserve its dependency and original acceptance; no approval question, dispatch or completion is implied. Resume only when the prerequisite's stated qualification/contract gate is satisfied.
- Touches: none before conversion; ** stands for the whole repository
- Reopened: Reopened after an owner-close correction: this is offline implementation work and belongs in Next, not in the device/live waiver.
- Gate recheck (2026-10-24): the prerequisite gate is still unsatisfied at upstream `14e1e43a23761b369641208e204365cd6cb9399d`; the session-scoped download route still resolves the stored session cwd for relative paths only. See the [revisit check](docs/analysis/terminal-files-feasibility.md#revisit-check-upstream-14e1e43a-2026-10-24). Still waiting on `FILES-TERMINAL-BROWSE`; no upload, edit, delete or always-disabled completion claim.
