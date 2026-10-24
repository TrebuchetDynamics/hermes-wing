# Guided enrollment

`/enroll` lives outside the authenticated shell. A user can arrive without an
Agent endpoint, through an explicit handoff, or while adding another host.
`/enroll?step=pair` rejects deprecated handoffs with generic direct Agent guidance, not a pairing review or Local setup return. The query contains
only navigation state, never a handoff, credential, host address, or pairing code.

## Desktop connection-path alignment

The [connection requirements](prd.md#connection-path-requirements) require direct
Agent entry without Wing Link prerequisites. The default welcome no longer offers
**Use another computer** or **I have a QR code or pairing link**, and no longer
constructs the computer setup guide. Its primary actions reuse the existing
**Add Hermes** form and direct Agent connection modes.

Android follows the accepted owner correction: **Connect via SSH** first,
**Connect to Remote Hermes** second, **Use this phone (Termux)** third, as distinct
actions. SSH and Remote open their corresponding existing connection forms;
Termux opens the unchanged manual on-phone guide. Android does not present the
desktop Local/Get Started action ahead of SSH. Desktop/web retain Get Started,
SSH and Remote; native Linux retains Local setup in a separate disclosure.
Remote retains its HTTPS/VPN choices. This slice changes entry presentation, not
installation, managed SSH, packaging or platform qualification.

Reuse the direct Agent channel and secure endpoint storage, not a mandatory
management exchange. Explicit legacy handoffs are discarded without parsing or exchanging them.
Reconnect through the direct Agent controls; saved records are not migrated or deleted.
Missing Agent APIs must leave affected features unavailable with an explanation.
No new backend, shadow state or broader compatibility adapter is authorized.

Connecting through SSH must not create credentials, install a management service
or restart Agent.
Keep the manual single-profile Agent connection available. See the
[Desktop comparison](desktop-connection-paths.md) for source evidence and limits.

## Android gateway sign-in (candidate)

The Android **Connect to Hermes Desktop** flow uses manual HTTPS address/profile
entry and browser sign-in. At the owner's request, QR creation and scanning were
removed from the connection screens. Existing saved gateway identities and secure
credentials are preserved; legacy handoffs remain rejected.

The phone opens its own system browser for the gateway's advertised `native_pkce`
login. Tokens remain origin-bound in secure storage, and a fresh WebSocket ticket
and advertised chat capabilities are still required. Reconnect does not replay
prompts or approvals. An existing reachable HTTPS gateway remains required;
Wing does not start Agent or configure networking. Historical QR fixture results
below do not describe the current login UI.

### Simplified SSH entry

The default form shows host/SSH port, username, password or private key, and the
Agent token, followed by Connect/Cancel. Optional Agent port/profile, transport
selection and destination save/load are under **Advanced**. Their defaults,
validation and saved values are preserved. An invalid hidden port or profile
reveals Advanced rather than permitting a connection. Saving credentials remains
opt-in, and the host-key verification dialog is unchanged.

### Offline reconciliation

MOBILE-GATEWAY-SIGNIN rechecked the existing implementation at Wing baseline
`7bac44af16829ee5aacfdd642bf85205967d7e4f` on Linux, without changing runtime code
or tests. Flutter **3.44.2** (Dart **3.12.2**) passed dependency resolution with
`flutter pub get --enforce-lockfile`, all **21** focused tests below, and
`flutter analyze --no-pub`:

```sh
flutter test --no-pub --concurrency=1 test/core/hermes/auth/native_gateway_auth_test.dart test/core/hermes/auth/secure_gateway_token_store_test.dart test/core/hermes/setup/hermes_gateway_invite_test.dart test/core/hermes/channel/hermes_remote_gateway_test.dart test/features/enrollment/gateway_https_flow_test.dart test/features/enrollment/gateway_login_entry_test.dart
```

These retained tests cover callback/cancellation rejection, S256 exchange, explicit
refresh, exact-origin secure persistence, metadata-only invitation validation and
fixture HTTPS/WSS negotiation without implicit prompt replay. They use synthetic
credentials, mock secure storage and Android presentation overrides, not Android
hardware or an actual system browser.

`flutter build web --release --no-pub -t lib/main_e2e.dart` passed the JavaScript
build, with existing `flutter_tts` Wasm dry-run incompatibilities and a missing
Cupertino font warning. It does not qualify Wasm or Android browser login.
`git diff --exit-code -- pubspec.yaml pubspec.lock` confirmed unchanged dependencies.

On Node **22.22.2**, plugin artifact reproducibility, syntax and all **5** VM tests
passed, including independent decoding of all three QR examples with **zbarimg
0.23.93**. The initial missing-PATH failure was resolved with a user-space decoder
in the shared tool cache; verification must expose that binary on PATH too. See
[plugin prerequisites and commands](../../desktop_plugins/wing-connect/README.md#source-and-validation).
No full-suite result is claimed here; the coordinator owns the merged-tree gate.

Remaining qualification is separate: actual Desktop plugin installation, physical
Android camera and system-browser login, platform secure persistence/refresh and
cancellation, and a reachable live HTTPS gateway with valid certificates, fresh
WSS tickets, exact-session recovery and deliberate generation without replay.
No device installation, live-account/provider call, service setup or deployment
was performed.

## Journey

Choose a direct Agent action, complete its existing authenticated form, or cancel
back to welcome. Opening or cancelling an entry does not save a connection or
exchange management credentials. Existing saved records and selected
host/profile/session ownership remain unchanged; restoration never replays sends.

The default chooser does not construct or invoke a Wing Link management client.
Linux and Termux Local setup now reuse the direct Agent form, without installation
or pairing completion. Explicit `/enroll?step=pair` and Android intent/share ingress now show generic
reconnection guidance, with no controller construction or Link operations.
The client, service, bootstrap installers and delivery dependencies are removed.
Historical records remain inert; personal installed services are untouched.

### Local preparation and authentication

Termux uses the manual preparation guide and direct Agent authentication delivered
by the preceding retirement slice. Wing cannot inspect another Android app's files
and does not request Termux command access.

Linux `/setup/local` now composes the same existing Local form. It checks default
Hermes-home directory metadata and offers deliberate alternative folder selection.
The selection is ephemeral: no Agent files are read, no Project is selected, and
the runtime is not bound to the discovered home. Prepare/start Agent separately,
then enter its API token in the masked form. Discovery is not installation,
authentication or model readiness. No installer, service starter, management
request or pairing return is constructed, including after Agent denial.

AppBar Back and platform cancellation return to the pushed caller; standalone
Back returns to welcome. Neither changes saved endpoints, credentials or active
profile/session ownership. An explicit direct-auth retry remains in the existing
connection owner and never replays an Agent mutation.

### Access preparation assistance

Direct Local/Remote token entry and localized native SSH API-token entry offer
**I need access to Hermes**. The token step of the guide and discovery denial
also expose this help. Users can preview and explicitly copy a fixed public
request for their existing Hermes chat/operator, or open official API-server
documentation. No form values or credentials enter the request; nothing is sent
automatically and the connection draft remains unchanged on close.

This is preparation guidance, not automatic enrollment or credential acquisition.
The host operator still controls setup and authorization; users enter credentials
only in the masked field. Browser sign-in is separate from these API-token forms;
the Android native-gateway candidate above owns its PKCE flow. See
[bounded delivery evidence](../../tasks/items/CONNECTION-ACCESS-ASSISTANCE.md).

### Deprecated handoff rejection

Cold and warm Android intent/share ingress is recognized from action, data
presence and MIME-type metadata only. Native code discards the external intent
before forwarding an ordinary launch to Flutter or plugins; it never reads URI
contents or shared text. Only a one-shot boolean notification crosses the native
bridge. The parser, QR scanner/image importer and their Dart/native APIs are
removed, not dormant connection methods.

The UI never displays incoming contents or origins, reads the clipboard or
contacts Link. Malformed and expired inputs receive the same bounded guidance.
Choose connection options to reconnect through Local, SSH or Remote (Android:
SSH, Remote, then Termux).

WingApp alone consumes incoming notifications; mounted enrollment screens do not
subscribe or mutate their caller state. Warm handoffs are pushed above the current
route so cancellation preserves its welcome, direct form or mounted Chat draft.
Back/Cancel returns to that caller; a standalone legacy route
returns to welcome. Direct options replace only the enrollment page. No saved
credentials, records, active Agent endpoint/profile/session or sends are changed
by rejection. No handoff is replayed on a later enrollment visit.

## Qualification limits

- Wing does not install or manage a host runtime.
- Termux background execution is best-effort; Android can suspend or kill it.
- Browser Agent connections require normally trusted HTTPS; native SSH verifies
  the host fingerprint.
- Existing-profile provider configuration remains a Hermes host action. No
  compatibility configuration API or shadow model state was added.
- Wing does not bundle or manage optional model gateways. Configure provider
  access through Hermes Agent; the UI does not promise free or unlimited models.

## Historical completion evidence (before default-entry retirement)

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

These receipts describe the earlier chooser, not this candidate's qualification.
Current candidate checks and source fingerprints are recorded on card t_22e074db.

### Historical validation commands

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
