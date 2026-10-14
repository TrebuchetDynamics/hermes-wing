# Desktop connection paths

Status: pinned official-source comparison and bounded offline Wing acceptance,
not full Desktop parity or native/live connection qualification.

This comparison replaces the withdrawn separate-app research. Historical Wing
receipts remain evidence of their named checks only; they do not establish what
the official Desktop implements. See [reference authority](../quality/official-desktop-reference.md).
[Product requirements](prd.md#connection-path-requirements) retain the accepted
Local / SSH / Remote outcome, with explicit platform and security adaptations.

## Source and transport boundary

Inspected read-only Hermes Agent revision:
[`158fd638da1629c8e62caf9ade1515d162def8ab`](https://github.com/NousResearch/hermes-agent/tree/158fd638da1629c8e62caf9ade1515d162def8ab).
Official `apps/desktop` tree: `2038178ee53e13cde6fe297daa2484a868e7d3a3`.
The checkout was clean before inspection; no reference was updated, modified,
installed, launched or tested. These are checkout identities, not latest-release
claims. Source paths below are relative to this Agent revision; line ranges and
nearest tests were inspected, not executed.

Official Desktop is an Electron/React chat surface over headless `hermes serve`
and `apps/shared` JSON-RPC. Local backends are pooled by connection/profile;
remote chat uses `/api/ws`. The narrow older-runtime fallback is `dashboard
--no-open`, not the dashboard frontend. See `apps/desktop/src/AGENTS.md`:6–34
and `apps/desktop/electron/backend-serve-support.test.ts`.

Wing production instead enrolls
[`HermesApiChannel`](../../lib/features/hermes_chat/providers/hermes_channel_provider.dart),
with direct Agent HTTP reads and exactly advertised REST/SSE operations. Its
[connection bootstrap](../../lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart)
reads health, capabilities and scoped sessions before reporting connected.
Internal native-web qualification clients are not production enrollment.
Similar URLs, shared Agent internals or Desktop session-token/OAuth success do
not prove bearer, operation, grant, profile or session compatibility. A configured
Desktop `serve` URL alone is not proof that it exposes Wing's required API.
Never add an RPC, shell, credential-discovery or management fallback to hide this gap.

## Official welcome, Local, SSH and Remote trace

Abbreviated official paths in this table are within `apps/desktop/`; component
siblings share `src/components/`, and Remote setup siblings share
`src/components/remote-setup/`.

| Outcome | Official implementation and nearest tests | Retained Wing path and explicit difference |
| --- | --- | --- |
| Initial setup choice | `apps/desktop/src/components/desktop-install-overlay.tsx`:443–520 offers **Connect to existing Hermes** and a state-dependent Local card, not a three-button Local/SSH/Remote welcome. `desktop-install-local-card.ts`:13–37 selects install vs use-local presentation. `desktop-install-overlay.test.tsx`:94–166 checks choice, deliberate local start and recoverable missing bridge. | [Welcome](../../lib/features/enrollment/widgets/hermes_welcome.dart):78–126 uses **Get Started**, **Connect via SSH**, **Remote server**; [enrollment](../../lib/features/enrollment/screens/hermes_enrollment_screen.dart):50–52 opens the shared Add form. This retained hierarchy is an accepted Wing outcome, not official wording/layout parity. |
| Local preparation | `desktop-install-overlay.tsx`:476–486 invokes `continueBootstrapLocal`; :523–579 has manual installation/docs/retry for unsupported installer platforms. `electron/local-backend-lifecycle.ts`:77–116 owns spawn/shutdown; nearest `local-backend-lifecycle.test.ts` and `backend-serve-support.test.ts` exercise lifecycle and command compatibility. | [Local panel](../../lib/features/hermes_chat/widgets/platform_local_connection_panel.dart):85–120,162–190 inspects Linux directory metadata and offers deliberate folder selection. It neither reads Agent files nor starts/installs a runtime or selects a Project. Existing [Local setup route](../../lib/features/local_setup/screens/local_hermes_setup_screen.dart) reuses direct authentication. Full managed-local parity remains a gap. |
| SSH acquisition and trust | `apps/desktop/src/app/settings/gateway-settings.tsx` owns SSH host/user/port/key-path/remote-runtime/profile fields, host suggestions and Test. `electron/ssh-config.ts`:72–173 reads aliases/Includes and parses effective OpenSSH config. `electron/ssh-connection.ts`:1–24,238–286 uses system OpenSSH, inherited config/agent/jump hosts, `BatchMode=yes` and `StrictHostKeyChecking=accept-new`; no interactive programmatic password/passphrase prompt. `ssh-connection.test.ts`:154–211 checks policy, identity args and loopback forwarding; `ssh-config.test.ts` covers config parsing. | [SSH form](../../lib/features/hermes_chat/widgets/managed_ssh_connection_form.dart) exposes deliberate Password / Private key, bounded native picker, encrypted-key passphrase, generated/saved Wing key and public-only copy. [Panel](../../lib/features/hermes_chat/widgets/managed_ssh_connection_panel.dart):53–69 requires fingerprint review; it does not inherit OpenSSH config, SSH-agent or jump-host support. These are explicit native/security adaptations, not a port of Desktop's key-path UX. |
| SSH Test and runtime | `electron/main.ts`:10729–10811 creates an isolated SSH probe, detects remote platform, locates/probes Hermes and checks ownership support; timeout alone gets one bounded retry. It is not the withdrawn app's forwarded-health test. :10164–10182 scopes bootstrap, :10299–10317 connects the remote lifecycle and forward, :10354–10425 fences publication and builds the authenticated connection. `electron/ssh-bootstrap-coordinator.test.ts`, `remote-lifecycle.test.ts` and `windows-remote-lifecycle.test.ts` are nearest lifecycle/ownership tests. | [Native Dart forward](../../lib/core/hermes/ssh/ssh_forward_io.dart):17–25,73–164 authenticates SSH, reviews the host key and binds an ephemeral loopback listener; :174–218 forwards only to remote loopback Agent port. [Controller](../../lib/features/hermes_chat/providers/managed_ssh_connection_controller.dart):35–116 then authenticates the separate Agent channel. No remote exec, bootstrap, restart, installation, discovery of tokens or durable forwarded-origin save. SSH authentication alone is not Agent readiness. |
| Remote authentication and Test/Apply | `remote-setup/first-run.tsx`:16–38,55–72 separates Back, Test and Apply. `use-remote-setup.ts`:68–74,110–155,201 binds auth mode and exact first-run test payload. `electron/main.ts`:10662–10726 probes public status/providers; :10823–10879 tests real authenticated HTTP plus WebSocket. :16863 onward gates native login on supported auth flows. `use-remote-setup.test.tsx`:30–89,92–160 rejects stale probe/login/test results; `electron/remote-oauth-ticket.test.ts` checks ticket resolution. | [Add form](../../lib/features/hermes_chat/screens/state/hermes_chat_layout.dart):153–245 groups **Local / SSH / Remote**, with Remote HTTPS and VPN subchoices. [Connect/save](../../lib/features/hermes_chat/screens/state/hermes_chat_connection.dart):378–453 uses current form/owner leases and secure persistence, then returns ownership to the directory. HTTPS validates certificates/origin; non-local HTTP credential use needs explicit trusted-network consent. Remote browser OAuth/PKCE/cookie-to-WebSocket acquisition is not enabled or qualified by this form. |

Official Desktop's first-run choice does not expose SSH as a third welcome card
in this inspected revision; SSH is a connection-mode/settings path. Do not rename
the withdrawn Welcome/App/IPC/tunnel citations into official evidence. Desktop
bootstrap is scoped, not the withdrawn single global fixed-port tunnel. Wing must
not copy Desktop's privileged remote lifecycle or installation techniques without
an eligible reviewed Agent contract; [Agent immutability](../adr/runtime-and-delivery.md#hard-boundary-never-modify-hermes-agent)
still applies.

## Current Wing controls and privacy

Android welcome deliberately orders SSH, Remote, then **Use this phone (Termux)**.
The Add form uses the same order; Linux/web retain Local, SSH, Remote. Remote
preserves a selected VPN subchoice. Android Local is a manual staged guide in a
separate Termux sandbox with fixed `http://127.0.0.1:8642`; guide completion does
not assert readiness. Browser raw-TCP SSH is explicitly unavailable. Web Local is
an explicit reachable endpoint, not browser host discovery or lifecycle authority.

### Private-key UX: Desktop reference and Wing adaptations

Selected imported private-key content is bounded to 64 KiB including streamed
bytes, remains attempt-scoped and is cleared on failure/cancel/disposal. Generated
Ed25519 identity has a separate versioned platform-secure-storage slot; generation
validates readback and reuses an existing valid identity without replacement.
Only its public key is copied. See [selection](../../lib/features/hermes_chat/ssh_keys/managed_ssh_key_selection.dart),
[generated store](../../lib/features/hermes_chat/ssh_keys/managed_ssh_generated_key_store.dart)
and [copy guard](../../lib/features/hermes_chat/widgets/managed_ssh_connection_form.dart).
Native picker, secure-storage persistence and real host login remain unqualified.

Wing Link client/service/installers/bundling and legacy consumers are removed,
not pending work or an optional setup path. Legacy intent/share/`step=pair`
input is discarded with generic direct-reconnection guidance; it is not parsed,
exchanged or displayed. Saved Agent credentials and endpoint/profile/session
identities survive; raw legacy records and secure slots remain inert and preserved.
Missing Agent credentials require direct reauthentication. Changed origins must
not borrow another origin's credential. Cancellation keeps the caller's owner/draft.

Reconnect restores the exact saved host/profile/session through directory owner
leases; it never replays Send, create, approval, Stop or configuration mutations.
The [delivered restoration correction and remaining acceptance](../quality/session-restoration-caller-admission.md)
record the missing-entry-guard repair separately from these public controls. It
was already delivered before this batch; no second production correction is needed.

## Acceptance and remaining gaps

The [offline acceptance receipt](../quality/session-restoration-caller-admission.md#remaining-official-connection-acceptance)
maps the existing public-control/security tests, render evidence, source/dependency
pins and exact commands. Linux-hosted widget tests exercise platform overrides,
not Linux GTK/Android native plugins or a live Agent/provider. Public controls
pass within those fixtures; that is not full Desktop product parity.

Remaining gaps are explicit: official setup wording/hierarchy and managed-local
lifecycle fidelity; Desktop OpenSSH config/agent/jump-host behavior; eligible
production native JSON-RPC/auth acquisition; Remote OAuth; durable SSH relaunch
identity/trust recovery; approved Linux/Android host/device authentication and
secure-storage/picker qualification; real inference and full three-path/recovery
qualification. Missing exact Agent operations remain unavailable. This batch does
not close `CONNECTION-PATHS`, canonical TODO/goals, installation, native/live or
release acceptance, and does not merge or publish its local candidate.