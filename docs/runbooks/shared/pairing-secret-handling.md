# Pairing Secret Handling Contract

Pairing tokens are short-lived secrets used only to connect Navivox to a local Gormes gateway. Use `gormes navivox connect-info` or `gormes navivox pair` to generate local connection details, then paste or scan the token into Navivox only.

Do not paste tokens into logs, docs, screenshots, issues, chat transcripts, runbook evidence, or this repository. Redact tokens before sharing terminal output or browser diagnostics.

UI and diagnostic copy must not echo the token value. If setup, browser pairing, Android intents, or shared-text import fail, describe the source and recovery step without rendering the secret.

Safe evidence may include non-secret base URLs, device IDs, command names, screenshots with token fields obscured, and status messages that prove pairing was attempted without exposing the token.
