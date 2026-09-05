# Guided enrollment

`/enroll` lives outside the authenticated shell. A user can arrive without an
Agent endpoint, through an explicit handoff, or while adding another host.
`/enroll?step=pair` opens the pairing step after local setup. The query contains
only navigation state, never a handoff, credential, host address, or pairing code.

## Journey

The opening question offers three outcomes rather than a list of transfer methods:

- **Use this phone** on native Android (or local setup on native Linux).
- **Use another computer** for a Linux host reached through a trusted VPN.
- **I have a QR code or pairing link** for an existing host.

Manual Agent credentials appear inside pairing as an advanced, single-profile
alternative. That path does not import Wing Link management access.

### This phone

The Termux guide has three steps: prepare Termux, run the verified setup command,
and return to Wing to pair. It keeps the existing release/source-pinned bootstrap
metadata validation, explicit clipboard action, and failure-closed copy control.

An existing healthy Agent is reused through that same bootstrap. Wing cannot
inspect another Android app's files and does not request Termux command access.
“Termux is showing the pairing link” acknowledges what the user sees; it does not
claim that Wing has verified an installation. The last step offers pairing and a
way back to the setup command if the service stopped or the handoff expired.

Native Linux retains actual `wing-link inspect --json` detection and locally
approved `setup --json`, now with progress from the existing bounded operation.
Its completion action enters pairing directly. No new installer protocol or
remote execution surface was introduced.

### Another computer

Four steps cover prerequisites, installation/adoption, provider/model setup, and
VPN pairing. An existing Wing Link installation selects inspect/setup commands;
otherwise the guide uses the established repository installer. Public commands
can be copied explicitly. The guide never reads a clipboard in the background.

Advancing a step acknowledges work performed on the host. It neither runs a
remote command nor marks that host verified. Previous-step navigation preserves
the installation choice, and back returns through the guide. The last step enters
pairing. A live handoff can interrupt the guide and open review immediately.

See the [computer setup runbook](../runbooks/android-hermes-setup.md) and
[phone setup runbook](../runbooks/android-termux-local-agent.md).

### Pair and verify

Paste works on every platform. Native Android also offers live QR scanning and
QR-image import. Explicit links and Android shares retain the same ingress.
A bounded, obscured input field provides a fallback when clipboard APIs fail.
Raw input is cleared before parsing/inspection and when dismissed; it is not
persisted, logged, analyzed, or included in errors.

The existing transaction remains inspect → review → exchange → verify management
identity → verify direct Agent access → securely save → acknowledge registration.
The UI exposes these stages while confirming. It does not auto-confirm a host,
merge credentials, weaken TLS/pinning, or bypass local approvals.

Recovery distinguishes clipboard, scanner, image, network, timeout, TLS, refused
handoff, unsupported operation, invalid response, secure-storage, direct Agent,
and management/registration failures. Only bounded categories are rendered, not
exception messages, URLs, credential bytes, or raw responses. Failed handoffs are
not silently replayed. A fresh handoff still requires review.

### Saved connection and readiness

“Paired” means credentials were securely saved and required registration was
acknowledged. It does not imply that the follow-up activation succeeded.
Connection retry uses the saved endpoint and never repeats enrollment exchange,
acknowledgment, or secure enrollment writes.

The final screen distinguishes saved credentials, the live connection, and
Agent-reported model configuration. It checks the enrolled endpoint identity and
exact authorized detailed-health capability before using model readiness. An
unrelated active endpoint, absent capability, or missing readiness field produces
“not reported,” never a ready claim. A configured model does not prove provider
authentication or successful inference; the screen says so and offers a fresh
connection check, Chat, and profile navigation.

The authoritative evidence is Agent's authenticated `/health/detailed` readiness
model check (`gateway/platforms/api_server.py`, `gateway/readiness.py` in the
read-only Agent checkout), Wing's existing capability-gated channel loading, and
regressions in `hermes_enrollment_journey_test.dart`.

## Why the first redesign was insufficient

It grouped controls and added computer instructions, but users still had to
assemble the journey themselves. It retained an undifferentiated transfer-method
list, a long Termux instruction page, generic failures, and a success message
that conflated pairing with readiness. The current flow replaces those gaps with
explicit choices, staged setup, transaction progress, actionable recovery, and
separate readiness evidence.

## Qualification limits

- Computer host setup describes Linux/systemd-user. Native Windows/macOS host
  installation remains unqualified.
- Termux background execution is best-effort; Android can suspend or kill it.
- Browser pairing requires normally trusted HTTPS. Self-signed Wing Link hosts
  require the native client's reviewed pinning flow.
- Existing-profile provider configuration remains a Hermes host action. No
  compatibility configuration API or shadow model state was added.
- OmniRoute installation remains optional future work. An installer needs its
  own reviewed verification, local approval, health, and rollback contract. The
  UI does not promise free or unlimited models.

## Completion evidence

| Requirement | Evidence |
| --- | --- |
| Outcome-based entry | Phone/computer/pairing choices in `HermesEnrollmentScreen`; native router and Chromium enrollment tests. |
| Install or reuse through existing contracts | Termux command/metadata tests; Linux consent, inspect/setup, and progress wiring; computer guide uses the existing installer and fixed local CLI commands. |
| Return from setup to pairing | Android phone and Linux manual-connection return-path regressions in `app_router_transitions_test.dart`. |
| QR, image, paste, and typed handoffs | Existing payload/flow/intent tests plus the typed clipboard-failure recovery test; raw input clears before review. |
| Explicit trust review and persistence | Existing exchange, identity, cancellation, pending-credential, and secure-store regressions retained. |
| Actionable bounded errors | Transport/status classification tests and phase-specific recovery; raw exception messages never become UI text. |
| Separate pairing and readiness | Saved-connection retry and cancellation tests; readiness tests reject unrelated endpoint state and unadvertised model checks. |
| Accessible journey | Narrow Android layouts at 200% text; browser command semantics and computer journey; visual inspection at 420 × 900 and desktop width. |

Physical Android installation, Termux process survival, native QR hardware, live
VPN pairing, and successful model inference were not exercised. Deterministic
evidence here establishes client behavior, not those platform qualifications.

### Validation commands

- `flutter gen-l10n`: generated localization outputs from `app_en.arb`.
- `dart format --output=none --set-exit-if-changed lib test integration_test`: 329 files, unchanged.
- `flutter analyze`: no issues.
- `flutter test --concurrency=1`: 1,567 passed on the frozen implementation.
- `flutter test test/router/app_router_transitions_test.dart`: 10 passed, including both local-setup return paths.
- `(cd wing_link && go test ./...)`: passed.
- `flutter build web --release -t lib/main_e2e.dart`: passed, including the Wasm dry run.
- `PORT=8987 HERMES_E2E_PORT=8988 npm run web:e2e`: 46 passed; one opt-in live Agent smoke skipped.
- `npm audit`: no vulnerabilities.
- `README_ASSET_BASE_URL=http://127.0.0.1:8997/ npm run readme:assets`: completed against the independent local fixture; tracked assets unchanged.
- `git diff --check` and changed documentation local-link checks: passed.

The first browser run found inaccessible command text in a nested selectable
widget. Reusing the route's selection area fixed it. The setup return-path tests
also reproduced the chooser-return bug before the explicit result-handling fix.
