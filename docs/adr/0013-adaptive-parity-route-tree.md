# ADR 0013: Use one adaptive parity route tree

Status: accepted
Date: 2026-07-13

Android uses four primary destinations—Chat, Discover, Office, and Tasks—plus a More action for Agents, Providers, Tools, Memory, Gateway, and Settings. Tasks combines Kanban and Schedules. The same route tree maps to desktop navigation rather than maintaining separate mobile and desktop screen topologies.

## Consequences

- `/hermes` remains the Chat route and existing deep link.
- `/discover`, `/office`, and `/tasks` become Android primary destinations.
- `/agents`, `/providers`, `/tools`, `/memory`, `/gateway`, and `/settings` are administrative destinations reached through More on Android.
- Profile switching and session history remain directly reachable from Chat.
- Routes are added only with working vertical slices; the app does not ship placeholder destinations merely to fill the navigation.
