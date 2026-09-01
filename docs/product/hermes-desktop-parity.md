# Hermes Desktop parity

This matrix tracks Hermes Desktop outcomes against Hermes Wing’s current typed Agent and Wing Link contracts. A Desktop screen or source file is not proof that the same operation is safe or supported in Wing.

## Statuses

- **implemented** — working Wing outcome with focused tests and capability gates.
- **partial** — an equivalent or read-only outcome exists, but Desktop mutations or transport are not available.
- **contract-blocked** — the current Hermes Agent capability document does not advertise the required operation.
- **local-native** — a desktop-local feature requiring platform implementation and runtime evidence.

| Hermes Desktop outcome                                                        | Wing status      | Current Wing outcome                                              | Required next contract or evidence                                     |
| ----------------------------------------------------------------------------- | ---------------- | ----------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Streaming chat, Markdown, tool activity, approvals, stop, retry               | implemented      | `/hermes` chat and runs                                           | Maintain Agent session/run contracts                                   |
| Session search, resume, fork, rename, delete                                  | implemented      | Chat session rail and actions                                     | Maintain exact session endpoints                                       |
| Agents/profiles and persona editing                                           | partial          | `/profiles`, embedded profile editor                              | Stable Agent profile/SOUL contracts or reviewed compatibility adapter  |
| Skills/Discover registry, install, uninstall, source links, profile targeting | contract-blocked | Installed skill inventory only through `/v1/skills`               | Bounded Agent registry/install/uninstall/profile-target contracts      |
| Memory entries, profile memory, capacity, providers                           | contract-blocked | No memory route                                                   | Advertised bounded memory read/write/provider contracts                |
| Saved models and full provider configuration                                  | partial          | Read-only/runtime and session model selection where advertised    | Agent provider/model CRUD, OAuth, pool, and secret-safe contracts      |
| Schedule create/edit/pause/resume/run/delete and delivery targets             | partial          | `/tasks` read-only job inventory                                  | Agent must advertise jobs admin endpoints and typed delivery targets   |
| Messaging gateway administration                                              | contract-blocked | Gateway health/status only                                        | Exact typed per-platform Agent or Wing Link operations                 |
| Toolset enable/disable and MCP administration                                 | partial          | `/tools` inventory only                                           | Advertised mutation and MCP contracts                                  |
| Standalone Soul/persona route                                                 | partial          | `/soul` plus the embedded Profiles persona editor                 | Stable profile-scoped SOUL read/write contract                         |
| Kanban/task planning                                                          | contract-blocked | No board state                                                    | Agent-owned Hermes Project/card contract plus opaque directory grants  |
| Backup/import, debug dump, log viewer, config health/fixes                    | partial          | Bounded diagnostics and local settings                            | Redacted structured diagnostics and atomic backup contracts            |
| Account/OAuth/credential pools, credits, wallet balances                      | contract-blocked | No account route                                                  | Exact account/provider/wallet contracts and secure OAuth handoff       |
| SSH/Docker/WSL remote backends                                                | contract-blocked | Typed gateway connections only                                    | Fixed Wing Link backend profiles and lifecycle contracts               |
| Web preview, file viewer, attachments/media                                   | partial          | Text/image attachments and bounded transcript media               | Advertised artifact/preview contracts and directory grants             |
| Office 3D/Claw3d management                                                   | partial          | Accessible 2D Office equivalent                                   | Optional local adapter; 2D path remains primary                        |
| Auto-updates and desktop window/install flows                                 | partial          | Linux install/build and native menu commands                      | Signed manifest, activation, health, and rollback evidence             |
| Full Desktop slash-command catalog                                            | partial          | Curated local `/usage`, `/model`, `/persona`, `/version` commands | Agent command catalog/completion contract; no arbitrary shell dispatch |

## Ownership rules

Hermes Agent owns domain state. Wing Link owns authenticated host setup, lifecycle, health, reviewed typed compatibility operations, and opaque directory grants. Wing never becomes a shell bridge, proxy for Agent traffic, or second backend.

A feature is promoted from `contract-blocked` or `partial` only after the exact operation is advertised by the connected Agent or implemented as a reviewed fixed Wing Link operation, then covered by unit/widget, deterministic fixture, and named-platform E2E evidence.
