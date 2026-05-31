# Termux Gormes Bootstrap

Use this guide when the operator wants to run a trusted Gormes gateway on the same Android device as Navivox through Termux.

This is not a silent mobile installer. Phase 1 is a user-run Termux bootstrap. Phase 2 can make Navivox assist the handoff, but Android app sandboxing means Navivox cannot silently install Gormes or run arbitrary Termux commands without explicit user action.

## Target product direction: one terminal interaction maximum

The target Android flow is: Install Termux, paste one command, continue in Navivox. Termux installation remains an explicit Android user action, but after Termux opens the operator should need at most one pasted bootstrap command before setup moves to the app.

After the bootstrap finishes, Gormes should print a short handoff instead of keeping the operator in a long terminal wizard:

```text
Gormes installed successfully
Choose setup path:
1. Navivox (recommended)
   Pair your Android app and continue setup there.
2. CLI setup
   Continue fully in terminal.
Recommended next step: gormes navivox pair
```

`gormes navivox pair` is the intended app-first handoff command. It should start local bridge, generate a pairing token, show a QR, print localhost URL, and wait for Navivox connection. Navivox then finishes configuration, verifies gateway status, and keeps pairing tokens inside the app.

## Source-backed Termux facts

- Termux publishes current install guidance from the Termux app repository and site: <https://termux.dev/en/> and <https://github.com/termux/termux-app>.
- Full app and package support is for Android >= 7.
- Prefer Termux from F-Droid or official GitHub Releases. Google Play currently has an experimental Android 11+ branch with missing functionality compared with the stable F-Droid build.
- The Termux app and plugins must come from one signing source; do not mix Termux APK sources, such as installing the main app from F-Droid and a plugin from GitHub.
- Keep Termux packages current before installing new packages: run `pkg upgrade` regularly.

## Phase 1: user-run Termux bootstrap

1. Install Termux on the Android device.
   - Preferred: F-Droid package `com.termux`.
   - Alternative: official Termux GitHub Releases.
   - Avoid mixing APK sources. If changing sources, uninstall existing Termux app and plugin APKs first and restore from a backup only after reinstalling from the same source family.
2. Open Termux and paste this one bootstrap command:

   ```sh
   printf '%s\n' 'This is one pasted Termux command for Navivox setup.' && \
   pkg upgrade -y && \
   pkg install -y git curl && \
   curl -fsSLO https://github.com/TrebuchetDynamics/gormes-agent/releases/latest/download/install.sh && \
   printf '%s\n' 'Review install.sh in the pager. Press q to continue install, or Ctrl-C to abort.' && \
   less install.sh && \
   GORMES_SKIP_SETUP=1 bash install.sh && \
   (gormes navivox pair || gormes navivox connect-info)
   ```

   This keeps the normal path to one pasted bootstrap command while still avoiding a blind network-to-shell pipe: it downloads `install.sh`, pauses for review in `less`, skips the long terminal setup wizard, and then starts the Navivox pairing handoff. If the installed Gormes build does not have `gormes navivox pair`, the command falls back to `gormes navivox connect-info`.

3. Paste or scan the reachable base URL and token into Navivox only. Never paste pairing tokens into issues, logs, screenshots, chat transcripts, or this repository.

4. Grant shared-storage access only if the operator needs to move logs, screenshots, or exported files between Android storage and Termux. This is not part of the normal one-terminal setup path:

   ```sh
   termux-setup-storage
   ```

## Phase 2: Navivox-assisted bootstrap

A future Navivox flow can reduce copy-and-paste mistakes, but it must stay explicit and reversible.

Navivox may help by:

- detecting that no trusted gateway is configured;
- showing the Phase 1 Termux checklist inside the setup flow;
- copying the safe command block to the clipboard;
- copying an optional Termux:Boot helper after manual Gormes setup succeeds;
- opening the official Termux download page or this guide;
- warning when a device URL uses `127.0.0.1` incorrectly for a separate host; and
- prompting the operator to paste values from `gormes navivox connect-info` after Termux finishes.

Navivox must not:

- install Termux APKs itself;
- bypass Android package-install prompts;
- run Termux commands silently;
- install the Termux:Boot plugin or enable boot actions without the operator;
- read private Termux files directly;
- embed pairing tokens in logs or screenshots; or
- assume a Google Play Termux build has the same behavior as F-Droid or official GitHub Releases.

## Optional Termux:Boot auto-start

Use this only after `bash install.sh`, `gormes gateway`, and `gormes navivox connect-info` work manually in Termux.

Install the Termux:Boot plugin from the same APK source as Termux. For example, do not mix a F-Droid Termux app with a GitHub Releases Termux:Boot plugin.

Then run these commands in Termux:

```sh
gormes gateway boot-install
gormes gateway status
gormes navivox connect-info
```

The boot install command writes `~/.termux/boot/gormes-gateway.sh`. Reboot Android to let Termux:Boot start the tmux gateway, then verify with `gormes gateway status` and paste fresh `gormes navivox connect-info` values into Navivox only.

Rollback is explicit:

```sh
gormes gateway boot-uninstall
```

This helper does not make Android background execution reliable. Android battery management may still stop Termux, and Navivox still does not install APKs or run Termux commands for the operator.

## Android networking notes

- Same device, Gormes inside Termux: Navivox should usually connect to the loopback URL printed by `gormes navivox connect-info`.
- Android emulator to host Gormes: use `http://10.0.2.2:<port>`.
- Physical Android device to separate host Gormes: use the host LAN, VPN, or Tailscale URL printed by `gormes navivox connect-info`.

## Recovery checks

- If `pkg upgrade` or `pkg install git curl` fails, reopen Termux and retry after selecting a working mirror.
- If `bash install.sh` fails, rerun it with verbose installer diagnostics only if the installer supports that mode, and redact paths or tokens before sharing logs.
- If Navivox cannot connect after Gormes starts, rerun `gormes navivox connect-info` and paste fresh values into Navivox only.
