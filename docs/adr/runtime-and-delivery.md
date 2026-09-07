# Runtime and delivery

Status: current decision

## Decision

Hermes Agent remains an external authoritative runtime. Hermes Wing packages may
include Wing Link, but never embed Hermes Agent or create a second domain backend.

### Hard boundary: never modify Hermes Agent

Decision: accepted on 2026-09-07; non-negotiable for all Hermes Wing work.

Hermes Agent itself must never be modified for Wing. This applies to the
`hermes-agent/` reference checkout, installed runtimes, and any copied or forked
Agent source or distribution. No source/test edits, patches, monkey-patches,
injected replacement internals, or Wing-specific Agent builds are permitted.
Missing APIs, bugs, test failures and user-interface parity are not exceptions;
do not ask for an upstream-edit exception as a way to unblock Wing work.

Implement changes in Hermes Wing or Wing Link, using only supported, unmodified
Agent contracts and the reviewed compatibility boundaries. If those contracts
cannot safely provide an operation, keep it unavailable and explain the missing
capability. Do not bypass this rule with direct Agent-file/database edits or
shadow domain state. Reference source and tests may be inspected read-only.

This does not prohibit explicitly authorized installation/update of unmodified
upstream releases or normal Agent-owned state changes through supported APIs and
reviewed fixed CLI operations. Existing security, approval and validation gates
still apply; runtime state is not permission to alter Agent implementation.

This decision supersedes the earlier proposed upstream implementation checkpoint
in the provider design. Future upstream capabilities may be evaluated when
available; implementing them in Hermes Agent is not Wing's work.

### Management and compatibility

Wing Link is the authenticated remote management plane on the Hermes host. It
owns installation/adoption, pairing, lifecycle, health, diagnostics, host
integration, and explicitly approved directory grants. Wing talks directly to
Hermes Agent for chat and supported Agent APIs, except the explicitly scoped
[setup catalog read](api-and-state.md#provider-model-setup-catalog) through Wing Link.

When a supported Agent lacks a required remote contract, Wing Link may delegate a
reviewed **typed compatibility operation** to the installed Hermes CLI. Each
operation must use a fixed executable and argument shape, bounded machine-readable
output, no shell, explicit authorization, and no shadow state. The current
exception covers profile list/create/rename/delete plus transactional new-profile
description, allowlisted provider and bounded model string setup, stdin-only
provider credential input, and a bounded readiness probe. Existing-profile configuration, Hermes
Project, and general provider operations remain blocked; arbitrary commands,
config keys, and paths remain prohibited.

The accepted next slice is the
[existing-profile provider compatibility direction](api-and-state.md#existing-profile-provider-compatibility-direction).
It is a design checkpoint, not an enabled compatibility operation; the conditions
there must be verified before expanding the current advertised capability set.

A profile's repository is represented as an Agent-owned per-profile Hermes
Project. Wing Link may translate an approved opaque directory handle into a path
for a fixed Project operation. It must not create a separate profile `workdir`
store or invoke global `profile use`/`project use` state.

Listeners stay on loopback plus at most one local private-LAN, NetBird, or Tailscale interface.
Loopback may use HTTP; every non-loopback listener uses TLS 1.3 tied to the durable
Wing Link host identity. Remote access requires a named, scoped, individually
revocable Wing Link credential. Hermes API credentials are never accepted by the
management listener.

Wing Link speaks the current and immediately previous protocol generation. Typed
compatibility adapters must record their authoritative Agent endpoint, supported
release window, and removal trigger; no adapter is permanent.

Android/Termux may host Wing Link and Hermes Agent only through an explicit user-run bootstrap
pinned to reviewed release artifacts. Both listeners remain loopback-only and use
best-effort background execution; this is not a managed-service qualification.
Hermes Wing does not request Termux external-command access.

An explicit local `wing-link setup --with-omniroute` may also install the
external OmniRoute model gateway. Its npm package and complete dependency closure
are integrity-locked; lifecycle scripts are disabled, installation is staged in
an owner-only version directory, and CLI readiness is checked before activation.
This option is not exposed through remote bootstrap requests. Installation does
not start OmniRoute, change Hermes provider configuration, or copy credentials
between the three systems. OmniRoute owns its own settings and credentials;
Hermes Agent remains the profile and chat authority.

Runtime and application artifacts must be versioned and signature/digest verified
before activation. Wing Link updates stage under versioned owner-only paths,
activate through a stable target, health-check locally, and restore the previous
version on failure. An empty production release-key set makes updating unavailable;
it never enables unsigned installation. Production service qualification is Linux
systemd-user first and requires restart, state-permission, activation, health, and
rollback evidence on Linux. A cross-compiled binary is not a qualified service.

Wing Link may perform a credential-free, read-only OmniRoute discovery at its
fixed host-loopback endpoint. The advertised `host.omniroute.discover` operation
requires acknowledged `health.read` authorization, uses a three-second deadline
and 64 KiB per-response bound, and follows no redirects or proxies. It returns
only a status enum; it never exposes discovered endpoints, credentials, provider
inventory, or arbitrary upstream bodies. Public identity and liveness checks do
not establish trust in the service or prove inference readiness. Remove this
compatibility discovery when Hermes Agent advertises equivalent host discovery.
