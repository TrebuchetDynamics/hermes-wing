# ADR 0036: Make backup and restore server-owned

Status: accepted
Date: 2026-07-13

Hermes Agent owns versioned backup creation, inspection, download, upload, and restore. Navivox uses capability-advertised typed jobs and opaque, expiring archive handles; it never reads, writes, displays, or submits a `HERMES_HOME` archive path and never shells out to backup commands.

## Archive modes

A **portable profile archive** is the default. It contains the selected profile's portable domain state and a versioned manifest, but excludes provider credentials, API and scoped tokens, OAuth data, analytics state, environment secrets, private filesystem paths, machine/runtime state, and legacy wallet material. It may still contain sensitive conversations and user data, so the export UI warns before saving or sharing it.

A **machine recovery archive** may include local provider secrets needed for disaster recovery only when encrypted as one authenticated outer envelope with a user-supplied passphrase and versioned key-derivation parameters. The passphrase is held only for the active operation and is never persisted, logged, copied, included in diagnostics, or returned by the server. Machine recovery creation and restore are local-host capabilities requiring superuser authorization and explicit confirmation; they are unavailable to ordinary remote clients.

Scoped operator credentials, Hermes One OAuth credentials, analytics consent or identifiers, and legacy local-wallet material are excluded from both modes and require fresh authorization or their separately guarded recovery flow. External provider state is included only when its adapter advertises a validated transactional export/restore contract; every exclusion is shown before export.

## Contract and authorization

Profile backup jobs require explicit `profile=<id>` context and dedicated `backups:read` or `backups:write` authorization. Capabilities identify supported archive modes, limits, handle retention, and whether local recovery is available. Job and archive responses contain IDs, state, bounded counts, sizes, hashes, timestamps, compatibility ranges, and apply dispositions—not server filesystem paths or secret values.

Archive handles are unguessable, bound to their principal and profile, expire, and support explicit deletion. Downloads and uploads are bounded and streamed. Navivox does not automatically upload archives to Hermes One or another cloud service.

## Restore lifecycle

Restore is never a blind force overlay. Hermes Agent first stages and inspects the archive, rejects traversal, links, duplicate entries, decompression bombs, invalid manifests or hashes, unsupported versions, wrong profiles, and prohibited secret categories, then returns a redacted change preview and required lifecycle disposition.

Applying an accepted preview requires a fresh explicit confirmation and unchanged inspection ID. Hermes Agent prevents new work, drains active work under ADR 0029, creates and verifies a pre-restore recovery checkpoint, applies the staged state with all-or-rollback semantics, and reports progress through the profile event stream. Failure restores the prior authoritative state. Success performs the required reload or restart and verifies health, capabilities, profile identity, and domain revisions before declaring completion.

Cancellation is allowed before apply begins. Restore never silently changes the client-selected profile, overwrites another profile, or replays work queued before restoration.
