# Product boundaries

Status: current

## Decision

Hermes Wing is an independent cross-platform client for Hermes Agent. It aims for equivalent user outcomes across supported platforms, not a line-for-line Hermes Desktop port.

Hermes Agent owns profiles, Projects, configuration, memory, skills, sessions,
runs, tools, schedules, approvals, gateway state, and other Agent domains. Wing
uses Hermes interfaces rather than creating a second source of truth. Hermes One
remains a separate optional authority for account and cloud features.

Wing Link is the remote management plane around an external Hermes runtime. When
an Agent API is missing, it may expose only a reviewed typed compatibility
operation defined by the runtime decision. The operation delegates to Hermes and
creates no Wing-owned domain state.

## Flexible guidance

- Navigation, wording, and platform presentation may evolve without a new architecture decision.
- Features may differ by platform when the user outcome remains clear and accessible.
- Unsupported capabilities should be hidden or explained instead of imitated with unreliable local state.
- Product and platform support claims require matching runtime evidence.

Use [CONTEXT.md](../../CONTEXT.md) for current product language and route names.
