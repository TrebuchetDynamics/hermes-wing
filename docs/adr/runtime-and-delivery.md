# Runtime and delivery

Status: current decision

## Decision

Hermes Agent remains an external authoritative runtime. Hermes Wing packages may
include Wing Link, but never embed Hermes Agent or create a second domain backend.

Wing Link is the authenticated remote management plane on the Hermes host. It
owns installation/adoption, pairing, lifecycle, health, diagnostics, host
integration, and explicitly approved directory grants. Wing talks directly to
Hermes Agent for chat and all supported Agent APIs.

When a supported Agent lacks a required remote contract, Wing Link may delegate a
reviewed **typed compatibility operation** to the installed Hermes CLI. Each
operation must use a fixed executable and argument shape, bounded machine-readable
output, no shell, explicit authorization, and no shadow state. The current
exception covers profile list/create/rename/delete plus transactional new-profile
description, allowlisted provider/model setup, stdin-only provider credential
input, and a bounded readiness probe. Existing-profile configuration, Hermes
Project, and general provider operations remain blocked; arbitrary commands,
config keys, and paths remain prohibited.

A profile's repository is represented as an Agent-owned per-profile Hermes
Project. Wing Link may translate an approved opaque directory handle into a path
for a fixed Project operation. It must not create a separate profile `workdir`
store or invoke global `profile use`/`project use` state.

Listeners stay on loopback plus at most one local private-LAN/Tailscale interface.
The current HTTP service may auto-select that interface; non-loopback plaintext
requires explicit client review and should run inside an encrypted VPN or behind
trusted HTTPS. Remote access requires a separate revocable Wing Link credential.
Hermes API credentials are never accepted by the management listener.

Runtime and application artifacts must be versioned and verified before
activation. Platform and service support require real target evidence; a
cross-compiled binary is not a qualified service.
