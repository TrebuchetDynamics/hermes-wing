# Android/Termux local Hermes Agent candidate

Status: Tier 2 qualification candidate; best-effort background operation

This flow hosts Hermes Agent and Wing Link inside Termux on the same Android
phone as Hermes Wing. It is separate from [pairing Android to a remote Linux
host](android-hermes-setup.md).

## Boundaries

- Install Termux from an [officially documented source](https://github.com/termux/termux-app#installation).
- Wing copies one public, immutable, verified command after an explicit tap. The
  user runs it in Termux; Wing does not request Termux external-command access.
- Signed Wing releases copy a command that downloads the immutable Wing Link
  binary and verifies its SHA-256. Source-built development APKs instead copy a
  command that downloads a bounded, commit-pinned source archive, verifies its
  exact size, archive SHA-256, and installer SHA-256, then builds Wing Link in
  Termux. The development path separately verifies and runs the current pinned
  Hermes Agent installer before Wing Link adopts it. Both paths invoke Hermes
  Agent's reviewed official installer; neither
  uses the mutable website one-liner or a community APT repository.
- Hermes Agent binds `127.0.0.1:8642`; Wing Link binds `127.0.0.1:8654`.
  Authentication is still mandatory because any local app can probe loopback.
- Android may suspend or kill both processes. There is no managed service,
  boot persistence, battery-exemption request, or unattended reliability claim.

## Install and pair

1. In Wing enrollment choose **Use this phone**. Confirm that Termux opens, then continue to the verified setup command.
2. Copy the verified setup command, open Termux, paste it, and keep Termux in
   the foreground while installation runs. Development builds install Termux's
   `golang` package and compile the pinned Wing Link source, so their first run
   takes longer than a signed release installation.
3. The installer adopts or installs Hermes Agent, starts both loopback services,
   and prints a code-free `http://127.0.0.1:<port>/open` link.
4. Tap the link, choose **Open Hermes Wing**, review the host and requested
   access, then confirm. The underlying pairing code remains five-minute,
   single-use, and absent from the copied bootstrap command.

## Configure a model

### Optional OmniRoute installation

Wing Link builds containing the OmniRoute installer support this explicit local
command after Node.js and npm are available:

```bash
wing-link setup --with-omniroute
wing-link omniroute-setup
```

The first command installs or adopts Hermes and installs OmniRoute 3.8.50 using
an embedded npm dependency lock. It disables npm lifecycle scripts, keeps
installation output private, checks the CLI, and activates the version directory
only after those checks pass. The second command opens OmniRoute's own interactive
setup wizard in the local terminal; it accepts no credential arguments.

The lock overrides vulnerable transitive dependencies with `adm-zip` 0.6.0,
`sharp` 0.35.3, and DOMPurify 3.4.13. See the
[installer review](../quality/omniroute-install-review.md) for audit results,
compatibility checks, and runtime limits.

OmniRoute is not started by Wing Link setup. Configure its administrator password
and provider access locally before running its server. Installing it does not
select a Hermes provider/model or connect Hermes to it. Existing Hermes profile
configuration still belongs to the Hermes CLI or an advertised Agent API.

The installer requires Node `>=22.22.2 <23` or `>=24 <27`. It currently supports
POSIX hosts; the locked installation and CLI checks were exercised on Linux.
This OmniRoute path has not yet been exercised on the physical Android device,
which disconnected during implementation. Earlier pinned Wing Link binaries do
not contain this option; installing an older bootstrap pin will not add it.

See [OmniRoute's Termux guide](https://github.com/diegosouzapw/OmniRoute/blob/release/v3.8.51/docs/guides/TERMUX_GUIDE.md)
for upstream runtime requirements. Electron and native integrations are not
qualified by this installation check.

### Hermes profile configuration

Choose one path after pairing:

1. **Existing default profile:** run `hermes setup` or `hermes model` in Termux.
   Hermes Agent remains authoritative for existing-profile configuration.
2. **Configure mostly in Wing:** create a new profile in Wing with its provider,
   model, and optional write-only credential. If approval is required, keep the
   draft open, run `wing-link approvals list` and
   `wing-link approvals approve <id>` in Termux, then retry the unchanged setup.
   Then pair again so Wing receives that new profile's own `/p/<profile>`
   Agent credential. Inventory visibility alone does not make the profile ready
   for Chat.

Existing-profile provider or credential edits remain blocked in Wing. Provider
credentials are sent only through the bounded stdin-driven new-profile operation;
they never enter command arguments, pairing links, logs, or diagnostics.

## Recovery

Start with `wing-link doctor`. It checks the Hermes executable, authenticated
local Agent API, and Wing Link's default loopback listener, then prints recovery
commands. It does not reinstall, restart, pair, or change credentials. A broken
Hermes CLI leads to local diagnosis before any reinstall recommendation.

Run `wing-link` for a short first-run guide, or `wing-link help pair` and
`wing-link setup --help` for focused examples. Help commands never start setup.
See the [Wing Link CLI guide](wing-link-cli.md) for output and exit-code details.

If Wing reports both local services disconnected, return to Termux and rerun the
same verified setup command. A healthy existing Hermes Agent, Wing Link process,
and Wing Link identity are adopted rather than duplicated or rotated. Server
state wins after reconnect; Wing does not silently replay queued mutations.

Use these non-secret checks in Termux when needed:

```bash
hermes --version
hermes doctor
curl --fail http://127.0.0.1:8642/health
curl --fail http://127.0.0.1:8654/healthz
```

The tested Termux bundle is intentionally narrower than desktop/server installs.
Do not infer support for `.[all]`, local `faster-whisper`, Docker isolation,
browser or WhatsApp bootstrap, x86 Android, or persistent background hosting.
