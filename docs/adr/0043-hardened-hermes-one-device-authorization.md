# ADR 0043: Harden Hermes One device authorization

Status: accepted
Date: 2026-07-13

Android, iOS, Linux, Windows, and macOS use the Hermes One OAuth 2.0 Device Authorization Grant (RFC 8628) through the system browser. This preserves Hermes Desktop's callback-free user outcome while removing its clipboard, hostname, and diagnostic exposure. Embedded webviews are prohibited.

## Authorization flow

Hermes One advertises the HTTPS device-code and token endpoints, verification origin, polling requirements, supported scopes, token lifetime, revocation, and optional refresh rotation. Hermes Wing accepts only the configured Hermes One authority and verifies that `verification_uri` and `verification_uri_complete` use its allowed HTTPS origin before opening either.

Hermes Wing requests one short-lived device authorization at a time using a generic, non-unique label such as `Hermes Wing on Android`; it does not submit the hostname, endpoint identity, profile name, hardware identifier, analytics identifier, or advertising identifier. The system browser opens `verification_uri_complete`. The app may display the user code for visual confirmation but never copies, shares, persists, logs, announces in diagnostics, or places it in a Hermes Wing URL.

Polling follows the server interval, `slow_down`, expiry, denial, cancellation, and transient-failure rules. Android/iOS suspension pauses client polling without a foreground service and may resume the same unexpired flow; expiry starts a fresh explicit flow rather than replaying a request. Login is single-flight per client.

## Credential ownership

The resulting Hermes One OAuth credential is client-global and stored only through platform secure storage. It is not copied into a Hermes endpoint profile, Hermes Agent, Flutter preferences, migration archive, analytics event, notification, URL, or clipboard. Hermes profile-to-cloud-agent links remain server-side account data and do not duplicate the account credential per profile.

Access-token expiry and refresh-token rotation follow the advertised account contract. Invalid-grant, revocation, account switch, or sign-out clears local account state and profile-linked cloud views without disabling Hermes Agent chat. Sign-out attempts online revocation but does not durably queue a failed revocation; the UI reports when server-side sessions may still require account-portal revocation.

The browser approval page is the authority for account identity, requested scopes, device label, and consent. Hermes Wing never treats a displayed user code, browser-open success, or polling transport state as proof of authorization.

## Web

Web account login requires a separately advertised Authorization Code flow with PKCE, exact redirect URI, state, nonce where applicable, and a reviewed browser token-storage boundary. Device authorization is not silently substituted. Until that contract and storage review pass, Hermes One account surfaces are platform-excluded on web without affecting Hermes Agent use.

## Evidence

Native-platform receipts cover allowed-origin validation, system-browser opening, no embedded webview, complete-URI use, visual code match, no clipboard/hostname leakage, interval and `slow_down`, denial, expiry, cancellation, suspension/resume, single-flight, secure persistence, refresh rotation, account switch, online and offline sign-out, revocation, malformed responses, and separation from every Hermes endpoint credential. Web receipts separately cover PKCE verifier/challenge, redirect/state/nonce validation, cancellation, and token-storage policy.
