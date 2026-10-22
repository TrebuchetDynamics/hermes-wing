# Wing Connect — official Hermes Desktop SDK plugin

A standalone **Desktop UI plugin**, authored by the Wing project using the
[official SDK](https://hermes-agent.nousresearch.com/docs/developer-guide/desktop-plugin-sdk).
It is not bundled with or endorsed by Hermes Agent. No Agent patch, Python plugin,
backend route, Wing Link service, package install or runtime configuration change
is needed. The installable artifact is **`plugin.js` only**.

## What it does

The sidebar page **Connect phone to Wing** (`/wing-connect`) asks the operator for:

- An existing, phone-reachable **HTTPS root origin** (optional root slash).
- The **exact profile ID**, defaulting to `default`. IDs match
  `[a-z0-9][a-z0-9_-]{0,63}`; there is no profile lookup or case conversion.

On **Generate QR**, it renders a real QR entirely offline as inline SVG, with
medium error correction and an included four-module quiet zone. The payload is
strictly these four fields, matching Wing's `HermesGatewayInvite` decoder:

```json
{"type":"hermes-wing-gateway","version":1,"origin":"https://gateway.example","profile":"default"}
```

The origin is canonicalized through `URL.origin` (root slash omitted, hostname
normalized). Credentials, non-root paths, queries, fragments, backslashes and
whitespace are rejected before the URL parser can repair them. Input bounds are
1024 characters for the origin and 64 for the profile. No unknown fields or
credentials are added. Errors never echo the submitted values.

Editing either field hides the previous QR immediately. **Hide QR** removes the
result; leaving the page discards component state. The page does not persist,
log, copy or transmit inputs, read host/profile credentials, discover network
addresses, test reachability or identity, start services, expose ports, or change
configuration. Private origins/profile names remain visible metadata: avoid
sharing screenshots publicly.

The phone must verify the intended origin and authenticate separately through the
official gateway login/PKCE flow. The QR is **not authorization**, a bearer token,
a Desktop-session export, or proof that the gateway supports the phone's login.
An HTTPS gateway reachable from the phone with valid certificates and the needed
authentication support must already exist. The plugin does not prepare one.
A keyboard/screen-reader accessible manual origin/profile alternative is shown
alongside the QR; scanning is optional.

## Manual installation (operator handoff; not performed by this repository)

Use the **Desktop app's actual app-level Hermes home**, not a guessed currently
selected remote profile. Desktop plugins share one root across the window's
profiles/connections. Confirm that root in Desktop's plugin UI/reveal-folder action.
`$HERMES_HOME/desktop-plugins/<id>/plugin.js` is the supported standalone layout;
folder name and plugin ID must both be `wing-connect`.

After reviewing the artifact, an operator can run the following **from this Wing
checkout**, setting `DESKTOP_HERMES_HOME` explicitly to the reviewed Desktop root:

```sh
: "${DESKTOP_HERMES_HOME:?Set the actual Desktop Hermes home first}"
mkdir -p "$DESKTOP_HERMES_HOME/desktop-plugins/wing-connect"
cp -i desktop_plugins/wing-connect/plugin.js \
  "$DESKTOP_HERMES_HOME/desktop-plugins/wing-connect/plugin.js"
```

Do not substitute a different profile's home. `cp -i` preserves an opportunity to
refuse overwriting an existing plugin. No Python `plugins/` directory or runtime
source files should be modified. Desktop watches this directory; if needed use
the command palette's **Reload desktop plugins**. Enable Wing Connect in
**Capabilities → Plugins** if previously disabled, then open the sidebar page.
A load-error toast means installation did not succeed. Removal/disable uses the
same supported plugin UI and affects only this UI contribution.

## Source and validation

`page.mjs` is the readable UI source. `build.mjs` inserts the licensed vendored
QR generator and produces the checked-in `plugin.js`; no build is required on the
operator's Desktop. Only `@hermes/plugin-sdk`, `react` and `react/jsx-runtime` are
imported by the artifact. There are no other runtime files, network images or
external module loads. Black/white SVG ink is intentional for QR readability;
the surrounding UI uses SDK controls and theme colors.

```sh
node desktop_plugins/wing-connect/build.mjs
node desktop_plugins/wing-connect/build.mjs --check
node --check desktop_plugins/wing-connect/plugin.js
node --experimental-vm-modules --test test/tooling/test_gateway_qr_plugin.mjs
git diff --check
```

Tests use Node's VM module linker with mocked SDK/React elements (only the three
allowed module specifiers), exercise the actual registered page and form gestures,
reject unsafe origins/IDs, and check result invalidation. An independent **zbarimg**
decoder reads rasterized versions of the rendered SVG modules and asserts the exact
JSON for DNS, IPv6/port and long-profile examples. `zbarimg` must be installed to
run that test; it is **not** a plugin/runtime dependency. The VM test also checks
artifact reproducibility and prohibited host/network dependencies.

These offline tests do not establish a real Desktop installation, camera scan,
phone connectivity, certificate acceptance, gateway PKCE authentication or a live
chat. No runtime or default-profile installation is part of this change.

## Vendored QR generator

`vendor/qrcode-generator.js` is the unmodified `qrcode.js` from
**qrcode-generator 1.4.4**, Kazuhiko Arase, MIT:

- Package: <https://registry.npmjs.org/qrcode-generator/-/qrcode-generator-1.4.4.tgz>
- Source: <https://github.com/kazuhikoarase/qrcode-generator>
- Source SHA-256: `18ae399f81182bc9de916e9c77b195df20cc58d6f2d55a62b085a299f1bf1780`
- Full license: [`vendor/LICENSE`](vendor/LICENSE), also included in `plugin.js`.

The build removes only the trailing AMD/CommonJS export wrapper when embedding the
source in ESM. QR generation itself is unchanged. Vendoring/rebuilding requires
no network calls; updating the vendor is a separate reviewed action.
