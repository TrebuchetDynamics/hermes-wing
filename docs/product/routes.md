# Routes

Hermes Wing uses one adaptive route tree. Android renders four primary destinations plus More; desktop layouts map the same routes to a navigation rail. Routes are added with working vertical slices, so approved entries may remain planned until their capability lands.

| Route | Android placement | Purpose | State |
| --- | --- | --- | --- |
| `/hermes` | Chat | Connection, sessions, runs, voice, approvals, and diagnostics. | implemented |
| `/discover` | Discover | Skills and MCP discovery. | planned |
| `/office` | Office | Adaptive Hermes Office. | planned |
| `/tasks` | Tasks | Kanban and Schedules. | planned |
| `/agents` | More | Profiles, persona, and profile administration. | implemented |
| `/enroll` | (deep link) | One-time pairing-code enrollment, outside the shell. | implemented |
| `/providers` | More | Providers, models, and task-model overrides. | implemented |
| `/tools` | More | Toolsets and MCP administration. | planned |
| `/memory` | More | Memory entries, profile, capacity, and providers. | planned |
| `/gateway` | More | Gateway lifecycle and messaging platforms. | planned |
| `/settings` | More | Local application and installation preferences. | implemented |

Profile switching and session history remain directly reachable from Chat. More is an action sheet, not a route.
