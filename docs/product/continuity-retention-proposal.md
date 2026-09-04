# Continuity retention proposal

Status: decision proposal only, 2026-09-04. Durable continuity is not approved or
implemented. Foreground recovery with a surviving process is not process-death
recovery. The current implementation work keeps drafts and viewport markers in
process memory; it adds no transcript, prompt, or attachment storage.

| Candidate | Default and lifetime | Deletion and export | If durable storage is later approved |
| --- | --- | --- | --- |
| Draft text, including recognized speech inserted into the composer | Private content, process-local; bounded draft count and text limits | Explicit clear, gateway removal, eviction, or process termination; no automatic export or diagnostics | Opt-in encrypted bounded store; explicit expiry; do not use ordinary preferences |
| Attachment bytes and text | Private content, process-local; existing per-file validation and aggregate retention budget | Remove/replacement, eviction, gateway removal, or process termination; no automatic export | Default remains no persistence; a separate decision must cover content, temporary-file cleanup, and app backup |
| Attachment metadata | Names, file paths, media types, and provider handles are private even without content | Remove with its attachment; no logs, audit bodies, export, or ordinary preferences | Separate consent and retention review; no persisted absolute host path or permission bypass |
| Gateway/profile/session identifiers | Private metadata used only for exact resource scoping | Remove matching presentation state on gateway removal or confirmed resource deletion | Secure, bounded metadata store with explicit deletion and migration tests; never infer authorization from a retained identifier |
| Viewport markers | Process-local resource identity, authoritative message identity if available, and edge offset; no content hash | Bounded inactive-marker eviction, gateway/session removal, or process termination | Metadata-only retention may be considered separately; no transcript excerpts or text matching; expired/missing anchors fall back safely |

Draft limits and viewport counts belong to the
[chat implementation plan](../superpowers/plans/2026-09-04-chat-continuity.md).
No local state may overwrite Agent history, prove a missing message identity, or
authorize replaying a queued mutation. Restoring a draft never sends it.

## Privacy and device behavior

Process-local data remains readable to a compromised running process; it is not
a secure enclave or protection against screenshots. UI lock-screen obscuring and
platform task-switcher snapshot behavior require explicit platform review. Do not
show draft content or attachment names in notifications, diagnostics, crash
attachments, or public evidence receipts. Do not introduce clipboard monitoring.
An explicit user export is a distinct action with its own review; retention does
not authorize export.

The default forbids backups and cross-device synchronization of these candidates.
A later durable design must specify OS backup exclusions, encryption keys in
platform secure storage, device-lock behavior, expiry while the app is suspended,
key loss, reinstall/restore, secure deletion limits, and compromise recovery.
Deleting a gateway must delete its retained drafts/markers and revoke any local
attachment permission owned for that retention; it must not delete Agent data.

## Decision required before storage work

Review draft content, attachment metadata, and metadata-only viewport durability
as separate choices. Acceptance must define maximum counts/bytes/age, explicit
enable/disable/delete controls, encrypted storage and key ownership, backup and
export policy, migration and deletion tests, and named-platform qualification.
Then write a separate implementation plan and update the existing
[security decision](../adr/security-and-privacy.md) and
[threat model](../security/threat-model.md) if the accepted policy changes them.
This proposal changes neither document and grants no storage authorization.
