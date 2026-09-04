# Notification contract proposal

Status: proposal only, 2026-09-04. No enrollment, relay, push SDK, credentials,
delivery support, or new Agent endpoint is implemented by this document.

Hermes Agent remains the authority for sessions, runs, approvals, and
clarifications. An optional advertised Agent plugin/account service could own
device enrollment and routing. An explicitly selected relay would transport
minimal delivery data. Wing Link has no notification or decision-plane role.
This responsibility split requires review before implementation.

## Enrollment and trust

Enrollment requires explicit opt-in, an authenticated Agent connection, exact
advertised enrollment/routing operations and grants, and OS notification
permission. Show the relay operator and normalized public origin before consent;
offer a self-hosted operator with the same contract and security requirements.
Permission denial leaves chat and foreground status usable and creates no
background retry loop.

Generate a separate per-device enrollment credential; never reuse Agent or Wing
Link bearer credentials. Store it and the platform delivery token only in secure
storage. The enrollment service binds the device, intended Agent, exact grants,
relay identity, and token revision. Token rotation replaces the previous token
atomically. A relay change requires new consent and enrollment, then revokes the
old registration and pending handles. Device revocation is independent of other
devices and invalidates its credentials, tokens, and unresolved handles.

Native relay connections require HTTPS, reviewed origin binding, TLS and pin
policy, and explicit trust review for identity changes. A custom relay URL does
not bypass these requirements. Reject URL credentials, query strings, fragments,
origin-changing authentication redirects, and script-injected credentials.
Browser clients require normally trusted HTTPS and cannot implement native TLS
pin overrides. No embedded WebView login or broad navigation trust is proposed.
Exact platform trust provisioning remains an implementation gate.

## Payload and lifetime

The application payload contains only a cryptographically random opaque routing
handle and one category: `approval_pending`, `completed`, `failed`, or
`background_activity`. Use generic localized lock-screen text. No prompt,
transcript, recognized speech, tool arguments, profile names, private hostnames,
provider values, credentials, or raw session/run IDs enter the payload. Transport
delivery tokens remain private service metadata and are not application payload.

Proposed bounds: 256-bit random handles, maximum five-minute lifetime, at most
one pending handle per device/resource/category, and at most 64 unresolved
handles per device. Routing state is a temporary reference to Agent state, not
a transcript or parallel run store. Expire and delete the routing record at its
deadline, revocation, or redemption. Delivery failures do not extend lifetime.
Do not back up payloads, tokens, credentials, or routing records. Logs contain
only allowlisted aggregate category/outcome counters, never handles or resource
identity. Retention and operational rate limits require privacy review.

## Tap resolution and replay

Notification receipt, preview rendering, background fetching, and OS delivery
acknowledgment must not redeem the handle or mutate Agent state. A deliberate tap
authenticates the enrolled device and requests one bounded redemption. Bind
redemption to device, intended Agent, relay registration revision, handle, and a
client idempotency key. Only a retry of that same redemption may recover its
short-lived result; another device or different replay gets no resource details.
Wrong-device, revoked, expired, unknown, and already-consumed handles fail closed.
Apply bounded attempts per credential and device; repeated failure never starts
an automatic retry loop. Do not put handles in shared URLs, browser history,
clipboards, analytics, diagnostics, or exported text.

The trusted routing authority returns a reference to the intended Agent resource
only after authentication. Wing uses direct authenticated Agent reads to verify
current profile/session/run identity and grants. A tap is explicit navigation and
outranks automatic viewport restoration. It does not interrupt a run, submit
text, retry work, answer an approval, or send a clarification.

Deleted sessions show an unavailable-target message and explicit session
selection. Missing gateways require deliberate selection/pairing; never try a
similarly named host or session. Offline, denied-grant, relay-outage, and expired
cases offer bounded retry or foreground navigation without leaking target
metadata. A retry rechecks the same target and cannot silently become a mutation
after reconnect. Subsequent approval/clarification requires user review and the
exact direct Agent operation; the relay never transports decision content.

## Implementation and qualification gates

- Advertised Agent/plugin enrollment, routing, revocation, and lookup contracts,
  with explicit scopes and stable resource identity; no endpoint names are
  invented here.
- Reviewed privacy/retention policy, relay operator and self-hosted trust model,
  credential rotation, revocation, deletion, and rate-limit tests.
- Platform credentials and integration validated separately for Android and iOS;
  permission denial, token rotation, wrong-device and expired handles, duplicate
  taps, locked-screen privacy, process termination, foreground return, and
  background delivery tested on named physical targets.
- Exact built-artifact identity attached to delivery receipts. Simulator,
  deterministic fixture, or compilation results cannot qualify APNs/FCM delivery.

Any missing gate keeps notification implementation unavailable. See the
[implementation plan](../superpowers/plans/2026-09-04-provenance-and-notifications.md),
[API decision](../adr/api-and-state.md), and
[security decision](../adr/security-and-privacy.md).
