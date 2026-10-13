# Gateway, profile, and Project management

Status: Agent-only client

## Identity and authority

A saved host is one canonical Hermes Agent origin. Profile names are local to
that origin; colliding names on different hosts are not interchangeable.
Endpoint/profile/session and credential identities stay explicit. Saved legacy
records are preserved but never used to construct a management connection.

## Current profile path

Profiles uses the selected Agent channel and exact advertised lifecycle operations,
with per-operation grants and current resource identity. Missing operations show
unavailability, not a compatibility CLI/catalog fallback. Creation, rename and
deletion do not change the active Chat owner implicitly. Destructive actions retain
confirmation and owner fences; reads confer no mutation authority.

## Repository and subfolder assignment

Hermes Projects remain Agent-owned per-profile workspaces. Project creation remains
unavailable without an exact authoritative operation. Project-aware Chat is separately
gated; no Wing workdir, opaque management directory browser or hidden global Project
selection is offered. Linux Local's folder chooser selects discovery metadata only,
not a Project or conversation working directory.

## Provider and model behavior

Use the Agent's exact advertised inventory and mutation operations. Catalog reads
never grant provider writes. Credentials remain write-only; unavailable secret-safe
contracts remain unavailable. No management service or shadow catalog is present.

## Troubleshooting

Use the direct connection's explicit Test/Retry and verify the selected origin,
profile and Agent credential separately. A missing credential requires direct
reauthentication. Changed origins do not inherit another origin's credential.
See [direct connection](../getting-started.md#direct-agent-connection) and
[capability policy](hermes-compatibility.md).
