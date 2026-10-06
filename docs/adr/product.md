# Product boundaries

Status: current

## Decision

Hermes Wing prioritizes a 1:1 Hermes Desktop product port in Flutter: feature
coverage, navigation, terminology, interaction flows, state transitions and
recovery behavior follow Desktop rather than a separately designed client.
This is product/behavior parity, not a line-for-line Electron implementation.
Platform adaptations must preserve the reference behavior or explicitly record
the difference. This priority was accepted by the product owner on 2026-10-03;
it does not establish that parity has already been implemented or qualified.

Hermes Agent owns profiles, Projects, configuration, memory, skills, sessions,
runs, tools, schedules, approvals, gateway state, and other Agent domains. Wing
uses Hermes interfaces rather than creating a second source of truth. Hermes One
remains a separate optional authority for account and cloud features.

Wing Link is the remote management plane around an external Hermes runtime, not
the organizing principle or a prerequisite goal of the Desktop port. Prioritize
direct Agent connection and Desktop parity over new Wing-specific management
features. Removing existing Wing Link dependencies or making it optional requires
a separately scoped implementation and verification; this decision does neither.
When
an Agent API is missing, it may expose only a reviewed typed compatibility
operation defined by the runtime decision. The operation delegates to Hermes and
creates no Wing-owned domain state.

## Flexible guidance

- Match Desktop navigation and wording by default; document deliberate deviations.
- Use platform-native presentation where required, preserving Desktop behavior and accessibility.
- Unsupported capabilities should be hidden or explained instead of imitated with unreliable local state.
- Product and platform support claims require matching runtime evidence.

Use [CONTEXT.md](../../CONTEXT.md) for current product language and route names.
