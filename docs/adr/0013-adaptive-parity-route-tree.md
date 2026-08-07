# ADR 0013: Use one adaptive parity route tree

Status: accepted
Date: 2026-07-13

Android uses four primary destinations—Chat, Discover, Office, and Tasks—plus a More action for Profiles, Providers, Tools, Memory, Gateway, and Settings. Tasks combines Kanban and Schedules. The same route tree maps to desktop navigation rather than maintaining separate mobile and desktop screen topologies.

## Consequences

- `/hermes` remains the Chat route and existing deep link.
- `/discover`, `/office`, and `/tasks` become Android primary destinations.
- `/profiles`, `/providers`, `/tools`, `/memory`, `/gateway`, and `/settings` are administrative destinations reached through More on Android; `/agents` redirects to `/profiles` for compatibility.
- Profile switching and session history remain directly reachable from Chat. Native desktop Ctrl/Command+K opens that same session surface, while Ctrl/Command+N is bound only when the exact session-create contract is authorized; shortcuts never become a second authorization path.
- Routes are added only with working vertical slices; the app does not ship placeholder destinations merely to fill the navigation.
