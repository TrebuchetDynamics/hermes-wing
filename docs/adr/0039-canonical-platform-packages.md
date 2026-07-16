# ADR 0039: Use a small canonical package matrix

Status: accepted
Date: 2026-07-13

Official Hermes Wing distribution uses a small platform-native package matrix rather than reproducing every Hermes Desktop/Electron format.

| Platform | Canonical packages |
| --- | --- |
| Android | Store-distributed signed AAB and direct signed APK |
| Linux | Signed APT `.deb` and RPM repository packages |
| Windows | Signed MSIX |
| macOS | Signed and notarized application in a DMG |

AppImage, Snap, portable EXE, generic tar archives, and other secondary formats may be added later but do not block Electron retirement. Existing users of those Hermes Desktop formats receive an explicit migration path to a canonical package.

## Package boundary

- Every package preserves the stable Hermes Wing application identity, data locations, URL handlers, secure-storage identity, and release channel across upgrades.
- Hermes Wing packages contain neither Python nor Hermes Agent. They may install only Hermes Wing application files and declared platform dependencies; they do not download or mutate the managed runtime from package installation scripts.
- Linux package maintainer scripts are minimal, deterministic, and offline. They do not invoke a network, shell a downloaded payload, change Hermes data, create privileged helpers, or add setuid files.
- Supported architectures are declared per platform and must include every architecture supported by the final Hermes Desktop retirement cutoff unless an explicit migration disposition is approved.
- Store and direct Android variants share the same application identity and signing lineage where platform rules permit safe upgrades. Direct and store channels never silently replace one another.
- Package metadata, icons, permissions, entitlements, protocol handlers, publisher identity, and version ordering are tested as product contracts rather than generated release trivia.

## Updates and uninstall

Canonical packages use ADR 0033's platform release authority and verified update path. A package upgrade preserves Hermes Wing client preferences, secure endpoint identity, and the external Hermes runtime and home. Downgrade protection and rollback follow the signed release policy.

Ordinary Hermes Wing uninstall removes application binaries but does not delete Hermes Agent, `HERMES_HOME`, profiles, conversations, backups, or legacy wallet data. Revoking client credentials and removing client-local secrets is an explicit pre-uninstall action; deleting Hermes runtime or domain data requires a separately confirmed cleanup flow. Reinstall discovers the preserved runtime and offers the explicit client-state migration or fresh enrollment paths.

## Evidence

Each canonical package passes clean install, signed upgrade, channel/version ordering, URL activation, secure-storage continuity, existing-runtime adoption, uninstall/reinstall, no-runtime-bundling, offline package-script, tamper rejection, rollback, and data-preservation receipts on its supported architectures. Repository metadata and direct artifacts are authenticated according to ADR 0033.
