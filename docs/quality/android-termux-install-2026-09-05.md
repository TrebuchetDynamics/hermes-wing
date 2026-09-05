# Physical Android / Termux installation evidence — 2026-09-05

Target: Samsung SM-S928B, Android 16, Termux Google Play build
`googleplay.2026.06.21`. This is a development installation with local repairs,
not qualification of the unmodified bootstrap or persistent background hosting.

## Result

- Hermes Agent 0.21.0 installed at revision
  `afc3d9d34c9c3b01fa2e1332d2c66a5b5fabae3f`.
- Wing Link built on the phone from verified source revision
  `21b87ca8c35fb20f95eb1cd3d3bd7db9317ada8b`.
- `wing-link setup` completed and verified the Agent gateway.
- Agent loopback `/health` on port 8642 and Wing Link `/healthz` on port 8654
  both returned HTTP 200, including after opening Wing.
- `wing-link pair --local --same-device` completed through the code-free local
  browser handoff and the production Wing app's connection review.
- Wing reported one connected profile and opened the Default profile's chat.
- Provider/model choice and credentials remain pending; no model response was
  tested. Opening the chat screen is not evidence of successful inference.

## Repairs required on this device

The first broad Python dependency pass was interrupted; the verified installer
continued with its baseline Termux dependency set and completed installation.

Go's direct execution of the generated Hermes shell launcher passed an extra
launcher path to Hermes, causing argument parsing to fail. Running
`termux-fix-shebang` did not resolve it. A small native launcher was compiled
locally: it clears `PYTHONPATH` and `PYTHONHOME`, executes the fixed installed
venv Python and checked-in Hermes entrypoint, and forwards the original arguments.
The same bounded Go `--version` probe then succeeded. Launcher source and the
previous generated launcher were retained on the phone under the local
`hermes-wing-local` support directory. This repair is device-local, not an
upstream or Wing source change; reinstalling Hermes may replace it.

Before this repair, Wing Link's failed launch check triggered its older pinned
installer, which changed the Hermes checkout and failed. The intended Agent
revision was restored only after confirming no tracked changes in that fresh
installation. The repaired launch check allowed Wing Link to adopt it.

The pinned Wing Link build discovers interfaces before reading `--listen`.
Android denied that discovery with a netlink permission error. Setting
`WING_LINK_LISTEN=127.0.0.1:8654` avoided discovery using its existing configuration
path. No Android permissions or network restrictions were weakened.

## Local recovery

A device-local `wing-local-start` command was installed and exercised. It runs
`wing-link setup`, adopts healthy services, and starts Wing Link with its explicit
loopback environment setting if needed. It does not configure boot startup or
request battery exemptions.

Configure the default profile with `hermes model` or `hermes setup` in Termux.
Enter any provider credential directly there. Hermes updates may require
rechecking the native launcher repair before using `wing-local-start`.

See the [Termux runbook](../runbooks/android-termux-local-agent.md) for the product
boundaries. Termux's [shebang repair tool](https://github.com/termux/termux-fix-shebang)
documents interpreter-path translation, but that repair alone did not fix this
phone's observed Go launch failure.
