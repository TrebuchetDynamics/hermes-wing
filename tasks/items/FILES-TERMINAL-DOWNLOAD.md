+++
schema = 1
id = "FILES-TERMINAL-DOWNLOAD"
title = "Download a selected terminal working-directory file to the Wing device with verified bytes"
short = "Download a selected terminal working-directory file to the Wing device with verified bytes"
status = "done"
goal = "PARITY"
section = "Next"
rank = 9000
depends_on = ["FILES-TERMINAL-BROWSE"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "reuse browse owner/root authorization; explicit Linux Save As and Android document-save picker, bounded/cancellable transfer, sanitized filename and destination handling. No upload, edit/delete, executable preview, recursive folder download or silent overwrite."
acceptance = ["read back saved bytes against the selected source; cancellation/denial/disconnection/owner-switch leave no claimed successful save; progress and explicit retry; test text and binary downloads and hostile filenames; native Linux and Android save receipts, not download-start-only claims."]
exclusions = []
closure = "manual"
closure_actor = "xel"
closure_timestamp = "2026-10-22T12:45:49.498874+00:00"
closure_reason = "2026-10-22 owner decision: defer this device/live qualification and close the queue row. Offline work and recorded evidence remain; no live evidence is claimed. Reopen when the authorized device/host target is available."
+++

- Sources: [FILES-3 and FILES-4](docs/product/prd.md#terminal-working-directory-files) and [existing raw-download contract](docs/analysis/terminal-files-feasibility.md#existing-contracts-and-official-consumers). Use the qualified owning `serve` connection and authenticated headers, not preview text or a token-bearing URL. Save-picker and byte-readback qualification remain open on both platforms.
- Ownership: unassigned.
- Section: Needs decision.
- Owner decision: 2026-10-18 — Apply the existing deferral of FILES-TERMINAL-BROWSE to this dependent task. Preserve its dependency and original acceptance; no approval question, dispatch or completion is implied. Resume only when the prerequisite's stated qualification/contract gate is satisfied.
- Touches: none before conversion; ** stands for the whole repository
