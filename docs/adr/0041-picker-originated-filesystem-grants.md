# ADR 0041: Require picker-originated filesystem grants

Status: accepted
Date: 2026-07-13

A Hermes Wing client never gains Hermes filesystem access by typing or submitting an arbitrary path. On a verified same-host desktop connection, the platform host adapter may use the native file or folder picker and register that explicit selection with Hermes Agent. Hermes returns an opaque resource handle and safe operator-approved label, not a path.

Remote, SSH-tunnelled, mobile, and web clients cannot register client paths. They upload bounded content or choose capability-advertised server workspaces represented by opaque handles.

## Grant shape

Every filesystem grant records its owning principal, profile, selected file or directory root, purpose, `read` or `read_write` access, creation time, expiry, and optional session binding. It is usable only through capability-advertised resource/workspace operations and does not itself widen Hermes tool permissions.

The default grant is session-bound and expires when the session, endpoint credential, or app connection ends. Persisting a profile-level grant requires a separate **Remember access** confirmation that names the safe label, purpose, access mode, and retention. Root filesystem, whole home/profile directories, credential stores, and other platform-sensitive roots cannot be remembered as broad grants.

Grant handles are unguessable, profile-bound, non-transferable between principals, absent from URLs, and excluded from client backups and analytics. Endpoint deletion, credential revocation, profile deletion, explicit removal, expiry, or a changed underlying filesystem identity revokes access immediately.

## Path safety

Hermes Agent validates the selected object before issuing a grant and anchors subsequent operations to the granted filesystem identity. Every access rejects traversal, absolute child paths, alternate separators, links or reparse points that escape the root, device files, sockets, and changed or missing roots. Platform implementations use anchored/no-follow operations where available and revalidate containment at use time rather than trusting a previously normalized string.

Directory listings are bounded and return handles plus safe metadata only. Hidden entries, recursive enumeration, writes, deletes, and executable content require explicit capability and policy. A `read` grant cannot be upgraded by a later request; the operator creates a new grant. Destructive writes require the domain's existing confirmation and revision rules.

Worktrees and generated files are created by Hermes Agent inside an approved `read_write` workspace. Clients receive workspace/resource handles and display labels, never server paths. Export-to-device remains a client download followed by a native save picker rather than a server path argument.

## Privacy and lifecycle

Raw selections may cross the loopback registration request only long enough for Hermes Agent to establish the grant. They are never returned in API responses or events and are excluded from request logs, errors, diagnostics, crash reports, analytics, clipboard actions, and notifications. Hermes Wing stores only the opaque handle and label; Hermes stores the canonical path with restrictive local permissions.

## Evidence

Desktop receipts cover file and folder grants, read/write separation, default expiry, remembered and revoked access, profile/principal/session isolation, endpoint deletion, traversal, symlink/reparse-point swap, root replacement, hidden and oversized enumeration, sensitive-root rejection, worktree containment, remote path-registration rejection, and zero raw paths in responses, logs, diagnostics, or screenshots.
