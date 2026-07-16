# ADR 0042: Provide guarded legacy-wallet export

Status: accepted
Date: 2026-07-13

Before Electron retirement, the final supported Hermes Desktop line must let an operator recover every decryptable legacy local wallet one at a time. This is a local data-exit feature in Hermes Desktop, not wallet custody or import in Hermes Wing.

## Entry and verification

Export is available only from the local desktop process for the selected profile and wallet. It is not exposed through Dashboard, Hermes Agent, SSH, remote IPC, Hermes One, or a URL handler. The operator reviews the wallet name, network, and full public address, completes operating-system user-presence verification when available, and enters a high-emphasis wallet-specific confirmation. Platforms without a usable user-presence API require the documented typed-confirmation fallback and disclose that limitation.

The Electron main process decrypts exactly one `safeStorage` value and derives its wallet before export. A mismatched phrase, public address, network, malformed record, unavailable secure store, or decryption failure stops the flow without returning partial secret material. Public metadata may be logged only in redacted form; the phrase never is.

## Export choices

### Timed manual reveal

A dedicated sandboxed, CSP-locked, non-debuggable local window reveals the phrase only after confirmation, obscures it on focus loss, disables selection and clipboard actions, requests platform screen-capture protection where available, and clears and closes after a short visible timeout. The operator transcribes it manually and confirms selected words before the flow records success. Hermes Wing does not claim that desktop operating systems can prevent every camera or privileged screen capture.

### Passphrase-encrypted file

The main process asks for and confirms a new export passphrase, writes through a native save picker, and never sends the recovery phrase to the ordinary renderer. A versioned authenticated-encryption envelope contains the phrase, expected public address, network, creation time, and format version; only non-secret format/KDF parameters remain outside the ciphertext. Encryption uses maintained platform/runtime cryptographic primitives with a memory-hard password KDF and authenticated encryption, then decrypts and re-derives the address in memory before reporting success.

The export passphrase and plaintext are never persisted, logged, copied, included in crash reports, or retained after the operation. Existing output is not overwritten without a second confirmation. Temporary and partial files are owner-only and removed on cancellation or failure.

## Prohibited flows

There is no clipboard, QR, print, cloud upload, bulk export, automatic Hermes Wing/Hermes One transfer, analytics event containing wallet identity, or API response containing recovery material. Export does not delete, rename, migrate, or mark the wallet safe. Deletion remains a separate later action with its own confirmation after the operator independently verifies recovery.

Legacy wallet material remains excluded from Hermes Wing backup/import and client-state migration. Hermes Wing never decrypts or imports the phrase.

## Retirement evidence

The retirement inventory scans every Desktop profile and reports only wallet counts and safe identifiers. Linux, Windows, and macOS receipts cover generated and imported wallets, each profile, address derivation, manual timeout/focus loss, blocked clipboard and bulk paths, encrypted-file round trip, wrong passphrase, cancellation and partial-file cleanup, existing-output refusal, secure-store failure, separate deletion, and zero secret leakage through logs, IPC traces, diagnostics, screenshots, URLs, or analytics. Any known decryptable wallet without a passing exit path keeps the Electron retirement gate closed.
