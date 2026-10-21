+++
schema = 1
id = "VERIFY-DIAGNOSTICS-ATOMIC-RECOVERY"
title = "Qualify exact advertised atomic restore authority before native recovery"
short = "Qualify exact advertised atomic restore authority before native recovery"
status = "open"
goal = "DIAGNOSTICS-RECOVERY"
section = "Needs decision"
rank = 1000
depends_on = ["DOC-DIAGNOSTICS-BACKUP-CONTRACT"]
touches = ["**"]
resources = []
kind = "implementation"
ownership = "worker"
scope = "validate an exact advertised Agent recovery operation and its profile, archive, revision, rollback and activation boundaries before implementing a Wing caller."
acceptance = ["authenticated secret-safe operation identity and all-resource rollback must be established; separately approved native target checks must prove recovery."]
exclusions = []
+++

- Sources: [accepted continuation](docs/plans/2026-10-03-desktop-port-goal.md#cron-restart-interview), [contract trace](docs/quality/diagnostics-backup-contract.md).
- Planner decision: skip native restore while its atomic operation is absent. This is primarily a missing Agent contract, not a product-choice question; user permission cannot manufacture all-resource rollback. Reconsider only after source/advertisement establishes that exact operation, then obtain separately approved disposable recovery target/access. Keep ordinary diagnostics work independent; no CLI/direct-file substitute, Agent patch or restore execution. ### **P2** — Remaining supported feature parity and accessibility ### Queue rules These distinct slices preserve two unfinished tasks per incomplete goal. They are queued, not ready while their predecessor is unfinished. Missing contracts remain unavailable; preparation does not authorize activation. Do not start duplicate work or repeat completed proofs with unchanged inputs. These tasks cover previously grouped or implicit gaps. They do not replace existing cards or grant privileged implementation authority. A missing contract defers only that operation. Verification tasks must record executed results before their goals can become `met`. ### **P0** — Desktop welcome and direct connection ### Terminal working-directory files (planned) ### **P1** — Daily use, recovery and core Desktop composition ### Official Desktop production transport successors These implementation slices follow CONNECTION-OFFICIAL-DESKTOP-PORT. They do not repeat its first connection correction or the completed REST/SSE fixture journeys. The internal `HermesWebReadClient` and `HermesWebLifecycle` remain qualification code, not a production channel. Each slice must reuse verified behavior where possible and preserve the existing messaging API path. No task authorizes Agent patches, personal credential discovery, service restarts or provider spending. ### **P3** — Integrated delivery, diagnostics and contracts ### **P1** — Daily use, recovery and core Desktop composition
- Dependencies: DOC-DIAGNOSTICS-BACKUP-CONTRACT is complete. Blocked by missing authoritative atomic restore contract and separately approved live recovery access. Do not patch Agent, execute backup/import, expose secrets or replace its authority.
- Touches: none before conversion; ** stands for the whole repository
