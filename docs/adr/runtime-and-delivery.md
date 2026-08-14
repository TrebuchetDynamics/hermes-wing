# Runtime and delivery

Status: current

## Decision

Hermes Agent remains an external runtime. Hermes Wing packages may include Wing Link, but they do not embed Hermes Agent or create a second backend.

Wing Link is an authenticated host supervisor for installation or adoption, pairing, lifecycle, secure bootstrap, health, and diagnostics. It must not expose arbitrary shell or CLI execution or keep shadow domain state.

Hermes profiles are the narrow compatibility exception. Supported Hermes Agent releases cannot be changed for Wing and lack the required profile enrollment contract, so Wing Link delegates to the installed Hermes CLI using only fixed `profile list`, `create`, `rename`, and `delete` argument vectors. During pairing it may resolve each validated profile's credential path through fixed `hermes --profile <id> config env-path`, enable `gateway.multiplex_profiles`, restart the active gateway, and issue a verified `/p/<id>` connection per profile. It bounds CLI output and execution time, invokes no shell, fails closed on unknown list output or unsafe credential paths, and retains no profile inventory or raw credential. It never invokes `profile use`, accepts a client-selected executable or subcommand, or extends this adapter to providers, general configuration, sessions, messages, tools, schedules, approvals, or messaging semantics.

Keep listeners local or on an explicitly selected trusted private/VPN interface. Android/Termux integration uses fixed allowlisted commands rather than client-provided shell text.

Runtime and application installation should use authenticated, versioned artifacts, verify before activation, and preserve user data. Updates should have a practical recovery path when activation or health checks fail. Optional components and starter content require clear consent and must fail independently.

## Flexible guidance

- Package formats, release channels, service managers, ports, and installer mechanics may follow supported platform conventions.
- A compatible existing runtime may be adopted in place rather than normalized or reinstalled.
- Background clients may detach while server-owned runs continue, then reconcile on return.
- Distribution and platform support claims require evidence from the affected platform; one platform does not prove another.
