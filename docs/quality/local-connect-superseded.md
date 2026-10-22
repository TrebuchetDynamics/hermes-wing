# Local-connect draft disposition

The owner-approved mobile gateway PKCE authentication direction supersedes the
unfinished local credential-file acquisition draft. This is a disposition record,
not evidence that mobile gateway authentication is implemented or qualified.

Reconciliation of the two untracked drafts on `wt/local-connect`:

| Draft under `lib/core/hermes/setup/` | Disposition |
| --- | --- |
| `local_hermes_credential_platform_io.dart` | Privately archived and removed; not shipped. |
| `local_hermes_credential_probe.dart` | Privately archived and removed; not shipped. |

Both drafts were incomplete and unused by tracked code: they attempted naive
`.env`/YAML reads, referenced a missing unsupported-platform implementation and a
nonexistent factory, and had no functioning regression tests. Their comments did
not establish an approved credential-reading boundary.

Both complete source files were preserved outside the repository with owner-only
permissions and source/archive SHA-256 equality verified before removal. Counts:
2 drafts inspected, 2 archived, 2 removed, 0 draft implementations integrated,
0 unresolved draft files. The private recovery manifest retains original source
paths, byte counts, hashes and branch/HEAD identity; private host paths are not
published here. Archival preserves work; it is not integration or acceptance.

Existing [local discovery](../product/routes.md) remains directory-metadata-only.
No Agent secret/configuration files were read or executed during this cleanup;
no credential-file acquisition was completed. Agent state, saved credentials and
runtime were untouched. The [security decision](../adr/security-and-privacy.md)
and [runtime boundary](../adr/runtime-and-delivery.md) remain unchanged. Future
authentication work must use supported, unmodified Agent contracts and obtain its
own implementation, security and platform qualification evidence.
